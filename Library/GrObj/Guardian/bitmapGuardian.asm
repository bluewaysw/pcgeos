COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		bitmapGuardian.asm

AUTHOR:		Steve Scholl, Jan  9, 1992

ROUTINES:
	Name	
	----	
BitmapGuardianConvertBitmapForEditing
BitmapGuardianGetSpriteAxisFlip

METHODS:
	Name
	----
BitmapInitialize
BitmapGuardianAnotherToolActivated
BitmapGuardianSetBitmapPointerActiveStatus		
BitmapGuardianBeginCreate
BitmapGuardianLostEditGrab
BitmapGuardianInvertEditIndicator
BitmapGuardianGrObjSpecificInitialize		
BitmapGuardianRealEstateHitDetection
BitmapGuardianActivateRealEstateResize
BitmapGuardianJumpStartRealEstateResize
BitmapGuardianDragRealEstateResizeCommon
BitmapGuardianPtrRealEstateResize
BitmapGuardianPtrRealEstateResizeCommon
BitmapGuardianEndRealEstateResize
BitmapGuardianEndRealEstateResizeCommon
BitmapGuardianInitToDefaultAttrs
BitmapGuardianCompleteCreate
BitmapGuardianUpdateVisWardWithStoredData		
BitmapGuardianSetToolClass		
BitmapGuardianUpdateEditGrabWithStoredData		

BitmapGuardianDrawFgArea

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	1/ 9/92		Initial revision


DESCRIPTION:
	
		

	$Id: bitmapGuardian.asm,v 1.1 97/04/04 18:08:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

BitmapGuardianClass		;Define the class record

GrObjClassStructures	ends



GrObjBitmapGuardianCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianDrawFgArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	don't draw the old stuff with the new mixmode, just
		add new stuff with the new mixmode!

CALLED BY:	MSG_GO_DRAW_FG_AREA
PASS:		*ds:si	= BitmapGuardianClass object
		ds:di	= BitmapGuardianClass instance data
		es 	= segment of BitmapGuardianClass
		cl	= DrawwFlags
		dx	= GState
		bp	= GrObjDrawFlags
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	calls super to do the real stuff..

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	7/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianDrawFgArea	method dynamic BitmapGuardianClass, 
					MSG_GO_DRAW_FG_AREA,
					MSG_GO_DRAW_FG_AREA_HI_RES
	push	ax
	mov	al, MM_COPY
	mov	di, dx
	call 	GrSetMixMode	; di <= GState handle
				; al <= new mix mode
	pop	ax
	mov	di, offset BitmapGuardianClass
	call	ObjCallSuperNoLock
	ret
BitmapGuardianDrawFgArea	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the class of the vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

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
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianMetaInitialize	method dynamic BitmapGuardianClass, 
							MSG_META_INITIALIZE
	.enter

	mov	di, offset BitmapGuardianClass
	CallSuper	MSG_META_INITIALIZE

	GrObjDeref	di,ds,si
	mov	ds:[di].GOVGI_class.segment, segment GrObjBitmapClass
	mov	ds:[di].GOVGI_class.offset, offset GrObjBitmapClass

	clr	ax
	mov	ds:[di].BGI_toolClass.segment,ax
	ornf	ds:[di].GOI_msgOptFlags,mask GOMOF_SEND_UI_NOTIFICATION or \
		mask GOMOF_INVALIDATE_LINE or mask GOMOF_INVALIDATE_AREA or \
		mask GOMOF_DRAW_FG_AREA

	;
	;  Make bitmaps multiplicative resize so that untransform
	;  will undo a scale
	;

	BitSet	ds:[di].GOI_attrFlags, GOAF_MULTIPLICATIVE_RESIZE

	.leave
	ret
BitmapGuardianMetaInitialize		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianEatMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Eat these message


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

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
	srs	12/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianEatMessage	method dynamic BitmapGuardianClass, 
						MSG_GO_INVALIDATE_LINE,
						MSG_GO_INVALIDATE_AREA
	.enter

	.leave
	ret
BitmapGuardianEatMessage		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianGrObjSpecificInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the active status of the vis ward tool from the
		VisWardToolActiveStatus in bp.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		bp high  - GrObjVisGuardianFlags
			only GOVGF_CAN_EDIT_EXISTING_OBJECTS and
			GOVGF_CREATE_MODE matter

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimzed for SMALL SIZE over SPEED
	
		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianGrObjSpecificInitialize	method dynamic BitmapGuardianClass, 
					MSG_GO_GROBJ_SPECIFIC_INITIALIZE
	uses	ax,cx
	.enter

	mov	ax,bp
	andnf	ah, mask GOVGF_CAN_EDIT_EXISTING_OBJECTS or \
		    mask GOVGF_CREATE_MODE 
	andnf	ds:[di].GOVGI_flags, not \
			(mask GOVGF_CAN_EDIT_EXISTING_OBJECTS or \
			mask GOVGF_CREATE_MODE )
	ornf	ds:[di].GOVGI_flags,ah

	.leave
	ret
BitmapGuardianGrObjSpecificInitialize		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianGrObjSpecificInitializeWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the active status of the vis ward tool from the
		VisWardToolActiveStatus in the data block in bp, and
		send notification that the bitmap tool has changed.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		^hbp - BitmapGuardianSpecificInitializationData

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		The status of the vis wards tool must be set
		before activate create so that a bitmap currently being
		edit can tell whether it should

			become uneditable - if ward tool inactive
			remain editable - if ward tool active

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimzed for SMALL SIZE over SPEED
	
		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianGrObjSpecificInitializeWithDataBlock	method dynamic BitmapGuardianClass, MSG_GO_GROBJ_SPECIFIC_INITIALIZE_WITH_DATA_BLOCK
	uses	ax,cx,dx
	.enter

	mov	bx, bp
	call	MemLock
	jc	done
	mov	es, ax
	movdw	cxdx, es:[BGSID_toolClass]
	mov	al, es:[BGSID_activeStatus]
	call	MemFree

	GrObjDeref	di,ds,si
	andnf	al, mask GOVGF_CAN_EDIT_EXISTING_OBJECTS or \
		    mask GOVGF_CREATE_MODE 
	andnf	ds:[di].GOVGI_flags, not \
			(mask GOVGF_CAN_EDIT_EXISTING_OBJECTS or \
			mask GOVGF_CREATE_MODE )
	ornf	ds:[di].GOVGI_flags,al

	mov	ax, MSG_BG_SET_TOOL_CLASS
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
BitmapGuardianGrObjSpecificInitializeWithDataBlock		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianSetToolClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store tool class in instance data

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		cx:dx - fptr to class

RETURN:		
		nothign
	
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
	srs	4/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianSetToolClass	method dynamic BitmapGuardianClass, 
						MSG_BG_SET_TOOL_CLASS
	uses	cx
	.enter

	movdw	ds:[di].BGI_toolClass,cxdx
	jcxz	bitmapPointerActive

	mov	cl,BGBPAS_INACTIVE
