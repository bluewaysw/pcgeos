COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		rect.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
ECRectCheckGrObjLMem		Determines if *ds:si is a RectClass

METHOD HANDLERS:
	Name			
	----			
RectEvaluateParentPoint		
RectCompleteCreate
RectDrawFG
RectDrawSpriteLine
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89	Initial revision


DESCRIPTION:
	This file contains routines to implement the Rect Class
		

	$Id: rect.asm,v 1.1 97/04/04 18:08:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

RectClass		;Define the class record

GrObjClassStructures	ends


GrObjRequiredExtInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectEvaluatePARENTPointForSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GrObj evaluates point to determine if it should be 
		selected by it.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RectClass
		ss:bp - PointDWFixed in PARENT coordinates


RETURN:		
		al - EvaluatePositionRating
		dx - EvaluatePositionNotes

DESTROYED:	
		ah

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RectEvaluatePARENTPointForSelection	method dynamic RectClass, 
				MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION

	.enter

	call	GrObjEvaluatePARENTPointForSelectionWithLineWidth

	.leave
	ret

RectEvaluatePARENTPointForSelection endm

GrObjRequiredExtInteractiveCode	ends


GrObjAlmostRequiredCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectGetBoundingRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the RectDWFixed that bounds the object in
		the dest gstate coordinate system

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RectClass

		ss:bp - BoundingRectData
			destGState
			parentGState

RETURN:		
		ss:bp - BoundingRectData
			rect
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RectGetBoundingRectDWFixed	method dynamic RectClass, 
					MSG_GO_GET_BOUNDING_RECTDWFIXED
	.enter

	mov	di,offset RectClass
	call	ObjCallSuperNoLock

	CallMod	GrObjAdjustRectDWFixedByLineWidth

	.leave
	ret
RectGetBoundingRectDWFixed		endm

GrObjAlmostRequiredCode	ends



RectPlusCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectCompleteCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After rectangle has been interactively created have
		it become selected.
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RectClass

		ss:bp - GrObjMouseData

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RectCompleteCreate	method dynamic RectClass, MSG_GO_COMPLETE_CREATE
	uses	ax,dx
	.enter

	mov	di,offset RectClass
	call	ObjCallSuperNoLock

	movnf	dx, HUM_NOW
	mov	ax,MSG_GO_BECOME_SELECTED
	call	ObjCallInstanceNoLock

	.leave
	ret
RectCompleteCreate		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectGetGrObjClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Rect method for MSG_GO_GET_GROBJ_CLASS

Called by:	MSG_GO_GET_GROBJ_CLASS

Pass:		*ds:si = Rect object
		ds:di = Rect instance

Return:		cx:dx - pointer to RectClass

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RectGetGrObjClass	method dynamic	RectClass, MSG_GO_GET_GROBJ_CLASS
	.enter

	mov	cx, segment RectClass
	mov	dx, offset RectClass

	.leave
	ret
RectGetGrObjClass	endm

RectPlusCode	ends



GrObjDrawCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectDrawFGArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the area foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RectClass
	
		cl - DrawFlags
		bp - GrObjDrawFlags
		dx - gstate to draw through

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RectDrawFGArea	method dynamic RectClass, MSG_GO_DRAW_FG_AREA,
					MSG_GO_DRAW_CLIP_AREA
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrFillRect

	.leave
	ret
RectDrawFGArea		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectDrawFGAreaHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the area foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RectClass
	
		cl - DrawFlags
		bp - GrObjDrawFlags
		dx - gstate to draw through

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RectDrawFGAreaHiRes	method dynamic RectClass, MSG_GO_DRAW_FG_AREA_HI_RES,
						MSG_GO_DRAW_CLIP_AREA_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	GrFillRect

	.leave
	ret
RectDrawFGAreaHiRes		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectDrawFGLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RectClass
	
		cl - DrawFlags
		bp - GrObjDrawFlags
		dx - gstate to draw through

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RectDrawFGLine	method dynamic RectClass, MSG_GO_DRAW_FG_LINE
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrDrawRect

	.leave
	ret
RectDrawFGLine		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectDrawFGLineHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RectClass
	
		cl - DrawFlags
		bp - GrObjDrawFlags
		dx - gstate to draw through

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RectDrawFGLineHiRes	method dynamic RectClass, MSG_GO_DRAW_FG_LINE_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	GrDrawRect

	.leave
	ret
RectDrawFGLineHiRes		endm


GrObjDrawCode	ends




if	ERROR_CHECK

GrObjErrorCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECRectCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an RectClass or one
		of its subclasses
		
CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - object chunk to check
RETURN:		
		none
DESTROYED:	
		nothing - not even flags

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECRectCheckLMemObject		proc	near
ForceRef	ECRectCheckLMemObject
	uses	es,di
	.enter
	pushf	
	mov	di,segment RectClass
	mov	es,di
	mov	di,offset RectClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_A_DRAW_OBJECT	
	popf
	.leave
	ret
ECRectCheckLMemObject		endp
GrObjErrorCode	ends

endif



