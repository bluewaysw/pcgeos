COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiInstructionControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjInstructionControlClass

	$Id: uiInstructionControl.asm,v 1.1 97/04/04 18:05:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjInstructionControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjInstructionControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjInstructionControlClass

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
GrObjInstructionControlGetInfo	method dynamic	GrObjInstructionControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOIC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjInstructionControlGetInfo	endm

GOIC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOIC_IniFileKey,		; GCBI_initFileKey
	GOIC_gcnList,			; GCBI_gcnList
	length GOIC_gcnList,		; GCBI_gcnCount
	GOIC_notifyList,		; GCBI_notificationList
	length GOIC_notifyList,		; GCBI_notificationCount
	GOICName,			; GCBI_controllerName

	handle GrObjInstructionControlUI,	; GCBI_dupBlock
	GOIC_childList,			; GCBI_childList
	length GOIC_childList,		; GCBI_childCount
	GOIC_featuresList,		; GCBI_featuresList
	length GOIC_featuresList,	; GCBI_featuresCount

	GOIC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	0,	; GCBI_dupBlock
	0,	; GCBI_childList
	0,	; GCBI_childCount
	0,	; GCBI_featuresList
	0,	; GCBI_featuresCount

	0,	; GCBI_defaultFeatures
	GOIC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOIC_helpContext	char	"dbGrObjInstr", 0

GOIC_IniFileKey	char	"GrObjInstruction", 0

GOIC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_INSTRUCTION_FLAGS_CHANGE>

GOIC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_INSTRUCTION_FLAGS_CHANGE>

;---


GOIC_childList	GenControlChildInfo \
	<offset GrObjInstructionAttrBooleanGroup, mask GOICF_DRAW or \
					  mask GOICF_PRINT, 0>,
	<offset GrObjDeleteInstructionsTrigger, mask GOICF_DELETE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjMakeInstructionsEditableTrigger, \
						mask GOICF_MAKE_EDITABLE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjMakeInstructionsUneditableTrigger, \
						mask GOICF_MAKE_UNEDITABLE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOIC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjDeleteInstructionsTrigger, DeleteInstructionsName, 0>,
	<offset GrObjMakeInstructionsUneditableTrigger, MakeInstructionsUneditableName, 0>,
	<offset GrObjMakeInstructionsEditableTrigger, MakeInstructionsEditableName, 0>,
	<offset GrObjPrintInstructionsBoolean, PrintInstructionsName, 0>,
	<offset GrObjDrawInstructionsBoolean, DrawInstructionsName, 0>

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
GrObjInstructionControlUpdateUI	method dynamic GrObjInstructionControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx, dx

	.enter

	test	ss:[bp].GCUUIP_features, mask GOICF_DRAW or mask GOICF_PRINT
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
	
	mov	si, offset GrObjInstructionAttrBooleanGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjInstructionControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInstructionControlDeleteInstructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjInstructionControl method for MSG_GOIC_DELETE_INSTRUCTIONS

Called by:	

Pass:		*ds:si = GrObjInstructionControl object
		ds:di = GrObjInstructionControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInstructionControlDeleteInstructions	method dynamic	GrObjInstructionControlClass, MSG_GOIC_DELETE_INSTRUCTIONS

	.enter
	mov	ax, MSG_GB_DELETE_INSTRUCTIONS
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjInstructionControlDeleteInstructions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInstructionControlMakeInstructionsEditable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjInstructionControl method for MSG_GOIC_MAKE_INSTRUCTIONS_EDITABLE

Called by:	

Pass:		*ds:si = GrObjInstructionControl object
		ds:di = GrObjInstructionControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInstructionControlMakeInstructionsEditable	method dynamic	GrObjInstructionControlClass, MSG_GOIC_MAKE_INSTRUCTIONS_EDITABLE

	.enter
	mov	ax, MSG_GB_MAKE_INSTRUCTIONS_SELECTABLE_AND_EDITABLE
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjInstructionControlMakeInstructionsEditable	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInstructionControlMakeInstructionsUneditable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjInstructionControl method for MSG_GOIC_MAKE_INSTRUCTIONS_UNEDITABLE

Called by:	

Pass:		*ds:si = GrObjInstructionControl object
		ds:di = GrObjInstructionControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInstructionControlMakeInstructionsUneditable	method dynamic	GrObjInstructionControlClass, MSG_GOIC_MAKE_INSTRUCTIONS_UNEDITABLE

	.enter
	mov	ax, MSG_GB_MAKE_INSTRUCTIONS_UNSELECTABLE_AND_UNEDITABLE
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjInstructionControlMakeInstructionsUneditable	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInstructionControlSetInstructionAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjInstructionControl method for MSG_GOIC_SET_INSTRUCTION_ATTRS

Called by:	

Pass:		*ds:si = GrObjInstructionControl object
		ds:di = GrObjInstructionControl instance

		cx - GrObjDrawFlags

Return:		nothing

Destroyed:	ax, bx, di, dx

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInstructionControlSetInstructionAttrs	method dynamic	GrObjInstructionControlClass, MSG_GOIC_SET_INSTRUCTION_ATTRS

	.enter

	call	GetChildBlockAndFeatures
	test	ax, mask GOICF_DRAW or mask GOICF_PRINT
	jz	done
	
	push	si					;save controller chunk
	push	cx					;save selected
	mov	si, offset GrObjInstructionAttrBooleanGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_MODIFIED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage				;ax <- MOD

	pop	cx					;cx <- selected
	pop	si					;*ds:si <- controller

	test	ax, mask GODF_DRAW_INSTRUCTIONS or mask GODF_PRINT_INSTRUCTIONS
	jz	done

	mov	dx,cx

	; Only set bits that are set now in the controller 
	; and have been modified since the last apply
	;

	and	cx,ax					;set in control,modified

	; Only clear bits that are not set in the controller
	; and have been modified since last apply
	;

	not	dx
	and	dx,ax

	;
	;  Pass only valid bits
	;
	mov	ax, mask GrObjDrawFlags
	and	cx, ax
	and	dx, ax
							
	mov	ax, MSG_GB_SET_GROBJ_DRAW_FLAGS
	call	GrObjControlOutputActionRegsToBody

done:
	.leave
	ret
GrObjInstructionControlSetInstructionAttrs	endm

GrObjUIControllerActionCode	ends
