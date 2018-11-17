COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		objectHandleUtils.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name				Description
	----				-----------
	GrObjHitDetectOneSquareHandle
	GrObjHitDetectOneHandle
	GrObjDoHitDetectionOnAllHandles

	GrObjDrawSelectedHandles		
	GrObjDrawOneSquareHandle		
GLB	GrObjDrawOneHandle			
	GrObjGetNormalDOCUMENTHandleCoords
	GrObjGetSpriteDOCUMENTHandleCoords
	GrObjOTGetDOCUMENTHandleCoords
	GrObjGetNormalPARENTHandleCoords
	GrObjGetSpritePARENTHandleCoords
	GrObjGetOTPARENTHandleCoords
	GrObjGetOTOBJECTHandleCoords
	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89	Initial revision


DESCRIPTION:
	Utililty routines for graphic class 
		

	$Id: grobjHandleUtils.asm,v 1.1 97/04/04 18:07:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



GrObjRequiredExtInteractiveCode segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDoHitDetectionOnAllHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if point is on any of the selection handles.
		Will ignore move handle if GOL_MOVE is passed in and
		object's GOL_MOVE lock is set and will ignore resize/rotate 
		handles if GOL_RESIZE/GOL_ROTATE is passed in and 
		GOL_RESIZE/GOL_ROTATE lock is set in the object.
		
CALLED BY:	INTERNAL
		GrObjHandleHitDetection

PASS:		
		*ds:si - object
		ss:bp - PointDWFixed in PARENT coords
		cx - mask GOL_ROTATE or mask GOL_RESIZE and/or mask GOL_MOVE

RETURN:		
		clc - didn't hit handles
			ax - destroyed
		stc - hit handle
			al - destroyed
			ah - GrObjHandleSpecification of hit handle

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			No hit on handle			

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDoHitDetectionOnAllHandles		proc	far
	class	GrObjClass
	uses	cx,bx,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	call	GrObjGetCurrentHandleSize

	;    Create handle location transform gstate
	;

	clr	di
	call	GrCreateState
	call	GrObjApplyNormalTransform	
	mov	dx,di					;conversion gstate

	;    Ignore move handle if move lock is set
	;

	GrObjDeref	di,ds,si
	mov	di,ds:[di].GOI_locks
	andnf	di,cx					;just locks passed in
	test	di,mask GOL_MOVE
	jnz	checkTransformLocks

	mov	cl,HANDLE_MOVE
	call	GrObjHitDetectOneHandleConvertGState
	jc	hit

checkTransformLocks:
	;    Ignore resize/rotate handles if resize/rotate lock is set.
	;

	test	di,mask GOL_RESIZE or mask GOL_ROTATE
	jnz	done					;implied clc from test
	
	mov	cl,HANDLE_LEFT_TOP
	call	GrObjHitDetectOneHandleConvertGState		
	jc	hit

	mov	cl,HANDLE_RIGHT_TOP
	call	GrObjHitDetectOneHandleConvertGState		
	jc	hit

	mov	cl,HANDLE_RIGHT_BOTTOM
	call	GrObjHitDetectOneHandleConvertGState		
	jc	hit

	mov	cl,HANDLE_LEFT_BOTTOM
	call	GrObjHitDetectOneHandleConvertGState		
	jc	hit

	mov	cl,HANDLE_MIDDLE_TOP
	call	GrObjHitDetectOneHandleConvertGState
	jc	hit

	mov	cl,HANDLE_MIDDLE_BOTTOM
	call	GrObjHitDetectOneHandleConvertGState
	jc	hit

	mov	cl,HANDLE_RIGHT_MIDDLE
	call	GrObjHitDetectOneHandleConvertGState
	jc	hit

	mov	cl,HANDLE_LEFT_MIDDLE
	call	GrObjHitDetectOneHandleConvertGState
	jc	hit

done:
	pushf
	mov	di,dx				;gstate
	call	GrDestroyState			;convert gstate
	popf

	.leave
	ret

hit:
	mov	ah,cl				;GrObjHandleSpecification
	stc					;flag hit
	jmp	short done

GrObjDoHitDetectionOnAllHandles		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHitDetectOneHandleConvertGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if point is on handle when passed
		a gstate to convert the handle location from OBJECT
		to PARENT.

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - GrObject
		cl - GrObjHandleSpecification		
		ss:bp - PointDWFixed in PARENT
		bl - handle width in DOCUMENT coords
		bh - handle height in DOCUMENT coords
		dx - convert gstate

