COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genAppAttDet.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenApplicationClass	Class that implements an application

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of genApplication.asm

DESCRIPTION:
	This file contains routines to implement the GenApplication class.

	$Id: genAppAttDet.asm,v 1.1 97/04/07 11:44:49 newdeal Exp $

------------------------------------------------------------------------------@
AppAttach	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	General-purpose routine to change the AS_FOCUSABLE,
		AS_MODELABLE, AS_NOT_USER_INTERACTABLE, or
		AS_AVOID_TRANSPARENT_DETACH state bits.

CALLED BY:	MSG_GEN_APPLICATION_SET_STATE
PASS:		*ds:si	= GenApplication object
		ds:di	= GenApplicationInstance
		cx	= bits to set
		dx	= bits to clear
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppSetState	method dynamic GenApplicationClass, MSG_GEN_APPLICATION_SET_STATE
	push	ds:[di].GAI_states	; save original value

	; Change state flags
	;
	ornf	ds:[di].GAI_states, cx
	not	dx
	andnf	ds:[di].GAI_states, dx
	not	dx

	; Update specific UI
	;
	call	GenCheckIfSpecGrown
	jnc	afterSpecUI
	mov	di, offset GenApplicationClass
	mov	ax, MSG_GEN_APPLICATION_SET_STATE
	call	ObjCallSuperNoLock
afterSpecUI:	

	pop	ax			; get original value
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	xor	ax, ds:[di].GAI_states	; see what's changed

	test	ax, mask AS_NOT_USER_INTERACTABLE or \
					mask AS_AVOID_TRANSPARENT_DETACH or \
					mask AS_TRANSPARENT_DETACHING or \
					mask AS_ATTACHING or \
					mask AS_DETACHING or \
					mask AS_QUIT_DETACHING
	jz	afterTransparentDetach
	call	GenAppUpdateTransparentDetachLists
afterTransparentDetach:

	ret
GenAppSetState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppSetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow changing GA_TARGETABLE while usable.

CALLED BY:	MSG_GEN_SET_ATTRS
PASS:		*ds:si	= GenApplication object
		ds:di	= GenApplicationInstance
		cl	= GenAttrs to set
		ch	= GenAttrs to clear
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	if GA_TARGETABLE is cleared, the sys target will be released

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppSetAttrs	method dynamic GenApplicationClass, MSG_GEN_SET_ATTRS
	test	cx, mask GA_TARGETABLE or (mask GA_TARGETABLE shl 8)
	jnz	specialCase
passToGen:
	mov	di, offset GenApplicationClass
passItUp:
	GOTO	ObjCallSuperNoLock
	
specialCase:
	
	;
	; Give the spui a crack at it, if we're grown (if not grown, just pass
	; to Gen to handle, as it won't throw up).
	; 
	call	GenCheckIfSpecGrown
	jnc	passToGen			; => not grown

	;
	; Play with data
	;
	not	ch
	andnf	ds:[di].GI_attrs, ch	; clear bits
	ornf	ds:[di].GI_attrs, cl	; set bits
	not	ch

	;
	; Now tell spui about it.
	; 
	mov	di, offset GenClass
	jmp	passItUp
GenAppSetAttrs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppSet[Not]AttachedToStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets/clears the bit in the application state that says that the
		associated process has successfully attached to a state file.

CALLED BY:	GLOBAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		Get serious! I just set a bit.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppSetAttachedToStateFile	method	dynamic GenApplicationClass,
				MSG_GEN_APPLICATION_SET_ATTACHED_TO_STATE_FILE
	ornf	ds:[di].GAI_states, mask AS_ATTACHED_TO_STATE_FILE
	ret
GenAppSetAttachedToStateFile	endm
GenAppSetNotAttachedToStateFile	method	dynamic GenApplicationClass,
				MSG_GEN_APPLICATION_SET_NOT_ATTACHED_TO_STATE_FILE
	andnf	ds:[di].GAI_states, not mask AS_ATTACHED_TO_STATE_FILE
	ret
GenAppSetNotAttachedToStateFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppSetNotQuitting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark app as not being quit by user.

CALLED BY:	MSG_GEN_APPLICATION_SET_NOT_QUITTING
PASS:		*ds:si	= GenApplication object
		ds:di	= GenApplicationInstance
RETURN:		ax, cx, dx, bp - unchanged
DESTROYED:	nothing
SIDE EFFECTS:	...

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppSetNotQuitting method dynamic GenApplicationClass, MSG_GEN_APPLICATION_SET_NOT_QUITTING
		.enter
		LOG	ALA_NOT_QUITTING

		test	ds:[di].GAI_states, mask AS_QUITTING
		jz	exit

		; Clear quitting flag
		;
		andnf	ds:[di].GAI_states, not mask AS_QUITTING

		;
		; Note that we're interactible still (no longer in flux).
		; 
		mov	cl, IACPSM_USER_INTERACTIBLE
		mov	ax, MSG_GEN_APPLICATION_IACP_REGISTER
		call	ObjCallInstanceNoLock

		;	
		; & allow input to flow again, to undo disruption that was
		; started at the point AS_QUITTING was set.
		;
		mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
		call	ObjCallInstanceNoLock

		;
		; Tell our parent field (if any) that we are no longer
		; quitting.  This is necessary if the field is waiting for
		; us to exiting because it is in 'quitOnClose' mode.
		;
		push	si
		mov	ax, MSG_GEN_FIELD_APP_NO_LONGER_EXITING
		mov	bx, segment GenFieldClass
		mov	si, offset GenFieldClass
		mov	di, mask MF_RECORD
		call	ObjMessage			; di = event handle
		pop	si
		mov	cx, di				; cx = event handle
		mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
		call	ObjCallInstanceNoLock
exit:
		.leave
		ret
GenAppSetNotQuitting endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppAppStartup

DESCRIPTION:	Begin bringing this whole thing to life, regardless of the
		launch model of the application.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_META_APP_STARTUP

	dx - AppLaunchBlock  (MUST NOT BE DESTROYED HERE)
		App filename & state file name should be copied into app
		instance data.

RETURN: AppLaunchBlock intact.

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	attach application to UI system object;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version
	Doug	11/89		Modified to accept AppLaunchBlock data
	ardeb	10/16/92	Changed to be invoked by MSG_META_APP_STARTUP

------------------------------------------------------------------------------@

GenAppAppStartup method	dynamic GenApplicationClass, MSG_META_APP_STARTUP
	;
	; Set the AS_QUITTING flag now so if the app never changes to interact
	; with the user, we'll know not to save anything to state. This also
	; allows us to differentiate between a forced detach and a user-
	; initiated quit in handling MSG_GEN_APPLICATION_NO_MORE_CONNECTIONS
	; 
	ornf	ds:[di].GAI_states, mask AS_QUITTING

	;
	; Set AS_SINGLE_INSTANCE if geode not multi-launchable. If it is
	; multi-launchable, we leave the bit as it was set by the programmer.
	; 
	call	GeodeGetProcessHandle
	mov	ax, GGIT_ATTRIBUTES
	call	GeodeGetInfo
	test	ax, mask GA_MULTI_LAUNCHABLE
	jnz	copyAIR
	ornf	ds:[di].GAI_states, mask AS_SINGLE_INSTANCE
copyAIR:
	;	
	; NOTE that we don't also have to IGNORE_INPUT, which is normally the
	; case when AS_QUITTING is set, as the app is not yet attached,
	; the other criteria for ignoring input while quitting.

	;
	; Copy the AppInstanceRef from the AppLaunchBlock into our instance
	; data.
	; 
	push	si
	mov	bx, dx
	call	MemLock
	push	bx

	push	ds, es
	segmov	es, ds		; es:di = instance data
	mov	ds, ax		; ds = AppLaunchBlock

	push	di
				; Copy app reference over to app instance
	mov	si, offset ALB_appRef
	add	di, offset GAI_appRef
	mov	cx, size AppInstanceReference
	rep	movsb
	pop	di

	;
	; Copy the launch flags.
	; 
	mov	al, ds:[ALB_launchFlags]   ; fetch launch flags
	mov	es:[di].GAI_launchFlags,al ; store into instance data

	;
	; if in app-mode, set AS_ATTACHING so that if we get another
	; IACPConnect before we get MSG_META_ATTACH, we'll not try to
	; switch into app-mode again (via GenAppSwitchToAppMode)
	; - brianc 3/22/93
	;
	cmp	ds:[ALB_appMode], MSG_GEN_PROCESS_OPEN_ENGINE
	je	notAppMode
	ornf	es:[di].GAI_states, mask AS_ATTACHING
notAppMode:

				; Add application object to generic parent
	mov	cx, ds:[ALB_genParent].handle
	mov	dx, ds:[ALB_genParent].chunk
	pop	ds, es
	pop	bx
	call	MemUnlock
	pop	si

	; NOW, add app object to GenField
	;
	tst	cx
	jnz	HaveParent

	; Ask system object where the application should be placed
	mov	ax, MSG_SPEC_GUP_QUERY_VIS_PARENT
	mov	cx, SQT_VIS_PARENT_FOR_APPLICATION
	call	UserCallSystem
				; Returns ^lcx:dx = vis parent to use

EC <	ERROR_NC UI_GEN_APPLICATION_COULDNT_FIND_A_VIS_PARENT		>
EC <	tst	cx							>
EC <	ERROR_Z	UI_NO_CURRENT_FIELD_EXCLUSIVE				>
HaveParent:

	; Setup a one-way generic link to the field object
	;
	call	GenSetUpwardLink

	mov	dx, bx				; dx <- ALB again

	; Let the specific UI know about this. This has the side benefit
	; of establishing the WinGeodeFlags for the app *before* we tell
	; the field we're attached.
	; 
	mov	ax, MSG_META_APP_STARTUP
	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock

	; Notify field that we're now on it.

	; See if we actually are on a GenFieldClass object  (The UI app
	; sits under a GenScreenClass object)
	;
	mov	cx, segment GenFieldClass
	mov	dx, offset GenFieldClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	GenCallParent
	jnc	afterAddition		; if not, skip addition notification

	mov	cx, ds:[LMBH_handle]	; set GenApp object in ^lcx:dx
	mov	dx, si
	mov	bp, CCO_LAST		; add at end
	mov	ax, MSG_GEN_FIELD_ADD_GEN_APPLICATION
	call	GenCallParent
