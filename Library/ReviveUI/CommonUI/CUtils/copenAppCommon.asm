COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		OpenLook/Open
FILE:		copenAppCommon.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLApplicationClass	Open look Application class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenApplication.asm

DESCRIPTION:

	$Id: copenAppCommon.asm,v 1.46 97/04/03 16:06:08 brianc Exp $

------------------------------------------------------------------------------@

if _RUDY
idata	segment

indicatorPrimaryWindow	hptr	0	; handle of indicator primary window.
					; This is to be passed to
					; WinChangePriority, in case we have
					; to raise indicator.

indicatorWindowMutex	Semaphore<1,>	; allow only one routine which
					; reads / writes 
					; indicatorPrimaryWindow to be 
					; executing at a time.

helpWindowIsUp	BooleanWord FALSE	; When help is up,
					; always raise the indicator

idata	ends

endif		; RUDY

AppCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationExpressMenuChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of the creation of an express menu to add a trigger
		for ourselves in GEOS tasks list.

CALLED BY:	MSG_NOTIFY_EXPRESS_MENU_CHANGE
PASS:		bp	= GCNExpressMenuNotificationType
		^lcx:dx	= optr of affected Express Menu Control
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLApplicationExpressMenuChange method dynamic OLApplicationClass, 
				      MSG_NOTIFY_EXPRESS_MENU_CHANGE
	uses	ax, cx, dx, bp, si
	.enter

	cmp	bp, GCNEMNT_CREATED
	jne	destroy
	;
	; New express menu created, so create a GEOS tasks list item
	;	^lcx:dx = new ExpressMenuControl
	;
	mov	ax, si		; *ds:ax = OLApplication

	call	GenFindParent	; ^lbx:si = parent field
	xchgdw	bxsi, cxdx	; ^lcx:dx = parent field
				; ^lbx:si = new ExpressMenuControl

	sub	sp, size CreateExpressMenuControlItemParams
	mov	bp, sp
	mov	ss:[bp].CEMCIP_feature, CEMCIF_GEOS_TASKS_LIST
	mov	ss:[bp].CEMCIP_class.segment, segment OLAppTaskItemClass
	mov	ss:[bp].CEMCIP_class.offset, offset OLAppTaskItemClass
	mov	ss:[bp].CEMCIP_itemPriority, CEMCIP_STANDARD_PRIORITY
	mov	ss:[bp].CEMCIP_responseMessage, MSG_OL_APPLICATION_GEOS_TASKS_LIST_ITEM_CREATED
						; send response back here
	mov	ss:[bp].CEMCIP_responseDestination.chunk, ax
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].CEMCIP_responseDestination.handle, ax
	mov	ss:[bp].CEMCIP_field.handle, cx
	mov	ss:[bp].CEMCIP_field.chunk, dx
	mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
	mov	dx, size CreateExpressMenuControlItemParams
	mov	di, mask MF_STACK
	call	ObjMessage
	add	sp, size CreateExpressMenuControlItemParams
callSuper:
	.leave
	mov	di, offset OLApplicationClass
	GOTO	ObjCallSuperNoLock

destroy:
	mov	si, ds:[di].OLAI_appMenuItems
	tst	si
	jz	noDestroy
	mov	bx, cs
	mov	di, offset OLAEMC_callback
	call	ChunkArrayEnum
noDestroy:
	jmp	callSuper
OLApplicationExpressMenuChange endm

;
; pass:		*ds:si = chunk array
;		ds:di = CreateExpressMenuControlItemResponseParams
;		^lcx:dx = destroyed Express Menu Control
; return:	carry clear to continue enumeration if no match
;		carry set to stop enumeration if match
;
OLAEMC_callback	proc	far
	cmp	cx, ds:[di].CEMCIRP_expressMenuControl.handle
	jne	notFound
	cmp	dx, ds:[di].CEMCIRP_expressMenuControl.chunk
	jne	notFound
	pushdw	cxdx
	movdw	bxax, ds:[di].CEMCIRP_expressMenuControl
	movdw	cxdx, ds:[di].CEMCIRP_newItem
	call	ChunkArrayDelete
	mov	si, ax				; ^lbx:si = EMC
	mov	ax, MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM
	mov	bp, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	popdw	cxdx
	stc					; stop enumeration
	jmp	short done

notFound:
	clc					; continue enumeration
done:
	ret
OLAEMC_callback	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLAppSendToFlow

DESCRIPTION:	Can't use default VisContent behavior just yet, so relay
		this onto the flow object (a transition step)

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- METHOD to pass on
		cx, dx, bp - data to pass on

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

------------------------------------------------------------------------------@

OLAppSendToFlow	method dynamic	OLApplicationClass,
			MSG_VIS_VUP_TERMINATE_ACTIVE_MOUSE_FUNCTION, \
			MSG_VIS_VUP_GET_MOUSE_STATUS, \
			MSG_VIS_VUP_BUMP_MOUSE
	mov	di, mask MF_CALL
	GOTO	UserCallFlow

OLAppSendToFlow	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLApplicationUpdateTaskEntry

DESCRIPTION:	Update this application's GenItem which is in the
		ApplicationMenu.

PASS:		ds:*si	- instance data
		cx = TRUE if application has focus

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OLApplicationUpdateTaskEntry	method dynamic	OLApplicationClass, \
					MSG_OL_APP_UPDATE_TASK_ENTRY
	;
	; Find the TaskItem we created earlier, that's on the Express menu
	;
	mov	dx, si			; *ds:dx = OLApplication
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLAI_appMenuItems
	tst	si
	jz	done			;skip if none...

	; Get parent window in bp
	; (needed for MSG_OL_APP_ITEM_SET_OPERATING_PARAMS)
	;
	mov	bp, ds:[di].OLAI_fieldWin

	mov_tr	ax, cx			; ax = TRUE if application has focus
	mov	cx, ds:[LMBH_handle]	; app obj in ^lcx:dx,

	; Setup each OLAppTaskItem object to have the info it will need to
	; function correctly.
	;	ax = TRUE if application has focus
	;	^lcx:dx = OLApplication object
	;	bp = field win
	;	*ds:si = chunk array of
	;			CreateExpressMenuControlItemResponseParams
	;
	mov	bx, cs			; bx:si = callback routine
	mov	di, offset OLAUTE_callback
	call	ChunkArrayEnum

done:
	ret
OLApplicationUpdateTaskEntry	endm

;
; pass:	*ds:si = chunk array
;	ds:di = CreateExpressMenuControlItemResponseParams
;	ax = TRUE if application has focus
;	^lcx:dx = OLApplication object
;	bp = field window
; return:
;	carry clear to continue enumeration
;
OLAUTE_callback	proc	far
	uses	ax, cx, dx, bp
	.enter

					; ^lbx:si = new item (may be run by
					;	different thread!)
	movdw	bxsi, ds:[di].CEMCIRP_newItem

	push	ax			; save flag
	mov	ax, MSG_OL_APP_TASK_ITEM_SET_OPERATING_PARAMS
	mov	di, mask MF_FIXUP_DS	;no MF_CALL
	call	ObjMessage
	pop	cx

	;
	; if we are setting a selection, make sure the set selection message
	; gets process after any clear selection messages
	;	cx = TRUE if app has focus
	;
	mov	di, mask MF_FORCE_QUEUE or \
			mask MF_INSERT_AT_FRONT or \
			mask MF_FIXUP_DS
	jcxz	haveMF
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
haveMF:

	mov	ax, MSG_OL_APP_TASK_ITEM_SET_EXCLUSIVE
	call	ObjMessage
done:
	clc

	.leave
	ret
OLAUTE_callback	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationGetMeasurementType --
		MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE for OLApplicationClass

DESCRIPTION:	Return the application's measurement type

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - The method

RETURN:
	al - MeasurementType (either metric or US)
	ah - AppMeasurementType (in application)
	cx, dx, bp - same

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/90		Initial version

------------------------------------------------------------------------------@
OLApplicationGetMeasurementType	method dynamic	OLApplicationClass,
					MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE
	uses	cx, dx, bp
	.enter

	mov	al, ds:[di].OLAI_units
	mov	ah, al
	cmp	al, AMT_DEFAULT
	jnz	noMapping

	; Get default units from localization driver

	push	ax				;save application measurement
	call	LocalGetMeasurementType		;returns measurement type in al
	pop	cx				;restore app measurement in ch
	mov	ah, ch				;put in ah
noMapping:

	.leave
	ret
OLApplicationGetMeasurementType	endm

AppCommon	ends
AppCommon segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLAppVisUpwardQuery

DESCRIPTION:	Respond to a query traveling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - MSG_VIS_VUP_QUERY

	cx - Query type (VisQueryType or SpecVisQueryType)
	dx -?
	bp -?
RETURN:
	carry - set if query acknowledged, clear if not
	ax, cx, dx, bp - data if query acknowledged

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/91		Initial version

------------------------------------------------------------------------------@

OLAppVisUpwardQuery	method	dynamic OLApplicationClass, MSG_VIS_VUP_QUERY

	; Send ALL visual upward queries to parent, the field, to avoid
	; default vis behavior of return info based on this object instead
	; of field/screen
	;
	GOTO	VisCallParent

OLAppVisUpwardQuery	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationQupQueryVisParent -- MSG_SPEC_GUP_QUERY_VIS_PARENT
					for OLApplicationClass

DESCRIPTION:	Respond to a query traveling up the generic composite tree.

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass
	ax - MSG_SPEC_GUP_QUERY_VIS_PARENT

	cx - GenQueryType	(Defined in genClass.asm)
		SQT_VIS_PARENT_FOR_FIELD
		SQT_VIS_PARENT_FOR_APPLICATION
		SQT_VIS_PARENT_FOR_PRIMARY
		SQT_VIS_PARENT_FOR_DISPLAY
		SQT_VIS_PARENT_FOR_POPUP
		SQT_VIS_PARENT_FOR_URGENT
		SQT_VIS_PARENT_FOR_SYS_MODAL


RETURN:
	carry - set if query acknowledged, clear if not
	cx:dx - obj descriptor of visual parent to use, null if not acknowledged
	bp    - window handle to use

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	VIS_PARENT_FOR_PRIMARY		-> This object, field window
	VIS_PARENT_FOR_DISPLAY		-> This object, field window
	VIS_PARENT_FOR_POPUP		-> This object, field window
	VIS_PARENT_FOR_URGENT		-> This object, field window
	VIS_PARENT_FOR_SYS_MODAL	-> This object, screen window

	All others:  pass on to superclass

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Doug	5/91		Changed to return THIS object, now IsoContent

------------------------------------------------------------------------------@
OLApplicationGupQueryVisParent	method dynamic	OLApplicationClass, \
					MSG_SPEC_GUP_QUERY_VIS_PARENT
	;
	; See if we can handle query
	;
	cmp	cx, SQT_VIS_PARENT_FOR_PRIMARY
	je	thisObject
	cmp	cx, SQT_VIS_PARENT_FOR_DISPLAY
	je	thisObject
	cmp	cx, SQT_VIS_PARENT_FOR_POPUP
	je	thisObject
	cmp	cx, SQT_VIS_PARENT_FOR_URGENT
	je	thisObject
	cmp	cx, SQT_VIS_PARENT_FOR_SYS_MODAL
	jne	askParent

sysModalExcl:
	; For sys modal case, return this object's OD to be the visible parent,
	; but the screen window for a parent window.
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, ds:[di].OLAI_screenWin
	stc			; return query acknowledged
	ret


askParent:
	; If we don't know the answer, pass on...
	;
	mov	di, offset OLApplicationClass
	CallSuper	MSG_SPEC_GUP_QUERY_VIS_PARENT
	jc	exit		; something ultimately found, exit
	clr	cx, dx		; else return cx:dx = null
	jmp	short exit

thisObject:
				; Return THIS object for visible parent
	mov	cx, ds:[LMBH_handle]
	mov	dx, si

	call	VisQueryWindow	; If a window handle exists for this
				; application, return it in bp
	mov	bp, di

	stc			; return query acknowledged
exit:
	ret

OLApplicationGupQueryVisParent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationGupQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Answer a generic query or two, specifically the
		SGQT_BUILD_INFO query so that dialog boxes under the app
		object don't try & put buttons on the field.

CALLED BY:	MSG_SPEC_GUP_QUERY
PASS:		*ds:si	= instance data
		cx	= query type (GenQueryType or SpecGenQueryType)
		bp	= OLBuildFlags
RETURN:		carry	= set if acknowledged, clear if not
		bp	= OLBuildFlags
		cx:dx	= vis parent
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLApplicationGupQuery	method dynamic	OLApplicationClass, MSG_SPEC_GUP_QUERY
	cmp	cx, SGQT_BUILD_INFO	;fieldable?
	je	answer

	mov	di, offset OLApplicationClass	;Pass the buck to our superclass
	GOTO	ObjCallSuperNoLock

answer:
	clr	cx, dx			; Respond with NO visible parent.
					; Dlg boxes, etc. under the application
					; object should NOT have buttons
					; appearing anywhere.

EC <	test	bp, mask OLBF_REPLY					>
EC <	ERROR_NZ	OL_BUILD_FLAGS_MULTIPLE_REPLIES			>
	ORNF	bp, OLBR_TOP_MENU shl offset OLBF_REPLY
	stc

	ret
OLApplicationGupQuery	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLApplicationGenGupEnsureUpdateWindow

DESCRIPTION:	Handle window update.

PASS:
	*ds:si - instance data (offset through Vis_offset)

	cx - UpdateWindowFlags
	dl - VisUpdateMode

RETURN:
	carry set to stop gup (stops at GenApplication object)
	cx, dl - unchanged
	ax, dh, bp - destroyed
	
DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/11/92		Initial version

------------------------------------------------------------------------------@

OLApplicationGenGupEnsureUpdateWindow	method	OLApplicationClass,
					MSG_GEN_GUP_ENSURE_UPDATE_WINDOW

	stc				; stop gup
	Destroy	ax, dh, bp
	ret

OLApplicationGenGupEnsureUpdateWindow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationEnterLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle reciept of the various enter/leave messages generated
		by the window system, & relayed to us.  Send them on to the
		object owning the window.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_RAW_UNIV_ENTER, MSG_META_RAW_UNIV_LEAVE

		cx:dx	- InputOD of window
		bp	- handle of window

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLApplicationEnterLeave	method dynamic	OLApplicationClass,
						MSG_META_RAW_UNIV_ENTER,
						MSG_META_RAW_UNIV_LEAVE
	movdw	bxsi, cxdx
	clr	di
	call	ObjMessage		; send message on...

	ret
OLApplicationEnterLeave	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationImpliedWinChange

DESCRIPTION:	Handles notification that the implied window, or window that
		the mouse is in, when interacting with this application,
		has changed.

PASS:
	*ds:si - instance data
	es - segment of FlowClass

	ax - MSG_META_IMPLIED_WIN_CHANGE
        cx:dx	- Input OD of implied window, or 0 if no window has the
		  implied grab.
	bp      - window that ptr is in

	 
	  
RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@
OLApplicationImpliedWinChange	method dynamic	OLApplicationClass,
						MSG_META_IMPLIED_WIN_CHANGE
	; Save away full Implied Win info
	;
	mov	ds:[di].OLAI_impliedWin.MG_OD.handle, cx
	mov	ds:[di].OLAI_impliedWin.MG_OD.chunk, dx
	mov	ds:[di].OLAI_impliedWin.MG_gWin, bp

	call	OLAppUpdateImpliedWin	; update VCNI_impliedMouseGrab
	call	OLAppUpdatePtrImage	; & update the ptr image

	ret
OLApplicationImpliedWinChange	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLAppNotifyActiveMouseGrabWinChanged

DESCRIPTION:	Intercept change of active grab window here.
		Inform window system, so that it will present the correct ptr
		image for us.

PASS:		*ds:si 	- instance data
		es     	- segment of VisContentClass
		ax 	- MSG_VIS_CONTENT_NOTIFY_ACTIVE_MOUSE_GRAB_WIN_CHANGED

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/92		Initial version

------------------------------------------------------------------------------@

OLAppNotifyActiveMouseGrabWinChanged	method	OLApplicationClass,
			MSG_VIS_CONTENT_NOTIFY_ACTIVE_MOUSE_GRAB_WIN_CHANGED

	; Update geode w/new active window
	;
	mov	di, ds:[di].VCNI_activeMouseGrab.VMG_gWin

	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	call	WinGeodeSetActiveWin

	; If mouse grab suddenly released, update PIL_LAYER ptr image
	;
	tst	di
	jnz	done
	call	OLAppUpdatePtrImage
done:
	ret

OLAppNotifyActiveMouseGrabWinChanged	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationEnsureActiveFT

DESCRIPTION:	Checks to make sure that something within the app has the
		Focus & Target exclusives.  Called from within the UI,
		usually on the closure of a window, to give the Focus and/or
		Target to the next best location.  Click-to-type model
		is implemented using the following rules:

		For Target, the priority order is:
			1) Anything already having the exclusive
			2) Top targetable PRIO_STD priority level window
			3) Top targetable PRIO_COMMAND priority level window

		For Focus, priority goes to:

			1) Anything already having the exclusive
			2) Top system modal window
			3) Top application modal window
			4) Last non-modal window to have or request the
			   exclusive
			5) Window having Target exclusive
			6) Top focusable PRIO_STD priority level window
			7) Top focusable PRIO_COMMAND priority level window

		Note that this message just tires to make sure that something
		DOES have the focus & target.  It does not go out of its
		way to forcibly change these exclusives to any particular
		location.  Thus, it is still the responsibility of windows
		to request the exclusives when they are due them, generally
		when being initiated to the front of the screen.

CALLED BY AS OF 2/22/92:
        OLApplicationGainedFocusExcl, method OLApplicationClass, \
                                        MSG_META_GAINED_FOCUS_EXCL
        OLBaseWinDismiss, method OLBaseWinClass, MSG_GEN_DISMISS_INTERACTION
        OpenWinLowerToBottom, method OLWinClass, MSG_GEN_LOWER_TO_BOTTOM
        OLDialogWinGenApply, method OLDialogClass, MSG_GEN_APPLY
        OLMenuedWinGenSetNotMinimized, method OLMenuedWinClass, \
                                        MSG_GEN_SET_NOT_MINIMIZED
        OLPopupDismiss
                OLDialogWinInteractionCommand, method OLDialogWinClass, \
                                        MSG_GEN_GUP_INTERACTION_COMMAND
                OLPopupInteractionCommand, method OLPopupWinClass, \
                                        MSG_GEN_GUP_INTERACTION_COMMAND
PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - MSG_META_ENSURE_ACTIVE_FT

RETURN:
	Nothing

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	Does NOT yet check to make sure that windows are focusable or
	targetable -- if they aren't it will just go ahead & ask them 
	to do it anyway (which they won't), but then won't move on to find
	the next window that will...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@
OLApplicationEnsureActiveFT	method dynamic	OLApplicationClass, \
				MSG_META_ENSURE_ACTIVE_FT
	;
	; TARGET
	;
	; Make sure we've got a target window.  If not, give target
	; win exclusive to top-most primary window
	;

	;		1) Anything already having the exclusive
	cmp	ds:[di].VCNI_targetExcl.FTVMC_OD.handle, 0
	jnz	targetDone

if _RUDY
	;		1.5) Top targetable PRIO_MODAL priority level window
	mov	cl, WIN_PRIO_MODAL
	call	AppFindTopWinOfPriority
	tst	cx
	jz	tryNext
	push	bx, si, cx, dx
	movdw	bxsi, cxdx			; ^lbx:si = potential target
	mov	ax, MSG_GEN_GET_ATTRIBUTES
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cl = GenAttrs
	test	cl, mask GA_TARGETABLE		; targetable?
	pop	bx, si, cx, dx
	jnz	giveTarget			; only if targetable
tryNext:
endif

	;		2) Top targetable PRIO_STD priority level window
	mov	cl, WIN_PRIO_STD
	call	AppFindTopWinOfPriority
	tst	cx
	jnz	giveTarget

	;		3) Top targetable PRIO_COMMAND priority level window
	mov	cl, WIN_PRIO_COMMAND
	call	AppFindTopWinOfPriority
	jcxz	targetDone

giveTarget:
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjMessageCallPreserveCXDXWithSelf
targetDone:

	; FOCUS
	;
	; If not the active application, then don't bother looking for a
	; focus window; no one will get the focus anyone, & no one will
	; even be curious about it.  Skip to choose a target however, which
	; won't scan windows if there is already a target -- some apps
	; may query to find the target within the app, so this might prove
	; useful.  This optimization is somewhat of a hack, as we're really
	; just trying to avoid loading in all of Welcome's resources when
	; the Express menu goes away (damn, non-conforming window has Welcome
	; as it's parent, & this method gets sent there)  This is a relatively
	; easy fix for a problem that appears to have no nasty side effects
	; other than loading in resources.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	test	ds:[di].OLAI_flowFlags, mask AFF_FOCUS_APP
	jz	focusDone

	;		1) Anything already having the exclusive
	tst	ds:[di].VCNI_focusExcl.FTVMC_OD.handle
	jnz	focusDone

	;		2) Top system modal window
	;		3) Top application modal window
	mov	cx, ds:[di].OLAI_modalWin.handle
	mov	dx, ds:[di].OLAI_modalWin.chunk
	tst	cx
	jnz	giveFocus

	;		4) Last non-modal window to have or request the
	;		   exclusive
	mov	cx, ds:[di].OLAI_nonModalFocus.handle
	mov	dx, ds:[di].OLAI_nonModalFocus.chunk
	tst	cx
	jnz	giveFocus

	;		5) Window having Target exclusive
	mov	cx, ds:[di].VCNI_targetExcl.FTVMC_OD.handle
	mov	dx, ds:[di].VCNI_targetExcl.FTVMC_OD.chunk
	tst	cx
	jnz	giveFocus

	;		6) Top focusable PRIO_STD priority level window
	mov	cl, WIN_PRIO_STD
	call	AppFindTopWinOfPriority
	tst	cx
	jnz	giveFocus

	;		7) Top focusable PRIO_COMMAND priority level window
	mov	cl, WIN_PRIO_COMMAND
	call	AppFindTopWinOfPriority
	jcxz	focusDone

giveFocus:
	; Ask window to grab the focus exclusive for itself.
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjMessageCallPreserveCXDXWithSelf
focusDone:

	call	OLAppUpdateFocusActivity	; Update focusExcl data
						; (If ignore input mode,
						; keep kbd data from flowing)


	call	OLAppUpdateImpliedWin		; update VCNI_impliedMouseGrab
	call	OLAppUpdatePtrImage		; & update the ptr image

	call	OLAppUpdateFlowHoldUpState	; Update hold-up state

;
; not needed yet - brianc 1/26/93
; turned on for Express Menu focus problems - brianc 2/23/93
;
if 1
	;
	; check to see if something has the focus
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].VCNI_focusExcl.FTVMC_OD.handle
	jnz	afterFocusCheck
	;
	; if not, send notification to ourselves (note that we force queue
	; this, so handlers should check if a focus hasn't been established
	; in the meanwhile)
	;
	mov	ax, MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
afterFocusCheck:
endif

	ret
OLApplicationEnsureActiveFT	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationNotifyModalChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Notification that the modal status of the application has
		changed in some way, either becoming modal, or becoming
		non-modal, or simply a change in which window is modal.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_APPLICATION_NOTIFY_MODAL_CHANGE

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLApplicationNotifyModalChange	method dynamic	OLApplicationClass, \
				MSG_GEN_APPLICATION_NOTIFY_MODAL_WIN_CHANGE

	; Test to see which window, if any, is the new top system modal or
	; modal window
	;
	call	AppFindTopSysModalWin	; First check for a system modal window
	tst	cx
	jnz	haveAnswer

	mov	cl, WIN_PRIO_MODAL	; Look for MODAL priority windows
	call	AppFindTopWinOfPriority	; Then check for an app-modal window

haveAnswer:

	; Store result of test
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLAI_modalWin.handle, cx
	mov	ds:[di].OLAI_modalWin.chunk, dx

	; If no modal window, clear AFF_OVERRIDE_INPUT_RESTRICTIONS flag.
	; Otherwise, ask the window itself whether it wants to override
	; input restrictions.
	;
	andnf    ds:[di].OLAI_flowFlags, \
				not mask AFF_OVERRIDE_INPUT_RESTRICTIONS
	jcxz	afterInputRestrictionsFlagSet
	push	si
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_INTERACTION_TEST_INPUT_RESTRICTABILITY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; returns carry set to override
	pop	si				; input restrictions
	jnc	afterInputRestrictionsFlagSet

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf    ds:[di].OLAI_flowFlags, \
				mask AFF_OVERRIDE_INPUT_RESTRICTIONS
afterInputRestrictionsFlagSet:

	call	OLAppUpdateFocusActivity	; Update focusExcl data
						; (If ignore input mode,
						; keep kbd data from flowing)
	call	OLAppUpdateFlowHoldUpState	; Update hold-up state
	call	OLAppUpdateImpliedWin	; update VCNI_impliedMouseGrab
	call	OLAppUpdatePtrImage

	call	SendOutModalChangeNotification	; In case there are interested
						;	parties....
	ret
OLApplicationNotifyModalChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendOutModalChangeNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends MSG_META_NOTIFY(GWNT_MODAL_WIN_CHANGE) to the
		GAGCNLT_MODAL_WIN_CHANGE list of the app object.

CALLED BY:	OLApplicationNotifyModalChange
PASS:		*ds:si	- GenApplication object
RETURN:
DESTROYED:	ax, bx, cx ,dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendOutModalChangeNotification	proc	near
	;
	; *ds:si - GenApplication object
	;
	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_MODAL_WIN_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage

	clr	ax
	push	ax				; GCNLMP_flags
	push	di				; GCNLMP_event
	push	ax				; GCNLMP_block
	mov	ax, GAGCNLT_MODAL_WIN_CHANGE
	push	ax				; GCNLT_type
	mov	ax, MANUFACTURER_ID_GEOWORKS
	push	ax				; GCNLT_manuf
	mov	dx, size GCNListMessageParams
	mov	bp, sp
	mov	ax, MSG_META_GCN_LIST_SEND
	call	ObjCallInstanceNoLock
	add	sp, size GCNListMessageParams

	ret
SendOutModalChangeNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLApplicationGetModalWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Returns current modal window, if any.  Used for printing,
		where one of the criteria of whether we're done or not
		is whether there's still a modal window up that the user
		hasn't responded to yet.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_APPLICATION_GET_MODAL_WIN

		nothing

RETURN:		^lcx:dx -	top modal window, if any

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLApplicationGetModalWin	method dynamic	OLApplicationClass, \
				MSG_GEN_APPLICATION_GET_MODAL_WIN
	mov	cx, ds:[di].OLAI_modalWin.handle
	mov	dx, ds:[di].OLAI_modalWin.chunk
	ret
OLApplicationGetModalWin	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	AppFindTopSysModalWin

DESCRIPTION:	Looks through all windows on screen for sys modal window
		of this application

CALLED BY:	INTERNAL

PASS:		*ds:si	- app object

