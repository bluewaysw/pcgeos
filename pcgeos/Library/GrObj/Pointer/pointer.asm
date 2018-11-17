COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ptr.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
PointerTryHandleHit		
PointerCheckHandleHit		
PointerDoHandleHit		
PointerSetPointDWFixedInInstanceData
PointerStoreCenter		
PointerStartBasicChoose		
PointerStartAdjustChoose	
PointerStartExtendChoose	
PointerStartExtendAdjustChoose  
PointerPtrBasicChoose		
PointerPtrAdjustChoose		
PointerCurrentMarquee?		
PointerInitResizeMarquee	
PointerInitMoveMarquee		
PointerResizeMarquee		
PointerMoveMarquee		
PointerEndBasiChoose		
PointerEndAdjustChoose		
PointerModifyChildrenInRect	
PointerGetSpriteRect		
PointerStartMoveAllSelectedGrObjs  
PointerGetChildrenUnderPoint	
				
PointerStartMoveCopyCommon	
PointerEndMoveCopyCommon	

METHOD HANDLERS
	Name			Description
	----			-----------
PointerStartSelect		
PointerStartChooseAbs		
PointerPtr			
PointerPtrChooseAbs		
PointerEndSelect		
PointerEndChooseAbs		
PointerStartMoveCopy		
PointerEndMoveCopy		
PointerStartMoveAbs		
PointerPtrMoveAbs		
PointerEndMoveAbs		
PointerActivateCreate		
PointerDrawSpriteRaw		
PointerInvertGrObjSprite	
PointerLargeStartMoveCopy	
PointerLargeEndMoveCopy		
PointerSendAnotherToolActivated

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
	This file contains routines to implement the Pointer Class
		

	$Id: pointer.asm,v 1.1 97/04/04 18:08:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

PointerClass			;Define the class record

GrObjClassStructures	ends






GrObjRequiredExtInteractive2Code segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the PointerInstance data portion

PASS:		
		*ds:si - instance data
		es - segment of PointerClass
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
PointerInitialize method PointerClass, MSG_META_INITIALIZE

	mov	di,	offset PointerClass
	CallSuper	MSG_META_INITIALIZE


	GrObjDeref	di,ds,si
	ornf	ds:[di].PTR_modes, mask PM_HANDLES_RESIZE
	BitSet	ds:[di].GOI_msgOptFlags, GOMOF_INVALIDATE
	ret
PointerInitialize		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerActivateCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts pointer in it's standard mode for selecting objects.


PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass

		cl - ActivateCreateFlags

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		set default mode flags
		stop any text objects from editing
		tell any text object that was editing to become selected
		grab mouse
		set cursor
		get current global modes

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerActivateCreate	method dynamic PointerClass, MSG_GO_ACTIVATE_CREATE
	uses	cx,dx,bp
	.enter 

	BitSet	ds:[di].GOI_optFlags, GOOF_FLOATER
	clr	ds:[di].GOI_actionModes


	call	GrObjCreateNormalTransform


	;    Clear the center so that there is some reasonably
	;    valid anchor point in case the user starts by doing an
	;    extended selection.
	;

	AccessNormalTransformChunk	di,ds,si

	clr	ax
	mov	ds:[di].OT_center.PDF_x.DWF_frac,ax
	mov	ds:[di].OT_center.PDF_x.DWF_int.low,ax
	mov	ds:[di].OT_center.PDF_x.DWF_int.high,ax
	mov	ds:[di].OT_center.PDF_y.DWF_frac,ax
	mov	ds:[di].OT_center.PDF_y.DWF_int.low,ax
	mov	ds:[di].OT_center.PDF_y.DWF_int.high,ax

	;    If ACF_NOTIFY set then send method to all objects on
	;    the selection list notifying them of activation. 
	;

	test	cl, mask ACF_NOTIFY
	jz	done
	mov	ax,MSG_GO_SEND_ANOTHER_TOOL_ACTIVATED
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

PointerActivateCreate		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerSendAnotherToolActivated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GO_ANOTHER_TOOL_ACTIVATED to selected and
		editable grobjects

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerSendAnotherToolActivated	method dynamic PointerClass, 
					MSG_GO_SEND_ANOTHER_TOOL_ACTIVATED
	uses	ax,cx,dx,bp
	.enter

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	bp, mask ATAF_STANDARD_POINTER		
	mov	ax,MSG_GO_ANOTHER_TOOL_ACTIVATED
	clr	di					;MessageFlags
	call	GrObjSendToSelectedGrObjsAndEditAndMouseGrabSuspended

	.leave
	ret
PointerSendAnotherToolActivated		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerClearSansUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent to object when it is about to be destroyed

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass

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
	srs	5/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerClearSansUndo method dynamic PointerClass, MSG_GO_CLEAR_SANS_UNDO
	.enter

	;    Clear memory used by the priority list just to be nice
	;

	mov	ax,MSG_GB_PRIORITY_LIST_RESET
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToBody

	;    Send clear method off to super class

	mov	ax,MSG_GO_CLEAR_SANS_UNDO
	mov	di,offset PointerClass
	call	ObjCallSuperNoLock

	.leave
	ret
PointerClearSansUndo		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerGetSituationalPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return pointer image for the situation

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass

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
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerGetSituationalPointerImage	method dynamic PointerClass,
			 MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	.enter

CheckHack < GOPIS_NORMAL eq 0 >
CheckHack < GOPIS_EDIT eq 1 >
CheckHack < GOPIS_CREATE eq 2 >

	cmp	cl,GOPIS_CREATE
	jg	other

	mov	ax,mask  MRF_CLEAR_POINTER_IMAGE

done:
	.leave
	ret

other:
	mov	di,offset PointerClass
	call	ObjCallSuperNoLock
	jmp	done

PointerGetSituationalPointerImage		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerDrawSpriteRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update visual image of sprite in case of expose event

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass
		dx - gstate

RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	if in choose mode then
		call super class - to draw pointers sprite raw
	if in resize,rotate or move mode
		if action object exists then
			if action object is not pointer object
				send method to it
			else
				call super class - to draw pointers sprite raw
		else
			send to all on selection list

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerDrawSpriteRaw	method dynamic PointerClass, MSG_GO_DRAW_SPRITE_RAW
	
	.enter
	test	ds:[di].GOI_actionModes, mask GOAM_CHOOSE
	jnz	sendToSuper

	test	ds:[di].GOI_actionModes, 	mask GOAM_RESIZE or \
					mask GOAM_MOVE or \
					mask GOAM_ROTATE
	jz	done

	test	ds:[di].PTR_modes, mask PM_POINTER_IS_ACTION_OBJECT
	jnz	sendToSuper
	call	PointerSendToActionGrObj
	jnc	sendToList

done:
	.leave
	ret

sendToList:
	clr	di					;MessageFlags
	call	GrObjSendToSelectedGrObjs
	jmp	short done

sendToSuper:
	mov	di,offset PointerClass
	call	ObjCallSuperNoLock
	jmp	short done

PointerDrawSpriteRaw		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerDrawSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't draw the sprite if the marquee is too small

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass
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
	srs	5/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerDrawSprite	method dynamic PointerClass, MSG_GO_DRAW_SPRITE
	
	.enter

	call	PointerCurrentMarquee?
	jnc	done

	mov	di,offset PointerClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret


