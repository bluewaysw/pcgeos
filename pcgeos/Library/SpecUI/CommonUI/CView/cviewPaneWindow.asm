COMMENT @-----------------------------------------------------------------------


	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/View
FILE:		viewPaneWindow.asm

ROUTINES:
	Name			Description
	----			-----------
    INT TestIfMouseImpliedOrActiveInPaneWindow 
				Tests to see if the mouse is actually
				active within the pane window (If not, then
				it must be active on the border of the
				pane) At least for the moment, calls
				superclass to do stuff if on the border,
				before returning.

    INT OLPaneWindowSetContent  Opens a new OD.  Sends whatever is
				necessary to simulate a view coming up.

    INT ViewEnabled?            Returns whether view is enabled or not.

    MTD MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK 
				This method handler is called to see if
				this view handles ink. If the InkType is
				anything other than NO_INK, then assume
				that we want ink.

    MTD MSG_VIS_LOST_GADGET_EXCL 
				Ends grab for pane that may be in effect.
				Can be used for simple case when user
				releases mouse from interacting with
				window, & in more complicated situations,
				such as the window being closed down or the
				thing losing the gadget exclusive.

				yadda yadda yadda...


    INT OLPaneClearGrabsCommon  Clear all grab flags, scrolling, panning,
				mouse grab, & timers, all without tampering
				with the gadget exclusive.

    MTD MSG_META_PTR            Handles pointer events in the pane.

    INT OLCombineMouseEvent     Handles pointer events in the pane.

    INT UpdateConstrain         Copy UIFA_CONSTRAIN bit into local instance
				bit

    INT TransCoords             Translates coordinates, as needed.

    GLB GrabTargetAndFocusIfPossible 
				Grabs the target and focus, unless the
				"don't grab from text objects" flag is set,
				and a text object has the focus.

    INT OLPaneContentLeave      Handler for MSG_META_RAW_UNIV_LEAVE.
				Implements drag-scrolling. If a wandering
				mouse grab is in effect, release the gadget
				exclusive if we have it, so that the mouse
				can continue to wander.

    MTD MSG_SPEC_VIEW_FORCE_INITIATE_DRAG_SCROLL 
				Forces a drag scroll by turning on the
				_GRAB flag.

    INT RepeatSelectScroll      Repeats the select scroll, if needed.

    INT GetPaneWinBounds        Gets the bounds for the actual window.
				Depends on what flags are set (could be a
				0, 1, or 2 pixel wide border).

    INT GetFrameBounds          Returns bounds of frame around window.

    INT DrawColorPaneWinFrame   Draws a chiseled border.

    INT DrawBWPaneWinFrame      Draws a regular border.

    MTD MSG_SPEC_VIEW_UNSUSPEND_OPENED_WIN 
				Unsuspends the newly opened window, if it
				still exists.

    INT SendPaneSizeMethod      Send a method to the OD associated with
				pane, containing current size of pane &
				pane handle

    INT SendMethod              Sends a method to the output descriptor.

    INT OLPaneGrabGadgetExclAndMouse 
				Enact a PRESS_GRAB by grabbing the gadget
				exclusive & mouse, if we don't already have
				it.

    INT OLPaneNoUpdatePending   Indicates that the parent pane's scroll
				will cause an update to happen (is 0,0).

    INT OLPaneWindowScroll      Scrolls the window.

    INT SeeIfLargeTranslation   Checks to see if the desired translation is
				large.

    INT OLPaneSelectScroll      Possibly initiate a scroll event.

    INT StartDragTimer          Start up the drag timer for a drag scroll.

    INT GetLimitedXIncrement    Get x increment, limited to a maximum
				value.

    INT GetLimitedYIncrement    Get x increment, limited to a maximum
				value.

    INT CheckIfNegativeScrollNeeded 
				Checks to see we need a negative scroll to
				see more of the drag bounds.

    INT CheckIfPositiveScrollNeeded 
				Checks to see we need a positive scroll to
				see more of the drag bounds.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

DESCRIPTION:
	Handles window-specific code for the OLPane object.
	

	$Id: cviewPaneWindow.asm,v 1.3 98/05/04 07:12:01 joon Exp $

-------------------------------------------------------------------------------@

idata segment
	; this global variable just provides a unique token to associate
	; windows with so we dont unsuspend the wrong windows
	windowID	word	0
idata ends

ViewCommon segment resource



COMMENT @----------------------------------------------------------------------

FUNCTION:	TestIfMouseImpliedOrActiveInPaneWindow

DESCRIPTION:	Tests to see if the mouse is actually active within the pane
		window  (If not, then it must be active on the border of
		the pane)
		
		At least for the moment, calls superclass to do stuff if
		on the border, before returning.

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLPane
		ax - method being used
		cx, dx, bp -- button stuff
		es -- class segment

RETURN:
		carry	- set if not over pane window, but instead is over
			  border (superclass called in this case, so no
			  further processing necessary)

		if carry set,		
		ax	- MouseReturnFlags	(In Objects/uiInputC.def)
 			  mask MRF_PROCESSED - if event processed by gadget.
					       See def. below.

 			  mask MRF_REPLAY    - causes a replay of the button
					       to the modified implied/active
					       grab.   See def. below.

			  mask MRF_SET_POINTER_IMAGE - sets the PIL_GADGET
			  level cursor based on the value of cx:dx:
			  cx:dx	- optr to PointerDef in sharable memory block,
			  OR cx = 0, and dx = PtrImageValue (Internal/im.def)

			  mask MRF_CLEAR_POINTER_IMAGE - Causes the PIL_GADGET
						level cursor to be cleared

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/90		Initial version
	Chris	2/91		Calls superclass if on border
	Doug	5/91		Fixup for elimination of Flow* routines
	
------------------------------------------------------------------------------@

TestIfMouseImpliedOrActiveInPaneWindow	proc	near	uses	di
	.enter

	; Call source of the mouse event, the application object, to see
	; if it recognizes this window or not.
	;
	push	ax, cx, dx, bp
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bp, ds:[di].OLPI_window	; Fetch pane to do the comparison with
	mov	ax, MSG_VIS_CONTENT_TEST_IF_ACTIVE_OR_IMPLIED_WIN
	call	GenCallApplication
	pop	ax, cx, dx, bp
	jnc	exit				; in pane's window, branch

	mov	di, offset OLPaneClass
	call	ObjCallSuperNoLock		; do superclass method, if one
	stc					; return carry set
exit:
	.leave
	ret
TestIfMouseImpliedOrActiveInPaneWindow	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneCloseWin -- MSG_VIS_CLOSE_WIN for OLPaneClass

DESCRIPTION:	Updates pane window.   If a window already exists,
		changes the window bounds.  If it doesn't, creates a window
		for it.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_CLOSE_WIN

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 4/89		Initial version
	Eric	5/90		Moved RELEASE_FOCUS, TARGET code to
				VIS_UN_BUILD handler.

------------------------------------------------------------------------------@

OLPaneCloseWin	method OLPaneClass, MSG_VIS_CLOSE_WIN
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset		; ds:bx = SpecificInstance
	clr	di
	xchg	di, ds:[bx].OLPI_window		; get window, store 0
	tst	di
	jz	none

	inc	ds:[bx].OLPI_windowID		; make sure ID for null-window
						; not equal to any window
						; that ever existed

	call	WinClose			; close Window, which will
						; prevent any further
						; MSG_META_EXPOSED events from
						; being generated.

	mov	bp, di
	mov	ax, MSG_META_CONTENT_VIEW_WIN_CLOSED
	call	OLPaneSendToApp
none:
	ret
OLPaneCloseWin	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneWindowSetContent -- 

DESCRIPTION:	Opens a new OD.  Sends whatever is necessary to simulate a
		view coming up.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VIEW_SET_CONTENT
		cx:dx	- new OD

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/22/89	Initial version
	srs	12/29/89	Skips window stuff if window handle is zero
------------------------------------------------------------------------------@

OLPaneWindowSetContent	proc	far
	call	PaneGetWindow			;get window in di
	jz	90$				;no window, exit
	push	si				;save pane handle
	mov	si, WIT_EXPOSURE_OBJ		;set a new exposure OD
	call	WinSetInfo	
	pop	si				;restore pane handle
	mov	bp, di				;pass window handle in bp
	mov	ax, MSG_META_CONTENT_VIEW_WIN_OPENED	;send this to output
	call	SendPaneSizeMethod
90$:
	ret
OLPaneWindowSetContent	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	ViewEnabled?

SYNOPSIS:	Returns whether view is enabled or not.

CALLED BY:	everyone

PASS:		*ds:si -- pane handle

RETURN:		true if view is enabled, false (ZF=1) otherwise 

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/ 2/90		Initial version

------------------------------------------------------------------------------@

ViewEnabled?	proc	near	uses	di
	.enter

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED	

	.leave
	ret
ViewEnabled?	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneEndMoveCopy

DESCRIPTION:	Handle release of quick move/paste button action which was
		started in the view.

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - MSG_META_END_MOVE_COPY
	cx - x pos, in window coordinates
	dx - y pos, in window coordinates
	bp high	- UIFunctionsActive
	bp low	- ButtonInfo

RETURN:
	nothing

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/90		Split out from main group for additional
				handling.

------------------------------------------------------------------------------@

OLPaneEndMoveCopy	method OLPaneClass, MSG_META_END_MOVE_COPY
	call	GenProcessGenAttrsBeforeAction	; Start any new input modes
	call	OLPaneButton			; Process move/copy
	call	GenProcessGenAttrsAfterAction	; Send terminating input mode
	ret					;	method via app queue

OLPaneEndMoveCopy	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneButton	- Handler for button methods

DESCRIPTION:	First handles local OL pane functions, then sends
		button on to application

PASS:
	*ds:si - instance data
	es - segment of MetaClass

	ax - Mouse button method
	cx - x pos, in window coordinates
	dx - y pos, in window coordinates
	bp high	- UIFunctionsActive
	bp low	- ButtonInfo

RETURN:
	nothing

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

OLPaneButton	method OLPaneClass, MSG_META_END_SELECT, \
					MSG_META_DRAG_SELECT, 	     \
					MSG_META_START_MOVE_COPY,    \
					MSG_META_DRAG_MOVE_COPY,     \
					MSG_META_DRAG_FEATURES,	     \
					MSG_META_START_OTHER,        \
					MSG_META_END_OTHER,          \
					MSG_META_DRAG_OTHER

	call	ViewEnabled?		; make sure view is enabled
	LONG	jz	exit		; nope, exit
	
					; See if the mouse is interacting
					; with the pane (as opposed to
					; the thin border around it)
	call	TestIfMouseImpliedOrActiveInPaneWindow
	LONG 	jc	exitProcessed	; Not in window, handled by superclass,
					;   exit with their return flags
;inPaneWindow:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					; NOTE: ds:di must be object!
	call	UpdateConstrain		; update our local copy of constrain bit

	;
	; If this is a button press, then grab the gadget exclusive & mouse,
	; if we haven't already.
	;
	test	bp, mask BI_PRESS
	jz	afterPress		; skip mouse grab if not press
	call	OLPaneGrabGadgetExclAndMouse
