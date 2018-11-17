COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GrObj
MODULE:		GrObj
FILE:		grobjHandles.asm

AUTHOR:		Steve Scholl, Aug 21, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	8/21/92		Initial revision


DESCRIPTION:
	
		

	$Id: grobjHandles.asm,v 1.1 97/04/04 18:07:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



GrObjRequiredExtInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjHandleHitDetection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if point hits any of the objects handles

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		ss:bp - PointDWFixed in PARENT

RETURN:		
		al - EVALUATE_NONE
			ah - destroyed
		al - EVALUATE_HIGH
			ah - GrObjHandleSpecification of hit handle

		dx - 0 ( blank EvaluatePositionNotes)

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE 

		Common cases:
			GOTM_HANDLES_DRAWN will be set
			The CENTER RELATIVE point will fit in WWF
			The hit detection will fail.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjHandleHitDetection	method dynamic GrObjClass, 
		MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE, 
		MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_RESIZE, 
		MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_ROTATE

	uses	cx,bp
	.enter

	test	ds:[di].GOI_tempState, mask GOTM_HANDLES_DRAWN
	jz	fail

	mov	cx,mask GOL_MOVE or mask GOL_RESIZE
	cmp	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_RESIZE
	jne	other

hitDetect:
	call	GrObjDoHitDetectionOnAllHandles
	jc	success

fail:
	mov	al, EVALUATE_NONE
done:
	clr	dx					;EvaluatePositionNotes

	.leave
	ret

success:
	mov	al, EVALUATE_HIGH
	jmp	short done

other:
	mov	cx,mask GOL_MOVE or mask GOL_ROTATE
	cmp	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_ROTATE
	je	hitDetect
	clr	cx
	jmp	hitDetect


GrObjHandleHitDetection		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws handles to indicate object is selected. 
 
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		dx - BODY_GSTATE gstate or 0

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	if not selected don't draw
	if handles are already drawn don't draw
	if in edit mode don't draw

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawHandles method dynamic GrObjClass, MSG_GO_DRAW_HANDLES
	uses	ax,cx,dx
	.enter

	call	GrObjCanDrawHandles?
	jnc	done

	;    Handles are being reset to their normal state, so clear
	;    the temp bit
	;

	clr	cl
	mov	ch, mask GOTM_TEMP_HANDLES
	call	GrObjChangeTempStateBits

	test	ds:[di].GOI_tempState, mask GOTM_SELECTED 
	jz	done
	test	ds:[di].GOI_tempState, mask GOTM_SYS_TARGET
	jz	done

	;   if the object handles are already drawn then
	;   don't draw handles
	;

	test	ds:[di].GOI_tempState, mask GOTM_HANDLES_DRAWN
	jnz	done

	;    Mark handles as being draw
	;

	mov	cl, mask GOTM_HANDLES_DRAWN
	clr	ch
	call	GrObjChangeTempStateBits

	;    Draw those handles
	;

	mov	di,dx					;passed gstate or 0
	call	GrObjGetBodyGStateStart
	mov	dx,di					;gstate for handles
	mov	ax,MSG_GO_INVERT_HANDLES
	call	ObjCallInstanceNoLock
	call	GrObjGetGStateEnd

done:
	.leave
	ret

GrObjDrawHandles endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjUnDrawHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the handles that indicate the object is selected.
		Only erases the handles if the handlesDrawn flag IS set.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		dx - gstate or 0

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
GrObjUnDrawHandles method dynamic GrObjClass, MSG_GO_UNDRAW_HANDLES
	uses	cx,dx
	.enter

	call	GrObjCanDrawHandles?
	jnc	done

	;    Handles are being reset to their normal state, so clear
	;    the temp bit
	;

	clr	cl
	mov	ch,  mask GOTM_TEMP_HANDLES
	call	GrObjChangeTempStateBits

	call	GrObjUnDrawHandlesLow
done:

	.leave
	ret
GrObjUnDrawHandles endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjUnDrawHandlesLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the handles that indicate the object is selected.
		Only erases the handles if the handlesDrawn flag IS set.

CALLED BY:	INTERNAL
		GrObjUnDrawHandles

PASS:		
		*(ds:si) - instance data of object
		es - segment of GrObjClass
		dx - gstate or 0
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
GrObjUnDrawHandlesLow proc near
	uses	ax,bx,cx,di
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject			>

	;    If the handles are not drawn then don't erase them
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_tempState, mask GOTM_HANDLES_DRAWN
	jz	done

	;    Mark handles as not drawn
	;

	clr	cl
	mov	ch,  mask GOTM_HANDLES_DRAWN
	call	GrObjChangeTempStateBits
	
	;    Erase those handles
	;

	mov	di,dx					;passed gstate or 0
	call	GrObjGetBodyGStateStart
	mov	dx,di				;gstate
	mov	ax,MSG_GO_INVERT_HANDLES
	call	ObjCallInstanceNoLock
	call	GrObjGetGStateEnd

done:
	.leave
	ret