afterAddition:
	;
	; Send MSG_META_APP_STARTUP to the members of the MGCNLT_APP_STARTUP
	; list.
	; 
	mov	dx, bx			; dx <- ALB handle
	mov	ax, MSG_META_APP_STARTUP
	mov	di, MGCNLT_APP_STARTUP
	call	SendToGenAppGCNList
	
	;
	; Register as IACP server in non-interactible mode.
	; 
	mov	cl, IACPSM_NOT_USER_INTERACTIBLE
	mov	ax, MSG_GEN_APPLICATION_IACP_REGISTER
	call	ObjCallInstanceNoLock

	;
	; Add to removable disk list, so we'll be notified of the disk being
	; removed.
	;
	call	GenAppAddToRemovableDiskList
	ret
GenAppAppStartup	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenAppSetAppModeMethod

DESCRIPTION:	Stores the process method passed in GAI_appMode, for
		later retrieval, usually upon the restoration of the application
		after having been shut down.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_GEN_APPLICATION_SET_APP_MODE_MESSAGE

	cx	- method # to store in application object as app mode

RETURN: nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

GenAppSetAppModeMethod	method	dynamic GenApplicationClass, \
					MSG_GEN_APPLICATION_SET_APP_MODE_MESSAGE
	mov	ds:[di].GAI_appMode, cx
	ret

GenAppSetAppModeMethod	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenAppAttach

DESCRIPTION:	Attach application, making it usable.  This should ONLY be
		called from the handler for MSG_GEN_PROCESS_OPEN_APPLICATION.

		The handling of this method work unlike any other; the
		application is actually always presumed "USABLE", & we
		just update the bit here so that the object is consistent
		with our beliefs.  What really happens to bring the app
		up on screen is that we send MSG_META_ATTACH on to our 
		superclass.  Once WIN_GROUPS are GS_USABLE, SA_REALIZABLE,
		& SA_ATTACHED, they'll come on screen.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_META_ATTACH

	cx - AppAttachFlags
	dx - AppLaunchBlock  (MUST NOT BE DESTROYED HERE)
		App filename & state file name should be copied into app
		instance data.
	bp -  Extra state block from state file, if any

RETURN: nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	NOTE: We can arrive here with AS_ATTACHING already set, if the attach
	comes from an IACP-initiated switch from engine to app mode -- ardeb

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

GenAppAttach	method	GenApplicationClass, MSG_META_ATTACH

; removed 10/19/92 so model exclusive grabbing by document control doesn't
; get lost when OLApplication data goes away -- ardeb.
; 
; restored to allow GenAppLazarus to work for normal app mode situtations.
; Engine mode document support (which this breaks) will have to wait
; - brianc 3/8/93
; <sniff> -- ardeb 3/9/93 :)
;
; must also save and restore model exclusive as it is only grabbed by the
; document control on APP_STARTUP, before ATTACH - brianc 3/9/93
;
	LOG	ALA_ATTACH

	;
	; store AppAttachFlags early on as it may be checked early on
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	mov	ds:[di].GAI_attachFlags, cx	; store AppAttachFlags

	push	dx			; save AppLaunchBlock for end

	push	si, cx, dx, bp		; save ATTACH params

	; If being launched in app-mode, mark the system busy, as 
	; the user shouldn't be trying to use an app that's about to be 
	; covered up by this new app coming up.  -- Doug 3/26/93
	;
	; {
	mov	ax, MSG_GEN_SYSTEM_MARK_BUSY		; busy now
	call	UserCallSystem
	; }

	mov	ax, MSG_META_GET_MODEL_EXCL
	call	ObjCallInstanceNoLock	; ^lcx:dx = model excl
	movdw	bxdi, cxdx		; ^lbx:di = model excl
	push	si, di
	mov	si, di			; ^lbx:si = model excl
	mov	ax, MSG_META_RELEASE_MODEL_EXCL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, di

	call	ZeroThreadUsage		; Keep 'er going

	call	GenSpecShrinkBranch	; Anything visually build out before now
					; doesn't count...

	mov	si, di			; ^lbx:si = prev model excl
	mov	ax, MSG_META_GRAB_MODEL_EXCL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; restore model excl

	pop	si, cx, dx, bp		; restore ATTACH params


					; Change application object state
					; to indicate "USABLE"
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	ORNF	ds:[di].GI_states, mask GS_USABLE

	ornf	ds:[di].GAI_states, mask AS_ATTACHING
	andnf	ds:[di].GAI_states, not (mask AS_QUITTING or \
					mask AS_TRANSPARENT_DETACHING)

	mov	ds:[di].GAI_attachFlags, cx	; store AppAttachFlags

	; If running in UILM_TRANSPARENT mode, remove Save Options trigger
	;
	segmov	es, <segment uiLaunchModel>, ax
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	jne	notTrans

	; Set a flag so we know we're in TRANSPARENT mode.

			;Set here always, cleared at reloc
	ornf	ds:[di].GAI_states, mask AS_TRANSPARENT


	; If the app is not closable, nuke the "save options" trigger

	call	UserGetLaunchOptions
	test	ax, mask UILO_CLOSABLE_APPS
	jnz	notTrans

	mov	ax, ATTR_GEN_APPLICATION_SAVE_OPTIONS_TRIGGER
	call	ObjVarFindData
	jnc	notTrans
	mov	di, ds:[bx].chunk	; Fetch SaveOptions trigger
	mov	bx, ds:[bx].handle
	call	ObjSwapLock
.warn -private
	mov	di, ds:[di]
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	andnf	ds:[di].GI_states, not mask GS_USABLE
.warn @private
	call	ObjSwapUnlock

notTrans:

;	If we are on a system w/o a keyboard, add ourselves to the
;	FOCUS_WINDOW_KBD_STATUS GCN list so we know when to bring up the
;	floating keyboard

	call	CheckIfFloatingKbdAllowed
	jnc	afterKbd			;Branch if kbd not allowed
	push	cx,dx,bp
	mov	ax, MSG_META_GCN_LIST_ADD
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	cx, ds:[LMBH_handle]
	movdw  	ss:[bp].GCNLP_optr, cxsi
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_FOCUS_WINDOW_KBD_STATUS
	call	ObjCallInstanceNoLock
	add	sp, size GCNListParams
	pop	cx,dx,bp
afterKbd:

	;
	; initialize options triggers to disabled unless restoring from
	; state, in which case we keep previous state
	;
	test	cx, mask AAF_RESTORING_FROM_STATE
	jnz	noOptions
	mov	ax, ATTR_GEN_APPLICATION_SAVE_OPTIONS_TRIGGER
	call	ObjVarFindData
	jnc	noOptions
;only disable Save
;	mov	di, bx
;	mov	ax, ATTR_GEN_APPLICATION_RESET_OPTIONS_TRIGGER
;	call	ObjVarFindData
;	jnc	noOptions
;	push	di			; save Save Options trigger
;	call	disableTrigger		; disable Reset Options trigger
;	pop	bx
	call	disableTrigger		; disable Save Options trigger
noOptions:

	; Call the superclass to do stuff.

	push	cx, dx, bp		; save attach info
	segmov	es, <segment GenApplicationClass>, di
	mov	di, offset GenApplicationClass
	mov	ax, MSG_META_ATTACH
	CallSuper MSG_META_ATTACH
	pop	cx, dx, bp		; restore attach info

	; Send MSG_META_LOAD_OPTIONS to objects on options list, if
	; needed.  MSG_META_LOAD_OPTIONS *MUST* happen after
	; MSG_META_ATTACH superclass call, because objects loading
	; options may increment the busy count of the app object, which
	; OLApplicationAttach nukes.

	test	cx, mask AAF_RESTORING_FROM_STATE
	jnz	afterOptions
	push	cx, dx, bp		; save AppAttachFlags
	mov	ax, MSG_META_LOAD_OPTIONS
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp		; restore AppAttachFlags
afterOptions:

	call	ZeroThreadUsage		; Keep 'er going

		
	; Send MSG_META_ATTACH to objects on active list.

	push	cx			; save AppAttachFlags
	mov	ax, MSG_META_ATTACH
	mov	di, MGCNLT_ACTIVE_LIST
	call	SendToGenAppGCNList
	pop	cx			; restore AppAttachFlags

	; Mark app busy while we're comming up.  This will appear when the
	; first window is visible, & last until gadgetry is drawn.
	; - Doug 3/26/93
	;
	; {
	push	cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp
	; }

	call	ZeroThreadUsage		; Keep 'er going

	; let all active windows know that we are attaching

	test	cx, mask AAF_RESTORING_FROM_STATE
					; UpdateWindowFlags:
					;	- attaching
					;	- top-level update
	mov	cx, mask UWF_ATTACHING or mask UWF_FROM_WINDOWS_LIST
	jz	notRestoringFromState
	ornf	cx, mask UWF_RESTORING_FROM_STATE