RETURN:		
		
		clc	- no hit
		stc	- hit

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		NOTE - GrObjects in groups are not supposed to 
		be drawing their handles so PARENT and DOCUMENT
		coords are the same.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHitDetectOneHandleConvertGState		proc	far
	uses	ax,bx,cx,dx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov_tr	ax,bx				;handle sizes
	mov	bx,bp				;point

	sub	sp, size PointDWFixed
	mov	bp,sp
	call	GrObjGetNormalPARENTHandleCoordsConvertGState

	mov_tr	dx,ax				;handle sizes
	call	GrObjHitDetectOneSquareHandle
	lahf
	add	sp,size PointDWFixed
	sahf

	.leave
	ret

GrObjHitDetectOneHandleConvertGState		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHitDetectOneHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if point is on handle

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - GrObject
		cl - GrObjHandleSpecification		
		ss:bp - PointDWFixed in PARENT
		bl - handle width in DOCUMENT coords
		bh - handle height in DOCUMENT coords

RETURN:		
		
		clc	- no hit
		stc	- hit

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		NOTE - GrObjects in groups are not supposed to 
		be drawing their handles so PARENT and DOCUMENT
		coords are the same.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHitDetectOneHandle		proc	far
	uses	ax,bx,cx,dx,bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	dx,bx				;handle sizes
	mov	bx,bp				;point

	sub	sp, size PointDWFixed
	mov	bp,sp
	call	GrObjGetNormalPARENTHandleCoords

	call	GrObjHitDetectOneSquareHandle
	lahf
	add	sp,size PointDWFixed
	sahf

	.leave
	ret

GrObjHitDetectOneHandle		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHitDetectOneSquareHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if point is on square handle

CALLED BY:	INTERNAL
		GrObjHitDetectOneHandle

PASS:		
		*ds:si - GrObject
		ss:bp - PointDWFixed in PARENT of handle
		ss:bx - PointDWFixed in PARENT of click
		dl - handle width in DOCUMENT coords
		dh - handle height in DOCUMENT coords

RETURN:		
		ss:bp - PointDWFixed deltas in PARENT between click and handle
		clc - no hit
		stc - hit

DESTROYED:	

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
GrObjHitDetectOneSquareHandle		proc	near
	uses	ax,bx,cx,dx
	.enter
	
	;    Subtract click point from handle center point
	;

	subdwf	ss:[bp].PDF_x, ss:[bx].PDF_x,ax
	subdwf	ss:[bp].PDF_y, ss:[bx].PDF_y,ax

	mov	bx,dx					;handle sizes

	;    Check for click to left of handle
	;

	;    Store (handle width (bl) * .5) as DWFixed in dxax.cx
	clr	cx					;clear factional part
	clr	ah
	mov	al,bl					;width
	shr	ax, 1
	cwd
	;    Set fractional part (cx) to be 1/2 if the width was odd (C=1)
	rcr	cx, 1	

	cmp	ss:[bp].PDF_x.DWF_int.high,dx
	jg	fail
	jl	right
	cmp	ss:[bp].PDF_x.DWF_int.low,ax
	jg	fail
	jl	right
	cmp	ss:[bp].PDF_x.DWF_frac,cx
	ja	fail

right:
	;    Check for click to right of handle
	;    use jle so as not to include pixel just to right
	;    of handle
	;

	negdwf	dxaxcx	
	cmp	ss:[bp].PDF_x.DWF_int.high,dx
	jl	fail
	jg	above
	cmp	ss:[bp].PDF_x.DWF_int.low,ax
	jl	fail
	jg	above
	cmp	ss:[bp].PDF_x.DWF_frac,cx
	jbe	fail


above:
	;    Check for click above of handle
	;

	;    Store (handle height (bh) * .5) as DWFixed in dxax.cx
	clr	cx					;clear factional part
	clr	ah
	mov	al,bh					;height
	shr	ax, 1
	cwd
	;    Set fractional part (cx) to be 1/2 if the height was odd (C=1)
	rcr	cx, 1

	cmp	ss:[bp].PDF_y.DWF_int.high,dx
	jg	fail
	jl	below
	cmp	ss:[bp].PDF_y.DWF_int.low,ax
	jg	fail
	jl	below
	cmp	ss:[bp].PDF_y.DWF_frac,cx
	ja	fail

