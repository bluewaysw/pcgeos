COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Avoid
FILE:		avoidApp.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/93		Initial version

DESCRIPTION:
	Demonstration program for how to deal properly with becoming
	a non-detachable application on a system working in transparent-
	launch mode (such as Zoomer)

IMPORTANT:

RCS STAMP:
	$Id: avoidApp.asm,v 1.1 97/04/04 16:34:02 newdeal Exp $

------------------------------------------------------------------------------@

idata	segment
	AvoidApplicationClass
idata	ends


AppCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AvoidAppOptionsChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle change in transparent detach options

PASS:		*ds:si	- app object
		es	- segment of class
		ax 	- MSG_AVOID_APPLICATION_OPTIONS_CHANGE

		cx	- GIGI_selectedBooleans
		dx	- GIGI_indeterminateBooleans
		bp	- GIGI_modifiedBooleans

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AvoidAppOptionsChange	method	AvoidApplicationClass,
					MSG_AVOID_APP_OPTIONS_CHANGE
	test	cx, mask ABID_OPERATION_IN_PROGRESS		; Identifier
	jz	endOperation

;startOperation:
	; Since we're starting up some operation that we don't want to be
	; detached in the middle of, change our status to indicate that
	; we wish to avoid transparent detach.
	;
	mov	cx, mask AS_AVOID_TRANSPARENT_DETACH	; bit to set
	clr	dx					; nothing to clear
	jmp	short ready

endOperation:
	; Now that we're done with the background operation, allow ourselves
	; to be transparently detachable agin.
	;
	clr	cx					; nothing to set
	mov	dx, mask AS_AVOID_TRANSPARENT_DETACH	; bit to clear
ready:
	mov	ax, MSG_GEN_APPLICATION_SET_STATE
	call	UserCallApplication
	ret
AvoidAppOptionsChange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AvoidAppCallSuperAndUpdateActiveBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Intercept various messages that affect changes in the state
		we use to decided whether to have an Active dialog up or
		not, call the superclass to provide default handling, & then
		get the Active dialog on or off screen as current state
		dictates.

PASS:		*ds:si	- app object
		es	- segment of class
		ax 	- message

		nothing

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AvoidAppCallSuperAndUpdateActiveBox	method	AvoidApplicationClass,
				MSG_META_GAINED_FULL_SCREEN_EXCL,
				MSG_META_LOST_FULL_SCREEN_EXCL,
				MSG_GEN_APPLICATION_SET_STATE,
				MSG_META_DETACH

	mov	di, offset AvoidApplicationClass
	call	ObjCallSuperNoLock
	pushf
	push	ax, cx, dx, bp		; save return values
	call	AvoidAppUpdateActiveBox
	pop	ax, cx, dx, bp		; restore return values
	popf
	ret
AvoidAppCallSuperAndUpdateActiveBox	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AvoidAppUpdateActiveBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check current state to see whether Active box should be on
		screen or off, then get it there.
CALLED BY:	INTERNAL
PASS:		*ds:si	- GenApplication
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AvoidAppUpdateActiveBox	proc	near
	; All these messages in one way or another affect whether we want
	; to have the Activate dialog on screen... SO figure out again
	; if we want to have it up, based on current state.
	;
	; Up only if AS_AVOID_TRANSPARENT_DETACH and (not AS_DETACHING) and
	; (not AS_HAS_FULL_SCREEN_EXCL), otherwise down.
	;
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	UserCallApplication
	test	ax, mask AS_AVOID_TRANSPARENT_DETACH
	jz	offScreen
	test	ax, mask AS_DETACHING
	jnz	offScreen
	test	ax, mask AS_HAS_FULL_SCREEN_EXCL
	jnz	offScreen

;onScreen:
	call	AvoidAppInitiateActiveDialog
	jmp	short done

offScreen:
	call	AvoidAppDismissActiveDialog
done:
	ret
AvoidAppUpdateActiveBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AvoidAppInitiateActiveDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get "Active" dialog on screen

CALLED BY:	INTERNAL
		AvoidAppLostFullScreenExcl
PASS:		*ds:si	- app object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AvoidAppInitiateActiveDialog	proc	near	uses	si
	.enter
	GetResourceHandleNS	ActiveDialog, bx
	mov	si, offset AvoidActiveDialog

	; See if already in use or not
	;
	mov	ax, MSG_GEN_FIND_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	tst	cx			; If already has parent, then we may
	jnz	afterInAndUsable	; assume usable as well since we always
					; do this in pairs, so just initiate
	mov	cx, bx
	mov	dx, si
	clr	bp
	mov	ax, MSG_GEN_ADD_CHILD
	call	UserCallApplication

	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

afterInAndUsable:

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
AvoidAppInitiateActiveDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AvoidAppDismissActiveDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove "Active" dialog from screen

CALLED BY:	INTERNAL
PASS:		*ds:si	- app object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AvoidAppDismissActiveDialog	proc	near	uses	si
	.enter
	GetResourceHandleNS	ActiveDialog, bx
	mov	si, offset AvoidActiveDialog

	; See if hooked in & on screen or not
	;
	mov	ax, MSG_GEN_FIND_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	tst	cx			; If no parent, then must be not usable
	jz	done			; as well.  Exit with nothing to do.

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	call	ObjMessage

	mov	cx, bx
	mov	dx, si
	clr	bp
	mov	ax, MSG_GEN_REMOVE_CHILD
	call	UserCallApplication
done:
	.leave
	ret
AvoidAppDismissActiveDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AvoidAppGoToAvoid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Respond to user request to go to this application

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_AVOID_APP_GOTO_AVOID

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AvoidAppGoToAvoid	method	AvoidApplicationClass, MSG_AVOID_APP_GOTO_AVOID
	;
	; Raise our app back to the top, which as a by-product, will bring
	; down the Active dialog, if up (because of a GAINED_FULL_SCREEN_EXCL
	; arriving that we intercept)
	;
	mov	ax, MSG_GEN_BRING_TO_TOP
	GOTO	ObjCallInstanceNoLock
AvoidAppGoToAvoid	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AvoidAppQuitOperation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Respond to user request to go to this application

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_AVOID_APP_GOTO_AVOID

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AvoidAppQuitOperation	method	AvoidApplicationClass,
					MSG_AVOID_APP_QUIT_OPERATION
	push	si
	GetResourceHandleNS	Interface, bx
	mov	si, offset AvoidOptionsBooleanGroup

	; Clear operation boolean
	;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
	mov	cx, mask ABID_OPERATION_IN_PROGRESS	; Identifier
	clr	dx					; clear boolean
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	; Quit avoiding detach, which as a by-product will bring down the
	; Active dialog, if up.
	;
	clr	cx
	mov	dx, mask AS_AVOID_TRANSPARENT_DETACH
	mov	ax, MSG_GEN_APPLICATION_SET_STATE
	call	UserCallApplication
	ret

AvoidAppQuitOperation	endm

AppCode	ends		;end of AppCode resource