RETURN:		cx:dx	- set to InputOD of first sys modal window which is
			  up on screen, which could take modal exclusive,
			else 0:0
		bp	- handle of window, else 0

DESTROYED:	nothing

	WARNING:  This routine MAY resize the LMem block, moving it on the
		  heap and invalidating stored segment pointers and current
		  register or stored offsets to it.
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version
------------------------------------------------------------------------------@
AppFindTopSysModalWin	proc	far
	uses	ax, bx, di
	.enter
	;
	; Look on screen window
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLAI_screenWin
	;
	; Check only windows owned by same geode as app object
	; 
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov_tr	ax, bx


	clr	bx		; any LayerID OK
				; restrict to sys modal windows
	mov	cx, (LAYER_PRIO_MODAL shl offset WPD_LAYER) or WIN_PRIO_MODAL
				; no focusable/targetable restrictions

if FIND_HIGHER_LAYER_PRIORITY
	call	FindHigherLayerPriorityWinOnWin
else
	call	FindWinOnWin
endif
	.leave
	ret
AppFindTopSysModalWin	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	AppFindTopWinOfPriority

DESCRIPTION:	Looks through all windows within the field having this 
		application's layerID for a modal window

CALLED BY:	INTERNAL

PASS:		*ds:si	- app object
		cl	- Window Priority level to look for

RETURN:		cx:dx	- set to InputOD of first app modal window which is
			  up on screen, which could take modal exclusive,
			else 0:0
		bp	- handle of window, else 0

DESTROYED:	nothing
	
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@
AppFindTopWinOfPriority	proc	far
	uses	ax, bx, si, di
	.enter

	;
	; Fetch di = window handle of field
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VCI_window

if (not _DUI)
	clr	ax			; All of this LayerID will be owned
					; by owner of this app obj, so no need
					; to check owner.
endif
	mov	bx, ds:[LMBH_handle]	; Get LayerID = geode handle
	call	MemOwner
if _DUI
	;
	; for _DUI, floating keyboard shares LayerID of app, so we must check
	; owner
	;
	mov	ax, bx
endif

	clr	ch		; no focusable/targetable restrictions
if FIND_HIGHER_LAYER_PRIORITY
	call	FindHigherLayerPriorityWinOnWin
else
	call	FindWinOnWin
endif
	.leave
	ret
AppFindTopWinOfPriority	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLAppTaskItemSetOperatingParams

DESCRIPTION:	Init OLAppTaskItem

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_OL_APP_TASK_ITEM_SET_OPERATING_PARAMS

	cx:dx	- app object
	bp	- field window

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version

------------------------------------------------------------------------------@

; NOTE!  This is *not* a handler for OLApplicationClass, but rather
; OLAppTaskItem.
;
OLAppTaskItemSetOperatingParams	method dynamic	OLAppTaskItemClass, \
				MSG_OL_APP_TASK_ITEM_SET_OPERATING_PARAMS
	mov	ds:[di].OLATI_appObj.handle, cx
	mov	ds:[di].OLATI_appObj.chunk, dx
	mov	ds:[di].OLATI_parentWin, bp
	ret
OLAppTaskItemSetOperatingParams	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLAppTaskItemSetMoniker

DESCRIPTION:	Set moniker for OLAppTaskItem

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_OL_APP_TASK_ITEM_SET_MONIKER

	^hcx	- block containing text vis moniker
			(freed afterwards)

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/12/92	Initial version

------------------------------------------------------------------------------@

; NOTE!  This is *not* a handler for OLApplicationClass, but rather
; OLAppTaskItem.
;
OLAppTaskItemSetMoniker	method dynamic	OLAppTaskItemClass, \
				MSG_OL_APP_TASK_ITEM_SET_MONIKER

	mov	bx, cx			; bx = block handle
	push	bx
	call	MemLock
	mov	cx, ax			; cx:dx = text moniker
	mov	dx, offset VM_data + offset VMT_text
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_NOW
	call	ObjCallInstanceNoLock
	pop	bx
	call	MemFree
	ret
OLAppTaskItemSetMoniker	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLAppTaskItemSetExclusive

DESCRIPTION:	Set exclusive in parent of OLAppTaskItem

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_OL_APP_TASK_ITEM_SET_EXCLUSIVE

	cx	- TRUE to set exclusive

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/12/92	Initial version

------------------------------------------------------------------------------@


; NOTE!  This is *not* a handler for OLApplicationClass, but rather
; OLAppTaskItem.
;
OLAppTaskItemSetExclusive	method dynamic	OLAppTaskItemClass, \
				MSG_OL_APP_TASK_ITEM_SET_EXCLUSIVE

					;gained or lost?
;	jcxz	updateGenList		;skip if lost target...
;let's try doing nothing if lost-target, as something else should gain-target
;- brianc 1/26/93
	jcxz	done

	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	call	ObjCallInstanceNoLock	;identifier in ax
	mov	cx, ax

updateGenList:
	clr	dx

	push	bx, si
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bx, segment GenItemGroupClass
	mov	si, offset GenItemGroupClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			;ClassedEvent to cx
	pop	bx, si			;^lbx:si is ListEntry

	; Send MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION to parent of
	; GenListEntry.
	;
	mov	dx, TO_GEN_PARENT
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	ObjCallInstanceNoLock
done:
	ret
OLAppTaskItemSetExclusive	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLAppTaskItemNotifyTaskSelected

DESCRIPTION:	Default handling for user "Switch to Task" request on this
		application, generally a result of user selecting this app
		from the Express menu

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_META_NOTIFY_TASK_SELECTED

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@

; NOTE!  This is *not* a handler for OLApplicationClass, but rather
; OLAppTaskItem.
;
OLAppTaskItemNotifyTaskSelected	method dynamic	OLAppTaskItemClass, \
					MSG_META_NOTIFY_TASK_SELECTED

	push	ds:[di].OLATI_appObj.handle
	push	ds:[di].OLATI_appObj.chunk

	; Raise app to top within field
	;
	mov	bx, ds:[di].OLATI_appObj.handle
	call	MemOwner			; Get owning geode
	mov	cx, bx
	mov	dx, bx				; which is also LayerID to raise
	mov	bp, ds:[di].OLATI_parentWin
	mov	ax, MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP
	call	UserCallSystem

	; Then pass on notification to the app object
	;
	pop	si
	pop	bx
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

done:
	ret

OLAppTaskItemNotifyTaskSelected	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationNotifyTaskSelected

DESCRIPTION:	Default handling for user "Switch to Task" request on this
		application, generally a result of user selecting this app
		from the Express menu

PASS:
	*ds:si - instance data
	es - segment of class

	ax - MSG_META_NOTIFY_TASK_SELECTED

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@
OLApplicationNotifyTaskSelected	method dynamic	OLApplicationClass, \
					MSG_META_NOTIFY_TASK_SELECTED

	; If detaching, not a good idea.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_DETACHING or \
					mask AS_NOT_USER_INTERACTABLE
        jnz     done

	push	si
	mov	bx, segment GenPrimaryClass
	mov	si, offset GenPrimaryClass
	mov	ax, MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
	mov	dl, VUM_NOW
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	mov	cx, di				; cx = event
	pop	si
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	call	ObjCallInstanceNoLock

	; If this is a transparent-detach mode Desk Accessory, bring back
	; to the top layer.
	;
	call	OLAppRaiseLayerPrioIfDeskAccessory

; This is done for us by the OLAppTaskItem, for synchronization purposes (the
; raising happens on the same thread as the notification of the selection of
; the task item, so if we're slow in responding to the selection, and the user
; chooses some other app from the express menu, we don't suddenly appear on top
; from out of nowhere)
;	mov	ax, MSG_GEN_BRING_TO_TOP
;	call	ObjCallInstanceNoLock

if (not _REDMOTIF)

	; Make sure field is on top as well, as if app is in a different
	; field than currently active, it will still not be able to
	; be interacted with without this step.
	;
	; (This screws up things in RedMotif.  I don't know how removing it
	;  will affect things, though.  10/25/93 cbh)
	;
	mov	ax, MSG_GEN_BRING_TO_TOP
	GOTO	GenCallParent
endif

done:
	ret

OLApplicationNotifyTaskSelected	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppRaiseLayerPrioIfDeskAccessory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this is a desk accessory, raise its layer priority to
		ON_TOP.  Does not affect focus/target, which must be dealt
		with seperately

CALLED BY:	INTERNAL
PASS:		*ds:si	- GenApplication
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLAppRaiseLayerPrioIfDeskAccessory	proc	far
if not _DUI		; no window layer changes for DAs in DUI
	uses	bx
	.enter
	;
	; If running as a desk accessory, raise layer priority to ON_TOP,
	; & bring windows up if present.  This is necessary both on startup
	; & if coming back to top after having being "Closed" by a user in
	; transparent launch mode, where we're really just pushed to the
	; back in a standard layer until called up again or transparently
	; detached.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_launchFlags, mask ALF_DESK_ACCESSORY
	jz	done

	; Set custom layer priority attribute so that future windows
	; will come up in the right layer.  Save to state so that we come
	; back in correct layer if shutdown, restored.
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY or \
				mask VDF_SAVE_TO_STATE
	mov	cx, size LayerPriority
	call	ObjVarAddData
	mov	{byte} ds:[bx], LAYER_PRIO_ON_TOP

	; Bring any opened windows back up to the top, w/new layer priority.

	call	VisQueryWindow		; Get window stored in app object,
					; which is really the field.
	tst	di
	jz	done
	mov	ax, mask WPF_LAYER or (LAYER_PRIO_ON_TOP shl offset WPD_LAYER)
	mov	bx, ds:[LMBH_handle]	; LayerID is owning geode handle
	call	MemOwner
	mov	dx, bx
	call	WinChangePriority	; Pop-her back to top.
done:
	.leave
endif
	ret
OLAppRaiseLayerPrioIfDeskAccessory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppLowerLayerPrioIfDeskAccessory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this is a desk accessory, lower its layer priority to STD.
		Does not deal with focus/target changes, which must be dealt
		with seperately.

CALLED BY:	INTERNAL
PASS:		*ds:si	- GenApplication
RETURN:		nothing
DESTROYED:	ax, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLAppLowerLayerPrioIfDeskAccessory	proc	far
	uses	bx
	.enter
	;
	; If a desk accessory, drop layer priority to STD.  This is useful
	; in transparent launch mode to get the app to go back to being
	; behind normal apps instead of actually "closing" it.  This has
	; the effect of adding it to the the app cache, where it can be
	; transparently detached or brought quickly back up.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_launchFlags, mask ALF_DESK_ACCESSORY
	jz	done

	; Change layer priority attribute to LAYER_PRIO_STD, so that future
	; windows come up in the standard layer.  We don't nuke the attribute,
	; which would do the same thing, because we want a record if we actually
	; saved to state (as opposed to being transparently detached, where
	; this attribute is nuked) that we were being "app-cached", so we
	; can come back that way.
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY or \
				mask VDF_SAVE_TO_STATE
	mov	cx, size LayerPriority
	call	ObjVarAddData
	mov	{byte} ds:[bx], LAYER_PRIO_STD

	; Push any opened windows to the bottom

	call	VisQueryWindow		; Get window stored in app object,
					; which is really the field.
	tst	di
	jz	done
	mov	ax, mask WPF_LAYER or (LAYER_PRIO_STD  shl offset WPD_LAYER)
	mov	bx, ds:[LMBH_handle]	; LayerID is owning geode handle
	call	MemOwner
	mov	dx, bx
	call	WinChangePriority	; Pop-her back to top.

done:
	.leave
	ret
OLAppLowerLayerPrioIfDeskAccessory	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationBringToTop

DESCRIPTION:	Brings whole application to the top.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_BRING_TO_TOP

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
	kho	1/24/96		Add indicator check for rudy

------------------------------------------------------------------------------@
OLApplicationBringToTop	method dynamic	OLApplicationClass, \
						MSG_GEN_BRING_TO_TOP
if _RUDY
	;
	; We need to check indicator position here, in addition to
	; "OpenWinOpenWin" and "OpenWinVisClose".
	;
	; This covers cases like: full screen fax document, then bring
	; up directory box, then press "Fax" hard icon so that fax
	; document tries to come up.
	;
	mov	ax, MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP
	call	OLAppRaiseLowerCommon
	;
	; Check indicator position
	;
	mov	ax, MSG_OL_APP_ENSURE_INDICATOR_CORRECT
	call	UserCallApplication
	ret
else
	mov	ax, MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP
	FALL_THRU	OLAppRaiseLowerCommon
endif
		
OLApplicationBringToTop	endp


OLAppRaiseLowerCommon	proc	far
	push	ax			; save method to call on sys obj

	mov	bp, ds:[di].OLAI_fieldWin

	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov	cx, bx			; geode
	mov	dx, bx			; & LayerID (geode handle)

	pop	ax
	call	UserCallSystem

	ret
OLAppRaiseLowerCommon	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationLowerToBottom

DESCRIPTION:	Brings whole application to the bottom, relinquishing focus,
	& passing it on to next app on top

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_LOWER_TO_BOTTOM

	cx, dx, bp - ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/90		Initial version

------------------------------------------------------------------------------@
OLApplicationLowerToBottom	method dynamic	OLApplicationClass,
					MSG_GEN_LOWER_TO_BOTTOM
	;
	; specify that we wish to stay in same layer (DA or normal app),
	; if possible
	;
	mov	bx, ds:[LMBH_handle]
	call	MemOwner			; bx = geode
	call	WinGeodeGetParentObj		; ^lcx:dx = parent obj
	mov	ax, LAYER_PRIO_STD shl offset WPD_LAYER	; assume not DA
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_launchFlags, mask ALF_DESK_ACCESSORY
	jz	havePref
	mov	ax, LAYER_PRIO_ON_TOP shl offset WPD_LAYER	; else, DA