below:
	;    Check for click below of handle
	;    Be careful so as not to include pixel just below
	;    handle.
	;

	negdwf	dxaxcx	
	cmp	ss:[bp].PDF_y.DWF_int.high,dx
	jl	fail
	jg	hit
	cmp	ss:[bp].PDF_y.DWF_int.low,ax
	jl	fail
	jg	hit
	cmp	ss:[bp].PDF_y.DWF_frac,cx
	ja	hit

fail:
	clc
done:
	.leave
	ret

hit:
	stc
	jmp	done

GrObjHitDetectOneSquareHandle		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawSelectedHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws selection handles for object

PASS:		
		*(ds:si) - instance data
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
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawSelectedHandles 	proc 	far
	class	GrObjClass
	uses	ax,cx,bx,dx,bp,si,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjGetDesiredHandleSize


	;    Create handle location transform gstate
	;

	mov_tr	ax,di					;drawing gstate
	clr	di
	call	GrCreateState
	call	GrObjApplyNormalTransform	
	mov	dx,di					;conversion gstate
	mov_tr	di,ax					;drawing gstate
	

	;    Draw handles on corners
	;

	mov	cl,HANDLE_LEFT_TOP
	call	GrObjDrawOneHandleConvertGState

	mov	cl,HANDLE_RIGHT_TOP
	call	GrObjDrawOneHandleConvertGState

	mov	cl,HANDLE_RIGHT_BOTTOM
	call	GrObjDrawOneHandleConvertGState

	mov	cl,HANDLE_LEFT_BOTTOM
	call	GrObjDrawOneHandleConvertGState			

	mov	cl,HANDLE_MOVE
	call	GrObjDrawOneHandleConvertGState

	mov	cl,HANDLE_MIDDLE_TOP
	call	GrObjDrawOneHandleConvertGState

	mov	cl,HANDLE_MIDDLE_BOTTOM
	call	GrObjDrawOneHandleConvertGState

	mov	cl,HANDLE_RIGHT_MIDDLE
	call	GrObjDrawOneHandleConvertGState

	mov	cl,HANDLE_LEFT_MIDDLE
	call	GrObjDrawOneHandleConvertGState

	mov	di,dx				;conversion gstate
	call	GrDestroyState

	.leave
	ret

GrObjDrawSelectedHandles endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawOneHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one of the selection handles.

CALLED BY:	GLOBAL

PASS:		
		*ds:si - GrObject
		cl - GrObjHandleSpecification		
		di - gstate
		bl - desired handle size DEVICE coords

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
GrObjDrawOneHandle		proc	far
	uses	bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	sub	sp, size PointDWFixed
	mov	bp,sp
	call	GrObjGetNormalPARENTHandleCoords

	tst	cl
	jz	moveHandle
	cmp	cl,mask GrObjHandleSpecification
	je	moveHandle
	call	GrObjDrawOneSquareHandle

clearStack:
	add	sp,size PointDWFixed

	.leave
	ret

moveHandle:
	call	GrObjDrawOneMoveHandle
	jmp	clearStack

GrObjDrawOneHandle		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawOneHandleConvertGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one of the selection handles when passed
		a gstate that can be used to convert the handles
		location from OBJECT coordinates to PARENT 
		coordinates

CALLED BY:	GLOBAL

PASS:		
		*ds:si - GrObject
		cl - GrObjHandleSpecification		
		di - drawing gstate
		bl - desired handle size DEVICE coords
		dx - conversion gstate

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
GrObjDrawOneHandleConvertGState	proc	far
	uses	bp
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	sub	sp, size PointDWFixed
	mov	bp,sp
	call	GrObjGetNormalPARENTHandleCoordsConvertGState

	tst	cl
	jz	moveHandle
	cmp	cl,mask GrObjHandleSpecification
	je	moveHandle
	call	GrObjDrawOneSquareHandle

clearStack:
	add	sp,size PointDWFixed

	.leave
	ret

moveHandle:
	call	GrObjDrawOneMoveHandle
	jmp	clearStack

GrObjDrawOneHandleConvertGState		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawOneSquareHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws one selection handle

CALLED BY:	INTERNAL
		GrObjDrawOneHandle

