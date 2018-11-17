COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Shape
FILE:		arc.asm

AUTHOR:		Steve Scholl, July 27, 1992

ROUTINES:
	Name		
	----		
ArcCalcThreePoints
ArcCalcPointFromAngle
ArcCalcMidAngle
ArcApplyTransformToNormalOBJECT
ArcCalcScaleToNormalOBJECT
ArcApplyTransformToSpriteOBJECT
ArcCalcScaleToSpriteOBJECT
ArcCalcTranslationToArcCenter
ArcCalcBounds
ArcSetupThreePointArcParams
ArcCompleteAngleOrCloseChange
ArcSetOBJECTDimensionsFromArcBounds
ArcGetArcCenterInPARENT

METHODS:
	Name		
	----		
ArcMetaInitialize
ArcDrawFG	
ArcDrawSpriteLine
ArcSetStartAngle
ArcSetEndAngle
ArcSetArcCloseType
ArcCompleteCreate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	7/27/92		Initial revision


DESCRIPTION:
	This file contains routines to implement the Arc Class
		

	$Id: arc.asm,v 1.1 97/04/04 18:08:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

	;Define the class record
ArcClass

GrObjClassStructures	ends

RectPlusCode	segment	resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set default angles and three points

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

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
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DEFAULT_ARC_RADIUS	equ	50 * 65536

ArcMetaInitialize	method dynamic ArcClass, MSG_META_INITIALIZE
	.enter

	mov	di,offset ArcClass
	call	ObjCallSuperNoLock

	GrObjDeref	di,ds,si
	BitSet	ds:[di].GOI_msgOptFlags, \
	GOMOF_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	clr	ax
	mov	bx,270
	movwwf	ds:[di].AI_startAngle,bxax
	mov	bx,360
	movwwf	ds:[di].AI_endAngle,bxax
	mov	ds:[di].AI_arcCloseType,ACT_PIE
	movwwf	ds:[di].AI_radius,DEFAULT_ARC_RADIUS
	BitSet	ds:[di].GOI_attrFlags, GOAF_MULTIPLICATIVE_RESIZE

	call	ArcCalcThreePoints

	.leave
	ret
ArcMetaInitialize		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcGetBoundingRectDWFixed
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
ArcGetBoundingRectDWFixed	method dynamic ArcClass, 
					MSG_GO_GET_BOUNDING_RECTDWFIXED
	.enter

	CallMod	GrObjGetBoundingRectDWFixedFromPath

	CallMod	GrObjAdjustRectDWFixedByLineWidth

	.leave
	ret
ArcGetBoundingRectDWFixed		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcInitBasicData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The arc handles this message very differently than
		other objects. It treats the width and height passed
		as the dimensions of the ellipse that the arc is part
		of and the center as the center of that ellipse.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

		ss:bp - BasicInit

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
	srs	7/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcInitBasicData	method dynamic ArcClass, 
						MSG_GO_INIT_BASIC_DATA
	uses	cx,dx,bp
	.enter

	;    Call superclass to get data copied into ObjectTransform
	;

	mov	di,offset ArcClass
	call	ObjCallSuperNoLock

	GrObjDeref	di,ds,si

	;    Calc scale from our internal circle to the ellipse
	;    and apply the scale to the transform
	;

	sub	sp,size GrObjScaleData
	mov	bp,sp
	push	si					;object chunk
	mov	si,ds:[di].GOI_normalTransform
EC <	tst	si					>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST		>
	mov	si,ds:[si]
	movwwf	dxcx,ds:[si].OT_width
	movwwf	bxax,ds:[di].AI_radius
	shlwwf	bxax
	call	GrSDivWWFixed
	movwwf	ss:[bp].GOSD_xScale,dxcx
	movwwf	dxcx,ds:[si].OT_height
	call	GrSDivWWFixed
	movwwf	ss:[bp].GOSD_yScale,dxcx
	pop	si					;object chunk
	mov	cl,HANDLE_CENTER
	call	GrObjScaleNormalRelativeOBJECT
	add	sp,size GrObjScaleData

	;    Since our circle is centered on 0,0 and so is the ellipse
	;    passed in by the user,
	;    if we convert the center of the arc bounds into PARENT coords
	;    it will give us the center of our arc object
	;

	sub	sp,size PointDWFixed
	mov	bp,sp
	call	ArcGetArcCenterInPARENT
	call	GrObjSetNormalCenter
	add	sp,size PointDWFixed

	call	ArcSetOBJECTDimensionsFromArcBounds

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	.leave
	ret
ArcInitBasicData		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcSetOBJECTDimensionsFromArcBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the OBJECT dimensions to the width and height of
		the bounds of the arc.

CALLED BY:	INTERNAL
		ArcInitBasicData

PASS:		*ds:si - arc

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
	srs	7/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcSetOBJECTDimensionsFromArcBounds		proc	near
	uses	ax,bx,cx,dx,bp
	.enter

