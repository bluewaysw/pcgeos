COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		ellipse.asm

AUTHOR:		Jon Witort

ROUTINES:
	Name			Description
	----			-----------

METHOD HANDLERS:
	Name			Description
	----			-----------
EllipseDrawFG
EllipseDrawSpriteLine
EllipseEvaluatePARENTPosition
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	23 jan 1992	Initial revision


DESCRIPTION:
	This file contains routines to implement the EllipseClass
		

	$Id: ellipse.asm,v 1.1 97/04/04 18:08:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

EllipseClass		;Define the class record

GrObjClassStructures	ends

RectPlusCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		MSG_META_INITIALIZE - EllipseClass

SYNOPSIS:	Initializes the Ellipse instance data

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of EllipseClass

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
	jon	23 jan 1992	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EllipseInitialize method dynamic EllipseClass, MSG_META_INITIALIZE
	.enter

	mov	di,	offset EllipseClass
	CallSuper	MSG_META_INITIALIZE

	GrObjDeref	di,ds,si
	BitSet	ds:[di].GOI_msgOptFlags, \
	GOMOF_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT

	.leave
	ret
EllipseInitialize		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseGetBoundingRectDWFixed
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
EllipseGetBoundingRectDWFixed	method dynamic EllipseClass,
				MSG_GO_GET_BOUNDING_RECTDWFIXED
	.enter

	call	GrObjCheckForOptimizedBoundsCalc
	jc	callSuper

	CallMod	GrObjGetBoundingRectDWFixedFromPath

	;
	; If we get all zeroes back, this is because GrGetPathBoundsDWord
	; drew an ellipse that was very small, and apparently trivially 
	; rejected.   We'll account for this and just return zeroes, without
	; bringing the line width into play, so it can be caught in the caller.
	; (Destroys cx, ax, di, es) 4/19/94 cbh
	;
	push	cx
	mov	cx, size RectDWFixed
	clr	ax
	segmov	es, ss
	lea	di, ss:[bp].BRD_rect
	repz	scasb
	pop	cx
	jz	exit				;all zeroes, exit

	CallMod	GrObjAdjustRectDWFixedByLineWidth
exit:
	.leave
	ret

callSuper:
	;
	; Call to superclass (RectClass) already calls
	; GrObjAdjustRectDWFixedByLineWidth, so do NOT call it here.
	; --JimG 6/21/94
	;
	mov	di,offset EllipseClass
	call	ObjCallSuperNoLock
	jmp	exit


EllipseGetBoundingRectDWFixed		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseDrawSpriteLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line component of the ellipse

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of EllipseClass
	
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
EllipseDrawSpriteLine	method dynamic EllipseClass, MSG_GO_DRAW_SPRITE_LINE
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetSpriteOBJECTDimensions
	call	GrObjCalcCorners
	call	GrDrawEllipse

	.leave
	ret
EllipseDrawSpriteLine		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseDrawSpriteLineHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line component of the ellipse

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of EllipseClass
	
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
EllipseDrawSpriteLineHiRes	method dynamic EllipseClass, 
				MSG_GO_DRAW_SPRITE_LINE_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetSpriteOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	GrDrawEllipse

	.leave
	ret
EllipseDrawSpriteLineHiRes		endm


RectPlusCode	ends

GrObjRequiredInteractiveCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseGetDWFSelectionHandleBoundsForTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	It is not trivial to calculate the selection handle
		bounds for rotated or skewed ellipse.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of EllipseClass

		ss:bp - RectDWFixed
RETURN:		
		ss:bp - RectDWFixed filled
		
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EllipseGetDWFSelectionHandleBoundsForTrivialReject method dynamic EllipseClass, 
		MSG_GO_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	.enter

	mov	di,offset EllipseClass
	call	GrObjGetDWFSelectionHandleBoundsForTrivialRejectProblems

	.leave
	ret
EllipseGetDWFSelectionHandleBoundsForTrivialReject		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseEvaluatePARENTPointForSelection
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
EllipseEvaluatePARENTPointForSelection	method dynamic EllipseClass, 
				MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION

point	local	PointWWFixed

	uses	cx

	.enter

	mov	bx, ss:[bp]				;PARENT pt frame

	;    Convert point to OBJECT and store in stack frame.
	;    If OBJECT coord won't fit in WWF then bail
	;

	push	bp					;local frame
	lea	bp, ss:[point]
	call	GrObjConvertNormalPARENTToWWFOBJECT
	jnc	popBPNotEvenClose

	;
	;	See if the point is on the line. If not, no dice
	;
	call	GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjust
	call	EllipseIsPointWWFixedInside?
	jnc	popBPNotEvenClose

	;
	;	See if point is inside the line. If not, NONE eval.
	;
	negwwf	dxcx
	negwwf	bxax
	call	EllipseIsPointWWFixedInside?
	pop	bp					;local frame
	call	GrObjGlobalCompleteHitDetectionWithAreaAttrCheck

checkSelectionLock:
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_SELECT
	jnz	selectionLock

done:
	.leave
	ret

selectionLock:
	BitSet	dx, EPN_SELECTION_LOCK_SET
	jmp	done

