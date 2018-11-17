COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		roundedRect.asm

AUTHOR:		Jon Witort

ROUTINES:
	Name			Description
	----			-----------

METHOD HANDLERS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	23 jan 1992	Initial revision


DESCRIPTION:
	This file contains routines to implement the RoundedRectClass
		

	$Id: roundedRect.asm,v 1.1 97/04/04 18:08:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

RoundedRectClass		;Define the class record

GrObjClassStructures	ends


RectPlusCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		MSG_META_INITIALIZE - RoundedRectClass

SYNOPSIS:	Initializes the RoundedRect instance data

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RoundedRectClass

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
RoundedRectInitialize method dynamic RoundedRectClass, MSG_META_INITIALIZE
	.enter

	mov	di,	offset RoundedRectClass
	CallSuper	MSG_META_INITIALIZE

	GrObjDeref	di,ds,si
	mov	ds:[di].RRI_radius, ROUNDED_RECT_RADIUS 
	BitSet	ds:[di].GOI_msgOptFlags, \
	GOMOF_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	.leave
	ret
RoundedRectInitialize		endm





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
RoundedRectGetBoundingRectDWFixed	method dynamic RoundedRectClass, 
					MSG_GO_GET_BOUNDING_RECTDWFIXED
	.enter

	call	GrObjCheckForOptimizedBoundsCalc
	jc	callSuper

	CallMod	GrObjGetBoundingRectDWFixedFromPath

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
	mov	di,offset RoundedRectClass
	call	ObjCallSuperNoLock
	jmp	exit

RoundedRectGetBoundingRectDWFixed		endm












COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectDrawSpriteLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RoundedRectClass
	
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
RoundedRectDrawSpriteLine	method dynamic RoundedRectClass, 
						MSG_GO_DRAW_SPRITE_LINE
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetSpriteOBJECTDimensions
	call	GrObjCalcCorners
	GrObjDeref	si,ds,si
	mov	si,ds:[si].RRI_radius
	call	RoundedRectGrDrawRoundRect

	.leave
	ret
RoundedRectDrawSpriteLine		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectDrawSpriteLineHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RoundedRectClass
	
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
RoundedRectDrawSpriteLineHiRes	method dynamic RoundedRectClass, 
					MSG_GO_DRAW_SPRITE_LINE_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetSpriteOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	RoundedRectCalcIncreasedResolutionRadius
	call	RoundedRectGrDrawRoundRect

	.leave
	ret
RoundedRectDrawSpriteLineHiRes		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectSetRadius
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the radius of the rounded rect

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RoundedRectClass

		cx - radius
RETURN:		
		nothing
	
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
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RoundedRectSetRadius	method dynamic RoundedRectClass, 
						MSG_RR_SET_RADIUS
	.enter

	call	GrObjCanEdit?
	jnc	done

	mov	bp,GOANT_PRE_SPEC_MODIFY
	call	GrObjOptNotifyAction

	call	GrObjBeginGeometryCommon
	call	ObjMarkDirty
	mov	ds:[di].RRI_radius,cx

	call	GrObjEndGeometryCommon

	mov	bp,GOANT_SPEC_MODIFIED
	call	GrObjOptNotifyAction

done:
	.leave
	ret
RoundedRectSetRadius		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectGetRadius
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the radius of the rounded rect

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RoundedRectClass

		cx - radius
RETURN:		
		nothing
	
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
	srs	9/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RoundedRectGetRadius	method dynamic RoundedRectClass, 
						MSG_RR_GET_RADIUS
	.enter

	mov	cx,ds:[di].RRI_radius

	.leave
	ret
RoundedRectGetRadius		endm




RectPlusCode	ends


GrObjRequiredInteractiveCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectGetDWFSelectionHandleBoundsForTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	It is not trivial to calculate the selection handle
		bounds for rotated or skewed rounded rect

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RoundedRectClass

		ss:bp - RectWWFixed
RETURN:		
		ss:bp - RectWWFixed filled
		
	
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
RoundedRectGetDWFSelectionHandleBoundsForTrivialReject	method dynamic \
RoundedRectClass, MSG_GO_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	.enter

	mov	di,offset RoundedRectClass
	call	GrObjGetDWFSelectionHandleBoundsForTrivialRejectProblems

	.leave
	ret
RoundedRectGetDWFSelectionHandleBoundsForTrivialReject		endm

