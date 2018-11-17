COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiEditSpecialControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjEditSpecialControlClass

	$Id: uiEditSpecialControl.asm,v 1.1 97/04/04 18:05:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjEditSpecialControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjEditSpecialControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjEditSpecialControlClass

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
GrObjEditSpecialControlGetInfo	method dynamic	GrObjEditSpecialControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOESC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjEditSpecialControlGetInfo	endm

GOESC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOESC_IniFileKey,		; GCBI_initFileKey
	GOESC_gcnList,			; GCBI_gcnList
	length GOESC_gcnList,		; GCBI_gcnCount
	GOESC_notifyList,		; GCBI_notificationList
	length GOESC_notifyList,		; GCBI_notificationCount
	GOESCName,			; GCBI_controllerName

	handle GrObjEditSpecialControlUI,	; GCBI_dupBlock
	GOESC_childList,			; GCBI_childList
	length GOESC_childList,		; GCBI_childCount
	GOESC_featuresList,		; GCBI_featuresList
	length GOESC_featuresList,	; GCBI_featuresCount

	GOESC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	handle GrObjEditSpecialToolControlUI,	; GCBI_dupBlock
	GOESC_toolList,			; GCBI_childList
	length GOESC_toolList,		; GCBI_childCount
	GOESC_toolFeaturesList,		; GCBI_featuresList
	length GOESC_toolFeaturesList,	; GCBI_featuresCount

	GOESC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_defaultFeatures
	GOESC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOESC_helpContext	char	"dbGrObjEdSpc", 0

GOESC_IniFileKey	char	"GrObjEditSpecial", 0

GOESC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GOESC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


GOESC_childList	GenControlChildInfo \
	<offset GrObjDuplicateTrigger, mask GOESCF_DUPLICATE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjCloneTrigger, mask GOESCF_CLONE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjPasteInsideTrigger, mask GOESCF_PASTE_INSIDE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjBreakoutPasteInsideTrigger, mask GOESCF_BREAKOUT_PASTE_INSIDE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOESC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjBreakoutPasteInsideTrigger, BreakoutPasteInsideName, 0>,
	<offset GrObjPasteInsideTrigger, PasteInsideName, 0>,
	<offset GrObjCloneTrigger, CloneName, 0>,
	<offset GrObjDuplicateTrigger, DuplicateName, 0>

GOESC_toolList	GenControlChildInfo \
	<offset GrObjDuplicateTool, mask GOESCF_DUPLICATE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjCloneTool, mask GOESCF_CLONE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjPasteInsideTool, mask GOESCF_PASTE_INSIDE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjBreakoutPasteInsideTool, mask GOESCF_BREAKOUT_PASTE_INSIDE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOESC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset GrObjBreakoutPasteInsideTool, BreakoutPasteInsideName, 0>,
	<offset GrObjPasteInsideTool, PasteInsideName, 0>,
	<offset GrObjCloneTool, CloneName, 0>,
	<offset GrObjDuplicateTool, DuplicateName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjEditSpecialControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjEditSpecialControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjEditSpecialControlClass
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
GrObjEditSpecialControlUpdateUI	method dynamic GrObjEditSpecialControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	uses	cx, dx, bp

	.enter

	mov	cx, 1
	mov	ax, mask GOESCF_CLONE
	mov	si, offset GrObjCloneTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	mov	si, offset GrObjCloneTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	mov	ax, mask GOESCF_DUPLICATE
	mov	si, offset GrObjDuplicateTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	mov	si, offset GrObjDuplicateTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	push	bp, cx
	clr	bp
	call	GrObjTestSupportedTransferFormats
	pop	bp, cx
	jc	setPasteInsideStatus

	;
	;  OK, there's no pasteable item on the clipboard, so we'll fool
	;  our utility routine into disabling the paste inside stuff
	;  based on num selected (some impossibly large value)
	;

	mov	cx, 0x7fff
	
setPasteInsideStatus:

	mov	ax, mask GOESCF_PASTE_INSIDE
	mov	si, offset GrObjPasteInsideTrigger
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSet

	mov	si, offset GrObjPasteInsideTool
	call	GrObjControlUpdateToolBasedOnNumSelectedAndToolboxFeatureSet

	mov	ax, mask GOESCF_BREAKOUT_PASTE_INSIDE
	mov	si, offset GrObjBreakoutPasteInsideTrigger
	call	GrObjControlUpdateUIBasedOnPasteInsideSelectedAndFeatureSet

	mov	si, offset GrObjBreakoutPasteInsideTool
	call	GrObjControlUpdateToolBasedOnPasteInsideSelectedAndFeatureSet

	.leave
	ret
GrObjEditSpecialControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjEditSpecialControlClone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjEditSpecialControl method for MSG_GOESC_CLONE

Called by:	

Pass:		*ds:si = GrObjEditSpecialControl object
		ds:di = GrObjEditSpecialControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEditSpecialControlClone	method dynamic	GrObjEditSpecialControlClass, MSG_GOESC_CLONE

	.enter
	mov	ax, MSG_GB_CLONE_SELECTED_GROBJS
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjEditSpecialControlClone	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjEditSpecialControlDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjEditSpecialControl method for MSG_GOESC_DUPLICATE

Called by:	

Pass:		*ds:si = GrObjEditSpecialControl object
		ds:di = GrObjEditSpecialControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEditSpecialControlDuplicate	method dynamic	GrObjEditSpecialControlClass, MSG_GOESC_DUPLICATE

	.enter
	mov	ax, MSG_GB_DUPLICATE_SELECTED_GROBJS
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjEditSpecialControlDuplicate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjEditSpecialControlPasteInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjEditSpecialControl method for MSG_GOESC_PASTE_INSIDE

Called by:	

Pass:		*ds:si = GrObjEditSpecialControl object
		ds:di = GrObjEditSpecialControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEditSpecialControlPasteInside	method dynamic	GrObjEditSpecialControlClass, MSG_GOESC_PASTE_INSIDE

	.enter

	mov	ax, MSG_GB_PASTE_INSIDE
	call	GrObjControlOutputActionRegsToBody

	.leave
	ret
GrObjEditSpecialControlPasteInside	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEditSpecialControlBreakoutPasteInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjEditSpecialControl method for
		MSG_GOESC_BREAKOUT_PASTE_INSIDE

Called by:	

Pass:		*ds:si = GrObjEditSpecialControl object
		ds:di = GrObjEditSpecialControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEditSpecialControlBreakoutPasteInside	method dynamic	GrObjEditSpecialControlClass, MSG_GOESC_BREAKOUT_PASTE_INSIDE

	.enter

	mov	ax, MSG_GB_UNGROUP_SELECTED_GROUPS
	call	GrObjControlOutputActionRegsToBody

	.leave
	ret
GrObjEditSpecialControlBreakoutPasteInside	endm

GrObjUIControllerActionCode	ends
