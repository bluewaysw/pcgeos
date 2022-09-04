COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		OpenLook/View
FILE:		viewPane.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER
				Allow quick tranfser destinations to
				receive MSG_PTRs by releasing win and mouse
				grabs.

 ?? INT OLPaneAdjustOrigin	Adjusts the origin to keep valid, or to
				stay tail oriented. The callers of this
				routine have messed around with the
				parameters of the pane, either changing the
				document size or changing the page size.

 ?? INT CustomCompareCharFlags	If both keyboard events are presses or both
				releases we eat the event.

 ?? INT BeepIfUnusedPress	Beeps if the user is pressing on a
				character.

    MTD MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
				Activates the object with the mnemonic.

 ?? INT HandleScrollKey		Handles a scrolling key press, if
				applicable.

 ?? INT CheckKeyIfScrollable	Checks for scroll keys if scrollable in
				that direction.

    MTD MSG_SPEC_NOTIFY_NAVIGATION_COMPLETE
				Notifies object that they will be the new
				focus via keyboard navigation.

 ?? INT EnsureScrollbars	Make sure scrollbars exist if needed.  Sets
				visible bits appropriately.

 ?? INT SetupScrollbarIfNeeded	Does appropriate things based on the view
				bits.  If we need a scrollbar, and there
				isn't one, we create it.  If there already
				is one, we set the visible bits
				appropriately.

 ?? INT CheckIfLeavingSpace	See if we're leaving room for scroller.

    MTD MSG_SPEC_CTRL_SET_MONIKER_OFFSET
				Manually sets a moniker offset based on the
				first child's position.

 ?? INT CheckScrollbarAssumption
				Error checking to make we got a scrollbar
				here.

    MTD MSG_META_GET_FOCUS_EXCL	Returns the current focus/target below this
				point in hierarchy

 ?? INT KillFloatingScroller	Make a scroller & its floating window go
				away.  Forever.

    MTD MSG_GEN_APPLY		Comes from a "change" being pressed in
				Rudy.

 ?? none OLPaneSetFlagAndSendToApp
				Sends method passed on to OD of view.  In
				case of focus/target gain/lost, set/reset
				flag in local instance data so that we will
				have a record of whether we have the
				focus/target or not, which is needed in
				SET_CONTENT.

    INT OLPaneSendToAppNow	Send method & data passed on to the output
				OD

    INT OLPaneSendToApp		Send method & data passed on to the output
				OD

    INT OLPaneCallApp		Send method & data passed on to the output
				OD

    INT ToAppCommon		Send method & data passed on to the output
				OD

    INT SendNotifyCommon	Send method & data passed on to the output
				OD

    INT SendNotifyLow		Send method & data passed on to the output
				OD

 ?? INT OLPaneFinishSetDocSize	Finishes the job of setting the document
				size.

 ?? INT OLPaneCallScrollbars	Sends method on to scrollbars.  The
				appropriate argument is passed to the
				scrollbar in cx.

 ?? INT OLPaneCallScrollbarsIfNonZeroArg
				Sends method on to scrollbars.  Only sends
				to a scrollbar if the arguments to be
				passed to the scrollbar are non-zero. The
				appropriate arguments are passed to the
				scrollbar in dx:cx.

 ?? INT OLPaneCallScrollbarsWithDWords
				Sends method on to scrollbars.  The
				appropriate arguments are passed to the
				scrollbar in dx:cx.

 ?? INT CallHorizScrollbar	Sends method on to scrollbars.

 ?? INT CallVertScrollbar	Sends method on to scrollbars.

 ?? INT CallScrollbar		Sends method on to a scrollbar.  Could be
				the vertical or horizontal scrollbar for
				the pane.

    MTD MSG_SPEC_NOTIFY_NOT_ENABLED
				Notifies object that someone has disabled
				us.

    MTD MSG_GEN_VIEW_GET_VISIBLE_RECT
				Returns visible rect.

 ?? none AddRemoveCommon	Builds out a pane, adding pane stuff if
				necessary. Does pane stuff to build out
				scrollbars, and does pane stuff to process
				hints and send the view handle to the OD.

    MTD MSG_SPEC_SCAN_GEOMETRY_HINTS
				Scans geometry hints.2/12/92

 ?? none LeaveRoomVert		Builds out children.

 ?? none LeaveRoomHoriz		Builds out children.

 ?? none DoNotWinScroll		Builds out children.

 ?? none RemoveScrollers	Builds out children.

 ?? INT SetScrollbarAreas	Finds out where the scrollbars want to be,
				and stores the info away for later.

 ?? INT FindAreaObjects		Looks for objects to go in different areas.

 ?? INT ChooseAreaForObject	Chooses an area for this object.

 ?? INT AddObjectToArea		Adds an object to the given area of a view.
				Various area pointers are updated as
				necessary.

 ?? INT SeeIfWeNeedToSkipAdd	See if this object should NOT be stored as
				usual in the one of the view outlier areas.

 ?? INT CreateAreaOLCtrl	Creates an OLCtrl to manage objects under
				an area. Unbuilds the previous object in
				that area and adds it to the ctrl, if
				necesssary.

 ?? INT GetObjectAreaChoice	Returns object's area choice, in the form
				of an offset to the view's area

 ?? INT GetFloatingParent	Get (or create) a floating window to put
				the scroller in.

 ?? INT CreateFloater		Instantiate & initiate the object.

 ?? INT RegisterOrUnregisterFloater
				"Register" for move-window & change-layer
				events.

 ?? INT FindOLWinGen		Get first win-group above us.

 ?? INT GetTitleBarGroup	Get the title-bar group to put the scroller
				in.

 ?? INT SetupPaneColor		Sets up the correct colors to use.

 ?? INT PaneGetWindow		Gets window handle in di.

 ?? INT SendViewHandle		Sends view handle to output object, to let
				content object know what it's view will be.
				Also visibly builds any objects in the view
				OD.

    MTD MSG_GEN_VIEW_SET_COLOR	Sets the view color.

    MTD MSG_SPEC_VIEW_SET_PANE_FLAGS
				Sets pane attrs.

    MTD MSG_VIS_RECALC_SIZE	Size to fit view.

    MTD MSG_VIS_OPEN		Open on View window.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	2/91		Started V2.0

DESCRIPTION:
	This file implements the Open Look pane object.

	$Id: cviewPane.asm,v 2.218 97/01/07 00:51:19 joon Exp $

-------------------------------------------------------------------------------@

	;
	;	For documentation of the OLPaneClass see:
	;	/staff/pcgeos/Spec/olPaneClass.doc
	; 

CommonUIClassStructures segment resource

; Define the class record.
  	OLPaneClass	 	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
				
CommonUIClassStructures ends


;---------------------------------------------------

	
ViewCommon segment resource

.assert (offset OLPSF_VERTICAL eq offset SF_VERTICAL), \
	"These Chris Bits must match."

.assert (offset OLPSF_ABSOLUTE eq offset SF_ABSOLUTE), \
	"These Chris Bits must match."
	
.assert (offset OLPSF_DOC_SIZE_CHANGE eq offset SF_DOC_SIZE_CHANGE), \
	"These Chris Bits must match."

SSP_VERTICAL	equ	size dword		;flag used as offset into data

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPaneAllowGlobalTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow quick tranfser destinations to receive MSG_PTRs by
		releasing win and mouse grabs.

PASS:		*ds:si	= object
		ds:di = instance

		ax = MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPaneAllowGlobalTransfer	method dynamic OLPaneClass, \
					MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER
	;
	; If already doing a wandering grab, done.
	;
	test	ds:[di].OLPI_optFlags, mask OLPOF_WANDERING_GRAB
	jnz	done

	; If not, we are now!
	;
	ornf	ds:[di].OLPI_optFlags, mask OLPOF_WANDERING_GRAB

	; If mouse is still over view window, or user has CONSTRAIN bit 
	; currently held down, we're kosher, just return with the flag set.
	;
	test	ds:[di].OLPI_optFlags, mask OLPOF_PTR_IN_RAW_UNIV or \
						mask OLPOF_CONSTRAIN
	jnz	done

	; If mouse outside of window, force release of gadget exclusive, so
	; that we let the mouse wander again.
	;
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	call	VisCallParentWithSelf

	mov	ax, MSG_FLOW_ALLOW_GLOBAL_TRANSFER
	clr	di
	call	UserCallFlow

done:

	; Clear any pending menu navigation toggle
	;
	call	OpenClearToggleMenuNavPending

	ret

OLPaneAllowGlobalTransfer	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGrabFocusExcl

DESCRIPTION:	Takes/releeases focus exclusive for object, if click-to-type
		environment

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass

	ax - MSG_META_GRAB_FOCUS_EXCL

RETURN:
	nothing
	ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version

------------------------------------------------------------------------------@
OLPaneGrabFocusExcl	method OLPaneClass, MSG_META_GRAB_FOCUS_EXCL
	;
	; View must be focusable in order to get focus
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_FOCUSABLE
	jz	done		; if so, skip taking focus

	;
	; Otherwise, let superclass do its thing
	;
	mov	di, offset OLPaneClass
	GOTO	ObjCallSuperNoLock
done:
	ret
OLPaneGrabFocusExcl	endm



ViewCommon ends

;--------------------------------

ViewCommon segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetDocBounds -- 
		MSG_GEN_VIEW_SET_DOC_BOUNDS for OLPaneClass

DESCRIPTION:	Sets the document size.  Will have been set by generic UI
		on entry, we're just here to clean up.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_DOC_BOUNDS
		ss:bp   - RectDWord: new scrollable bounds

RETURN:		nothing
		ax, cx, dx, bp -- trashed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/24/90		Initial version

------------------------------------------------------------------------------@

OLPaneSetDocBounds	method OLPaneClass, MSG_GEN_VIEW_SET_DOC_BOUNDS
	;
	; Lets adjust the origin, if necessary, to keep the origin valid
	; and, if necessary, to keep it tail oriented.
	;
	mov	bp, SA_SCROLL or mask OLPSF_ALWAYS_SEND_NORMALIZE \
			      or mask OLPSF_DOC_SIZE_CHANGE \
			      or mask OLPSF_ABSOLUTE
	call	OLPaneAdjustOrigin
	;
	; Tell the scrollbars about the change in document size and redo
	; geometry if necessary.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GVI_attrs, mask GVA_TRACK_SCROLLING
;	jnz	exit				;normalizing, branch
	;
	; hack to fix problem where if the view isn't on-screen,
	; OLPaneAdjustOrigin will not have done track-scrolling and so
	; scrollbars wouldn't be updated - brianc 6/16/93
	;
	jz	finishSetDocSize
	call	PaneGetWindow
	jnz	exit	; have window, OLPaneAdjustOrigin send track-scrolling
			;	method and will do a OLPaneFinishSetDocSize
			;	from there
			; else, do it ourselves here
finishSetDocSize:
	call	OLPaneFinishSetDocSize
exit:
	ret
OLPaneSetDocBounds	endm


			



COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPaneAdjustOrigin

SYNOPSIS:	Adjusts the origin to keep valid, or to stay tail oriented.
		The callers of this routine have messed around with the
		parameters of the pane, either changing the document size
		or changing the page size.

CALLED BY:	OLPaneSetDocSize, OLPaneGeometryValid

PASS:		*ds:si -- pane
		bp     -- OLPaneScrollFlags

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/21/90		Initial version

------------------------------------------------------------------------------@

OLPaneAdjustOrigin	proc	near
	push	bp				;save OLPaneScrollFlags
	;
	; Assume no tail orientation to preserve -- let's try to stay where
	; we are, unless new conditions require a scroll.
	;
	call	GetXOrigin			;get x origin in bx:ax
	call	GetYOrigin			;get y origin in dx:cx
	;
	; If we're tail oriented in the vertical or horizontal direction,
	; and we're still at the bottom or right edge of the document, let's
	; try to preserve that.
	;
	mov	di, ds:[si]			;point to instance
	mov	bp, di
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	add	bp, ds:[bp].Gen_offset		;ds:[bp] -- GenInstance
	test	ds:[bp].GVI_vertAttrs, mask GVDA_TAIL_ORIENTED
	jz	10$				;not vertically tail oriented
	test	ds:[di].OLPI_flags, mask OLPF_AT_BOTTOM_EDGE
	jz	10$				;not at bottom anyway, branch
	mov	dx, ds:[bp].GVI_docBounds.RD_bottom.high
	mov	cx, ds:[bp].GVI_docBounds.RD_bottom.low
10$:
	test	ds:[bp].GVI_horizAttrs, mask GVDA_TAIL_ORIENTED
	jz	20$				;not vertically tail oriented
	test	ds:[di].OLPI_flags, mask OLPF_AT_RIGHT_EDGE
	jz	20$				;not at bottom anyway, branch
	mov	bx, ds:[bp].GVI_docBounds.RD_right.high
	mov	ax, ds:[bp].GVI_docBounds.RD_right.low
20$:
	call	MakeRelativeToOrigin		;now make relative
	pop	bp				;restore OLPaneScrollFlags
	call	OLPaneScroll
	ret
OLPaneAdjustOrigin	endp


ViewCommon	ends


ActionObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetPtrImage

DESCRIPTION:	Allows changing ptr image to be displayed automatically 
		whenever mouse enters this view.

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass

	ax - MSG_GEN_VIEW_SET_PTR_IMAGE

	cx:dx   - optr to PointerDef in sharable memory block, OR
        cx = 0, and dx = 0 for no ptr image request for view, OR
        	    dx = PtrImageValue (see Internal/im.def)
        bp      - PIL_GADGET, for feedback from individual gadgets, OR
                   PIL_WINDOW, to set the lower priority background
                               cursor to use over the view.
        NOTE:  if cx = 0, dx = PIV_UPDATE, bp is not used.


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

------------------------------------------------------------------------------@
OLPaneSetPtrImage	method OLPaneClass, MSG_GEN_VIEW_SET_PTR_IMAGE
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	cmp	bp, PIL_WINDOW		; If window level, save across
					; close/open of view
	jne	afterSaved
					; Store away for posterity
	mov	ds:[di].OLPI_ptrImage.handle, cx
	mov	ds:[di].OLPI_ptrImage.chunk, dx
afterSaved:

	mov	di, ds:[di].OLPI_window
	tst	di
	jz	done

	call	WinSetPtrImage		; set in window sys
done:
	ret
	
OLPaneSetPtrImage	endm

ActionObscure	ends


ViewCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneKbdChar -- 
		MSG_META_KBD_CHAR for OLPaneClass

DESCRIPTION:	Returns accelerator-type kbd chars, unless VWA_GRAB_ACCELERATOR
		CHARS is set.  Sends the rest to the OD.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_KBD_CHAR
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState 
		bp high = scan code 

RETURN:		nothing
		ax, cx, dx, bp -- trashed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 2/90		Initial version

------------------------------------------------------------------------------@

OLPaneKbdChar	method OLPaneClass, MSG_META_KBD_CHAR
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GVI_attrs, mask GVA_SEND_ALL_KBD_CHARS
	jnz	toContent			;sending everything, branch
	
;
; Now this is called here, because otherwise page up/down events just get sent
; to our parent, instead of causing a scroll...	
;

