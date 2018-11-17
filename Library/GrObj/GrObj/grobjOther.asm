COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Admin
FILE:		objectOther.asm

AUTHOR:		Steve Scholl, Nov 15, 1991

Routines:
	Name			Description
	----			-----------

Method Handlers:
	Name			Description
	----			-----------
GrObjGetCenter			
GrObjEvaluateParentPoint
GrObjEvaluatePARENTPointForEdit		
GrObjSetActionNotificationOutput
GrObjUnsuspendActionNotification		
GrObjSuspendActionNotification		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/91	Initial revision


DESCRIPTION:
		

	$Id: grobjOther.asm,v 1.1 97/04/04 18:07:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjAlmostRequiredCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetActionNotificationOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Specify the message and output descriptor for grobjects to 
	send notification to when an action is performed on them.
	Grobjects will use this notification in the body if they
	don't have one of their own. Many uses of the grobj will
	have no notification. This is for special uses like the
	chart library which needs to know when pieces of the chart
	have become selected, been moved, etc.

	When a grobject sends out a notification it will put
	its OD in cx:dx and bp will contain GrObjActionNotificationType.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx:dx - optr of object to notify 
			passing cx=0 will clear the data and suspension
		bp - message to send

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
	srs	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetActionNotificationOutput	method dynamic GrObjClass, 
					MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT
	uses	ax
	.enter

	;    Attribute manager is not permitted to send action notifications
	;

	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	BitSet	ds:[di].GOI_optFlags, GOOF_HAS_ACTION_NOTIFICATION
	jcxz	clearBit
	
dirty:
	call	ObjMarkDirty

	mov	ax, ATTR_GO_ACTION_NOTIFICATION
	call	GrObjGlobalSetActionNotificationOutput
done:

	.leave
	ret

clearBit:
	BitClr	ds:[di].GOI_optFlags, GOOF_HAS_ACTION_NOTIFICATION
	jmp	dirty

GrObjSetActionNotificationOutput		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSuspendActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prevent grobject from sending out any action notifications.
	If the grobject has no action notification od it will
	will still record the suspension and the suspension will
	be in place when the action output is set.
	Nested suspends and unsuspends are allowed.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		none
	
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
	srs	3/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSuspendActionNotification	method dynamic GrObjClass, 
					MSG_GO_SUSPEND_ACTION_NOTIFICATION
	uses	ax
	.enter

	;    Don't waste space in the attribute manager. It can't
	;    send notifications so it is no use to suspend it.
	;

	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	mov	ax,ATTR_GO_ACTION_NOTIFICATION
	call	GrObjGlobalSuspendActionNotification
done:
	.leave
	ret

GrObjSuspendActionNotification		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjUnsuspendActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Counterbalance a call to MSG_GO_SUSPEND_ACTION_NOTIFICATION.
	If all suspends have been balanced the grobject will be
	free to send out action notification. However, it will not
	send action notifications that were aborted during the suspended
	period. If the grobject is not suspend the message will be ignored.

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
			action notification var data exists

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUnsuspendActionNotification	method dynamic GrObjClass, 
					MSG_GO_UNSUSPEND_ACTION_NOTIFICATION
	uses	ax
	.enter

	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	mov	ax,ATTR_GO_ACTION_NOTIFICATION
	call	GrObjGlobalUnsuspendActionNotification

done:
	.leave	
	ret

GrObjUnsuspendActionNotification		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill the passed PointDWFixed with the center of the object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		ss:bp - PointDWFixed - empty
RETURN:		
		ss:bp - PointDWFixed - filled with center
	
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
GrObjGetCenter	method dynamic GrObjClass, MSG_GO_GET_CENTER
	uses	cx,di,si
	.enter

	mov	si,ds:[di].GOI_normalTransform
	mov	si,ds:[si]
	add	si,offset OT_center			;source offset
	segmov	es,ss,cx				;dest seg
	mov	di,bp					;dest offset

	mov	cx,size PointDWFixed/2
	rep	movsw

	.leave
	ret

GrObjGetCenter		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjAfterAddedToBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent to object just after it is added to the body

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
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAfterAddedToBody	method dynamic GrObjClass, MSG_GO_AFTER_ADDED_TO_BODY
	.enter

