COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CWin (common code for several specific ui's)
FILE:		cwinPtr.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version

DESCRIPTION:

	$Id: cwinPtr.asm,v 2.129 95/06/14 23:22:10 ptrinh Exp $

-------------------------------------------------------------------------------@

WinOther segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinStartButton

DESCRIPTION:	To implement the SelectMyControlsOnly mechanism, we send
		MSG_STARTUP_GRAB to self, then send the method on to our
		children.

PASS:		*ds:si - instance data
		es - segment of OLWinClass
		ax - method
		cx, dx - ptr position
		bp - [ UIFunctionsActive | buttonInfo ]

RETURN:		Nothing

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
	Eric	8/89		More doc.

------------------------------------------------------------------------------@


OpenWinStartButton	proc	far
	class	OLWinClass
			
	;if we had begun the process of toggling menu navigation (i.e. ALT
	;had been pressed), we want to nuke it.  
	;
	; We must go up to an OLBaseWin in case we aren't an OLBaseWin, where
	; menu navigation is allowed
	
	call	WinOther_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_menuState, not mask OLWMS_TOGGLE_MENU_NAV_PENDING
	call	OpenClearToggleMenuNavPending
	
	;the user is beginning to interact with this window or its contents.
	;Initiate the SelectMyControlsOnly mechanism.

	push	ax, cx, dx, bp
	mov	ax, MSG_OL_WIN_STARTUP_GRAB
	call	WinOther_ObjCallInstanceNoLock
	pop	ax, cx, dx, bp

	;now send to the correct children

	GOTO	WinOther_ObjCallSuperNoLock_OLWinClass_Far

OpenWinStartButton	endp

WinOther	ends

;----------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinStartupGrab -- MSG_OL_WIN_STARTUP_GRAB

USED TO IMPLEMENT:	SelectMyControlsOnly mechanism (see top of file)

DESCRIPTION:	This procedure is called when:
			1) the mouse button has been pressed within the
			Visible window, we received the event through
			the implied grab. The user might be starting to
			use a gadget, such as a button. (The event has not
			yet been sent on to the child.)

			2) (menu windows) the mouse button was just pressed on
			the menu button for this menu window. This menu window
			was Opened, and now we expect the user to drag the
			mouse onto the window.

		Grab window & installed passive grab, so that we can tell when
		the mouse button(s) have been released. When that future event
		happens, we will remove our passive grab, and (if not a
		menu window in stay-up mode), will remove our window grab.

PASS:		*ds:si - instance data
		es - segment of OLWinClass
		ax - method
		cx, dx, bp - ?

RETURN:		Nothing

DESTROYED:	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version
	Eric	8/89		Documented, changes for menu windows.

------------------------------------------------------------------------------@


OpenWinStartupGrab	method dynamic	OLWinClass, MSG_OL_WIN_STARTUP_GRAB
	;for SelectMyControlsOnly mechanism:

					;if we haven't already
	test	ds:[di].OLWI_specState, mask OLWSS_GRABBED
	jnz	OWSG_50
					;mark as grabbed
	or	ds:[di].OLWI_specState, mask OLWSS_GRABBED
	mov	di, ds:[di].VCI_window	;fetch window handle

	call	VisAddButtonPostPassive	;Startup passive grab, so we
					;can tell when all buttons have
					;been released.
OWSG_50:
	ret
OpenWinStartupGrab	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinCheckIfInteractableObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if that is an interactable object

CALLED BY:	GLOBAL
PASS:		cx:dx - object
RETURN:		carry set if child
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinCheckIfInteractableObject	method	OLWinClass,
					MSG_META_CHECK_IF_INTERACTABLE_OBJECT
	.enter
CUAS <	cmp	cx, ds:[di].OLWI_sysMenu 			>
CUAS <	stc							>
CUAS <	je	exit						>
	clc
CUAS < exit:							>
	.leave
	ret
OpenWinCheckIfInteractableObject	endp

WinMethods	ends

;----------------------

WinOther	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinPrePassiveButton -- MSG_META_PRE_PASSIVE_BUTTON

DESCRIPTION:	Handler for Passive Button events (see CTTFM description,
		top of cwinClass.asm file.)

	(We know that REFM mechanism does not rely on this procedure, because
	REFM does not request a pre-passive grab.)

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

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
	Doug	4/89		Initial version

------------------------------------------------------------------------------@

OpenWinPrePassiveButton	method dynamic	OLWinClass, MSG_META_PRE_PASSIVE_BUTTON

	; Check to see if mouse is allowed to interact with this window or not.
	; Since we set up a pre-passive grab whenever the mouse is over us,
	; regardless of mouse grabs or modal status, we have to do this check
	; to make sure user presses can actually affect this window.
	;
	call	CheckIfInteractable
	jnc	exit			;If not allowed in window, exit

	;
	; Code added 10/22/90 to hopefully cover all cases where the user
	; clicks somewhere in or out of the window when we're in menu navigation
	; so that it will be turned off.
	;
	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask MAEF_OD_IS_MENU_RELATED
	jz	noMenuFocus			;menu does not have focus branch
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask HGF_APP_EXCL
	jz	noMenuFocus			;window is not focus win, branch
	push	cx, dx, bp
	mov	ax, MSG_VIS_VUP_RELEASE_MENU_FOCUS
	call	WinOther_ObjCallInstanceNoLock	 ;if menu has focus, release it
	pop	cx, dx, bp
	;					;fall thru to do anything else
	;					;  necessary (cbh 10/25/90)
noMenuFocus:

	;translate method into MSG_META_PRE_PASSIVE_START_SELECT etc. and
	;send to self. (See OpenWinPrePassStartSelect)

	mov	ax, MSG_META_PRE_PASSIVE_BUTTON
	call	OpenDispatchPassiveButton
exit:
	ret
OpenWinPrePassiveButton	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckIfInteractable

DESCRIPTION:	Utility routine to check & see if this object is allowed to
		interact with the mouse at this time.  Uses new boffo
		MSG_META_TEST_WIN_INTERACTIBILITY which takes into
		account grabs, modality, etc.

CALLED BY:	INTERNAL
		OpeWinPrePassiveButton
		OLDisplayControlPrePassiveButton
		OpenWinEnsureMouseNotActivelyTrespassing

PASS:		*ds:si	- windowed object

RETURN:		carry	- set if interactable, clear if not
		ax	- MRF_PROCESSED

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

CheckIfInteractable	proc	far	uses	cx, dx, bp, di
	class	VisCompClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bp, ds:[di].VCI_window

	;
	; New code to exit not-interactable if we don't find the silly window.
	; -cbh 11/ 6/92
	;
	tst_clc	bp
	jz	exit
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_META_TEST_WIN_INTERACTIBILITY
	call	GenCallApplication
exit:
	mov	ax, mask MRF_PROCESSED		; in case exiting
	.leave
	ret
CheckIfInteractable	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinPostPassiveButton -- MSG_META_POST_PASSIVE_BUTTON

DESCRIPTION:	Handler for Passive Button events
			;SMCO: button release comes through here, indicating
			;that user finished pressing on child gadget. If
			;not a menu in stay-up mode, we _END_GRAB.

		(This is subclassed by the OLMenuButton object,
		so that it can decide whether to drop its menu which
		is exiting stay-up mode.)
			;mechanisms: SMCO
			;SMCO: button release comes through here, indicating
			;that user finished pressing on child gadget. If
			;not a menu in stay-up mode, we _END_GRAB.
PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax - method
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
	Doug	4/89		Initial version

------------------------------------------------------------------------------@


OpenWinPostPassiveButton	method dynamic	OLWinClass,
						MSG_META_POST_PASSIVE_BUTTON

	;are any buttons pressed?

	test	bp, mask BI_B3_DOWN or mask BI_B2_DOWN or \
		    mask BI_B1_DOWN or mask BI_B0_DOWN
	jnz	OWPPB_90		;skip if so...

	;all released: end window grab & monitoring.

	push	cx, dx, bp
	clr	cx			;do not force release
	mov	ax, MSG_OL_WIN_END_GRAB
	call	WinOther_ObjCallInstanceNoLock
	pop	cx, dx, bp

OWPPB_90:

	mov	ax, MSG_META_POST_PASSIVE_BUTTON
	call	OpenDispatchPassiveButton
	ret
OpenWinPostPassiveButton	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinEnsureMouseNotActivelyTrespassing

DESCRIPTION:	Makes sure that this window doesn't have the window or
		mouse grabbed if it shouldn't.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

RETURN:
	Nothing

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

OpenWinEnsureMouseNotActivelyTrespassing method	OLWinClass, \
				MSG_META_ENSURE_MOUSE_NOT_ACTIVELY_TRESPASSING

	call	CheckIfInteractable	; Check to see if mouse can interact
					;	with this window
        jc     done                    ; if allowed to be in, done

	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	justEndGrab		; skip if not a menu...

	.warn	-private

	test	ds:[di].OLMWI_specState,  mask OMWSS_IN_STAY_UP_MODE

	.warn	@private

	jz	justEndGrab		; if not in stay-up mode, just end the
					; grab that it has.

					; If it IS in stay-up mode, then
					; force the darn thing down -- it
					; just doesn't make sense while a
					; modal window is up
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	jmp	short sendMethod

justEndGrab:
	; OTHERWISE, force a release of any window grab we have, & force
	; any gadget within us to release the mouse -- it is not our
	; right to have it anymore (Some modal window has just popped up)
	;
	mov	ax, MSG_OL_WIN_END_GRAB
	mov	cx, TRUE		;force release of exclusives

sendMethod:
        call    WinOther_ObjCallInstanceNoLock

done:
	clr	ax			; Return "MouseFlags" null
	ret
OpenWinEnsureMouseNotActivelyTrespassing endm



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinAllowGlobalTransfer

DESCRIPTION:	Release window grab for global quick-transfer.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

RETURN:
	Nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/89		Initial version for 2.0 quick-transfer

------------------------------------------------------------------------------@

OpenWinAllowGlobalTransfer method	OLWinClass, \
				MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER

	;
	; clear toggle menu naviagion pending flag here (in case we are a
	; OLBaseWin) and up to a OLBaseWin (in case we are not)
	;
	call	WinOther_DerefVisSpec_DI
	andnf	ds:[di].OLWI_menuState, not mask OLWMS_TOGGLE_MENU_NAV_PENDING
	call	OpenClearToggleMenuNavPending

	mov	cx, FALSE
	mov	ax, MSG_OL_WIN_END_GRAB
	call    WinOther_ObjCallInstanceNoLock

	mov	ax, MSG_FLOW_ALLOW_GLOBAL_TRANSFER
	clr	di
	GOTO	UserCallFlow

OpenWinAllowGlobalTransfer endm


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinEndGrab -- MSG_OL_WIN_END_GRAB

DESCRIPTION:	Ungrab window, uninstall post-passive grab.  Set active
		exclusive to 0, so that any previous owner is notified.
		This method should be called only in two cases:
		1) When all buttons have been released
		2) When the window is being closed.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax	- method
	cx	= TRUE to force release of all grabs (used by OpenWinVisClose)
	cx, dx	- ?
	bp	- ?

RETURN:
	Nothing
	NOTE:  may result in install of pre-passive mouse grab if mouse is
	       over window.

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


OpenWinEndGrab	method dynamic	OLWinClass, MSG_OL_WIN_END_GRAB
	class	OLWinClass

EC <	call	VisCheckVisAssumption	; Make sure vis data exists >

EC <	cmp	cx, FALSE						>
EC <	je	5$							>
EC <	cmp	cx, TRUE						>
EC <	ERROR_NE OL_ERROR						>
EC <5$:									>

					; see if base window is grabbed
	test	ds:[di].OLWI_specState, mask OLWSS_GRABBED
	jz	done			; if not, done

	tst	cx			;force release?
	jnz	10$			;skip if so...

	;This window has a current Window Grab. If this window
	;is a menu in stay-up-mode, allow Window Grab to persist,
	;so no other windows in the system get PTR events.
	;(OK to look at OLMenuWinClass instance data)

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	10$			;skip if not a menu...

	.warn	-private

	test	ds:[di].OLMWI_specState, mask OMWSS_IN_STAY_UP_MODE

	.warn	@private

	jnz	done			;skip if is menu in stay up mode...