if not _RUDY
;
; For the Responder UI, it turns out that the page up/page down keys are
; overloaded, and do different things, depending upon what objects are under
; the content. So, give them a chance to handle these nifty scroll keys first,
; before we mess with them (we'll handle them in OLPaneFupKbdChar, if our
; child doesn't handle them).
;
	call	HandleScrollKey			;if scroll key, handle it
	jc	exit				;if handled, exit
endif

	;
	; If something is pressed in the pane window, we won't send the 
	; character up.   (Why is unclear to me now, but there certainly was
	; a good reason at the time.)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB
	jnz	notHandledBySpecUI		;any of these, send to app only
	
	
	call	SpecCheckIfSpecialUIChar	;handled specially by the UI?
	jnc	notHandledBySpecUI		;nope, send to app
	
	push	cx, dx, bp

	mov	di, 1000
	call	ThreadBorrowStackSpace
	mov	ax, MSG_META_FUP_KBD_CHAR	;do a fup, (send up -- our
	call	VisCallParent			; FUP handler assumes chars are
	call	ThreadReturnStackSpace

	pop	cx, dx, bp
	jnc	notHandledBySpecUI		; coming from the content)
	
	;
	; Always send alt keys to the app, even if handled by the specific UI.
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_LALT			>
DBCS <	cmp	cx, C_SYS_LEFT_ALT					>
	je	notHandledBySpecUI
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_RALT			>
DBCS <	cmp	cx, C_SYS_RIGHT_ALT					>
	jne	exit
						
notHandledBySpecUI:
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jnz	toContent			;a key down event, send to app
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_DONT_SEND_KBD_RELEASES	
	jnz	exit				;not sending releases, exit
	
toContent:
	clr	di

	;***** START HACK
	;	If there are few handles left...
	push	dx
	mov	ax, SGIT_NUMBER_OF_FREE_HANDLES
	call	SysGetInfo
	pop	dx
	cmp	ax, LOW_ON_FREE_HANDLES_THRESHOLD
	ja	10$

if _RUDY
	; 	For Rudy we don't want to discard keyboard input events if one
	;	is a first_press and the other is a release.  So we define
	;	a custom compare routine to make sure that this does not
	;	happen.
	mov	di, mask MF_CHECK_DUPLICATE or mask MF_MATCH_ALL or \
		    mask MF_FORCE_QUEUE or mask MF_CUSTOM
	push	cs
	mov	ax, offset CustomCompareCharFlags
	push	ax
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset	; get ptr to SpecificInstance
	mov	bx, ds:[si].GVI_content.handle
	mov	si, ds:[si].GVI_content.chunk
	mov	ax, MSG_META_KBD_CHAR		
	call	ObjMessage		; send to content
	jmp	exit	
else
	;	Drop key event if there are any others already in the queue.
	mov	di, mask MF_CHECK_DUPLICATE or mask MF_MATCH_ALL or \
		    mask MF_FORCE_QUEUE or mask MF_CAN_DISCARD_IF_DESPERATE
endif		
	;***** END HACK
10$:
	mov	ax, MSG_META_KBD_CHAR		;send to content
	GOTO	ToAppCommon
exit:
	ret
OLPaneKbdChar	endm

if _RUDY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustomCompareCharFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If both keyboard events are presses or both releases we
		eat the event.

CALLED BY:	ObjMessage
PASS:		ax, cx, dx, si, bp - event being sent
		ds:bx - event in queue (structure Event)
RETURN:		di - flags:
			PROC_SE_EXIT - to exit without queueing the new
				       message. The routine may have modified
				       the event at ds:dx to incorporate the
				       event being set.
			PROC_SE_STORE_AT_BACK - to store teh new message at
						the back of the queue.
			PROC_SE_CONTINUE - to continue down the queue.
		cx, dx, bp - possible return values to the caller of ObjMessage
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	4/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CustomCompareCharFlags	proc	far
	mov	di, PROC_SE_CONTINUE
	cmp	ds:[bx].HE_method, MSG_META_KBD_CHAR
	jne	exit

;	If events are both presses or both releases, then eat the event,
;	else continue to allow the event to be queued up.

	push	dx
	xor	dx, ds:[bx].HE_dx
	test	dl, mask CF_RELEASE	
	pop	dx
	jnz	exit
	mov	di, PROC_SE_EXIT	;Eat the event
exit:
	ret
CustomCompareCharFlags	endp
endif

ViewCommon	ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneFupKbdChar -- 
		MSG_META_FUP_KBD_CHAR for OLPaneClass

DESCRIPTION:	Handles characters coming back from the OD.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_FUP_KBD_CHAR
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState 
		bp high = scan code 

RETURN:		nothing
		ax, cx, dx, bp -- trashed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/16/90		Initial version

------------------------------------------------------------------------------@

OLPaneFupKbdChar	method OLPaneClass, MSG_META_FUP_KBD_CHAR
	push	si
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	callSuper			;skip if not press event...
	
	call	HandleScrollKey			;if scroll key, handle it
	jc	exit				;if handled, exit

callSuper:
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_ENTER			>
DBCS <	cmp	cx, C_SYS_ENTER						>
						;enter key, FUP up for defaults
	je	sendCharUp			;  (I'm nervous to FUP it before
						;   sending to app, but it might
						;   be OK to do that.)
	;
	; Let's FUP tabs, so that keyboard navigation functions if the 
	; content FUPS the character to the view.  -11/ 3/92 cbh
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_TAB			>
DBCS <	cmp	cx, C_SYS_TAB						>
	je	sendCharUp

if _RUDY
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_PREVIOUS			>
DBCS <	cmp	cx, C_SYS_PREVIOUS					>
	je	sendCharUp						
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_NEXT			>
DBCS <	cmp	cx, C_SYS_NEXT						>
	je	sendCharUp
endif

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GVI_attrs, mask GVA_SEND_ALL_KBD_CHARS
	jnz	sentAllKbdChars			;sent all kbd chars to content,
						;   need to FUP now.
	;
	; Code added 6/30/92 cbh for non-send-all cases, to allow any characters
	; that weren't deemed normal accelerator chars the first time to be sent
	; up now.  If apps don't want this behavior, they can avoid fupping.
	;

	call	SpecCheckIfSpecialUIChar	;special UI char?
	jc	beepIfUnusedPress		;yes, already been tried by 
						;  specific UI earlier, beep.
						;else fall through to FUP
	
sentAllKbdChars:

;	Changed 6/30/92 cbh so that an application that has SEND_ALL_KBD_CHARS
;	set can have all characters eligible as accelerators.  Those that don't
; 	have this set are limited to the normal selection of alt- and ctrl- 
;	chars.
;	call	SpecCheckIfSpecialUIChar	;handled specially by the UI?
;	jnc	beepIfUnusedPress		;nope, exit

sendCharUp:	
	;
	; If something is pressed in the pane window, we won't send the 
	; character up.   I believe so that menu navigation won't be toggled
	; on ALT presses when using it to modify a quick-copy.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB
	jnz	exit				;any of these, throw char away

	pop	si				;restore handle
	push	si				;save again for exit
	push	dx
	mov	ax, MSG_META_FUP_KBD_CHAR
	mov	di, offset OLPaneClass		;call superclass to fup
	call	ObjCallSuperNoLock
	pop	dx
	jc	exit				;handled by spec UI, exit
beepIfUnusedPress:
	call	BeepIfUnusedPress		;beep if needed

exit:
	pop	si				;restore handle
	ret
OLPaneFupKbdChar	endm




COMMENT @----------------------------------------------------------------------

ROUTINE:	BeepIfUnusedPress

SYNOPSIS:	Beeps if the user is pressing on a character.

CALLED BY:	OLPaneFupKbdChar

PASS:		*ds:si -- pane
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState 
		bp high = scan code 

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/26/92		Initial version

------------------------------------------------------------------------------@

BeepIfUnusedPress	proc	near
				; No destination!
				; See if first press or not
	test	dl, mask CF_FIRST_PRESS
	jz	exit		; if not, no beep

;	test	dl, mask CF_RELEASE
;	jnz	exit		; ignore releases too.  -cbh 2/ 5/93

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT or mask CF_RELEASE
	jnz	exit				; Quit if not press, accent, or
						; state key. -cbh 3/ 8/93
	
	;
	; Don't beep on any shift keys or toggle state keys, or extended
	; state keys (if there ever are any).
	;
SBCS <	cmp	ch, CS_CONTROL						>
DBCS <	cmp	ch, CS_CONTROL_HB					>
	jne	10$

	tst	cl
	jz	exit		; I don't know why this is ever sent (it's sent
				; by the penInputTest app) but there it
				; is.  -cbh 2/ 5/93

SBCS <	cmp	cl, VC_LALT						>
DBCS <	cmp	cl, C_SYS_LEFT_ALT and 0x00ff				>
	jb	10$
SBCS < 	cmp	cl, VC_INVALID_KEY					>
DBCS < 	cmp	cl, C_NOT_A_CHARACTER and 0x00ff			>
	jb	exit
10$:
				; Let user know that he is annoying us ;)
	push	ax
	mov	ax, SST_NO_INPUT
	call	UserStandardSound
	pop	ax
exit:
	ret
BeepIfUnusedPress	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneActivateObjectWithMnemonic -- 
		MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC for OLPaneClass

DESCRIPTION:	Activates the object with the mnemonic.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState (unused)
		bp high = scan code (unused)

RETURN:		carry set if match found
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/ 8/93        Initial Version

------------------------------------------------------------------------------@
OLPaneActivateObjectWithMnemonic	method dynamic	OLPaneClass, \
				MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_GENERIC_CONTENTS
	jz	exit			;exit (c=0)

	call	VisCheckIfFullyEnabled
	jnc	noActivate
	call	VisCheckMnemonic
	jnc	noActivate
	;
	; mnemonic matches, grab focus
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLCI_buildFlags, mask OLBF_TOOLBOX
	jnz	exit			;is a toolbox, don't grab (carry clear)
	call	MetaGrabFocusExclLow

	;
	; New code to send the ACTIVATE message to the content, so text objects
	; will grab the focus, too.   Hopefully won't screw up list objects
	; in views.   8/31/93 cbh
	;
	call	OLPaneSendToAppNow
	stc				;handled, no matter what
	jmp	short exit

noActivate:
	;
	; let superclass call children, since either were are not fully
	; enabled, or our mnemonic doesn't match, superclass won't be
	; activating us, just calling our children
	;
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, offset OLPaneClass
	call	ObjCallSuperNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret
OLPaneActivateObjectWithMnemonic	endm

KbdNavigation	ends


ViewCommon	segment resource
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	HandleScrollKey

SYNOPSIS:	Handles a scrolling key press, if applicable.

CALLED BY:	OLPaneKbdChar, OLPaneFupKbdChar

PASS:		*ds:si -- object
		cx = charValue
		dl = CharFlags
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc.
			CF_TEMP_ACCENT - set if accented char pending
		dh = ShiftState
		bp low = ToggleState 
		bp high = scan code 

RETURN:		carry set if handled

DESTROYED:	possibly everything if handled, otherwise di, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/16/90		Initial version

------------------------------------------------------------------------------@

HandleScrollKey	proc	far
	push	ax
	
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	exit			;exit if not press, carry clear
	;
	; Don't handle the keypress if the view is not scrollable.  
	; -cbh 10/ 7/91
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	add	di, offset GVI_vertAttrs
if _ODIE
	;
	; allow up/down arrow to scroll text object, but only non-editable text
	;
	mov	ax, ATTR_OL_PANE_SCROLLING_TEXT
	call	ObjVarFindData
	jnc	notScrollingText

	mov	bx, ds:[bx]		;*ds:bx = OLText
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLTDI_specState, mask TDSS_EDITABLE
	jnz	notScrollingText

	mov	ax, offset cs:OLPaneTextVertKbdBindings
	jmp	short haveVertBindings

notScrollingText:
endif
	mov	ax, offset cs:OLPaneVertKbdBindings
haveVertBindings::
	push	di			;save pointer to attributes
	call	CheckKeyIfScrollable
	pop	di
	jc	sendMessage		;key found, send message
	
	add	di, offset GVI_horizAttrs - offset GVI_vertAttrs
	mov	ax, offset cs:OLPaneHorizKbdBindings
	call	CheckKeyIfScrollable
	jnc	exit			;skip if none found...
	
sendMessage:
	;
	; Found a shortcut, we'll set a flag to trickle to the track scrolling
	; info.  6/15/94 cbh
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLPI_optFlags, mask OLPOF_KBD_CHAR_SCROLL

	;
	; Found a scroll shortcut.  We'll send the method to ourselves.
	;
	call	ObjCallInstanceNoLock
	stc				;say handled
exit:
	pop	ax
	ret
HandleScrollKey	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckKeyIfScrollable

SYNOPSIS:	Checks for scroll keys if scrollable in that direction.

CALLED BY:	HandleScrollKey

PASS:		ds:di -- pointer to GenViewDimensionAttrs for that direction
		cs:ax -- pointer to table of key bindings for 
				ConvertKeyToMethod

RETURN:		carry set if handled

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/ 7/91	Initial version

------------------------------------------------------------------------------@

CheckKeyIfScrollable	proc	near
	test	{word} ds:[di], mask GVDA_SCROLLABLE
	clc				;not scrollable, exit
	jz	exit
	push	es
	mov	di, cs			
	mov	es, di
	mov	di, ax			;es:di <- bindings to use
	call	ConvertKeyToMethod
	pop	es
exit:
	ret
CheckKeyIfScrollable	endp
		
		
;Keyboard shortcut bindings for OLPaneClass (do not separate tables)

OLPaneVertKbdBindings	label	word
	word	length OLPaneVertShortcutList
if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
OLPaneVertShortcutList KeyboardShortcut \
	<1, 0, 0, 0, C_SYS_PREVIOUS and mask KS_CHAR>,		;Page up
	<1, 0, 0, 0, C_SYS_NEXT and mask KS_CHAR>,		;Page down
	<1, 0, 0, 0, C_SYS_JOYSTICK_90 and mask KS_CHAR>,	;Page up, jstk
	<1, 0, 0, 0, C_SYS_JOYSTICK_270 and mask KS_CHAR>	;Page down, jstk
else

		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
OLPaneVertShortcutList KeyboardShortcut \
		 <1, 0, 0, 0, 0xf, VC_PREVIOUS>,    ; Page up.
		 <1, 0, 0, 0, 0xf, VC_NEXT>,        ; Page down.
		 <1, 0, 0, 0, 0xf, VC_JOYSTICK_90>,  ; Page up, joystick
		 <1, 0, 0, 0, 0xf, VC_JOYSTICK_270>  ; Page down, joystick
endif

;OLPaneVertMethodList	label word
if	PAGE_KEYS_DO_INCREMENTAL_SCROLL
	word	MSG_GEN_VIEW_SCROLL_UP
	word	MSG_GEN_VIEW_SCROLL_DOWN
	word	MSG_GEN_VIEW_SCROLL_UP
	word	MSG_GEN_VIEW_SCROLL_DOWN
else
	word	MSG_GEN_VIEW_SCROLL_PAGE_UP
	word	MSG_GEN_VIEW_SCROLL_PAGE_DOWN
	word	MSG_GEN_VIEW_SCROLL_PAGE_UP
	word	MSG_GEN_VIEW_SCROLL_PAGE_DOWN
endif
	
OLPaneHorizKbdBindings	label	word
	word	length OLPaneHorizShortcutList
if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
OLPaneHorizShortcutList KeyboardShortcut \
	<1, 0, 1, 0, C_SYS_PREVIOUS and mask KS_CHAR>,		;Page left
	<1, 0, 1, 0, C_SYS_NEXT and mask KS_CHAR>,		;Page right
	<1, 0, 0, 0, C_SYS_JOYSTICK_180 and mask KS_CHAR>,	;Page left, jstk
	<1, 0, 0, 0, C_SYS_JOYSTICK_0 and mask KS_CHAR>		;Page right, jstk
else
		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
OLPaneHorizShortcutList KeyboardShortcut \
		 <1, 0, 1, 0, 0xf, VC_PREVIOUS>,     ; Page left.
		 <1, 0, 1, 0, 0xf, VC_NEXT>,         ; Page right.
		 <1, 0, 0, 0, 0xf, VC_JOYSTICK_180>, ; Page left, joystick
		 <1, 0, 0, 0, 0xf, VC_JOYSTICK_0>    ; Page right, joystick
endif

;OLPaneHorizMethodList	label word
if	PAGE_KEYS_DO_INCREMENTAL_SCROLL
	word	MSG_GEN_VIEW_SCROLL_LEFT
	word	MSG_GEN_VIEW_SCROLL_RIGHT
	word	MSG_GEN_VIEW_SCROLL_LEFT
	word	MSG_GEN_VIEW_SCROLL_RIGHT
else
	word	MSG_GEN_VIEW_SCROLL_PAGE_LEFT
	word	MSG_GEN_VIEW_SCROLL_PAGE_RIGHT
	word	MSG_GEN_VIEW_SCROLL_PAGE_LEFT
	word	MSG_GEN_VIEW_SCROLL_PAGE_RIGHT
endif


if _ODIE
OLPaneTextVertKbdBindings	label	word
	word	length OLPaneTextVertShortcutList
if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
OLPaneTextVertShortcutList KeyboardShortcut \
	<1, 0, 0, 0, C_SYS_PREVIOUS and mask KS_CHAR>,		;Page up
	<1, 0, 0, 0, C_SYS_NEXT and mask KS_CHAR>,		;Page down
	<1, 0, 0, 0, C_SYS_JOYSTICK_90 and mask KS_CHAR>,	;Page up, jstk
	<1, 0, 0, 0, C_SYS_JOYSTICK_270 and mask KS_CHAR>,	;Page down, jstk
	<1, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,		;Up arrow
	<1, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>		;Down arrow
else

		 ;P     C  S     C
		 ;h  A  t  h  S  h
		 ;y  l  r  f  e  a
	         ;s  t  l  t  t  r
OLPaneTextVertShortcutList KeyboardShortcut \
		 <1, 0, 0, 0, 0xf, VC_PREVIOUS>,    ; Page up.
		 <1, 0, 0, 0, 0xf, VC_NEXT>,        ; Page down.
		 <1, 0, 0, 0, 0xf, VC_JOYSTICK_90>,  ; Page up, joystick
		 <1, 0, 0, 0, 0xf, VC_JOYSTICK_270>, ; Page down, joystick
		 <1, 0, 0, 0, 0xf, VC_UP>,	    ; Up arrow
		 <1, 0, 0, 0, 0xf, VC_DOWN>         ; Down arrow
endif

;OLPaneTextVertMethodList	label word
if	PAGE_KEYS_DO_INCREMENTAL_SCROLL
	word	MSG_GEN_VIEW_SCROLL_UP
	word	MSG_GEN_VIEW_SCROLL_DOWN
	word	MSG_GEN_VIEW_SCROLL_UP
	word	MSG_GEN_VIEW_SCROLL_DOWN
else
	word	MSG_GEN_VIEW_SCROLL_PAGE_UP
	word	MSG_GEN_VIEW_SCROLL_PAGE_DOWN
	word	MSG_GEN_VIEW_SCROLL_PAGE_UP
	word	MSG_GEN_VIEW_SCROLL_PAGE_DOWN
endif
	word	MSG_GEN_VIEW_SCROLL_UP
	word	MSG_GEN_VIEW_SCROLL_DOWN
endif	; _ODIE

ViewCommon	ends


Resident	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLPaneNavigate - MSG_SPEC_NAVIGATION_QUERY handler
			for OLPaneClass

DESCRIPTION:	This method is used to implement the keyboard navigation
		within-a-window mechanism. See method declaration for full
		details.

CALLED BY:	utility

PASS:		*ds:si	= instance data for object
		cx:dx	= OD of object which originated the navigation method
		bp	= NavigationFlags

RETURN:		ds, si	= same
		cx:dx	= OD of replying object
		bp	= NavigationFlags (in reply)
		carry set if found the next/previous object we were seeking

DESTROYED:	ax, bx, es, di