EC <	call	ECArcCheckLMemObject				>

	sub	sp,size RectWWFixed
	mov	bp,sp
	call	ArcCalcBounds
	movwwf	dxcx,ss:[bp].RWWF_right
	subwwf	dxcx,ss:[bp].RWWF_left
	movwwf	bxax,ss:[bp].RWWF_bottom
	subwwf	bxax,ss:[bp].RWWF_top
	add	sp,size RectWWFixed
	call	GrObjSetNormalOBJECTDimensions

	.leave
	ret
ArcSetOBJECTDimensionsFromArcBounds		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCalcThreePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the three points on the circular arc

CALLED BY:	INTERNAL
		ArcMetaInitalize
		ArcSetStartAngle
		ArcSetEndAngle

PASS:		*ds:si - Arc
			AI_startAngle, AI_endAngle set

RETURN:		
		AI_startPoint
		AI_endPoint
		AI_midPoint

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
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcCalcThreePoints		proc	far
	class	ArcClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECArcCheckLMemObject			>

	call	ObjMarkDirty

	ArcDeref	di,ds,si

	movwwf	dxax,ds:[di].AI_startAngle
	call	ArcCalcPointFromAngle
	movwwf	ds:[di].AI_startPoint.PF_x,dxcx
	movwwf	ds:[di].AI_startPoint.PF_y,bxax

	movwwf	dxax,ds:[di].AI_endAngle
	call	ArcCalcPointFromAngle
	movwwf	ds:[di].AI_endPoint.PF_x,dxcx
	movwwf	ds:[di].AI_endPoint.PF_y,bxax

	movwwf	dxax,ds:[di].AI_startAngle
	movwwf	cxbx,ds:[di].AI_endAngle
	call	ArcCalcMidAngle
	call	ArcCalcPointFromAngle
	movwwf	ds:[di].AI_midPoint.PF_x,dxcx
	movwwf	ds:[di].AI_midPoint.PF_y,bxax

	.leave
	ret
ArcCalcThreePoints		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCalcPointFromAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the point on the arc based on the angle

CALLED BY:	INTERNAL
		ArcCalcThreePoints

PASS:		*ds:si - arc
		dxax - WWFixed angle

RETURN:		
		dxcx - x WWFixed
		bxax - y WWFixed		

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
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcCalcPointFromAngle		proc	far
	class	ArcClass
	uses	di
	.enter

EC <	call	ECArcCheckLMemObject			>
	
	ArcDeref	di,ds,si

	pushwwf	dxax					;angle
	call	GrQuickCosine
	mov_tr	cx,ax					;cos frac	
	movwwf	bxax,ds:[di].AI_radius
	call	GrMulWWFixed
	mov	bx,dx					;x int
	popwwf	dxax					;angle

	pushwwf	bxcx					;x 
	call	GrQuickSine
	mov_tr	cx,ax					;cos frac	
	movwwf	bxax,ds:[di].AI_radius
	call	GrMulWWFixed
	mov	bx,dx					;y int
	mov_tr	ax,cx					;y frac
	popwwf	dxcx					;x

	negwwf	bxax					;HACK for wierdness
							;in graphics system
	.leave
	ret
ArcCalcPointFromAngle		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCalcMidAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc the angle in the middle of the two passed

CALLED BY:	INTERNAL
		ArcCalcThreePoints		

PASS:		dxax - start angle WWFixed
		cxbx - end angle WWFixed

RETURN:		
		dxax - mid angle WWFixed		

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
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcCalcMidAngle		proc	near
	uses	bx,cx
	.enter

	;    Get both angle in range 0 to 360
	;

	xchg	cx,ax				;start frac, end int
	call	GrObjNormalizeDegrees
	xchg	ax,dx				;start int, end int	
	xchg	bx,cx				;start frac, end frac
	call	GrObjNormalizeDegrees
	xchg	cx,ax				;start int, end frac

	;     dxax - end angle
	;     bxcx - start angle
	;     To calc mid angle (end - start)/2 + start
	;     This only works if end > start, so add 360 to
	;     end if it is smaller
	
	jlewwf	dxax,cxbx,advanceEnd
	
calcMid:
	subwwf	dxax,cxbx
	shrwwf	dxax
	addwwf	dxax,cxbx

	.leave
	ret

advanceEnd:
	add	dx,360
	jmp	calcMid

ArcCalcMidAngle		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcDrawSpriteLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line of arc

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass
	
		cl - DrawFlags
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
ArcDrawSpriteLine	method dynamic ArcClass, MSG_GO_DRAW_SPRITE_LINE,
					MSG_GO_DRAW_SPRITE_LINE_HI_RES
	uses	cx,dx,bp
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	call	ArcCalcTranslationToArcCenter
	call	GrApplyTranslation

	sub	sp,size ThreePointArcParams
	mov	bp,sp
	call	ArcSetupThreePointArcParams
	call	GrDrawArc3Point
	add	sp,size ThreePointArcParams

	.leave
	ret