notRestoringFromState:
	mov	dl, VUM_NOW
	mov	ax, MSG_META_UPDATE_WINDOW
	mov	di, GAGCNLT_WINDOWS
	call	SendToGenAppGCNList


	; 
	; Bring this application alive as the active app in the
	; field (unless the ALF_DO_NOT_OPEN_ON_TOP is set)
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_launchFlags, mask ALF_DO_NOT_OPEN_ON_TOP
	jnz	ensureRegistered

	; Bring this application to the top.
	; Change to happen immediately now that window VisOpen's now happen
	; immediately & aren't queued.  Has the side benefit of giving
	; this app the focus before the "Activating..." system dialog is brought
	; down, meaning that we get the high thread prio instead of whoever
	; had the focus before.  - Doug 4/15/93
	;
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	ObjCallInstanceNoLock
ensureRegistered:

	mov	cl, IACPSM_USER_INTERACTIBLE
	mov	ax, MSG_GEN_APPLICATION_IACP_REGISTER
	call	ObjCallInstanceNoLock

				; & let ourselves know when app is up
	mov	ax, MSG_GEN_APPLICATION_OPEN_COMPLETE
	mov	bx, ds:LMBH_handle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	; Change sys back to not busy again.
	; {
        mov     ax, MSG_GEN_SYSTEM_MARK_NOT_BUSY	; not busy after flush
	call	UserCallSystem
	; }

	; Change app back to not be busy, after a queue flush
	; {
        mov     ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	mov	bx, ds:[LMBH_handle]	; Send to self
	mov	di, mask MF_RECORD
	call	ObjMessage		; wrap up into event
	mov	cx, di			; event in cx

	mov	dx, bx			; pass a block owned by process
	mov	bp, OFIQNS_INPUT_OBJ_OF_OWNING_GEODE	; app obj is next stop
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE

;	mov	di, mask MF_RECORD	; Flush through a second time
;	call	ObjMessage		; wrap up into event
;	mov	cx, di			; event in cx

					; dx is already block owned by process
					; bp is next stop
					; ax is message
	call	ObjCallInstanceNoLock	; Finally, send this after a flush
	; }

	pop	dx			; retrieve AppLaunchBlock

	; Tell field we're done with any "Activating" dialog that may be up
	; on screen, as we're up (will cause no harm if there isn't).
	; -- Doug 4/14/93
	;
	push	si
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov	cx, bx			; Get owning geode
	mov	bx, segment GenFieldClass	; classed event
	mov	si, offset GenFieldClass
	mov	ax, MSG_GEN_FIELD_ACTIVATE_DISMISS
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = event
	pop	si
	mov	cx, di			; cx = event
	mov	dx, TO_GEN_PARENT	; send to our gen parent (GenField)
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage		; throw onto our queue to delay

	call	ZeroThreadUsage		; Keep 'er going
	ret

disableTrigger	label	near
	push	si
	mov	si, ds:[bx].chunk	; Fetch SaveOptions trigger
	mov	bx, ds:[bx].handle
	call	ObjSwapLock
.warn -private
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	andnf	ds:[di].GI_states, not mask GS_ENABLED
.warn @private
	call	ObjMarkDirty
	call	ObjSwapUnlock
	pop	si
	retn
GenAppAttach	endm


ZeroThreadUsage	proc	near	uses	ax, bx
	.enter
	clr	bx
	mov	ah, mask TMF_ZERO_USAGE
	call	ThreadModify
	.leave
	ret
ZeroThreadUsage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FocusFirstWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	give focus to first window in GAGCNLT_WINDOWS list

CALLED BY:	GenAppAttach
PASS:		*ds:si = GenApplication
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppOpenComplete

DESCRIPTION:	Let app know that it is up on screen.  Sent from within
		GenAppGenSetUsable

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_APP_GEN_OPEN_COMPLETE

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version

------------------------------------------------------------------------------@

GenAppOpenComplete	method	dynamic GenApplicationClass, \
					MSG_GEN_APPLICATION_OPEN_COMPLETE
				; Clear the flag, now that the application has
				; been opened.  (So that should app bring all
				; windows down & then put any back up, they
				; won't go up in back)

	LOG	ALA_OPEN_COMPLETE

	andnf	ds:[di].GAI_launchFlags, \
		not (mask ALF_OPEN_IN_BACK or mask ALF_DO_NOT_OPEN_ON_TOP)
	andnf	ds:[di].GAI_states, not mask AS_ATTACHING

	segmov	es, <segment uiLaunchModel>, ax
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	jne	afterTransparentDetachStuff
	;
	; Remove the geode from the list of geodes in the process of detaching,
	; in case it's decided to come back to life.  This will allow the
	; kernel to transparently detach the thing if it is detachable, & 
	; space is needed.  Now's a good time to do it, before we become a
	; candidate for transparent detaching (we just finished AS_ATTACHING),
	; & the lists haven't been updated yet)
	;
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_IN_PROGRESS
	call	GCNListRemove
afterTransparentDetachStuff:

	; Update the transparent detach GCN lists, now that we're attached.
	;
	call	GenAppUpdateTransparentDetachLists

	call	ZeroThreadUsage		; Keep 'er going

	;
	; Finish any pending IACP connections, now that we assume the app is
	; prepared to field them.
	; 
	mov	ax, MSG_GEN_APPLICATION_IACP_COMPLETE_CONNECTIONS
;	call	ObjCallInstanceNoLock
;
; We need to FORCE_QUEUE this thing so that we may hold it up if there is
; a UserDoDialog in progress.  (see comment in
; CheckIfObjectCanReceiveMessagesDuringUserDoDialog) - brianc 6/23/93
;
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	;
	; let specific UI know also
	;
	mov	ax, MSG_GEN_APPLICATION_OPEN_COMPLETE
	segmov	es, <segment GenApplicationClass>, di
	mov	di, offset GenApplicationClass
	GOTO	ObjCallSuperNoLock

GenAppOpenComplete	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenAppBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenApplicationClass

DESCRIPTION:	Return the correct specific class for an object

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

GenAppBuild	method	dynamic GenApplicationClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
					; get UI to use
	mov	ax, ds:[di].GAI_specificUI
	tst	ax
	jnz	GAB_40			; if exists, use it.

					; else determine UI to use
	mov	cx, GUQT_UI_FOR_APPLICATION
	mov	ax, MSG_SPEC_GUP_QUERY
	call	GenCallParent		; ask parent object what UI should be
	jnc	outaHere		; Bad news.. we appear to be a product
					; of immaculate conception...

					; Store it
EC <	ERROR_NC	UI_APP_OBJ_HAS_NO_GENERIC_PARENT		>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	;ds:di = GenInstance
	mov	ds:[di].GAI_specificUI, ax
	call	ObjMarkDirty		; Change Gen instance data, mark dirty

GAB_40:
	mov	bx,ax			; bx = handle of specific UI to use
	mov	ax, SPIR_BUILD_APPLICATION
	mov	di,MSG_META_RESOLVE_VARIANT_SUPERCLASS
	call	ProcGetLibraryEntry
	GOTO	ProcCallFixedOrMovable

outaHere:
EC <	ERROR	UI_MESSAGE_ARRIVING_AFTER_SAVED_TO_STATE		>
NEC <	clr	cx		; try to escape by just not building	>
NEC <	ret								>

GenAppBuild	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppRelocOrUnReloc -- MSG_META_RELOCATE/MSG_META_UNRELOCATE for
					GenApplicationClass

DESCRIPTION:	Deal with loading and storing of an application object.

PASS:	*ds:si	- instance data

	ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE

	cx - handle of block containing relocation
	dx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE
	bp - data to pass to ObjRelocOrUnRelocSuper

RETURN:
	carry - set if error
	bp - unchanged

ALLOWED TO DESTROY:
	ax, cx, dx
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       When unrelocating, we store a zero in the GAI_specificUI instance
       variable so when the object is reloaded, we will query the system
       for the UI to use.
       
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/89		Initial version

------------------------------------------------------------------------------@

GenAppRelocOrUnReloc	method	GenApplicationClass, reloc
	cmp	ax, MSG_META_RELOCATE
	je	reloc
	mov	di, ds:[si]			; Point to object
	add	di, ds:[di].Gen_offset		; Point to our part

;	IF UNRELOCATING, CLEAR VARIOUS STATES

	clr	bx
	mov	ds:[di].GAI_specificUI, bx	; zero out spec ui handle
						; zero out *certain* state flags
	andnf	ds:[di].GAI_states, not (mask AS_DETACHING or \
				mask AS_QUITTING or \
				mask AS_TRANSPARENT_DETACHING or \
				mask AS_TRANSPARENT or \
				mask AS_REAL_DETACHING or \
				mask AS_ATTACHED_TO_STATE_FILE or \
				mask AS_RECEIVED_APP_OBJECT_DETACH)

	;
	; unrelocate any GCN lists (will do all GCN lists stored in
	; TEMP_META_GCN even non-GAGCNLT types.  This is okay as other classes
	; that do this will check if it is necessary before unrelocating.)
	;
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData			; get ptr to TempGenAppGCNList
	jnc	done
	test	ds:[bx].TMGCND_flags, mask TMGCNF_RELOCATED
	jz	done				; already unrelocated
						; indicate unrelocated
	andnf	ds:[bx].TMGCND_flags, not mask TMGCNF_RELOCATED
	mov	di, ds:[bx].TMGCND_listOfLists	; get list of lists
	mov	dx, ds:[LMBH_handle]
	call	GCNListUnRelocateBlock		; unrelocate all the lists we've
						;	been using
	jnc	done				; lists saved to state, leave
						;	var data element
	mov	ax, TEMP_META_GCN
	call	ObjVarDeleteData		; else, remove var data element
	jmp	done

reloc:
	;
	; relocate any GCN lists (will do all GCN lists stored in TEMP_META_GCN
	; even non-GAGCNLT types.  This is okay as other classes that do this
	; will check if it is necessary before relocating.)
	;
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData			; get ptr to TempGenAppGCNList
	jnc	done
	test	ds:[bx].TMGCND_flags, mask TMGCNF_RELOCATED
	jnz	done				; already relocated
						; indicate relocated
	ornf	ds:[bx].TMGCND_flags, mask TMGCNF_RELOCATED
	mov	di, ds:[bx].TMGCND_listOfLists	; get list of lists
	mov	dx, ds:[LMBH_handle]
	call	GCNListRelocateBlock		; relocate all the lists we've
						;	been using

done:
	clc
	mov	di, offset GenApplicationClass
	call	ObjRelocOrUnRelocSuper
	ret
GenAppRelocOrUnReloc	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenApplicationFindMoniker

DESCRIPTION:	Find the specified moniker (or most approriate moniker) in
		this GenApplication's VisMonikerList, and optionally copy the
		Moniker a remote ObjectBlock.

CALLED BY:	EXTERNAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	bp	- VisMonikerSearchFlags (see visClass.asm)
			flags indicating what type of moniker to find
			in the VisMonikerList, and what to do with
			the Moniker when it is found.
	cx	- handle of destination block (if bp contains
			VMSF_COPY_CHUNK command)
	dh	- DisplayType to use for search

RETURN:	ds updated if ObjectBlock moved as a result of chunk overwrite
	^lcx:dx	- handle of VisMoniker (cx = NIL if none)
	bp - unchanged

ALLOWED TO DESTROY:
	ax
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Initial version

------------------------------------------------------------------------------@


GenApplicationFindMoniker	method	GenApplicationClass, \
					MSG_GEN_APPLICATION_FIND_MONIKER
EC <	call	GenCheckGenAssumption	; Make sure gen data exists	>
EC <	test	bp, mask VMSF_REPLACE_LIST				>
EC <	ERROR_NZ UI_CANNOT_REPLACE_APPLICATION_MONIKER_LIST		>

	mov	bh, dh			;bh = DisplayType

	;pass:	*ds:di = VisMoniker or VisMonikerList
	;	bh = DisplayType
	;	bp = VisMonikerSearchFlags
	;	cx = handle of destination block

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		;ds:di = GenInstance
	mov	di, ds:[di].GI_visMoniker	;*ds:di = VisMoniker
	push	si
	call	VisFindMoniker
	pop	si
	ret

GenApplicationFindMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppAppModeComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that "application mode" for this application is complete,
		and either shut down the app, or switch to engine mode,
		depending on whether there are any IACP connections left.

CALLED BY:	MSG_GEN_APPLICATION_APP_MODE_COMPLETE
PASS:		*ds:si	= GenApplication object
		^ldx:bp	= ack OD
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This is used in two instances:
			1) when an IACP connection goes away. We want to exit
			   if we're in engine mode and that was the last
			   connection
			2) when GenProcess receives MSG_META_ACK from us, it
			   wants to either continue exiting, or switch us
			   into engine mode, based on whether there are any
			   IACP connections left. It also needs to unregister
			   us as an IACP server, with all that entails.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppAppModeComplete method dynamic GenApplicationClass, 
					MSG_GEN_APPLICATION_APP_MODE_COMPLETE

	;
	; See if we're in application mode, so we need to stay open regardless
	; (this is for instance (1), above).
	; 
		LOG	ALA_APP_MODE_COMPLETE

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		test	ds:[di].GI_states, mask GS_USABLE
		jnz	inAppMode
	;
	; If switching to app mode, pretend we're already there, for the
	; purposes of deciding what to do. -- ardeb
	; 
		test	ds:[di].GAI_states, mask AS_ATTACHING
		jnz	inAppMode

	;
	; Tell IACP we're no longer interactible.
	; 
		LOG	ALA_AMC_NOT_IN_APP_MODE

		push	cx, dx, bp
		mov	cl, IACPSM_NOT_USER_INTERACTIBLE
		mov	ax, MSG_GEN_APPLICATION_IACP_REGISTER
		call	ObjCallInstanceNoLock
		pop	cx, dx, bp
	;
	; See if we've got an app-mode thing pending.
	; 
		mov	ax, TEMP_GEN_APPLICATION_SAVED_ALB
		call	ObjVarFindData
		jc	iAmTheResurrectionAndTheLife
	;
	; App not interactible. If there are no more active client
	; connections, unregister ourselves as a server, in preparation for
	; exiting.
	; 
		push	cx
		mov	ax, MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS
		call	ObjCallInstanceNoLock
		tst	cx
		pop	cx
		jz	shutdown

		LOG	ALA_AMC_MORE_CONNECTIONS
	;
	; Check to see if we have an ack OD and if so save it so we can ack
	; after all IACP connections have been closed.
	;
		tst	dx
		jz	done

		mov	ax, TEMP_GEN_APPLICATION_APP_MODE_COMPLETE_ACK_OD
		mov	cx, size optr	
		call	ObjVarAddData
		movdw	ds:[bx], dxbp