EC <	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER	>
EC <	ERROR_NZ	FLOATER_IN_DOCUMENT		>

	call	ObjMarkDirty
	ornf	ds:[di].GOI_optFlags, mask GOOF_ADDED_TO_BODY

	.leave
	ret
GrObjAfterAddedToBody		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBeforeRemovedFromBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent to object just before it is removed from the body

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
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBeforeRemovedFromBody	method dynamic GrObjClass, 
						MSG_GO_BEFORE_REMOVED_FROM_BODY
	.enter

	call	ObjMarkDirty
	andnf	ds:[di].GOI_optFlags, not mask GOOF_ADDED_TO_BODY

	.leave
	ret
GrObjBeforeRemovedFromBody		endm


GrObjAlmostRequiredCode	ends

GrObjRequiredInteractiveCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEvaluatePARENTPointForEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have object evaluate the passed point in terms
		of editing. (ie could the object edit it self
		at this point)(eg for a bitmap, anywhere within
		its bounds, for a spline, somewhere along the spline
		or drawn control points).

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - PointDWFixed in PARENT coordinate system

RETURN:		
		al - EvaluatePositionRating
		dx - EvaluatePositionNotes
	
DESTROYED:	
		ah

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEvaluatePARENTPointForEdit	method dynamic GrObjClass, 
					MSG_GO_EVALUATE_PARENT_POINT_FOR_EDIT
	.enter

	;    Call evaluate point to get the EvaluatePositionNotes
	;    but return the evaluate as none as the default
	;

	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION
	call	ObjCallInstanceNoLock
	mov	al,EVALUATE_NONE

	.leave
	ret

GrObjEvaluatePARENTPointForEdit		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEvaluatePARENTPointForSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GrObj evaluates point to determine if it should be 
		selected by it. This default handler evaluates as
		HIGH and BLOCKS_OUT_LOWER_OBJECTS any point that is
		within the bounds of the object.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
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
GrObjEvaluatePARENTPointForSelection	method dynamic GrObjClass, 
			MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION
bounds	local	RectWWFixed
point	local	PointWWFixed

	uses	cx
	.enter

	mov	bx,ss:[bp]				;orig bp,PARENT pt frame

	;    Convert point to OBJECT and store in stack frame.
	;    If OBJECT coord won't fit in WWF then bail
	;

	push	bp					;local frame
	lea	bp, ss:[point]
	call	GrObjConvertNormalPARENTToWWFOBJECT
	pop	bp					;local frame
	jnc	notInBounds

	;    Get bounds of object in OBJECT coords system
	;

	push	bp
	lea	bp,ss:[bounds]
	CallMod	GrObjGetWWFOBJECTBounds
	pop	bp

	;    Calc hit zone
	;

	mov	dx,MINIMUM_SELECT_DELTA

	;    Point ds:si at bounds and es:di at point 
	;    for several routines
	;
	
	push	ds,si				;object ptr
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	lea	si,ss:[bounds]
	lea	di,ss:[point]

	;    Expand bounds to include object and hit zone
	;

	CallMod	GrObjGlobalExpandRectWWFixedByWWFixed

	;    Check for point in outer bounds
	;

	CallMod	GrObjGlobalIsPointWWFixedInsideRectWWFixed?
	pop	ds,si					;object ptr
	jnc	notInBounds

	;    Point evaluates high and object blots out
	;    out any other objects beneath it that might 
	;    be interested in the point.
	;

	mov	al,EVALUATE_HIGH
	mov	dx,mask EPN_BLOCKS_LOWER_OBJECTS

checkSelectionLock:
	pushf
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_SELECT
	jnz	selectionLock

donePop:
	popf
	.leave
	ret

selectionLock:
	BitSet	dx, EPN_SELECTION_LOCK_SET
	jmp	donePop

notInBounds:
	;    The point is not even within the outer bounds of the
	;    object.  We are not interested in this point
	;

	mov	al,EVALUATE_NONE			
	clr	dx					;doesn't block out
	jmp	checkSelectionLock

