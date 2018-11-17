COMMENT }***********************************************************************

	Copyright (c) GeoWorks 1988 - All rights reserved

	PROJECT: 	PCGEOS
	MODULE: 	Windowing System
	FILE:		winNotification

	AUTHOR:		Doug Fults

	ROUTINES:

		Name				description
		----				-----------

    May be called by any thread:
	GLB	WinGrabChange			Sets up recipient of WIN_CHANGE
	GLB	WinUnGrabChange			To release OD above

	GLB	WinEnsureChangeNotification	Routine called by IM to force
						the sending of a WIN_CHANGE
	GLB	WinMovePtr			Routine called by IM to let
						this module know where mouse is
	INT	WinRedoMovePtr			Recalcs where pointer is
	INT	WinCheckPtr			Checks if mouse still in rect.


    Must be called by thread owning wPtrOutputOD only:
*	GLB	WinChangeAck			Acknowledge for
						MSG_META_WIN_CHANGE
*EL	GLB	WinMouseGrab			Grab this window.
*EL	GLB	WinMouseRelease			Release this window.
*EL	GLB	WinBranchExclude		Exclude this window branch from
						having implied grab
*EL	GLB	WinBranchInclude		Allow window branch to have
						implied grab again.

* These routines all result in the immediate messaging of Enter/Leave messages

    May only be called by a thread having the winTreeSem:
	INT	WinChangePtrNotification	Let's notification system know
						that a window has been moved/
						resized/opened, etc.  Ptr may
						by in a new win
	INT	WinCommonTraverse		Traverses tree from one
						point to another, generating
						methods
	INT	WinTraverseHere			Traverses window sys, generating
						methods.
	INT	CheckInVis			See if mouse is in vis region
						of a window, send methods
EL	INT	SendVisEvents			Send more events from CheckInVis
	INT	CheckInUniv			See if mouse is in univ region
						of a window, send methods
EL	INT	SendUnivEvents			Send more events from
						CheckInUniv
	INT	CheckHere
	INT	CheckInChildren
	INT	CheckAcross

	INT	SendEnterLeaveEvents		Send events via queue, start on
						WinEnterLeaveFlags
	INT	WinSendViaPtrEventQueue		Put event in queue
	INT	WinFlushSendQueue		Deliver all events in queue

EL	- these exist only if WIN_ENTER_LEAVE_CONTROL = TRUE

	REVISION HISTORY:
		date		name	description
		----		----	-----------
		3/89		doug	New file created

	$Id: winNotification.asm,v 1.1 97/04/05 01:16:11 newdeal Exp $

********************************************************************************

	DESCRIPTION:

		Ptr handling routines for window system.  Keeps track of
	current location of ptr, storing for each window whether the ptr is
	currently in its universe region, & whether it is in its visible
	region.  An enclosing rectangle is kept, which is tested against when
	the Input manager notifies the windowing system of a ptr change using
	the routine WinMovePtr.  WinMovePtr only does the test, & will send
	a MSG_META_WIN_CHANGE to the change OD if the ptr goes outside that
	rectangle.  The changeOD routine should call back WinChangeAck, which
	will actually traverse the tree to determine the new ptr location, &
	if no grab is in effect, send any of MSG_META_VIS_ENTER,
	MSG_META_VIS_LEAVE, MSG_META_UNIV_ENTER, MSG_META_UNIV_LEAVE, as is
	appropriate.  The events to be sent are accumulated in a buffer,
	& then sent out in a batch, outside of the winTreeSem locking, so
	that the method handlers may use window routines.  Methods are not sent
	using MF_FORCE_QUEUE, so that objects running under the same thread
	as that which called WinChangeAck will be called synchronously.
	Enter/Leave events are sent in a consistent nesting, in the order:

	parent window	MSG_META_UNIV_ENTER
	parent window	    MSG_META_VIS_ENTER
	parent window	    MSG_META_VIS_LEAVE
	child window		MSG_META_UNIV_ENTER
	child window		    MSG_META_VIS_ENTER
	child window		    MSG_META_VIS_LEAVE
	child window		MSG_META_UNIV_ENTER
	parent window	    MSG_META_VIS_ENTER
	parent window	    MSG_META_VIS_LEAVE
	parent window	MSG_META_UNIV_LEAVE

	If a window is grabbed, then enter & leaves are generated for that
	window only.  When the grab is released, the enter/leave states are
	updated for windows that previously were blocked from getting that
	information.


	WinMovePtr should be called from Input Manager.

	WinChangeAck should all be called from the
	same thread, which runs the object referenced by wOutputOD.

	Strategy for MSG_META_IMPLIED_WIN_CHANGE
	--------------------------------------

	The wPtrOutputOD is notified whenever the ptr moves into a new window.
	It is passed the window handle that has been moved into and if that
	branch of the window system is not excluded, or prevented from being
	interacted with by a grab in progress, is send the Input OD of the
	window as well.  If the window may not be interacted with, the OD
	is passed as 0.

	We would like this method out before any MSG_META_UNIV_ENTER in which
	the mouse has moved to a new window, but not before the last
	MSG_META_UNIV_LEAVE getting us out of a window.

	Strategy for PtrImages
	----------------------

	If no windows grabbed:
		If implied win not excluded:	Use PtrImage of implied window
		If implied win excluded:	NULL (default pointer)
	If window(s) grabbed:
		PtrImages follow wPtrLastGrabWin


*******************************************************************************}

EC <MAX_GRABBED_WINDOWS		=	20				>



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinMovePtr

DESCRIPTION:	Notifies window system of pointer movement on a root tree,
		causing it to set status flags, & send out MSG_META_WIN_CHANGE
		if further work will be done.  NOTE:  this routine should
		be VERY fast.

CALLED BY:	EXTERNAL
		NOTE:  May be called by any thread, without winTreeSem

PASS:
	al - Save-under areas that the mouse is in
		(VD_VID_MOVEPTR provides this info)
	bx - handle of root window that pointer is on
	cx - Ptr X position, in screen coordinates
	dx - Ptr Y position, in screen coordinates

RETURN:
	INT's ON

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	We may wish to move GrMovePtr into here, taking into account
	the change of window trees.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


WinMovePtr	proc	far
	push	ds
	LoadVarSeg	ds		; get kernel segment

	INT_OFF				; Can only process one at a time

					; Store latest pointer position
					; & window tree that ptr is on
	mov	ds:[wPtrLocAtWinMovePtr].P_x, cx
	mov	ds:[wPtrLocAtWinMovePtr].P_y, dx

	mov	ah, ds:[wPtrSUFlagsAtWinMovePtr]	; get old SU flags
							; (From last time
							; through)
	mov	ds:[wPtrSUFlagsAtWinMovePtr], al	; store new ones

					; See if same tree as last time
	cmp	bx, ds:[wPtrTreeAtWinMovePtr]
					; Store away latest tree for next time
	mov	ds:[wPtrTreeAtWinMovePtr], bx
	jne	sendWinChange		; if changed, then force sending of
					; win change

	; IF ptr has crossed into a save-under area, force sending of win change
	cmp	al, ah			; See if any differences
	je	testPtrChange		; if ptr hasn't changed between save
					; under areas, then just check ptr
					; change
sendWinChange:
	GOTO		WinSendWinChange, ds

testPtrChange:
					; Now test for change
	FALL_THRU	WinCheckPtr, ds

WinMovePtr	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinCheckPtr

DESCRIPTION:	Performs actual operation of checking to see if ptr is
		still in rectangle of region that it was last in,
		Notifies window system of pointer movement on a root tree,
		causing it to set status flags, & send out MSG_META_WIN_CHANGE
		if further work will be done.  NOTE:  this routine should
		be VERY fast.

CALLED BY:	INTERNAL
		WinReMovePtr, WinMovePtr
		NOTE:  May be called by any thread, without winTreeSem

PASS:
	bx - handle of root window that pointer is on
	cx - Ptr X position, in screen coordinates
	dx - Ptr Y position, in screen coordinates

	ds - segment of kernel variables
	INT's OFF
	on stack:	ds to be restored before returning

RETURN:

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	We may wish to move GrMovePtr into here, taking into account
	the change of window trees.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

WinCheckPtr	proc	far
	tst	ds:[wPtrChangeCount]	; If WIN_CHANGE's are pending, there
	jnz	WCP_MoveDone		; is no bounds for us to test against,
					; done.

					; see if in bounds as set by last pass
					; through WinChangeAck
	cmp	cx, ds:[wPtrTestBounds].R_left
	jl	WCP_PtrChange
	cmp	cx, ds:[wPtrTestBounds].R_right
	jg	WCP_PtrChange
	cmp	dx, ds:[wPtrTestBounds].R_top
	jl	WCP_PtrChange
	cmp	dx, ds:[wPtrTestBounds].R_bottom
	jg	WCP_PtrChange

WCP_MoveDone:
	INT_ON				; Allow ints again
	FALL_THRU_POP	ds		; return - still in rectangle
	ret

WCP_PtrChange:

if	ERROR_CHECK
					; Since we haven't pushed the
					; registers locally, we have to do
					; this so that we push before the
					; below FALL_THRU which turns into
					; a call & pop ds.  Since non-ec
					; version just turns into a pop, a
					; push, & a reload of ds, we can
					; just "if" the code out.

	FALL_THRU_POP	ds		; return - still in rectangle
	push	ds
	LoadVarSeg	ds		; get kernel segment
endif
					; Now send MSG_META_WIN_CHANGE
	FALL_THRU	WinSendWinChange, ds

WinCheckPtr	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinSendWinChange

DESCRIPTION:	Sends out a MSG_META_WIN_CHANGE, invalidates ptr test bounds

CALLED BY:	INTERNAL
		WinMovePtr, WinCheckPtr, WinForceWinChange
		NOTE:  May be called by any thread, without winTreeSem

PASS:
	bx - handle of root window that pointer is on
	cx - Ptr X position, in screen coordinates
	dx - Ptr Y position, in screen coordinates

	ds - segment of kernel variables
	INT's OFF
	on stack:	ds  to be restored before returning

RETURN:

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

WinSendWinChange	proc	far
	inc	ds:[wPtrChangeCount]	; inc count -- one more WIN_CHANGE
					; which must be processed  (Also,
					; is non-zero which indicates that
					; wPtrTestBounds are invalid)

	push	si
	push	di
	push	bp
					; Send MSG_META_WIN_CHANGE to Change
					; OD (normally UI Flow object)
	mov	bp, bx			; pass window tree in bp
	mov	bx, ds:[wPtrOutputOD].handle
	mov	si, ds:[wPtrOutputOD].chunk

	INT_ON

	mov	ax, MSG_META_WIN_CHANGE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	pop	bp
	pop	di
	pop	si

	FALL_THRU_POP	ds		; return - still in rectangle
	ret

WinSendWinChange	endp


WinMisc segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	WinGrabChange

DESCRIPTION:	Allows an object to grab Ptr events

CALLED BY:	EXTERNAL
		NOTE:  May be called by any thread, without winTreeSem

PASS:
	bx:si	- object to send change events to

RETURN:
	INT's ON
	carry - set if grabbed, clear if grab unsucessful

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@


WinGrabChange	proc	far	uses	ds
	.enter
	LoadVarSeg	ds		; get kernel segment
	INT_OFF
					; does anyone have grab?
	tst	ds:[wPtrOutputOD].handle
	jnz	WGC_110		; if so, branch out
				; Store new grab
	mov	ds:[wPtrOutputOD].handle, bx
	mov	ds:[wPtrOutputOD].chunk, si
	stc
	INT_ON
	pop	ds
	ret
WGC_110:
	clc			; return failure
	INT_ON
	.leave
	ret
WinGrabChange	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinReleaseChange

DESCRIPTION:	Allows an object to un-grab the change OD, if it had the grab

CALLED BY:	EXTERNAL
		NOTE:  May be called by any thread, without winTreeSem

PASS:
	bx:si	- object ungrabbing

RETURN:
	INT's ON

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