setActiveStatus:
	mov	ax,MSG_BG_SET_BITMAP_POINTER_ACTIVE_STATUS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GOVG_UPDATE_VIS_WARD_WITH_STORED_DATA
	call	ObjCallInstanceNoLock

	.leave
	ret

bitmapPointerActive:	
	mov	cl,BGBPAS_ACTIVE
	jmp	setActiveStatus

BitmapGuardianSetToolClass		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianGetToolClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get stored tool class in instance data

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

RETURN:		
		cx:dx - fptr to class
	
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
	srs	4/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianGetToolClass	method dynamic BitmapGuardianClass, 
						MSG_BG_GET_TOOL_CLASS
	.enter

	movdw	cxdx,ds:[di].BGI_toolClass

	.leave
	ret
BitmapGuardianGetToolClass		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If start select on real estate handles of editing bitmap
		object then start a real estate resize of it.
		If click on bitmap then put it into edit mode
		Else pass to our super class for bitmap create

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE
			cx:dx - optr of pointer image
		else
			cx,dx - DESTROYED

	
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
	srs	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianStartSelect	method dynamic BitmapGuardianClass, 
						MSG_GO_LARGE_START_SELECT

	.enter

	test	ds:[di].GOI_optFlags,mask GOOF_FLOATER
	jnz	tryBitmapPointerFunc

callSuper:
	mov	di,offset BitmapGuardianClass
	mov	ax,MSG_GO_LARGE_START_SELECT
	call	ObjCallSuperNoLock

done:
	.leave
	ret

processed:
	mov	ax,mask MRF_PROCESSED
	jmp	done

tryBitmapPointerFunc:
	;    If we have a tool class then we are not the bitmap pointer
	;

	tst	ds:[di].BGI_toolClass.segment
	jnz	callSuper


	;    See if crop handle of edit object is hit.
	;

	mov	ax,MSG_BG_REAL_ESTATE_HANDLE_HIT_DETECTION
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToEdit
	jz	checkForBitmapSelect			;jmp if not edit
	cmp	al,EVALUATE_HIGH
	je	handleHit				;jmp if handle hit

checkForBitmapSelect:
	;    See if we can select another bitmap for real estate
	;    resizing

	call	GrObjVisGuardianGetObjectUnderPointToEdit
	jcxz	callSuper

	;    Stomp the action modes so ptr and end select can be
	;    ignored.
	;

	call	ObjMarkDirty
	GrObjDeref	di,ds,si
	clr	ds:[di].GOI_actionModes

	;   Send message to object to put it in edit mode
	;

	push	si				;pointer chunk
	mov	bx,cx				;object to edit handle
	mov	si,dx				;object to edit chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_BECOME_EDITABLE
	call	ObjMessage
	pop	si				;pointer chunk

	;   Tell new edit object to display its crop handles
	;

	mov	ax,MSG_BG_SET_BITMAP_POINTER_ACTIVE_STATUS
	mov	cl,BGBPAS_ACTIVE
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToEdit
	jmp	processed


handleHit:
	;    Start a real estate resize of the edit object
	;

	call	ObjMarkDirty

	;    Store mouse point for calcing deltas later
	;

	call	PointerSetOrigMousePt

	;    Store od of edit object in action
	;

	push	si					;our chunk
	call	GrObjGetEditOD
	mov	cx,si					;edit chunk
	pop	si					;our chunk

	mov	di,bx					;edit handle
	call	PointerGetObjManipVarData
	mov	ds:[bx].GOOMD_actionGrObj.handle,di
	mov	ds:[bx].GOOMD_actionGrObj.chunk,cx

	GrObjDeref	di,ds,si
	mov	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING or \
					mask GOAM_RESIZE
	mov	cl,ah					;OHS grabbed
	call	PointerSetResizeInfo

	mov	ax,MSG_BG_JUMP_START_REAL_ESTATE_RESIZE
	mov	dx,ss:[bp].GOMD_gstate
	push	bp					;stack frame
	mov	bp,ss:[bp].GOMD_goFA
	call	PointerSendToActionGrObj
	pop	bp					;stack frame
	jmp	processed



BitmapGuardianStartSelect		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If in real estate resize mode then send
		PTR_REAL_ESTATE to edit, otherwise send to super class

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		ss:bp - GrObjMouseData

RETURN:		
		ax - mask MRF_PROCESSED
	
DESTROYED:
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE
	
		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianPtr	method dynamic BitmapGuardianClass, MSG_GO_LARGE_PTR,
						MSG_GO_LARGE_DRAG_SELECT
	.enter

	;   Only the floater be doing a real estate resize on the
	;   edit object.
	;

	test	ds:[di].GOI_optFlags,mask GOOF_FLOATER
	jnz	checkForRealEstateResize

callSuper:
	mov	di,offset BitmapGuardianClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret

checkForRealEstateResize:
	test	ds:[di].GOI_actionModes, mask GOAM_RESIZE
	jz	callSuper
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	callSuper

	mov	ax,MSG_BG_PTR_REAL_ESTATE_RESIZE
	call	PointerSendResizeDelta

	mov	ax,mask MRF_PROCESSED
	jmp	done

BitmapGuardianPtr		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If in real estate resize mode then send
		END_SELECT_REAL_ESTATE to edit, otherwise send to super class

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		ss:bp - GrObjMouseData

RETURN:		
		ax - mask MRF_PROCESSED
	
DESTROYED:
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE
	
		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianEndSelect	method dynamic BitmapGuardianClass, 
							MSG_GO_LARGE_END_SELECT
	.enter

	;   Only the floater can be doing a real estate resize on the
	;   edit object.
	;

	test	ds:[di].GOI_optFlags,mask GOOF_FLOATER
	jnz	checkForRealEstateResize

callSuper:
	mov	di,offset BitmapGuardianClass
	call	ObjCallSuperNoLock

	;   If vis ward is controlling create then the create
	;   wasn't automatically ended on end select in the super
	;   class.
	;

	GrObjDeref	di,ds,si
	mov	bl,ds:[di].GOVGI_flags
	andnf	bl,mask GOVGF_CREATE_MODE
	cmp	bl,GOVGCM_VIS_WARD_CREATE
	je	endCreate

done:
	.leave
	ret

endCreate:
	push	ax,cx				;MouseReturnFlags
	clr	cx				;EndCreatePassFlags
	mov	ax,MSG_GO_END_CREATE
	call	ObjCallInstanceNoLock
	pop	ax,cx				;MouseReturnFlags
	jmp	done

checkForRealEstateResize:
	test	ds:[di].GOI_actionModes, mask GOAM_RESIZE
	jz	callSuper
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	callSuper

	mov	ax,MSG_BG_END_REAL_ESTATE_RESIZE
	call	PointerSendResizeDelta

	call	PointerEndCleanUp

	mov	ax,mask MRF_PROCESSED
	jmp	done