afterPress:

	push	bp
	push	ax				; save method (MSG_META_BUTTON)
	;
	; Save mouse position, in case we get panning
	; pointer events.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	ax, cx				;pointer coords in ax,bx
	mov	bx, dx
;	push	di
;	mov	di, ds:[di].OLPI_window	;pass window handle
;	call	WinTransform		;make screen coords!
;	pop	di
	mov	ds:[di].OLPI_mouseX, ax	;save mouse position
	mov	ds:[di].OLPI_mouseY, bx	;

	pop	ax				; restore MSG_META_BUTTON
						; Send on to application
EC <	call	ECCheckVisCoords				>
   	call	TransCoords			; translate coords appropriately
	call	OLPaneSendToApp
	pop	bp

	; Release gadget exclusive, thereby forcing a cease & desist of
	; all activity, if no buttons are down, i.e. they're all up.
	; Do this AFTER sending the button release on to the app, so that
	; we don't inadvertently nuke a grab before the object has a chance
	; to get the UP-button.
	;
	test	bp, mask BI_B0_DOWN or \
		    mask BI_B1_DOWN or \
		    mask BI_B2_DOWN or \
		    mask BI_B3_DOWN
	jnz	afterReleaseCheck

	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	call	VisCallParentWithSelf
afterReleaseCheck:

exit:
	mov	ax, mask MRF_PROCESSED		;say processed
exitProcessed:
	ret

OLPaneButton	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPaneQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler is invoked to send the
		MSG_META_QUERY_IF_PRESS_IS_INK to the output.

CALLED BY:	GLOBAL
PASS:		ds:di, *ds:si - ptr to OLPane object
		cx,dx - coords of mouse press
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 3/91	Initial version
	IP	08/22/94  	fixed gstate problem

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPaneQueryIfPressIsInk	method	OLPaneClass, MSG_META_QUERY_IF_PRESS_IS_INK
EC <	call	ECCheckVisCoords					>
	call	ViewEnabled?		;If view is not enabled, just exit...
	LONG	jz	noInkExit