havePref:
	push	si				; save OLApp chunk
	sub	sp, size EnsureActiveFTPriorityPreferenceData
	mov	bp, sp				; ss:bp = EAFTPPD
	mov	ss:[bp].EAFTPPD_priority, ax
	mov	ax, ds:[LMBH_handle]		; ^lax:si = OLApp handle
	mov	ss:[bp].EAFTPPD_avoidOptr.handle, ax
	mov	ss:[bp].EAFTPPD_avoidOptr.chunk, si
	movdw	bxsi, cxdx			; ^lbx:si = parent obj
	mov	ax, bp				; ss:ax = EAFTPPD
	mov	dx, size AddVarDataParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].AVDP_data.segment, ss
	mov	ss:[bp].AVDP_data.offset, ax
	mov	ss:[bp].AVDP_dataSize, size EnsureActiveFTPriorityPreferenceData
	mov	ss:[bp].AVDP_dataType, \
			TEMP_META_ENSURE_ACTIVE_FT_LAYER_PRIORITY_PREFERENCE
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
						; free params and LayerPrio
	add	sp, size AddVarDataParams + size EnsureActiveFTPriorityPreferenceData
	pop	si				; *ds:si = OLApp
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		; set ds:di = vis instance
						;  for OLAppRaiseLowerCommon

	mov	ax, MSG_GEN_SYSTEM_LOWER_GEODE_TO_BOTTOM
	call	OLAppRaiseLowerCommon

	;
	; move ourselves to the end of our parent GenField's
	; GFI_genApplication list
	;
	push	si
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	bp, CCO_LAST			; move to end
	mov	ax, MSG_GEN_FIELD_MOVE_GEN_APPLICATION
	mov	di, mask MF_RECORD
	call	ObjMessage			; ^hdi = event
	pop	si
	mov	cx, di				; ^hcx = event
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock

if _RUDY
	;
	; Check indicator position
	;
	mov	ax, MSG_OL_APP_ENSURE_INDICATOR_CORRECT
	call	UserCallApplication
endif

	ret
OLApplicationLowerToBottom	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationCheckBeforeGrabbing

DESCRIPTION:	Check to make sure application has a right to be grabbing
		exclusives from the field before going ahead & doing so.

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - 	MSG_META_GRAB_FOCUS_EXCL,
		MSG_META_GRAB_TARGET_EXCL,
		MSG_META_GRAB_MODEL_EXCL

	cx, dx, bp	- data to pass onto superclass if function can continue

RETURN:

DESTROYED:
	ax, bx, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@
OLApplicationCheckBeforeGrabbing	method	OLApplicationClass, \
				MSG_META_GRAB_FOCUS_EXCL,
				MSG_META_GRAB_TARGET_EXCL,
				MSG_META_GRAB_MODEL_EXCL

	; If detaching, not a good idea
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_DETACHING or \
					mask AS_NOT_USER_INTERACTABLE
        jnz     done

	mov	di, offset OLApplicationClass
	GOTO	ObjCallSuperNoLock

done:
	ret

OLApplicationCheckBeforeGrabbing	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationGainedFocusExcl

DESCRIPTION:	Notification that we have gained the focus
		exclusive.  We should let the object within this
		level that last had the exclusive have it again.

PASS:		*ds:si 	- instance data
		es     	- segment of OLApplicationClass
		ax 	- MSG_META_GAINED_FOCUS_EXCL

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

OLApplicationGainedFocusExcl	method	OLApplicationClass, \
						MSG_META_GAINED_FOCUS_EXCL

	ornf	ds:[di].OLAI_flowFlags, mask AFF_FOCUS_APP
	call	OLAppUpdateFocusActivity	; Update focusExcl data
	;
	; If no window has been recognized as being on top yet, give it
	; to the top primary window.
	;
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	call	ObjCallInstanceNoLock

	;
	; move ourselves to the front of our parent GenField's
	; GFI_genApplication list
	;
	push	si
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	bp, CCO_FIRST			; move to front
	mov	ax, MSG_GEN_FIELD_MOVE_GEN_APPLICATION
	mov	di, mask MF_RECORD
	call	ObjMessage			; ^hdi = event
	pop	si
	mov	cx, di				; ^hcx = event
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock

	ret
OLApplicationGainedFocusExcl	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationLostFocusExcl -- MSG_META_LOST_FOCUS_EXCL

DESCRIPTION:	Take away focus exclusive from any object which has it.
		(But remember which one it was, so that we can give it
		back again later)


PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ax - MSG_META_LOST_FOCUS_EXCL

RETURN:
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@

OLApplicationLostFocusExcl	method	OLApplicationClass, \
						MSG_META_LOST_FOCUS_EXCL
					; Clear flag - no longer active app
	andnf	ds:[di].OLAI_flowFlags, not mask AFF_FOCUS_APP
	FALL_THRU	OLAppUpdateFocusActivity	; Update focusExcl data
	
OLApplicationLostFocusExcl	endm




COMMENT @----------------------------------------------------------------------

FUNCTION:	OLAppUpdateFocusActivity

DESCRIPTION:	Let focusExcl be active or force to be not active, based
		on such criteria as whiether app is active application, whether
		there is a focus window up, and whether or not the app
		is in an ignore input mode.

CALLED BY:	INTERNAL

PASS:	*ds:si	- OLApplicationInstance

RETURN:
	Nothing

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/90		Initial version
------------------------------------------------------------------------------@
OLAppUpdateFocusActivity	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

					; If app isn't active, then can't
					; have focus just yet
	test	ds:[di].OLAI_flowFlags, mask AFF_FOCUS_APP
	jz	disallowFocusWin

	; If overriding input restrictions, allow focus.  Otherwise check
	; ignore input flag
	;
	test    ds:[di].OLAI_flowFlags, \
				mask AFF_OVERRIDE_INPUT_RESTRICTIONS
	jnz	allowFocusWin

	; If ignoring input, then disallow kbd data
	;
	tst	ds:[di].OLAI_ignoreInputCount
	jnz	disallowFocusWin

allowFocusWin:
					; If already has exclusive, then done.
	test	ds:[di].VCNI_focusExcl.FTVMC_flags, mask HGF_SYS_EXCL
	jnz	done

	mov	ax, MSG_META_GAINED_SYS_FOCUS_EXCL
	jmp	short flowUpdateExclCommon

disallowFocusWin:
					; If already doesn't have exclusive,
					; then done.
	test	ds:[di].VCNI_focusExcl.FTVMC_flags, mask HGF_SYS_EXCL
	jz	done

	mov	ax, MSG_META_LOST_SYS_FOCUS_EXCL
flowUpdateExclCommon:
	mov	bp, MSG_META_GAINED_FOCUS_EXCL	; pass base message
	mov	bx, offset Vis_offset
	mov	di, offset VCNI_focusExcl
	GOTO	FlowUpdateHierarchicalGrab
done:
	ret

OLAppUpdateFocusActivity	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLAppConsumeMessage

DESCRIPTION:	Consume the event so that the superclass will NOT provide
		default handling for it.

PASS:		*ds:si 	- instance data
		es     	- segment of OLAppClass
		ax 	- message to eat

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@

OLAppConsumeMessage	method	OLApplicationClass,
						MSG_META_FORCE_GRAB_KBD,
						MSG_VIS_FORCE_GRAB_LARGE_MOUSE,
						MSG_VIS_FORCE_GRAB_MOUSE,
						MSG_META_GRAB_KBD,
						MSG_VIS_GRAB_LARGE_MOUSE,
						MSG_VIS_GRAB_MOUSE,
						MSG_META_RELEASE_KBD,
						MSG_VIS_RELEASE_MOUSE
	ret
	
OLAppConsumeMessage	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationUpdateTargetExcl

DESCRIPTION:	Convert gained/lost target to gained/lost system messages, but
		otherwise provide default target node behavior.


PASS:		*ds:si 	- instance data
		es     	- segment of OLApplicationClass
		ax 	- MSG_META_GAINED_TARGET_EXCL

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

OLApplicationUpdateTargetExcl	method	OLApplicationClass, \
						MSG_META_GAINED_TARGET_EXCL,
						MSG_META_LOST_TARGET_EXCL
	add	ax, MSG_META_GAINED_SYS_TARGET_EXCL-MSG_META_GAINED_TARGET_EXCL
	mov	bp, MSG_META_GAINED_TARGET_EXCL	; pass base message
	mov	bx, offset Vis_offset
	mov	di, offset VCNI_targetExcl
	GOTO	FlowUpdateHierarchicalGrab

OLApplicationUpdateTargetExcl	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationUpdateModelExcl

DESCRIPTION:	Convert gained/lost model to gained/lost system messages, but
		otherwise provide default model node behavior.

PASS:		*ds:si 	- instance data
		es     	- segment of OLApplicationClass
		ax 	- MSG_[GAINED/LOST]_MODEL_EXCL

RETURN:		nothing
		ax, cx, dx, bp - destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@

OLApplicationUpdateModelExcl	method	OLApplicationClass, \
						MSG_META_GAINED_MODEL_EXCL,
						MSG_META_LOST_MODEL_EXCL
	add	ax, MSG_META_GAINED_SYS_MODEL_EXCL-MSG_META_GAINED_MODEL_EXCL
	mov	bp, MSG_META_GAINED_MODEL_EXCL	; pass base message
	mov	bx, offset Vis_offset
	mov	di, offset OLAI_modelExcl
	GOTO	FlowUpdateHierarchicalGrab
OLApplicationUpdateModelExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationAlterFTVMCExcl

DESCRIPTION:	Allows object to grab/release any of the FTVMC exlusives.

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of class
		ax 	- MSG_META_MUP_ALTER_FTVMC_EXCL

		^lcx:dx - object requesting grab/release
		bp	- MetaAlterFTVMCExclFlags
		
RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/25/91		Initial version

------------------------------------------------------------------------------@

OLApplicationAlterFTVMCExcl	method	OLApplicationClass, \
					MSG_META_MUP_ALTER_FTVMC_EXCL

	; If app itself is wishing to alter exclusive, call super to send
	; request on up.
	;
	test	bp, mask MAEF_NOT_HERE
	jnz	toField

EC <	test	bp, mask MAEF_FULL_SCREEN				>
EC <	ERROR_NZ OL_ERROR_FULL_SCREEN_EXCL_NOT_LEGAL_BELOW_APP_OBJ	>
EC <	call	ECCheckODCXDX						>

next:
	; If no requests for operations left, exit
	;
	test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
	jz	done

	; Check FIRST for focus, while ds:di still points to instance data
	;
	test	bp, mask MAEF_FOCUS
	jz	afterFocus
	mov	ax, di
	add	ax, offset OLAI_nonModalFocus	; ds:ax is nonModalFocus
	tst	ds:[di].OLAI_modalWin.handle	; set non-zero if in modal state
	mov	bx, offset Vis_offset		; bx is master offset,
	mov	di, offset VCNI_focusExcl	; di is offset, to focusExcl
	call	AlterFExclWithNonModalCacheCommon
	jmp	short next
afterFocus:

	; Check for other requests we can handle
	;

	mov	ax, MSG_META_GAINED_TARGET_EXCL
	mov	bx, mask MAEF_TARGET
	mov	di, offset VCNI_targetExcl
	test	bp, bx
	jnz	doHierarchy

	mov	ax, MSG_META_GAINED_MODEL_EXCL
	mov	bx, mask MAEF_MODEL
	mov	di, offset OLAI_modelExcl
	test	bp, bx
	jnz	doHierarchy

toField:
	and	bp, not mask MAEF_NOT_HERE
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	GOTO	GenCallParent

doHierarchy:
	push	bx, bp
	and	bp, mask MAEF_GRAB
	or	bp, bx			; or back in hierarchy flag
	mov	bx, offset Vis_offset
	call	FlowAlterHierarchicalGrab
	pop	bx, bp
	not	bx			; get not mask for hierarchy
	and	bp, bx			; clear request on this hierarchy
	jmp	short next

done:
	Destroy	ax, cx, dx, bp
	ret

OLApplicationAlterFTVMCExcl	endm

AppCommon	ends
AppCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLApplicationSendClassedEvent

DESCRIPTION:	Sends message to target object at level requested
		Focus, Target, View, Model & Controller requests are all
		passed on to the current field.

PASS:
	*ds:si - instance data
	es - segment of OLApplicationClass

	ax - MSG_META_SEND_CLASSED_EVENT

	cx	- handle of classed event
	dx	- TargetObject

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@
OLApplicationSendClassedEvent	method	OLApplicationClass, \
					MSG_META_SEND_CLASSED_EVENT
	mov     bp, di                          ; save offset to master part

	mov	di, offset VCNI_focusExcl
	cmp	dx, TO_FOCUS
	je	sendHere

	mov	di, offset VCNI_targetExcl
	cmp	dx, TO_TARGET
	je	sendHere

	mov	di, offset OLAI_modelExcl
	cmp	dx, TO_MODEL
	je	sendHere

	mov	di, offset OLApplicationClass
	CallSuper	MSG_META_SEND_CLASSED_EVENT
	ret

sendHere:
	add	di, bp			; Get ptrs to instance data
	add	bx, bp
	mov	bx, ds:[di].BG_OD.handle
	mov	bp, ds:[di].BG_OD.chunk
	clr	di
	GOTO	FlowDispatchSendOnOrDestroyClassedEvent

OLApplicationSendClassedEvent	endm

