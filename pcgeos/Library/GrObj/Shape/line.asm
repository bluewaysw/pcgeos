COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Shape
FILE:		line.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
INT LineDrawSelectedHandles	
INT LineGenerateFourPointDWFixeds		
INT ECLineCheckGrObjLMem	


METHOD HANDLERS:
	Name			
	----			
LineGetBoundingRectDWFixed
LineClear			
LineHandleHitDetection		
LineInvertHandles		
LineCompleteCreate
LineDrawFG
LineDrawSpriteLine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
	This file contains routines to implement the Line Class
		

	$Id: line.asm,v 1.1 97/04/04 18:08:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjClassStructures	segment resource


	;Define the class record

LineClass

GrObjClassStructures	ends


RectPlusCode	segment resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineGetBoundingRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the RectDWFixed that bounds the object in
		the dest gstate coordinate system

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass

		ss:bp - BoundingRectData
			destGState
			parentGState

RETURN:		
		ss:bp - BoudingRectData
			rect
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineGetBoundingRectDWFixed	method dynamic LineClass, 
						MSG_GO_GET_BOUNDING_RECTDWFIXED
	class	LineClass
	uses	dx,cx
	.enter

	mov	di,ss:[bp].BRD_parentGState
	call	GrSaveTransform
	call	GrObjApplyNormalTransform

	;    Set bounding rect to hold line ends
	;

	CallMod	GrObjGetNormalOBJECTDimensions
	sar	dx,1				;width/2 int
	rcr	cx,1				;width/2 frac
	sar	bx,1				;height/2 int
	rcr	ax,1				;height/2 frac
	call	GrObjInitBoundingRectDataByPointWWFixed
	negwwf	dxcx
	negwwf	bxax
	call	GrObjExpandBoundingRectDataByPointWWFixed

	;    Check if we need to include arrowhead ends
	;

	call	GrObjGetArrowheadInfo
	and	al, mask GOLAIR_ARROWHEAD_ON_START or \
			mask GOLAIR_ARROWHEAD_ON_END

	jnz	arrowheads

adjustForLine:
	CallMod	GrObjAdjustRectDWFixedByLineWidth

	mov	di,ss:[bp].BRD_parentGState
	call	GrRestoreTransform

	.leave
	ret

arrowheads:
	;    Yes we are adjusting the bounding rect by the line width
	;    a second time. This helps compensate for some of the
	;    miter joins sticking really far out.
	;

	call	LineAdjustRectDWFixedByLineWidthForArrowheads

	test	al,mask GOLAIR_ARROWHEAD_ON_START
	jz	onEnd

	push	ax					;flags
	call	GrObjGetNormalOBJECTDimensions
	call	GrSaveTransform			;CalcCorners changes xform
	call	GrObjCalcCorners
	call	GrObjGetArrowheadPoints
	push	ax,bx					;2nd point
	mov	bx,dx					;y
	mov	dx,cx					;x
	clr	ax,cx					;fracs
	call	GrObjExpandBoundingRectDataByPointWWFixed
	pop	dx,bx					;2nd point	
	call	GrObjExpandBoundingRectDataByPointWWFixed
	call	GrRestoreTransform
	pop	ax					;flags
	test	al,mask GOLAIR_ARROWHEAD_ON_END
	jz	adjustForLine

onEnd:
	call	GrObjGetNormalOBJECTDimensions
	call	GrSaveTransform			;CalcCorners changes xform
	call	GrObjCalcCorners
	xchg	ax,cx					;end x, start x
	xchg	bx,dx					;end y, start y
	call	GrObjGetArrowheadPoints
	push	ax,bx					;2nd point
	mov	bx,dx					;y
	mov	dx,cx					;x
	clr	ax,cx					;fracs
	call	GrObjExpandBoundingRectDataByPointWWFixed
	pop	dx,bx					;2nd point	
	call	GrObjExpandBoundingRectDataByPointWWFixed
	call	GrRestoreTransform
	jmp	adjustForLine

LineGetBoundingRectDWFixed		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineAdjustRectDWFixedByLineWidthForArrowheads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand RectDWFixed by line with to hopefully include the
		miter join on fat lines with arrowheads.

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object instance data

		ss:bp - RectDWFixed

