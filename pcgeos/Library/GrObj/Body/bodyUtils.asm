COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Hierarchy
FILE:		graphicBodyUtils.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name				Description
	----				-----------
GrObjBodyGetAllGrObjsUnderPointLow  	Get list of children under point
GrObjBodyGetAllGrObjsUnderPointLowCB 	Call back routine ya geek 
GrObjBodyPointInExtendBounds? 	Check for point in object bounds
GrObjBodyCertifyGrObj?
GrObjBodyEvaluateClassHigh?
GrObjBodyOKToInsert?
GrObjBodyPrematureStop?
GrObjBodyMessageToHead		
GrObjBodyMessageToGOAM
GrObjBodyMessageToEdit
GrObjBodyMessageToRuler
GrObjBodyMessageToMouseGrab		

GrObjBodyProcessAllGrObjsInReverseOrderCommon
GrObjBodyGetHighestSelectedChildPosition
GrObjBodyGetHighestSelectedChildPositionCB

GrObjBodySendMessageToFloater		Send message to floater object
GrObjBodySendMessageToFloaterIfCurrentBody	Send message to floater object
						if this body is the current one
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
	Utililty routines for graphic class 
		

	$Id: bodyUtils.asm,v 1.1 97/04/04 18:08:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjRequiredInteractiveCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFillPriorityList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Fill the body's priority list
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of PointerClass

RETURN:		
		GBI_priorityList
			PL_numElements - may have changed
			PL_list	- may have changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFillPriorityList method dynamic GrObjBodyClass, 
				MSG_GB_FILL_PRIORITY_LIST
	uses	cx,dx
	.enter
	
	mov	cx,ds:[LMBH_handle]
	mov	dx,ds:[di].GBI_priorityList

	call	GrObjBodyGetAllGrObjsUnderPointLow
	.leave
	ret
GrObjBodyFillPriorityList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToChildrenInReverseOrder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all children of body in reverse order of
		the draw list. The message will be sent to all
		children regardless of message return values

CALLED BY:	INTERNAL
		

PASS:		
		*ds:si - instance data of graphic body
		ax - message to send to children
		cx,dx,bp - parameters to message

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
	jon	29 sept 92	copied from GrObjBodySendToChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToChildrenInReverseOrder		proc	far
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	clr	bx					;no call back segment
	mov	di, OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GrObjBodyProcessAllGrObjsInReverseOrderCommon

	.leave
	ret
GrObjBodySendToChildrenInReverseOrder		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyProcessAllGrObjsInReverseOrderCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to all children of body in order of the
		draw list

CALLED BY:	INTERNAL
		GrObjBodyGetAllGrObjsUnderPointLow

