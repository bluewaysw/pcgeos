COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiMoveInsideControl.asm

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
	Code for the GrObjMoveInsideControlClass

	$Id: uiMoveInsideControl.asm,v 1.1 97/04/04 18:05:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjMoveInsideControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjMoveInsideControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjMoveInsideControlClass

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
GrObjMoveInsideControlGetInfo	method dynamic	GrObjMoveInsideControlClass,
					MSG_GEN_CONTROL_GET_INFO

	pushdw	cxdx
	mov	di, offset GrObjMoveInsideControlClass
	call	ObjCallSuperNoLock

	; now fill in a few things

	popdw	esdi
	mov	si, offset GOMIC_newFields
	mov	cx, length GOMIC_newFields
	call	CopyFieldsToBuildInfo
	ret
GrObjMoveInsideControlGetInfo	endm

GOMIC_newFields	GC_NewField	\
 <offset GCBI_initFileKey, size GCBI_initFileKey,
				<GCD_dword GOMIC_IniFileKey>>,
 <offset GCBI_controllerName, size GCBI_controllerName,
				<GCD_optr GOMICName>>,
 <offset GCBI_features, size GCBI_features, <GCD_dword \
				(mask GrObjNudgeControlFeatures and not \
					mask GONCF_CUSTOM_MOVE)>>,
 <offset GCBI_helpContext, size GCBI_helpContext,
				<GCD_dword GOMIC_helpContext>>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOMIC_helpContext	char	"dbGrObjNujIn", 0
GOMIC_IniFileKey	char	"GrObjMoveInside", 0

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

;---

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjMoveInsideControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjMoveInsideControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjMoveInsideControlClass
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
GrObjMoveInsideControlUpdateUI	method GrObjMoveInsideControlClass,
						MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	ax, mask GONCF_NUDGE_LEFT
	mov	si, offset GrObjNudgeLeftTrigger
	call	GrObjControlUpdateUIBasedOnPasteInsideSelectedAndFeatureSet

	mov	ax, mask GONCF_NUDGE_RIGHT
	mov	si, offset GrObjNudgeRightTrigger
	call	GrObjControlUpdateUIBasedOnPasteInsideSelectedAndFeatureSet

	mov	ax, mask GONCF_NUDGE_UP
	mov	si, offset GrObjNudgeUpTrigger
	call	GrObjControlUpdateUIBasedOnPasteInsideSelectedAndFeatureSet

	mov	ax, mask GONCF_NUDGE_DOWN
	mov	si, offset GrObjNudgeDownTrigger
	call	GrObjControlUpdateUIBasedOnPasteInsideSelectedAndFeatureSet

	.leave
	ret
GrObjMoveInsideControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjMoveInsideControlNudge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjMoveInsideControl method for MSG_GONC_NUDGE

Called by:	

Pass:		*ds:si = GrObjMoveInsideControl object
		ds:di = GrObjMoveInsideControl instance

		cx - x MoveInside
		dx - y MoveInside

Return:		nothing

Destroyed:	bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMoveInsideControlNudge	method	GrObjMoveInsideControlClass,
					MSG_GONC_NUDGE
	.enter

	mov	ax, MSG_GO_NUDGE_INSIDE
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjMoveInsideControlNudge	endm

GrObjUIControllerActionCode	ends