PointerDrawSprite		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pointer has nothing to invalidate. Eat the message. Yum Yum.


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass

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
	srs	11/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerInvalidate	method dynamic PointerClass, MSG_GO_INVALIDATE
	.enter

	.leave
	ret
PointerInvalidate		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start select
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass
		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE
			cx:dx - optr of pointer image
		else
			cx,dx - DESTROYED

	
DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerStartSelect	method dynamic PointerClass, MSG_GO_LARGE_START_SELECT
	.enter

	;    Check for and handle user clicking on the handle of
	;    a selected object

	mov	al,ds:[di].PTR_modes
	call	PointerTryHandleHit
	jc	processed

	;    Didn't hit a handle so, try to select something
	;

	mov	ax,MSG_GO_START_CHOOSE_ABS
	call	ObjCallInstanceNoLock

image:
	mov	di,ax					;MouseReturnFlags
	mov	ax,MSG_GO_GET_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	ornf	ax,di					;MouseReturnFlags

	.leave
	ret

processed:
	mov	ax,mask MRF_PROCESSED
	jmp	image

PointerStartSelect		endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerTryHandleHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if handle of a selected object was hit
		and activates the proper mode on this object if so

CALLED BY:	INTERNAL
		PointerStartSelect

PASS:		
		*(ds:si) - instance data of pointer
		ss:bp - GrObjMouseData
		al - PointerModes - how to treat corner handle hits

RETURN:		
		stc - handled
		clc - not handled		

DESTROYED:	
		nothing
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerTryHandleHit		proc	far
	.enter

	call	PointerSetOrigMousePt
	call	PointerCheckHandleHit
	jnc	done				;jmp if not handled
	call	PointerDoHandleHit
	stc					;flag hit
done:
	.leave
	ret

PointerTryHandleHit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerCheckHandleHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the handles of a selected object were hit

CALLED BY:	INTERNAL
		PointerTryHandleHit

PASS:		
		*(ds:si) - instance data of object
		ss:bp - GrObjMouseData
		GOOMD_origMousePt
		al - PointerModes - how to treat corner handle hits


RETURN:		
		stc - object hit
			GOOMD_actionGrObj - OD of hit object
			cl - GrObjHandleSpecification of handle hit
			ch - DESTROYED
		clc - no object hit
			GOOMD_actionGrObj - 0
			cx - DESTROYED

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerCheckHandleHit		proc	near
	uses	ax,bx,dx,di
	class	PointerClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	;    Choose appropriate message depending on whether we are
	;    a resize or rotate pointer.
	;

	mov	cl,al					;PointerModes
	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_RESIZE
	test	cl, mask PM_HANDLES_ROTATE
	jz	getChildren
	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_ROTATE
getChildren:
	call	GrObjGlobalGetChildrenWithHandleHit

	;    If no child under with handle hit then jump 
	;

	mov	ax,MSG_GB_PRIORITY_LIST_GET_NUM_ELEMENTS
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	jcxz	noGrObj

	;    Get OD of child whose handle was hit
	;

	clr	cx				;first child
	mov	ax,MSG_GB_PRIORITY_LIST_GET_ELEMENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

store:
	;    Store handle of hit object, if any, and set carry
	;    flag accordingly for returned info
	;

	call	PointerGetObjManipVarData
	movdw	ds:[bx].GOOMD_actionGrObj,cxdx
	jcxz	noHit					;handle of hit object
	mov	cl,ah					;other data is
							;GrObjHandleSpec
	stc						;flag hit

done:
	.leave
	ret
noHit:
	clc	
	jmp	short done

noGrObj:
	;    No objects were hit, so clear dx (cx is alread zero), and
	;    then jump to store cx,dx as action od
	;    

	mov	dx,cx
	jmp	store

PointerCheckHandleHit		endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerStartChooseAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles method start choose, a start select in choose
		mode that didn't hit any handles

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass
		ss:bp - GrObjMouseData

RETURN:		
		ax- MouseReturnFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		nothing	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerStartChooseAbs	method dynamic PointerClass, MSG_GO_START_CHOOSE_ABS
	uses	dx
	.enter

	call	PointerSetOrigMousePt
	call	GrObjCreateSpriteTransform

	mov	dx,ss:[bp].GOMD_goFA

	;    if neither extend or adjust is set the do basic choose
	;    otherwise jump to modified selection

	test	dx, (mask GOFA_EXTEND or mask GOFA_ADJUST)
	jnz	checkExtendAdjust
	call	PointerStartBasicChoose			

done:
	mov	ax,mask MRF_PROCESSED

	.leave
	ret

	;    check for extended selection, adjusted selection or both
	;

checkExtendAdjust:
	test	dx, mask GOFA_ADJUST
	jz	doExtend
	test	dx, mask GOFA_EXTEND
	jz	doAdjust			
	call	PointerStartExtendAdjustChoose
	jmp	short done

doExtend:
	call	PointerStartExtendChoose
	jmp	short done

doAdjust:
	call	PointerStartAdjustChoose
	jmp	short	done

PointerStartChooseAbs		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerStartBasicChoose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up pointer object for basic selection
			select object under point
			or select objects in marquee

CALLED BY:	INTERNAL
		PointerStartChooseAbs

PASS:		
		*(ds:si) - instance data of object
		ss:bp - GrObjMouseData

RETURN:		
		GOOMD_actionGrObj - set to object selected under point (if any)

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerStartBasicChoose		proc	near
	class	PointerClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	call	ObjMarkDirty

	;    Center is used as anchored corner of marquee
	;

	call	PointerStoreCenter

	GrObjDeref	di,ds,si
	ornf	ds:[di].GOI_actionModes, mask GOAM_CHOOSE or \
						mask GOAM_ACTION_HAPPENING
	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_ACTIVATED

	clr	dx				;no gstate
	clr	di
	mov	ax,MSG_GO_UNDRAW_HANDLES
	call	GrObjSendToSelectedGrObjs

	;    Get OD of children under point if any
	;

	call	PointerGetChildrenUnderPoint

	;    If no child under point then jump to initiate marquee
	;

	mov	ax,MSG_GB_PRIORITY_LIST_GET_NUM_ELEMENTS
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	jcxz	initMarquee			

	;    Save OD of first priority child in GOOMD_actionGrObj and 
	;    draw handles of child under point
	;

	push	si				;pointer lmem
	clr	cx				;first child
	mov	ax,MSG_GB_PRIORITY_LIST_GET_ELEMENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	call	PointerGetObjManipVarData
	mov	ds:[bx].GOOMD_actionGrObj.handle,cx
	mov	ds:[bx].GOOMD_actionGrObj.chunk,dx
	mov	bx,cx				;child handle
	mov	si,dx				;child offset
	mov	dx,ss:[bp].GOMD_gstate
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_DRAW_HANDLES_FORCE
	call	ObjMessage
	pop	si				;pointer lmem

initMarquee:

	call	PointerInitResizeMarquee

	.leave
	ret
PointerStartBasicChoose		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerGetChildrenUnderPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill instance data with list of children under the point
		

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - pointer instance data
		ss:bp - PointDWFixed

RETURN:		
		PriorityList changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerGetChildrenUnderPoint		proc	near
	class	PointerClass
	uses	ax,cx,dx
	.enter