AppCommon	ends
AppCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:
	MSG_GEN_APPLICATION_MARK_BUSY		- OLAppMarkBusy
	MSG_GEN_APPLICATION_MARK_NOT_BUSY	- OLAppMarkNotBusy
	MSG_GEN_APPLICATION_HOLD_UP_INPUT	- OLAppHoldUpBusy
	MSG_GEN_APPLICATION_RESUME_INPUT		- OLAppResumeBusy
	MSG_GEN_APPLICATION_IGNORE_INPUT		- OLAppIgnoreBusy
	MSG_GEN_APPLICATION_ACCEPT_INPUT		- OLAppAcceptBusy

DESCRIPTION:	These routines handle the inc'ing & dec'ing of variables
	for determining whether the application should be marked as busy,
	should hold up UI processing, or should discard UI processing.

PASS:
	*ds:si - instance data
	es - segment of OlApplicationClass

	ax - MSG_?

	cx, dx, bp	- ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version

------------------------------------------------------------------------------@

OLAppMarkBusy	method dynamic	OLApplicationClass, MSG_GEN_APPLICATION_MARK_BUSY
	inc	ds:[di].OLAI_busyCount		; Inc busy count
EC <	ERROR_Z	OL_BUSY_COUNT_OVERFLOW					>
if DISABLE_APO_ON_BUSY
	call	SysDisableAPO
endif
if ANIMATED_BUSY_CURSOR
	cmp	ds:[di].OLAI_busyCount, 1
	jne	noTimer
	push	di
	mov	al, TIMER_EVENT_CONTINUAL
	mov	bx, ds:[LMBH_handle]
	mov	cx, 0
	mov	dx, MSG_OL_APP_UPDATE_PTR_IMAGE
	mov	di, 60/NUM_BUSY_CURSOR_FRAMES	; every 1/x second
	call	TimerStart
	pop	di
	xchg	bx, ds:[di].OLAI_busyTimer
	xchg	ax, ds:[di].OLAI_busyTimerID
	tst	bx
	jz	noTimer
	call	TimerStop
noTimer:
endif
	GOTO	OLAppUpdatePtrImage

OLAppMarkBusy	endp

OLAppMarkNotBusy	method dynamic	OLApplicationClass, \
						MSG_GEN_APPLICATION_MARK_NOT_BUSY
	dec	ds:[di].OLAI_busyCount		; Dec busy count
EC <	ERROR_S OL_BUSY_COUNT_UNDERFLOW					>
if DISABLE_APO_ON_BUSY
	call	SysEnableAPO
endif
if ANIMATED_BUSY_CURSOR
	tst	ds:[di].OLAI_busyCount
	jnz	noTimer
	clr	bx
	xchg	bx, ds:[di].OLAI_busyTimer
	mov	ax, ds:[di].OLAI_busyTimerID
	call	TimerStop
noTimer:
endif
	GOTO	OLAppUpdatePtrImage

OLAppMarkNotBusy	endp

OLAppHoldUpInput	method dynamic	OLApplicationClass, \
						MSG_GEN_APPLICATION_HOLD_UP_INPUT
	inc	ds:[di].OLAI_holdUpInputCount
EC <	ERROR_Z OL_HOLD_UP_INPUT_COUNT_OVERFLOW				>
	call	OLAppUpdateFlowHoldUpState	; Update hold-up state
	GOTO	OLAppUpdatePtrImage

OLAppHoldUpInput	endp

OLAppResumeInput	method dynamic	OLApplicationClass, \
						MSG_GEN_APPLICATION_RESUME_INPUT
	dec	ds:[di].OLAI_holdUpInputCount
EC <	ERROR_S OL_HOLD_UP_INPUT_COUNT_UNDERFLOW			>
	call	OLAppUpdateFlowHoldUpState	; Update hold-up state
	GOTO	OLAppUpdatePtrImage

OLAppResumeInput	endp

OLAppIgnoreInput	method dynamic	OLApplicationClass, \
						MSG_GEN_APPLICATION_IGNORE_INPUT
	inc	ds:[di].OLAI_ignoreInputCount
EC <	ERROR_Z OL_IGNORE_INPUT_COUNT_OVERFLOW				>

	call	OLAppUpdateFocusActivity	; Make sure app is allowing/
						; disallowing focus as is
						; appropriate.
	call	OLAppUpdateImpliedWin	; update VCNI_impliedMouseGrab
	GOTO	OLAppUpdatePtrImage

OLAppIgnoreInput	endp


OLAppAcceptInput	method dynamic	OLApplicationClass, \
						MSG_GEN_APPLICATION_ACCEPT_INPUT
	dec	ds:[di].OLAI_ignoreInputCount
EC <	ERROR_S OL_IGNORE_INPUT_COUNT_UNDERFLOW				>

	jnz	done			; if hasn't reached zero yet, no
					; action needs to be taken

	call	OLAppUpdateFocusActivity	; Make sure app is allowing/
						; disallowing focus as is
						; appropriate.
	call	OLAppUpdateImpliedWin	; update VCNI_impliedMouseGrab
	GOTO	OLAppUpdatePtrImage	; fix up ptr image.
done:
	ret

OLAppAcceptInput	endp



COMMENT @----------------------------------------------------------------------

METHOD:	OLAppMarkCompletelyBusy
METHOD:	OLAppMarkAppNotCompletely

DESCRIPTION:	These routines handle the inc'ing & dec'ing of variables
	for determining whether the application should be marked as busy,
	should hold up UI processing, or should discard UI processing.

PASS:
	*ds:si - instance data
	es - segment of OlApplicationClass

	ax - MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY/
	     MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY

	cx, dx, bp	- ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version

------------------------------------------------------------------------------@

OLAppMarkCompletelyBusy	method dynamic	OLApplicationClass, \
					MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	inc	ds:[di].OLAI_completelyBusyCount		; Inc busy count
EC <	ERROR_Z	OL_BUSY_COUNT_OVERFLOW					>

if DISABLE_APO_ON_COMPLETELY_BUSY
	call	SysDisableAPO
endif

	GOTO	OLAppUpdatePtrImage

OLAppMarkCompletelyBusy	endp

OLAppMarkAppNotCompletely	method dynamic	OLApplicationClass, \
					MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
	dec	ds:[di].OLAI_completelyBusyCount		; Dec busy count
EC <	ERROR_S OL_BUSY_COUNT_OVERFLOW					>

if DISABLE_APO_ON_COMPLETELY_BUSY
	call	SysEnableAPO
endif

	GOTO	OLAppUpdatePtrImage

OLAppMarkAppNotCompletely	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLAppUpdateFlowHoldUpState

DESCRIPTION:	Check to make sure that our current state of input-holding,
		with regards to the flow object (managed via calls to
		FlowHoldUpInput & FlowResumeInput) are in the state which they
		should be in.

CALLED BY:	INTERNAL
		OLAppHoldUpInput
		OLAppResumeInput
		OLAppGrabModalExcl
		OLAppReleaseModalExcl

PASS:
	*ds:si	- OLApplication object

RETURN:
	Nothing

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version
------------------------------------------------------------------------------@
OLAppUpdateFlowHoldUpState	proc	near
	uses	ax
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	; First, decide if flow object should be holding up input for us
	; or not...

	; If overriding input restrictions, allow input to flow.
	; Otherwise check hold up input flag
	;
	test    ds:[di].OLAI_flowFlags, \
				mask AFF_OVERRIDE_INPUT_RESTRICTIONS
	jnz	letErRip
				; Otherwise, see if we have a non-zero hold
				; up count, indicating hold up desired
	tst	ds:[di].OLAI_holdUpInputCount
	jnz	holdUpInput	; if so, hold up input

				; Otherwise, let fly
letErRip:
				; If already allowing flow, nothing more to
				; worry about, we're done.
	test	ds:[di].OLAI_flowFlags, mask AFF_FLOW_HOLDING_INPUT_FOR_APP
	jz	done
				; Otherwise, reset flag & release input
	andnf	ds:[di].OLAI_flowFlags, not mask AFF_FLOW_HOLDING_INPUT_FOR_APP

	mov	ax, MSG_VIS_CONTENT_RESUME_INPUT_FLOW
	jmp	short callThenDone

holdUpInput:
				; If already holding up, nothing more to worry
				; about, we're done.
	test	ds:[di].OLAI_flowFlags, mask AFF_FLOW_HOLDING_INPUT_FOR_APP
	jnz	done
				; Otherwise, set flag & hold up input
	ornf	ds:[di].OLAI_flowFlags, mask AFF_FLOW_HOLDING_INPUT_FOR_APP

	mov	ax, MSG_VIS_CONTENT_HOLD_UP_INPUT_FLOW

callThenDone:
	push	cx, dx, bp
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp
done:
	.leave
	ret
OLAppUpdateFlowHoldUpState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfInteractableObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the object is interactable.

CALLED BY:	GLOBAL
PASS:		CX:DX <- object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfInteractableObject	proc	far
	.enter

	movdw	bxsi, ds:[di]
	cmpdw	cxdx, bxsi
	stc				;If this object is on the list,
	je	exit			; then it must be interactable

;	If the object on the list was not the one we were testing, send a
;	message to the object on the list in case the passed object is a
;	child object of the one on the list (GenControl subclasses this
;	this to allow messages to its child blocks)

	push	cx, dx
	mov	ax, MSG_META_CHECK_IF_INTERACTABLE_OBJECT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;Returns carry set if interactable
					; object
	pop	cx, dx
exit:
	.leave
	ret
CheckIfInteractableObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppCheckIfAlwaysInteractableObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the object should always be interactable.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if allowed
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLAppCheckIfAlwaysInteractableObject	method	OLApplicationClass,
			MSG_GEN_APPLICATION_CHECK_IF_ALWAYS_INTERACTABLE_OBJECT
	.enter

	mov	di, offset CheckIfInteractableObject
	mov	ax, GAGCNLT_CONTROLLERS_WITHIN_USER_DO_DIALOGS
	call	CallOnAllItemsInGCNList
	jc	exit

if _JEDIMOTIF
	;
	; allow messages through to OLMenuBarClass, to allow updating of
	; sticky key area
	;
	push	bx
	mov	bx, cx				; bx = dest obj block
	call	MemOwner
	cmp	bx, cx				; process owns itself
	je	notMenuBar			; (carry clear)
	mov	bx, cx				; bx = dest obj block
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo			; ax = exec thread
	cmp	ax, 0
	je	notMenuBar			; queue (carry clear)
	cmp	ax, bx
	je	notMenuBar			; thread runs itself (C clr)
	call	ObjTestIfObjBlockRunByCurThread
	clc					; assume not, don't allow
	jnz	notMenuBar			; not!
	push	si, ds, es
	mov	si, dx				; ^lbx:si = obj
	call	ObjLockObjBlock			; ax = segment
	mov	ds, ax
	mov	di, segment OLMenuBarClass
	mov	es, di
	mov	di, offset OLMenuBarClass
	call	ObjIsObjectInClass		; carry set if menu bar
	call	MemUnlock			; (preserves flags)
	pop	si, ds, es
notMenuBar:
	pop	bx
	jc	exit				; allow interaction
endif

;	If nobody on the app wants this, try the modal win itself...

	mov	di, ds:[si]
	add	di, ds:[di].OLApplication_offset
	movdw	bxsi, ds:[di].OLAI_modalWin
	tst_clc	bx
	jz	exit
	mov	ax, MSG_META_CHECK_IF_INTERACTABLE_OBJECT
	mov	di, mask MF_CALL
	call	ObjMessage
exit:
	.leave
	ret
OLAppCheckIfAlwaysInteractableObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfWindowIsInteractable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the window is interactable, then return carry set.

CALLED BY:	GLOBAL
PASS:		cx:dx - InputOD as passed w/ MSG_META_TEST_WIN_INTERACTIBILITY
		bp - window
		ds:di - object in GCN list
RETURN:		carry set if window is interactable
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfWindowIsInteractable	proc	far
	.enter

	push	cx, dx, bp
	mov	ax, MSG_META_TEST_WIN_INTERACTIBILITY
	movdw	bxsi, ds:[di]
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;Returns carry set if mouse allowed
					; in window
	pop	cx, dx, bp

	.leave
	ret
CheckIfWindowIsInteractable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallOnAllItemsInGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the passed callback routine on all items in the 
		passed gcnlist.

CALLED BY:	GLOBAL
PASS:		*ds:si - OLApplicationClass object
		ax - GCN list
		CS:DI - callback routine
		CX,DX,BP - data to pass to callback
RETURN:		carry set if callback routine set it
		carry clear if no items in list, or callback routine did
		not set it.
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallOnAllItemsInGCNList	proc	near
	uses	si
	.enter

;	Call callback on all items in GCN list

	push	ax
	mov	ax, TEMP_META_GCN	;
	call	ObjVarFindData		;
	pop	ax
	jnc	exit			;If no GCN lists, exit

	push	di
	mov	di, ds:[bx].TMGCND_listOfLists
	mov	bx, MANUFACTURER_ID_GEOWORKS
	clc				;Don't create list
	call	GCNListFindListInBlock
	pop	di
	jnc	exit			;If no GCNList, exit

	clr	ax
	mov	bx, cs			;BX:DI <- callback routine
	call	ChunkArrayEnum		;Returns carry set if window was
					; interactable
exit:
	.leave
	ret
CallOnAllItemsInGCNList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppTestWinInteractibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	General purpose message used to determine whether the mouse
		should be allowed into a particular window on an implied
		basis at any given point in time.  The default handler here
		returns "yes" unless there is a modal window up, & the mouse
		is outside of it, or if the app is currently IGNORING input.
		This message may be subclassed to do enable interesting effects
		like allowing clicking on spreadsheet cells while a modal
		dialog is up.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_TEST_WIN_INTERACTIBILITY

		^lcx:dx	- InputOD of window to check
		^hbp	- Window to check