ArcDrawSpriteLine		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcSetStartAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the starting angle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

		dx:cx - WWFixed angle

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
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcSetStartAngle	method dynamic ArcClass, 
						MSG_ARC_SET_START_ANGLE
	.enter

	mov	di,offset AI_startAngle
	mov	ax,2					;two words new data
	call	ArcCompleteAngleOrCloseChange

	.leave
	ret
ArcSetStartAngle		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcSetEndAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the starting angle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

		dx:cx - WWFixed angle

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
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcSetEndAngle	method dynamic ArcClass, MSG_ARC_SET_END_ANGLE
	.enter

	mov	di,offset AI_endAngle
	mov	ax,2					;two words new data
	call	ArcCompleteAngleOrCloseChange

	.leave
	ret
ArcSetEndAngle		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcSetArcCloseType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the starting angle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

		cx - ArcCloseType

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
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcSetArcCloseType	method dynamic ArcClass, MSG_ARC_SET_ARC_CLOSE_TYPE
	uses	bp
	.enter

	mov	di, offset AI_arcCloseType
	mov	ax,1
	call	ArcCompleteAngleOrCloseChange

	.leave
	ret
ArcSetArcCloseType		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCompleteAngleOrCloseChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common functionality for changing arc data

CALLED BY:	INTERNAL
		ArcSetStartAngle
		ArcSetEndAngle
		ArcSetArcCloseType

PASS:		
		*ds:si - Arc
		di - offset into ArcInstance to put new data
		cx - low word of new data
		dx - high word of new data
		ax - number of data words (must be at least 1)

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		We want the arc/chord to be part of the same ellipse as
		it was before the angle/close type change. So we need to
		move the center of the object the distance that the
		center of the arc bounds moves.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcCompleteAngleOrCloseChange		proc	near
	class	ArcClass
	uses	ax,bx,bp,di
	.enter

EC <	call	ECArcCheckLMemObject	>

	GrObjDeref	bx,ds,si
	test	ds:[bx].GOI_locks, mask GOL_EDIT
	jnz	done

	mov	bp,GOANT_PRE_SPEC_MODIFY
	call	GrObjOptNotifyAction

	call	ArcGenerateUndoArcChangesChain

	call	GrObjBeginGeometryCommon

	sub	sp,size SrcDestPointDWFixeds
	mov	bp,sp
	addnf	bp,<offset SDPDWF_dest>
	call	ArcGetArcCenterInPARENT
	subnf	bp,<offset SDPDWF_dest>

	;    Must change the arc instance data after calcing the
	;    destination of the move, because that calculation
	;    depends on the original data.
	;

	call	ObjMarkDirty
	GrObjDeref	bx,ds,si
	add	di,bx
	mov	ds:[di],cx
	cmp	ax,1
	je	10$
	mov	ds:[di+2],dx
10$:
	call	ArcCalcThreePoints

	addnf	bp,<offset SDPDWF_source>
	call	ArcGetArcCenterInPARENT
	subnf	bp,<offset SDPDWF_source>

	call	GrObjMoveNormalBackToAnchor
	add	sp,size SrcDestPointDWFixeds

	call	ArcSetOBJECTDimensionsFromArcBounds

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	call	GrObjEndGeometryCommon

	mov	bp,GOANT_SPEC_MODIFIED
	call	GrObjOptNotifyAction

done:
	.leave
	ret
ArcCompleteAngleOrCloseChange		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcGetArcCenterInPARENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the center of the arc points and convert it into PARENT

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - arc
		ss:bp - PointDWFixed

RETURN:		
		ss:bp - PointDWFixed - center of arc in PARENT

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
	srs	7/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcGetArcCenterInPARENT		proc	near
	uses	ax,bx,cx,dx,bp
	.enter

	call	ArcCalcBoundsCenter
	mov	ss:[bp].PDF_x.DWF_int.low,dx
	mov	ss:[bp].PDF_x.DWF_frac,cx
	mov	ss:[bp].PDF_y.DWF_int.low,bx
	mov	ss:[bp].PDF_y.DWF_frac,ax
	mov_tr	ax,dx					;x int low
	cwd						;sign extend x int
	mov	ss:[bp].PDF_x.DWF_int.high,dx
	mov_tr	ax,bx					;y int low
	cwd						;sign extend y int
	mov	ss:[bp].PDF_y.DWF_int.high,dx
	call	GrObjConvertNormalOBJECTToPARENT	

	.leave
	ret
ArcGetArcCenterInPARENT		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCompleteCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After rectangle has been interactively created have
		it become selected.
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

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
ArcCompleteCreate	method dynamic ArcClass, MSG_GO_COMPLETE_CREATE
	uses	ax,dx
	.enter

	;    In case the user dragged some other way the down and to the
	;    left, this will keep the angle orientation correcte.
	;

	call	ArcCompensateAnglesForFlips

	mov	di,offset ArcClass
	call	ObjCallSuperNoLock

	movnf	dx, HUM_NOW
	mov	ax,MSG_GO_BECOME_SELECTED
	call	ObjCallInstanceNoLock

	.leave
	ret