PASS:		
		di - gstate
		ss:bp - PointDWFixed of center of handle
		bl - desired handle size
	
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
GrObjDrawOneSquareHandle		proc	near
	uses	ax
	.enter

	clr	ax
	cmp	bl, MEDIUM_DESIRED_HANDLE_SIZE
	je	gotSize
	inc	ax
	cmp	bl, SMALL_DESIRED_HANDLE_SIZE
	je	gotSize
	inc	ax
gotSize:
	call	GrObjDrawHandleCommon

	.leave
	ret
GrObjDrawOneSquareHandle		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawHandleCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws one selection handle

CALLED BY:	INTERNAL
		GrObjDrawOneHandle

PASS:		
		di - gstate
		ss:bp - PointDWFixed of center of handle

		ax - index into handleRegionTable to draw
	
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
GrObjDrawHandleCommon		proc	near
	uses	ax,bx,cx,dx,si,ds
	.enter

	mov_tr	si, ax

	movdw	dxcx,ss:[bp].PDF_x.DWF_int
	pushdw	dxcx					;save x large
	movdw	bxax,ss:[bp].PDF_y.DWF_int
	pushdw	bxax					;save y large
	call	GrApplyTranslationDWord

	mov	cx,ss:[bp].PDF_x.DWF_frac
	push	cx
	mov	ax,ss:[bp].PDF_y.DWF_frac
	push	ax
	clr	dx, bx
	call	GrApplyTranslation

	shl	si					;word sized entries
	mov	si, cs:[handleRegionTable][si]
	segmov	ds, cs
	clr	ax, bx
	call	GrDrawRegion

	pop	ax
	pop	cx
	clr	bx, dx
	negwwf	bxax
	negwwf	dxcx
	call	GrApplyTranslation

	popdw	bxax
	negdw	bxax
	popdw	dxcx
	negdw	dxcx
	call	GrApplyTranslationDWord

	.leave
	ret
GrObjDrawHandleCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawOneMoveHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws move handle in center of object

CALLED BY:	INTERNAL
		GrObjOneHandleDraw

PASS:		
		di - gstate translated to center
		ss:bp - PointDWFixed of center of handle
		bl - desired handle size DEVICE coords

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		This routine doesn't work quite right for an odd
		handle width or height

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawOneMoveHandle		proc	near
	uses	ax
	.enter

	mov	ax, (offset firstMoveHandle - offset handleRegionTable) / 2
	cmp	bl, MEDIUM_DESIRED_HANDLE_SIZE
	je	gotSize
	inc	ax
	cmp	bl, SMALL_DESIRED_HANDLE_SIZE
	je	gotSize
	inc	ax
gotSize:
	call	GrObjDrawHandleCommon

	.leave
	ret
GrObjDrawOneMoveHandle		endp

handleRegionTable	label	word
	word	offset MediumSquareHandleRegion
	word	offset SmallSquareHandleRegion
	word	offset LargeSquareHandleRegion
firstMoveHandle		label	word
	word	offset MediumMoveHandleRegion
	word	offset SmallMoveHandleRegion
	word	offset LargeMoveHandleRegion

SmallSquareHandleRegion	word	-2, -2, 2, 2	;the "vis" bounds
				word	-3, EOREGREC
				word	2, -2, 2, EOREGREC
				word	EOREGREC

MediumSquareHandleRegion	word	-4, -4, 4, 4	;the "vis" bounds
				word	-5, EOREGREC
				word	4, -4, 4, EOREGREC
				word	EOREGREC

if 0		;hollow handle region
MediumSquareHandleRegion	word	-4, -4, 4, 4	;the "vis" bounds
				word	-5, EOREGREC
				word	-4, -4, 4, EOREGREC
				word	3, -4, -4, 4, 4, EOREGREC
				word	4, -4, 4, EOREGREC
				word	EOREGREC
endif

LargeSquareHandleRegion		word	-6, -6, 6, 6	;the "vis" bounds
				word	-7, EOREGREC
				word	6, -6, 6, EOREGREC
				word	EOREGREC

SmallMoveHandleRegion		word	-4, -4, 4, 4	;the "vis" bounds
				word	-3, EOREGREC
				word	-2, 0, 0, EOREGREC
				word	-1, -1, 1, EOREGREC
				word	0, -2, 2, EOREGREC
				word	1, -1, 1, EOREGREC
				word	2, 0, 0, EOREGREC
				word	EOREGREC

