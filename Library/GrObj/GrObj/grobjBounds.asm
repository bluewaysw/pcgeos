COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GrObj
MODULE:		GrObj
FILE:		grobjBounds.asm

AUTHOR:		Steve Scholl, Aug 21, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	8/21/92		Initial revision


DESCRIPTION:
	
		

	$Id: grobjBounds.asm,v 1.1 97/04/04 18:07:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjAlmostRequiredCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetBoundingRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the RectDWFixed that bounds the object in
		the dest gstate coordinate system

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - BoundingRectData
			destGState
			parentGState

RETURN:		
		ss:bp - BoundingRectData
			rect
	
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
GrObjGetBoundingRectDWFixed	method dynamic GrObjClass, 
						MSG_GO_GET_BOUNDING_RECTDWFIXED
	uses	dx
	.enter

	mov	bx,bp					;BoundingRectData

	sub	sp,size FourPointDWFixeds
	mov	bp,sp
	call	GrObjGenerateNormalFourPointDWFixeds
	mov	di,ss:[bx].BRD_parentGState
	mov	dx,ss:[bx].BRD_destGState
	call	GrObjCalcNormalDWFixedMappedCorners
	mov	di,ss
	mov	ds,di					;Rect segment
	mov	es,di					;FourPoints segment
	mov	si,bx					;rect offset
	mov	di,bp					;FourPoints offset
	call	GrObjGlobalSetRectDWFixedFromFourPointDWFixeds
	add	sp, size FourPointDWFixeds

	mov	bp,bx					;BoundingRectData

	.leave
	ret
GrObjGetBoundingRectDWFixed		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcPARENTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the document dimensions and store then in the
		instance data.
		This default handler treats the object as a 
		rectangle with no line width


PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		calculate the bounding RectDWFixed
		calculate the width and height from RectDWFixed
		store

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		nothing


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcPARENTDimensions method dynamic GrObjClass, 
					MSG_GO_CALC_PARENT_DIMENSIONS
	uses	ax,cx,dx,bp
	.enter

	call	GrObjCanGeometry?
	jnc	done

	sub	sp,size BoundingRectData
	mov	bp,sp

	mov	di,PARENT_GSTATE
	call	GrObjCreateGStateForBoundsCalc
	mov	ss:[bp].BRD_parentGState,di

	mov	di,PARENT_GSTATE
	call	GrObjCreateGStateForBoundsCalc
	mov	ss:[bp].BRD_destGState,di

	mov	ax,MSG_GO_GET_BOUNDING_RECTDWFIXED
	call	ObjCallInstanceNoLock

	call	GrObjCheckForUnbalancedPARENTDimensions

	CallMod GrObjGlobalGetWWFixedDimensionsFromRectDWFixed
EC <	ERROR_NC	BUG_IN_DIMENSIONS_CALC			>

	mov	di,ss:[bp].BRD_parentGState
	call	GrDestroyState
	mov	di,ss:[bp].BRD_destGState
	call	GrDestroyState
	add	sp, size BoundingRectData

	call	GrObjSetNormalPARENTDimensions

	call	GrObjExpandParentGroup

done:
	.leave
	ret

GrObjCalcPARENTDimensions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCheckForOptimizedBoundsCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the object has no rotation and the parent gstate
		has no rotation then when can use the default handler
		to calc our bounds instead of the path code. The default
		handler does bounds for a rectangle

CALLED BY:	INTERNAL UTILITY
		
PASS:		
		*ds:si - object
		ss:bp - BoundingRectData
			BRD_parentGState is set

RETURN:		
		stc - can do optimized calc
		clc - nope

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
	srs	12/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCheckForOptimizedBoundsCalc		proc	far
	class	GrObjClass 
	uses	ax,di,si,ds
	.enter

EC <	call	ECGrObjCheckLMemObject			>	

	AccessNormalTransformChunk	di,ds,si
	clr	ax
	cmp	ds:[di].OT_transform.GTM_e12.WWF_int,ax        
	jnz	fail
	cmp	ds:[di].OT_transform.GTM_e12.WWF_frac,ax        
	jnz	fail
	cmp	ds:[di].OT_transform.GTM_e21.WWF_int,ax        
	jnz	fail
	cmp	ds:[di].OT_transform.GTM_e21.WWF_frac,ax        
	jnz	fail

	mov	di,ss:[bp].BRD_parentGState
	sub	sp, size TransMatrix
	mov	si,sp
	segmov	ds,ss
	call	GrGetTransform
	cmp	ds:[si].TM_e12.WWF_int,ax        
	jnz	failClearStack
	cmp	ds:[si].TM_e12.WWF_frac,ax        
	jnz	failClearStack
	cmp	ds:[si].TM_e21.WWF_int,ax        
	jnz	failClearStack
	cmp	ds:[si].TM_e21.WWF_frac,ax        
	jnz	failClearStack
	add	sp,size TransMatrix
	
	stc
done:

	.leave
	ret

failClearStack:
	add	sp,size TransMatrix
fail:
	clc
	jmp	done

GrObjCheckForOptimizedBoundsCalc		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetDWFSelectionHandleBoundsForTrivialRejectProblems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Certain shapes, when rotated or skewed, do not have 
		selection handles that fall in or very close to the
		PARENT dimensions, for those cases we just return
		very large bounds. Otherwise call the super class
		

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - object
		di - offset of objects superclass
		es - class segment
		ss:bp - RectDWFixed

