COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genClassMisc.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenClass		Gen UI object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of genClass.asm

DESCRIPTION:
	This file contains routines to implement the Gen class

	$Id: genClassMisc.asm,v 1.1 97/04/07 11:45:39 newdeal Exp $

------------------------------------------------------------------------------@

; see documentation in /staff/pcgeos/Library/User/Doc/GenClass.doc

UserClassStructures	segment resource

	;
	; Basicly a hack to avoid FIXUP_ES dying when es is the segment of the
	; class structure.
	;
	classStructuresHandle	hptr	handle UserClassStructures
	ForceRef classStructuresHandle
;	CheckHack <(offset classStructuresHandle) eq 0>

	;
	; Declare the class record for GenClass. We have a relocation routine,
	; but there are other things that need to be relocated, so don't
	; specify the HAS_RELOC flag -- Esp will generate a relocation table
	; for us.
	;
	GenClass

UserClassStructures	ends

Resident segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckGenCopyTreeArgs

DESCRIPTION:	This procedure does error checking specifically for UI
		classes which handle MSG_GEN_COPY_TREE.

CALLED BY:	utility

PASS:		ds:*si	- instance data of generic object
		bp	- CompChildFlags
		^lcx:dx - optr of generic object to add tree to, OR, if 
				dx=0, cx is ObjectBlock to add tree to
				(will not be added to a parent).

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@
if ERROR_CHECK
ECCheckGenCopyTreeArgs	proc	far	;all callers are in Build resource
	pushf

	;make sure that destination ObjectBlock is different from source

	cmp	cx, ds:[LMBH_handle]
	ERROR_Z	UI_GEN_COPY_TREE_SOURCE_AND_DEST_CANNOT_BE_SAME_BLOCK

	tst	dx			;are we attaching tree to a parent?
	jz	noParent		;skip if not...

	;we are adding this tree to a generic parent. Test optr for parent.

	call	ECCheckLMemODCXDX
	popf
	ret

noParent:
	;we are not adding this tree to a generic parent. Make sure
	;that cx is a valid ObjectBlock handle.

	push	bx
	mov	bx, cx
	call	ECCheckLMemHandle
	pop	bx
	popf
	ret
ECCheckGenCopyTreeArgs	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckForCXDXNotUsable

DESCRIPTION:	Checks to make sure that object in ^lcx:dx is NOT_USABLE

CALLED BY:	INTERNAL

PASS:
	^lcx:dx	- object to check

RETURN:
	nothing

DESTROYED:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

if	ERROR_CHECK
CheckForCXDXNotUsable	proc	far
	class	GenClass

	push	bx
	push	si
	push	ds
	mov	bx, cx
	mov	si, dx
					; Lock child
	call	ObjLockObjBlock
	mov	ds, ax			; get seg of child
	mov	di, ds:[si]
	cmp	ds:[di].Gen_offset, 0	; not built yet?
	je	GRGC_10			; if not, ok
	add	di, ds:[di].Gen_offset
			; Make sure object is marked not usable
	test	ds:[di].GI_states, mask GS_USABLE
	ERROR_NZ UI_ERROR_CAN_NOT_ADD_OR_REMOVE_OBJECT_WHILE_USABLE

GRGC_10:
	call	MemUnlock
	pop	ds
	pop	si
	pop	bx
	ret

CheckForCXDXNotUsable	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGupQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Converts incoming MSG_GEN_GUP_QUERY to specific-UI internal
		message, which we can have an efficient VisClass GUP handler
		for.  If MSG_GEN_GUP_QUERY can be eliminated (API change...)
		so can this handler.  (The specific UI uses MSG_SPEC_GUP_QUERY
		exclusively)

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_GUP_QUERY

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenGupQuery	method	GenClass, MSG_GEN_GUP_QUERY

	; Convert to specific-UI internal message
	;
	mov	ax, MSG_SPEC_GUP_QUERY
	GOTO	ObjCallInstanceNoLock

GenGupQuery	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenContinueGupQuery


DESCRIPTION:	Handler of misc GUP_QUERY methods for GenClass.
		Attempts to continue a GUP query.  This is done by first
		offering the specific master layer a shot at replying to
		the query, and if the query remains unanswered, sending
		it up the generic composite tree.

	This method forces specific building of object, & therefore shouldn't
	be done prior to setting up pre-specifically built hints, attributes,
	& for some objects, tree location.

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_GUP_INTERACTION_COMMAND,
	     MSG_GEN_GUP_ENSURE_UPDATE_WINDOW

	cx, dx, bp - data to query with

RETURN: carry - set if query has been responded to
	ax, cx, dx, bp - response data (depends on query type)

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

GenContinueGupQuery	method	GenClass, MSG_GEN_GUP_INTERACTION_COMMAND,
					MSG_GEN_GUP_ENSURE_UPDATE_WINDOW

					; Call super class (specific object),
					; to see if they want to handle query
	push	ax


	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di
	mov	di, offset GenClass
	call	ObjCallSuperNoLock
	pop	di
	call	ThreadReturnStackSpace	; preserves flags

	jc	GCGQ_90			; if query answered, done

					; else try generic parent
	pop	ax			; Gup query method to send on
	GOTO	GenCallParent		; Will change to stack-efficient
					; version in non-EC code