WinReleaseChange	proc	far	uses	ds
	.enter
	LoadVarSeg	ds		; get kernel segment
	INT_OFF
				; Make sure object had the grab
	cmp	ds:[wPtrOutputOD].handle, bx
	jne	WUC_110		; quit if not
	cmp	ds:[wPtrOutputOD].chunk, si
	jne	WUC_110		; quit if not

				; Zero out grab
	mov	ds:[wPtrOutputOD].handle, 0
	mov	ds:[wPtrOutputOD].chunk, 0
WUC_110:
	INT_ON
	.leave
	ret
WinReleaseChange	endp

WinMisc ends

;---

WinMovable segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinEnsureChangeNotification

DESCRIPTION:	Makes sure that if the window that the mouse is in has
		changed since the last sending of a MSG_META_WIN_CHANGE, that
		another MSG_META_WIN_CHANGE is sent out.  Used by the IM
		to make sure the UI has the correct implied window for
		processing position sensitive events like a button change.
		This is need because otherwise, the window sys only sends
		out one MSG_META_WIN_CHANGE at a time, & no more until the
		previous one is process (thereby avoiding zillions of
		backlogged window enter/leave events should the mouse be
		moved around while the UI is busy)

CALLED BY:	EXTERNAL
		NOTE:  May be called by any thread, without winTreeSem


PASS:	Nothing


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
	Doug	11/89		Initial version
------------------------------------------------------------------------------@

WinEnsureChangeNotification	proc	far
	push	ds
	LoadVarSeg	ds		; get kernel segment

	INT_OFF
					; See if we still know the bounds
					; that the ptr is inside of
	tst	ds:[wPtrChangeCount]	; if Non-zero, we don't
	pop	ds

	jnz	sendWinChange		; if not, then send another WIN_CHANGE
					; so that the UI will definitely know
					; which window the mouse is in before
					; processing its next important event
					; (Button, kbd, etc -- position
					; dependant stuff)  If we DO know where
					; the mouse is, then it must not have
					; moved outside of the region it was
					; enclosed in the last time we figured
					; out where it was.

	INT_ON
	ret

sendWinChange:
	push	ax
	push	bx
	push	cx
	push	dx
	call	WinForceWinChange
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

WinEnsureChangeNotification	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinChangePtrNotification

DESCRIPTION:	Notification that a window's visible region is being changed,
		so that we may fix any problems that may occur.

CALLED BY:	INTERNAL
		Window system validation routines
		NOTE:  caller must have winTreeSem

PASS:	bx	- window handle

RETURN:
	INT's ON

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

WinChangePtrNotification	proc	far
EC <	call	ECEnsureWinTreeSem					>
	push	ds
	LoadVarSeg	ds		; get kernel segment

	INT_OFF

	; BUG:  If the mouse is over a window having w/save-under, and that
	; window is closed, & another opened using the same save under area
	; of the video system, AND the next MSG_META_PTR to come in is over that
	; new window, WinMovePtr mistakenly saw that the save under areas the
	; mouse was over had not changed, & so did not issue a MSG_META_WIN_CHANGE.
	; This can happen relatively easy on a pen-based system (pick "Exit to
	; DOS" menu, then click in modal dialog that comes up -- the cursor
	; will stay modal when the dialog box is clicked in)
	;
	; SOLUTION:
	; Set save-under areas that the mouse is last reported as being over
	; back to none.  This will force a new MSG_META_WIN_CHANGE to occur if the
	; next MSG_META_PTR coming along indicates the mouse is over a save-under
	; area.  If the next MSG_META_PTR turns out to be over no save-under areas,
	; the mouse will be found to have moved off the box is was over 
	; anyway, also resulting in a MSG_META_WIN_CHANGE.
	;
	;	- Doug 2/18/92
	;
	mov	ds:[wPtrSUFlagsAtWinMovePtr], 0

					; See if we still know the bounds
					; that the ptr is inside of
	tst	ds:[wPtrChangeCount]	; if Non-zero, we don't
	pop	ds

	jz	sendWinChange		; if not, then we are waiting for
					; a WinChangeAck to see where the mouse
					; has gone, just return & wait
	INT_ON
	ret

sendWinChange:

					; Otherwise, we should worry about
					; the case that the window change
					; screws up the test bounds,
					; invalidating them -- force a
					; WIN_CHANGE, just in case
	push	ax
	push	bx
	push	cx
	push	dx
	call	WinForceWinChange
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

WinChangePtrNotification	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinForceWinChange

DESCRIPTION:	Forces out a MSG_META_WIN_CHANGE at last reported mouse position


CALLED BY:	INTERNAL
		NOTE:  May be called by any thread, without winTreeSem

PASS:
	Nothing

RETURN:
	INT's ON

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	We may wish to move GrMovePtr into here, taking into account
	the change of window trees.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/90		Initial version
------------------------------------------------------------------------------@


WinForceWinChange	proc	far
	push	ds
	LoadVarSeg	ds		; get kernel segment

	INT_OFF
					; Fetch last reported position of mouse
	mov	cx, ds:[wPtrLocAtWinMovePtr].P_x
	mov	dx, ds:[wPtrLocAtWinMovePtr].P_y
	mov	bx, ds:[wPtrTreeAtWinMovePtr]
	GOTO	WinSendWinChange, ds

WinForceWinChange	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinRedoMovePtr

DESCRIPTION:	Redoes last pointer move.


CALLED BY:	INTERNAL
		NOTE:  May be called by any thread, without winTreeSem

PASS:
	Nothing

RETURN:
	INT's ON

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	We may wish to move GrMovePtr into here, taking into account
	the change of window trees.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


WinRedoMovePtr	proc	far
	push	ds
	LoadVarSeg	ds		; get kernel segment

	INT_OFF
					; Fetch last reported position of mouse
	mov	cx, ds:[wPtrLocAtWinMovePtr].P_x
	mov	dx, ds:[wPtrLocAtWinMovePtr].P_y
	mov	bx, ds:[wPtrTreeAtWinMovePtr]
	GOTO	WinCheckPtr, ds

WinRedoMovePtr	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinDeathPtrNotification

DESCRIPTION:	Notification of window being destroyed (i.e., handle being
		nuked).  Used to prevent nasty problems w/referring to 
		destroyed window handles.

CALLED BY:	INTERNAL
		WinClose
		NOTE:  caller must have winTreeSem

PASS:	bx	- window handle
	di	- parent window handle (or 0 if none)

RETURN:
	INT's ON

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version
------------------------------------------------------------------------------@

WinDeathPtrNotification	proc	near	uses	ds
	.enter
EC <	call	ECEnsureWinTreeSem					>
	LoadVarSeg	ds		; get kernel segment

EC <	; This case should NEVER happen - the ptr should always do a 	>
EC <	; RAW_LEAVE before this routine is allowed to be called		>
EC <	cmp	bx, ds:[wPtrImpliedWin]		; if was last win,	>
EC <	ERROR_Z	WIN_PTR_SHOULD_HAVE_LEFT_CLOSING_WINDOW_BY_NOW	; blow up  >

if      (WIN_ENTER_LEAVE_CONTROL)
EC <	cmp	bx, ds:[wPtrLastGrabWin]	; if was last grab win,	>
EC <	ERROR_Z	WIN_CAN_NOT_CLOSE_GRABBED_WINDOW	; blow up	>

	cmp	bx, ds:[wPtrWinAtGrab]		; if was grab window,
	jne	WPCN_30
	mov	ds:[wPtrWinAtGrab], di		; then change to use parent
	or	di, di
	jnz	WPCN_30
	mov	ds:[wPtrTreeAtGrab], di		; if off top, change grab tree
WPCN_30:					; to be none, as well.

	cmp	bx, ds:[wPtrWinAtExclude]	; top of excluded branch?
	jne	WPCN_50
	mov	ds:[wPtrWinAtExclude], 0	; if so, won't need to ever
						; include again.
WPCN_50:
endif
	.leave
	ret
WinDeathPtrNotification	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinChangeAck

DESCRIPTION:	Called to acknowledge a MSG_META_WIN_CHANGE, this function
		generates MSG_ENTER & MSG_LEAVE events for any windows
		which the mouse may have moved across

CALLED BY:	EXTERNAL
		NOTE: must be called by same thread which runs wPtrOutputOD

CALLED BY AS OF 2/19/92:
        FlowWinChange method FlowClass, MSG_META_WIN_CHANGE


PASS:
	cx, dx	- screen location to traverse to
	bp	- window handle of tree to traverse to

RETURN:
	cx:dx	- enter/leave Output Descriptor for that window (0 if none)
	bp	- handle of window that ptr is in

	NOTE:  if window(s) grabbed, then the above info is returned only
	       if the window has the grab.

DESTROYED:
	Nothing

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


WinChangeAck	proc	far	uses	ax, si, di, es
	.enter
	call	FarPWinTree		; make sure tree doesn't change on us
					;  es <- idata

					; No MSG_META_IMPLIED_WIN_CHANGE sent
					; yet.
	and	es:[wPtrChangeFlags], not mask WCF_IMPLIED_CHANGE_SENT

	mov	bx, bp			; get window tree in bx

;EC <	tst	bx						>
;EC <	ERROR_Z	WIN_CHANGE_ACK_MISSING_TREE_ARG			>

	call	WinCommonTraverse	; Traverse tree, update
					; does VSem of winTreeSem

					; Returns current window, input OD
					; of ptr, unless grab, in which case
					; only returns data if window marked
					; as having grab.  (if not, returns 0)

					; Redo at last location, just in case
					; some change occured while we were
					; working

	INT_OFF
	push	ds
	LoadVarSeg	ds
	dec	ds:[wPtrChangeCount]	; dec count -- one less WIN_CHANGE
					; Indicates that ptr test bounds may
					; be tested agains as valid, if this
					; var reaches 0
	pop	ds
	INT_ON

	push	cx			; Preserve window, Input OD
	push	dx
	push	bp
	call	WinRedoMovePtr		; In case no more WIN_CHANGE's, pay
					; better attention to the last reported
					; mouse position -- it might have 
					; wandered out already.
	pop	bp
	pop	dx
	pop	cx

	.leave
	ret

WinChangeAck	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinMouseGrab

DESCRIPTION:	Called to grab mouse for this window.  If this is the
		first window to be grabbed after a period when none were 
		grabbed, then causes window system to enter "MOUSE_GRABBED"
		mode:  Basically halts MSG_META_UNIV_ENTER & MSG_META_VIS_ENTER
		from being sent, though MSG_META_UNIV_LEAVE & MSG_META_VIS_LEAVE
		will be sent out when the mouse leaves, but only once, if
		the mouse was in the window when the grab stared.  Causes
		WinChangeAck to only return the mouse as being
		in windows which have the grab.  If the ptr is outside
		of these windows, then WinChangeAck will return 0.
		This behavior will continue until the last window
		which was WinMouseGrab'ed is Released, at which time
		enter & leave info is updated.


CALLED BY:	EXTERNAL
		NOTE: must be called by same thread which runs wPtrOutputOD

CALLED BY AS OF 2/19/92:
	OLPaneButton method OLPaneClass, MSG_META_END_SELECT,
                                        MSG_META_DRAG_SELECT,
                                        MSG_META_START_MOVE_COPY,
                                        MSG_META_DRAG_MOVE_COPY,
                                        MSG_META_DRAG_FEATURES,
                                        MSG_META_START_OTHER,
                                        MSG_META_END_OTHER,
                                        MSG_META_DRAG_OTHER
        OpenWinStartupGrab method OLWinClass, MSG_OL_WIN_STARTUP_GRAB
                OLMenuButtonLeaveStayUpMode method OLMenuButtonClass,
                        		MSG_MO_MB_LEAVE_STAY_UP_MODE
                OLMenuWinActivate method OLMenuWinClass, MSG_OL_POPUP_ACTIVATE
                OpenWinStartButton
                        OpenWinStartSelect method OLWinClass,
                                	MSG_META_START_SELECT,
					MSG_META_START_MOVE_COPY
                        OpenWinStartMenu method OLWinClass,
                                	MSG_META_START_FEATURES

PASS:
	di	- window to grab mouse for

RETURN:
	cx:dx	- enter/leave Output Descriptor for that window (0 if none)
	bp	- handle of window that ptr is in

	NOTE:  if window(s) grabbed, then the above info is returned only
	       if the window has the grab.