RETURN:		
		ss:bp - RectDWFixed

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
	srs	11/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetDWFSelectionHandleBoundsForTrivialRejectProblems	proc	far
	class	GrObjClass
	uses	bx
	.enter

EC <	call	ECGrObjCheckLMemObject>

	AccessNormalTransformChunk	bx,ds,si

	tst	ds:[bx].OT_transform.GTM_e12.WWF_int
	jnz	veryLarge
	tst	ds:[bx].OT_transform.GTM_e12.WWF_frac
	jnz	veryLarge
	tst	ds:[bx].OT_transform.GTM_e21.WWF_int
	jnz	veryLarge
	tst	ds:[bx].OT_transform.GTM_e21.WWF_frac
	jnz	veryLarge

	call	ObjCallSuperNoLock

done:
	.leave
	ret
	
veryLarge:
	call	GrObjReturnLargeRectDWFixed
	jmp	done


GrObjGetDWFSelectionHandleBoundsForTrivialRejectProblems		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjReturnLargeRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for filling a RectDWFixed with
		graphic system size dimensions

CALLED BY:	INTERNAL
		GrObjGetDWFSelectionHandleBoundsForTrivialRejectProblems

PASS:		ss:bp - RectDWFixed

RETURN:		ss:bp - RectDWFixed

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
	srs	11/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjReturnLargeRectDWFixed		proc	far
	uses	ax
	.enter

	mov	ax,0x8000
	mov	ss:[bp].RDWF_left.DWF_int.high,ax
	mov	ss:[bp].RDWF_top.DWF_int.high,ax
	
	dec	ax		; ax <- 0x7fff, high word of largest positive
				;  32-bit number
	mov	ss:[bp].RDWF_right.DWF_int.high, ax
	mov	ss:[bp].RDWF_bottom.DWF_int.high, ax

	clr	ax
	mov	ss:[bp].RDWF_left.DWF_int.low,ax
	mov	ss:[bp].RDWF_top.DWF_int.low,ax

	dec	ax		; ax <- 0xffff, low word of largest positive
				;  32-bit number
	mov	ss:[bp].RDWF_right.DWF_int.low,ax
	mov	ss:[bp].RDWF_bottom.DWF_int.low,ax

				; 0xffff is also fraction for largest positive
				;  DWF number
	mov	ss:[bp].RDWF_right.DWF_frac,ax
	mov	ss:[bp].RDWF_bottom.DWF_frac,ax

	inc	ax		; ax <- 0, for left & top fractions
	mov	ss:[bp].RDWF_left.DWF_frac,ax
	mov	ss:[bp].RDWF_top.DWF_frac,ax

	.leave
	ret
GrObjReturnLargeRectDWFixed		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetBoundingRectDWFixedFromPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use path stuff to fill in the BRD_rect.

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si
		ss:bp - BoundingRectData
RETURN:		
		BRD_rect

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
	srs	11/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetBoundingRectDWFixedFromPath		proc	far
	class	GrObjClass
	uses	ax,bx,cx,dx,di,es
	.enter

EC <	call	ECGrObjCheckLMemObject			>


	mov	di,ss:[bp].BRD_parentGState
	call	GrSaveTransform

	;
	;	Draw the object into the parent gstate's path
	;
	
	mov	di, ss:[bp].BRD_parentGState
	call	GrObjApplyNormalTransform
	movnf	cx, PCT_REPLACE
	call	GrBeginPath
		
	mov	dx, di					;dx <- gstate
	mov	ax, MSG_GO_DRAW_FG_LINE
	call	ObjCallInstanceNoLock

	call	GrEndPath

	push	ds, si				;object

	;    Because out path is associated with parentGstate we need to
	;    copy the destGState transformation to the parentGState
	;    to get the bounds in the dest coordinate system
	;

	sub	sp, size TransMatrix
	mov	si, sp
	segmov	ds, ss
	mov	di, ss:[bp].BRD_destGState
	call	GrGetTransform
	mov	di, ss:[bp].BRD_parentGState
	call	GrSetTransform
	add	sp, size TransMatrix

	;    Get the bounds of the path

	sub	sp,size RectDWord
	mov	bx,sp				; ds:bx -> RectDWord
	mov	ax, GPT_CURRENT			; want current path
	call	GrGetPathBoundsDWord
EC <	ERROR_C BUG_IN_DIMENSIONS_CALC					>
NEC <	jc hackBoundsClearStack						>

	;    Copy RectDWord bounds to our RectDWFixed in
	;    BoundingRectData stack frame
	;

	movdw	dxax,ds:[bx].RD_left
	movdw	ss:[bp].BRD_rect.RDWF_left.DWF_int,dxax
	movdw	dxax,ds:[bx].RD_top
	movdw	ss:[bp].BRD_rect.RDWF_top.DWF_int,dxax
	movdw	dxax,ds:[bx].RD_right
	movdw	ss:[bp].BRD_rect.RDWF_right.DWF_int,dxax
	movdw	dxax,ds:[bx].RD_bottom
	movdw	ss:[bp].BRD_rect.RDWF_bottom.DWF_int,dxax
	add	sp,size RectDWord

	pop	ds, si					;object

	;    Clear fractions in BoundingRectData
	;

	clr	ax
	mov	ss:[bp].BRD_rect.RDWF_left.DWF_frac, ax
	mov	ss:[bp].BRD_rect.RDWF_top.DWF_frac, ax
	mov	ss:[bp].BRD_rect.RDWF_right.DWF_frac, ax
	mov	ss:[bp].BRD_rect.RDWF_bottom.DWF_frac, ax

	mov	di,ss:[bp].BRD_parentGState
	call	GrRestoreTransform

	;    HACK ???. Currently GrGetPathBounds returns all
	;    8000h for the bounds if nothing was drawn.
	;    This fucks up the unbalanced center code.
	;

	cmp	ss:[bp].BRD_rect.RDWF_left.DWF_int.low,8000h
	je	hackBounds

	;    Sometimes the object has no space so the
	;    path code returns very large bounds. Be robust about it.
	;

	CheckHack	< (offset BRD_rect eq 0) >
	mov	dx,0x7000
	clr	cx
	call	GrObjGlobalCheckWWFixedDimensionsOfRectDWFixed
	jnc	hackBounds