ifdef	PATH_SHIT_DOESNT_WORK_YET


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RectEvaluateParentPoint
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
RoundedRectEvaluateParentPoint	method dynamic RoundedRectClass, 
					MSG_GO_EVALUATE_PARENT_POINT

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
	pop	bp					;local frame
	jnc	notEvenClose

	;
	;	See if the point is on the line. If so, HIGH eval.
	;
	push	bp					;local frame
	lea	bp, ss:[point]
	call	RoundedRectIsPointWWFixedOnLine?
	pop	bp					;local frame
	jc	highNothing

	;
	;	See if point is inside the line. If not, NONE eval.
	;
	push	bp					;local frame
	lea	bp, ss:[point]
	call	RoundedRectIsPointWWFixedInsideArea?
	pop	bp					;local frame
	jnc	notEvenClose

	;    At this time we know that the point is inside the
	;    rectangle and not on the edge. So the evaluation
	;    depends on the attributes of the rectangle
	;
	call	GrObjGetAreaInfoAndMask

	;    If the object is not filled then the user clicked in the
	;    middle of an empty rect. Evaluate low and signal that
	;    object doesn't block out lower objects
	;

	cmp	ah,SDM_0
	je	lowNothing

	;    We know the object is filled, if it is not transparent
	;    then the user has clicked inside an opaque object.
	;    Evaluate high and signal that object blocks lower objects
	;

	test	al, mask AAIR_TRANSPARENT
	jz	highBlock

	;    The object is filled, but transparent. If the user
	;    is kind of goofy, the object may still be filled solid
	;    but just have the transparent bit set. If so, jump
	;    to treat as an opaque object.
	;

	cmp	ah,SDM_100
	je	highBlock

	;    The object is filled with a transparent pattern.
	;

lowNothing:
	;    Point evaluates med and requires no special notes
	;    for the priority list.
	;

	movnf	al,EVALUATE_MEDIUM
nothing:
	clr	dx					;doesn't block out

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

notEvenClose:
	movnf	al,EVALUATE_NONE			
	jmp	short	nothing

highNothing:
	;    Point evaluates high but requires no special command
	;    for the priority list
	;

	movnf	al,EVALUATE_HIGH
	jmp	short nothing

highBlock:
	;    Point evaluates high and object blots out
	;    out any other objects beneath it that might 
	;    be interested in the point.
	;

	movnf	al,EVALUATE_HIGH
	mov	dx,mask EPN_BLOCKS_LOWER_OBJECTS
	jmp	checkSelectionLock


RoundedRectEvaluateParentPoint endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			RoundedRectIsPointWWFixedOnLine?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si  = RoundedRect
		ss:[bp] = PointWWFixed

Return:		carry set if point lies on rect's line

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RoundedRectIsPointWWFixedOnLine?	proc	near
	uses	ax, bx, cx, di
	.enter

	;
	;	Create and OBJECT gstate and draw the desired hit
	;	area to the path
	;
	movnf	di, OBJECT_GSTATE
	call	GrObjCreateGState
	movnf	cx, PCT_REPLACE
	call	GrBeginPath
	call	DrawRoundedRectLine
	call	GrEndPath

	;
	;	Round the point to the nearest pixel and test for
	;	collision.
	;
	mov	ax, ss:[bp].PF_x.WWF_int
	RoundWWFixed	ax, ss:[bp].PF_x.WWF_frac
	mov	bx, ss:[bp].PF_y.WWF_int
	RoundWWFixed	bx, ss:[bp].PF_y.WWF_frac
	movnf	cx, RFR_ODD_EVEN
	call	GrTestPointInPath

	pushf
	call	GrDestroyState
	popf
	.leave
	ret
RoundedRectIsPointWWFixedOnLine?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectIsPointWWFixedInsideArea?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si  = RoundedRect
		ss:[bp] = PointWWFixed

Return:		carry set if point lies within the RoundedRect's area

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 29, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RoundedRectIsPointWWFixedInsideArea?	proc	near
	uses	ax, bx, cx, di
	.enter

	;
	;	Create and OBJECT gstate and draw the desired hit
	;	area to the path
	;
	movnf	di, OBJECT_GSTATE
	call	GrObjCreateGState
	movnf	cx, PCT_REPLACE
	call	GrBeginPath
	call	DrawRoundedRectArea
	call	GrEndPath

	;
	;	Round the point to the nearest pixel and test for
	;	collision.
	;
	mov	ax, ss:[bp].PF_x.WWF_int
	RoundWWFixed	ax, ss:[bp].PF_x.WWF_frac
	mov	bx, ss:[bp].PF_y.WWF_int
	RoundWWFixed	bx, ss:[bp].PF_y.WWF_frac
	movnf	cx, RFR_ODD_EVEN
	call	GrTestPointInPath

	pushf
	call	GrDestroyState
	popf
	.leave
	ret
RoundedRectIsPointWWFixedInsideArea?	endp

endif	;	PATH_SHIT_DOESNT_WORK_YET



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectEvaluatePARENTPointForSelection
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
RoundedRectEvaluatePARENTPointForSelection	method dynamic RoundedRectClass, 
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
	call	RoundedRectIsPointWWFixedInside?
	jnc	popBPNotEvenClose

	;
	;	See if point is inside the line. If not, NONE eval.
	;
	negwwf	dxcx
	negwwf	bxax
	call	RoundedRectIsPointWWFixedInside?
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

