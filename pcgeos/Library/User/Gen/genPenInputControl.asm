COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genPenInputControl.asm

AUTHOR:		David Litwin, Apr 12, 1994

ROUTINES:
	Name			Description
	----			-----------
   GLB	PenInputControlClass	Floating keyboard
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/12/94   	Initial revision


DESCRIPTION:
	This file contains routines to implement the PenInputControl class.
	
		

	$Id: genPenInputControl.asm,v 1.1 97/04/07 11:45:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

GenPenInputControlClass:

Synopsis
--------

------------------------------------------------------------------------------@

UserClassStructures	segment resource

	GenPenInputControlClass

UserClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS	;++++++++++++++++++++++++++++++++++++++++++++++++++++

Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenPenInputControlBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS
					for GenPenInputControlClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si	= object in a GenXXXX class
	ds:di	= instance data (for object in a GenXXXX class)
	es - segment of GenPenInputControlClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/12/94		Initial version
	

------------------------------------------------------------------------------@

GenPenInputControlBuild	method	GenPenInputControlClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

	;
	; embedded PenInputControls aren't supported anymore with the
	; move from the UI to the SPUI (because before GenCInteraction would
	; build out to OLWinDialog or OLCtrl or some other class).  When it
	; moved we had to create OLPenInputControlClass, and since we don't
	; have multiple inheritance, we chose to subclass it from
	; OLDialogWinClass, meaning it must be in its own window.
	;
	mov	ds:[di].GII_visibility, GIV_DIALOG

	mov	ax, SPIR_BUILD_PEN_INPUT_CONTROL
	GOTO	GenQueryUICallSpecificUI

GenPenInputControlBuild	endm


Build ends


;
; Place this in GCCommon because it doesn't warrant its own segment, and
; that is where GenControlNotifyWithDataBlock is defined.
;
; This is in the UI instead of the SPUI because it needs to be called before
; GenControl gets ahold of it.  Were it in the SPUI it would be called
; after GenControl calls its superclass, which is too late.  If we have
; GenControl call "SendToSuperIfFlagSet" (if GCBF_SPECIFIC_UI is set), it
; will call it first, but later when GenControl calls its superclass it
; will be called for a second time, which is bad.  It shouldn't ever be
; different for differing SPUI's, so it's not a problem to be in the UI.
;		dlitwin 5/31/94
;

GCCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPenInputControlNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle notifictations.

CALLED BY:	GLOBAL
PASS:		cx	= ManufacturerID
		dx	= GeoWorksNotificationType
		bp	= change specific data
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPenInputControlNotify	method	GenPenInputControlClass,
				MSG_META_NOTIFY
	.enter

 	cmp	dx, GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	jne	callSuper
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper

	;
	; If a UserDoDialog is on screen, ignore everything not sent by
	; objects on the UI thread.
	;
	push	cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_CHECK_IF_RUNNING_USER_DO_DIALOG
	call	UserCallApplication
	pop	cx, dx, bp
	tst	ax
	jz	doNotIgnore
	test	bp, mask TFF_OBJECT_RUN_BY_UI_THREAD
	jz	exit

	;
	; Nuke the TFF_OBJECT_RUN_BY_UI_THREAD, so BP = 0 if nothing
	; has the focus, and non-zero otherwise.
	;
doNotIgnore:
	andnf	bp, not mask TFF_OBJECT_RUN_BY_UI_THREAD

	test	bp, mask TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	jz	callSuper

	;
	; Set ourselves interactable if we are getting the focus, as
	; we will need to get the MSG_GEN_SET_ENABLED message
	;
	call	DerefVardata
	test	ds:[bx].TGCI_interactableFlags, mask GCIF_CONTROLLER
	jnz	callSuper

	push	cx, dx, bp
	mov	ax, MSG_GEN_CONTROL_NOTIFY_INTERACTABLE
	mov	cx, mask GCIF_CONTROLLER
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp

callSuper:
	mov	ax, MSG_META_NOTIFY
	mov	di, offset GenPenInputControlClass
	call	ObjCallSuperNoLock
