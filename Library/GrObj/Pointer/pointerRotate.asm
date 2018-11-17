COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ptr.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
		

	$Id: pointerRotate.asm,v 1.1 97/04/04 18:08:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjClassStructures	segment resource


	;Define the class record

RotatePointerClass

GrObjClassStructures	ends

GrObjExtInteractiveCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotatePointerInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the RotatePointerInstance data portion

PASS:		
		*ds:si - instance data
		es - segment of RotatePointerClass
RETURN:		
		nothing
DESTROYED:	
		di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotatePointerInitialize method RotatePointerClass, MSG_META_INITIALIZE
	mov	di,	offset RotatePointerClass
	CallSuper	MSG_META_INITIALIZE
	GrObjDeref	di,ds,si
	mov	ds:[di].PTR_modes, mask PM_HANDLES_ROTATE
	ret
RotatePointerInitialize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotatePointerGetPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return od of pointer image

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RotatePointerClass

		ss:bp - PointDWFixed

RETURN:		
		ax - mask MRF_NEW_POINTER_IMAGE
		cx:dx - od of pointer image
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			object will be in create mode

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotatePointerGetPointerImage	method dynamic RotatePointerClass, 
			MSG_GO_GET_POINTER_IMAGE
	.enter

	mov	al,ds:[di].GOI_actionModes
	test	al,mask GOAM_MOVE
	jz	tryRotate
	mov	cl,GOPIS_MOVE
	jmp	getImage

getImage:
	mov	ax,MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	clr	al
	ornf	ax, mask MRF_PROCESSED

	.leave
	ret

tryRotate:
	test	al,mask GOAM_ROTATE
	jz	checkHandle
	mov	cl,GOPIS_RESIZE_ROTATE
	jmp	getImage

checkHandle:
	call	RotatePointerGetPointOverAHandlePointerImageSituation
	jmp	getImage

RotatePointerGetPointerImage		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotatePointerGetPointOverAHandlePointerImageSituation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the point over handle and return the
		GrObjPointerImageSituation that is appropriate. If the
		point is not over a handle return GOPIS_NORMAL

CALLED BY:	INTERNAL UTILITY

PASS:		
		ss:bp - PointDWFixed

RETURN:		
		cl - GrObjPointerImageSituation
		first child in priority list is the one whose handle was hit

DESTROYED:	
		ch

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotatePointerGetPointOverAHandlePointerImageSituation		proc	far
	uses	ax
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_ROTATE
	call	GrObjGlobalCheckForPointOverAHandle
	jc	handleHit

	mov	cl,GOPIS_NORMAL
done:
	.leave
	ret

handleHit:
	cmp	al,HANDLE_MOVE
	jne	rotate
	mov	cl,GOPIS_MOVE
	jmp	done

rotate:
	mov	cl,GOPIS_RESIZE_ROTATE
	jmp	done

RotatePointerGetPointOverAHandlePointerImageSituation		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotatePointerGetSituationalPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return default pointer images for situation

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RotatePointerClass

		cl - GrObjPointerImageSituation

RETURN:		
		ah - high byte of MouseReturnFlags
			MRF_SET_POINTER_IMAGE or MRF_CLEAR_POINTER_IMAGE
		if MRF_SET_POINTER_IMAGE
		cx:dx - optr of mouse image
	
DESTROYED:	
		al

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotatePointerGetSituationalPointerImage	method dynamic RotatePointerClass, 
					MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	.enter

CheckHack < GOPIS_NORMAL eq 0 >
CheckHack < GOPIS_EDIT eq 1 >
CheckHack < GOPIS_CREATE eq 2 >

	cmp	cl,GOPIS_CREATE
	jg	other

	mov	ax,mask  MRF_SET_POINTER_IMAGE
	mov	cx,handle ptrRotateTool
	mov	dx,offset ptrRotateTool

done:
	.leave
	ret

other:
	cmp	cl,GOPIS_RESIZE_ROTATE
	jne	callSuper
	mov	ax,mask MRF_SET_POINTER_IMAGE
	mov	cx,handle ptrRotate
	mov	dx,offset ptrRotate
	jmp	done

callSuper:
	mov	di,offset RotatePointerClass
	call	ObjCallSuperNoLock
	jmp	done

RotatePointerGetSituationalPointerImage	endm

GrObjExtInteractiveCode	ends


