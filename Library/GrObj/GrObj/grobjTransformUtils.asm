COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		graphicTransformUtils.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			
	----
INT GrObjMoveSpriteRelative	
INT GrObjMoveNormalRelative	
INT GrObjOTMoveRelative	
INT GrObjResizeSpriteRelative	
INT GrObjResizeNormalRelative	
INT GrObjResizeSpriteRelativeToSprite
INT GrObjOTAdditiveResizeRelative	
INT GrObjOTMultiplicativeResizeRelative	
INT GrObjInteractiveResizeSpriteRelative	
INT GrObjInteractiveResizeNormalRelative	
INT GrObjInteractiveResizeSpriteRelativeToSprite
INT GrObjOTInteractiveAdditiveResizeRelative	
INT GrObjOTInteractiveMultiplicativeResizeRelative	
INT GrObjRotateSpriteRelative	
INT GrObjRotateNormalRelative  
INT GrObjOTRotateRelative	
INT GrObjSkewSpriteRelative	
INT GrObjSkewNormalRelative	
INT GrObjOTSkewRelative	
INT GrObjScaleSpriteRelativeOBJECT
INT GrObjScaleSpriteRelativeToSpriteOBJECT
INT GrObjScaleNormalRelativeOBJECT
INT GrObjOTScaleRelativeOBJECT	

INT GrObjApplySpriteTransform		
INT GrObjApplyNormalTransform		
INT GrObjOTApplyObjectTransform	
INT GrObjOTApplyGrObjTransMatrix
INT GrObjApplyGrObjTransMatrix
INT GrObjApplyTranslationToNormalCenter
INT GrObjApplyTranslationToSpriteCenter
INT GrObjOTApplyTranslationToCenter	
INT GrObjOTGetOBJECTDimensions		
INT GrObjGetNormalOBJECTDimensions	
INT GrObjGetSpriteOBJECTDimensions	
INT GrObjOTGetAbsOBJECTDimensions		
INT GrObjGetAbsNormalOBJECTDimensions	
INT GrObjGetAbsSpriteOBJECTDimensions	
INT GrObjConvertNormalPARENTToWWFOBJECT
INT GrObjConvertNormalPARENTToWWFCENTERRELATIVE
INT GrObjApplyNormalTransformSansCenterTranslation		
INT GrObjOTConvertPARENTToOBJECT
INT GrObjConvertNormalPARENTToOBJECT
INT GrObjConvertNormalWWFVectorPARENTToOBJECT
INT GrObjOTConvertWWFVectorPARENTToOBJECT
INT GrObjOTConvertVectorPARENTToOBJECT
INT GrObjSetNormalOBJECTDimensions
INT GrObjSetSpriteOBJECTDimensions
INT GrObjOTSetOBJECTDimensions
INT GrObjSetNormalCenter
INT GrObjSetSpriteCenter
INT GrObjOTSetCenter

INT GrObjConvertNormalOBJECTToPARENT
INT GrObjConvertSpriteOBJECTToPARENT
INT GrObjConvertToPARENT
INT GrObjMoveNormalBackToAnchor
INT GrObjOTMoveBackToAnchor
INT GrObjTransformSpriteRelative
INT GrObjTransformNormalRelative
INT GrObjOTTransformRelative
INT GrObjOTGStateTransformCenterRelative
	
GrObjCheckGrObjTransMatrixForIdentity
GrObjSetOBJECTDimensionsAndIdentityMatrix		
GrObjOTSetGrObjTransMatrixFromGState
GrObjSetGrObjTransMatrixFromGState

GrObjOTApplyScaleRelative
GrObjOTApplyScaleRelative
GrObjOTApplyRotateRelative
GrObjOTApplySkewRelative

GrObjScaleSpriteRelative
GrObjScaleNormalRelative
GrObjOTScaleRelative


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
	Utililty routines for graphic class 
		

	$Id: grobjTransformUtils.asm,v 1.1 97/04/04 18:07:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



GrObjRequiredExtInteractiveCode segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMoveSpriteRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys move deltas to data in normalTransform and stores
		the results in the spriteTransform
		

CALLED BY:	INTERNAL
		GrObjPtrMove

PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed - deltas to move object in document coords

RETURN:		
		in spriteTransform
			center - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMoveSpriteRelative		proc	far
	class	GrObjClass
	uses	di,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	;   Get offset of spriteTransform in di
	;

	GrObjDeref	di,ds,si
	mov	si,di
	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	MISSING_SPRITE_TRANSFORM_CHUNK				>
	mov	di,ds:[di]

	;   Point ds:si at normalTransform and do move
	;

	mov	si,ds:[si].GOI_normalTransform
	mov	si,ds:[si]
	call	GrObjOTMoveRelative
	
	.leave
	ret
GrObjMoveSpriteRelative		endp

GrObjMoveSpriteRelativeToSprite		proc	far
	class	GrObjClass
	uses	di,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;   Point ds:di to spriteTransform
	;

	GrObjDeref	di,ds,si
	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	SPRITE_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]
	mov	si, di
	call	GrObjOTMoveRelative

	.leave
	ret

GrObjMoveSpriteRelativeToSprite		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMoveNormalRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys move deltas to data in normalTransform and stores
		the results back in the normalTransform. 
		

CALLED BY:	INTERNAL
		GrObjEndMove

PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed - deltas to move object in PARENT coords

RETURN:		
		in normalTransform
			center moved

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMoveNormalRelative		proc	far
	class	GrObjClass
	uses	ax,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	;   Point ds:si and ds:di at normalTransform and move object
	;

	push	si					;instance chunk
	AccessNormalTransformChunk	si,ds,si
	mov	di,si
	call	GrObjOTMoveRelative
	pop	si					;instance chunk

	.leave
	ret
GrObjMoveNormalRelative		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMoveNormalAbsolute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the normal transform to be centered on the passed point

CALLED BY:	INTERNAL
		GrObjEndMove

PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed

RETURN:		
		in normalTransform
			center moved

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMoveNormalAbsolute		proc	far
	class	GrObjClass
	uses	ax,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	;   Point ds:si and ds:di at normalTransform and move object
	;

	AccessNormalTransformChunk	si,ds,si

	movdwf	ds:[si].OT_center.PDF_x, ss:[bp].PDF_x, ax
	movdwf	ds:[si].OT_center.PDF_y, ss:[bp].PDF_y, ax

	.leave
	ret
GrObjMoveNormalAbsolute		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTMoveRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys deltas to object position stored in source
		ObjectTransform and stores the result in the
		dest ObjectTransform. Source and dest may be the
		same structure
		

CALLED BY:	INTERNAL

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		ss:bp - PointDWFixed, deltas to move object in document coords

RETURN:		
		ds:di.OT_center - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTMoveRelative		proc	near
	uses	ax,bx,cx
	.enter

	movdwf	cxbxax, ds:[si].OT_center.PDF_x
	adddwf	cxbxax, ss:[bp].PDF_x
	movdwf	ds:[di].OT_center.PDF_x, cxbxax

	movdwf	cxbxax, ds:[si].OT_center.PDF_y
	adddwf	cxbxax, ss:[bp].PDF_y
	movdwf	ds:[di].OT_center.PDF_y, cxbxax

	.leave
	ret
GrObjOTMoveRelative		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInteractiveResizeSpriteRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys resize deltas to data in normalTransform and 
		stores the results in the spriteTranform.

CALLED BY:	INTERNAL
		GrObjPtrResizeCommon

PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed - deltas to resize object 
		cl - GrObjHandleSpecification of anchor
		ch - GrObjHandleSpecification of grabbed handle

RETURN:		
		in spriteTransform
			OT_center - may have changed
			OT_width - may have changed
			OT_height - may have changed
			OT_transformFlags - may have changed
			OFT_transform - may have changed



DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInteractiveResizeSpriteRelative		proc	far
	class	GrObjClass
	uses	ax,di,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty


	GrObjDeref	di,ds,si
	mov	ax,ds:[di].GOI_attrFlags

	;   Point ds:di to spriteTransform
	;
	mov	si,di				
	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	SPRITE_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]

	;   Point ds:si at normalTransform and do resize
	;

	mov	si,ds:[si].GOI_normalTransform
EC <	tst	si							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	si,ds:[si]

	test	ax, mask GOAF_MULTIPLICATIVE_RESIZE
	jnz	mult
	call	GrObjOTInteractiveAdditiveResizeRelative

done:
	.leave
	ret
mult:
	call	GrObjOTInteractiveMultiplicativeResizeRelative
	jmp	done

GrObjInteractiveResizeSpriteRelative		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInteractiveResizeNormalRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys resize deltas to data in normalTransform and 
		stores the results in the normalTranform

CALLED BY:	INTERNAL
		GrObjSetSize

PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed - deltas to resize object 
		cl - GrObjHandleSpecification of anchor
		ch - GrObjHandleSpecification of grabbed handle

RETURN:		
		in normalTransform
			OT_center - may have changed
			OT_width - may have changed
			OT_height - may have changed
			OT_transformFlags - may have changed
			OFT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInteractiveResizeNormalRelative		proc	far
	class	GrObjClass
	uses	ax,di,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	GrObjDeref	di,ds,si
	mov	ax,ds:[di].GOI_attrFlags
	
	;   Point ds:di and ds:si to normalTransform
	;

	mov	di,ds:[di].GOI_normalTransform
EC <	tst	di							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]
	mov	si,di

	test	ax, mask GOAF_MULTIPLICATIVE_RESIZE
	jnz	mult
	call	GrObjOTInteractiveAdditiveResizeRelative

done:
	.leave
	ret
mult:
	call	GrObjOTInteractiveMultiplicativeResizeRelative
	jmp	done

GrObjInteractiveResizeNormalRelative		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInteractiveResizeSpriteRelativeToSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys resize deltas to data in spriteTransform and 
		stores the results in the spriteTranform

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed - deltas to resize object 
		cl - GrObjHandleSpecification of anchor
		ch - GrObjHandleSpecification of grabbed handle

RETURN:		
		in spriteTransform
			OT_center - may have changed
			OT_width - may have changed
			OT_height - may have changed
			OT_transformFlags - may have changed
			OFT_transform - may have changed



DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjInteractiveResizeSpriteRelativeToSprite		proc	far
	class	GrObjClass
	uses	di,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	GrObjDeref	di,ds,si
	mov	ax,ds:[di].GOI_attrFlags
	
	;   Point ds:di and ds:si to spriteTransform
	;

	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	SPRITE_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]
	mov	si,di

	test	ax, mask GOAF_MULTIPLICATIVE_RESIZE
	jnz	mult
	call	GrObjOTInteractiveAdditiveResizeRelative

done:
	.leave
	ret

mult:
	call	GrObjOTInteractiveMultiplicativeResizeRelative
	jmp	done

GrObjInteractiveResizeSpriteRelativeToSprite		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjResizeSpriteRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys resize deltas to data in normalTransform and stores
		the results in the spriteTransform
		

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data
		ss:bp - PointWDFixed - deltas to resize object in OBJECT coords
		cl - GrObjHandleSpecification of anchor