EC <	call	ECPointerCheckLMemObject	>

	mov	ax, MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION
	mov	cx, MAX_PRIORITY_LIST_ELEMENTS
	mov	dl, mask PLI_DONT_INSERT_OBJECTS_WITH_SELECTION_LOCK or \
			mask PLI_ONLY_INSERT_HIGH

	call	GrObjGlobalInitAndFillPriorityList

	.leave
	ret
PointerGetChildrenUnderPoint		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerStartAdjustChoose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up pointer object for adjust selection.
		Toggling selection of object under point or objects
		inside marquee

CALLED BY:	INTERNAL
		PointerStartChooseAbs

PASS:		
		*(ds:si) - instance data of object
		ss:bp - GrObjMouseData

RETURN:		
		GOOMD_actionGrObj - set to object selected under point (if any)

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerStartAdjustChoose		proc	near
	class	PointerClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	call	ObjMarkDirty

	call	PointerStoreCenter

	;    Mark choose as happening
	;

	GrObjDeref	di,ds,si
	ornf	ds:[di].GOI_actionModes, mask GOAM_CHOOSE or \
						mask GOAM_ACTION_HAPPENING
	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_ACTIVATED

	;    Get OD of children under point if any
	;

	call	PointerGetChildrenUnderPoint

	;    If no child under point then jump to initiate marquee
	;

	mov	ax,MSG_GB_PRIORITY_LIST_GET_NUM_ELEMENTS
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	jcxz	initMarquee			

	;    Save OD of first priority child in GOOMD_actionGrObj and 
	;    toggle handles of child under point
	;

	push	si				;pointer lmem
	clr	cx				;first child
	mov	ax,MSG_GB_PRIORITY_LIST_GET_ELEMENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>
	call	PointerGetObjManipVarData
	mov	ds:[bx].GOOMD_actionGrObj.handle,cx
	mov	ds:[bx].GOOMD_actionGrObj.chunk,dx
	mov	bx,cx
	mov	si,dx
	mov	dx,ss:[bp].GOMD_gstate
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_DRAW_HANDLES_OPPOSITE
	call	ObjMessage
	pop	si				;pointer lmem


initMarquee:

	call	PointerInitResizeMarquee

	.leave
	ret
PointerStartAdjustChoose		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerStartExtendChoose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up pointer object for extend selection.
		Create marquee between previous click, which is
		currently stored in center and this press.

CALLED BY:	INTERNAL
		PointerStartChooseAbs

PASS:		
		*(ds:si) - instance data of object
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
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerStartExtendChoose		proc	near
	class	PointerClass
	uses	ax,cx,dx,bp,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	call	ObjMarkDirty

	;    Mark choose as happening, since we are clearing the
	;    selection list here, there is no point in marking
	;    the action as pending and waiting for a drag event
	;

	GrObjDeref	di,ds,si
	ornf	ds:[di].GOI_actionModes, mask GOAM_CHOOSE or \
						mask GOAM_ACTION_HAPPENING
	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_ACTIVATED

	;    Initialize the marquee between the current mouse pt and
	;    the center

	call	PointerInitResizeMarquee

	;    Get GState for sprite and handles drawing
	;

	mov	dx,ss:[bp].GOMD_gstate

	;    Draw that marquee
	;

	mov	bp,ss:[bp].GOMD_goFA
	mov	ax,MSG_GO_DRAW_SPRITE
	call	ObjCallInstanceNoLock

	;    Draw handles of all objects that are inside the
	;    current marquee rectangle
	;

	mov	cx,MSG_GO_DRAW_HANDLES_FORCE
	mov	bl,mask GOIRS_IGNORE_TEMP
	call	PointerModifyChildrenInRect

	.leave
	ret
PointerStartExtendChoose		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerStartExtendAdjustChoose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up pointer object for extend selection.
		Create marquee between previous click, which is
		currently stored in center and this press.
		Toggle the selection of objects within it.

CALLED BY:	INTERNAL
		PointerStartChooseAbs

PASS:		
		*(ds:si) - instance data of object
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
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerStartExtendAdjustChoose		proc	near
	class	PointerClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	call	ObjMarkDirty

	;    Mark choose as happening
	;

	GrObjDeref	di,ds,si
	ornf	ds:[di].GOI_actionModes, mask GOAM_CHOOSE or \
						mask GOAM_ACTION_HAPPENING
	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_ACTIVATED

	call	PointerInitResizeMarquee

	;    Get GState for sprite and handles drawing
	;

	mov	dx,ss:[bp].GOMD_gstate

	;    Draw that marquee
	;
	
	mov	ax,MSG_GO_DRAW_SPRITE
	call	ObjCallInstanceNoLock

	;    Toggle handles of all objects inside the marquee	
	;

	mov	cx,MSG_GO_DRAW_HANDLES_OPPOSITE
	mov	bl,mask GOIRS_IGNORE_TEMP
	call	PointerModifyChildrenInRect

	.leave
	ret
PointerStartExtendAdjustChoose		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles ptr events

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass

		ss:bp - GrObjMouseData
RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE
			cx:dx - optr of pointer image
		else
			cx,dx - DESTROYED

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerPtr	method	dynamic PointerClass, MSG_GO_LARGE_PTR,\
					MSG_GO_LARGE_DRAG_SELECT
	
	.enter

	;    On drag event switch action from pending to happening
	;    The prevents an accidental click from wasting a lot of
	;    time moving many selected objects nowhere
	;

	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_PENDING
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING


	;    Send choose message if either pending or happening,
	;    but others wait for happening. This prevents moving
	;    object no distance.
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING or \
					mask GOAM_ACTION_PENDING
	jz	notHandled

	test	ds:[di].GOI_actionModes, mask GOAM_CHOOSE
	jz	tryMove
	mov	ax,MSG_GO_PTR_CHOOSE_ABS
	call	ObjCallInstanceNoLock
	jmp	image

	;    If pointer is actionGrObj then pointer is drawing
	;    sprite for group move
	;

tryMove:
	test	ds:[di].GOI_actionModes, mask GOAM_MOVE
	jz	tryResize
	test	ds:[di].PTR_modes, mask PM_POINTER_IS_ACTION_OBJECT
	jnz	sendMoveToPointer
	mov	ax,MSG_GO_PTR_MOVE
	call	PointerSendMouseDelta
	jmp	processed

tryResize:
	test	ds:[di].GOI_actionModes, mask GOAM_RESIZE
	jz	tryRotate
	mov	ax,MSG_GO_PTR_RESIZE
	call	PointerSendResizeDelta

processed:
	mov	ax,mask MRF_PROCESSED

image:
	mov	di,ax					;MouseReturnFlags
	mov	ax,MSG_GO_GET_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	ornf	ax,di					;MouseReturnFlags

	.leave
	ret

notHandled:
	clr	ax
	jmp	image

sendMoveToPointer:
	;    Send absolute ptr move message to pointer.
	;

	mov	ax,MSG_GO_PTR_MOVE_ABS
	call	ObjCallInstanceNoLock
	jmp	short image


tryRotate:
	test	ds:[di].GOI_actionModes, mask GOAM_ROTATE
	jz	notHandled
	mov	ax,MSG_GO_PTR_ROTATE
	call	PointerSendRotateDelta
	jmp	processed

