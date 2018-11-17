COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiObscureAttrControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjObscureAttrControlClass

	$Id: uiObscureAttrControl.asm,v 1.1 97/04/04 18:06:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjObscureAttrControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjObscureAttrControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjObscureAttrControlClass

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
GrObjObscureAttrControlGetInfo	method dynamic	GrObjObscureAttrControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOOAC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjObscureAttrControlGetInfo	endm

GOOAC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOOAC_IniFileKey,		; GCBI_initFileKey
	GOOAC_gcnList,			; GCBI_gcnList
	length GOOAC_gcnList,		; GCBI_gcnCount
	GOOAC_notifyList,		; GCBI_notificationList
	length GOOAC_notifyList,		; GCBI_notificationCount
	GOOACName,			; GCBI_controllerName

	handle GrObjObscureAttrControlUI,	; GCBI_dupBlock
	GOOAC_childList,			; GCBI_childList
	length GOOAC_childList,		; GCBI_childCount
	GOOAC_featuresList,		; GCBI_featuresList
	length GOOAC_featuresList,	; GCBI_featuresCount

	GOOAC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	0,	; GCBI_dupBlock
	0,	; GCBI_childList
	0,	; GCBI_childCount
	0,	; GCBI_featuresList
	0,	; GCBI_featuresCount

	0,	; GCBI_defaultFeatures
	GOOAC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOOAC_helpContext	char	"dbGrObjObAtr", 0

GOOAC_IniFileKey	char	"GrObjObscureAttr", 0

GOOAC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_STARTUP_LOAD_OPTIONS>

GOOAC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GOOAC_childList	GenControlChildInfo \
	<offset GrObjWrapTextList, GOOAC_WRAP_FEATURES, 0>,
	<offset GrObjObscureAttrBooleanGroup, mask GOOACF_INSTRUCTIONS or \
				 GOOAC_INSERT_OR_DELETE_FEATURES, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GOOAC_featuresList	GenControlFeaturesInfo	\
	<offset WrapTightlyItem, WrapTightlyName, 0>,
	<offset WrapAroundRectItem, WrapAroundRectName, 0>,
	<offset WrapInsideItem, WrapInsideName, 0>,
	<offset DontWrapItem, DontWrapName, 0>,
	<offset	InsOrDelDeleteBoolean, InsOrDelDeleteName, 0>,
	<offset	InsOrDelResizeBoolean, InsOrDelResizeName, 0>,
	<offset	InsOrDelMoveBoolean, InsOrDelMoveName, 0>,
	<offset	InstructionBoolean, InstructionName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjObscureAttrControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjObscureAttrControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjObscureAttrControlClass
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
	sean	3/22/99		Added code to enable/disable the controller
				based on if a GrObj is selected or not.
	
------------------------------------------------------------------------------@
GrObjObscureAttrControlUpdateUI	method dynamic GrObjObscureAttrControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx, dx

	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax
	mov	cx, es:[GONSSC_selectionState].GSS_grObjFlags
	mov	dx, es:[GONSSC_grObjFlagsDiffs]
	mov	ax, es:[GONSSC_selectionState].GSS_numSelected	; How many GrObjs selected
	call	MemUnlock

	; Added this routine to enable/disable the controller based on
	; if a GrObj is selected or not.  Sean 3/22/99.
	;
	call	EnableDisableController
	mov	bx, ss:[bp].GCUUIP_childBlock

	push	dx					;save diffs
							
	mov	ax, cx					;flags
	not	ax	
	or	dx, ax

	test	ss:[bp].GCUUIP_features, mask GOOACF_INSTRUCTIONS or GOOAC_INSERT_OR_DELETE_FEATURES
	jz	afterObscure

	mov	si, offset GrObjObscureAttrBooleanGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage

afterObscure:
	pop	dx					;dx <- diffs
	test	ss:[bp].GCUUIP_features, GOOAC_WRAP_FEATURES
	jz	done
	andnf	dx, mask GOAF_WRAP
	andnf	cx, mask GOAF_WRAP
	rept	offset GOAF_WRAP
	shr	cx
	endm

	mov	si, offset GrObjWrapTextList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjObscureAttrControlUpdateUI	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EnableDisableController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable the controller based on if there
		are any GrObj's selected.

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI for GrObjObscureAttrControlClass
	
PASS:		ds:si	= GrObjObjscureAttrControlClass object
		ax	= DayEvent buffer handle
RETURN:		Nothing
DESTROYED:	Nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Enables/Disables the controller

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/22/99		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableDisableController proc near
	uses	ax, bx, cx, dx, di, si, bp, es
	.enter

	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	cx, ax
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	tst	cx
	jz	sendMsg
	mov	ax, MSG_GEN_SET_ENABLED	