PSEUDO CODE/STRATEGY:
	OLPaneClass handler:

	NOTE: MORE WORK WILL BE REQUIRED IN THIS AREA TO SUPPORT NAVIGATION
	INTO VIEWS WITH GENERIC CONTENTS. This is just a quick hack to allow
	navigation into views which have been created for text objects.

	if (view for text object) {

	     query text object to see if is focusable
	     call VisNavigateCommon

	     IMPORTANT: when this GenView gains the focus, we immediately
	     pass it on to the text object. See Eric.

	} else {

	     call VisNavigateCommon, passing NOT_FOCUSABLE, NOT_COMPOSITE,
		so this node is skipped.
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version

------------------------------------------------------------------------------@
OLPaneNavigate	method	OLPaneClass, MSG_SPEC_NAVIGATION_QUERY
	clr	bl
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED   	
	jz	10$

	;
	; At least test for GVA_FOCUSABLE.  There probably should be some
	; kind of navigation hint as well.  -cbh 11/23/92
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_FOCUSABLE
	jz	10$

	mov	bl, mask NCF_IS_COMPOSITE or mask NCF_IS_FOCUSABLE
10$:
	mov	di, si			;if this object has generic part,
					;ok to scan it for hints.
	call	VisNavigateCommon
	ret
	
OLPaneNavigate	endm

Resident	ends

;----------------------

KbdNavigation	segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneNavigationComplete -- 
		MSG_SPEC_NOTIFY_NAVIGATION_COMPLETE for OLPaneClass

DESCRIPTION:	Notifies object that they will be the new focus via keyboard
		navigation.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_NAVIGATION_COMPLETE

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	12/10/91	Initial Version

------------------------------------------------------------------------------@

OLPaneNavigationComplete	method dynamic	OLPaneClass, \
				MSG_SPEC_NOTIFY_NAVIGATION_COMPLETE

	and	bp, not (mask NF_REACHED_ROOT or \
			 mask NF_COMPLETED_CIRCUIT)
	mov	ax, MSG_META_CONTENT_NAVIGATION_QUERY
	call	OLPaneSendToApp
	;
	; Mark that the view is taking the focus, but searching for the content
	; a grab the focus.  The content must send a MSG_OL_WIN_FOUND_FOCUSABLE-
	; CONTENT_OBJECT when it actually discovers an object to give the focus
	; to, so that the next time navigation happens, it will work.
	;
;	or	bp, mask NF_QUERY_SENT_TO_CONTENT
exit:
	ret
OLPaneNavigationComplete	endm

KbdNavigation ends

;----------------------------


ViewBuild segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneInitialize --
		MSG_META_INITIALIZE for OLPaneClass

DESCRIPTION:	Initializes a pane.   Neede for converting generic sizes
		to real ones.  

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_INITIALIZE

RETURN:		nothing
		ax, cx, dx, bp -- trashed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/11/89		Initial version

------------------------------------------------------------------------------@

OLPaneInitialize	method OLPaneClass, MSG_META_INITIALIZE
	mov	di, offset OLPaneClass	;call superclass
	call	ObjCallSuperNoLock
	;
	; Mark this as a portal.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance
	ORNF	ds:[di].VI_typeFlags,mask VTF_IS_PORTAL or \
				     mask VTF_CHILDREN_OUTSIDE_PORTAL_WIN

	;
	; Have generic children query us for the correct visual parent.
	;
	ORNF	ds:[di].VI_specAttrs, mask SA_CUSTOM_VIS_PARENT_FOR_CHILD

if DRAW_STYLES
	;
	; default draw style is flat
	;
.assert (DS_FLAT eq 0)
endif
	ret

OLPaneInitialize	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLPaneBroadcastForDefaultFocus --
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS handler.

DESCRIPTION:	This broadcast method is used to find the object within a window
		which has HINT_DEFAULT_FOCUS{_WIN}.

PASS:		*ds:si	= instance data for object

RETURN:		^lcx:dx	= OD of object with hint
		carry set if broadcast handled

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	3/90		initial version

------------------------------------------------------------------------------@

OLPaneBroadcastForDefaultFocus	method	OLPaneClass, \
			MSG_SPEC_BROADCAST_FOR_DEFAULT_FOCUS

	test	ds:[di].OLPI_flags, mask OLPF_MAKE_DEFAULT_FOCUS
	jz	done				;skip if not...

	mov	di, ds:[si]			;not focusable, forget it!
	add	di, ds:[di].Gen_offset		;  (12/ 8/92 cbh)
	test	ds:[di].GVI_attrs, mask GVA_FOCUSABLE
	jz	done

	;
	; Set the default focus in the content, if any.
	;
	mov	ax, MSG_META_CONTENT_APPLY_DEFAULT_FOCUS
	call	OLPaneSendToApp
	
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	clr	bp
done:
	ret
OLPaneBroadcastForDefaultFocus	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	EnsureScrollbars

SYNOPSIS:	Make sure scrollbars exist if needed.  Sets visible bits
		appropriately.

CALLED BY:	BuildScrollbarsIfNeeded

PASS:		*ds:si -- pane handle

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

      	Some serious optimizations could be done here, but it's 6/ 1/90.  `
	You understand.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 1/90		Initial version

------------------------------------------------------------------------------@

EnsureScrollbars	proc	far
if _JEDIMOTIF
	;
	; Do horizontal scrollbar
	;
	clr	bx				; make horizontal bar
	mov	ax, HORIZONTAL_VIEW_BASE_MESSAGE	; base method
	call	SetupScrollbarIfNeeded
	;
	; Instantiate a vertical scrollbar, if needed
	;
	mov	bx, SSIN_VERTICAL		; make vertical bar
	mov	ax, VERTICAL_VIEW_BASE_MESSAGE	; base method
	call	SetupScrollbarIfNeeded
else
	;
	; Instantiate a vertical scrollbar, if needed
	;
	mov	bx, SSIN_VERTICAL		; make vertical bar
	mov	ax, VERTICAL_VIEW_BASE_MESSAGE	; base method
	call	SetupScrollbarIfNeeded
	;
	; Do horizontal scrollbar
	;
	clr	bx				; make horizontal bar
	mov	ax, HORIZONTAL_VIEW_BASE_MESSAGE	; base method
	call	SetupScrollbarIfNeeded
endif

if FLOATING_SCROLLERS
	call	EnsureFloatingScrollers
endif
	ret
EnsureScrollbars	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupScrollbarIfNeeded

SYNOPSIS:	Does appropriate things based on the view bits.  If we need
		a scrollbar, and there isn't one, we create it.  If there 
		already is one, we set the visible bits appropriately.

CALLED BY:	EnsureScrollbars

PASS:		*ds:si -- view
		bx     -- 0 if doing horizontal scrollbar
			  SSIN_VERTICAL if doing vertical scrollbar
		ax     -- method to give to scrollbar

RETURN:		nothing

DESTROYED:	di, ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/25/91		Initial version
	Jim	7/30/91		Changed GVI_origin to PointDWFixed

------------------------------------------------------------------------------@

SSIN_VERTICAL	=	1

CheckHack <(offset GVI_vertAttrs - offset GVI_horizAttrs) eq SSIN_VERTICAL>
CheckHack <(offset OLPI_vertScrollbar - offset OLPI_horizScrollbar) \
		eq (SSIN_VERTICAL * 2)>
CheckHack <(offset RD_top - offset RD_left) eq (SSIN_VERTICAL * 4)>
CheckHack <(offset PD_y - offset PD_x) eq (SSIN_VERTICAL * 4)>
CheckHack <(offset PD_y - offset PD_x) eq (SSIN_VERTICAL * 4)>
	
SetupScrollbarIfNeeded	proc	near
EC <	cmp	bx, SSIN_VERTICAL					>
EC <	ERROR_A	OL_VIEW_BAD_FLAGS_PASSED_TO_SCROLLBAR_SETUP		>
   
   	push	si
   	;
	; First, if there is a scrollbar currently, let's assume it shouldn't
	; be visible.  
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	di, bx				;get to correct scrollbar
	add	di, bx
	mov	di, ds:[di].OLPI_horizScrollbar
	tst	di
	jz	5$
EC <	xchg	si, di							>
EC <	call	CheckScrollbarAssumption				>
EC <	call	VisCheckVisAssumption					>
EC <	xchg	si, di							>
	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset
	and	ds:[di].VI_attrs, not (mask VA_DRAWABLE or mask VA_DETECTABLE \
				   or mask VA_MANAGED)
5$:
	call	CheckIfLeavingSpace
	jnz	needScrollbar				;leaving room, do
							;  scrollbar
	;	
	; See if we're supposed to have a scrollbar.
	;
	mov	di, ds:[si]				; deference
	add	di, ds:[di].Gen_offset		
	test	ds:[di].GVI_horizAttrs[bx], mask GVDA_DONT_DISPLAY_SCROLLBAR
	LONG	jnz	exit				; not displaying one
	test	ds:[di].GVI_horizAttrs[bx], mask GVDA_SCROLLABLE    
	LONG	jz	exit				; not scrollable, skip

needScrollbar:
	;
	; We need a scrollbar.  If it exists, make it visible; otherwise, 
	; create a new one.
	;
	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di


	shl	bx, 1					; now offset to words
	push	bx
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLPI_horizScrollbar[bx]	; put bar handle in cx
	
	shl	bx, 1					; now offset to dwords
	
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	add	di, bx					; add into di
	mov	dx, bx					; save passed offset
	tst	bl					; see if vertical
	mov	bx, HINT_VALUE_X_SCROLLER		; assume not
	jz	10$
	mov	bx, HINT_VALUE_Y_SCROLLER		; else try horiz
10$:
	push	bx					; pass orient on stack
	push	ax					; pass action method
	push	ds:[di].GVI_docBounds.RD_left.high	; high word of minimum
	push	ds:[di].GVI_docBounds.RD_left.low	; low word of minimum
	push	ds:[di].GVI_docBounds.RD_right.high	; high word of maximum
	push	ds:[di].GVI_docBounds.RD_right.low	; low word of maximum
	tst	dx					; if this non-zero,
	jnz	doingVertical				;  then we have work
	push	ds:[di].GVI_origin.PDF_x.DWF_int.high	; high initial value
	push	ds:[di].GVI_origin.PDF_x.DWF_int.low	; high initial value
afterOrigin:
	push	ds:[di].GVI_increment.PD_x.high		; high word increment
	push	ds:[di].GVI_increment.PD_x.low		; low word increment
	
	jcxz	checkImmediateDragUpdates		; => no scrollbar yet,
							;   go create one
	mov	dx, si					; pass view in dx
	mov	si, cx					; pass scrollbar in si
EC <	call	VisCheckVisAssumption					>
EC <	call	CheckScrollbarAssumption				>
	clr	bx					; not creating!
	call	OpenSetScrollbarAttrs			; just set attributes
	pop	bx					; restore vertical flag
	jmp	short checkOrientation			; and continue
		
	; we needed this to deal with GVI_origin changing from PointDWord to
	; PointDWFixed.  The offsets no longer matched up with SSIN_VERTICAL.
	; (Fixed to preserve di -- cbh 7/14/92)
doingVertical:
	add	di, (offset PDF_y - offset PDF_x + offset PD_y - offset PD_x)
	push	ds:[di].GVI_origin.PDF_x.DWF_int.high	; high initial value
	push	ds:[di].GVI_origin.PDF_x.DWF_int.low	; high initial value
	sub	di, (offset PDF_y - offset PDF_x + offset PD_y - offset PD_x)
	jmp	afterOrigin

checkImmediateDragUpdates:
	;	
	; See if we need immediate updates on drag, set ah appropriately.
	;
	mov	ax, HINT_VIEW_IMMEDIATE_DRAG_UPDATES
	call	ObjVarFindData				; see if data exists
	mov	ax, 0ffh				; put in generic tree
	jnc	addIt
	dec	ah					
addIt:
	call	OpenAddScrollbar			; add a scrollbar
	
	;
	; Pass our ignore-dirty flag on to our scrollbar if needed, to fix
	; bug where dynamic lists create an ignore-dirty view, but not the
	; scrollbar gets saved to state.  -cbh 5/ 6/93
	;
	mov	ax, si
	call	ObjGetFlags				; al <- ObjChunkFlags
	and	al, mask OCF_IGNORE_DIRTY
	jz	noIgnoreDirty				

	clr	bx
	mov	bl, al
	mov	ax, dx
	call	ObjSetFlags				; ignore-dirty,set child
noIgnoreDirty:

	pop	bx					; restore vertical flag
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLPI_horizScrollbar[bx], dx     ; store handle in view
	
checkOrientation:
	pop	di
	call	ThreadReturnStackSpace

	;
	; Set not drawable or detectable if the appropriate LEAVE_ROOM hint
	; is set on the view.  -cbh 11/ 4/92
	;
	pop	si					; get view handle,
	push	si, dx					;   save again

if FLOATING_SCROLLERS
	mov	si, dx					; we never want the
	mov	si, ds:[si]				; scrollbar to appear
	add	si, ds:[si].Vis_offset
	and	ds:[si].VI_attrs, not (mask VA_DRAWABLE or mask VA_DETECTABLE \
				   or mask VA_MANAGED)
else	
	call	CheckIfLeavingSpace			; not leaving space,
	jz	8$					;   branch
	mov	si, dx					; scrollbar handle
	mov	cx, (mask VA_DRAWABLE or mask VA_DETECTABLE) shl 8
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_SET_ATTRS			; clear managed, detct
	call	ObjCallInstanceNoLock
8$:
endif	; FLOATING_SCROLLERS

	pop	si, dx
	push	si
	;
	; Set orientation properly.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].OLPI_horizScrArea[bx]	; get area being used
	sub	ax, offset OLPI_leftObj			; check if vertical
	test	ax, offset OLPI_topObj - offset OLPI_leftObj
	mov	cl, 0					; assume horizontal
	jnz	20$					; top or bottom area,jmp
	dec	cl			                ; else vertical
20$:
	mov	si, dx					; *ds:si <- scrollbar
	mov	ax, MSG_SET_ORIENTATION
	call	ObjCallInstanceNoLock			; set orientation

exit:
	pop	si
	ret
SetupScrollbarIfNeeded	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfLeavingSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're leaving room for scroller.

CALLED BY:	SetupScrollbarIfNeeded

PASS:		bx -- non-zero if vertically oriented
		*ds:si -- view

RETURN:		zero flag clear if leaving space

DESTROYED:	 cl, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfLeavingSpace	proc	near

	mov	cl, mask OLPF_LEAVE_ROOM_FOR_VERT_SCROLLER
	tst	bx					; vertical?
	jnz	7$
	mov	cl, mask OLPF_LEAVE_ROOM_FOR_HORIZ_SCROLLER
7$:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_flags, cl

	ret
CheckIfLeavingSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureFloatingScrollers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure floating scrollers

CALLED BY:	EnsureScrollbars
PASS:		*ds:si	= OLPaneClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

EnsureFloatingScrollers	proc	far
	uses	bx, bp, es
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bp, ds:[di].OLPI_vertScrollbar
	tst	bp
	jz	checkHoriz

	mov	bx, offset OLPI_upScroller
	mov	cx, offset UpArrowWindowRegion
	mov	dx, offset UpArrowBitmap
	mov	ax, offset UpSelectedArrowBitmap
	call	instantiateScroller

	mov	bx, offset OLPI_downScroller
	mov	cx, offset DownArrowWindowRegion
	mov	dx, offset DownArrowBitmap
	mov	ax, offset DownSelectedArrowBitmap
	call	instantiateScroller

checkHoriz:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bp, ds:[di].OLPI_horizScrollbar
	tst	bp
	jz	done

	mov	bx, offset OLPI_leftScroller
	mov	cx, offset LeftArrowWindowRegion
	mov	dx, offset LeftArrowBitmap
	mov	ax, offset LeftSelectedArrowBitmap
	call	instantiateScroller

	mov	bx, offset OLPI_rightScroller
	mov	cx, offset RightArrowWindowRegion
	mov	dx, offset RightArrowBitmap
	mov	ax, offset RightSelectedArrowBitmap
	call	instantiateScroller
done:
	mov	cx, -1			; close and reopen the scrollers
	call	OLPaneUpdateFloatingScrollers

	.leave
	ret

instantiateScroller:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = OLPaneInstanceData
	tst	{word}ds:[di][bx]	; check if scroller already exists
	jnz	instantiated

	push	bx, si
	segmov	es, <segment FloatingScrollerClass>, di
	mov	di, offset FloatingScrollerClass
	mov	bx, ds:[LMBH_handle]
	call	GenInstantiateIgnoreDirty
	mov	di, ds:[si]
	mov	ds:[di].FSI_scrollbar, bp
	mov	ds:[di].FSI_windowRegion, cx
	mov	ds:[di].FSI_bitmap, dx
	mov	ds:[di].FSI_selectedBitmap, ax
	mov	ax, si
	pop	bx, si

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = OLPaneInstanceData
	mov	ds:[di][bx], ax		; save scroller chunk handle
instantiated:
	retn

EnsureFloatingScrollers	endp

endif	; FLOATING_SCROLLERS


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetMonikerOffset -- 
		MSG_OL_CTRL_SET_MONIKER_OFFSET for OLPaneClass

DESCRIPTION:	Manually sets a moniker offset based on the first child's 
		position.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_OL_CTRL_SET_MONIKER_OFFSET
		cx	- x offset
		dx	- y offset

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	11/15/92        Initial Version

------------------------------------------------------------------------------@

OLPaneSetMonikerOffset	method dynamic	OLPaneClass, \
				MSG_SPEC_CTRL_SET_MONIKER_OFFSET
	;
	; When calculating the moniker offset for a view, it's generally
	; coming from the content so well build in the offset to the window
	; origin.  Or whatever.
	;
	push	cx, dx, es
	call	GetWinLeftTop
	call	GetFrameWidth
	add	cx, ax
	add	dx, ax
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	sub	cx, ds:[di].VI_bounds.R_left
	sub	dx, ds:[di].VI_bounds.R_top
	pop	ax, bx, es
	add	cx, ax
	add	dx, bx

	mov	ax, MSG_SPEC_CTRL_SET_MONIKER_OFFSET
	mov	di, offset OLPaneClass
	GOTO	ObjCallSuperNoLock

OLPaneSetMonikerOffset	endm


ViewBuild ends

;--------------------
	
ViewCommon segment resource
		 


COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckScrollbarAssumption

SYNOPSIS:	Error checking to make we got a scrollbar here.

CALLED BY: 	utility

PASS:		*ds:si -- object to check

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/16/91		Initial version

------------------------------------------------------------------------------@
	
if	ERROR_CHECK
CheckScrollbarAssumption	proc	far
	uses es, di
	.enter

	mov	di, segment GenValueClass
	mov	es, di
	mov	di, offset GenValueClass
	call	ObjIsObjectInClass
	ERROR_NC	OL_VIEW_SCROLLER_HAS_BEEN_DESTROYED
	
	push	bx
	push	si
	call	GenFindParent
	tst	bx
	ERROR_Z	OL_VIEW_SCROLLER_IS_NOT_IN_GEN_TREE
	pop	si
	pop	bx
	
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE	
	ERROR_Z	OL_VIEW_SCROLLER_CANNOT_BE_MADE_NOT_USABLE
	.leave
	ret
CheckScrollbarAssumption	endp
endif	; ERROR_CHECK



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneTargetChange

DESCRIPTION:	Handle notification from content that there is a new target
		object within the content.  Data is for later use in
		MSG_META_GET_TARGET_AT_TARGET_LEVEL handler.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_GEN_VIEW_UPDATE_CONTENT_TARGET_INFO

	ss:[bp]	- pointer to ViewTargetInfo

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@
OLPaneTargetChange	method OLPaneClass, \
				MSG_GEN_VIEW_UPDATE_CONTENT_TARGET_INFO
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
				; Copy data from stack frame into instance
				; ss:[bp] is source
				; setup ds:di is destination
	add	di, offset OLPI_targetInfo
	mov	cx, size ViewTargetInfo
copyLoop:
	mov	al, ss:[bp]	; copy from stack frame
	mov	ds:[di], al	; to instance data
	inc	bp		; inc pointers 
	inc	di
	loop	copyLoop	; & loop (currently 16 bytes)
	ret
OLPaneTargetChange	endm

ViewCommon	ends

;------------------------------

InstanceObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGetFocusTarget

DESCRIPTION:	Returns the current focus/target below this point in hierarchy

PASS:		*ds:si 	- instance data
		ds:di	- SpecInstance
		es     	- segment of class
		ax 	- MSG_GEN_GET_[FOCUS/TARGET]
		
RETURN:		^lcx:dx - handle of object with focus/target
		carry	- set because msg has been responded to
		ax, bp	- destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/25/91		Initial version

------------------------------------------------------------------------------@
OLPaneGetFocusTarget 	method dynamic OLPaneClass, MSG_META_GET_FOCUS_EXCL,
					    MSG_META_GET_TARGET_EXCL
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GVI_content.handle
	mov	dx, ds:[di].GVI_content.chunk 
	stc
	Destroy	ax, bp
	ret
OLPaneGetFocusTarget	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGetTargetAtTargetLevel

DESCRIPTION:	Returns current target object within this branch of the
		hierarchical target exclusive, at level requested

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass

	ax - MSG_META_GET_TARGET_AT_TARGET_LEVEL

	cx	- TargetLevel

RETURN:
	cx:dx	- OD of target at level requested (0 if none)
	ax:bp	- Class of target object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@
OLPaneGetTargetAtTargetLevel	method	OLPaneClass, \
				MSG_META_GET_TARGET_AT_TARGET_LEVEL
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	cmp	cx, TL_GEN_VIEW		; looking for view?
	je	view
	cmp	cx, TL_CONTENT		; looking for content?
	je	content
	cmp	cx, TL_TARGET		; looking for target?
	je	target

