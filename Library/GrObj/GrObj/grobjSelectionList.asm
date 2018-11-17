COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj	
FILE:		objectSelectionList.asm

AUTHOR:		Steve Scholl, Jan  3, 1992

ROUTINES:
	Name			Description
	----			-----------
GrObjIsGrObjSelected?
GrObjRemoveGrObjsFromSelectionList
GrObjGetBoundsOfSelectedGrObjs
GrObjSendToSelectedGrObjs
GrObjSendToSelectedGrObjsAndEdit
GrObjSendToSelectedGrObjsAndEditAndMouseGrab
GrObjGetNumSelectedGrObjs

METHODS:
	Name			Description
	----			-----------
GrObjBecomeSelected
GrObjBecomeUnselected
GrObjGainedSelectionList
GrObjLostSelectionList
GrObjToggleSelection	

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	1/ 3/92		Initial revision


DESCRIPTION:
	
		

	$Id: grobjSelectionList.asm,v 1.1 97/04/04 18:07:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjRequiredExtInteractive2Code	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBecomeSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Tell object to join the selection list, draw it's handle ...

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		dl - HandleUpdateMode

RETURN:		
		ax

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBecomeSelected method dynamic GrObjClass, MSG_GO_BECOME_SELECTED
	uses	cx,dx,bp
	.enter

	call	GrObjCanSelect?
	jnc	undraw

EC <	cmp	dl,HandleUpdateMode				>
EC <	ERROR_AE	BAD_HANDLE_UPDATE_MODE			>

	test	ds:[di].GOI_tempState, mask GOTM_SELECTED
	jnz	handles


EC <	clr	dh						>
	mov	bp,dx				;HandleUpdateMode
	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax,MSG_GB_ADD_GROBJ_TO_SELECTION_LIST
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>


handles:
	;    If the caller requested DRAW_HANDLES_NOW and we are
	;    now actually selected, then draw the handles. This
	;    covers the case of an object that is already selected
	;    when BECOME_SELECTED is sent to it.
	;

	mov	dx,bp				;HandleUpdateMode
	cmp	dl,HUM_NOW
	jne	done
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_tempState, mask GOTM_SELECTED
	jz	done
	clr	dx				;no gstate
	mov	ax,MSG_GO_DRAW_HANDLES
	call	ObjCallInstanceNoLock


done:
	.leave
	ret

undraw:
	;    This handles a special case involving the pointer tool and
	;    interactive drawing of the handles during drag select. The
	;    Pointer code depends on the BECOME_SELECTED handler clearing
	;    the GOTM_TEMP_HANDLES.  I'm pretty sure that the handles
	;    wouldn't have been drawn nor the TEMP bit set but 
	;    I am just being robust.
	;

	clr	dx				;no gstate
	mov	ax,MSG_GO_UNDRAW_HANDLES
	call	ObjCallInstanceNoLock
	jmp	done

GrObjBecomeSelected endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCanSelect?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if object can be selected

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObj

RETURN:		
		stc - yes
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			object can be resized

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCanSelect?		proc	far
	class	GrObjClass
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject					>

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_SELECT			; clc
	jnz	done

	test	ds:[di].GOI_locks, mask GOL_SHOW			; clc
	jnz	done

	test	ds:[di].GOI_optFlags, mask GOOF_ATTRIBUTE_MANAGER	; clc
	jnz	done

	test	ds:[di].GOI_optFlags, mask GOOF_ADDED_TO_BODY		; clc
	jz	done

	test	ds:[di].GOI_optFlags, mask GOOF_IN_GROUP		; clc
	jnz	done

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID		; clc
	jnz	done

	test	ds:[di].GOI_attrFlags, mask GOAF_INSTRUCTION
	jnz	checkIfInstructionsVisible

success:
	stc

done:
	.leave
	ret

checkIfInstructionsVisible:
    	;
	; Check if instructions (annotations) are visible.  If they are not
	; visible, then they are not selectable.  We query the body for this
	; information.
	;
	push	ax
	call	GrObjGetDrawFlagsFromBody
	test	ax, mask GODF_DRAW_INSTRUCTIONS		; Carry clear
	pop	ax
	jz	done					; invisible => fail
	jmp	success					; visible => stc

GrObjCanSelect?		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGainedSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	tells the object is has gained the selection grab

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		dl - HandleUpdateMode

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
	srs	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjGainedSelectionList	method dynamic GrObjClass, 
					MSG_GO_GAINED_SELECTION_LIST
	uses	cx,dx,bp
	.enter