BitmapGuardianEndSelect		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianBeginCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark ward as inactive because it cannot be used
		to create the object.
	
		??? Hopefully we can change the vis bitmap to
		handle creating when it doesn't have a bitmap yet.


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianBeginCreate	method dynamic BitmapGuardianClass, 
						MSG_GO_BEGIN_CREATE
	uses	cx
	.enter

	mov	ax,MSG_GO_BEGIN_CREATE
	mov	di,offset BitmapGuardianClass
	call	ObjCallSuperNoLock

	;    If the vis ward is handling the create then
	;    we need to update it with the bitmap tool class
	;

	GrObjDeref	di,ds,si
	mov	cl,ds:[di].GOVGI_flags
	andnf	cl,mask GOVGF_CREATE_MODE
	cmp	cl,GOVGCM_VIS_WARD_CREATE
	jne	done
	mov	ax,MSG_GOVG_UPDATE_VIS_WARD_WITH_STORED_DATA
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
BitmapGuardianBeginCreate		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianUpdateVisWardWithStoredData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create bitmap tool of stored class in vis ward	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

RETURN:		
		nothing
	
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
	srs	4/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianUpdateVisWardWithStoredData method dynamic BitmapGuardianClass, 
				MSG_GOVG_UPDATE_VIS_WARD_WITH_STORED_DATA
	uses	cx,dx
	.enter

	mov	ax,MSG_VIS_BITMAP_CREATE_TOOL
	movdw	cxdx,ds:[di].BGI_toolClass
	jcxz	sendNotification
	clr	di
	call	GrObjVisGuardianMessageToVisWard
	jnz	done

sendNotification:
	;
	;  No ward was present, so we want to generate the update ourselves
	;
	mov	bx, size VisBitmapNotifyCurrentTool
	call	GrObjGlobalAllocNotifyBlock
	jc	done
	call	MemLock
	mov	es, ax
	movdw	es:[VBNCT_toolClass], cxdx
	call	MemUnlock

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_TOOL_CHANGE
	mov	dx, GWNT_BITMAP_CURRENT_TOOL_CHANGE
	call	GrObjGlobalUpdateControllerLow
done:
	.leave
	ret
BitmapGuardianUpdateVisWardWithStoredData		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianUpdateEditGrabWithStoredData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the bitmap tool class in the edit grab

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

RETURN:		
		nothing
	
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
	srs	4/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianUpdateEditGrabWithStoredData method dynamic BitmapGuardianClass, 
				MSG_GOVG_UPDATE_EDIT_GRAB_WITH_STORED_DATA
	.enter

	mov	ax,MSG_BG_SET_TOOL_CLASS
	movdw	cxdx,ds:[di].BGI_toolClass
	clr	di
	call	GrObjMessageToEdit

	.leave
	ret
BitmapGuardianUpdateEditGrabWithStoredData		endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianSetBitmapPointerActiveStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify guardian whether the current floater is a
		BitmapPointer

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		cl - BitmapGuardianBitmapPointerActiveStatus
RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED.
		But special consideration should be given to not dirting
		the object unnecessarily

		Common cases:
			This method will be called more times with
			BGBPAS_INACTIVE since everytime is loses the
			edit grab it will send this message to itself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianSetBitmapPointerActiveStatus	method dynamic \
		BitmapGuardianClass, MSG_BG_SET_BITMAP_POINTER_ACTIVE_STATUS
	uses	ax,dx
	.enter

	mov	bx,di					;instance data offset

	cmp	cl, BGBPAS_ACTIVE
	je	activating

	test	ds:[bx].BGI_flags, mask BGF_POINTER_ACTIVE
	jz	done

	;    We are changing the status from active to inactive
	;    If edit indicator is drawn we need to erase it,
	;    update the pointer status and redraw the indicator
	;    the new way
	;

	test	ds:[bx].GOI_tempState, mask GOTM_EDIT_INDICATOR_DRAWN
	jz	setInactive

	mov	di,BODY_GSTATE
	call	GrObjCreateGState
	mov	dx,di
	mov	ax,MSG_GO_UNDRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock

	andnf	ds:[bx].BGI_flags, not mask BGF_POINTER_ACTIVE

	mov	ax,MSG_GO_DRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock
	mov	di,dx
	call	GrDestroyState

	;
	;  Clip the bitmap to the visual bounds here so that the dude
	;  isn't editing invisible parts of the bitmap
	;
	mov	ax,MSG_VIS_BITMAP_BITMAP_BOUNDS_MATCH_VIS_BOUNDS
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	
setInactive:
	andnf	ds:[bx].BGI_flags, not mask BGF_POINTER_ACTIVE

done:

	.leave
	ret

activating:
	test	ds:[bx].BGI_flags, mask BGF_POINTER_ACTIVE
	jnz	done


	;    We are changing the status from inactive to active
	;    If edit indicator is drawn we need to erase it,
	;    update the pointer status and redraw the indicator
	;    the new way
	;

	test	ds:[bx].GOI_tempState, mask GOTM_EDIT_INDICATOR_DRAWN
	jz	setActive

	mov	di,BODY_GSTATE
	call	GrObjCreateGState
	mov	dx,di
	mov	ax,MSG_GO_UNDRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock

	ornf	ds:[bx].BGI_flags, mask BGF_POINTER_ACTIVE

	mov	ax,MSG_GO_DRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock
	mov	di,dx
	call	GrDestroyState

setActive:
	ornf	ds:[bx].BGI_flags, mask BGF_POINTER_ACTIVE
	jmp	done		


BitmapGuardianSetBitmapPointerActiveStatus		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianAnotherToolActivated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify selected and edited objects that another tool
		has been activated. If the bitmap is not editing
		it should just call its superclass. If, however, it
		is editing and the class of the tool being activated
		is BitmapGuardian or BitmapPointer then it should
		keep the edit. And in the case of BitmapPointer is
		should send notification to itself
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx:dx - od of caller
		bp - AnotherToolActivatedFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none			

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			The activating class will be BitmapGuardian since
			that is the class of all bitmap editing tools
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianAnotherToolActivated	method dynamic BitmapGuardianClass, \
					MSG_GO_ANOTHER_TOOL_ACTIVATED
	uses	ax,cx,dx,bp
	.enter

	test	ds:[di].GOI_actionModes,mask GOAM_CREATE
	jnz	callSuper

	test	bp,mask ATAF_SHAPE or mask ATAF_STANDARD_POINTER
	jnz	callSuper

	;    Since it is not a standard pointer we definitely can't
	;    stay selected.
	;

	mov	ax,MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLock

	;    Get the class of the tool activating
	;

	push	si				;guardian lmem
	mov	bx,cx				;activating handle
	mov	si,dx				;activating lmem
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_META_GET_CLASS
	call	ObjMessage
	mov	di,si				;activating lmem
	pop	si				;guardian lmem

	;    Check for activating tool being BitmapGuardian 
	;

	cmp	dx,offset BitmapGuardianClass
	jne	callSuper
	cmp	cx,segment BitmapGuardianClass
	jne	callSuper

	;    The object activating is a BitmapGuardian if were
	;    are not being edited currently we don't need 
	;    to do anthing special
	;

	push	di				;activating chunk
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_tempState, mask GOTM_EDITED
	pop	di				;activating chunk
	jnz	bitmapPointerCheck