ArcCompleteCreate		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcGenerateUndoArcChangesChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate undo chain for changes to arc specific
		instance data

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - arc

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
	srs	12/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcGenerateUndoArcChangesChain		proc	far
	uses	ax,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	cx,handle arcChangesString
	mov	dx,offset arcChangesString
	mov	ax,\
		MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_CHAIN
	call	ObjCallInstanceNoLock

	.leave
	ret
ArcGenerateUndoArcChangesChain		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcReplaceArcGeometryInstanceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the arcs instance data with the passed data

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

		ss:bp - ArcBasicInit
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
	srs	12/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcReplaceArcGeometryInstanceData	method dynamic ArcClass, 
				MSG_ARC_REPLACE_ARC_GEOMETRY_INSTANCE_DATA
	uses	cx
	.enter

	push	ds,si
	segmov	es,ds
	add	di,offset AI_arcCloseType	
	segmov	ds,ss
	mov	si,bp
	MoveConstantNumBytes	<size ArcBasicInit>,cx
	pop	ds,si

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	.leave
	ret
ArcReplaceArcGeometryInstanceData		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcUndoReplaceArcGeometryInstanceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our instance data from the passed undo info.

		We do not want to generate an undo action for this
		because all the arc undo stuff is piggy backed on
		the grobj instance data undo actions.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

		dx - DB group
		cx - DB item
		bp - VM File handle

		The referenced DBitem must contain a ArcBasicInit structure

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
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcUndoReplaceArcGeometryInstanceData	method dynamic ArcClass, 
			MSG_ARC_UNDO_REPLACE_ARC_GEOMETRY_INSTANCE_DATA
	uses	cx,bp
	.enter

	call	GrObjBeginGeometryCommon

	;    Lock the db item with instance data copy in it
	;

	mov	bx,bp					;VM file
	mov	ax,dx					;group
	mov	di,cx					;item
	call	DBLock
	mov	di,es:[di]				;deref db

	;    Copy ArcBasicInit struc to stack frame
	;

	sub	sp,size ArcBasicInit
	mov	bp,sp
	push	ds,si					;object 
	segmov	ds,es					;db item is source
	segmov	es,ss					;stack is dest
	mov	si,di					;source offset
	mov	di,bp					;dest offset
	MoveConstantNumBytes	<size ArcBasicInit>,cx

	;    Unlock the db item
	;

	segmov	es,ds					;db block
	call	DBUnlock
	pop	ds,si					;object

	;    Set the object instance data from the undo info
	;    and clear stack frame
	;

	mov	ax,MSG_ARC_REPLACE_ARC_GEOMETRY_INSTANCE_DATA
	call	ObjCallInstanceNoLock
	add	sp,size ArcBasicInit

	call	GrObjEndGeometryCommon

	mov	bp,GOANT_UNDO_GEOMETRY
	call	GrObjOptNotifyAction

	.leave
	ret
ArcUndoReplaceArcGeometryInstanceData		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcGenerateUndoReplaceArcGeometryInstanceDataAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo action for the arcs current geometry
		instance data

PASS:		
		*(ds:si) - instance data of object

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
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcGenerateUndoReplaceArcGeometryInstanceDataAction proc near
	class	ArcClass
	uses	ax,bx,cx,dx,bp,si,di,es
	.enter

EC <	call	ECArcCheckLMemObject			>

	;    Alloc db item for storing undo item in undo file
	;

	mov	cx,size	ArcBasicInit
	call	GrObjGlobalAllocUndoDBItem

	;    Copy instance data to  to db item
	;

	push	ax,di,si			;group, item, object chunk
	call	DBLock
	mov	di,es:[di]			;deref db item
	ArcDeref	si,ds,si
	add	si,offset AI_arcCloseType
	MoveConstantNumBytes	<size ArcBasicInit>,cx

	pop	dx,cx,si			;group, item, object chunk
	call	DBUnlock

	mov	bp,bx				;vm file handle
	clr	bx				;AddUndoActionFlags
	mov	ax,MSG_ARC_UNDO_REPLACE_ARC_GEOMETRY_INSTANCE_DATA
	call	GrObjGlobalAddVMChainUndoAction

	.leave
	ret
ArcGenerateUndoReplaceArcGeometryInstanceDataAction		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcGenerateUndoReplaceGeometryInstanceDataAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some geometry changes cause the arc to modify it's
		specific instance data, so create an action for
		those changes too.

		For instance flipping an arc causes it to swap it's
		angles so the user orientation doesn't get dorked.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

		cx:dx - od of undo text 

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
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcGenerateUndoReplaceGeometryInstanceDataAction method dynamic ArcClass,
		MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_ACTION
	.enter

	;    Must do arc specific data first, othewise on undo
	;    we will create an arc action that has the already undone
	;    arc data in it.
	;

	call	ArcGenerateUndoReplaceArcGeometryInstanceDataAction

	mov	ax,MSG_GO_GENERATE_UNDO_REPLACE_GEOMETRY_INSTANCE_DATA_ACTION
	mov	di,offset ArcClass
	call	ObjCallSuperNoLock


	.leave
	ret