PointerPtr		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerPtrChooseAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles pointer events when in choose mode

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass
		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		PtrBasicChoose also works for extended choose
		PtrAdjustChoose also works for extended adjusted choose

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerPtrChooseAbs	method dynamic PointerClass, MSG_GO_PTR_CHOOSE_ABS
	.enter
	
	mov	dx,ss:[bp].GOMD_goFA

	;    If neither extend or adjust specified then do basic choose
	;

	test	dx, (mask GOFA_ADJUST)
	jnz	doAdjust
	call	PointerPtrBasicChoose			

done:
	mov	ax,mask MRF_PROCESSED

	.leave
	ret

doAdjust:
	call	PointerPtrAdjustChoose
	jmp	short done
	

PointerPtrChooseAbs		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerPtrBasicChoose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle ptr event when just doing basic choose or adjust choose

CALLED BY:	INTERNAL
		PointerPtrChooseAbs
		PointerEndBasicChoose

PASS:		
		*(ds:si) - instance data of object
		ss:bp - PointDWFixed location of mouse event		
		dh - UIFunctionsActive
		dl - ButtonInfo

RETURN:		
		GOI_actionModes
		most of OI instance data if actionHappening

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	if actionHappening
		adjust marquee		
		return processed

	if actionPending
		if moved more than min marquee distance then
			initialize marquee
		else 
			do nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerPtrBasicChoose		proc	near
	class	PointerClass
	uses	ax,cx,dx,bp,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	;    If no action happening the bail
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	done

	call	PointerResizeMarquee

	call	PointerCurrentMarquee?
	jnc	noCurrentMarquee

	;    Clear the handles of objects that were modified last time
	;    but aren't in rect this time. Do nothing to objects that were
	;    modified last time and are still in rect. Force drawing
	;    of handles of objects that weren't modified last time
	;    but are in the rect this time
	;

	mov	dx,ss:[bp].GOMD_gstate			;for forces handles
	mov	bp,dx					;for undraw handles
	mov	ax,MSG_GO_UNDRAW_HANDLES
	mov	cx,MSG_GO_DRAW_HANDLES_FORCE
	mov	bl, mask GOIRS_XOR_CHECK
	call	PointerModifyChildrenInRect

done:
	.leave
	ret



noCurrentMarquee:

	;    There is not a current marquee, so the action object
	;    is drawn as selected
	;

	mov	dx,ss:[bp].GOMD_gstate			;for force handles
	mov	ax,MSG_GO_DRAW_HANDLES_FORCE
	call	PointerSendToActionGrObj
	jmp	short done

PointerPtrBasicChoose		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerPtrAdjustChoose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle ptr event when just doing basic choose or adjust choose

CALLED BY:	INTERNAL
		PointerPtrChooseAbs
		PointerEndAdjustChoose

PASS:		
		*(ds:si) - instance data of object
		ss:bp - GrObjMouseData
RETURN:		
		GOI_actionModes
		most of OI instance data if actionHappening

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerPtrAdjustChoose		proc	near
	class	PointerClass
	uses	ax,cx,dx,bp,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	;    If no action happening, then ignore event
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	done

	call	PointerResizeMarquee

	call	PointerCurrentMarquee?
	jnc	noCurrentMarquee


	;    Reset the handles of objects that were modified last time
	;    but aren't in rect this. Do nothing to objects that were
	;    modified last time and are still in rect. Toggle
	;    handles of objects that weren't modified last time
	;    but are in the rect this time
	;

	mov	dx,ss:[bp].GOMD_gstate			;for handles opposite
	mov	bp,dx					;for handles match
	mov	ax,MSG_GO_DRAW_HANDLES_MATCH
	mov	cx,MSG_GO_DRAW_HANDLES_OPPOSITE
	mov	bl, mask GOIRS_XOR_CHECK
	call	PointerModifyChildrenInRect

done:
	.leave
	ret



noCurrentMarquee:

	;    There is not a current marquee, so the action object's
	;    handles are drawn opposite 
	;

	mov	dx,ss:[bp].GOMD_gstate			;for handles opposite
	mov	ax,MSG_GO_DRAW_HANDLES_OPPOSITE
	call	PointerSendToActionGrObj
	jmp	short done

PointerPtrAdjustChoose		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerCurrentMarquee?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if sprite rect has grown large enough
		to do the marquee thing

CALLED BY:	INTERNAL
		PointerPtrBasicChoose
		PointerPtrAdjustChoose

PASS:		
		*(ds:si) - instance data of pointer

RETURN:		
		stc - use marquee
		clc - don't use marquee
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
PointerCurrentMarquee?		proc	near
	class	PointerClass
	uses	ax,bx,bp,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	AccessSpriteTransformChunk	di,ds,si

	;    Get positive width in bx:ax
	;	

	mov	ax,ds:[di].OT_width.low
	mov	bx,ds:[di].OT_width.high
	tst	bx
	js	negWidth

checkWidth:
	;    If high word of width is non-zero or low word
	;    is greater than or equal min dimension, then
	;    jump to use marquee
	;

	tst	bx
	jnz	useMarquee
	cmp	ax,MIN_MARQUEE_DIMENSION
	jae	useMarquee

	;    Get positive height in bx:ax
	;	

	mov	ax,ds:[di].OT_height.low
	mov	bx,ds:[di].OT_height.high
	tst	bx
	js	negHeight

checkHeight:
	;    If high word of height is non-zero or low word
	;    is greater than or equal min dimension, then
	;    jump to use marquee
	;

	tst	bx
	jnz	useMarquee
	cmp	ax,MIN_MARQUEE_DIMENSION
	jae	useMarquee

	clc					
done:
	.leave
	ret

negWidth:
	NegWWFixed	bx,ax
	jmp	short checkWidth

negHeight:
	NegWWFixed	bx,ax
	jmp	short checkHeight

useMarquee:
	stc
	jmp	short done

PointerCurrentMarquee?		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerInitResizeMarquee
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize instance of pointer object to draw marquee

CALLED BY:	INTERNAL
		PointerStartBasicChoose
		PointerStartAdjustChoose
		PointerStartExtendChoose
		PointerStartExtendAdjustChoose

PASS:		
		*(ds:si) - instance data of object
		GOOMD_origMousePt