done:
		; Update transparent detach list, in case we're now detachable
		; again.
		;
		call	GenAppUpdateTransparentDetachLists
		ret

inAppMode:
	; If open in app mode for user, stay open.
	;
		LOG	ALA_AMC_IN_APP_MODE

		test	ds:[di].GAI_launchFlags, mask ALF_OPEN_FOR_IACP_ONLY
		jz	done

		LOG	ALA_AMC_FOR_IACP_ONLY

	; If not, see if there's any remaining app mode connections
	; to keep us open
	;
		push	cx, dx, bp
		mov	ax, MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_APP_MODE_CONNECTIONS
		call	ObjCallInstanceNoLock
		pop	cx, dx, bp
		tst	ax
		jnz	done

		LOG	ALA_AMC_QUIT

	; No reason to stay open in app mode -- quit (will end up
	; hanging around in engine mode if there are still engine
	; mode connections)
	;
		mov	dx, QL_AFTER_UI
		call	GenAppQuitCommon
		jmp	done

iAmTheResurrectionAndTheLife:
		LOG	ALA_AMC_LAZARUS

		mov	bx, ds:[bx]
		call	ObjVarDeleteData
		call	GenAppLazarus
		jmp	done
shutdown:
	;
	; Unregister as a server for the application's token.
	; 
		LOG	ALA_AMC_SHUTDOWN
		push	cx, dx, bp
		mov	ax, MSG_GEN_APPLICATION_IACP_UNREGISTER
		call	ObjCallInstanceNoLock
		pop	cx, dx, bp
	;
	; Queue a message to ourselves to quit. If, when we receive that
	; message, there are still no active connections (there might be a
	; NEW_CONNECTION message queued for us...), we'll tell ourselves to
	; quit.
	; 
		mov	ax, MSG_GEN_APPLICATION_IACP_NO_MORE_CONNECTIONS
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	done
GenAppAppModeComplete endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GENAPPCLOSEKEYBOARD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes any open keyboard window. This routine is only
		effective when an applicaiton is in the middle of attaching
		(i.e. call this in your method for MSG_GEN_APPLICATION
		_OPEN_APPLICATION)

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/17/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GENAPPCLOSEKEYBOARD	proc	far
		uses	ax, ds
		.enter
	
		segmov	ds, dgroup, ax
		clr	ds:[displayKeyboard]

		.leave
		ret
GENAPPCLOSEKEYBOARD	endp

AppAttach ends
AppDetach	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppFinishQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the passed abort flag off to the owning process.

CALLED BY:	GLOBAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	cx - abort flag

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppFinishQuit	method	GenApplicationClass, MSG_META_FINISH_QUIT
	push	ax, cx

if LOG_DETACH_CRUFT
   	jcxz	noAbort
	LOG	ALA_FINISH_QUIT_ABORT
	jmp	doIt
noAbort:
	LOG	ALA_FINISH_QUIT
doIt:
endif

	mov	ax, MSG_META_QUIT_ACK	;Send quit acknowledge with any abort
	mov	dx, QL_UI		; flag off to the process.
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	ax, cx
	mov	di, offset GenApplicationClass 	; do superclass thing
	GOTO	ObjCallSuperNoLock

GenAppFinishQuit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppQuitOptionsQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save options and quit

CALLED BY:	GLOBAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	cx - IC_YES to save options and quit
	cx - IC_NO to just quit

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/8/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppQuitOptionsQuery	method	GenApplicationClass, MSG_GEN_APPLICATION_QUIT_OPTIONS_QUERY
	cmp	cx, IC_NO
	je	justQuit
	;
	; save options first
	;
	mov	ax, MSG_META_SAVE_OPTIONS
	call	ObjCallInstanceNoLock
justQuit:
	mov	dx, QL_BEFORE_UI		;Set appropriate quit level
	GOTO	GenAppQuitCommon
GenAppQuitOptionsQuery	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This just sets the "I am quitting" flag in the state block, and
		sends the method off to the process.

CALLED BY:	GLOBAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
querySaveCat	char	"ui",0
querySaveKey	char	"askSaveOptions",0
GenAppQuit	method	GenApplicationClass, MSG_META_QUIT
	LOG	ALA_QUIT

	;
	; if changed options, query user to save them
	;
	push	ds, si
	mov	cx, cs
	mov	dx, offset querySaveKey
	mov	si, offset querySaveCat
	mov	ds, cx
	call	InitFileReadBoolean
	pop	ds, si
	jc	askSave
	tst	ax
	jz	noOptionsShort
askSave:
	mov	ax, ATTR_GEN_APPLICATION_SAVE_OPTIONS_TRIGGER
	call	ObjVarFindData
	jnc	noOptionsShort
;only check save
;	mov	ax, ATTR_GEN_APPLICATION_RESET_OPTIONS_TRIGGER
;	call	ObjVarFindData
;	jnc	noOptionsShort
	push	si
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov	ax, MSG_GEN_GET_ENABLED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	; C set if enabled
	call	ObjMessage
	pop	si
	jc	getAppName
noOptionsShort:
	jmp	noOptions

	;
	; get appname from app
	;
getAppName:
	mov	dx, -1			; get appname from app
	mov	bp, (VMS_TEXT shl offset VMSF_STYLE) or mask VMSF_COPY_CHUNK
	mov	cx, ds:[LMBH_handle]	; copy into spell control block
	mov	ax, MSG_GEN_FIND_MONIKER
	call	ObjCallInstanceNoLock	; ^lcx:dx = moniker
	jcxz	useNullString
	mov	di, dx
	mov	di, ds:[di]
	test	ds:[di].VM_type, mask VMT_GSTRING
	jnz	useNullString
	add	di, offset VM_data.VMT_text	; ds:di = appname
	jmp	short haveString

useNullString:
	mov	al, 0
	mov	cx, (size TCHAR)		; null-terminator only
	call	LMemAlloc
	mov	dx, ax
	mov_tr	di, ax
	mov	di, ds:[di]			; ds:di = null appname
	mov	{TCHAR}ds:[di], 0
	;
	; ask user
	;
