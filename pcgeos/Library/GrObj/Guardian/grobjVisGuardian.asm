COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj	
FILE:		objectVisGuardian.asm

AUTHOR:		Steve Scholl, Dec  6, 1991

ROUTINES:
	Name			Description
	----			-----------
GrObjVisGuardianSendGrObjMouseMessageToVisWard
GrObjVisGuardianMessageToVisWard
GrObjVisGuardianInitAndFillPriorityList		
GrObjVisGuardianSendClassedEvent
GrObjVisGuardianEvaluateEditGrabForEdit
GrObjVisGuardianAttemptToEditOther
GrObjVisGuardianStartSelectToEditGrab
GrObjVisGuardianCalcScaleFactorVISToOBJECT
GrObjVisGuardianBeginEditGeometryCommon
GrObjVisGuardianEndEditGeometryCommon

MESSAGE HANDLERS
	Name			Description
	----			-----------
GrObjVisGuardianInitialize
GrObjVisGuardianSetVisWardClass
GrObjVisGuardianCreateVisWard
GrObjVisGuardianSendAnotherToolActivated
GrObjVisGuardianKbdChar		
GrObjVisGuardianDuplicateFloater
GrObjVisGuardianAddVisWard
GrObjVisGuardianLargeStartSelect
GrObjVisGuardianLargePtr
GrObjVisGuardianLargeDragSelect
GrObjVisGuardianLargeEndSelect
GrObjVisGuardianConvertLargeMouseData
GrObjVisGuardianDrawFG
GrObjVisGuardianSetVisWardToolActiveStatus		
GrObjVisGuardianGetVisWardToolActiveStatus
GrObjVisGuardianSetVisWardMouseEventType	
GrObjVisGuardianAfterAddedToBody
GrObjVisGuardianBeforeRemovedFromBody
GrObjVisGuardianApplyOBJECTToVISTransform
GrObjVisGuardianNotifyGrObjValid
GrObjVisGuardianVisBoundsSetup
GrObjVisGuardianHaveWardDestroyCachedGStates
GrObjVisGuardianObjFree		
GrObjVisGuardianGainedTargetExcl
GrObjVisGuardianLostTargetExcl
GrObjVisGuardianGainedFocusExcl
GrObjVisGuardianLostFocusExcl
GrObjVisGuardianAlterFTVMCExcl
GrObjVisGuardianNotifyVisWardChangeBounds
GrObjVisGuardianCreateGState
GrObjVisGuardianPARENTPointForEdit	
GrObjVisGuardianBeginCreate
GrObjVisGuardianGetVisWardOD
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	12/ 6/91		Initial revision


DESCRIPTION:
	
		

	$Id: grobjVisGuardian.asm,v 1.1 97/04/04 18:08:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

GrObjVisGuardianClass		;Define the class record

GrObjClassStructures	ends

GrObjVisGuardianCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize object 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	12/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianMetaInitialize	method dynamic GrObjVisGuardianClass, \
							MSG_META_INITIALIZE
	.enter

	;    Initialize mouse flags to small mouse events and 
	;    to not pass mouse events to ward
	;

	clr	ds:[di].GOVGI_flags

	mov	di, offset GrObjVisGuardianClass
	CallSuper MSG_META_INITIALIZE

	.leave
	ret
GrObjVisGuardianMetaInitialize		endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the vis ward and then call our superclass
		to initialize instance data and attributes

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		ss:bp - GrObjInitializeData

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
	srs	4/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianInitialize	method dynamic GrObjVisGuardianClass, 
						MSG_GO_INITIALIZE
	.enter

	mov	ax,MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	mov	ax,MSG_GOVG_CREATE_VIS_WARD
	call	ObjCallInstanceNoLock

	mov	di,offset GrObjVisGuardianClass
	mov	ax,MSG_GO_INITIALIZE
	call	ObjCallSuperNoLock

	;    Initialize the vis bounds of the ward to be the
	;    OBJECT dimensions. This is the default for most
	;    ward/guardian pairs.
	;

	call	GrObjVisGuardianSetVisBoundsToOBJECTDimensions

	.leave
	ret
GrObjVisGuardianInitialize		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrobjVisGuardianSetVisWardClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the class of the vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		cx:dx - ftpr to class of vis ward

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
	srs	5/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrobjVisGuardianSetVisWardClass	method dynamic GrObjVisGuardianClass, 
						MSG_GOVG_SET_VIS_WARD_CLASS
	.enter

EC <	tst	ds:[di].GOVGI_ward.handle			>
EC <	ERROR_NZ GROBJ_CANT_SET_VIS_WARD_CLASS_AFTER_WARD_CREATED 	>

	mov	ds:[di].GOVGI_class.segment,cx
	mov	ds:[di].GOVGI_class.offset,dx

	.leave
	ret
GrobjVisGuardianSetVisWardClass		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianCreateVisWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create ward of the class in GOVGI_class and store
		OD in GOVGI_ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		cx - block to create ward in

RETURN:		
		cx:dx - ward od
	
DESTROYED:	
		nothing

		WARNING: May cause block in cx to move

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianCreateVisWard	method dynamic GrObjVisGuardianClass, 
						MSG_GOVG_CREATE_VIS_WARD
	uses	ax
	.enter

	;    Create ward of class
	;

	push	si					;parent chunk
	mov	bx,cx					;block handle
	mov	cx,ds:[di].GOVGI_class.segment
EC <	tst	cx					>
EC <	ERROR_Z	OBJECT_VIS_PARENT_HAS_NO_CHILD_CLASS	>
	mov	es,cx
	mov	di,ds:[di].GOVGI_class.offset
	call	ObjInstantiate

	;    Add ward 
	;
	
	movdw	cxdx,bxsi				;ward
	pop	si					;parent chunk
	mov	ax, MSG_GOVG_ADD_VIS_WARD
	call	ObjCallInstanceNoLock

	;    Update body's info on how big objects in the wards
	;    block can get.
	;

	pushdw	cxdx					;ward od
	mov	dx,cx					;ward handle
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GV_GET_POTENTIAL_WARD_SIZE
	call	GrObjVisGuardianMessageToVisWard
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GB_INCREASE_POTENTIAL_EXPANSION
	call	GrObjMessageToBody
	popdw	cxdx					;ward od

	.leave
	ret

GrObjVisGuardianCreateVisWard		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianAddVisWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add ward as visual child

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		cx:dx - vis ward to add

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
	srs	12/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianAddVisWard	method dynamic GrObjVisGuardianClass, \
							MSG_GOVG_ADD_VIS_WARD
	uses	ax, cx, dx
	.enter

EC <	tst	ds:[di].GOVGI_ward.handle				>
EC <	ERROR_NZ OBJECT_VIS_PARENT_ALREADY_HAS_CHILD			>

	call	ObjMarkDirty

	movdw	ds:[di].GOVGI_ward,cxdx

	mov	cx, ds:[LMBH_handle]
	mov	dx, si

	mov	ax,MSG_GV_SET_GUARDIAN_LINK
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
GrObjVisGuardianAddVisWard		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianPassToWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass message to ward. Watch what you pass because
		this handler automatically destroys everything.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass
	
		depends on message

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianPassToWard	method dynamic GrObjVisGuardianClass, 
						MSG_META_SUSPEND,
						MSG_META_UNSUSPEND
	.enter

	push	ax				;message
	mov	di,offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock
	pop 	ax				;message

	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	.leave

	Destroy ax,cx,dx,bp

	ret
GrObjVisGuardianPassToWard		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send any keypresses onto the ward
		

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
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianKbdChar	method dynamic GrObjVisGuardianClass, MSG_META_KBD_CHAR
	.enter

	clr	di
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
GrObjVisGuardianKbdChar		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianSendAnotherToolActivated
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
GrObjVisGuardianSendAnotherToolActivated	method dynamic \
		GrObjVisGuardianClass, MSG_GO_SEND_ANOTHER_TOOL_ACTIVATED
	uses	ax,cx,dx,bp
	.enter

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	bp,mask ATAF_GUARDIAN	
	mov	ax,MSG_GO_ANOTHER_TOOL_ACTIVATED
	clr	di					;MessageFlags
	call	GrObjSendToSelectedGrObjsAndEditAndMouseGrabSuspended

	.leave
	ret
GrObjVisGuardianSendAnotherToolActivated		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianGetEditClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This default handler returns the class of the guardian

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

RETURN:		
		cx:dx - fptr to class
	
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
	srs	5/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianGetEditClass	method dynamic GrObjVisGuardianClass, 
						MSG_GOVG_GET_EDIT_CLASS
	.enter

	mov	di, ds:[si]				;access meta
	movdw	cxdx,ds:[di].MI_base.MB_class

	.leave
	ret
GrObjVisGuardianGetEditClass		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianDuplicateFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy object and its visual ward to a block in the vm
		file. Get handle of block from body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianParentClass

		cx:dx - od of body

RETURN:		
		cx:dx - od of new object
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianDuplicateFloater	method dynamic GrObjVisGuardianClass, \
						MSG_GO_DUPLICATE_FLOATER
	uses	ax
	.enter

EC <	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER 		>
EC <	ERROR_Z OBJECT_BEING_DUPLICATED_IS_NOT_THE_FLOATER	>

	push	cx,dx					;body od

	;    Use super class to copy this object
	;

	mov	di, offset GrObjVisGuardianClass
	CallSuper	MSG_GO_DUPLICATE_FLOATER

	pop	bx, si					;body od

	push	cx, dx					;new guardian od

	;    get block for vis ward into cx
	;
	mov	ax,MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	
	pop	bx, si					;new guardian od
	mov	ax, MSG_GOVG_CREATE_VIS_WARD
	clr	di
	call	ObjMessage

	movdw	cxdx, bxsi				;^lcx:dx <-new guardian

	.leave
	ret
GrObjVisGuardianDuplicateFloater		endm








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianLargeStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start select event.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		ax - Message
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
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianLargeStartSelect	method dynamic GrObjVisGuardianClass, 
						MSG_GO_LARGE_START_SELECT
	.enter

	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jz	document

	test	ds:[di].GOVGI_flags,mask GOVGF_CAN_EDIT_EXISTING_OBJECTS
	jnz	attemptFloaterEdit

checkFloaterCreate:
	;   If the floater is allowed to create objects
	;   then call super class to duplicate floater
	;

	GrObjDeref	di,ds,si
	mov	cl,ds:[di].GOVGI_flags
	andnf	cl,mask GOVGF_CREATE_MODE
	cmp	cl,GOVGCM_NO_CREATE
	je	unprocessed