RETURN:		
		instance data set 

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The pointer sprite is a rectangle defined by
		its upper left and a width and height. The upper left
		is stored in OT_center and the width and height are
		stored in OT_width and OT_height. The width and height
		fields are treated as sdwords instead of WWFixed so that
		objects over a large area can be selected

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerInitResizeMarquee		proc	near
	class	PointerClass
	uses	ax,bp,cx,dx,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	call	ObjMarkDirty

	GrObjDeref	di,ds,si

	;    Access normal transform
	;

	mov	bx,ds:[di].GOI_normalTransform
	mov	bx,ds:[bx]			

	;    Clean out the transform
	;

	add	bx,offset OT_transform
	xchg	si,bx				;GrObjTransMatrix, object chunk
	call	GrObjGlobalInitGrObjTransMatrix
	xchg	bx,si				;GrObjTransMatrix, object chunk
	sub	bx,offset OT_transform

	;    Set standard dimension to current mouse pt - center
	;    treating standard dimensions as dwords
	;

	mov	di,bx				;instance data
	call	PointerGetObjManipVarData
	mov	ax,ds:[bx].GOOMD_origMousePt.PDF_x.DWF_int.low
	mov	cx,ds:[bx].GOOMD_origMousePt.PDF_x.DWF_int.high
	sub	ax,ds:[di].OT_center.PDF_x.DWF_int.low
	sbb	cx,ds:[di].OT_center.PDF_x.DWF_int.high
	mov	ds:[di].OT_width.low,ax
	mov	ds:[di].OT_width.high,cx

	mov	ax,ds:[bx].GOOMD_origMousePt.PDF_y.DWF_int.low
	mov	cx,ds:[bx].GOOMD_origMousePt.PDF_y.DWF_int.high
	sub	ax,ds:[di].OT_center.PDF_y.DWF_int.low
	sbb	cx,ds:[di].OT_center.PDF_y.DWF_int.high
	mov	ds:[di].OT_height.low,ax
	mov	ds:[di].OT_height.high,cx

	;    Copy normalTransform to spriteTransform
	;
	
	call	GrObjCopyNormalToSprite


	.leave
	ret
PointerInitResizeMarquee		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerInvertGrObjSprite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert objects sprite

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass

		dx - gstate or 0
			

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		The pointer sprite is a rectangle defined by
		its upper left and a width and height. The upper left
		is stored in OT_center and the width and height are
		stored in OT_width and OT_height. The width and height
		fields are treated as sdwords instead of WWFixed so that
		objects over a large area can be selected

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerInvertGrObjSprite	method dynamic PointerClass, \
						MSG_GO_INVERT_GROBJ_SPRITE
	uses	ax,cx,dx,bp
	.enter

	;    Set attributes for drawing sprite
	;
		
	xchg	di,dx					;di <- gstate
							;dx <- instance data
	call	GrObjGetParentGStateStart
	call	GrObjApplySpriteTransform

	GrObjApplySimpleSpriteAttrs

	;    Treat value in width and height as
	;    32 bits of int. If high word of either is set
	;    we must call special routine for drawing rects
	;    larger than 16 bits
	;
	push	di					;gstate
	mov	di,dx					;instance data offset

	;    Access sprite transform chunk
	;

	mov	di,ds:[di].GOI_spriteTransform
	mov	di,ds:[di]

	mov	dx,ds:[di].OT_width.high
	mov	cx,ds:[di].OT_width.low
	mov	bx,ds:[di].OT_height.high
	mov	ax,ds:[di].OT_height.low

	;    If the dimensions are less than the min negative
	;    coords or greater than the max positive coords, then
	;    jump to draw a large rect
	;

	jlDW	dx,cx,-1,MIN_COORD,largeRect
	jgDW	dx,cx,0,MAX_COORD,largeRect
	jlDW	bx,ax,-1,MIN_COORD,largeRect
	jgDW	bx,ax,0,MAX_COORD,largeRect


	;    Draw normal size rectangle. 
	;    We know that the high words of both the width and height 
	;    hold no information of value. Even the sign
	;    is correct in the low words.

	mov_tr	dx,ax					;height
	clr	ax,  bx					;

	pop	di					;gstate
	call	GrDrawRect

endGState:
	call	GrObjGetGStateEnd

	.leave
	ret

largeRect:

	pop	di					;gstate
	sub	sp, size RectDWord
	mov	bp,sp
	mov	ss:[bp].RD_right.low,cx
	mov	ss:[bp].RD_right.high,dx
	mov	ss:[bp].RD_bottom.low,ax
	mov	ss:[bp].RD_bottom.high,bx
	clr	ax
	mov	ss:[bp].RD_left.low,ax
	mov	ss:[bp].RD_left.high,ax
	mov	ss:[bp].RD_top.low,ax
	mov	ss:[bp].RD_top.high,ax
	segmov	ds,ss,bx				;rect segment
	mov	bx,bp					;rect offset
	call	GrObjDraw32BitRect
	add	sp, size RectDWord
	jmp	short endGState

PointerInvertGrObjSprite		endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerResizeMarquee
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize the marquee

CALLED BY:	INTERNAL
		PointerPtrBasicChoose
PASS:		
		*(ds:si) - instance data of object
		ss:bp - GrObjMouseDelta
		

RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The pointer sprite is a rectangle defined by
		its upper left and a width and height. The upper left
		is stored in OT_center and the width and height are
		stored in OT_width and OT_height. The width and height
		fields are treated as sdwords instead of WWFixed so that
		objects over a large area can be selected

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerResizeMarquee		proc	near
	uses	ax,bx,dx,di,si,bp
	class PointerClass
	.enter

EC <	call	ECPointerCheckLMemObject				>

	;    Erase old sprite
	;

	mov	dx,ss:[bp].GOMD_gstate
	mov	ax,MSG_GO_UNDRAW_SPRITE
	call	ObjCallInstanceNoLock

	push	si					;pointer chunk
	CreateMouseDeltaStackFrame

	;    Add mouse delta to standard dimensions in normalTransform
	;    and store the result in the spriteTransform. Treat
	;    standard dimensions as dwords
	;

	GrObjDeref	di,ds,si
	mov	si,ds:[di].GOI_spriteTransform
	mov	si,ds:[si]
	mov	di,ds:[di].GOI_normalTransform
	mov	di,ds:[di]

	mov	ax,ds:[di].OT_width.low
	mov	bx,ds:[di].OT_width.high
	add	ax,ss:[bp].GOMD_point.PDF_x.DWF_int.low
	adc	bx,ss:[bp].GOMD_point.PDF_x.DWF_int.high
	mov	ds:[si].OT_width.low,ax
	mov	ds:[si].OT_width.high,bx

	mov	ax,ds:[di].OT_height.low
	mov	bx,ds:[di].OT_height.high
	add	ax,ss:[bp].GOMD_point.PDF_y.DWF_int.low
	adc	bx,ss:[bp].GOMD_point.PDF_y.DWF_int.high
	mov	ds:[si].OT_height.low,ax
	mov	ds:[si].OT_height.high,bx

	CleanMouseDeltaStackFrame
	pop	si					;pointer chunk

	;    Draw new sprite
	;

	mov	dx,ss:[bp].GOMD_gstate
	mov	bp,ss:[bp].GOMD_goFA
	mov	ax,MSG_GO_DRAW_SPRITE
	call	ObjCallInstanceNoLock

	.leave
	ret
PointerResizeMarquee		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle end select


PASS:		
		*(ds:si) - Pointer instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass
		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE
			cx:dx - optr of pointer image
		else
			cx,dx - DESTROYED


DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerEndSelect	method dynamic PointerClass, MSG_GO_LARGE_END_SELECT
	.enter

	;    If action not pending or happening just finish up
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_PENDING or \
					mask GOAM_ACTION_HAPPENING
	jz	notHandled

	;    Send appropriate method based on current mode
	;

	test	ds:[di].GOI_actionModes, mask GOAM_CHOOSE
	jz	tryHappening
	mov	ax,MSG_GO_END_CHOOSE_ABS
	call	ObjCallInstanceNoLock
	jmp	short finishUp