done:
	.leave
	ret

bitmapPointerCheck:
	;    Normally the tool gets set in the bitmap being edited
	;    by the floater when the users clicks. But for fatbits
	;    the user doesn't click in the guardian, so we need to
	;    get the tool and soon as the user switches to it. Also
	;    this will update the BGF_POINTER_ACTIVE bit now.
	;

	push	si					;guardian lmem
	mov	si,di					;activating lmem
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GOVG_UPDATE_EDIT_GRAB_WITH_STORED_DATA
	call	ObjMessage
	pop	si					;guardian lmem
	jmp	done


callSuper:
	mov	di,offset BitmapGuardianClass
	mov	ax,MSG_GO_ANOTHER_TOOL_ACTIVATED
	call	ObjCallSuperNoLock
	jmp	short done


BitmapGuardianAnotherToolActivated		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify bitmap that it is losing the edit grab. The
		bitmap needs to mark the bitmap pointer as inactive

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This message should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianLostTargetExcl	method dynamic BitmapGuardianClass, 
						MSG_META_LOST_TARGET_EXCL
	.enter

	;    Toss any data that exists outside of vis bounds
	;

	mov	ax,MSG_VIS_BITMAP_BITMAP_BOUNDS_MATCH_VIS_BOUNDS
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	mov	ax,MSG_VIS_BITMAP_BECOME_DORMANT
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	mov	ax,MSG_META_LOST_TARGET_EXCL
	mov	di,offset BitmapGuardianClass
	call	ObjCallSuperNoLock

	Destroy 	ax,cx,dx,bp

	.leave
	ret
BitmapGuardianLostTargetExcl		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianInvertEditIndicator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inverts edit indicator of selected object.
		If the bitmap pointer is active then draw handles
		as the edit indicator, for use in changing bitmap
		real estate. Otherwise call superclass to handle
		normally

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
		This method should be optimized for SMALL SIZE over SPEED.

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianInvertEditIndicator	method dynamic BitmapGuardianClass, \
						MSG_GO_INVERT_EDIT_INDICATOR
	uses	ax
	.enter

	test	ds:[di].BGI_flags, mask BGF_POINTER_ACTIVE
	jnz	drawHandles

	mov	di,offset BitmapGuardianClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret

drawHandles:
	mov	di,dx					;gstate	
EC <	call	ECCheckGStateHandle			>

	mov	al, MM_INVERT
	call	GrSetMixMode
	
	mov	al,SDM_50
	call	GrSetAreaMask

	call	GrObjGetDesiredHandleSize

	mov	cl,HANDLE_LEFT_TOP
	call	GrObjDrawOneHandle		

	mov	cl,HANDLE_RIGHT_TOP
	call	GrObjDrawOneHandle

	mov	cl,HANDLE_RIGHT_BOTTOM
	call	GrObjDrawOneHandle

	mov	cl,HANDLE_LEFT_BOTTOM
	call	GrObjDrawOneHandle			

	mov	cl,HANDLE_MIDDLE_TOP
	call	GrObjDrawOneHandle

	mov	cl,HANDLE_MIDDLE_BOTTOM
	call	GrObjDrawOneHandle

	mov	cl,HANDLE_RIGHT_MIDDLE
	call	GrObjDrawOneHandle

	mov	cl,HANDLE_LEFT_MIDDLE
	call	GrObjDrawOneHandle

	jmp	done


BitmapGuardianInvertEditIndicator		endm

if	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert bitmap into untransformed image if necessary
		and then call super class to begin edit

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			Bitmap has simple transform, no rotation and the
			object dimensions exactly match vis bounds.
			Which means no conversion is necessary


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianGainedTargetExcl	method dynamic BitmapGuardianClass, 
						MSG_META_GAINED_TARGET_EXCL
	.enter


	;    If the scale factor from vis to object is not 1 to 1 or
	;    if the object is using a full transform, or 
	;    if there is any rotation, then the bitmap must be
	;    converted before it can be edited
	;

	call	GrObjVisGuardianCalcScaleFactorVISToOBJECT
	jnc	convert


	;    If GrObjTransMatrix is not the identity matrix then
	;    the bitmap needs to be converted.
	;

	AccessNormalTransformChunk		di,ds,si
	add	di,offset OT_transform
	xchg	di,si				;object chunk, transform offset
	call	GrObjCheckGrObjTransMatrixForIdentity
	mov	si,di				;object chunk
	jnc	convert

callSuper:
	mov	ax,MSG_META_GAINED_TARGET_EXCL
	mov	di, segment BitmapGuardianClass
	mov	es, di
	mov	di, offset BitmapGuardianClass
	call	ObjCallSuperNoLock

	.leave
	ret

convert:
	call	BitmapGuardianConvertBitmapForEditing
	jmp	callSuper

BitmapGuardianGainedTargetExcl		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianConvertBitmapForEditing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For editing the bitmap must be using a simple transform
		with no rotation and the vis bounds must match
		the object dimensions.

CALLED BY:	INTERNAL
		BitmapGuardianGainedEditGrab

PASS:		
		*ds:si - BitmapGuardianClass

RETURN:		
		Bitmap has been converted, normalTransform data
		has been updated.

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		WARNING - may cause block to move or object to move within block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianConvertBitmapForEditing		proc	near
	class	BitmapGuardianClass
	uses	ax,cx,dx,bp,di
	.enter

EC <	call	ECBitmapGuardianCheckLMemObject			>

	;    Calc transformation to apply to bitmap
	;

	clr	di					;no window
	call	GrCreateState
	call	GrObjApplyNormalTransformSansCenterTranslation
	mov	dx,di					;gstate
	call	GrObjVisGuardianOptApplyOBJECTToVISTransform

	;    Convert bitmap through gstate and have it
	;    change it vis bounds to match the new size of the bitmap
	;

	mov	bp,dx					;gstate
	mov	ax,MSG_VIS_BITMAP_CONTORT
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	mov	ax,MSG_VIS_BITMAP_VIS_BOUNDS_MATCH_BITMAP_BOUNDS
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	mov	di,bp					;gstate
	call	GrDestroyState

	;    Convert the object's instance data to have the
	;    same center but the new height and width
	;

	call	GrObjVisGuardianGetWardSize
	mov	bx,dx					;height int
	mov	dx,cx					;width int
	clr	ax					;height frac
	mov	cx,ax					;width frac
	call	GrObjSetOBJECTDimensionsAndIdentityMatrix

	.leave
	ret

BitmapGuardianConvertBitmapForEditing		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianRealEstateHitDetection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if point hits any of the objects 
		real estate handles

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

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
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			GOTM_EDIT_INDICATOR_DRAWN will be set
			BGF_POINTER_ACTIVE will be set
			The CENTER RELATIVE point will fit in WWF

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianRealEstateHitDetection	method dynamic BitmapGuardianClass, 
					MSG_BG_REAL_ESTATE_HANDLE_HIT_DETECTION
	uses	cx,bp
	.enter

	test	ds:[di].GOI_tempState, mask GOTM_EDIT_INDICATOR_DRAWN
	jz	fail
	test	ds:[di].BGI_flags, mask BGF_POINTER_ACTIVE
	jz	fail

	;    Convert PARENT point to CENTER RELATIVE
	;    If value won't fit in WWFixed then fail
	;

	call	GrObjConvertNormalPARENTToWWFCENTERRELATIVE
	jnc	fail

	RoundWWFixed	dx,cx				;x CENTER RELATIVE
	RoundWWFixed	bx,ax				;y CENTER RELATIVE
	mov	cx,dx					;rounded x
	mov	dx,bx					;rounded y

	call	GrObjDoHitDetectionOnAllHandles
	jc	hit