DESTROYED:
	Nothing

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.


REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


if	(WIN_ENTER_LEAVE_CONTROL)
WinMouseGrab	proc	far	uses	ax, si, di, ds, es
	.enter
	call	PWinTree		; es <- idata
					; No MSG_META_IMPLIED_WIN_CHANGE sent
					; yet.
	and	es:[wPtrChangeFlags], not mask WCF_IMPLIED_CHANGE_SENT

	inc	es:[wPtrGrabCount]	; inc grab count

EC <	cmp	es:[wPtrGrabCount], MAX_GRABBED_WINDOWS			>
EC <	ERROR_A	WIN_TOO_MANY_GRABBED_WINDOWS				>

	cmp	es:[wPtrGrabCount], 1	; see if first window to be grabbed
	jne	afterStartingWinGrab	; skip if not

;startingWinGrab:
	; OTHERWISE, save window & tree of ptr at time of grab, so that we
	; can pick up UNIV_ENTER & LEAVE again when the grabs finally end
	;
	mov	ax, es:[wPtrImpliedWin]	; Save window ptr was last in
	mov	es:[wPtrWinAtGrab], ax
	mov	ax, es:[wPtrLastTree]	; & tree
	mov	es:[wPtrTreeAtGrab], ax

					; Initially, there are no grabbed
					; windows.  Therefore, the pointer
					; isn't in any of them. (This situation
					; may change shortly -- see below)
	mov	es:[wPtrLastGrabWin], 0

					; Mark mouse as grabbed.
	or	es:[wPtrChangeFlags], mask WCF_MOUSE_GRABBED

	mov	bx, di
	call	NearPLockDS		; lock window
	mov	cx, ds:[W_inputObj].handle	; pass InputOD in cx:dx
	mov	dx, ds:[W_inputObj].chunk
	mov	bp, di				; pass window in bp
	mov	bx, ds:[LMBH_handle]
	call	NearUnlockV		; release window

					; Let output OD know of status change
	mov	ax, MSG_META_WIN_GRAB_ACTIVE
	call	WinSendViaPtrEventQueue

afterStartingWinGrab:
	mov	bx, di
	call	NearPLockDS		; lock window
					; Mark window as grabbed
	or	ds:[W_ptrFlags], mask WPF_WIN_GRABBED

	test	ds:[W_ptrFlags], mask WPF_PTR_IN_VIS	; is ptr here?
	jz	WMG_20
	mov	es:[wPtrLastGrabWin], bx		; if so, store as last
							; grab window w/ptr
WMG_20:


	mov	bx, ds:[LMBH_handle]
	call	NearUnlockV		; release window

	call	WinCommonEnd		; Send events, release winTreeSem,
					; return implied grab info

	.leave
	ret
WinMouseGrab	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinMouseRelease

DESCRIPTION:	Called to release mouse for this window.  If this is the
		last window to be released, then this ends the MOUSE_GRABBED
		mode of operation:  Causes enter/leave methods to
		be sent out for any changes in ptr position from when grab
		occurred,  such as when the mouse is currently over
		a window which DOESN't have a window grab.


CALLED BY:	EXTERNAL
		NOTE: must be called by same thread which runs wPtrOutputOD

CALLED BY AS OF 2/19/92:
	ClearPaneWinWindowGrab
		OLPanePostPassive method OLPaneClass, MSG_META_POST_PASSIVE_BUTTON
		OLPaneEndGrab method OLPaneClass, MSG_VIS_LOST_GADGET_EXCL
	OpenWinEndGrab, method OLWinClass, MSG_OL_WIN_END_GRAB

PASS:
	di	- window to release mouse for

RETURN:
	cx:dx	- enter/leave Output Descriptor for that window (0 if none)
	bp	- handle of window that ptr is in

	NOTE:  if window(s) grabbed, then the above info is returned only
	       if the window has the grab.

DESTROYED:
	Nothing

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

if      (WIN_ENTER_LEAVE_CONTROL)
WinMouseRelease	proc	far	uses ax, si, di, ds, es
	.enter
	call	PWinTree		; es <- idata
					; No MSG_META_IMPLIED_WIN_CHANGE sent
					; yet.
	and	es:[wPtrChangeFlags], not mask WCF_IMPLIED_CHANGE_SENT

	mov	bx, di
	call	NearPLockDS		; lock window

					; Mark window as no longer grabbed
	and	ds:[W_ptrFlags], not (mask WPF_WIN_GRABBED)

	mov	bx, ds:[LMBH_handle]
	cmp	es:[wPtrLastGrabWin], bx	; was this the last grab
					; window that the mouse was in?
	jne	WMR_20			; skip if not
	mov	es:[wPtrLastGrabWin], 0	; clear to no window
WMR_20:

	call	NearUnlockV		; release window

EC <	tst	es:[wPtrGrabCount]					>
EC <	ERROR_Z	WIN_GRAB_COUNT_0_ON_RELEASE				>

	dec	es:[wPtrGrabCount]	; decrement # of windows grabbed
	jne	stillGrabbed		; if still MOUSE_GRABBED, just
					; send implied win change info &
					; release winTreeSem.

					; Let output OD know of status change
	mov	ax, MSG_META_WIN_GRAB_NOT_ACTIVE
	call	WinSendViaPtrEventQueue

	call	WinReTraverseHere	; In case windows/save-under, etc.
					; has changed, re-traverse from current
					; win to current loc, JUST to make
					; sure that wPtrImpliedWin is really where
					; the mouse is.

	segmov	ds, es
	mov	bx, ds:[wPtrLastTree]	; Traverse TO last processed point,
					;	which should end up to be the
					;	window that the mouse is
					;	currently in. (wPtrImpliedWin)
	mov	cx, ds:[wPtrLastLoc].P_x
	mov	dx, ds:[wPtrLastLoc].P_y

	; Case for needing to use REAL dest window:  Put menu in stay-up
	; mode.  Move down & click on menu item.  This traversal will
	; try to take us from Primary to onto the menu -- the universes
	; of menu & primary overlap, & ptr starting on primary, & so without
	; using REAL dest window will end up inside of the primary.
	;
					; Traverse FROM window that ptr was
					; in when grab started.
	mov	ax, ds:[wPtrWinAtGrab]
	mov	ds:[wPtrImpliedWin], ax	; Get window ptr was in when grab
	mov	ax, ds:[wPtrTreeAtGrab]	;	started.
	mov	ds:[wPtrLastTree], ax	; & tree

	clr	ax
	mov	ds:[wPtrWinAtGrab], ax	; clear variables
	mov	ds:[wPtrTreeAtGrab], ax
	mov	ds:[wPtrLastGrabWin], ax
					; Mark mouse as not grabbed.
	and	ds:[wPtrChangeFlags], not (mask WCF_MOUSE_GRABBED)

					; Now, traverse tree from grab window
					; to current position, sending out
					; enters & leaves that have occured.

	segmov	es, ds			; get kernel segment in es, for
					;	WinCommonTraverse
	call	WinCommonTraverse	; Traverse tree, update
					; does VSem of winTreeSem

					; Returns current window, input OD
					; of ptr, unless grab, in which case
					; only returns data if window marked
					; as having grab.  (if not, returns 0)
	jmp	short done

stillGrabbed:
	call	WinCommonEnd		; Send events, release winTreeSem,
					; return implied grab info
done:
	.leave
	ret
WinMouseRelease	endp
endif





COMMENT @----------------------------------------------------------------------

FUNCTION:	WinBranchExclude

DESCRIPTION:	Called to exclude this branch from receiving UNIV_ENTER/
		& UNIV_LEAVE events.  NOTE:  WinBranchExclude may NOT
		be called on any window having a child or parent which 
		is excluded.  The UI maintains this criteria by using this
		routine only on windows which lie directly on the field
		window.


CALLED BY:	EXTERNAL
		NOTE: must be called by same thread which runs wPtrOutputOD

CALLED BY AS OF 2/19/92:
	VisExcludeWin, method VisClass, MSG_VIS_EXCLUDE_WIN
		OLSystemWinOnFieldRawLeaveNotification  method OLSystemClass, \
			MSG_GEN_SYSTEM_WIN_ON_FIELD_RAW_LEAVE_NOTIFICATION
			        VisRawUnivEnterLeave, method VisClass, \
					MSG_META_RAW_UNIV_LEAVE
				OpenWinRawUnivLeave     method OLWinClass, \
					MSG_META_RAW_UNIV_LEAVE

		OLSystemEnsureMouseNotTrespassing       method OLSystemClass, \
                        	MSG_OL_SYSTEM_ENSURE_MOUSE_NOT_TRESPASSING
			OLAppResumeInput method OLApplicationClass, \
                                                MSG_GEN_APPLICATION_IGNORE_INPUT
			OLPopupWinGainedModalExcl OLPopupWinClass, \
                                        	MSG_META_GAINED_MODAL_EXCL
			    ForceGrabModalWinExcl
				OLAppReleaseModalExcl method OLApplicationClass,
                                		MSG_OL_APP_RELEASE_MODAL_EXCL
				    OLPopupWinVisClose method OLPopupWinClass,
						MSG_VIS_CLOSE
				OLAppGrabModalExcl, method OLApplicationClass,
						MSG_OL_APP_GRAB_MODAL_EXCL
				    OLPopupBringToTop method OLPopupWinClass,
						MSG_GEN_BRING_TO_TOP

PASS:
	di	- window at head of branch to exlude

RETURN:
	cx:dx	- enter/leave Output Descriptor for that window (0 if none)
	bp	- handle of window that ptr is in

	NOTE:  if window(s) grabbed, then the above info is returned only
	       if the window has the grab.


DESTROYED:
	Nothing

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


if      (WIN_ENTER_LEAVE_CONTROL)
WinBranchExclude	proc	far	uses	ax, si, di, ds, es
	.enter
	call	PWinTree		; es <- idata
					; No MSG_META_IMPLIED_WIN_CHANGE sent
					; yet.
	and	es:[wPtrChangeFlags], not mask WCF_IMPLIED_CHANGE_SENT

	mov	bx, di
	call	NearPLockDS		; lock window
					; Mark window as excluded
	or	ds:[W_ptrFlags], mask WPF_WIN_BRANCH_EXCLUDED

	test	ds:[W_ptrFlags], mask WPF_PTR_IN_UNIV	; is ptr in here?
	jnz	WBE_Exclude				; If so, branch to
							; get out of window
					; If not, just...
	call	NearUnlockV		; release window

	call	WinCommonEnd		; Send events, release winTreeSem,
					; return implied grab info
	jmp	short WBE_Done


WBE_Exclude:
	call	NearUnlockV		; release window

	mov	es:[wPtrWinAtExclude], bx		; if so, store as last
							; exclude branch we're

	; Traverse from current window to branch head, sending VIS_LEAVE &
	; UNIV_LEAVE to all windows on path.

	mov	bx, es:[wPtrImpliedWin]	; get last window we were in
	call	WinTraverseOut		; traverse out from there

	call	WinCommonEnd		; Send events, release winTreeSem,
					; return implied grab info

WBE_Done:
	.leave
	ret
WinBranchExclude	endp
endif




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinBranchInclude

DESCRIPTION:	Called to allow branch to have implied window grab
		NOTE:  WinBranchInclude may NOT be called on any window
		having a child or parent which is excluded.  The UI maintains
		this criteria by using this routine only on windows which
		lie directly on the field window.


CALLED BY:	EXTERNAL
		NOTE: must be called by same thread which runs wPtrOutputOD

