COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiDraftModeControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjDraftModeControlClass

	$Id: uiDraftModeControl.asm,v 1.1 97/04/04 18:06:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDraftModeControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjDraftModeControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjDraftModeControlClass

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
GrObjDraftModeControlGetInfo	method dynamic	GrObjDraftModeControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GODMC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjDraftModeControlGetInfo	endm

GODMC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GODMC_IniFileKey,		; GCBI_initFileKey
	GODMC_gcnList,			; GCBI_gcnList
	length GODMC_gcnList,		; GCBI_gcnCount
	GODMC_notifyList,		; GCBI_notificationList
	length GODMC_notifyList,		; GCBI_notificationCount
	GODMCName,			; GCBI_controllerName

	handle GrObjDraftModeControlUI,	; GCBI_dupBlock
	GODMC_childList,			; GCBI_childList
	length GODMC_childList,		; GCBI_childCount
	GODMC_featuresList,		; GCBI_featuresList
	length GODMC_featuresList,	; GCBI_featuresCount

	GODMC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	0,	; GCBI_dupBlock
	0,	; GCBI_childList
	0,	; GCBI_childCount
	0,	; GCBI_featuresList
	0,	; GCBI_featuresCount

	0,	; GCBI_defaultFeatures
	GODMC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GODMC_helpContext	char	"dbGrObjDraft", 0

GODMC_IniFileKey	char	"GrObjDraftMode", 0

GODMC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_INSTRUCTION_FLAGS_CHANGE>

GODMC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_INSTRUCTION_FLAGS_CHANGE>

;---


GODMC_childList	GenControlChildInfo \
	<offset GrObjDraftModeBooleanGroup, mask GODMCF_DRAFT_MODE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GODMC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjDraftModeBoolean, DraftModeName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjDraftModeControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjDraftModeControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjDraftModeControlClass
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
GrObjDraftModeControlUpdateUI	method dynamic GrObjDraftModeControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx, dx

	.enter

	test	ss:[bp].GCUUIP_features, mask GODMCF_DRAFT_MODE
	jz	done

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	jc	done
	mov	es, ax
	mov	cx, es:[GBNIF_flags]
	call	MemUnlock
	mov	bx, ss:[bp].GCUUIP_childBlock

	mov	dx, cx
	not	dx
	
	mov	si, offset GrObjDraftModeBooleanGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjDraftModeControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDraftModeControlSetDraftModeStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjDraftModeControl method for MSG_GODMC_SET_DRAFT_MODE_STATUS

Called by:	

Pass:		*ds:si = GrObjDraftModeControl object
		ds:di = GrObjDraftModeControl instance

		cx - GODF_DRAW_QUICK_VIEW set (or not)

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDraftModeControlSetDraftModeStatus	method dynamic	GrObjDraftModeControlClass, MSG_GODMC_SET_DRAFT_MODE_STATUS

	.enter

	mov	dx, cx
	not	dx
	mov	ax, mask GODF_DRAW_QUICK_VIEW
	and	cx, ax
	and	dx, ax
	mov	ax, MSG_GB_SET_GROBJ_DRAW_FLAGS
	call	GrObjControlOutputActionRegsToBody

	.leave
	ret
GrObjDraftModeControlSetDraftModeStatus	endm

GrObjUIControllerActionCode	ends
