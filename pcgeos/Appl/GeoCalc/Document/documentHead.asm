COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		documentHead.asm<2>
FILE:		documentHead.asm<2>

AUTHOR:		Gene Anderson, Jun  4, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/ 4/92		Initial revision

DESCRIPTION:
	GeoCalc sub-class of GrObjHeadClass

	$Id: documentHead.asm,v 1.1 97/04/04 15:48:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcClassStructures	segment	resource
CHART<	GeoCalcGrObjHeadClass						>
GeoCalcClassStructures	ends

UICode segment resource
if _CHARTS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcGrObjHeadSetCurrentTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subclass to set the current tool (and handle the ssheet)
CALLED BY:	MSG_GH_SET_CURRENT_TOOL

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcGrObjHeadClass
		ax - the message
		cx:dx - fptr to Class of tool
		bp - MSG_GO_GROBJ_SPECIFIC_INITIALIZE data
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcGrObjHeadSetCurrentTool	method dynamic GeoCalcGrObjHeadClass, \
						MSG_GH_SET_CURRENT_TOOL,
					MSG_GH_SET_CURRENT_TOOL_WITH_DATA_BLOCK

	push	cx, dx
	;
	; Let the superclass do its thing
	;
	mov	di, offset GeoCalcGrObjHeadClass
	call	ObjCallSuperNoLock
	pop	ax, dx

;PrintMessage <Nuke this if we ever get a real pen solution>
;  The above PrintMessage commented out cause as of 6/10/93 we had a real
;  pen solution for GeoCalc and this code was included in it. 
;	- Huan
;
;	Set the display group focusable if the current tool is the GrObjText
;	tool. This is to ensure that in pen mode, the display group does
;	not grab the focus away from the edit bar.

	clr	cx
	cmp	ax, segment GrObjTextClass
	jne	10$
	cmp	dx, offset GrObjTextClass
	jne	10$
	mov	cx, TRUE
10$:
	mov	ax, MSG_GEOCALC_DISPLAY_GROUP_SET_FOCUSABLE
	GetResourceHandleNS	GCDisplayGroup, bx
	mov	si, offset GCDisplayGroup
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;
	; Notify all documents of the new tool
	;
	mov	ax, MSG_GEOCALC_DOCUMENT_SET_TARGET_BASED_ON_TOOL
	mov	si, offset GCDocumentGroup	;in the same block!
	call	GenSendToChildren
	ret
GeoCalcGrObjHeadSetCurrentTool	endm
endif

UICode ends
