COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj	
FILE:		pointerUtils.asm

AUTHOR:		Steve Scholl, Jan 17, 1992

ROUTINES:
	Name	
	----	
PointerSetOrigMousePt		
PointerCalcMouseDelta		
PointerSendMouseDelta		
PointerSendResizeDelta		
PointerSendRotateDelta	
PointerSetResizeInfo
PointerSetRotateInfo
PointerCalcLineAngle
PointerCalcCenterAnchorAngleDelta
PointerCalcOppositeAnchorAngleDelta
PointerSetPointDWFixedInVarData
PointerStoreCenter
PointerEndCleanUp
PointerSendToActionGrObj
PointerSendToActionGrObjOnStack		
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	1/17/92		Initial revision


DESCRIPTION:
	
		

	$Id: pointerUtils.asm,v 1.1 97/04/04 18:08:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateMouseDeltaStackFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

Expects ss:bp - GrObMouseData of current mouse position and *ds:si as instance
data of pointer object with GOOMD_origMousePt set. Creates new stack frame,
without damaging old, that has current mouse position - origMousePt



PASS:		
	*ds:si - instance data of object
	ss:bp - GrObjMouseData current mouse position

RETURN:		
	orig bp on stack
	ss:bp - GrObjMouseData stack frame with delta

DESTROYED:	
	bx

PSEUDO CODE/STRATEGY:
	none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateMouseDeltaStackFrame macro
	push	bp				;orig stack frame
	sub	sp,size GrObjMouseData
	mov	bx,bp				;orig stack frame
	mov	bp,sp				;new stack frame
	push	ss:[bx].GOMD_gstate
	pop	ss:[bp].GOMD_gstate
	push	ss:[bx].GOMD_goFA
	pop	ss:[bp].GOMD_goFA
	call	PointerCalcMouseDelta
endm


CleanMouseDeltaStackFrame	macro
	add	sp, size GrObjMouseData
	pop	bp				;orig stack frame
endm

GrObjRequiredExtInteractive2Code	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerSetOrigMousePt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set GOOMD_origMousePt data from stack frame

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data of object
		ss:bp - PointDWFixed 
RETURN:		
		GOOMD_origMousePt set

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerSetOrigMousePt		proc	far
	class	PointerClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	mov	di,offset GOOMD_origMousePt
	call	PointerSetPointDWFixedInVarData

	.leave
	ret
PointerSetOrigMousePt		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerGetObjManipVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If ATTR_GO_OBJ_MANIP_DATA exists then return ptr to it,
		otherwise create ATTR_GO_OBJ_MANIP_DATA and return ptr
		to it.

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object

RETURN:		
		ds:bx - GrObjObjManipData at ATTR_GO_OBJ_MANIP_DATA
		in var data

		carry set - if data already existed
		carry clear - if data had to be created

		fptr into var data will not be valid after lmem operations

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
	srs	10/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerGetObjManipVarData		proc	far
	uses	ax,cx
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	mov	ax,ATTR_GO_OBJ_MANIP_DATA
	call	ObjVarFindData
	jnc	notFound

done:
	.leave
	ret

notFound:
	mov	cx,size GrObjObjManipData
	call	ObjVarAddData
	clc
	jmp	done

PointerGetObjManipVarData		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerCalcMouseDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the mouse delta between the current mouse
		position in GrObjMouseData at ss:bp and the 
		GOOMD_origMousePt in the object's var data.
		Store the results in stack frame at ss:bp

CALLED BY:	INTERNAL (UTILITY)
		

PASS:		
		*ds:si - pointer
		ss:bx - GrObjMouseData of current mouse position
		ss:bp - empty PointDWFixed