GrObjEvaluatePARENTPointForSelection endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjEvaluatePARENTPointForSelectionWithLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some useful hit detection functionality for rectangular
		objects that includes the line width. The default
		handler doesn't include the line width

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - grobject
		ss:bp - PointDWFixed in PARENT coordinates

RETURN:		
		al - EvaluatePositionRating
		dx - EvaluatePositionNotes

DESTROYED:	
		ah

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/24/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjEvaluatePARENTPointForSelectionWithLineWidth		proc	far
bounds		local	RectWWFixed
point		local	PointWWFixed
xAdjust		local	WWFixed
yAdjust		local	WWFixed

	class	GrObjClass
	uses	cx

	.enter

EC <	call	ECGrObjCheckLMemObject			>

	mov	bx,ss:[bp]				;orig bp,PARENT pt frame

	;    Convert point to OBJECT and store in stack frame.
	;    If OBJECT coord won't fit in WWF then bail
	;

	push	bp					;local frame
	lea	bp, ss:[point]
	call	GrObjConvertNormalPARENTToWWFOBJECT
	pop	bp					;local frame
	jc	continue
	jmp	notEvenClose

continue:
	;    Get bounds of object in OBJECT coords system
	;

	push	bp
	lea	bp,ss:[bounds]
	CallMod	GrObjGetWWFOBJECTBounds
	pop	bp

	call	GrObjGlobalGetLineWidthPlusSlopHitDetectionAdjust
	movwwf	xAdjust,dxcx
	movwwf	yAdjust,bxax

	;    Point ds:si at bounds and es:di at point 
	;    for several routines
	;
	
	push	ds,si				;object ptr
	mov	di,ss
	mov	ds,di
	mov	es,di
	lea	si,ss:[bounds]
	lea	di,ss:[point]

	;    Expand bounds to include object and hit zone
	;

	movwwf	dxcx,xAdjust
	movwwf	bxax,yAdjust
	call	GrObjGlobalAsymetricExpandRectWWFixedByWWFixed

	;    Check for point in outer bounds
	;

	CallMod	GrObjGlobalIsPointWWFixedInsideRectWWFixed?
	jnc	notInBoundsPop

	;    Collapse bounds by twice hit zone to get inner rectangle.
	;

	negwwf	dxcx	
	shlwwf	dxcx
	movwwf	bxax,yAdjust
	negwwf	bxax
	shlwwf	bxax
	call	GrObjGlobalAsymetricExpandRectWWFixedByWWFixed

	;    Check for point in inner rectangle
	;

	CallMod	GrObjGlobalIsPointWWFixedInsideRectWWFixed?
	pop	ds,si					;object ptr

	call	GrObjGlobalCompleteHitDetectionWithAreaAttrCheck

checkSelectionLock:
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_SELECT
	jnz	selectionLock

done:
	.leave
	ret

selectionLock:
	BitSet	dx, EPN_SELECTION_LOCK_SET
	jmp	done

notInBoundsPop:
	;    The point is not even within the outer bounds of the
	;    object.  We are not interested in this point
	;

	pop	ds,si					;object ptr

notEvenClose:
	movnf	al,EVALUATE_NONE
	clr	dx
	jmp	checkSelectionLock

GrObjEvaluatePARENTPointForSelectionWithLineWidth		endp


GrObjRequiredInteractiveCode	ends



GrObjExtInteractiveCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetAnchorDOCUMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get coords of anchor point specified by 
		GrObjHandleSpecification in DOCUMENT coords

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		
		ss:bp - GrObjHandleAnchorData
			GOHAD_handle - GrObjHandleSpecification

RETURN:		
		ss:bp - GrObjHandleAnchorData
			GOHAD_anchor - point
		
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetAnchorDOCUMENT	method dynamic GrObjClass, MSG_GO_GET_ANCHOR_DOCUMENT
	uses	cx
	.enter

EC <	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP		>
EC <	ERROR_NZ	OBJECT_CANNOT_BE_IN_A_GROUP		>

	mov	cl,ss:[bp].GOHAD_handle
	call	GrObjGetNormalDOCUMENTHandleCoords

	.leave
	ret
GrObjGetAnchorDOCUMENT		endm




GrObjExtInteractiveCode	ends


GrObjMiscUtilsCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMakeInstruction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make this object an instruction object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

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
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMakeInstruction	method dynamic GrObjClass, 
						MSG_GO_MAKE_INSTRUCTION
	uses	cx, dx
	.enter

	mov	ax, MSG_GO_MAKE_NOT_INSTRUCTION
	call	GrObjGenerateAttributeFlagsChangeUndo

	call	ObjMarkDirty

	;
	; Check to see if instructions are invisible.  If so, then we need
	; to unselect and invalidate this object so that it may become
	; invisible.  Don't do this for an (the) attribute manager.  Sets dx
	; true if object needs to be invalidated.
	;
	
	clr	dx					;Do not invalidate
	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	setFlag
	
	call	GrObjGetDrawFlagsFromBody
	test	ax, mask GODF_DRAW_INSTRUCTIONS
	jnz	setFlag
	
	; Unselect this object.  Must be done before INSTRUCTION bit is
	; changed because they object cannot "Draw Handles" if it is an
	; instruction object and instructions are not drawn.
	dec	dx					;Okay, invalidate
	mov	ax, MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLock
	GrObjDeref	di,ds,si
	
setFlag:
	BitSet	ds:[di].GOI_attrFlags, GOAF_INSTRUCTION

	mov	cx, mask GOUINT_GROBJ_SELECT
	call	GrObjOptSendUINotification

	tst	dx					;Should we invalidate?
	jz	done
	
	push	bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock			;Destroys: ax,cx,dx,bp
	pop	bp
	
done:
	.leave
	ret
GrObjMakeInstruction		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMakeNotInstruction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make this object not an instruction object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

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
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMakeNotInstruction	method dynamic GrObjClass, 
						MSG_GO_MAKE_NOT_INSTRUCTION
	uses	cx
	.enter

	mov	ax, MSG_GO_MAKE_INSTRUCTION
	call	GrObjGenerateAttributeFlagsChangeUndo

	call	ObjMarkDirty

	BitClr	ds:[di].GOI_attrFlags,GOAF_INSTRUCTION

	mov	cx,mask GOUINT_GROBJ_SELECT
	call	GrObjOptSendUINotification
	
	; Check to see if we have to invalidate and thus redraw this object
	; because it was made "NOT_INSTRUCTION" while instructions were
	; invisible.
	call	GrObjGetDrawFlagsFromBody
	test	ax, mask GODF_DRAW_INSTRUCTIONS
	jnz	done					;Not invisible.. bail
	
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	done					;Attr mgr.. bail
	
	push	dx, bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock			;Destroys: ax,cx,dx,bp
	pop	dx, bp
done:
	.leave
	ret
GrObjMakeNotInstruction		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetWrapTextType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the GrObjWrapTextType for this object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
	
		cl - GrObjWrapTextType

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
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetWrapTextType	method dynamic GrObjClass, 
						MSG_GO_SET_WRAP_TEXT_TYPE
	uses	cx
	.enter

EC <	cmp	cl,GrObjWrapTextType			>
EC <	ERROR_AE GROBJ_BAD_GROBJ_WRAP_TEXT_TYPE		>

	test	ds:[di].GOI_locks, mask GOL_WRAP
	jnz	done

	;
	; If we set the wrap type to be wrap inside, be sure to make
	; the object appear unfilled.  Otherwise, you can't see the
	; text anyway.  --JimG 8/31/99
	;
	cmp	cl, GOWTT_WRAP_INSIDE
	jne	afterInside

	call	GrObjGlobalUndoIgnoreActions	; no undoing this action
	push	cx
	mov	ax, MSG_GO_SET_AREA_MASK
	mov	cl, SDM_0
	call	ObjCallInstanceNoLock		; set unfilled (area = 0%)
	pop	cx
	call	GrObjGlobalUndoAcceptActions	; restore undos

afterInside:	
	call	GrObjGenerateUndoChangeGrObjFlagsChain

	clr	ah
	mov	al,cl
	mov	cl,offset GOAF_WRAP
	shl	ax,cl

	mov	cx, ds:[di].GOI_attrFlags
	mov	bx, cx
	andnf	bx, mask GOAF_WRAP
	cmp	ax, bx
	jz	done

	andnf	cx, not mask GOAF_WRAP
	or	ax, cx
	mov	ds:[di].GOI_attrFlags,ax
	call	ObjMarkDirty

	mov	bp, GOANT_WRAP_CHANGED
	call	GrObjOptNotifyAction

	mov	cx,mask GOUINT_GROBJ_SELECT
	call	GrObjOptSendUINotification