tryHappening:
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	notHandled

	;    If pointer is actionGrObj then pointer is drawing
	;    sprite for group move
	;

	test	ds:[di].GOI_actionModes, mask GOAM_MOVE
	jz	tryResize
	test	ds:[di].PTR_modes, mask PM_POINTER_IS_ACTION_OBJECT
	jnz	sendMoveToPointer

	;   The suspend gives as undo chain for undoing the move of 
	;   potentially many objects and it fixes a bug when moving a 
	;   large number of flow regions in geowrite.
	;

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_META_SUSPEND
	call	GrObjMessageToBody
	mov	ax,MSG_GO_END_MOVE
	call	PointerSendMouseDelta
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_META_UNSUSPEND
	call	GrObjMessageToBody

	jmp	processed

tryResize:
	test	ds:[di].GOI_actionModes, mask GOAM_RESIZE
	jz	tryRotate
	mov	ax,MSG_GO_END_RESIZE
	call	PointerSendResizeDelta

processed:
	mov	ax,mask MRF_PROCESSED

finishUp:
	call	PointerEndCleanUp

	mov	di,ax					;MouseReturnFlags
	mov	ax,MSG_GO_GET_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	ornf	ax,di					;MouseReturnFlags

	.leave
	ret

notHandled:
	clr	ax
	jmp	finishUp

sendMoveToPointer:
	;    Send absolute end move message to pointer
	;

	mov	ax,MSG_GO_END_MOVE_ABS
	call	ObjCallInstanceNoLock
	jmp	processed


tryRotate:
	test	ds:[di].GOI_actionModes, mask GOAM_ROTATE
	jz	notHandled
	mov	ax,MSG_GO_END_ROTATE
	call	PointerSendRotateDelta
	jmp	processed

PointerEndSelect		endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerEndChooseAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles pointer events when in choose mode

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass
		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerEndChooseAbs	method dynamic PointerClass, MSG_GO_END_CHOOSE_ABS
	.enter

	mov	dx,ss:[bp].GOMD_goFA

	test	dx, (mask GOFA_ADJUST)
	jnz	doAdjust
	call	PointerEndBasicChoose

destroySpriteDone:
	call	GrObjDestroySpriteTransform

	mov	ax,mask MRF_PROCESSED
	.leave
	ret

doAdjust:
	call	PointerEndAdjustChoose	
	jmp	destroySpriteDone
PointerEndChooseAbs		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerEndBasicChoose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handles end select when in basic choose mode or extend choose

CALLED BY:	
		INTERNAL
		PointerEndChooseAbs

PASS:		
		*(ds:si) - instance data of object
		ss:bp - GrObjMouseData

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		treat as pointer event
		if actionPending
			select object under point
			deselect all other objects
		if actionHappening
			erase sprite
			select all objects inside marquee
			deselect all other objects

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerEndBasicChoose		proc	near
	class	PointerClass
	uses	ax,bx,cx,dx,bp,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	call	PointerPtrBasicChoose

	;    Suspend the body so that all the objects that are becoming
	;    selected and unselected won't try and update the controllers
	;    independently
	;

	mov	ax, MSG_GB_IGNORE_UNDO_ACTIONS_AND_SUSPEND
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	call	GrObjRemoveGrObjsFromSelectionList

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	noMarquee

	call	PointerCurrentMarquee?
	jc	marqueeSelect			;jmp if current marquee

noMarquee:
	mov	dx, HUM_NOW
	mov	ax,MSG_GO_BECOME_SELECTED
	call	PointerSendToActionGrObj

unsuspend:
	mov	ax, MSG_GB_UNSUSPEND_AND_ACCEPT_UNDO_ACTIONS
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	.leave
	ret

marqueeSelect:

	;    Erase marquee 
	;

	mov	dx,ss:[bp].GOMD_gstate
	call	MSG_GO_UNDRAW_SPRITE, PointerClass

	;    Since we just called PointerPtrBasicChoose we know that
	;    all the objects in the current rectangle have their
	;    temp bit set, so there is no point in doing anything
	;    with it. We are counting on the BECOME_SELECTED message
	;    to draw the objects handles which clears the TEMP bit
	;


	mov	cx,MSG_GO_BECOME_SELECTED
	mov	dx,HUM_NOW
	mov	bl,mask GOIRS_IGNORE_TEMP
	call	PointerModifyChildrenInRect
	jmp	unsuspend

PointerEndBasicChoose		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerEndAdjustChoose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handles end select when in basic choose mode

CALLED BY:	
		INTERNAL
		PointerEndChooseAbs

PASS:		
		*(ds:si) - instance data of object
		ss:bp - GrObjMouseData

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		treat as pointer event
		if actionPending
			toggle object under point
		if actionHappening
			erase sprite
			toggle all objects inside marquee

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerEndAdjustChoose		proc	near
	class	PointerClass
	uses	ax,bx,cx,bp,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	call	PointerPtrAdjustChoose

	;
	; the suspend/unsuspend used to happen just for the marqueeSelect case,
	; but splines send out select notification (with a can't-copy flag, who
	; knows why) of their own *after* the default GrObj handling of
	; MSG_GO_TOGGLE_SELECTION sends out its default selection notification
	; (with a can-copy flag).  The suspend will hold everything up until we
	; have everything straightened out and can generate the correct
	; notification (with a can-copy flag) - brianc 11/4/94
	;
	mov	ax, MSG_META_SUSPEND
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	noMarquee

	call	PointerCurrentMarquee?
	jc	marqueeSelect

noMarquee:
	
	;    Toggle selection of actionGrObj if it exists
	;

	mov	ax,MSG_GO_TOGGLE_SELECTION
	call	PointerSendToActionGrObj
done:

	mov	ax, MSG_META_UNSUSPEND
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	.leave
	ret


marqueeSelect:
	;    Erase marquee 
	;

	mov	dx,ss:[bp].GOMD_gstate
	call	MSG_GO_UNDRAW_SPRITE, PointerClass

	;    Since we just call PointerPtrAdjustChoose we know that
	;    all the objects in the current rectangle have their
	;    temp bit set, so there is no point in doing anything
	;    with it. We are counting on the TOGGLE_SELECTION message
	;    to draw or undraw the objects handles which clears the TEMP bit
	;

	mov	cx,MSG_GO_TOGGLE_SELECTION
	mov	bl, mask GOIRS_IGNORE_TEMP
	call	PointerModifyChildrenInRect

	jmp	done

PointerEndAdjustChoose		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerModifyChildrenInRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Send GRUP_PROCESS_ALL_GROBJS_IN_RECT message with
		passed info and current sprite rect
		

CALLED BY:	INTERNAL
		PointerStartExtendChooose
		PointerStartExtendAdjustChoose
		PointerPtrBasicChoose
		PointerPtrAdjustChoose

PASS:		
		*(ds:si) - instance data of an object
		ax - temp message
		bp - temp message dx
		cx - in rect message
		dx - in rect message dx
		bl - GrObjsInRectSpecial
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
	srs	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerModifyChildrenInRect		proc	near
	class	PointerClass
	uses	ax,cx,dx,bp,di
	.enter