RETURN:		
		ss:bp -GrObjMouseData with mouse deltas

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerCalcMouseDelta		proc	far
	class	GrObjClass
	uses	ax,di
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	mov	di,bx					;dest frame offset
	call	PointerGetObjManipVarData
	mov	ax,ss:[di].GOMD_point.PDF_x.DWF_frac
	sub	ax,ds:[bx].GOOMD_origMousePt.PDF_x.DWF_frac
	mov	ss:[bp].PDF_x.DWF_frac,ax

	mov	ax,ss:[di].GOMD_point.PDF_x.DWF_int.low
	sbb	ax,ds:[bx].GOOMD_origMousePt.PDF_x.DWF_int.low
	mov	ss:[bp].PDF_x.DWF_int.low,ax

	mov	ax,ss:[di].GOMD_point.PDF_x.DWF_int.high
	sbb	ax,ds:[bx].GOOMD_origMousePt.PDF_x.DWF_int.high
	mov	ss:[bp].PDF_x.DWF_int.high,ax

	mov	ax,ss:[di].GOMD_point.PDF_y.DWF_frac
	sub	ax,ds:[bx].GOOMD_origMousePt.PDF_y.DWF_frac
	mov	ss:[bp].PDF_y.DWF_frac,ax

	mov	ax,ss:[di].GOMD_point.PDF_y.DWF_int.low
	sbb	ax,ds:[bx].GOOMD_origMousePt.PDF_y.DWF_int.low
	mov	ss:[bp].PDF_y.DWF_int.low,ax

	mov	ax,ss:[di].GOMD_point.PDF_y.DWF_int.high
	sbb	ax,ds:[bx].GOOMD_origMousePt.PDF_y.DWF_int.high
	mov	ss:[bp].PDF_y.DWF_int.high,ax

	.leave
	ret
PointerCalcMouseDelta		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerSendMouseDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate delta of mouse from origMousePt and send it
		with method to actionGrObj or the entire selection
		list if there is no action object

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjMouseData 
			GOMD_point -- current mouse position
			GOMD_gstate
			GOMD_goFA
		ax - method #
		GOOMD_origMousePt

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
	srs	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerSendMouseDelta		proc	far
	uses	bx,dx
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	CreateMouseDeltaStackFrame

	mov	dx,size GrObjMouseData
	call	PointerSendToActionGrObjOnStack
	jnc	sendToList				;jmp if no action
done:
	CleanMouseDeltaStackFrame
	.leave
	ret

sendToList:
	call	GrObjSendToSelectedGrObjsShareData
	jmp	short done
PointerSendMouseDelta		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerSetPointDWFixedInVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set PointDWFixed in var data from stack frame

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data of object
		di - offset to PointDWFixed in var data
		ss:bp - PointDWFixed 
RETURN:		
		PointDWFixed in var data

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerSetPointDWFixedInVarData		proc	far
	class	GrObjClass
	uses	ax,bx,cx,di,si,es
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	call	PointerGetObjManipVarData
	add	di,bx
	segmov	es,ds,ax			;dest segment
	segmov	ds,ss,ax			;source segment
	mov	si,bp				;source offset
	mov	cx,(size PointDWFixed)/2
	rep	movsw
	segmov	ds,es,ax			;pointer segment

	.leave
	ret
PointerSetPointDWFixedInVarData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerStoreCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set center in normalTransform to passed
		mousePosition

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed - mouse location
RETURN:		
		OT_center in normal transform

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerStoreCenter		proc	far
	uses	cx,di,si,es
	class	PointerClass
	.enter

EC <	call	ECPointerCheckLMemObject		>
	
	AccessNormalTransformChunk		di,ds,si

	segmov	es,ds				;dest segment
	add	di, offset OT_center		;dest offset
	segmov	ds,ss				;source segment
	mov	si,bp				;source offset
	mov	cx,(size PointDWFixed)/2
	rep	movsw
	segmov	ds,es				;pointer segment

	.leave
	ret
PointerStoreCenter		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerEndCleanUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset instance data after an END_SELECT or END_MOVE_COPY
		method to prepare for the next action by user

CALLED BY:	INTERNAL (UTILITY)
		