done:
	.leave
	ret
GrObjSetWrapTextType		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCheckActionModes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GrObjActionModes

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		carry set if GrObjActionModes not clear
	
DESTROYED:	
		ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	18 jan 1993	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCheckActionModes	method dynamic GrObjClass, MSG_GO_CHECK_ACTION_MODES
	.enter

	test	ds:[di].GOI_actionModes, mask GrObjActionModes
	jz	done

	stc

done:
	.leave
	ret
GrObjCheckActionModes		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetPasteInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set/reset the GOAF_PASTE_INSIDE bit

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cl - TRUE or FALSE
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
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetPasteInside	method dynamic GrObjClass, 
					MSG_GO_SET_PASTE_INSIDE
	.enter

	test	ds:[di].GOI_optFlags,mask GOOF_ATTRIBUTE_MANAGER
	jnz	done

	call	GrObjGenerateUndoChangeGrObjFlagsChain

	call	ObjMarkDirty

	BitClr	ds:[di].GOI_attrFlags, GOAF_PASTE_INSIDE
	tst	cl
	jz	done
	BitSet	ds:[di].GOI_attrFlags, GOAF_PASTE_INSIDE

done:
	.leave
	ret
GrObjSetPasteInside		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetInsertDeleteMoveAllowed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set/reset the GOAF_INSERT_DELETE_MOVE_ALLOWED bit

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cl - TRUE or FALSE
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
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetInsertDeleteMoveAllowed	method dynamic GrObjClass, 
					MSG_GO_SET_INSERT_DELETE_MOVE_ALLOWED
	uses	cx
	.enter

	call	GrObjGenerateUndoChangeGrObjFlagsChain

	call	ObjMarkDirty

	BitClr	ds:[di].GOI_attrFlags, GOAF_INSERT_DELETE_MOVE_ALLOWED
	tst	cl
	jz	sendUI
	BitSet	ds:[di].GOI_attrFlags, GOAF_INSERT_DELETE_MOVE_ALLOWED

sendUI:
	mov	cx,mask GOUINT_GROBJ_SELECT
	call	GrObjOptSendUINotification

	.leave
	ret
GrObjSetInsertDeleteMoveAllowed		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetInsertDeleteResizeAllowed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set/reset the GOAF_INSERT_DELETE_RESIZE_ALLOWED bit

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cl - TRUE or FALSE
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
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetInsertDeleteResizeAllowed	method dynamic GrObjClass, 
					MSG_GO_SET_INSERT_DELETE_RESIZE_ALLOWED
	uses	cx
	.enter

	call	GrObjGenerateUndoChangeGrObjFlagsChain

	call	ObjMarkDirty

	BitClr	ds:[di].GOI_attrFlags, GOAF_INSERT_DELETE_RESIZE_ALLOWED
	tst	cl
	jz	sendUI
	BitSet	ds:[di].GOI_attrFlags, GOAF_INSERT_DELETE_RESIZE_ALLOWED

sendUI:
	mov	cx,mask GOUINT_GROBJ_SELECT
	call	GrObjOptSendUINotification

	.leave
	ret
GrObjSetInsertDeleteResizeAllowed		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetInsertDeleteDeleteAllowed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set/reset the GOAF_INSERT_DELETE_DELETE_ALLOWED bit

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cl - TRUE or FALSE
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
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetInsertDeleteDeleteAllowed	method dynamic GrObjClass, 
					MSG_GO_SET_INSERT_DELETE_DELETE_ALLOWED
	uses	cx
	.enter

	call	GrObjGenerateUndoChangeGrObjFlagsChain

	call	ObjMarkDirty

	BitClr	ds:[di].GOI_attrFlags, GOAF_INSERT_DELETE_DELETE_ALLOWED
	tst	cl
	jz	sendUI
	BitSet	ds:[di].GOI_attrFlags, GOAF_INSERT_DELETE_DELETE_ALLOWED