EC <	call	ECPointerCheckLMemObject				>

	mov	di,bp				;tempMessageDX
	sub	sp,size GrObjsInRectData
	mov	bp,sp
	mov	ss:[bp].GOIRD_tempMessage,ax
	mov	ss:[bp].GOIRD_tempMessageDX,di
	mov	ss:[bp].GOIRD_inRectMessage,cx
	mov	ss:[bp].GOIRD_inRectMessageDX,dx
	mov	ss:[bp].GOIRD_special,bl

	;    Temporarily point bp at the rect and fill it with
	;    the current marquee rectangle
	;

	add	bp, offset GOIRD_rect
	call	PointerGetSpriteRect
	sub	bp, offset GOIRD_rect

	;    Send grup method along with struct up to graphic body
	;

	mov	dx, size GrObjsInRectData
	mov	ax,MSG_GB_PROCESS_ALL_GROBJS_IN_RECT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	;    Remove structure from stack
	;

	add	sp,size GrObjsInRectData

	.leave
	ret
PointerModifyChildrenInRect		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerGetSpriteRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return rectangle defined by pointer's sprite instance data. 
		The center is one corner and the standard
		dimensions are the offsets to the other corner. The
		returned rectangle will be ordered correctly.

CALLED BY:	INTERNAL
		PointerEndBasicChoose
		PointerEndAdjustChoose
		PointerCurrentMarquee?
		PointerModifyChildrenInRect

PASS:		
		*(ds:si)- instance data of pointer
		ss:bp - RectDWord struct empty

RETURN:		
		ss:bp - RectDWord struct filled

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerGetSpriteRect		proc	near
	uses	ax,bx,cx,dx,di
	class	PointerClass
	.enter

EC <	call	ECPointerCheckLMemObject				>

	AccessSpriteTransformChunk	di,ds,si

	;    Get rect corner and offset of opposite corner in regs
	;

	mov	ax,ds:[di].OT_center.PDF_x.DWF_int.low
	mov	bx,ds:[di].OT_center.PDF_x.DWF_int.high
	mov	cx,ds:[di].OT_width.low
	mov	dx,ds:[di].OT_width.high

	;    If offset to opposite corner is negative, then need 
	;    to switch ordering of left and right. Store flags
	;    of negative test.
	;

	tst	dx
	pushf

	;    Add center to offset to opposite corner
	;

	add	cx,ds:[di].OT_center.PDF_x.DWF_int.low
	adc	dx,ds:[di].OT_center.PDF_x.DWF_int.high

	;    Recover sign flag specifying whether to switch left right
	;    and jump to switch if necessary    
	;

	popf
	js	switchLeftRight

storeLeftRight:
	mov	ss:[bp].RD_left.low,ax
	mov	ss:[bp].RD_left.high,bx
	mov	ss:[bp].RD_right.low,cx
	mov	ss:[bp].RD_right.high,dx

	;    Get rect corner and offset of opposite corner in regs
	;

	mov	ax,ds:[di].OT_center.PDF_y.DWF_int.low
	mov	bx,ds:[di].OT_center.PDF_y.DWF_int.high
	mov	cx,ds:[di].OT_height.low
	mov	dx,ds:[di].OT_height.high

	;    If offset to opposite corner is negative, jump to 
	;    switch ordering of top and  bottom. Store flag
	;    of negative test
	;

	tst	dx
	pushf

	;    Add center to offset to opposite corner
	;

	add	cx,ds:[di].OT_center.PDF_y.DWF_int.low
	adc	dx,ds:[di].OT_center.PDF_y.DWF_int.high

	popf
	js	switchTopBottom

storeTopBottom:
	mov	ss:[bp].RD_top.low,ax
	mov	ss:[bp].RD_top.high,bx
	mov	ss:[bp].RD_bottom.low,cx
	mov	ss:[bp].RD_bottom.high,dx

	.leave
	ret


switchLeftRight:
	xchg	ax,cx
	xchg	bx,dx
	jmp	short storeLeftRight

switchTopBottom:
	xchg	ax,cx
	xchg	bx,dx
	jmp	short storeTopBottom

PointerGetSpriteRect		endp








GrObjRequiredExtInteractive2Code	ends

GrObjExtInteractiveCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerDoHandleHit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send proper activate method to object whose handle was
		hit

CALLED BY:	INTERNAL
		PointerTryHandleHit

PASS:		
		*(ds:si) - instance data of object
		ss:bp - GrObjMouseData
		GOOMD_actionGrObj 
		GOOMD_origMousePt
		cl - GrObjHandleSpecification of handle hit
		al - PointerModes - how to treat corner handle hits

RETURN:		
		GOOMD_actionGrObj - may have been zeroed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerDoHandleHit		proc	far
	uses	ax,cx,di
	class	GrObjClass
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	ObjMarkDirty

	;    Clear state bits and mark action as happening
	;

	GrObjDeref	di,ds,si
	mov	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING

	;    If center handle it then it was a move
	;

	cmp	cl,HANDLE_MOVE
	jz	moveHandleHit

	;    Check for rotate mode and jump if so
	;

	test	al, mask PM_HANDLES_ROTATE
	jnz	rotate				

	;    Mark resize mode and send START_RESIZE method
	;

	call	PointerSetResizeInfo
	mov	ax,MSG_GO_JUMP_START_RESIZE
	ornf	ds:[di].GOI_actionModes,mask GOAM_RESIZE	

sendStart:
	mov	dx,ss:[bp].GOMD_gstate
	push	bp					;stack frame
	mov	bp,ss:[bp].GOMD_goFA
	call	PointerSendToActionGrObj
	pop	bp					;stack frame

done:
	.leave
	ret

rotate:
	;    Mark rotate mode and send START_ROTATE method

	call	PointerSetRotateInfo
	mov	ax,MSG_GO_JUMP_START_ROTATE
	ornf	ds:[di].GOI_actionModes,mask GOAM_ROTATE
	jmp	short sendStart


moveHandleHit:
	;    Move handle was hit.
	;

	call	PointerStartMoveAllSelectedGrObjs
	jmp	short done

PointerDoHandleHit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerStartMoveAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to have the pointer object move all the selected
		objects with the pointers rectangle sprite

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass
		ss:[bp] - GrObjMouseData


RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerStartMoveAbs method dynamic PointerClass, MSG_GO_START_MOVE_ABS
	uses	ax,cx,dx,bp
	.enter

	call	ObjMarkDirty

	call	GrObjCreateSpriteTransform
	call	PointerSetOrigMousePt
	call	PointerInitMoveMarquee

	;    Make pointer the action object
	;

	GrObjDeref	di,ds,si
	mov	bx,ds:[LMBH_handle]
;	mov	ds:[di].PTR_actionGrObj.handle,bx
;	mov	ds:[di].PTR_actionGrObj.chunk,si
	ornf	ds:[di].PTR_modes, mask PM_POINTER_IS_ACTION_OBJECT
	andnf	ds:[di].GOI_actionModes, not mask GOAM_CHOOSE
	ornf	ds:[di].GOI_actionModes, mask GOAM_MOVE or \
						mask GOAM_ACTION_HAPPENING

	;    Clear handles of all selected objects
	;

	mov	dx,ss:[bp].GOMD_gstate
	mov	ax,MSG_GO_UNDRAW_HANDLES
	clr	di					;MessageFlags
	call	GrObjSendToSelectedGrObjs

	;    Draw the pointer's sprite
	;

	mov	bp,ss:[bp].GOMD_goFA
	call	MSG_GO_DRAW_SPRITE, GrObjClass	

	.leave
	ret

PointerStartMoveAbs endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerStartMoveAllSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Initate move on all selected objects