10$:	;Kill Window Grab for this window

	ANDNF	ds:[di].OLWI_specState, not (mask OLWSS_GRABBED)
					;reset flag

	push	cx
	call	VisReleaseMouse		; if we happened to have had mouse,
					;	release it.
	call	VisReleaseKbd		; if we happened to have had kbd,
					;	release it.
	call	AbortMoveResize		; If moving/resizing window, abort out

					; Release passive grab
	call	VisRemoveButtonPostPassive
	pop	cx

	;Now we want to grab the gadget exclusive for this window group,
	;so that any menus of other related gadgets visually below us
	;will go away. We only do this if:
	;	cx = TRUE (we have been called from VisClose, and want to
	;		forcibly close all menus)
	;	- OR -
	;	OLWMS_HAS_MENU_IN_STAY_UP_MODE is FALSE. This means that
	;		we have not been notified that a child menu is in
	;		stay-up-mode, and so want to force the release of the
	;		gadget exclusive as the user releases the mouse.

	
	;For cascading menus, we do not want to take the gadget exclusive away
	;from the menus UNLESS it is requested to be taken by force.  This
	;allows the user to click-and-drag from the top menu button and
	;release on a menu button within the menu without having the menu
	;disappear (because none have actually been told to be in STAY_UP
	;mode yet.)  This is actually a problem with the standard Motif
	;menus (which hasn't been fixed yet).
	
	tst	cx			;force release?
if	 _CASCADING_MENUS
	jz	50$			;no, move on..
else	;_CASCADING_MENUS is FALSE
	jnz	40$			;skip if so...

	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_menuState, mask OLWMS_HAS_MENU_IN_STAY_UP_MODE
	jnz	50$			;skip if HAS menu in stay up mode...
endif	;_CASCADING_MENUS

40$:	;Take Gadget Exclusive: force release of any active element

	clr	cx			;grab active exclusive semaphore:
	clr	dx			;will notify menu and force it to
					;close up toute suite.
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	call	WinOther_ObjCallInstanceNoLock

50$:
	call	WinOther_DerefVisSpec_DI
	mov	di, ds:[di].VCI_window	; fetch window handle
EC <	tst	di							>
EC <	ERROR_Z	OL_ERROR						>

done:
	ret
OpenWinEndGrab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinAbortMoveResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	abort move/resize

CALLED BY:	MSG_OL_WIN_ABORT_MOVE_RESIZE

PASS:		*ds:si	= OLWinClass object
		ds:di	= OLWinClass instance data
		es 	= segment of OLWinClass
		ax	= MSG_OL_WIN_ABORT_MOVE_RESIZE

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/4/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinAbortMoveResize	method	dynamic	OLWinClass, MSG_OL_WIN_ABORT_MOVE_RESIZE
	call	AbortMoveResize
	ret
OpenWinAbortMoveResize	endp

WinOther	ends

WinCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinPtr -- MSG_META_PTR

DESCRIPTION:	Handler for PTR events
			;mechanisms: CPORB
			;CPORB: check is ptr over resize border, change image

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax 	- method
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
	Doug	4/89		Initial version
	Eric	8/89		Added CPORB mechanism - changes ptr image
				when over resize border in CUA/Motif

------------------------------------------------------------------------------@


OpenWinPtr	method dynamic	OLWinClass, MSG_META_PTR

if	_CUA_STYLE	;START of MOTIF specific code -------------------------
					;are select or move/copy functions
					;active?
	test	bp, (mask UIFA_SELECT or mask UIFA_MOVE_COPY) shl 8
	jnz	10$			;skip if so...

	call	OpenWinUpdatePtrImage	;change pointer image if necessary
					;does not change ax, cx, dx, bp
	call	WinCommon_DerefVisSpec_DI
10$:
endif		;END of MOTIF specific code -----------------------------------

	;if a keyboard resize is pending, start the resize in the direction
	;of mouse movement

	test	ds:[di].OLWI_moveResizeState, mask OLWMRS_RESIZE_PENDING
	jz	notResizePending
	mov	di, ds:[di].VCI_window
	tst	di
	jz	OWP_QuitProcessed
	push	es
	segmov	es, dgroup, ax			; es = dgroup
	mov	ax, es:[olScreenStart.P_x]	; ax, bx = start position
	mov	bx, es:[olScreenStart.P_y]
	pop	es
	call	WinUntransform			; convert to win coords
	sub	cx, ax				; cx = X deflection
	sub	dx, bx				; dx = Y deflection
	mov	ax, cx
	or	ax, dx
	tst	ax
	jz	OWP_QuitProcessed		; no deflection
	mov	ax, cx
	tst	ax
	jns	haveLeftRight
	neg	ax
haveLeftRight:
	mov	bx, dx
	tst	bx
	jns	haveUpDown
	neg	bx
haveUpDown:
	cmp	ax, bx
	jge	resizeLeftRight
CUAS <	mov	bl, mask OLWMRS_RESIZING_DOWN >
	cmp	dx, 3
	jge	haveResizeDir
CUAS <	mov	bl, mask OLWMRS_RESIZING_UP >
	cmp	dx, -3
	jle	haveResizeDir
	jmp	short OWP_QuitProcessed
resizeLeftRight:
CUAS <	mov	bl, mask OLWMRS_RESIZING_RIGHT >
	cmp	cx, 3
	jge	haveResizeDir
CUAS <	mov	bl, mask OLWMRS_RESIZING_LEFT >
	cmp	cx, -3
	jle	haveResizeDir
	jmp	short OWP_QuitProcessed

haveResizeDir:
CUAS <	call	OLWMRStartResize		; only handles one direction >
	jmp	short OWP_QuitProcessed

notResizePending:

	;very important: if in the middle of a move or resize operation,
	;ignore this pointer event - we don't want menu buttons to get
	;involved in this.

	test	ds:[di].OLWI_moveResizeState, OLWMRS_MOVING_OR_RESIZING_MASK
	jnz	OWP_QuitProcessed	; if so, quit out

if	_OL_STYLE	;START of OPEN LOOK specific code ---------------------
	test	bp, (mask UIFA_SELECT or mask UIFA_MOVE_COPY or \
						mask UIFA_FEATURES) shl 8
	jz	OWP_QuitProcessed	;skip if no button pressed

	test	ds:[di].OLWI_attrs, mask OWA_PINNABLE
	jz	OWP_90			;skip if not...

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	OWP_90			;skip if pinned already

	push	ax
	call	CheckIfInMarkBounds	;if in bounds, returns carry
	pop	ax
	jc	pointerIsOnMark		;skip if in bounds...

pointerIsNotOnMark:
	;Not on push pin: in menus, we want to restore pin image to "unpinned".

	test	ds:[di].OLWI_specState, mask OLWSS_DRAWN_PINNED
	jz	OWP_90			;skip if not drawn as pinned...

	ANDNF	ds:[di].OLWI_specState, not (mask OLWSS_DRAWN_PINNED)

;	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
;	jnz	OWP_90			;If unpinned, do nothing...

	;set state flag so that header is redrawn.

	mov	cl, mask OLWHS_HEADER_MARK_IMAGES_INVALID
	call	OpenWinHeaderMarkInvalid
	jmp	short OWP_QuitProcessed

pointerIsOnMark:
	; Ptr on top of push pin

	test	ds:[di].OLWI_specState, mask OLWSS_DRAWN_PINNED
	jnz	OWP_90			;skip if already drawn pinned...

	ORNF	ds:[di].OLWI_specState, mask OLWSS_DRAWN_PINNED

;	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
;	jnz	OWP_90				; If pinned, do nothing
;						; else draw it "pinned"

	;set state flag so that header is redrawn.

	push	cx, dx
	mov	cl, mask OLWHS_HEADER_MARK_IMAGES_INVALID
	call	OpenWinHeaderMarkInvalid
	pop	cx, dx
	jmp	OWP_QuitProcessed

OWP_90:
endif		;END of OPEN LOOK specific code -------------------------------

	; SEND PTR on down to children, but only if this window is grabbed,
	; indicating user has pressed in the window & is trying to interact
	; with it.

	; In Motif we must send all pointer events to the children so that text
	; objects can update their cursor

OLS <	call	WinCommon_DerefVisSpec_DI				   >
OLS <	test	ds:[di].OLWI_specState, mask OLWSS_GRABBED		   >
OLS <	jz	OWP_QuitProcessed	; if not grabbed, eat event here.  >
					; Else
	call	VisCallChildUnderPoint	; pass on to object under location
	ret

OWP_QuitProcessed:
						; show processed
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	ret

OpenWinPtr	endp



COMMENT @----------------------------------------------------------------------

PROCEDURE:	OpenWinUpdatePtrImage

DESCRIPTION:	This procedure changes the pointer image when it
		is over the resize border.

CALLED BY:	OpenWinPtr
		OpenWinStartSelect

PASS:		*ds:si - instance data
		ds:di - offset to master part instance data
		es - segment of OLWinClass
		ax 	- method
		cx, dx	- ptr position
		bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:		ax, cx, dx, si, ds, es = same

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version

------------------------------------------------------------------------------@


if	_CUA_STYLE	;START of CUA/MOTIF/PM specific code ---------

OpenWinUpdatePtrImage	proc	far

	push	ax, cx, dx, bp		;save pointer position and data

	mov	bl, ds:[di].OLWI_moveResizeState
	test	bl, OLWMRS_MOVING_OR_RESIZING_MASK
	jz	normalUpdate

	mov	cl, OLPI_MOVE
	test	bl, mask OLWMRS_MOVING
	LONG jnz	OWUPI_30
	andnf	bl, OLWMRS_RESIZING_MASK

if _OL_STYLE
	mov	cl, OLPI_RESIZE_UP_DIAG
	cmp	bl, mask OLWMRS_RESIZING_UR
	je	OWUPI_30		;skip if so...
	cmp	bl, mask OLWMRS_RESIZING_LL
	je	OWUPI_30		;skip if so...

	mov	cl, OLPI_RESIZE_DOWN_DIAG
;save bytes
;	cmp	bl, mask OLWMRS_RESIZING_LR
;	je	OWUPI_30		;skip if so...
;	cmp	bl, mask OLWMRS_RESIZING_UL
;	je	OWUPI_30		;skip if so...
endif

if _CUA_STYLE or _MAC
	mov	cl, OLPI_RESIZE_UPL_DIAG
	cmp	bl, mask OLWMRS_RESIZING_UP or mask OLWMRS_RESIZING_LEFT
	je	OWUPI_30		;skip if so...
	mov	cl, OLPI_RESIZE_UPR_DIAG
	cmp	bl, mask OLWMRS_RESIZING_UP or mask OLWMRS_RESIZING_RIGHT
	je	OWUPI_30		;skip if so...

	mov	cl, OLPI_RESIZE_DOWNL_DIAG
	cmp	bl, mask OLWMRS_RESIZING_DOWN or mask OLWMRS_RESIZING_LEFT
	je	OWUPI_30		;skip if so...
	mov	cl, OLPI_RESIZE_DOWNR_DIAG
	cmp	bl, mask OLWMRS_RESIZING_DOWN or mask OLWMRS_RESIZING_RIGHT
	je	OWUPI_30		;skip if so...

	mov	cl, OLPI_RESIZE_LEFT
	test	bl, mask OLWMRS_RESIZING_LEFT
	jnz	OWUPI_30		;skip if so...
	mov	cl, OLPI_RESIZE_RIGHT
	test	bl, mask OLWMRS_RESIZING_RIGHT
	jnz	OWUPI_30		;skip if so...

	mov	cl, OLPI_RESIZE_UP
	test	bl, mask OLWMRS_RESIZING_UP
	jnz	OWUPI_30		;skip if so...
	mov	cl, OLPI_RESIZE_DOWN
;saving bytes...
;	test	bl, mask OLWMRS_RESIZING_DOWN
;	jnz	OWUPI_30		;skip if so...
endif
	jmp	short OWUPI_30

normalUpdate:

	;If RESIZABLE then allow pointer to change over boundaries

MO <	push	bp			; Save button information	>
MO <	call	TestForMoveControl	;pass ds:di = specific instance >
MO <	pop	bp			; Recover button information	>
MO <	mov	bx, cx			; Save mouse xpos		>
MO <	mov	cl, OLPI_MOVE		; Assume using the move ptr	>
MO <	jnc	10$							>
MO <	test	bp, (mask UIFA_SELECT or mask UIFA_MOVE_COPY) shl 8	;is mouse button pressed? >
MO <	jnz	OWUPI_30		; Go chg ptr image, if moving	>
MO <10$:								>
MO <	mov	cx, bx			; Else restore mouse xpos	>

PMAN <	push	bp			; Save button information	>
PMAN <	call	TestForMoveControl	;pass ds:di = specific instance >
PMAN <	pop	bp			; Recover button information	>
PMAN <	mov	bx, cx			; Save mouse xpos		>
PMAN <	mov	cl, OLPI_MOVE		; Assume using the move ptr	>
PMAN <	jnc	10$							>
PMAN <	test	bp, (mask UIFA_SELECT or mask UIFA_MOVE_COPY) shl 8	;is mouse button pressed? >
PMAN <	jnz	OWUPI_30		; Go chg ptr image, if moving	>
PMAN <10$:								>
PMAN <	mov	cx, bx			; Else restore mouse xpos	>

	call	TestForResizeControl	;Test window bounds to see if is
					;in resize corner. Sets flags to
					;indicate which one.
	mov	cl, OLPI_NONE		;default: not over border;
					;	no override image requested
	jnc	OWUPI_30		;skip if not over border...

	;find correct resize image:

if _MOTIF or _PM	;-------------------------------------------------------
	mov	cl, OLPI_RESIZE_UPL_DIAG
	cmp	bx, mask XF_RESIZE_TOP or mask XF_RESIZE_LEFT
	je	OWUPI_30		;skip if so...
	mov	cl, OLPI_RESIZE_UPR_DIAG
	cmp	bx, mask XF_RESIZE_TOP or mask XF_RESIZE_RIGHT
	je	OWUPI_30		;skip if so...

	mov	cl, OLPI_RESIZE_DOWNL_DIAG
	cmp	bx, mask XF_RESIZE_BOTTOM or mask XF_RESIZE_LEFT
	je	OWUPI_30		;skip if so...
	mov	cl, OLPI_RESIZE_DOWNR_DIAG
	cmp	bx, mask XF_RESIZE_BOTTOM or mask XF_RESIZE_RIGHT
	je	OWUPI_30		;skip if so...

	mov	cl, OLPI_RESIZE_LEFT
	test	bx, mask XF_RESIZE_LEFT
	jnz	OWUPI_30		;skip if so...
	mov	cl, OLPI_RESIZE_RIGHT
	test	bx, mask XF_RESIZE_RIGHT
	jnz	OWUPI_30		;skip if so...

	mov	cl, OLPI_RESIZE_UP
	test	bx, mask XF_RESIZE_TOP
	jnz	OWUPI_30		;skip if so...
	mov	cl, OLPI_RESIZE_DOWN
;saving bytes...
;	test	bx, mask XF_RESIZE_BOTTOM
;	jnz	OWUPI_30		;skip if so...

else		;---------------------------------------------------------------
	mov	cl, OLPI_RESIZE_UP_DIAG	
	cmp	bx, mask XF_RESIZE_TOP or mask XF_RESIZE_RIGHT
	je	OWUPI_30		;skip if so...
	cmp	bx, mask XF_RESIZE_BOTTOM or mask XF_RESIZE_LEFT
	je	OWUPI_30		;skip if so...

	mov	cl, OLPI_RESIZE_DOWN_DIAG
	cmp	bx, mask XF_RESIZE_BOTTOM or mask XF_RESIZE_RIGHT
	je	OWUPI_30		;skip if so...
	cmp	bx, mask XF_RESIZE_TOP or mask XF_RESIZE_LEFT
	je	OWUPI_30		;skip if so...

	mov	cl, OLPI_RESIZE_HORIZ
	test	bx, mask XF_RESIZE_LEFT or mask XF_RESIZE_RIGHT
	jnz	OWUPI_30		;skip if so...

	mov	cl, OLPI_RESIZE_VERT
;saving bytes...
;	test	bx, mask XF_RESIZE_TOP or mask XF_RESIZE_BOTTOM
;	jnz	OWUPI_30		;skip if so...

endif		;---------------------------------------------------------------

OWUPI_30: ;tell the window sys which pointer image to use for the window

	push	di
	mov	ch, PIL_WINDOW		;indicate which level in the image
					;hierarchy we are changing
	mov	di, ds:[di].VCI_window	;fetch window to set on
	call	OpenSetPtrImage		;change image!
	pop	di

	pop	ax, cx, dx, bp		;recall pointer position and data
	ret
OpenWinUpdatePtrImage	endp

endif			;END of CUA/MOTIF/PM specific code ---------------



COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinStartSelect -- MSG_META_START_SELECT,
						MSG_META_START_MOVE_COPY

DESCRIPTION:	Handler for SELECT button pressed on base window.
		Raise window to front, make focus, if using point & click.

		IMPORTANT: if not starting a move or resize, don't grab
		the mouse!

			;First send method to kids, and if they don't handle
			;event, we begin move/resize.


PASS:
	*ds:si - instance data
	es - segment of OLWinClass

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
	Doug	4/89		Initial version

------------------------------------------------------------------------------@


OpenWinStartSelect	method dynamic	OLWinClass, MSG_META_START_SELECT, \
						    MSG_META_START_MOVE_COPY
	;First: update the mouse pointer image, in case we have not received
	;a MSG_META_PTR event recently.

CUAS <	call	OpenWinUpdatePtrImage					>

	;Startup SMCO mechanism, and send event on to children

	pushdw	cxdx
	call	OpenWinStartButton
	popdw	bxbp
	test	ax, mask MRF_SET_POINTER_IMAGE
	jnz	10$
	movdw	cxdx, bxbp		;restore cx and dx if not returning ptr
10$:

	test	ax, mask MRF_PROCESSED	;see if processed by child
	jnz	OWSS_90			;child processed event. Exit here.

	;Mouse press is in window background - no child took the event
	;exit menu navigation, if in progress.  
	;(Releases of menu are now handled by the menu's pre-passive button
	;handler, set up when menu navigation is started.  -cbh 10/22/90)
;
;	push	cx, dx
;	mov	ax, MSG_VIS_VUP_RELEASE_MENU_FOCUS
;	call	WinCommon_ObjCallInstanceNoLock
;	pop	cx, dx

;	;If "SELECT_ALWAYS_RAISES" isn't set, then
;	;raise now, & set as focus if selectable & click-to-type model
;					; es holds class, which is in dgroup
;					; test global property
;	call	FlowGetUIButtonFlags
;	test	al, mask UIBF_SELECT_ALWAYS_RAISES
;	jnz	OWSS_70			; If raise ALWAYS, we're done already

; Shouldn't need this, since pre-passive button should always catch this...
;	push	cx, dx
;	mov	ax, MSG_GEN_BRING_TO_TOP
;	call	WinCommon_ObjCallInstanceNoLock
;					; Raise to top, select, make active,
;					; all if window type allows
;	pop	cx, dx

;OWSS_70:

if DIALOGS_WITH_FOLDER_TABS
	call	WinCommon_DerefVisSpec_DI
	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW
	jbe	testMoveResize

	mov	ax, ds:[di].OLWI_titleBarBounds.R_bottom
	sub	ax, ds:[di].OLWI_titleBarBounds.R_top
	cmp	dx, ax
	ja	testMoveResize

	mov	ax, TEMP_OL_WIN_TAB_INFO
	call	ObjVarFindData
	jnc	testMoveResize

	clr	di
	cmp	cx, ds:[bx].OLWFTS_tabs[0].LS_end
	jb	gotTab

	inc	di
	cmp	cx, ds:[bx].OLWFTS_tabs[4].LS_end
	jb	gotTab

	inc	di
	cmp	cx, ds:[bx].OLWFTS_tabs[8].LS_end
	ja	testMoveResize

gotTab:
	shl	di, 1
	tst	ds:[bx].OLWFTS_tabPosition[di]
	jz	testMoveResize		;skip if already on top

	push	cx, dx
	mov	cx, di
	shr	cx, 1
	mov	ax, MSG_OL_DIALOG_WIN_RAISE_TAB
	call	ObjCallInstanceNoLock
	pop	cx, dx

testMoveResize:
endif


	;See if the user is initiating a move or resize operation:
	;check if the pointer is in the move/resize area. If is there,
	;grab the mouse, and save some state flags so that when we get
	;a DRAG event we can begin the move or resize. If we get an END_SELECT
	;instead, we just release the mouse grab.

	call	WinCommon_DerefVisSpec_DI
	call	TestForResizeControl	;pass ds:di = specific instance
	jc	isMoveResize		;skip if is resizing window...

	call	TestForMoveControl	;pass ds:di = specific instance
	jnc	OWSS_80			;skip if not moving window...

isMoveResize:
	;we might be starting to move or resize this window: save state flags
	;indicating which operation and direction, and grab mouse.
	;	al = mask of flags to set in OLWI_moveResizeState to
	;		indicate operation and direction	
	;	bx = move/resize flags for IM
	push	es
	push	ax
	segmov	es, dgroup, ax		;es = dgroup
	pop	ax
	or	ds:[di].OLWI_moveResizeState, al
					;set MOVING or RESIZING flags
	mov	es:[olXorFlags], bx	;Pass move/resize flags for IM
	pop	es
	call	VisGrabMouse		; if in window background, grab mouse >

	;STORE away Click position, in case a drag ensues (Stored in
	;screen start variable, temporarily, since not in use by anyone
	;else right now-- we're storing actually in window coords, but
	;we'll fix this in DRAG_SELECT)
	push	es
	segmov	es, dgroup, ax			;es = dgroup
	mov	es:[olScreenStart.P_x], cx
	mov	es:[olScreenStart.P_y], dx
	pop	es			;restore es
OWSS_80:
	mov	ax, mask MRF_PROCESSED	; show processed

OWSS_90:
	ret
OpenWinStartSelect	endp

WinCommon	ends
WinOther	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinDragSelect -- MSG_META_DRAG_SELECT, MSG_META_DRAG_MOVE_COPY

DESCRIPTION:	Handler for SELECT button being dragged on base window. If in
		previous START_SELECT determined that a move or resize operation
		would be valid, we start it now.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

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
	Doug	11/89		Code moved here from START_SELECT handler
	Eric	12/89		lots of rework

------------------------------------------------------------------------------@


OpenWinDragSelect	method dynamic	OLWinClass, MSG_META_DRAG_SELECT, \
						    MSG_META_DRAG_MOVE_COPY
	;see if MSG_META_START_SELECT initiated the move or resize operations
	;(i.e. grabbed mouse, but did not move or resize window yet)

	test	ds:[di].OLWI_moveResizeState, mask OLWMRS_MOVING
					;test instruction clears carry
	jnz	isMovingOrResizing	;skip if moving (CY=0)...

	test	ds:[di].OLWI_moveResizeState, OLWMRS_RESIZING_MASK
	stc				;flag: is resizing
	LONG	jz done			;skip if not resizing...

isMovingOrResizing:
	;Get mouse position value which was saved at MSG_META_START_SELECT.

	pushf				;save carry (move/resize) flag

	ANDNF	ds:[di].OLWI_moveResizeState,
					not mask OLWMRS_MOVE_RESIZE_PENDING
					;reset flag, so that END_SELECT does
					;not void this move/resize


	mov	di, [di].VCI_window	; Get window handle
EC <	push	bx							>
EC <	mov	bx, di							>
EC <	call	ECCheckWindowHandle	;make sure we have a window	>
EC <	pop	bx							>

	;now begin to PUSH ARGS for call to ImStartMoveResize:

	popf
	jnc	calcPosition		;skip if is move operation...

	;for resize operation, must pass min/max values

if 0	; let's see if this is too slow - brianc 9/18/92
;PrintMessage <Calc window resize min/max values! (Get rid of dummy values!)>
	mov	ax, 100
	push	ax			; Pass the minWidth
	mov	ax, 50
	push	ax			; Pass the minHeight
else
	mov	ax, MSG_VIS_COMP_GET_MINIMUM_SIZE
	call	ObjCallInstanceNoLock	; cx = min width, dx = min height
	push	cx			; Pass the minWidth
	push	dx			; Pass the minHeight
endif
	mov	ax, 4000h
	push	ax			; Pass the maxWidth
	mov	ax, 4000h		;can SAVE BYTES here
	push	ax			; Pass the maxHeight

calcPosition: ;get pointer position in document coords
	push	es
	segmov	es, dgroup, ax		; es = dgroup
	mov	ax, es:[olScreenStart.P_x]
	mov	bx, es:[olScreenStart.P_y]
	pop	es
	push	ax			;Pass the x offset in doc coords
	push	bx			;Pass the y offset in doc coords
	call	WinTransform	;convert to screen coordinate

	;store screen start position in global variable, until done.
	push	es, cx
	segmov	es, dgroup, cx
	mov	es:[olScreenStart.P_x], ax
	mov	es:[olScreenStart.P_y], bx
	pop	es, cx
	
	call	VisGetSize		;Get bounds in doc coords
	clr	ax
	clr	bx

if	_OL_STYLE	;START of OPEN LOOK specific code ---------------------
	;just a thin line
;	clr	bp			; rectangle, not a region
;	push	bp			;   (pass 0 address)
;	push	bp
	mov	bp, offset PrimaryResizeRegion
	mov	si, handle PrimaryResizeRegion
	push	si			; ^hsi:bp = region definition, push
	push	bp
endif		;END of OPEN LOOK specific code -------------------------------

if	_CUA_STYLE	;START of MOTIF specific code -------------------------

if	 _ROUND_THICK_DIALOGS
	mov	bp, offset RoundedPrimaryResizeRegion	;assume rounded border
	call	OpenWinShouldHaveRoundBorderFar		;destroys nothing
	jc	OWDS_78
endif	;_ROUND_THICK_DIALOGS
	
	mov	bp, offset PrimaryResizeRegion
					;assume is normal window

	push	di
	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_WIN_ICON
	jz	OWDS_77			;skip if is not window icon

	mov	bp, offset WinIconResizeRegion

OWDS_77:
	pop	di

if	 _ROUND_THICK_DIALOGS
OWDS_78:
endif	;_ROUND_THICK_DIALOGS
					; Get segment that regions are in
	mov	si, handle PrimaryResizeRegion
	push	si			; ^hsi:bp = region definition, push
	push	bp
endif		;END of MOTIF specific code -----------------------------------

	mov	bp, 0			; End on all buttons up
	push	es
	segmov	es, dgroup, si		; es = dgroup
	mov	si, es:[olXorFlags]	; Pass move/resize flags
	pop	es
	call	ImStartMoveResize	; Start the screen xor'ing

done:
	mov	ax, mask MRF_PROCESSED	; show processed
	ret

OpenWinDragSelect	endp

if _OL_STYLE

RESIZE_WIDTH	= 1

;resize region for GenPrimaries, etc...

FXIP<RegionResourceXIP	segment resource				>

PrimaryResizeRegion	label	Region
	word	PARAM_0, PARAM_1, PARAM_2-1, PARAM_3-1		;bounds

	word	PARAM_1-1,					EOREGREC
	word	PARAM_1+RESIZE_WIDTH-1, PARAM_0, PARAM_2-1,	EOREGREC
	word	PARAM_3-RESIZE_WIDTH-1
	word	    PARAM_0, PARAM_0+RESIZE_WIDTH-1
	word	    PARAM_2-RESIZE_WIDTH, PARAM_2-1,		EOREGREC
	word	PARAM_3-1, PARAM_0, PARAM_2-1,			EOREGREC
	word	EOREGREC

FXIP<RegionResourceXIP	ends				>

endif

if	_CUA_STYLE		;START of CUA/MOTIF specific code -----

RESIZE_WIDTH	= 5

;resize region for GenPrimaries, etc...

FXIP<RegionResourceXIP	segment resource				>

PrimaryResizeRegion	label	Region
	word	PARAM_0, PARAM_1, PARAM_2-1, PARAM_3-1		;bounds

	word	PARAM_1-1,					EOREGREC
	word	PARAM_1+RESIZE_WIDTH-1, PARAM_0, PARAM_2-1,	EOREGREC
	word	PARAM_3-RESIZE_WIDTH-1
	word	    PARAM_0, PARAM_0+RESIZE_WIDTH-1
	word	    PARAM_2-RESIZE_WIDTH, PARAM_2-1,		EOREGREC
	word	PARAM_3-1, PARAM_0, PARAM_2-1,			EOREGREC
	word	EOREGREC

if	 _ROUND_THICK_DIALOGS
; resize region for Primaries that have rounded windows

; This is drawn 5 pixels thick.  It would be difficult to make the width
; variable with rounded corners.

RoundedPrimaryResizeRegion	label	Region
	word	PARAM_0, PARAM_1, PARAM_2-1, PARAM_3-1		;bounds
	
	word	PARAM_1-1,					EOREGREC
	word	PARAM_1,
		    PARAM_0+4, PARAM_2-5,			EOREGREC
    	word	PARAM_1+1,
		    PARAM_0+2, PARAM_2-3,			EOREGREC
	word	PARAM_1+3,
		    PARAM_0+1, PARAM_2-2,			EOREGREC
	word	PARAM_1+4,
		    PARAM_0,   PARAM_2-1,			EOREGREC
	word	PARAM_1+5,
		    PARAM_0,   PARAM_0+5, PARAM_2-6, PARAM_2-1,	EOREGREC
	word	PARAM_3-7,
		    PARAM_0,   PARAM_0+4, PARAM_2-5, PARAM_2-1, EOREGREC
	word	PARAM_3-6,
		    PARAM_0,   PARAM_0+5, PARAM_2-6, PARAM_2-1,	EOREGREC
	word	PARAM_3-5,
		    PARAM_0,   PARAM_2-1,			EOREGREC
	word	PARAM_3-3,
		    PARAM_0+1, PARAM_2-2,			EOREGREC
	word	PARAM_3-2,
		    PARAM_0+2, PARAM_2-3,			EOREGREC
	word	PARAM_3-1,
		    PARAM_0+4, PARAM_2-5,			EOREGREC
	word	EOREGREC
	
endif	;_ROUND_THICK_DIALOGS

;Resize region for window icons (is need for when icon is moved)

WinIconResizeRegion	label	Region
	dw	0, 0, PARAM_2-1, PARAM_3-1			;bounds

	dw	-1,						EOREGREC
	dw	PARAM_3-1, 0, PARAM_2-1,			EOREGREC
	dw	EOREGREC


FXIP<RegionResourceXIP	ends				>

endif			;END of CUA/MOTIF specific code ---------------

WinOther	ends
WinCommon	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TestForMoveControl

DESCRIPTION:	This procedure tests the mouse pointer position to see if this
		event is the beginning of a window move operation.

CALLED BY:	OpenWinStartSelect, OpenWinUpdatePtrImage

PASS:		ds:*si	- object
		ds:di	- specific instance data
		es - segment of OLWinClass
		cx, dx	- ptr position

RETURN:		carry set if move operation
		al = mask to OR with OLWI_moveResizeState to indicate
				that we are moving
		bx = 0 (to keep symmetry with TestForResizeControl)
		cx, dx, ds, si, di = same

DESTROYED:	ax, bx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/89		Initial version

------------------------------------------------------------------------------@

if _OL_STYLE	;--------------------------------------------------------------
TestForMoveControl	proc	near
	test	ds:[di].OLWI_attrs, mask OWA_MOVABLE
	jz	notMoving		;skip if not movable...

	;If window is pinnable, see if mouse pointer is inside the mark icon
	;boundary. If so, we are not moving. Otherwise, we are moving.
	;OpenLook is so simple!

	push	di, cx, dx
	call	CheckIfInMarkBounds	;returns carry set if in bounds
	pop	di, cx, dx
	jc	notMoving		;skip if in bounds...

	mov	al, mask OLWMRS_MOVING or mask OLWMRS_MOVE_RESIZE_PENDING
	clr	bx
	stc
	ret

notMoving:
	clc
	ret
TestForMoveControl	endp
endif		;--------------------------------------------------------------

if _CUA_STYLE	;--------------------------------------------------------------
TestForMoveControl	proc	near
	class	OLWinClass

	test	ds:[di].OLWI_attrs, mask OWA_MOVABLE
	jz	notMoving		;skip if not movable...

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_WIN_ICON
	jnz	isMoving		;skip if window icon (entire icon is
					;move area)...

	call	MouseInTitleBounds?	;see if in bounds
	jnc	notMoving		;no, not moving

isMoving:
	mov	al, mask OLWMRS_MOVING or mask OLWMRS_MOVE_RESIZE_PENDING
	clr	bx
	stc				;RETURN: inside title area
	ret

notMoving:
	clc				;RETURN:  not inside resizing corner
	ret
TestForMoveControl	endp


			
endif 		;--------------------------------------------------------------




COMMENT @----------------------------------------------------------------------

ROUTINE:	MouseInTitleBounds?

SYNOPSIS:	Sees if mouse pointer in header title.

CALLED BY:	TestForMoveControl, OLBaseWinStartSelect

PASS:		ds:di  -- win SpecInstance
		cx, dx -- pointer position

RETURN:		carry set if in bounds

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/16/90		Initial version

------------------------------------------------------------------------------@

MouseInTitleBounds?	proc	near	uses	si, bp, cx, dx, ax, bx, di
	.enter

	;
	; If no title (OWA_HEADER is what'd you think we should use, but
	; OWA_TITLED seems to be what is really used), can't be in title
	; area
	;
	test	ds:[di].OLWI_attrs, mask OWA_TITLED
	jz	notInTitle		;no title, not in title area

if	_CUA_STYLE and (not _PM)

;	No title bars in maximized displays 

	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW
	jne	notADisplay
	test	ds:[di].OLWI_specState, mask OLWSS_MAXIMIZED
	jnz	notInTitle
notADisplay:
endif
	mov	bp, dx			;bp = Y coordinate
	push	cx			;save X coordinate

	call	OpenWinGetHeaderTitleBounds
					;get coordinates of title area
					;(header minus icons to left and right)
	pop	si			;si = X coordinate

	;first check for vertical component: (bp = Y coordinate)

	cmp	bp, bx
	jl	notInTitle		;skip if too high...
	cmp	bp, dx
	jge	notInTitle		;skip if too low...

	;now check for horizontal component: (si = X coordinate)

	cmp	si, ax
	jl	notInTitle		;skip if too far to the left...
	cmp	si, cx
	jge	notInTitle		;skip if too far to the right...
	stc				;else we're in title area
	jmp	short exit
	
notInTitle:
	clc				;not in title area
exit:
	.leave
	ret
MouseInTitleBounds?	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	TestForResizeControl

DESCRIPTION:	This procedure tests the mouse pointer position to see if this
		event is the beginning of a window resize operation.

CALLED BY:	OpenWinStartSelect, OpenWinUpdatePtrImage

PASS:		ds:*si	- object
		ds:di	- specific instance data
		es - segment of OLWinClass
		cx, dx	- ptr position

RETURN:		carry set if resize operation
		al = mask to OR with OLWI_moveResizeState to indicate that are resize
		bx = mask to stuff into olXorFlags (used by IM to draw xor box)
		cx, dx, ds, si, di = same

DESTROYED:	ah, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/89		Initial version

------------------------------------------------------------------------------@

if _OPEN_LOOK	;--------------------------------------------------------------

TestForResizeControl	proc	near
	push	di, cx, dx
	test	ds:[di].OLWI_attrs, mask OWA_RESIZABLE
	jz	CRC_90			;skip if not resizable...

	mov	bp, cx			;save mouse X position
	push	dx			;save mouse Y position
	call	VisGetSize		;get window edges in document coords
					;(does not trash si, di)
	pop	di			;di = mouse Y position

	sub	di, OLS_WIN_RESIZE_SEGMENT_LENGTH	; Is the pointer inside the top resize?
	jns	CRC_20			; If not, go check the bottom

	sub	bp, OLS_WIN_RESIZE_SEGMENT_LENGTH ; Check if it's in upper left corner
	jns	CRC_10
					; Set the approriate resizing flags
	mov	al, mask OLWMRS_RESIZING_UL or mask OLWMRS_MOVE_RESIZE_PENDING
	mov	bx, mask XF_RESIZE_LEFT or mask XF_RESIZE_TOP
	jmp	short CRC_80

CRC_10:
	add	bp, OLS_WIN_RESIZE_SEGMENT_LENGTH * 2
	cmp	bp, cx			; Check if it's in upper right corner
	jl	CRC_90			; If not, then must be moving window
					; Set the approriate resizing flags
	mov	al, mask OLWMRS_RESIZING_UR or mask OLWMRS_MOVE_RESIZE_PENDING
	mov	bx, mask XF_RESIZE_RIGHT or mask XF_RESIZE_TOP
	jmp	short CRC_80

CRC_20:					; Is the ptr in the bottom resize area?
	add	di, OLS_WIN_RESIZE_SEGMENT_LENGTH * 2
	cmp	di, dx
	jl	CRC_90			; skip if not...

	sub	bp, OLS_WIN_RESIZE_SEGMENT_LENGTH
					; Check if it's in lower right corner
	jns	CRC_30
					; Set the approriate resizing flags
	mov	al, mask OLWMRS_RESIZING_LL or mask OLWMRS_MOVE_RESIZE_PENDING
	mov	bx, mask XF_RESIZE_LEFT or mask XF_RESIZE_BOTTOM
	jmp	short CRC_80

CRC_30:
	add	bp, OLS_WIN_RESIZE_SEGMENT_LENGTH * 2
	cmp	bp, cx			; Check if it's in lower right corner
	jl	CRC_90			; skip if not...

					; Set the approriate resizing flags
	mov	al, mask OLWMRS_RESIZING_LR or mask OLWMRS_MOVE_RESIZE_PENDING
	mov	bx, mask XF_RESIZE_RIGHT or mask XF_RESIZE_BOTTOM

CRC_80:	;is resizing:
	pop	di, cx, dx
	stc				;RETURN: inside resizing
	ret

CRC_90:	;not resizing
	pop	di, cx, dx
	clc				;RETURN: not resizing
	ret
TestForResizeControl	endp

endif		;--------------------------------------------------------------

if _CUA_STYLE	;--------------------------------------------------------------

TestForResizeControl	proc	near
	class	OLWinClass

	push	cx, dx			;save position of mouse,
					;since caller must check for move start

	test	ds:[di].OLWI_attrs, mask OWA_RESIZABLE
	LONG jz	done			;skip if not resizable (cy=0)...

NKE <	cmp	ds:[di].OLWI_type, MOWT_DISPLAY_WINDOW			>
NKE <	je	done			;skip if GenDisplay (cy=0)...	>

	mov	ax, cx			;(ax, bx) = position of mouse
	mov	bx, dx
	call	VisGetSize		;Get window edges in document coords

	;FIRST SEE IF THE POINTER IS IN ONE OF THE FRAMES OF THE WINDOW:

	push	cx, dx, si, bp		;save size of total area
	push	ds
	mov	bp, segment idata	;get segment of core blk
	mov	ds, bp
	mov	si, ds:[resizeBarWidth]
	mov	bp, ds:[resizeBarHeight]
	pop	ds

	;
	; Calc inner right/bottom edges of the resize border
	sub	cx, si
	sub	dx, bp

	or	bx, bx
	js	notResizingPopCxDx	;skip if too high (is negative #)...
	cmp	bx, bp
	jl	CRS_10			;skip if in top frame border...
	cmp	bx, dx
	jge	CRS_10			;skip if in bottom frame border...

	or	ax, ax
	js	notResizingPopCxDx	;skip if too far left (is negative #)...
	cmp	ax, si
	jl	CRS_10			;skip if in left frame border...
	cmp	ax, cx
	jl	notResizingPopCxDx	;skip if not in right frame border - not
					;resize, MUST POP 2 ARGS)...
CRS_10:	;THE POINTER IS IN AT LEAST ONE OF THE FRAME BORDERS - see
	;which resize directions are selected.
	;First check for vertical component: (bx = Y coordinate)

	pop	cx, dx, si, bp		;get original size of area

	cmp	bx, CUAS_WIN_ICON_HEIGHT	;is pointer in the top resize area?
	jge	CRS_20			;skip if not...

	;pointer is in top resize area: set UP component = TRUE

	mov	dl, mask OLWMRS_RESIZING_UP or mask OLWMRS_MOVE_RESIZE_PENDING
	mov	bx, mask XF_RESIZE_TOP
	jmp	short CRS_50		;skip to check horizontal component...

CRS_20:	;vertical component: in bottom resize area?
	add	bx, CUAS_WIN_ICON_HEIGHT	;add height of border for comparison
	cmp	bx, dx
	jle	CRS_45			;skip if not...

	;pointer is in bottom resize border: set DOWN component = TRUE

	mov	dl, mask OLWMRS_RESIZING_DOWN or mask OLWMRS_MOVE_RESIZE_PENDING
	mov	bx, mask XF_RESIZE_BOTTOM
	jmp	short CRS_50

CRS_45:
	clr	dl
	clr	bx

CRS_50:	;now check for horizontal component: (si = X coordinate)
	cmp	ax, CUAS_WIN_ICON_WIDTH	;is pointer in the left resize area?
	jge	CRS_60			;skip if not...

	;pointer is in left resize area: set LEFT component = TRUE

	ORNF	dl, mask OLWMRS_RESIZING_LEFT or mask OLWMRS_MOVE_RESIZE_PENDING
	ORNF	bx, mask XF_RESIZE_LEFT
	jmp	short CRS_70		;skip to end...

CRS_60:	;horizontal component: in right resize area?
	add	ax, CUAS_WIN_ICON_WIDTH	;add width of border for comparison
	cmp	ax, cx
	jle	CRS_70			;skip to end if not...

	;pointer is in right resize area: set RIGHT component = TRUE

	ORNF	dl, mask OLWMRS_RESIZING_RIGHT or mask OLWMRS_MOVE_RESIZE_PENDING
	ORNF	bx, mask XF_RESIZE_RIGHT

CRS_70:	;if any of the above tests succeeded, return with carry set
	mov	al, dl			;al = OLWI_moveResizeState mask value
	test	al, OLWMRS_RESIZING_MASK ;test instruction clears carry flag
	jz	done			;skip if not resizing (CY=0)...

	stc

done:
	pop	cx, dx			;(cx, dx) = mouse position
	ret

notResizingPopCxDx:
	pop	cx, dx, si, bp		;clean up stack
	pop	cx, dx			;(cx, dx) = mouse position
	clc
	ret
TestForResizeControl	endp

endif		;--------------------------------------------------------------

WinCommon	ends
WinOther	segment resource		


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinStartMenu -- MSG_META_START_FEATURES

DESCRIPTION:	OpenLook-specific handler for MENU button pressed
		on base window - opens a free-standing POPUP menu.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax	- method
	cx, dx	- ptr position
	bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:
	Nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version

------------------------------------------------------------------------------@


OpenWinStartMenu	method dynamic	OLWinClass, MSG_META_START_FEATURES

	;do basic handling, sending to children

	call	OpenWinStartButton

if _OL_STYLE	;START of OPEN LOOK specific code -----------------------------

	test	ax, mask MRF_PROCESSED	;see if processed by child
	jnz	returnProcessed		;skip if so (was not in window bgrnd)...


	;is window pinnable?

	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_PINNABLE
	jz	checkForMenu		;skip if not...

	;Is pinnable: don't do menu function over it.

	call	CheckIfInMarkBounds	;if pinnable & in bounds, returns carry
	jc	returnProcessed		;skip if so...

checkForMenu: ;Do we have a menu?
	call	WinOther_DerefVisSpec_DI
	tst	ds:[di].OLWI_menu
	jnz	openMenu		;skip if have menu...

	push	cx, dx			;preserve mouse position
	call	OpenWinEnsureMenu	;try to create menu
	pop	cx, dx

openMenu:

;NO LONGER NECESSARY: POPUP MENU WILL GRAB THE GADGET EXCL FOR ITSELF. eds 4/90
;	;first grab the gadget exclusive, so that other menus drop.
;	;If we had a menu button, it would do this work itself.
;
;	push	cx, dx
;	mov	cx, ds:[LMBH_handle]
;	mov	dx, si				;grab GADGET EXCLUSIVE
;	mov	ax, MSG_VIS_TAKE_GADGET_EXCL	;so other menus close up
;	call	ObjCallInstanceNoLock		;send to self
;	pop	cx, dx

	call	VisQueryWindow		;get window handle in di
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	push	si
	mov	si, ds:[bx].OLWI_menu
	tst	si
	jz	OWSM_60			; if no menu, just quit

	mov	ax, cx			; Translate mouse position to Screen
	mov	bx, dx
	call	WinTransform
	mov	cx, ax
	mov	dx, bx

	mov	ax, MSG_OL_POPUP_ACTIVATE
	call	WinOther_ObjCallInstanceNoLock	;open the menu

OWSM_60:
	pop	si

returnProcessed:
	mov	ax, mask MRF_PROCESSED	; show processed
endif		;END of OPEN LOOK specific code -------------------------------

	ret
OpenWinStartMenu	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinEnsureMenu

DESCRIPTION:	OpenLook specific - ensures that a popup (not pull-down)
		menu has been constructed for this window if it uses one.

CALLED BY:	OpenWinStartMenu, when responding to MSG_META_START_MENU

PASS:
	*ds:si - window object

RETURN:
	(*ds:si).OLWI_menu	- set to menu object, if applicable for window

DESTROYED:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

------------------------------------------------------------------------------@


if _OPEN_LOOK	;START of OPENLOOK specific code -------------------------------

OpenWinEnsureMenu	proc	near
	call	WinOther_DerefVisSpec_DI
	tst	ds:[di].OLWI_menu
	jnz	done			;skip if already has menu...

	mov	ax, offset OLWI_menu

	test	ds:[di].OLWI_attrs, mask OWA_HAS_WIN_MENU
	jz	testForPopupMenu	;skip if no "WindowMenu"...

	;Copy generic branch under window, set w/one-way upward link. Will be
	;discarded on save.  Will save created chunk handle in OLWI_menu.

	mov	bx, handle WindowMenuResource
	mov	dx, offset WindowMenu
	call	FatalError
	;call	OpenWinCreateChildObject

	;update the "Close", "FullSize", "Restore", and "Quit" items
	;in this menu.

	call	OpenWinUpdateWindowMenuItems
	jmp	done

testForPopupMenu:
	test	ds:[di].OLWI_attrs, mask OWA_HAS_POPUP_MENU
	jz	done

	;Copy generic branch under window, set w/one-way upward link. Will be
	;discarded on save.  Will save created chunk handle in OLWI_menu.

	mov	bx, handle PopupMenuResource
	mov	dx, offset PopupMenu
	;call	OpenWinCreateChildObject
	call FatalError

done:
	ret
OpenWinEnsureMenu	endp

endif		;END of OPEN LOOK specific code -------------------------------


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinEndSimpleButton

DESCRIPTION:	Handler for mouse SELECT or MENU button released on base window.
		(Note that gadget with active mouse grab may have already
		handled event, then REPLAYed so we get it as MSG_META_BUTTON.)

			;button release may have been handed by gadget which
			;had (and released) active mouse grab, then event
			;was replayed, so here we are.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax	- method
	cx, dx	- ptr position
	bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:
	Nothing

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version

------------------------------------------------------------------------------@


OpenWinEndSimpleButton	method dynamic	OLWinClass, MSG_META_END_SELECT, \
						MSG_META_END_MOVE_COPY,
						MSG_META_END_FEATURES

CUAS <	call	OpenWinUpdatePtrImage	;restore pointer image to normal >
					;does not trash cx, dx

	call	OpenWinHandleEndMoveResize
if 	_OL_STYLE	;START of OPEN LOOK specific code ---------------------
	jc	OWES_90			; was move/resize, done

;WAS NOT MOVING OR RESIZING

	call	CheckIfInMarkBounds	; see if pin or window mark hit
	jnc	OWES_90			; skip if miss

	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_attrs, mask OWA_PINNABLE
	jz	OWES_80			;skip if was window mark

	;PUSHPIN has been released on: force menu into PINNED mode

	ANDNF	ds:[di].OLWI_specState, not (mask OLWSS_DRAWN_PINNED)

	mov	bp, TRUE		;pass flag: CLOSE if unpinning window.
	mov	ax, MSG_OL_POPUP_TOGGLE_PUSHPIN
	call	WinOther_ObjCallInstanceNoLock
	jmp	short OWES_90

OWES_80: ;CLOSE has been clicked
;NOTE: CLAYTON: see OpenWinEndSimple to handle select in OpenLook window mark

OWES_90:
endif		;END of OPEN LOOK specific code -------------------------------
	call	VisReleaseMouse		;if we had mouse grab, release it.
	mov	ax, mask MRF_PROCESSED	;show processed
	ret
OpenWinEndSimpleButton	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinHandleEndMoveResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle end of move/resize operation

CALLED BY:	INTERNAL
			OpenWinEndSimpleButton
			OLWMRKeyStopMoveResize

PASS:		*ds:si	= OLWinClass object
		cx, dx	= ptr position

RETURN:		carry set if move/resize operation stopped
			(now stopped)
		carry clear if move/resize wasn't in progress
			(can re-use mouse event)

DESTROYED:	if carry set
			ax, bx, cx, dx, di, bp
		if carry clear
			ax, bx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinHandleEndMoveResize	proc	far
	call	WinOther_DerefVisSpec_DI
					; See if moving or resizing
	test	ds:[di].OLWI_moveResizeState, OLWMRS_MOVING_OR_RESIZING_MASK
	jz	done			;skip if not.. (carry clear)

	;if a MSG_META_DRAG_SELECT has not yet arrived, void this operation

	test	ds:[di].OLWI_moveResizeState, mask OLWMRS_MOVE_RESIZE_PENDING
	jz	wasMovingOrResizing	;skip if it did arrive..

	ANDNF	ds:[di].OLWI_moveResizeState, not \
		(OLWMRS_MOVING_OR_RESIZING_MASK \
		or mask OLWMRS_MOVE_RESIZE_PENDING)
	clc				;indicate move/resize wasn't in progress
	jmp	done

wasMovingOrResizing:
	;END WINDOW MOVE/RESIZE OPERATION:

	mov	di, [di].VCI_window	; Get window handle
	tst	di
	jz	done			; if no window, can't click in it..
					;	(exit with carry clear)

	push	cx, dx
	call	ImStopMoveResize
	pop	ax, bx			;(ax, bx) = pointer position in
					;document coordinates
	call	WinTransform	;convert to screen coordinates
					;so can calculate movement distance
	push	es
	segmov	es, dgroup, di
	sub	ax, es:[olScreenStart.P_x]
	sub	bx, es:[olScreenStart.P_y]
	pop	es

	call	WinOther_DerefVisSpec_DI
	ORNF	ds:[di].OLWI_winPosSizeState, mask WPSS_HAS_MOVED_OR_RESIZED
					;set flag for OpenWinSaveState, so will
					;save new window position and size
					;in case application is shut-down.

	test	ds:[di].OLWI_moveResizeState, mask OLWMRS_MOVING
	jz	wasResizing		;skip if not moving

					;Clear moving flag
	ANDNF	ds:[di].OLWI_moveResizeState, not mask OLWMRS_MOVING

	mov	cx, ax			;See if moving any at all
	or	cx, bx
	jz	moveResizeStopped	;if not, skip work (exit w/carry set)

	;Move window instance bounds by (ax, bx) distance

	add	ds:[di].VI_bounds.R_left, ax
	add	ds:[di].VI_bounds.R_top, bx
	add	ds:[di].VI_bounds.R_right, ax
	add	ds:[di].VI_bounds.R_bottom, bx

					; Now move actual window
					; Use std method for doing this.
					; Some windows subclass this & do
					; things like keep the window on
					; screen.
	mov	ax, MSG_VIS_MOVE_RESIZE_WIN
	call	WinOther_ObjCallInstanceNoLock
	jmp	moveResizeStopped

wasResizing:
	;	ds:di = VisInstance

	mov	dl, ds:[di].OLWI_moveResizeState
					;get resizing direction info
	call	DoResizeBounds		;Make changes to appr. window edges
					;returns di, si = same
	and	ds:[di].OLWI_moveResizeState, not OLWMRS_RESIZING_MASK

	;Added 11/30/92 cbh to hopefully improve the current problem with
	;wrapping composites deep inside interactions.  (Commented out
	;to see if it's really needed, now that another bug is fixed. 11/30/92)

	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_INVAL_ALL_GEOMETRY
	call	WinOther_ObjCallInstanceNoLock

					; Now resize actual window, doing
					; any geometry changes required
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID \
					      or mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	mov	ax, MSG_VIS_MARK_INVALID
	call	WinOther_ObjCallInstanceNoLock
moveResizeStopped:
	stc
done:
	ret
OpenWinHandleEndMoveResize	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckIfInMarkBounds

DESCRIPTION:	This procedure tests if the mouse pointer is inside the
		OpenLook "mark" bounds. Examples of marks: Pushpin,
		Close Mark.

PASS:		*ds:si	= instance data for object
		cx, dx	= position of mouse pointer in window coords.

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	?			Initial Version
	Eric	1/90		general cleanup
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

if 	_OL_STYLE	;START of OPEN LOOK specific code ---------------------

CheckIfInMarkBounds	proc	far
	push	cx, dx
	call	WinOther_DerefVisSpec_DI

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_WIN_ICON
	jnz	miss			;skip if is an OLWinIconClass object...

	test	ds:[di].OLWI_attrs, mask OWA_PINNABLE or mask OWA_CLOSABLE
	jz	miss			;skip if not pinnable or closable...

	push	cx, dx, bp
	mov	bp, di
	call	OpenWinGetHeaderBounds	;get bounds for header
	add	ax, OLS_WIN_HEADER_MARK_X_POSITION ;set ax, bx = top left coord
	add	bx, OLS_WIN_HEADER_MARK_Y_POSITION ;for first mark.
	pop	cx, dx, bp
	sub	cx, ax			;see if left of mark
	jl	miss			;skip if so...
	sub	dx, bx			;see if above mark
	jl	miss			;skip if so...

	test	ds:[di].OLWI_attrs, mask OWA_PINNABLE
	jnz	pushpin			;skip if looking for pin...

	;we are testing for the Close mark

	cmp	cx, OLS_CLOSE_MARK_WIDTH
	jg	miss			;skip if not...
	cmp	dx, OLS_CLOSE_MARK_HEIGHT
	jg	miss			;skip if not...

hit:	
	stc
	jmp	done

pushpin:
	cmp	dx, OLS_PUSHPIN_HEIGHT
	jg	miss			;skip if not...

	test	ds:[di].OLWI_specState, mask OLWSS_PINNED
	jnz	isPinned

	cmp	cx, OLS_PUSHPIN_UNPINNED_WIDTH
	jle	hit
	jmp	short miss		;skip if not...

isPinned:
	cmp	cx, OLS_PUSHPIN_PINNED_WIDTH
	jle	hit			;skip if not...

miss:
	clc				; Return miss
done:
	pop	cx, dx
	ret

CheckIfInMarkBounds	endp

endif		;END of OPEN LOOK specific code -------------------------------


if 	_OL_STYLE	;START of OPEN LOOK specific code ---------------------

;DoResizeBounds: Change the appropriate window edges & clear the resizing flag.
;NOTE: the Motif resize mechanism is more appropriate for specific ui's that
;can resize in eight directions. See Eric for details.
;Pass:	ds:si = specific instance data for object (no kidding!)
;	ds:di = visible  instance data for object
;	dl = OLWinMoveResizeFlags for object

DoResizeBounds	proc	near
	test	dl, mask OLWMRS_RESIZING_UL
	jz	DRB_20			; skip if not
					; Clear resizing flag
	add	ds:[di].VI_bounds.R_left, ax
	add	ds:[di].VI_bounds.R_top, bx
	jmp	short done
DRB_20:
	test	dl, mask OLWMRS_RESIZING_UR
	jz	DRB_30			; skip if not

	add	ds:[di].VI_bounds.R_right, ax
	add	ds:[di].VI_bounds.R_top, bx
	jmp	short done

DRB_30:
	test	dl, mask OLWMRS_RESIZING_LL
	jz	DRB_40			; skip if not
					; Clear resizing flag
	add	ds:[di].VI_bounds.R_left, ax
	add	ds:[di].VI_bounds.R_bottom, bx
	jmp	done

DRB_40:
	test	dl, mask OLWMRS_RESIZING_LR
	jz	done			; skip if not

	add	ds:[di].VI_bounds.R_right, ax
	add	ds:[di].VI_bounds.R_bottom, bx
done:
	;
	; Some dumb error correction for negative sizing, which shouldn't
	; happen when the input manager is sizing/constraining correctly
	;
	push	cx
	mov	cx, ds:[di].VI_bounds.R_left
	cmp	cx, ds:[di].VI_bounds.R_right
	jle	70$			; reasonable bounds, branch
	mov	ds:[di].VI_bounds.R_right, cx
70$:
	mov	cx, ds:[di].VI_bounds.R_top
	cmp	cx, ds:[di].VI_bounds.R_bottom
	jle	80$			; reasonable bounds, branch
	mov	ds:[di].VI_bounds.R_bottom, cx
80$:
	pop	cx
	ret
DoResizeBounds	endp
endif		;END of OPEN LOOK specific code -------------------------------


if	_CUA_STYLE	;START of CUA/MOTIF specific code ------------

;DoResizeBounds: Change the appropriate window edges & clear the resizing flag.
;Pass:	ds:si = specific instance data for object (no kidding!)
;	ds:di = visible  instance data for object
;	dl = OLWinMoveResizeFlags for object

DoResizeBounds	proc	near
	class	OLWinClass

	;first test for an upward component in the resize

	test	dl, mask OLWMRS_RESIZING_UP
	jz	DRB_20			; skip if not

	add	ds:[di].VI_bounds.R_top, bx

DRB_20:	;now test for a downward component in the resize
	test	dl, mask OLWMRS_RESIZING_DOWN
	jz	DRB_30			; skip if not

	add	ds:[di].VI_bounds.R_bottom, bx

DRB_30: ;now test for a leftward component in the resize
	test	dl, mask OLWMRS_RESIZING_LEFT
	jz	DRB_40			; skip if not

	add	ds:[di].VI_bounds.R_left, ax

DRB_40: ;now test for a rightward component in the resize
	test	dl, mask OLWMRS_RESIZING_RIGHT
	jz	DRB_60			; skip if not

	add	ds:[di].VI_bounds.R_right, ax
DRB_60:
	;
	; Some dumb error correction for negative sizing, which shouldn't
	; happen when the input manager is sizing/constraining correctly
	;
	push	cx
	mov	cx, ds:[di].VI_bounds.R_left
	cmp	cx, ds:[di].VI_bounds.R_right
	jle	70$			; reasonable bounds, branch
	mov	ds:[di].VI_bounds.R_right, cx
70$:
	mov	cx, ds:[di].VI_bounds.R_top
	cmp	cx, ds:[di].VI_bounds.R_bottom
	jle	80$			; reasonable bounds, branch
	mov	ds:[di].VI_bounds.R_bottom, cx
80$:
	pop	cx
	ret
DoResizeBounds	endp

endif			;END of CUA/MOTIF specific code ---------------


COMMENT @----------------------------------------------------------------------

FUNCTION:	AbortMoveResize

DESCRIPTION:	If moving/resizing window, abort out.

CALLED BY:	OpenWinEndGrab

PASS:
	*ds:si	- Openlook window

RETURN:
	Nothing

DESTROYED:
	ax, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version
------------------------------------------------------------------------------@


AbortMoveResize	proc	far
	class	OLWinClass

	call	WinOther_DerefVisSpec_DI
					; See if moving or resizing
	test	ds:[di].OLWI_moveResizeState, OLWMRS_MOVING_OR_RESIZING_MASK or mask OLWMRS_RESIZE_PENDING
	jz	AMR_90		; skip if not
	push	bx, bp
	call	FinishMoveResize
	pop	bx, bp
AMR_90:
	ret
AbortMoveResize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishMoveResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	finish up after successful or aborted move/resize

CALLED BY:	INTERNAL
			AbortMoveResize
			OLWMRKeyAbortMoveResize

PASS:		*ds:si = OLWinClass object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/12/93		Broke out for common usage

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FinishMoveResize	proc	far
	;
	; clear flags
	;
	call	WinOther_DerefVisSpec_DI
	ANDNF	ds:[di].OLWI_moveResizeState, not \
		(OLWMRS_MOVING_OR_RESIZING_MASK \
		or mask OLWMRS_MOVE_RESIZE_PENDING \
		or mask OLWMRS_RESIZE_PENDING)
	;
	; stop XOR
	;
	call	ImStopMoveResize
	;
	; restore ptr image
	;
	mov	di, ds:[di].VCI_window
	tst	di
	jz	noWindow
	mov	cx, OLPI_NONE or (PIL_WINDOW shl 8)
	call	OpenSetPtrImage
noWindow:
	;
	; remove monitor
	;
	push	ds
;	segmov	ds, es				;es is no longer dgroup
	segmov	ds, dgroup, ax			;ds = dgroup
	PSem	ds, olMoveResizeMonitorSem, TRASH_AX_BX
	test	ds:[olMoveResizeMonitorFlags], mask OLMRMF_ACTIVE
	jz	noMon			;monitor gone
	mov	bx, offset olMoveResizeAbortMonitor
	mov	al, mask MF_REMOVE_IMMEDIATE
	call	ImRemoveMonitor
	mov	ds:[olMoveResizeMonitorFlags], 0
	;
	; restore previous mouse position if PF_DISEMBODIED_PTR or
	; PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE were previously set
	;
	test	ds:[olMoveResizeSavedPtrFlags], mask PF_DISEMBODIED_PTR or \
				mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE
	jz	noMouseRestore
	clr	di			;no window
	call	ImGetMousePos		;cx, dx = current mouse pos
	movdw	axbx, cxdx
	mov	cx, ds:[olMoveResizeSavedMousePos].P_x
	mov	dx, ds:[olMoveResizeSavedMousePos].P_y
	sub	cx, ax			;cx, dx = deflection
	sub	dx, bx
	mov	ax, MSG_VIS_VUP_BUMP_MOUSE
	clr	di
	call	UserCallFlow
noMouseRestore:
	;
	; restore previous PtrFlags
	;
	call	ImGetPtrFlags		;al = current PtrFlags
	mov	ah, al			;clear them all
					;set old PtrFlags
	mov	al, ds:[olMoveResizeSavedPtrFlags]
	call	ImSetPtrFlags
noMon:
	VSem	ds, olMoveResizeMonitorSem, TRASH_AX_BX
	pop	ds
	;
	; release grabs
	;
	call	VisReleaseMouse		;if we had mouse grab, release it.
	call	VisReleaseKbd		;if we had kbd grab, release it.
	mov	ax, MSG_FLOW_RELEASE_MOUSE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	UserCallFlow

	call	WinOther_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	done	
	;
	; Menus should release focus and then ensure active f/t
	; This is a fix for problem with moving/resizing pinned Express Menu.
	;
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	ObjCallInstanceNoLock
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	GOTO	UserCallApplication
done:
	ret
FinishMoveResize	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinPrePassStartSelect

DESCRIPTION:	Handler for SELECT button being pressed while we have a
		passive mouse grab. See the CTTFM/REFM mechanisms documented
		in the cwinClass.asm file.
			;mechanisms: CTTFM
			;CTTFM: we get this after it is translated and resent
			;by the MSG_META_PRE_PASSIVE_BUTTON handler above.
PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax	- method
	cx, dx	- ptr position
	bp	- [ UIFunctionsActive | buttonInfo ]

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
	Eric	8/89		Updated according to Tony's new UI methods

------------------------------------------------------------------------------@

OpenWinPrePassStartMoveCopy		method OLWinClass, \
					MSG_META_PRE_PASSIVE_START_MOVE_COPY

	;
	; If we're a menu, don't bring to the front just because the move-copy
	; button was pressed.   Probably we're in the middle of menu
	; navigation, possibly with a submenu up, and the user hit it by 
	; accident, in which case, just leave well alone.  -cbh 2/16/93
	;
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jnz	OpenWinFinishPrePassive

	FALL_THRU	OpenWinPrePassStartSelect

OpenWinPrePassStartMoveCopy		endm


OpenWinPrePassStartSelect	method OLWinClass, \
					MSG_META_PRE_PASSIVE_START_SELECT

	;
	; Added to hopefully keep menus from moving to the front when
	; menu navigation is in progress, could be a big mistake.  See
	; comment above as well.  -cbh 2/16/93
	;
	test	ds:[di].OLWI_specState, mask OLWSS_GRABBED
	jnz	OpenWinFinishPrePassive

	;Click-To-Type Focus Model. (NOTE FALL THROUGH FROM ABOVE)
	;Bring window to top in application layer, and make it the
	;FOCUS window if it is not a pinned menu.

	mov	ax, MSG_GEN_BRING_TO_TOP
	call	WinOther_ObjCallInstanceNoLock

OpenWinFinishPrePassive		label	far

	call	VisRemoveButtonPrePassive	;turn off CTTFM mechanism

	mov	ax, mask MRF_PROCESSED	; show processed, no event destruction
	ret
OpenWinPrePassStartSelect	endp

WinOther	ends

;----------------------

WinMethods	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinRawUnivEnter -- MSG_META_RAW_UNIV_ENTER

DESCRIPTION:	Process RAW_UNIV_ENTER for OLWinClass object. See comments
		at top of cwinClass.asm.
			;mechanisms: CTTFM, REFM
			;Received when ptr enters this window, or when covering
			;window which contains ptr goes away.

PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax - method

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
	Eric	8/89		Updated according to Tony's new UI methods

------------------------------------------------------------------------------@


OpenWinRawUnivEnter	method dynamic	OLWinClass, MSG_META_RAW_UNIV_ENTER
					;mark in universe
	;
	; Check to see if we've already gotten a VIS_CLOSE.  If so, do
	; nothing.  Ok'd by Doug.  dl 6/9/94
	;
	tst	ds:[di].VCI_window
	jz	done

	ornf	ds:[di].OLWI_specState, mask OLWSS_PTR_IN_RAW_UNIV

	call	VisAddButtonPrePassive	;startup CTTFM mechanisms.
done:
	ret

OpenWinRawUnivEnter	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OpenWinRawUnivLeave -- MSG_META_RAW_UNIV_LEAVE

DESCRIPTION:	Process RAW_UNIV_LEAVE for OLWinClass object. See comments
		at top of cwinClass.asm file.

			;mechanisms: CTTFM, REFM
			;Received when ptr leaves this window, or when covering
			;window opens which contains ptr.


PASS:
	*ds:si - instance data
	es - segment of OLWinClass

	ax - method

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
	Eric	8/89		Updated according to Tony's new UI methods

------------------------------------------------------------------------------@


OpenWinRawUnivLeave	method dynamic	OLWinClass, MSG_META_RAW_UNIV_LEAVE

					;mark NOT in universe
	andnf	ds:[di].OLWI_specState, not mask OLWSS_PTR_IN_RAW_UNIV

	; Iin most all cases, we can now remove the pre-passive grab, which
	; is used to detect when the mouse has been pressed INSIDE the window,
	; so that it may be raised.  If we're dealing with a menu in stay-up
	; mode, however, we must leave the pre-passive intact, so that it
	; will know that it has to decide to come down or pick up interaction
	; again when the mouse is pressed.

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU
	jz	continue		; skip if not a menu...

	.warn	-private

	test	ds:[di].OLMWI_specState,  mask OMWSS_IN_STAY_UP_MODE

	.warn	@private
	jnz	afterPrePassive

continue:
	;SPACE-SAVER: whether CTTFM or REFM, we want to remove pre-passive
	;grab, so do it here. (If CTTFM and press-release already occurred,
	;may have been removed already.)

	call	VisRemoveButtonPrePassive	;turn off mechanisms

afterPrePassive:

	ret

OpenWinRawUnivLeave	endp

WinMethods	ends

;----------------------

WinCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if clicks in this window should be ink or not.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 5/91	Initial version
	cbh	3/16/93		Title bar checking moved from OLMenuedWinClass

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinQueryIfPressIsInk	method	dynamic OLWinClass,
						MSG_META_QUERY_IF_PRESS_IS_INK

	test	ds:[di].OLWI_attrs, mask OWA_TITLED			
	jz	doneWithTitle
	call	MouseInTitleBounds?	;click in title bounds, no ink
	jc	noInk
doneWithTitle:

	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU or mask OWFA_IS_WIN_ICON
	jnz	noInk

	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask HGF_APP_EXCL
	jz	noFocus			;No object has the focus, so no ink,
					; dude.

inkAllowed:
	call	TestForResizeControl
	jc	noInk
	call	TestForMoveControl
	jc	noInk
	mov	ax, MSG_META_QUERY_IF_PRESS_IS_INK
	mov	di, offset OLWinClass
	GOTO	ObjCallSuperNoLock
noFocus:
	mov	ax, ATTR_GEN_WINDOW_ACCEPT_INK_EVEN_IF_NOT_FOCUSED
	call	ObjVarFindData
	jc	inkAllowed
noInk:
	mov	ax, IRV_NO_INK
	ret
OpenWinQueryIfPressIsInk	endp

WinCommon	ends

;----------------------

WinMethods	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenWinVisQueryIfObjectHandlesInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenWinVisQueryIfObjectHandlesInk	method	dynamic OLWinClass,
					MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_MENU or mask OWFA_IS_WIN_ICON
	jnz	exit
	test	ds:[di].OLWI_focusExcl.FTVMC_flags, mask HGF_APP_EXCL
	jz	noFocus			;No object has the focus, so no ink,
					; dude
inkAllowed:
	mov	ax, MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK
	mov	di, offset OLWinClass
	GOTO	ObjCallSuperNoLock
noFocus:
	mov	ax, ATTR_GEN_WINDOW_ACCEPT_INK_EVEN_IF_NOT_FOCUSED
	call	ObjVarFindData
	jc	inkAllowed
exit:
	ret
OpenWinVisQueryIfObjectHandlesInk	endp

WinMethods ends


KbdNavigation	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenWinKbdChar - MSG_META_KBD_CHAR handler for OLWinClass

DESCRIPTION:	handle keyboard move and resize of window

PASS:		*ds:si	= instance data for object
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:
		Although there is spui-conditional code here, this only
		works for CUA style spuis.  Up, down, left, right keys
		don't work well for diagonal resizing needed in OL style
		spuis.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/17/92	Initial version

------------------------------------------------------------------------------@

if _KBD_NAVIGATION	;------------------------------------------------------

OpenWinKbdChar	method dynamic	OLWinClass, MSG_META_KBD_CHAR

	;if not moving or resizing, let super handle

	test	ds:[di].OLWI_moveResizeState, mask OLWMRS_RESIZE_PENDING or \
						OLWMRS_MOVING_OR_RESIZING_MASK
	jz	notMoveResize

	;Don't handle state keys (shift, ctrl, etc).

	test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
	jnz	eatIt

	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	eatIt

	push	ax, ds, si, bp
	segmov	ds, cs
	mov	si, offset moveResizeKeysTable
	mov	ax, MOVE_RESIZE_KEYS_TABLE_SIZE
	call	FlowCheckKbdShortcut		; carry set if match
	mov	bx, si				; bx = table offset if match
	pop	ax, ds, si, bp
	jc	goodKey
eatIt:
	ret				; <-- EXIT HERE ALSO

notMoveResize:
;
; incorporated here from cwinExcl.asm
;
	mov	bx, ds:[di].OLWI_focusExcl.FTVMC_OD.handle
	tst	bx
	jz	callSuper
	mov	si, ds:[di].OLWI_focusExcl.FTVMC_OD.chunk
	clr	di
	GOTO	ObjMessage

callSuper:
	mov	di, offset OLWinClass
	GOTO	ObjCallSuperNoLock

goodKey:
	call	cs:[bx].moveResizeKeysRoutineTable
	ret

OpenWinKbdChar	endm

if DBCS_PCGEOS
	;p  a  c  s   c
	;h  l  t  h   h
	;y  t  r  f   a
	;s     l  t   r
	;
moveResizeKeysTable KeyboardShortcut \
	<0, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>,	;left
	<0, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>,	;right
	<0, 0, 0, 0, C_SYS_UP and mask KS_CHAR>,	;up
	<0, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>,	;down
	<0, 0, 1, 0, C_SYS_LEFT and mask KS_CHAR>,	;ctrl-left
	<0, 0, 1, 0, C_SYS_RIGHT and mask KS_CHAR>,	;ctrl-right
	<0, 0, 1, 0, C_SYS_UP and mask KS_CHAR>,	;ctrl-up
	<0, 0, 1, 0, C_SYS_DOWN and mask KS_CHAR>,	;ctrl-down
	<0, 0, 0, 0, C_SYS_ENTER and mask KS_CHAR>,	;stop move, resize
	<0, 0, 0, 0, C_SYS_ESCAPE and mask KS_CHAR>	;abort move, resize

else
	 ;P     C  S     C
	 ;h  A  t  h  S  h
	 ;y  l  r  f  e  a
	 ;s  t  l  t  t  r

moveResizeKeysTable	KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_LEFT>,	;left
	<0, 0, 0, 0, 0xf, VC_RIGHT>,	;right
	<0, 0, 0, 0, 0xf, VC_UP>,	;up
	<0, 0, 0, 0, 0xf, VC_DOWN>,	;down
	<0, 0, 1, 0, 0xf, VC_LEFT>,	;ctrl-left
	<0, 0, 1, 0, 0xf, VC_RIGHT>,	;ctrl-right
	<0, 0, 1, 0, 0xf, VC_UP>,	;ctrl-up
	<0, 0, 1, 0, 0xf, VC_DOWN>,	;ctrl-down
	<0, 0, 0, 0, 0xf, VC_ENTER>,	;stop move, resize
	<0, 0, 0, 0, 0xf, VC_ESCAPE>	;abort move, resize
endif

MOVE_RESIZE_KEYS_TABLE_SIZE = ($-moveResizeKeysTable)/(size KeyboardShortcut)

moveResizeKeysRoutineTable	nptr.near \
	OLWMRKeyLeft,	   		; VC_LEFT
	OLWMRKeyRight,			; VC_RIGHT
	OLWMRKeyUp,			; VC_UP
	OLWMRKeyDown,			; VC_DOWN
	OLWMRKeySmallLeft,	   	; Ctrl+VC_LEFT
	OLWMRKeySmallRight,		; Ctrl+VC_RIGHT
	OLWMRKeySmallUp,		; Ctrl+VC_UP
	OLWMRKeySmallDown,		; Ctrl+VC_DOWN
	OLWMRKeyStopMoveResize,		; VC_ENTER
	OLWMRKeyAbortMoveResize		; VC_ESCAPE
MOVE_RESIZE_KEYS_ROUTINE_TABLE_SIZE = length moveResizeKeysRoutineTable

.assert (size KeyboardShortcut eq size word)
.assert (MOVE_RESIZE_KEYS_ROUTINE_TABLE_SIZE eq MOVE_RESIZE_KEYS_TABLE_SIZE)

;
; XXX: make the OLWMRS_RESIZE_<blah> flags spui-dependent
;
OLWMRKeyLeft	proc	near
	mov	cx, -10
OLWMRKeyLeftCommon	label	near
	mov	dx, 0
	mov	bl, mask OLWMRS_RESIZING_LEFT
if _NIKE
	clr	bh			; no diagonal resizing
else
	mov	bh, mask OLWMRS_RESIZING_UP or mask OLWMRS_RESIZING_DOWN
endif
	GOTO	OLWMRKeyCommon
OLWMRKeyLeft	endp

OLWMRKeyRight	proc	near
	mov	cx, 10
OLWMRKeyRightCommon	label	near
	mov	dx, 0
	mov	bl, mask OLWMRS_RESIZING_RIGHT
if _NIKE
	clr	bh			; no diagonal resizing
else
	mov	bh, mask OLWMRS_RESIZING_UP or mask OLWMRS_RESIZING_DOWN
endif
	GOTO	OLWMRKeyCommon
OLWMRKeyRight	endp

OLWMRKeyUp	proc	near
	mov	dx, -10
OLWMRKeyUpCommon	label	near
	mov	cx, 0
	mov	bl, mask OLWMRS_RESIZING_UP
if _NIKE
	clr	bh			; no diagonal resizing
else
	mov	bh, mask OLWMRS_RESIZING_LEFT or mask OLWMRS_RESIZING_RIGHT
endif
	GOTO	OLWMRKeyCommon
OLWMRKeyUp	endp

OLWMRKeyDown	proc	near
	mov	dx, 10
OLWMRKeyDownCommon	label	near
	mov	cx, 0
	mov	bl, mask OLWMRS_RESIZING_DOWN
if _NIKE
	clr	bh			; no diagonal resizing
else
	mov	bh, mask OLWMRS_RESIZING_LEFT or mask OLWMRS_RESIZING_RIGHT
endif
	GOTO	OLWMRKeyCommon
OLWMRKeyDown	endp

OLWMRKeySmallLeft	proc	near
	mov	cx, -1
	GOTO	OLWMRKeyLeftCommon
OLWMRKeySmallLeft	endp

OLWMRKeySmallRight	proc	near
	mov	cx, 1
	GOTO	OLWMRKeyRightCommon
OLWMRKeySmallRight	endp

OLWMRKeySmallUp	proc	near
	mov	dx, -1
	GOTO	OLWMRKeyUpCommon
OLWMRKeySmallUp	endp

OLWMRKeySmallDown	proc	near
	mov	dx, 1
	GOTO	OLWMRKeyDownCommon
OLWMRKeySmallDown	endp

OLWMRStartResize	proc	far
	clr	bh			; not needed on RESIZE_PENDING
	clr	cx
	clr	dx
	call	OLWMRKeyCommon
	ret
OLWMRStartResize	endp

;
; pass:
;	*ds:si = OLWin class
;	bl - OLWMRS_* for desired direction
;	bh - OLWMRS_* for opposing directions
;	cx, dx = mouse deflection
;
OLWMRKeyCommon	proc	near

curMousePos	local	Point
newMousePos	local	Point
newDirection	local	byte
incomingMRFlags	local	byte
newMRFlags	local	byte
dummy		local	byte

	.enter
	mov	incomingMRFlags, bl
	mov	newDirection, 0		; no new direction to consider
	call	KN_DerefVisSpec_DI
	test	ds:[di].OLWI_moveResizeState, mask OLWMRS_RESIZE_PENDING
	LONG jz	notResizePending
doNewResize:
	;
	; resize was pending, restart XOR with correct flags
	;	bl = new OLWMRS_RESIZE_<blah> flags
	;
	call	ImStopMoveResize	; stop pending resize XOR
	andnf	ds:[di].OLWI_moveResizeState,
				not (mask OLWMRS_RESIZE_PENDING or \
					OLWMRS_RESIZING_MASK)
	ornf	bl, ds:[di].OLWI_moveResizeState
	mov	ds:[di].OLWI_moveResizeState, bl
	mov	newMRFlags, bl

	mov	di, [di].VCI_window	; Get window handle
EC <	mov	bx, di							>
EC <	call	ECCheckWindowHandle	; make sure we have a window	>

	;
	; now begin to PUSH ARGS for call to ImStartMoveResize:
	;

	;
	; push minimum bounds
	;
	push	bp			; save locals
	mov	ax, MSG_VIS_COMP_GET_MINIMUM_SIZE
	call	ObjCallInstanceNoLock	; cx = min width, dx = min height
	pop	bp			; restore locals
	push	bp			; save locals below ImStartMoveResize
					;	params on stack
	push	cx			; Pass the minWidth
	push	dx			; Pass the minHeight
	mov	ax, 4000h
	push	ax			; Pass the maxWidth
	mov	ax, 4000h		; can SAVE BYTES here
	push	ax			; Pass the maxHeight

	;
	; determine pointer X, Y position based on size of window and
	; current mouse position (in case we are already resizing one
	; side of the window)
	;
	call	VisGetSize		; cx, dx = right, bottom
	dec	cx
	dec	dx
	movdw	axbx, cxdx

	call	ImGetMousePos		; cx, dx = position (doc)
	mov	curMousePos.P_x, cx
	mov	curMousePos.P_y, dx
					; XXX: not relative to this thread?
	test	incomingMRFlags, mask OLWMRS_RESIZING_UP
	jz	notTop
	mov	dx, 1			; resize top, move mouse to top
	jmp	short mousePosCommon

notTop:
	test	incomingMRFlags, mask OLWMRS_RESIZING_DOWN
	jz	notBottom
	mov	dx, bx			; resize bottom, move mouse to bottom
	jmp	short mousePosCommon

notBottom:
	test	incomingMRFlags, mask OLWMRS_RESIZING_LEFT
	jz	notLeft
	mov	cx, 1			; resize left, move mouse to left
	jmp	short mousePosCommon

notLeft:
	test	incomingMRFlags, mask OLWMRS_RESIZING_RIGHT
	jz	notRight
	mov	cx, ax			; resize right, move mouse to right
	jmp	short mousePosCommon

notRight:

mousePosCommon:
	mov	newMousePos.P_x, cx	; cx, dx = desired mouse pos
	mov	newMousePos.P_y, dx
	push	cx			; pass the x offset in doc coords
	push	dx			; pass the y offset in doc coords
	;
	; save start position for end of move, resize so we can actually
	; perform the operation
	;
	movdw	axbx, cxdx		; ax, bx = desired mouse position
	call	WinTransform		; convert to screen coordinates
					; store for end
	test	newDirection, mask OLWMRS_RESIZING_UP or \
					mask OLWMRS_RESIZING_DOWN
	jnz	updateStartY
updateStartXY:
	push	es, bx
	segmov	es, dgroup, bx
	mov	es:[olScreenStart.P_x], ax
	pop	es, bx
	test	newDirection, mask OLWMRS_RESIZING_LEFT or \
					mask OLWMRS_RESIZING_RIGHT
	jnz	afterUpdateStart
updateStartY:
	push	es, ax
	segmov	es, dgroup, ax		; es = dgroup
	mov	es:[olScreenStart.P_y], bx
	pop	es, ax
afterUpdateStart:
	;
	; move the mouse pointer itself to the new position
	;
					; cx, dx = desired mouse position (doc)
					; ax, bx = current mouse position (doc)
	sub	cx, curMousePos.P_x
	sub	dx, curMousePos.P_y
	push	bp			; save locals
	mov	ax, MSG_OL_WIN_TURN_ON_AND_BUMP_MOUSE
	call	ObjCallInstanceNoLock	; move mouse to window edge
	pop	bp			; restore locals
	;
	; compute bottom and right bounds of XOR region
	;
	call	VisGetSize		; bottom, right bounds in doc coords
					;	(cx, dx)
	test	newMRFlags, mask OLWMRS_RESIZING_RIGHT
	jz	rBoundOkay
	mov	cx, newMousePos.P_x	; use new mouse X instead
rBoundOkay:
	test	newMRFlags, mask OLWMRS_RESIZING_DOWN
	jz	bBoundOkay
	mov	dx, newMousePos.P_y	; use new mouse Y instead
bBoundOkay:
	;
	; pass XOR region specification
	;
if	_OL_STYLE	;START of OPEN LOOK specific code ---------------------
	;just a thin line
	clr	ax			; rectangle, not a region
	push	ax			;   (pass 0 address)
	push	ax
endif		;END of OPEN LOOK specific code -------------------------------

if	_CUA_STYLE	;START of MOTIF specific code -------------------------

if	 _ROUND_THICK_DIALOGS
	mov	ax, offset RoundedPrimaryResizeRegion	;assume rounded border
	call	OpenWinShouldHaveRoundBorderFar		;destroys nothing
	jc	wasRounded
endif	;_ROUND_THICK_DIALOGS

	mov	ax, offset PrimaryResizeRegion
					;assume is normal window
	push	di			; save window handle
	call	KN_DerefVisSpec_DI
	test	ds:[di].OLWI_fixedAttr, mask OWFA_IS_WIN_ICON
	jz	notIcon			;skip if is not window icon

	mov	ax, offset WinIconResizeRegion

notIcon:
	pop	di			; restore window handle

if	 _ROUND_THICK_DIALOGS
wasRounded:
endif	;_ROUND_THICK_DIALOGS
					; Get resource that regions are in
	mov	bx, handle PrimaryResizeRegion
	push	bx			; ^hbx:ax = region definition, push
	push	ax
endif		;END of MOTIF specific code -----------------------------------
	;
	; setup and pass flags
	;
	push	di			; save window handle
	call	KN_DerefVisSpec_DI
	mov	al, ds:[di].OLWI_moveResizeState
	pop	di			; restore window handle
					; si = initial XorFlags
;	mov	si, mask XF_END_MATCH_ACTION
;no end on button action
	mov	si, mask XF_NO_END_MATCH_ACTION
	test	al, mask OLWMRS_RESIZING_LEFT
	jz	71$
	ornf	si, mask XF_RESIZE_LEFT
71$:
	test	al, mask OLWMRS_RESIZING_RIGHT
	jz	72$
	ornf	si, mask XF_RESIZE_RIGHT
72$:
	test	al, mask OLWMRS_RESIZING_UP
	jz	73$
	ornf	si, mask XF_RESIZE_TOP
73$:
	test	al, mask OLWMRS_RESIZING_DOWN
	jz	74$
	ornf	si, mask XF_RESIZE_BOTTOM
74$:
	;
	; compute top and left bounds of XOR region
	;
	clr	ax			; top, left of bounds
	test	newMRFlags, mask OLWMRS_RESIZING_LEFT
	jz	lBoundOkay
	mov	ax, newMousePos.P_x	; use new mouse X instead
lBoundOkay:
	clr	bx
	test	newMRFlags, mask OLWMRS_RESIZING_UP
	jz	tBoundOkay
	mov	bx, newMousePos.P_y	; use new mosue Y instead
tBoundOkay:
	;
	; finally, call ImStartMoveResize
	;
;	mov	bp, 0x0080		; end on any press
;no end on button action
	mov	bp, 0
	call	ImStartMoveResize	; Start the screen xor'ing
	pop	bp			; restore locals
	;
	; set pointer image based on movement
	;	si = XorFlags
	;	di = window
	;
	andnf	si, XOR_RESIZE_ALL
	mov	cl, OLPI_MOVE		; assume move
	tst	si
	jz	havePtr
if _MOTIF or _PM	;-------------------------------------------------------
	mov	cl, OLPI_RESIZE_UPL_DIAG
	cmp	si, mask XF_RESIZE_TOP or mask XF_RESIZE_LEFT
	je	havePtr			;skip if so...
	mov	cl, OLPI_RESIZE_UPR_DIAG
	cmp	si, mask XF_RESIZE_TOP or mask XF_RESIZE_RIGHT
	je	havePtr			;skip if so...

	mov	cl, OLPI_RESIZE_DOWNL_DIAG
	cmp	si, mask XF_RESIZE_BOTTOM or mask XF_RESIZE_LEFT
	je	havePtr			;skip if so...
	mov	cl, OLPI_RESIZE_DOWNR_DIAG
	cmp	si, mask XF_RESIZE_BOTTOM or mask XF_RESIZE_RIGHT
	je	havePtr			;skip if so...

	mov	cl, OLPI_RESIZE_LEFT
	test	si, mask XF_RESIZE_LEFT
	jnz	havePtr			;skip if so...
	mov	cl, OLPI_RESIZE_RIGHT
	test	si, mask XF_RESIZE_RIGHT
	jnz	havePtr			;skip if so...

	mov	cl, OLPI_RESIZE_UP
	test	si, mask XF_RESIZE_TOP
	jnz	havePtr			;skip if so...
	mov	cl, OLPI_RESIZE_DOWN
;saving bytes...
;	test	si, mask XF_RESIZE_BOTTOM
;	jnz	havePtr			;skip if so...

else		;---------------------------------------------------------------
	mov	cl, OLPI_RESIZE_UP_DIAG	
	cmp	si, mask XF_RESIZE_TOP or mask XF_RESIZE_RIGHT
	je	havePtr			;skip if so...
	cmp	si, mask XF_RESIZE_BOTTOM or mask XF_RESIZE_LEFT
	je	havePtr			;skip if so...

	mov	cl, OLPI_RESIZE_DOWN_DIAG
	cmp	si, mask XF_RESIZE_BOTTOM or mask XF_RESIZE_RIGHT
	je	havePtr			;skip if so...
	cmp	si, mask XF_RESIZE_TOP or mask XF_RESIZE_LEFT
	je	havePtr			;skip if so...

	mov	cl, OLPI_RESIZE_HORIZ
	test	si, mask XF_RESIZE_LEFT or mask XF_RESIZE_RIGHT
	jnz	havePtr			;skip if so...

	mov	cl, OLPI_RESIZE_VERT
;saving bytes...
;	test	si, mask XF_RESIZE_TOP or mask XF_RESIZE_BOTTOM
;	jnz	havePtr			;skip if so...

endif		;---------------------------------------------------------------

havePtr:
	mov	ch, PIL_WINDOW
	call	OpenSetPtrImage
	jmp	short done		; don't resize on first press

notResizePending:
	;
	; combine new resize direction with any existing one
	;
					; is one of the opposite directions
					;	set?
	test	ds:[di].OLWI_moveResizeState, bh
	jz	bumpMouseNow		; no, do our same direction resize
	mov	al, bh
	xor	al, OLWMRS_RESIZING_MASK
					; is one of our directions already set?
	test	ds:[di].OLWI_moveResizeState, al
	jnz	bumpMouseNow		; yes, just move in desired direction
	mov	newDirection, bl	; save new direction
	mov	ah, ds:[di].OLWI_moveResizeState
	andnf	ah, bh			; ah = current opposite direction
	ornf	bl, ah			; bl = new direction + current direction
	jmp	doNewResize

bumpMouseNow:
	push	bp			; save locals
	mov	ax, MSG_OL_WIN_TURN_ON_AND_BUMP_MOUSE
	call	ObjCallInstanceNoLock
	pop	bp			; restore locals
done:
	.leave
	ret
OLWMRKeyCommon	endp

OLWMRKeyAbortMoveResize	proc	near
	call	FinishMoveResize
	ret
OLWMRKeyAbortMoveResize	endp

OLWMRKeyStopMoveResize	proc	near

	mov	di, ds:[di].VCI_window
	tst	di
	jz	releaseGrabs
	mov	cx, OLPI_NONE or (PIL_WINDOW shl 8)
	call	OpenSetPtrImage		;turn off any move/resize cursor

	call	ImGetMousePos		;cx, dx = mouse pos in doc coords
	call	OpenWinHandleEndMoveResize

releaseGrabs:
	call	KN_DerefVisSpec_DI
	call	FinishMoveResize	;finish up
	ret
OLWMRKeyStopMoveResize	endp


endif	;----------------------------------------------------------------------

KbdNavigation	ends