fail:
	mov	al, EVALUATE_NONE
done:
	clr	dx					;EvaluatePositionNotes

	.leave
	ret

hit:
	;    The routine GrObjDoHitDetectionOnAllHandles checks 
	;    the move handle in the center of the object. However,
	;    there isn't actually a real estate handle in the center
	;    so fail if it is hit. This may cause a problem if the
	;    bitmap is so small the real estate handles overlap the
	;    where the missing center handle would be, but until
	;    some one complains I'm not wasting the code space to
	;    handle it differently.
	;

	cmp	ah,HANDLE_MOVE
	je	fail
	mov	al, EVALUATE_HIGH
	jmp	short done


BitmapGuardianRealEstateHitDetection		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianActivateRealEstateResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up object for resize.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

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
BitmapGuardianActivateRealEstateResize method dynamic BitmapGuardianClass, 
					MSG_BG_ACTIVATE_REAL_ESTATE_RESIZE
	.enter

	call	GrObjCanResize?
	jnc	done

	call	ObjMarkDirty
	ornf	ds:[di].BGI_flags,mask BGF_REAL_ESTATE_RESIZE
	ornf	ds:[di].GOI_actionModes,mask GOAM_RESIZE or \
					mask GOAM_ACTION_ACTIVATED
done:
	.leave
	ret
BitmapGuardianActivateRealEstateResize endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianJumpStartRealEstateResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Jump starts resize by doing an activate,start and drag resize

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		bp - GrObjFunctionsActive
		dx - gstate to draw through or 0


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
	srs	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianJumpStartRealEstateResize	method dynamic BitmapGuardianClass,\
					 MSG_BG_JUMP_START_REAL_ESTATE_RESIZE
	uses	ax
	.enter

	mov	ax,MSG_BG_ACTIVATE_REAL_ESTATE_RESIZE
	call	ObjCallInstanceNoLock
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_ACTIVATED
	jz	notHandled

	;    Pretend we got start select
	;

	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_ACTIVATED
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_PENDING

	;    Pretend we got a drag
	;

	call	BitmapGuardianDragRealEstateResizeCommon

	;  Draw sprite in initial position
	;

	mov	ax,MSG_GO_DRAW_SPRITE
	call	ObjCallInstanceNoLock

	mov	ax,mask MRF_PROCESSED

done:
	.leave
	ret

notHandled:
	clr	ax
	jmp	done

BitmapGuardianJumpStartRealEstateResize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianDragRealEstateResizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform common functionality for drag events when in
		resize mode
		
CALLED BY:	INTERNAL
		BitmapGuardianJumpStartRealEstateResize

PASS:		
		*(ds:si) - instance data
		bp - GrObjFunctionsActive
		dx - gstate to draw through or 0

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		mark block dirty
		clear handles
		set state to action happening
		set sprite draw modes

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE - MAY CAUSE OBJECT BLOCK TO MOVE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianDragRealEstateResizeCommon proc near
	uses	ax,di,dx
	class	BitmapGuardianClass
	.enter

EC <	call	ECBitmapGuardianCheckLMemObject				>

	call	ObjMarkDirty

	call	GrObjCreateSpriteTransform

	;    Clear edit indicator if currently drawn
	;	

	mov	ax,MSG_GO_UNDRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock

	;    Change state to reflect that action is now happening
	;

	GrObjDeref	di,ds,si
	andnf	ds:[di].GOI_actionModes, not mask GOAM_ACTION_PENDING
	ornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING

	.leave
	ret

BitmapGuardianDragRealEstateResizeCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianPtrRealEstateResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when a ptr event is received and the object is in
		real estate resize mode

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		ss:bp = GrObjMoveResizeData
			GORSMD_point - deltas to resize
			GORSMD_anchor - anchored handle
			GORSMD_grabbed - grabbed handle
			GORSMD_gstate - gstate to draw with
			GORSMD_goFA - GrObjFunctionsActive

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
	srs	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianPtrRealEstateResize method dynamic BitmapGuardianClass, 
					MSG_BG_PTR_REAL_ESTATE_RESIZE
	uses	ax,cx,dx,bp
	.enter

	test	ds:[di].GOI_actionModes, mask GOAM_RESIZE
	jz	done
	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_HAPPENING
	jz	done
	test	ds:[di].BGI_flags, mask BGF_REAL_ESTATE_RESIZE
	jz	done

	mov	cl,ss:[bp].GORSMD_anchor
	mov	ch,ss:[bp].GORSMD_grabbed
	mov	dx,ss:[bp].GORSMD_gstate
	call	BitmapGuardianPtrRealEstateResizeCommon

	mov	bp,ss:[bp].GORSMD_goFA
	mov	ax,MSG_GO_DRAW_SPRITE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

BitmapGuardianPtrRealEstateResize endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianPtrRealEstateResizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common functionality performed on MSG_PTR_REAL_ESTATE_RESIZE

CALLED BY:	INTERNAL
		BitmapGuardianPtrRealEstateResize


PASS:		
		*(ds:si) - instance data
		ss:bp - PointDWFixed - point is deltas too resize object
					in document coords
			
		cl - GrObjHandleSpecification of anchored handle
		ch - GrObjHandleSpecification of grabbed handle

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
	srs	3/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianPtrRealEstateResizeCommon		proc	near
	class	BitmapGuardianClass
	uses	ax,bx
	.enter

EC <	call	ECBitmapGuardianCheckLMemObject				>

	;    Erase current sprite
	;

	mov	ax,MSG_GO_UNDRAW_SPRITE
	call	ObjCallInstanceNoLock

	;    For real estate resize to work we need to be
	;    doing an additive resize.
	;

	GrObjDeref	di,ds,si
	push	ds:[di].GOI_attrFlags
	BitClr	ds:[di].GOI_attrFlags,GOAF_MULTIPLICATIVE_RESIZE

	;    Apply resize deltas to object and store the new
	;    information in the sprite transform

	CallMod	GrObjInteractiveResizeSpriteRelative
	
	;     Set the resize type back to its original
	;

	GrObjDeref	di,ds,si
	pop	ds:[di].GOI_attrFlags

	.leave
	ret


BitmapGuardianPtrRealEstateResizeCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianEndRealEstateResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when an end select is received and the object is
		in resize mode

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		ss:bp = GrObjResizeMouseData
			GORSMD_point - deltas to resize
			GORSMD_gstate - gstate to draw with
			GORSMD_goFA - GrObjFunctionsActive
			GORSMD_anchor - anchored handle

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			GOAM_RESIZE set
			GOAM_ACTION_HAPPENING set
			BGF_REAL_ESTATE_RESIZE set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianEndRealEstateResize method dynamic BitmapGuardianClass,
						 MSG_BG_END_REAL_ESTATE_RESIZE
	uses	ax,cx,dx
	.enter

	;    If not in interactive resize then just ignore. If not
	;    happening then didn't get drag select, so reset to
	;    previous state
	;

	test	ds:[di].GOI_actionModes,mask GOAM_RESIZE
	jz	done
	test	ds:[di].BGI_flags, mask BGF_REAL_ESTATE_RESIZE
	jz	done
	test	ds:[di].GOI_actionModes,mask GOAM_ACTION_HAPPENING
	jz	reset

	;    Invalidate object at its original position
	;

	call	GrObjOptInvalidate

	;    Resize sprite data
	;

	mov	cl,ss:[bp].GORSMD_anchor
	mov	ch,ss:[bp].GORSMD_grabbed
	mov	dx,ss:[bp].GORSMD_gstate
	call	BitmapGuardianPtrRealEstateResizeCommon

	call	BitmapGuardianEndRealEstateResizeCommon

	;    Invalidate object at its new position
	;

	call	GrObjOptInvalidate

	call	GrObjDestroySpriteTransform

reset:
	call	ObjMarkDirty

	;   Set state instance back to normal, redraw indicator
	;
	GrObjDeref	di,ds,si
	clr	ds:[di].GOI_actionModes

	andnf	ds:[di].BGI_flags, not mask BGF_REAL_ESTATE_RESIZE

	mov	dx,ss:[bp].GORSMD_gstate
	mov	ax,MSG_GO_DRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

BitmapGuardianEndRealEstateResize endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianEndRealEstateResizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some amazing things with the instance data to
		complete the real estate resize and reflect the
		changes in the vis bitmap

CALLED BY:	INTERNAL
		BitmapGuardianEndRealEstateResize

PASS:		
		*ds:si - BitmapGuardian
			normalTransform is old position,size
			spriteTransform is new position,size

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Important element is movement of upper left of object.
		The bitmap must be moved the same amount but in the
		opposite direction to keep the image in the same place.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianEndRealEstateResizeCommon		proc	near
	uses	ax,bx,cx,dx,di,bp
	.enter

	call	BitmapGuardianGetSpriteAxisFlip
	push	ax					;flipped flags

	;    Get current upper left of object
	;

	sub	sp,size PointDWFixed
	mov	bp,sp
	mov	ax,MSG_GO_GET_POSITION
	call	ObjCallInstanceNoLock

	;    Get new object position and size info into normal data
	;

	call	GrObjCopySpriteToNormal
	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	;    Get new upper left of object.
	;    Subtract new upper left from original
	;    put results in original's stack frame
	;    and clear new's stack frame
	;

	sub	sp, size PointDWFixed
	mov	bx,bp					;original's frame
	mov	bp,sp	
	mov	ax,MSG_GO_GET_POSITION
	call	ObjCallInstanceNoLock
	SubDWF	ss:[bx].PDF_x, ss:[bp].PDF_x
	SubDWF	ss:[bx].PDF_y, ss:[bp].PDF_y
	add	sp,size PointDWFixed

	mov	dx,ss:[bx].PDF_x.DWF_int.low
	mov	cx,ss:[bx].PDF_x.DWF_frac
	mov	ax,ss:[bx].PDF_y.DWF_frac
	mov	bx,ss:[bx].PDF_y.DWF_int.low
	add	sp,size PointDWFixed
	call	GrObjConvertNormalWWFVectorPARENTToOBJECT
	RoundWWFixed	dx,cx				;x change
	RoundWWFixed	bx,ax				;y change
	mov	cx,dx					;x change
	mov	dx,bx					;y change

	;    Mark the bitmap's geometry invalid so that is doesn't do
	;    anything stupid until we are done
	;

	push	cx,dx					;bitmap deltas
	mov	ax,MSG_VIS_MARK_INVALID
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	pop	cx,dx					;bitmap deltas

	;    Move bitmap. word on stack contains flipped information. If an 
	;    axis was flipped, set the delta to zero so that the bitmap
	;    stays left aligned with the flipped edge. If high byte is 
	;    non-zero then y flipped, if low byte is non zero then x did.
	;	

	pop	ax
	tst	al
	jz	10$
	clr	cx
10$:
	tst	ah
	jz	20$
	clr	dx
20$:
	mov	ax,MSG_VIS_BITMAP_MOVE_INSIDE_VIS_BOUNDS
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	;    Finally set the vis bounds and send notify geometry valid
	;

	call	GrObjVisGuardianRoundOBJECTDimensions
	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjCallInstanceNoLock

	.leave
	ret

BitmapGuardianEndRealEstateResizeCommon		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianGetSpriteAxisFlip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if spriteTransform has flipped about
		either axis when compared to the normalTransform and
		force the sprite dimensions to be positive.

CALLED BY:	INTERNAL
		BitmapGuardianEndRealEstateResizeCommon

PASS:		*ds:si - BitmapGuardian

RETURN:		
		al - zero if width not flipped
		     non-zero if width has flipped
		ah - zero if height not flipped
		     non-zero if height has flipped


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
	srs	1/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianGetSpriteAxisFlip		proc	near
	class	BitmapGuardianClass
	uses	di
	.enter

	;   By definition the bitmaps normal width and height
	;   must be positive. So if the sprite width or height
	;   is negative the bitmap was flipped during real estate
	;   resize. We don't really won't to flip over the bitmap,
	;   so force the sprite dimensions positive
	;

EC <	push	ax,bx,cx,dx
EC <	call	GrObjGetNormalOBJECTDimensions	
EC <	tst	dx					
EC <	ERROR_S GROBJ_BITMAP_GUARDIAN_MUST_NOT_HAVE_NEGATIVE_DIMENSIONS
EC <	tst	bx					
EC <	ERROR_S GROBJ_BITMAP_GUARDIAN_MUST_NOT_HAVE_NEGATIVE_DIMENSIONS
EC <	pop	ax,bx,cx,dx

	clr	ax					;assume no flips
	AccessSpriteTransformChunk	di,ds,si
	tst	ds:[di].OT_width.WWF_int
	js	negWidth

checkHeight:
	tst	ds:[di].OT_height.WWF_int
	js	negHeight

done:
	.leave
	ret

negWidth:
	negwwf	ds:[di].OT_width
	inc	al					;non zero
	jmp	checkHeight

negHeight:
	negwwf	ds:[di].OT_height
	inc	ah					;non zero
	jmp	done

BitmapGuardianGetSpriteAxisFlip		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianEndCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish creating the object given whatever data
		is currently available. 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		cx - EndCreatePassFlags