callSuper:
	mov	di, offset GrObjVisGuardianClass
	CallSuper	MSG_GO_LARGE_START_SELECT

done:
	.leave
	ret

attemptFloaterEdit:
	call	GrObjVisGuardianEvaluateEditGrabForEdit
	call	GrObjVisGuardianAttemptToEditOther
	cmp	bl,GOAEOR_NOTHING_TO_EDIT
	je	checkFloaterCreate
	cmp	bl,GOAEOR_EAT_START_SELECT
	je	unprocessed
	call	GrObjVisGuardianStartSelectToEditGrab
	jmp	done

unprocessed:
	clr	ax
	jmp	done


document:
	;   Object in document has received start select.
	;

	test	ds:[di].GOI_actionModes, mask GOAM_CREATE
	jnz	creating
	test	ds:[di].GOI_tempState,mask GOTM_EDITED
	jz	unprocessed
	test	ds:[di].GOI_tempState,mask GOTM_SYS_TARGET
	jz	unprocessed
	
sendToWard:
	push	ax
	mov	ax, MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD
	call	ObjCallInstanceNoLock
	pop	ax
	call	GrObjVisGuardianHaveBodyGrabTargetAndFocus
	call 	GrObjVisGuardianSendGrObjMouseMessageToVisWard
	jmp	done

creating:
	;    If the guardian should control create then call
	;    the super class to start a drag create
	;

	mov	cl,ds:[di].GOVGI_flags
	andnf	cl,mask GOVGF_CREATE_MODE
	cmp	cl,GOVGCM_GUARDIAN_CREATE
	je	callSuper

	;   Object in document in create mode has received a
	;   start select. if the action is activated, then 
	;   mark happening and proceed. Otherwise bail because
	;   we never received a MSG_GO_BEGIN_CREATE.
	;

	test	ds:[di].GOI_actionModes, mask GOAM_ACTION_ACTIVATED
	jz	unprocessed

	;
	;	clear GOAM_ACTION_ACTIVATED and set GOAM_ACTION_HAPPENING
	;
	xornf	ds:[di].GOI_actionModes, mask GOAM_ACTION_ACTIVATED or \
					 mask GOAM_ACTION_HAPPENING
	jmp	sendToWard
GrObjVisGuardianLargeStartSelect		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianHaveBodyGrabTargetAndFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to body telling it to grab target and focus.

		This routine is called just before sending a start select
		to the ward. Most wards grab the target when they get
		a start select, but if the body hasn't grabbed the target
		from it's parent then the ward won't be able to gain the 
		target. This should only be a problem if the user has been
		working in another application and then moves back over	
		a body and clicks in it. One would expect that the body 
		would just grab the target when it got a start select, 
		but the edit text guardian is not supposed to grab the 
		target unless it really is going to edit something.

CALLED BY:	INTERNAL
		GrObjVisGuardianLargeStartSelect

PASS:		*ds:si - guardian

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
	srs	2/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianHaveBodyGrabTargetAndFocus		proc	near
	uses	ax,di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	mov	ax,MSG_GB_GRAB_TARGET_FOCUS
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	.leave
	ret
GrObjVisGuardianHaveBodyGrabTargetAndFocus		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianLargeStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start MoveCopy event.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		ax - Message
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
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianLargeStartMoveCopy	method dynamic GrObjVisGuardianClass, 
						MSG_GO_LARGE_START_MOVE_COPY,
						MSG_GO_LARGE_END_MOVE_COPY
	.enter

	;
	;  If we're the floater, hooey it
	;
	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER
	jnz	done

	;   Object in document has received start MoveCopy.
	;

	test	ds:[di].GOI_tempState,mask GOTM_EDITED
	jz	unprocessed
	test	ds:[di].GOI_tempState,mask GOTM_SYS_TARGET
	jz	unprocessed
	
	call 	GrObjVisGuardianSendGrObjMouseMessageToVisWard

done:
	.leave
	ret

unprocessed:
	clr	ax
	jmp	done
GrObjVisGuardianLargeStartMoveCopy		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianAttemptToEditOther
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if some other object is more interested in
		the edit point than the edit grab. If so, give it
		the edit grab.


CALLED BY:	INTERNAL
		GrObjVisGuardianLargeStartSelect
		EditTextGuardianLargeStartSelect

PASS:		
		*ds:si - grobjVisGuardian
		ss:bp - GrObjMouseData
		bl - EvaluatePositionRating of edit grab

RETURN:		
		bl - GrObjAttemptToEditOtherResults

DESTROYED:	
		bh

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAttemptEditOtherResults	etype byte
	GOAEOR_EDIT_GRAB_SET	enum GrObjAttemptEditOtherResults
	GOAEOR_NOTHING_TO_EDIT	enum GrObjAttemptEditOtherResults
	GOAEOR_EAT_START_SELECT	enum GrObjAttemptEditOtherResults

GrObjVisGuardianAttemptToEditOther		proc	far
	uses	ax,cx,dx,di,si
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	;    If edit grabs evaluation is high we can't beat it.
	;

	cmp	bl, EVALUATE_HIGH
	je	edit

	call	GrObjVisGuardianGetObjectUnderPointToEdit
	jcxz	noOther

	;    If priority of other object is not greater than
	;    the edit grab priority then edit the edit grab
	;

	cmp	al,bl				;other priority, edit priority
	jle	edit

	;   Send message to object to put it in edit mode.
	;

	push	si				;floater chunk
	mov	bx,cx				;object to edit handle
	mov	si,dx				;object to edit chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_BECOME_EDITABLE
	call	ObjMessage
	pop	si				;floater chunk

	;    See if the floater should starting editing the object with this
	;    start select or if it should just make the object 
	;    editable. This is mainly for the beginner poly* tools
	;    which would add an anchor point at a the location of
	;    the click if we edited them right away.
	;

	mov	ax,MSG_GOVG_CHECK_FOR_EDIT_WITH_FIRST_START_SELECT
	call	ObjCallInstanceNoLock
	jnc	eatStartSelect

edit:
	mov	bl,GOAEOR_EDIT_GRAB_SET

done:
	.leave
	ret

eatStartSelect:
	mov	bl,GOAEOR_EAT_START_SELECT
	jmp	done


noOther:
	;    There is no other object to edit, if the edit grab
	;    is even remotely interested then edit it
	;

	cmp	bl,EVALUATE_NONE
	jne	edit
	mov	bl,GOAEOR_NOTHING_TO_EDIT
	jmp	done

GrObjVisGuardianAttemptToEditOther		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianCheckForEditWithFirstStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler returns carry set to signify the
		object should be edited with the first start select.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

RETURN:		
		stc - edit with this start select
	
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
	srs	11/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianCheckForEditWithFirstStartSelect	method dynamic\
	 GrObjVisGuardianClass, MSG_GOVG_CHECK_FOR_EDIT_WITH_FIRST_START_SELECT
	.enter

	stc

	.leave
	ret
GrObjVisGuardianCheckForEditWithFirstStartSelect		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianGetObjectUnderPointToEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get OD of object that the guardian can edit that
		is under the passed point

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - grobjVisGuardian
		ss:bp - GrObjMouseData

RETURN:		
		^lcx:dx - object to edit
		al - EvaluatePositionNotes
		or cx:dx = 0 if no object

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
	srs	10/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianGetObjectUnderPointToEdit		proc	far
	.enter

	;    See if click is on object of class that we can edit.
	;    We process all objects, regardless of class, so that
	;    we don't edit objects of our class that are blocked out by
	;    objects on top of them. 
	;

	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_EDIT
	mov	cx,1					;return only one object
	mov	dl, 	mask PLI_ONLY_INSERT_CLASS or \
			mask PLI_ONLY_INSERT_HIGH
	call	GrObjVisGuardianInitAndFillPriorityList

	;    Get od of object to edit and priority
	;

	clr	cx				;first child
	mov	ax,MSG_GB_PRIORITY_LIST_GET_ELEMENT
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjMessageToBody
	jbe	noObject			;if carry or zero then
						;we have no object
done:
	.leave
	ret

noObject:
	clr	cx,dx
	jmp	done

GrObjVisGuardianGetObjectUnderPointToEdit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianEvaluateEditGrabForEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if current edit grab is interested in
		start select and is of correct class

CALLED BY:	INTERNAL
		GrObjVisGuardianLargeStartSelect

PASS:		
		*ds:si - objectVisGuardian
		ss:bp - GrObjMouseData

RETURN:		
		bl - EvaluatePositionRating

DESTROYED:	
		bh

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianEvaluateEditGrabForEdit		proc	far
	class	GrObjVisGuardianClass
	uses	ax,cx,dx,di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	;   If edit object is not of same class as guardians vis ward
	;   then punt. 
	;

	mov	ax,MSG_GOVG_GET_EDIT_CLASS
	call	ObjCallInstanceNoLock
	push	bp
	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToEdit
	pop	bp
	jz	none					;jmp if no edit grab
	jnc	none					;jmp if not of class

	;    Get and return evaluation of point from edit grab
	;

	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_EDIT
	mov	dx,size PointDWFixed
	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	call	GrObjMessageToEdit
	mov	bl,al
done:
	.leave
	ret

none:
	mov	bl,EVALUATE_NONE
	jmp	done

GrObjVisGuardianEvaluateEditGrabForEdit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianStartSelectToEditGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	START_SELECT was received by the floater with
		an active ward.

		Attempt to edit currently editing object, else
		attempt to edit object of same class under point.

CALLED BY:	INTERNAL
		GrObjVisGuardianLargeStartSelect

PASS:		
		*ds:si - objectVisGuardian
		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags
		cx, dx - data

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianStartSelectToEditGrab		proc	far
	uses	di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	call	GrObjVisGuardianHaveBodyGrabTargetAndFocus

	;    Update the edit grab with any stored data.
	;    This will get things like the bitmap tool class
	;    to the BitmapGuardian and its Bitmap vis ward.
	;

	mov	ax,MSG_GOVG_UPDATE_EDIT_GRAB_WITH_STORED_DATA
	call	ObjCallInstanceNoLock

	;    Send start select on to editable object
	;

	mov	ax,MSG_GO_LARGE_START_SELECT
	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	dx,size GrObjMouseData
	call	GrObjMessageToEdit

	.leave
	ret