returnNull:
	clr	ax, dx, cx, bp
	ret

view:
	mov	cx, ds:[LMBH_handle]	; return THIS View object
	mov	dx, si
	mov	di, ds:[si]			; & object's Class
	mov	ax, ds:[di].MB_class.segment
	mov	bp, ds:[di].MB_class.offset
	ret

content:
					; return content object as last
					; reported
	mov	cx, ds:[di].OLPI_targetInfo.VTI_content.TR_object.handle
	mov	dx, ds:[di].OLPI_targetInfo.VTI_content.TR_object.chunk
	mov	ax, ds:[di].OLPI_targetInfo.VTI_content.TR_class.segment
	mov	bp, ds:[di].OLPI_targetInfo.VTI_content.TR_class.offset

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	cmp	cx, ds:[di].GVI_content.handle	;If target content matches
	jne	returnNull			; current generic content, OK
	cmp	dx, ds:[di].GVI_content.chunk 
	jne	returnNull
	ret

target:
					; return last target of content
					; as reported by content
	mov	cx, ds:[di].OLPI_targetInfo.VTI_target.TR_object.handle
	mov	dx, ds:[di].OLPI_targetInfo.VTI_target.TR_object.chunk
	mov	ax, ds:[di].OLPI_targetInfo.VTI_target.TR_class.segment
	mov	bp, ds:[di].OLPI_targetInfo.VTI_target.TR_class.offset
	ret

OLPaneGetTargetAtTargetLevel	endm

InstanceObscure	ends


ViewCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSendClassedEvent

DESCRIPTION:	Sends message to target object at level requested.
		Focus, & Target requests are
		all sent on to the content.  If other behavior is desired,
		this message should be intercepted in a subclass & 
		implemented differently.

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass

	ax - MSG_META_SEND_CLASSED_EVENT

	cx	- handle of classed event
	dx	- TargetObject

RETURN:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/91		Initial version

------------------------------------------------------------------------------@

OLPaneSendClassedEvent	method	OLPaneClass, \
					MSG_META_SEND_CLASSED_EVENT

	cmp	dx, TO_FOCUS
	je	sendToContent
	cmp	dx, TO_TARGET
	je	sendToContent

	mov	di, offset OLPaneClass
	GOTO	ObjCallSuperNoLock

sendToContent:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GVI_content.handle
	mov	bp, ds:[di].GVI_content.chunk 
	clr	di
	call	FlowDispatchSendOnOrDestroyClassedEvent
	ret

OLPaneSendClassedEvent	endm


ViewCommon ends

;----------------------
	
ViewBuild segment resource
		 


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneVisClose
		MSG_VIS_CLOSE for OLPaneClass

DESCRIPTION:	Visibly CLOSE the pane & contents

PASS:		*ds:si 	- instance data
		es     	- segment of OLPaneClass
		ax 	- MSG_VIS_CLOSE
		bp	- 0 if top win group, -1 if not

RETURN:		nothing
		ax, cx, dx, bp -- trashed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version

------------------------------------------------------------------------------@
OLPaneVisClose	method OLPaneClass, MSG_VIS_CLOSE
	push	bp

					; Notify content that view is closing
	mov	ax, MSG_META_CONTENT_VIEW_CLOSING
	call	OLPaneSendToApp

	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL	
	call	VisCallParentWithSelf

if FLOATING_SCROLLERS
	call	OLPaneCloseFloatingScrollers
endif
	pop	bp
	mov	di, offset OLPaneClass	;do superclass method
	mov	ax, MSG_VIS_CLOSE
	GOTO	ObjCallSuperNoLock

OLPaneVisClose	endm

ViewBuild ends

;---------------------

ViewCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPaneChange -- 
		MSG_SPEC_CHANGE for OLPaneClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Comes from a "change" being pressed in Rudy.

PASS:		*ds:si 	- instance data
		es     	- segment of OLPaneClass
		ax 	- MSG_SPEC_CHANGE

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	5/18/95         Initial Version
	chris	9/ 1/95 	Expanding to cover all sorts of stuff.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _RUDY
 method OLPaneChange, OLPaneClass, MSG_SPEC_CHANGE
 method OLPaneChange, OLPaneClass, MSG_SPEC_POPUP_LIST_APPLY
 method OLPaneChange, OLPaneClass, MSG_SPEC_POPUP_LIST_CANCEL

; Added these 9/1/95; these should be in all products.
;method OLPaneChange, OLPaneClass, MSG_GEN_APPLY
 method OLPaneChange, OLPaneClass, MSG_GEN_RESET
 method OLPaneChange, OLPaneClass, MSG_GEN_PRE_APPLY
 method OLPaneChange, OLPaneClass, MSG_GEN_POST_APPLY
endif

if _RUDY

OLPaneChange	method dynamic	OLPaneClass, MSG_GEN_APPLY
	;
	; Check to make sure generic contents bit is set.   (9/ 1/95 cbh)
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_GENERIC_CONTENTS
	je	exit			;not doing generic contents, do nothing

	;
	; Hopefully force-queuing will be OK.  Sure, this message doesn't
	; return anything.   Avoids problems with contents in another
	; thread.   (Changed to send-to-app-now to fix cancel problem, 
	; 8/30/95 cbh
	;
	.enter
	call	OLPaneSendToAppNow
exit:
	.leave
	ret
OLPaneChange	endm

endif




COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGainedTargetExcl
METHOD:		OLPaneLostTargetExcl
METHOD:		OLPaneGainedFocusExcl
METHOD:		OLPaneLostFocusExcl
METHOD:		OLPaneGainedSysTargetExcl
METHOD:		OLPaneLostSysTargetExcl
METHOD:		OLPaneGainedSysFocusExcl
METHOD:		OLPaneLostSysFocusExcl
METHOD:		OLPaneSetFlagAndSendToApp

DESCRIPTION:	Sends method passed on to OD of view.  In case of focus/target
		gain/lost, set/reset flag in local instance data so that
		we will have a record of whether we have the focus/target
		or not, which is needed in SET_CONTENT.

PASS:
	*ds:si - instance data of view
	es - segment of GenViewClass

	ax - method being sent
	cx - data
	dx - data
	bp - data

RETURN:
	ax, cx, dx, bp

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

OLPaneLostAppTargetExcl	method OLPaneClass, MSG_META_LOST_TARGET_EXCL
	mov	bx, mask OLPA_APP_TARGET shl 8	; clear target flag
	call	OLPaneSetFlagAndSendToApp
	mov	cx, 1
	call	SendNotifyLow
	ret
OLPaneLostAppTargetExcl	endm

OLPaneGainedAppTargetExcl method OLPaneClass, MSG_META_GAINED_TARGET_EXCL
	mov	bx, mask OLPA_APP_TARGET	; set target flag
	call	OLPaneSetFlagAndSendToApp
	call	SendNotifyCommon
	ret
OLPaneGainedAppTargetExcl	endm


OLPaneLostSysTargetExcl	method OLPaneClass, MSG_META_LOST_SYS_TARGET_EXCL
	mov	bx, mask OLPA_SYS_TARGET shl 8	; clear target flag
	GOTO	OLPaneSetFlagAndSendToApp
OLPaneLostSysTargetExcl	endm

OLPaneGainedSysTargetExcl method OLPaneClass, MSG_META_GAINED_SYS_TARGET_EXCL
	mov	bx, mask OLPA_SYS_TARGET	; set target flag
	GOTO	OLPaneSetFlagAndSendToApp
OLPaneGainedSysTargetExcl	endm


OLPaneGainedAppFocusExcl method	OLPaneClass, MSG_META_GAINED_FOCUS_EXCL
	mov	bx, mask OLPA_APP_FOCUS		; set focus flag
	call	OLPaneSetFlagAndSendToApp

	; Since we have the focus exclusive within the app, & are the leaf focus
	; object before the next keyboard exclusive node, we can grab the
	; keyboard exclusive.  This speeds up the transmission of KBD_CHAR
	; events, as they'll come directly to us instead of trickling down
	; from the Application object.
	;
	call	VisForceGrabKbd
	ret
OLPaneGainedAppFocusExcl	endm

OLPaneLostAppFocusExcl method OLPaneClass, MSG_META_LOST_FOCUS_EXCL

	; As we're no longer have the focus, we must relinquish our
	; stranglehold on the keyboard grab.
	;
	call	VisReleaseKbd

	mov	bx, mask OLPA_APP_FOCUS shl 8	; clear focus flag
	GOTO	OLPaneSetFlagAndSendToApp
OLPaneLostAppFocusExcl	endm

OLPaneGainedSysFocusExcl method	OLPaneClass, MSG_META_GAINED_SYS_FOCUS_EXCL
if _ODIE
	;
	; if scrolling text, grab focus for it
	; use MetaGrabFocusExclLow to bypass OLText handler for
	; MSG_META_GRAB_FOCUS_EXCL which checks if we are in a view and
	; grabs focus for the view if so
	;
	push	ax
	mov	ax, ATTR_OL_PANE_SCROLLING_TEXT
	call	ObjVarFindData
	jnc	notText
	push	si
	mov	si, ds:[bx]			; *ds:si = scrolling text
	call	MetaGrabFocusExclLow
	pop	si
notText:
	pop	ax
endif
	mov	bx, mask OLPA_SYS_FOCUS		; set focus flag
	GOTO	OLPaneSetFlagAndSendToApp
OLPaneGainedSysFocusExcl	endm

OLPaneLostSysFocusExcl method OLPaneClass, MSG_META_LOST_SYS_FOCUS_EXCL
	mov	bx, mask OLPA_SYS_FOCUS shl 8	; clear focus flag
	FALL_THRU	OLPaneSetFlagAndSendToApp
OLPaneLostSysFocusExcl	endm



OLPaneSetFlagAndSendToApp	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

EC <	test	ds:[di].OLPI_attrs, bl					>
EC <	ERROR_NZ	OL_VIEW_ALREADY_HAS_EXLUSIVE			>

	or	ds:[di].OLPI_attrs, bl		; set flag

EC <	tst	bh	; skip test if not clearing flag		>
EC <	jz	ok							>
EC <	test	ds:[di].OLPI_attrs, bh					>
EC <	ERROR_Z		OL_VIEW_DOES_NOT_HAVE_EXLUSIVE			>
EC <ok:									>

	not	bh				; get AND mask
	and	ds:[di].OLPI_attrs, bh		; clear flag

	FALL_THRU	OLPaneSendToAppNow
OLPaneSetFlagAndSendToApp	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLPaneSendToApp

DESCRIPTION:	Send method & data passed on to the output OD

CALLED BY:	INTERNAL

PASS:
	*ds:si	- GenViewClass object
	ax 	- method to send on
	cx, dx, bp	- data

RETURN:
	ax	- clear (in OLPaneSendToApp)
	cx, dx  - possible return args (in OLPaneCallApp)

DESTROYED:	anything not returned, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/90		Initial version
------------------------------------------------------------------------------@
OLPaneSendToAppNow	proc	far
	mov	di, mask MF_FIXUP_DS
	call	ToAppCommon
	clr	ax			; in case flags expected
	ret
OLPaneSendToAppNow	endp

ViewCommon ends

;-------------------

Resident segment resource			
			
OLPaneSendToApp	proc	far
	mov	di, mask MF_FORCE_QUEUE
	call	ToAppCommon
	clr	ax			; in case flags expected
	ret

OLPaneSendToApp	endp

OLPaneCallApp	proc	far
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	FALL_THRU	ToAppCommon

OLPaneCallApp	endp

;------

ToAppCommon	proc	far
	push	si
	push	bx
EC <	push	di							>
EC <	mov	di, si						 	>
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset	; get ptr to SpecificInstance
	mov	bx, ds:[si].GVI_content.handle
	mov	si, ds:[si].GVI_content.chunk

	; Make sure that the method we're passing belongs to MetaClass	
	; if we don't have a generic content.	(Changed 12/27/92 cbh to
	; allow messages through if GVA_VIEW_FOLLOWS_CONTENT_SIZE is set.)

EC <	mov	di, ds:[di]						>
EC <	add	di, ds:[di].Gen_offset					>
EC <    test	ds:[di].GVI_attrs, mask GVA_GENERIC_CONTENTS or	\
			           mask GVA_VIEW_FOLLOWS_CONTENT_GEOMETRY  >
EC <	jnz	EC10							>
EC <	cmp	ax, first FlowMessages					>
EC <	ERROR_AE	OL_VIEW_MUST_PASS_A_META_MSG_TO_NON_GEN_CONTENT >
EC <EC10:								>

	; Don't allow contents run by a different thread if GVA_GENERIC_CONTENTS
	; is set.   Or GVA_VIEW_FOLLOWS_CONTENT_GEOMETRY.  -cbh 3/30/93

EC <    test	ds:[di].GVI_attrs, mask GVA_GENERIC_CONTENTS or	\
				   mask GVA_VIEW_FOLLOWS_CONTENT_GEOMETRY >
EC <	jz	EC20							  >
EC <	call	ObjTestIfObjBlockRunByCurThread			 	  >
EC <	ERROR_NE	OL_VIEW_GENERIC_CONTENTS_MUST_BE_IN_SAME_THREAD   >
EC <EC20:								  >
EC <	pop	di							>

	call	ObjMessage
	pop	bx
	pop	si
	ret

ToAppCommon	endp

SendNotifyCommon	proc	far	uses cx
	.enter
	clr	cx
	call	SendNotifyLow
	.leave
	ret
SendNotifyCommon	endp

;---

SendNotifyLow	proc	far	uses ax, dx, bp
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_CONTROLLED
	jz	done
	mov	ax, MSG_GEN_VIEW_SEND_NOTIFICATION
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
SendNotifyLow	endp

Resident ends

;---------------------

ViewCommon segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLPanePrePassiveButton -- MSG_META_PRE_PASSIVE_BUTTON

DESCRIPTION:	Handler for Passive Button events (see CTTFM description,
		top of cwinClass.asm file.)

	(We know that REFM mechanism does not rely on this procedure, because
	REFM does not request a pre-passive grab.)

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass

	ax	- method
	cx, dx	- ptr position
	bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:
	Nothing

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	1/90		Initial version

------------------------------------------------------------------------------@
	
; Hopefully unecessary now.  Window keeps pre-passive and releases focus.
; -cbh 10/22/90
if	0
OLPanePrePassiveButton	method 	OLPaneClass, MSG_META_PRE_PASSIVE_BUTTON
	push	ax, cx, dx, bp, es

	;first exit menu navigation, if it is in progress. This will
	;restore the focus back to the display control, if it had the focus
	;before menu navigation began.

	push	bp
	mov	ax, MSG_VIS_VUP_RELEASE_MENU_FOCUS
	call	VisCallParent		;if menu has focus, release it
	pop	bp
	call	VisRemoveButtonPrePassive	;turn off CTTFM mechanism
	pop	ax, cx, dx, bp, es
	
	mov	di, offset OLPaneClass
	call	ObjCallSuperNoLock
	ret
OLPanePrePassiveButton	endm
endif



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetIncrement --
		MSG_GEN_VIEW_SET_INCREMENT for OLPaneClass

DESCRIPTION:	Sets the increment amount.  Generic handler has already 
		stored the increment.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_INCREMENT
		bx:ax	- x increment amount (or zero if no change desired)
		dx:cx	- y increment amount (ditto)

RETURN:		nothing
		ax, cx, dx, bp -- trashed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/12/89		Initial version

------------------------------------------------------------------------------@

OLPaneSetIncrement	method OLPaneClass, MSG_GEN_VIEW_SET_INCREMENT
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	cx, ds:[di].GVI_increment.PD_y.low
	mov	dx, ds:[di].GVI_increment.PD_y.high
	mov	bx, ds:[di].GVI_increment.PD_x.low
	mov	di, ds:[di].GVI_increment.PD_x.high
	mov	ax, MSG_GEN_VALUE_SET_INCREMENT	
	call	OLPaneCallScrollbarsIfNonZeroArg	;send to scrollbars
	ret
OLPaneSetIncrement	endm


COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPaneFinishSetDocSize

SYNOPSIS:	Finishes the job of setting the document size.

CALLED BY:	OLPaneSetDocSize, OLPaneNormalizeComplete

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	something

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/25/90		Initial version

------------------------------------------------------------------------------@

OLPaneFinishSetDocSize	proc	far
	;
	; Now send the method on to the scrollbars.
	; 
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	bx, ds:[di].GVI_docBounds.RD_left.high
	mov	dx, ds:[di].GVI_docBounds.RD_top.high
	mov	cx, ds:[di].GVI_docBounds.RD_top.low
	mov	di, ds:[di].GVI_docBounds.RD_left.low
	mov	ax, MSG_GEN_VALUE_SET_MINIMUM	;send on to scrollbars
	call	OLPaneCallScrollbarsWithDWords
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	bx, ds:[di].GVI_docBounds.RD_right.high
	mov	dx, ds:[di].GVI_docBounds.RD_bottom.high
	mov	cx, ds:[di].GVI_docBounds.RD_bottom.low
	mov	di, ds:[di].GVI_docBounds.RD_right.low
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM	;send on to scrollbars
	call	OLPaneCallScrollbarsWithDWords

	;
	; Mark the PARENT's geometry as invalid.  If the parent has extra space
	; that it can dole out to the kids, it will.
	;
	call	VisCheckIfSpecBuilt		;see if vis built yet
	jnc	exit				;no, branch
	call	FullyInvalidateView
exit:
	call	SendNotifyCommon
	ret
OLPaneFinishSetDocSize	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPaneCallScrollbars
		
SYNOPSIS:	Sends method on to scrollbars.  The appropriate argument is
		passed to the scrollbar in cx.

CALLED BY:	RepeatSelectScroll

PASS:		*ds:si 	- pane instance data
		ax 	- method
		cx	- argument to pass to horizontal scrollbar
		dx	- argument to pass to vertical scrollbar

RETURN:		ax, cx, dx, bp - return values of method being called...

DESTROYED:	bx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/89		Initial version

------------------------------------------------------------------------------@

OLPaneCallScrollbars	proc	far
	call	CallHorizScrollbar		;first call horizontal
	mov	cx, dx				;now pass arg in cx
	call	CallVertScrollbar		;and call vertical
	ret
OLPaneCallScrollbars	endp

			

COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPaneCallScrollbarsIfNonZeroArg
		
SYNOPSIS:	Sends method on to scrollbars.  Only sends to a scrollbar
		if the arguments to be passed to the scrollbar are non-zero.
		The appropriate arguments are passed to the scrollbar in dx:cx.

CALLED BY:	RepeatSelectScroll

PASS:		*ds:si 	- pane instance data
		ax 	- method
		bx:di   - arguments to pass to horizontal scrollbar
		dx:cx	- arguments to pass to vertical scrollbar

RETURN:		nothing

DESTROYED:	bx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/89		Initial version

------------------------------------------------------------------------------@

OLPaneCallScrollbarsIfNonZeroArg	proc	far		;uses dwords
	tst	cx
	jnz	callVert
	tst	dx
	jz	tryHoriz