if GRAFFITI_ANYWHERE
	;
	;  Test for Ink starting inside our bounds.  It turns out that
	;  we want to allow starting outside our bounds if we're in a
	;  GenPrimary, because title bars do nothing for full-screen
	;  windows.  In dialogs, however, specifically in the Graffiti
	;  Input Box, this test is required because otherwise you can't
	;  activate the Exit trigger.  If the Key library returned
	;  IRV_INK_WITH_STANDARD_OVERRIDE it would work, but that causes
	;  another problem (can't do single-tap for punctuation shift).
	;  So here we check if we're in a dialog box of some sort, and
	;  only do the test in that case.
	;
	push	ax, cx, dx
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	cx, segment OLDialogWinClass	; is it a dialog?
	mov	dx, offset OLDialogWinClass
	call	CallOLWin			; carry set if so
	pop	ax, cx, dx			; cx = TitleGroupType
	jnc	notDialog			; not GenDisplay, use CallOLWin

	call	TestIfMouseImpliedOrActiveInPaneWindow
	LONG	jc	noInkExit
notDialog:
else
	call	TestIfMouseImpliedOrActiveInPaneWindow
	LONG	jc	noInkExit
endif
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bl, ds:[di].GVI_inkType
	cmp	bl, GVIT_PRESSES_ARE_NOT_INK
	LONG je	noInkExit

	call	GrabTargetAndFocusIfPossible

	cmp	bl, GVIT_QUERY_OUTPUT
	je	doQuery

	clr	bp
	mov	ax, IRV_DESIRES_INK
	cmp	bl, GVIT_PRESSES_ARE_INK
	je	inkCommon
	mov	ax, IRV_INK_WITH_STANDARD_OVERRIDE
inkCommon:

;	Check if an object has set up any dest info for the ink (the ink object
;	does this to allow ink input even though the ink object's thread may
;	be busy).

	push	ax
	mov	ax, ATTR_GEN_VIEW_INK_DESTINATION_INFO
	call	ObjVarFindData
	jnc	popExit

	clr	di
	tst	ds:[bx].IDIP_createGState
	jz	createBlock

	mov	ax, MSG_GEN_VIEW_GET_WINDOW
	call	ObjCallInstanceNoLock
	mov	di, cx
	jcxz	createBlock

	call	GrCreateState

	tst	ds:[bx].IDIP_color
	jz	createBlock
	mov	al, ds:[bx].IDIP_color
	clr	ah
	call	GrSetLineColor
createBlock:
	mov	bp, di					; ^h GState
	movdw	cxdx, ds:[bx].IDIP_dest
	mov	ax, ds:[bx].IDIP_brushSize
	clrdw	bxdi
	call	UserCreateInkDestinationInfo
popExit:
	pop	ax
exit:
	ret

doQuery:
	call	TransCoords
EC <	push	si							>
EC <	mov	si, ds:[si]						>
EC <	add	si, ds:[si].Gen_offset					>
EC <	tstdw	ds:[si].GVI_content					>
EC <	ERROR_Z	OL_VIEW_GVIT_QUERY_OUTPUT_SET_WITH_NO_OUTPUT		>
EC <	pop	si							>
	call	OLPaneSendToApp
	mov	ax, IRV_WAIT
	ret

noInkExit:
	mov	ax, IRV_NO_INK
	jmp	exit
OLPaneQueryIfPressIsInk	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPaneQueryIfObjectHandlesInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler is called to see if this view handles ink.
		If the InkType is anything other than NO_INK, then assume
		that we want ink.

CALLED BY:	GLOBAL
PASS:		ss:bp - ptr to VisCallChildrenInBoundsFrame
RETURN:		CX:DX <- optr of this object, if necessary
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPaneQueryIfObjectHandlesInk	method	dynamic OLPaneClass,
					MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK
	mov	di, bx
	add	di, ds:[di].GenView_offset
	cmp	ds:[di].GVI_inkType, GVIT_PRESSES_ARE_NOT_INK
	je	exit
	call	VisObjectHandlesInkReply
exit:
	ret
OLPaneQueryIfObjectHandlesInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPaneInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine sends the ink off to the output, after
		transforming the bounds...

CALLED BY:	GLOBAL
PASS:		bp - InkHeader
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPaneInk	method	OLPaneClass, MSG_META_NOTIFY_WITH_DATA_BLOCK
	cmp	dx, GWNT_INK
	jne	callSuper
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper

;	We are getting ink, so grab the target

	call	GrabTargetAndFocusIfPossible

	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	call	OLPaneSendToApp
exit:
	ret
callSuper:
	mov	di, offset OLPaneClass
	GOTO	ObjCallSuperNoLock
OLPaneInk	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLPaneEndGrab

DESCRIPTION:	Ends grab for pane that may be in effect.  Can
		be used for simple case when user releases mouse from
		interacting with window, & in more complicated situations,
		such as the window being closed down or the thing losing
		the gadget exclusive.

		The main reason this is done is to force the release of the
		mouse grab & feedback by an object within the view when
		doing a quick-transfer operation.  This is the only way we
		have of telling such an object to "knock it off" if the mouse
		moves out of the view, or over onto another application.

		The only other way this might possibly be done would be to
		trick the content with regards to the implied window.  Such
		a scenerio might look like:

		" All contents, even those below Views, now
		  have to be instructed as to when the IMPLIED_WIN is one
		  of theirs.  Views will send this notification whenever the
		  mouse enters the view area, & clear it when it leaves.  One
		  special case, however:  As long as the view has the mouse
		  grabbed, we'll continue to let the content believe the
		  mouse is over the port window.  Why?  Because we in every
		  other way treat the document area itself as being visible,
		  continuing to pass it mouse events, & expecting it to
		  continue doing things like selecting while auto-scrolling.
		  By leaving the implied window set, UIFA_IN will continue
		  to indicate whether the mouse is in the visible bounds
		  of the object or not. "

		This approach was chosen against both because of the 
		ugliness of faking enter/leave events, & because LARGE mouse
		events don't have a UIFA_IN flag, meaning that would be
		insufficient info objects in a large doc model.
		
		Releases:

		Mouse grab
		Gadget exclusive
		Drag scrolling

CALLED BY:	INTERNAL
		OLPaneLostGadgetExcl

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_LOST_GADGET_EXCL

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/89		Initial version
------------------------------------------------------------------------------@

OLPaneEndGrab	method dynamic OLPaneClass, MSG_VIS_LOST_GADGET_EXCL

	push	ds:[di].OLPI_window	; Save window handle while we can get it
	push	ds:[di].OLPI_optFlags	; Save opt flags for wandering-grab
					;  check.

	call	OLPaneClearGrabsCommon

	;
	; If we've got a wandering grab active, set the quick-transfer cursor
	; to the non-interactable one. If no quick-transfer is active (someone
	; told us to allow global transfer for no apparent reason), this will
	; have no effect, so it won't cause any harm. -- ardeb 7/31/92
	; 
	pop	ax
	test	ax, mask OLPOF_WANDERING_GRAB
	jz	tellContent
	
	mov	ax, CQTF_CLEAR
	clr	bp
	call	ClipboardSetQuickTransferFeedback

tellContent:
	pop	bp			; Pass window handle in bp per method
					;	specification
	mov	ax, MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL
	call	OLPaneSendToApp
	ret

OLPaneEndGrab	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLPaneClearGrabsCommon

DESCRIPTION:	Clear all grab flags, scrolling, panning, mouse grab, & timers,
		all without tampering with the gadget exclusive.

CALLED BY:	INTERNAL

PASS:		*ds:si	- OLPaneClass object

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

OLPaneClearGrabsCommon	proc near

	; Clear bits which are defined as being clear when losing gadget excl
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLPI_optFlags, not (mask OLPOF_PRESS_GRAB or \
			mask OLPOF_PANNING_GRAB or \
			mask OLPOF_DRAG_SCROLL_ON_ANY_BUTTON or \
			mask OLPOF_DRAG_SCROLLING)

	; .. as well as the mouse grab, which may not be had without the gadget
	; exclusive.
	;
	call	VisReleaseMouse

	call	OLPaneNoUpdatePending	; Turn off timers, etc. related to
					; above bits

	; If ptr no longer over view area, send off MSG_META_CONTENT_LEAVE, if
	; we haven't done so already.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_optFlags, mask OLPOF_PTR_IN_RAW_UNIV
	jnz	done
	call	OLPaneContentLeave
done:
	ret

OLPaneClearGrabsCommon	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLPanePtr --
		MSG_META_PTR for OLPaneClass

DESCRIPTION:	Handles pointer events in the pane.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_PTR

		cx, dx	- ptr screen position, relative to view window.

RETURN:
		ax - 0 if ptr not in button, mask MRF_PROCESSED if ptr is inside
		cx, dx, bp -- trashed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/28/89		Initial version

------------------------------------------------------------------------------@

OLPanePtrMethod	method dynamic OLPaneClass, MSG_META_PTR
	call	ViewEnabled?			;make sure view is enabled
	LONG	jz	exit			;nope, exit
	
; Rather than doing this, which is not too incredibly fast, we can do
; an optimized check (which follows in braces)
;					; See if the mouse is interacting
;					; with the pane (as opposed to
;					; the thin border around it)
;	call	TestIfMouseImpliedOrActiveInPaneWindow
;	jc	exitProcessed		; Not in window, handled by superclass,
;

; {
					; Test to see if we have the mouse
					; grabbed at this time
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB
	jnz	sendOnPtrEvent		; if so (same criteria as used
					; to grab mouse), then window handle
					; in grab is pane, coord info
					; is OK, go ahead and send.
sendBasedOnInRawUniv:
					; OTHERWISE, we may assume that
					; we got the event because we are
					; the implied window.  Check to see
					; if ptr is in RAW_UNIV of pane
					; or not
	test	ds:[di].OLPI_optFlags, mask OLPOF_PTR_IN_RAW_UNIV
	jnz	sendOnPtrEvent		; in raw universe, go process it
	
	mov	di, offset OLPaneClass
	call	ObjCallSuperNoLock	; else send to any children
	jmp	exitProcessed

sendOnPtrEvent:
; }


	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
					; NOTE: ds:di must be object!
	call	UpdateConstrain		; update our local copy of constrain bit


	; WANDER DETECTION
	;
	; Check for situation of mouse wandering into the view window on
	; an implied basis, i.e. we don't have the grab
	;
	test	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB
	jnz	afterWanderDetect		; nope, just the usual

			; indeed, we've just gotten an implied PTR event.
			; Presume no mouse buttons are down...

	andnf	ds:[di].OLPI_optFlags, not mask OLPOF_WANDERING_GRAB

			; test presumption
	test	bp, mask BI_B0_DOWN or \
		    mask BI_B1_DOWN or \
		    mask BI_B2_DOWN or \
		    mask BI_B3_DOWN
	jz	afterWanderDetect		; nope, just the usual

	;
	; only do wander grab on quick-transfer, prevents unwanted grabbing
	; of gadget excl if dragging on START_SELECT - brianc 2/4/93
	;
	test	bp, mask UIFA_MOVE_COPY shl 8
	jz	afterWanderDetect

			; Jackpot!  We've detected the mouse wandering into
			; us with a mouse button down, meaning that there is
			; a wandering grab, such as a quick-transfer active.
			; To accomodate it, we'll grab the gadget excl & mouse,
			; but with the caveat of a "WANDERING_GRAB" in action.

	call	OLPaneGrabGadgetExclAndMouse
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLPI_optFlags, mask OLPOF_WANDERING_GRAB
afterWanderDetect:


	; UNCONSTRAIN
	;
	; Check to see if ptr outside of view window, with wandering grab,
	; but without CONSTRAIN bit, i.e. it has been released by user
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_optFlags, mask OLPOF_WANDERING_GRAB
	jz	afterUnconstrain
	test	ds:[di].OLPI_optFlags, mask OLPOF_PTR_IN_RAW_UNIV or \
						mask OLPOF_CONSTRAIN
	jnz	afterUnconstrain
	;
	; Force release of gadget exclusive, so that we let the mouse
	; wander again.
	;
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	call	VisCallParentWithSelf

	mov	ax, MSG_FLOW_ALLOW_GLOBAL_TRANSFER
	clr	di
	call	UserCallFlow

	; Don't send ptr event onto content -- instead, replay it to
	; whatever window it is over now.
	;
	mov	ax, mask MRF_PROCESSED or mask MRF_REPLAY
	jmp	short exitProcessed

afterUnconstrain:


	; PANNING
	;
	; Handle panning if we're doing panning.
	;
	test	ds:[di].OLPI_optFlags, mask OLPOF_PANNING_GRAB
	jnz	pan				


	; DRAG SCROLL
	;
	; If select-scrolling, let's possibly start a scroll happening.
	;
	test	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLLING
	jz	afterDragScroll			;not select scrolling, branch
	test	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLL_PENDING or \
					mask OLPOF_TIMER_EXPIRED_PENDING
	jnz	afterDragScroll			;already started one, branch
	;
	; We'll select scroll, and send the pointer event to the content,
	; anyway, in case it is wanted or the thing doesn't actually scroll.
	; (Used to just exit afterwards -- changed to this 7/30/90 cbh)
	;
	push	ax, cx, dx, bp			;save regs
	call	OLPaneSelectScroll		;else possibly start something
	pop	ax, cx, dx, bp			;restore regs
afterDragScroll:

	; SEND TO CONTENT
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_DONT_SEND_PTR_EVENTS
	jnz	afterSendToContent

	call	TransCoords			;translate coords as needed
						;Else send on to pane
						;window, compressing events
						;as we go.
	push	si
	mov	bx, ds:[di].GVI_content.handle
	mov	si, ds:[di].GVI_content.chunk
	push	cs				;push custom vector on stack
	mov	di, offset OLCombineMouseEvent
	push	di
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE or \
		    mask MF_CUSTOM or mask MF_CHECK_LAST_ONLY
	call	ObjMessage			;off she goes...
	pop	si
afterSendToContent:

exit:
	mov	ax, mask MRF_PROCESSED		; assume output sets ptr image
exitProcessed:
	ret


pan:
if	0
	mov	ax, cx				;pointer coords in ax,bx
	mov	bx, dx
;	push	di
;	mov	di, ds:[di].OLPI_window		;pass window handle
;	call	WinTransform		;make screen coords!
;	pop	di
	mov	cx, ds:[di].OLPI_mouseX		;get old position
	mov	dx, ds:[di].OLPI_mouseY
	sub	cx, ax				;subtract new position from old
	sub	dx, bx
	mov	ds:[di].OLPI_mouseX, ax		;store new position
	mov	ds:[di].OLPI_mouseY, bx
	call	ConvertScreenToDocCoords	;convert to document change
	
	mov	ax, MSG_SPEC_VIEW_PAN		;send scroll method to ourselves
	call	ObjCallInstanceNoLock		;
endif
	jmp	short exit

OLPanePtrMethod	endm




;
; Custom combination routine for ptr events, called by ObjMessage in
; OLPanePtr above.
;
OLCombineMouseEvent	proc	far
	class	OLPaneClass
	
	cmp	ds:[bx].HE_method, MSG_META_PTR
	jne	cantUpdate

	cmp	ds:[bx].HE_bp, bp	; different button flags?
	jne	cantUpdate		; yes!, can't combine

	mov	ds:[bx].HE_cx, cx	; update event
	mov	ds:[bx].HE_dx, dx	; update event
	mov	di, PROC_SE_EXIT	; show we're done
	ret

cantUpdate:
	mov	di, PROC_SE_STORE_AT_BACK	; just put at the back.
	ret
OLCombineMouseEvent	endp

			


COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateConstrain

DESCRIPTION:	Copy UIFA_CONSTRAIN bit into local instance bit

CALLED BY:	INTERNAL
		OLPanePtrMethod
		OLPaneButton

PASS:		ds:di	- ptr straight into OLPaneClass object
		bp high - UIFunctionsActive

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version
------------------------------------------------------------------------------@

UpdateConstrain	proc	near
	test	bp, (mask UIFA_CONSTRAIN) shl 8
	jz	clear

	ornf	ds:[di].OLPI_optFlags, mask OLPOF_CONSTRAIN
	ret

clear:
	andnf	ds:[di].OLPI_optFlags, not mask OLPOF_CONSTRAIN
	ret
UpdateConstrain	endp

				


COMMENT @----------------------------------------------------------------------

ROUTINE:	TransCoords

SYNOPSIS:	Translates coordinates, as needed.

CALLED BY:	utility

PASS:		*ds:si -- view
		cx, dx -- mouse position, in window coordinates

RETURN:		cx, dx -- coords translated, according to translate flag
		carry set if window is closing
		
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if (not GVA_WINDOW_COORDINATE_MOUSE_EVENTS)
		WinUnTransCoord(cx, dx, OLPI_window)
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/26/91		Initial version
	Doug	5/13/91		Changed to pass unscaled data for large doc
				model case (Now new flag GVA_WINDOW_COORDINATE_
				MOUSE_EVENTS)

------------------------------------------------------------------------------@

TransCoords	proc	near		uses	di, ax, bx
	.enter
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
						;See if passing window coords
						;between view & content
	test	ds:[di].GVI_attrs, mask GVA_WINDOW_COORDINATE_MOUSE_EVENTS
	jnz	exit				;branch if doing this
	
	call	PaneGetWindow			;get window in di
	jz	exit				;no window, exit (cbh 10/21/91)
	push	cx, dx				;save mouse coords
	call	WinGetWinScreenBounds		;add window left/top back in
	pop	cx, dx
	add	ax, cx
	add	bx, dx				;we now have screen coords again
	call	WinUntransform		;go ahead and translate
	mov	cx, ax
	mov	dx, bx
EC <	jnc	EC10							>
EC <	cmp	ax, WE_COORD_OVERFLOW					>
EC <	ERROR_E	OL_VIEW_CANT_SEND_ABS_MOUSE_COORDS_TO_BIG_CONTENTS	>
EC < EC10:								>
   
exit:
	.leave					;
	ret
TransCoords	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabTargetAndFocusIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grabs the target and focus, unless the "don't grab from 
		text objects" flag is set, and a text object has the focus.

CALLED BY:	GLOBAL
PASS:		*ds:si - OLPane object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabTargetAndFocusIfPossible	proc	near	uses	ax, cx, dx, bp
	.enter
	;
	; New code so that certain views avoid taking the focus from text
	; objects.  Currently only used by scrolling lists, as text objects
	; and other contents figure to always want the focus if the thing
	; is focusable, anyway.  Of course, I see no code here for 
	; GVA_FOCUSABLE, so I wonder... -cbh 9/12/92
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_flags, mask OLPF_DONT_TAKE_FOCUS_FROM_TEXT_OBJECTS
	jz	10$

	call	OpenTestIfFocusOnTextEditObject
	jnc	exit			;skip if on text object, shouldn't take
					; focus or target...
10$:
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock
exit:
	.leave
	ret
GrabTargetAndFocusIfPossible	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneStartSelect	- Handler for MSG_META_START_SELECT

DESCRIPTION:	Implements click-to-type kbd focus, if selected.

PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ax - MSG_META_START_SELECT

	cx - x pos, in window coordinates
	dx - y pos, in window coordinates
	bp high	- UIFunctionsActive
	bp low	- ButtonInfo

RETURN:
	nothing

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

OLPaneStartSelect	method OLPaneClass, MSG_META_START_SELECT
	call	ViewEnabled?		; make sure view is enabled
	jz	exit			; nope, exit
	
					; See if the mouse is interacting
					; with the pane (as opposed to
					; the thin border around it)
	call	TestIfMouseImpliedOrActiveInPaneWindow
	jc	exitProcessed		; Not in window, handled by superclass,
					;  exit

	call	GrabTargetAndFocusIfPossible

	GOTO	OLPaneButton

exit:
	mov	ax, mask MRF_PROCESSED		;say processed
exitProcessed:
	ret

OLPaneStartSelect	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneStartFeatures - Handler for MSG_META_START_FEATURE

DESCRIPTION:	Handles panning of the pane.  Gets the grab for the
		pane.

PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ax - MSG_META_START_FEATURE

	cx - x pos
	dx - y pos
	bp - OpenButton flags

RETURN:
	nothing

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

OLPaneStartFeatures method OLPaneClass, MSG_META_START_FEATURES
	call	ViewEnabled?		; make sure view is enabled
	jz	exit			; nope, exit
	
					; See if the mouse is interacting
					; with the pane (as opposed to
					; the thin border around it)
	call	TestIfMouseImpliedOrActiveInPaneWindow
	jc	exitProcessed		; Not in window, handled by superclass,
					;   exit

	push	bp
	call	OLPaneButton
	pop	bp

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB
	jz	exitProcessed			;don't have grab, exit

	test	bp, mask UIFA_PAN shl 8	; panning option set?
	jz	exitProcessed		; if not, do standard button stuff
	
					; Mark as panning
	or	ds:[di].OLPI_optFlags, mask OLPOF_PANNING_GRAB
exit:
	mov	ax, mask MRF_PROCESSED
exitProcessed:
	ret

OLPaneStartFeatures	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneEndFeatures - Handler for MSG_META_END_FEATURES

DESCRIPTION:	Stops panning (if scrollable)

PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ax - MSG_META_END_FEATURES

	cx - x pos
	dx - y pos
	bp - OpenButton flags

RETURN:
	nothing

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

OLPaneEndFeatures	method OLPaneClass, MSG_META_END_FEATURES

					; See if the mouse is interacting
					; with the pane (as opposed to
					; the thin border around it)
	call	TestIfMouseImpliedOrActiveInPaneWindow
	jc	exitProcessed		; Not in window, handled by superclass,
					;   exit

					; Make sure not panning anymore
					; (EVEN IF NOT ENABLED)
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	and	ds:[di].OLPI_optFlags, not (mask OLPOF_PANNING_GRAB)
	GOTO	OLPaneButton		; & do regular handling

exit:
	mov	ax, mask MRF_PROCESSED
exitProcessed:
	ret

OLPaneEndFeatures	endm




COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneRawEnter

DESCRIPTION:	Uses raw enter method to turn off any drag scrolling in
		progress.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_RAW_UNIV_ENTER

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 6/89		Initial version

------------------------------------------------------------------------------@

OLPaneRawEnter	method OLPaneClass, MSG_META_RAW_UNIV_ENTER
					; Ptr is longer in universe
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	or	ds:[di].OLPI_optFlags, mask OLPOF_PTR_IN_RAW_UNIV

	;
	; END any select scrolling in process
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	and	ds:[di].OLPI_optFlags, not mask OLPOF_DRAG_SCROLLING

; No more.  Not needed, & just results in more messages flying around.
; 					-- Doug 7/1/92
;	; NOTIFY OD
;
;	call	OLPaneSendToApp

	; Send out a MSG_META_CONTENT_ENTER, unless we've already done so.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLPI_optFlags, mask OLPOF_ENTERED
	jnz	afterEnter
	ornf	ds:[di].OLPI_optFlags, mask OLPOF_ENTERED
	mov	ax, MSG_META_CONTENT_ENTER
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	OLPaneSendToApp
afterEnter:

	ret
OLPaneRawEnter	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneRawLeave

DESCRIPTION:	Handler for MSG_META_RAW_UNIV_LEAVE.  Implements drag-scrolling.
		If a wandering mouse grab is in effect, release the
		gadget exclusive if we have it, so that the mouse can
		continue to wander.


PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_RAW_LEAVE

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 1/89		Initial version

------------------------------------------------------------------------------@

OLPaneRawLeave method OLPaneClass, MSG_META_RAW_UNIV_LEAVE
					; Ptr is no longer in universe
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	and	ds:[di].OLPI_optFlags, not mask OLPOF_PTR_IN_RAW_UNIV

	call	ViewEnabled?		; make sure view is enabled
	jz	afterConstrain		; if not, force release of any exlusive
	
	; WANDER CONTINUATION
	;
	; If not wandering, keep mouse grabbed by view, by not messing
	; with gadget excl.
	;
	test	ds:[di].OLPI_optFlags, mask OLPOF_WANDERING_GRAB
	jz	afterForceRelease

	; See if user has CONSTRAIN override to wandering mouse
	;
	test	ds:[di].OLPI_optFlags, mask OLPOF_CONSTRAIN
	jz	afterConstrain

	; But! Can't oblige if GVA_DRAG_SCROLLING not set.
	;
	mov	bx, ds:[si]			
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GVI_attrs, mask GVA_DRAG_SCROLLING
	jz	afterConstrain

	; if so, set bit to let the scrolling begin, & skip force-off of
	; gadget exclusive.
	;
	ornf	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLL_ON_ANY_BUTTON
	jmp	short afterForceRelease

afterConstrain:

	; If mouse should be allowed to wander, force off gadget excl so it can
	;
	push	ax, cx, dx, bp
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	call	VisCallParentWithSelf

	call	ViewEnabled?			; make sure view is enabled
	jz	afterAllowGlobalTransfer	; no, branch  -cbh 4/26/93

	mov	ax, MSG_FLOW_ALLOW_GLOBAL_TRANSFER
	clr	di
	call	UserCallFlow

afterAllowGlobalTransfer:
	pop	ax, cx, dx, bp

afterForceRelease:

	call	ViewEnabled?		; make sure view is enabled
	jz	afterDragScroll		; if not, can't drag scroll

	; DRAG SCROLL DETECTION
	;
	; See if we're supposed to scroll while moving outside of the window.
	; If so, we should set the OLPWF_DRAG_SCROLLING flag to start
	; scrolling the window.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB
	jz	afterDragScroll				;don't have grab, exit

					; See if temp override to allow
					; drag scroll until end of win grab
	test	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLL_ON_ANY_BUTTON
	jnz	startDragScroll

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GVI_attrs, mask GVA_DRAG_SCROLLING
	jz	exit				;user doesn't want it, branch

					; See if select button down
					; (we only scroll on select)
	push	ax, cx, dx, bp
	mov	ax, MSG_VIS_VUP_GET_MOUSE_STATUS
	call	VisCallParent
	mov	ax, bp
	test	ah, mask UIFA_SELECT
	pop	ax, cx, dx, bp
	jz	exit				;if not exit

startDragScroll:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLLING
	push	ax, cx, dx, bp
	call	OLPaneSelectScroll	;initiate a select-scroll event
	pop	ax, cx, dx, bp
afterDragScroll:

exit:

	; Unless press grab is still active (in which case content is
	; still being interacted with), send a MSG_META_CONTENT_LEAVE
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB
	jnz	afterLeave
	call	OLPaneContentLeave
afterLeave:

; No more.  Not needed, & just results in more messages flying around.
; 					-- Doug 7/1/92
;	; NOTIFY OD of MSG_META_RAW_UNIV_LEAVE
;
;	call	OLPaneSendToApp
	ret
OLPaneRawLeave	endm

OLPaneContentLeave	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
						; if already left, done.
	test	ds:[di].OLPI_optFlags, mask OLPOF_ENTERED
	jz	done
						; else clear bit & leave.
	andnf	ds:[di].OLPI_optFlags, not mask OLPOF_ENTERED
	push	ax, cx, dx, bp
	mov	ax, MSG_META_CONTENT_LEAVE
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	OLPaneSendToApp
	pop	ax, cx, dx, bp
done:
	ret
OLPaneContentLeave	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneForceInitiateDragScroll -- 
		MSG_SPEC_VIEW_FORCE_INITIATE_DRAG_SCROLL for OLPaneClass

DESCRIPTION:	Forces a drag scroll by turning on the _GRAB flag.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VIEW_FORCE_INITIATE_DRAG_SCROLL

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
	chris	11/23/92         	Initial Version

------------------------------------------------------------------------------@

OLPaneForceInitiateDragScroll	method dynamic	OLPaneClass, \
				MSG_SPEC_VIEW_FORCE_INITIATE_DRAG_SCROLL

;	or	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB
	andnf	ds:[di].OLPI_optFlags, not mask OLPOF_WANDERING_GRAB
	call	OLPaneGrabGadgetExclAndMouse

	FALL_THRU	OLPaneInitiateDragScroll

OLPaneForceInitiateDragScroll	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneInitiateDragScroll

DESCRIPTION:	Initiates panning of window, if mouse button(s) are down.
		This is used for the case that an application wishes panning
		to happen with buttons other than the SELECT button  (Such
		as hitting DIRECT_ACTION on a control point in Draw)

PASS:
	*ds:si - instance data
	es - segment of MetaClass
	ax - MSG_GEN_VIEW_INITIATE_DRAG_SCROLL


RETURN:
	nothing
	ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

OLPaneInitiateDragScroll method OLPaneClass, \
				MSG_GEN_VIEW_INITIATE_DRAG_SCROLL
	call	ViewEnabled?		; make sure view is enabled
	jz	exit			; nope, exit
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance

					; First, make sure that a PRESS_GRAB
					; is in effect
	test	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB
	jz	exit			; if not, done

					; Set flag to allow any-button drag 
					; scroll
	or	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLL_ON_ANY_BUTTON

	; if in view, or already scrolling, done
	;
	test	ds:[di].OLPI_optFlags, mask OLPOF_PTR_IN_RAW_UNIV
	jnz	exit				; if still in window, no scroll
	test	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLLING
	jnz	exit				; if already scrolling, done

	; Else, START scrolling
	;
	or	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLLING
	call	OLPaneSelectScroll	; try to initiate a scroll
exit:
EC <	Destroy	ax, cx, dx, bp				;trash things	    >
	ret

OLPaneInitiateDragScroll	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneUpdateComplete --
		MSG_META_WIN_UPDATE_COMPLETE for OLPaneClass

DESCRIPTION:	Handles update complete events.  When we're not in select-
		scrolling mode, we just send the event up to the parent, to see
		if any scrollbars need to keep scrolling.  If we are in
		select-scroll mode, we check to see if the current mouse
		position is outside the window and send a scroll method to
		our parent if so.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_WIN_UPDATE_COMPLETE

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/22/89		Initial version

------------------------------------------------------------------------------@

WinCommon	segment	resource
global	OpenWinDarkenWindow:far
WinCommon	ends

OLPaneUpdateComplete method OLPaneClass, MSG_META_WIN_UPDATE_COMPLETE
	mov	di, ds:[si]			;no more scroll pending
	add	di, ds:[di].Vis_offset		;
	and	ds:[di].OLPI_optFlags, not mask OLPOF_DRAG_SCROLL_PENDING
	call	RepeatSelectScroll

	ret
OLPaneUpdateComplete	endm


				


COMMENT @----------------------------------------------------------------------

ROUTINE:	RepeatSelectScroll

SYNOPSIS:	Repeats the select scroll, if needed.

CALLED BY:	OLPaneUpdateComplete, OLPaneTimerExpired

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 6/90		Initial version

------------------------------------------------------------------------------@

RepeatSelectScroll	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLLING
	jz	repeatScroll			;not select-scrolling branch
	
	test	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLL_PENDING \
				     or mask OLPOF_TIMER_EXPIRED_PENDING
	jnz	exit				;still waiting for one of these,
						;    exit
	;
	; Try initiating another select-scroll event if the pointer is still
	; out of the window bounds.
	;
	call	OLPaneSelectScroll	;else try to initiate scroll
	jmp	short exit
	
repeatScroll:
	;
	; We've just completed a normal scroll event.  Send method back to
	; scrollbars to see if we should scroll again.  (Sadly, we must send
	; it via the queue because a scrollbars MSG_META_END_SELECT may still
	; be on the queue. -cbh 2/22/93)
	;
	mov	ax, MSG_REPEAT_SCROLL

	clr	bx	
	mov	di, mask MF_FORCE_QUEUE
	call	CallScrollbar
	mov	bx, CS_VERTICAL
	mov	di, mask MF_FORCE_QUEUE
	call 	CallScrollbar
exit:
	ret
RepeatSelectScroll	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPaneWinBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the bounds for the actual window.  Depends on what
		flags are set (could be a 0, 1, or 2 pixel wide border).

CALLED BY:	OLPaneRealize, OLPaneUpdateWindows

PASS:		*ds:si -- handle of pane

RETURN:		ax, bx, cx, dx -- bounds of actual window, in screen 
					coordinates

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GetPaneWinBounds	proc	far
	class	OLPaneClass
	
	push	di
	call	GetWinLeftTop			 ;cx, dx <- window left, top
	call	GetFrameWidth			 ;frame width in ax
	add	cx, ax				 ;add frame to upper left
	add	dx, ax
	
	mov	ax, cx				 ;keep in ax, bx as well
	mov	bx, dx
	mov	di, ds:[si]			 ;and get right and bottom
	add	di, ds:[di].Vis_offset		 ;  from window size.
	add	cx, ds:[di].OLPI_winWidth	 
	dec	cx
	add	dx, ds:[di].OLPI_winHeight
	dec	dx
	pop	di
	ret

GetPaneWinBounds	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	GetFrameBounds

SYNOPSIS:	Returns bounds of frame around window.

CALLED BY: 	utility

PASS:		*ds:si -- pane

RETURN:		ax, bx, cx, dx -- bounds of frame around window, in screen
					coordinates

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/19/91		Initial version

------------------------------------------------------------------------------@

GetFrameBounds	proc	far
	push	di

	call	GetFrameWidth			;get frame width
	push	ax
	call	GetPaneWinBounds		;get bounds of frame area
	pop	di
	sub	ax, di				;move out from window
	sub	bx, di
	add	cx, di
	add	dx, di
	pop	di
	ret
GetFrameBounds	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneDraw -- MSG_VIS_DRAW for OLPaneClass

DESCRIPTION:	Draw the pane.   

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass

	ax - MSG_VIS_DRAW

	cl - DrawFlags:  DF_EXPOSED set if updating
	bp - GState to use

RETURN:
	nothing
	ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

OLPaneDraw	method OLPaneClass, MSG_VIS_DRAW
		
if	_OL_STYLE
	push	es						  
	push	bp
	push	cx
	call	ViewEnabled?			;see if enabled
	jnz	drawIt				;it is enabled, branch
      
greyOut:
	push	ax
	mov	ax, SDM_50			;50% outline
	mov	di, bp
	call	GrSetLineMask
	pop	ax

drawIt:

	push	cx
	push	dx
	mov	ax,GIT_PRIVATE_DATA
	mov	di, bp
	call	GrGetInfo			;returns ax, bx, cx, dx
	pop	dx
	pop	cx
	;
	; al = color scheme, ah = display type, cl = update flag
	;
	mov	ch, cl				;Pass DrawFlags in ch
	mov	cl, al				;Pass color scheme in cl
						;(ax & bx get trashed)
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- GenInstance
	test	ds:[di].OLPI_attrs, mask OLPA_SPECIAL_BORDER
	mov	di, bp				;gstate in di
	jnz	color				;do chisel if color doesn't
						;    match
	call	DrawBWPaneWinFrame		;draw normal black frame
	jmp	short exit

color:
	CallMod	DrawColorPaneWinFrame		;draw chiseled frame

exit:
	mov	ax, SDM_100			;in case we did a 50% pattern
	call	GrSetAreaMask
      
	pop	cx
	pop	bp
	pop	es      
	mov	ax, MSG_VIS_DRAW			;call superclass to draw 
	mov	di, offset OLPaneClass		;   children
	call	ObjCallSuperNoLock
	ret
endif 


if	_MOTIF
	
if (not DRAW_STYLES)
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- SpecInstance
	test	ds:[di].GVI_attrs, mask GVA_NO_WIN_FRAME
	jnz	doChildren			;no frame, skip all of this
endif
	
	push	ax
	push	cx
	mov	di, bp				;gstate in di
	
if DRAW_STYLES ;---------------------------------------------------------------

	;
	; set wash color
	;
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	dx, di				; ds:dx = gen instance
	movdw	bxax, ds:[di].GVI_color
	pop	di
	call	GrSetAreaColor
	;
	; get frame flag, draw style, frame thickness, inset thickness
	;
	push	di
	mov	di, dx				; ds:di = gen instance
	mov	ax, mask DIAFF_FRAME shl 8	; default to draw frame
	test	ds:[di].GVI_attrs, mask GVA_NO_WIN_FRAME
	jz	haveFrameFlag
	clr	ax				; clear frame flag
haveFrameFlag:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	al, ds:[di].OLPI_drawStyle
	pop	di
	push	ax				; pass frame, draw style
	mov	ax, (DRAW_STYLE_FRAME_WIDTH shl 8) or DRAW_STYLE_INSET_WIDTH
	push	ax				; pass flags, inset widths
	call	GetFrameBounds			; pass frame bounds
	inc	cx				; make fillRect-style coords
	inc	dx
	;
	; draw frame and inset
	;
	call	OpenDrawInsetAndFrame
	;
	; show focus for text object, if necessary
	;
if TEXT_DISPLAY_FOCUSABLE
	call	ShowScrollingTextFocus
endif
	
else ;-------------------------------------------------------------------------

	call	OpenSetInsetRectColors		;set typical colors

	mov	bx, ds:[si]			;point to instance
	add	bx, ds:[bx].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[bx].OLPI_attrs, mask OLPA_SPECIAL_BORDER
	jnz	drawIt				;special border, go draw it
	
	mov	bp, (C_BLACK shl 8) or C_BLACK	;probably want black instead
	
	test	ds:[bx].OLPI_attrs, mask OLPA_WHITE_BORDER
	jz	drawIt				;not drawing white, branch
	mov	bp, (C_WHITE shl 8) or C_WHITE	;else draw a white border
drawIt:
	call	GetFrameBounds			;get bounds
	inc	cx				;make fillRect-style coords
	inc	dx
	call	OpenDrawRect			;draw an inset rect
doneFrame::

endif ; DRAW_STYLES -----------------------------------------------------------

	mov	bp, di				;gstate in di again
	pop	cx
	pop	ax
	
doChildren:
	mov	di, offset OLPaneClass		;do children now
	call	ObjCallSuperNoLock
	ret	
endif

if	_ISUI
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- SpecInstance
	test	ds:[di].GVI_attrs, mask GVA_NO_WIN_FRAME
	jnz	doChildren			;no frame, skip all of this
	
	push	ax, cx, bp
	mov	di, bp				;gstate in di
	
	call	GetFrameBounds			;get bounds
	inc	cx				;make fillRect-style coords
	inc	dx

	mov	bp, C_DARK_GRAY or (C_WHITE shl 8)
	call	OpenCheckIfBW
	jnc	10$
	mov	bp, C_BLACK or (C_BLACK shl 8)
10$:
	call	OpenDrawRect			;draw an inset rect
	inc	ax
	inc	bx
	dec	cx
	dec	dx

	mov	bp, C_BLACK or (C_LIGHT_GRAY shl 8)
	call	OpenCheckIfBW
	jnc	20$
	mov	bp, C_BLACK or (C_BLACK shl 8)
20$:
	call	OpenDrawRect
	pop	ax, cx, bp
	
doChildren:
	mov	di, offset OLPaneClass		;do children now
	GOTO	ObjCallSuperNoLock
endif	; _ISUI

OLPaneDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowScrollingTextFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw focus indicator for scrolling text, if necessary

CALLED BY:	INTERNAL
			OLPaneDraw
PASS:		*ds:si = view
		di = gstate
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TEXT_DISPLAY_FOCUSABLE

ShowScrollingTextFocus	proc	near
	mov	ax, ATTR_OL_PANE_SCROLLING_TEXT
	call	ObjVarFindData
	jnc	done
	mov	bx, ds:[bx]			; *ds:bx = text object
	mov	bx, ds:[bx]			; deref
	add	bx, ds:[bx].Vis_offset
	test	ds:[bx].OLTDI_specState, mask TDSS_EDITABLE
	jnz	done
	test	ds:[bx].OLTDI_moreState, mask TDSS_FOCUSABLE
	jz	done
	test	ds:[bx].VTI_intSelFlags, mask VTISF_IS_FOCUS
	pushf					; save focus state
	mov	ax, ({dword}ds:[bx].VTI_washColor).low
	push	ax				; save color for later
	mov	bx, ({dword}ds:[bx].VTI_washColor).high
	call	GrSetAreaColor
	push	di				; save gstate
	call	GetFrameWidth			; ax = frame width
	pop	di
	mov	bp, ax
	sub	bp, 1+TEXT_DISPLAY_FOCUS_WIDTH	; remove gutter and focus
						;	width
	call	GetFrameBounds			; view bounds
	add	ax, bp				; adjust to get focus coords
	sub	cx, bp
	add	bx, bp
	sub	dx, bp
	pop	bp				; bp = wash color
	call	GrFillRect			; clear area out
	popf					; get focus state
	jz	done
;not needed here for some reason
;	dec	cx				; adjust for line drawing
;	dec	dx
	push	ax
	mov	ax, C_WHITE			; assume white cursor
	cmp	bp, C_BLACK
	je	haveCursorColor			; white cursor for black
	cmp	bp, C_DARK_GREY
	je	haveCursorColor			; white cursor for dark grey
	mov	ax, C_BLACK			; black cursor for any other
haveCursorColor:
	call	GrSetLineColor
	mov	al, SDM_50
	call	GrSetLineMask
	pop	ax
	call	GrDrawRect			; draw focus indicator
	mov	al, SDM_100
	call	GrSetLineMask
done:
	ret
ShowScrollingTextFocus	endp

endif




COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawColorPaneWinFrame

SYNOPSIS:	Draws a chiseled border.

CALLED BY:	OLPaneDraw

PASS:		*ds:si -- instance data
		cl     -- color scheme
		ch     -- DrawFlags: DF_EXPOSED set if updating
		di     -- gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/31/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@
	
if	_OL_STYLE ;-----------------------------
DrawColorPaneWinFrame	proc	far
	class	OLPaneClass
	
	call	GetDarkColor			;al <- dark color, ah <- flag
	call	GrSetLineColor
	call	GetLightColor			;al <- light color, ah <- flag
	call	GrSetAreaColor			;use for clearing first

	call	GetFrameBounds			;get the bounds of the thing
	inc	cx
	inc	dx
	call	GrFillRect			;first white out
	dec	cx
	dec	dx
	dec	cx				;inset right and bottom
	dec	dx
	call	GrDrawRect
	inc	ax				;draw a dark frame, shifted
	inc	bx
	inc	cx
	inc	dx
	push	ax
	mov	ax, C_WHITE
	call	GrSetLineColor
	pop	ax
	call	GrDrawRect			;then draw the white frame
	ret
DrawColorPaneWinFrame	endp
endif ;-----------------------------------------
      

COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawBWPaneWinFrame

SYNOPSIS:	Draws a regular border.

CALLED BY:	OLPaneDraw

PASS:		*ds:si -- instance data
		cl     -- color scheme
		ch     -- DrawFlags: DF_EXPOSED set if updating
		di     -- gstate

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/31/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

if	_OL_STYLE
	
DrawBWPaneWinFrame	proc	near
	class	OLPaneClass
	
	mov	al, cl				;set area color to bkgd
	mov	cl, 4
	shr	al, cl
	clr	ah
	call	GrSetAreaColor			;used for clearing
	
	mov	ax, C_BLACK			;use dark color
	mov	bx, ds:[si]			;point to instance
	add	bx, ds:[bx].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[bx].OLPI_attrs, mask OLPA_WHITE_BORDER
	jz	10$				;not drawing white, branch
	mov	ax, C_WHITE			;else draw a white border
10$:
	call	GrSetLineColor

	call	GetFrameBounds			;get the bounds of the thing
	inc	cx
	inc	dx
	call	GrFillRect			;clear area first
	dec	cx
	dec	dx
	call	GrDrawRect			;now draw the frame.
	ret
DrawBWPaneWinFrame	endp

endif


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneOpenWin -- MSG_VIS_OPEN_WIN for OLPaneClass

DESCRIPTION:	Open pane

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_OPEN_WIN
		bp	- window to realize on

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 4/89		Initial version
	Doug	10/89		Broke into OpenWin & MoveResizeWin

------------------------------------------------------------------------------@


OLPaneOpenWin	method OLPaneClass, MSG_VIS_OPEN_WIN

	push	si			;save pane handle

	call	GeodeGetProcessHandle	; Get owner for window
	push	bx			; Push layer ID to use
	push	bx			; Push owner to use

	push	bp			; pass parent window handle
	clr	ax			; pass region (rectangular)
	push	ax
	push	ax

	call	GetPaneWinBounds	; get window bounds to pass
	push	dx
	push	cx
	push	bx
	push	ax

	;
	; Get color to use, set up in the pane's spec build.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	movdw	bxax, ds:[di].GVI_color			;bxax = color
	
	mov	bp, ds:[di].GVI_content.chunk	; pass OD from pane object
	mov	di, ds:[di].GVI_content.handle
	mov	cx, ds:[LMBH_handle]		; pass enter/leave OD
	mov	dx, si

						; Initialize window suspended
						; (No update drawing)
	mov	si, mask WPF_INIT_SUSPENDED
	call	WinOpen

	; Inform the application that the pane is open

	pop	si				;restore chunk handle
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = SpecificInstance
	mov	ds:[di].OLPI_window, bx	;store window handle
	push	es
	mov	ax, segment dgroup
	mov	es, ax
	mov	ax, es:[windowID]
	inc	es:[windowID]
	pop	es
	mov	ds:[di].OLPI_windowID, ax 	;change unique window ID
	push	bx				;save window handle

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	dx, ds:[di].GVI_scaleFactor.PF_x.WWF_int  ;get current scaling
	mov	cx, ds:[di].GVI_scaleFactor.PF_x.WWF_frac	
	mov	bx, ds:[di].GVI_scaleFactor.PF_y.WWF_int	
	mov	ax, ds:[di].GVI_scaleFactor.PF_y.WWF_frac	
	pop	di				;restore window handle
	push	di				;save again
	
	mov	bp, si				;save pane handle
	mov	si, WIF_INVALIDATE		;invalidate when scaling
	call	WinApplyScale			;scale the sucker
	mov	si, bp				;restore pane handle
	
	mov	ax, MSG_SPEC_VIEW_INIT_ORIGIN	;get initial origin straight
	call	ObjCallInstanceNoLock
	
	mov	ax, MSG_GEN_VIEW_GET_SCALE_FACTOR
	call	ObjCallInstanceNoLock		;send the initial scale factor
	mov	bx, bp
	call	SendNewScaleToOD
	
	pop	bx				;restore window handle
	mov	ax, MSG_META_CONTENT_VIEW_WIN_OPENED
	call	SendPaneSizeMethod
						;if not normalized scrolling,
						;then we won't be getting
						;a NORMALIZE_COMPLETE w/initial
						;position later, so 
						;UnSuspend now.
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		;ds:si = SpecificInstance
	tst	ds:[di].GVI_content.handle	;if no content yet, we didn't
	jz	unsuspend			; normalize, unsuspend now.
	test	ds:[di].GVI_attrs, mask GVA_TRACK_SCROLLING
	jnz	done				; if normalized scrolling, the
						; UnSuspend will be delayed
						; until the initial position
						; is sent to NORMALIZE_COMPLETE

unsuspend:					; If not, then do it now.
	;
	; Now calling MSG_SPEC_VIEW_UNSUSPEND_OPENED_WIN, which will check
	; to make sure the view window still matches, rather than MSG_GEN_-
	; VIEW_UNSUSPEND_UPDATE.  -cbh 4/21/93
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset		
	mov	cx, ds:[di].OLPI_windowID
	mov	ax, MSG_SPEC_VIEW_UNSUSPEND_OPENED_WIN
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE		; Send via queue to force same
	call	ObjMessage			;   ordering with content 
						;   messages whether content
						;   run by UI or not (they are
						;   also send FORCE_QUEUE
						;   12/ 2/91 -cbh 
done:
	ret

OLPaneOpenWin	endm





COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneUnsuspendOpenedWin -- 
		MSG_SPEC_VIEW_UNSUSPEND_OPENED_WIN for OLPaneClass

DESCRIPTION:	Unsuspends the newly opened window, if it still exists.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VIEW_UNSUSPEND_OPENED_WIN
		cx	- windowID of window to unsuspend

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
	chris	4/21/93         	Initial Version

------------------------------------------------------------------------------@

OLPaneUnsuspendOpenedWin	method dynamic	OLPaneClass, \
				MSG_SPEC_VIEW_UNSUSPEND_OPENED_WIN

	cmp	cx, ds:[di].OLPI_windowID	;same window?
	jne	exit				;no, forget unsuspend, probably
						;  from a previous incarnation.
	mov	ax, MSG_GEN_VIEW_UNSUSPEND_UPDATE
	GOTO	ObjCallInstanceNoLock
exit:
	ret
OLPaneUnsuspendOpenedWin	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneMoveResizeWin -- MSG_VIS_MOVE_RESIZE_WIN
			for OLPaneClass

DESCRIPTION:	Resizes a pane

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_MOVE_RESIZE_WIN

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 4/89		Initial version
	Doug	10/89		Broke into OpenWin & MoveResizeWin

------------------------------------------------------------------------------@


OLPaneMoveResizeWin	method OLPaneClass, MSG_VIS_MOVE_RESIZE_WIN
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset	 	  ;ds:bx = SpecificInstance
	mov	di, ds:[bx].OLPI_window	  	  ;fetch window handle

;	cmp	ds:[bx].OLPI_window, 0		  ;already have a window?

EC<	call	VisCheckVisAssumption		  ;Make sure vis data exists >
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset		  ;ds:di = VisInstance
	test	ds:[bx].VI_optFlags, mask VOF_WINDOW_INVALID
	jz	exit				  ;skip if not invalid
	;
	; Notify Pane OD of change in pane size.
	;
	push	si				  ;save chunk handle
	call	GetPaneWinBounds
	mov	si,mask WPF_ABS			  ;resize absolute (i.e. move)
	push	si
	clr	si
	clr	bp
	call	WinResize
	pop	si				  ;restore handle

if FLOATING_SCROLLERS
	; Update floating scrollers so they'll move
	push	cx
	mov	cx, TRUE			;close scrollers before update
	call	OLPaneUpdateFloatingScrollers
	pop	cx
endif	
	;
	; Moved back here from OLPaneSetNewPageSize, so things are done in the
	; correct order.  10/23/91 cbh.
	;
	push	di
	mov	ax, MSG_META_CONTENT_VIEW_SIZE_CHANGED
	call	SendPaneSizeMethod		;send size notification
	pop	di
	
	;
	; Unsuspend the update, after making a complete trip through the 
	; application's queue.  (Only if the thing has been suspended 
	; previously, of course.)
	; 
;	push	si
;	mov	si, ds:[si]			
;	add	si, ds:[si].Vis_offset
;	test	ds:[si].OLPI_flags, mask OLPF_SUSPENDED_FOR_SIZE_CHANGE	
;	jz	90$
;	and	ds:[si].OLPI_flags, not mask OLPF_SUSPENDED_FOR_SIZE_CHANGE
;	call	WinUnSuspendUpdate

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPI_flags, mask OLPF_SUSPENDED_FOR_SIZE_CHANGE	
	jz	exit

	and	ds:[di].OLPI_flags, not mask OLPF_SUSPENDED_FOR_SIZE_CHANGE
	mov	cx, ds:[di].OLPI_windowID
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_SPEC_VIEW_UNSUSPEND_OPENED_WIN  ;to help updates.  I think
	mov	di, mask MF_FORCE_QUEUE		   ;  re-maximizing displays &
	call	ObjMessage			   ;  stuff causes extra 
						   ;  invalidation even after
						   ;  this point. 4/13/93 cbh
;90$:
;	pop	si
exit:
	ret

OLPaneMoveResizeWin	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	SendPaneSizeMethod

DESCRIPTION:	Send a method to the OD associated with pane,
		containing current size of pane & pane handle

CALLED BY:	INTERNAL

PASS:
	*ds:si	- pane
	ax - Method to send on to GVI_content

RETURN:
	Method sent to OD, with cx, dx = width & height, bp = window handle

	di - pane handle

DESTROYED:
	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
------------------------------------------------------------------------------@

SendPaneSizeMethod	proc	far
	class	OLPaneClass
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].OLPI_pageWidth	
	mov	dx, ds:[di].OLPI_pageHeight
	FALL_THRU	SendMethod		;and send