MediumMoveHandleRegion		word	-4, -4, 4, 4	;the "vis" bounds
				word	-5, EOREGREC
				word	-4, 0, 0, EOREGREC
				word	-3, -1, 1, EOREGREC
				word	-2, -2, 2, EOREGREC
				word	-1, -3, 3, EOREGREC
				word	0, -4, 4, EOREGREC
				word	1, -3, 3, EOREGREC
				word	2, -2, 2, EOREGREC
				word	3, -1, 1, EOREGREC
				word	4, 0, 0, EOREGREC
				word	EOREGREC

if 0		;hollow handle region

MediumMoveHandleRegion		word	-4, -4, 4, 4	;the "vis" bounds
				word	-5, EOREGREC
				word	-4, 0, 0, EOREGREC
				word	-3, -1, -1, 1, 1, EOREGREC
				word	-2, -2, -2, 2, 2, EOREGREC
				word	-1, -3, -3, 3, 3, EOREGREC
				word	0, -4, -4, 4, 4, EOREGREC
				word	1, -3, -3, 3, 3, EOREGREC
				word	2, -2, -2, 2, 2, EOREGREC
				word	3, -1, -1, 1, 1, EOREGREC
				word	4, 0, 0, EOREGREC
				word	EOREGREC

endif

LargeMoveHandleRegion		word	-6, -6, 6, 6	;the "vis" bounds
				word	-7, EOREGREC
				word	-6, 0, 0, EOREGREC
				word	-5, -1, 1, EOREGREC
				word	-4, -2, 2, EOREGREC
				word	-3, -3, 3, EOREGREC
				word	-2, -4, 4, EOREGREC
				word	-1, -5, 5, EOREGREC
				word	0, -6, 6, EOREGREC
				word	1, -5, 5, EOREGREC
				word	2, -4, 4, EOREGREC
				word	3, -3, 3, EOREGREC
				word	4, -2, 2, EOREGREC
				word	5, -1, 1, EOREGREC
				word	6, 0, 0, EOREGREC
				word	EOREGREC


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetNormalDOCUMENTHandleCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the DOCUMENT coordinates for the specified
		handle.

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - GrObject
		cl -  GrObjHandleSpecification
		ss:bp - PointDWFixed 

RETURN:		
		ss:bp - PointDWFixed in DOCUMENT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		This routine will not work correctly for objects in
		groups. But objects in groups should not be drawing
		their handles so you are probably confused anyway.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetNormalDOCUMENTHandleCoords		proc	far
	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>
EC <	push	di						>
EC <	GrObjDeref	di,ds,si				>
EC <	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP	>
EC <	ERROR_NZ	OBJECT_CANNOT_BE_IN_A_GROUP		>
EC <	pop	di						>

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTGetDOCUMENTHandleCoords

	.leave
	ret
GrObjGetNormalDOCUMENTHandleCoords		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSpriteGetDOCUMENTHandleCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the DOCUMENT coordinates for the specified
		handle.

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - GrObject
		cl -  GrObjHandleSpecification
		ss:bp - PointDWFixed

RETURN:		
		ss:bp - PointDWFixed in DOCUMENT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		This routine will not work correctly for objects in
		groups. But objects in groups should not be drawing
		their handles so you are probably confused anyway.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetSpriteDOCUMENTHandleCoords		proc	far
	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>
EC <	push	di						>
EC <	GrObjDeref	di,ds,si				>
EC <	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP	>
EC <	ERROR_NZ	OBJECT_CANNOT_BE_IN_A_GROUP		>
EC <	pop	di						>

	AccessSpriteTransformChunk	si,ds,si
	call	GrObjOTGetDOCUMENTHandleCoords

	.leave
	ret
GrObjGetSpriteDOCUMENTHandleCoords		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTGetDOCUMENTHandleCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the DOCUMENT coordinates for the specified
		handle.

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - ObjectTransform
		cl -  GrObjHandleSpecification
		ss:bp - PointDWFixed

RETURN:		
		ss:bp - PointDWFixed in PARENT

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		This routine will not work correctly for objects in
		groups. But objects in groups should not be drawing
		their handles so you are probably confused anyway.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjOTGetDOCUMENTHandleCoords		proc	near
	uses	ax
	.enter

	call	GrObjOTGetPARENTHandleCoords

	.leave
	ret
GrObjOTGetDOCUMENTHandleCoords		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetNormalPARENTHandleCoordsConvertGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the PARENT coordinates for the specified
		handle when passed a gstate that can be used
		to convert the handle location from OBJECT to
		PARENT

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - GrObject
		cl -  GrObjHandleSpecification
		ss:bp - PointDWFixed 
		dx - convert gstate