GCGQ_90:
	pop	di			; fix stack (OK to destroy di)
	ret

GenContinueGupQuery	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGupFinishQuit


DESCRIPTION:	Support for quit mechanism and hierarical active list
		(MGCNLT_ACTIVE_LIST).

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_GUP_FINISH_QUIT

	cx - abort flag (non-zero for abort)
	dx - TRUE to notify parent of finished quit sequence

RETURN: nothing

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/19/92		Initial version

------------------------------------------------------------------------------@

GenGupFinishQuit	method	GenClass, MSG_GEN_GUP_FINISH_QUIT

	;
	; let superclass do default handling
	;
	push	cx, dx				; save data
	mov	ax, MSG_META_FINISH_QUIT
	mov	di, offset GenClass
	call	ObjCallSuperNoLock

	;
	; then if we want to continue up generic tree, do so
	;
	pop	cx, dx				; retreive data
	tst	dx				; notify parent?
	jz	done				; no, done
	mov	ax, MSG_GEN_GUP_FINISH_QUIT	; else, continue up
	GOTO	GenCallParent			; Will change to stack-efficient
						; version in non-EC

done:
	ret
GenGupFinishQuit	endm




Resident ends

;--------

GenUtils segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenSendToChildren -- MSG_GEN_SEND_TO_CHILDREN

DESCRIPTION:	Call all children of a generic object

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_SEND_TO_CHILDREN

	^hcx - ClassedEvent (freed by this handler)

RETURN:
	nothing

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Here's how to use this method:

	; passing registers only
	mov	ax, <methodToSendToChildren>
	mov	bx, <segmentOfClassForMethod>
	mov	si, <offsetOfClassForMethod>
	mov	cx, <dataToPassToChildInCX>
	mov	dx, <dataToPassToChildInDX>
	mov	bp, <dataToPassToChildInBP>
	mov	di, mask MF_RECORD
	call	ObjMessage		; returns event handle in di
	mov	cx, di			; cx = event handle
	mov	bx, <handleOfGenericComposite>
	mov	si, <chunkOfGenericComposite>
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	mov	di, <MessageFlags>
	call	ObjMessage

	; passing stack data
	<setup stack data>
	mov	ax, <methodToSendToChildren>
	mov	bx, <segmentOfClassForMethod>
	mov	si, <offsetOfClassForMethod>
	mov	cx, <dataToPassToChildInCX>
	mov	dx, <sizeOfStackData>
	mov	bp, <offsetToStackData>
	mov	di, mask MF_STACK or mask MF_RECORD
	call	ObjMessage		; returns event handle in di
	mov	cx, di			; cx = event handle
	mov	bx, <handleOfGenericComposite>
	mov	si, <chunkOfGenericComposite>
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	mov	di, <MessageFlags>	; MF_STACK not needed here!
	call	ObjMessage

	Note that since a classed event needs to be created, if using stack
	data, that data should not be too large.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@

GenGenSendToChildren	method	GenClass, MSG_GEN_SEND_TO_CHILDREN
	push	cx			; save event
	;
	; push ObjCompProcessChildren parameters
	;
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset GI_link	; Pass offset to LinkPart
	push	bx
	mov	bx, SEGMENT_CS		; use our callback routines
	push	bx
	mov	bx, offset GGSTC_callback
	push	bx

	mov	bx, cx
	push	si
	call	ObjGetMessageInfo	;Get stored "class" into dx:bp
	mov	dx, cx
	mov	bp, si
	pop	si
	mov	cx, bx			;Pass event in cx

			on_stack di bx bx bx bx cx retf
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
	;
	; after calling all the appropriate children, free the classed event
	;
	pop	bx			; restore classed event
	call	ObjFreeMessage
	ret
GenGenSendToChildren	endm

GGSTC_callback	proc	far
	mov	bx, cx			; bx = classed event
	tst	dx
	jz	sendEvent
	push	es
	mov	es, dx
	mov	di, bp
	call	ObjIsObjectInClass	; is child of correct class?
	pop	es
	jnc	noSend			; nope, don't send to this child
sendEvent:
	push	ax, cx, dx, bp		; save params for next child
	mov	cx, ds:[LMBH_handle]	; cx:si = this child
	call	MessageSetDestination	; set destination to this object
					; preserve event for next child
	mov	di, mask MF_CALL or mask MF_RECORD or \
			mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	MessageDispatch		; dispatch event to this child
	pop	ax, cx, dx, bp		; retreive params for next child

noSend:
	clc				; continue calling children
	ret
GGSTC_callback	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenSendClassedEvent

DESCRIPTION:

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_META_SEND_CLASSED_EVENT

	^hcx	- ClassedEvent
	dx	- TravelOption

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/91		Initial version

------------------------------------------------------------------------------@

GenSendClassedEvent	method	GenClass, \
				MSG_META_SEND_CLASSED_EVENT
	cmp	dx, TO_GEN_PARENT
	je	sendToParent

	cmp	dx, TO_APP_FOCUS
	jb	send
	cmp	dx, TO_APP_MODEL
	jbe	sendToApp

	cmp	dx, TO_SYS_FOCUS
	jb	send
	cmp	dx, TO_SYS_MODEL
	jbe	sendToSys