CALLED BY AS OF 2/19/92:
	VisIncludeWin, method VisClass, MSG_VIS_INCLUDE_WIN
		OLSystemWinOnFieldRawEnterNotification  method OLSystemClass, \
                	MSG_GEN_SYSTEM_WIN_ON_FIELD_RAW_ENTER_NOTIFICATION
				VisRawUnivEnterLeave, method VisClass, \
					MSG_META_RAW_UNIV_ENTER
				OpenWinRawUnivEnter     method OLWinClass, \
					MSG_META_RAW_UNIV_ENTER
		OLSystemEnsureMouseRightOfWay   method dynamic  OLSystemClass, \
                                MSG_OL_SYSTEM_ENSURE_MOUSE_RIGHT_OF_WAY
			OLAppAcceptInput dynamic  OLApplicationClass, \
                                                MSG_GEN_APPLICATION_ACCEPT_INPUT
			OLPopupWinGainedModalExcl OLPopupWinClass, \
                                        	MSG_META_GAINED_MODAL_EXCL
			    ForceGrabModalWinExcl
				OLAppReleaseModalExcl method OLApplicationClass,
                                		MSG_OL_APP_RELEASE_MODAL_EXCL
				    OLPopupWinVisClose method OLPopupWinClass,
						MSG_VIS_CLOSE
				OLAppGrabModalExcl, method OLApplicationClass,
						MSG_OL_APP_GRAB_MODAL_EXCL
				    OLPopupBringToTop method OLPopupWinClass,
						MSG_GEN_BRING_TO_TOP

PASS:
	di	- window at head of branch to include.

RETURN:
	cx:dx	- enter/leave Output Descriptor for that window (0 if none)
	bp	- handle of window that ptr is in

	NOTE:  if window(s) grabbed, then the above info is returned only
	       if the window has the grab.


DESTROYED:
	Nothing

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.


REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


if      (WIN_ENTER_LEAVE_CONTROL)
WinBranchInclude	proc	far	uses	ax, si, di, ds, es
	.enter
	call	PWinTree		; es <- idata
					; No MSG_META_IMPLIED_WIN_CHANGE sent
					; yet.
	and	es:[wPtrChangeFlags], not mask WCF_IMPLIED_CHANGE_SENT

	mov	bx, di
	call	NearPLockDS		; lock window

					; Mark window as included
	and	ds:[W_ptrFlags], not (mask WPF_WIN_BRANCH_EXCLUDED)

	mov	bx, ds:[LMBH_handle]
	call	NearUnlockV		; release window

	cmp	es:[wPtrWinAtExclude], bx
					; Is the ptr in this branch?
	je	WBI_Traverse		; If so, then update ENTER/LEAVE stuff


	call	WinCommonEnd		; Send events, release winTreeSem,
					; return implied grab info
	jmp	short WPI_End		; & all done.

WBI_Traverse:
	call	WinReTraverseHere	; In case windows/save-under, etc.
					; has changed, re-traverse from current
					; win to current loc, JUST to make
					; sure that wPtrImpliedWin is really where
					; the mouse is.

	mov	bx, es:[wPtrLastTree]	; Traverse TO last processed point
	mov	cx, es:[wPtrLastLoc].P_x
	mov	dx, es:[wPtrLastLoc].P_y

	; THIS fix would only be needed if we allowed child windows of
	; windows which may be excluded to have save-under -- image being over
	; a window w/save-under which is a child of a dialg box, when that
	; dialog box is suddenly included -- the traversal starting from
	; the dialg box would just presume that that's where the mouse was,
	; since the mouse would be in that window's visible universe.  We
	; could easily decide just to not allow that case & therefore
	; not have to deal with this.
	;
					; Traverse FROM top of branch that
					; was excluded.
	mov	ax, es:[wPtrWinAtExclude]
	mov	es:[wPtrImpliedWin], ax	; Get window ptr was in when exclude
					;	started.
					; Traverse from same tree, since we're
					; already in this window.

					; clear to not in an excluded branch.
	clr	ax
	mov	es:[wPtrWinAtExclude], ax

					; Now, traverse tree from exclude window
					; to current position, sending out
					; enters & leaves that have occured.

	call	WinCommonTraverse	; Traverse tree, update
					; does VSem of winTreeSem

					; Returns current window, input OD
					; of ptr, unless grab, in which case
					; only returns data if window marked
					; as having grab.  (if not, returns 0)
WPI_End:
	.leave
	ret

WinBranchInclude	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinTraverseOut

DESCRIPTION:	Traverses from current window to branch head, sending
		VIS_LEAVE & UNIV_LEAVE's to all windows on path.  This
		function is needed in order to "push" the mouse out of a
		window branch, which it has been excluded from.

CALLED BY:	INTERNAL
		WinBranchExclude

PASS:
	winTreeSem	- P'd
	es		- kernel segment

	bx	- window handle to start in (non-zero)
	es:[wPtrWinAtExclude]	- window to stop at (leave this one last)

RETURN:
	cx, dx, es	- intact

DESTROYED:
	ax, bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/89		Initial version
------------------------------------------------------------------------------@


if      (WIN_ENTER_LEAVE_CONTROL)
WinTraverseOut	proc	near
EC <	call	ECEnsureWinTreeSem					>

traverseLoop:
	call	NearPLockDS		; lock window

	call	EnsureVisLeave		; Make sure that the window has been
					; visibly left (Send MSG_META_VIS_LEAVE
					; if needed to get it out)

	call	EnsureUnivLeave		; Make sure that the window has been
					; universe left (Send MSG_META_UNIV_LEAVE
					; if needed to get it out)

	mov	si, ds:[W_parent]	; get parent handle
	mov	bx, ds:[LMBH_handle]		; unlock old window
	call	NearUnlockV
	cmp	bx, es:[wPtrWinAtExclude]
	je	foundTopOfBranch

	mov	bx, si			; prepare to do new window
	jmp	short traverseLoop

foundTopOfBranch:
	ret

WinTraverseOut	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinCommonTraverse

DESCRIPTION	Common section of code to traverse tree from wPtrImpliedWin to
		current position as reported by WinMovePtr.

CALLED BY:	INTERNAL
		WinChangeAck

PASS:
	winTreeSem	- P'd
	es		- kernel segment

	wPtrLastTree	- window tree to traverse from
	wPtrImpliedWin	- window to traverse from

	bx		- window tree to traverse to
	cx, dx		- x, y screen position to traverse to

RETURN:
	cx:dx	- enter/leave Output Descriptor for that window (0 if none)
	bp	- handle of window that ptr is in

	NOTE:  if window(s) grabbed, then the above info is returned only
	       if the window has the grab.

	es		- intact

DESTROYED:
	ax, si, di

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


WinCommonTraverse	proc	near	uses	ds
	.enter
EC <	call	ECEnsureWinTreeSem					>

	mov	bp, bx			; place tree handle to travel TO in bp

	mov	di, es:[wPtrLastTree]	; Put tree to start at in di,
	mov	bx, es:[wPtrImpliedWin]	; and window to start at in bx

	cmp	di, bp			; see if changing trees
	je	traverseAndFinish	; if not, just traverse to new point

;changingTrees:
	push	bp			; save tree to walk onto for later

	push	cx			; save location to walk onto
	push	dx
	mov	cx, EOREGREC		; claim point is off screen
	mov	dx, cx
	call	WinTraverseHere		; & walk off of this tree altogether
	pop	dx
	pop	cx

	pop	di			; put tree to start at in di
	mov	bx, di			; & place window (same as tree) in bx

traverseAndFinish:
	call	WinTraverseHere

;done:
	call	WinCommonEnd		; Send out events, release winTreeSem,
					; return implied grab info
	.leave
	ret

WinCommonTraverse	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinCommonEnd

DESCRIPTION:	Finish up many of the Win notification routines, by V'ing
		the win tree semaphore, sending any events that we've queued
		up, & returning some interesting info that the caller might
		be interested in.

CALLED BY:	INTERNAL

PASS:
	winTreeSem	- P'd
	es		- kernel segment

RETURN:
	cx:dx	- enter/leave Output Descriptor for that window (0 if none)
	bp	- handle of window that ptr is in
	winTreeSem	- V'd

DESTROYED:
	ax, bx, si, di

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