callVert:
	push	di
	push	bx
	call	CallVertScrollbar
	pop	bx
	pop	cx
tryHoriz:
	mov	dx, bx
	tst	cx
	jnz	callHoriz
	tst	dx
	jz	exit
callHoriz:
	call	CallHorizScrollbar		
exit:
	ret
OLPaneCallScrollbarsIfNonZeroArg	endp
			
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPaneCallScrollbarsWithDWords
		
SYNOPSIS:	Sends method on to scrollbars.  The appropriate arguments
		are passed to the scrollbar in dx:cx.

CALLED BY:	RepeatSelectScroll

PASS:		*ds:si 	- pane instance data
		ax 	- method
		bx:di	- arguments to pass to horizontal scrollbar
		dx:cx	- arguments to pass to vertical scrollbar

RETURN:		nothing

DESTROYED:	bx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/89		Initial version

------------------------------------------------------------------------------@

OLPaneCallScrollbarsWithDWords	proc	far
	push	di
	push	bx
	call	CallVertScrollbar
	pop	bx
	pop	cx				;setup cx and dx for horiz
	mov	dx, bx
	FALL_THRU	CallHorizScrollbar		
OLPaneCallScrollbarsWithDWords	endp

			
			
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	CallVertScrollbar, CallHorizScrollbar
		
SYNOPSIS:	Sends method on to scrollbars.

CALLED BY:	RepeatSelectScroll

PASS:		*ds:si 	- pane instance data
		ax 	- method
		cx, dx	- any arguments to pass
		
RETURN:		nothing

DESTROYED:	bx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/89		Initial version

------------------------------------------------------------------------------@

CallHorizScrollbar	proc	far
	clr	bx	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	CallScrollbar
CallHorizScrollbar	endp
			

CallVertScrollbar	proc	far
	mov	bx, CS_VERTICAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	FALL_THRU 	CallScrollbar
CallVertScrollbar	endp
			
			

COMMENT @----------------------------------------------------------------------

ROUTINE:	CallScrollbar
		
SYNOPSIS:	Sends method on to a scrollbar.  Could be the vertical or
		horizontal scrollbar for the pane.

CALLED BY:	RepeatSelectScroll

PASS:		*ds:si 	- pane instance data
		ax 	- method
		cx, dx  - possible arguments to pass
		bx	- 0 if we're to call the horizontal scrollbar, 
			  CS_VERTICAL if vertical.
		di	- MessageFlags

RETURN:		nothing

DESTROYED:	bx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/89		Initial version

------------------------------------------------------------------------------@
CS_VERTICAL	equ	2
		
CheckHack <(offset OLPI_vertScrollbar - offset OLPI_horizScrollbar) \
		eq CS_VERTICAL>
CheckHack <(CS_VERTICAL eq (SSP_VERTICAL/2))>


CallScrollbar	proc	far
	push	si
	mov	si, ds:[si]			;point to instance
	add	si, ds:[si].Vis_offset		;ds:[di] -- SpecInstance
	mov	si, ds:[si].OLPI_horizScrollbar[bx]	
	;
	; si is chunk handle of scrollbar, or null if none.  
	;
	tst	si				;no scrollbar, branch
	jz	exit
	push	ax				;save method number
	push	cx, dx, bp			;save args
EC <	call	CheckScrollbarAssumption				>
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage			;call it
	pop	cx, dx, bp			;restore args
	pop	ax				;restore method number
exit:
	pop	si
	ret
	
CallScrollbar		endp
			

ViewCommon	ends

Unbuild	segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneNotifyNotEnabled -- 
		MSG_SPEC_NOTIFY_ENABLED for OLPaneClass

DESCRIPTION:	Notifies object that someone has disabled us.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_NOTIFY_ENABLED
		dl	- VisUpdateMode
		dh	- NotifyEnabledFlags:
				mask NEF_STATE_CHANGING if this is the object
					getting its enabled state changed

RETURN:		carry set if visual change
		ax, cx, dx, bp -- trashed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/10/90		Initial version

------------------------------------------------------------------------------@
	
OLPaneNotifyNotEnabled	method dynamic OLPaneClass, MSG_SPEC_NOTIFY_NOT_ENABLED

	;
	; Of course, first do superclass stuff.
	;
	mov	di, offset OLPaneClass
	call	ObjCallSuperNoLock
	jnc	exit				;nothing happened, exit

	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL	
	call	VisCallParentWithSelf
	stc
exit:
	ret
OLPaneNotifyNotEnabled	endm

Unbuild ends


InstanceObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGetWindow -- 
		MSG_GEN_VIEW_GET_WINDOW for OLPaneClass

DESCRIPTION:	Returns window handle, or null if none.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_WINDOW

RETURN:		cx	- window handle

DESTROYED:	bx, si, di, ds, es
		ax, dx, bp -- trashed

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/15/91		Initial version

------------------------------------------------------------------------------@

OLPaneGetWindow	method OLPaneClass, MSG_GEN_VIEW_GET_WINDOW
	mov	cx, ds:[di].OLPI_window
EC <	Destroy	ax, dx, bp						>
	ret
OLPaneGetWindow	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGetVisibleRect -- 
		MSG_GEN_VIEW_GET_VISIBLE_RECT for OLPaneClass

DESCRIPTION:	Returns visible rect.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_GET_VISIBLE_RECT
		cx:dx   - buffer of size RectDWord, currently nulled by generic
				handler.

RETURN:		cx:dx   - {RectDWord} visible rect, or left null if not built
		ax, bp	- destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 2/91		Initial version
	Chris	5/ 4/91		Fixed for graphics coord definitions

------------------------------------------------------------------------------@

OLPaneGetVisibleRect	method dynamic OLPaneClass,
						MSG_GEN_VIEW_GET_VISIBLE_RECT
	mov	di, ds:[di].OLPI_window		; get window in di
	tst	di				; is there a window?
	jz	exit				; jump if not

	call	GrCreateState			;Don't VUP! 10/21/92 cbh
	movdw	dssi, cxdx
	call	GrGetWinBoundsDWord		; fill buffer with bounds
	call	GrDestroyState
	add	ds:[si].RD_bottom.low, 1
	adc	ds:[si].RD_bottom.high, 0
	add	ds:[si].RD_right.low, 1
	adc	ds:[si].RD_right.high, 0
exit:
	ret
OLPaneGetVisibleRect	endm

InstanceObscure ends

;----------------------------


ViewBuild segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPaneSpecBuild --
		MSG_SPEC_BUILD for OLPaneClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Builds out a pane, adding pane stuff if necessary.
		Does pane stuff to build out scrollbars, and does pane stuff
		to process hints and send the view handle to the OD.

PASS:		*ds:si 	- instance data
		ax 	- MSG_VISBUILD
		bp	- SpecBuildFlags

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLPaneSpecBuild	method OLPaneClass, MSG_SPEC_BUILD