send:
	mov	di, offset GenClass
	GOTO	ObjCallSuperNoLock

sendToParent:
	call	GenFindParent
	mov	ax, MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS
	clr	di
	GOTO	FlowMessageClassedEvent

sendToApp:
	sub	dx, TO_APP_FOCUS-TO_FOCUS
	GOTO	GenCallApplication

sendToSys:
	sub	dx, TO_SYS_FOCUS-TO_FOCUS
	GOTO	UserCallSystem

GenSendClassedEvent	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenGupCallObjectOfClass

DESCRIPTION:

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_GUP_CALL_OBJECT_OF_CLASS

	^hcx	- ClassedEvent

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

GenGupCallObjectOfClass	method	GenClass, \
				MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	mov	bp, si
	call	GenFindParent
	xchg	si, bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	FlowDispatchSendOnOrDestroyClassedEvent

GenGupCallObjectOfClass	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenGupSendToObjectOfClass

DESCRIPTION:

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS

	^hcx	- ClassedEvent

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@

GenGupSendToObjectOfClass	method	GenClass, \
				MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS
	mov	bp, si
	call	GenFindParent
	xchg	si, bp
	mov	di, mask MF_FIXUP_DS
	GOTO	FlowDispatchSendOnOrDestroyClassedEvent

GenGupSendToObjectOfClass	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGupTestForObjectOfClass

DESCRIPTION:	Searches up the generic tree for an object of the class
		specified.  If found, the optr of the object is returned.

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_GUP_TEST_FOR_OBJECT_OF_CLASS

	cx:dx	- class of object to look for

RETURN: carry	- set if object found
		- clear if no object found

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@

GenGupTestForObjectOfClass	method	GenClass,
					MSG_GEN_GUP_TEST_FOR_OBJECT_OF_CLASS
	mov	es, cx
	mov	di, dx
	call	ObjIsObjectInClass	; see if object is member of class
	jc	found			; branch if so
	GOTO	GenCallParent		; otherwise, pass on to parent -- will
					; change to stack-efficient version in
					; non-EC
found:
	stc
EC <	Destroy	ax, cx, dx, bp						>
	ret
GenGupTestForObjectOfClass	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGupFindObjectOfClass

DESCRIPTION:	Searches up the generic tree for an object of the class
		specified.  If found, the optr of the object is returned.

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_GUP_FIND_OBJECT_OF_CLASS

	cx:dx	- class of object to look for

RETURN: carry	- set if object found
		- clear if no object found
	^lcx:dx - object if found, null if not found

ALLOWED_TO_DESTROY:
	ax, bp
	bx, si, di, ds, es

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@

GenGupFindObjectOfClass	method	GenClass,
					MSG_GEN_GUP_FIND_OBJECT_OF_CLASS
	mov	es, cx
	mov	di, dx
	call	ObjIsObjectInClass	; see if object is member of class
	jc	found			; branch if so
	call	GenCallParentEnsureStack	; otherwise, pass on to parent
	jc	done			; found, ^lcx:dx = object
	clr	cx			; else, return null
	mov	dx, cx
	jmp	short done

found:
	mov	cx, ds:[LMBH_handle]	; return optr
	mov	dx, si
	stc
done:
EC <	Destroy	ax, bp							>
	ret
GenGupFindObjectOfClass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGenCountChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler uses ObjCompProcessChildren to count the
		children of the passed object

 This method is guaranteed NOT to force the specific building of any object.

CALLED BY:	GLOBAL

PASS:	*ds:si - generic object

RETURN:	dx - # children

ALLOWED_TO_DESTROY:	
	ax, cx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenGenCountChildren	method	GenClass, MSG_GEN_COUNT_CHILDREN
	mov	di, OCCT_COUNT_CHILDREN
	clr	dx
	FALL_THRU	GenCallCommon
GenGenCountChildren	endm

GenCallCommon	proc	far
	class	GenClass		; Tell Esp we're a friend of GenClass
					; so we can play with instance data
			on_stack retf

	mov	ax,bp			; Pass method in ax
GenCallCommonAX	label far
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset GI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	push	di
			on_stack di bx bx bx bx retf
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
	ret

GenCallCommon	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenCallParent

DESCRIPTION:	Call parent of a generic object

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_CALL_PARENT

	^hcx - ClassedEvent to call on parent

RETURN: carry clear if no generic parent
	else carry returned from parent's method handler
	ax, cx, dx, bp - returned from parent's method handler

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenGenCallParent	method	GenClass, MSG_GEN_CALL_PARENT
	call	GenFindParent		; ^lbx:si = parent
	mov	dx, TO_SELF		; no special UI handling
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	FlowMessageClassedEvent

GenGenCallParent	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenGenSendToParent

DESCRIPTION:	Send message to parent of a generic object

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_SEND_TO_PARENT

	^hcx - ClassedEvent to send to parent

RETURN: nothing

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenGenSendToParent	method	GenClass, MSG_GEN_SEND_TO_PARENT
	call	GenFindParent		; ^lbx:si = parent
	mov	dx, TO_SELF		; no special UI handling
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	di, mask MF_FIXUP_DS
	GOTO	FlowMessageClassedEvent

GenGenSendToParent	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenCallApplication

DESCRIPTION:	Call GenApplication of a generic object

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_CALL_APPLICATION

	^hcx - ClassedEvent to call on GenApplication