GrObjVisGuardianStartSelectToEditGrab		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianLargePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Either pass message on to super class or to vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	12/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianLargePtr method dynamic GrObjVisGuardianClass, 
						MSG_GO_LARGE_DRAG_SELECT,
						MSG_GO_LARGE_PTR
						
	.enter

	;    Floater shouldn't be handling these events so
	;    just eat it.
	;

	test	ds:[di].GOI_optFlags,mask GOOF_FLOATER
	jnz	setPointerImage

	;    Guardian in document received ptr event.
	;    If we are being edited then ward must be handling mouse events,
	;    so send mouse event to ward
	;

	test	ds:[di].GOI_tempState,mask GOTM_EDITED
	jz	checkCreate
	test	ds:[di].GOI_tempState,mask GOTM_SYS_TARGET
	jnz	sendToWard

checkCreate:
	;    If we are not in create mode then we don't know what is
	;    going on, so punt to superclass
	;

	test	ds:[di].GOI_actionModes,mask GOAM_CREATE
	jz	callSuper	

	;   If vis ward is controlling create then pass mouse
	;   event onto ward, otherwise call our superclass
	;   to continue drag open create
	;

	mov	cl,ds:[di].GOVGI_flags
	andnf	cl,mask GOVGF_CREATE_MODE
	cmp	cl,GOVGCM_VIS_WARD_CREATE
	je	sendToWard

callSuper:
	mov	di, offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret

sendToWard:
	;    Send mouse event to vis ward so it can create/edit itself
	;
	
	;
	;  Let the ruler do what it will
	;
	push	ax
	mov	ax, MSG_GOVG_RULE_LARGE_PTR_FOR_WARD
	call	ObjCallInstanceNoLock
	pop	ax
	call 	GrObjVisGuardianSendGrObjMouseMessageToVisWard
	jmp	done

setPointerImage:
	mov	ax,MSG_GO_GET_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	ornf	ax,mask MRF_PROCESSED
	jmp	done

GrObjVisGuardianLargePtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianLargeEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Either pass message on to super class or to vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	12/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianLargeEndSelect method dynamic GrObjVisGuardianClass, 
						MSG_GO_LARGE_END_SELECT
						
	.enter

	;    Floater shouldn't be handling these events so
	;    just eat it.
	;

	test	ds:[di].GOI_optFlags,mask GOOF_FLOATER
	jnz	setPointerImage

	;    Guardian in document received ptr event.
	;    If we are being edited then ward must be handling mouse events,
	;    so send mouse event to ward
	;

	test	ds:[di].GOI_tempState,mask GOTM_EDITED
	jz	checkCreate
	test	ds:[di].GOI_tempState,mask GOTM_SYS_TARGET
	jnz	sendToWard

checkCreate:
	;    If we are not in create mode then we don't know what is
	;    going on, so punt to superclass
	;

	test	ds:[di].GOI_actionModes,mask GOAM_CREATE
	jz	callSuper	

	;   If vis ward is controlling create then pass mouse
	;   event onto ward, otherwise call our superclass
	;   to complete drag open create
	;

	mov	cl,ds:[di].GOVGI_flags
	andnf	cl,mask GOVGF_CREATE_MODE
	cmp	cl,GOVGCM_VIS_WARD_CREATE
	je	sendToWard

callSuper:
	mov	di, offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret

sendToWard:
	;    Send mouse event to vis ward so it can create/edit itself
	;
	
	;
	;  Let the ruler do what it will
	;
	push	ax
	mov	ax, MSG_GOVG_RULE_LARGE_END_SELECT_FOR_WARD
	call	ObjCallInstanceNoLock
	pop	ax
	call 	GrObjVisGuardianSendGrObjMouseMessageToVisWard
	jmp	done

setPointerImage:
	mov	ax,MSG_GO_GET_POINTER_IMAGE
	call	ObjCallInstanceNoLock
	ornf	ax,mask MRF_PROCESSED
	
	push	ax					;MouseReturnFlags
	mov	ax,MSG_GO_RELEASE_MOUSE
	call	ObjCallInstanceNoLock
	pop	ax					;MouseReturnFlags
	jmp	done

GrObjVisGuardianLargeEndSelect		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianRuleLargeStartSelectForWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjVisGuardian method for MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD

Called by:	MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD

Pass:		*ds:si = GrObjVisGuardian object
		ds:di = GrObjVisGuardian instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 20, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianRuleLargeStartSelectForWard	method dynamic	GrObjVisGuardianClass, MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD
	uses	cx
	.enter

	mov	cx, mask VRCS_SET_REFERENCE
	call	GrObjVisGuardianRuleCommon

	.leave
	ret
GrObjVisGuardianRuleLargeStartSelectForWard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianRuleLargeEndSelectForWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjVisGuardian method for MSG_GOVG_RULE_LARGE_END_SELECT_FOR_WARD

Called by:	MSG_GOVG_RULE_LARGE_END_SELECT_FOR_WARD

Pass:		*ds:si = GrObjVisGuardian object
		ds:di = GrObjVisGuardian instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 20, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianRuleLargeEndSelectForWard	method dynamic	GrObjVisGuardianClass, MSG_GOVG_RULE_LARGE_END_SELECT_FOR_WARD,
	MSG_GOVG_RULE_LARGE_PTR_FOR_WARD
	uses	cx
	.enter

	clr	cx
	call	GrObjVisGuardianRuleCommon

	.leave
	ret
GrObjVisGuardianRuleLargeEndSelectForWard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjVisGuardianRuleCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		*ds:si - guardian
		ss:[bp] - GrObjMouseData

		ax - grobj mouse message
		cx - mask VRCS_SET_REFERENCE if so desired; 0 otherwise

Return:		ss:[bp] - point ruled if applicable

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 25, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianRuleCommon	proc	near
	uses	ax, cx, di
	.enter
	
	test	ss:[bp].GOMD_goFA, mask GOFA_SNAP_TO or mask GOFA_CONSTRAIN
	jnz	checkSnap
	;
	; Pass the mouse event on anyway, so that ruler feedback shows
	; while manipulating the ward
	;
sendToRuler:
	ornf	cx, mask VRCS_OVERRIDE
	mov	ax, MSG_VIS_RULER_RULE_LARGE_PTR
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToRuler
	.leave
	ret

checkSnap:
	test	ss:[bp].GOMD_goFA, mask GOFA_SNAP_TO
	jz	doGuides				;must be guides

	ornf	cx, VRCS_SNAP_TO_GRID_ABSOLUTE or VRCS_SNAP_TO_GUIDES

	test	ss:[bp].GOMD_goFA, mask GOFA_CONSTRAIN
	jz	sendToRuler

doGuides:
	ornf	cx, VRCS_CONSTRAIN_TO_HV_AXES or VRCS_CONSTRAIN_TO_DIAGONALS
	jmp	sendToRuler
GrObjVisGuardianRuleCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianSendGrObjMouseMessageToVisWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert GrObj Mouse Message to a system mouse message
		and send to visual ward

CALLED BY:	INTERNAL
		GrObjVisGuardianLargeStartSelect
		GrObjVisGuardianLargeDragSelect
		GrObjVisGuardianLargePtr
		GrObjVisGuardianLargeEndSelect

PASS:		
		*ds:si - GrObjVisGuardian
		ss:bp - GrObjMouseData
		ax - GrObj Message

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
	srs	12/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianSendGrObjMouseMessageToVisWard		proc	far
	class	GrObjVisGuardianClass
	uses	bx,bp,di
	.enter

	;    Always convert mouse event to large data structure
	;

	mov	cx,bp
	sub	sp,size LargeMouseData
	mov	bp,sp
	push	ax					;grobj message
	mov	ax,MSG_GOVG_CONVERT_LARGE_MOUSE_DATA
	call	ObjCallInstanceNoLock
	pop	ax					;grobj message

	GrObjDeref	di,ds,si
	test	ds:[di].GOVGI_flags, mask GOVGF_LARGE
	jnz	reallyLarge

	;    If ward really wants small mouse event then
	;    take data from LargeMouseData stack frame and
	;    pass it in registers to ward
	;

	mov_tr	cx,ax					;grobj message
	CallMod	GrObjConvertGrObjMouseMessageToSmall

	mov	cx, ss:[bp].LMD_location.PDF_x.DWF_int.low
	mov	bx, ss:[bp].LMD_location.PDF_x.DWF_frac
	rndwwf	cxbx

	mov	dx, ss:[bp].LMD_location.PDF_y.DWF_int.low
	mov	bx, ss:[bp].LMD_location.PDF_y.DWF_frac
	rndwwf	dxbx

	mov	bh,ss:[bp].LMD_uiFunctionsActive
	mov	bl,ss:[bp].LMD_buttonInfo
	mov	bp, bx


send:
	;    Send mouse message to ward, using MF_CALL so that ward
	;    can return MouseReturnFlags
	;

	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard


	add	sp,size LargeMouseData

	.leave
	ret

reallyLarge:
	;    Ward wanting large mouse events is not handled yet
	;

	mov_tr	cx,ax					;grobj mouse message
	CallMod	GrObjConvertGrObjMouseMessageToLarge
	jmp	send

GrObjVisGuardianSendGrObjMouseMessageToVisWard		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianConvertLargeMouseData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert data in GrObjMouseData to LargeMouseData

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		ss:cx - GrObjMouseData - 
				GOMD_point - in PARENT coords
				GOMD_gstate - not used
				GOMD_goFA -
				GOMD_buttonInfo - from orig system mouse event
				GOMD_uiFA - from orig system mouse event
		ss:bp - LargeMouseData - empty

RETURN:		
		ss:bp - LargeMouseData 
			LMD_location - in vis bounds coordinate system of ward
			LMD_buttonInfo
			LMD_uiFA

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This routine takes data on two different areas 
		of the stack and it returns data on the stack so it
		may only be called from the same thread

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianConvertLargeMouseData	method dynamic GrObjVisGuardianClass, 
					MSG_GOVG_CONVERT_LARGE_MOUSE_DATA
	uses	ax,cx,dx
	.enter

	mov	bx,cx				;GrObjMouseData offset

	;    Copy point to LargeMouseData
	;

	push	ds,si				;object ptr
	mov	ax,ss
	mov	ds,ax				;source segment
	mov	es,ax				;dest segment
	lea	si, [bx.GOMD_point]		;source offset
	lea	di, [bp.LMD_location]		;dest offset
	MoveConstantNumBytes	<size PointDWFixed> ,cx
	pop	ds,si				;object ptr

	;    Untransform the document coordinate mouse postion into 
	;    the vis coordinates of ward
	;

	clr	di
	call	GrCreateState
	call	GrObjApplyNormalTransform
	mov	dx,di				;gstate
	call	GrObjVisGuardianOptApplyOBJECTToVISTransform
	mov	dx,bp				;LargeMouseData	
	call	GrUntransformDWFixed
	call	GrDestroyState

	;   Copy ButtonInfo and UIFA into LargeMouseData
	;

	mov	cl,ss:[bx].GOMD_uiFA
	ornf	cl,mask UIFA_IN
	mov	ss:[bp].LMD_uiFunctionsActive,cl
	mov	cl,ss:[bx].GOMD_buttonInfo
	mov	ss:[bp].LMD_buttonInfo,cl


	.leave
	ret