EC <	cmp	dl,HandleUpdateMode				>
EC <	ERROR_AE	BAD_HANDLE_UPDATE_MODE			>

	;    Since the body passes MSG_META_SUSPEND and MSG_META_UNSUSPEND
	;    onto the selected
	;    objects, if an object becomes selected while the body
	;    is already suspended then the object must match the 
	;    body's suspend count. Otherwise the object could
	;    receive unbalanced unsuspends from the body.
	;

	mov	ax,MSG_META_SUSPEND
	call	GrObjMatchSuspend

	;    Mark object as selected
	;

	mov	cl, mask GOTM_SELECTED
	clr	ch
	call	GrObjChangeTempStateBits

	;    Erase any sprite that may be floating about
	;

	mov	cx,dx				;HandleUpdateMode
	clr	dx				;no stored gstate
	mov	ax,MSG_GO_UNDRAW_SPRITE
	call	ObjCallInstanceNoLock

	;    Skip drawing handles if they will be drawn later
	;
	cmp	cx, HUM_MANUAL
	je	notify

	;    Draw handles of object
	;

	mov	ax,MSG_GO_DRAW_HANDLES		;dx=0 above (no gstate)
	call	ObjCallInstanceNoLock

notify:
	mov	cx, mask GrObjUINotificationTypes
	call	GrObjOptSendUINotification

	mov	bp,GOANT_SELECTED
	call	GrObjOptNotifyAction

	.leave
	ret
GrObjGainedSelectionList		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjLostSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	tells the object is has lost the selection grab

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
	srs	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLostSelectionList		method dynamic GrObjClass, 
					MSG_GO_LOST_SELECTION_LIST
	uses	cx,dx,bp
	.enter

	;    Send ui notification before clearing GOTM_SELECTED bit
	;    because the notification won't be sent if the bit
	;    is not set.
	;
	
	mov	cx, mask GrObjUINotificationTypes
	call	GrObjOptSendUINotification

	;   GOTM_SYS_TARGET is invalid if GOTM_SELECTED is not set
	;

	clr	cl
	mov	ch,  mask GOTM_SELECTED or mask GOTM_SYS_TARGET
	call	GrObjChangeTempStateBits

	clr	dx				;no gstate
	mov	ax,MSG_GO_UNDRAW_HANDLES
	call	ObjCallInstanceNoLock		;clear selection handles

	mov	bp,GOANT_UNSELECTED
	call	GrObjOptNotifyAction

	;    Since the body passes MSG_META_SUSPEND and MSG_META_UNSUSPEND
	;    onto the selected objects, 
	;    if an object becomes unselected while the body
	;    is already suspended then the object must match the 
	;    body's suspend count. Otherwise the object would
	;    be left suspended permanently.
	;

	mov	ax,MSG_META_UNSUSPEND
	call	GrObjMatchSuspend

	.leave
	ret
GrObjLostSelectionList		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjMatchSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the passed message to the object the number
		of times the body is suspend. 

CALLED BY:	INTERNAL
		GrObjLostSelectionList
		GrObjGainedSelectionList

PASS:		*ds:si - grobject
		ax - MSG_META_SUSPEND or MSG_META_UNSUSPEND

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
	srs	3/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjMatchSuspend		proc	far
	class	GrObjClass
	uses	cx,dx,bp
	.enter

	call	GrObjGetSuspendCountFromBody
	jcxz	done

loopSend:
	push	ax,cx					;message
	call	ObjCallInstanceNoLock
	pop	ax,cx					;message
	loop	loopSend

done:
	.leave
	ret

GrObjMatchSuspend		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjToggleSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch status of objects selection.

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
	srs	7/31/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjToggleSelection	method dynamic GrObjClass, MSG_GO_TOGGLE_SELECTION
	uses	ax,dx
	.enter

	test	ds:[di].GOI_tempState, mask GOTM_SELECTED
	jz	becomeSelected

	mov	ax,MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

becomeSelected:
	mov	ax,MSG_GO_BECOME_SELECTED
	mov	dx,HUM_NOW
	call	ObjCallInstanceNoLock
	jmp	short done

GrObjToggleSelection		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjIsGrObjSelected?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if object is selected

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - instance data of object
RETURN:		
		stc - selected
		clc - not selected

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
GrObjIsGrObjSelected?		proc	far
	class	GrObjClass
	uses	di
	.enter				

EC <	call	ECGrObjCheckLMemObject		>

	GrObjDeref 	di,ds,si
	test	ds:[di].GOI_tempState,mask GOTM_SELECTED
	jz	notSelected

	stc

done:
	.leave
	ret

notSelected:
	clc
	jmp	done

GrObjIsGrObjSelected?		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjRemoveGrObjsFromSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send GRUP METHOD to empty selection list

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - instance data of an object

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
GrObjRemoveGrObjsFromSelectionList		proc	far
	uses	ax,cx,dx,bp,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	ax,MSG_GB_REMOVE_ALL_GROBJS_FROM_SELECTION_LIST
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	.leave
	ret