RETURN: carry clear if no GenApplication found
	else, carry returned from GenApplication's method handler
	ax, cx, dx, bp - returned from GenApplication's method handler

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenGenCallApplication	method	GenClass, MSG_GEN_CALL_APPLICATION
	clr	bx
	call	GeodeGetAppObject	; ^lbx:si = GenApplication
	mov	dx, TO_SELF		; no special UI handling
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	FlowMessageClassedEvent
GenGenCallApplication	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenSendToProcess

DESCRIPTION:	Send method to process running object

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_SEND_TO_PROCESS

	^hcx - Event to send to process  (NOT a ClassedEvent, just a plain,
	       ordinary, recorded event)

RETURN: none

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenGenSendToProcess	method	GenClass, MSG_GEN_SEND_TO_PROCESS
	call	GeodeGetProcessHandle
EC <	tst	bx						>
EC <	ERROR_Z	UI_ERROR_NO_OWNING_PROCESS			>
	xchg	cx, bx			; bx = handle of event
	clr	si			; cx:si = destination (process)
	call	MessageSetDestination	; Set destination in message
	clr	di
	call	MessageDispatch
	ret
GenGenSendToProcess	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenCallSystem

DESCRIPTION:	Call UI system object

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_CALL_SYSTEM

	^hcx - ClassedEvent to call on UI system object

RETURN: carry returned from UI system object's method handler
	ax, cx, dx, bp - returned from UI system object's method handler

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenGenCallSystem	method	GenClass, MSG_GEN_CALL_SYSTEM
	push	ds
	mov	ax, segment idata
	mov	ds, ax
	mov	bx, ds:[uiSystemObj].handle	; ^lbx:si = UI system object
	mov	si, ds:[uiSystemObj].chunk
	pop	ds
	mov	dx, TO_SELF		; no special UI handling
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	FlowMessageClassedEvent

GenGenCallSystem	endm

GenUtils	ends

;
;---------------
;
		
Navigation	segment	resource

GenGenNavigateToNextField	method	GenClass, \
				MSG_GEN_NAVIGATE_TO_NEXT_FIELD
	mov	ax, MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
	GOTO	ObjCallInstanceNoLock
GenGenNavigateToNextField	endm

GenGenNavigateToPreviousField	method	GenClass, \
				MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
	mov	ax, MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD
	GOTO	ObjCallInstanceNoLock
GenGenNavigateToPreviousField	endm

GenGenNavigationQuery	method	GenClass, MSG_GEN_NAVIGATION_QUERY
	mov	ax, MSG_SPEC_NAVIGATION_QUERY
	GOTO	ObjCallInstanceNoLock
GenGenNavigationQuery	endm

Navigation	ends

;
;---------------
;

AppDetach segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDetachAbort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleans up after the detach (frees the temp chunk, and sends
		MSG_META_DETACH_ABORT off through the ACK_OD).	

CALLED BY:	GLOBAL

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax	- MSG_META_DETACH_ABORT

RETURN:		nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenDetachAbort	method	GenClass, MSG_META_DETACH_ABORT
EC <	push	ax							>
EC <	mov	cx, segment GenSystemClass	;CX:DX <- class ptr	>
EC <	mov	dx, offset GenSystemClass				>
EC <	mov	ax, MSG_META_IS_OBJECT_IN_CLASS				>
EC <	call	ObjCallInstanceNoLock					>
EC <	jc	10$							>
EC <	mov	cx, segment GenFieldClass	;CX:DX <- class ptr	>
EC <	mov	dx, offset GenFieldClass				>
EC <	mov	ax, MSG_META_IS_OBJECT_IN_CLASS				>
EC <	call	ObjCallInstanceNoLock					>
EC <	ERROR_NC UI_MSG_DETACH_ABORT_SENT_TO_INVALID_CLASS		>
EC <10$:								>
EC <	pop	ax							>
	push	ax
	mov	ax, DETACH_DATA
	call	ObjVarFindData			;ds:bx = data entry if found
	pop	ax
						;Send method off in place of
						; ACK. (method=MSG_META_DETACH_ABORT)
	jnc	exit				;If no chunk exit
	mov	dx, ds:[LMBH_handle]		;^lDX:BP - this object
	mov	bp, si
	push	bx				;save entry offset
	mov	cx, ds:[bx].DDE_callerID
	mov	si, ds:[bx].DDE_ackOD.chunk
	mov	bx, ds:[bx].DDE_ackOD.handle
	mov	di, mask MF_FORCE_QUEUE		;
	call	ObjMessage			;
	mov	si, bp				;*DS:SI <- this object
	pop	bx				;restore entry offset
	call	ObjVarDeleteDataAt		;delete it
exit:
	ret
GenDetachAbort	endm


AppDetach ends

;
;----------------------
;

LessCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets enabled state of generic object

CALLED BY:	GLOBAL

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax	- MSG_GEN_GET_ENABLED

RETURN:		carry set if enabled
		carry clear if not enabled

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenGetEnabled	method	dynamic GenClass, MSG_GEN_GET_ENABLED
	mov	al, mask GS_ENABLED
	GOTO	TestGenState
GenGetEnabled	endm