RETURN:		carry	- set if mouse allowed in window, clear if not.

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLAppTestWinInteractibility	method dynamic	OLApplicationClass, \
				MSG_META_TEST_WIN_INTERACTIBILITY
	clc
	jcxz	exit			; if no InputOD, mouse can't interact

	mov	bx, ds:[di].OLAI_modalWin.handle
	tst	bx
	jz	afterModal


;	We want to accept input to this modal dialog, so query the dialog
;	to see if the window the mouse is over is a child window of this
;	dialog, and if so, allow input in...

	push	cx, dx, bp, si
	mov	si, ds:[di].OLAI_modalWin.chunk
	mov	ax, MSG_META_TEST_WIN_INTERACTIBILITY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp, si
	jc	overModalWin

;	The mouse is not over the modal window, so check to see if the window
;	belongs to an object on the GCN list that says it should always
;	be interactable - if so, branch to allow input in

	mov	di, offset CheckIfWindowIsInteractable
	mov	ax, GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS
	call	CallOnAllItemsInGCNList
	;Returns carry set if window belongs to ALWAYS_INTERACTABLE object
	jmp	exit				


overModalWin:

;	The mouse is over the current modal window (or one of its subwindows).
;	Ask the currently active modal window if it wants to abide by input
;	restrictions. If so, treat it like a non-modal window, and if ignoring
;	input, don't let the mouse in (2/25/94 - atw)

	push	cx, dx, bp, si
	mov	di, ds:[si]
	add	di, ds:[di].OLApplication_offset
	mov	si, ds:[di].OLAI_modalWin.chunk
	mov	ax, MSG_GEN_INTERACTION_TEST_INPUT_RESTRICTABILITY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp, si
	jc	exit	;Branch if it wants to override input restrictions
			; (which is the default for modal windows, for some 
			; stupid reason).

	mov	di, ds:[si]
	add	di, ds:[di].OLApplication_offset
afterModal:
	; If ignoring input, mouse isn't allowed in.
	;
	tst_clc	ds:[di].OLAI_ignoreInputCount
	jnz	exit
	stc
exit:
	ret
OLAppTestWinInteractibility	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLAppUpdateImpliedWin

DESCRIPTION:	Sets VCNI_impliedMouseGrab based on current implied win info, &
		whether or not we have an app-modal or system modal dialog
		up on screen.  Normally, we just let mouse data go to 
		whatever window it is over (unless, of course, there is
		an active grab).  If there is a modal window, up, however,
		only allow implied mouse data to be sent to that window.

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLApplication object

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/92		Initial version

------------------------------------------------------------------------------@
OLAppUpdateImpliedWin	proc	near
	uses	es
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	;
	; Get window mouse is over
	;

	mov	cx, ds:[di].OLAI_impliedWin.MG_OD.handle
	mov	dx, ds:[di].OLAI_impliedWin.MG_OD.chunk
	mov	bp, ds:[di].OLAI_impliedWin.MG_gWin

	; Ask ourselves (while allowing developers to subclass & give us a
	; different answer), whether the mouse should be allowed in this
	; window or not.
	;
	push	cx, dx, bp
	mov	ax, MSG_META_TEST_WIN_INTERACTIBILITY
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp
	jc	haveDecision
	clr	cx, dx			; if not allowed in, clear out implied
					;	win optr.
haveDecision:

	mov	ax, MSG_META_IMPLIED_WIN_CHANGE
	mov	di, segment OLApplicationClass
	mov	es, di
	mov	di, offset OLApplicationClass
	call	ObjCallSuperNoLock

	.leave
	ret
OLAppUpdateImpliedWin	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppUpdatePtrImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines appropriate PtrImages for PIL_LAYER,
		& sets them for the App's Layer

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:
        if (OLAI_completelyBusyCount) OLPI_BUSY
        else {
	    if (sys/app modal window active) {
                if (active or implied mouse grab) OLPI_NONE
                else OLPI_MODAL
            } else {
                if (ignore input OR busy) OLPI_BUSY
                else OLPI_NONE
	    }
        }

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ANIMATED_BUSY_CURSOR
OLAppUpdatePtrImage	method OLApplicationClass, MSG_OL_APP_UPDATE_PTR_IMAGE
else
OLAppUpdatePtrImage	proc	far
endif
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	; FIRST, figure out whether we want to show a completely
	; BUSY cursor or not.

	mov	cl, OLPI_NONE		; assume we don't

	; If completely busy, modal state doesn't matter -- show busy.
	;
	tst	ds:[di].OLAI_completelyBusyCount
	jnz	showBusy

	; Check to see if "outside modal" area cursor should be displayed
	; (Is overriden by busy states)
	;
    	tst	ds:[di].OLAI_modalWin.handle
	jz	afterModalWin
	;
	; If active grab, no special cursor
	;
	tst	ds:[di].VCNI_activeMouseGrab.VMG_object.handle
	jnz	afterModalWin
	;
	; If mouse allowed in current implied window, no special cursor
	;
	tst	ds:[di].VCNI_impliedMouseGrab.VMG_object.handle
	jnz	afterModalWin
	;
	mov	cl, OLPI_MODAL		; Otherwise, use modal cursor
afterModalWin:

;
; Can't do this as it allows busy cursor on modal dialogs with text entry,
; etc.  Oh well, no busy cursor for you. - brianc 6/8/93
;
if 0
	;
	; If running in PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE mode, then
	; allow busy cursor to override AFF_OVERRIDE_INPUT_RESTRICTIONS
	; - brianc 6/3/93
	;
	push	ax
	call	ImGetPtrFlags
	test	al, mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE
	pop	ax
	jnz	checkBusy
endif

	; If overriding input restrictions, then use current mouse image.
	; Otherwise, check to see if we should show "busy."
	;
	test	ds:[di].OLAI_flowFlags, \
				mask AFF_OVERRIDE_INPUT_RESTRICTIONS
	jnz	setLayerStatus
	;
	; Show busy if ignoring input or app marked "Busy".
	;
;checkBusy:
    	tst	ds:[di].OLAI_ignoreInputCount
	jnz	showBusy
    	tst	ds:[di].OLAI_busyCount
	jnz	showBusy
	jmp	short setLayerStatus
	;
showBusy:
	mov	cl, OLPI_BUSY		; if any outstanding, set busy

setLayerStatus:
	call	OpenGetPtrImage		; Fetch OL ptr image to use
	mov	bx, ds:[LMBH_handle]	; get handle of app's geode
	call	MemOwner
	call	WinGeodeSetPtrImage	; Set it.
done:
	ret
OLAppUpdatePtrImage	endp
	



COMMENT @----------------------------------------------------------------------

METHOD:		OLAppGetDisplayScheme -- MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME for
			OLApplicationClass

DESCRIPTION:	Fetch display scheme store in app object

PASS:
	*ds:si - instance data
	es - segment of ApplicationClass

	ax - MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME

	cx - ?
	dx - ?
	bp - ?

RETURN:	Display scheme structure in ax,cx,dx,bp.

		al - DS_colorScheme	
		ah - DS_displayType
		cx - DS_unused
		dx - DS_fontID
		bp - DS_pointSize
		carry	- set




DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

; NOTE!  This routine is called directly from various places, so be careful
; with what you trash.
;
OLAppGetDisplayScheme	method OLApplicationClass, \
					MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME

	push	bx
	call	SpecGetDisplayScheme		; Use FAST routine for this
	mov	bp, dx				; specific UI, which works with
	mov	dx, cx				; only one DisplayScheme at
	mov	cx, bx					; a time.
	pop	bx
	stc
	ret

OLAppGetDisplayScheme	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLApplicationSetTaskEntryMoniker - 
		MSG_GEN_APPLICATION_SET_TASK_ENTRY_MONIKER handler.

DESCRIPTION:	This procedure sets a new moniker for the GenItem
		which represents this application in the Application Menu.

PASS:		ds:*si	- instance data
		^lcx:dx = VisMoniker or VisMonikerList to use
				(will copy to this block)

RETURNS:	nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		initial version

------------------------------------------------------------------------------@

OLApplicationSetTaskEntryMoniker	method dynamic	OLApplicationClass, \
				MSG_GEN_APPLICATION_SET_TASK_ENTRY_MONIKER

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	si, ds:[di].OLAI_appMenuItems
	tst	si
	jz	done
	mov	bx, cs
	mov	di, offset OLASTEM_callback
	call	ChunkArrayEnum
done:
	ret
OLApplicationSetTaskEntryMoniker	endm

;
; pass:		*ds:si = chunk array
;		ds:di = CreateExpressMenuControlItemResponseParams
;		^lcx:dx = vis moniker to copy
; return:	carry clear to continue enumeration
;
OLASTEM_callback	proc	far
	uses	cx, dx
	.enter

	movdw	bxsi, ds:[di].CEMCIRP_newItem
	call	CopyTextMonikerToListEntry
	clc

	.leave
	ret
OLASTEM_callback	endp

AppCommon	ends
AppCommon	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyTextMonikerToListEntry

DESCRIPTION:	Copy text moniker over current moniker of list entry passed

CALLED BY:	INTERNAL
		OLApplicationSetTaskEntryMoniker

PASS:	ds	- object block segment to keep fixed up
	^lbx:si	- GenItem
	^lcx:dx	- source moniker

RETURN:

DESTROYED:
	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/90		Initial version
------------------------------------------------------------------------------@
CopyTextMonikerToListEntry	proc	near
	uses	bx, di, bp
	.enter

	push	bx			; ^lbx:si is GenItem

					; ^lcx:dx is VisMoniker to copy from
	jcxz	haveMoniker		; if NULL source, pass it on

	;
	; lock down VisMoniker and if moniker list, find a text moniker
	;
	mov	bx, cx			; bx = moniker block handle
	call	ObjSwapLock		; ds = moniker segment
					; bx = passed ds block
	push	bx, si			; save ds block, GenItem chunk
	mov	di, dx			; *ds:di = VisMoniker to copy from
	call	UserGetDisplayType	; ah = DisplayType
	mov	bh, ah			; bh = DisplayType
					; bp = search flags
	mov	bp, (VMS_TEXT shl offset VMSF_STYLE)
					;return non-abbreviated text string,
					;otherwise abbreviated text string,
					;otherwise textual GString, otherwise
					;non-textual GString.
	call	VisFindMoniker		; ^lcx:dx = moniker found
	pop	bx, si			; restore ds block, GenItem chunk
	call	ObjSwapUnlock
	;
	; XXX: make sure returned moniker is text
	;
	
haveMoniker:
	pop	bx			; ^lbx:si = GenItem

	jcxz	exit			; just exit if no moniker found

	;
	; set found moniker in OLAppTaskItem
	;	^lbx:si = OLAppTaskItem
	;	cx:dx = optr of text vis moniker
	;
	; NOTE:  We have to bend backwards to be very careful here.  We
	; cannot use MSG_GEN_REPLACE_VIS_MONIKER_OPTR because the GenItem
	; being set can be run by a different thread.  We could use
	; MSG_GEN_REPLACE_VIS_MONIKER_TEXT, but then we'd have to a MF_CALL
	; which is bad because if there are several threads running Express
	; Menu Controls (and their GenItems), we could get deadlock as one
	; thread waits for another.  So we copy the moniker into a sharable
	; block and do a send.
	;
	pushdw	bxsi			; save OLAppTaskItem

	mov	bx, cx
	call	ObjSwapLock		; *ds:dx is text moniker
	push	bx			; save for ObjSwapUnlock
	mov	di, dx
	mov	si, ds:[di]		; *ds:si = text moniker

	ChunkSizePtr	ds, si, ax	; ax = size of text moniker
	push	ax			; save size
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc		; bx = handle, ax = segment
	pop	cx			; cx = size
	jc	memError1		; couldn't allocate block, skip
	mov	es, ax			; es:di = block
	clr	di
	rep movsb			; copy over
	call	MemUnlock		; unlock new text moniker block
	mov	ax, bx			; ax = new text moniker block
memError1:
	pop	bx
	call	ObjSwapUnlock		; (preserves flags)

	popdw	bxsi			; ^lbx:si = OLAppTaskItem
	jc	exit			; memory error above, skip setting
					;	moniker
	mov	cx, ax			; cx = new text moniker block
	mov	ax, MSG_OL_APP_TASK_ITEM_SET_MONIKER
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:

	.leave
	ret
CopyTextMonikerToListEntry	endp

if _JEDIMOTIF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppEnsureAppMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create app menu and print screen trigger, if needed

CALLED BY:	MSG_OL_APP_ENSURE_APP_MENU

PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data

RETURN:		^lcx:dx = App menu
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLAppEnsureAppMenu	method dynamic OLApplicationClass, 
					MSG_OL_APP_ENSURE_APP_MENU
	;
	; Find app menu, though not one that we've created
	;
		call	FindAppMenu			; ^lcx:dx = app menu
	;
	;  Make sure we've added the print-screen trigger; if not,
	;  add one now.  If we didn't find an app menu, we create
	;  it in this routine.
	;
		call	EnsurePrintScreenTrigger	; ^lbx:si = app menu
		Assert	optr	bxsi
	;
	; set boring moniker
	;
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		mov	bp, VUM_DELAYED_VIA_APP_QUEUE
		mov	cx, handle StandardMonikers
		mov	dx, offset JediAppMenuMoniker
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; return optr
	;
		movdw	cxdx, bxsi
		ret
OLAppEnsureAppMenu	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindAppMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find App menu, though not one that we created