WinCommonEnd	proc	near
EC <	call	ECEnsureWinTreeSem					>
	; In case ptr isn't in ANY window, set ptr test bounds to invalid
	; (EOREGREC), so that any comparison would yield ptr OUT of region
	;
	tst	es:[wPtrImpliedWin]
	jnz	boundsValid
				; Mark bounds as invalid - not sure
				; where ptr is (More WIN_CHANGE's in queue)
	mov	es:[wPtrTestBounds].R_left, EOREGREC
	mov	es:[wPtrTestBounds].R_right, EOREGREC
boundsValid:

	; If a MSG_META_IMPLIED_WIN_CHANGE hasn't been sent yet, do so.
	;
	call	SendImpliedChangeEvent

					; Get access to W_*PtrImage variables,
					; wPtrFinalWin, wPtrFinalGeode,
					; & routines
					; ActivateWinPtrImages,
					; LayerActivePtrImage.

	PSem	es, winPtrImageSem, TRASH_AX_BX

	call	UpdatePtrImages		; Update PIL_GADGET, PIL_WINDOW,
					; PIL_LAYER ponter images

	VSem	es, winPtrImageSem, TRASH_AX_BX

	; Fetch optr of implied win in cx:dx, while we have semaphore
	;
	call	GetImpliedOD

	; ... plus process owning window & window mouse is physically over.
	;
	mov	bx, es:[wPtrImpliedWinProc]; Return process owning window
	mov	bp, es:[wPtrImpliedWin]	; Return window mouse is physically over

	push	cx		; preserve implied grab OD
	push	dx
	push	bp		; preserve window that ptr is in

				; Read in all events sent to ptrEventQueue,
				; process with new implied window, & stuff
				; into outgoing ptrSendQueue.
	call	WinProcessEventQueue

				; Release semaphore, so window system
				; can continue to function.
	call	FarVWinTree

				; Send events, outside of semaphore, so
				; that the methods called can perform
				; operations on the window system.  This
				; routine will check to see if this is a
				; reentrant call, in which case it will just
				; return, & rely on top level call to 
				; finish dispatching.
	call	WinFlushSendQueue

	pop	bp
	pop	dx
	pop	cx
	ret
WinCommonEnd	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdatePtrImages

DESCRIPTION:	

CALLED BY:	INTERNAL
		WinCommonEnd

PASS:
	winTreeSem	- P'd
	winPtrImageSem	- P'd
	es		- kernel segment

RETURN:
	nothing

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/91		Initial version
------------------------------------------------------------------------------@

UpdatePtrImages	proc	near	uses	bx, bp
	.enter
EC <	call	ECEnsureWinTreeSem					>
	; See if change in final window/layer
	;
	call	GetFinalWinAndGeode	; Get final Window into bx, geode in bp
	push	bp			; save final geode

	mov	bp, bx			; copy new final window to bp
	xchg	bp, es:[wPtrFinalWin]	; store new final win, get old
	cmp	bx, bp
					; if same, skip messing w/ptr changes
	je	afterFinalWinChange

	; Update PIL_GADGET & PIL_WINDOW Pointer Image Levels.
	;
	call	ActivateWinPtrImages	; Use ptr images of this window
afterFinalWinChange:
	pop	bx			; get final geode

	mov	bp, bx			; copy new final geode to bp
	xchg	bp, es:[wPtrFinalGeode]	; store new final geode,
						; get old
	cmp	bx, bp
					; if same, skip messing w/ptr changes
	je	afterActiveGeodeChange

	; Update PIL_GEODE Pointer Image Level
	;
	call	ActivateGeodePtrImage
afterActiveGeodeChange:

	.leave
	ret
UpdatePtrImages	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GetImpliedOD

DESCRIPTION:	Fetch Input OD of implied window.
		This version of the routine returns the absolute
		current information as can only be attained while
		have the winTreeSem.

CALLED BY:	INTERNAL
		WinCommonEnd

PASS:
	winTreeSem	- P'd
	es	- kernel seg

RETURN:
	cx:dx	- implied grab OD

DESTROYED:
	bp


REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
------------------------------------------------------------------------------@


GetImpliedOD	proc	near
EC <	call	ECEnsureWinTreeSem					>
if      (WIN_ENTER_LEAVE_CONTROL)
	tst	es:[wPtrWinAtExclude]	; Make sure we're not in an excluded
					; area
	jnz	noImpliedOD		; if so, then no implied grab
endif

					; get OD of window mouse is over
	mov	cx, es:[wPtrImpliedWinOD].handle
	mov	dx, es:[wPtrImpliedWinOD].chunk

if      (WIN_ENTER_LEAVE_CONTROL)
					; Is the window system in a grab mode?
	test	es:[wPtrChangeFlags], mask WCF_MOUSE_GRABBED
	jz	done		; skip if not

	mov	bp, es:[wPtrImpliedWin]	; get window that ptr is physically over
	cmp	bp, es:[wPtrLastGrabWin]; is this window the same as the
					; last grabbed window the ptr was in?
	je	done			; if so, allow data to be returned.

noImpliedOD:
	clr	cx			; no implied OD
	clr	dx

done:
endif
	ret
GetImpliedOD	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetFinalWinAndGeode

DESCRIPTION:	Fetches final window (i.e. the one the mouse is over &
		included in, or if a mouse grab in progress, the last
		grabbed window the mouse was over) & its geode.
		This version of the routine returns the absolute
		current information as can only be attained while
		having the winTreeSem.

CALLED BY:	INTERNAL
		UpdatePtrImages

PASS:
	winTreeSem	- P'd
	winPtrImageSem	- P'd
	es	- kernel seg

RETURN:
	bx	- final Window
	bp	- final geode

DESTROYED:
	Nothing


REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/91		Initial version
------------------------------------------------------------------------------@

GetFinalWinAndGeode	proc	near
	.enter
EC <	call	ECEnsureWinTreeSem					>
if      (WIN_ENTER_LEAVE_CONTROL)
	; If over an excluded area, no final Window or geode.
	;
	tst	es:[wPtrWinAtExclude]
	jnz	noFinalWin

	; Is the window system in a grab mode?  If so, use last grabbed
	; window that mouse was in, else nothing.
	;
	mov	bx, es:[wPtrLastGrabWin]
	test	es:[wPtrChangeFlags], mask WCF_MOUSE_GRABBED
	jnz	thisWin
endif

	; OK, no exclusions, no "WinMouseGrab" state.  Utilize new thinking
	; here:  If no active geode, return the overall implied window.
	;
	mov	bx, es:[wPtrImpliedWin]	; get window that ptr is physically over
	mov	bp, es:[wPtrActiveGeode]
	tst	bp
	jz	thisWin


	; If there IS an active geode, i.e. mouse is down inside of a window
	; of the geode, then see if overall implied window belongs to geode
	;
	tst	bx
	jz	haveImpliedWin
	push	bx
	call	MemOwnerFar
	cmp	bp, bx
	pop	bx
	je	haveImpliedWin
	clr	bx
haveImpliedWin:
	jmp	short checkForActiveWinOverride

thisWin:
	clr	bp			; No layer yet
	tst	bx
	jz	done
	push	bx
	call	MemOwnerFar
	mov	bp, bx
	pop	bx

checkForActiveWinOverride:
	; bx = win, bp = geode
	;
	tst	bp
	jz	done
	xchg	bx, bp
	push	si, ds
	push	es
	pop	ds
	call	ReadGeodeWinVars
	tst	ds:[si].GWV_activeWin
	jz	haveFinalWinInGeode
	mov	bp, ds:[si].GWV_activeWin
haveFinalWinInGeode:
	pop	si, ds
	xchg	bx, bp
if      (WIN_ENTER_LEAVE_CONTROL)
	jmp	short done		; final last in

noFinalWin:
	clr	bx			; no final window
	clr	bp
endif

done:
	.leave
	ret
GetFinalWinAndGeode	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ActivateWinPtrImages

DESCRIPTION:	Takes gadget & window ptr images stored in the window passed
		& calls the IM to set these as the current images for the
		PIL_GADGET & PIL_WINDOW levels.  The caller must make certain
		that the window being passed is indeed the final one, with
		rights to do this...

CALLED BY:	INTERNAL
		UpdatePtrImages

PASS:	bx	- Window whose ptr images should be used,
		  OR, 0 to clear ptr images for these levels
	winPtrImageSem	- P'd

RETURN: nothing

DESTROYED:
	nothing


REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/91		Initial version
------------------------------------------------------------------------------@

ActivateWinPtrImages	proc	near
	uses	cx, dx, si, di, bp
	.enter

	clr	cx			; Presume null ptr images
	clr	dx
	clr	si
	clr	di

	tst	bx			; see if no final window
	jz	havePtrImages		; if so, use null ptr images

	push	ax, ds
	call	WinPLockDS
	mov	cx, ds:[W_gadgetPtrImage].handle
	mov	dx, ds:[W_gadgetPtrImage].chunk
	mov	si, ds:[W_windowPtrImage].handle
	mov	di, ds:[W_windowPtrImage].chunk
	call	WinUnlockV
	pop	ax, ds

havePtrImages:
	mov	bp, PIL_GADGET		; set gadget level image
	call	ImSetPtrImage

	mov	cx, si
	mov	dx, di

	mov	bp, PIL_WINDOW		; set window level image
	call	ImSetPtrImage
	.leave
	ret

ActivateWinPtrImages	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ActivateGeodePtrImage

DESCRIPTION:	Takes geode ptr image, as
		stored in the geode referenced by the window passed
		& calls the IM to set these as the current images.
		The caller must make certain that the geode being passed is
		the one with rights to do this...

CALLED BY:	INTERNAL
		UpdatePtrImages
		WinCommonEnd

PASS:	
	bx	- geode whose ptr images should be used,
	  	  OR, 0 to clear ptr images for these levels
	winPtrImageSem	- P'd
	es	- kernel seg

RETURN:
	nothing

DESTROYED:
	nothing


REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/91		Initial version
------------------------------------------------------------------------------@

ActivateGeodePtrImage	proc	near
	uses	cx, dx, bp
	.enter
	clr	cx			; Presume null ptr images
	clr	dx

	tst	bx			; see if no final geode
	jz	havePtrImages		; if so, use null ptr images

	
	push	si, ds
	push	es
	pop	ds
	call	ReadGeodeWinVars
	mov	cx, ds:[si].GWV_ptrImage.handle
	mov	dx, ds:[si].GWV_ptrImage.chunk
	pop	si, ds

havePtrImages:
	mov	bp, PIL_GEODE
	call	ImSetPtrImage
	.leave
	ret
ActivateGeodePtrImage	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinReTraverseHere

DESCRIPTION:	Traverse window system from last window & tree that we thought
		the mouse was in to the last location the mouse was.  

CALLED BY:	INTERNAL
		WinMouseRelease
		WinBranchInclude

PASS:
	es	- segment of kernel data

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/90		Initial version
------------------------------------------------------------------------------@


if      (WIN_ENTER_LEAVE_CONTROL)
WinReTraverseHere	proc	near
					; Traverse from last window & tree we
					; thought the mouse was in, to the same
					; tree & same point as last recorded 
					; (Will do nothing most of the time, but
					; will update the wPtrImpliedWin if the
					; windows have changed out from under
					; the mouse)
	mov	bx, es:[wPtrImpliedWin]
	mov	di, es:[wPtrLastTree]
	mov	cx, es:[wPtrLastLoc].P_x
	mov	dx, es:[wPtrLastLoc].P_y
	FALL_THRU	WinTraverseHere

WinReTraverseHere	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinTraverseHere

DESCRIPTION:	Traverse window system, going from window passed to location
		passed in (cx, dx).

CALLED BY:	INTERNAL
		WinCommonTraverse

PASS:
	bx		- window handle to start in (if zero, will use tree win)
	di		- window tree to start on (if zero, will just set "Last"
			  location win, tree & info to 0, as we don't know
			  where the ptr is)
	cx, dx		- x, y screen position to traverse to

	es	- segment of kernel data

RETURN:
	cx, dx, es	- intact

DESTROYED:
	ax, bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


WinTraverseHere	proc	near
EC <	uses	bx, di, cx, dx		; get debug info on stack...	>
EC <	.enter								>
EC <	call	ECEnsureWinTreeSem					>
;EC <	call	ECValidateWinTreeNoSem	; make sure OK so far		>

	mov	es:[wPtrLastTree], di	; Store new "last tree"

	tst	bx			; Have a window to start on?
	jnz	haveWin
	mov	bx, di			; if not, start at window tree
haveWin:
					; Init to being in no window, in
					; case we're not found to be in any.
	clr	ax
	mov	es:[wPtrImpliedWin], ax
	mov	es:[wPtrImpliedWinProc], ax	; or process
	mov	es:[wPtrImpliedWinOD].handle, ax	; or its OD
	mov	es:[wPtrImpliedWinOD].chunk, ax


					; Default to assuming not using
					; hand-tracked down vis window
					; (Only required if point we're
					; traversing TO is in a save-under
					; region)
	mov	es:[wPtrLocatedVisWin], ax

	tst	di			; if no window to start in, we won't
	jz	afterSaveUnderCheck	; need to do save-under check.

	cmp	cx, EOREGREC		; if Both = EOREGREC, walking off,
	jne	checkForSaveUnder	; don't need to check save-under
	cmp	dx, EOREGREC
	je	afterSaveUnderCheck
checkForSaveUnder:
	push	ax, bx, cx, dx
	push	di
	mov	bx, di			; Get new tree locked, so that
					; we know which video driver to call
	call	WinPLockDS		; lock window

	mov	ax, cx			; Set up "Rectangle" at point
	mov	bx, dx
	mov	di,DR_VID_CHECK_UNDER	; See if any overlaps w/save under
					;	areas.
	call	WinCallVidDriver

	pop	di

	mov	bx, di
	call	WinUnlockV

	tst	al			; Test for overlapping any save-unders
	pop	ax, bx, cx, dx
	jz	afterSaveUnderCheck	; if point isn't within save-under
					; bounds, don't need to track down
					; window which mouse is really in-
					; our standard logic will do just
					; fine.

					; Determine which window the ptr is
					; REALLY in, accounting for save-under
					; problems & everything
	push	bx
	push	cx
	push	dx
	push	di
					; Tree we're going to search is in di
	call	WinLocateCommon		; Call win tree function to brute-force
					; determine window
	mov	es:[wPtrLocatedVisWin], di ; store here for later reference.
	pop	di
	pop	dx
	pop	cx
	pop	bx
afterSaveUnderCheck:
					; Store as last processed location,
					; in case needed later, for WinEndGrab,
					; WinEndExclusive, etc.
	mov	es:[wPtrLastLoc].P_x, cx
	mov	es:[wPtrLastLoc].P_y, dx


	tst	di			; Make sure we have a window to start
	jz	done			; with

	call	WinPLockDS		; lock window

					; Before diving in, figure out which
					; way we're going - out or into
					; window? (If OUT, do vis then univ, if
					; IN, do univ then vis)

	tst	es:[wPtrLocatedVisWin]		; see if actual window known
	jz	standardApproach		; if so, branch to handle
						; differently
;windowKnown:
	mov	ax, es:[wPtrLocatedVisWin]	; get known actual window
	cmp	ax, ds:[LMBH_handle]		; see if current win
	je	standardApproach		; if so, branch to call
						; GrTestPointInReg, to determine
						; which region band the mouse
						; is in, & then do LowCheckInVis
	clc
	jmp	short notInVis			; otherwise, ignore
						; ds:[W_visReg], as the ptr
						; can't possibly be in that
						; region (& the test may
						; incorrectly generate the
						; wrong result because of 
						; save under)

standardApproach:

	mov	si, ds:[W_visReg]
	mov	si, ds:[si]		; get ptr to region
	call	GrTestPointInReg	; see if still in visible region
	jc	inVis			; if so, then no VIS_LEAVE's are
					; necessary, so branch & start
					; with the standard CheckHere.
notInVis:
					; if not in vis reg, then we may
					; need to generate VIS_LEAVE's.
					; Start with a vis check.
	call	LowCheckInVis		; send out any VIS_LEAVE's needed
					; & continue on from there.
inVis:
	mov	si, ds:[LMBH_handle]	; pass handle of this window, in si
	mov	bx, si			; but unlock first
	call	WinUnlockV		; block has to be unlocked
	call	CheckHere

done:
;EC <	call	ECValidateWinTreeNoSem	; make sure OK so far		>

	tst	es:[wPtrImpliedWin]	; Make sure we ended up in a window
	jnz	inWindow
	mov	es:[wPtrLastTree], 0	; If not, nuke assumption of last tree
					; we made earlier
inWindow:
					; Clear located window, if any, 
					; can't be used again.
	mov	es:[wPtrLocatedVisWin], 0

EC <	; Make sure cx & dx haven't changed, as documentated		>
EC <	;								>
EC <	mov	ax, cx							>
EC <	mov	si, dx							>
EC <	.leave				; fix stack			>
EC <	cmp	ax, cx							>
EC <	ERROR_NE	GET_DOUG__WIN_CX_TRASHED			>
EC <	cmp	si, dx							>
EC <	ERROR_NE	GET_DOUG__WIN_DX_TRASHED			>
	ret

WinTraverseHere	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckHere

DESCRIPTION:	Checks to see if ptr location is in a window, starting with
		the universe region, & then work up or down from there.
		MSG_ VIS/UNIV _ ENTER/LEAVE's are generated on the way.

CALLED BY:	INTERNAL
		WinTraverseHere

PASS:
	si	- handle of first window to start with
	es	- segment of kernel vars

	cx	- X Ptr location, in screen coords
	dx	- Y Ptr location, in screen coords

RETURN:
	cx, dx, es	- intact

DESTROYED:
	ax, bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


CheckHere	proc	near
EC <	call	ECEnsureWinTreeSem					>
					; si = first block handle. no
					; windows owned/locked
upwardLoop:
;EC <	call	ECValidateWinTreeNoSem	; make sure OK so far		>
	mov	bx, si
	call	WinPLockDS
	call	CheckInUniv		; see if in universe
	jnc	goUp			; if not, go up another level
	call	CheckInVis		; see if in vis region
	jnc	notInVis		; if not, in children
	mov	bx, ds:[LMBH_handle]
NEC <	GOTO	WinUnlockV						>
EC <	call	WinUnlockV						>
EC <	jmp	short	doneValidate					>

notInVis:
NEC <	GOTO	CheckInChildren						>
EC <	call	CheckInChildren						>
EC <	jmp	short	doneValidate					>

goUp:
	mov	si, ds:[W_parent]	; get parent handle
	mov	bx, ds:[LMBH_handle]
	call	WinUnlockV
	tst	si			; if top of tree, quit
	jnz	upwardLoop

EC <doneValidate:							>
;EC <	call	ECValidateWinTreeNoSem	; make sure OK so far		>
	ret

CheckHere	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckInChildren

DESCRIPTION:	Checks to see if location is in any of a window's children.
		MSG_ VIS/UNIV _ ENTER/LEAVE's are generated on the way.

CALLED BY:	INTERNAL
		CheckAcross
		CheckHere

PASS:
	ds	- PLock'ed segment of window
	es	- segment of kernel vars

	cx	- X Ptr location, in screen coords
	dx	- Y Ptr location, in screen coords

RETURN:
	cx, dx, es	- intact

DESTROYED:
	ax, bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


CheckInChildren	proc	near
EC <	call	ECEnsureWinTreeSem					>
	mov	si, ds:[W_firstChild]
	mov	bx, ds:[LMBH_handle]		; get window handle
	call	WinUnlockV
	tst	si
	jz	done
	call	CheckAcross		; else must be in children
done:
	ret
CheckInChildren	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckAcross

DESCRIPTION:	Checks to see if ptr location is in any window at a
		certain level in the tree. going from left to right.
		MSG_ VIS/UNIV _ ENTER/LEAVE's are generated on the way.

CALLED BY:	INTERNAL
		CheckInChildren

PASS:
	si	- handle of first window to start with
	es	- segment of kernel vars

	cx	- X Ptr location, in screen coords
	dx	- Y Ptr location, in screen coords

RETURN:
	cx, dx, es	- intact

DESTROYED:
	ax, bx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

CheckAcross proc	near
EC <	call	ECEnsureWinTreeSem					>
					; si - first block handle.  no
					; windows owned/locked
acrossLoop:
;EC <	call	ECValidateWinTreeNoSem	; make sure OK so far		>
	mov	bx, si
	call	WinPLockDS		; lock child
	call	CheckInUniv		; see if in child's universe
	jnc	notInUniv		; branch if not in universe
	call	CheckInVis		; see if in window's vis region
	jnc	notInVis		; if so, all done
	mov	bx, ds:[LMBH_handle]
NEC <	GOTO	WinUnlockV						>
EC <	call	WinUnlockV						>
EC <	jmp	short doneValidate					>

notInVis:
NEC <	GOTO	CheckInChildren						>
EC <	call	CheckInChildren						>
EC <	jmp	short doneValidate					>

notInUniv:
	mov	si, ds:[W_nextSibling]
	mov	bx, ds:[LMBH_handle]
	call	WinUnlockV
	tst	si
	jnz	acrossLoop		; loop to do next sibling

EC <doneValidate:							>
;EC <	call	ECValidateWinTreeNoSem	; make sure OK so far		>
	ret

CheckAcross	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckInUniv

DESCRIPTION:	Checks to see if location is in univ region of window.
		If the state of this has changed, then a MSG_META_UNIV_ENTER or
		MSG_META_UNIV_LEAVE is sent to the enter/leave OD for the
		window.

CALLED BY:	INTERNAL
		CheckHere
		CheckAcross

PASS:
	ds	- PLock'ed segment of window
	es	- segment of kernel vars

	cx	- X Ptr location, in screen coords
	dx	- Y Ptr location, in screen coords

RETURN:
	carry	- set if in region
	cx, dx, es	- intact

DESTROYED:
	ax, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


CheckInUniv	proc	near
EC <	call	ECEnsureWinTreeSem					>
	cmp	es:[wPtrLocatedVisWin], 0	; see if actual window known
	jne	compareWithKnown		; If so, branch to do check
						; by tree relationship

	mov	si, ds:[W_univReg]
	mov	si, ds:[si]		; get ptr to region
	call	GrTestPointInReg	; see if still in region
finishBasedOnCarry:
	pushf				; save carry flag
	jnc	notInUniv		; branch if not in region
					; See if was already marked as in
	test	ds:[W_ptrFlags], mask WPF_PTR_IN_UNIV
	jnz	sendEventsNoLeave	; if so, skip to doing events
					; Else set flag to show in
	or	ds:[W_ptrFlags], mask WPF_PTR_IN_UNIV

					; If we're in entering a
					; universe region,
					; update implied window info before
					; sending any MSG_UNIV_?_ENTER events
	call	SendImpliedChangeEvent

if      (WIN_ENTER_LEAVE_CONTROL)
					; See if we've just entered an excluded
					; branch
	test	ds:[W_ptrFlags], mask WPF_WIN_BRANCH_EXCLUDED
	jz	notInExcluded		; skip if not, else...
					; Store window handle here to note
					; that mouse is in excluded branch
	mov	ax, ds:[LMBH_handle]
	mov	es:[wPtrWinAtExclude], ax
notInExcluded:
endif


					; And send notification of change
	mov	ax, MSG_META_RAW_UNIV_ENTER
	call	SendEnterLeaveEvent

sendEventsNoLeave:
	mov	al, FALSE		; For now, don't need raw leave
	jmp	short sendEvents

notInUniv:
	mov	al, FALSE		; For now, don't need raw leave
					; See if was already marked as out
	test	ds:[W_ptrFlags], mask WPF_PTR_IN_UNIV
	jz	sendEvents		; if so, skip to doing events

					; if not in region, reset flag
	and	ds:[W_ptrFlags], not (mask WPF_PTR_IN_UNIV)

	mov	al, TRUE		; pass flag indicating we should
					; send a MSG_META_RAW_UNIV_LEAVE

sendEvents:
if      (WIN_ENTER_LEAVE_CONTROL)
	push	ax			; Save flag for raw leave
	call	SendUnivEvents		; Update events to reflect state
	pop	ax
endif
	cmp	al, TRUE		; See if we should send raw leave
	jne	skipRawLeave		; skip if not


					; Else send notification
	mov	ax, MSG_META_RAW_UNIV_LEAVE
	call	SendEnterLeaveEvent

if      (WIN_ENTER_LEAVE_CONTROL)
					; See if we've just left an excluded
					; branch
	test	ds:[W_ptrFlags], mask WPF_WIN_BRANCH_EXCLUDED
	jz	notOutOfExcluded	; skip if not, else...
					; Clear flag, to show we're out
	mov	es:[wPtrWinAtExclude], 0
notOutOfExcluded:
endif


skipRawLeave:

	popf				; return carry flag
	ret

compareWithKnown:
	mov	bx, es:[wPtrLocatedVisWin]	; See if actual visible window
	call	WinTestIfWinInBranch		; is in branch.  Carry set if so
	jmp	short finishBasedOnCarry

CheckInUniv	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	SendUnivEvents

DESCRIPTION:	Corrects any discrepancies between whether ptr is marked
		as being in the universe region of a window & whether events
		have been sent out to notify the InputOD for the window
		of that fact.

		UNIV_ENTER & UNIV_LEAVE methods are sent only if the mouse
		is not grabbed.

CALLED BY:	INTERNAL

PASS:
	ds	- PLock'ed segment of window
	es	- segment of kernel vars
	W_ptrFlags	- WPF_PTR_IN_UNIV flag set accurately
			  WPF_UNIV_ENTER, WPF_UNIV_LEAVE,
			  according to last event sent out

RETURN:
	cx, dx, es	- intact

DESTROYED:
	ax, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


if      (WIN_ENTER_LEAVE_CONTROL)
SendUnivEvents	proc	near
EC <	call	ECEnsureWinTreeSem					>
					; Is ptr in universe?
	test	ds:[W_ptrFlags], mask WPF_PTR_IN_UNIV
	jz	notInUniv		; branch if not

;inUniv:
					; is mouse grabbed?
	test	es:[wPtrChangeFlags], mask WCF_MOUSE_GRABBED
					; If window sys grabbed, then don't send
	jnz	done			; out standard Enter/Leave methods

;stdUnivEnter:

	; SEE IF WE'RE IN AN EXCLUDED BRANCH
	cmp	es:[wPtrWinAtExclude], 0
	jnz	done			; if so, then we can't send std ENTER

					; See if univ entered
	test	ds:[W_ptrFlags], mask WPF_UNIV_ENTERED
	jnz	done			; if so, OK, done
					; else change state
	or	ds:[W_ptrFlags], mask WPF_UNIV_ENTERED

					; If we're in a visible region,
					; update implied window info before
					; sending any MSG_VIS_? events
	call	SendImpliedChangeEvent

	mov	ax, MSG_META_UNIV_ENTER	; & send method
	call	SendEnterLeaveEvent
	jmp	short done

notInUniv:

; A CHANGE!  We hereby decree that MSG_META_UNIV_LEAVE's may always be sent
; in the case that the mouse moves out of a window, and that window had
; previously received a MSG_META_UNIV_ENTER.
;
;					; is mouse grabbed?
;	test	es:[wPtrChangeFlags], mask WCF_MOUSE_GRABBED
;	jnz	done		; If window sys grabbed, then don't send
;				; out standard Enter/Leave methods

;stdUnivLeave:
	; ALLOW MSG_META_UNIV_LEAVE from an excluded branch

	call	EnsureUnivLeave
done:
	ret
SendUnivEvents	endp


EnsureUnivLeave	proc	near
EC <	call	ECEnsureWinTreeSem					>
					; See if univ already left
	test	ds:[W_ptrFlags], mask WPF_UNIV_ENTERED
	jz	done			; if so, OK, done
					; else update flags
	and	ds:[W_ptrFlags], not (mask WPF_UNIV_ENTERED)
	mov	ax, MSG_META_UNIV_LEAVE	; & send method
	call	SendEnterLeaveEvent
done:
	ret
EnsureUnivLeave	endp
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckInVis

DESCRIPTION:	Checks to see if location is in visible region of window.
		If the state of this has changed, then a MSG_META_VIS_ENTER or
		MSG_META_VIS_LEAVE is sent to the enter/leave OD for the
		window.

CALLED BY:	INTERNAL
		CheckHere
		CheckAcross

PASS:
	ds	- PLock'ed segment of window
	es	- segment of kernel vars

	cx	- X Ptr location, in screen coords
	dx	- Y Ptr location, in screen coords

RETURN:
	carry	- set if in region
	cx, dx, es	- intact

DESTROYED:
	ax, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@


CheckInVis	proc	near
EC <	call	ECEnsureWinTreeSem					>
	cmp	es:[wPtrLocatedVisWin], 0	; see if actual window known
	jne	compareWithKnown		; IF not, then do physical check
standardApproach:
	mov	si, ds:[W_visReg]
	mov	si, ds:[si]		; get ptr to region
	call	GrTestPointInReg	; see if still in region
finishBasedOnCarry:
	call	LowCheckInVis		; complete check, using flag passed
	ret

compareWithKnown:
	mov	ax, es:[wPtrLocatedVisWin]
	cmp	ax, ds:[LMBH_handle]		; if actual window known, just
	je	standardApproach		; if mouse is DEFINITELY in
						; 	this window, allow
						;	standard test.
	clc
	jmp	short finishBasedOnCarry	; Otherwise, declare NOT in
						;	window
CheckInVis	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	LowCheckInVis

DESCRIPTION:	Sends out methods for change in visible region location
		If the state of this has changed, then a MSG_META_VIS_ENTER or
		MSG_META_VIS_LEAVE is sent to the enter/leave OD for the
		window.

CALLED BY:	INTERNAL
		CheckInVis
		WinTraverseHere

PASS:
	ds	- PLock'ed segment of window
	es	- segment of kernel vars

	cx	- X Ptr location, in screen coords
	dx	- Y Ptr location, in screen coords

	CARRY	- result of GrTestPointInReg on point in window's visReg.
		If in region, then returns rectangle inside region that the
		point was in:
		ax		- top bounding Y value
		bx		- bottom bottom X value
		ds:[si-4]	- left bounding X value
		ds:[si-2]	- right bounding X value

RETURN:
	carry	- set if in region
	cx, dx, es	- intact

DESTROYED:
	ax, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

LowCheckInVis	proc	near
EC <	call	ECEnsureWinTreeSem					>
	pushf				; save carry flag
	jnc	notInVis		; branch if not in region

	INT_OFF
	mov	es:[wPtrTestBounds].R_top, ax		; store top bound
	mov	es:[wPtrTestBounds].R_bottom, bx	; store bottom bound
	mov	ax, ds:[si-4]				; get XON position
	mov	es:[wPtrTestBounds].R_left, ax		; store left position
	mov	ax, ds:[si-2]				; get XOFF position
	mov	es:[wPtrTestBounds].R_right, ax		; store right position
	INT_ON

					; See if was already marked as in
	test	ds:[W_ptrFlags], mask WPF_PTR_IN_VIS
	jnz	afterVisEntered		; if so, don't need to send event

if	WIN_ERROR_CHECK

	; Error if ptr has just been determined to be in the Vis regions of
	; two windows at once.
	;
	tst	es:[wPtrRawWin]		; See if ptr already in a window
	ERROR_NZ	GET_DOUG__WIN_ERROR_PTR_CAN_NOT_BE_IN_TWO_WINDOWS_AT_ONCE
	mov	ax, ds:[LMBH_handle]
	mov	es:[wPtrRawWin], ax	; Store new window having ptr
endif
					; show ptr in visible region
	or	ds:[W_ptrFlags], mask WPF_PTR_IN_VIS

					; If we're in a visible region,
					; update implied window info before
					; sending any MSG_VIS_? events
	call	SendImpliedChangeEvent

if      (WIN_VIS_ENTER_LEAVE)
					; Else send notification of enter
	mov	ax, MSG_META_RAW_VIS_ENTER
	call	SendEnterLeaveEvent
endif
afterVisEntered:

	mov	bx, ds:[LMBH_handle]	; get window handle
	mov	es:[wPtrImpliedWin], bx	; Store the fact we're in it, as the
					; next place to start looking.

					; Store owner of that window, too
	push	bx
	call	MemOwnerFar
	mov	es:[wPtrImpliedWinProc], bx
	pop	bx

if      (WIN_ENTER_LEAVE_CONTROL)
					; See if window marked as having grab
	test	ds:[W_ptrFlags], mask WPF_WIN_GRABBED
	jz	afterGrabCheck			; skip if not
	mov	es:[wPtrLastGrabWin], bx	; store as last grabbed window
						; that mouse was in.
afterGrabCheck:
endif
					; & store Output Descriptor
	mov	ax, ds:[W_inputObj].handle
	mov	es:[wPtrImpliedWinOD].handle, ax
	mov	ax, ds:[W_inputObj].chunk
	mov	es:[wPtrImpliedWinOD].chunk, ax

	mov	al, FALSE		; don't need raw leave
	jmp	short sendEvents

notInVis:
	mov	al, FALSE		; don't need raw leave yet
					; See if was already marked as out
	test	ds:[W_ptrFlags], mask WPF_PTR_IN_VIS
	jz	sendEvents		; if so, just do regular events
					; else show not in vis region
	and	ds:[W_ptrFlags], not (mask WPF_PTR_IN_VIS)
	mov	al, TRUE		; & pass flag to send leave

sendEvents:
if      (WIN_ENTER_LEAVE_CONTROL)
	push	ax			; Save flag for raw leave
	call	SendVisEvents		; Update events to reflect state
	pop	ax
endif
	cmp	al, TRUE		; See if we should send raw leave
	jne	skipRawLeave		; skip if not

					; Else send notification
if      (WIN_VIS_ENTER_LEAVE)
	mov	ax, MSG_META_RAW_VIS_LEAVE
	call	SendEnterLeaveEvent
endif

if	WIN_ERROR_CHECK
	mov	ax, ds:[LMBH_handle]
	cmp	ax, es:[wPtrRawWin]	; See if ptr in window
	ERROR_NZ	WIN_ERROR_PTR_CAN_NOT_LEAVE_WINDOW_NOT_ENTERED
	mov	es:[wPtrRawWin], 0	; Show mouse not in window
endif

skipRawLeave:
	popf				; return carry flag
	ret

LowCheckInVis	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	SendVisEvents

DESCRIPTION:	Corrects any discrepancies between whether ptr is marked
		as being in the vis region of a window & whether events
		have been sent out to notify the InputOD for the window
		of that fact.

		VIS_ENTER & VIS_LEAVE methods are sent only if the mouse
		is not grabbed.

CALLED BY:	INTERNAL

PASS:
	ds	- PLock'ed segment of window
	es	- segment of kernel vars
	W_ptrFlags	- WPF_PTR_IN_VIS flag set accurately
			  WPF_VIS_ENTER, WPF_VIS_LEAVE,
			  according to last event sent out

RETURN:
	cx, dx, es	- intact

DESTROYED:
	ax, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@



if      (WIN_ENTER_LEAVE_CONTROL)
SendVisEvents	proc	near
EC <	call	ECEnsureWinTreeSem					>
					; Is ptr in vis?
	test	ds:[W_ptrFlags], mask WPF_PTR_IN_VIS
	jz	notInVis		; branch if not

;inVis:
					; is mouse grabbed?
	test	es:[wPtrChangeFlags], mask WCF_MOUSE_GRABBED
	jnz	done			; if window sys grabbed, no normal
					; Enter/Leave events should be sent
;stdVisEnter:
	; SEE IF WE'RE IN AN EXCLUDED BRANCH
	;
	cmp	es:[wPtrWinAtExclude], 0
	jnz	done			; if so, then we can't send std ENTER

					; See if vis entered
	test	ds:[W_ptrFlags], mask WPF_VIS_ENTERED
	jnz	done			; if so, OK, done
					; else change state
	or	ds:[W_ptrFlags], mask WPF_VIS_ENTERED
					; If we're in a visible region,
					; update implied window info before
					; sending any MSG_VIS_? events
	call	SendImpliedChangeEvent

	mov	ax, MSG_META_VIS_ENTER	; & send method
	call	SendEnterLeaveEvent
	jmp	short done

notInVis:
; A CHANGE!  We hereby decree that MSG_META_VIS_LEAVE's may always be sent
; in the case that the mouse moves out of a window, and that window had
; previously received a MSG_META_VIS_ENTER.
;
;					; is mouse grabbed?
;	test	es:[wPtrChangeFlags], mask WCF_MOUSE_GRABBED
;	jnz	done			; if window sys grabbed, no normal
;					; Enter/Leave events should be sent

;stdVisLeave:
	call	EnsureVisLeave
done:
	ret
SendVisEvents	endp



EnsureVisLeave	proc	near
EC <	call	ECEnsureWinTreeSem					>
					; See if vis already left
	test	ds:[W_ptrFlags], mask WPF_VIS_ENTERED
	jz	done			; if so, OK, done
					; else update flags
	and	ds:[W_ptrFlags], not (mask WPF_VIS_ENTERED)
	mov	ax, MSG_META_VIS_LEAVE	; & send method
	call	SendEnterLeaveEvent
done:
	ret
EnsureVisLeave	endp
endif




COMMENT @----------------------------------------------------------------------

FUNCTION:	SendEnterLeaveEvent

DESCRIPTION:	Send enter/leave method for current window

CALLED BY:	INTERNAL

PASS:
	ds	- segment of PLock'ed window
	ax	- method to send

RETURN:

DESTROYED:
	ax, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

SendEnterLeaveEvent	proc	near	uses cx, dx, bp
	.enter
EC <	call	ECEnsureWinTreeSem					>
	mov	cx, ds:[W_inputObj].handle
	mov	dx, ds:[W_inputObj].chunk
	mov	bp, ds:[LMBH_handle]
	call	WinSendViaPtrEventQueue
	.leave
	ret
SendEnterLeaveEvent	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	SendImpliedChangeEvent

DESCRIPTION:	Send a MSG_META_IMPLIED_WIN_CHANGE, to the wOutputOD, via
		the event block, but ONLY if we haven't sent one yet during
		this traversal.  The code which flushes the event queue
		will fill in the correct implied information for us, so we
		needn't set it here.

CALLED BY:	INTERNAL

PASS:
	es	- kernel seg

RETURN:

DESTROYED:
	ax, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

SendImpliedChangeEvent	proc	near
EC <	call	ECEnsureWinTreeSem					>
					; Have we already sent one?
	test	es:[wPtrChangeFlags], mask WCF_IMPLIED_CHANGE_SENT
	jnz	done
					; Send it.
	push	cx, dx, bp
	mov	ax, MSG_META_IMPLIED_WIN_CHANGE
	call	WinSendViaPtrEventQueue
	pop	cx, dx, bp
					; Show that we've sent one.
	or	es:[wPtrChangeFlags], mask WCF_IMPLIED_CHANGE_SENT

done:
	ret
SendImpliedChangeEvent	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	WinSendViaPtrEventQueue

DESCRIPTION:	Adds event to end of event queue buffer.  This code is NOT
		reentrant.


CALLED BY:	WinChangeAck

PASS:
	winTreeSem	- P'd

	ax		- method
	cx, dx, bp	- data
			  For ENTER/LEAVE:
				cx:dx	- InputOD
				bp	- window
			  For MSG_META_IMPLIED_WIN_CHANGE:
				nothing (will be filled in when determined)

RETURN:

DESTROYED:
	ax, bx, cx, dx, bp, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

WinSendViaPtrEventQueue	proc	near	uses di, ds
	.enter
EC <	call	ECEnsureWinTreeSem					>
	LoadVarSeg	ds		; get kernel segment
	mov	bx, ds:[wPtrEventQueue]	; fetch queue to send events to
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	.leave
	ret

WinSendViaPtrEventQueue	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinProcessEventQueue

DESCRIPTION:	Process all of the Enter/Leave events stored in the
		ptrEventQueue, to update the flags that should be passed for
		various methods.  Transfer results to the ptrSendQueue, which
		will be flushed at a later time, outside of the winTreeSem


CALLED BY:	INTERNAL
		WinCommonEnd

PASS:
	winTreeSem	- P'd
	Values of variables to update methods with:

	bp	- wPtrImpliedWin
	bx	- wPtrImpliedWinProc
	cx:dx	- wPtrImpliedWinOD


RETURN:
	di	- unchanged

DESTROYED:
	ax, bx, cx, dx, si, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version
------------------------------------------------------------------------------@

WinProcessEventQueue	proc	near	uses	ds
	.enter
EC <	call	ECEnsureWinTreeSem					>
	LoadVarSeg	ds		; get kernel segment
	;
	; Store data in kernel data space, where callback routine will be
	; able to get access to it.
	;
	mov	ds:[wPtrProcessEventData.WPED_wPtrWinProc], bx
	mov	ds:[wPtrProcessEventData.WPED_wPtrWinOD.handle], cx
	mov	ds:[wPtrProcessEventData.WPED_wPtrWinOD.chunk], dx
	mov	ds:[wPtrProcessEventData.WPED_wPtrWin], bp

	mov	bx, ds:[wPtrEventQueue]	; fetch queue to get events from
processLoop:
	call	GeodeInfoQueue		; see if we've got any events in queue
	tst	ax
	jz	processDone

	push	bx
	call	QueueGetMessage		; get next message
	mov	bx, ax
					; no data to pass in di
	clr	si			; don't preserve message

	mov	ax, SEGMENT_CS		; setup custom callback
	push	ax
	mov	ax, offset ProcessCallBack
	push	ax
	call	MessageProcess

	pop	bx
	jmp	short processLoop
processDone:
	.leave
	ret
WinProcessEventQueue	endp


ProcessCallBack	proc far	uses	ds
	.enter
	LoadVarSeg	ds		; get kernel segment

	; FOR MSG_META_IMPLIED_WIN_CHANGE, load in new win under ptr &
	; implied grab. (copy from vars which can be accessed outside
	; of wWinTreeSem)
	;
	cmp	ax, MSG_META_IMPLIED_WIN_CHANGE
	jne	afterImplied

	; Get implied data to send
	;
	mov	cx, ds:[wPtrProcessEventData].WPED_wPtrWinOD.handle
	mov	dx, ds:[wPtrProcessEventData].WPED_wPtrWinOD.chunk
	mov	bp, ds:[wPtrProcessEventData].WPED_wPtrWin
afterImplied:

	mov	bx, ds:[wPtrSendQueue]	; fetch queue to send events to
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret

ProcessCallBack	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	WinFlushSendQueue

DESCRIPTION:	Send off all events stored in block passed.  Does not use
		MF_FORCE_QUEUE so objects running under thread calling
		this routine will get direct calls.  Method handlers may
		do about anything they want.  They may modify windows in
		the window system, since this routine is called only with
		the wWinTreeSem released.


CALLED BY:	INTERNAL
		WinCommonEnd

PASS:

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  then on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
------------------------------------------------------------------------------@

WinFlushSendQueue	proc	near	uses	ds
	.enter
	LoadVarSeg	ds		; get kernel segment
	test	ds:[wPtrChangeFlags], mask WCF_FLUSHING_QUEUE
	jnz	done			; if already flushing quit, let top
					; level handle

	 				; Set flag to show we're in this routine
	or	ds:[wPtrChangeFlags], mask WCF_FLUSHING_QUEUE
	mov	bx, ds:[wPtrSendQueue]	; fetch queue to dispatch events from
flushLoop:
	call	GeodeInfoQueue		; see if we've got any events in queue
	tst	ax
	jz	flushDone
	call	QueueGetMessage		; fetch next message
	push	bx
	mov	bx, ax

					; no data to pass in di
	clr	si			; don't preserve message

	mov	ax, SEGMENT_CS		; setup custom callback
	push	ax
	mov	ax, offset FlushCallBack
	push	ax

	call	MessageProcess

	pop	bx
	jmp	short flushLoop
flushDone:
					; Clear flag, to show no longer
					; flushing.
	and	ds:[wPtrChangeFlags], not mask WCF_FLUSHING_QUEUE
done:
	.leave
	ret

WinFlushSendQueue	endp

FlushCallBack	proc	far
	push	ds
	LoadVarSeg	ds		; get kernel segment
	mov	bx, ds:[wPtrOutputOD].handle
	mov	si, ds:[wPtrOutputOD].chunk
	pop	ds

	clr	di				; Use call/send as is approp.
	GOTO	ObjMessage			; & send it
FlushCallBack	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	WinSetPtrImage

DESCRIPTION:	Allows setting PtrImages within the range handled by windows.

CALLED BY:	EXTERNAL

PASS:	bp	- PIL_GADGET or PIL_WINDOW.

	cx:dx	- optr to PointerDef in sharable memory block, OR
		  cx = 0, and dx = PtrImageValue (see Internal/im.def)

	NOTE:  if cx = 0, dx = PIV_UPDATE, bp is not used.


	di - handle of graphics state, or window

RETURN:	nothing

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/91		Initial version

------------------------------------------------------------------------------@

WinSetPtrImage	proc	far
	uses	ax, bx, ds, es, di
	.enter

	LoadVarSeg	es
					; Get access to W_*PtrImage variables,
					; wPtrFinalWin, & ActivateWinPtrImages
	PSem	es, winPtrImageSem, TRASH_AX_BX

	tst	cx			; if PIV_UPDATE, skip changing window
	jnz	setNewImage
	cmp	dx, PIV_UPDATE
	je	afterWinUpdate

setNewImage:
	call	FarWinLockFromDI		; Get window locked
	jc	exit

	mov	bx, offset W_gadgetPtrImage
	cmp	bp, PIL_GADGET
	je	continue
EC <	cmp	bp, PIL_WINDOW						>
EC <	ERROR_NE	WIN_ILLEGAL_PTR_IMAGE_LEVEL			>
	mov	bx, offset W_windowPtrImage
continue:
	cmp	ds:[bx].handle, cx
	jne	setNew
	cmp	ds:[bx].chunk, dx
	je	skipSetting
setNew:
	; Store new gadget ptr image
	mov	ds:[bx].handle, cx
	mov	ds:[bx].chunk, dx
skipSetting:

	mov	bx, di			; bx = window handle
	call	WinUnlockV		; unlock, release window
	je	exit			; if no change, exit

afterWinUpdate:
					; update if this is the final window
	cmp	bx, es:[wPtrFinalWin]
	jne	exit

	call	ImSetPtrImage		; Set new ptr image at level passed

exit:
	VSem	es, winPtrImageSem, TRASH_AX_BX

	.leave
	ret

WinSetPtrImage	endp

WinMovable ends

;
;---
;
ECCode	segment	resource
if	ERROR_CHECK





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECEnsureWinTreeSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the WinTreeSem is grabbed.

CALLED BY:	INTERNAL
PASS:
RETURN:
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECEnsureWinTreeSem	proc	far
	uses	ds
	.enter
	pushf
	LoadVarSeg ds
	cmp	ds:[winTreeSem].Sem_value, 1
	ERROR_E	GET_DOUG__WIN_TREE_SEM_NOT_GRABBED
	popf
	.leave
	ret
ECEnsureWinTreeSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ECValidateWinTreeNoSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to make sure entire window tree is OK.

CALLED BY:	INTERNAL
		PWinTree
		VWinTree
		NOTE:  caller must have winTreeSem

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECValidateWinTreeNoSem	proc	far	uses ax, bx, ds
	.enter
	LoadVarSeg ds, bx
	mov	bx, ds:[wPtrLastTree]	; Put tree to start at in bx
	tst	bx
	jz	done
	call	ECValidateWinBranch
done:
	.leave
	ret
ECValidateWinTreeNoSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ECValidateWinBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recursively validates window & all children

CALLED BY:	INTERNAL
PASS:		bx	- Window to validate
RETURN:		al	- WinPtrFlags, indicating if flag is set indicating
			  ptr is in Univ reg of window, or Vis reg of the
			  window or any of its children's
		ah	- 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECValidateWinBranch	proc	far
	uses	bx, dx, ds
	.enter

	call	MemPLock
	mov	ds, ax
	mov	dl, ds:[W_ptrFlags]	; Init combined WinPtrFlags
	clr	dh			; Init combined WinPtrFlags - parent

	; Check for reasonable window regions.
	;
	call	ECheckWinRegions

	mov	ax, ds:[W_firstChild]
	call	MemUnlockV
	mov	bx, ax

nextWin:
	tst	bx			; If no more windows, done.
	jz	done

	call	ECValidateWinBranch	; Get WinPtrFlags for this child.

	; If ptr in Univ of child, MUST also be in Univ of parent
	;
	test	al, mask WPF_PTR_IN_UNIV
	jz	afterTest2
	test	dl, mask WPF_PTR_IN_UNIV
	ERROR_Z	GET_DOUG__WIN_ERROR_PTR_IN_UNIV_OF_CHILD_BUT_NOT_PARENT
afterTest2:


	; If ptr in Vis of child, must NOT be of Vis of parent,
	;		or any previous child encountered to this point
	;
	test	al, mask WPF_PTR_IN_VIS
	jz	afterTest3
	test	dl, mask WPF_PTR_IN_VIS
	ERROR_NZ	GET_DOUG__WIN_ERROR_PTR_IN_VIS_OF_CHILD_AND_PARENT_OR_PREV_CHILD
afterTest3:

	; If ptr in Univ of child, must NOT be in Univ of any previous child

	test	al, mask WPF_PTR_IN_UNIV
	jz	afterTest4
	test	dh, mask WPF_PTR_IN_UNIV
	ERROR_NZ	GET_DOUG__WIN_ERROR_PTR_IN_UNIV_OF_TWO_CHILDREN_AT_ONCE
afterTest4:

	or	dl, al			; OR in flags for combined 
					; parent + children to this point
	or	dh, al			; OR in flags bit for combined children
					; to this point.

	call	MemPLock		; Get next sibling
	mov	ds, ax
	mov	ax, ds:[W_nextSibling]
	call	MemUnlockV
	mov	bx, ax
	jmp	nextWin

done:
	; As this routine tallies the entire branch, if the ptr is in
	; the Univ of this branch, it MUST also be in Vis of the combined
	; windows.

	mov	al, dl			; Return WinPtrFlags in al
	clr	ah
	.leave
	ret
ECValidateWinBranch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ECheckWinRegions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure regions of this window look reasonable

CALLED BY:	INTERNAL
PASS:		ds	- PLock'd segment of window
RETURN:		ds	- fixed up
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECheckWinRegions	proc	far	uses	ax, bx, cx, dx, si, di, bp, es
	.enter

; Make sure Window is P'd (can only be PLock'd, not just locked)
;
	mov	bx, ds:[LMBH_handle]	; get handle
	LoadVarSeg es
	cmp	es:[bx].HM_otherInfo, 1
	ERROR_E		GET_DOUG__WIN_ERROR_VIS_REG_BIGGER_THAT_UNIV