RETURN:		
		in spriteTransform
			OT_width - may have changed
			OT_height - may have changed
			OT_center - may have changed
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjResizeSpriteRelative		proc	far
	class	GrObjClass
	uses	ax,di,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	GrObjDeref	di,ds,si
	mov	ax,ds:[di].GOI_attrFlags

	;   Get offset of spriteTransform in di
	;

	mov	si,di
	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	MISSING_SPRITE_TRANSFORM_CHUNK				>
	mov	di,ds:[di]

	;   Point ds:si at normalTransform and do resize
	;

	mov	si,ds:[si].GOI_normalTransform
	mov	si,ds:[si]

	test	ax, mask GOAF_MULTIPLICATIVE_RESIZE
	jnz	mult

	call	GrObjOTAdditiveResizeRelative
	
done:
	.leave
	ret

mult:
	call	GrObjOTMultiplicativeResizeRelative
	jmp	done

GrObjResizeSpriteRelative		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjResizeSpriteRelativeToSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys resize deltas to data in spriteTransform and stores
		the results in the spriteTransform
		

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed - deltas to resize object in OBJECT coords
		cl - GrObjHandleSpecification of anchor

RETURN:		
		in spriteTransform
			OT_width - may have changed
			OT_height - may have changed
			OT_center - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjResizeSpriteRelativeToSprite		proc	far
	class	GrObjClass
	uses	di,si,ax
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	GrObjDeref	di,ds,si
	mov	ax,ds:[di].GOI_attrFlags

	;   Point ds:di and ds:si to spriteTransform
	;

	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	SPRITE_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]
	mov	si, di

	test	ax, mask GOAF_MULTIPLICATIVE_RESIZE
	jnz	mult

	call	GrObjOTAdditiveResizeRelative
done:
	.leave
	ret
mult:
	call	GrObjOTMultiplicativeResizeRelative
	jmp	done

GrObjResizeSpriteRelativeToSprite		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjResizeNormalRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys resize deltas to data in normalTransform and stores
		the results back in the normalTransform. 
		

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed - deltas to resize object in OBJECT coords
		cl - GrObjHandleSpecification of anchor

RETURN:		
		in normalTransform
			OT_width - may have changed
			OT_height - may have changed
			OT_center - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjResizeNormalRelative		proc	far
	class	GrObjClass
	uses	ax,si,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	GrObjDeref	di,ds,si
	mov	ax,ds:[di].GOI_attrFlags

	;   Point ds:si and ds:di at normalTransform and resize object
	;

	mov	di,ds:[di].GOI_normalTransform
EC <	tst	di							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]
	mov	si, di

	test	ax, mask GOAF_MULTIPLICATIVE_RESIZE
	jnz	mult

	call	GrObjOTAdditiveResizeRelative
done:
	.leave
	ret

mult:
	call	GrObjOTMultiplicativeResizeRelative
	jmp	done

GrObjResizeNormalRelative		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTInteractiveAdditiveResizeRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds resize deltas to object position stored in source
		ObjectTransform and stores the result in the
		dest ObjectTransform. Source and dest may be the
		same structure
		

CALLED BY:	INTERNAL
		GrObjInteractiveResizeNormalRelative
		GrObjInteractiveResizeSpriteRelative

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		ss:bp - PointDWFixed, deltas to resize in DOCUMENT/PARENT coords
		cl - GrObjHandleSpecification of anchor
		ch - GrObjHandleSpecification of grabbed handle

RETURN:		
		ds:di.OT_center - may have changed
		ds:di.OT_width - may have changed
		ds:di.OT_height - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTInteractiveAdditiveResizeRelative		proc	near
	uses	bx
	.enter
	
	;    Create new stack frame for holding OBJECT deltas
	;    

	sub	sp, size PointDWFixed
	mov	bx,sp
	call	GrObjOTCalcInteractiveSizeChange
	
	;   Do additive resize
	;
	
	xchg	bx,bp				;DOCUMENT change,OBJECT change
	call	GrObjOTAdditiveResizeRelative
	mov	bp,bx				;DOCUMENT change
	add	sp,size PointDWFixed

	.leave
	ret
GrObjOTInteractiveAdditiveResizeRelative		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTAdditiveResizeRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the size changes in OBJECT coords to the object

CALLED BY:	INTERNAL
		GrObjOTInteractiveAdditiveResizeRelative
		GrObjResizeNormalRelative
		GrObjResizeSpriteRelative
		GrObjResizeSpriteRelativeToSprite

PASS:	
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		ss:bp - PointDWFixed
			PDF_x - width change in OBJECT
			PDF_y - height change in OBJECT
		cl - GrObjHandleSpecification of anchor
		
RETURN:		
		ds:di.OT_center - may have changed
		ds:di.OT_transform - may have changed

DESTROYED:	
		ss:bp - PointDWFixed - destroyed

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTAdditiveResizeRelative		proc	near
	uses	ax,bx,cx,dx,es


anchorHandle	local	word \
		push	cx
anchorPoints	local	SrcDestPointDWFixeds

	.enter

	mov	bx,ss:[bp]			;passed stack frame

	;    The passed values are changes in absolute size
	;

	tst	ds:[si].OT_width.WWF_int
	jns	10$
	negdwf	ss:[bx].PDF_x
10$:
	tst	ds:[si].OT_height.WWF_int
	jns	20$
	negdwf	ss:[bx].PDF_y
20$:

	;    Make sure centers of source and dest ObjectTransform
	;    are the same
	;

	cmp	si, di
	je	inPlace

	push	si,di				;source, dest
	segmov	es,ds,cx
	add	si,offset OT_center
	add	di,offset OT_center
	MoveConstantNumBytes	<size PointDWFixed>, cx
	pop	si,di				;source, dest

inPlace:
	;    Calculate the initial position of the anchor point
	;

	push	bp				;stack frame
	mov	cx,anchorHandle			;cl gets GHS of anchor handle
	lea	bp,[anchorPoints.SDPDWF_source]
	call	GrObjOTGetPARENTHandleCoords
	pop	bp				;stack frame

	;    Add changes to width and height
	;
	
	movwwf	dxcx,ds:[si].OT_width
	add	cx,ss:[bx].PDF_x.DWF_frac
	adc	dx,ss:[bx].PDF_x.DWF_int.low
	movwwf	ds:[di].OT_width,dxcx

	movwwf	dxcx,ds:[si].OT_height
	add	cx,ss:[bx].PDF_y.DWF_frac
	adc	dx,ss:[bx].PDF_y.DWF_int.low
	movwwf	ds:[di].OT_height,dxcx

	;    Calc the final position of the anchored point
	;

	push	bp				;stack frame
	mov	cx,anchorHandle			;ch gets GHS of anchor handle
	lea	bp,[anchorPoints.SDPDWF_dest]
	xchg	di,si				;source, dest ObjectTransform
	call	GrObjOTGetPARENTHandleCoords
	pop	bp				;stack frame

	;    Move the object so that the anchored point
	;    stays in the same place
	;

	push	bp
	lea	bp,ss:[anchorPoints]
	call	GrObjOTMoveBackToAnchor
	xchg	si,di				;source, dest ObjectTransform
	pop	bp

	.leave
	ret

GrObjOTAdditiveResizeRelative		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTInteractiveMultiplicativeResizeRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calcs scale factor from resize deltas and applys it
		to object stored in source ObjectTransform and 
		stores the result in the
		dest ObjectTransform. Source and dest may be the
		same structure
		

CALLED BY:	INTERNAL
		GrObjInteractiveResizeNormalRelative
		GrObjInteractiveResizeSpriteRelative

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		ss:bp - PointDWFixed, deltas to resize in DOCUMENT/PARENT coords
		cl - GrObjHandleSpecification of anchor
		ch - GrObjHandleSpecification of grabbed handle

RETURN:		
		ds:di.OT_center - may have changed
		ds:di.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTInteractiveMultiplicativeResizeRelative		proc	near
	uses	bx
	.enter
	
	;    Create new stack frame for holding OBJECT deltas
	;    

	sub	sp, size PointDWFixed
	mov	bx,sp
	call	GrObjOTCalcInteractiveSizeChange
	
	;   Do scale
	;

	call	GrObjOTMultiplicativeResizeRelative
	add	sp,size PointDWFixed

	.leave
	ret
GrObjOTInteractiveMultiplicativeResizeRelative		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTMultiplicativeResizeRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc scale factor 

		current OBJECT dimensions + deltas to OBJECT dimensions
		-------------------------------------------------------
			current OBJECT dimensions

		and apply it to object.


CALLED BY:	INTERNAL

PASS:	
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		ss:bx - PointDWFixed
			PDF_x - width change in OBJECT
			PDF_y - height change in OBJECT
		cl - GrObjHandleSpecification of anchor
		
RETURN:		
		ds:di.OT_center - may have changed
		ds:di.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTMultiplicativeResizeRelative		proc	far
	uses	ax,bx,cx,dx
scale		local	GrObjScaleData
	.enter

	push	cx				;anchor

	;    Calc X scale factor (width change + width / width )
	;

	push	bx,bp				;delta buffer, stack frame
	movwwf	axbp,ds:[si].OT_width
	cwd					;sign extend current width
	adddwf	dxaxbp,ss:[bx].PDF_x
	mov	cx,ax				;new width int
	movwwf	bxax,ds:[si].OT_width
	call	GrSDivDWFbyWWF
	mov	ax,bp				;x scale factor frac
	pop	bx,bp				;delta buffer ,stack frame
	movwwf	scale.GOSD_xScale, cxax

	;    Calc Y scale factor (height change + height/ height)
	;

	push	bp				;stack frame
	movwwf	axbp,ds:[si].OT_height
	cwd					;sign extend current height
	adddwf	dxaxbp,ss:[bx].PDF_y
	mov	cx,ax				;new height int
	movwwf	bxax,ds:[si].OT_height
	call	GrSDivDWFbyWWF
	mov	ax,bp				;y scale factor frac
	pop	bp				;stack frame
	movwwf	scale.GOSD_yScale,cxax

	;    Apply the scale factor to the source GrObjTransMatrix
	;    and store it in the dest GrObjTransMatrix
	;

	pop	cx					;anchor
	push	bp					;frame
	lea	bp,ss:[scale]
	call	GrObjOTScaleRelativeOBJECT
	pop	bp					;frame

	.leave
	ret

GrObjOTMultiplicativeResizeRelative		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTCalcInteractiveSizeChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the change in width and height in OBJECT
		coordinates, based on deltas, grabbed handle and
		anchored handle

		NOTE: The resize deltas passed to this routine
		are in DOCUMENT coordinates. However the routine
		it is intended for use on objects being interactively
		resized, which means that the object is not in
		a group. If an object is not in a group then
		its PARENT and DOCUMENT coordinate systems are the
		same. So below you will see a call to
		GrObjOTConvertPARENTToOBJECT instead of a
		routine to convert DOCUMENTToOBJECT.

CALLED BY:	INTERNAL
		GrObjOTAdditiveResizeRelative

PASS:		
		ds:si - ObjectTransform defining OBJECT coordinates
		ss:bp - PointDWFixed - deltas in DOCUMENT/PARENT
		ss:bx - PointDWFixed - empty
		cl - GrObjHandleSpecification of anchor
		ch - GrObjHandleSpecification of grabbed handle