done:
	.leave
	ret


ife	ERROR_CHECK	
hackBoundsClearStack:
	pop	ds,si
	add	sp,size RectDWord
endif
hackBounds:
	;    Set bounds to be very narrow and at the center
	;

	push	ds,si
	AccessNormalTransformChunk	di,ds,si
	segmov	es,ds,ax
	segmov	ds,ss,ax
	add	di,offset OT_center
	mov	si,bp
	call	GrObjGlobalInitRectDWFixedWithPointDWFixed
	pop	ds,si
	jmp	done


GrObjGetBoundingRectDWFixedFromPath		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCreateGStateForBoundsCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a gstate with no window and no body translation
		for use during bounds calculations

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - object requesting gstate
		di - GrObjCreateGStateType
			only OBJECT_GSTATE and PARENT_GSTATE are lega

RETURN:		
		di - gstate

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCreateGStateForBoundsCalc		proc	far
	class	GrObjClass
	uses	ax,bp
	.enter

EC <	call	ECGrObjCheckLMemObject			>	

	push	di					;GrObjCreateGStateType

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags,mask GOOF_IN_GROUP
	jz	notInGroup

	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GROUP_CREATE_GSTATE_FOR_BOUNDS_CALC
	call	GrObjMessageToGroup
	mov	di,bp

checkType:
	pop	ax					;GrObjCreateGStateType
	cmp	ax,PARENT_GSTATE
	je	done
	call	GrObjApplyNormalTransform

done:
	.leave
	ret

notInGroup:
	clr	di				;no window
	call	GrCreateState
	jmp	checkType

GrObjCreateGStateForBoundsCalc		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjExpandParentGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GROUP_EXPAND to our parent group if we are in one

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object

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
	srs	11/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjExpandParentGroup		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject		>

	GrObjDeref	di,ds,si

	;    GrObjs are marked invalid while they are being ungrouped
	;    and we don't want the group to be recalcing its bounds
	;    while objects are being removed from it. This is
	;    a concern when undoing a grouping because the group
	;    is not suspended which would normal prevent it from 
	;    recalcing.
	;

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done
	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP
	jnz	sendMessage
	
done:
	.leave
	ret

sendMessage:
	clr	di
	mov	ax,MSG_GROUP_EXPAND
	call	GrObjMessageToGroup
	jmp	done

GrObjExpandParentGroup		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCheckForUnbalancedPARENTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that center of BRD_rect is at the center of the
		object (OT_center in GOI_normalTransform chunk). If
		not then store offset in vardata and set unbalanced
		bit in instance data.

CALLED BY:	INTERNAL
		GrObjCalcPARENTDimensions

PASS:		
		*ds:si - object
		ss:bp - BoundingRectData
			BRD_rect - filled in

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
	srs	11/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCheckForUnbalancedPARENTDimensions		proc	far
	class	GrObjClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	;    Assume
	;

	GrObjDeref	di,ds,si
	BitClr	ds:[di].GOI_optFlags,GOOF_HAS_UNBALANCED_PARENT_DIMENSIONS
	mov	ax,ATTR_GO_PARENT_DIMENSIONS_OFFSET
	call	ObjVarDeleteData


	;    Calc X and Y centers of bounding rect
	;

	movdwf	dxcxbx,ss:[bp].BRD_rect.RDWF_right
	subdwf	dxcxbx,ss:[bp].BRD_rect.RDWF_left
	sardwf	dxcxbx
	adddwf	dxcxbx,ss:[bp].BRD_rect.RDWF_left
	pushdwf	dxcxbx					;x of bounds center

	movdwf	cxaxbx,ss:[bp].BRD_rect.RDWF_bottom
	subdwf	cxaxbx,ss:[bp].BRD_rect.RDWF_top
	sardwf	cxaxbx
	adddwf	cxaxbx,ss:[bp].BRD_rect.RDWF_top

	AccessNormalTransformChunk	di,ds,si
	subdwf	cxaxbx,ds:[di].OT_center.PDF_y
	cwd
	cmp	cx,dx
EC <	ERROR_NE GROBJ_VERY_UNBALANCED_PARENT_BOUNDS		>	

	;    If the difference is greater than one or less
	;    then negative one then store offset
	;

	cmp	ax,1
	jg	addYVarData
	jl	10$
	tst	bx
	jnz	addYVarData
10$:
	cmp	ax,-1
	jl	addYVarData