TestGenState	proc	far
	class	GenClass

	test	ds:[di].GI_states, al
	stc				; assume enabled
	jnz	done			; yes, enabled
	clc				; else, not enabled
done:
	ret
TestGenState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGetUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets usable state of generic object

CALLED BY:	GLOBAL

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax	- MSG_GEN_GET_USABLE

RETURN:		carry set if usable
		carry clear if not usable

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenGetUsable	method	dynamic GenClass, MSG_GEN_GET_USABLE
	mov	al, mask GS_USABLE
	GOTO	TestGenState
GenGetUsable	endm


COMMENT @----------------------------------------------------------------------

METHOD:		MSG_GEN_CHECK_IF_FULLY_ENABLED

DESCRIPTION:
	Tests to see if this object & all parents above it are marked as
	GS_ENABLED.  This routine is thorough, making no optimizations.
	It does NOT force the growing out of specific or visual instance
	data.

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_CHECK_IF_FULLY_ENABLED
	cx	- optimization flag required by GenCheckIfFullyEnabled.

RETURN:	carry set if fully enabled
	ax, cx, dx, bp - unchanged

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


	method	GenCheckIfFullyEnabled, GenClass, \
				MSG_GEN_CHECK_IF_FULLY_ENABLED



COMMENT @----------------------------------------------------------------------

METHOD:		MSG_GEN_CHECK_IF_FULLY_USABLE

DESCRIPTION:
	Tests to see if this object & all parents above it are marked as
	GS_USABLE.  This routine is thorough, making no optimizations.
	It does NOT force the growing out of specific or visual instance
	data.

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_CHECK_IF_FULLY_USABLE
	cx	- optimization flag required by GenCheckIfFullyUsable.

RETURN:	carry set if fully usable
	ax, cx, dx, bp - unchanged

ALLOWED_TO_DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


	method	GenCheckIfFullyUsable, GenClass, \
				MSG_GEN_CHECK_IF_FULLY_USABLE



COMMENT @----------------------------------------------------------------------

METHOD:		GenChangeAccelerator

DESCRIPTION:	Modifies the button's accelerator.  For building system menus.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_CHANGE_ACCELERATOR

		cx	- bits to clear first (the mask)
		dx	- bits to change

RETURN:		nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      	Currently only works for GenTriggers, GenDataTriggers.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/25/90		Initial version

------------------------------------------------------------------------------@

GenChangeAccelerator	method GenClass, MSG_GEN_CHANGE_ACCELERATOR
	not	cx				; invert mask
	and	ds:[di].GI_kbdAccelerator, cx	; clear the mask bits
	or	ds:[di].GI_kbdAccelerator, dx	; set bits
	ret
GenChangeAccelerator	endm


LessCommon	ends
;
;----------------
;
GenUtils segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGrabTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nukes request for grab of target exclusive if this object
		is not GA_TARGETABLE, otherwises passes request on to
		superclass

CALLED BY:	MSG_META_GRAB_TARGET_EXCL

PASS:		*ds:si - generic object
		es - segment of GenClass
		ax - MSG_META_GRAB_TARGET_EXCL

RETURN:		nothing

ALLOWED TO DESTROYED:	
		ax, bx, ch, dp
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	10/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenGrabTargetExcl	method	GenClass, MSG_META_GRAB_TARGET_EXCL
	test    ds:[di].GI_attrs, mask GA_TARGETABLE
	jz	done

	mov	di, offset GenClass
	GOTO	ObjCallSuperNoLock

done:
	Destroy	ax, bx, ch, bp
	ret
GenGrabTargetExcl	endm

GenUtils	ends

;
;-------------
;

IniFile	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenMetaLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	High-level routine to load options for this object

PASS:		*ds:si	= GenClass object
		ax	= message

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenMetaLoadOptions	method	dynamic	GenClass, MSG_META_LOAD_OPTIONS
	mov	bp, MSG_GEN_LOAD_OPTIONS
	FALL_THRU	LoadOrSaveOptions
GenMetaLoadOptions	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadOrSaveOptions

DESCRIPTION:	Generate GenOptionsParams and send message

CALLED BY:	GenAttach, GenMetaSaveOptions

PASS:		*ds:si - object
		ax	- MSG_META_[LOAD, SAVE]_OPTIONS
		bp	- MSG_GEN_[LOAD, SAVE]_OPTIONS

RETURN:		none

DESTROYED:	ax,bx,cx,dx,si,di,es,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91	Initial version
	Don	 5/20/92	Added passing message down generic tree

------------------------------------------------------------------------------@
LoadOrSaveOptions	proc	far
	class	GenClass

	; is there a key ?

	mov_tr	dx, ax				;dx = meta message
	mov	ax, ATTR_GEN_INIT_FILE_KEY
	call	ObjVarFindData
	jnc	done

	; construct GenOptionsParams structure to pass ourself

	push	dx				;save the meta message
	mov_tr	ax, bp				;ax = gen message
	sub	sp, size GenOptionsParams
	mov	bp, sp

	push	si
	mov	si, bx				;ds:si = source
	segmov	es, ss
	lea	di, ss:[bp].GOP_key
	mov	cx, INI_CATEGORY_BUFFER_SIZE / 2
	rep movsw
	pop	si

		CheckHack <offset GOP_category eq 0>
	mov	cx, ss
	mov	dx, bp				;cx:dx = buffer
	call	UserGetInitFileCategory		;get category

	call	ObjCallInstanceNoLock		;call get load/save message

	add	sp, size GenOptionsParams
	pop	dx				;restore the meta message