; Check to make sure Vis region isn't bigger than the Univ region
;

	; Create a new temporary region
	;
	mov	cx, size RectRegion	; Init size for region chunk
	call	LMemAlloc
	push	ax

	; First, check to make sure Vis is a subset of the Univ.
	; Vis AND (NOT Univ) should be NULL.

	mov	si, ds:[W_univReg]
	mov	di, ax
	push	di
	segmov	es, ds
	call	FarWinNOTLocReg		; get NOT Univ in temp chunk, fixup DS
	mov	ax, NULL_SEGMENT	; Indicate done with es
	mov	es, ax
	pop	di

	; Create a second temp region
	;
	mov	cx, size RectRegion	; Init size for region chunk
	call	LMemAlloc
	push	ax

	mov	bx, di			; first temp is now source
	mov	si, ds:[W_visReg]
	mov	di, ax			; second temp is dest
	push	di
	segmov	es, ds
	call	FarWinANDLocReg		; get Vis AND (NOT Univ), fixup DS
	mov	ax, NULL_SEGMENT	; Indicate done with es
	mov	es, ax
	pop	di

	mov	di, ds:[di]
	cmp	word ptr ds:[di], NULL_REG	; NULL?
	ERROR_NE	GET_DOUG__WIN_ERROR_VIS_REG_BIGGER_THAT_UNIV

	pop	ax
	call	LMemFree		; Free temporary region

	pop	ax			; Free temporary region
	call	LMemFree
	.leave
	ret

ECheckWinRegions	endp

endif
ECCode	ends
