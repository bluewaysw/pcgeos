COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiHideShowControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjHideShowControlClass

	$Id: uiHideShowControl.asm,v 1.1 97/04/04 18:06:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjHideShowControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjHideShowControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjHideShowControlClass

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
GrObjHideShowControlGetInfo	method dynamic	GrObjHideShowControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOHSC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjHideShowControlGetInfo	endm

GOHSC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOHSC_IniFileKey,		; GCBI_initFileKey
	0,			; GCBI_gcnList
	0,		; GCBI_gcnCount
	0,		; GCBI_notificationList
	0,		; GCBI_notificationCount
	GOHSCName,			; GCBI_controllerName

	handle GrObjHideShowControlUI,	; GCBI_dupBlock
	GOHSC_childList,			; GCBI_childList
	length GOHSC_childList,		; GCBI_childCount
	GOHSC_featuresList,		; GCBI_featuresList
	length GOHSC_featuresList,	; GCBI_featuresCount

	GOHSC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	0,	; GCBI_dupBlock
	0,			; GCBI_childList
	0,		; GCBI_childCount
	0,		; GCBI_featuresList
	0,	; GCBI_featuresCount

	0,	; GCBI_defaultFeatures
	GOHSC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOHSC_helpContext	char	"dbGrObjHide", 0

GOHSC_IniFileKey	char	"GrObjHideShow", 0

;---


GOHSC_childList	GenControlChildInfo \
	<offset GrObjHideTrigger, mask GOHSCF_HIDE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjShowTrigger, mask GOHSCF_SHOW, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOHSC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjShowTrigger, ShowName, 0>,
	<offset GrObjHideTrigger, HideName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif


GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjHideShowControlHide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjHideShowControl method for MSG_GOHSC_HIDE

Called by:	

Pass:		*ds:si = GrObjHideShowControl object
		ds:di = GrObjHideShowControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHideShowControlHide	method dynamic	GrObjHideShowControlClass, MSG_GOHSC_HIDE

	.enter
	mov	ax, MSG_GB_HIDE_UNSELECTED_GROBJS
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjHideShowControlHide	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjShowShowControlShow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjShowShowControl method for MSG_GOHSC_SHOW

Called by:	

Pass:		*ds:si = GrObjShowShowControl object
		ds:di = GrObjShowShowControl instance

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHideShowControlShow	method dynamic	GrObjHideShowControlClass, MSG_GOHSC_SHOW

	.enter
	mov	ax, MSG_GB_SHOW_ALL_GROBJS
	call	GrObjControlOutputActionRegsToBody
	.leave
	ret
GrObjHideShowControlShow	endm

GrObjUIControllerActionCode	ends