GrObjRemoveGrObjsFromSelectionList		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBecomeUnselected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell object to remove itself from seelction list

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
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBecomeUnselected method dynamic GrObjClass, MSG_GO_BECOME_UNSELECTED
	uses	ax,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	test	ds:[di].GOI_tempState,mask GOTM_SELECTED
	jz	done

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax,MSG_GB_REMOVE_GROBJ_FROM_SELECTION_LIST
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody

done:
	.leave
	ret
GrObjBecomeUnselected endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetBoundsOfSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send GRUP METHOD to get selection list bounds

CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - instance data of an object
		ss:bp - RectDWord

RETURN:		
		ss:bp - RectDWord

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
GrObjGetBoundsOfSelectedGrObjs		proc	far
	uses	ax
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	ax,MSG_GB_GET_BOUNDS_OF_SELECTED_GROBJS
	mov	di,mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	mov	dx, size RectDWord
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	.leave
	ret
GrObjGetBoundsOfSelectedGrObjs		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSendToSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encapsulate message and pass event to body
		for sending to selected grobjs

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data of an object
		ax - method to send
		cx,dx,bp - other data
		di - MF_STACK if data on stack

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
GrObjSendToSelectedGrObjs		proc	far
	uses	ax,cx,dx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjCreateGrObjClassedEvent
	mov	ax,MSG_GB_SEND_CLASSED_EVENT_TO_SELECTED_GROBJS
	mov	dx,TO_SELF
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
	jz	noBody

done:
	.leave
	ret

noBody:
	mov	bx,cx
	call	ObjFreeMessage
	jmp	done

GrObjSendToSelectedGrObjs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSendToSelectedGrObjsShareData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encapsulate message and pass event to body
		for sending to selected grobjs

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data of an object
		cx - method to send
		dx,bp - other data

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
GrObjSendToSelectedGrObjsShareData		proc	far
	uses	ax,cx,di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov_tr	cx, ax						;cx <- message
	mov	ax, MSG_GB_SEND_TO_SELECTED_GROBJS_SHARE_DATA
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody

	.leave
	ret
GrObjSendToSelectedGrObjsShareData		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSendToSelectedGrObjsAndEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to selected grobjs and edit grab

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data of an object
		ax - method to send
		cx,dx,bp - other data
		di - MF_STACK if data on stack		

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
GrObjSendToSelectedGrObjsAndEdit		proc	far
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjSendToSelectedGrObjs
	ornf	di,mask MF_FIXUP_DS
	call	GrObjMessageToEdit

	.leave
	ret
GrObjSendToSelectedGrObjsAndEdit		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSendToSelectedGrObjsAndEditAndMouseGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to selected grobjs and edit grab and
		the mouse grab

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data of an object
		ax - method to send
		cx,dx,bp - other data
		di - MF_STACK if data on stack		

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
GrObjSendToSelectedGrObjsAndEditAndMouseGrab		proc	far
	uses	di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	call	GrObjSendToSelectedGrObjs
	ornf	di,mask MF_FIXUP_DS
	call	GrObjMessageToEdit
	call	GrObjMessageToMouseGrab

	.leave
	ret
GrObjSendToSelectedGrObjsAndEditAndMouseGrab		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSendToSelectedGrObjsAndEditAndMouseGrabSuspended
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to selected grobjs and edit grab and
		the mouse grab.

		This routine is mainly used when switching tools. It seemed
		bad to throw out the undo actions just because the user
		changed tools, so we ignore the undo actions before
		suspending. (suspending normally starts an undo chain
		which is ended on unsuspend).

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data of an object
		ax - method to send
		cx,dx,bp - other data
		di - MF_STACK if data on stack		

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
GrObjSendToSelectedGrObjsAndEditAndMouseGrabSuspended		proc	far
	uses	ax, di
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	push	ax
	mov	ax, MSG_GB_IGNORE_UNDO_ACTIONS_AND_SUSPEND
	clr	di
	call	GrObjMessageToBody
	pop	ax

	call	GrObjSendToSelectedGrObjsAndEditAndMouseGrab

	mov	ax, MSG_GB_UNSUSPEND_AND_ACCEPT_UNDO_ACTIONS
	clr	di
	call	GrObjMessageToBody

	.leave
	ret
GrObjSendToSelectedGrObjsAndEditAndMouseGrabSuspended		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjGetNumSelectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to body to get number of selected children

CALLED BY:	INTERNAL (UTILITY)

PASS:		
		*(ds:si) - instance data of an object

RETURN:		
		bp - number of objects

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
GrObjGetNumSelectedGrObjs		proc	far
	uses	ax,cx,dx
	.enter

EC <	call	ECGrObjCheckLMemObject				>

	mov	ax,MSG_GB_GET_NUM_SELECTED_GROBJS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	.leave
	ret
GrObjGetNumSelectedGrObjs		endp

GrObjRequiredExtInteractive2Code	ends