checkX:
	AccessNormalTransformChunk	di,ds,si
	popdwf	cxaxbx
	subdwf	cxaxbx,ds:[di].OT_center.PDF_x
	cwd
	cmp	cx,dx
EC <	ERROR_NE GROBJ_VERY_UNBALANCED_PARENT_BOUNDS		>	

	;    If the difference is greater than one or less
	;    then negative one then store offset
	;

	cmp	ax,1
	jg	addXVarData
	jl	20$
	tst	bx
	jnz	addXVarData
20$:
	cmp	ax,-1
	jl	addXVarData

done:
	.leave
	ret


addYVarData:
	movwwf	dxcx,axbx
	mov	di,offset PF_y
	call	GrObjStoreUnbalancedPARENTDimensionsOffsetPiece
	jmp	checkX

addXVarData:
	movwwf	dxcx,axbx
	mov	di,offset PF_x
	call	GrObjStoreUnbalancedPARENTDimensionsOffsetPiece
	jmp	done


GrObjCheckForUnbalancedPARENTDimensions		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjStoreUnbalancedPARENTDimensionsOffsetPiece
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find or Add the ATTR_GO_PARENT_DIMENSIONS_OFFSET vardata
		and put in the passed info.

CALLED BY:	INTERNAL
		GrObjCheckForUnbalancedPARENTDimensions

PASS:		*ds:si - object
		dxcx - WWFixed x or y offset
		di - offset into PointWWFixed to store data
	
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
	srs	11/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjStoreUnbalancedPARENTDimensionsOffsetPiece		proc	near
	class	GrObjClass
	uses	ax,bx,di
	.enter
EC <	call	ECGrObjCheckLMemObject			>

	mov	ax,ATTR_GO_PARENT_DIMENSIONS_OFFSET
	call	ObjVarFindData
	jnc	addData

storeData:
	add	bx,di
	movwwf	ds:[bx],dxcx

	GrObjDeref	di,ds,si
	BitSet	ds:[di].GOI_optFlags,GOOF_HAS_UNBALANCED_PARENT_DIMENSIONS
	call	ObjMarkDirty

	.leave
	ret

addData:
	push	cx
	mov	ax,ATTR_GO_PARENT_DIMENSIONS_OFFSET
	mov	cx,size PointWWFixed
	call	ObjVarAddData
	pop	cx
	jmp	storeData

GrObjStoreUnbalancedPARENTDimensionsOffsetPiece		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcNormalDWFixedMappedCorners
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the four points in OBJECT coords into the
		coordinate system of the dest gstate
		

CALLED BY:	INTERNAL UTILITY


PASS:		
		*ds:si - object
		ss:bp - FourPointDWFixeds - OBJECT COORDS
		di - parent gstate
		dx - dest gstate

RETURN:		
		ss:bp - FourDWPoints - DEST COORDS

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcNormalDWFixedMappedCorners		proc	far
	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject			>	

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTCalcDWFixedMappedCorners

	.leave
	ret
GrObjCalcNormalDWFixedMappedCorners		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTCalcDWFixedMappedCorners
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the four points in OBJECT coords into the
		coordinate system of the dest gstate
		

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - ObjectTransform
		ss:bp - FourPointDWFixeds - OBJECT COORDS
		di - parent gstate
		dx - dest gstate

RETURN:		
		ss:bp - FourDWPoints - DEST COORDS

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTCalcDWFixedMappedCorners		proc	far
	uses	dx,es,si
	.enter

	call	GrObjCheckGrObjTransMatrixForIdentity
	pushf
	jc	doConvert

	call	GrSaveTransform
	call	GrObjOTApplyObjectTransform

doConvert:
	segmov	es,ss					;FPDWF segment
	mov	si,dx					;dest gstate

	mov	dx,bp					;offset FPDF_TL
	call	GrObjConvertCoordDWFixed

	add	dx,size PointDWFixed			;offset FPDF_TR
	call	GrObjConvertCoordDWFixed

	add	dx,size PointDWFixed			;offset FPDF_BL
	call	GrObjConvertCoordDWFixed

	add	dx,size PointDWFixed			;offset FPDF_BR
	call	GrObjConvertCoordDWFixed

	popf
	jc	done
	call	GrRestoreTransform

done:
	.leave
	ret
GrObjOTCalcDWFixedMappedCorners		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateNormalFourPointDWFixeds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in FourPointDWFixeds structure from width and
		height of object
		-w/2,-h/2,w/2,h/2


CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - instance data
		ss:bp - FourPointDWFixeds	 - empty

RETURN:		
		ss:bp - FourDWPoints - filled

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		nothing
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateNormalFourPointDWFixeds		proc	far
	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject		>

	AccessNormalTransformChunk		si,ds,si
	call	GrObjOTGenerateFourPointDWFixeds

	.leave
	ret
GrObjGenerateNormalFourPointDWFixeds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTGenerateFourPointDWFixeds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in FourPointDWFixeds structure from width and
		height of object
		-w/2,-h/2,w/2,h/2


CALLED BY:	INTERNAL

PASS:		
		ds:si - ObjectTransform
		ss:bp - FourPointDWFixeds	 - empty

