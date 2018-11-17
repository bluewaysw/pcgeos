COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiLocksControl.asm

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
	Code for the GrObjLocksControlClass

	$Id: uiLocksControl.asm,v 1.1 97/04/04 18:05:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjLocksControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjLocksControlClass

DESCRIPTION:	Return locks

PASS:
	*ds:si - instance data
	es - segment of GrObjLocksControlClass

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
GrObjLocksControlGetInfo	method dynamic	GrObjLocksControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOLC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjLocksControlGetInfo	endm

GOLC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOLC_IniFileKey,		; GCBI_initFileKey
	GOLC_gcnList,		; GCBI_gcnList
	length GOLC_gcnList,		; GCBI_gcnCount
	GOLC_notifyList,		; GCBI_notificationList
	length GOLC_notifyList,		; GCBI_notificationCount
	GOLCName,			; GCBI_controllerName

	handle GrObjLocksControlUI,	; GCBI_dupBlock
	GOLC_childList,		; GCBI_childList
	length GOLC_childList,		; GCBI_childCount
	GOLC_featuresList,	; GCBI_featuresList
	length GOLC_featuresList,	; GCBI_featuresCount

	GOLC_DEFAULT_FEATURES,		; GCBI_features

	0,
	0,
	0,
	0,
	0,
	0,
	GOLC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOLC_helpContext	char	"dbGrObjLocks", 0

GOLC_IniFileKey	char	"GrObjLocks", 0

GOLC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GOLC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GOLC_childList	GenControlChildInfo \
	<offset GrObjLocksBooleanGroup, mask GrObjLocks, 0>

GOLC_featuresList	GenControlFeaturesInfo	\
	<offset PrintLockBoolean, PrintLockName, 0>,
	<offset DrawLockBoolean, DrawLockName, 0>,
	<offset UnGroupLockBoolean, UnGroupLockName, 0>,
	<offset GroupLockBoolean, GroupLockName, 0>,
	<offset AttributeLockBoolean, AttributeLockName, 0>,
	<offset SelectLockBoolean, SelectLockName, 0>,
	<offset DeleteLockBoolean, DeleteLockName, 0>,
	<offset EditLockBoolean, EditLockName, 0>,
	<offset SkewLockBoolean, SkewLockName, 0>,
	<offset RotateLockBoolean, RotateLockName, 0>,
	<offset ResizeLockBoolean, ResizeLockName, 0>,
	<offset MoveLockBoolean, MoveLockName, 0>,
	<offset WrapLockBoolean, WrapLockName, 0>,
	<offset ShowLockBoolean, ShowLockName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjLocksControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjLocksControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjLocksControlClass
	ax - MSG_GEN_CONTROL_UPDATE_UI

	ss:bp - GenControlUpdateUIParams

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
GrObjLocksControlUpdateUI	method dynamic GrObjLocksControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx, dx

	.enter

	test	ss:[bp].GCUUIP_features, mask GrObjLocks
	jz	done

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax
	mov	cx, es:[GONSSC_selectionState].GSS_locks
	mov	ax, es:[GONSSC_locksDiffs]
	call	MemUnlock

	;
	;	We set "indeterminate" any non-true or actually indeterminate
	;	(ie, different objects have different bits) locks
	;
	mov	dx, cx
	not	dx
	or	dx, ax

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset GrObjLocksBooleanGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjLocksControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjLocksControlChangeLocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjLocksControl method for MSG_GOLC_CHANGE_LOCKS

Called by:	

Pass:		*ds:si = GrObjLocksControl object
		ds:di = GrObjLocksControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLocksControlChangeLocks	method dynamic	GrObjLocksControlClass,
				MSG_GOLC_CHANGE_LOCKS
	.enter


	call	GetChildBlockAndFeatures
	test	ax, mask GrObjLocks
	jz	done

	push	si
	mov	si, offset GrObjLocksBooleanGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	push	ax					;save TRUE/FALSE

	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_INDETERMINATE_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	push	ax					;save INDET

	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_MODIFIED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage				;ax <- MOD

	pop	dx					;dx <- INDET
	pop	cx					;cx <- TRUE
	or	dx, cx					;dx <- T or I
	not	dx					;dx <- FALSE
	and	cx, ax					;cx <- true modified
	and	dx, ax					;dx <- false modified

	pop	si
	mov	ax, MSG_GO_CHANGE_LOCKS
	call	GrObjControlOutputActionRegsToGrObjs

done:
	.leave
	ret
GrObjLocksControlChangeLocks	endm

GrObjUIControllerActionCode	ends
