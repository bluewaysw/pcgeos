COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiPasteInsideControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjPasteInsideControlClass

	$Id: uiPasteInsideControl.asm,v 1.1 97/04/04 18:06:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjPasteInsideControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjPasteInsideControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjPasteInsideControlClass

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
GrObjPasteInsideControlGetInfo	method dynamic	GrObjPasteInsideControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOPIC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjPasteInsideControlGetInfo	endm

GOPIC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOPIC_IniFileKey,		; GCBI_initFileKey
	GOPIC_gcnList,			; GCBI_gcnList
	length GOPIC_gcnList,		; GCBI_gcnCount
	GOPIC_notifyList,		; GCBI_notificationList
	length GOPIC_notifyList,		; GCBI_notificationCount
	GOPICName,			; GCBI_controllerName

	handle GrObjPasteInsideControlUI,	; GCBI_dupBlock
	GOPIC_childList,			; GCBI_childList
	length GOPIC_childList,		; GCBI_childCount
	GOPIC_featuresList,		; GCBI_featuresList
	length GOPIC_featuresList,	; GCBI_featuresCount

	GOPIC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	handle GrObjPasteInsideToolControlUI,	; GCBI_dupBlock
	GOPIC_toolList,			; GCBI_childList
	length GOPIC_toolList,		; GCBI_childCount
	GOPIC_toolFeaturesList,		; GCBI_featuresList
	length GOPIC_toolFeaturesList,	; GCBI_featuresCount

	GOPIC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_defaultFeatures
	GOPIC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOPIC_helpContext	char	"dbGrObjEdSpc", 0

GOPIC_IniFileKey	char	"GrObjPasteInside", 0

GOPIC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE>

GOPIC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_SELECT_STATE_CHANGE>

;---


GOPIC_childList	GenControlChildInfo \
	<offset GrObjPasteInsideTrigger, mask GOPICF_PASTE_INSIDE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjBreakoutPasteInsideTrigger, mask GOPICF_BREAKOUT_PASTE_INSIDE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOPIC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjBreakoutPasteInsideTrigger, BreakoutPasteInsideName, 0>,
	<offset GrObjPasteInsideTrigger, PasteInsideName, 0>

GOPIC_toolList	GenControlChildInfo \
	<offset GrObjPasteInsideTool, mask GOPICTF_PASTE_INSIDE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjBreakoutPasteInsideTool, mask GOPICTF_BREAKOUT_PASTE_INSIDE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOPIC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset GrObjBreakoutPasteInsideTool, BreakoutPasteInsideName, 0>,
	<offset GrObjPasteInsideTool, PasteInsideName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjPasteInsideControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjPasteInsideControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjPasteInsideControlClass
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
GrObjPasteInsideControlUpdateUI	method dynamic GrObjPasteInsideControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx, dx, bp

	.enter

	cmp	ss:[bp].GCUUIP_changeType, GWNT_SELECT_STATE_CHANGE
	jne	grobjUpdate

	;
	;  It's a GWNT_SELECT_STATE_CHANGE update, so use our lastNumSelected
	;  to determine whether or not we should update
	;

	mov	ax, MSG_GEN_SET_NOT_ENABLED		;assume not enabled
	tst	ds:[di].GPICI_lastNumSelected
	jz	setPasteInsideable

	push	bp
	clr	bp
	call	GrObjTestSupportedTransferFormats
	pop	bp
	jnc	setPasteInsideable

	mov	ax, MSG_GEN_SET_ENABLED		;assume not enabled

setPasteInsideable:
	mov	dl, VUM_NOW
	test	ss:[bp].GCUUIP_features, mask GOPICF_PASTE_INSIDE
	jz	checkPasteInsideTool

	;
	;  Send the message to the PasteInside trigger
	;

	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset GrObjPasteInsideTrigger
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

checkPasteInsideTool:
	test	ss:[bp].GCUUIP_features, mask GOPICTF_PASTE_INSIDE
	jz	done

	;
	;  Send the message to the PasteInside trigger
	;

	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, offset GrObjPasteInsideTool
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jmp	done

grobjUpdate:

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	jc	done
	mov	es, ax
	mov	ax, es:[GONSSC_selectionState].GSS_numSelected
	call	MemUnlock

	;
	;  Store the number for next time
	;

	mov	ds:[di].GPICI_lastNumSelected, ax

	;
	;  If there aren't any selected objects, none of the UI should
	;  be highlited
	;
	mov	cx, 1
	tst	ax
	jz	setPasteInsideStatus

	push	bp
	clr	bp
	call	GrObjTestSupportedTransferFormats
	pop	bp
	mov	cx, 1
	jc	setPasteInsideStatus

	;
	;  OK, there's no pasteable item on the clipboard, so we'll fool
	;  our utility routine into disabling the paste inside stuff
	;  based on num selected (some impossibly large value)
	;

	mov	cx, 0x7fff
	
setPasteInsideStatus:

	mov	ax, mask GOPICF_PASTE_INSIDE
	mov	si, offset GrObjPasteInsideTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	mov	ax, mask GOPICTF_PASTE_INSIDE
	mov	si, offset GrObjPasteInsideTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	mov	ax, mask GOPICF_BREAKOUT_PASTE_INSIDE
	mov	si, offset GrObjBreakoutPasteInsideTrigger
	call	GrObjControlUpdateUIBasedOnPasteInsideSelectedAndFeatureSet

	mov	ax, mask GOPICTF_BREAKOUT_PASTE_INSIDE
	mov	si, offset GrObjBreakoutPasteInsideTool
	call	GrObjControlUpdateToolBasedOnPasteInsideSelectedAndFeatureSet

done:
	.leave
	ret
GrObjPasteInsideControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjPasteInsideControlPasteInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjPasteInsideControl method for MSG_GOPIC_PASTE_INSIDE

Called by:	

Pass:		*ds:si = GrObjPasteInsideControl object
		ds:di = GrObjPasteInsideControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPasteInsideControlPasteInside	method dynamic	GrObjPasteInsideControlClass, MSG_GOPIC_PASTE_INSIDE

	.enter

	mov	ax, MSG_GB_PASTE_INSIDE
	call	GrObjControlOutputActionRegsToBody

	.leave
	ret
GrObjPasteInsideControlPasteInside	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjPasteInsideControlBreakoutPasteInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjPasteInsideControl method for
		MSG_GOPIC_BREAKOUT_PASTE_INSIDE

Called by:	

Pass:		*ds:si = GrObjPasteInsideControl object
		ds:di = GrObjPasteInsideControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjPasteInsideControlBreakoutPasteInside	method dynamic	GrObjPasteInsideControlClass, MSG_GOPIC_BREAKOUT_PASTE_INSIDE

	.enter

	mov	ax, MSG_GB_UNGROUP_SELECTED_GROUPS
	call	GrObjControlOutputActionRegsToBody

	.leave
	ret
GrObjPasteInsideControlBreakoutPasteInside	endm

GrObjUIControllerActionCode	ends