RETURN:		
		ss:bx - PointDWFixed - width and height deltas in OBJECT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	Size Change 
		Convert mouse deltas to OBJECT to
		get the direction and magnitude of the change in the
		object's coordinate system.

		Zero irrelevant deltas (if grabbed a middle handle)

		Calculate the Outward Delta (OD). A positive value means
		one edge is being pulled away from the other, a negative
		value means one is edge is moving toward the other (until
		the object flips over). The Outward Delta is calced by
		negating the corresponding OBJECT delta if the left
		or top handle is grabbed. (eg. if the OBJECT delta x is 
		positive but the left handle was grabbed, then the left
		edge is moving toward the right edge, a negative OD)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTCalcInteractiveSizeChange		proc	near
	uses	ax,di,es
	.enter

	xchg	bp,bx				;empty PDF, orig deltas PDF

	;    Copy deltas into a separate stack frame so we
	;    don't trash the originals
	;

	push	ds,si				;ObjectTransforms
	mov	si,bx				;original deltas
	segmov	ds,ss,ax			
	mov	es,ax
	mov	di,bp
	MoveConstantNumBytes	<size PointDWFixed>,ax
	pop	ds,si				;ObjectTransforms

	;    If resizing about center then double deltas to keep 
	;    corner of object on mouse
	;

	tst	cl
	jz	fromCenter
	cmp	cl,mask GrObjHandleSpecification
	jne	toObject

fromCenter:
	shldwf	ss:[bp].PDF_x
	shldwf	ss:[bp].PDF_y

toObject:
	;    See NOTE: in header
	;

	call	GrObjOTConvertVectorPARENTToOBJECT

	;   Zero irrelevant deltas if middle handles grabbed
	;

	test	ch, (mask GOHS_HANDLE_RIGHT or mask GOHS_HANDLE_LEFT ) 
	jnz	10$
	clrdwf	ss:[bp].PDF_x
10$:
	test	ch, (mask GOHS_HANDLE_BOTTOM or mask GOHS_HANDLE_TOP )
	jnz	20$
	clrdwf	ss:[bp].PDF_y
20$:

	;    Compensate for flip in sign of dimensions instead of
	;    in tranform
	;

	tst	ds:[si].OT_width.WWF_int
	jns	22$
	negdwf	ss:[bp].PDF_x
22$:

	tst	ds:[si].OT_height.WWF_int
	jns	25$
	negdwf	ss:[bp].PDF_y
25$:

	;   Calculate the Outward Deltas based on handle grabbed
	;

	test	ch,	mask GOHS_HANDLE_LEFT 

	jz	30$
	negdwf	ss:[bp].PDF_x
30$:
	test	ch,	mask GOHS_HANDLE_TOP
	jz	40$
	negdwf	ss:[bp].PDF_y
40$:

	xchg	bx,bp				;OBJECT PDF, orig deltas PDF

	.leave
	ret
GrObjOTCalcInteractiveSizeChange		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjRotateSpriteRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys rotate deltas to data in normal transform and
		stores the results in the spriteTransform

		[current matrix][rotate]

		This rotation is applied relative to the DOCUMENT axes.
		It will rotate the entire image without skewing it.
		This rotate is used during interactive rotate.

CALLED BY:	INTERNAL UTILITY
PASS:		
		*(ds:si) - instance data
		ss:bp - WWFixed delta of rotation change in degrees
		cl - GrObjHandleSpecification of anchor

RETURN:		
		GOI_spriteTransform.OT_degrees - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjRotateSpriteRelative		proc	far
	uses	ax,di,si	
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	GrObjDeref	di,ds,si			
	mov	si,di
	mov	si,ds:[si].GOI_normalTransform
EC <	tst	si							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	si,ds:[si]
	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	SPRITE_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]

	call	GrObjOTRotateRelative

	.leave
	ret
GrObjRotateSpriteRelative		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjRotateNormalRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys rotate deltas to data in normal transform and
		stores the results in the normalTransform

		[current matrix][rotate]

		This rotation is applied relative to the DOCUMENT axes.
		It will rotate the entire image without skewing it.
		This rotate is used during interactive rotate.

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data
		ss:bp - WWFixed delta of rotation change in degrees
		cl - GrObjHandleSpecification of anchor

RETURN:		
		GOI_normalTransform.OT_degrees - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjRotateNormalRelative		proc	far
	uses	ax,di,dx
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	call	ObjMarkDirty

	;   Point ds:si and ds:di at normalTransform and move object
	;

	push	si					;instance chunk
	GrObjDeref	di,ds,si
	mov	di,ds:[di].GOI_normalTransform
EC <	tst	di							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]
	mov	si,di
	call	GrObjOTRotateRelative
	pop	si					;instance chunk

	.leave
	ret
GrObjRotateNormalRelative		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTRotateRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply rotation delta to object information stored in
		source ObjectTransform and stores result in the dest
		ObjectTransform. Source and dest may be the same structure.

		[current matrix][rotate]

		This rotation is applied relative to the DOCUMENT axes.
		It will rotate the entire image without skewing it.
		This rotate is used during interactive rotate		


CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		ss:bp - WWFixed delta degrees
		cl - GrObjHandleSpecification of anchor


RETURN:		
		ds:di.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		For rotation to work correctly it must be applied
		before the objects current transformation.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTRotateRelative		proc	near
	uses	bx,cx,dx,bp,es

	mov	bx,bp				;rotate degrees frame

anchorHandle	local	word \
		push	cx
anchorPoints	local	SrcDestPointDWFixeds
	
	.enter

	;    Make sure centers of source and dest ObjectTransforms
	;    are the same
	;

	cmp	si, di
	je	inPlace

	push	si,di				;source, dest
	segmov	es,ds,cx
	add	si,offset OT_center
	add	di,offset OT_center
	MoveConstantNumBytes	<size PointDWFixed>, cx
	pop	si,di				;source, dest

inPlace:
	;    Calculate the initial position of the anchor point
	;

	push	bp				;stack frame
	mov	cx,anchorHandle			;cl gets GHS of anchor handle
	lea	bp,[anchorPoints.SDPDWF_source]
	call	GrObjOTGetPARENTHandleCoords
	pop	bp				;stack frame

	;    Rotate the object
	;

	movwwf	dxcx,ss:[bx]
	call	GrObjOTApplyRotateRelative

	;    Calc the final position of the anchored point
	;

	push	bp				;stack frame
	mov	cx,anchorHandle			;ch gets GHS of anchor handle
	lea	bp,[anchorPoints.SDPDWF_dest]
	xchg	di,si				;source, dest ObjectTransform
	call	GrObjOTGetPARENTHandleCoords
	pop	bp				;stack frame

	;    Move the object so that the anchored point
	;    stays in the same place
	;

	push	bp
	lea	bp,[anchorPoints]
	call	GrObjOTMoveBackToAnchor
	xchg	si,di				;source, dest ObjectTransform
	pop	bp

	.leave
	ret

GrObjOTRotateRelative		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjScaleSpriteRelativeOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys scale factors to data in normal transform and
		stores the results in the spriteTransform

		[scale][current matrix]

		This scales the object in its coordinate system. So
		it will not cause the object to skew or otherwise
		be deformed. This scale is used during interactive
		resizing of the object

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjScaleData
		cl - GrObjHandleSpecification of anchor

RETURN:		
		GOI_spriteTransform.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScaleSpriteRelativeOBJECT		proc	far
	uses	ax,di,si	
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	GrObjDeref	di,ds,si			
	mov	si,di
	mov	si,ds:[si].GOI_normalTransform
EC <	tst	si							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	si,ds:[si]
	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	SPRITE_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]

	call	GrObjOTScaleRelativeOBJECT

	.leave
	ret
GrObjScaleSpriteRelativeOBJECT		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjScaleNormalRelativeOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys scale factors to data in normal transform and
		stores the results in the normalTransform

		[scale][current matrix]

		This scales the object in its coordinate system. So
		it will not cause the object to skew or otherwise
		be deformed. This scale is used during interactive
		resizing of the object

CALLED BY:	INTERNAL UTILITY


PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjScaleData
		cl - GrObjHandleSpecification of anchor

RETURN:		
		GOI_normalTransform.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScaleNormalRelativeOBJECT		proc	far
	uses	ax,di,dx
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	call	ObjMarkDirty

	;   Point ds:si and ds:di at normalTransform and move object
	;

	push	si					;instance chunk
	GrObjDeref	di,ds,si
	mov	di,ds:[di].GOI_normalTransform
EC <	tst	di							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]
	mov	si,di
	call	GrObjOTScaleRelativeOBJECT
	pop	si					;instance chunk

	.leave
	ret
GrObjScaleNormalRelativeOBJECT		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjScaleSpriteRelativeToSpriteOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys scale factors to data in sprite transform and
		stores the results in the spriteTransform

		[scale][current matrix]

		This scales the object in its coordinate system. So
		it will not cause the object to skew or otherwise
		be deformed. This scale is used during interactive
		resizing of the object

CALLED BY:	INTERNAL UTILITY


PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjScaleData
		cl - GrObjHandleSpecification of anchor

RETURN:		
		GOI_spriteTransform.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScaleSpriteRelativeToSpriteOBJECT		proc	far
	uses	ax,di,si
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	call	ObjMarkDirty

	;   Point ds:si and ds:di at spriteTransform and move object
	;

	GrObjDeref	di,ds,si
	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	SPRITE_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]
	mov	si,di
	call	GrObjOTScaleRelativeOBJECT

	.leave
	ret
GrObjScaleSpriteRelativeToSpriteOBJECT		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTScaleRelativeOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply scale to object information stored in
		source ObjectTransform and stores result in the dest
		ObjectTransform. Source and dest may be the same structure.

		[scale][current matrix]

		This scales the object in its coordinate system. So
		it will not cause the object to skew or otherwise
		be deformed. This scale is used during interactive
		resizing of the object


CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		ss:bp - GrObjScaleData
		cl - GrObjHandleSpecification of anchor


RETURN:		
		ds:di.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTScaleRelativeOBJECT		proc	near
	uses	bx,cx,dx,bp,es

	mov	bx,bp				;scale frame

anchorHandle	local	word \
		push	cx
anchorPoints	local	SrcDestPointDWFixeds
	

	.enter

	;    Make sure centers of source and dest ObjectTransform
	;    are the same
	;

	cmp	si, di
	je	inPlace
	push	si,di				;source, dest
	segmov	es,ds,cx
	add	si,offset OT_center
	add	di,offset OT_center
	MoveConstantNumBytes	<size PointDWFixed>, cx
	pop	si,di				;source, dest