RETURN:		
		ss:bp - RectDWFixed 

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineAdjustRectDWFixedByLineWidthForArrowheads		proc	near
	uses	cx,dx,di,si,ds
	.enter

	;   Get line width
	;

	push	bp					;stack frame
	call	GrObjGetLineWidth
	mov	cx,bp					;line width frac
	pop	bp					;stack frame
	mov	dx,di					;line width int
	clr	di					;line width high int

	;    Expand rect by line width
	;

	segmov	ds,ss
	mov	si,bp
	CallMod	GrObjGlobalExpandRectDWFixedByDWFixed

	.leave
	ret
LineAdjustRectDWFixedByLineWidthForArrowheads		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineDrawSpriteLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line component of the line with the spriteTransform

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass
	
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
LineDrawSpriteLine	method dynamic LineClass, MSG_GO_DRAW_SPRITE_LINE
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetSpriteOBJECTDimensions
	call	GrObjCalcCorners
	call	GrDrawLine

	.leave
	ret
LineDrawSpriteLine		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineDrawNormalSpriteLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line component of the line with the normalTransform

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass
	
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
LineDrawNormalSpriteLine method dynamic LineClass, 
					MSG_GO_DRAW_NORMAL_SPRITE_LINE
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrDrawLine

	.leave
	ret
LineDrawNormalSpriteLine		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineDrawSpriteLineHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line component of the line

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass
	
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
LineDrawSpriteLineHiRes	method dynamic LineClass, MSG_GO_DRAW_SPRITE_LINE_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetSpriteOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	GrDrawLine

	.leave
	ret
LineDrawSpriteLineHiRes		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineCompleteCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After line has been interactively created have
		it become selected.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass

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
LineCompleteCreate	method dynamic LineClass, MSG_GO_COMPLETE_CREATE
	uses	ax,cx
	.enter

	mov	di,offset LineClass
	call	ObjCallSuperNoLock

	movnf	dx, HUM_NOW
	mov	ax,MSG_GO_BECOME_SELECTED
	call	ObjCallInstanceNoLock

	.leave
	ret
LineCompleteCreate		endm

RectPlusCode	ends


GrObjRequiredInteractiveCode	segment resource


PointToLine	struct
	PTL_lineStart		PointWWFixed
	PTL_lineEnd		PointWWFixed
	PTL_otherPoint		PointWWFixed
	PTL_slope		WWFixed
	PTL_slopeSquared	WWFixed
	PTL_pointMovedToOrigin	PointWWFixed
	PTL_newPoint		PointWWFixed
PointToLine	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineEvaluatePARENTPointForSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	 Line evaluates point to determine if it should be 
		selected by it.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass
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
LineEvaluatePARENTPointForSelection	method dynamic LineClass, 
			MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION
hitRect		local	RectWWFixed
pointToLine	local	PointToLine
closest		local	PointWWFixed
newOrigin	local	PointDWFixed
temp		local	PointDWFixed

	uses	cx,bp
	.enter


	;    Convert line ends -w/2,-h/2 and w/2,h/2 into PointDWFixed
	;    and then into PARENT coords
	;

	call	GrObjGetNormalOBJECTDimensions
	sarwwf	dxcx
	mov	di,ax					;y frac
	mov_tr	ax,dx
	cwd						;x int high
	movdwf	temp.PDF_x,dxaxcx
	negdwf	dxaxcx
	movdwf	newOrigin.PDF_x,dxaxcx
	mov	ax,bx					;y int low
	sarwwf	axdi
	cwd						;y int high
	movdwf	temp.PDF_y,dxaxdi
	negdwf	dxaxdi
	movdwf	newOrigin.PDF_y,dxaxdi

	push	bp
	lea	bp,newOrigin
	call	GrObjConvertNormalOBJECTToPARENT
	pop	bp
	
	push	bp
	lea	bp,temp
	call	GrObjConvertNormalOBJECTToPARENT
	pop	bp

	;    Store points in the PointToLine structure relative to 
	;    -w/2,-h/2 converted into PARENT. This allows us to
	;    do calcs in WWFixed instead of DWFixed.
	;

	subdwf	temp.PDF_x,newOrigin.PDF_x,ax
	subdwf	temp.PDF_y,newOrigin.PDF_y,ax
	mov	ax,temp.PDF_x.DWF_int.low
	mov	pointToLine.PTL_lineEnd.PF_x.WWF_int,ax
	mov	ax,temp.PDF_x.DWF_frac
	mov	pointToLine.PTL_lineEnd.PF_x.WWF_frac,ax
	mov	ax,temp.PDF_y.DWF_int.low
	mov	pointToLine.PTL_lineEnd.PF_y.WWF_int,ax
	mov	ax,temp.PDF_y.DWF_frac
	mov	pointToLine.PTL_lineEnd.PF_y.WWF_frac,ax

	clr	ax,dx
	movwwf	pointToLine.PTL_lineStart.PF_x,dxax
	movwwf	pointToLine.PTL_lineStart.PF_y,dxax

	;    If the passed PARENT point cannot be converted to a WWFixed
	;    relative to the newOrigin, then the point cannot be on
	;    the line, so bail.
	;

	mov	bx,ss:[bp]				;orig bp PARENT pt frame
	movdwf	diaxcx,ss:[bx].PDF_y
	subdwf	diaxcx,newOrigin.PDF_y
	cwd
	cmp	di,dx
	jne	notEvenClose
	movwwf	pointToLine.PTL_otherPoint.PF_y,axcx

	movdwf	diaxcx,ss:[bx].PDF_x
	subdwf	diaxcx,newOrigin.PDF_x
	cwd
	cmp	di,dx
	jne	notEvenClose
	movwwf	pointToLine.PTL_otherPoint.PF_x,axcx

	push	bp					;local frame
	lea	bp, pointToLine
	call	CalcClosestPointOnLineSegment
	pop	bp					;local frame

	movwwf	closest.PF_x,dxcx
	movwwf	closest.PF_y,bxax
	
	call	GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjustInPARENT

	;    Init hitRect to the point to evaluate and add in
	;    adjust factors.
	;
	
	push	ds,si				;object ptr
	mov	di,ss
	mov	ds,di
	mov	es,di
	lea	si,ss:[hitRect]
	lea	di,ss:[pointToLine.PTL_otherPoint]
	call	GrObjGlobalInitRectWWFixedWithPointWWFixed
	call	GrObjGlobalAsymetricExpandRectWWFixedByWWFixed

	;    If the closest point on the line is within the 
	;    rectangle surrounding the passed point then 
	;    consider it a hit.
	;

	lea	di,ss:[closest]
	call	GrObjGlobalIsPointWWFixedInsideRectWWFixed?
	jc	hit


notEvenClose:
	mov	al,EVALUATE_NONE			
	clr	dx				;EvaluatePositionNotes
setPositionNotes:
	pop	ds,si				;object ptr
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_SELECT
	jnz	selectionLock

done:

	.leave
	ret

selectionLock:
	BitSet	dx, EPN_SELECTION_LOCK_SET
	jmp	done

hit:
	mov	al, EVALUATE_HIGH

	;   Because we haven't added code to cycle through
	;   the selection list, make the processing of
	;   objects stop on all high objects.
	;

	mov	dx,mask EPN_BLOCKS_LOWER_OBJECTS

	jmp	setPositionNotes

LineEvaluatePARENTPointForSelection endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcClosestPointOnLineSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calulates the point on a line segment that
		is closest to the passed point

CALLED BY:	INTERNAL
		CheckForPointSelectingLine

PASS:		
		ss:bp - PointToLine
			PTL_lineStart
			PTL_lineEnd
			PTL_otherPoint

