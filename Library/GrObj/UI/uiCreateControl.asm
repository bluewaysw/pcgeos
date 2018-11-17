COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiCreateControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	28 sept 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjCreateControlClass

	$Id: uiCreateControl.asm,v 1.1 97/04/04 18:06:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjCreateControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjCreateControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjCreateControlClass

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
GrObjCreateControlGetInfo	method dynamic	GrObjCreateControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GrObjCreateControl_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjCreateControlGetInfo	endm

GrObjCreateControl_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GrObjCreateControl_IniFileKey,		; GCBI_initFileKey
	0,			; GCBI_gcnList
	0,		; GCBI_gcnCount
	0,		; GCBI_notificationList
	0,		; GCBI_notificationCount
	GrObjCreateControlName,			; GCBI_controllerName

	handle GrObjCreateControlUI,	; GCBI_dupBlock
	GrObjCreateControl_childList,			; GCBI_childList
	length GrObjCreateControl_childList,		; GCBI_childCount
	GrObjCreateControl_featuresList,		; GCBI_featuresList
	length GrObjCreateControl_featuresList,	; GCBI_featuresCount

	GROBJ_CREATE_CONTROL_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	handle GrObjCreateToolControlUI,	; GCBI_dupBlock
	GrObjCreateControl_toolList,			; GCBI_childList
	length GrObjCreateControl_toolList,		; GCBI_childCount
	GrObjCreateControl_toolFeaturesList,		; GCBI_featuresList
	length GrObjCreateControl_toolFeaturesList,	; GCBI_featuresCount

	GROBJ_CREATE_CONTROL_DEFAULT_TOOLBOX_FEATURES,	; GCBI_defaultFeatures
	GrObjCreateControl_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GrObjCreateControl_helpContext	char	"dbGrObjCreat", 0

GrObjCreateControl_IniFileKey	char	"GrObjCreate", 0

;---


GrObjCreateControl_childList	GenControlChildInfo \
<offset GrObjCreateRectangleTrigger, mask GOCCF_RECTANGLE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateEllipseTrigger, mask GOCCF_ELLIPSE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateLineTrigger, mask GOCCF_LINE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateRoundedRectTrigger, mask GOCCF_ROUNDED_RECTANGLE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateArcTrigger, mask GOCCF_ARC, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateTriangleTrigger, mask GOCCF_TRIANGLE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateHexagonTrigger, mask GOCCF_HEXAGON, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateOctogonTrigger, mask GOCCF_OCTOGON, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateFiveStarTrigger, mask GOCCF_FIVE_POINTED_STAR, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateEightStarTrigger, mask GOCCF_EIGHT_POINTED_STAR, mask GCCF_IS_DIRECTLY_A_FEATURE>

GrObjCreateControl_featuresList	GenControlFeaturesInfo	\
<offset GrObjCreateEightStarTrigger, CreateEightStarName, 0>,
<offset GrObjCreateFiveStarTrigger, CreateFiveStarName, 0>,
<offset GrObjCreateOctogonTrigger, CreateOctogonName, 0>,
<offset GrObjCreateHexagonTrigger, CreateHexagonName, 0>,
<offset GrObjCreateTriangleTrigger, CreateTriangleName, 0>,
<offset GrObjCreateArcTrigger, CreateArcName, 0>,
<offset GrObjCreateRoundedRectTrigger, CreateRoundedRectName, 0>,
<offset GrObjCreateLineTrigger, CreateLineName, 0>,
<offset GrObjCreateEllipseTrigger, CreateEllipseName, 0>,
<offset GrObjCreateRectangleTrigger, CreateRectangleName, 0>

GrObjCreateControl_toolList	GenControlChildInfo \
<offset GrObjCreateRectangleTool, mask GOCCF_RECTANGLE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateEllipseTool, mask GOCCF_ELLIPSE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateLineTool, mask GOCCF_LINE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateRoundedRectTool, mask GOCCF_ROUNDED_RECTANGLE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateArcTool, mask GOCCF_ARC, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateTriangleTool, mask GOCCF_TRIANGLE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateHexagonTool, mask GOCCF_HEXAGON, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateOctogonTool, mask GOCCF_OCTOGON, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateFiveStarTool, mask GOCCF_FIVE_POINTED_STAR, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset GrObjCreateEightStarTool, mask GOCCF_EIGHT_POINTED_STAR, mask GCCF_IS_DIRECTLY_A_FEATURE>