inPlace:
	;    Calculate the initial position of the anchor point
	;

	push	bp				;stack frame
	mov	cx,anchorHandle			;cl gets GHS of anchor handle
	lea	bp,[anchorPoints.SDPDWF_source]
	call	GrObjOTGetPARENTHandleCoords
	pop	bp				;stack frame

	;    Scale the object
	;

	movwwf	dxcx,ss:[bx].GOSD_xScale
	mov	ax,ss:[bx].GOSD_yScale.WWF_frac
	mov	bx,ss:[bx].GOSD_yScale.WWF_int
	call	GrObjOTApplyScaleRelativeOBJECT

	;    Calc the final position of the anchored point
	;

	push	bp				;stack frame
	mov	cx,anchorHandle			;ch gets GHS of anchor handle
	lea	bp,[anchorPoints.SDPDWF_dest]
	xchg	di,si				;source, dest ObjectTransform
	call	GrObjOTGetPARENTHandleCoords
	pop	bp				;stack frame

	;    Move the object so that the anchored point
	;    stays in the same place
	;

	push	bp
	lea	bp,ss:[anchorPoints]
	call	GrObjOTMoveBackToAnchor
	xchg	si,di				;source, dest ObjectTransform
	pop	bp

	.leave
	ret

GrObjOTScaleRelativeOBJECT		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjScaleSpriteRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys scale factors to data in normal transform and
		stores the results in the spriteTransform.
		
		[current matrix][scale]

		The scale is applied along the DOCUMENT axes. This will
		tend to cause objects to skews as well as scale. See
		GrObjScaleSpriteRelative for the scaling normally used.
		during interactive resize


CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjScaleData

RETURN:		
		GOI_spriteTransform.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScaleSpriteRelative		proc	far
	uses	ax,di,si	
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	GrObjDeref	di,ds,si			
	mov	si,di
	mov	si,ds:[si].GOI_normalTransform
EC <	tst	si							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	si,ds:[si]
	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	SPRITE_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]

	call	GrObjOTScaleRelative

	.leave
	ret
GrObjScaleSpriteRelative		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjScaleNormalRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys scale factors to data in normal transform and
		stores the results in the normalTransform.
		
		[current matrix][scale]

		The scale is applied along the DOCUMENT axes. This will
		tend to cause objects to skews as well as scale. See
		GrObjScaleNormalRelative for the scaling normally used
		during interactive resize

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjScaleData

RETURN:		
		GOI_normalTransform.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjScaleNormalRelative		proc	far
	uses	ax,di,dx
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	call	ObjMarkDirty

	;   Point ds:si and ds:di at normalTransform and move object
	;

	push	si					;instance chunk
	GrObjDeref	di,ds,si
	mov	di,ds:[di].GOI_normalTransform
EC <	tst	di							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]
	mov	si,di
	call	GrObjOTScaleRelative
	pop	si					;instance chunk

	.leave
	ret
GrObjScaleNormalRelative		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTScaleRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply scale to object information stored in
		source ObjectTransform and stores result in the dest
		ObjectTransform. Source and dest may be the same structure.

		[current matrix][scale]

		The scale is applied along the DOCUMENT axes. This will
		tend to cause objects to skews as well as scale. See
		GrObjOTScaleRelativeOBJECT for the scaling normally used
		during interactive resize

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		ss:bp - GrObjScaleData


RETURN:		
		ds:di.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTScaleRelative		proc	near
	uses	ax,bx,cx,dx
	.enter

	movwwf	dxcx,ss:[bp].GOSD_xScale
	movwwf	bxax,ss:[bp].GOSD_yScale
	call	GrObjOTApplyScaleRelative

	.leave
	ret

GrObjOTScaleRelative		endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMoveNormalBackToAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the center of the normalTransform so that the 
		destination PARENT anchor is where the source PARENT
		is.

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data
		ss:bp - SrcDestPointDWFixeds
			SDPDWF_source
			SDPDWF_dest
			
RETURN:		
		GOI_normalTransform.OT_center - may have changed
		ss:bp - SrcDestPointDWFixeds
			source - deltas moved
			dest  - unchanged

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMoveNormalBackToAnchor		proc	far
	uses	si
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	;   Point ds:si at normalTransform and move object
	;

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTMoveBackToAnchor

	.leave
	ret
GrObjMoveNormalBackToAnchor		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTMoveBackToAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the center of the ObjectTransform so that the 
		destination PARENT anchor is where the source PARENT
		anchor is.

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - source ObjectTransform
		ss:bp - SrcDestPointDWFixeds
			SDPDWF_source
			SDPDWF_dest
			
RETURN:		
		ds:si - ObjectTransform - center may have been moved
		ss:bp - SrcDestPointDWFixeds
			source - deltas moved
			dest  - unchanged


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Calc movement of anchor (source anchor- dest anchor)
		Move center of object

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The idea here is that the source anchor was calculated
		from the original ObjectTransform. 
		The ObjectTransform was then modified by a resize, rotate,
		skew, etc. The dest anchor was then calculated. If we 
		move back the distance the dest anchor moved then that
		point of the object will stay in place.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTMoveBackToAnchor		proc	near
	uses	di
	.enter

	;    Subtract the dest from the source
	;

	SubDWF	ss:[bp].SDPDWF_source.PDF_x, ss:[bp].SDPDWF_dest.PDF_x
	SubDWF	ss:[bp].SDPDWF_source.PDF_y, ss:[bp].SDPDWF_dest.PDF_y

	;    Clean out low byte frac cruft
	;

	RoundDWFtoDWBF	ss:[bp].SDPDWF_source.PDF_x.DWF_int.high, \
			ss:[bp].SDPDWF_source.PDF_x.DWF_int.low, \
			ss:[bp].SDPDWF_source.PDF_x.DWF_frac

	RoundDWFtoDWBF	ss:[bp].SDPDWF_source.PDF_y.DWF_int.high, \
			ss:[bp].SDPDWF_source.PDF_y.DWF_int.low, \
			ss:[bp].SDPDWF_source.PDF_y.DWF_frac

	;    Move the center of ObjectTransform
	;

	mov	di,si				;dest OT = src OT
	call	GrObjOTMoveRelative

	.leave
	ret
GrObjOTMoveBackToAnchor		endp










COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplySpriteTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply sprite transform information  to passed gstate

CALLED BY:	INTERNAL
		GrObjCalcDWFixedMappedCorners

PASS:		
		*(ds:si) - instance data
		di - gstate
RETURN:		
		di - gstate with transforms applied
		carry set if GrObj's GrObjTransMatrix = I

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		set documentOffset from 32 integer bits draw pt 
		apply fractional translation of draw pt
		rotate object
		apply scale factor

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplySpriteTransform		proc	far
	uses	si
	class GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	AccessSpriteTransformChunk	si,ds,si
	call	GrObjOTApplyObjectTransform

	.leave
	ret
GrObjApplySpriteTransform		endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetGStateFromGrObjTransMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the transform in a gstate from
		the data in a GrObjTransMatrix

CALLED BY:	INTERNAL UTILITY

PASS:		ds:si - GrObjTransMatrix
		di - gstate

RETURN:		
		di - gstate with transform set

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetGStateFromGrObjTransMatrix		proc	near
	uses	ds,si,bp,ax,cx
	.enter

EC<	call	ECCheckGStateHandle		>

	;    Create TransMatrix stack frame
	;
	
	;
	;	Fill in the GrObj portion on the TMatrix
	;
	segmov	es, ss
	sub	sp, size TransMatrix
	mov	bp, sp					;es:bp <- dest TMatrix
	push	di					;save gstate
	mov	di, bp					;es:di <- dest TMatrix
	mov	cx, (size TransMatrix - size PointDWFixed) / 2
	rep movsw

	;
	;	Clear out the PointDWFixed at the end of it
	;
	mov_tr	ax, cx					;ax <- 0
	mov	cx, size PointDWFixed / 2
	rep stosw


	;    Apply TransMatrix to gstate
	;

	segmov	ds,ss					;TransMatrix segment
	mov	si,bp					;TransMatrix offset
	pop	di					;di <- gstate
	call	GrSetTransform
	add	sp, size TransMatrix

	.leave
	ret
GrObjSetGStateFromGrObjTransMatrix		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTSetGrObjTransMatrixFromGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the OT_transform in the passed ObjectTransform
		from the GState

CALLED BY:	INTERNAL UTILITY

PASS:		ds:si - ObjectTransform
		di - gstate

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
	srs	4/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTSetGrObjTransMatrixFromGState		proc	far
	uses	si
	.enter

	add	si,offset OT_transform
	call	GrObjSetGrObjTransMatrixFromGState	

	.leave
	ret
GrObjOTSetGrObjTransMatrixFromGState		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetGrObjTransMatrixFromGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the transform in a gstate from
		the data in a GrObjTransMatrix

CALLED BY:	INTERNAL UTILITY

PASS:		ds:si - GrObjTransMatrix
		di - gstate

RETURN:		
		di - gstate with transform set

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetGrObjTransMatrixFromGState		proc	far
	uses	dx,di,si,ds,es
	.enter

EC <	call	ECCheckGStateHandle				>

	segmov	es,ds,dx				;GTM segment
	mov	dx,si					;GTM offset

	;    Get the transformation from the gstate

	sub	sp,size TransMatrix
	segmov	ds,ss,si
	mov	si,sp
	call	GrGetTransform

	;    Copy upper 2x2 from TransMatrix to GrObjTransMatrix
	;

	mov	di,dx					;GTM offset
	MoveConstantNumBytes	<size GrObjTransMatrix>,dx
	
	add	sp, size TransMatrix

	.leave
	ret
GrObjSetGrObjTransMatrixFromGState		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTApplyScaleRelativeOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply scale factor to the the GrObjTransMatrix
		in the source ObjectTransform and store
		the results in the dest ObjectTransform
		
		[scale][GrObjTransMatrix]


CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		dx:cx - WWFixed x scale factor
		bx:ax - WWFixed y scale factor

RETURN:		
		nothing

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
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTApplyScaleRelativeOBJECT		proc	far
	uses	di,si
	.enter

	push	di				;dest offset

	;    Create gstate with GrObjTransMatrix in it
	;

	clr	di
	call	GrCreateState
	add	si,offset OT_transform
	call	GrObjSetGStateFromGrObjTransMatrix

	;    Apply scale to gstate
	;

	call	GrApplyScale

	;    Copy transfromation from gstate into dest GrObjTransMatrix
	;

	pop	si				;dest offset
	call	GrObjOTSetGrObjTransMatrixFromGState
	call	GrObjOTRemoveCruftFromGrObjTransMatrix
	call	GrDestroyState

	.leave
	ret
GrObjOTApplyScaleRelativeOBJECT	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTRemoveCruftFromGrObjTransMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If values are very close to integers then make then	
		integers. 

		This helps with cumulative wwfixed errors. If the user
		rotates an object by small degree increments, each
		rotation introduces a .5/65536 error into the calculation.
		This begins to add up and causes objects that should
		be rotated to 90 degrees to be drawn with a one pixel
		hitch in their sides.
		
		

CALLED BY:	INTERNAL UTILITY

PASS:		ds:si - ObjectTransform

RETURN:		
		ds:si - cruftless ObjectTransform

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			All fracs are zero

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MIN_REQUIRED_FRAC = 16			;empirically determined

GrObjOTRemoveCruftFromGrObjTransMatrix		proc	near
	uses	cx,ax
	.enter

	clr	cx

	cmp	ds:[si].OT_transform.GTM_e11.WWF_frac,cx
	jne	e11NonZero

e12Check:
	cmp	ds:[si].OT_transform.GTM_e12.WWF_frac,cx
	jne	e12NonZero