RETURN:		
		ss:bp - FourDWPoints - filled

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		nothing
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTGenerateFourPointDWFixeds		proc	far
	class	GrObjClass
	uses	ax,bx,cx,dx,di,es
	.enter

	;    Get dimensions divided by two
	;

	CallMod	GrObjOTGetOBJECTDimensions

	sar	dx,1				;width/2 int
	rcr	cx,1				;width/2 frac

	sar	bx,1				;height/2 int
	rcr	ax,1				;height/2 frac

	;    Store bottom as height/2 and top as -height/2
	;

	push	dx				;width int
	xchg	bx,ax				;bx <- height frac
						;ax <- height int
	cwd					;sign extend height/2
	movdwf	ss:[bp].FPDF_BR.PDF_y, dxaxbx
	movdwf	ss:[bp].FPDF_BL.PDF_y, dxaxbx
	negdwf	dxaxbx
	movdwf	ss:[bp].FPDF_TR.PDF_y, dxaxbx
	movdwf	ss:[bp].FPDF_TL.PDF_y, dxaxbx

	;    Store right as width/2 and left as -width/2
	;

	pop	ax				;width int
	cwd					;sign extend width/2
	movdwf	ss:[bp].FPDF_BR.PDF_x, dxaxcx
	movdwf	ss:[bp].FPDF_TR.PDF_x, dxaxcx
	negdwf	dxaxcx
	movdwf	ss:[bp].FPDF_BL.PDF_x, dxaxcx
	movdwf	ss:[bp].FPDF_TL.PDF_x, dxaxcx

	.leave
	ret
GrObjOTGenerateFourPointDWFixeds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertCoordDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a DWFixed coordinate from one coordinate system
		to another by transforming it through a gstate into
		device coordinates and then untransforming it through
		a different gstate into the new coordinate system

CALLED BY:	INTERNAL
		GrObjOTCalcDWFixedMappedCorners
		

PASS:		
		es:dx - PointDWFixed
		di - transform/source gstate
		si - untransform/dest gstate

RETURN:		
		es:dx - Transformed PointDWFixed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertCoordDWFixed		proc	far
	.enter

EC <	call	ECCheckGStateHandle		;check source gstate >
	call	GrTransformDWFixed		
	xchg	di,si				;source in si, dest in di
EC <	call	ECCheckGStateHandle		;check dest gstate	>
	call	GrUntransformDWFixed
	xchg	di,si				;source in di, dest in si 

	.leave
	ret
GrObjConvertCoordDWFixed		endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAdjustRectDWFixedByLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand RectDWFixed to encompass line width of object

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
GrObjAdjustRectDWFixedByLineWidth		proc	far
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

	;    Divide line width by two
	;

	sar	dx,1
	rcr	cx,1

	;    Expand rect by half line width
	;

	segmov	ds,ss
	mov	si,bp
	CallMod	GrObjGlobalExpandRectDWFixedByDWFixed

	.leave
	ret
GrObjAdjustRectDWFixedByLineWidth		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetNormalPARENTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the width and height of the object in the DOCUMENT
		COORD SYSTEM in the object's instance data

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		dx:cx - width
		bx:ax - height

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
	srs	10/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetNormalPARENTDimensions		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	call	ObjMarkDirty
	AccessNormalTransformChunk	di,ds,si

	mov	ds:[di].OT_parentWidth.WWF_int,dx
	mov	ds:[di].OT_parentWidth.WWF_frac,cx
	mov	ds:[di].OT_parentHeight.WWF_int,bx
	mov	ds:[di].OT_parentHeight.WWF_frac,ax

	.leave
	ret

GrObjSetNormalPARENTDimensions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetWWFOBJECTBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the RectWWFixed that surrounds the children in
		its OBJECT coordinate system

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - RectWWFixed

RETURN:		
		ss:bp - RectWWFixed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetWWFOBJECTBounds method  GrObjClass, MSG_GO_GET_WWF_OBJECT_BOUNDS
	uses	ax,bx,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjGetAbsNormalOBJECTDimensions

	;    Get width/2
	;

	sar	dx,1					;width/2 int
	rcr	cx,1					;width/2 frac

	;   Put width/2 in right
	;   Put -width/2 in left
	;

	mov	ss:[bp].RWWF_right.WWF_frac, cx
	mov	ss:[bp].RWWF_right.WWF_int, dx
	NegWWFixed 	dx,cx
	mov	ss:[bp].RWWF_left.WWF_frac, cx		
	mov	ss:[bp].RWWF_left.WWF_int, dx

	;    Get height/2
	;

	sar	bx,1					;height/2 int
	rcr	ax,1					;height/2 frac

	;   Put  height/2 in bottom
	;   Put -height/2 in top
	;

	mov	ss:[bp].RWWF_bottom.WWF_frac, ax
	mov	ss:[bp].RWWF_bottom.WWF_int, bx
	NegWWFixed	bx,ax
	mov	ss:[bp].RWWF_top.WWF_frac, ax
	mov	ss:[bp].RWWF_top.WWF_int, bx


	.leave
	ret
GrObjGetWWFOBJECTBounds		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInitBoundingRectDataByPointWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the BRD_rect with the passed point
		converted into the destination coordinate system

CALLED BY:	INTERNAL UTILITY

PASS:		
		ss:bp - BoundingRectData
		dxcx,bxax - wwfixed point