done:
	; Check to see if children are present.   If not, we're out of here.
	; If so, check for ATTR_GEN_INIT_FILE_PROPAGATE_TO_CHILDREN.
	; Pass the message onto our children, if we find an
	; ATTR_GEN_INIT_FILE_PROPAGATE_TO_CHILDREN
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GI_comp.CP_firstChild.handle
	jz	exit

	mov	ax, ATTR_GEN_INIT_FILE_PROPAGATE_TO_CHILDREN
	call	ObjVarFindData
	jnc	exit		
	mov_tr	ax, dx				;ax = meta message
	call	GenSendToChildren
exit:
	ret

LoadOrSaveOptions	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenMetaSaveOptions -- MSG_META_SAVE_OPTIONS for GenClass

DESCRIPTION:	Generate structure for saving options and call
		MSG_GEN_SAVE_OPTIONS

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/12/91	Initial version

------------------------------------------------------------------------------@
GenMetaSaveOptions	method dynamic	GenClass, MSG_META_SAVE_OPTIONS

	mov	bp, MSG_GEN_SAVE_OPTIONS
	GOTO	LoadOrSaveOptions
GenMetaSaveOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenGetIniCategory -- MSG_META_GET_INI_CATEGORY for GenClass

DESCRIPTION:	Get the .ini file category

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - The message

	cx:dx - buffer for .ini category (0 to just get flags)

RETURN:
	cx:dx - filled
	carry - set if filled in

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/26/91		Initial version

------------------------------------------------------------------------------@
GenGetIniCategory	method dynamic	GenClass, MSG_META_GET_INI_CATEGORY
	mov	bx, ATTR_GEN_INIT_FILE_CATEGORY
	FALL_THRU	GGetAttrCommon
	;	NOTE:  In non-EC, *must* be jump/fallthru -- GGetAttrCommon uses
	;	GenGotoParentTailRecurse to keep a lid on stack usage.

GenGetIniCategory	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGetAttrCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to get get attr stuff for Gen objects

		NOTE:  In non-EC, *must* be jumped to from end of method
		handler -- we use GenGotoParentTailRecurse to keep a lid
		on stack usage.

CALLED BY:	GenGetHelpFile(), GenGetIniCategory()
PASS:		*ds:si - GenClass object
		ax - message to pass
		bx - vardata to check for locally
		es - seg addr of GenClass
		cx:dx - ptr to buffer
RETURN:		cx:dx - filled in if handled
		carry - set if filled in
DESTROYED:	ax, es, di, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 2/92	broken out from GenGetIniCategory()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGetAttrCommon		proc	far

	;
	; Init string to NULL, in case not found.
	;
	push	ds				;save object segment
	mov	ds, cx
	mov	di, dx				;ds:di <- buffer
	mov	{char} ds:[di], 0
	pop	ds				;ds <- seg addr of object

; Nope.  Specific UI doesn't use this ability now, & will not be able to in
; the future.  One less message, many more to go.  -- Doug 1/93
;	;
;	; See if superclass wants to handle it
;	;
;	push	ax				;save message
;	mov	di, offset GenClass
;	call	ObjCallSuperNoLock		;returns carry
;	pop	ax				;ax <- message
;
;	;
;	; See if handled by superclass
;	;
;	jc	done				;branch if handled

	;
	; Look to see if we have stuff locally
	;
	push	ax				;save message
	mov	ax, bx				;ax <- var data to find
	call	ObjVarFindData
	pop	ax				;ax <- message
	jnc	notFound			;branch if no var data
	;
	; The information exists locally -- copy into the buffer
	;
	push	cx
	mov	si, bx				;ds:si <- source
	mov	es, cx
	mov	di, dx				;es:di <- dest
	VarDataSizePtr	ds, si, cx		;cx <- size of string
	push	di
	rep	movsb				;copy me jesus
	pop	di
	call	RemoveTrailingSpacesFromHelpFileName
	pop	cx
	stc					;carry <- handled
	ret

notFound:
	;
	; Finally, pass on to our generic parent to handle
	;
EC <	GOTO	GenCallParent						    >
NEC <	GOTO	GenGotoParentTailRecurse	; Use recursive version	    >
						; directly, as we won't be
						; detected as being in a
						; method handler.

GGetAttrCommon		endp

;
; es:di = help file name
;
RemoveTrailingSpacesFromHelpFileName	proc	far
	uses	ax, cx, dx, di
	.enter
	mov	dx, di
	mov	cx, -1
	mov	al, 0
	repne	scasb				;es:di = points past null
	dec	di				;es:di = null at end
	cmp	di, dx				;null string?
	je	done
spaceLoop:
	dec	di
	cmp	di, dx				;in case all spaces
	jb	spaceDone
	cmp	{char}es:[di], C_SPACE
	je	spaceLoop
	inc	di				;es:di = space
spaceDone:
	mov	{char}es:[di], C_NULL
done:
	.leave
	ret
RemoveTrailingSpacesFromHelpFileName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGetHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the help file for an object