SendPaneSizeMethod	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SendMethod

SYNOPSIS:	Sends a method to the output descriptor.

CALLED BY:	SendPaneSizeMethod, OLPaneOpenWin
		OLPaneMoveResizeWin

PASS:		ax -- method

RETURN:		nothing

DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/29/89		Initial version

------------------------------------------------------------------------------@

SendMethod		proc	far
	class	OLPaneClass
	
	push	bp
	call	PaneGetWindow			;get window in di
	mov	bp, di				;pass window handle in bp
	call	OLPaneSendToApp			;send to output
	pop	bp
	ret
SendMethod	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	OLPaneGrabGadgetExclAndMouse

DESCRIPTION:	Enact a PRESS_GRAB by grabbing the gadget exclusive & mouse, 
		if we don't already have it.

CALLED BY:	INTERNAL
		OLPaneButton

PASS:
	*ds:si	- OLPane

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	Doug	5/90		Updated
------------------------------------------------------------------------------@

OLPaneGrabGadgetExclAndMouse	proc	near	uses	ax, cx, dx, di, bp
	class	OLPaneClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

				; Skip if we already have it
	test	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB
	jnz	done

				; Mark as having grab now
	or	ds:[di].OLPI_optFlags, mask OLPOF_PRESS_GRAB

				; Init to not DRAG_SCROLLING, &
				; not OLPOF_DRAG_SCROLL_ON_ANY_BUTTON

	andnf	ds:[di].OLPI_optFlags, not (mask OLPOF_DRAG_SCROLLING or \
				mask OLPOF_DRAG_SCROLL_ON_ANY_BUTTON)

	; Grab gadget exclusive, so that we're allowed to grab mouse
	;
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL	
	call	VisCallParentWithSelf

	; Grab mouse itself, passing pane window (can't use VisGrabMouse)
	;
	sub	sp, size VupAlterInputFlowData	; create stack frame
	mov	bp, sp				; ss:bp points to it
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].VAIFD_object.handle, ax	; copy object OD into frame
	mov	ss:[bp].VAIFD_object.chunk, si
	mov	ss:[bp].VAIFD_flags, mask VIFGF_MOUSE or mask VIFGF_GRAB or \
				mask VIFGF_PTR or mask VIFGF_NOT_HERE
	mov	ss:[bp].VAIFD_grabType, VIFGT_ACTIVE

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLPI_window	; get window handle for pane
	mov	ss:[bp].VAIFD_gWin, di		; & pass in method

	clr	ax				; init to no translation
	mov	ss:[bp].VAIFD_translation.PD_x.high, ax
	mov	ss:[bp].VAIFD_translation.PD_x.low, ax
	mov	ss:[bp].VAIFD_translation.PD_y.high, ax
	mov	ss:[bp].VAIFD_translation.PD_y.low, ax

	mov	dx, size VupAlterInputFlowData	; pass size of structure in dx
	mov	ax, MSG_VIS_VUP_ALTER_INPUT_FLOW	; send method
	call	ObjCallInstanceNoLock
	add	sp, size VupAlterInputFlowData	; restore stack