RETURN:		
		ss:bp - PointDWFixed in PARENT

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
GrObjGetNormalPARENTHandleCoordsConvertGState		proc	far
	class	GrObjClass
	uses	si,ax,bx,cx,dx,di,es
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	di,dx				;convert gstate
	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTGetOBJECTHandleCoords
	push	dx				;x int
	xchg	bx,ax				;y frac, y int
	cwd					;sign extend y
	movdwf	ss:[bp].PDF_y,dxaxbx
	pop	ax				;x int
	cwd					;sign extend x
	movdwf	ss:[bp].PDF_x,dxaxcx
	segmov	es,ss,dx
	mov	dx,bp
	call	GrTransformDWFixed
	
	.leave
	ret
GrObjGetNormalPARENTHandleCoordsConvertGState		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetNormalPARENTHandleCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the PARENT coordinates for the specified
		handle.

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - GrObject
		cl -  GrObjHandleSpecification
		ss:bp - PointDWFixed 

RETURN:		
		ss:bp - PointDWFixed in PARENT

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
GrObjGetNormalPARENTHandleCoords		proc	far
	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	AccessNormalTransformChunk	si,ds,si
	call	GrObjOTGetPARENTHandleCoords

	.leave
	ret
GrObjGetNormalPARENTHandleCoords		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSpriteGetPARENTHandleCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the PARENT coordinates for the specified
		handle.

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - GrObject
		cl -  GrObjHandleSpecification
		ss:bp - PointDWFixed

RETURN:		
		ss:bp - PointDWFixed in PARENT

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
GrObjGetSpritePARENTHandleCoords		proc	far
	class	GrObjClass
	uses	si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	AccessSpriteTransformChunk	si,ds,si
	call	GrObjOTGetPARENTHandleCoords

	.leave
	ret
GrObjGetSpritePARENTHandleCoords		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTGetPARENTHandleCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the PARENT coordinates for the specified
		handle.

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - ObjectTransform
		cl -  GrObjHandleSpecification
		ss:bp - PointDWFixed

RETURN:		
		ss:bp - PointDWFixed in OBJECT

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
GrObjOTGetPARENTHandleCoords		proc	far
	uses	ax,bx,cx,dx
	.enter

	call	GrObjOTGetOBJECTHandleCoords
	push	dx				;x int
	xchg	bx,ax				;y frac, y int
	cwd					;sign extend y
	movdwf	ss:[bp].PDF_y,dxaxbx
	pop	ax				;x int
	cwd					;sign extend x
	movdwf	ss:[bp].PDF_x,dxaxcx
	call	GrObjOTConvertOBJECTToPARENT

	.leave
	ret
GrObjOTGetPARENTHandleCoords		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjOTGetOBJECTHandleCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the OBJECT coordinates for the specified
		handle.

CALLED BY:	INTERNAL UTILITY

PASS:		
		ds:si - ObjectTransform
		cl -  GrObjHandleSpecification

RETURN:		
		dx:cx - WWFixed x in OBJECT
		bx:ax - WWFixed y in OBJECT

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
GrObjOTGetOBJECTHandleCoords		proc	far
	uses	bp
	.enter

	;    Start with center x
	;

	clr	bp
	mov	dx,bp

	test	cl, mask GOHS_HANDLE_LEFT
	jz	right
	movwwf	bxax,ds:[si].OT_width
	sarwwf	bxax
	subwwf	dxbp,bxax

right:
	test	cl, mask GOHS_HANDLE_RIGHT
	jz	top
	movwwf	bxax,ds:[si].OT_width
	sarwwf	bxax
	addwwf	dxbp,bxax

top:
	push	dx,bp					;x
	clr	ax
	mov	bx,ax
	test	cl, mask GOHS_HANDLE_TOP
	jz	bottom
	movwwf	dxbp,ds:[si].OT_height
	sarwwf	dxbp
	subwwf	bxax,dxbp

bottom:
	test	cl, mask GOHS_HANDLE_BOTTOM
	jz	done
	movwwf	dxbp,ds:[si].OT_height
	sarwwf	dxbp
	addwwf	bxax,dxbp

done:
	pop	dx,cx					;x

	.leave
	ret
GrObjOTGetOBJECTHandleCoords		endp



GrObjRequiredExtInteractiveCode ends