GrObjVisGuardianConvertLargeMouseData		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianInitAndFillPriorityList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize PriorityList and fill it with objects
		that can be edited by the guardian

CALLED BY:	INTERNAL
		GrObjVisGuardianAttemptToEditOther
PASS:		
		*(ds:si) - pointer instance data
		ss:bp - PointDWFixed
		ax - method
		cx - max elements
		dl - PriorityListInstructions

RETURN:		
		PriorityListChanged
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianInitAndFillPriorityList		proc	near
	class	GrObjVisGuardianClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject	>

	push	ax,cx,dx			
	mov	ax,MSG_GOVG_GET_EDIT_CLASS
	call	ObjCallInstanceNoLock
	movdw	bxdi,cxdx
	pop	ax,cx,dx
	call	GrObjGlobalInitAndFillPriorityList

	.leave
	ret
GrObjVisGuardianInitAndFillPriorityList		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass gained target onto the ward
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardian

RETURN:		
		none
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianGainedTargetExcl	method dynamic GrObjVisGuardianClass, 
						MSG_META_GAINED_TARGET_EXCL
	.enter

	call	GrObjVisGuardianIncVisWardsInteractibleCount

	;    We need body to be suspended so that we don't get multiple
	;    ui updates as selected objects become unselected and this
	;    object becomes editable.
	;    HACK. Because we are suspending body after gaining
	;    target this object will receive a MSG_META_SUSPEND from the
	;    body. But when this object sends MSG_META_GAINED_TARGET_EXCL
	;    to its superclass, the superclass handler will send a 
	;    MSG_META_SUSPEND to the object for each time the body
	;    is suspended. One of those MSG_META_SUSPENDs this object
	;    already received directly from the body. So we got it
	;    twice. Counteract it by sending an MSG_META_UNSUSPEND 
	;    to ourself.
	;

	clr	di
	mov	ax, MSG_GB_IGNORE_UNDO_ACTIONS_AND_SUSPEND
	call	GrObjMessageToBody
	mov	ax,MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_GAINED_TARGET_EXCL
	mov	di, offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_META_GAINED_TARGET_EXCL
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	mov	ax, MSG_GB_UNSUSPEND_AND_ACCEPT_UNDO_ACTIONS
	clr	di
	call	GrObjMessageToBody

	;   Must do this last because the spline changes its
	;   bounds upon gaining of target.
	;   Not marking the object dirty on purpose, because
	;   object can't be discard while  it is being edited.
	;

	GrObjDeref	di,ds,si
	BitClr	ds:[di].GOVGI_flags, GOVGF_VIS_BOUNDS_HAVE_CHANGED

	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjVisGuardianGainedTargetExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Passed lost target onto the ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianLostTargetExcl	method dynamic GrObjVisGuardianClass, 
						MSG_META_LOST_TARGET_EXCL
	.enter

	test	ds:[di].GOI_tempState, mask GOTM_EDITED
	jz	done

	;    We need to be suspended so that we don't get two updates.
	;    One from this object losing the target and the other
	;    from this object becoming selected.
	;    HACK. Because we are suspending body while we have the
	;    target this object will receive a MSG_META_SUSPEND from the
	;    body. But when this object sends MSG_META_LOST_TARGET_EXCL
	;    to its superclass, the superclass handler will send a 
	;    MSG_META_UNSUSPEND to the object for each time the body
	;    is suspended. One of those MSG_META_UNSUSPENDs this object
	;    isn't supposed to have received yet because this object
	;    hasn't unsuspended the body yet. So we have received
	;    a MSG_META_UNSUSPEND ahead of time. To counteract this
	;    so that we can sucessfully unsuspend the body we
	;    need to suspend just ourselves one more time.
	;

	clr	di
	mov	ax, MSG_GB_IGNORE_UNDO_ACTIONS_AND_SUSPEND
	call	GrObjMessageToBody
	mov	ax,MSG_META_SUSPEND
	call	ObjCallInstanceNoLock

	mov	ax,MSG_META_LOST_TARGET_EXCL
	mov	di,offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_META_LOST_TARGET_EXCL
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	call	GrObjVisGuardianDecVisWardsInteractibleCount

	mov	ax, MSG_GB_UNSUSPEND_AND_ACCEPT_UNDO_ACTIONS
	clr	di
	call	GrObjMessageToBody

	call	GrObjVisGuardianSendResizeActionNotificationIfBoundsChanged

done:

	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjVisGuardianLostTargetExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianReleaseExcls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell our ward to release the gadget exclusive

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	jdashe	3/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianReleaseExcls	method dynamic GrObjVisGuardianClass, 
						MSG_GO_RELEASE_EXCLS
	uses	cx,dx
	.enter

	;    In case the ward has the gadget, tell the body to
	;    take the gadget away from it.
	;

	movdw	cxdx,ds:[di].GOVGI_ward
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody

	mov	ax, MSG_GO_RELEASE_EXCLS
	mov	di, offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

	.leave

	Destroy	ax

	ret
GrObjVisGuardianReleaseExcls		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianIncVisWardsInteractibleCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment the interactible count of the block that the
		vis ward is in. This is normally used when the
		the guardian gains the target or focus so that
		the ward won't be discarded while targeted or focused

CALLED BY:	INTERNAL
		GrObjVisGuardianGainedTargetExcl
		GrObjVisGuardianGainedFocusExcl

PASS:		*ds:si - guardian

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			wards is in same block as guardian

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianIncVisWardsInteractibleCount		proc	far
	class	GrObjVisGuardianClass
	uses	ax,bx,di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject
EC <	push	si						>

	;    If the ward is in the same block as the guardian then
	;    no need to lock the ward block
	;

	GrObjDeref	di,ds,si
	mov	bx,ds:[di].GOVGI_ward.handle
	tst	bx
	jz	done
EC <	mov	si,ds:[di].GOVGI_ward.chunk				>
	cmp	bx,ds:[LMBH_handle]
	jne	notSameBlock
	call	ObjIncInteractibleCount
done:

EC <	pop	si						>
	.leave
	ret

notSameBlock:
	push	ds					;guardian segment
	call	ObjLockObjBlock				;lock ward block
	mov	ds,ax					;ward segment
	call	ObjIncInteractibleCount			;wards interactible
	call	MemUnlock				;unlock ward block
	pop	ds					;guardian segment
	jmp	done


GrObjVisGuardianIncVisWardsInteractibleCount		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianDecVisWardsInteractibleCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the interactible count of the block that the
		vis ward is in. This is normally used when the
		the guardian loses the target or focus to counteract
		the incing when the target or focus was gained.

CALLED BY:	INTERNAL
		GrObjVisGuardianLostTargetExcl
		GrObjVisGuardianLostFocusExcl

PASS:		*ds:si - guardian

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			wards is in same block as guardian

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianDecVisWardsInteractibleCount		proc	far
	class	GrObjVisGuardianClass
	uses	ax,bx,di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject
EC <	push	si						>

	;    If the ward is in the same block as the guardian then
	;    no need to lock the ward block
	;

	GrObjDeref	di,ds,si
	mov	bx,ds:[di].GOVGI_ward.handle
	tst	bx
	jz	done
EC <	mov	si,ds:[di].GOVGI_ward.chunk				>
	cmp	bx,ds:[LMBH_handle]
	jne	notSameBlock
	call	ObjDecInteractibleCount
done:

EC <	pop	si						>
	.leave
	ret

notSameBlock:
	push	ds					;guardian segment
	call	ObjLockObjBlock				;lock ward block
	mov	ds,ax					;ward segment
	call	ObjDecInteractibleCount			;wards interactible
	call	MemUnlock				;unlock ward block
	pop	ds					;guardian segment
	jmp	done


GrObjVisGuardianDecVisWardsInteractibleCount		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianSendResizeActionNotificationIfBoundsChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the GOVGF_VIS_BOUNDS_CHANGED bit is set then
		clear the bit and send a GOANT_RESIZED action
		notification.

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - GrObjVisGuardian

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
	srs	11/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianSendResizeActionNotificationIfBoundsChanged	proc	far
	class	GrObjVisGuardianClass
	uses	di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	GrObjDeref	di,ds,si
	test	ds:[di].GOVGI_flags, mask GOVGF_VIS_BOUNDS_HAVE_CHANGED
	jz	done

	BitClr	ds:[di].GOVGI_flags,GOVGF_VIS_BOUNDS_HAVE_CHANGED

	mov	bp,GOANT_RESIZED
	call	GrObjOptNotifyAction

done:
	.leave
	ret
GrObjVisGuardianSendResizeActionNotificationIfBoundsChanged		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianUpdateSysExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass message onto ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		WARNING: This method is not dynamic

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianUpdateSysExcl	method GrObjVisGuardianClass, 
						MSG_META_GAINED_SYS_TARGET_EXCL,
						MSG_META_LOST_SYS_TARGET_EXCL,
						MSG_META_GAINED_SYS_FOCUS_EXCL,
						MSG_META_LOST_SYS_FOCUS_EXCL
	.enter

	push	ax				;message
	mov	di,offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock
	pop 	ax				;message

	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjVisGuardianUpdateSysExcl		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianGainedFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bad things happen if vis objects get discarded while
		they have the focus.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianGainedFocusExcl	method dynamic GrObjVisGuardianClass, 
						MSG_META_GAINED_FOCUS_EXCL
	.enter

	call	GrObjVisGuardianIncVisWardsInteractibleCount
	call	GrObjVisGuardianUpdateSysExcl

	.leave

	ret
GrObjVisGuardianGainedFocusExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianLostFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bad things happen if vis objects get discarded while
		they have the focus.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianLostFocusExcl	method dynamic GrObjVisGuardianClass, 
						MSG_META_LOST_FOCUS_EXCL
	.enter

	call	GrObjVisGuardianUpdateSysExcl
	call	GrObjVisGuardianDecVisWardsInteractibleCount

	.leave

	ret
GrObjVisGuardianLostFocusExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianAlterFTVMCExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If message is a grab target from our ward then
		grab the edit.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass
	
		cx:dx - optr to grab/release exclusive for
		bp - MetaAlterFTVMCExclFlags

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianAlterFTVMCExcl	method dynamic GrObjVisGuardianClass, 
						MSG_META_MUP_ALTER_FTVMC_EXCL
	.enter

	test	bp, mask MAEF_NOT_HERE
	jnz	callSuper

	;    If this is not for the target and focus then handle normally
	;

	test	bp, mask MAEF_TARGET
	jnz	target

checkFocus:
	test	bp,mask MAEF_FOCUS
	jnz	focus

callSuper:
	; Pass message on to superclass for handling outside of
	; this class.
	;

	test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
	jz	done

	mov	di, offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

done:
	Destroy	ax,cx,dx,bp

	.leave
	ret

target:
	mov	ax,MSG_GO_BECOME_EDITABLE			;assume
	test	bp, mask MAEF_GRAB
	jnz	send
	mov	ax,MSG_GO_BECOME_UNEDITABLE
	mov	cl,SELECT_AFTER_EDIT
send:
	call	ObjCallInstanceNoLock

	BitClr	bp, MAEF_TARGET
	jmp	checkFocus

focus:
	BitClr	bp,MAEF_FOCUS
	test	bp,mask MAEF_GRAB
	jz	releaseFocus
	call	GrObjCanEdit?
	jnc	callSuper
	call	MetaGrabFocusExclLow
	jmp	callSuper

releaseFocus:
	call	MetaReleaseFocusExclLow
	jmp	callSuper

GrObjVisGuardianAlterFTVMCExcl		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for a classed event passed via 
		MSG_META_SEND_CLASSED_EVENT. 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		cx - handle of ClassedEvent
		dx - TravelOptions

RETURN:		
		if Event delivered
			if MF_CALL ax,cx,dx,bp  - from method	

DESTROYED:	
		ax,cx,dx,bp - unless returned

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianSendClassedEvent	method dynamic GrObjVisGuardianClass, \
						MSG_META_SEND_CLASSED_EVENT
	.enter

	;    Guardian and its ward are generally consider one object
	;    so self may be sent to vis ward
	;

	cmp	dx,TO_SELF
	je	checkWard	

	;    Attempt to send the message to the vis ward for these
	;    travel options
	;

	cmp	dx, TO_TARGET
	je	checkWard

	cmp	dx, TO_FOCUS
	je	checkWard

callSuper:
	mov	di, offset GrObjVisGuardianClass
	CallSuper	MSG_META_SEND_CLASSED_EVENT

done:
	.leave
	ret

checkWard:
	;    If vis ward is not able to handle event then send message
	;    to superclass, otherwise send to ward.  So that the
	;    ward can handle MSG_META_COPY and such we pass messages
	;    with a zero class to the ward.
	;

	push	ax,cx,dx				;message, event, TO
	mov	bx,cx					;event handle
	mov	dx,si					;guardian chunk
	call	ObjGetMessageInfo
	xchg	dx,si			;event class offset, guard chunk
	jcxz	popToWard				;class segment
	push	bp
	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	pop	bp
	pop	ax,cx,dx			;message, event, TO
	jz	callSuper			;jmp if no ward
	jnc	callSuper			;jmp if ward not of class

sendToWard:
	;    Send message to ward
	;

	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	jmp	done

popToWard:
	pop	ax,cx,dx			;message, event, TO
	jmp	sendToWard

GrObjVisGuardianSendClassedEvent		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianNotifyGrObjValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify object that it now has a valid normalTransform
		and attribute. The vis guardian needs to set up
		the geometry in its vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

	
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
	srs	1/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianNotifyGrObjValid	method dynamic GrObjVisGuardianClass, 
						MSG_GO_NOTIFY_GROBJ_VALID
	uses	cx
	.enter

	;    Ignore if already valid
	;

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jz	done

	mov	di,offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

	;    Do any initialization necessary for ward. 
	;

	mov	ax,MSG_VIS_NOTIFY_GEOMETRY_VALID
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
 
done:
	.leave
	ret
GrObjVisGuardianNotifyGrObjValid		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianNotifyGrObjInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify object that it is no longer valid.
		Mark ward as geometry invalid

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

	
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
	srs	1/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianNotifyGrObjInvalid	method dynamic GrObjVisGuardianClass, 
					MSG_GO_NOTIFY_GROBJ_INVALID
	.enter

	;    Ignore if already invalid
	;

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done

	mov	di,offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

	call	GrObjVisGuardianMarkVisWardGeometryInvalid
done:
	.leave
	ret
GrObjVisGuardianNotifyGrObjInvalid		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianMarkVisWardGeometryInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the vis ward as having invalid geometry

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - guardian

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
	srs	11/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianMarkVisWardGeometryInvalid		proc	far
	uses	ax,cx,dx,di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject			>

	mov	ax,MSG_VIS_MARK_INVALID
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
GrObjVisGuardianMarkVisWardGeometryInvalid		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianHaveWardDestroyCachedGStates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After the object has been transformed or translated
		when need to have the ward destroy any cached gstates,
		because those gstates will no longer map to proper
		place in the document.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		MSG_GO_COMPLETE_TRANSFORM
			bp - GrObjActionNotificationType

		MSG_GO_COMPLETE_TRANSLATE
			bp - GrObjActionNotificationType

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
	srs	1/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianHaveWardDestroyCachedGStates	method dynamic \
						GrObjVisGuardianClass, 
						MSG_GO_COMPLETE_TRANSFORM,
						MSG_GO_COMPLETE_TRANSLATE
	uses	ax
	.enter

	mov	di,offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_VIS_RECREATE_CACHED_GSTATES
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
GrObjVisGuardianHaveWardDestroyCachedGStates		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianVisBoundsSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This default handler for the
		VisGuardian sets the height and width of the vis ward
		to the OBJECT dimensions and notify the ward
		that its geometry is valid.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	1/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianVisBoundsSetup	method dynamic GrObjVisGuardianClass, 
						MSG_GOVG_VIS_BOUNDS_SETUP
	.enter

	call	GrObjVisGuardianSetVisBoundsToOBJECTDimensions

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done

	;    Objects will do any necessary calculations to handle their
	;    new geometry upon receiving this message. For instance
	;    text objects will re-wrap.
	;

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	GrObjVisGuardianMessageToVisWard
done:
	.leave
	ret
GrObjVisGuardianVisBoundsSetup		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianSetVisBoundsToOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the vis bounds of the ward to match the OBJECT
		dimensions of the object

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - guardian

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
	srs	11/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianSetVisBoundsToOBJECTDimensions		proc	far
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	call	GrObjGetAbsNormalOBJECTDimensions
	rndwwf	dxcx
	rndwwf	bxax
	mov	cx,dx					;width
	mov	dx,bx					;height
	mov	ax,MSG_VIS_SET_SIZE
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
GrObjVisGuardianSetVisBoundsToOBJECTDimensions		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a gstate with the transformations of all groups
		above this object and its own transform

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

RETURN:		
		bp - gstate
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianCreateGState	method dynamic GrObjVisGuardianClass, 
							MSG_GOVG_CREATE_GSTATE
	.enter

	mov	di,OBJECT_GSTATE
	call	GrObjCreateGState
	mov	dx,di					;gstate
	call	GrObjVisGuardianOptApplyOBJECTToVISTransform
	mov	bp,di					;gstate

	.leave
	ret
GrObjVisGuardianCreateGState		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianSetVisWardMouseEventType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the type (large or small) of mouse event that the
		vis ward is interested in

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardian

		cl - VisWardMouseEventType

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
	srs	1/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianSetVisWardMouseEventType	method dynamic \
		GrObjVisGuardianClass, MSG_GOVG_SET_VIS_WARD_MOUSE_EVENT_TYPE
	.enter

	;   Assume small mouse events
	;

	andnf	ds:[di].GOVGI_flags, not mask GOVGF_LARGE

	;   If assumption correct then bail, otherwise deactive
	;

	cmp	cl,VWMET_SMALL
	je	done
	ornf	ds:[di].GOVGI_flags, mask GOVGF_LARGE

done:
	.leave
	ret
GrObjVisGuardianSetVisWardMouseEventType		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianQuickTotalBodyClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Must destroy the wards data in other blocks. The easiest
		way to do this is just to destroy the little pecker completely.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	3/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianQuickTotalBodyClear	method dynamic GrObjVisGuardianClass, 
						MSG_GO_QUICK_TOTAL_BODY_CLEAR
	.enter

	;    Normally MSG_META_OBJ_FREE would inc the in use count
	;    of the ward, but we are pulling a short cut here by
	;    just sending MSG_META_FINAL_OBJ_FREE, so we must
	;    inc the in use count ourselves.
	;

	call	GrObjVisGuardianIncVisWardsInUseCount
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_META_FINAL_OBJ_FREE
	call	GrObjVisGuardianMessageToVisWard

	mov	di, offset GrObjVisGuardianClass
	mov	ax,MSG_GO_QUICK_TOTAL_BODY_CLEAR
	call	ObjCallSuperNoLock

	.leave
	ret
GrObjVisGuardianQuickTotalBodyClear		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generally guardian's do not flush their queue before 
		sending themselves MSG_META_FINAL_OBJ_FREE. However, the
		vis wards always send MSG_META_FINAL_OBJ_FREE via the
		queue. So the ward my still exist after the guardian
		is gone. We must prevent the ward from attempt to send
		messages to the guardian.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

RETURN:		

	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianFinalObjFree	method dynamic GrObjVisGuardianClass, 
						MSG_META_FINAL_OBJ_FREE
	.enter

	clrdw	cxdx
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GV_SET_GUARDIAN_LINK
	call	GrObjVisGuardianMessageToVisWard

	mov	ax,MSG_META_FINAL_OBJ_FREE
	mov	di,offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

	.leave
	ret
GrObjVisGuardianFinalObjFree		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianClearVisWardOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	3/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianClearVisWardOD	method dynamic GrObjVisGuardianClass, 
						MSG_GOVG_CLEAR_VIS_WARD_OD
	.enter

	clr	ax	
	mov	ds:[di].GOVGI_ward.handle,ax
	mov	ds:[di].GOVGI_ward.chunk,ax

	.leave
	ret
GrObjVisGuardianClearVisWardOD		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianIncVisWardsInUseCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment the in use count of the block that the
		vis ward is in. This is normally used when the
		the guardian gains the target or focus so that
		the ward won't be discarded while targeted or focused

CALLED BY:	INTERNAL
		GrObjVisGuardianQuickTotalBodyClear

PASS:		*ds:si - guardian

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			wards is in same block as guardian

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianIncVisWardsInUseCount		proc	near
	class	GrObjVisGuardianClass
	uses	ax,bx,di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject
EC <	push	si						>

	;    If the ward is in the same block as the guardian then
	;    no need to lock the ward block
	;

	GrObjDeref	di,ds,si
	mov	bx,ds:[di].GOVGI_ward.handle
	tst	bx
	jz	done
EC <	mov	si,ds:[di].GOVGI_ward.chunk				>
	cmp	bx,ds:[LMBH_handle]
	jne	notSameBlock
	call	ObjIncInUseCount
done:

EC <	pop	si						>
	.leave
	ret

notSameBlock:
	push	ds					;guardian segment
	call	ObjLockObjBlock				;lock ward block
	mov	ds,ax					;ward segment
	call	ObjIncInUseCount			;wards interactible
	call	MemUnlock				;unlock ward block
	pop	ds					;guardian segment
	jmp	done


GrObjVisGuardianIncVisWardsInUseCount		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianMetaObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass message onto vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	1/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianMetaObjFree	method dynamic GrObjVisGuardianClass,
							MSG_META_OBJ_FREE

	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	
	mov	di,offset GrObjVisGuardianClass
	GOTO	ObjCallSuperNoLock

GrObjVisGuardianMetaObjFree		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free an object *now*

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	1/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianObjFree	method dynamic GrObjVisGuardianClass,
							MSG_GO_OBJ_FREE

	;    The Vis Wards must always use the queue flushing messages.
	;    For instance the text object may have a flash cursor
	;    message in the queue.
	;

	push	ax
	mov	ax, MSG_META_OBJ_FREE
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	pop	ax
	
	mov	di,offset GrObjVisGuardianClass
	GOTO	ObjCallSuperNoLock

GrObjVisGuardianObjFree		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianObjFreeGuaranteedNoQueuedMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free an object *now* without queueing any messages.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	1/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianObjFreeGuaranteedNoQueuedMessages	method dynamic \
GrObjVisGuardianClass,	MSG_GO_OBJ_FREE_GUARANTEED_NO_QUEUED_MESSAGES

	push	ax
	call	GrObjVisGuardianIncVisWardsInUseCount
	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	pop	ax
	
	mov	di,offset GrObjVisGuardianClass
	GOTO	ObjCallSuperNoLock

GrObjVisGuardianObjFreeGuaranteedNoQueuedMessages		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianNormalize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the object into a rectangle with 
		its GrObjTransMatrix as the Identity Matrix

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	4/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianNormalize	method dynamic GrObjVisGuardianClass, 
						MSG_GOVG_NORMALIZE
	.enter

	;    Calculate the bounds of the object in the PARENT
	;    coordinate system. Use the dimensions of the
	;    bounds as the width and height
	;
	
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

	CallMod GrObjGlobalGetWWFixedDimensionsFromRectDWFixed
EC <	ERROR_NC	BUG_IN_DIMENSIONS_CALC			>

	mov	di,ss:[bp].BRD_parentGState
	call	GrDestroyState
	mov	di,ss:[bp].BRD_destGState
	call	GrDestroyState

	add	sp, size BoundingRectData

	rndwwf	dxcx
	rndwwf	bxax
	clr	ax, cx
	call	GrObjSetOBJECTDimensionsAndIdentityMatrix

	.leave
	ret
GrObjVisGuardianNormalize		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianNotifyVisWardChangeBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Notify the guardian that the vis ward wishes to changes its
	vis bounds.

	This default handler sets the OBJECT dimensions to match
	the desired vis bounds. Moves the grobj the amount
	the vis bounds have moved. Sets the vis bounds of the
	ward.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		ss:bp - Rect, desired vis bounds

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
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianNotifyVisWardChangeBounds method dynamic GrObjVisGuardianClass, 
					MSG_GOVG_NOTIFY_VIS_WARD_CHANGE_BOUNDS
	uses	cx,dx

moveDeltas	local	PointDWFixed

	mov	bx, bp			;ss:bx <- passed Rect

	.enter

	call	GrObjVisGuardianBeginEditGeometryCommon

	GrObjDeref	di,ds,si
	BitSet	ds:[di].GOVGI_flags, GOVGF_VIS_BOUNDS_HAVE_CHANGED

	;    Set OBJECT dimensions from the new VisBounds
	;

	mov	dx, ss:[bx].R_right
	sub	dx, ss:[bx].R_left
	mov	ax, ss:[bx].R_bottom
	sub	ax, ss:[bx].R_top
	push	bx				;passed frame offset
	mov_tr	bx,ax				;height int
	clr	ax, cx				;height/width frac
	call	GrObjSetNormalOBJECTDimensions
	pop	bx				;passed frame offset

	;    Calculate the delta from the original vis bound center 
	;    to the new vis bounds center.
	;

	clr	ax
	mov	cx, ss:[bx].R_right
	add	cx, ss:[bx].R_left
	sarwwf	cxax
	movwwf	({WWFixed}ss:moveDeltas.PDF_x.DWF_frac),cxax	

	clr	ax
	mov	cx, ss:[bx].R_bottom
	add	cx, ss:[bx].R_top
	sarwwf	cxax
	movwwf	({WWFixed}ss:moveDeltas.PDF_y.DWF_frac),cxax	

	call	GrObjVisGuardianGetWardWWFixedCenter
	subwwf	({WWFixed}ss:moveDeltas.PDF_x.DWF_frac),dxcx
	subwwf	({WWFixed}ss:moveDeltas.PDF_y.DWF_frac),bxax

	;    Convert to PointDWFixed
	;

	mov	ax,moveDeltas.PDF_x.DWF_int.low
	cwd
	mov	moveDeltas.PDF_x.DWF_int.high,dx
	mov	ax,moveDeltas.PDF_y.DWF_int.low
	cwd
	mov	moveDeltas.PDF_y.DWF_int.high,dx

	;    Convert center delta into PARENT coords.
	;    We don't need to include the transformation from
	;    vis to object because we are setting the object dimensions
	;    to equal the vis bounds.
	;

	clr	di					;no window
	call	GrCreateState
	mov	dx,di					;gstate
	call	GrObjApplyNormalTransformSansCenterTranslation
	segmov	es,ss
	lea	dx,ss:moveDeltas
	call	GrTransformDWFixed
	mov	dx,di					;gstate
	call	GrDestroyState

	push	bp					;locals frame
	lea	bp, ss:moveDeltas
	call	GrObjMoveNormalRelative
	pop	bp					;locals frame

	;    This leave restores the passed bp which has the
	;    Rectangle in it.
	;

	.leave

	;    Actually change bounds of ward
	;

	mov	ax, MSG_GV_SET_VIS_BOUNDS
	mov	di,mask MF_FIXUP_DS or mask MF_STACK
	mov	dx, size Rectangle
	call	GrObjVisGuardianMessageToVisWard

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	call	GrObjVisGuardianEndEditGeometryCommon

	ret
GrObjVisGuardianNotifyVisWardChangeBounds		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianBeginEditGeometryCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform some common functionality for the methods
		the do geometry manipulations on a grobject

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - GrObject

RETURN:		
		nothing

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianBeginEditGeometryCommon		proc	far
	uses	ax,di,dx
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	;    Get gstate to pass with handle drawing messages
	;

	mov	di,BODY_GSTATE
	call	GrObjCreateGState
	mov	dx,di					;gstate

	;    Erase handle of object in case it is selected
	;

	mov	ax,MSG_GO_UNDRAW_HANDLES
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GO_UNDRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock

	;    If we are being edited then let the object
	;    do any necessary invalidations to allow for
	;    object specific optimizations.
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_tempState,mask GOTM_EDITED
	jz	invalidate

destroy:
	mov	di,dx
	call	GrDestroyState

	.leave
	ret

invalidate:
	call	GrObjOptInvalidate
	jmp	destroy

GrObjVisGuardianBeginEditGeometryCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianEndEditGeometryCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform some common functionality for the methods
		the do geometry manipulations on a grobject

CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - GrObject

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianEndEditGeometryCommon		proc	far
	uses	ax,di,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>


	;    Get gstate to pass with handle drawing messages
	;

	mov	di,BODY_GSTATE
	call	GrObjCreateGState
	mov	dx,di					;gstate

	;    Redraw handles of object if it is selected
	;

	mov	ax,MSG_GO_DRAW_HANDLES
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GO_DRAW_EDIT_INDICATOR
	call	ObjCallInstanceNoLock

	;    If we are being edited then let the object
	;    do any necessary invalidations to allow for
	;    object specific optimizations.
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_tempState,mask GOTM_EDITED
	jz	invalidate

destroy:
	mov	di,dx
	call	GrDestroyState

	.leave
	ret

invalidate:
	call	GrObjOptInvalidate
	jmp	destroy

GrObjVisGuardianEndEditGeometryCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianGetVisWardOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return OD of vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

RETURN:		
		cx:dx - od
	
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
	srs	5/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianGetVisWardOD	method dynamic GrObjVisGuardianClass, 
						MSG_GOVG_GET_VIS_WARD_OD
	.enter

	movdw	cxdx,ds:[di].GOVGI_ward

	.leave
	ret
GrObjVisGuardianGetVisWardOD		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianRecreateCachedGStates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass message onto ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

RETURN:		
		nothing

	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianRecreateCachedGStates	method dynamic GrObjVisGuardianClass, 
						MSG_GO_RECREATE_CACHED_GSTATES
	.enter

	mov	ax,MSG_VIS_RECREATE_CACHED_GSTATES
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjVisGuardianRecreateCachedGStates		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianRoundOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Round width and height so that the OBJECT dimensions
		can match up with the interger vis bounds of the ward

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
	srs	9/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianRoundOBJECTDimensions		proc	far
	uses	ax,bx,cx,dx
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	call	GrObjGetNormalOBJECTDimensions
	rndwwf	dxcx
	rndwwf	bxax
	clr	ax,cx
	call	GrObjSetNormalOBJECTDimensions

	.leave
	ret
GrObjVisGuardianRoundOBJECTDimensions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianQuickTransferTakeMouseGrabIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decides if this VisGuardian object should take the
		mouse grab.  This is called during a quick transfer when
		the body has the grab but there is also an object within
		the body that has the target exclusive.

CALLED BY:	MSG_GO_QUICK_TRANSFER_TAKE_MOUSE_GRAB_IF_POSSIBLE
PASS:		*ds:si	= GrObjVisGuardianClass object
		ds:di	= GrObjVisGuardianClass instance data
		ds:bx	= GrObjVisGuardianClass object (same as *ds:si)
		es 	= segment of GrObjVisGuardianClass
		ax	= message #
		ss:bp	= LargeMouseData
		^lcx:dx	= optr to the owner of the Quick Transfer Object
		