PASS:		
		*(ds:si) - instance data

RETURN:		
		GOI_actionModes - choose and move activated
		GOOMD_actionGrObj - cleared

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerEndCleanUp		proc	far
	class  GrObjClass
	uses	ax,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	;    Reset state to waiting for move/choose by user
	;

	GrObjDeref	di,ds,si
	clr	ds:[di].GOI_actionModes

	mov	ax,MSG_GO_RELEASE_MOUSE
	call	ObjCallInstanceNoLock

	mov	ax,ATTR_GO_OBJ_MANIP_DATA
	call	ObjVarDeleteData

	.leave
	ret
PointerEndCleanUp		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerSendToActionGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to pointer's action object

CALLED BY:	INTERNAL
		PointerDoHandleHit
		PointerPtrBasicChoose
		PointerPtrAdjustChoose
		PointerSendMouseDelta
		PointerEndBasicChoose
		PointerDrawSpriteRaw

PASS:		
		*(ds:si) - instance data of pointer
		ax - method
		cx,dx,bp -other data

RETURN:		
		stc - message sent
		clc - message not sent

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerSendToActionGrObj		proc	far
	class	PointerClass
	uses	bx,di,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	PointerGetObjManipVarData
	mov	di,bx					;offset var data
	mov	bx,ds:[di].GOOMD_actionGrObj.handle
	tst	bx
	jz	notSent
	mov	si,ds:[di].GOOMD_actionGrObj.chunk
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	stc
done:
	.leave
	ret

notSent:
	clc
	jmp	short done

PointerSendToActionGrObj		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerSendToActionGrObjOnStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to pointer's action object

CALLED BY:	INTERNAL
		PointerSendMouseDelta

PASS:		
		*(ds:si) - instance data of grobj
		ax - method
		ss:bp - stack frame
		dx - size of stack frame

RETURN:		
		stc - message sent
		clc - message not sent

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerSendToActionGrObjOnStack		proc	far
	class	GrObjClass
	uses	bx,di,si
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	PointerGetObjManipVarData
	mov	di,bx
	mov	bx,ds:[di].GOOMD_actionGrObj.handle
	tst	bx
	jz	notSent
	mov	si,ds:[di].GOOMD_actionGrObj.chunk
	mov	di,mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	ObjMessage
	stc
done:
	.leave
	ret

notSent:
	clc
	jmp	short done

PointerSendToActionGrObjOnStack		endp





GrObjRequiredExtInteractive2Code	ends


GrObjExtInteractiveCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerSendResizeDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate delta of mouse from origMousePt and send it
		with method to actionGrObj or the entire selection
		list if there is no action object

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data
		ss:bp - GrObjMouseData 
			GOMD_point -- current mouse position
			GOMD_gstate
			GOMD_goFA
		ax - method #
		GOOMD_origMousePt
		GOOMD_oppositeHandle
		GOOMD_grabbedHandle

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
	srs	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerSendResizeDelta		proc	far
	uses	bx,dx,di,bp
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    Calculate delta of mouse and put in new stack frame
	;

	mov	bx,bp				;orig stack frame
	sub	sp,size GrObjResizeMouseData
	mov	bp,sp				;new stack frame
	mov	dx,ss:[bx].GOMD_gstate
	mov	ss:[bp].GORSMD_gstate,dx
	mov	dx,ss:[bx].GOMD_goFA
	mov	ss:[bp].GORSMD_goFA,dx
	call	PointerCalcMouseDelta

	;    Get OHS of anchored handle
	;

	call	PointerGetObjManipVarData
	mov	dl,ds:[bx].GOOMD_oppositeHandle

	;     If not resizing from center, jump to set anchor, otherwise
	;     clear anchor
	;

	test	ss:[bp].GORSMD_goFA, mask GOFA_FROM_CENTER
	jz	setAnchor
	clr	dl