RETURN:		
		cx - EndCreateReturnFlags
	
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
	srs	4/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianEndCreate	method dynamic BitmapGuardianClass, 
						MSG_GO_END_CREATE
	uses	dx
	.enter

	test	ds:[di].GOI_actionModes, mask GOAM_CREATE
	jz	done

	;    If guardian is handling the create then call
	;    super to end a drag open create.
	;

	push	cx
	mov	cl,ds:[di].GOVGI_flags
	andnf	cl,mask GOVGF_CREATE_MODE
	cmp	cl,GOVGCM_VIS_WARD_CREATE
	pop	cx
	je	endVisBitmapCreate

	call	BitmapConvertScaleToDimensions

	;    The superclass will try to make the create undoable, but
	;    undoing create of objects that are intended to be
	;    edited next is messy, because if they undo the undo then
	;    they want to be editing this thing again. Hard to do.
	;    It would also muck of code that nukes undo stuff
	;    when editing object loses the target.
	;

	call	GrObjGlobalUndoIgnoreActions

	mov	di,offset BitmapGuardianClass
	call	ObjCallSuperNoLock

	;    Balance the ignore above 
	;

	call	GrObjGlobalUndoAcceptActions

done:
	.leave
	ret

endVisBitmapCreate:
	call	BitmapGuardianCheckForTinyBitmap
	jc	destroyBitmap

	;
	;  Clear the action modes
	;
	GrObjDeref	di,ds,si
	andnf	ds:[di].GOI_actionModes, not ( mask GOAM_RESIZE or \
						mask GOAM_CREATE or \
						mask GOAM_ACTION_ACTIVATED or \
						mask GOAM_ACTION_PENDING or \
						mask GOAM_ACTION_HAPPENING )
	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_COMPLETE_CREATE
	call	ObjCallInstanceNoLock

	call	GrObjGlobalUndoAcceptActions
	clr	cx				;no EndCreateReturnFlags
	jmp	done


destroyBitmap:
	mov	ax,MSG_GO_CLEAR_SANS_UNDO
	call	ObjCallInstanceNoLock
	call	GrObjGlobalUndoAcceptActions
	mov	cx,mask ECRF_DESTROYED
	jmp	done

BitmapGuardianEndCreate		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianCheckForTinyBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the width and height of the normalTransform
		to be really small. Take into account the view factor
		by using nudge units so that min size is in screen pixels

CALLED BY:	INTERNAL 
		BitmapGuardianEndCreate

PASS:		*ds:si - object
		normalTransform exists

RETURN:		
		stc - it is a tiny sprite
		clc - it is not a tiny sprite

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
	srs	11/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MIN_ACCEPTABLE_BITMAP_DIMENSION equ 8
BitmapGuardianCheckForTinyBitmap		proc	near
	class	GrObjClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>
	AccessNormalTransformChunk	di,ds,si
	call	GrObjGetCurrentNudgeUnitsWWFixed

	pushwwf	dxcx					;x nudge
	movwwf	dxcx,ds:[di].OT_height
	tst	dx
	jns	10$
	negwwf	dxcx
10$:
	call	GrUDivWWFixed
	popwwf	bxax					;y nudge
	cmp	dx,MIN_ACCEPTABLE_BITMAP_DIMENSION
	jge	notTiny

	movwwf	dxcx,ds:[di].OT_width
	tst	dx
	jns	20$
	negwwf	dxcx
20$:
	call	GrUDivWWFixed
	cmp	dx,MIN_ACCEPTABLE_BITMAP_DIMENSION
	jl	tiny

notTiny:
	clc
done:
	.leave
	ret

tiny:
	stc	
	jmp	done

BitmapGuardianCheckForTinyBitmap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapConvertScaleToDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the scale factor into integer width and height
		for the bitmap and set the transform to the identity matrix.
		The bitmap uses multiplicate resize normally, but on create
		we really the need dimensions for the bitmap.
		This routine will cause serious trouble if there
		is non scale data in the tmatrix

CALLED BY:	INTERNAL
		BitmapGuardianEndCreate

PASS:		*ds:si - BitmapGuardian

RETURN:		
		spriteTransform data has been changed.

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
	srs	3/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapConvertScaleToDimensions		proc	near
	class	BitmapGuardianClass
	uses	di,ax,bx,dx
	.enter

EC <	call	ECBitmapGuardianCheckLMemObject	

	;    By setting the transformation matrix to the idenity
	;    we are changing the way the sprite draws (from dashed line
	;    to 50% mask), so erase it now to avoid glitches
	;    
	
	clr	dx					;no gstate
	mov	ax,MSG_GO_UNDRAW_SPRITE
	call	ObjCallInstanceNoLock

	AccessSpriteTransformChunk	di,ds,si

	mov	bx,1
	clr	ax
	xchgwwf	bxax,ds:[di].OT_transform.GTM_e11
	tst	bx
	jns	10$
	negwwf	bxax
10$:
	rndwwf	bxax
	clr	ax
	movwwf	ds:[di].OT_width,bxax

	mov	bx,1
	clr	ax
	xchgwwf	bxax,ds:[di].OT_transform.GTM_e22
	tst	bx
	jns	20$
	negwwf	bxax
20$:
	rndwwf	bxax
	clr	ax
	movwwf	ds:[di].OT_height,bxax

	.leave
	ret
BitmapConvertScaleToDimensions		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianCompleteCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After bitmap has been interactively created: 
		Clean up its instance data to have the Identity matrix
		in OT_transform
		Have it become editable
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		ss:bp - GrObjMouseData

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianCompleteCreate	method dynamic BitmapGuardianClass, 
							MSG_GO_COMPLETE_CREATE
	.enter

	mov	ax,MSG_GOVG_NORMALIZE
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_COMPLETE_CREATE
	mov	di,offset BitmapGuardianClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_GO_BECOME_EDITABLE
	call	ObjCallInstanceNoLock

	.leave
	ret
BitmapGuardianCompleteCreate		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianCreateVisBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent to force the bitmap to allocate its vidmem
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		ss:[bp] - VisBitmapCreateBitmapParams

RETURN:		
		nothing
	
DESTROYED:	
		ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	28 jun 92	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianCreateVisBitmap	method dynamic BitmapGuardianClass, 
				MSG_BG_CREATE_VIS_BITMAP
	.enter

	mov	ax,MSG_VIS_BITMAP_CREATE_BITMAP
	clr	di
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
BitmapGuardianCreateVisBitmap		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianCombineSelectionStateNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	BitmapGuardian method for
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
BitmapGuardianCombineSelectionStateNotificationData method dynamic BitmapGuardianClass,  MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

	uses	ax

	.enter

	mov	di, offset BitmapGuardianClass
	call	ObjCallSuperNoLock

	;
	;  Indicate that a bitmap object is selected
	;
	mov	bx, cx
	call	MemLock
	jc	done
	mov	es, ax
	BitSet	es:[GONSSC_selectionState].GSS_flags, GSSF_BITMAP_SELECTED
	call	MemUnlock

done:
	.leave
	ret
BitmapGuardianCombineSelectionStateNotificationData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianGetPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return od of pointer image

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		ss:bp - PointDWFixed