RETURN: carry:	SET	- Object was eligible and mouse was grabbed.
		CLEAR	- Object was not eligible, mouse grab was not changed.

DESTROYED:	ax
SIDE EFFECTS:	
	May take mouse grab.
	NOT TO BE CALLED WITH MF_STACK.

PSEUDO CODE/STRATEGY:
	1) Check if this object's VisWard is the owner of the quick transfer
	   object.
	2) Check to see if the mouse's position is inside our bounds.

        If both of these are true, then take the mouse grab.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianQuickTransferTakeMouseGrabIfPossible	method dynamic \
			    GrObjVisGuardianClass, 
			    MSG_GO_QUICK_TRANSFER_TAKE_MOUSE_GRAB_IF_POSSIBLE
	uses	cx, dx, bp
	.enter
	
	; Check to see if the VisWard of this guardian is the owner of the
	; quick transfer object.
	cmpdw	ds:[di].GOVGI_ward, cxdx
	clc
	jne	exit					; not affected by C
	
	; Check to see if the mouse point is inside my bounds!
	; Will return false if this object is the floater.
	mov	bx, bp
	lea	bp, ss:[bp].LMD_location
	mov	ax, MSG_GO_IS_POINT_INSIDE_OBJECT_BOUNDS
	mov	dx, size PointDWFixed
	call	ObjCallInstanceNoLock
	mov	bp, bx
	
	jnc	exit					; not in bounds (clc)
	
	; Okay.. we can now take the grab!  Cool.
	mov	ax, MSG_GO_GRAB_MOUSE
	call	ObjCallInstanceNoLock
	
	; SUCCESS!
	stc
	
exit:
	.leave
	ret
	
GrObjVisGuardianQuickTransferTakeMouseGrabIfPossible	endm


GrObjVisGuardianCode	ends

GrObjStyleSheetCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjVisGuardianStyleCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Forwards any MSG_META_STYLED_OBJECT_* messages to the
		appropriate object(s).

Pass:		*ds:si - GrObjVisGuardian object
		ds:di - GrObjVisGuardian instance

		ax - MSG_META_STYLED_OBJECT_* (except RECALL_STYLE)

		cx,dx,bp - data

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianStyleCommon	method dynamic	GrObjVisGuardianClass, 
			MSG_META_STYLED_OBJECT_REQUEST_ENTRY_MONIKER,
			MSG_META_STYLED_OBJECT_UPDATE_MODIFY_BOX,
			MSG_META_STYLED_OBJECT_MODIFY_STYLE,
			MSG_META_STYLED_OBJECT_DEFINE_STYLE,
			MSG_META_STYLED_OBJECT_REDEFINE_STYLE,
			MSG_META_STYLED_OBJECT_SAVE_STYLE,
			MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET,
			MSG_META_STYLED_OBJECT_DESCRIBE_STYLE,
			MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS,
			MSG_META_STYLED_OBJECT_APPLY_STYLE,
			MSG_META_STYLED_OBJECT_RETURN_TO_BASE_STYLE,
			MSG_META_STYLED_OBJECT_DELETE_STYLE
	.enter

	push	ax, cx, dx, bp
	movdw	cxdx, ss:[bp]
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
	jnc	checkWard

	;
	; It's a grobj style message; call the super class
	;
	mov	di, segment GrObjVisGuardianClass
	mov	es, di
	mov	di, offset GrObjVisGuardianClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret

checkWard:
	push	ax, cx, dx, bp
	movdw	cxdx, ss:[bp]
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard
	pop	ax, cx, dx, bp
	jnc	done

	;
	;  The style message is intended for the ward
	;
	clr	di
	call	GrObjVisGuardianMessageToVisWard
	jmp	done
GrObjVisGuardianStyleCommon	endm


GrObjStyleSheetCode	ends


GrObjDrawCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianMessageToVisWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to vis ward

CALLED BY:	INTERNAL
		GrObjVisGuardianSendGrObjMouseMessageToVisWard		

PASS:		
		*ds:si - object
		ax - message
		cx,dx,bp - other data with message
		di - MessageFlags

RETURN:		
		if no vis ward return
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
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianMessageToVisWard		proc	far
	class	GrObjVisGuardianClass
	uses	bx,si,di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject	>

	;    If no ward, then return with zero flag set
	;

	GrObjDeref	si,ds,si
	mov	bx,ds:[si].GOVGI_ward.handle
	tst	bx
	jz	done

	mov	si,ds:[si].GOVGI_ward.chunk
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage

	;    Clear zero flag to signify message being sent
	;

	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret

GrObjVisGuardianMessageToVisWard		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianOptApplyOBJECTToVISTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSYS:	Apply transformation from OBJECT coordinate system to
		the VIS to OBJECT coordinate system taking into
		account the GOVGF_APPLY_OBJECT_TO_VIS_TRANSFORM bit

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object
		dx - gstate

RETURN:		
		dx - gstate with transform applied

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			opt bit not set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianOptApplyOBJECTToVISTransform		proc	far
	class	GrObjVisGuardianClass
	uses	di
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	GrObjDeref	di,ds,si
	test	ds:[di].GOVGI_flags, mask GOVGF_APPLY_OBJECT_TO_VIS_TRANSFORM
	jnz	send

	call	GrObjVisGuardianApplyOBJECTToVISTransform

done:
	.leave
	ret

send:
	push	ax
	mov	ax,MSG_GOVG_APPLY_OBJECT_TO_VIS_TRANSFORM
	call	ObjCallInstanceNoLock
	pop	ax
	jmp	done

GrObjVisGuardianOptApplyOBJECTToVISTransform		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianApplyOBJECTToVISTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Apply transformation from OBJECT coordinate system to
	the VIS coordinate system
	
	This will transform VIS coordinates into OBJECT coordinates

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		dx - gstate

RETURN:		
		dx - gstate with transform applied
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		The goal is to create a transformation to transform
		the vis bounds into a rectangle with the same dimensions
		as the object bounds with its center a 0,0.

		This default handler does the following
		A scale factor is calculated from the vis bounds
		to the object dimensions and then applied. Then 
		the center of the vis bounds is translated to 0,0

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This method is not dynamic, so the passed 
		parameters are more limited and you must be careful
		what you destroy.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianApplyOBJECTToVISTransform method  GrObjVisGuardianClass, 
				MSG_GOVG_APPLY_OBJECT_TO_VIS_TRANSFORM

	uses	ax,bx,cx,bp,di
	.enter

	mov	di,dx					;gstate

	;    Calc scale factor from vis bounds to object dimensions
	;    and apply it if both not 1.0
	;
	
	call	GrObjVisGuardianCalcScaleFactorVISToOBJECT
	jc	translate

	call	GrApplyScale


translate:
	;    Calc translation, (- center), and apply it
	;

	push	di					;gstate
	call	GrObjVisGuardianGetWardWWFixedCenter
	negwwf	dxcx
	negwwf	bxax
	pop	di					;gstate
	call	GrApplyTranslation
	mov	dx,di					;gstate

	.leave
	ret
GrObjVisGuardianApplyOBJECTToVISTransform		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianApplySPRITEOBJECTToVISTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Apply transformation from SPRITEOBJECT coordinate system to
	the VIS coordinate system
	
	This will transform VIS coordinates into SPRITEOBJECT coordinates

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		dx - gstate

RETURN:		
		dx - gstate with transform applied
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		The goal is to create a transformation to transform
		the vis bounds into a rectangle with the same dimensions
		as the object bounds with its center a 0,0.

		This default handler does the following
		A scale factor is calculated from the vis bounds
		to the object dimensions and then applied. Then 
		the center of the vis bounds is translated to 0,0

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This method is not dynamic, so the passed 
		parameters are more limited and you must be careful
		what you destroy.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianApplySPRITEOBJECTToVISTransform method  dynamic \
	GrObjVisGuardianClass, MSG_GOVG_APPLY_SPRITE_OBJECT_TO_VIS_TRANSFORM

	uses	ax,cx,bp
	.enter

	mov	di,dx					;gstate

	;    Calc scale factor from vis bounds to object dimensions
	;    and apply it if both not 1.0
	;
	
	call	GrObjVisGuardianCalcScaleFactorVISToSPRITEOBJECT
	jc	translate

	call	GrApplyScale


translate:
	;    Calc translation, (- center), and apply it
	;

	push	di					;gstate
	call	GrObjVisGuardianGetWardWWFixedCenter
	negwwf	dxcx
	negwwf	bxax
	pop	di					;gstate
	call	GrApplyTranslation
	mov	dx,di					;gstate

	.leave
	ret
GrObjVisGuardianApplySPRITEOBJECTToVISTransform		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianCalcScaleFactorVISToOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate scale factor from vis wards vis bounds
		to object dimensions of guardian

CALLED BY:	INTERNAL
		GrObjVisGuardianApplyOBJECTToVISTransform
		BitmapGuardianGainedEditGrab

PASS:		
		*ds:si - GrObjVisGuardian

RETURN:		
		dx:cx - WWFixed x scale factor
		bx:ax - WWFixed y scale factor

		stc - if both scale factors are 1.0
			

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL_SIZE
		as it is called for drawing and for each mouse event

		Common cases:
			Vis bounds equal object dimensions

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianCalcScaleFactorVISToOBJECT		proc	far
	class	GrObjVisGuardianClass

	uses	di,si
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	GrObjDeref	di,ds,si
	tst	ds:[di].GOI_normalTransform
	jz	noNormalTransform

	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjVisGuardianCalcScaleFactorVISToDimensions

done:
	.leave
	ret

noNormalTransform:
	;    There is no normalTransform so just return the scale factor
	;    as zero.
	;

	clr	ax,bx,cx,dx			;clears carry
	stc
	jmp	done

GrObjVisGuardianCalcScaleFactorVISToOBJECT		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianCalcScaleFactorVISToSPRITEOBJECT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate scale factor from vis wards vis bounds
		to sprite object dimensions of guardian

CALLED BY:	INTERNAL
		GrObjVisGuardianApplySPRITE_OBJECTToVISTransform

PASS:		
		*ds:si - GrObjVisGuardian

RETURN:		
		dx:cx - WWFixed x scale factor
		bx:ax - WWFixed y scale factor

		stc - if both scale factors are 1.0
			

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL_SIZE
		as it is called for drawing and for each mouse event during
		a move or resize

		Common cases:
			Vis bounds equal object dimensions

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianCalcScaleFactorVISToSPRITEOBJECT		proc	far
	class	GrObjVisGuardianClass

	uses	di,si
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	GrObjDeref	di,ds,si
	tst	ds:[di].GOI_spriteTransform
	jz	noSpriteTransform

	CallMod	GrObjGetSpriteOBJECTDimensions
	call	GrObjVisGuardianCalcScaleFactorVISToDimensions

