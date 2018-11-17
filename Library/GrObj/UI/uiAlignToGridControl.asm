COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiAlignToGridControl.asm

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
	Code for the GrObjAlignToGridControlClass

	$Id: uiAlignToGridControl.asm,v 1.1 97/04/04 18:05:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAlignToGridControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjAlignToGridControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjAlignToGridControlClass

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
GrObjAlignToGridControlGetInfo	method dynamic	GrObjAlignToGridControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOATGC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjAlignToGridControlGetInfo	endm

GOATGC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOATGC_IniFileKey,		; GCBI_initFileKey
	GOATGC_gcnList,			; GCBI_gcnList
	length GOATGC_gcnList,		; GCBI_gcnCount
	GOATGC_notifyList,		; GCBI_notificationList
	length GOATGC_notifyList,		; GCBI_notificationCount
	GOATGCName,			; GCBI_controllerName

	handle GrObjAlignToGridControlUI,	; GCBI_dupBlock
	GOATGC_childList,		; GCBI_childList
	length GOATGC_childList,	; GCBI_childCount
	GOATGC_featuresList,		; GCBI_featuresList
	length GOATGC_featuresList,	; GCBI_featuresCount

	GOATGC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	GOATGC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOATGC_helpContext	char	"dbAlign2Grid", 0

GOATGC_IniFileKey	char	"GrObjAlignToGrid", 0

GOATGC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

GOATGC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---

GOATGC_childList	GenControlChildInfo \
	<offset GrObjAlignToGridDirectionGroup, mask GOATGCF_ALIGN_TO_GRID, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOATGC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjAlignToGridDirectionGroup, GOATGCName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAlignToGridControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjAlignToGridControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjAlignToGridControlClass
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
GrObjAlignToGridControlUpdateUI	method GrObjAlignToGridControlClass,
						MSG_GEN_CONTROL_UPDATE_UI

	uses	cx
	.enter

	mov	cx, 1
	mov	ax, mask GOATGCF_ALIGN_TO_GRID
	mov	dx, mask GOL_MOVE
	mov	si, offset GrObjAlignToGridDirectionGroup
	call	GrObjControlUpdateUIBasedOnNumSelectedAndFeatureSetAndLocksClear

	.leave
	ret
GrObjAlignToGridControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjAlignToGridControlAlignToGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAlignToGridControl method for MSG_GOATGC_ALIGN_TO_GRID

Called by:	

Pass:		*ds:si = GrObjAlignToGridControl object
		ds:di = GrObjAlignToGridControl instance
		cl = AlignToGridType

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAlignToGridControlAlignToGrid	method	GrObjAlignToGridControlClass,
					MSG_GOATGC_ALIGN_TO_GRID
	.enter

	mov	ax, MSG_GO_ALIGN_TO_GRID
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjAlignToGridControlAlignToGrid	endm

GrObjUIControllerActionCode	ends