RETURN:		
		ss:bp - BRD_rect

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
	srs	9/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInitBoundingRectDataByPointWWFixed		proc	far
	uses	ax,bx,cx,dx,di,si,es,ds
	.enter

	;    Create PointDWFixed from PointWWFixed
	;

	sub	sp, size PointDWFixed
	mov	di,sp
	push	dx				;width int
	xchg	bx,ax				;bx <- height frac
						;ax <- height int
	cwd					;sign extend height/2
	movdwf	ss:[di].PDF_y,dxaxbx
	pop	ax				;width int
	cwd					;sign extend width/2
	movdwf	ss:[di].PDF_x,dxaxcx

	;    Transform point to destination coordinate system
	;

	mov	dx,di				;offset PointDWFixed
	mov	di,ss:[bp].BRD_parentGState
	mov	si,ss:[bp].BRD_destGState
	segmov	es,ss
	call	GrObjConvertCoordDWFixed

	;    Init bounding rect around point
	;

	mov	di,dx				;offset PointDWFixed
	segmov	ds,ss				;segment bounding rect
	mov	si,bp				;offset bounding rect
	call	GrObjGlobalInitRectDWFixedWithPointDWFixed

	add	sp, size PointDWFixed

	.leave
	ret
GrObjInitBoundingRectDataByPointWWFixed		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjExpandBoundingRectDataByPointWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand the BRD_rect with the passed point
		converted into the destination coordinate system

CALLED BY:	INTERNAL UTILITY

PASS:		
		ss:bp - BoundingRectData
		dxcx,bxax - wwfixed point

RETURN:		
		ss:bp - BRD_rect

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
	srs	9/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjExpandBoundingRectDataByPointWWFixed		proc	far
	uses	ax,bx,cx,dx,di,si,es,ds
	.enter

	;    Create PointDWFixed from PointWWFixed
	;

	sub	sp, size PointDWFixed
	mov	di,sp
	push	dx				;width int
	xchg	bx,ax				;bx <- height frac
						;ax <- height int
	cwd					;sign extend height/2
	movdwf	ss:[di].PDF_y,dxaxbx
	pop	ax				;width int
	cwd					;sign extend width/2
	movdwf	ss:[di].PDF_x,dxaxcx

	;    Transform point to destination coordinate system
	;

	mov	dx,di				;offset PointDWFixed
	mov	di,ss:[bp].BRD_parentGState
	mov	si,ss:[bp].BRD_destGState
	segmov	es,ss
	call	GrObjConvertCoordDWFixed

	;    Expand bounding rect around point
	;

	mov	di,dx				;offset PointDWFixed
	segmov	ds,ss				;segment bounding rect
	mov	si,bp				;offset bounding rect
	call	GrObjGlobalCombineRectDWFixedWithPointDWFixed

	add	sp, size PointDWFixed

	.leave
	ret
GrObjExpandBoundingRectDataByPointWWFixed		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjIsPointInsideObjectBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine's if the passed point is inside this GrObject's
		bounds.

CALLED BY:	MSG_GO_IS_POINT_INSIDE_OBJECT_BOUNDS
PASS:		*ds:si	= GrObjClass object
		ds:di	= GrObjClass instance data
		ds:bx	= GrObjClass object (same as *ds:si)
		es 	= segment of GrObjClass
		ax	= message #
		ss:bp	= PointDWFixed
		dx	= size PointDWFixed
		
RETURN: carry:	SET	- Point is inside bounds
		CLEAR	- Point is NOT inside bounds

DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjIsPointInsideObjectBounds	method dynamic GrObjClass, 
					MSG_GO_IS_POINT_INSIDE_OBJECT_BOUNDS
	uses	bp
	.enter
	
	; Don't do anything if this is the floater.
	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER	; clc implied
	jnz	exit
	
	; Allocate space for the bound rectangle on the stack
	mov	bx, bp					; ss:bx = PointDWFixed
	sub	sp, size RectDWFixed
	mov	bp, sp					; ss:bp = RectDWFixed
	
	; Get my bounds
	mov	ax, MSG_GO_GET_DWF_PARENT_BOUNDS
	call	ObjCallInstanceNoLock
	
	; Set up arguments for utility routine
	
	mov	si, ss
	mov	ds, si
	mov	es, si
	mov	si, bp
	mov	di, bx
	
	; ds:si = RectDWFixed - bounds of the object
	; es:di = PointDWFixed - position to test
	
	call	GrObjGlobalIsPointDWFixedInsideRectDWFixed?
	lahf						; save C flag
	
	add	sp, size RectDWFixed			; restore stack
	sahf						; restore C flag
	
exit:
	.leave
	ret
GrObjIsPointInsideObjectBounds	endm


GrObjAlmostRequiredCode ends

GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetDWPARENTBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns RectDWord bounds of object in the PARENT coordinate
		system

PASS:		
		*(ds:si) - instance data of object
		ss:bp - RectDWord 

RETURN:		
		ss:bp - RectDWord

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetDWPARENTBounds method  GrObjClass, MSG_GO_GET_DW_PARENT_BOUNDS
	uses	bx,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	sub	sp,size RectDWFixed
	mov	bx,bp					;RectDWord
	mov	bp,sp
	call	GrObjGetDWFPARENTBounds

	;    Floor of left
	;
	
	mov	ax,ss:[bp].RDWF_left.DWF_int.high
	mov	ss:[bx].RD_left.high,ax
	mov	ax,ss:[bp].RDWF_left.DWF_int.low
	mov	ss:[bx].RD_left.low,ax

	;    Floor of top
	;

	mov	ax,ss:[bp].RDWF_top.DWF_int.high
	mov	ss:[bx].RD_top.high,ax
	mov	ax,ss:[bp].RDWF_top.DWF_int.low
	mov	ss:[bx].RD_top.low,ax

	;    Ceiling of right 
	;

	movdwf	dxaxcx,ss:[bp].RDWF_right
	jcxz	10$
	adddw	dxax,1