setAnchor:
	mov	ss:[bp].GORSMD_anchor,dl
	mov	dl,ds:[bx].GOOMD_grabbedHandle
	mov	ss:[bp].GORSMD_grabbed,dl

	mov	dx,size GrObjResizeMouseData
	call	PointerSendToActionGrObjOnStack

	add	sp, size GrObjResizeMouseData

	.leave
	ret

PointerSendResizeDelta		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerSetResizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate and store information necessary to resize
		objects

CALLED BY:	INTERNAL (UTILITY)


PASS:		*(ds:si) - instance data
		cl - GrObjHandleSpecification of grabbed handle

RETURN:		
		GOOMD_oppositeHandle - GrObjHandleSpecification of 
					opposite anchor
		GOOMD_grabbedHandle - GrObjHandleSpecification of 
					grabbed handle
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerSetResizeInfo		proc	far
	uses	cx,bx
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	call	PointerGetObjManipVarData
	mov	ds:[bx].GOOMD_grabbedHandle,cl

	not	cl
	and	cl, mask GrObjHandleSpecification
	mov	ds:[bx].GOOMD_oppositeHandle,cl

	.leave
	ret
PointerSetResizeInfo		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerSendRotateDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate rotation delta and send message to 
		action object (or selection list if no action object ) 
		with GrObjRotateMouseData stack frame

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*ds:si -  pointer object
		GOOMD_origMousePt - center of object being rotated
		GOOMD_initialAngle
		GOOMD_oppositeAnchor - position of not from center anchor
		GOOMD_initialOppositeAngle
		GOOMD_oppositeHandle
		ax - message
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
	srs	10/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerSendRotateDelta		proc	far
	class 	PointerClass
	uses	bx,cx,dx,di,bp
	.enter

EC <	call	ECPointerCheckLMemObject		>


	;    Create stack frame to send rotate delta in
	;

	sub	sp,size GrObjRotateMouseData
	mov	bx,sp
	mov	dx,ss:[bp].GOMD_goFA
	mov	ss:[bx].GORMD_goFA,dx
	mov	dx,ss:[bp].GOMD_gstate
	mov	ss:[bx].GORMD_gstate,dx

	;    If not rotating around center then jump to send 
	;    rotate info for opposite anchor

	test	ss:[bp].GOMD_goFA, mask GOFA_ABOUT_OPPOSITE
	jnz	oppositeAnchor

	;    Calculate angle delta and put in stack frame along
	;    with anchor specification for center
	;

	call	PointerCalcCenterAnchorAngleDelta
	mov	ss:[bx].GORMD_degrees.WWF_int,dx
	mov	ss:[bx].GORMD_degrees.WWF_frac,cx
	clr	ss:[bx].GORMD_anchor		

sendToAction:
	mov	bp,bx				;GrOrbjRotateData offset
	mov	dx,size GrObjRotateMouseData
	call	PointerSendToActionGrObjOnStack
	jnc	sendToList

clean:
	add	sp,size GrObjRotateMouseData

	.leave
	ret

oppositeAnchor:
	;    Calculate angle delta and put in stack frame along
	;    with anchor specification for center
	;

	call	PointerCalcOppositeAnchorAngleDelta
	mov	ss:[bx].GORMD_degrees.WWF_int,dx
	mov	ss:[bx].GORMD_degrees.WWF_frac,cx

	mov	di,bx					;stack frame
	call	PointerGetObjManipVarData
	xchg	bx,di				;stack frame, var data
	mov	cl,ds:[di].GOOMD_oppositeHandle
	mov	ss:[bx].GORMD_anchor,cl
	jmp	sendToAction

sendToList:
	mov	di,mask MF_STACK
	call	GrObjSendToSelectedGrObjs
	jmp	clean


PointerSendRotateDelta		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerSetRotateInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate and store information necessary to rotate
		objects

CALLED BY:	INTERNAL (UTILITY)

PASS:		*(ds:si) - instance data
		ss:bp - PointDWFixed - location of mouse in doc coords
		GOOMD_actionGrObj
		cl - GrObjHandleSpecification of grabbed handle