CALLED BY:	INTERNAL
		PointerStartMoveAbs
		PointerDoHandleHit

PASS:		
		*(ds:si) - instance data of pointer
		ss:bp - GrObjMouseData - point at start of move
		GOOMD_origMousePt - to current mouse position

RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	if each object will draw it's own sprite
		send start move to all selected objects		
	else
		send start move abs to pointer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerStartMoveAllSelectedGrObjs		proc	near
	class	GrObjClass
	uses	ax,di,bp,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	;    Flag move mode and clear action object since all objects
	;    are being moved
	;

	ornf	ds:[di].GOI_actionModes, mask GOAM_MOVE

	call	PointerGetObjManipVarData
	clr	ds:[bx].GOOMD_actionGrObj.handle

	;    GState for all objects to draw with and set
	;    GrObjFunctionsActive
	;

	mov	dx,ss:[bp].GOMD_gstate
	mov	bp,ss:[bp].GOMD_goFA

	mov	ax,MSG_GO_JUMP_START_MOVE
	clr	di					;MessageFlags
	call	GrObjSendToSelectedGrObjsShareData

	.leave
	ret
PointerStartMoveAllSelectedGrObjs		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerInitMoveMarquee
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize instance of pointer object to draw marquee
		surrounding all selected objects

CALLED BY:	INTERNAL
		PointerStartMoveAbs

PASS:		
		*(ds:si) - instance data of object
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
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerInitMoveMarquee		proc	near
	class	PointerClass
	uses	ax,bx,cx,dx,di,bp
	.enter

EC <	call	ECPointerCheckLMemObject				>

	call	ObjMarkDirty

	AccessNormalTransformChunk	di,ds,si

	;    Clean out the transform
	;

	add	di,offset OT_transform
	xchg	si,di				;GrObjTransMatrix, object chunk
	call	GrObjGlobalInitGrObjTransMatrix
	xchg	di,si				;GrObjTransMatrix, object chunk
	sub	di,offset OT_transform

	;    Set center to upper left of selection bounds
	;    Set width and weight to lower right
	;    of selection bounds - upper left, treating standardDimensions
	;    as sdwords
	;	

	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjGetBoundsOfSelectedGrObjs
	mov	ax,ss:[bp].RD_left.low
	mov	bx,ss:[bp].RD_left.high
	mov	ds:[di].OT_center.PDF_x.DWF_int.low,ax
	mov	ds:[di].OT_center.PDF_x.DWF_int.high,bx
	mov	cx,ss:[bp].RD_right.low
	mov	dx,ss:[bp].RD_right.high
	sub	cx,ax					;right - left
	sbb	dx,bx					;right - left
	mov	ds:[di].OT_width.low,cx
	mov	ds:[di].OT_width.high,dx

	mov	ax,ss:[bp].RD_top.low
	mov	bx,ss:[bp].RD_top.high
	mov	ds:[di].OT_center.PDF_y.DWF_int.low,ax
	mov	ds:[di].OT_center.PDF_y.DWF_int.high,bx
	mov	cx,ss:[bp].RD_bottom.low
	mov	dx,ss:[bp].RD_bottom.high
	sub	cx,ax					;bottom - top
	sbb	dx,bx					;bottom - top
	mov	ds:[di].OT_height.low,cx
	mov	ds:[di].OT_height.high,dx
	add	sp, size RectDWord

	;    Copy normalTransform to spriteTransform
	;
	
	call	GrObjCopyNormalToSprite

	.leave
	ret
PointerInitMoveMarquee		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerPtrMoveAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles moving of pointer's sprite on ptr events

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass
		ss:[bp] - GrObjMouseData

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
	srs	8/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerPtrMoveAbs	method dynamic PointerClass, MSG_GO_PTR_MOVE_ABS
	uses	ax,dx,bp
	.enter

	;    Erase old sprite
	;

	mov	dx,ss:[bp].GOMD_gstate
	mov	ax,MSG_GO_UNDRAW_SPRITE
	call	ObjCallInstanceNoLock

	push	si					;pointer chunk
	CreateMouseDeltaStackFrame

	;    Add mouse deltas to center
	;    and store the result in the spriteTransform.
	;

	AccessSpriteTransformChunk	di,ds,si

	mov	ax,ds:[di].OT_center.PDF_x.DWF_int.low
	mov	bx,ds:[di].OT_center.PDF_x.DWF_int.high
	add	ax,ss:[bp].GOMD_point.PDF_x.DWF_int.low
	adc	bx,ss:[bp].GOMD_point.PDF_x.DWF_int.high
	mov	ds:[si].OT_center.PDF_x.DWF_int.low,ax
	mov	ds:[si].OT_center.PDF_x.DWF_int.high,bx

	mov	ax,ds:[di].OT_center.PDF_y.DWF_int.low
	mov	bx,ds:[di].OT_center.PDF_y.DWF_int.high
	add	ax,ss:[bp].GOMD_point.PDF_y.DWF_int.low
	adc	bx,ss:[bp].GOMD_point.PDF_y.DWF_int.high
	mov	ds:[si].OT_center.PDF_y.DWF_int.low,ax
	mov	ds:[si].OT_center.PDF_y.DWF_int.high,bx

	CleanMouseDeltaStackFrame
	pop	si					;pointer chunk

	;    Draw new sprite
	;

	mov	dx,ss:[bp].GOMD_gstate
	mov	bp,ss:[bp].GOMD_goFA
	mov	ax,MSG_GO_DRAW_SPRITE
	call	ObjCallInstanceNoLock

	.leave
	ret
PointerPtrMoveAbs		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointerEndMoveAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles ending of group move using pointer's sprite

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass

		ss:bp - GrObjMouseData

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointerEndMoveAbs method dynamic PointerClass, MSG_GO_END_MOVE_ABS
	uses	ax,bx,cx,bp
	.enter

	;    If object wasn't moved, skip to reseting instance data
	;
	
	test	ds:[di].GOI_actionModes,mask GOAM_ACTION_HAPPENING
	jz	reset

	;    Erase the current sprite
	;

	mov	dx,ss:[bp].GOMD_gstate
	call	MSG_GO_UNDRAW_SPRITE, PointerClass
	call	GrObjDestroySpriteTransform


	;	Move all of the objects
	;

	CreateMouseDeltaStackFrame
	mov	ax,MSG_GO_MOVE
	mov	di,mask MF_STACK
	call	GrObjSendToSelectedGrObjs
	CleanMouseDeltaStackFrame

reset:
	;    Redraw handles of selected objects	
	;

	mov	dx,ss:[bp].GOMD_gstate
	mov	ax,MSG_GO_DRAW_HANDLES
	clr	di					;MessageFlags
	call	GrObjSendToSelectedGrObjs
	.leave
	ret

PointerEndMoveAbs endm

GrObjExtInteractiveCode	ends




if	ERROR_CHECK
GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECPointerCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an PointerClass or one
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
ECPointerCheckLMemObject		proc	far
	uses	es,di
	.enter
	pushf	
	call	ECCheckLMemObject
	mov	di,segment PointerClass
	mov	es,di
	mov	di,offset PointerClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_A_DRAW_OBJECT	
	popf
	.leave
	ret
ECPointerCheckLMemObject		endp

GrObjErrorCode	ends
endif