CALLED BY:	OLAppEnsureAppMenu
PASS:		*ds:si = OLApp
RETURN:		^lcx:dx = App menu, or null if none
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindAppMenu	proc	far
	;
	;  Pass lptr of created App menu, if any
	;
		mov	ax, TEMP_OL_APP_CREATED_APP_MENU
		call	ObjVarFindData
		mov	ax, 0			; assume none (preserves flags)
		jnc	noAppMenu
		mov	ax, ds:[bx]		; ax = lptr of created App menu
noAppMenu:
	;
	;  Get the app menu by finding the first popup menu
	;  child and using that.
	;
		clr	cx, di			; start at child 0
		push	di
		push	di			; push starting child #

		mov	di, offset GI_link
		push	di			; push offset to LinkPart

		mov	di, SEGMENT_CS
		push	di
		mov	di, offset FindAppMenuCB
		push	di

		mov	bx, offset Gen_offset	; Use the generic linkage
		mov	di, offset GI_comp
		call	ObjCompProcessChildren
		ret
FindAppMenu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindAppMenuCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return if this is a popup window.

CALLED BY:	FindAppMenu via ObjCompProcessChildren

PASS:		*ds:si = child
		*es:di = composite (app object)
		ax = lptr of created App menu, if any

RETURN:		carry set to end processing
		^lcx:dx = child optr if a popup
		cx, dx = null otherwise

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	10/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindAppMenuCB	proc	far

	;
	;  See if we're a GenInteractionClass, firstly.
	;
		clr	cx, dx
		push	es
		mov	di, segment GenInteractionClass
		mov	es, di
		mov	di, offset GenInteractionClass
		call	ObjIsObjectInClass
		pop	es
		jnc	done
	;
	;  We're a GenInteractionClass.  See if we're a popup.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		cmp	ds:[di].GII_visibility, GIV_POPUP
		clc					; assume not popup
		jne	done				; not popup => bail
	;
	;  Make sure we are usable
	;
		test	ds:[di].GI_states, mask GS_USABLE
		jz	done				; not usable, C clr
	;
	;  Return our optr and the carry flag set.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si				; ^lcx:dx = us
	;
	; Skip if it is the App menu we created
	;
		cmp	cx, es:[LMBH_handle]
		jne	notOurs
		cmp	dx, ax
		je	done				; it is!, carry clear
notOurs:
		stc
done:
		.leave
		ret
FindAppMenuCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsurePrintScreenTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a print-screen trigger child of the app menu.

CALLED BY:	OLAppEnsureAppMenu

PASS:		*ds:si = OLApplication object
		^lcx:dx = app menu, if any (null if none found)

RETURN:		^lbx:si = app menu

DESTROYED:	none

PSEUDO CODE/STRATEGY:

	- if we don't have an app-menu yet, make one
	- create a print-screen trigger child of the app-menu,
	  if we haven't done so already

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	If the user creates an app menu, and we attach our
	print-screen trigger to it, and then the user deletes
  	the menu, we don't find out, and when they create a
	new app menu, we don't add a new trigger to it.  Such
  	is life.

	However, we always add a print-screen trigger to a new
	app-menu, even if we think we already had one.  So if
	the user just ups and deletes the app menu, they get a
  	brand-new one with a new print-screen trigger.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	10/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsurePrintScreenTrigger	proc	near
		uses	ax,cx,dx,di,bp
		.enter
	;
	;  If we don't have an app menu, create one; else see
	;  if we need to add a print-screen trigger.
	;
		tst	cx			; got menu already?
		jnz	gotMenu

		call	CreateAppMenu		; ^lcx:dx = app menu
gotMenu:
	;
	;  See if we need to add a print-screen trigger.  Before
	;  jumping anywhere, make ^lbx:si = the app menu, since
	;  both our potential destinations need this.
	;
		call	SeeIfNeedToAddTrigger	; carry set if need to add
		LONG jnc	done		; don't need to add it
	;
	;  Create the PrintScreen trigger.
	;
		push	cx, dx			; save app menu again
		push	ds:[LMBH_handle], si	; save application OD
		mov	bx, cx			; bx = app menu block
		call	ObjLockObjBlock		; ax = app menu segment
		mov	ds, ax			; *ds:dx = app menu

		push	es
		mov	di, segment GenTriggerClass
		mov	es, di
		mov	di, offset GenTriggerClass
		mov	ax, 00ffh		; init USABLE, 2-way link
		mov	bx, HINT_TRIGGER_BRINGS_UP_WINDOW or \
				mask VDF_SAVE_TO_STATE
		mov	bp, CCO_LAST		; (not dirty)
		call	OpenCreateChildObject	; ^lcx:dx = trigger
		pop	es

		Assert	optr cxdx		; did we screw up?
	;
	;  Store optr of created Print Screen trigger
	;	^lcx:dx = Print Screen trigger
	;
		pop	bx, si
		push	bx, si
		call	MemDerefDS		; *ds:si = app object
		push	cx
		mov	ax, TEMP_OL_APP_CREATED_PRINT_SCREEN
		mov	cx, size optr
		call	ObjVarAddData
		pop	cx
		movdw	ds:[bx], cxdx
	;
	;  Give the printscreen trigger a moniker.
	;	^lcx:dx = Print Screen trigger
	;
		movdw	bxsi, cxdx		; ^lbx:si = trigger

		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		mov	bp, VUM_DELAYED_VIA_APP_QUEUE
		mov	cx, handle StandardMonikers
		mov	dx, offset PrintScreenMoniker
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

	;
	;  Give it a purpose.
	;
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		mov	cx, MSG_OL_APP_PRINT_SCREEN
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

	;
	; Find the optr of the app.  Then we'll set the destination
	; of the trigger to the app.
	;
		popdw	cxdx			; application instance
		mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

	;
	;  Unlock the app-menu block now that we're done with it.
	;
		pop	bx, si			; ^lbx:si = app menu
		call	MemUnlock
done:
		.leave
		ret
EnsurePrintScreenTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAppMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an application menu for ourselves.

CALLED BY:	EnsurePrintScreenTrigger

PASS:		*ds:si = OLApplication instance

RETURN:		^lcx:dx = app menu

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	10/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAppMenu	proc	near
		uses	ax,bx,si,di,bp,es
		.enter
	;
	;  If we've created one previously, use it
	;
		mov	ax, TEMP_OL_APP_CREATED_APP_MENU
		call	ObjVarFindData
		jnc	noPrevious
		mov	cx, ds:[LMBH_handle]
		mov	dx, ds:[bx]
		jmp	short done

noPrevious:
	;
	;  No app-menu; create one and fall-through to create
	;  PrintScreen trigger.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si			; add to app object resource
		mov	di, segment GenInteractionClass
		mov	es, di
		mov	di, offset GenInteractionClass
		mov	ax, 00ffh		; 2-way link, usable
		clr	bx			; no hints
		mov	bp, CCO_LAST
		call	OpenCreateChildObject	; ^lcx:dx = app menu

		Assert	optr cxdx		; did we screw up?
	;
	;  Store lptr of created App menu
	;
		push	cx
		mov	ax, TEMP_OL_APP_CREATED_APP_MENU
		mov	cx, size lptr
		call	ObjVarAddData
		pop	cx
		mov	ds:[bx], dx
	;
	;  Set the visibility to "popup" to make it a menu.
	;
		movdw	bxsi, cxdx		; ^lbx:si = app menu
		call	MemDerefDS		; *ds:si = app menu

		push	di
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].GII_visibility, GIV_POPUP
		pop	di
done:
		.leave
		ret
CreateAppMenu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeeIfNeedToAddTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we have to add a PrintScreen trigger.

CALLED BY:	EnsurePrintScreenTrigger

PASS:		*ds:si = OLApplication
		^lcx:dx = app menu

RETURN:		carry set if we have to add it -
			^lbx:si = unchanged

		carry clear if don't need to add it -
			^lbx:si = app menu

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	10/21/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SeeIfNeedToAddTrigger	proc	near
		uses	ax, cx
		.enter
	;
	;  See if we have a PrintScreen trigger already
	;
		xchg	bx, cx			; ^lbx:si = App menu
		xchg	si, dx			; ^lcx:dx = passed ^lbx:si
		call	ObjSwapLock
		push	bx			; bx = handle of OLApp
		clr	di			; start at child 0
		push	di
		push	di			; push starting child #

		mov	di, offset GI_link
		push	di			; push offset to LinkPart

		mov	di, SEGMENT_CS
		push	di
		mov	di, offset CheckPrintScreenCB
		push	di

		mov	bx, offset Gen_offset	; Use the generic linkage
		mov	di, offset GI_comp
		call	ObjCompProcessChildren	; carry set if found
						; flags preserved
		pop	bx			; bx = handle of OLApp
		call	ObjSwapUnlock		; ds = OLApp segment
						; ^lbx:si = App menu
		jnc	addTrigger
	;
	;  Don't need to add trigger.  Carry is set, so jmp done
	;  to invert the flag.  Return ^lbx:si = App menu
	;	^lbx:si = App menu
	;	^lcx:dx = passed ^lbx:si
	;
		movdw	cxdx, bxsi		; ^lcx:dx = App menu, as passed
		jmp	done			; carry is set
addTrigger:
	;
	;  Haven't added trigger yet.  Return passed ^lbx:si.
	;
		xchg	bx, cx			; ^lcx:dx = App menu
		xchg	si, dx			; ^lbx:si = passed ^lbx:si
		clc				; say we have to add trigger
done:
		cmc
		
		.leave
		ret
SeeIfNeedToAddTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckPrintScreenCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return if this is PrintScreen trigger

CALLED BY:	SeeIfNeedToAddTrigger via ObjCompProcessChildren

PASS:		*ds:si = child
		*es:di = composite (App menu)

RETURN:		carry set to end processing (PrintScreen found)
		carry clear otherwise