RETURN:		
		dx:cx	- WWFixed x
		bx:ax	- WWFixed y

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The line segment runs from Xa,Ya to Xb,Yb
	Xp,Yp is the point in question
	Xn,Yn is the point we are calculating
	M = ( Ya - Yb )/( Xa - Xb)

	These are the point slope forms of the passed line segment and
	the line that passes through our point and is perpendicular to
	the line segment.  

	Y - Ya = M ( X - Xa )
	Y - Yp = -1/M ( X - Xp)

	To calculate the intersection, we set the equations equal, 
	subtract them and solve for x. The calculations are much simplier 
	if the line segment goes from 0,0 to some X,Y. So we will subtract
	Xa,Ya from all the coords before starting the calculations and
	then add Xa,Ya to the results.

	Xn = ( Xp + ( Yp * M ) ) / (M^2 + 1)
	Yn = M * Xn 

	The equation for Xn is a problem to calculate when M is large.
	But if M is large then -1/M is small. So we simply reverse the
	way we solve the equations. M' = -1/M

	Xn = ( Xa + ( Ya * M' ) ) / (M'^2 + 1)
	Yn = M' * Xn 

	The calculated point may not actually be between Xa,Ya and Xb,Yb.
	If not then returned point will be either Xa,Ya or Xb,Yb depending
	on which is close to Xn,Yn



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcClosestPointOnLineSegment		proc	near
	uses	di,si
	.enter

	call	CalcSlope
	call	CalcXY

	add	cx,ss:[bp].PTL_pointMovedToOrigin.PF_x.WWF_frac
	adc	dx,ss:[bp].PTL_pointMovedToOrigin.PF_x.WWF_int
	add	ax,ss:[bp].PTL_pointMovedToOrigin.PF_y.WWF_frac
	adc	bx,ss:[bp].PTL_pointMovedToOrigin.PF_y.WWF_int

	call	MakeSurePointIsOnLineSegment

	.leave
	ret

CalcClosestPointOnLineSegment		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeSurePointIsOnLineSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the point is not on the line segment move the
		point to the closest end point.

CALLED BY:	INTERNAL
		CalcClosestPointOnLineSegment

PASS:		
		ss:bp - PointToLine
		dxcx,bxax - WWFixed point that is on line but not
		necessarily on line segment
RETURN:		
		dxcx,bxax - point on line
			may be same as passed or may be one of
			the end points of line
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
	srs	12/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeSurePointIsOnLineSegment		proc	near
	uses	di,si
	.enter

	;    Use the larger delta for the check
	;

	mov	di,ss:[bp].PTL_lineStart.PF_x.WWF_int
	sub	di,ss:[bp].PTL_lineEnd.PF_x.WWF_int
	tst	di
	jns	10$
	neg	di
10$:	
	mov	si,ss:[bp].PTL_lineStart.PF_y.WWF_int
	sub	si,ss:[bp].PTL_lineEnd.PF_y.WWF_int
	tst	si
	jns	20$
	neg	si
20$:
	cmp	di,si
	jl	useY

	mov	di, offset PF_x
	call	MakeSurePointIsOnLineSegmentLow
done:
	.leave
	ret

useY:
	xchgwwf		bxax,dxcx
	mov	di, offset PF_y
	call	MakeSurePointIsOnLineSegmentLow
	jnc	done
	xchgwwf		bxax,dxcx
	jmp	done

MakeSurePointIsOnLineSegment		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeSurePointIsOnLineSegmentLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the x or y value is not between then x or y of the endpoints
		then move it to the closest endpoint

CALLED BY:	INTERNAL
		MakeSurePointIsOnLineSegment

PASS:		
		ss:bp - PointToLine
		dxcx - X or Y of WWFixed point that is on line but not
		di - offset of PF_x or PF_y
		necessarily on line segment
RETURN:		
		if carry set
			dxcx - as passed
		if carry clear
			dxcx,bxax - PointWWFixed of one of endpoints
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
	srs	12/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeSurePointIsOnLineSegmentLow		proc	near
	.enter

	;    Don't destroy these if nothing changes
	;

	push	dx,cx,bx,ax

	;    Make sure that point is actually on line segment
	;    If value is between lineStart and lineEnd
	;    the the point is on the line segment. If not
	;    then set the point to the closest of lineStart
	;    and lineEnd
	;

	movwwf	bxax,dxcx
	subwwf	dxcx,({WWFixed}(ss:[bp][di].PTL_lineStart))
	subwwf	bxax,({WWFixed}(ss:[bp][di].PTL_lineEnd))
	js	negativeDeltaToEnd

	;    The delta from the point to the lineEnd is positive
	;    so the delta from the point to the lineStart must
	;    be negative or the point is not on the line segment
	;
	
	tst	dx				;sign of delta to start
	jns	notOnSegment

popOriginals:
	pop	dx,cx,bx,ax
	stc
done:
	.leave
	ret

negativeDeltaToEnd:
	;    The delta from the point to the lineEnd is negative
	;    so the delta from the point to the lineStart must
	;    be positive or the point is not on the line segment
	;    However, in the event of failure, I want both deltas
	;    to be positive for the comparison. So I will negate
	;    both deltas and then check for lineStart delta
	;    being negative.
	;
	
	negwwf	bxax			;make delta to end positive
	negwwf	dxcx			;delta to start
	tst	dx			;sign of delta to start
	js	popOriginals

notOnSegment:
	;    The calculated point is not on the line segment.
	;    The absolute values of the delta to lineStart
	;    and lineEnd are in dxcx and bxax respectively
	;    Set the calculated point to the line point with
	;    the smaller delta
	;

	jbWWF	dx,cx,bx,ax,setToLineStart

	add	sp,8				;clear originals from stack
	movwwf	dxcx,ss:[bp].PTL_lineEnd.PF_x
	movwwf	bxax,ss:[bp].PTL_lineEnd.PF_y
	clc
	jmp	short done


setToLineStart:
	add	sp,8				;clear originals from stack
	movwwf	dxcx,ss:[bp].PTL_lineStart.PF_x
	movwwf	bxax,ss:[bp].PTL_lineStart.PF_y
	clc
	jmp	short done

MakeSurePointIsOnLineSegmentLow		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcSlope
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the slope we need and the point used in the
		equations (Xa,Ya or Xp,Yp) adjusted by moving the 
		other point to the origin

CALLED BY:	INTERNAL
		CalcClosestPointOnLineSegment

PASS:		
		ss:bp - PointToLine
			PTL_lineStart
			PTL_lineEnd
			PTL_otherPoint

RETURN:		
			PTL_slope
			PTL_slopeSquared
			PTL_pointMoveToOrigin
			PTL_newPoint

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcSlope		proc	near

	uses	ax,bx,cx,dx,si,di
	.enter	

	clr	si					;assumed sign of slope

	;    Calc delta X and delta Y
	;

	mov	bx,ss:[bp].PTL_lineEnd.PF_x.WWF_int
	mov	ax,ss:[bp].PTL_lineEnd.PF_x.WWF_frac
	sub	ax,ss:[bp].PTL_lineStart.PF_x.WWF_frac
	sbb	bx,ss:[bp].PTL_lineStart.PF_x.WWF_int
	tst	bx
	jns	calcDeltaY
	not	si					;toggle sign of slope
	NegWWFixed	bx,ax

calcDeltaY:

	mov	dx,ss:[bp].PTL_lineEnd.PF_y.WWF_int
	mov	cx,ss:[bp].PTL_lineEnd.PF_y.WWF_frac
	sub	cx,ss:[bp].PTL_lineStart.PF_y.WWF_frac
	sbb	dx,ss:[bp].PTL_lineStart.PF_y.WWF_int
	tst	dx
	jns	compDeltas
	not	si					;toggle sign of slope
	NegWWFixed	dx,cx

compDeltas:	
	;    If delta Y is less than delta X use normal equation
	;    otherwise do reverse stuff
	;

	jleWWF	dx,cx,bx,ax,normal			;delta y to delta x

	;    Doing things in reverse
	;

	;    Calculate 1/M
	;

	xchg	dx,bx
	xchg	cx,ax
	not	si					;toggle sign of slope
	call	GrUDivWWFixed

	;    otherPoint is moved to origin and lineStart is 
	;    adjusted accordingly
	;

	push	si					;slope sign
	mov	ax,ss:[bp].PTL_lineStart.PF_x.WWF_frac
	mov	bx,ss:[bp].PTL_lineStart.PF_x.WWF_int
	mov	si,ss:[bp].PTL_otherPoint.PF_x.WWF_frac
	mov	di,ss:[bp].PTL_otherPoint.PF_x.WWF_int
	sub	ax,si
	sbb	bx,di
	mov	ss:[bp].PTL_newPoint.PF_x.WWF_frac,ax
	mov	ss:[bp].PTL_newPoint.PF_x.WWF_int,bx
	mov	ss:[bp].PTL_pointMovedToOrigin.PF_x.WWF_frac,si
	mov	ss:[bp].PTL_pointMovedToOrigin.PF_x.WWF_int,di
	mov	ax,ss:[bp].PTL_lineStart.PF_y.WWF_frac
	mov	bx,ss:[bp].PTL_lineStart.PF_y.WWF_int
	mov	si,ss:[bp].PTL_otherPoint.PF_y.WWF_frac
	mov	di,ss:[bp].PTL_otherPoint.PF_y.WWF_int
	sub	ax,si
	sbb	bx,di
	mov	ss:[bp].PTL_newPoint.PF_y.WWF_frac,ax
	mov	ss:[bp].PTL_newPoint.PF_y.WWF_int,bx
	mov	ss:[bp].PTL_pointMovedToOrigin.PF_y.WWF_frac,si
	mov	ss:[bp].PTL_pointMovedToOrigin.PF_y.WWF_int,di
	pop	si					;slope sign


calcSlopeSquared:
	;    Calculate slope squared + 1
	;

	mov	ax,cx					;slope frac
	mov	bx,dx					;slope int
	call	GrSqrWWFixed
	inc	dx					;m^2 + 1
	mov	ss:[bp].PTL_slopeSquared.WWF_int,dx
	mov	ss:[bp].PTL_slopeSquared.WWF_frac,cx

	;    Set sign of slope
	;

	tst	si
	jns	setSlope
	NegWWFixed 	bx,ax

setSlope:
	mov	ss:[bp].PTL_slope.WWF_int,bx
	mov	ss:[bp].PTL_slope.WWF_frac,ax

	.leave
	ret


normal:
	;    Calculate the unsigned slope normally
	;

	call	GrUDivWWFixed

	;    lineStart is moved to origin and otherPoint is 
	;    adjusted accordingly
	;

	push	si					;slope sign
	mov	ax,ss:[bp].PTL_otherPoint.PF_x.WWF_frac
	mov	bx,ss:[bp].PTL_otherPoint.PF_x.WWF_int
	mov	si,ss:[bp].PTL_lineStart.PF_x.WWF_frac
	mov	di,ss:[bp].PTL_lineStart.PF_x.WWF_int
	sub	ax,si
	sbb	bx,di
	mov	ss:[bp].PTL_newPoint.PF_x.WWF_frac,ax
	mov	ss:[bp].PTL_newPoint.PF_x.WWF_int,bx
	mov	ss:[bp].PTL_pointMovedToOrigin.PF_x.WWF_frac,si
	mov	ss:[bp].PTL_pointMovedToOrigin.PF_x.WWF_int,di
	mov	ax,ss:[bp].PTL_otherPoint.PF_y.WWF_frac
	mov	bx,ss:[bp].PTL_otherPoint.PF_y.WWF_int
	mov	si,ss:[bp].PTL_lineStart.PF_y.WWF_frac
	mov	di,ss:[bp].PTL_lineStart.PF_y.WWF_int
	sub	ax,si
	sbb	bx,di
	mov	ss:[bp].PTL_newPoint.PF_y.WWF_frac,ax
	mov	ss:[bp].PTL_newPoint.PF_y.WWF_int,bx
	mov	ss:[bp].PTL_pointMovedToOrigin.PF_y.WWF_frac,si
	mov	ss:[bp].PTL_pointMovedToOrigin.PF_y.WWF_int,di
	pop	si					;slope sign
	jmp	calcSlopeSquared



CalcSlope		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcXY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Calculate the X of the line intersection
		Xn = ( Xnp + ( Ynp * M ) ) / (M^2 + 1)
		Calculate the Y of the line intersection
		Yn = Xnp * M


CALLED BY:	INTERNAL
		CalcClosestPointOnLineSegment

PASS:		
		ss:bp - PointToLine
			PTL_slope
			PTL_slopeSquared
			PTL_newPoint


RETURN:		
		dx:cx - WWFixed X
		bx:ax - WWFixed Y

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcXY		proc	near
	.enter	

	;    Calc Ynp * M
	;

	mov	dx,ss:[bp].PTL_slope.WWF_int
	mov	cx,ss:[bp].PTL_slope.WWF_frac
	mov	bx,ss:[bp].PTL_newPoint.PF_y.WWF_int
	mov	ax,ss:[bp].PTL_newPoint.PF_y.WWF_frac
	call	GrMulWWFixed

	;    Calc Xnp + (Ynp * M)
	;

	add	cx,ss:[bp].PTL_newPoint.PF_x.WWF_frac
	adc	dx,ss:[bp].PTL_newPoint.PF_x.WWF_int	

	;    Calc (Xnp + Ynp * M)/(M^2+1)
	;

	mov	bx,ss:[bp].PTL_slopeSquared.WWF_int
	mov	ax,ss:[bp].PTL_slopeSquared.WWF_frac
	call	GrSDivWWFixed

	;    Calc Xn * M
	;

	push	dx,cx					;WWFixed X
	mov	bx,ss:[bp].PTL_slope.WWF_int
	mov	ax,ss:[bp].PTL_slope.WWF_frac
	call	GrMulWWFixed
	mov	bx,dx					;WWF_int Y
	mov_trash	ax,cx				;WWF_frac Y
	pop	dx,cx					;WWFixed X

	.leave
	ret

CalcXY		endp

GrObjRequiredInteractiveCode	ends

GrObjRequiredExtInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineAdjustCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish creating the object given whatever data
		is currently available. Use the sprite data
		as the desired size and position of this beast.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass

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
	srs	4/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineAdjustCreate	method dynamic LineClass, MSG_GO_ADJUST_CREATE
	uses	cx
	.enter

	mov	cl, TRUE
	mov	ax, MSG_GO_SET_ARROWHEAD_ON_END
	call	ObjCallInstanceNoLock

	.leave
	ret
LineAdjustCreate		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineEvaluatePARENTPointForHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if point hits any of the objects handles

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass
		ss:bp - fptr to PointWWFixed in CR coords

RETURN:		
		al - EVALUATE_NONE
			ah - destroyed
		al - EVALUATE_HIGH
			ah - GrObjHandleSpecification of hit handle

		dx - 0

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineEvaluatePARENTPointForHandle	method dynamic LineClass, 
		MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE, 
		MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_RESIZE, 
		MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_ROTATE

	uses	cx,bp
	.enter

	clr	dx					;pretend no gstate
	test	ds:[di].GOI_tempState, mask GOTM_HANDLES_DRAWN
	jz	fail

	mov	cx,mask GOL_MOVE or mask GOL_RESIZE
	cmp	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_RESIZE
	jne	other

hitDetect:
	call	GrObjGetCurrentHandleSize

	;    Create handle location transform gstate
	;

	clr	di					;no window
	call	GrCreateState
	call	GrObjApplyNormalTransform	
	mov	dx,di					;conversion gstate

	;    Ignore move handle if move lock is set
	;

	GrObjDeref	di,ds,si
	mov	di,ds:[di].GOI_locks
	andnf	di,cx					;just locks that matter
	test	di,mask GOL_MOVE
	jnz	checkTransformLocks

	mov	cl,HANDLE_MOVE
	call	GrObjHitDetectOneHandleConvertGState
	jc	hit

checkTransformLocks:
	;    Ignore resize/rotate handles if resize/rotate lock is set.
	;

	test	di,mask GOL_RESIZE or mask GOL_ROTATE
	jnz	destroyGState

	;    Check corner handles

	mov	cl,HANDLE_LEFT_TOP
	call	GrObjHitDetectOneHandleConvertGState
	jc	hit

	mov	cl,HANDLE_RIGHT_BOTTOM
	call	GrObjHitDetectOneHandleConvertGState
	jnc	fail
hit:
	mov	al, EVALUATE_HIGH
	mov	ah,cl				;flags in ah

destroyGState:
	tst	dx
	jz	done
	mov	di,dx				;gstate
	call	GrDestroyState
	clr	dx				;no EvaluatePositionNotes
done:
	.leave
	ret

fail:
	mov	al, EVALUATE_NONE
	jmp	short destroyGState


other:
	mov	cx,mask GOL_MOVE or mask GOL_ROTATE
	cmp	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_ROTATE
	je	hitDetect
	clr	cx
	jmp	hitDetect

LineEvaluatePARENTPointForHandle		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineInvertHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inverts handles of line

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass
		dx - gstate

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
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineInvertHandles	method dynamic LineClass, MSG_GO_INVERT_HANDLES
	uses	ax
	.enter

	mov	di,dx					;gstate	
EC <	call	ECCheckGStateHandle			>

	mov	al,MM_INVERT
	call	GrSetMixMode

	mov	al,SDM_100				
	call	GrSetAreaMask

	;
	;  See if the invisible bit is set
	;
	push	cx, dx, bp, di
	mov	ax, MSG_GB_GET_DESIRED_HANDLE_SIZE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	pop	cx, dx, bp, di

	tst	al			;if negative, invisible handles
	js	justDrawMoveHandle

	call	LineDrawSelectedHandles

done:
	.leave
	ret

justDrawMoveHandle:
	CallMod	GrObjGetCurrentHandleSize
	mov	cl,HANDLE_MOVE
	call	GrObjDrawOneHandle
	jmp	done
LineInvertHandles endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineDrawSelectedHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws handles for line

PASS:		
		*(ds:si) - instance data of object
		di - gstate
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
	srs	12/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineDrawSelectedHandles		proc 	near
	class	LineClass
	uses	ax,bx
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	call	GrObjGetDesiredHandleSize

	;    Draw handles on corners
	;

	mov	cl,HANDLE_LEFT_TOP
	call	GrObjDrawOneHandle		

	mov	cl,HANDLE_RIGHT_BOTTOM
	call	GrObjDrawOneHandle

	mov	cl,HANDLE_MOVE
	call	GrObjDrawOneHandle

	.leave
	ret
LineDrawSelectedHandles		endp


GrObjRequiredExtInteractiveCode	ends













































GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineDrawFGArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Line has no area or clipping. Eat this message.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass
	
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
LineDrawFGArea	method dynamic LineClass, MSG_GO_DRAW_FG_AREA,
					MSG_GO_DRAW_FG_AREA_HI_RES,
					MSG_GO_DRAW_CLIP_AREA,
					MSG_GO_DRAW_CLIP_AREA_HI_RES,
					MSG_GO_DRAW_FG_GRADIENT_AREA,
					MSG_GO_DRAW_FG_GRADIENT_AREA_HI_RES
					

	.enter

	.leave
	ret

LineDrawFGArea		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineDrawFG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the foreground/background line component of the line

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass
	
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
LineDrawFG	method dynamic LineClass, MSG_GO_DRAW_BG_AREA,
						MSG_GO_DRAW_FG_LINE
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	call	GrSaveTransform
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrDrawLine
	call	GrRestoreTransform
	call	GrObjGetLineInfo
	call	LineDrawStartArrowhead
	call	LineDrawEndArrowhead

	.leave
	ret

LineDrawFG		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineDrawQuickView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the foreground line component of the line

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass
	
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
LineDrawQuickView	method dynamic LineClass, MSG_GO_DRAW_QUICK_VIEW
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrDrawLine

	.leave
	ret

LineDrawQuickView		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineDrawFGHiRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the foreground/background line component of the line

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of LineClass
	
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
LineDrawFGHiRes	method dynamic LineClass, MSG_GO_DRAW_FG_LINE_HI_RES,
					MSG_GO_DRAW_BG_AREA_HI_RES
						
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	call	GrSaveTransform
	CallMod	GrObjApplyIncreaseResolutionScaleFactor
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcIncreasedResolutionCorners
	call	GrDrawLine
	call	GrRestoreTransform
	call	GrObjGetLineInfo
	call	LineDrawStartArrowhead
	call	LineDrawEndArrowhead

	.leave
	ret

LineDrawFGHiRes		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineDrawStartArrowhead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw arrow head at start of line in needed

CALLED BY:	INTERNAL
		LineDrawFGLine

PASS:		*ds:si - object
		di - gstate with normalTransform applied
		al - GrObjLineAttrInfoRecord

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
	srs	9/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineDrawStartArrowhead		proc	near

	uses	ax,bx,cx,dx
	.enter

EC <	call	ECLineCheckLMemObject				>
EC <	call	ECCheckGStateHandle			>

	test	al, mask GOLAIR_ARROWHEAD_ON_START
	jz	done

	call	GrSaveTransform
	call	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrObjDrawArrowhead
	call	GrRestoreTransform

done:
	.leave
	ret
LineDrawStartArrowhead		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineDrawEndArrowhead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw arrow head at end of line in needed

CALLED BY:	INTERNAL
		LineDrawFGLine

PASS:		*ds:si - object
		di - gstate with normalTransform applied
		al - GrObjLineAttrInfoRecord

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
	srs	9/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineDrawEndArrowhead		proc	near
	uses	ax,bx,cx,dx
	.enter

EC <	call	ECLineCheckLMemObject				>
EC <	call	ECCheckGStateHandle			>

	test	al, mask GOLAIR_ARROWHEAD_ON_END
	jz	done

	call	GrSaveTransform
	call	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	xchg	ax,cx					;end x, start x
	xchg	bx,dx					;end y, start y
	call	GrObjDrawArrowhead
	call	GrRestoreTransform
done:
	.leave
	ret
LineDrawEndArrowhead		endp



GrObjDrawCode	ends














if	ERROR_CHECK
GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECLineCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an LineClass or one
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
ECLineCheckLMemObject		proc	far
ForceRef	ECLineCheckLMemObject
	uses	es,di
	.enter
	pushf	
	call	ECCheckLMemObject
	mov	di,segment LineClass
	mov	es,di
	mov	di,offset LineClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_A_DRAW_OBJECT	
	popf
	.leave
	ret
ECLineCheckLMemObject		endp

GrObjErrorCode	ends

endif