e21Check:
	cmp	ds:[si].OT_transform.GTM_e21.WWF_frac,cx
	jne	e21NonZero

e22Check:
	cmp	ds:[si].OT_transform.GTM_e22.WWF_frac,cx
	jne	e22NonZero

done:
	.leave
	ret

e11NonZero:
	mov	ax,ds:[si].OT_transform.GTM_e11.WWF_frac
	cmp	ax,MIN_REQUIRED_FRAC
	jb	e11ClrFrac
	cmp	ax,-MIN_REQUIRED_FRAC
	jbe	e12Check
	inc	ds:[si].OT_transform.GTM_e11.WWF_int	
e11ClrFrac:
	mov	ds:[si].OT_transform.GTM_e11.WWF_frac,cx
	jmp	e12Check


e12NonZero:
	mov	ax,ds:[si].OT_transform.GTM_e12.WWF_frac
	cmp	ax,MIN_REQUIRED_FRAC
	jb	e12ClrFrac
	cmp	ax,-MIN_REQUIRED_FRAC
	jbe	e21Check
	inc	ds:[si].OT_transform.GTM_e12.WWF_int	
e12ClrFrac:
	mov	ds:[si].OT_transform.GTM_e12.WWF_frac,cx
	jmp	e21Check

e21NonZero:
	mov	ax,ds:[si].OT_transform.GTM_e21.WWF_frac
	cmp	ax,MIN_REQUIRED_FRAC
	jb	e21ClrFrac
	cmp	ax,-MIN_REQUIRED_FRAC
	jbe	e22Check
	inc	ds:[si].OT_transform.GTM_e21.WWF_int	
e21ClrFrac:
	mov	ds:[si].OT_transform.GTM_e21.WWF_frac,cx
	jmp	e22Check

e22NonZero:
	mov	ax,ds:[si].OT_transform.GTM_e22.WWF_frac
	cmp	ax,MIN_REQUIRED_FRAC
	jb	e22ClrFrac
	cmp	ax,-MIN_REQUIRED_FRAC
	jbe	done
	inc	ds:[si].OT_transform.GTM_e22.WWF_int	
e22ClrFrac:
	mov	ds:[si].OT_transform.GTM_e22.WWF_frac,cx
	jmp	done

GrObjOTRemoveCruftFromGrObjTransMatrix		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTApplyScaleRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply GrObjTransMatrix to the scale factor
		in the source ObjectTransform and store
		the results in the dest ObjectTransform

		[GrObjTransMatrix][scale]

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		dx:cx - WWFixed x scale factor
		bx:ax - WWFixed y scale factor

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
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTApplyScaleRelative		proc	far
	uses	di,si
	.enter

	push	di				;dest offset

	;    Create gstate with scale in it
	;

	clr	di
	call	GrCreateState
	call	GrApplyScale

	;    Apply GrObjTransMatrix to gstate
	;

	call	GrObjOTApplyGrObjTransMatrix


	;    Copy transfromation from gstate into dest GrObjTransMatrix
	;

	pop	si				;dest offset
	call	GrObjOTSetGrObjTransMatrixFromGState
	call	GrObjOTRemoveCruftFromGrObjTransMatrix
	call	GrDestroyState

	.leave
	ret
GrObjOTApplyScaleRelative		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTApplyRotateRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply rotate to the the GrObjTransMatrix
		in the source ObjectTransform and store
		the results in the dest ObjectTransform.

		The rotation must be applied before 
		the existing transformation to keep the 
		user from going insane.

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		dx:cx - WWFixed rotate degrees delta

RETURN:		
		nothing

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
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTApplyRotateRelative		proc	far
	uses	di,si
	.enter

	push	di				;dest offset

	;    Create gstate and apply rotation to it
	;

	clr	di
	call	GrCreateState
	call	GrApplyRotation	

	;    Apply the source GrObjTransMatrix to the gstate
	;

	call	GrObjOTApplyGrObjTransMatrix

	;    Copy transfromation from gstate into dest GrObjTransMatrix
	;

	pop	si				;dest offset
	call	GrObjOTSetGrObjTransMatrixFromGState
	call	GrObjOTRemoveCruftFromGrObjTransMatrix
	call	GrDestroyState

	.leave
	ret
GrObjOTApplyRotateRelative		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTApplySkewRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply skew to the the GrObjTransMatrix
		in the source ObjectTransform and store
		the results in the dest ObjectTransform

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		dx:cx - WWFixed x skew degrees
		bx:ax - WWFixed y skew degrees

RETURN:		
		nothing

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
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTApplySkewRelative		proc	far
	uses	ax,bx,cx,dx,di,si
	.enter

	push	di				;dest offset

	clr	di				;no window
	call	GrCreateState

	;    Create TransMatrix with skew values in it
	;

	push	ds,si
	sub	sp,size TransMatrix
	segmov	ds,ss,si
	mov	si,sp
	call	GrObjGlobalInitTransMatrix
	xchg	ax,cx				;x degrees frac, y degrees frac
	call	GrQuickTangent
	movwwf	ds:[si].TM_e21,dxax
	movwwf	dxax,bxcx			;y degrees
	call	GrQuickTangent
	negwwf	dxax				;our coord system in upside down
	movwwf	ds:[si].TM_e12,dxax

	;    Apply skew to gstate
	;

	call	GrApplyTransform
	add	sp,size TransMatrix
	pop	ds,si

	call	GrObjOTApplyGrObjTransMatrix

	;    Copy transfromation from gstate into dest GrObjTransMatrix
	;

	pop	si				;dest offset
	call	GrObjOTSetGrObjTransMatrixFromGState
	call	GrObjOTRemoveCruftFromGrObjTransMatrix
	call	GrDestroyState

	.leave
	ret
GrObjOTApplySkewRelative		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyNormalTransformSansCenterTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply transform information  to passed gstate

CALLED BY:	INTERNAL
		GrObjApplyNormalTransform
		GrObjApplySpriteTransform
PASS:		
		*ds:si - ObjectTransform or ObjectFullTransform
		di - gstate
RETURN:		
		di - gstate with transforms applied

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
GrObjApplyNormalTransformSansCenterTranslation		proc	far
	uses	si
	class GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject			>
EC <	call	ECCheckGStateHandle			>

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTApplyGrObjTransMatrix

	.leave
	ret


GrObjApplyNormalTransformSansCenterTranslation		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyTranslationToNormalCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the document offset given a ObjectTransform

CALLED BY:	INTERNAL
		GrObjOTApplyObjectTransform

PASS:		
		*ds:si - object
		di - gstate
RETURN:		
		di - documentOffset set

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
GrObjApplyTranslationToNormalCenter		proc	far
	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	AccessNormalTransformChunk		si,ds,si
	call	GrObjOTApplyTranslationToCenter

	.leave
	ret
GrObjApplyTranslationToNormalCenter		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyTranslationToSpriteCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the document offset given a ObjectTransform

CALLED BY:	INTERNAL
		GrObjOTApplyObjectTransform

PASS:		
		*ds:si - object
		di - gstate
RETURN:		
		di - gstate  translated to objects center

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
GrObjApplyTranslationToSpriteCenter		proc	far
	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	AccessSpriteTransformChunk		si,ds,si
	call	GrObjOTApplyTranslationToCenter

	.leave
	ret
GrObjApplyTranslationToSpriteCenter		endp









COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetSpriteOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dimensions of the object in the OBJECT coordinate
		system defined by the spriteTransform

CALLED BY:	INTERNAL (UTILITY)

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
	srs	10/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetSpriteOBJECTDimensions		proc	far
	class	GrObjClass
	uses	si
	.enter

	AccessSpriteTransformChunk	si,ds,si
	call	GrObjOTGetOBJECTDimensions

	.leave
	ret
GrObjGetSpriteOBJECTDimensions		endp









COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetNormalOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the objects width and height in the unflipped OBJECT
		coordinate system. 
		Use the OBJECT coord system defined by the normal transform

CALLED BY:	INTERNAL UTILITY

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
	srs	10/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetNormalOBJECTDimensions		proc	far
	class	GrObjClass
	uses	si
	.enter

	call	ObjMarkDirty
	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTSetOBJECTDimensions

	.leave
	ret
GrObjSetNormalOBJECTDimensions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetSpriteOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the objects width and height in the unflipped OBJECT
		coordinate system. 
		Use the OBJECT coord system defined by the sprite transform

CALLED BY:	INTERNAL (UTILITY)

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
	srs	10/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetSpriteOBJECTDimensions		proc	far
	class	GrObjClass
	uses	si
	.enter

	call	ObjMarkDirty
	AccessSpriteTransformChunk	si,ds,si
	call	GrObjOTSetOBJECTDimensions

	.leave
	ret
GrObjSetSpriteOBJECTDimensions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTSetOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the objects width and height in the unflipped OBJECT
		coordinate system. 
		
CALLED BY:	INTERNAL (UTILITY)

PASS:		
		ds:si - ObjectTransform
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
GrObjOTSetOBJECTDimensions		proc	near
	class	GrObjClass
	.enter

	mov	ds:[si].OT_width.WWF_int,dx
	mov	ds:[si].OT_width.WWF_frac,cx
	mov	ds:[si].OT_height.WWF_int,bx
	mov	ds:[si].OT_height.WWF_frac,ax

	.leave
	ret

GrObjOTSetOBJECTDimensions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetNormalCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the objects center

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - object
		ss:bp - PointDWFixed

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
	srs	10/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetNormalCenter		proc	far
	class	GrObjClass
	uses	si
	.enter

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTSetCenter

	.leave
	ret
GrObjSetNormalCenter		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetSpriteCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the object's center.

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si - object
		ss:bp - PointDWFixed

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
	srs	10/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetSpriteCenter		proc	far
	class	GrObjClass
	uses	si
	.enter

	AccessSpriteTransformChunk	si,ds,si
	call	GrObjOTSetCenter

	.leave
	ret
GrObjSetSpriteCenter		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTSetCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the objects center.
		
CALLED BY:	INTERNAL (UTILITY)

PASS:		
		ds:si - ObjectTransform
		ss:bp - PointDWFixed

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
GrObjOTSetCenter		proc	near
	class	GrObjClass
	uses	cx,di,si,ds,es
	.enter

	segmov	es,ds
	segmov	ds,ss
	mov	di,si
	addnf	di,<offset OT_center>
	mov	si,bp
	MoveConstantNumBytes	<size PointDWFixed>,cx

	.leave
	ret

GrObjOTSetCenter		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertNormalPARENTToWWFCENTERRELATIVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert point in PARENT coordinate system to one
		relative to the objects center.

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - object
		ss:bp - PointDWFixed