sendUI:
	mov	cx,mask GOUINT_GROBJ_SELECT
	call	GrObjOptSendUINotification

	.leave
	ret
GrObjSetInsertDeleteDeleteAllowed		endm





GrObjMiscUtilsCode	ends


GrObjAttributesCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSetGrObjAttrFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set/reset GrObjAttrFlags

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx - GrObjAttrFlags to set
		dx - GrObjAttrFlags to reset

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
	srs	9/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSetGrObjAttrFlags	method dynamic GrObjClass, 
						MSG_GO_SET_GROBJ_ATTR_FLAGS
	uses	cx,dx,bp
	.enter

	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER
	jnz	attrMgr

undo:
	call	GrObjGenerateUndoChangeGrObjFlagsChain

	mov	ax,ds:[di].GOI_attrFlags
	push	ax					;orig flags
	not	dx
	andnf	ax,dx					;reset
	ornf	ax,cx					;set
	mov	ds:[di].GOI_attrFlags,ax
	call	ObjMarkDirty
	pop	cx					;orig flags

	;    Check for any of the wrap bits changing.
	;

	xor	cx,ax					;orig flags, new flags
	and	cx,mask GOAF_WRAP
	jnz	wrapNotification

uiUpdate:
	mov	cx,mask GOUINT_GROBJ_SELECT
	call	GrObjOptSendUINotification

	.leave
	ret

attrMgr:
	;    Not allowed to set the no default bits in the attribute manager
	;

	andnf	cx,not NO_DEFAULT_GROBJ_ATTR_FLAGS
	jmp	undo

wrapNotification:
	mov	bp, GOANT_WRAP_CHANGED
	call	GrObjOptNotifyAction
	jmp	uiUpdate

GrObjSetGrObjAttrFlags		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetGrObjAttrFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GrObjAttrFlags

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		cx - GrObjAttrFlags
	
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
	srs	9/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGetGrObjAttrFlags	method dynamic GrObjClass, 
						MSG_GO_GET_GROBJ_ATTR_FLAGS
	.enter

	mov	cx,ds:[di].GOI_attrFlags

	.leave
	ret

GrObjGetGrObjAttrFlags		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateUndoChangeGrObjFlagsChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for changing an objects GrObjFlags

CALLED BY:	INTERNAL
		GrObjRemoveGrObj

PASS:		*ds:si - group

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
	srs	8/ 4/92   	Initial version
	JimG	7/13/94		Changed to use ..AttributeFlagsChangeUndo

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateUndoChangeGrObjFlagsChain		proc	far
	class	GrObjClass
	uses	ax,cx,dx,di
	.enter

	GrObjDeref	di,ds,si
	mov	dx, mask GrObjAttrFlags			;reset them all
	mov	cx,ds:[di].GOI_attrFlags		;set these
	mov	ax,MSG_GO_SET_GROBJ_ATTR_FLAGS		;undo message
	call	GrObjGenerateAttributeFlagsChangeUndo
	
	.leave
	ret
GrObjGenerateUndoChangeGrObjFlagsChain		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGenerateAttributeFlagsChangeUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generates a generic attribute flags change undo chain.

CALLED BY:	INTERNAL
		GrObjMakeInstruction, GrObjMakeNotInstruction,
		GrObjGenerateUndoChangeGrObjFlagsChain
		
PASS:		*ds:si	= GrObj object
		ax	= Message to send for undo
		cx, dx, bp	= Message params
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGenerateAttributeFlagsChangeUndo	proc	far
	uses	bx
	.enter
	
EC <	call	ECGrObjCheckLMemObject				>

	push	cx, dx
	mov	cx, handle attrFlagsString
	mov	dx, offset attrFlagsString
	call	GrObjGlobalStartUndoChain
	pop	cx, dx
	jc	endChain
	
	clr	bx					;no AddUndoActionFlags
	call	GrObjGlobalAddFlagsUndoAction

endChain:
	call	GrObjGlobalEndUndoChain
	
	.leave
	ret
GrObjGenerateAttributeFlagsChangeUndo	endp


GrObjAttributesCode	ends