haveString:
	push	dx				; save appname chunk
	mov	ax, (CDT_QUESTION shl offset CDBF_DIALOG_TYPE or GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	mov	dx, size GenAppDoDialogParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, ax
	mov	ss:[bp].GADDP_dialog.SDP_stringArg1.segment, ds
	mov	ss:[bp].GADDP_dialog.SDP_stringArg1.offset, di
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GADDP_finishOD.handle, ax
	mov	ss:[bp].GADDP_finishOD.offset, si
	mov	ss:[bp].GADDP_message, MSG_GEN_APPLICATION_QUIT_OPTIONS_QUERY
	mov	si, bx
	mov	bx, handle Strings
	call	MemLock
	push	ds
	mov	ds, ax
	mov	si, offset SaveOptionsQuery
	mov	si, ds:[si]		;DS:SI <- ptr to string to display
	pop	ds
	mov	ss:[bp].GADDP_dialog.SDP_customString.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_customString.offset, si
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	call	GenCallApplication
	add	sp, size GenAppDoDialogParams
	pop	ax				; *ds:ax = appname chunk
	call	LMemFree
	mov	bx, handle Strings
	call	MemUnlock
	ret
noOptions:

	mov	dx, QL_BEFORE_UI		;Set appropriate quit level
	FALL_THRU	GenAppQuitCommon

GenAppQuit	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GenAppQuitCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start quit sequence for attached app, if not yet in progress.
		Sets AS_QUITTING flag, starts IGNORE_INPUT, sends off starting
		MSG_META_QUIT to process at level indicated

CALLED BY:	INTERNAL
PASS:		*ds:si	- app object
		cx	- QuitLevel
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/1/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenAppQuitCommon	proc	far	uses	si
	class	GenApplicationClass

	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	test	ds:[di].GAI_states, mask AS_QUITTING	; If already quitting,
	jnz	exit					; just exit

	test	ds:[di].GAI_states, mask AS_DETACHING or mask AS_QUIT_DETACHING
;EC <	ERROR_NZ UI_MSG_QUIT_RECEIVED_AFTER_MSG_META_DETACH		>
;could happen in some new exit-to-dos while printing multiple-files from
;GeoManager scenario - brianc 8/16/94
EC <	jne	exit							>
NEC <	jne	exit							>

	; Set flag to indicate quitting
	;
	ornf	ds:[di].GAI_states, mask AS_QUITTING

	push	dx

	mov	cl, IACPSM_IN_FLUX
	mov	ax, MSG_GEN_APPLICATION_IACP_REGISTER
	call	ObjCallInstanceNoLock

	;
	; Start ignoring input, other than dialog responses (Is undone if the
	; abort is quit)
	;
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	ObjCallInstanceNoLock

	; Init flag to be false, i.e. missing
	;
	mov	ax, TEMP_GEN_APPLICATION_ABORT_QUIT
	call	ObjVarDeleteData

	pop	dx
	mov	ax, MSG_META_QUIT
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	.leave
	ret
GenAppQuitCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppInitiateQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a MSG_META_QUIT off to the superclass.

CALLED BY:	GLOBAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/19/90		Initial version
	Joon	12/31/92	Send MSG_META_QUIT to window list

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppInitiateQuit	method	dynamic GenApplicationClass,
					MSG_GEN_APPLICATION_INITIATE_UI_QUIT
EC <	test	ds:[di].GAI_states, mask AS_QUITTING			>
EC <	ERROR_Z	UI_APP_RECEIVED_INITIATE_QUIT_BEFORE_MSG_META_QUIT	>
	test	ds:[di].GI_states, mask GS_USABLE	;If not usable, just
	jne	10$					; ack the quit

	clr	cx					;Clear abort flag
	mov	ax, MSG_META_QUIT_ACK			;Send ack off
	mov	dx, QL_UI
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret

10$:
	; Do MSG_META_QUIT for window list

	mov	ax, MSG_META_QUIT
	mov	di, GAGCNLT_WINDOWS
	call	SendToGenAppGCNList

	clr	cx				; no abort
	mov	ax, MSG_META_QUIT_ACK
	mov	di, offset GenApplicationClass
	GOTO	ObjCallSuperNoLock
GenAppInitiateQuit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppQuitAfterUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle QL_AFTER_UI level of quit for the process QUIT
		mechanism - set QUIT_DETACHING flag, detach application,
		unless there remains a reason for it to be open in app mode,
		in which case we abort the quit thereby defeating the detach

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- method

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppQuitAfterUI	method	dynamic GenApplicationClass,
					MSG_GEN_APPLICATION_QUIT_AFTER_UI

	LOG	ALA_QUIT_AFTER_UI

	mov	ax, TEMP_GEN_APPLICATION_ABORT_QUIT
	call	ObjVarFindData
	jc	abortQuit
	
	mov	ax, TEMP_GEN_APPLICATION_SAVED_ALB
	call	ObjVarFindData
	jc	healTheLeper

	; If should be open for IACP, abort quit.
	;
	mov	ax, MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_APP_MODE_CONNECTIONS
	call	ObjCallInstanceNoLock
	tst	ax
if LOG_DETACH_CRUFT
   	jz	quit
	LOG	ALA_QAUI_MORE_CONNECTIONS
	jmp	abortQuit
quit:
else
	jnz	abortQuit		; if so, if we need app mode, then
					; don't detach at all.
endif

	LOG	ALA_QAUI_QUITTING

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	; Mark as NOT_OPEN_FOR_USER, as about to detach for a QUIT.
	;
	ornf	ds:[di].GAI_launchFlags, mask ALF_OPEN_FOR_IACP_ONLY
	ornf	ds:[di].GAI_states, mask AS_QUIT_DETACHING

	clr	cx			; clear abort flag
	jmp	short ack

healTheLeper:
	LOG	ALA_QAUI_LEPER

	mov	ax, ds:[bx]
	call	ObjVarDeleteDataAt
	clr	bp
	mov_tr	bx, ax
	call	MemLock
	mov	es, ax
	mov	cx, TRUE		; open default if no document
	call	GenAppNotifyModelIfDoc
	call	MemFree
	
	mov	ax, MSG_GEN_APPLICATION_IACP_COMPLETE_CONNECTIONS
	call	ObjCallInstanceNoLock

abortQuit:
	LOG	ALA_QAUI_ABORT

	; Let IACP know we're back.

	mov	cl, IACPSM_USER_INTERACTIBLE
	mov	ax, MSG_GEN_APPLICATION_IACP_REGISTER
	call	ObjCallInstanceNoLock

	mov	cx, -1			; set abort flag
ack:
	mov	ax, MSG_META_QUIT_ACK
	mov	dx, QL_AFTER_UI
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

GenAppQuitAfterUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppIACPGetNumberOfAppModeConnections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	<description here>

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_APP_MODE_CONNECTIONS

RETURN:		ax	- # of app mode IACP connections

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppIACPGetNumberOfAppModeConnections	method	dynamic GenApplicationClass,
		MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_APP_MODE_CONNECTIONS
	clr	ax			; default to zero
	mov	si, ds:[di].GAI_iacpConnects
	tst	si
	jz	exit
	mov	bx, cs
	mov	di, offset GAIGNOFMC_callback
	call	ChunkArrayEnum
exit:
	ret
GenAppIACPGetNumberOfAppModeConnections endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GAIGNOFMC_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count # of app mode connections

CALLED BY:	GenAppIACPGetNumberOfAppModeConnections
PASS:		*ds:si	= array
		ds:di	= array element to examine
		ax	= # of app mode connections encountered so far
RETURN:		ax	= new # of app mode connections found
		carry set to stop enumerating
		carry clear to keep going
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GAIGNOFMC_callback	proc	far
		.enter
		cmp	ds:[di].GAIACPC_appMode, \
				MSG_GEN_PROCESS_OPEN_APPLICATION
		jne	next
		
		inc	ax
next:
		clc
		.leave
		ret
GAIGNOFMC_callback	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenAppDetach -- MSG_META_DETACH for GenApplicationClass

DESCRIPTION:	Perform actual object detach for the Application object

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_META_DETACH
	cx	- caller's ID
	dx:bp	- ackOD		(The application process itself)

	NOTE:  the app process takes advantage of the passing parameters
	by storing an optr in here, which it will get back later.  The
	"hidden" data here is:

	dx	- process handle
	cx:bp	- OD of original ackOD sent in MSG_META_DETACH to process

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version
	Doug	12/89		Revised detach methodology

------------------------------------------------------------------------------@

GenAppDetach	method	GenApplicationClass, MSG_META_DETACH
EC <	xchg	bx, dx							>
EC <	xchg	si, bp							>
EC <	call	ECCheckOD						>
EC <	xchg	bx, dx							>
EC <	xchg	si, bp							>

   	LOG	ALA_DETACH

	test	ds:[di].GAI_states, mask AS_DETACHING
	LONG jnz	alreadyDetaching	;If already detaching, branch

	; if not in app mode, this has no meaning (happens if we're exiting
	; when field decides to shut everyone down...), so just ack the thing,
	; as we're already detached -- ardeb 1/6/93

	test	ds:[di].GI_states, mask GS_USABLE
	LONG jz		alreadyDetaching

	ornf	ds:[di].GAI_states, mask AS_DETACHING
EC <	andnf	ds:[di].GAI_states, not mask AS_RECEIVED_APP_OBJECT_DETACH >

	push	ax
	push	cx
	push	dx
	push	bp

	clr	cx			; Remove from all transparent detach
					; lists (won't be added back on again
					; now that AS_DETACHING is set)
	call	GenAppRemoveFromTransparentDetachLists
;
;	If we are on a system w/o a keyboard, remove ourselves from the
;	FOCUS_WINDOW_KBD_STATUS GCN list.
;
	call	CheckIfFloatingKbdAllowed
	jnc	notOnGCNList

	mov	ax, MSG_META_GCN_LIST_REMOVE
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	cx, ds:[LMBH_handle]
	movdw  	ss:[bp].GCNLP_optr, cxsi
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_FOCUS_WINDOW_KBD_STATUS
	call	ObjCallInstanceNoLock
	add	sp, size GCNListParams

notOnGCNList:
				; Notify specific UI that application is
				; being detached.  Will force down any
				; app-modal UserDoDialog's, so that app
				; process will be able to get MSG_META_DETACH.
	mov	ax, MSG_GEN_APPLICATION_DETACH_PENDING
	call	ObjCallInstanceNoLock

	pop	bp
	pop	dx
	pop	cx
	pop	ax

EC <	push	cx, dx, bp						>
EC <	mov	di, ds:[si]						>
EC <	add	di, ds:[di].Gen_offset					>
EC <	ornf	ds:[di].GAI_states, mask AS_RECEIVED_APP_OBJECT_DETACH	>
EC <									>
EC <	xchg	bx, dx							>
EC <	xchg	si, bp							>
EC <	call	ECCheckOD						>
EC <	xchg	bx, dx							>
EC <	xchg	si, bp							>
EC <	pop	cx, dx, bp						>

	; start the standard detach mechanism

	call	ObjInitDetach

	; IF the application is not marked as USABLE, then we may presume
	; that the active list was never sent a MSG_META_ATTACH, as that happens
	; in GenAppSetUsable itself.  THEREFORE, if this thing isn't
	; USABLE, then we want to skip sending MSG_META_DETACH to the active
	; list.  (The app object will stay USABLE until this detach is
	; complete)
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	AfterActiveListDetached

	; let all active windows know that we are detaching

	push	cx, dx, bp
	mov	cx, mask UWF_DETACHING	; UpdateWindowFlags
	mov	dl, VUM_NOW
	mov	ax, MSG_META_UPDATE_WINDOW
	mov	di, GAGCNLT_WINDOWS
	call	SendToGenAppGCNList
	pop	cx, dx, bp

	; Do active list detach - pass same dx:bp ack OD, even
	; though it is not used since ObjInitDetach has already been done.
	;
	; The detach will finish up when all DETACHES generated
	; here AND in the active list are acknowledged.

	mov	ax, MGCNLT_ACTIVE_LIST
	mov	di, MSG_META_DETACH
	call	SendToGenAppGCNListUppingDetachCount

	; let superclass do stuff, if it wishes

	mov	di, offset GenApplicationClass
	mov	ax, MSG_META_DETACH
	CallSuper MSG_META_DETACH

AfterActiveListDetached:

	; force a clearing of the event queue

	call	ObjIncDetach		; Inc for ACK we'll receive back from
					; this...
	mov	bx,ds:[LMBH_handle]
	mov	ax, MSG_META_ACK
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	call	ObjEnableDetach
done:
	ret


alreadyDetaching:
	LOG	ALA_DETACH_NESTED

	call	GenAppNestedDetach
	jmp	short done

GenAppDetach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToGenAppGCNListUppingDetachCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all elements of a GCN list bound to the
		application object, calling ObjIncDetach for each one

CALLED BY:	(INTERNAL) GenAppDetach, GenAppAppShutdown
PASS:		*ds:si	= GenApplication object
		ax	= GeoWorks gcn list type
		di	= message to send to all members
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToGenAppGCNListUppingDetachCount	proc	near
	uses	cx, dx, bp
	.enter

	;
	; Locate the list of GCN lists.
	; 
	push	ax
	mov	bp, si			; *ds:bp = GenApp object
	mov	ax, TEMP_META_GCN
	call	ObjVarFindData		; ds:bx = TempMetaGCNData
	pop	ax
	jnc	done
	;
	; Locate the GCN list in question.
	; 
	push	di
	mov	di, ds:[bx].TMGCND_listOfLists
	mov	bx, MANUFACTURER_ID_GEOWORKS
	call	GCNListFindListInBlock	; *ds:si = MGCNLT_ACTIVE_LIST list
	pop	ax
	jnc	done
	;
	; Enumerate them all, sending the proper message to each.
	; 
	mov	bx, cs
	mov	di, offset STGAGLUDC_callback
	call	ChunkArrayEnum
	mov	si, bp			; *ds:si = GenApp object
done:
	.leave
	ret
SendToGenAppGCNListUppingDetachCount endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STGAGLUDC_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to send a message to all members of a
		GCN list, incrementing the app object's detach count for
		each message sent.

CALLED BY:	(INTERNAL) SendToGenAppGCNListUppingDetachCount via
       				ChunkArrayEnum
PASS:		*ds:si	= GCN list
		ds:di	= GCN list element
		*ds:bp	= GenApplication object
		ax	= message to send
RETURN:		carry clear to continue enumeration
DESTROYED:	cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STGAGLUDC_callback proc	far
	uses	bp, ax
	.enter
	mov	si, bp			; *ds:si = GenApp object
	call	ObjIncDetach		; INC for message we are about
					;	to send out
	clr	cx			; ACK ID
	mov	dx, ds:[LMBH_handle]	; active list objects ACK back here
					;	(dx:bp = GenApp object)
	mov	bx, ds:[di].GCNLE_item.handle	; ^lbx:si = object to detach
	mov	si, ds:[di].GCNLE_item.chunk
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	clc				; continue enumeration
	.leave
	ret
STGAGLUDC_callback endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenAppNestedDetach

DESCRIPTION:	Handle case of nested detach

CALLED BY:	INTERNAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	cx	- caller's ID
	dx:bp	- ackOD		(The application process itself)

	NOTE:  the app process takes advantage of the passing parameters
	by storing an optr in here, which it will get back later.  The
	"hidden" data here is:

	dx	- process handle
	cx:bp	- OD of original ackOD sent in MSG_META_DETACH to process

RETURN:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version
------------------------------------------------------------------------------@


GenAppNestedDetach	proc	far	; (far for GOTO ObjMessage's sake)
	push	cx
	push	dx
	push	bp

	; Check to see if DETACH_DATA can be found in the vardata space for
	; this object, meaning that we've started a detach, but have not
	; yet finished detaching the generic object tree.
	;
        mov     ax, DETACH_DATA
        call    ObjVarFindData          ;ds:bx = data entry if found
        jnc     justACK			;not found, just ACK the nested detach

	; OK, we found one.  Now, here's the tricky part -- if the app is
	; being detach with a final ACK OD of NULL, as is the case when the
	; app is quit by the user, convert it to have an ACK OD of the new
	; DETACH requestor (such as a field), so that it won't exit until
	; we've finished detaching.

	tst	ds:[bx].DDE_callerID
	jnz	justACK
	pop	ds:[bx].DDE_ackOD.chunk
	pop	ds:[bx].DDE_ackOD.handle
	pop	ds:[bx].DDE_callerID
	ret

justACK:
	pop	bp
	pop	dx
	pop	cx
	; ABORT this DETACH.  Rather than sending ACK back to the process,
	; which will continue with the shutdown antics, send the ACK back
	; to the original caller, to let them know they should quit
	; worrying about us.
	;
	mov	ax, MSG_META_ACK						
	mov	bx, cx
	mov	si, bp
	clr	cx			; error code (none)
	clr	bp			; DX:BP is source of ack, our
					; 	process.
	mov	di, mask MF_FORCE_QUEUE					
	GOTO	ObjMessage						

GenAppNestedDetach	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppDetachComplete

DESCRIPTION:	Handle notification that the applications's children
		have finished detaching themselves.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_META_DETACH_COMPLETE

	cx - caller's ID
	dx:bp - OD for MSG_META_ACK	(application process)

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version
	Doug	12/89		Revised detach methodology

------------------------------------------------------------------------------@

GenAppDetachComplete	method	GenApplicationClass, MSG_META_DETACH_COMPLETE

	LOG	ALA_DETACH_COMPLETE

EC <	xchg	bx, dx							>
EC <	xchg	si, bp							>
EC <	call	ECCheckOD						>
EC <	xchg	bx, dx							>
EC <	xchg	si, bp							>

	; Call super to send MSG_META_ACK to process, which will then
	; respond with MSG_GEN_APPLICATION_CLOSE_COMPLETE when done.
	;
	mov	di, offset GenApplicationClass
	GOTO	ObjCallSuperNoLock

GenAppDetachComplete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppCloseComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Called from process after UI has been detached & 
		the apropriate CLOSE message has been called on the process.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_APPLICATION_CLOSE_COMPLETE

		^ldx:bp	= ack OD

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenAppCloseComplete	method	dynamic GenApplicationClass,
				MSG_GEN_APPLICATION_CLOSE_COMPLETE
	LOG	ALA_CLOSE_COMPLETE

	push	dx, bp		; save ack OD

	; Change application object state to indicate "NOT USABLE".  This
	; happens ONLY after the application generic tree has been detached, &
	; really is used as a flag for the rest of the detach mechanism.
	;
	andnf	ds:[di].GI_states, not mask GS_USABLE

	; NOTE! We can't clear the "AS_QUITTING" & AS_TRANSPARENT_DETACHING
	; flags here, because they are actually used by the process's
	; MSG_GEN_PROCESS_REAL_DETACH handler later, to know if the field
	; needs to be updated about the detach, or whether we're exiting for
	; a different reason that doesn't require the field to be updated.
	; These two flags are updated seperately.
	;
	andnf	ds:[di].GAI_states, not (mask AS_DETACHING or \
				mask AS_QUIT_DETACHING or \
				mask AS_RECEIVED_APP_OBJECT_DETACH)

	;
	; Sends off the IACP completion message that will let the client
	; know that whatever file it wants to use has been closed.  Has
	; no effect unless TEMP_*_FILE_CLOSE_EVENNT exists.
	;
	mov	ax, MSG_GEN_APPLICATION_CLOSE_FILE_ACK
	call	ObjCallInstanceNoLock

	; Release mouse grab, if we've got it

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_FLOW_RELEASE_MOUSE_IF_GRABBED
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	UserCallFlow

	;
	; let specific UI know also
	;
	mov	ax, MSG_GEN_APPLICATION_CLOSE_COMPLETE
	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock

	pop	dx, bp		; restore ack OD

	; Finally, figure out where we should go from here.
	;
	mov	ax, MSG_GEN_APPLICATION_APP_MODE_COMPLETE
	GOTO	ObjCallInstanceNoLock

GenAppCloseComplete	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppLazarus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the application back to life with the passed ALB

CALLED BY:	(INTERNAL) GenAppAppModeComplete
PASS:		*ds:si	= GenApplication object
		^hbx	= AppLaunchBlock to use in the resurrection
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppLazarus	proc	far
		class	GenApplicationClass
		.enter
		push	bx
		call	GenAppSwitchToAppMode
		pop	bx
		call	MemFree
		.leave
		ret
GenAppLazarus	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppGenSetUsable
METHOD:		GenAppGenSetNotUsable

DESCRIPTION:	Intercept MSG_GEN_SET_USABLE & MSG_GEN_SET_NOT_USABLE to
		warn developers that these methods may NOT be used on
		GenApplicationClass objects.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_GEN_SET_USABLE/MSG_GEN_SET_NOT_USABLE

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	6/3/92		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK
GenAppFatalError	method dynamic	GenApplicationClass,
						MSG_GEN_SET_USABLE,
						MSG_GEN_SET_NOT_USABLE
	ERROR	UI_ILLEGAL_REQUEST_OF_GEN_APPLICATION_OBJECT
GenAppFatalError	endm
endif


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppAppShutdown

DESCRIPTION:	Complete detach stuff - unlink from generic tree,
		clear out misc instance data.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass
	cx - data for MSG_META_SHUTDOWN_ACK
	^ldx:bp - optr for MSG_META_SHUTDOWN_ACK

	ax - MSG_META_APP_SHUTDOWN

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Revised detach methodology

------------------------------------------------------------------------------@

GenAppAppShutdown	method	GenApplicationClass, \
					MSG_META_APP_SHUTDOWN

	LOG	ALA_APP_SHUTDOWN

	call	ObjInitDetach
	mov	ax, MGCNLT_APP_STARTUP
	mov	di, MSG_META_APP_SHUTDOWN
	call	SendToGenAppGCNListUppingDetachCount

	mov	ax, MSG_META_APP_SHUTDOWN
	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock

	call	ObjEnableDetach
	;
	; Remove from removable disk list.
	;
	call	GenAppRemoveFromRemovableDiskList
	ret
GenAppAppShutdown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppShutdownComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish our processing of MSG_META_APP_SHUTDOWN

CALLED BY:	MSG_META_SHUTDOWN_COMPLETE
PASS:		*ds:si	= GenApplication object
		cx	= word o' data passed with MSG_META_APP_SHUTDOWN
		^ldx:bp	= object to notify of our finishing
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppShutdownComplete method dynamic GenApplicationClass, 
		       		MSG_META_SHUTDOWN_COMPLETE
	uses	cx, dx, bp
	.enter

	LOG	ALA_SHUTDOWN_COMPLETE

	; One last time, just before linkage is severed -- make sure app
	; doesn't have any exclusives  (App SHOULD have already released
	; this, but it is possible that an ill-behaved app could somehow
	; re-grab an exclusive before being nuked)
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, mask MAEF_FOCUS or mask MAEF_TARGET or mask MAEF_MODEL
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	GenCallParent		; Call our GenField parent, to release
					; any excl we may have

	; Tell any Field object we may be on that we want off.
	;
	; See if we actually are on a GenFieldClass object  (The UI app
	; sits under a GenScreenClass object)
	;
	mov	cx, segment GenFieldClass
	mov	dx, offset GenFieldClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	GenCallParent
	jnc	afterRemoved		; if not, skip removal notification

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GEN_FIELD_REMOVE_GEN_APPLICATION
	call	GenCallParent
afterRemoved:

	; Last thing before we nuke parent link -- have parent make sure 
	; there is a reasonable focus & target
	; 12/10/92: do this only if the app was focusable, as otherwise nothing
	; should have changed. This finesses a problem with the Lights Out
	; Launched exiting before geomanager has finished attaching, making the
	; field think it has nothing left with which the user can interact.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_FOCUSABLE
	jz	clearLink

	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	GenCallParent
clearLink:
	;
	; clear upward-only link to GenField
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GI_link.LP_next.handle, 0
	mov	ds:[di].GI_link.LP_next.chunk, 0

	call	ObjMarkDirty		; Change Gen instance data, mark dirty
	.leave

	;
	; Let our superclass send the ack for us.
	; 
	mov	di, offset GenApplicationClass
	mov	ax, MSG_META_SHUTDOWN_COMPLETE
	GOTO	ObjCallSuperNoLock
GenAppShutdownComplete endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppFinalObjFree

DESCRIPTION:	Free GenApplication GCN lists.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax - MSG_META_FINAL_OBJ_FREE

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/92		Initial version

------------------------------------------------------------------------------@

GenAppFinalObjFree	method	GenApplicationClass, MSG_META_FINAL_OBJ_FREE

	; Free GCN list of lists chunk, & list chunks, if in use here
	;
	mov	ax, MSG_META_GCN_LIST_DESTROY
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock
	ret
GenAppFinalObjFree	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppGetAppRef

DESCRIPTION:	Fetches data stored in GAI_appRef.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax	- MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE

RETURN: dx	- block handle of structure AppInstanceReference

ALLOWED TO DESTROY:
	ax, cx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenAppGetAppRef	method	dynamic GenApplicationClass, MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE
				; figure the number of bytes required to save
				; the disk handle
	mov	bx, ds:[di].GAI_appRef.AIR_diskHandle
	push	bx		; save handle for later DiskSave
	clr	cx
	call	DiskSave	; cx <- # bytes needed to save disk handle away

				; Get ds:si = GAI_appRef
	lea	si, ds:[di].GAI_appRef

				; Create block to return data in
	mov	ax, size AppInstanceReference
	add	ax, cx
	push	cx
	mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_SHARABLE or ALLOC_DYNAMIC_NO_ERR
	call	MemAlloc
	call	MemLock
	mov	dx, bx		; return block handle in dx
	mov	es, ax		; es:di = ptr to appRef 
	clr	di

	mov	cx, offset AIR_savedDiskData
	rep movsb		; Copy data over into block

	pop	cx		; recover buffer size for DiskSave
	pop	bx		;  and disk handle as well
	call	DiskSave

	mov	bx, dx		; bx <- memory block
	call	MemUnlock
	ret

GenAppGetAppRef	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenAppSetAppRef

DESCRIPTION:	Stores passed data in GAI_appRef.

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

	ax	- MSG_GEN_APPLICATION_SET_APP_INSTANCE_REFERENCE
	dx	- block handle of structure AppInstanceReference. any saved
		  disk handle should have already been restored.

RETURN:	nothing

ALLOWED TO DESTROY:
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

GenAppSetAppRef	method	dynamic GenApplicationClass, MSG_GEN_APPLICATION_SET_APP_INSTANCE_REFERENCE
				; Get ds:si = GAI_appRef
	add	di, offset GAI_appRef	;
	segmov	es, ds		;ES:DI <- ptr to dest for AppInstanceReference
	mov	bx, dx
	call	MemLock
	mov	ds, ax		; ds:di = ptr to appRef 
	clr	si		;
	mov	cx, size AppInstanceReference
	rep	movsb		; Copy data over into block
	GOTO	MemFree		;Free up the block handle
GenAppSetAppRef	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppSendAppInstanceReferenceToField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine sends the AppInstanceReference contained in the
		instance data off to the parent field for use in restarting
		the app.

CALLED BY:	GLOBAL

PASS:	*ds:si	- instance data
	ds:di - ptr to generic instance part
	es - segment of GenApplicationClass

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppSendAppInstanceReferenceToField	method GenApplicationClass, 
			MSG_GEN_APPLICATION_SEND_APP_INSTANCE_REFERENCE_TO_FIELD

	; See if we actually are on a GenFieldClass object  (The UI app
	; sits under a GenScreenClass object)
	;
	mov	cx, segment GenFieldClass
	mov	dx, offset GenFieldClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	GenCallParent
	jnc	done				;if not, don't create blcok
						;that we'd have to get rid of

	mov	ax, MSG_GEN_APPLICATION_GET_APP_INSTANCE_REFERENCE
	call	ObjCallInstanceNoLock		;Get our AppInstanceReference

	mov	ax, MSG_GEN_FIELD_ADD_APP_INSTANCE_REFERENCE
	mov	bp, ds:[LMBH_handle]		;BP <- handle of our block
	call	GenCallParent			;Send ref to our parent

done:
	ret
GenAppSendAppInstanceReferenceToField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppTransparentDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach application because the system needs more heap space,
		& we're running in transparent detach mode.

CALLED BY:	MSG_META_TRANSPARENT_DETACH

PASS:		*ds:si	= GenApplication object
		ds:di	= GenApplication instance data
		es 	= segment of GenApplicationClass
		ax	= MSG_META_TRANSPARENT_DETACH

RETURN:		nothing

ALLOWED TO DESTROYED:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/20/92  	Initial version
	doug	3/3/93		Switched to meta message, sent by kernel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppTransparentDetach	method	dynamic	GenApplicationClass,
					MSG_META_TRANSPARENT_DETACH

	; If already detaching in any form, just ignore this request -- we'll
	; be gone soon, satisfying the request.
	;
	test	ds:[di].GAI_states, mask AS_TRANSPARENT_DETACHING or \
					mask AS_DETACHING or \
					mask AS_QUIT_DETACHING
	jnz	done

	; If not usable, must already be on our way out, so bail.
	;
	test	ds:[di].GI_states, mask GS_USABLE
	jz	done

					; Note that we are starting a
					;	transparent detach
	ornf	ds:[di].GAI_states, mask AS_TRANSPARENT_DETACHING

	; Let superclass do any cleanup it needs to do
	;
	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock

	;
	; Send MSG_META_DETACH to process (matching logic in
	; GenFieldShutdownApps)
	;
	call	GeodeGetProcessHandle	; bx = process
	clr	cx, dx, bp		; no ACK needed
	mov	ax, MSG_META_DETACH
	mov	di, mask MF_FORCE_QUEUE	; in case of single-threaded app, let's
					;	make sure we finish up
	GOTO	ObjMessage

done:
	ret

GenAppTransparentDetach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppRemoveFromTransparentDetachLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes app obj from transparent detach list, if it is on it

CALLED BY:	INTERNAL
		GenAppTransparentDetach
		UI_Detach
PASS:		cx	- GeoWorks GCNList to keep on, if any
			  (i.e. don't remove from this one).
			  Pass 0 to remove from all lists.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppRemoveFromTransparentDetachLists	proc	far
	uses	ax, bx, cx, dx
	.enter
	;
	; Take ourselves off the transparent detach lists, if we're on there
	;
	mov	ax, GCNSLT_TRANSPARENT_DETACH
	call	GCNListRemoveIfNoMatch
	mov	ax, GCNSLT_TRANSPARENT_DETACH_FULL_SCREEN_EXCL
	call	GCNListRemoveIfNoMatch
	mov	ax, GCNSLT_TRANSPARENT_DETACH_DA
	call	GCNListRemoveIfNoMatch
	.leave
	ret
GenAppRemoveFromTransparentDetachLists	endp

GCNListRemoveIfNoMatch		proc	near
	cmp	ax, cx
	je	done
	push	cx
	call	GetTransparentDetachListParams
	call	GCNListRemove
	pop	cx
done:
	ret
GCNListRemoveIfNoMatch		endp

GetTransparentDetachListParams	proc	near
	uses	si
	.enter
	clr	bx
	call	GeodeGetAppObject
	mov	cx, bx
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	.leave
	ret
GetTransparentDetachListParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppRemoveFromRemovableDiskList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes app obj from removable disk list, if it is on it

CALLED BY:	INTERNAL
		GenAppTransparentDetach
		UI_Detach
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppRemoveFromRemovableDiskList	proc	far
	uses	ax, bx, cx, dx
	.enter
	;
	; Take ourselves off GCNSLT_REMOVABLE_DISK list, if we're on it.
	;
	call	GetRemovableDiskListParams
	call	GCNListRemove
	.leave
	ret
GenAppRemoveFromRemovableDiskList	endp

GenAppAddToRemovableDiskList	proc	far
	uses	ax, bx, cx, dx
	.enter
	;
	; Add ourselves to the GCNSLT_REMOVABLE_DISK list, if we're not
	; on it.
	;
	call	GetRemovableDiskListParams
	call	GCNListAdd
	.leave
	ret
GenAppAddToRemovableDiskList	endp

GetRemovableDiskListParams	proc	near
	uses	si
	.enter
	clr	bx
	call	GeodeGetAppObject
	mov	cx, bx
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_REMOVABLE_DISK
	.leave
	ret
GetRemovableDiskListParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppUpdateTransparentDetachLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update whether we're on ia transparent detach list or not
		NOTE:  Will not move us between lists, will just remove from
		all or add to specific, so if something's changed *which* list
		we should go on, object should be removed from all lists first,
		before calling here.

CALLED BY:	INTERNAL
PASS:		*ds:si	- GenApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppUpdateTransparentDetachLists	proc	far	uses	es
	.enter
	mov	ax, segment uiLaunchModel
	mov	es, ax

	; If still starting up UI, then don't know launch model yet.
	;
	test	es:[uiFlags], mask UIF_INIT
	jnz	done			; if still starting up, bail

	; See if doing transparent detach
	;
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	jne	done			; if not, bail

	; If actually using these things, call self to figure out which list
	; we should be on.
	;
	mov	ax, MSG_GEN_APPLICATION_GET_TRANSPARENT_DETACH_LIST
	call	ObjCallInstanceNoLock
	tst	ax
	jz	remove

	push	cx			; Remove from all lists but this one
	call	GenAppRemoveFromTransparentDetachLists
					; The add ourselves to it, if not
					; already on.
	call	GetTransparentDetachListParams
	pop	ax
	call	GCNListAdd
done:
	.leave
	ret

remove:
	clr	cx			; Remove from all lists
	call	GenAppRemoveFromTransparentDetachLists
	jmp	short done

GenAppUpdateTransparentDetachLists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppGetTransparentDetachList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Fetch GeoWorks Transparent Detach GCN list this app should
		be on/is on, if any.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_APP_GET_TRANSPARENT_DETACH_LIST

		nothing

RETURN:		ax	- GeoWorks transparent detach GCN list app should be
			  placed on/is on, if any

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppGetTransparentDetachList	method GenApplicationClass,
				MSG_GEN_APPLICATION_GET_TRANSPARENT_DETACH_LIST
	.enter
	mov	ax, segment uiLaunchModel
	mov	es, ax

	; If still starting up UI, then don't know launch model yet.
	;
	test	es:[uiFlags], mask UIF_INIT
	jnz	none			; if still starting up, bail

	; See if doing transparent detach
	;
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	jne	none			; if not, bail

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	; Can't be transparently detachable if we aren't open in app mode.
	;
	test	ds:[di].GI_states, mask GS_USABLE
	jz	none

	; Can't be transparently detachable if we have any IACP connections open
	;
	mov	ax, MSG_GEN_APPLICATION_IACP_GET_NUMBER_OF_CONNECTIONS
	call	ObjCallInstanceNoLock
	tst	cx
	jnz	none

	; Can't be transparently detachable if not interactable, avoiding
	; transparent detach, or attaching or detaching in any form.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_NOT_USER_INTERACTABLE or \
					mask AS_AVOID_TRANSPARENT_DETACH or \
					mask AS_TRANSPARENT_DETACHING or \
					mask AS_ATTACHING or \
					mask AS_DETACHING or \
					mask AS_QUIT_DETACHING
	jnz	none

	mov	cx, GCNSLT_TRANSPARENT_DETACH	; default

	; Different logic for desk accessory & full screen apps
	;
	test	ds:[di].GAI_launchFlags, mask ALF_DESK_ACCESSORY
	jnz	deskAccessory

;fullScreenApp:
	test	ds:[di].GAI_states, mask AS_HAS_FULL_SCREEN_EXCL
	jz	thisOne

	mov	cx, GCNSLT_TRANSPARENT_DETACH_FULL_SCREEN_EXCL
	jmp	short thisOne

deskAccessory:
	; If we are a desk accessory, check to see if now floating, or
	; hidden in back as a "cached" app.
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	call	ObjVarFindData
	jnc	thisOne			; if not found, place on full screen
					; if found, full-screen list if low
					; prio
	cmp	{LayerPriority} ds:[bx], LAYER_PRIO_STD
	jae	thisOne
					; Otherwise, we've passed all the tests.
					; We're up there where the user can
					; see us, so put ourselves on the
					; DA list.
	mov	cx, GCNSLT_TRANSPARENT_DETACH_DA
thisOne:
	mov	ax, cx			; Return GCN List
	.leave
	ret

none:
	clr	cx
	jmp	short thisOne

GenAppGetTransparentDetachList	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppGainedFullScreenExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle gaining of full screen excl

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- message

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppGainedFullScreenExcl	method	dynamic	GenApplicationClass,
					MSG_META_GAINED_FULL_SCREEN_EXCL
	;
	; send notification to GAGCNLT_FULL_SCREEN_EXCL_CHANGE list
	;
	call	UpdateFullScreenExclGCN
	mov	ax, MSG_META_GAINED_FULL_SCREEN_EXCL
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	
	ornf	ds:[di].GAI_states, mask AS_HAS_FULL_SCREEN_EXCL
	call	GenAppAdjustTDLists
	;
	; Let the Mailbox library know there's a new foreground app in town.
	; 
	mov	bx, ds:[LMBH_handle]
	call	IACPPrepareMailboxNotify	; bxcxdx <- app's token
						; si <- SST_MAILBOX
	mov	di, MSN_NEW_FOCUS_APP
	call	SysSendNotification
	ret
GenAppGainedFullScreenExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFullScreenExclGCN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update GAGCNLT_FULL_SCREEN_EXCL_CHANGE GCN list

CALLED BY:	GenAppGainedFullScreenExcl, GenAppLostFullScreenExcl
PASS:		ax - gained/lost message
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateFullScreenExclGCN	proc	near
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_FULL_SCREEN_EXCL_CHANGE
	mov	ss:[bp].GCNLMP_block, 0
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, 0
	mov	ax, MSG_META_GCN_LIST_SEND
	call	ObjCallInstanceNoLock
	add	sp, size GCNListMessageParams
	ret
UpdateFullScreenExclGCN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppLostFullScreenExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle gaining of full screen excl

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- message

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppLostFullScreenExcl	method	dynamic	GenApplicationClass,
					MSG_META_LOST_FULL_SCREEN_EXCL
	;
	; dismiss help so that switching to new app won't confusingly leave
	; old app's help dialog up - brianc 6/9/93
	; (responder does this on GEN_BRING_TO_TOP, below)
	;
	push	si, ax
	mov	bx, handle SysHelpObject
	mov	si, offset SysHelpObject

	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, ax
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	andnf	ds:[di].GAI_states, not mask AS_HAS_FULL_SCREEN_EXCL
	mov	ax, MSG_META_LOST_FULL_SCREEN_EXCL
	call	GenAppAdjustTDLists

	;
	; send notification to GAGCNLT_FULL_SCREEN_EXCL_CHANGE list
	;
	mov	ax, MSG_META_LOST_FULL_SCREEN_EXCL
	call	UpdateFullScreenExclGCN
	ret
GenAppLostFullScreenExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenAppAdjustTDLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update which GCN app detach list we're on, or whether we're
		on one at all.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- message

RETURN:		per message	

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenAppAdjustTDLists	method	static	GenApplicationClass,
					MSG_GEN_BRING_TO_TOP,
					MSG_GEN_LOWER_TO_BOTTOM
;;; (statically called from above)	MSG_META_LOST_FULL_SCREEN_EXCL
;;;					MSG_META_GAINED_FULL_SCREEN_EXCL


	mov	di, offset GenApplicationClass
	call	ObjCallSuperNoLock


	; Remove, add back app to transparent detach list if appropriate,
	; to put it at the back of the LRU queue
	;
	pushf					; why do we do this?
	push	ax, cx, dx, bp
	clr	cx			; Remove from all lists, as this
					; designates a "use" & we wish to
					; be added back onto the end of whatever
					; list we're already on.
	call	GenAppRemoveFromTransparentDetachLists
	call	GenAppUpdateTransparentDetachLists
	pop	ax, cx, dx, bp
	popf
	ret
GenAppAdjustTDLists	endm

AppDetach	ends