RoundedRectEvaluatePARENTPointForSelection endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			RoundedRectIsPointWWFixedInside?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si  = RoundedRect
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
RoundedRectIsPointWWFixedInside?	proc	near
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
	call	RoundedRectDrawLineAfterAdjust
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
RoundedRectIsPointWWFixedInside?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectDrawLineAfterAdjust
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
RoundedRectDrawLineAfterAdjust	proc	near
	class	RoundedRectClass
	uses	ax,bx,cx,dx,bp,si
	.enter

EC <	call	ECCheckGStateHandle				>

	push	si
	pushwwf	dxcx					;save width adjust
	pushwwf	bxax					;save height adjust
	CallMod	GrObjGetNormalOBJECTDimensions
	popwwf	sibp					;si:bp <- height adj
	shlwwf	sibp					;expand both edges
	;
	; if the height is negative, we need to negate the adjustment as we
	; want an absolute effect from the adjustment, not a relative one
	;
	tst	bx					;negative
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
	pop	si

	call	GrObjCalcCorners
	GrObjDeref	si,ds,si
	mov	si,ds:[si].RRI_radius
	call	RoundedRectGrDrawRoundRect

	.leave
	ret
RoundedRectDrawLineAfterAdjust	endp

GrObjRequiredInteractiveCode	ends

GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectDrawFGArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the area foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RoundedRectClass
	
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
RoundedRectDrawFGArea	method dynamic RoundedRectClass, MSG_GO_DRAW_FG_AREA,
						MSG_GO_DRAW_CLIP_AREA,
						MSG_GO_DRAW_BG_AREA
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	GrObjDeref	si, ds, si
	mov	si, ds:[si].RRI_radius
	call	GrFillRoundRect

	.leave
	ret
RoundedRectDrawFGArea		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectDrawFGAreaHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the area foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RoundedRectClass
	
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
RoundedRectDrawFGAreaHiRes	method dynamic RoundedRectClass, 
						MSG_GO_DRAW_FG_AREA_HI_RES,
						MSG_GO_DRAW_CLIP_AREA_HI_RES,
						MSG_GO_DRAW_BG_AREA_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	RoundedRectCalcIncreasedResolutionRadius
	call	GrFillRoundRect

	.leave
	ret
RoundedRectDrawFGAreaHiRes		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectDrawFGLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RoundedRectClass
	
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
RoundedRectDrawFGLine	method dynamic RoundedRectClass, MSG_GO_DRAW_FG_LINE,
						MSG_GO_DRAW_QUICK_VIEW
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	GrObjDeref	si, ds, si
	mov	si, ds:[si].RRI_radius
	call	RoundedRectGrDrawRoundRect

	.leave
	ret
RoundedRectDrawFGLine		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectDrawFGLineHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RoundedRectClass
	
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
RoundedRectDrawFGLineHiRes	method dynamic RoundedRectClass, MSG_GO_DRAW_FG_LINE_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	RoundedRectCalcIncreasedResolutionRadius
	call	RoundedRectGrDrawRoundRect

	.leave
	ret
RoundedRectDrawFGLineHiRes		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectCalcIncreasedResolutionRadius
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine that calculates the radius of
		the rectangle for drawing with increased
		resolutions

CALLED BY:	INTERNAL
		RoundedRectDrawFG
		RoundedRectDrawSpriteLine

PASS:		*ds:si - rounded rect

RETURN:		
		si - increased resolution radius

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
	srs	9/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RoundedRectCalcIncreasedResolutionRadius		proc	far
	class	RoundedRectClass
	uses	cx
	.enter

EC <	call	ECRoundedRectCheckLMemObject			>

	GrObjDeref	si,ds,si
	mov	si,ds:[si].RRI_radius
	mov	cl,INCREASE_RESOLUTION_SHIFT
	shl	si,cl

	.leave
	ret
RoundedRectCalcIncreasedResolutionRadius		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RoundedRectGrDrawRoundRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grobj replacement for GrDrawRoundRect so that we can
		set the line join to beveled everytime

CALLED BY:	INTERNAL UTLIITY

PASS:		same as GrDrawRoundRect

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
RoundedRectGrDrawRoundRect		proc	far
	uses	bp
	.enter
	
	mov	bp,ax
	call	GrGetLineJoin
	push	ax
	mov	al,LJ_BEVELED
	call	GrSetLineJoin
	mov	ax,bp
	call	GrDrawRoundRect
	pop	ax
	call	GrSetLineJoin

	.leave
	ret
RoundedRectGrDrawRoundRect		endp

GrObjDrawCode	ends





if	ERROR_CHECK

GrObjErrorCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECRoundedRectCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an RoundedRectClass or one
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
ECRoundedRectCheckLMemObject		proc	far
ForceRef	ECRectCheckLMemObject
	uses	es,di
	.enter
	pushf	
	mov	di,segment RoundedRectClass
	mov	es,di
	mov	di,offset RoundedRectClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_A_DRAW_OBJECT	
	popf
	.leave
	ret
ECRoundedRectCheckLMemObject		endp
GrObjErrorCode	ends

endif