GrObjCreateControl_toolFeaturesList	GenControlFeaturesInfo	\
<offset GrObjCreateEightStarTool, CreateEightStarName, 0>,
<offset GrObjCreateFiveStarTool, CreateFiveStarName, 0>,
<offset GrObjCreateOctogonTool, CreateOctogonName, 0>,
<offset GrObjCreateHexagonTool, CreateHexagonName, 0>,
<offset GrObjCreateTriangleTool, CreateTriangleName, 0>,
<offset GrObjCreateArcTool, CreateArcName, 0>,
<offset GrObjCreateRoundedRectTool, CreateRoundedRectName, 0>,
<offset GrObjCreateLineTool, CreateLineName, 0>,
<offset GrObjCreateEllipseTool, CreateEllipseName, 0>,
<offset GrObjCreateRectangleTool, CreateRectangleName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCreateControlCreateGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjCreateControl method for MSG_GOCC_CREATE_GROBJ

Called by:	

Pass:		*ds:si = GrObjCreateControl object
		ds:di = GrObjCreateControl instance

		cx:dx - segment:offset of grobj class to create (eg. RectClass)

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCreateControlCreateGrObj	method dynamic	GrObjCreateControlClass,
				MSG_GOCC_CREATE_GROBJ
	.enter

	sub	sp, size GrObjBodyCreateGrObjParams
	mov	bp, sp

	movdw	ss:[bp].GBCGP_class, cxdx
	mov	ss:[bp].GBCGP_width.WWF_int, 100
	mov	ss:[bp].GBCGP_width.WWF_frac, 0
	mov	ss:[bp].GBCGP_height.WWF_int, 100
	mov	ss:[bp].GBCGP_height.WWF_frac, 0

	mov	dx, size GrObjBodyCreateGrObjParams
	mov	ax, MSG_GB_CREATE_GROBJ
	call	GrObjControlOutputActionStackToBody

	add	sp, size GrObjBodyCreateGrObjParams

	.leave
	ret
GrObjCreateControlCreateGrObj	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCreateControlCreatePolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjCreateControl method for MSG_GOCC_CREATE_POLYGON

Called by:	

Pass:		*ds:si = GrObjCreateControl object
		ds:di = GrObjCreateControl instance

		cx - # of polygon sides

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCreateControlCreatePolygon	method dynamic	GrObjCreateControlClass,
				MSG_GOCC_CREATE_POLYGON
	.enter

	mov	bp, cx					;cx <- # sides
	mov	cx, 100
	mov	dx, cx
	mov	ax, MSG_GB_CREATE_POLYGON
	call	GrObjControlOutputActionRegsToBody

	.leave
	ret
GrObjCreateControlCreatePolygon	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCreateControlCreateStar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjCreateControl method for MSG_GOCC_CREATE_STAR

Called by:	

Pass:		*ds:si = GrObjCreateControl object
		ds:di = GrObjCreateControl instance

		cx - # of star points

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCreateControlCreateStar	method dynamic	GrObjCreateControlClass,
				MSG_GOCC_CREATE_STAR
	.enter

	sub	sp, size SplineMakeStarParams
	mov	bp, sp

	mov	ss:[bp].SMSP_outerRadius.P_y, 50
	mov	ss:[bp].SMSP_outerRadius.P_x, 50
	mov	ss:[bp].SMSP_innerRadius.P_y, 19
	mov	ss:[bp].SMSP_innerRadius.P_x, 19
	mov	ss:[bp].SMSP_starPoints, cx

	mov	dx, size SplineMakeStarParams
	mov	ax, MSG_GB_CREATE_STAR
	call	GrObjControlOutputActionStackToBody

	add	sp, size SplineMakeStarParams

	.leave
	ret
GrObjCreateControlCreateStar	endm

GrObjUIControllerActionCode	ends