ArcGenerateUndoReplaceGeometryInstanceDataAction		endm



RectPlusCode	ends




if	ERROR_CHECK
GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECArcCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an ArcClass or one
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
ECArcCheckLMemObject		proc	far
ForceRef	ECArcCheckLMemObject
	uses	es,di
	.enter
	pushf	
	mov	di,segment ArcClass
	mov	es,di
	mov	di,offset ArcClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_A_DRAW_OBJECT	
	popf
	.leave
	ret
ECArcCheckLMemObject		endp

GrObjErrorCode	ends

endif




GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCalcTranslationToArcCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc translation necessary to get center of arc to
		0,0

CALLED BY:	INTERNAL
		ArcApplyTransformToSpriteOBJECT
		ArcApplyTransformToNormalOBJECT

PASS:		*ds:si - arc

RETURN:		
		dxcx - WWFixed x translation
		bxax - WWFixed y translation

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
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcCalcTranslationToArcCenter		proc	far
	.enter

EC <	call	ECArcCheckLMemObject	>

	call	ArcCalcBoundsCenter
	negwwf	dxcx
	negwwf	bxax

	.leave
	ret
ArcCalcTranslationToArcCenter		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCalcBoundsCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate center of arc point bounds

CALLED BY:	INTERNAL

PASS:		
		*ds:si - arc

RETURN:		
		dx:cx - WWFixed x of center
		bx:ax - WWFixed y of center

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
	srs	7/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcCalcBoundsCenter		proc	far
	uses	bp
	.enter

EC <	call	ECArcCheckLMemObject				>

	sub	sp,size RectWWFixed
	mov	bp,sp
	call	ArcCalcBounds
	movwwf	dxcx,ss:[bp].RWWF_right
	movwwf	bxax,ss:[bp].RWWF_left
	subwwf	dxcx,bxax
	shrwwf	dxcx
	addwwf	dxcx,bxax
	movwwf	bxax,ss:[bp].RWWF_bottom
	subwwf	bxax,ss:[bp].RWWF_top
	shrwwf	bxax
	addwwf	bxax,ss:[bp].RWWF_top
	add	sp,size RectWWFixed

	.leave
	ret
ArcCalcBoundsCenter		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCalcBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the rectangle that bounds the three points
		and 0,0 if the arc is a pie

CALLED BY:	INTERNAL
		ArcCalcScaleToOBJECT

PASS:		*ds:si - arc
		ss:bp - RectWWFixed - empty

RETURN:		
		ss:bp - RectWWFixed - filled

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
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcCalcBounds		proc	far
	class	ArcClass
	uses	ax,di,es
	.enter

	push	ds,si					;object

	;    Initialize rectangle to start point
	;

	ArcDeref	di,ds,si
	segmov	es,ds,si	
	add	di,offset AI_startPoint
	segmov	ds,ss,si
	mov	si,bp
	call	GrObjGlobalInitRectWWFixedWithPointWWFixed

	;    Expand rect to include endPoint and midPoint
	;    of arc.
	;

	add	di, (offset AI_endPoint - offset AI_startPoint)
	call	GrObjGlobalCombineRectWWFixedWithPointWWFixed
	add	di, (offset AI_midPoint - offset AI_endPoint)
	call	GrObjGlobalCombineRectWWFixedWithPointWWFixed

	;    If the arc is a pie, then include the center
	;    in the rectangle
	;

	sub	di,offset AI_midPoint
	cmp	es:[di].AI_arcCloseType,ACT_PIE
	jne	90$
	sub	sp,size PointWWFixed
	segmov	es,ss,di
	mov	di,sp
	clr	ax
	clrwwf	es:[di].PF_x,ax
	clrwwf	es:[di].PF_y,ax
	call	GrObjGlobalCombineRectWWFixedWithPointWWFixed
	add	sp,size PointWWFixed


90$:
	pop	ds,si					;object 
	
	;    Expand rect to include any of the 90 degree multiple
	;    angles between the start and end angles
	;

	call	ArcExpandBoundsFor90s



	.leave
	ret
ArcCalcBounds		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcExpandBoundsFor90s
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: 	Expand rect to include any of the 90 degree 
		multiple angles that are between starting and
		ending angles
	

CALLED BY:	INTERNAL
		ArcCalcBounds

PASS:		
		*ds:si - arc
		ss:bp - initialized RectWWFixed

RETURN:		
		ss:bp - maybe modified

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
	srs	11/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcExpandBoundsFor90s		proc	near
	class	ArcClass
	uses	ax,cx
	.enter

EC <	call	ECArcCheckLMemObject				>

	clr	ax
	mov	cx,4
next:
	call	ArcExpandBoundsForAngleIfNecessary
	add	ax,90
	loop	next

	.leave
	ret

ArcExpandBoundsFor90s		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcExpandBoundsForAngleIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand the bounds of the arc to include the passed angle
		if the angle is between the starting and ending angle

CALLED BY:	INTERNAL
		ArcExpandBoundsFor90s