done:
	.leave
	ret
OLPaneGrabGadgetExclAndMouse	endp




COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneNoUpdatePending

SYNOPSIS:	Indicates that the parent pane's scroll will cause an update
		to happen (is 0,0).

CALLED BY:	several routines
       
PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass

RETURN:		nothing

DESTROYED:	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/25/90		Initial version

------------------------------------------------------------------------------@

OLPaneNoUpdatePending	proc	far		uses	ax, cx, dx, bp
	.enter
	mov	di, ds:[si]			;no more scroll pending
	add	di, ds:[di].Vis_offset		;
	test	ds:[di].OLPI_optFlags, (mask OLPOF_DRAG_SCROLL_PENDING \
					  or mask OLPOF_TIMER_EXPIRED_PENDING)
	jz	exit				;neither flag set, exit
	and	ds:[di].OLPI_optFlags, not (mask OLPOF_DRAG_SCROLL_PENDING \
					  or mask OLPOF_TIMER_EXPIRED_PENDING)
	mov	dx, si				;now pass ^lcx:dx 10/29/90 cbh
	mov	cx, ds:[LMBH_handle]
	mov	ax, MSG_OL_APP_STOP_TIMER
	call	GenCallApplication
exit:
	.leave
	ret
OLPaneNoUpdatePending	endp