exit:
	.leave
	ret
GenPenInputControlNotify	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPenInputControlHide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the pen input control w/o notifying the app

CALLED BY:	GLOBAL
PASS:		*ds:si - GenPenInputControlClass
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPenInputControlHide	method	GenPenInputControlClass,
			MSG_META_SEND_CLASSED_EVENT
	cmp	dx, TO_SELF
	jne	callSuper

;	If it is sending MSG_GEN_GUP_INTERACTION_COMMAND to this object,
;	then dispatch it to our superclass.

	mov	bx, cx			;BX <- event handle
	push	ax, cx, dx, bp, si
	call	ObjGetMessageInfo
	cmp	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	pop	ax, cx, dx, bp, si
	jne	callSuper

	mov	cx, ds:[LMBH_handle]		;^lcx:si <- this object
	call	MessageSetDestination

	mov	di, segment ObjCallSuperNoLock	;Pass the event off to the
	push	di				; superclass
	mov	di, offset ObjCallSuperNoLock
	push	di
	mov	di, offset GenPenInputControlClass
	clr	si				;Destroy event when done
	call	MessageProcess
	ret			; <--- EXIT HERE

callSuper:
	mov	di, offset GenPenInputControlClass
	GOTO	ObjCallSuperNoLock

GenPenInputControlHide	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPenInputControlGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we are coming off screen, tell the app object

CALLED BY:	GLOBAL
PASS:		*ds:si - GenPenInputControlClass
RETURN:		cx - InteractionCommand
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPenInputControlGupInteractionCommand	method GenPenInputControlClass,
					MSG_GEN_GUP_INTERACTION_COMMAND
	push	cx
	mov	di, offset GenPenInputControlClass
	call	ObjCallSuperNoLock
	pop	cx

	;
	; If the floating keyboard is being dismissed, tell the app
	;
	cmp	cx, IC_DISMISS
	jne	exit

	;
	; If we are closing because we are set disabled, this doesn't mean
	; the user dismissed the keyboard, so don't register this with
	; the app.
	;
	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_INITIATE_WHEN_ENABLED
	call	ObjVarFindData
	jc	exit

	mov	ax, MSG_GEN_APPLICATION_FLOATING_KEYBOARD_CLOSED
	GOTO	UserCallApplication

exit:
	ret
GenPenInputControlGupInteractionCommand	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPenInputControlNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles various notifications.

CALLED BY:	GLOBAL
PASS:		*ds:si - GenPenInputControlClass
		cx - NT_manuf
		dx - NT_type
		bp - data block
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPenInputControlNotifyWithDataBlock	method	GenPenInputControlClass,
					MSG_META_NOTIFY_WITH_DATA_BLOCK
	uses	ax, cx, dx, bp
	.enter

;	If this is the floating keyboard, we don't bother processing the
;	GWNT_FOCUS_WINDOW_KBD_STATUS notifications, as the application will
;	bring us down if the current window doesn't want us around.

	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_IS_FLOATING_KEYBOARD
	call	ObjVarFindData
	jc	callSuper
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_FOCUS_WINDOW_KBD_STATUS
	jne	callSuper

;	Now, find out if the window in which we reside has the focus. If not,
;	disable the view.

	tst	bp
	jz	disableView
	mov	bx, bp
	push	es
	call	MemLock
	mov	es, ax


	;
	; Record a message that will return the OD of the WinGroup
	; object, then send it up the tree to find out what our
	; WinGroup actually is.
	;
	push	bx, si, di
	mov	ax, MSG_META_GET_OPTR
	mov	bx, segment VisClass
	mov	si, offset VisClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	pop	bx, si, di

	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP
	call	ObjCallInstanceNoLock		;If parent has the focus, 
	cmpdw	cxdx, es:[NFWKS_focusWindow]	; enable the view.
	call	MemUnlock			;Preserves flags
	pop	es
	mov	ax, MSG_GEN_SET_ENABLED
	je	setView