RETURN:		
		ax - MouseReturnFlags with MRF_NEW_POINTER_IMAGE
		cx:dx - od of pointer image
	
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
	srs	5/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianGetPointerImage	method dynamic BitmapGuardianClass, 
			MSG_GO_GET_POINTER_IMAGE

	tst	ds:[di].BGI_toolClass.segment
	jz	callSuper

	mov	es, ds:[di].BGI_toolClass.segment
	mov	di, ds:[di].BGI_toolClass.offset
	mov	ax, MSG_TOOL_GET_POINTER_IMAGE
	GOTO	ObjCallClassNoLock

callSuper:
	mov	di, offset BitmapGuardianClass
	GOTO	ObjGotoSuperTailRecurse
BitmapGuardianGetPointerImage		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BitmapGuardianSendUINotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	BitmapGuardian method for MSG_GO_SEND_UI_NOTIFICATION

		Passes the notification to the GrObjBody so that it can
		coalesce each GrObjBitmap's attrs into a single update.

Pass:		*ds:si = BitmapGuardian object
		ds:di = BitmapGuardian instance

		cx - GrObjUINotificationTypes of notifications that need to
		     be performed.

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianSendUINotification	method dynamic	BitmapGuardianClass,
					MSG_GO_SEND_UI_NOTIFICATION
	uses	bp
	.enter

	mov	di, offset BitmapGuardianClass
	call	ObjCallSuperNoLock

	test	cx,mask GOUINT_SELECT
	jz	done

	;  The guardian has been selected so 
	;  tell the ward to update its controllers (except for select state,
	;  'cause we want the grobj's select state), so that the controllers
	;  will reflect the wards attributes,etc.
	;

	mov	ax, MSG_VIS_BITMAP_NOTIFY_CURRENT_FORMAT_CHANGE
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

done:
	.leave
	ret
BitmapGuardianSendUINotification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianRuleLargeStartSelectForWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	BitmapGuardian method for MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD

Called by:	MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD

Pass:		*ds:si = BitmapGuardian object
		ds:di = BitmapGuardian instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 20, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianRuleLargeStartSelectForWard	method dynamic	BitmapGuardianClass, MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD,
	MSG_GOVG_RULE_LARGE_PTR_FOR_WARD,
	MSG_GOVG_RULE_LARGE_END_SELECT_FOR_WARD

	.enter

	;
	;	The bitmap has its own constrain, so override the
	;	grobj constrain
	;

	push	ss:[bp].GOMD_goFA
	BitClr	ss:[bp].GOMD_goFA, GOFA_CONSTRAIN

	mov	di, offset BitmapGuardianClass
	call	ObjCallSuperNoLock

	pop	ss:[bp].GOMD_goFA

	.leave
	ret
BitmapGuardianRuleLargeStartSelectForWard	endm


GrObjBitmapGuardianCode	ends

GrObjTransferCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianGetTransferBlockFromVisWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a vm block from the ward with the ward's data in it

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		ss:bp - GrObjTransferParams

RETURN:		
		cx:dx - 32 bit identifier
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	19 may 92	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianGetTransferBlockFromVisWard method dynamic  BitmapGuardianClass,
				MSG_GOVG_GET_TRANSFER_BLOCK_FROM_VIS_WARD
	.enter

	;
	;  Tell the bitmap object that we want the vm block allocated in
	;  the transfer file.
	;
	mov	bx, ss:[bp].GTP_vmFile
	mov	cx, bx					;cx <- vm file
	mov	ax, MSG_VIS_BITMAP_CREATE_TRANSFER_FORMAT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard

	;
	;  Return the block in 32 bit id form
	;
	mov_tr	cx, ax
	clr	dx

	.leave
	ret
BitmapGuardianGetTransferBlockFromVisWard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianCreateWardWithTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a vm block from the ward with the ward's data in it

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		ss:bp - GrObjTransferParams
		cx:dx - 32 bit identifier

RETURN:		^lcx:dx <- new ward

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	19 may 92	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianCreateWardWithTransfer	method dynamic	BitmapGuardianClass,
					MSG_GOVG_CREATE_WARD_WITH_TRANSFER
	uses	bp

	.enter

	push	cx					;save vm block handle

	;
	;  get the block to store the bitmap object in
	;
	mov	ax,MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	;
	;  Create our ward in the returned block
	;
	mov	ax,MSG_GOVG_CREATE_VIS_WARD
	call	ObjCallInstanceNoLock

	mov_tr	ax, dx					;^lcx:ax <- bitmap obj
	pop	dx					;dx <- vm block
	push	cx, ax					;save bitmap object

	mov	bx, ss:[bp].GTP_vmFile
	mov	cx, bx					;bp <- transfer file
	mov	ax, MSG_VIS_BITMAP_REPLACE_WITH_TRANSFER_FORMAT
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	pop	cx, dx					;return optr
	.leave
	ret
BitmapGuardianCreateWardWithTransfer	endm


GrObjTransferCode	ends


GrObjSpecialGraphicsCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianDrawFGGradientArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bitmaps don't do gradient, so just draw normally

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass

		cl - DrawFlags
		ch - GrObjDrawFlags
		dx - gstate

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
	srs	9/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianDrawFGGradientArea	method dynamic BitmapGuardianClass, 
						MSG_GO_DRAW_FG_GRADIENT_AREA,
					MSG_GO_DRAW_FG_GRADIENT_AREA_HI_RES
	.enter

	mov	ax,MSG_GO_DRAW_FG_AREA
	call	ObjCallInstanceNoLock

	.leave
	ret
BitmapGuardianDrawFGGradientArea		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianSetAreaAttrElementType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bitmaps don't do gradient fill

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass
				
		cl - GrObjAreaAttrElementType

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
	srs	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapGuardianSetAreaAttrElementType method extern dynamic BitmapGuardianClass, 
			MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE
	.enter

	cmp	cl,GOAAET_GRADIENT
	je	done

	mov	di,offset BitmapGuardianClass
	call	ObjCallSuperNoLock
done:
	.leave
	ret
BitmapGuardianSetAreaAttrElementType		endp



GrObjSpecialGraphicsCode	ends


GrObjMiscUtilsCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BitmapGuardianDrawClipArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle as the clip area

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of BitmapGuardianClass
	
		cl - DrawFlags
		ch - GrObjDrawFlags
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
BitmapGuardianDrawClipArea	method dynamic BitmapGuardianClass, 
					MSG_GO_DRAW_CLIP_AREA,
					MSG_GO_DRAW_CLIP_AREA_HI_RES
	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrFillRect

	.leave
	ret
BitmapGuardianDrawClipArea		endm



GrObjMiscUtilsCode	ends


if	ERROR_CHECK

GrObjErrorCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECBitmapGuardianCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an BitmapGuardianClass or one
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
ECBitmapGuardianCheckLMemObject		proc	far
	uses	es,di
	.enter
	pushf	
	mov	di,segment BitmapGuardianClass
	mov	es,di
	mov	di,offset BitmapGuardianClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_OF_CORRECT_CLASS
	popf
	.leave
	ret
ECBitmapGuardianCheckLMemObject		endp

GrObjErrorCode	ends

endif