RETURN:		
		GOOMD_origMousePt - center of rotating object
		GOOMD_initialAngle - angle of line from center of object 
				   to mouse point
		GOOMD_oppositeAnchor - anchor point that object will rotate
					about if not about center
		GOOMD_oppositeInitialAngle - angle of line from oppositeAnchor
						to mouse point
		GOOMD_oppositeHandle - GrObjHandleSpecification of 
					opposite anchor
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerSetRotateInfo		proc	far
	uses	ax,bx,cx,dx,di
	class	PointerClass
	.enter

EC <	call	ECPointerCheckLMemObject			>

	push	cx				;grabbed handle

	;    Get center of object to be rotated
	;

	mov	bx,bp				;orig stack frame
	sub	sp,size PointDWFixed
	mov	bp,sp
	mov	ax,MSG_GO_GET_CENTER
	mov	dx,size PointDWFixed
	call	PointerSendToActionGrObjOnStack

	;    Copy center of object to GOOMD_origMousePt
	;

	call	PointerSetOrigMousePt
	add	sp, size PointDWFixed
	mov	bp,bx				;orig stack frame

	;    Calc angle of line from center of object to
	;    current mouse pt in stack frame and store it
	;

	mov	di,offset GOOMD_origMousePt
	call	PointerCalcLineAngle
EC <	ERROR_C	BAD_POINTER_LINE_ANGLE_CALCULATION		>
	call	PointerGetObjManipVarData
	mov	ds:[bx].GOOMD_initialAngle.WWF_frac,cx
	mov	ds:[bx].GOOMD_initialAngle.WWF_int,dx

	;    Calc GrObjHandleSpecification of opposite handle
	;    and store in instance data
	;

	pop	cx				;grabbed handle
	not	cl
	and	cl, mask GrObjHandleSpecification
	mov	ds:[bx].GOOMD_oppositeHandle,cl

	;    Get anchor of object to be rotated
	;

	mov	bx,bp					;orig stack frame
	sub	sp,size GrObjHandleAnchorData
	mov	bp,sp
	mov	ss:[bp].GOHAD_handle,cl			;opposite handle spec
	mov	ax,MSG_GO_GET_ANCHOR_DOCUMENT
	mov	dx,size GrObjHandleAnchorData
	call	PointerSendToActionGrObjOnStack

	;    Copy anchor of object to GOOMD_origMousePt
	;

	mov	di,offset GOOMD_oppositeAnchor
	call	PointerSetPointDWFixedInVarData
	add	sp, size GrObjHandleAnchorData
	mov	bp,bx				;orig stack frame

	;    Calc angle of line from anchor of object to
	;    current mouse pt in stack frame and store it
	;

	mov	di,offset GOOMD_oppositeAnchor
	call	PointerCalcLineAngle
EC <	ERROR_C	BAD_POINTER_LINE_ANGLE_CALCULATION		>
	call	PointerGetObjManipVarData
	mov	ds:[bx].GOOMD_oppositeInitialAngle.WWF_frac,cx
	mov	ds:[bx].GOOMD_oppositeInitialAngle.WWF_int,dx

	.leave
	ret
PointerSetRotateInfo		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerCalcLineAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate angle of the line from PointDWFixed in
		vardata to PointDWFixed in stack frame

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - pointer
		di - offset to PointDWFixed in var data
		ss:bp - PointDWFixed	

RETURN:		
		clc
			dx:cx - WWFixed angle

		stc - couldn't calc angle 
			dx,cx - destoryed
DESTROYED:	
		See RETURN

PSEUDO CODE/STRATEGY:
		Treat the source point as 0,0 and calculate the
		angle of line going from it to the other point.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Ignoring fractional info because GrObjCalcLineAngle
		doesn't take fractional position.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerCalcLineAngle		proc	far
	uses	ax,bx,di
	class	PointerClass
	.enter