RETURN:		
		stc - point successfully convert and fits in WWF
			dx:cx - WWFixed x
			bx:ax - WWFixed y
		clc - point won't fit in WWFixed
			ax,bx,cx,dx - destroyed

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		A DWFixed value cannot be converted to a WWFixed value
		unless the sign extension of the low int is equal
		to the high int.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE 
		because it is used during handle hit detection

		Common cases:
			The resulting CENTER RELATIVE point will fit in WWF

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertNormalPARENTToWWFCENTERRELATIVE		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	AccessNormalTransformChunk	di,ds,si

	MovDWF	cx,ax,bx,ss:[bp].PDF_x
	SubDWF	cx,ax,bx,ds:[di].OT_center.PDF_x
	cwd						;sign extend low int
	cmp	dx,cx					;sign extend low, high  
	jne	fail
	push	ax,bx					;x CR int,frac

	MovDWF	cx,ax,bx,ss:[bp].PDF_y
	SubDWF	cx,ax,bx,ds:[di].OT_center.PDF_y
	cwd						;sign extend low int
	cmp	dx,cx					;sign extend low, high  
	jne	fail
	xchg	ax,bx					;y CR frac, y CR int
	pop	dx,cx					;x CR int, frac

	stc
done:
	.leave
	ret

fail:
	clc
	jmp	done

GrObjConvertNormalPARENTToWWFCENTERRELATIVE		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTConvertVectorPARENTToOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a vector in PARENT coords to point in OBJECT coords

CALLED BY:	INTERNAL
		GrObjOTCalcInteractiveSizeChange
	
PASS:		
		ds:si -  ObjectTransform
		ss:bp - PointDWFixed in PARENT coords


RETURN:		
		ss:bp - PointDWFixed in OBJECT coords

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTConvertVectorPARENTToOBJECT		proc	far
	uses	dx,di,es
	.enter

	clr	di					;no window
	call	GrCreateState
	segmov	es,ss,dx
	mov	dx,bp
	call	GrObjOTApplyGrObjTransMatrix
	call	GrUntransformDWFixed		
	call	GrDestroyState

	.leave
	ret
GrObjOTConvertVectorPARENTToOBJECT		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertNormalWWFVectorPARENTToOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a vector from PARENT coords to OBJECT using
		the normalTransform

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - object
		dx:cx - WWFixed x in PARENT
		bx:ax - WWFixed y in PARENT

RETURN:		
		dx:cx - WWFixed x in OBJECT
		bx:ax - WWFixed y in OBJECT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertNormalWWFVectorPARENTToOBJECT		proc	far
	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTConvertWWFVectorPARENTToOBJECT	

	.leave
	ret
GrObjConvertNormalWWFVectorPARENTToOBJECT		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTConvertWWFVectorPARENTToOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a vector in PARENT coords to point in OBJECT coords

CALLED BY:	INTERNAL
		GrObjConvertNormalWWFVectorPARENTToOBJECT
	
	
PASS:		
		ds:si -  ObjectTransform
		dx:cx - WWFixed x in PARENT
		bx:ax - WWFixed y in PARENT


RETURN:		
		dx:cx - WWFixed x in OBJECT
		bx:ax - WWFixed y in OBJECT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTConvertWWFVectorPARENTToOBJECT		proc	near
	uses	di
	.enter

	clr	di					;no window
	call	GrCreateState
	call	GrObjOTApplyGrObjTransMatrix
	call	GrUntransformWWFixed		
	call	GrDestroyState

	.leave
	ret
GrObjOTConvertWWFVectorPARENTToOBJECT		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjRulePoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the passed point to the ruler

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		ss:bp - PointDWFixed in DOCUMENT
		cx = VisRulerConstrainStrategy

RETURN:		
		ss:bp - snapped PointDWFixed in DOCUMENT

		carry set if point was snapped

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	8 jan 92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjRulePoint	proc	far
	class	GrObjClass
	uses	ax, di
	.enter

	;    Tell the ruler to snap to our point
	;

	mov	ax, MSG_VIS_RULER_RULE_LARGE_PTR
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToRuler

	;
	;  Test to see if the ruler might have done anything
	;
	test	cx, VRCS_MOUSE_TWEAKING_FLAGS
	jz	done
	stc
done:
	.leave
	ret
GrObjRulePoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertNormalOBJECTToPARENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a PointDWFixed in OBJECT through the normal
		transform into PARENT

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		ss:bp - PointDWFixed in OBJECT

RETURN:		
		ss:bp - PointDWFixed in PARENT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertNormalOBJECTToPARENT		proc	far
	class GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;   Point ds:si at normalTransform and convert
	;

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTConvertOBJECTToPARENT

	.leave
	ret
GrObjConvertNormalOBJECTToPARENT		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertSpriteOBJECTToPARENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a PointDWFixed in OBJECT through the normal
		transform into PARENT

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		ss:bp - PointDWFixed in OBJECT

RETURN:		
		ss:bp - PointDWFixed in PARENT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertSpriteOBJECTToPARENT		proc	far
	class GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;   Point ds:si at spriteTransform and convert
	;

	AccessSpriteTransformChunk	si,ds,si
	call	GrObjOTConvertOBJECTToPARENT

	.leave
	ret
GrObjConvertSpriteOBJECTToPARENT		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTConvertOBJECTToPARENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a PointDWFixed in OBJECT to PARENT coords

CALLED BY:	INTERNAL
		GrObjConvertNormalOBJECTToPARENT
		GrObjConvertSpriteOBJECTToPARENT

PASS:		
		ds:si - ObjectTransform
		ss:bp - PointDWFixed in OBJECT

RETURN:		
		ss:bp - PointDWFixed in PARENT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTConvertOBJECTToPARENT		proc	far
	uses	dx,di,es
	.enter

	clr	di
	call	GrCreateState
	call	GrObjOTApplyObjectTransform
	segmov	es,ss,dx
	mov	dx,bp
	call	GrTransformDWFixed
	call	GrDestroyState

	.leave
	ret
GrObjOTConvertOBJECTToPARENT		endp









COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetOBJECTDimensionsAndIdentityMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the passed width and height in the objects
		normal instance data and reset the GrObjTransMatrix to
		the Identity matrix

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - grobject
		dx:cx - WWFixed width in OBJECT
		bx:ax - WWFixed height in OBJECT

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
	srs	4/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetOBJECTDimensionsAndIdentityMatrix		proc	far

	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	AccessNormalTransformChunk	si,ds,si

	;    It causes nasty trouble with the resize code if the
	;    width or height is exactly zero, so set it to one
	;

	tst	dx
	jnz	setWidth
	tst	cx
	jnz	setWidth
	mov	dx,1
setWidth:
	mov	ds:[si].OT_width.WWF_int,dx
	mov	ds:[si].OT_width.WWF_frac,cx

	tst	bx
	jnz	setHeight
	tst	ax
	jnz	setHeight
	mov	bx,1
setHeight:
	mov	ds:[si].OT_height.WWF_int,bx
	mov	ds:[si].OT_height.WWF_frac,ax

	add	si,offset OT_transform
	call	GrObjGlobalInitGrObjTransMatrix	

	.leave
	ret
GrObjSetOBJECTDimensionsAndIdentityMatrix		endp





















GrObjRequiredExtInteractiveCode ends


GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetNormalOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dimensions of the object in the OBJECT coordinate
		system defined by the normalTransform

CALLED BY:	INTERNAL (UTILITY)

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
	srs	10/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetNormalOBJECTDimensions		proc	far
	class	GrObjClass
	uses	si
	.enter

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTGetOBJECTDimensions

	.leave
	ret
GrObjGetNormalOBJECTDimensions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTGetOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the objects dimensions in the OBJECT coordinate system

CALLED BY:	INTERNAL
		GrObjGetSpriteOBJECTDimensions
		GrObjGetNormalOBJECTDimensions

PASS:		
		ds:si - ObjectTransform

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
GrObjOTGetOBJECTDimensions		proc	far
	class	GrObjClass
	.enter

	mov	dx,ds:[si].OT_width.WWF_int
	mov	cx,ds:[si].OT_width.WWF_frac
	mov	bx,ds:[si].OT_height.WWF_int
	mov	ax,ds:[si].OT_height.WWF_frac

	.leave
	ret

GrObjOTGetOBJECTDimensions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyNormalTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply normal transform information  to passed gstate

CALLED BY:	INTERNAL
		GrObjCalcDWFixedMappedCorners

PASS:		
		*(ds:si) - instance data
		di - gstate
RETURN:		
		di - gstate with transforms applied
		carry set if passed GrObjTransMatrix = I

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		set documentOffset from 32 integer bits draw pt 
		apply fractional translation of draw pt
		rotate object
		apply scale factor

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplyNormalTransform		proc	far
	uses	si
	class GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTApplyObjectTransform

	.leave
	ret
GrObjApplyNormalTransform		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTApplyObjectTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply transform information  to passed gstate

CALLED BY:	INTERNAL
		GrObjApplyNormalTransform
		GrObjApplySpriteTransform
PASS:		
		ds:si - ObjectTransform or ObjectFullTransform
		di - gstate
RETURN:		
		di - gstate with transforms applied
		carry set if passed GrObjTransMatrix = I

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
GrObjOTApplyObjectTransform		proc	far
	class GrObjClass
	.enter

EC <	call	ECCheckGStateHandle			>

	call	GrObjOTApplyTranslationToCenter

	call	GrObjOTApplyGrObjTransMatrix


	.leave
	ret

GrObjOTApplyObjectTransform		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTApplyGrObjTransMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply the GrObjTransMatrix stored in the ObjectTransform
		to the passed gstate

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - ObjectTransform
		di - gstate

RETURN:		
		di - gstate with transform applied
		carry set if passed GrObjTransMatrix = I

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTApplyGrObjTransMatrix		proc	far
	uses	si
	.enter

	add	si,offset OT_transform
	call	GrObjApplyGrObjTransMatrix

	.leave
	ret
GrObjOTApplyGrObjTransMatrix		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyGrObjTransMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply a GrObjTransMatrix to a gstate

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - GrObjTransMatrix
		di - gstate

RETURN:		
		di - gstate with transform applied
		carry set if passed GrObjTransMatrix = I

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplyGrObjTransMatrix		proc	near
	uses	ax
	.enter

	;   If the GrObjTransMatrix is the identity matrix then
	;   do nothing
	;

	call	GrObjCheckGrObjTransMatrixForIdentity
	jnc	notIdentity

done:
	.leave
	ret

notIdentity:
	;     If the gstate passed is actually a gstring we cannot
	;     do some special optimizations
	;

	call	GrGetGStringHandle
	tst	ax					;gstring handle
	jnz	itsAGString

	call	GrObjApplyGrObjTransMatrixToGState
	clc						;not identity
	jmp	done

itsAGString:
	call	GrObjApplyGrObjTransMatrixToGString
	clc						;not identity
	jmp	done

GrObjApplyGrObjTransMatrix		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyGrObjTransMatrixToGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply a GrObjTransMatrix to a gstate that is
		not a gstring. This routine uses an optimization
		that requires a GrSetTransform which is bad
		for gstrings.
		
		This routine does not optimize for the case of
		the passed GrObjTransMatrix being the identity 
		matrix. Currently this is handled in 
		GrObjApplyGrObjTransMatrix.


CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - GrObjTransMatrix
		di - gstate that is not a gstring