done:
	.leave
	ret

noSpriteTransform:
	;    There is no spriteTransform so just return the scale factor
	;    as zero.
	;

	clr	ax,bx,cx,dx			;clears carry
	stc
	jmp	done

GrObjVisGuardianCalcScaleFactorVISToSPRITEOBJECT		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianCalcScaleFactorVISToDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate scale factor from vis ward's vis bounds
		to passed dimensions

CALLED BY:	INTERNAL
		GrObjVisGuardianCalcScaleFactorVISToSPRITE
		GrObjVisGuardianCalcScaleFactorVISToOBJECT

PASS:		
		*ds:si - GrObjVisGuardian
		dxcx - WWFixed x dimension
		bxax - WWFixed y dimension

RETURN:		
		dx:cx - WWFixed x scale factor
		bx:ax - WWFixed y scale factor

		stc - if both scale factors are 1.0
			

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL_SIZE
		as it is called for drawing and for each mouse event

		Common cases:
			Vis bounds equal object dimensions

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianCalcScaleFactorVISToDimensions		proc	far
	class	GrObjVisGuardianClass

objectWidth	local	WWFixed

	uses	di,si
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject		>

	movwwf	objectWidth, dxcx
	call	GrObjVisGuardianGetWardSize

	;
	;  If either vis dimension is zero:
	;	actually, we want to stuff the Ward's Size such that
	;	that direction's transform is 1

	jcxz	fixFirst	
checkOther:
	tst	dx
	jz	fixSecond


continue:	
	;    Check for vis bounds equaling object dimensions
	;

	cmp	bx,dx					;height ints
	jne	doDivide
	cmp	objectWidth.WWF_int,cx
	jne	doDivide
	tst	ax					;object height frac
	jnz	doDivide
	tst	objectWidth.WWF_frac
	jnz	doDivide

	;    Set both scale factors to 1.0 and flag nice results
	;

	mov	cx,1
	mov	dx,cx
	clr	ax, bx
	stc

done:
	.leave
	ret

fixFirst:
	mov	cx,bx		; if Ward's size was zero, stuff the
				; int part of the passed coord into
				; the size so we get a scale of 1
	jmp	checkOther

fixSecond:
	mov	dx,objectWidth.WWF_int	; same as above except in
					; other dimension
	jmp	continue

doDivide:
	;   Divide object width and height by VIS width and height
	;

	push	cx					;VIS width int
	xchg	dx,bx			;OBJECT height int, VIS height int
	mov_tr	cx,ax					;OBJECT height frac
	clr	ax					;VIS height frac
	call	GrSDivWWFixed				;calc y scale factor
	pop	bx					;VIS width int
	push	dx,cx					;y scale factor
	movwwf	dxcx,objectWidth
	call	GrSDivWWFixed				;calc x scale factor
	pop	bx,ax					;y scale factor
	clc
	jmp	done
GrObjVisGuardianCalcScaleFactorVISToDimensions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianDrawFGArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the visual ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

		cl - DrawFlags
		dx - gstate
		bp - GrObjDrawFlags
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
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianDrawFGArea	method dynamic GrObjVisGuardianClass, 
						MSG_GO_DRAW_FG_AREA,
						MSG_GO_DRAW_FG_AREA_HI_RES,
						MSG_GO_DRAW_CLIP_AREA,
						MSG_GO_DRAW_CLIP_AREA_HI_RES
						
	.enter

	mov	di,dx					;gstate
	call	GrSaveTransform
	call	GrObjVisGuardianOptApplyOBJECTToVISTransform

	;   Send draw message to vis ward
	;

	push	cx,dx,bp				;DrawFlags,gstate,GrObjDrawFlags 
	test	bp, mask GODF_DRAW_OBJECTS_ONLY
	jnz	foolVisObjects
continue:
	mov	bp,dx					;gstate
	mov	di,mask MF_FIXUP_DS
	mov	ax, MSG_VIS_DRAW
	call	GrObjVisGuardianMessageToVisWard
	pop	cx,dx,bp				;DrawFlags,gstate,GrObjDrawFlags 

	;    Restore gstate transformation
	;

	mov	di,dx					;gstate
	call	GrRestoreTransform

	.leave
	ret

foolVisObjects:
	;    If we are supposed to only draw the objects prevent the vis objects
	;    from drawing their selections and such by passing the print flag.
	;	

	ornf	cl,mask DF_PRINT
	jmp	continue

GrObjVisGuardianDrawFGArea		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianGetWardWWFixedCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the WWFixed center of the vis wards vis bounds.
		This routine can be used instead of 
		MSG_GV_GET_WWFIXED_CENTER for speed purposes.

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - GrObjVisGuardian

RETURN:		
		dx:cx - WWFixed x of center
		bx:ax - WWFixed y of center

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
	srs	8/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianGetWardWWFixedCenter		proc	far
	class	VisClass
	uses	si,ds,bp
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject			>

	.warn	-private
	GrObjDeref	si,ds,si	
	movdw	bxsi,ds:[si].GOVGI_ward
	tst	bx
	jz	bummer
	.warn	+private

	push	bx					;ward handle
	call	ObjLockObjBlock
	mov	ds,ax

	mov	si,ds:[si]
	add	si,ds:[si].Vis_offset

	;    (width)/2 + left
	;

	mov	dx,ds:[si].VI_bounds.R_right
	mov	bx,ds:[si].VI_bounds.R_left
	sub	dx,bx					;width int
	clr	cx					;width frac
	sar	dx,1					;width/2 int
	rcr	cx,1					;width/2 frac
	add	dx,bx					;width/2 + left

	;    (height)/2 + top
	;

	mov	bp,ds:[si].VI_bounds.R_bottom
	mov	bx,ds:[si].VI_bounds.R_top
	sub	bp,bx					;height int
	clr	ax					;height frac
	sar	bp,1					;height/2 rcr
	rcr	ax,1					;height/2 frac
	add	bp,bx					;height/2 + top

	pop	bx					;ward handle
	call	MemUnlock

	mov	bx,bp
done:
	.leave
	ret

bummer:
	;    Hopefully this won't cause any trouble. This situation
	;    occurs when the text object decides to send out messages
	;    while it is handling MSG_META_FINAL_OBJ_FREE.
	;

	mov	dx,10
	mov	bx,dx
	clrdw	axcx
	jmp	done

GrObjVisGuardianGetWardWWFixedCenter		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianGetWardSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the size of the vis bounds of the ward
		This routine can be used instead of 
		MSG_VIS_GET_SIZE for speed purposes.

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - GrObjVisGuardian

RETURN:		cx -- width of object
		dx -- height of object

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
	srs	8/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianGetWardSize		proc	far
	class	GrObjVisGuardianClass
	uses	ax,si,ds,bx
	.enter

EC <	call	ECGrObjVisGuardianCheckLMemObject			>

	GrObjDeref	si,ds,si	
	movdw	bxsi,ds:[si].GOVGI_ward
	tst	bx
	jz	bummer
	call	ObjLockObjBlock
	mov	ds,ax

	call	VisGetSize

	call	MemUnlock

done:
	.leave
	ret

bummer:
	;    Hopefully this won't cause any trouble. This situation
	;    occurs when the text object decides to send out messages
	;    while it is handling MSG_META_FINAL_OBJ_FREE.
	;

	mov	cx,10
	mov	dx,cx
	jmp	done
GrObjVisGuardianGetWardSize		endp 



GrObjDrawCode	ends

GrObjAlmostRequiredCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianAfterAddedToBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent to object just after it is added to the body
		Set guardian link in vis ward
		Mark the vis object as realized so it can draw and
		set an upward link to the body. This is needed for 
		fuping characters and such.

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
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianAfterAddedToBody	method dynamic GrObjVisGuardianClass, 
						MSG_GO_AFTER_ADDED_TO_BODY
	uses	cx,dx,bp
	.enter

	mov	di,offset GrObjVisGuardianClass
	CallSuper	MSG_GO_AFTER_ADDED_TO_BODY

	push	si				;guardian chunk
	GrObjGetBodyOD
	mov	cx,bx				;body handle
	mov	dx,si				;body chunk
	pop	si				;guardian chunk
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GV_SET_REALIZED_AND_UPWARD_LINK
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
GrObjVisGuardianAfterAddedToBody		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianBeforeRemovedFromBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent to object just before it is removed from body.
		Remove vis ward visually from body.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisGuardianClass

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
	srs	1/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGuardianBeforeRemovedFromBody	method dynamic GrObjVisGuardianClass, 
						MSG_GO_BEFORE_REMOVED_FROM_BODY
	.enter

	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GV_CLEAR_REALIZED_AND_UPWARD_LINK
	call	GrObjVisGuardianMessageToVisWard

	mov	ax,MSG_GO_BEFORE_REMOVED_FROM_BODY
	mov	di,offset GrObjVisGuardianClass
	CallSuper	MSG_GO_BEFORE_REMOVED_FROM_BODY

	.leave
	ret
GrObjVisGuardianBeforeRemovedFromBody		endm

GrObjAlmostRequiredCode	ends


GrObjRequiredInteractiveCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGuardianPARENTPointForEdit
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
GrObjVisGuardianPARENTPointForEdit	method dynamic GrObjVisGuardianClass, 
					MSG_GO_EVALUATE_PARENT_POINT_FOR_EDIT
	.enter

	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION
	call	ObjCallInstanceNoLock

	call	GrObjCanEdit?
	jnc	cantEdit

done:
	.leave
	ret

cantEdit:
	;   Object can't be edited, so evaluate as none but leave the 
	;   notes intact.
	;

	mov	al,EVALUATE_NONE
	jmp	done

GrObjVisGuardianPARENTPointForEdit		endm

GrObjRequiredInteractiveCode	ends






if	ERROR_CHECK
GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECGrObjVisGuardianCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an GrObjVisGuardianClass or one
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
ECGrObjVisGuardianCheckLMemObject		proc	far
	uses	es,di
	.enter
	pushf	
	mov	di,segment GrObjVisGuardianClass
	mov	es,di
	mov	di,offset GrObjVisGuardianClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_OF_CORRECT_CLASS
	popf
	.leave
	ret
ECGrObjVisGuardianCheckLMemObject		endp

GrObjErrorCode	ends
endif