CALLED BY:	MSG_META_GET_HELP_FILE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GenClass
		ax - the message
RETURN:		cx:dx - filled
		carry - set if filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

helpfileKey	char "helpfile", 0

; NOTE! Must be in IniFile resource in order to GOTO GGetAttrCommon

GenGetHelpFile		method dynamic GenClass, MSG_META_GET_HELP_FILE
	;
	; See if there is a flag specifying we should look in the
	; geos.ini file
	;
	mov	ax, ATTR_GEN_HELP_FILE_FROM_INIT_FILE
	call	ObjVarFindData
	jnc	notIni				;branch if flag not present
	;
	; Get the geos.ini category name to use
	;
	push	cx, dx, es
	sub	sp, INI_CATEGORY_BUFFER_SIZE
	pushdw	cxdx
	mov	cx, ss
	mov	dx, sp
	add	dx, (size word)*2		;cx:dx <- ptr to buffer
	mov	ax, MSG_META_GET_INI_CATEGORY
	call	ObjCallInstanceNoLock
	popdw	esdi				;es:di <- ptr to dest buffer
	jnc	notIniPop			;branch if no category
	;
	; See if anything exists under that category with "helpfile"
	;
	push	ds, si, bp
	movdw	dssi, cxdx			;ds:si <- ptr to category string
	mov	cx, cs
	mov	dx, offset helpfileKey		;cx:dx <- ptr to key string
	mov	bp, INI_CATEGORY_BUFFER_SIZE	;bp <- buffer size
	call	InitFileReadString
	pop	ds, si, bp
	jc	notIniPop			;branch if not found
	;
	; Clean up the stack and exit
	;
	add	sp, INI_CATEGORY_BUFFER_SIZE
	pop	cx, dx, es			;cx:dx <- ptr to buffer
	stc					;carry <- buffer filled
	ret

	;
	; There was no flag, or nothing in the geos.ini file
	; -- continue the search normally up the tree.
	;
notIniPop:
	add	sp, INI_CATEGORY_BUFFER_SIZE
	pop	cx, dx, es			;cx:dx <- ptr to buffer
notIni:
	mov	ax, MSG_META_GET_HELP_FILE
	mov	bx, ATTR_GEN_HELP_FILE

	GOTO	GGetAttrCommon			;sets carry if handled
	;
	;	NOTE:  In non-EC, *must* be jump -- GGetAttrCommon uses
	;	GenGotoParentTailRecurse to keep a lid on stack usage.

GenGetHelpFile		endm


IniFile ends

HelpControlCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenSetHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the help file for this object.

CALLED BY:	GLOBAL

PASS:		*ds:si	= GenClass object
		cx:dx	= FileLongName of help file to use
		(cx:dx *cannot* be pointing in the XIP movable code seg.)
		
RETURN:		nothing
DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	1/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenSetHelpFile	method dynamic GenClass, 
					MSG_META_SET_HELP_FILE
		
		uses	cx
		.enter
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cxdx					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; Check if given fptr is pointing to the same segment as the
	; given object.   
	;
EC <		mov	ax, es					>
EC <		mov	bx, ds					>
EC <		cmp	ax, bx					>
EC <		ERROR_E	-1					>

	;
	; Get length of given help file name
	;
		mov	es, cx
		mov	di, dx	
	;
	; help file is always SBCS string
	;
		push	di
		clr	al
		mov	cx, -1
		repne	scasb
		not	cx			; cx = length w/null
		pop	di
	;
	; append/change relevant hint
	;
		mov	ax, ATTR_GEN_HELP_FILE
		call	ObjVarAddData		
	;
	; copy over the help file name
	;

;copyHelpFile:
		segxchg	es, ds
		mov	si, di				; ds:si -> help file
		mov	di, bx				; es:di -> VarData
EC <		call	ECCheckBounds				>
		rep	movsb
	;
 	; make sure we haven't read or written off into space
	; (We must back up one "character" because the copyNString (rep...)
	; goes ONE byte/word past the end.)
	;
EC <		dec	si					>
EC <		call	ECCheckBounds				>
EC <		segmov	ds, es					>
EC <		mov	si, di					>
EC <		dec	si					>
EC <		call	ECCheckBounds				>

		.leave
		ret

GenSetHelpFile	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGetHelpType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the help type for an object tree

CALLED BY:	MSG_META_GET_HELP_TYPE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GenClass
		ax - the message
RETURN:		carry - set if handled
		dl - HelpType
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenGetHelpType		method dynamic GenClass,
						MSG_META_GET_HELP_TYPE
	;
	; See if superclass wants to handle it
	;
	mov	di, offset GenClass
	call	ObjCallSuperNoLock
	jc	done				;branch if handled
	;
	; See if we have something locally
	;
	mov	ax, ATTR_GEN_HELP_TYPE
	call	ObjVarFindData
	jnc	notFound			;branch if not found locally
	mov	dl, ds:[bx]			;dl <- HelpType
	jmp	done

	;
	; Finally, pass on to our generic parent to handle
	;
notFound:
	mov	ax, MSG_META_GET_HELP_TYPE
	call	GenCallParent
done:
	ret
GenGetHelpType		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenBringUpHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up help for this generic tree

CALLED BY:	MSG_META_BRING_UP_HELP
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GenClass
		ax - the message