disableView:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
setView:
	;
	; Disable or enable the view based upon whether or not the parent
	; win group has the focus
	;
	push	si
	push	ax
	mov	ax, MSG_GEN_PEN_INPUT_CONTROL_GET_MAIN_VIEW
	call	ObjCallInstanceNoLock
	pop	ax			; enable or disable
	jc	popAndCallSuper

	mov	bx, cx
	mov	si, dx
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

popAndCallSuper:
	pop	si

callSuper:
	.leave
	mov	di, offset GenPenInputControlClass
	GOTO	ObjCallSuperNoLock
GenPenInputControlNotifyWithDataBlock	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPenInputControlSetDisabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the ATTR_GEN_PEN_INPUT_CONTROL_INITIATE_WHEN_ENABLED
		hint if we are disabling and the PIC is displayed.  We do
		this so that if the PIC goes away when being disabled (in
		Stylus, because it has no system menu), we will know to bring
		it back up.

CALLED BY:	MSG_GEN_SET_ENABLED
PASS:		*ds:si	= GenPenInputControlClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPenInputControlSetDisabled	method dynamic GenPenInputControlClass, 
					MSG_GEN_SET_NOT_ENABLED

	;
	; Ensure the hint is gone, then add it if we need it.
	;
	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_INITIATE_WHEN_ENABLED
	call	ObjVarDeleteData

	push	es
	segmov	es, dgroup, ax
	tst	es:[displayKeyboard]
	pop	es
	jz	callSuper

	push	cx
	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_INITIATE_WHEN_ENABLED or \
				mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
	pop	cx

callSuper:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	di, offset GenPenInputControlClass
	GOTO	ObjCallSuperNoLock

GenPenInputControlSetDisabled	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPenInputControlSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the ATTR_GEN_PEN_INPUT_CONTROL_INITIATE_WHEN_ENABLED
		and initiate ourselves if it is set.
		Also check if the TEMP_GEN_APPLICATION_FLOATING_KEYBOARD_INFO
		attr is present on our application, and don't intiate
		ourselves if it isn't.

CALLED BY:	MSG_GEN_SET_ENABLED
PASS:		*ds:si	= GenPenInputControlClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenPenInputControlSetEnabled	method dynamic GenPenInputControlClass, 
					MSG_GEN_SET_ENABLED
	.enter

	mov	di, offset GenPenInputControlClass
	call	ObjCallSuperNoLock

	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_INITIATE_WHEN_ENABLED
	call	ObjVarFindData
	jnc	exit

	segmov	es, dgroup, ax
	tst	es:[displayKeyboard]
	jz	exit

	;
	; Check if the App has the TEMP_GEN_APPLICATION_FLOATING_KEYBOARD_INFO
	; attr by MSG_META_GET_VAR_DATA.  Pass a null length buffer, because
	; we only care if it exists, not what is in it.
	;
	mov	ax, MSG_META_GET_VAR_DATA
	mov	dx, size GetVarDataParams
	sub	sp, dx
	mov	bp, sp
	clr	ss:[bp].GVDP_bufferSize		; we don't care what the data is
	mov	ss:[bp].GVDP_dataType, TEMP_GEN_APPLICATION_FLOATING_KEYBOARD_INFO
	call	UserCallApplication
	add	sp, size GetVarDataParams
	cmp	ax, -1		; -1 returned if no data found
	je	exit

	;
	; If we are enabled then we don't need this attr anymore (and
	; in fact we don't want it as it is an indication that we have
	; been disabled without the app's knowledge).
	;
	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_INITIATE_WHEN_ENABLED
	call	ObjVarDeleteData

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjCallInstanceNoLock

	;
	; undo any WCT_KEEP_VISIBLE that was on for placement reasons
	;
	mov	ax, MSG_GEN_PEN_INPUT_CONTROL_RESET_CONSTRAIN
	mov	dx, VUM_MANUAL
	call	ObjCallInstanceNoLock

exit:
	.leave
	ret
GenPenInputControlSetEnabled	endm




GCCommon ends

endif			; NO_CONTROLLERS ++++++++++++++++++++++++++++++++++++