PASS:		*ds:si - Arc
		ax - angle
		ss:bp - initialized RectWWFixed

RETURN:		
		ss:bp - RectWWFixed may have been expanded

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
	srs	11/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcExpandBoundsForAngleIfNecessary		proc	near
	class	ArcClass
	uses	di,cx,bx
	.enter

	ArcDeref	di,ds,si
	mov	bx,ds:[di].AI_startAngle.WWF_int
	mov	cx,ds:[di].AI_endAngle.WWF_int
	sub	bx,ax
	js	startIsCWFromAngle

	;    Starting angle is counter clock wise from angle in question.
	;

	sub	cx,ax
	jns	bothCWWFromAngle

	;    The starting angle is counter clock wise from the angle
	;    and the ending angle is clockwise from the angle, so the
	;    angle is not between start and end.
	;

done:
	.leave
	ret

startIsCWFromAngle:
	sub	cx,ax
	js	bothCWFromAngle

	;    The starting angle is clock wise from the angle and the
	;    ending angle is counter clock wise from the angle, so the
	;    angle must be between them
	;

expand:
	call	ArcExpandBoundsForAngle
	jmp	done


bothCWFromAngle:
	;    Both angles are clock wise from the angle, so the
	;    distance to the starting angle must be smaller for
	;    the angle to be between start and end. But both
	;    values are negative, so a smaller distance is
	;    a larger number. Just fall thru
	;

bothCWWFromAngle:
	;    Both angles are counter clock wise from angle, so the
	;    distance to the starting angle must be greater
	;    for the angle to be between start and end.
	;

	cmp	bx,cx
	jge	expand
	jmp	done

ArcExpandBoundsForAngleIfNecessary		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcExpandBoundsForAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand bounds of arc to include the passed angle

CALLED BY:	INTERNAL
		ArcExpandBoundsForAngleIfNecessary

PASS:		
		*ds:si - Arc
		ax - angle
		ss:bp - initialized RectWWFixed

RETURN:		
		ss:bp - RectWWFixed may have been expanded

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
	srs	11/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcExpandBoundsForAngle		proc	near
	uses	ax,bx,cx,dx,si,ds,es
	.enter

EC <	call	ECArcCheckLMemObject				>

	mov	dx,ax					;int
	clr	ax					;frac
	call	ArcCalcPointFromAngle

	sub	sp,size PointWWFixed
	mov	di,sp
	movwwf	ss:[di].PF_x,dxcx
	movwwf	ss:[di].PF_y,bxax

	mov	si,ss
	mov	es,si
	mov	ds,si
	mov	si,bp
	call	GrObjGlobalCombineRectWWFixedWithPointWWFixed
	add	sp,size PointWWFixed

	.leave
	ret
ArcExpandBoundsForAngle		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcDrawFGArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the area foreground components of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass
	
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
ArcDrawFGArea	method dynamic ArcClass, MSG_GO_DRAW_FG_AREA,
					MSG_GO_DRAW_BG_AREA,
					MSG_GO_DRAW_FG_AREA_HI_RES,
					MSG_GO_DRAW_BG_AREA_HI_RES,
					MSG_GO_DRAW_CLIP_AREA,
					MSG_GO_DRAW_CLIP_AREA_HI_RES
	uses	cx,dx,bp
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	call	ArcCalcTranslationToArcCenter
	call	GrApplyTranslation

	sub	sp,size ThreePointArcParams
	mov	bp,sp
	call	ArcSetupThreePointArcParams
	call	GrFillArc3Point
	add	sp,size ThreePointArcParams

	.leave
	ret
ArcDrawFGArea		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcDrawFGLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line foreground components of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass
	
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
ArcDrawFG	method dynamic ArcClass, MSG_GO_DRAW_FG_LINE,
					MSG_GO_DRAW_FG_LINE_HI_RES,
					MSG_GO_DRAW_QUICK_VIEW
	uses	cx,dx,bp
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	call	ArcCalcTranslationToArcCenter
	call	GrApplyTranslation

	sub	sp,size ThreePointArcParams
	mov	bp,sp
	call	ArcSetupThreePointArcParams
	call	ArcGrDrawArc3Point
	add	sp,size ThreePointArcParams

	.leave
	ret
ArcDrawFG		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcSetupThreePointArcParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the ThreePointArcParams data structure from
		the object's instance data.

CALLED BY:	INTERNAL
		ArcDrawFG
		ArcDrawSpriteLine

PASS:		*ds:si - arc
		ss:bp - ThreePointArcParams