EC <	push	bx,si,di						     >
EC <	mov	di, ds:[si]			;point to instance	     >
EC <	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance	     >
EC <	mov	si, ds:[di].GVI_content.chunk	;check OD		     >
EC <	tst	si				;zero is probably cool...    >
EC <	jz	EC10							     >
EC <	mov	bx, ds:[di].GVI_content.handle				     >
EC <	call	ECCheckOD			;make sure an OD	     >
EC < EC10:								     >
EC <	DoPop	di,si,bx						     >
   
	push	bp
	mov	di, offset OLPaneClass		;do super class build
	call	ObjCallSuperNoLock

	call	PaneOnlyGeometryHints		;handle hints for pane only

	mov	bp, si				;pass handle in bp
	
	; FINALLY, PROCESS HINTS.  The hints requesting that the window be
	; made the default focus or target are processed here.  (But not
	; if the view isn't focusable!  -cbh 12/ 8/92)
	;

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_FOCUSABLE
	jnz	10$

	; We want to process HINT_DEFAULT_TARGET even if the view is not
	; focusable. - Joon (7/12/94)

	call	ScanTargetHintHandler
	jmp	20$
10$:
	;
	; If we are on a no-kbd system, try to bring up the kbd for this
	; focusable view.
	;
	call	CheckIfKeyboardRequired
	jnc	noKeyboard

	mov	ax, ATTR_GEN_VIEW_DOES_NOT_ACCEPT_TEXT_INPUT
	call	ObjVarFindData
	jc	noKeyboard

	push	bp
	mov	ax, MSG_SPEC_GUP_QUERY
	mov	cx, SGQT_BRING_UP_KEYBOARD
	call	GenCallParent
	pop	bp

noKeyboard:

	call	ScanFocusTargetHintHandlers
	jcxz	20$					;was there a hint?
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLPI_flags, mask OLPF_MAKE_DEFAULT_FOCUS
	
20$:
	call	SetupPaneColor				;set up window color
	pop	bp
	call	SendViewHandle				;send handle of view
	
	;
	; Set the default focus in the content, if we have the default focus.
	; (Changed to do this anytime we're focusable, to get an initial node
	; to have the focus in the content.  -cbh 2/12/92)
	;
;	mov	di, ds:[si]			
;	add	di, ds:[di].Vis_offset
;	test	ds:[di].OLPI_flags, mask OLPF_MAKE_DEFAULT_FOCUS
;	jz	30$

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_FOCUSABLE
	jz	30$
	mov	ax, MSG_META_CONTENT_APPLY_DEFAULT_FOCUS
	call	OLPaneSendToApp
30$:
	mov	ax, MSG_META_GCN_LIST_ADD
	call	AddRemoveCommon

if NO_WINDOW_FRAME_ON_VIEWS
	;	
	; Force all views to not have a win frame.   
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	ornf	ds:[di].GVI_attrs, mask GVA_NO_WIN_FRAME
else
	;
	; Set a flag in the OLCtrl that we can't be overlapping objects,
	; if we have no win frame.   -cbh 2/22/93
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GVI_attrs, mask GVA_NO_WIN_FRAME
	jz	exit				;has a frame, exit
	call	OpenCheckIfBW			;not B/W, don't sweat this
	jnc	exit
	call	SpecSetFlagsOnAllCtrlParents	;sets CANT_OVERLAP_KIDS
endif

exit:
	ret

OLPaneSpecBuild	endm


;---

AddRemoveCommon	proc	far
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_CONTROLLED
	jz	done

	push	bp
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_CONTROLLED_GEN_VIEW_OBJECTS
	mov	di, ds:[LMBH_handle]
	movdw	ss:[bp].GCNLP_optr, disi
	call	GenCallApplication
	add	sp, size GCNListParams
	pop	bp
done:
	ret

AddRemoveCommon	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScanGeometryHints -- 
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLPaneClass

DESCRIPTION:	Scans geometry hints.2/12/92

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SCAN_GEOMETRY_HINTS

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 4/92		Initial Version

------------------------------------------------------------------------------@

OLPaneScanGeometryHints	method static OLPaneClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS

	mov	di, segment OLPaneClass
	mov	es, di
	mov	di, offset OLPaneClass
	CallSuper	MSG_SPEC_SCAN_GEOMETRY_HINTS

PaneOnlyGeometryHints	label	far
	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
	;
	; We have our own method position.  Clear this flag.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	andnf	ds:[di].VI_geoAttrs, not mask VGA_USE_VIS_SET_POSITION	
	
	;
	; Set the notify flag so we can get a method when the geometry is all
	; done and set the scrollbar's page size then.
	;
	ornf 	ds:[di].VI_geoAttrs, mask VGA_NOTIFY_GEOMETRY_VALID

	;
	; Clear this flag so that we make sure we invalidate the entire object
	; every time, not just the margins.
	;
	andnf 	ds:[di].VCI_geoAttrs, not mask VCGA_ONLY_DRAWS_IN_MARGINS

	;
	; Avoid thinking we're centered, etc.  We really don't use the 
	; geometry manager at all.  Otherwise we end up with centering problems
	; etc.  (Can't figure out how this could help us.  It 
	; certainly screws up things like minimum size when there's a moniker.
	; -cbh 11/ 5/92)  (Okay, figured it out.  We need to avoid centering,
	; other geometry flags.  Might as well turn them off, so other problems
	; don't occur.  Also, we'll turn on CUSTOM_GEOMETRY.  Yes, this helps
	; centering.  -cbh 11/11/92)
	;
	andnf	ds:[di].VCI_geoAttrs, mask VCGA_HAS_MINIMUM_SIZE
	ornf	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN

	.leave
	ret
OLPaneScanGeometryHints	endm
		


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneUpdateSpecBuild -- 
		MSG_SPEC_BUILD_BRANCH for OLPaneClass

DESCRIPTION:	Builds out children.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_BUILD_BRANCH
		bp - SpecBuildFlags

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version

------------------------------------------------------------------------------@
OLPaneUpdateSpecBuild	method OLPaneClass, MSG_SPEC_BUILD_BRANCH
	;
	; We're going to zero these now, and expect them to get rebuilt.
	; We don't clear them in the unbuild so that adding generic objects
	; can function the same way whether built or unbuilt.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	clr	bx
	mov	ds:[di].OLPI_horizScrArea, bx
	mov	ds:[di].OLPI_vertScrArea, bx
	mov	ds:[di].OLPI_leftObj, bx
	mov	ds:[di].OLPI_topObj, bx
	mov	ds:[di].OLPI_rightObj, bx
	mov	ds:[di].OLPI_bottomObj, bx
					
	push	ax, bp

	call	SetScrollbarAreas		;choose areas for scrollbars

	;
	;  See if there are any non-scrollbar objects that want to
	;  go in the scroller areas.
	;
	call	FindAreaObjects			;set up area objects
	pop	ax, bp
	
	mov	di, offset OLPaneClass		;build ourselves, children
	call	ObjCallSuperNoLock

	;
	; Do hints now.  (Previously in MSG_META_INITIALIZE, moved here to
	; make rulers work.) - 11/ 4/92 cbh  (Moved from top of routine to
	; really make these work. - 12/ 7/92 cbh)
	;
	mov	di, cs
	mov	es, di
	mov	di, offset cs:PaneHints
	mov	ax, length (cs:PaneHints)
	call	OpenScanVarData			;look for positioning hint

if _NIKE
	; Notify OLWin of horizontally scrollable view
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_horizAttrs, mask GVDA_SCROLLABLE
	jz	notHorizScroll

	mov	ax, MSG_OL_WIN_SET_DISPLAY_TITLE_VIEW
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	CallOLWin
notHorizScroll:
endif

	call	EnsureScrollbars		;add bars if needed

done:	
	ret
OLPaneUpdateSpecBuild	endm


PaneHints	VarDataHandler \
 <HINT_VIEW_LEAVE_ROOM_FOR_VERT_SCROLLER, offset LeaveRoomVert>,
 <HINT_VIEW_LEAVE_ROOM_FOR_HORIZ_SCROLLER, offset LeaveRoomHoriz>,
 <ATTR_GEN_VIEW_DO_NOT_WIN_SCROLL, offset DoNotWinScroll>,
if DRAW_STYLES
 <HINT_DRAW_STYLE_FLAT, offset PaneDrawStyleFlat>,
 <HINT_DRAW_STYLE_3D_LOWERED, offset PaneDrawStyleLowered>,
 <HINT_DRAW_STYLE_3D_RAISED, offset PaneDrawStyleRaised>,
endif
 <HINT_VIEW_REMOVE_SCROLLERS_WHEN_NOT_SCROLLABLE, offset RemoveScrollers>

if DRAW_STYLES

PaneDrawStyleFlat	proc	far
	mov	al, DS_FLAT
	GOTO	PaneStoreDrawStyle
PaneDrawStyleFlat	endp

PaneDrawStyleLowered	proc	far
	mov	al, DS_LOWERED
	GOTO	PaneStoreDrawStyle
PaneDrawStyleLowered	endp

PaneDrawStyleRaised	proc	far
	mov	al, DS_RAISED
	FALL_THRU	PaneStoreDrawStyle
PaneDrawStyleRaised	endp

PaneStoreDrawStyle	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLPI_drawStyle, al
	ret
PaneStoreDrawStyle	endp

endif ; DRAW_STYLES

LeaveRoomVert	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLPI_flags, mask OLPF_LEAVE_ROOM_FOR_VERT_SCROLLER
	ret
LeaveRoomVert	endp
		
LeaveRoomHoriz	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLPI_flags, mask OLPF_LEAVE_ROOM_FOR_HORIZ_SCROLLER
	ret
LeaveRoomHoriz	endp

DoNotWinScroll	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLPI_attrs, mask OLPA_NON_SCROLLING
	ret
DoNotWinScroll	endp

RemoveScrollers	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLPI_attrs, \
		mask OLPA_REMOVE_SCROLLBARS_WHEN_NOT_SCROLLABLE
	ret
RemoveScrollers	endp
		
		

COMMENT @----------------------------------------------------------------------

ROUTINE:	SetScrollbarAreas

SYNOPSIS:	Finds out where the scrollbars want to be, and stores the info
		away for later.

CALLED BY:	OLPaneSpecBuild

PASS:		*ds:si -- view

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 9/91		Initial version

------------------------------------------------------------------------------@

SetScrollbarAreas	proc	near

	clr	cx, dx, bp		; nothing yet at all
	mov	ax, MSG_GEN_FIND_VIEW_RANGES
	
	mov	di, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset GI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	push	di
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren	; call children, returning args
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	tst	dx				;did we find a horiz bar?
	jz	10$				;no, just set default position
	mov	ds:[di].OLPI_horizScrollbar, dx	;else store as the bar
	cmp	cl, RVA_NO_AREA_CHOICE		;a choice made?
	jne	20$				;yes, branch
10$:
	mov	cl, RVA_BOTTOM_AREA		;use bottom area, the default
20$:
	push	cx
	clr	ch				;convert to an area variable
	shl	cx, 1
	add	cx, offset OLPI_leftObj - RVA_LEFT_AREA*2   
	mov	ds:[di].OLPI_horizScrArea, cx	;save as horiz scroll area
	pop	cx				;restore area choice
	
	tst	bp				;did we find a horiz bar?
	jz	30$				;no, branch
	mov	ds:[di].OLPI_vertScrollbar, bp	;else store as the bar
	cmp	ch, RVA_NO_AREA_CHOICE		;a choice made?
	jne	40$				;yes, branch
30$:
if _RUDY and 0
	mov	ch, RVA_LEFT_AREA		;use left area, the default
else
	mov	ch, RVA_RIGHT_AREA		;use right area, the default
endif
40$:
	mov	cl, ch				;put in cx
	clr	ch
	shl	cx, 1
	add	cx, offset OLPI_leftObj - RVA_LEFT_AREA*2   ;dork with value
	mov	ds:[di].OLPI_vertScrArea, cx	;save as vert scroll area

	ret
SetScrollbarAreas	endp
		
CheckHack <((RVA_TOP_AREA - RVA_LEFT_AREA)*2) eq \
		(offset OLPI_topObj - offset OLPI_leftObj)
CheckHack <((RVA_RIGHT_AREA - RVA_LEFT_AREA)*2) eq \
		(offset OLPI_rightObj - offset OLPI_leftObj)
CheckHack <((RVA_BOTTOM_AREA - RVA_LEFT_AREA)*2) eq \
		(offset OLPI_bottomObj - offset OLPI_leftObj)



COMMENT @----------------------------------------------------------------------

ROUTINE:	FindAreaObjects

SYNOPSIS:	Looks for objects to go in different areas.

CALLED BY:	OLPaneUpdateSpecBuild

PASS:		*ds:si -- pane

RETURN:		nothing

DESTROYED:	ax, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version

------------------------------------------------------------------------------@
FindAreaObjects	proc	near
		
	clr	bx				; initial child (first
	push	bx				; child of
	push	bx				; composite)
	mov	bx,offset GI_link		;pass offset to LinkPart
	push	bx
	mov	bx, SEGMENT_CS
	push	bx				;pass callback routine (seg)
	mov	bx,offset ChooseAreaForObject
	push	bx				;pass callback routine (seg)

	mov	bx,offset Gen_offset		;pass offset to master part
	mov	di,offset GI_comp		;pass offset to composite
	call	ObjCompProcessChildren
	ret
FindAreaObjects	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ChooseAreaForObject

SYNOPSIS:	Chooses an area for this object.

CALLED BY:	FindAreaObjects (via ObjCompProcessChildren)

PASS:		*ds:si -- object
		*es:di -- parent view
		
RETURN:		nothing

DESTROYED:	ax, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

        Don't use this if the view is not yet built or usable!  This
	stuff can be put off until a vis built and involves growing 
	visible objects.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version

------------------------------------------------------------------------------@
ChooseAreaForObject	proc	far

	push	bx, si
EC <	call	CheckForDamagedES					>
EC <	mov	cx, ds:[LMBH_handle]					>
EC <	cmp	cx, es:[LMBH_handle]					>
EC <	ERROR_NZ	OL_VIEW_CHILDREN_MUST_BE_IN_SAME_BLOCK		>
   
   	push	es:[LMBH_handle]
   	call	GetObjectAreaChoice		;cx <- offset to area
	pop	bx
	call	MemDerefES			;fixup es
	
storeInOffset:
	call	AddObjectToArea			;add object to area
	pop	bx, si
	clc					;continue processing!

	ret
ChooseAreaForObject	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	AddObjectToArea

SYNOPSIS:	Adds an object to the given area of a view.  Various area
		pointers are updated as necessary.

CALLED BY:	ChooseAreaForObject

PASS:		*ds:si -- object to add
		*ds:di -- view
		cx -- area to add it to

RETURN:		nothing

DESTROYED:	bx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/20/92		Initial version

------------------------------------------------------------------------------@
AddObjectToArea	proc	near

if _VIEW_X_SCROLLERS_GO_IN_TITLE_BAR or _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR ;----
	;
	;  If this is an X or Y scroller that wants to be in the
	;  title bar, skip this routine.
	;

	call	SeeIfWeNeedToSkipAdd		; carry set to skip
	jc	exit

endif	;----------------------------------------------------------------------

	;
	; See if any object is currently stored where we'd like this one.
	; If there is, we'll have to create a OLCtrl to keep both of these
	; objects in.
	;
	mov	ax, di				;save view handle
	mov	di, ds:[di]			;deref view
	add	di, ds:[di].Vis_offset
	add	di, cx				;add to view instance data
	mov	bp, {word} ds:[di]		;get current area object
	tst	bp
	jz	storeInOurArea			;no object in area, go store
	
	;
	; If there is an object, and it's an OLCtrl that we've created 
	; previously, then we'll exit and allow this object to be added to
	; that OLCtrl.  (It better not be an OLSettingCtrl, though)
	;
	mov	si, bp				; also si, for the moment
	call	VisCheckIfVisGrown		; vis grown?
	jnc	buildOLCtrl			; no, not visComp, go build one
	
	push	es:[LMBH_handle]
	call	MakeSpecificObject		; *ds:si <- object
	clc					; assume nothing there
	mov	bp, si				; (keep in bp as well)
	jz	10$				; nothing there, build control
	mov	di, segment OLCtrlClass
	mov	es, di
	mov	di, offset OLCtrlClass
	call	ObjIsObjectInClass		; see if OLCtrl
	jnc	10$				; not an OLCtrl, branch
	mov	di, offset OLItemGroupClass	; see if OLItemGroup
	call	ObjIsObjectInClass
	jnc	8$				; else so, clear carry so we
	clc					;  won't use it as an OLCtrl
	jmp	short 10$
8$:
	stc
10$:
	pop	bx
	pushf
	call	MemDerefES
	popf
	jc	exit				; is OLCtrl, exit
	
buildOLCtrl:
	call	CreateAreaOLCtrl		; create an OLCtrl, then.
						; si <- OLCtrl handle
storeInOurArea:
	;
	; cx    -- offset to area variable
	; ax    -- view handle
	; si    -- holds new object to be store in area variable
	;
	xchg	ax, si
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	add	di, cx
	mov	{word} ds:[di], ax		;store new head's handle
	
exit:
	ret
AddObjectToArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeeIfWeNeedToSkipAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this object should NOT be stored as usual in
		the one of the view outlier areas.

CALLED BY:	AddObjectToArea

PASS:		*ds:si = object

RETURN:		carry set if we should NOT add the object normally
		(i.e. it's a scroller bound for the titlebar)
		carry clear if it's to go near the view as usual

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/29/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _VIEW_X_SCROLLERS_GO_IN_TITLE_BAR or _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR

SeeIfWeNeedToSkipAdd	proc	near
		uses	ax,bx
		.enter

if _VIEW_X_SCROLLERS_GO_IN_TITLE_BAR	;--------------------------------------
	;
	;  See if it's an X scroller, and if so, skip away.
	;
		mov	ax, HINT_VALUE_X_SCROLLER
		call	ObjVarFindData
		jc	done

endif	; _VIEW_X_SCROLLERS_GO_IN_TITLE_BAR -----------------------------------

if _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR	;--------------------------------------
	;
	;  If this is an "item group gadget" (meaning it scrolls
	;  a scrolling list), then it shouldn't go in the title
	;  bar.
	;
		mov	ax, HINT_VALUE_ITEM_GROUP_GADGET
		call	ObjVarFindData
		jc	normal
	;
	;  See if it's a Y scroller, and if so, skip away.
	;
		mov	ax, HINT_VALUE_Y_SCROLLER
		call	ObjVarFindData
		jc	done

endif	; _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR -----------------------------------
	;
	;  It's not an object we're interested in; return
	;  carry clear to have view add it as normal.
	;
normal:
		clc
done:
		.leave
		ret
SeeIfWeNeedToSkipAdd	endp

endif	;_VIEW_X_SCROLLERS_GO_IN_TITLE_BAR or _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR


COMMENT @----------------------------------------------------------------------

ROUTINE:	CreateAreaOLCtrl

SYNOPSIS:	Creates an OLCtrl to manage objects under an area.
		Unbuilds the previous object in that area and adds it
		to the ctrl, if necesssary. 

CALLED BY:	ChooseAreaForObject

PASS:		cx -- offset to area to add it for (offset OLPI_leftObj, etc.)
		*ds:si, *ds:bp -- specific instance of current object in that 
				  area
		ax -- view handle

RETURN:		*ds:si -- new area control
		cx, bp, es -- preserved

DESTROYED:	bp, dx, di, bx

PSEUDO CODE/STRATEGY:
       		I am not proud of this code.  There must be an easier way
		to do such a thing.  I am thinking now that using a
		GenInteraction and setting things usable, unusable, etc.
		may have made this simpler.  Or maybe not.  We would have
		had to use the HINT_RANGE_THROW_AWAY in the GenInteractions that
		we currently use in the scrollbars, to generically remove
		themselves and destroying themselves on visually unbuilding.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/16/91		Initial version

------------------------------------------------------------------------------@
CreateAreaOLCtrl	proc	near
	;
	; Need to remove current object if it's already visually built, 
	; create a OLCtrl object here, add the current object to the new 
	; OLCtrl if was built before, and push the comps handle to be stored
	; for the area.
	;
	; cx      -- offset to area variable
	; bp,si   -- current visual head object for the desired area 
	; ax      -- view handle
	;
	push	es:[LMBH_handle]
	push	ax, cx				; save area variable, view
	
	mov	dx, bp				; dx <- old head handle
						; ax <- view handle
	
	tst	si				; is there even a vis part?
	clc					; assume not
	jz	5$				; no, branch
	call	VisCheckIfSpecBuilt		; have we already added 
5$:						;   the old head visually?
	mov	si, ax				; (view handle in si)
	pushf					; push the result of our test
	push	dx				; save old head object
	jnc	10$				; not vis built, branch
	
	push	si				; save view handle
	mov	si, dx
	mov	ax, MSG_VIS_CLOSE		; close our old head
	call	ObjCallInstanceNoLock
	mov	dx, si
	pop	si				; restore view handle
	
	mov	cx, ds:[LMBH_handle]
	clr	bp				; no dirty necessary
	mov	ax, MSG_VIS_REMOVE_CHILD
	call	ObjCallInstanceNoLock		; remove old head from view
10$:	
	mov	dx, si				; keep view in dx
	mov	di, offset OLCtrlClass
	mov	ax, segment OLCtrlClass
	mov	es, ax
	mov	bx, ds:[LMBH_handle]
	call	GenInstantiateIgnoreDirty
	mov	bx, offset Vis_offset
	call	ObjInitializePart		; Will initialize text object
	xchg	si, dx				; *ds:si = view, 
						; *ds:dx = new visComp
	
	push	dx				; save vis comp's handle
	mov	cx, ds:[LMBH_handle]
	mov	bp, CCO_LAST
	mov	ax, MSG_VIS_ADD_CHILD
	call	ObjCallInstanceNoLock		; visibly add the OLCtrl
	
EC <	call	VisCheckVisAssumption					>
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset		; assuming view is vis'ed
	pop	si				; vis comp in *ds:si
	
;	test	ds:[di].VI_attrs, mask VA_REALIZED
;	jz	15$				; view not realized, branch
	
	mov	cl, mask VOF_WINDOW_INVALID
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_MARK_INVALID
	call	ObjCallInstanceNoLock
	
;	clr	bp				; top of branch
;	mov	ax, MSG_VIS_OPEN		; let's open the OLCtrl now
;	call	ObjCallInstanceNoLock		
;15$:
	mov	cx, mask VA_FULLY_ENABLED	; set fully enabled
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_SET_ATTRS		; be a good boy and send method
	call	ObjCallInstanceNoLock
	
	pop	dx				; old head in *ds:dx
	popf					; restore whether old head had
						;    been specifically built
	jnc	20$				; no, don't do it now
	
	mov	cx, ds:[LMBH_handle]		
	mov	bp, CCO_LAST
	mov	ax, MSG_VIS_ADD_CHILD	; add old head to visComp
	call	ObjCallInstanceNoLock		
	
	push	si
	mov	si, dx
	
	mov	cl, mask VOF_WINDOW_INVALID
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_MARK_INVALID
	call	ObjCallInstanceNoLock
	
;	clr	bp				; top of branch
;	mov	ax, MSG_VIS_OPEN		; let's open the old head now
;	call	ObjCallInstanceNoLock		
	pop	si
20$:
	;
	; Set the OLCtrl's geometry appropriately.  The nice thing to do is
	; to justify the children towards the view window.
	;
	pop	bx				; restore area variable
	push	bx
	sub	bx, offset OLPI_leftObj		; make offset from left

if _JEDIMOTIF
	mov	cx, mask VCGA_ORIENT_CHILDREN_VERTICALLY or \
			(HJ_CENTER_CHILDREN_VERTICALLY shl \
				offset VCGDA_HEIGHT_JUSTIFICATION) shl 8 or\
			(WJ_RIGHT_JUSTIFY_CHILDREN shl \
				offset VCGDA_WIDTH_JUSTIFICATION) shl 8
else
	mov	cx, mask VCGA_ORIENT_CHILDREN_VERTICALLY or \
			(HJ_BOTTOM_JUSTIFY_CHILDREN shl \
				offset VCGDA_HEIGHT_JUSTIFICATION) shl 8 or\
			(WJ_RIGHT_JUSTIFY_CHILDREN shl \
				offset VCGDA_WIDTH_JUSTIFICATION) shl 8
		  				; assume vert, bottom just,
		    				;   right just
endif

	clr	dx				; assume nothing to be cleared
	cmp	bx, offset OLPI_rightObj - offset OLPI_leftObj	
	jb	30$				; top or left, leave justs in
	xchg	ch, dh				; right or bot, clear them
30$:
	test	bx, offset OLPI_topObj - offset OLPI_leftObj
						  ; check left or right
	jz	40$				  ; left or right, set vertical
						  ; else top or bottom
	xchg	cl, dl				  ; clear vertical flag

if (not _JEDIMOTIF)
	and	ch, mask VCGDA_HEIGHT_JUSTIFICATION ; height justification is
	and	dh, mask VCGDA_HEIGHT_JUSTIFICATION ;    applicable only
endif

if _NIKE
	or	ch, mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
		    mask VCGDA_DIVIDE_WIDTH_EQUALLY
else
	or	ch, mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT
endif
	jmp	short 45$
40$:
						  ; left or right...
	and	ch, mask VCGDA_WIDTH_JUSTIFICATION  ; width justification is 
	and	dh, mask VCGDA_WIDTH_JUSTIFICATION  ;   applicable

	or	ch, mask VCGDA_EXPAND_HEIGHT_TO_FIT_PARENT
45$:
	and	cl, not mask VCGA_ONLY_DRAWS_IN_MARGINS ; clear this, so that 
						  ;   when the
						  ;   comp shrinks, what it
						  ;   left behind is all 
						  ;   redrawn.
	mov	ax, MSG_VIS_COMP_SET_GEO_ATTRS	  ; set the thing's geometry
	call	ObjCallInstanceNoLock
	
	DoPop	cx, ax				; restore area variable
						; si <- newly created visComp 
	pop	bx
	call	MemDerefES
	ret
CreateAreaOLCtrl	endp

			

COMMENT @----------------------------------------------------------------------

ROUTINE:	GetObjectAreaChoice

SYNOPSIS:	Returns object's area choice, in the form of an offset to
		the view's area

CALLED BY:	ChooseAreaForObject, OLPaneAddVisChild

PASS:		*ds:si -- object
		*ds:di -- view

RETURN:		cx -- offset in view's instance data to the area choice

DESTROYED:	ax, cx, dx, bp, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version

------------------------------------------------------------------------------@

GetObjectAreaChoice	proc	near
	push	di
	mov	cl, RVA_NO_AREA_CHOICE		;no choice made yet
	mov	ax, MSG_GEN_QUERY_VIEW_AREA
	call	ObjCallInstanceNoLock
	mov	di, ds:[di]			
	add	di, ds:[di].Vis_offset		;deref view
	
	cmp	cl, RVA_NO_AREA_CHOICE		;still ambivalent?
	je	15$				;yes, we'll put with y scroller
	
;EC <	cmp	cl, RVA_NO_AREA_CHOICE		;still ambivalent?	    >
;EC <	ERROR_E	OL_VIEW_CHILD_NEEDS_AREA_HINT	;require a view area hint   >
	
	cmp	cl, RVA_X_SCROLLER_AREA		;wants to be with x scroller?
	jne	10$				;no, branch
	mov	cx, ds:[di].OLPI_horizScrArea	;else look up offset to use
	jmp	short exit			;and store
10$:
	cmp	cl, RVA_Y_SCROLLER_AREA		;wants to be with y scroller?
	jne	20$				;no, branch
15$:
	mov	cx, ds:[di].OLPI_vertScrArea	;else look up offset to use
	jmp	short exit			;and store
20$:
	clr	ch				;convert to an area variable
	shl	cx, 1
	add	cx, offset OLPI_leftObj - RVA_LEFT_AREA*2   
exit:
	pop	di
EC <	cmp	cx, offset OLPI_leftObj		;bad value?		    >
EC <	ERROR_B	OL_VIEW_BAD_CHILD_AREA_OFFSET		;we fucked up if so	    >
EC <	cmp	cx, offset OLPI_bottomObj	;bad value?		    >
EC <	ERROR_A	OL_VIEW_BAD_CHILD_AREA_OFFSET	;we fucked up if so	    >
	ret
GetObjectAreaChoice	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneGetVisParent -- 
		MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD for OLPaneClass

DESCRIPTION:	Returns a vis parent.  What we will be doing here is looking
		up the child`s desired location.  If it's listed as the
		head object at that location, we'll just return ourselves;
		otherwise, we'll return the head object, which is probably
		a OLCtrl object that we created earlier.  

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD
		^lcx:dx	- child to add

RETURN:		carry set if anything returned, with: 
			^lcx:dx - vis parent to add child to

ALLOWED TO DESTROY:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

	- if the scroller is an X scroller AND X scrollers are
	  supposed to go in the titlebar, return the appropriate
  	  title-bar group (currently the right one, unless
	  someone feels like implementing more features).

	- if the scroller is a Y scroller AND Y scrollers are
	  supposed to go in the titlebar, return the right group

	  Note:  the code is duplicated for X & Y scrollers since
		 those features can be turned on & off independently.

	- if the scroller is an X or Y scroller but not supposed
	  to go in the titlebar, have it choose the area around
	  the view in which to place itself.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version
	stevey	9/28/94		added title-bar scroller features

------------------------------------------------------------------------------@

OLPaneGetVisParent	method OLPaneClass, \
			MSG_SPEC_DETERMINE_VIS_PARENT_FOR_CHILD
EC <	xchg	dx, si							    >
EC <	call	VisCheckVisAssumption		;assume we didn't screw up  >
EC <	xchg	dx, si							    >

if _VIEW_X_SCROLLERS_GO_IN_TITLE_BAR or _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR

	;
	;  If this scroller is (save us!) the scroller of one o'
	;  them thar scrolling lists, then don't put it in the title
	;  bar.  Theoretically a specific UI could have either X
	;  or Y scrollers for its scrolling lists, so we do it here
	;  instead of down in the X or Y checking below.
	;
	push	ax, si
	mov	si, dx				; *ds:si = scroller
	mov	ax, HINT_VALUE_ITEM_GROUP_GADGET
	call	ObjVarFindData
	pop	ax, si
	jc	normalScroller			; store normally
endif

if _VIEW_X_SCROLLERS_GO_IN_TITLE_BAR ;-----------------------------------------
	;
	;  Check to see if this is an X scroller before doing
	;  anything crazy.
	;
	push	ax, si
	mov	si, dx				; *ds:si = scroller
	mov	ax, HINT_VALUE_X_SCROLLER
	call	ObjVarFindData			; carry set if found
	pop	ax, si				; *ds:si = view
	jnc	notXScroller			; not found

	;
	;  It's in a title group -- return the group.
	;
	mov	cx, TGT_RIGHT_GROUP		; default for Nike, Jedi
	call	GetTitleBarGroup		; ^lcx:dx = group
	jmp	exit

notXScroller:
endif	; _VIEW_X_SCROLLERS_GO_IN_TITLE_BAR ------------------------------------

if _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR ;------------------------------------------
	;
	;  Check to see if this is a Y scroller before doing
	;  anything crazy.
	;
	push	ax, si
	mov	si, dx				; *ds:si = scroller
	mov	ax, HINT_VALUE_Y_SCROLLER
	call	ObjVarFindData			; carry set if found
	pop	ax, si				; *ds:si = view
	jnc	notYScroller			; not found

	;
	;  It's in a title group -- return the group. 
	;
	mov	cx, TGT_RIGHT_GROUP		; default for Jedi
	call	GetTitleBarGroup		; ^lcx:dx = title group
	jmp	exit

notYScroller:
endif ; _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR ------------------------------------

normalScroller::
	;
	;  This scroller isn't supposed to be in some weird place,
	;  so do the normal area-choosing thing.
	;

	push	ax, si, dx, es, bp		;save much
	mov	di, si				;parent handle in di
	mov	si, dx				;child handle in si
	call	GetObjectAreaChoice		;return choice for object
	pop	ax, si, dx, es, bp		;restore much
	
	mov	di, ds:[si]			;else look up area pointer
	add	di, ds:[di].Vis_offset
	add	di, cx
	mov	di, {word} ds:[di]		;get the chunk handle there
EC <	tst	di				;is anything here?	  >
EC <	ERROR_Z	OL_VIEW_EXPECTED_A_CHILD_IN_AREA ;no, something went wrong >
   
	cmp	dx, di				;is it this object?
	mov	cx, ds:[LMBH_handle]		;(restore cx)
	je	returnParent			;yes, return ourselves
	mov	si, di				;else return head object
	
returnParent:
	mov	dx, si				;^lcx:dx -- parent to use
	mov	cx, ds:[LMBH_handle]
exit:
	stc					;set duh carry
	ret					
OLPaneGetVisParent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTitleBarGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the title-bar group to put the scroller in.

CALLED BY:	OLPaneGetVisParent

PASS:		*ds:si = view
		cx = TitleGroupType

RETURN:		^lcx:dx = title bar group (created if necessary)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	9/28/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _VIEW_X_SCROLLERS_GO_IN_TITLE_BAR or _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR
GetTitleBarGroup	proc	near
	uses	ax,bp
	.enter

if _JEDIMOTIF
	;
	; for JEDI, scrollers from a GenDisplay need to go up to the primary
	; (use OLDisplayWinClass since GenDisplayClass is both displays and
	; primaries, the stuff should already be spec-built)
	;
	push	cx				; save TitleGroupType
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	cx, segment OLDisplayWinClass
	mov	dx, offset OLDisplayWinClass
	call	CallOLWin			; carry set if so
	pop	cx				; cx = TitleGroupType
	jnc	notDisplay			; not GenDisplay, use CallOLWin
	mov	ax, MSG_OL_WIN_GET_OR_CREATE_TITLE_GROUP
	call	callOLBaseWin			; call OLBaseWin, ret ^lcx:dx
	;
	; for this case, we need to update the OLBaseWin manually
	;
	push	cx, dx
	mov	ax, MSG_VIS_MARK_INVALID
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	callOLBaseWin			; call OLBaseWin
	pop	cx, dx				; ^lcx:dx = title bar group
	jmp	done
notDisplay:
	mov	ax, MSG_OL_WIN_GET_OR_CREATE_TITLE_GROUP
	call	CallOLWin
done:
else
	mov	ax, MSG_OL_WIN_GET_OR_CREATE_TITLE_GROUP
	call	CallOLWin
endif

	.leave
	ret

if _JEDIMOTIF
callOLBaseWin	label	near
	push	si				; save our chunk handle
	mov	bx, segment OLBaseWinClass	; else use Classed event
	mov	si, offset OLBaseWinClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	pop	si				; *ds:si = view
	mov	cx, di				; cx = Classed event
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock
	retn
endif
GetTitleBarGroup	endp
endif	; _VIEW_X_SCROLLERS_GO_IN_TITLE_BAR or _VIEW_Y_SCROLLERS_GO_IN_TITLE_BAR


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneAddGenChild -- 
		MSG_GEN_ADD_CHILD for OLPaneClass

DESCRIPTION:	Somebody is going to make our lives miserable by adding a
		new child.  Find an area for the new object and hope for 
		the best.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ADD_CHILD
		bp	- CompChildFlags

RETURN:		nothing
		destroys -- ax, cx, dx, bp
		
ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version

------------------------------------------------------------------------------@

OLPaneAddGenChild	method OLPaneClass, MSG_GEN_ADD_CHILD
EC <	cmp	cx, ds:[LMBH_handle]					>
EC <	ERROR_NZ	OL_VIEW_CHILDREN_MUST_BE_IN_SAME_BLOCK		>
   
   	call	VisCheckIfSpecBuilt		;are we specifically built yet?
	jnc	exit				;no, don't choose an area 
						;   until then.
   	push	bp, cx, dx
   	mov	di, si				;view in es:di
	mov	si, ds
	mov	es, si
	mov	si, dx				;pass child in ds:si
	call	ChooseAreaForObject		;choose an area for it
	pop	bp, cx, dx
exit:
	ret
OLPaneAddGenChild	endm

ViewBuild	ends


Unbuild	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneRemoveGenChild -- 
		MSG_GEN_REMOVE_CHILD for OLPaneClass

DESCRIPTION:	Somebody is going to make our lives miserable by removing a
		child.  Zero out the area location this child uses.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_REMOVE_CHILD
		bp	- CompChildFlags

RETURN:		nothing
		destroys -- ax, cx, dx, bp
		
ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version

------------------------------------------------------------------------------@

OLPaneRemoveGenChild	method OLPaneClass, MSG_GEN_REMOVE_CHILD
EC <	cmp	cx, ds:[LMBH_handle]					>
EC <	ERROR_NZ	OL_VIEW_CHILDREN_MUST_BE_IN_SAME_BLOCK		>
   
	mov	cx, 4
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	
anotherArea:
	cmp	ds:[di].OLPI_leftObj, dx	;is the object being removed?
	jne	10$
	clr	ds:[di].OLPI_leftObj		;yes, zero it
10$:
	add	di, size OLPI_leftObj		;increment to next thing
	loop	anotherArea
	ret
OLPaneRemoveGenChild	endm

Unbuild	ends


ViewBuild	segment resource



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupPaneColor

SYNOPSIS:	Sets up the correct colors to use.

CALLED BY:	OLPaneSpecBuild

PASS:		*ds:si -- pane handle

RETURN:		nothing

ALLOWED TO DESTROY:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 1/90		Initial version

------------------------------------------------------------------------------@

SetupPaneColor	proc	near
	;
	; First, get the current window background color.  We'll keep it
	; in cx.   dx will be set to true if we're in color mode.
	; 
	push	ds
	mov	dx, segment dgroup
	mov	ds, dx
	test	ds:[moCS_flags], mask CSF_BW

	clr	dx				;assume in b/w mode
	jnz	5$				;b/w, branch
	dec	dx				;else set dx (multi-color flag)
5$:
	mov	cl, ds:[moCS_dsLightColor]
	clr	ch
	pop	ds

	;
	; Assume we'll be using colors passed in instance data.
	;
	mov	di, ds:[si]			  ;point to instance
	add	di, ds:[di].Gen_offset		  ;ds:[di] -- GenViewInstance
	movdw	bxax, ds:[di].GVI_color

	;
	; For views that run UI stuff, we will definitely use the background
	; color of the parent window.
	;
	test	ds:[di].GVI_attrs, mask GVA_SAME_COLOR_AS_PARENT_WIN
	jz	10$
	mov	ax, cx				;store as the color we'll use
	clr	bx
10$:

if	_MOTIF or _PM
	;
	; One last thing.  Set a flag in the view's instance data so we'll 
	; know whether the pane window color matches the background color.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	and	ds:[di].OLPI_attrs, not (mask OLPA_SPECIAL_BORDER)
	
	tst	dx				;see if in b/w mode
	jz	exit				;yes, no chisel!
	test	ah, mask WCF_RGB		;if RGB, no match...
	jnz	exit
	cmp	al, C_DARK_GREY			;dark grey?
	je	20$				;yes, use white border
	cmp	al, C_BLACK			;see if black inside
	jne	20$				;no, check for match
15$:
	or 	ds:[di].OLPI_attrs, mask OLPA_WHITE_BORDER
	jmp	short exit			;else use white border and exit
20$:
	cmp	al, C_WHITE			;is the inside white?
	je	exit				;yes, use black border
	or	ds:[di].OLPI_attrs, mask OLPA_SPECIAL_BORDER
exit:
endif

	;
	; Store the final colors.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	movdw	ds:[di].GVI_color, bxax
	ret
SetupPaneColor	endp





COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneVisOpen -- 
		MSG_VIS_OPEN for OLPaneClass

DESCRIPTION:	Opens a simple pane.  Sends some stuff to the output, like the
		pane does, then does OLPaneVisOpen to decide whether to scroll
		the pane window or not.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_OPEN
		bp	- flags

RETURN:		ax, cx, dx, bp -- trashed


ALLOWED TO DESTROY:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/19/90		Initial version

------------------------------------------------------------------------------@

OLPaneVisOpen	method OLPaneClass, MSG_VIS_OPEN
	push	ax, bp			;save method, flags, handle
					;tell content we're opening

	mov	cx, ds:[LMBH_handle]	; Pass OD of view
	mov	dx, si
	mov	ax, MSG_META_CONTENT_VIEW_OPENING
	call	OLPaneSendToApp

	pop	ax, bp
	mov	di, offset OLPaneClass
	call	ObjCallSuperNoLock

if FLOATING_SCROLLERS
	clr	cx			;no need to close before updating
	call	OLPaneUpdateFloatingScrollers
endif
	ret	
OLPaneVisOpen	endm

ViewBuild	ends


Unbuild	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneVisUnbuild --
		MSG_SPEC_UNBUILD for OLPaneClass

DESCRIPTION:	Unbuilds Pane object

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_UNBUILD
		bp	- SpecBuildFlags

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:	ax, bx, cx, dx, si, di, ds, es, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

OLPaneVisUnbuild	method OLPaneClass, MSG_SPEC_UNBUILD

					; Null out references to scrollbars.
					; MSG_SPEC_UNBUILD_BRANCH will
					; send MSG_SPEC_UNBUILD's
					; to them, where they will destroy
					; themselves.
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	AddRemoveCommon

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ax
	mov	ds:[di].OLPI_horizScrollbar, ax		;could be loop
	mov	ds:[di].OLPI_vertScrollbar, ax
	
	call	MetaReleaseFocusExclLow
	call	MetaReleaseTargetExclLow

	mov	ax, MSG_SPEC_UNBUILD
	mov	di, offset OLPaneClass	; do super class unbuild
	GOTO	ObjCallSuperNoLock

OLPaneVisUnbuild	endm

Unbuild ends


InstanceObscure	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetDimensionAttrs -- 
		MSG_GEN_VIEW_SET_DIMENSION_ATTRS for OLPaneClass

DESCRIPTION:	Specific UI handler for this method.  Generic UI is assumed
		to have already set or cleared the attributes.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_DIMENSION_ATTRS
		cl	- vert attrs that were set
		ch	- vert attrs that were cleared
		dl	- horiz attrs that were set
		dh	- horiz attrs that were cleared
		bp 	- update mode

RETURN:		nothing
		ax, cx, dx, bp -- destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/12/91		Initial version

------------------------------------------------------------------------------@

OLPaneSetDimensionAttrs	method OLPaneClass, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
	mov	al, mask GVDA_SCROLLABLE or mask GVDA_DONT_DISPLAY_SCROLLBAR
	test	cl, al			;if messing with any of these,
	jnz	ensureScrollbars	;  make sure we have scrollbars.
	test	ch, al
	jnz	ensureScrollbars
	test	dl, al
	jnz	ensureScrollbars
	test	dh, al
	jz	exit
	
ensureScrollbars:
	;
	; If a scrollbar is going away, we have to invalidate its area
	; first.
	;
	test	cl, mask GVDA_DONT_DISPLAY_SCROLLBAR
	jnz	invalHorizBar
	test	ch, mask GVDA_SCROLLABLE
	jz	checkVert
	
invalHorizBar:
	mov	ax, MSG_VIS_INVALIDATE
	call	CallHorizScrollbar
	
checkVert:
	test	dl, mask GVDA_DONT_DISPLAY_SCROLLBAR
	jnz	invalVertBar
	test	dh, mask GVDA_SCROLLABLE
	jz	doneInvaling
	
invalVertBar:
	mov	ax, MSG_VIS_INVALIDATE
	call	CallVertScrollbar

doneInvaling:
	call	EnsureScrollbars	;There.  We did it.
	;
	; Mark these scrollbar's geometry as invalid.  Probably they're
	; trying to be added or removed, and the view may not get invalidated
	; unless these guys have a path bit leading to their area head.
	; See SizeArea for clues on how things get invalidated.
	;
	; (Changed 5/ 7/91 cbh to keep bits cleaned up.  If we're not going
	;  to use the scrollbar, we'd rather not be marking its geometry
	;  invalid.  Doing on the parent *should* be good enough.)  Well, 
	;  maybe we'll just keep the path bits clear.
	;
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_MARK_INVALID
;	clr	bx			;call parent of horizontal bar
;	call	CallScrollbarParent
;	mov	bx, CS_VERTICAL
;	call 	CallScrollbarParent	;call parent of vertical bar
	
	call	CallHorizScrollbar
	call	CallVertScrollbar
exit:
	ret
OLPaneSetDimensionAttrs	endm

InstanceObscure	ends


ViewCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSuspendUpdate -- 
		MSG_GEN_VIEW_SUSPEND_UPDATE for OLPaneClass

DESCRIPTION:	Suspends window updates.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SUSPEND_UPDATE

RETURN:		carry set if window was suspended
		ax, cx, dx, bp destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/12/91		Initial version

------------------------------------------------------------------------------@

OLPaneSuspendUpdate	method OLPaneClass, MSG_GEN_VIEW_SUSPEND_UPDATE
	call	PaneGetWindow			;get window in di
	jz	couldnt
	call	WinSuspendUpdate
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
						;clear this now as we have
						;suspended
	and	ds:[di].OLPI_optFlags, not mask OLPOF_COULDNT_SUSPEND
	stc					;say handled
	ret
couldnt:					;don't destroy registers!
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	or	ds:[di].OLPI_optFlags, mask OLPOF_COULDNT_SUSPEND
	ret
OLPaneSuspendUpdate	endm

			

COMMENT @----------------------------------------------------------------------

ROUTINE:	PaneGetWindow

SYNOPSIS:	Gets window handle in di.

CALLED BY:	utility

PASS:		*ds:si -- pane

RETURN:		di -- window or null if none
		zero flag set if no window

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/28/91		Initial version

------------------------------------------------------------------------------@
PaneGetWindow	proc	near
	mov	di, ds:[si]			;can be called directly
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLPI_window
	tst	di
	ret
PaneGetWindow	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneUnSuspendUpdate -- 
		MSG_GEN_VIEW_UNSUSPEND_UPDATE for OLPaneClass

DESCRIPTION:	Suspends window updates.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SUSPEND_UPDATE

RETURN:		nothing
		ax, cx, dx, bp destroyed (not if called locally, though)

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/12/91		Initial version

------------------------------------------------------------------------------@
OLPaneUnSuspendUpdate	method OLPaneClass, MSG_GEN_VIEW_UNSUSPEND_UPDATE
	;
	; Couldn't suspend originally, unsuspending not so smart.  -cbh 12/26/92
	;
	mov	di, ds:[si]		
	add	di, ds:[di].Vis_offset	
	test	ds:[di].OLPI_optFlags, mask OLPOF_COULDNT_SUSPEND
	jnz	exit			

	call	PaneGetWindow			;get window in di
	jz	exit			;  and exit...
	call	WinUnSuspendUpdate
exit:
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	and	ds:[di].OLPI_optFlags, not mask OLPOF_COULDNT_SUSPEND
	ret				;don't put in destroy EC code
OLPaneUnSuspendUpdate	endm


			

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetContent -- 
		MSG_GEN_VIEW_SET_CONTENT for OLPaneClass

DESCRIPTION:	Opens a new output for a pane.  Sends all of the appropriate
		initialization things down to the output.  Closes the old one
		if there is one.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_CONTENT
		cx:dx	- new content handle

RETURN:		nothing
		ax, cx, dx, bp -- trashed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/22/89	Initial version

------------------------------------------------------------------------------@

OLPaneSetContent	method OLPaneClass, MSG_GEN_VIEW_SET_CONTENT
EC <	xchg	cx, bx				;get in bx:si		     >
EC <	xchg	dx, si							     >
EC <	call	ECCheckOD			;can be anything             >
EC <	xchg	cx, bx							     >
EC <	xchg	dx, si							     >
   
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	cmp	ds:[di].GVI_content.handle, cx	;see if already opened
	jne	checkExisting			;different OD, branch
	cmp	ds:[di].GVI_content.chunk, dx	;same guy?
	LONG	je	exit			;yes, don't do anything
	
checkExisting:
						; Since changing contents,
						; nuke ViewTargetInfo, as
						; we don't know what's
						; going on in the content
						; yet.
	push	ax, cx
	push	di
	segmov	es, ds
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	add	di, offset OLPI_targetInfo	; ZERO out ViewTargetInfo
	mov	cx, size ViewTargetInfo
	clr	al
	rep	stosb
	pop	di
	pop	ax, cx

	push	ax, cx, dx
	tst	ds:[di].GVI_content.handle	;see if currently an OD	    
	jz	openContent

	push	cx, dx
				; If already closed, don't send close method
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	afterClosed

	;
	; This used to be in the MSG_OL_PANE_CONTENT_CLOSING method for
	; the old pane window.
	;
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL	
	call	VisCallParentWithSelf
	
	; Release content of any exclusives we'd passed on to it earlier
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_attrs, mask OLPA_APP_TARGET
	pushf
	test	ds:[di].OLPI_attrs, mask OLPA_SYS_TARGET
	pushf
	test	ds:[di].OLPI_attrs, mask OLPA_APP_FOCUS
	pushf
	test	ds:[di].OLPI_attrs, mask OLPA_SYS_FOCUS
	jz	afterSysFocusReleased
	mov	ax, MSG_META_LOST_SYS_FOCUS_EXCL
	call	OLPaneSendToApp
afterSysFocusReleased:
	popf
	jz	afterAppFocusReleased
	mov	ax, MSG_META_LOST_FOCUS_EXCL
	call	OLPaneSendToApp
afterAppFocusReleased:
	popf
	jz	afterSysTargetReleased
	mov	ax, MSG_META_LOST_SYS_TARGET_EXCL
	call	OLPaneSendToApp
afterSysTargetReleased:
	popf
	jz	afterAppTargetReleased
	mov	ax, MSG_META_LOST_TARGET_EXCL
	call	OLPaneSendToApp
afterAppTargetReleased:

						; Tell output we're closing
	mov	ax, MSG_META_CONTENT_VIEW_CLOSING
	call	OLPaneSendToApp

	mov	ax, MSG_META_CONTENT_VIEW_WIN_CLOSED	
	call	OLPaneSendToApp			;send to old content
	
	; Tell the output to set its view OD to 0

afterClosed:
	clr	cx
	clr	dx
	mov	ax, MSG_META_CONTENT_SET_VIEW
	call	OLPaneSendToApp

	DoPop	dx, cx
	
openContent:
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	ds:[di].GVI_content.handle, cx	;else store new output OD
	mov	ds:[di].GVI_content.chunk, dx	
	push	si
	call	SendViewHandle			;send SET_VIEW method,
	pop	si				;  calc sizes of things
	;
	; Now, send the initial origin.
	; 
	call	GetXOrigin
	call	GetYOrigin
	call	SendNewOriginToOD
	
	;
	; Now, send the initial scale factor.
	;
	mov	ax, MSG_GEN_VIEW_GET_SCALE_FACTOR
	call	ObjCallInstanceNoLock
	mov	bx, bp
	call	SendNewScaleToOD
	
	;
	; Now tell the content that its window is created.
	; 
	DoPop	dx, cx, ax			;restore method number
	call	OLPaneWindowSetContent		;do window stuff
	
	;
	; If closed, don't send re-open method.  Otherwise, simulate a MSG_
	; VIS_OPEN.
	;		
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	afterReOpened
	
	;
	; Then, let contents know that the view
	; has been opened.
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_CONTENT_VIEW_OPENING
	call	OLPaneSendToApp
	
	mov	cl, mask VOF_GEOMETRY_INVALID	;mark the geometry invalid
	mov	dl, VUM_NOW
	call	VisMarkInvalid

;	call	InvalViewWindow			; moved back to content
	
	; Pass any exclusives that we have onto the new content
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_attrs, mask OLPA_SYS_TARGET
	pushf
	test	ds:[di].OLPI_attrs, mask OLPA_APP_TARGET
	pushf
	test	ds:[di].OLPI_attrs, mask OLPA_SYS_FOCUS
	pushf
	test	ds:[di].OLPI_attrs, mask OLPA_APP_FOCUS
	jz	afterAppFocusGrabbed
	mov	ax, MSG_META_GAINED_FOCUS_EXCL
	call	OLPaneSendToApp
afterAppFocusGrabbed:
	popf
	jz	afterSysFocusGrabbed
	mov	ax, MSG_META_GAINED_SYS_FOCUS_EXCL
	call	OLPaneSendToApp
afterSysFocusGrabbed:
	popf
	jz	afterAppTargetGrabbed
	mov	ax, MSG_META_GAINED_TARGET_EXCL
	call	OLPaneSendToApp
afterAppTargetGrabbed:
	popf
	jz	afterSysTargetGrabbed
	mov	ax, MSG_META_GAINED_SYS_TARGET_EXCL
	call	OLPaneSendToApp
afterSysTargetGrabbed:

afterReOpened:
exit:
	ret
	
OLPaneSetContent	endm
			


COMMENT @----------------------------------------------------------------------

ROUTINE:	SendViewHandle

SYNOPSIS:	Sends view handle to output object, to let content object
		know what it's view will be.  Also visibly builds any objects
		in the view OD.

CALLED BY:	OLPaneSpecBuild, OLSimplePaneSpecBuild

PASS:		*ds:si -- handle of view
		bp	- SpecBuildFlags:
			mask SBF_UPDATE_MODE
			mask SBF_IN_UPDATE_WIN_GROUP

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 5/89		Initial version

------------------------------------------------------------------------------@

SendViewHandle	proc	far
	class	OLPaneClass
	
	push	bp
	mov	cx, ds:[LMBH_handle]		;pass view's OD
	mov	dx, si
;
; This is not used in the content object, nor is documented for MSG_META_CONTENT_SET_VIEW!
; I will slit my wrists now.  -cbh 3/19/91
;
;	mov	di, ds:[si]			;point to instance
;	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
;	clr	bp				;start with no content flags
;	test	ds:[di].GVI_vertAttrs, mask GVDA_SCROLLABLE
;	jz	10$				;not scrollable, branch
;	or	bp, mask OLCNF_VERT_SCROLLABLE	;else pass this flag
;10$:
;	test	ds:[di].GVI_horizAttrs, mask GVDA_SCROLLABLE
;	jz	20$				;not scrollable, branch
;	or	bp, mask OLCNF_HORIZ_SCROLLABLE	;else pass this flag
;20$:
	mov	ax, MSG_META_CONTENT_SET_VIEW
	call	OLPaneSendToApp
	pop	bp				;Get SpecBuildFlags

	or	bp, mask SBF_WIN_GROUP or mask SBF_TREE_BUILD
	mov	cx, -1				;do full, non-optimized check
	call	GenCheckIfFullyEnabled
	jnc	30$				;not fully enabled, branch
	or	bp, mask SBF_VIS_PARENT_FULLY_ENABLED
30$:
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_GENERIC_CONTENTS	
	jz	exit				;not generic, exit
	mov	ax, MSG_SPEC_BUILD_BRANCH	;let's build everyone out!
	call	OLPaneSendToApp
exit:
	ret

SendViewHandle	endp


ViewCommon	ends


Obscure	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPaneSetInkType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the GenViewInkType for the passed object

CALLED BY:	GLOBAL
PASS:		cl - GenViewInkType	
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPaneSetInkType	method	OLPaneClass, MSG_GEN_VIEW_SET_INK_TYPE
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].GenView_offset
	cmp	cl, ds:[di].GVI_inkType
	je	exit
	mov	ds:[di].GVI_inkType, cl
	call	ObjMarkDirty
exit:
	.leave
	ret
OLPaneSetInkType	endp
	


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetColor -- 
		MSG_GEN_VIEW_SET_COLOR for OLPaneClass

DESCRIPTION:	Sets the view color.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_COLOR
		
		cl	- Red value
		ch	- WinColorFlags
		dl	- Green color
		dh	- Blue color

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
        The generic UI will change the generic color instance data whether
	we do anything or not, before our handler is executed.  This should
	probably be a MSG_SPEC... message whose definition spells out this
	information, but this can be saved for some later cleanup...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	9/ 2/91		Initial Version

------------------------------------------------------------------------------@

OLPaneSetColor	method dynamic	OLPaneClass, MSG_GEN_VIEW_SET_COLOR
	mov	di, ds:[di].OLPI_window		;get window handle
	tst	di
	jz	exit				;no window, nothing to do in
						;   specific UI
	push	si
	mov	ax, cx				;pass color in bx.ax
	mov	bx, dx
	mov	si, WIT_COLOR
	call	WinSetInfo
	pop	si
	call	InvalViewWindow			;invalidate the window, to
						;  get the correct background
exit:
	ret
OLPaneSetColor	endm

Obscure ends

ViewBuild	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneSetPaneFlags -- 
		MSG_SPEC_VIEW_SET_PANE_FLAGS for OLPaneClass

DESCRIPTION:	Sets pane attrs.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VIEW_SET_PANE_FLAGS
		cl	- OLPaneFlags to set
		ch	- OLPaneFlags to clear

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	9/12/92		Initial Version

------------------------------------------------------------------------------@

OLPaneSetPaneFlags	method dynamic	OLPaneClass, \
				MSG_SPEC_VIEW_SET_PANE_FLAGS
	or	ds:[di].OLPI_flags, cl
	not 	ch
	and	ds:[di].OLPI_flags, ch
	ret
OLPaneSetPaneFlags	endm

ViewBuild	ends

;----------------------------

ViewCommon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPaneUpdateFloatingScrollers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update floating scrollers

CALLED BY:	MSG_SPEC_VIEW_UPDATE_FLOATING_SCROLLERS
PASS:		*ds:si	= OLPaneClass object
RETURN:		cx	= TRUE/FALSE - close all windows before updating
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

FloatingScrollerState	record
	FSS_LEFT_JUSTIFY_UP_DOWN_SCROLLERS:1	; up/down on left side of view
	FSS_UP:1				; up scroller
	FSS_DOWN:1				; down scroller
	FSS_LEFT:1				; left scroller
	FSS_RIGHT:1				; right scroller
	FSS_VERT_AND_HORIZ_SCROLLABLE:1		; vert & horiz scrollable
FloatingScrollerState	end

OLPaneUpdateFloatingScrollers	method OLPaneClass, 
					MSG_SPEC_VIEW_UPDATE_FLOATING_SCROLLERS
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; first, close all the floating scroller windows

	jcxz	getState
	call	OLPaneCloseFloatingScrollers

getState:
	; get the FloatingScrollerState so we know what to open and close

	call	GetFloatingScrollerState	; bp = FloatingScrollerState

	; get the bounds for the floating scrollers

	call	GetPaneWinBounds
	add	ax, FLOATING_SCROLLER_MARGIN
	add	bx, FLOATING_SCROLLER_MARGIN
	sub	cx, FLOATING_SCROLLER_MARGIN
	sub	dx, FLOATING_SCROLLER_MARGIN

	; adjust bounds in case we have both vert & horiz scrollers

	push	cx, dx
	test	bp, mask FSS_VERT_AND_HORIZ_SCROLLABLE
	jz	10$
	sub	dx, FLOATING_SCROLLER_EXTRA_MARGIN
10$:
	test	bp, mask FSS_LEFT_JUSTIFY_UP_DOWN_SCROLLERS
	jz	checkUpDown

	mov	cx, ax				; up/down scroller on left side
	add	cx, FLOATING_Y_SCROLLER_WIDTH

checkUpDown:
	; open OLPI_upScroller if needed

	mov	di, offset OLPI_upScroller
	test	bp, mask FSS_UP
	call	openClose

	; open OLPI_downScroller if needed

	mov	di, offset OLPI_downScroller
	test	bp, mask FSS_DOWN
	call	openClose
	pop	cx, dx

	; adjust bounds in case we have both vert & horiz scrollers

	test	bp, mask FSS_VERT_AND_HORIZ_SCROLLABLE
	jz	checkLeftRight
	test	bp, mask FSS_LEFT_JUSTIFY_UP_DOWN_SCROLLERS
	jz	adjustRight
adjustLeft:
	add	ax, FLOATING_SCROLLER_EXTRA_MARGIN
	jmp	checkLeftRight
adjustRight:
	sub	cx, FLOATING_SCROLLER_EXTRA_MARGIN

checkLeftRight:
	; open OLPI_leftScroller if needed

	mov	di, offset OLPI_leftScroller
	test	bp, mask FSS_LEFT
	call	openClose

	; open OLPI_rightScroller if needed

	mov	di, offset OLPI_rightScroller
	test	bp, mask FSS_RIGHT
	call	openClose
done:
	.leave
	ret

openClose:
	jz	close
	call	OpenFloatingScrollerWindow
	retn
close:
	call	CloseFloatingScrollerWindow
	retn

OLPaneUpdateFloatingScrollers	endm

endif	; FLOATING_SCROLLERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFloatingScrollerState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine which scroller should be open and which should
		be closed.

CALLED BY:	OLPaneUpdateFloatingScrollers
PASS:		*ds:si	= OLPaneClass object
RETURN:		bp	= FloatingScrollerState
		ds:bx	= GenViewClass instance data
		ds:di	= OLPaneClass instance data
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

GetFloatingScrollerState	proc	near
	.enter

	clr	ax, cx			; ax = FloatingScrollerState (closed)
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLPI_window	; if OLPane window is not yet open,
	jz	done			;  then just close all scrollers

	; start by checking for up/down scroller of left side of view

	mov_tr	bp, ax
	mov	ax, HINT_LEFT_JUSTIFY_CHILDREN
	call	ObjVarFindData
	mov_tr	ax, bp
	jnc	checkScrollers

	ornf	ax, mask FSS_LEFT_JUSTIFY_UP_DOWN_SCROLLERS

checkScrollers:
	; check if up/down scrollers needed

	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GVI_vertAttrs, mask GVDA_DONT_DISPLAY_SCROLLBAR
	jnz	checkHoriz
	test	ds:[bx].GVI_vertAttrs, mask GVDA_SCROLLABLE
	jz	checkHoriz
	mov	bp, ds:[di].OLPI_vertScrollbar
	tst	bp			; *ds:bp = vertScrollbar
	jz	checkHoriz

	inc	cx			; cx = number of scrollable directions

	mov	bp, ds:[bp]
	add	bp, ds:[bp].Vis_offset	; ds:bp = OLScrollbar instance data
	test	ds:[bp].OLSBI_state, mask OLSS_AT_TOP
	jnz	checkDown
	ornf	ax, mask FSS_UP		; need up scroller
checkDown:
	test	ds:[bp].OLSBI_state, mask OLSS_AT_BOTTOM
	jnz	checkHoriz
	ornf	ax, mask FSS_DOWN	; need down scroller

checkHoriz:
	; create if left/right scrollers needed

	test	ds:[bx].GVI_horizAttrs, mask GVDA_DONT_DISPLAY_SCROLLBAR
	jnz	done
	test	ds:[bx].GVI_horizAttrs, mask GVDA_SCROLLABLE
	jz	done
	mov	bp, ds:[di].OLPI_horizScrollbar
	tst	bp			; *ds:bp = horizScrollbar
	jz	done
	jcxz	leftRight

	ornf	ax, mask FSS_VERT_AND_HORIZ_SCROLLABLE

leftRight:
	mov	bp, ds:[bp]
	add	bp, ds:[bp].Vis_offset	; ds:bp = OLScrollbar instance data
	test	ds:[bp].OLSBI_state, mask OLSS_AT_TOP
	jnz	checkRight
	ornf	ax, mask FSS_LEFT	; need left scroller
checkRight:
	test	ds:[bp].OLSBI_state, mask OLSS_AT_BOTTOM
	jnz	done
	ornf	ax, mask FSS_RIGHT	; need right scroller
done:
	mov	bp, ax			; bp = FloatingScrollerState

	.leave
	ret
GetFloatingScrollerState	endp

endif	; FLOATING_SCROLLERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPaneCloseFloatingScrollers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy (close) floating scrollers

CALLED BY:	OLPaneVisClose
PASS:		*ds:si	= OLPaneClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

OLPaneCloseFloatingScrollers	proc	far
	uses	di
	.enter

	mov	di, offset OLPI_upScroller
	call	CloseFloatingScrollerWindow
	mov	di, offset OLPI_downScroller
	call	CloseFloatingScrollerWindow
	mov	di, offset OLPI_leftScroller
	call	CloseFloatingScrollerWindow
	mov	di, offset OLPI_rightScroller
	call	CloseFloatingScrollerWindow

	.leave
	ret
OLPaneCloseFloatingScrollers	endp

endif	; FLOATING_SCROLLERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenFloatingScrollerWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open floating scroller window

CALLED BY:	OLPaneCreateFloatingScrollers
PASS:		*ds:si	= OLPaneClass object
		di	= OLPI_{up/down/left/right}Scroller
		ax	= left
		bx	= top
		cx	= right
		dx	= bottom
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

OpenFloatingScrollerWindow	proc	near
	push	bp
	mov	bp, 500
	xchg	di, bp
	call	ThreadBorrowStackSpace
	xchg	di, bp
	call	OpenFloatingScrollerWindowLow
	xchg	di, bp
	call	ThreadReturnStackSpace
	xchg	di, bp
	pop	bp
	ret
OpenFloatingScrollerWindow	endp

OpenFloatingScrollerWindowLow	proc	near
params	local	Rectangle	push	dx,cx,bx,ax
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	cx, ds:[bx].OLPI_window	; has the OLPI_window been opened yet?
	LONG jcxz done			; it's a normal jcxz in non-EC

	push	si, di
	mov	si, WIT_PARENT_WIN	; use parent of OLPI_window so we don't
	mov	di, cx			; have problems with modal dialogs
	call	WinGetInfo		; ax = parent window
	mov	cx, ax			; cx = parent window
	pop	si, di
	jcxz	done

	mov	di, ds:[bx][di]		; *ds:di = FloatingScroller object
	tst	di			; do we have a FloatingScroller object?
	jz	done

EC <	push	es, di, si						>
EC <	mov	si, di							>
EC <	segmov	es, <segment FloatingScrollerClass>, di			>
EC <	mov	di, offset FloatingScrollerClass			>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC OL_ERROR		; not a FloatingScroller	>
EC <	pop	es, di, si						>

	mov	bx, ds:[di]
	tst	ds:[bx].FSI_window	; window already open?
	jnz	update			; then just update image

NOFXIP <mov	bx, handle ScrollbarCommon				>
FXIP <	mov	bx, handle RegionResourceXIP				>
	call	MemLock

	push	bp, di
	call	GeodeGetProcessHandle	; Get owner for window
	push	bx			; layer ID to use
	push	bx			; owner to use
	push	cx			; parent window handle
	push	ax			; window region segment
	mov	bx, ds:[di]
	push	ds:[bx].FSI_windowRegion; window region offset
	push	ss:[params].R_bottom
	push	ss:[params].R_right
	push	ss:[params].R_top
	push	ss:[params].R_left
	mov	ax, (mask WCF_TRANSPARENT shl 8) or C_LIGHT_GRAY
	clr	bx			; bx.ax = color
	mov	bp, di
	mov	di, ds:[LMBH_handle]	; ^ldi:bp = expose OD
	movdw	cxdx, dibp		; ^lcx:dx = mouse OD
	clr	si			; si = WinPassFlags
	call	WinOpen
	pop	bp, di

	mov	di, ds:[di]
	mov	ds:[di].FSI_window, bx

NOFXIP <mov	bx, handle ScrollbarCommon				>
FXIP <	mov	bx, handle RegionResourceXIP				>
	call	MemUnlock
done:
	.leave
	ret

update:
	push	bp
	mov	di, ds:[bx].FSI_window
	clr	ax, bx
	mov	cx, ss:[params].R_right
	mov	dx, ss:[params].R_bottom
	clr	bp
	call	WinInvalReg
	pop	bp
	jmp	done
	
OpenFloatingScrollerWindowLow	endp

endif	; FLOATING_SCROLLERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseFloatingScrollerWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close floating scroller window

CALLED BY:	INTERNAL
PASS:		*ds:si	= OLPaneClass object
		di	= OLPI_{up/down/left/right}Scroller
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	8/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

CloseFloatingScrollerWindow	proc	near
	uses	bx,di
	.enter

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	bx, ds:[bx][di]		; *ds:bx = FloatingScroller object
	tst	bx
	jz	done

EC <	push	es, si							>
EC <	segmov	es, <segment FloatingScrollerClass>, di			>
EC <	mov	di, offset FloatingScrollerClass			>
EC <	mov	si, bx							>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC OL_ERROR		; not a FloatingScroller	>
EC <	pop	es, si							>

	clr	di
	mov	bx, ds:[bx]
	xchg	di, ds:[bx].FSI_window
	tst	di
	jz	done

	call	WinClose		; close the floating scroller window
done:
	.leave
	ret
CloseFloatingScrollerWindow	endp

endif	; FLOATING_SCROLLERS

ViewCommon	ends