RETURN:		
		di - gstate with transform applied

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		if the gstates upper 2x2 matrix is the identity matrix then
			copy GrObjTransMatrix to the upper 2x2 of gstate
		else
			mult GrObjTransMatrix 2x2 by the gstate 2x2
			since GrObjTransMatrix has no translation we
			can skip that portion of the matrix multiplication.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	4/ 1/92   	Initial version
	srs	9/17/92		Broke out of GrObjApplyGrObjTransMatrix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplyGrObjTransMatrixToGState		proc	near
	uses	ax, cx, dx, si, es, ds
	.enter

	;
	;	es:ax <- GrObjTransMatrix
	;
	segmov	es, ds, ax
	mov_tr	ax, si

	;
	;	ds:si <- gstate's TransMatrix
	;
	sub	sp, 2 * size TransMatrix
	segmov	ds, ss, si
	mov	si, sp
	call	GrGetTransform
	xchg	di, ax				;es:di <- GrObjTransMatrix
						;ax <- gstate

	;
	;	If the gstate's 2x2 matrix = I, then we just
	;	want to copy our GrObjTransMatrix to the gstate
	;
	call	GrObjCheckGrObjTransMatrixForIdentity
	jnc	doMul

	;
	;	ds:si <- GTM, es:di <- TM, then copy
	;
	segxchg	es, ds
	xchg	si, di
	mov	cx, size GrObjTransMatrix / 2	
	push	di				;save dest TransMatrix
	rep	movsw

	segmov	ds, es, si
	pop	si				;ds:si <- dest TransMatrix
	mov_tr	di, ax				;di <- gstate
	jmp	setTransform

doMul:

	;
	;	dxcx <- (GTM_e11) * (TM_e11)
	;
	call	GrMulWWFixedPtr
	mov	ds:[si][(size TransMatrix)].TM_e11.WWF_int, dx
	mov	ds:[si][(size TransMatrix)].TM_e11.WWF_frac, cx

	;
	;	es:di <- GTM_e21
	;
	add	di, offset GTM_e21

	;
	;	dxcx <- (GTM_e21) * (TM_e11)
	;
	call	GrMulWWFixedPtr
	mov	ds:[si][(size TransMatrix)].TM_e21.WWF_int, dx
	mov	ds:[si][(size TransMatrix)].TM_e21.WWF_frac, cx

	;
	;	ds:si <- TM_e12
	;
	add	si, offset TM_e12
	
	;
	;	dxcx <- (GTM_e21) * (TM_e12)
	;
	call	GrMulWWFixedPtr
	mov	ds:[(size TransMatrix - offset TM_e12)][si].TM_e22.WWF_int,dx
	mov	ds:[(size TransMatrix - offset TM_e12)][si].TM_e22.WWF_frac,cx

	;
	;	es:di <- GTM_e11
	;
	sub	di, offset GTM_e21

	;
	;	dxcx <- (GTM_e11) * (TM_e12)
	;
	call	GrMulWWFixedPtr
	mov	ds:[(size TransMatrix - offset TM_e12)][si].TM_e12.WWF_int, dx
	mov	ds:[(size TransMatrix - offset TM_e12)][si].TM_e12.WWF_frac, cx

	;
	;	ds:si <- TM_e21
	;
	add	si, offset TM_e21 - offset TM_e12

	;
	;	es:di <- GTM_e12
	;
	add	di, offset GTM_e12
	
	;
	;	dxcx <- (GTM_e12) * (TM_e21)
	;
	call	GrMulWWFixedPtr
	add	ds:[(size TransMatrix - offset TM_e21)][si].TM_e11.WWF_frac, cx
	adc	ds:[(size TransMatrix - offset TM_e21)][si].TM_e11.WWF_int, dx

	;
	;	es:di <- GTM_e22
	;
	add	di, offset GTM_e22 - offset GTM_e12

	;
	;	dxcx <- (GTM_e22) * (TM_e21)
	;
	call	GrMulWWFixedPtr
	add	ds:[(size TransMatrix - offset TM_e21)][si].TM_e21.WWF_frac, cx
	adc	ds:[(size TransMatrix - offset TM_e21)][si].TM_e21.WWF_int, dx

	;
	;	ds:si <- TM_e22
	;
	add	si, offset TM_e22 - offset TM_e21
	
	;
	;	dxcx <- (GTM_e22) * (TM_e22)
	;
	call	GrMulWWFixedPtr
	add	ds:[(size TransMatrix - offset TM_e22)][si].TM_e22.WWF_frac, cx
	adc	ds:[(size TransMatrix - offset TM_e22)][si].TM_e22.WWF_int, dx

	;
	;	es:di <- GTM_e12
	;
	sub	di, offset GTM_e22 - offset GTM_e12

	;
	;	dxcx <- (GTM_e12) * (TM_e22)
	;
	call	GrMulWWFixedPtr
	add	ds:[(size TransMatrix - offset TM_e22)][si].TM_e12.WWF_frac, cx
	adc	ds:[(size TransMatrix - offset TM_e22)][si].TM_e12.WWF_int, dx

	;
	;	Set the new transform
	;	
	add	si, size TransMatrix - offset TM_e22
	mov_tr	di, ax					;di <- gstate

	;
	;	Copy the e31 and e32 elements from the returned transform
	;	to the new one
	;
	mov	ax, ds:[si - (size TransMatrix)].TM_e31.DWF_int.high
	mov	ds:[si].TM_e31.DWF_int.high, ax
	mov	ax, ds:[si - (size TransMatrix)].TM_e31.DWF_int.low
	mov	ds:[si].TM_e31.DWF_int.low, ax
	mov	ax, ds:[si - (size TransMatrix)].TM_e31.DWF_frac
	mov	ds:[si].TM_e31.DWF_frac, ax

	mov	ax, ds:[si - (size TransMatrix)].TM_e32.DWF_int.high
	mov	ds:[si].TM_e32.DWF_int.high, ax
	mov	ax, ds:[si - (size TransMatrix)].TM_e32.DWF_int.low
	mov	ds:[si].TM_e32.DWF_int.low, ax
	mov	ax, ds:[si - (size TransMatrix)].TM_e32.DWF_frac
	mov	ds:[si].TM_e32.DWF_frac, ax

setTransform:
	call	GrSetTransform
	add	sp, 2 * size TransMatrix

	.leave
	ret

GrObjApplyGrObjTransMatrixToGState		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjApplyGrObjTransMatrixToGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply a GrObjTransMatrix to a gstring. When performing
		graphics operations on a gstring, certain commands
		like GrSetTransform cannot be used. So we can't
		do any of our nifty optimizations

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - GrObjTransMatrix
		di - gstate that is a gstring

RETURN:		
		di - gstate with transform applied


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjApplyGrObjTransMatrixToGString		proc	near
	uses	ds,si,bp,ax,cx,es
	.enter

EC<	call	ECCheckGStateHandle		>

	;    Create TransMatrix stack frame and 
	;    fill in the GrObj portion on the TMatrix
	;

	segmov	es, ss
	sub	sp, size TransMatrix
	mov	bp, sp					;es:bp <- dest TMatrix
	push	di					;save gstate
	mov	di, bp					;es:di <- dest TMatrix
	mov	cx, (size TransMatrix - size PointDWFixed) / 2
	rep movsw

	;    Clear out the PointDWFixed at the end of it
	;

	mov_tr	ax, cx					;ax <- 0
	mov	cx, size PointDWFixed / 2
	rep stosw

	;    Apply TransMatrix to gstate
	;

	segmov	ds,ss					;TransMatrix segment
	mov	si,bp					;TransMatrix offset
	pop	di					;di <- gstate
	call	GrApplyTransform

	add	sp,size TransMatrix

	.leave

	ret

GrObjApplyGrObjTransMatrixToGString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCheckGrObjTransMatrixForIdentity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if a GrObjTransMatrix is the identity matrix

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - GrObjTransMatrix

RETURN:		
		stc - identity
		clc - not

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		This routine is *extremely* sensitive to the
		structure of a GrObjTransMatrix.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCheckGrObjTransMatrixForIdentity		proc	far
	uses	ax
	.enter

	clr	ax

	cmp	ds:[si].GTM_e11.WWF_frac, ax
	jne	fail
	cmp	ds:[si].GTM_e12.WWF_int, ax
	jne	fail
	cmp	ds:[si].GTM_e12.WWF_frac, ax
	jne	fail
	cmp	ds:[si].GTM_e21.WWF_int, ax
	jne	fail
	cmp	ds:[si].GTM_e21.WWF_frac, ax
	jne	fail
	cmp	ds:[si].GTM_e22.WWF_frac, ax
	jne	fail

	inc ax

	cmp	ds:[si].GTM_e11.WWF_int,ax
	jne	fail
	cmp	ds:[si].GTM_e22.WWF_int,ax
	jne	fail

	stc
	jmp	done

fail:
	clc
done:
	.leave
	ret
GrObjCheckGrObjTransMatrixForIdentity		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTApplyTranslationToCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the document offset given a ObjectTransform

CALLED BY:	INTERNAL
		GrObjOTApplyObjectTransform
		GrObjApplyTranslationToNormalCenter

PASS:		
		ds:si - ObjectTransform
		di - gstate
RETURN:		
		di - gstate with translation to center

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
GrObjOTApplyTranslationToCenter		proc	far
	uses	ax,bx,cx,dx
	.enter

	;    If translation can be accurately represented in WWFixed
	;    then just use GrApplyTranslation
	;

	mov	ax,ds:[si].OT_center.PDF_y.DWF_int.low
	cwd
	cmp	dx,ds:[si].OT_center.PDF_y.DWF_int.high
	jne	dwordTranslation
	mov	bx,ax						;y int low

	mov	ax,ds:[si].OT_center.PDF_x.DWF_int.low
	cwd
	cmp	dx,ds:[si].OT_center.PDF_x.DWF_int.high
	jne	dwordTranslation
	mov	dx,ax						;x int low

normalFrac:
	mov	cx,ds:[si].OT_center.PDF_x.DWF_frac
	mov	ax,ds:[si].OT_center.PDF_y.DWF_frac
	call	GrApplyTranslation

	.leave
	ret

dwordTranslation:
	mov	dx,ds:[si].OT_center.PDF_x.DWF_int.high
	mov	bx,ds:[si].OT_center.PDF_y.DWF_int.high
	mov	cx,ds:[si].OT_center.PDF_x.DWF_int.low
	mov	ax,ds:[si].OT_center.PDF_y.DWF_int.low
	call	GrApplyTranslationDWord
	clr	dx,bx
	jmp	normalFrac

GrObjOTApplyTranslationToCenter		endp


GrObjDrawCode	ends



GrObjRequiredInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertNormalPARENTToWWFOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert PointDWF in PARENT coords into PointWWF in OBJECT

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - object
		ss:bx - PARENT PointDWFixed
		ss:bp - PointWWFixed struct

RETURN:		
		ss:bx - PARENT  PointDWFixed unchanged

		stc - point successfully converted to WWF
			ss:bp - OBJECT PointWWFixed
		clc - point won't fit in WWFixed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertNormalPARENTToWWFOBJECT		proc	far