RETURN:		
		ds:si - ThreePointArcParams

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
	srs	7/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcSetupThreePointArcParams		proc	far
	class	ArcClass
	uses	cx,dx
	.enter

	ArcDeref	si,ds,si
	movwwf	dxcx,ds:[si].AI_startPoint.PF_x
	movwwf	ss:[bp].TPAP_point1.PF_x,dxcx
	movwwf	dxcx,ds:[si].AI_startPoint.PF_y
	movwwf	ss:[bp].TPAP_point1.PF_y,dxcx

	movwwf	dxcx,ds:[si].AI_midPoint.PF_x
	movwwf	ss:[bp].TPAP_point2.PF_x,dxcx
	movwwf	dxcx,ds:[si].AI_midPoint.PF_y
	movwwf	ss:[bp].TPAP_point2.PF_y,dxcx

	movwwf	dxcx,ds:[si].AI_endPoint.PF_x
	movwwf	ss:[bp].TPAP_point3.PF_x,dxcx
	movwwf	dxcx,ds:[si].AI_endPoint.PF_y
	movwwf	ss:[bp].TPAP_point3.PF_y,dxcx

	mov	dx,ds:[si].AI_arcCloseType
	mov	ss:[bp].TPAP_close,dx

	segmov	ds,ss,si
	mov	si,bp

	.leave
	ret
ArcSetupThreePointArcParams		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcGrDrawArc3Point
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grobj replacement for GrDrawArc3Point so that we can
		set the line join to beveled everytime

CALLED BY:	INTERNAL UTLIITY

PASS:		same as GrDrawArc

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
ArcGrDrawArc3Point		proc	far
	uses	ax
	.enter
	
	call	GrGetLineJoin
	push	ax
	mov	al,LJ_BEVELED
	call	GrSetLineJoin
	call	GrDrawArc3Point
	pop	ax
	call	GrSetLineJoin

	.leave
	ret
ArcGrDrawArc3Point		endp

GrObjDrawCode	ends

GrObjRequiredInteractiveCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcGetDWFSelectionHandleBoundsForTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	It is not trivial to calculate the selection handle
		bounds for arcs

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

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
ArcGetDWFSelectionHandleBoundsForTrivialReject	method dynamic ArcClass, 
		MSG_GO_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	.enter

	call	GrObjReturnLargeRectDWFixed

	.leave
	ret
ArcGetDWFSelectionHandleBoundsForTrivialReject		endm

GrObjRequiredInteractiveCode	ends


GrObjRequiredExtInteractive2Code segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCombineSelectionStateNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Arc method for
		MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		^hcx = GrObjNotifySelectionStateChange struct

Return:		carry set if relevant diff bit(s) are all set

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcCombineSelectionStateNotificationData	method dynamic	ArcClass,
			 MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA
	.enter

	mov	di, offset ArcClass
	call	ObjCallSuperNoLock

	;
	;  Indicate that a arc is selected
	;
	pushf

	ArcDeref	di,ds,si

	mov	bx, cx
	call	MemLock
	jc	popfDone
	mov	es, ax

	test	es:[GONSSC_selectionState].GSS_flags, mask GSSF_ARC_SELECTED
	jz	firstArc

	mov	ax, ds:[di].AI_arcCloseType
	cmp	ax, es:[GONSSC_arcCloseType]
	je	checkStartAngle

	BitSet	es:[GONSSC_selectionStateDiffs], GSSD_MULTIPLE_ARC_CLOSE_TYPES

checkStartAngle:
	cmpwwf	es:[GONSSC_arcStartAngle], ds:[di].AI_startAngle, ax
	je	checkEndAngle

	BitSet	es:[GONSSC_selectionStateDiffs], GSSD_MULTIPLE_ARC_START_ANGLES

checkEndAngle:
	cmpwwf	es:[GONSSC_arcEndAngle], ds:[di].AI_endAngle, ax
	je	unlockDone

	BitSet	es:[GONSSC_selectionStateDiffs], GSSD_MULTIPLE_ARC_END_ANGLES

unlockDone:		
	call	MemUnlock

popfDone:
	popf
	.leave
	ret

firstArc:
	BitSet	es:[GONSSC_selectionState].GSS_flags, GSSF_ARC_SELECTED

	mov	ax, ds:[di].AI_arcCloseType
	mov	es:[GONSSC_arcCloseType], ax
	movwwf	es:[GONSSC_arcStartAngle], ds:[di].AI_startAngle, ax
	movwwf	es:[GONSSC_arcEndAngle], ds:[di].AI_endAngle, ax
	jmp	unlockDone
ArcCombineSelectionStateNotificationData	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCompleteTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the angles to compensate for flips

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ArcClass

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
	srs	11/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcCompleteTransform	method dynamic ArcClass, 
						MSG_GO_COMPLETE_TRANSFORM
	.enter

	call	ArcCompensateAnglesForFlips

	mov	di,offset ArcClass
	call	ObjCallSuperNoLock

	.leave
	ret
ArcCompleteTransform		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcCompensateAnglesForFlips
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust start and ending angles for flips in transformation
		matrix

CALLED BY:	INTERNAL
		ArcCompleteTransform

PASS:		*ds:si - Arc

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
	srs	11/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcCompensateAnglesForFlips		proc	far
	class	ArcClass
matrix		local	GrObjTransMatrix
scaleX		local	WWFixed
scaleY		local	WWFixed
skewXY		local	WWFixed
ForceRef	scaleX
ForceRef	scaleY
ForceRef	skewXY
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECArcCheckLMemObject				>

	call	GrObjDecomposeTransform
	jnc	continue
	jmp	done