sendMsg:	
	mov	bx, segment GrObjObscureAttrControlClass
	mov	es, bx
	call	ObjCallInstanceNoLock
		
	.leave
	ret
		
EnableDisableController endp
		


COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjObscureAttrControlUpdateUI -- MSG_GEN_CONTROL_GENERATE_UI
					for GrObjObscureAttrControlClass

DESCRIPTION:	Initially disable this controller (we'll enable it in
		UPDATE_UI if there's a GrObj selected).

PASS:
	*ds:si - instance data
	es - segment of GrObjObscureAttrControlClass
	ax - MSG_GEN_CONTROL_GENERATE_UI

RETURN: 	nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/22/99		Initial Version

------------------------------------------------------------------------------@
GrObjObscureAttrControlGenerateUI method dynamic GrObjObscureAttrControlClass,
						MSG_GEN_CONTROL_GENERATE_UI
	uses	ax, bx, cx, dx, di, si, bp
	.enter

	; Call the superclass first
	;
	mov	di, offset GrObjObscureAttrControlClass
	call	ObjCallSuperNoLock

	; Initially disable the controller.  The UPDATE_UI message
	; will enable the controller if a GrObj is selected.
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
		
	.leave
	ret
GrObjObscureAttrControlGenerateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjObscureAttrControlSetWrapTextType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjObscureAttrControl method for
		MSG_GOOAC_SET_WRAP_TEXT_TYPE

Called by:	

Pass:		*ds:si = GrObjObscureAttrControl object
		ds:di = GrObjObscureAttrControl instance

		cl - GrObjWrapTextType

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjObscureAttrControlSetWrapTextType	method dynamic	GrObjObscureAttrControlClass, MSG_GOOAC_SET_WRAP_TEXT_TYPE

	.enter


setWrapType::
	mov	ax, MSG_GO_SET_WRAP_TEXT_TYPE
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjObscureAttrControlSetWrapTextType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjObscureAttrControlChangeObscureAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjObscureAttrControl method for
		MSG_GOOAC_CHANGE_OBSCURE_ATTRS

Called by:	

Pass:		*ds:si = GrObjObscureAttrControl object
		ds:di = GrObjObscureAttrControl instance

		cl - selected GrObjFlags

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjObscureAttrControlChangeObscureAttrs	method dynamic	GrObjObscureAttrControlClass, MSG_GOOAC_CHANGE_OBSCURE_ATTRS
	.enter

	call	GetChildBlockAndFeatures
	test	ax, mask GOOACF_INSTRUCTIONS or GOOAC_INSERT_OR_DELETE_FEATURES
	jz	done

	push	si					;save controller chunk
	push	cx					;save selected
	mov	si, offset GrObjObscureAttrBooleanGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_MODIFIED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage				;ax <- MOD

	mov	bp, ax					;bp <- MOD
	pop	cx					;cx <- selected
	pop	si					;*ds:si <- controller

	test	bp, mask GOAF_INSTRUCTION
	jz	checkInsDelMove

	mov	ax, MSG_GO_MAKE_INSTRUCTION
	test	cl, mask GOAF_INSTRUCTION
	jnz	makeInstruction
	mov	ax, MSG_GO_MAKE_NOT_INSTRUCTION
makeInstruction:
	call	GrObjControlOutputActionRegsToGrObjs
	
checkInsDelMove:
	test	bp, mask GOAF_INSERT_DELETE_MOVE_ALLOWED
	jz	checkInsDelResize

	push	cx
	andnf	cx, mask GOAF_INSERT_DELETE_MOVE_ALLOWED
	mov	ax, MSG_GO_SET_INSERT_DELETE_MOVE_ALLOWED
	call	GrObjControlOutputActionRegsToGrObjs
	pop	cx

checkInsDelResize:
	test	bp, mask GOAF_INSERT_DELETE_RESIZE_ALLOWED
	jz	checkInsDelDelete

	push	cx
	andnf	cx, mask GOAF_INSERT_DELETE_RESIZE_ALLOWED
	mov	ax, MSG_GO_SET_INSERT_DELETE_RESIZE_ALLOWED
	call	GrObjControlOutputActionRegsToGrObjs
	pop	cx

checkInsDelDelete:
	test	bp, mask GOAF_INSERT_DELETE_DELETE_ALLOWED
	jz	done

	andnf	cx, mask GOAF_INSERT_DELETE_DELETE_ALLOWED
	mov	ax, MSG_GO_SET_INSERT_DELETE_DELETE_ALLOWED
	call	GrObjControlOutputActionRegsToGrObjs

done:
	.leave
	ret
GrObjObscureAttrControlChangeObscureAttrs	endm

GrObjUIControllerActionCode	ends