10$:
	movdw	ss:[bx].RD_right,dxax

	;    Ceiling of bottom
	;

	movdwf	dxaxcx,ss:[bp].RDWF_bottom
	jcxz	20$
	adddw	dxax,1
20$:
	movdw	ss:[bx].RD_bottom,dxax

	add	sp,size RectDWFixed
	mov	bp,bx					;RectDWord

	.leave
	ret
GrObjGetDWPARENTBounds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetNormalPARENTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width and height of the object in the DOCUMENT
		COORD SYSTEM from the object's instance data

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object

RETURN:		
		dx:cx - width
		bx:ax - height

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetNormalPARENTDimensions		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	AccessNormalTransformChunk	di,ds,si
	mov	dx,ds:[di].OT_parentWidth.WWF_int
	mov	cx,ds:[di].OT_parentWidth.WWF_frac
	mov	bx,ds:[di].OT_parentHeight.WWF_int
	mov	ax,ds:[di].OT_parentHeight.WWF_frac
	.leave
	ret


GrObjGetNormalPARENTDimensions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetDWFPARENTBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns DWFixed bounds of object in PARENT coordinate system

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - RectDWFixed

RETURN:		
		ss:bp - RectDWFixed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetDWFPARENTBounds method  GrObjClass, MSG_GO_GET_DWF_PARENT_BOUNDS
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjGetNormalPARENTDimensions

	;    Initialize the rect from the dimensions
	;

	push	bx,ax					;height
	sarwwf	dxcx					;width
	mov	ax,dx
	cwd
	movdwf	ss:[bp].RDWF_right,dxaxcx
	negdwf	dxaxcx
	movdwf	ss:[bp].RDWF_left,dxaxcx
	pop	ax,bx					;height (reg switch)
	sarwwf	axbx					;width
	cwd
	movdwf	ss:[bp].RDWF_bottom,dxaxbx
	negdwf	dxaxbx
	movdwf	ss:[bp].RDWF_top,dxaxbx

	AccessNormalTransformChunk	di,ds,si

	movdwf	cxbxax,ds:[di].OT_center.PDF_x
	adddwf	ss:[bp].RDWF_left,cxbxax
	adddwf	ss:[bp].RDWF_right,cxbxax
	movdwf	cxbxax,ds:[di].OT_center.PDF_y
	adddwf	ss:[bp].RDWF_top,cxbxax
	adddwf	ss:[bp].RDWF_bottom,cxbxax

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags,mask GOOF_HAS_UNBALANCED_PARENT_DIMENSIONS
	jnz	unbalanced

done:
	.leave
	ret

unbalanced:
	mov	ax,ATTR_GO_PARENT_DIMENSIONS_OFFSET
	call	ObjVarFindData
EC <	ERROR_NC	GROBJ_MISSING_PARENT_DIMENSIONS_OFFSET	>	

	movwwf	axcx,ds:[bx].PF_x
	cwd
	adddwf	ss:[bp].RDWF_left,dxaxcx
	adddwf	ss:[bp].RDWF_right,dxaxcx
	movwwf	axcx,ds:[bx].PF_y
	cwd
	adddwf	ss:[bp].RDWF_top,dxaxcx
	adddwf	ss:[bp].RDWF_bottom,dxaxcx
	jmp	done

GrObjGetDWFPARENTBounds		endp

GrObjDrawCode	ends


GrObjRequiredInteractiveCode	segment resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOptGetDWFSelectionHandleBoundsForTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GO_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
		or call the default handler directly depending on the 
		GrObjMessageOptimizationFlags

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - grobject

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			opt bit not set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOptGetDWFSelectionHandleBoundsForTrivialReject		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_msgOptFlags, \
		mask GOMOF_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	jnz	send

	call	GrObjGetDWFSelectionHandleBoundsForTrivialReject

done:
	.leave
	ret

send:
	push	ax
	mov	ax,MSG_GO_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	call	ObjCallInstanceNoLock
	pop	ax
	jmp	done

GrObjOptGetDWFSelectionHandleBoundsForTrivialReject		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetDWFSelectionHandleBoundsForTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the rectangle that surrounds the object and 
		anything that might stick off the object, like
		its handles. The rectangle is in document coords.

		This routine is only valid on objects that are not
		in groups.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - RectDWFixed

RETURN:		
		ss:bp - RectDWFixed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.

		This method should be optimized for SPEED over SMALL SIZE 
		because it is called from ObjCompProcessChildren during
		hit detection.

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetDWFSelectionHandleBoundsForTrivialReject method  GrObjClass, 
	MSG_GO_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	uses	ax,bx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>