continue:
	ArcDeref	di,ds,si

	sub	sp,size GrObjScaleData
	mov	bx,sp
	push	si					;object chunk
	mov	si,bx					;GrObjScaleData offset
	clr	ax
	mov	ss:[si].GOSD_xScale.WWF_frac,ax
	mov	ss:[si].GOSD_yScale.WWF_frac,ax
	inc	ax
	mov	ss:[si].GOSD_xScale.WWF_int,ax
	mov	ss:[si].GOSD_yScale.WWF_int,ax

	;    The decompose routine always returns a positive scale,
	;    so we need to look at the rotation to see of our
	;    object has been flipped.
	;

	tst	matrix.GTM_e11.WWF_int
	jns	checkY

	;    If x scale is negative, make it positive and adjust angles.
	;    Swap start and end. Subtract start and end from 180.
	;

	negwwf	ss:[si].GOSD_xScale

	movwwf	bxax,ds:[di].AI_startAngle
	movwwf	dxcx,ds:[di].AI_endAngle
	push	dx,cx					;endAngle
	mov	dx,180
	clr	cx
	subwwf	dxcx,bxax
	call	GrObjNormalizeDegrees
	movwwf	ds:[di].AI_endAngle,dxcx
	pop	bx,ax					;orig end angle
	mov	dx,180
	clr	cx
	subwwf	dxcx,bxax
	call	GrObjNormalizeDegrees
	movwwf	ds:[di].AI_startAngle,dxcx

checkY:
	;    The decompose routine always returns a positive scale,
	;    so we need to look at the rotation to see of our
	;    object has been flipped.
	;

	tst	matrix.GTM_e22.WWF_int
	jns	scale

	;    If y scale is negative, make it positive and adjust angles.
	;    Swap start and end. Negate start and end.
	;

	negwwf	ss:[si].GOSD_yScale

	movwwf	dxcx,ds:[di].AI_startAngle
	movwwf	bxax,ds:[di].AI_endAngle
	negwwf	dxcx
	call	GrObjNormalizeDegrees
	movwwf	ds:[di].AI_endAngle,dxcx
	negwwf	bxax
	movwwf	dxcx,bxax
	call	GrObjNormalizeDegrees
	movwwf	ds:[di].AI_startAngle,dxcx

scale:
	mov	ax,bp					;locals
	mov	bp,si					;GrObjScaleData
	pop	si					;object chunk
	mov	cl,HANDLE_CENTER
	call	GrObjScaleNormalRelativeOBJECT
	add	sp,size GrObjScaleData
	mov	bp,ax					;locals
	
	;    Calculate new points from our new angles
	;

	call	ArcCalcThreePoints

	call	ObjMarkDirty

	;
	;  Since the arc may have changed its start and end angles, we
	;  need to update the UI accordingly
	;

	mov	cx, mask GOUINT_GROBJ_SELECT
	mov	ax, MSG_GO_SEND_UI_NOTIFICATION
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
ArcCompensateAnglesForFlips		endp




GrObjRequiredExtInteractive2Code ends

GrObjTransferCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ArcWriteInstanceToTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Arc method for MSG_GO_WRITE_INSTANCE_TO_TRANSFER

Called by:	

Pass:		*ds:si = Arc object
		ds:di = Arc instance

		ss:[bp] - GrObjTransferParams

Return:		ss:[bp].GTP_curPos updated to point past data

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcWriteInstanceToTransfer	method dynamic	ArcClass,
				MSG_GO_WRITE_INSTANCE_TO_TRANSFER
	uses	cx,dx
	.enter

	mov	di, offset ArcClass
	call	ObjCallSuperNoLock

	;
	;  Write our Arc specific stuff out by pointing at our instance data
	;

	ArcDeref	di,ds,si
	segmov	es, ds

	add	di, offset AI_arcCloseType
	mov	cx, size ArcBasicInit
	call	GrObjWriteDataToTransfer

	.leave
	ret
ArcWriteInstanceToTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ArcReadInstanceFromTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Arc method for MSG_GO_READ_INSTANCE_FROM_TRANSFER

Called by:	

Pass:		*ds:si = Arc object
		ds:di = Arc instance

		ss:[bp] - GrObjTransferParams

Return:		ss:[bp].GTP_curPos updated to point past data

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ArcReadInstanceFromTransfer	method dynamic	ArcClass,
				MSG_GO_READ_INSTANCE_FROM_TRANSFER
	uses	cx,dx
	.enter

	mov	di, offset ArcClass
	call	ObjCallSuperNoLock

	;
	;  Read our Arc specific stuff out
	;

	ArcDeref	di,ds,si
	segmov	es, ds

	add	di, offset AI_arcCloseType
	mov	cx, size ArcBasicInit
	call	GrObjReadDataFromTransfer

	.leave
	ret
ArcReadInstanceFromTransfer	endm

GrObjTransferCode	ends