popBPNotEvenClose:
	pop	bp					;bp <- stack frame
	movnf	al,EVALUATE_NONE			
	clr	dx
	jmp	checkSelectionLock

EllipseEvaluatePARENTPointForSelection endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EllipseIsPointWWFixedInside?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si  = Ellipse
		ss:[bp] = PointWWFixed

		dx:cx - WWFixed width to add to bounds before drawing
			(to account for line width, slop factor)
		bx:ax - WWFixed height to add to bounds before drawing
			(to account for line width, slop factor)

Return:		carry set if point lies on rect's line

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EllipseIsPointWWFixedInside?	proc	near
	uses	ax, bx, cx, di
	.enter

	;
	;	Create and OBJECT gstate and draw the desired hit
	;	area to the path
	;
	movnf	di, OBJECT_GSTATE
	call	GrObjCreateGState
	push	cx
	movnf	cx, PCT_REPLACE
	call	GrBeginPath
	pop	cx
	call	EllipseDrawLineAfterAdjust
	call	GrEndPath

	;
	;	Round the point to the nearest pixel and test for
	;	collision.
	;
	rndwwf	ss:[bp].PF_x,ax
	rndwwf	ss:[bp].PF_y,bx
	movnf	cx, RFR_ODD_EVEN
	call	GrTestPointInPath

	pushf
	call	GrDestroyState
	popf
	.leave
	ret
EllipseIsPointWWFixedInside?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseDrawLineAfterAdjust
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line and area foreground components of the ellipse

PASS:		
		*(ds:si) - instance data of object

		dx:cx - WWFixed width to add to bounds before drawing
			(to account for line width, slop factor)
		bx:ax - WWFixed height to add to bounds before drawing
			(to account for line width, slop factor)

		di - gstate

RETURN:		
		nothing
	
DESTROYED:	
		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	5 aug 1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EllipseDrawLineAfterAdjust	proc	near 
	uses	ax,bx,cx,dx,bp,si
	.enter

EC <	call	ECCheckGStateHandle				>
	pushwwf	dxcx					;save width adjust
	pushwwf	bxax					;save height adjust
	CallMod	GrObjGetNormalOBJECTDimensions
	popwwf	sibp					;si:bp <- height adj
	shlwwf	sibp					;expand both edges
	;
	; if the height is negative, we need to negate the adjustment as we
	; want an absolute effect from the adjustment, not a relative one
	;
	tst	bx					;negative?
	jns	heightOkay				;nope
	negwwf	sibp					;negate adjustment
heightOkay:
	addwwf	bxax, sibp				;bx:ax <- adjusted ht.
	popwwf	sibp					;si:bp <- width adj
	shlwwf	sibp					;expand both edges
	tst	dx					;negative
	jns	widthOkay				;nope
	negwwf	sibp					;negate adjustment
widthOkay:
	addwwf	dxcx, sibp				;dx:cx <- adjusted wdth

	call	GrObjCalcCorners
	call	EllipseGrDrawEllipse

	.leave
	ret
EllipseDrawLineAfterAdjust	endp

GrObjRequiredInteractiveCode	ends


GrObjDrawCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseDrawFGArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the area foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of EllipseClass
	
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
EllipseDrawFGArea	method dynamic EllipseClass, MSG_GO_DRAW_FG_AREA,
						MSG_GO_DRAW_CLIP_AREA,
						MSG_GO_DRAW_BG_AREA
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrFillEllipse

	.leave
	ret
EllipseDrawFGArea		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseDrawFGAreaHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the area foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of EllipseClass
	
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
EllipseDrawFGAreaHiRes	method dynamic EllipseClass, MSG_GO_DRAW_FG_AREA_HI_RES,
						MSG_GO_DRAW_CLIP_AREA_HI_RES,
						MSG_GO_DRAW_BG_AREA_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	GrFillEllipse

	.leave
	ret
EllipseDrawFGAreaHiRes		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseDrawFGLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of EllipseClass
	
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
EllipseDrawFGLine	method dynamic EllipseClass, MSG_GO_DRAW_FG_LINE,
						MSG_GO_DRAW_QUICK_VIEW
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	EllipseGrDrawEllipse

	.leave
	ret
EllipseDrawFGLine		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseDrawFGLineHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of EllipseClass
	
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
EllipseDrawFGLineHiRes	method dynamic EllipseClass, MSG_GO_DRAW_FG_LINE_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	EllipseGrDrawEllipse

	.leave
	ret
EllipseDrawFGLineHiRes		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseGrDrawEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grobj replacement for GrDrawEllipse so that we can
		set the line join to beveled everytime

CALLED BY:	INTERNAL UTLIITY

PASS:		same as GrDrawEllipse

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EllipseGrDrawEllipse		proc	far
	uses	si
	.enter
	
	mov	si,ax
	call	GrGetLineJoin
	push	ax
	mov	al,LJ_BEVELED
	call	GrSetLineJoin
	mov	ax,si
	call	GrDrawEllipse
	pop	ax
	call	GrSetLineJoin

	.leave
	ret
EllipseGrDrawEllipse		endp

GrObjDrawCode	ends