DESTROYED:	es, di (preserved by ObjCompProcessChildren for its caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	brianc	2/17/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckPrintScreenCB	proc	far

	;
	;  See if we're a GenTriggerClass, firstly.
	;
		mov	di, segment GenTriggerClass
		mov	es, di
		mov	di, offset GenTriggerClass
		call	ObjIsObjectInClass
		jnc	done
	;
	;  We're a GenTriggerClass.  See if we're PrintScreen trigger
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		cmp	ds:[di].GTI_actionMsg, MSG_OL_APP_PRINT_SCREEN
		clc				; assume not PrintScreen
		jne	done			; not PrintScreen, return C clr
		stc				; else, indicate found
done:
		ret
CheckPrintScreenCB	endp



AppDetach	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveAppMenuAndPrintScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	remove created App menu and Print Screen trigger, if any

CALLED BY:	OLApplicationDetachPending
PASS:		*ds:si = OLApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveAppMenuAndPrintScreen	proc	near
	uses	si
	.enter
	mov	ax, TEMP_OL_APP_CREATED_PRINT_SCREEN
	call	ObjVarFindData
	jnc	noPrintScreen
	push	si			; save app obj
	push	({optr}ds:[bx]).handle, ({optr}ds:[bx]).offset
	call	ObjVarDeleteDataAt
	pop	bx, si			; ^lbx:si = Print Screen
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si			; *ds:si = app obj
noPrintScreen:
	mov	ax, TEMP_OL_APP_CREATED_APP_MENU
	call	ObjVarFindData
	jnc	done
	push	ds:[bx]
	call	ObjVarDeleteDataAt
	pop	si			; *ds:si = App menu
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	bp
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
RemoveAppMenuAndPrintScreen	endp

AppDetach	ends

endif	; if _JEDIMOTIF -------------------------------------------------------


if _PRINT_SCREEN	;------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppPrintScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the screen.

CALLED BY:	MSG_OL_APP_PRINT_SCREEN

PASS:		*ds:si	= OLApplicationClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ACJ	1/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLAppPrintScreen	method dynamic OLApplicationClass, 
					MSG_OL_APP_PRINT_SCREEN
		uses	bp

		screenDumpToken	local	GeodeToken

		.enter
	;
	;  Initialize the local(s).
	;
		mov	{word}ss:[screenDumpToken].GT_chars, 'SC'
		mov	{word}ss:[screenDumpToken].GT_chars+2, 'DP'
		mov	{word}ss:[screenDumpToken].GT_manufID, \
				MANUFACTURER_ID_GEOWORKS
	;
	;  Create a launch block for IACP.
	;
		mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACPCreateDefaultLaunchBlock
		mov	bx, dx			; ^hbx = launch block
		jc	error
	;
	;  Launch app using IACP.
	;
		push	bp			; locals
		segmov	es, ss
		lea	di, ss:screenDumpToken
		mov	ax, mask IACPCF_FIRST_ONLY or \
			mask IACPCF_OBEY_LAUNCH_MODEL or \
		(IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
		call	IACPConnect		; bp = IACPConnection

		mov_tr	ax, bp			; ax = IACPConnection
		pop	bp			; locals
		jc	error
	;
	;  Close the connection (but leave Screen Dumper active --
	;  it will close itself eventually).
	;
		push	bp			; locals
		mov_tr	bp, ax			; bp = IACPConnection
		clr	cx			; server shutting down
		call	IACPShutdown
		pop	bp			; locals
done::
error:
		.leave
		ret
OLAppPrintScreen	endm

endif	; _PRINT_SCREEN	-------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLAppEnsureIndicatorCorrect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that indicator floats to top or sink to
		bottom correctly. Specifically, if the currect active
		window does not occupy the whole screen, Indicator
		should appear (unless the active window is a bubble
		window).

CALLED BY:	MSG_OL_APP_ENSURE_INDICATOR_CORRECT
PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data
		es 	= segment of OLApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		/* if the app is detaching, don't do any check. --
		   commented because geometry should update if an
		   app transparently detach. */
		if the app is indicator (AS_NOT_USER_INTERACTABLE)
		don't do any check -- to prevent deadlock.
		if we haven't found indicator primary window {
			find it by callback
		}
		find the correct window that is not a popup nor indicator
		window. 
		if (no such window) {
		    quit
		}
		if (VisGetBounds(window).Left >= INDICATOR_WIDTH) {
		    Bring up indicator window (*)
		} else {
		    Bring up the top window (*)
		}

		(*) done by WinChangePriority, so we don't have to force
		queue, call message, and have delays or worries about
		synchronization.

		Need exclusive access to indicatorPrimaryWindow because
		OpenWinVisClose will change it when indicator window is
		closed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	6/19/95   	Initial version
	kho	3/18/96		Bring up window by WinChangePriority, thanks
				to Drew's suggestion.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _RUDY	;-----------------------------------------------------------
indicatorGeodeName	char	'indicato', 0

OLAppEnsureIndicatorCorrect	method dynamic OLApplicationClass, 
					MSG_OL_APP_ENSURE_INDICATOR_CORRECT
		.enter
	;
	; Add "AS_NOT_USER_INTERACTABLE" flag: to skip the check when
	; indicator window comes up (so that it doesn't recursively
	; check itself). -- kho, 1/23/96
	;
		add	bx, ds:[bx].Gen_offset
		test	ds:[bx].GAI_states, mask AS_NOT_USER_INTERACTABLE
		;		mask AS_RECEIVED_APP_OBJECT_DETACH or \
		;		mask AS_DETACHING or \
		LONG jnz	quit
	;
	; Push the layer window on stack. We will need it for
	; CreateChunkArrayOnWindows.
	;
		push	ds:[di].OLAI_fieldWin
	;
	; Find the layerID of indicator app, ala handle of indicator geode.
	;
		segmov	es, cs, ax
		mov	di, offset indicatorGeodeName	; es:di <- name
							; to match
FXIP <		clr	cx						>
FXIP <		call	SysCopyToStackESDI				>
		mov	ax, GEODE_NAME_SIZE
		mov	cx, mask GA_APPLICATION
		clr	dx
		call	GeodeFind			; bx <- geode handle
							; carry set if found
FXIP <		call	SysRemoveFromStack				>
EC <	WARNING_NC RUDY_INDICATOR_NOT_FOUND_IS_GEOS_BOOTING_OR_SHUTTING_DOWN>
							; it should be found
							; unless GEOS is
							; shutting down
		pop	di				; di <- field window
		LONG jnc	quit			; if not found, quit
		mov_tr	dx, bx				; dx <- indicator 
							; process handle
	;
	; Go make a list of windows we have, top most first.
	; di has the right window already
	;
		clr	ax
		mov	bx, ax
		call	CreateChunkArrayOnWindows	; *ds:si - list of
							; windows belonging to
							; this app in
							; chunk array 
	;
	; Get dgroup
	;
		mov	bx, handle dgroup
		call	MemDerefES			; es <- dgroup
	;
	; Need exclusive access to indicatorPrimaryWindow
	;
		PSem	es, indicatorWindowMutex
	;
	; See if indicator primary window has been found
	;
		tst	es:[indicatorPrimaryWindow]
		jnz	findTopWindow
	;
	; Find it with a callback, on the window chunk array
	; ax == 0
	;
		mov	cx, ax			; haven't found any yet
		mov	bx, cs
		mov	di, offset FindWindowWithLayerIDCallBack
		call	ChunkArrayEnum		; cx <- indicator window,
						; 0 if not found
		jcxz	quitVSem
		Assert	window, cx
		mov	es:[indicatorPrimaryWindow], cx
	;
	; Find the first window that is not a popup interaction nor indicator
	;
findTopWindow:
		mov	cx, ax			; haven't found any yet
;;		mov	bx, vseg FindTopWindowNoPopUpCallBack
		mov	bx, cs
		mov	di, offset FindTopWindowNoPopUpCallBack
		call	ChunkArrayEnum		; ax <- top window.left,
						; cx <- handle of process
						; that owns the window
						; bp <- window handle
						; or cx <- 0 if no
						; legal window found.
		push	ax
		mov	ax, si
		call	LMemFree		; Free the chunk array
		pop	ax
		jcxz	quitVSem
		Assert	window, bp		; top most window
	;
	; If help is up, then no matter what the windows of an app
	; may do, keep the indicator on top.
	;
		tst	es:[helpWindowIsUp]
		jnz	bringUpIndicator
	;
	; Check the currect window geometry.
	; if left >= 74 (FOAM_INDICATOR_WIDTH), bring indicator window
	; to top, else bring up the current app.
	;
		cmp	ax, FOAM_INDICATOR_WIDTH
		jl	bringWindowUp
bringUpIndicator:
	;
	; bring indicator to top.
	; 	dx == handle of indicator process
	;
		mov	di, es:[indicatorPrimaryWindow]
	;
	; If indicator quits already, don't do anything
	;
		cmp	di, RUDY_INDICATOR_WINDOW_ALREADY_CLOSED
EC <	WARNING_E RUDY_INDICATOR_WINDOW_NOT_FOUND_IS_GEOS_SHUTTING_DOWN>
		je	quitVSem
		
changePriority:
	;
	; dx == handle of process that owns top window, or indicator process
	; 	if we have to raise indicator.
	; di == handle of top window, or indicator primary window
	;
		Assert	window, di
		mov	si, WIT_PARENT_WIN
		call	WinGetInfo		; ax <- parent window
		mov	di, ax
		mov	ax, mask WPF_LAYER	; change layer priority, and 
						; place window in front
		call	WinChangePriority
quitVSem:
		VSem	es, indicatorWindowMutex
quit:
		.leave
		ret
bringWindowUp:
	;
	; Bring up the APP that owns the top window to cover the
	; indicator, instead of sending message to indicator for it to
	; go down. This will speed up the process.
	;
		mov	dx, cx			; dx <- handle of process
		mov	di, bp			; find handle of
						; parent window
		jmp	changePriority

OLAppEnsureIndicatorCorrect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindTopWindowNoPopUpCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a window in the chunk array passed, looking for
		top window that is not a popup, and return that
		window's inputOD.

CALLED BY:	INTERNAL
PASS:		*ds:si	= chunk array
		ds:di	= element to process
		dx	= layerID of indicator app (ala handle of
			  Indicator geode)

RETURN:		if this window is indicator app window or window is a popup
		/ flashing note
			cx cleared
			carry clear to continue along the list of windows
		endif
		if this is a GenField (layerID == 0) {
			callback called recursively on the GenField
			ret
		}
		if this window is not a popup/flashing note:
			ax <- left of window
			cx <- handle of process that owns the window
			bp <- window handle
			carry set to stop traversing the list
		endif

DESTROYED:	bx, si, di, as allowd by ChunkArrayEnum
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		So we called CreateChunkArrayOnWindows in
		OLAppEnsureIndicatorCorrect.

		The top windows in chunk array belong to the app in
		foreground, the next few windows belong to the
		previous app in foreground, etc.

		A few things to worry: when we pull up / push down
		indicator app (which is what we are doing) indicator
		app is considered app in foreground. So the first
		window in the chunk array could be GenPrimary of
		indicator. We don't want to consider that window.
		We see that the layerID of any window =
		handle of Geode (hence fixed). We just have to find
		layerID of indicator beforehand (dx), and ignore it if
		our layerID == dx.

		Second thing: if UI thread puts up a dialog, 
		(e.g. charset table in text lib) the layerID != 0, but
		we ignore popup. The only 2 windows left in array are
		GenFields, with layerID == 0. We will not find any
		window that belongs to active app in the chunk
		array. In that case, recursively call this call back
		to the children of the GenField.

		if (our layerID == bp) we go to next window (we are
		indicator primary)

		if (layerID == 0) (we are GenFields) recursively call
		this to our children. If anything good shows up,
		return, otherwise traverse to next (simbling window).

		Get the window bounds and see if it is a pop
		up/flashing note. If so, traverse to next.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	6/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindTopWindowNoPopUpCallBack	proc	far
		uses	dx
		.enter

		mov	di, ds:[di]			; di <- window handle
	;
	; Find layerID of element
	;
		mov	si, WIT_LAYER_ID
		call	WinGetInfo			; ax <- layer ID
	;
	; If this window is indicator primary (ie. layerID == dx) we traverse
	; to next element
	;
		cmp	ax, dx
		je	short traverseNext
	;
	; If this window is GenField with layerID == 0, we recursively
	; call this call back on the GenField (reason being, the
	; children of this GenField do not show up in the chunk array
	; created in OLAppEnsureIndicatorCorrect).
	;
		tst	ax
		jz	short doGenField
	;
	; Get the vis bound of window
	;
		push	ax			; layer ID
		call	WinGetWinScreenBounds	; ax <- left, bx <- top,
						; cx <- right, dx <- bottom
		pop	cx			; cx <- layer ID
	;
	; If this window's top is a little bit away from screen top,
	; we guess this is a popup or flashing note, and ignore it.
	; Yes, this is very very gross...
	;
	;	cmp	bx, 3
	;	jge	traverseNext

	;
	; Oh.. to cover more cases, the determinant is: if the left of
	; window is more than 5 + FOAM_INDICATOR_WIDTH pixels from
	; screen, we think this is a popup / flashing note
	;
		cmp	ax, FOAM_INDICATOR_WIDTH+5
		jge	traverseNext
	;
	; We find the top window that is not a popup/flashing note.
	; Now return
	;	cx = process handle,
	;	ax = window.left
	;	bp = window handle
	;
		mov	bp, di
succeed:
		stc					; succeed!!
quit:
		.leave
		ret
traverseNext:
		clr	cx
		clc
		jmp	short quit

doGenField:
	;
	; ^hdi is the GenField handle, and dx is layerID of indicator app
	;
EC <		Assert	window, di					>
	;
	; We have to recursively call this call back to the children
	; of the GenField, because they are not included in the chunk
	; array we made in OLAppEnsureIndicatorCorrect
	;
	; Go make a list of windows we have, top most first.
	;
		mov	ax, 0
		mov	bx, 0
		call	CreateChunkArrayOnWindows	; *ds:si - list of
							; windows belonging to
							; this app in
							; chunk array 

		clr	cx			; haven't found any yet
		mov	bx, cs
;		mov	bx, vseg FindTopWindowNoPopUpCallBack
		mov	di, offset FindTopWindowNoPopUpCallBack
		call	ChunkArrayEnum		; ax <- window.left,
						; cx <- process handle that
						; owns the window,
						; bp <- window handle
						; or cx <- 0 if no
						; legal window found.
		push	ax
		mov	ax, si			; *ds:ax - chunk array
		call	LMemFree
		pop	ax
		
		jcxz	short traverseNext
		jmp	short succeed
		
FindTopWindowNoPopUpCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindWindowWithLayerIDCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	From the chunk array, find any window which has the passed
		layer ID.
		This is primarily used to find the window of indicator
		primary.

CALLED BY:	INTERNAL (ChunkArrayEnum)
PASS:		*ds:si	= chunk array
		ds:di	= element to process
		dx	= layerID of indicator app (ala handle of
			  Indicator geode)

RETURN:		if this window has the right layerID:
			cx <- window handle
			carry set to stop traversing the list
		else
			cx cleared
			carry clear
		endif

DESTROYED:	bx, si, di as allowed by ChunkArrayEnum
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		find the layer ID
		if (layerID == 0)
			// the window is a GenField
			create chunk array on the GenField, and recursively
			calls the call back (*)
		endif
		if (layerID == dx)
			return found
		else
			return not found
		endif

		(*) Generally, we shouldn't have to recursively call the
		callback: we are expected to find the indicator window during
		the boot process when the first app comes up. We see a
		GenField only if a sysModal dialog comes up (on UI
		thread). So a warning is issued if we ever have to create
		chunk array and call callback recursively.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	3/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindWindowWithLayerIDCallBack	proc	far
		uses	ax
		.enter

		mov	di, ds:[di]			; di <- window handle
	;
	; Find layerID of element
	;
		mov	si, WIT_LAYER_ID
		call	WinGetInfo			; ax <- layer ID
	;
	; If this window is GenField with layerID == 0, we recursively
	; call this call back on the GenField (reason being, the
	; children of this GenField do not show up in the chunk array
	; created in OLAppEnsureIndicatorCorrect).
	;
		tst	ax
		jz	short doGenField
	;
	; If layerID is same as dx, we find it, and return
	;
		cmp	ax, dx
		jne	traverseNext
	;
	; Return with correct value
	;
		mov	cx, di
succeed:
		stc					; to stop traversing
quit:		
		.leave
		ret
traverseNext:
		clc
		jmp	quit

doGenField:
	;
	; ^hdi is the GenField handle, and dx is layerID of indicator app
	;
EC <		WARNING	RUDY_HAS_TO_FIND_INDICATOR_WINDOW_IN_GEN_FIELD	>
EC <		Assert	window, di					>
	;
	; We have to recursively call this call back to the children
	; of the GenField, because they are not included in the chunk
	; array we made in OLAppEnsureIndicatorCorrect
	;
	; Go make a list of windows we have, top most first.
	;
		mov	ax, 0
		mov	bx, 0
		call	CreateChunkArrayOnWindows	; *ds:si - list of
							; windows belonging to
							; this app in
							; chunk array 

		clr	cx			; haven't found any yet
		mov	bx, cs
		mov	di, offset FindWindowWithLayerIDCallBack
		call	ChunkArrayEnum		; cx <- window handle
						; or cx <- 0 if not found
		push	ax
		mov	ax, si			; *ds:ax - chunk array
		call	LMemFree
		pop	ax
		
		jcxz	short traverseNext		; not found..
		jmp	short succeed
		
FindWindowWithLayerIDCallBack	endp

endif	; _RUDY -------------------------------------------------------------

AppCommon	ends