EC <	push	di						>
EC <	GrObjDeref	di,ds,si					>
EC <	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP		>
EC <	ERROR_NZ	OBJECT_CANNOT_BE_IN_A_GROUP		>
EC <	pop	di						>

	call	GrObjGetDWFPARENTBounds

	;    Choose the extension from the of half the handle
	;    size

	call	GrObjGetCurrentHandleSize
	mov	dx,bx					;handle sizes
	clr	bh					;leave width
	mov	dl,dh					;height
	clr	dh					;leave height
	shr	bl,1					;half width
	shr	dl,1					;half height

	;    Extend the bounds
	;

	clr	ax
	sub	ss:[bp].RDWF_left.DWF_int.low,bx
	sbb	ss:[bp].RDWF_left.DWF_int.high,ax
	add	ss:[bp].RDWF_right.DWF_int.low,bx
	adc	ss:[bp].RDWF_right.DWF_int.high,ax
	sub	ss:[bp].RDWF_top.DWF_int.low,dx
	sbb	ss:[bp].RDWF_top.DWF_int.high,ax
	add	ss:[bp].RDWF_bottom.DWF_int.low,dx
	adc	ss:[bp].RDWF_bottom.DWF_int.high,ax


	.leave
	ret
GrObjGetDWFSelectionHandleBoundsForTrivialReject		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetWWFPARENTBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the RectWWFixed that surrounds the children in
		is parent coordinate system.

		Only children in groups are guaranteed to have 
		bounds that can be expressed in WWFixed so this
		message can only be sent to children in groups

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - RectWWFixed

RETURN:		
		ss:bp - RectWWFixed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetWWFPARENTBounds method  GrObjClass, MSG_GO_GET_WWF_PARENT_BOUNDS
	uses	bx
	.enter

EC <	call	ECGrObjCheckLMemObject				>
EC <	push	di						>
EC <	GrObjDeref	di,ds,si					>
EC <	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP		>
EC <	ERROR_Z	OBJECT_NOT_IN_A_GROUP		>
EC <	pop	di						>

	sub	sp,size RectDWFixed
	mov	bx,bp					;RectDWord
	mov	bp,sp
	call	GrObjGetDWFPARENTBounds

	mov	ax,ss:[bp].RDWF_left.DWF_frac
	mov	ss:[bx].RWWF_left.WWF_frac,ax
	mov	ax,ss:[bp].RDWF_left.DWF_int.low
	mov	ss:[bx].RWWF_left.WWF_int,ax

	mov	ax,ss:[bp].RDWF_top.DWF_frac
	mov	ss:[bx].RWWF_top.WWF_frac,ax
	mov	ax,ss:[bp].RDWF_top.DWF_int.low
	mov	ss:[bx].RWWF_top.WWF_int,ax

	mov	ax,ss:[bp].RDWF_right.DWF_frac
	mov	ss:[bx].RWWF_right.WWF_frac,ax
	mov	ax,ss:[bp].RDWF_right.DWF_int.low
	mov	ss:[bx].RWWF_right.WWF_int,ax

	mov	ax,ss:[bp].RDWF_bottom.DWF_frac
	mov	ss:[bx].RWWF_bottom.WWF_frac,ax
	mov	ax,ss:[bp].RDWF_bottom.DWF_int.low
	mov	ss:[bx].RWWF_bottom.WWF_int,ax

	add	sp,size RectDWFixed
	mov	bp,bx					;RectDWord

	.leave
	ret
GrObjGetWWFPARENTBounds		endp


GrObjRequiredInteractiveCode	ends

GrObjExtNonInteractiveCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetDWFPARENTBoundsUpperLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns DWFixed upper left of the bounds of object 
		in PARENT coordinate system

PASS:		
		*(ds:si) - instance data of object

		ss:bp - PointDWFixed

RETURN:		
		ss:bp - PointDWFixed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED
	
		Common cases:
			none
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetDWFPARENTBoundsUpperLeft proc	far
	class	GrObjClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	call	GrObjGetNormalPARENTDimensions
	push	bx,ax					;height

	sar	dx,1					;width int
	rcr	cx,1					;width frac

	;   Put floor of (center - width/2) in PDF_x
	;

	AccessNormalTransformChunk	di,ds,si

	mov_tr	ax,dx					;width int
	cwd						;sign extend width
	mov_tr	bx, ax

	mov	ax, ds:[di].OT_center.PDF_x.DWF_frac
	sub	ax, cx
	mov	ss:[bp].PDF_x.DWF_frac, ax
	mov	ax, ds:[di].OT_center.PDF_x.DWF_int.low
	sbb	ax, bx
	mov	ss:[bp].PDF_x.DWF_int.low, ax
	mov	ax, ds:[di].OT_center.PDF_x.DWF_int.high
	sbb	ax, dx
	mov	ss:[bp].PDF_x.DWF_int.high, ax

	;    Get sign extend height/2 in dx:ax:cx
	;

	pop	ax,cx					;height
	sar	ax,1
	rcr	cx,1
	cwd
	mov_tr	bx, ax

	;   Put floor of center - height/2 in PDF_y
	;

	mov	ax, ds:[di].OT_center.PDF_y.DWF_frac
	sub	ax, cx
	mov	ss:[bp].PDF_y.DWF_frac, ax
	mov	ax, ds:[di].OT_center.PDF_y.DWF_int.low
	sbb	ax, bx
	mov	ss:[bp].PDF_y.DWF_int.low, ax
	mov	ax, ds:[di].OT_center.PDF_y.DWF_int.high
	sbb	ax, dx
	mov	ss:[bp].PDF_y.DWF_int.high, ax

	.leave
	ret
GrObjGetDWFPARENTBoundsUpperLeft		endp

GrObjExtNonInteractiveCode	ends