RETURN:		ax - destroyed
DESTROYED:	bx, si, di, es (method handler)
		
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenBringUpHelp		method dynamic GenClass,
						MSG_META_BRING_UP_HELP
	uses	cx, dx, bp

	.enter
	;
	; First see if there is help locally
	;
	mov	ax, ATTR_GEN_HELP_CONTEXT
	call	ObjVarFindData
	jnc	noHelp				;branch if no help locally

	;
	; Bring up help
	;
	push	ds:LMBH_handle
	sub	sp, (size FileLongName)
	;
	; GUP to find the help file name
	;
	mov	ax, MSG_META_GET_HELP_FILE
	movdw	cxdx, sssp			;cx:dx <- ptr to filename buffer
	call	ObjCallInstanceNoLock
NEC <	jnc	quit				;branch if not found >
EC <	ERROR_NC HELP_NO_FILENAME_FOUND		;>
	;
	; GUP to find the help type
	;
	mov	ax, MSG_META_GET_HELP_TYPE
	call	ObjCallInstanceNoLock
NEC <	jnc	quit				;branch if help type not found>
EC <	ERROR_NC HELP_NO_HELP_TYPE_FOUND	;>
	;
	; Send off a help notification
	;
	mov	ax, ATTR_GEN_HELP_CONTEXT
	call	ObjVarFindData
	mov	si, bx				;ds:si <- ptr to context name
	mov	al, dl				;al <- HelpType
	mov	di, sp
	segmov	es, ss				;es:di <- ptr to filename
	call	HelpSendHelpNotification
NEC <quit:					;>
	add	sp, (size FileLongName)
	;
	; Fix up ds in case it changed.  This will generally
	; only happen in single threaded apps, but it will
	; happen.
	;
	pop	bx				;bx <- handle of trigger's block
	call	MemDerefDS			;ds <- fixed up object segment
exit:
	.leave
	ret

	;
	; No help exists locally -- keep vupping
	;
noHelp:
	mov	ax, MSG_META_BRING_UP_HELP
	call	VisFindParent
	tstdw	bxsi
	jz	exit
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	jmp	short exit

GenBringUpHelp		endm

HelpControlCode	ends

;
;----------
;

DestroyCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenGenDestroy

DESCRIPTION:	Destroy a generic branch, closing & unlinking as necessary.

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_DESTROY

	cx	- ?
	dl	- VisUpdateMode to use when updating parent
	bp	- mask CCF_MARK_DIRTY if we want to mark the links as dirty

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

    All Kernel versions through V1.05, V1.13:

        Flag in bp is trashed before being passed down to children, resulting
	in fatal error in EC code, incorrect dirtying results in NON-EC code.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/90		Initial version

------------------------------------------------------------------------------@

GenGenDestroy	method	GenClass, MSG_GEN_DESTROY

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	; 1) Set not usable
	;
	mov	ax, MSG_GEN_SET_NOT_USABLE
	push	dx
	push	bp			; Preserve CCF_MARK_DIRTY flag
	call	ObjCallInstanceNoLock
	pop	bp
	pop	dx

	; 2) Destroy any children of this object
	;
	mov	ax, MSG_GEN_DESTROY
	call	GenSendToChildren	; Preserves bp

	; 3) Remove from generic tree.
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	GenCallParent

	; 4) Destroy object + moniker + hint chunks
	;
					; Finally, destroy the object, hints
					; & vis moniker
	mov	ax, MSG_META_OBJ_FREE	; after queue flush
	call	ObjCallInstanceNoLock

	pop	di
	call	ThreadReturnStackSpace
	ret

GenGenDestroy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDestroyAndFreeBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Destroy branch & free block.  Do in optimized fashion if
		possible.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_DESTROY_AND_FREE_BLOCK

RETURN:		carry set

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenDestroyAndFreeBlock 	method GenClass,
				MSG_GEN_DESTROY_AND_FREE_BLOCK

	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST
	mov	ss:[bp].GCNLP_optr.chunk, 0
	mov	ax, MSG_META_GCN_LIST_FIND_ITEM
	push	si, bp
	clr	bx
	call	GeodeGetAppObject
	mov	dx, size GCNListParams
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, bp
	lahf
	add	sp, size GCNListParams
	sahf
	jc	defaultApproach

	; Do specific-UI specific cleanup (get off screen, release FTVMC,
	; GCN list stuff, etc.
	;
	mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
	mov	di, offset GenClass
	call	ObjCallSuperNoLock
	jnc	defaultApproach		; if not handled, or can't optimize --
					; do standard nuke.

	; Otherwise, just unhook & nuke.
	;
	clr	bp
	call	GenRemoveDownwardLink

	jmp	short freeBlock

defaultApproach:

	; remove from parent

	mov	ax, MSG_GEN_REMOVE
	mov	dl, VUM_NOW
	clr	bp
	call	ObjCallInstanceNoLock

freeBlock:
	; and free the block (we do this via the queue, as there could
	; conceivably be messages (such as a
	; MSG_META_CONTENT_VIEW_WINDOW_OPENED) destined for an object in the
	; dialog.

	mov	ax, MSG_META_BLOCK_FREE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	stc			; always successful
	ret

GenDestroyAndFreeBlock 	endp

DestroyCommon	ends