ViewCommon	ends

ViewScroll	segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneWindowScroll --

DESCRIPTION:	Scrolls the window.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass

		bx:ax 	- new x origin
		dx:cx   - new y origin

RETURN:		bx:ax	- new x origin (may have changed)
		dx:cx	- new y origin (may have changed)

DESTROYED:	di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		The reason that the passed origin values may have changed is
		that when a view is scaled, the passed integer scroll value
		may not translate to an integer number of pixels.  The integer
		number of pixels that consistute the scroll amount are 
		translated into the equivalent document units, which may 
		change the passed origin by some fraction.  The fractional 
		part of the change is stored in GVI_origin by this routine -- 
		the integer part returned here is stored later by 
		StoreNewOrigin, which is called by OLPaneScroll.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/23/89		Initial version
	Jim	8/5/91		Added fixed-point support to GVI_origin

------------------------------------------------------------------------------@

OLPaneWindowScroll	proc	far
	uses	bp, si
	.enter
	push	ax, bx, cx, dx			; save translation amount
						; NOTE: code at WinScroll 
						;  (below) assumes that nothing
						;  is pushed between here and
						;  there...(jad)

	call	MakeRelativeToOrigin		;make relative scroll amount
	mov	bp, ax				;slightly cheaper to do this
	or	bp, bx
	or	bp, cx
	or	bp, dx				
	LONG	jz	exit			;nothing to scroll, exit 1/21/93

	mov	bp, ds:[si]			;say there's a scroll pending
	add	bp, ds:[bp].Vis_offset
	mov	di, ds:[bp].OLPI_window	;pass window handle
	tst	di
	LONG jz	exit				;exit if no window
	
	test	ds:[bp].OLPI_optFlags, mask OLPOF_DRAG_SCROLLING
	jz	7$
	push	di
	call	StartDragTimer		;start up the drag timer (moved here
	pop	di			;(from OLPaneSelectScroll 1/21/93 cbh)

7$:
	;
	; If non-scrolling, we'll disconnect the view's scrolling capability,
	; while keeping the origin internally.
	; 
	mov	bp, ds:[si]			
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLPI_attrs, mask OLPA_NON_SCROLLING
	LONG jnz exit

	;
	; Now, do the scrolling.  For scrolling small amounts, and we know we
	; won't be invalidating soon anyway, we'll use WinScroll.  For small
	; amounts where invalidation is pending,  we will call WinApply-
	; Translation without an invalidation.  For large scrolling (32 bits),
	; we'll call the new and exciting WinApplyTranslationDWord.
	;
	call	SeeIfLargeTranslation		;is vertical scroll large?	
	jc	largeScroll			;yes, branch
	xchg	ax, cx				;now check horiz scroll
	xchg	bx, dx
	call	SeeIfLargeTranslation
	xchg	ax, cx
	xchg	bx, dx
	jc	largeScroll			;large, branch
	
;smallScroll:	
	pop	ax, bx, cx, dx			; restore original absolute org
	call	MakeRelativeWWFixed
	call	WinScroll			;scroll the window

	; the values returned by WinScroll may be different (by some fraction)
	; that what we passd to the routine.  We need to reflect this change
	; in GVI_origin.  Since we have the relative amounts in registers, we
	; just add these to GVI_origin, the have this routine return the final
	; value (integer part).  It will get stored again later, but that's OK.
updateOrigin:
	neg	cx				; NegateFixed dx.cx
	not	dx
	cmc
	adc	dx, 0
	neg	ax				; NegateFixed bx.ax
	not	bx
	cmc
	adc	bx, 0
	mov	bp, ds:[si]			; get ptr to instance data
	add	bp, ds:[bp].Gen_offset		

	add	ds:[bp].GVI_origin.PDF_x.DWF_frac, cx ; update origin
	xchg	ax, cx				; need to do cwd
	mov	ax, dx
	cwd
	adc	ds:[bp].GVI_origin.PDF_x.DWF_int.low, ax
	adc	ds:[bp].GVI_origin.PDF_x.DWF_int.high, dx

	add	ds:[bp].GVI_origin.PDF_y.DWF_frac, cx
	mov	ax, bx
	cwd
	adc	ds:[bp].GVI_origin.PDF_y.DWF_int.low, ax
	adc	ds:[bp].GVI_origin.PDF_y.DWF_int.high, dx

	movdw	bxax, ds:[bp].GVI_origin.PDF_x.DWF_int
	movdw	dxcx, ds:[bp].GVI_origin.PDF_y.DWF_int

;	This screwed up the integer portion of GVI_origin.  -cbh 3/30/93
;	tst	ds:[bp].GVI_origin.PDF_x.DWF_frac
;	jns	10$
;	incdw	bxax
;10$:	
;	tst	ds:[bp].GVI_origin.PDF_y.DWF_frac
;	jns	20$
;	incdw	dxcx
;20$:	
	push	ax, bx, cx, dx
	jmp	short finishScroll
	
largeScroll:
	clr	si				;assume we can invalidate
	
	negdw	dxcx				;negate dx:cx (y scroll amt)
	xchg	ax, cx				;Jim does these the other way.	
	xchg	bx, dx
	negdw	dxcx				;negate dx:cx (x scroll amt)
	call	WinApplyTranslationDWord
	
finishScroll:
	call	ImForcePtrMethod		;ptr has moved wrt. window...
exit:
	pop	ax, bx, cx, dx			; restore translation amounts
	.leave
	ret
	
OLPaneWindowScroll	endp







COMMENT @----------------------------------------------------------------------

ROUTINE:	SeeIfLargeTranslation

SYNOPSIS:	Checks to see if the desired translation is large.

CALLED BY:	OLPaneWindowScroll

PASS:		dx:cx -- translation to check

RETURN:		carry set if large

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/21/91		Initial version

------------------------------------------------------------------------------@
LARGE_TRANSLATION	equ	2000h		;arbitrary cutoff point...
HIGH_WORD		equ	0ffff0000h
LOW_WORD		equ	00000ffffh

SeeIfLargeTranslation	proc	near
	cmp	dx, (LARGE_TRANSLATION and HIGH_WORD) shr 16
	jg	isLarge				;a lot bigger, exit	
	jl	10$				
	cmp	cx, LARGE_TRANSLATION and LOW_WORD
	ja	isLarge				;a little bigger, exit
10$:
	cmp	dx, (-LARGE_TRANSLATION and HIGH_WORD) shr 16
	jl	isLarge				;a lot smaller, exit
	jg	isSmall				
	cmp	cx, -LARGE_TRANSLATION and LOW_WORD
	jb	isLarge				;a little smaller, exit
isSmall:
	clc
	jmp	short exit
isLarge:
	stc					
exit:
	ret
SeeIfLargeTranslation	endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneTimerExpired --
		MSG_TIMER_EXPIRED for OLPaneClass

DESCRIPTION:	Handles timer-expired events.  We start timers at the 
		beginning of select-scrolls.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_TIMER_EXPIRED

RETURN:		nothing
		ax, cx, dx, bp -- trashed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/22/89		Initial version

------------------------------------------------------------------------------@

OLPaneTimerExpired method OLPaneClass, MSG_TIMER_EXPIRED
	mov	di, ds:[si]			;no more scroll pending
	add	di, ds:[di].Vis_offset		;
	and	ds:[di].OLPI_optFlags, not mask OLPOF_TIMER_EXPIRED_PENDING
	call	RepeatSelectScroll	
	ret

OLPaneTimerExpired	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	OLPaneSelectScroll

SYNOPSIS:	Possibly initiate a scroll event.

CALLED BY:	OLPaneUpdateComplete, OLPaneInitiateDragScroll,
       		OLPaneRawLeave, OLPanePtr

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
      	Horrible access to pane's instance data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/21/90		Initial version

------------------------------------------------------------------------------@
	
OLPaneSelectScroll	proc	far
	call	GetPaneWinBounds		;get pane bounds in ax,bx,cx,dx
	xchg	bx, cx				;xchg to get left,right,top,bot
	push	cx, dx				;save top and bottom
	call	VisQueryWindow			;get window in di
	call	ImGetMousePos			;returns current pos in cx, dx
	mov	di, ds:[si]			;point to instance of pane
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance of pane
	cmp	cx, ax				;see if to left of window
	jge	10$				;it's not, branch
	
	call	GetLimitedXIncrement		;increment in cx
	clr	bx				;doing horizontal
	xchg	cx, dx				;pass scroll amount in dx
	call	CheckIfNegativeScrollNeeded	;if we even need to scroll
	xchg	cx, dx				;return scroll amount to cx
	jc	5$				;we need to scroll, branch
	clr	cx				;else don't scroll
5$:
	neg	cx				;scroll negatively
	jmp	checkVert

10$:
	cmp	cx, bx				;see if to right of window
	mov	cx, 0				;assume not
	jle	checkVert			;nope, branch

	call	GetLimitedXIncrement
	clr	bx				;doing horizontal
	xchg	cx, dx				;pass scroll amount in dx
	call	CheckIfPositiveScrollNeeded	;if we even need to scroll
	xchg	cx, dx				;(restore scroll amount to cx)
	jc	checkVert			;yes, branch
	clr	cx				;else don't scroll

checkVert:
	DoPop	bx, ax				;restore bottom, top
	cmp	dx, ax				;see if above top
	jge	20$				;nope, branch
	
	call	GetLimitedYIncrement
	mov	bx, CNSN_VERTICAL		;vertical scroll
	call	CheckIfNegativeScrollNeeded	;if we even need to scroll
	jc	15$				;yes, branch
	clr	dx				;else don't scroll
15$:
	neg	dx				;scroll negatively
	jmp	scroll

20$:
	cmp	dx, bx				;see if below bottom of view!!!
						;  (sorry, Wendy)
	mov	dx, 0				;assume not
	jle	scroll				;nope, branch

	call	GetLimitedYIncrement
	mov	bx, CNSN_VERTICAL		;vert scroll
	call	CheckIfPositiveScrollNeeded	;if we even need to scroll
	jc	scroll				;yes, branch
	clr	dx				;else don't scroll

scroll:
	;
	; Vert scroll amount in dx:cx, horizontal amount in bx:ax. Move into
	; scroll structure.
	;
	clr	bp				;normal scroll
	mov	ax, MSG_SPEC_VIEW_DRAG_SCROLL	;get ready to send scroll method
	tst	cx				;see if any x change
	jnz	stillScrolling			;yes, branch
	tst	dx				;see if any y change
	jz	exit				;nope, exit

stillScrolling:
	call	ObjCallInstanceNoLock		;go scroll
exit:
	ret
OLPaneSelectScroll	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	StartDragTimer

SYNOPSIS:	Start up the drag timer for a drag scroll.

CALLED BY:	OLPaneWindowScroll

PASS:		*ds:si -- pane

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/21/93       	Initial version

------------------------------------------------------------------------------@

StartDragTimer	proc	near
	;
	; Start a timer going.  We won't re-scroll until the timer expires.
	;
	push	ax, cx, dx, bp
	mov	dx, si				;now pass ^lcx:dx 10/29/90 cbh
	mov	cx, ds:[LMBH_handle]
	mov	ax, MSG_OL_APP_STOP_TIMER
	call	GenCallApplication	; turn timer off, if any
	clr	bp			; use standard system delay
	mov	dx, si
	mov	cx, ds:[LMBH_handle]
	mov	ax, MSG_OL_APP_START_TIMER
	call	GenCallApplication
	pop	ax, cx, dx, bp
	
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLPI_optFlags, mask OLPOF_DRAG_SCROLLING or \
					mask OLPOF_TIMER_EXPIRED_PENDING
	ret
StartDragTimer	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	GetLimitedXIncrement, GetLimitedYIncrement

SYNOPSIS:	Get x increment, limited to a maximum value.

CALLED BY:	OLPaneSelectScroll

PASS:		ds:di -- GenView instance

RETURN:		cx -- value to use (dx for GetLimitedYIncrement)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 3/91		Initial version

------------------------------------------------------------------------------@
MAX_DRAG_SCROLL_INCREMENT	equ	4000


GetLimitedXIncrement	proc	near
	mov	cx, ds:[di].GVI_increment.PD_x.low	
	cmp	cx, MAX_DRAG_SCROLL_INCREMENT	;limit to a maximum increment
	ja	3$
	tst	ds:[di].GVI_increment.PD_x.high
	jz	5$
3$:
	mov	cx, MAX_DRAG_SCROLL_INCREMENT
5$:
	ret
GetLimitedXIncrement	endp

GetLimitedYIncrement	proc	near
	mov	dx, ds:[di].GVI_increment.PD_y.low	
	cmp	dx, MAX_DRAG_SCROLL_INCREMENT	;limit to a maximum increment
	ja	3$
	tst	ds:[di].GVI_increment.PD_y.high
	jz	5$
3$:
	mov	dx, MAX_DRAG_SCROLL_INCREMENT
5$:
	ret
GetLimitedYIncrement	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfNegativeScrollNeeded

SYNOPSIS:	Checks to see we need a negative scroll to see more of the
		drag bounds.

CALLED BY:	OLPaneSelectScroll

PASS:		*ds:si -- view
		bx -- CNSN_VERTICAL if y, zero otherwise
		dx -- suggested absolute amount to scroll (will be negated
				later)

RETURN:		carry set if scroll needed, with:
			dx -- possibly updated to only scroll what is necessary

DESTROYED:	di

PSEUDO CODE/STRATEGY:
       can scroll if docOrigin.x > dragLeft

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 3/91		Initial version

------------------------------------------------------------------------------@
CNSN_VERTICAL equ	offset P_y - offset P_x
	      
CheckIfNegativeScrollNeeded	proc	near	uses	cx, bp
	.enter
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	add	di, bx				;account for direction for
	add	di, bx				;  GVI_origin (using 
	add	di, bx				;  CNSN_VERTICAL * 3)
	mov	bp, ds:[si]			
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLPI_optFlags, mask OLPOF_LIMIT_DRAG_SCROLLING
	jz	needed				;not limiting, exit
	
	add	bp, bx				;account for direction for
	add	bp, bx				;  OLPI_dragBounds (using 
						;  CNSN_VERTICAL * 2)
	
	mov	cx, ds:[di].GVI_origin.PDF_x.DWF_int.high	
	cmp	cx, ds:[bp].OLPI_dragBounds.RD_left.high
	jg	needed
	jl	notNeeded
	mov	cx, ds:[di].GVI_origin.PDF_x.DWF_int.low
	sub	cx, ds:[bp].OLPI_dragBounds.RD_left.low
	jbe	notNeeded			;already onscreen, branch
	;
	; We need the thing onscreen.  If the amount of scrolling needed to
	; get the object completely onscreen is smaller than the increment
	; amount, then we'll just scroll that amount.
	;
	cmp	cx, dx				;still a ways to go before 
	ja	needed				;  getting onscreen, branch
	mov	dx, cx				;else only scroll as much as we
	jmp	short needed				;  need
	
notNeeded:
	clc
	jmp	short exit
needed:
	stc
exit:
	.leave
	ret
CheckIfNegativeScrollNeeded	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	CheckIfPositiveScrollNeeded

SYNOPSIS:	Checks to see we need a positive scroll to see more of the
		drag bounds.

CALLED BY:	OLPaneSelectScroll

PASS:		*ds:si -- view
		bx -- CNSN_VERTICAL if in y, zero otherwise

RETURN:		carry set if scroll needed

DESTROYED:	di

PSEUDO CODE/STRATEGY:
       should scroll if docOrigin.x + pageWidth < dragRight

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 3/91		Initial version

------------------------------------------------------------------------------@
	
CheckIfPositiveScrollNeeded	proc	near	uses	ax, cx, bp
				
	CheckHack <CNSN_VERTICAL eq (offset OLPI_pageHeight - \
				      offset OLPI_pageWidth)>
	CheckHack <CNSN_VERTICAL*3 eq (offset GVI_origin.PDF_y - \
				      offset GVI_origin.PDF_x)>
	CheckHack <CNSN_VERTICAL*2 eq (offset OLPI_dragBounds.RD_top - \
				      offset OLPI_dragBounds.RD_left)>
	.enter
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	add	di, bx				;account for direction
	add	di, bx				;  using CNSN_VERTICAL*3
	add	di, bx
	
	mov	bp, ds:[si]			
	add	bp, ds:[bp].Vis_offset
	test	ds:[bp].OLPI_optFlags, mask OLPOF_LIMIT_DRAG_SCROLLING
	jz	needed				;not limiting, exit
	
	mov	ax, ds:[di].GVI_origin.PDF_x.DWF_int.high	
	mov	cx, ds:[di].GVI_origin.PDF_x.DWF_int.low
	tst	ds:[di].GVI_origin.PDF_x.DWF_frac.high
	clc					; set carry correct for round
	jns	addWidth
	stc
addWidth:
	add	bp, bx				;vertical offset to words
	add	cx, ds:[bp].OLPI_pageWidth	;origin + pageWidth
	adc	ax, 0
	
	add	bp, bx				;bp now used for dwords
	cmp	ax, ds:[bp].OLPI_dragBounds.RD_right.high
	jl	needed
	jg	notNeeded
	sub	cx, ds:[bp].OLPI_dragBounds.RD_right.low
	jae	notNeeded
	;
	; We need the thing onscreen.  If the amount of scrolling needed to
	; get the object completely onscreen is smaller than the increment
	; amount, then we'll just scroll that amount.
	;
	neg	cx				;make positive
	cmp	cx, dx				;still a ways to go before 
	ja	needed				;  getting onscreen, branch
	mov	dx, cx				;else only scroll as much as we
	jmp	short needed			;  need
	
notNeeded:
	clc
	jmp	short exit
needed:
	stc
exit:
	.leave
	ret
CheckIfPositiveScrollNeeded	endp



ViewScroll	ends