EC <	call	ECPointerCheckLMemObject		>
	
	call	PointerGetObjManipVarData
	add	di,bx				;offset to source PointDWFixed

	;    Subtract source point from point on stack
	;    If either x or y of difference doesn't fit in
	;    word then bail
	;

	mov	bx,ss:[bp].PDF_x.DWF_int.high
	mov	ax,ss:[bp].PDF_x.DWF_int.low
	sub	ax,ds:[di].PDF_x.DWF_int.low
	sbb	bx,ds:[di].PDF_x.DWF_int.high

	;   If the sign extension of the low word doesn't equal the high
	;   word, then the value doesn't fit in a word
	;

	cwd
	cmp	dx,bx					;sign ext, high int
	jne	fail
	mov	cx,ax					;x low int

	mov	bx,ss:[bp].PDF_y.DWF_int.high
	mov	ax,ss:[bp].PDF_y.DWF_int.low
	sub	ax,ds:[di].PDF_y.DWF_int.low
	sbb	bx,ds:[di].PDF_y.DWF_int.high

	;   If the sign extension of the low word doesn't equal the high
	;   word, then the value doesn't fit in a word
	;

	cwd
	cmp	dx,bx					;sign ext, high int
	jne	fail
	mov	dx,ax					;y low int

	;    Calc angle from 0,0 to point calced above
	;

	clr	ax					
	mov	bx,ax					
	call	GrObjCalcLineAngle

done:	
	.leave
	ret

fail:
	stc	
	jmp	short done


PointerCalcLineAngle		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerCalcCenterAnchorAngleDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calcs the difference between the PTR_initialAngle
		and the angle between PTR_origMousePt and the
		point in the stack frame

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - pointer instance data
		GOOMD_origMousePt
		GOOMD_initialAngle
		ss:bp - PointDWFixed

RETURN:		
		dx:cx - WWFixed angle delta

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerCalcCenterAnchorAngleDelta		proc	far
	uses	di,bx
	class	PointerClass
	.enter

EC <	call	ECPointerCheckLMemObject			>

	mov	di, offset GOOMD_origMousePt
	call	PointerCalcLineAngle
	jc	failedCalc

	call	PointerGetObjManipVarData
	sub	cx,ds:[bx].GOOMD_initialAngle.WWF_frac
	sbb	dx,ds:[bx].GOOMD_initialAngle.WWF_int
done:
	.leave
	ret

failedCalc:
	;    If the angle couldn't be calculated (because mouse pt
	;    is very far from the origMousePt), just return 0
	;    as the delta
	;

	clr	dx
	mov	cx,dx
	jmp	short done

PointerCalcCenterAnchorAngleDelta		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerCalcOppositeAnchorAngleDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calcs the difference between the PTR_oppositeInitialAngle
		and the angle between PTR_oppositeAnchor and the
		point in the stack frame

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - pointer instance data
		GOOMD_oppositeAnchor
		GOOMD_initialAngle
		ss:bp - PointDWFixed

RETURN:		
		dx:cx - WWFixed angle delta

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerCalcOppositeAnchorAngleDelta		proc	far
	uses	di,bx
	class	PointerClass
	.enter

EC <	call	ECPointerCheckLMemObject			>

	mov	di, offset GOOMD_oppositeAnchor
	call	PointerCalcLineAngle
	jc	failedCalc

	call	PointerGetObjManipVarData
	sub	cx,ds:[bx].GOOMD_oppositeInitialAngle.WWF_frac
	sbb	dx,ds:[bx].GOOMD_oppositeInitialAngle.WWF_int
done:
	.leave
	ret

failedCalc:
	;    If the angle couldn't be calculated (because mouse pt
	;    is very far from the anchor), just return 0
	;    as the delta
	;

	clr	dx
	mov	cx,dx
	jmp	short done

PointerCalcOppositeAnchorAngleDelta		endp



GrObjExtInteractiveCode	ends