GrObjUnDrawHandlesLow endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawHandlesForce
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws handles of object, reqardless of selected bit
 
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		dx - gstate or 0

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	if handles are already drawn don't draw
	if in edit mode don't draw

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawHandlesForce method dynamic GrObjClass, MSG_GO_DRAW_HANDLES_FORCE
	uses	cx,dx
	.enter

	call	GrObjCanDrawHandles?
	jnc	done

	;    Having the handles forcibly drawn is a temporary state,
	;    mark it as such, so that we can find this object again.
	;

	mov	cl, mask GOTM_TEMP_HANDLES	
	clr	ch
	call	GrObjChangeTempStateBits

	call	DrawHandlesForce
done:
	.leave
	ret

GrObjDrawHandlesForce endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHandlesForce
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws handles of object, reqardless of selected bit
 
PASS:		
		*(ds:si) - instance data of object

		dx - gstate or 0
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	if handles are already drawn don't draw
	if in edit mode don't draw

	This routine will draw the handles regardless of the state of
	the GOTM_SYS_TARGET bit because we can't count on that bit
	unless the GOTM_SELECTED bit is set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawHandlesForce 	proc 	near
	class	GrObjClass
	uses	ax,bx,cx,di
	.enter
	
EC <	call	ECGrObjCheckLMemObject			>

	call	GrObjCanDrawHandles?
	jnc	done

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_tempState, mask GOTM_HANDLES_DRAWN
	jnz	done

	mov	cl, mask GOTM_HANDLES_DRAWN 
	clr	ch
	call	GrObjChangeTempStateBits

	mov	di,dx					;passed gstate or 0
	call	GrObjGetBodyGStateStart
	mov	dx,di					;gstate
	mov	ax,MSG_GO_INVERT_HANDLES
	call	ObjCallInstanceNoLock
	call	GrObjGetGStateEnd

done:
	.leave
	ret

DrawHandlesForce endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawHandlesOpposite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws or undraws the handles of the object to reflect
		the opposite of the selected bit
 
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		dx - gstate

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	if selected bit set
		call undraw handles
	if selected bit not set
		call force draw handles

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawHandlesOpposite method dynamic GrObjClass, 
						MSG_GO_DRAW_HANDLES_OPPOSITE
	uses	cx,dx
	.enter

	;    Having the handles drawn opposite is a temporary state,
	;    mark it as such, so that we can find this object again.
	;

	mov	cl, mask GOTM_TEMP_HANDLES
	clr	ch
	call	GrObjChangeTempStateBits

	test	ds:[di].GOI_tempState,mask GOTM_SELECTED
	jnz	undraw

	call	DrawHandlesForce
done:
	.leave
	ret

undraw:
	call	GrObjUnDrawHandlesLow
	jmp	short done

GrObjDrawHandlesOpposite endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawHandlesMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws or undraws the handles of the object to reflect
		the state of the selected bit
 
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		dx - gstate or 0

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	if selected bit set
		call force draw handles
	if selected bit not set
		call undraw handles

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawHandlesMatch method dynamic GrObjClass, MSG_GO_DRAW_HANDLES_MATCH
	uses	cx,dx
	.enter

	;    Handles are being reset to their normal state, so clear
	;    the temp bit
	;

	clr	cl
	mov	ch, mask GOTM_TEMP_HANDLES
	call	GrObjChangeTempStateBits

	test	ds:[di].GOI_tempState, mask GOTM_SELECTED 
	jz	undraw					

	call	DrawHandlesForce
done:
	.leave
	ret

undraw:
	call	GrObjUnDrawHandlesLow
	jmp	short done

GrObjDrawHandlesMatch endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjInvertHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inverts handles of selected object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
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
GrObjInvertHandles	method dynamic GrObjClass, MSG_GO_INVERT_HANDLES
	uses	ax
	.enter

	mov	di,dx					;gstate	
EC <	call	ECCheckGStateHandle			>

	mov	al, MM_INVERT
	call	GrSetMixMode

	mov	al,SDM_100				
	call	GrSetAreaMask				

	;  See if the invisible bit is set
	;

	call	GrObjGetDesiredHandleSize
	tst	bl			;if negative, invisible handles
	js	justDrawMoveHandle

	CallMod	GrObjDrawSelectedHandles

done:
	.leave
	ret

justDrawMoveHandle:

	neg	bl
	mov	cl,HANDLE_MOVE
	call	GrObjDrawOneHandle
	jmp	done
	
GrObjInvertHandles endm


GrObjRequiredExtInteractiveCode	ends


GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjDrawHandlesRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to update the handles during an expose event. Draws
		the handles if the handlesDraw flag is set, otherwise
		does nothing

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		dx - gstate

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	If the handles are drawn, draw them again because they may have been
		damaged.
	If the handles aren't drawn, do nothing, you'll only make it worse.

		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjDrawHandlesRaw method dynamic GrObjClass, MSG_GO_DRAW_HANDLES_RAW
	uses	ax,cx
	.enter

	call	GrObjCanDrawHandles?
	jnc	done

	test	ds:[di].GOI_tempState, mask GOTM_HANDLES_DRAWN
	jz	done					;jmp if not drawn

	mov	ax,MSG_GO_INVERT_HANDLES
	call	ObjCallInstanceNoLock
done:
	.leave

	ret	
GrObjDrawHandlesRaw endm

GrObjDrawCode	ends