point	local	PointDWFixed

	uses	ax,dx,di

	.enter

	mov	di,ss:[bp]			;orig bp, PointWWFixed frame

	;    Copy PARENT point to local frame and convert copy in
	;    local frame to OBJECT
	;

	MovDWF	point.PDF_x, ss:[bx].PDF_x,ax
	MovDWF	point.PDF_y, ss:[bx].PDF_y,ax
	mov	ax,bp				;local stack frame		
	lea	bp,ss:[point]
	call	GrObjConvertNormalPARENTToOBJECT
	mov_tr	bp,ax				;local stack frame

	;    If the sign extended low int does not equal the high int
	;    then the value cannot fit in WWFixed. If value fits then
	;    copy it to PointWWFixed frame
	;

	mov	ax,point.PDF_x.DWF_int.low
	cwd
	cmp	dx, point.PDF_x.DWF_int.high
	jne	fail

	mov	ss:[di].PF_x.WWF_int,ax
	mov	ax,point.PDF_x.DWF_frac
	mov	ss:[di].PF_x.WWF_frac,ax

	mov	ax,point.PDF_y.DWF_int.low
	cwd
	cmp	dx, point.PDF_y.DWF_int.high
	jne	fail

	mov	ss:[di].PF_y.WWF_int,ax
	mov	ax,point.PDF_y.DWF_frac
	mov	ss:[di].PF_y.WWF_frac,ax

	stc
done:
	.leave
	ret

fail:
	clc
	jmp	done

GrObjConvertNormalPARENTToWWFOBJECT		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjConvertNormalPARENTToOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert point from PARENT coords to OBJECT using
		the normalTransform

CALLED BY:	INTERNAL

PASS:		
		*ds:si - object
		ss:bp - PointDWFixed in PARENT

RETURN:		
		ss:bp - PointDWFixed in OBJECT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjConvertNormalPARENTToOBJECT		proc	far
	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTConvertPARENTToOBJECT	

	.leave
	ret
GrObjConvertNormalPARENTToOBJECT		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTConvertPARENTToOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert point in PARENT coords to point in OBJECT coords

CALLED BY:	INTERNAL
		GrObjConvertNormalPARENTToOBJECT
	
PASS:		
		ds:si -  ObjectTransform
		ss:bp - PointDWFixed in PARENT coords


RETURN:		
		ss:bp - PointDWFixed in OBJECT coords

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTConvertPARENTToOBJECT		proc	near
	uses	dx,di,es
	.enter

	clr	di					;no window
	call	GrCreateState
	segmov	es,ss,dx
	mov	dx,bp
	call	GrObjOTApplyObjectTransform
	call	GrUntransformDWFixed		
	call	GrDestroyState

	.leave
	ret
GrObjOTConvertPARENTToOBJECT		endp


GrObjRequiredInteractiveCode	ends


GrObjGroupCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTransformSpriteRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys transform to data in normalTransform and stores
		the results in the spriteTransform
		

CALLED BY:	INTERNAL
		GrObjPtrTransform

PASS:		
		*(ds:si) - instance data
		ss:bp - TransMatrix

RETURN:		
		in spriteTransform
			transform may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTransformSpriteRelative		proc	far
	class	GrObjClass
	uses	di,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	;   Get offset of spriteTransform in di
	;

	GrObjDeref	di,ds,si
	mov	si,di
	mov	di,ds:[di].GOI_spriteTransform
	mov	di,ds:[di]
EC <	tst	di							>
EC <	ERROR_Z	MISSING_SPRITE_TRANSFORM_CHUNK				>

	;   Point ds:si at normalTransform and do transform
	;

	mov	si,ds:[si].GOI_normalTransform
	mov	si,ds:[si]
	call	GrObjOTTransformRelative
	
	.leave
	ret
GrObjTransformSpriteRelative		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjTransformNormalRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys transform to data in normalTransform and stores
		the results back in the normalTransform. 
		

CALLED BY:	INTERNAL
		GrObjEndTransform

PASS:		
		*(ds:si) - instance data
		ss:bp - TransMatrix

RETURN:		
		in normalTransform
			transform may have changed			

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjTransformNormalRelative		proc	far
	class	GrObjClass
	uses	ax,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	;   Point ds:si and ds:di at normalTransform and transform object
	;

	push	si					;instance chunk
	AccessNormalTransformChunk	si,ds,si
	mov	di,si
	call	GrObjOTTransformRelative
	pop	si					;instance chunk

	.leave
	ret
GrObjTransformNormalRelative		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTTransformRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pre-Apply transform to object transform stored in source
		ObjectTransform and stores the result in the
		dest ObjectTransform. Source and dest may be the
		same structure
		

CALLED BY:	INTERNAL
		GrObjTransformNormalRelative
		GrObjTransformSpriteRelative

PASS:		
		ds:si - source ObjectTransform or ObjectFullTransform
		ds:di - dest ObjectTransform or ObjectFullTransform
		ss:bp - TransMatrix

RETURN:		
		ds:di.OT_center - may have changed
		ds:di.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common Cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTTransformRelative		proc	near
	uses	bx,di,si
	.enter

	mov	bx,di					;dest offset

	;    Create null gstate and apply passed transform to it
	;

	push	ds,si					;source fptr
	clr	di					;no window
	call	GrCreateState
	segmov	ds,ss					;GTM segment
	mov	si,bp					;GTM offset
	call	GrApplyTransform
	pop	ds,si					;source fptr

	;    Transform the source center through the transform
	;    and store it in dest.
	;

	call	GrObjOTGStateTransformCenterRelative

	;    Apply source transform to gstate
	;    and copy the transformation into dest transform
	;

	call	GrObjOTApplyGrObjTransMatrix
	mov	si,bx					;dest offset
	call	GrObjOTSetGrObjTransMatrixFromGState	

	;    Destroy temporary gstate
	;

	call	GrDestroyState

	.leave
	ret

GrObjOTTransformRelative		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTGStateTransformCenterRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform the center of the source ObjecTransform through
		the gstate and store in dest ObjectTransform

CALLED BY:	INTERNAL
		GrObjOTTransformRelative

PASS:		
		ds:si - source ObjectTransform
		ds:bx - dest ObjectTransform
		di - gstate
RETURN:		
		ds:bx.OT_center - may have changed

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
	srs	4/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTGStateTransformCenterRelative		proc	near
	uses	bx,dx,si,es
	.enter

	;     Copy source center to dest center
	;

	push	bx					;dest offset
	add	si,offset OT_center
	xchg	bx,di					;gstate, dest offset
	add	di,offset OT_center
	segmov	es,ds,dx
	MoveConstantNumBytes	<size PointDWFixed>,dx
	mov	di,bx					;gstate
	pop	dx					;dest offset

	;    Transform the center in place in the dest
	;

	add	dx,offset OT_center
	call	GrTransformDWFixed

	.leave
	ret
GrObjOTGStateTransformCenterRelative		endp


GrObjGroupCode	ends

GrObjExtNonInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSkewSpriteRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys skew deltas to data in normal transform and
		stores the results in the spriteTransform

		[current matrix][skew]

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjSkewData

RETURN:		
		GOI_spriteTransform.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSkewSpriteRelative		proc	far
	uses	ax,di,si	
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	GrObjDeref	di,ds,si			
	mov	si,di
	mov	si,ds:[si].GOI_normalTransform
EC <	tst	si							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	si,ds:[si]
	mov	di,ds:[di].GOI_spriteTransform
EC <	tst	di							>
EC <	ERROR_Z	SPRITE_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]

	call	GrObjOTSkewRelative

	.leave
	ret
GrObjSkewSpriteRelative		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSkewNormalRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applys skew deltas to data in normal transform and
		stores the results in the normalTransform

		[current matrix][skew]


CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjSkewData

RETURN:		
		GOI_normalTransform.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSkewNormalRelative		proc	far
	uses	ax,di,dx
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	call	ObjMarkDirty

	;   Point ds:si and ds:di at normalTransform and move object
	;

	push	si					;instance chunk
	GrObjDeref	di,ds,si
	mov	di,ds:[di].GOI_normalTransform
EC <	tst	di							>
EC <	ERROR_Z	NORMAL_TRANSFORM_DOESNT_EXIST				>
	mov	di,ds:[di]
	mov	si,di
	call	GrObjOTSkewRelative
	pop	si					;instance chunk

	.leave
	ret
GrObjSkewNormalRelative		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTSkewRelative
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply skew to object information stored in
		source ObjectTransform and stores result in the dest
		ObjectTransform. Source and dest may be the same structure.

		[current matrix][skew]


CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - source ObjectTransform
		ds:di - dest ObjectTransform
		ss:bp - GrObjSkewData


RETURN:		
		ds:di.OT_transform - may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTSkewRelative		proc	near
	uses	ax,bx,cx,dx,es

	.enter

	;    Make sure centers of source and dest ObjectTransforms
	;    are the same
	;

	cmp	si, di
	je	inPlace	

	push	si,di				;source, dest
	segmov	es,ds,cx
	add	si,offset OT_center
	add	di,offset OT_center
	MoveConstantNumBytes	<size PointDWFixed>, cx
	pop	si,di				;source, dest

inPlace:
	;    Skew the object
	;

	movwwf	dxcx,ss:[bp].GOSD_xDegrees
	mov	ax,ss:[bp].GOSD_yDegrees.WWF_frac
	mov	bx,ss:[bp].GOSD_yDegrees.WWF_int
	call	GrObjOTApplySkewRelative

	.leave
	ret

GrObjOTSkewRelative		endp

GrObjExtNonInteractiveCode	ends


GrObjInitCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetAbsNormalOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the absolute value of the dimensions of the 
		object in the OBJECT coordinate system 
		defined by the normalTransform

CALLED BY:	INTERNAL (UTILITY)

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
	srs	10/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetAbsNormalOBJECTDimensions		proc	far
	class	GrObjClass
	uses	si
	.enter

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTGetAbsOBJECTDimensions

	.leave
	ret
GrObjGetAbsNormalOBJECTDimensions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetAbsSpriteOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the absolute value of the object in the OBJECT coordinate
		system defined by the spriteTransform

CALLED BY:	INTERNAL (UTILITY)

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
	srs	10/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetAbsSpriteOBJECTDimensions		proc	far
	class	GrObjClass
	uses	si
	.enter

	AccessSpriteTransformChunk	si,ds,si
	call	GrObjOTGetAbsOBJECTDimensions

	.leave
	ret
GrObjGetAbsSpriteOBJECTDimensions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTGetAbsOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the absolute value of the objects dimensions 
		in the OBJECT coordinate system

CALLED BY:	INTERNAL
		GrObjGetAbsSpriteOBJECTDimensions
		GrObjGetAbsNormalOBJECTDimensions

PASS:		
		ds:si - ObjectTransform

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
GrObjOTGetAbsOBJECTDimensions		proc	far
	class	GrObjClass
	.enter

	mov	dx,ds:[si].OT_width.WWF_int
	mov	cx,ds:[si].OT_width.WWF_frac
	tst	dx
	js	negWidth

doHeight:
	mov	bx,ds:[si].OT_height.WWF_int
	mov	ax,ds:[si].OT_height.WWF_frac
	tst	bx
	js	negHeight

done:
	.leave
	ret

negWidth:
	negwwf 	dxcx
	jmp	doHeight

negHeight:
	negwwf 	bxax
	jmp	done

GrObjOTGetAbsOBJECTDimensions		endp

GrObjInitCode	ends