PASS:		
		*ds:si - instance data of graphic body
		ax - message to send to children
		cx,dx,bp - parameters to message
		bx:di - call back routine
			(must be vfptr in XIP'ed)
			or
			bx = 0
			di - ObjCompCallType

RETURN:		
		ax,cx,dx,bp - may be returned depending on message,
		call back or ObjCompCallType

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: call back routine must be in the same segment
		as this routine or must have been locked explicitly

		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyProcessAllGrObjsInReverseOrderCommon		proc	far
	class	GrObjBodyClass
	uses	bx,di,es
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	es,bx			;segment of call back or zero
	clr	bx			;initial child (first
	push	bx			;child of
	push	bx			;composite)
	mov	bx, offset GOI_reverseLink ;pass offset to LinkPart on stack
	push	bx
	push	es			;pass call-back routine
	push	di			;call back offset or ObjCompCallType

	mov	bx, offset GrObj_offset

;	mov	di,ds:[si]		;treat composite offset as if
;	mov	di,ds:[di].GrObjBody_offset	;it is from meta data
;	add	di,offset GBI_reverseComp
CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	mov	di,offset GBI_reverseComp
	call	ObjCompProcessChildren	; must use a call (no GOTO) since
					; parameters are passed on the stack

	.leave
	ret
GrObjBodyProcessAllGrObjsInReverseOrderCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetAllGrObjsUnderPointLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Send passed method to all children of the body whose visual
	bounds surround the passed point. A list of PL_maxElements children 
	who respond with a non-zero priority will be built in PL_list. 
	The list will be sorted by priority with higher priority first.
	Within a given priority, the items will be sorted in reverse order
	of when they were encountered in the draw list.
		with carry set. Currently only returns the last child.

CALLED BY:	INTERNAL
		
PASS:
	*ds:si - instance data of composite object
	cx:dx - optr to PriorityList
		PL_message
		PL_maxElements
		PL_point
		PL_list - empty
		PL_numElements - 0

RETURN:
	ds	- updated segment
	PL_numElements
	PL_list

DESTROYED:
	es - not updated if segment of PriorityList block

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetAllGrObjsUnderPointLow		proc	near
	class	GrObjBodyClass	
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject				>


	mov	bx, SEGMENT_CS				;call back segment
	mov	di, offset GrObjBodyGetAllGrObjsUnderPointLowCB
	call	GrObjBodyProcessAllGrObjsInReverseOrderCommon

	.leave
	ret

GrObjBodyGetAllGrObjsUnderPointLow		endp
	



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetAllGrObjsUnderPointLowCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if child is under current point.  Calls the
		child if so.

CALLED BY:	INTERNAL
		ObjCompProcessChildren

PASS:		
		*ds:si -- child handle
		*es:di -- composite handle
		cx:dx - optr to PriorityList

RETURN:		
		clc - to keep search going
		stc - to stop search

DESTROYED:	
		ds,es - not updated, this is allowed because this routine
			is called by ObjCompProcessChildren

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetAllGrObjsUnderPointLowCB		proc	far

parentPoint	local	PointDWFixed
bounds		local	RectDWFixed

ForceRef	bounds

	class	GrObjBodyClass
	uses	ax,bx,cx,dx
	.enter	

	;   bx:di to priority list
	;

	mov	bx,cx
	mov	di,dx

	mov	cx,bp					;stack frame
	lea	bp, ss:parentPoint
	call	PriorityListGetPLPoint
	mov	bp,cx					;stack frame

	;    Check for instructions to see if object should not
	;    be processed.
	;

	call	GrObjBodyCertifyGrObj?
	jnc	done

	;    Check for point in bounds of object. If not bail
	;

	call	GrObjBodyPointInBounds?
	jnc	done			

	;    Set ss:bp to parentPoint to be passed with
	;    method to child. Also set ax to method
	;

	push	bp				;stack frame
	lea	bp,ss:[parentPoint]
	call	PriorityListGetMethod

	cmp	ax,PRIORITY_LIST_EVALUATE_PARENT_POINT_FOR_BOUNDS
	je	justBounds

	;    Send method to child using ES version because es is the
	;    segment of the composite
	;

	call	ObjCallInstanceNoLockES
	pop	bp				;stack frame

	tst	al				;check rating
	jnz	newEvaluation			;jmp if not NONE


checkStop:
	call	GrObjBodyPrematureStop?

done:
	.leave
	ret

justBounds:
	pop	bp				;stack frame
	mov	al,EVALUATE_HIGH
	clr	ah				;other data
	clr	dx				;EvaluatePositionNotes

newEvaluation:
	call	GrObjBodyOKToInsert?
	jnc	checkStop

	push	dx				;EvaluatePositionNotes

	;    GrObj has returned a non zero priority. Insert 
	;    it into the priority list
	;

	mov	cx,ds:[LMBH_handle]			;child handle
	mov	dx,si					;child chunk
	call	PriorityListInsert
	
	;    At this point ds and es can no longer be trusted if they
	;    were the segment of the PriorityList block. Since this is
	;    a call back routine, they will be fixed up in 
	;    ObjCompProcessChildren. Just don't try to use them here.
	;

	pop	dx					;EvaluatePositionNotes
	jmp	checkStop

GrObjBodyGetAllGrObjsUnderPointLowCB		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPointInBounds?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the passed parent point is within the extended 
		bounds of the child
		

CALLED BY:	INTERNAL

PASS:		
		*ds:si - instance data of object
		ss:bp - inherit stack frame
			parentPoint
		al - PriorityListInstructions

RETURN:		
		clc - NOT in bounds
		stc - IN bounds

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyPointInBounds?		proc	near

parentPoint	local	PointDWFixed
bounds		local	RectDWFixed

	class	GrObjClass
	uses	ax,bx,di,si,es,ds
	.enter 	inherit

EC <	call	ECGrObjCheckLMemObject				>

	test	al,mask PLI_CHECK_SELECTION_HANDLE_BOUNDS
	jnz	extended

	push	bp
	lea	bp,ss:bounds
	call	GrObjGetDWFPARENTBounds
	pop	bp
	
	;    Expand rectangle so that selection slop
	;    can take affect. We add in the extra one because it helps
	;    some cases when scaled to fit that would get rejected.
	;    

	call	GrObjGetCurrentNudgeUnitsWWFixed
	inc	dx					;x nudge int fudge
	inc 	bx					;y nudge int fudge
	clr	di					;high int
	subdwf	bounds.RDWF_left,didxcx
	subdwf	bounds.RDWF_top,dibxax
	adddwf	bounds.RDWF_right,didxcx
	adddwf	bounds.RDWF_bottom,dibxax

checkInside:
	;    See if parent point is inside bounds
	;

	mov	ax,ss
	mov	ds,ax					;rect segment
	mov	es,ax					;point segment
	lea	di,parentPoint
	lea	si,bounds
	call	GrObjGlobalIsPointDWFixedInsideRectDWFixed?
	jnc	done					;jmp if failed

	stc
done:
	.leave
	ret


extended:
	;    Get extended bounds of object
	;

	push	bp
	lea	bp,ss:bounds
	call	GrObjOptGetDWFSelectionHandleBoundsForTrivialReject
	pop	bp
	jmp	checkInside

GrObjBodyPointInBounds?		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCertifyGrObj?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if object meets priority list criteria
		

CALLED BY:	INTERNAL
		GrObjBodyGetAllGrObjsUnderPointCallBack

PASS:		
		*ds:si - instance data of child
		bx:di - optr of PriorityList

RETURN:		
		stc - certified
			al - PriorityListInstructions
		clc - rejected

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
GrObjBodyCertifyGrObj?		proc	near
	class	GrObjClass

	uses	cx,dx,bp,si
	.enter 	

	call	PriorityListGetInstructions
	tst	al
	jz	ok

	GrObjDeref	bp,ds,si

	test 	al, mask PLI_ONLY_PROCESS_SELECTED	
	jz	checkClass
	test	ds:[bp].GOI_tempState, mask GOTM_SELECTED
	jz	done		;carry clear from test

checkClass:
	test	al, mask PLI_ONLY_PROCESS_CLASS
	jz	ok
	call	PriorityListGetClass
	mov	si, ds:[si]					;access meta
	cmp	dx,ds:[si].MI_base.MB_class.offset
	jne	reject
	cmp	cx,ds:[si].MI_base.MB_class.segment
	jne	reject
	
ok:
	stc
done:
	.leave
	ret

reject:
	clc
	jmp	done

GrObjBodyCertifyGrObj?		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyOKToInsert?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Based on instructions determine if ok to insert object
		into priority list.
		

CALLED BY:	INTERNAL
		GrObjBodyGetAllGrObjsUnderPointCallBack

PASS:		
		*ds:si - instance data of child
		bx:di - optr of PriorityList
		dx - EvaluatePositionNotes
		al - EvaluatePositionRating

RETURN:		
		stc - ok to insert
		clc - not

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
GrObjBodyOKToInsert?		proc	near
	class	GrObjClass
	uses	ax,cx,dx,di,es
	.enter

	mov	ah,al				;EvaluatePositionRatings
	call	PriorityListGetInstructions

	test	al,mask PLI_ONLY_INSERT_HIGH
	jz	checkClass
	cmp	ah, EVALUATE_HIGH
	jne	notOK

checkClass:
	test	al, mask PLI_ONLY_INSERT_CLASS
	jz	checkSelectionLock
	push	dx				;EvaluatePositionNotes
	call	PriorityListGetClass
	mov	es,cx
	mov	di,dx
	call	ObjIsObjectInClass
	pop	dx				;EvaluatePositionNotes
	jnc	notOK
	
checkSelectionLock:
	test	al,mask PLI_DONT_INSERT_OBJECTS_WITH_SELECTION_LOCK
	jz	ok
	test	dx,mask EPN_SELECTION_LOCK_SET
	jnz	notOK

ok:
	stc

done:
	.leave
	ret

notOK:
	clc
	jmp	done
GrObjBodyOKToInsert?		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyPrematureStop?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Should search be stopped because of notes or instructions
		
		

CALLED BY:	INTERNAL
		GrObjBodyGetAllGrObjsUnderPointCallBack

PASS:		
		al - EvaluationPositionRating
		dx - EvaluationPositionNotes
		bx:di - optr of PriorityList

RETURN:		
		stc - stop
		clc - don't stop

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
GrObjBodyPrematureStop?		proc	near
	uses	ax
	.enter

	test	dx, mask EPN_BLOCKS_LOWER_OBJECTS		
	jnz	stop

	mov	ah,al					;EvaluatePositionRatings
	call	PriorityListGetInstructions

	test	al, mask PLI_STOP_AT_FIRST_HIGH
	jz	done		;carry clear from test
	cmp	ah, EVALUATE_HIGH
	je	stop	

	clc

done:
	.leave
	ret

stop:
	stc
	jmp	done

GrObjBodyPrematureStop?		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMessageToHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to head

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - graphic body
		ax - method
		cx,dx,bp - other data
		di - MessageFlags

RETURN:		
		if no head return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
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
	srs	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMessageToHead		proc	far
	class	GrObjBodyClass
	uses	si,bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	mov	bx,ds:[si].GBI_head.handle
	tst	bx						
	jz	done
	mov	si,ds:[si].GBI_head.chunk
	ornf	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Clear zero flag to signify message being sent
	;

	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret

GrObjBodyMessageToHead		endp

GrObjRequiredInteractiveCode	ends


GrObjAlmostRequiredCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GBMarkBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Mark the process that owns the block the body is in as
		busy. 

CALLED BY:	
		INTERNAL
PASS:		
		*(ds:si) - graphic body
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
	srs	6/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GBMarkBusy		proc	far
	uses	ax,cx,dx,bp
	.enter

EC <	call	ECGrObjBodyCheckLMemObject				>

	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication

	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock

	.leave
	ret
GBMarkBusy		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GBMarkNotBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Mark the process that owns the block the body is in as
		not busy. 

CALLED BY:	
		INTERNAL
PASS:		
		*(ds:si) - graphic body
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
	srs	6/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GBMarkNotBusy		proc	far
	uses	ax,cx,dx,bp
	.enter

EC <	call	ECGrObjBodyCheckLMemObject				>

	mov	ax, MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication

	.leave
	ret
GBMarkNotBusy		endp

GrObjAlmostRequiredCode ends





if	ERROR_CHECK
GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECGrObjBodyCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is a subclass of 
		GrObjBodyClass
		
CALLED BY:	

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
ECGrObjBodyCheckLMemObject		proc	far
	uses	es,di
	.enter
	pushf	
	call	ECCheckLMemObject
	mov	di,segment GrObjBodyClass
	mov	es,di
	mov	di, offset GrObjBodyClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_A_BODY_OBJECT	
	popf
	.leave
	ret
ECGrObjBodyCheckLMemObject		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECGrObjBodyCheckLMemOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if ^lbx:si is an OD for an object stored
		in an object block and that it is a subclass of 
		GrObjBodyClass
		
CALLED BY:	INTERNAL

PASS:		
		^lbx:si - object to check
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
ECGrObjBodyCheckLMemOD		proc	far
	uses	ax,cx,dx,bp,di
	.enter
	pushf	
	mov	cx,segment GrObjBodyClass
	mov	dx,offset GrObjBodyClass
	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	ERROR_NC OBJECT_NOT_A_BODY_OBJECT	
	popf
	.leave
	ret
ECGrObjBodyCheckLMemOD		endp


GrObjErrorCode	ends

endif


GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMessageToMouseGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to object with the mouse grab

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - graphic body
		ax - method
		cx,dx,bp - other data
		di - MessageFlags

RETURN:		
		if no mouse grab return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
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
	srs	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMessageToMouseGrab		proc	far
	class	GrObjBodyClass
	uses	si,bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	mov	bx,ds:[si].GBI_mouseGrab.handle
	tst	bx
	jz	done

	mov	si,ds:[si].GBI_mouseGrab.chunk
	ornf	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Clear zero flag to signify message being sent
	;

	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret


GrObjBodyMessageToMouseGrab		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMessageToEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to object being edited

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - graphic body
		ax - method
		cx,dx,bp - other data
		di - MessageFlags

RETURN:		
		if no edit return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
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
	srs	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMessageToEdit		proc	far
	class	GrObjBodyClass
	uses	si,bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	mov	bx,ds:[si].GBI_targetExcl.HG_OD.handle
	tst	bx
	jz	done

	mov	si,ds:[si].GBI_targetExcl.HG_OD.chunk
	ornf	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Clear zero flag to signify message being sent
	;

	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret


GrObjBodyMessageToEdit		endp

GrObjDrawCode	ends


GrObjGroupCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetHighestSelectedChildPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the draw position and reverse position of the
		selected child that is furthest along in the draw list

CALLED BY:	INTERNAL

PASS:		
		*ds:si - body

RETURN:		
		clc - no selected children
			cx,dx - destroyed
		stc - success
			cx - position in draw list
			dx - position in reverse list

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetHighestSelectedChildPosition		proc	far
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx, SEGMENT_CS
	mov	di, offset GrObjBodyGetHighestSelectedChildPositionCB
	clr	cx				;position of first child
						;in reverse list
	call	GrObjBodyProcessAllGrObjsInReverseOrderCommon

	.leave
	ret
GrObjBodyGetHighestSelectedChildPosition		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetHighestSelectedChildPositionCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this child is selected then get it position
		and stop
		

CALLED BY:	INTERNAL

PASS:		
		*ds:si -- child handle
		*es:di -- composite handle

RETURN:		
		clc - not yet
			cx - position of next child in reverse list
		stc - found
			cx - position in draw list
			dx - position in reverse list

DESTROYED:	
		si,di - ok because this is call back routine

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetHighestSelectedChildPositionCB		proc	far
	class	GrObjBodyClass
	.enter

	GrObjDeref 	si,ds,si
	test	ds:[si].GOI_tempState,mask GOTM_SELECTED
	jnz	selected

	inc	cx				;next child in reverse list

	;carry clear from test

done:
	.leave
	ret

selected:
	;    Convert position in reverse list to position in draw list
	;

	mov	dx,cx				;position in reverse list
	mov	di,es:[di]
	add	di,es:[di].GrObjBody_offset
	mov	cx,es:[di].GBI_childCount
	sub	cx,dx				;position in draw list
	dec	cx
	jmp	done

GrObjBodyGetHighestSelectedChildPositionCB	endp

GrObjGroupCode	ends


GrObjInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMessageToGOAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to GrObjAttributeManager

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - graphic body
		ax - method
		cx,dx,bp - other data
		di - MessageFlags

RETURN:		
		if MF_CALL
			ax,cx,dx,bp

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMessageToGOAM		proc	far
	class	GrObjBodyClass
	uses	si,bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	mov	bx,ds:[si].GBI_goam.handle
EC <	tst	bx						>
EC <	ERROR_Z GROBJ_BODY_HAS_NO_ATTRIBUTE_MANAGER		>
	mov	si,ds:[si].GBI_goam.chunk
	ornf	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjBodyMessageToGOAM		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMessageToGOAMText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the text object associated with
		the attribute manager

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - object
		ax - message
		di - MessageFlags
		cx,dx,bp - other data for message

RETURN:		
		if MF_CALL
			ax,cx,dx,bp - from message handler

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
	srs	5/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMessageToGOAMText		proc	far
	uses	bx,si,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Get OD of text object from attribute manager
	;

	push	ax,cx,dx,di				;message, params
	mov	ax,MSG_GOAM_GET_TEXT_OD
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMessageToGOAM
	mov	bx,cx
	mov	si,dx
	pop	ax,cx,dx,di				;message, params

	;    Send original message to text object
	;

	ornf	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjBodyMessageToGOAMText		endp

GrObjInitCode	ends




GrObjRequiredExtInteractiveCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendMessageToFloaterIfCurrentBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Send a message to the floater only if this body
		is the current body. Send message by encapsulating the
		message and sending 
		MSG_GH_CLASSED_EVENT_TO_FLOATER_IF_CURRENT_BODY
		to the graphic head

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - graphic body
		ax - method
		cx,dx,bp - other method data
		di - 0 or mask MF_STACK
		es:bx - class ptr of message

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
	srs	7/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendMessageToFloaterIfCurrentBody		proc	far
	class	GrObjBodyClass
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>
EC <	push	di						>
EC <	mov	di,bx						>
EC <	call	ECCheckClass					>
EC <	pop	di						>

	push	si				;body chunk

	;    Get head od and save on stack
	;

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	push	ds:[si].GBI_head.handle
	push	ds:[si].GBI_head.chunk

	;    Encapsulate message
	;

	ornf	di,mask MF_RECORD
	mov	si,bx				;msg class offset
	mov	bx,es				;msg class segment
	call	ObjMessage

	;    Send encapsulated message to head with body od in dx:bp
	;

	mov	cx,di					;message handle
	mov	ax,MSG_GH_CLASSED_EVENT_TO_FLOATER_IF_CURRENT_BODY
	pop	bx,si					;head od
	mov	dx,ds:[LMBH_handle]			;body handle
	pop	bp					;body chunk
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjBodySendMessageToFloaterIfCurrentBody		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCallFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Call the floater. Message is encapsulated and sent to
		head. Head will return the floaters parameters

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - graphic body
		ax - method
		cx,dx,bp - other method data
		di - 0 or mask MF_STACK

RETURN:		
		ax,cx,dx,bp - from message

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCallFloater		proc	far
	class	GrObjBodyClass
	uses	bx,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Get head od and save on stack
	;

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	push	ds:[si].GBI_head.handle
	push	ds:[si].GBI_head.chunk

	;    Encapsulate message
	;

	ornf	di,mask MF_RECORD
	clr	bx,si				;destination
	call	ObjMessage

	;    Send encapsulated message to head
	;

	mov	cx,di					;message handle
	mov	ax,MSG_GH_CALL_FLOATER
	pop	bx,si					;head od
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
GrObjBodyCallFloater		endp

	









COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMessageToFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to object with the focus

CALLED BY:	INTERNAL UTILITY

PASS:		
		*(ds:si) - graphic body
		ax - method
		cx,dx,bp - other data
		di - MessageFlags

RETURN:		
		if no focus return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
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
	srs	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMessageToFocus		proc	far
	class	GrObjBodyClass
	uses	si,bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	mov	bx,ds:[si].GBI_focusExcl.HG_OD.handle
	tst	bx
	jz	done

	mov	si,ds:[si].GBI_focusExcl.HG_OD.chunk
	ornf	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Clear zero flag to signify message being sent
	;

	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret


GrObjBodyMessageToFocus		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMessageToRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to ruler

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - graphic body
		ax - method
		cx,dx,bp - other data
		di - MessageFlags

RETURN:		
		if no edit return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
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
	srs	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMessageToRuler		proc	far
	class	GrObjBodyClass
	uses	si,bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	mov	bx,ds:[si].GBI_ruler.handle
	tst	bx
	jz	done

	mov	si,ds:[si].GBI_ruler.chunk
	ornf	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Clear zero flag to signify message being sent
	;

	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret


GrObjBodyMessageToRuler		endp


GrObjRequiredExtInteractiveCode	ends


GrObjMiscUtilsCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyStandardError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a standard error dialog box

CALLED BY:	INTERNAL UTILITY

PASS:		bx - handle error string chunk
		ax - chunk error string chunk

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
	srs	11/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyStandardError		proc	far
	uses	ax,bp
	.enter

	sub	sp,size StandardDialogOptrParams
	mov	bp,sp
	mov	ss:[bp].SDP_customFlags, 
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	movdw	ss:[bp].SDOP_customString,bxax
	clr	ax
	mov	ss:[bp].SDOP_stringArg1.handle,ax
	mov	ss:[bp].SDOP_stringArg2.handle,ax
	mov	ss:[bp].SDOP_customTriggers.handle,ax
	clr	ss:[bp].SDOP_helpContext.segment

	;    Note: this baby pops the hooey off the stack
	;

	call	UserStandardDialogOptr



	.leave
	ret
GrObjBodyStandardError		endp


GrObjMiscUtilsCode	ends
