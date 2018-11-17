COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/User
FILE:		userDialog.asm

ROUTINES:
	Name			Description
	----			-----------
	UserDoDialog
	UserStandardDialog

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

DESCRIPTION:

	$Id: userDialog.asm,v 1.1 97/04/07 11:46:16 newdeal Exp $

-------------------------------------------------------------------------------@

Common segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserDoDialog

DESCRIPTION:	Allows applications to invoke a dialog & block until the user
		responds.   The dialog must be a modal GenInteractionClass
		object, and be marked as being invoked by the routine, i.e.
		look like:

        	visibility = dialog;
        	attributes = default +modal, +initiatedViaUserDoDialog;


		NOTE:  Please see /staff/pcgeos/Library/Doc/UserDoDialog.doc
		       for restrictions on usage.  Briefly:

		1) The pased object must be linked into a generic tree and be
		   fully USABLE.

		2) Use MSG_GEN_INTERACTION_INITIATE instead, where possible.

		3) All objects making up the dialog must reside within a
		   single block. If one of the objects in the box will
		   create children that will reside in another block
		   (such as a controller or a GenFileSelector) you will
		   want to put the object on the 
		   GAGCNLT_CONTROLLERS_WITHIN_USER_DO_DIALOGS app GCN list.

		4) The dialog must be self-contained, i.e. may not rely on
		   messages sent or called on objects outside of itself
		   (i.e. no dynamic lists having destinations outside of
		   the dialog)

        visibility = dialog;
        attributes = default +modal, +initiatedViaUserDoDialog, +notUserInitiata


CALLED BY:	EXTERNAL

PASS:
	^lbx:si	- GenInteractionClass dialog to invoke.
		  Must be linked into a generic tree & be fully USABLE before
		  this routine may be called on it.

RETURN:
	ax	- InteractionCommand response value

		  NOTE:  If the dialog is terminated in some way other than
			 a gadget which is terminating the interaction, ax is
			 returned IC_NULL, to indicate that the interaction
			 has been terminated by the system.

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

NOTES ON USAGE:

REGISTER/STACK USAGE:

Relies on the structure UserDialogStruct, which describes what's on the
stack while the application is blocked.  This includes a set of registers
to pass and a semaphore.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Initial version
	Doug	8/92		Updated to provide support for same-thread
				dialog

------------------------------------------------------------------------------@


UserDoDialog	proc	far	uses bp, di, cx, dx
	.enter

	mov	di, 1200
	call	ThreadBorrowStackSpace
	push	di

	push	ds
	mov	ax, segment uiLaunchModel
	mov	ds, ax
	cmp     ds:[uiLaunchModel], UILM_TRANSPARENT
	pop	ds
	jne	afterTransparentLaunchMode

	push	bx, si		; save OD of dialog
	call	MemOwner
	mov	cx, bx
	mov	ax, MSG_GEN_FIELD_ACTIVATE_DISMISS
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	clr	di
	pop	bx, si		; restore OD of dialog
	call	ObjMessage

afterTransparentLaunchMode:

				; Reserve space on stack for reply structure
;	sub	sp, size UserDoDialogStruct
;	mov	bp, sp
;handle ThreadBorrowStackSpace problems - brianc 7/6/93
	mov	bp, ss:[TPD_stackBot]
	add	ss:[TPD_stackBot], (size UserDoDialogStruct)

				; Init w/optr of dialog itself
	movdw	ss:[bp].UDDS_dialog, bxsi

				; Init other struc entries to zero's
	clr	ax
	mov	ss:[bp].UDDS_semaphore, ax
	mov	ss:[bp].UDDS_response, ax
	mov	ss:[bp].UDDS_complete, ax
	mov	ss:[bp].UDDS_queue, ax
	mov	ss:[bp].UDDS_boxRunByCurrentThread, ax
	call	ObjTestIfObjBlockRunByCurThread
	jne	10$
	mov	ss:[bp].UDDS_boxRunByCurrentThread, -1
10$:

;	We always sit in a loop and dispatch - we never block, as we have to
;	be able to field MSG_META_DETACH.

	push	bx
	mov	ax, TGIT_QUEUE_HANDLE
	clr	bx
	call	ThreadGetInfo
	mov	ss:[bp].UDDS_callingThread, ax
	pop	bx

	tst	ax
	jnz	readyToGo

	mov_trash	ax, bx	; ax = OD.handle
	clr	bx		;value = 0
	call	ThreadAllocSem
	mov	ss:[bp].UDDS_semaphore, bx
	mov_trash	bx, ax	; bx = OD.handle
readyToGo:

	mov	dx, ss		; pass dx:bp = far ptr to UserDoDialogStruct
				; Deliver method
	mov	ax, MSG_GEN_INTERACTION_INITIATE_BLOCKING_THREAD_ON_RESPONSE
	clr	di
	call	ObjMessage

				; Get semaphore/flag
	tst	ss:[bp].UDDS_semaphore
	jnz	blockingMode

	call	LoopDispatchFromUserDoDialog
	jmp	dialogComplete

blockingMode:
	push	bx
	mov	bx, ss:[bp].UDDS_semaphore ; Block ourselves on this semaphore
	call	ThreadPSem		   ; until the box frees us up
	call	ThreadFreeSem
	pop	bx

dialogComplete:
	mov	ax, ss:[bp].UDDS_response	; get response
;	add	sp, size UserDoDialogStruct
;handle ThreadBorrowStackSpace problems - brianc 7/6/93
	sub	ss:[TPD_stackBot], (size UserDoDialogStruct)

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

UserDoDialog	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			LoopDispatchFromUserDoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dispatches events from the thread's event queue, either to
		the specified destination, or into a hold up queue, until
		the dialog has been completed, as indicated by UDDS_complete
		being non-zero following a dispatch.  Once complete, the
		held up queue, if any, is merged back in to the front of
		the thread's queue.

CALLED BY:	INTERNAL
		UserDoDialog
PASS:		ss:bp	- ptr to UserDoDialogStruct
RETURN:		ss:bp	- intact
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoopDispatchFromUserDoDialog	proc	near	uses	bx, cx, dx, si, di
	.enter
	clr	bx			; Get queue handle for current thread,
	call	GeodeInfoQueue		; in bx

	; Loop to dispatch/save off events until dialog is complete
	;
notCompleteYet:
	push	bx, bp
	call	QueueGetMessage

	mov	bx, ax
	mov	di, bp			; pass stackframe in ss:di
	clr	si			; don't preserve message
NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	ax, SEGMENT_CS					>
FXIP <		push	ax						>
	mov	ax, offset DispatchFromUserDoDialog
	push	ax
	call	MessageProcess

	pop	bx, bp

	tst	ss:[bp].UDDS_complete
	jz	notCompleteYet

	; OK, now, merge back the saved off events, if any, into main queue.
	;
	mov	si, bx			; Put queue handle in si, as destination
					; queue for following routine

	mov	bx, ss:[bp].UDDS_queue	; Setup hold up input queue as source
	tst	bx			; If no queue, done.
	jz	done

FlushAfterDialog:			; To make it easy to set a bpt here
	ForceRef	FlushAfterDialog

	mov	cx, si			; I don't think this will ever actually
					; be needed, but just in case..

					; Move all of these events to the
					; front of the UI queue
	mov	di, mask MF_INSERT_AT_FRONT
	call	GeodeFlushQueue

	; Finally, nuke the temp queue.  Instance reference has already been
	; zeroed, so we're all done.
	;
	call	GeodeFreeQueue

done:
	.leave
	ret
LoopDispatchFromUserDoDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfObjectCanReceiveMessagesDuringUserDoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the destination of the current message is
		allowed to receive messages while a UserDoDialog is on screen.

CALLED BY:	GLOBAL
PASS:		ss:di - UserDoDialogStruct
		bx:si - destination
		ax - message #
		cx, dx, bp	- data
RETURN:		carry set if object can receive messages
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfObjectCanReceiveMessagesDuringUserDoDialog	proc	near
	.enter
	; 1) If message is destined for some object in the block containing the
	;    dialog, then dispatch it.
	;
	cmp	bx, ss:[di].UDDS_dialog.handle
	LONG je	messagesOK

	push	bx
	call	GeodeGetProcessHandle
	cmp	bx, handle 0
	pop	bx
	jne	notOnUIThread


	; 2) If we're on the ui thread and the destination is the flow
	;     object or the system object, allow it to go through.
	;
	cmpdw	bxsi, ss:[uiFlowObj]
	LONG je	messagesOK
	cmpdw	bxsi, ss:[uiSystemObj]
	LONG je	messagesOK

notOnUIThread:
	; 3) If message is destined for our app object, let it through
	;    unless it's MSG_META_IACP_PROCESS_MESSAGE
	;
	push	cx, dx
	push	bx, si
	clr	bx
	call	GeodeGetAppObject
	mov	cx, bx			; get app object in ^lcx:dx
	mov	dx, si
	pop	bx, si
	cmpdw	cxdx, bxsi
	pop	cx, dx
	je	isAppObj


	; 4) Lastly, check to see if object is on the 
	;    CONTROLLERS_WITHIN_USER DO_DIALOGS GCN list.
	;    If so, send message to it...

	push	ax, bx, cx, dx, si, di, bp
	movdw	cxdx, bxsi		;^lCX:DX <- dest object
	mov	ax, MSG_GEN_APPLICATION_CHECK_IF_ALWAYS_INTERACTABLE_OBJECT
	clr	bx
	call	GeodeGetAppObject
	tst_clc	bx
	jz	noCall
	mov	di, mask MF_CALL
	call	ObjMessage
noCall:
	pop	ax, bx, cx, dx, si, di, bp
					;Returns carry set if object on
					; list
exit:
	.leave
	ret

isAppObj:

	;
	; We must also hold up MSG_GEN_APPLICATION_IACP_COMPLETE_CONNECTIONS
	; to parallel the held up MSG_META_IACP_PROCESS_MESSAGE(MSG_META_ICAP_
	; NEW_CONNECTION).  If we don't we can actually get the MSG_GEN_
	; APPLICATION_IACP_COMPLETE_CONNECTIONS before we get the MSG_META_
	; ICAP_NEW_CONNECTION.  A fail case is opening a document
	; from GeoManager by double-clicking and that document gives an error
	; when opened and the creator application is a single threaded app.
	; - brianc 6/23/93
	;
	cmp	ax, MSG_GEN_APPLICATION_IACP_COMPLETE_CONNECTIONS
	je	exit			; (carry clear)

	cmp	ax, MSG_META_IACP_PROCESS_MESSAGE
	je	exit			; (carry clear)

messagesOK:
	stc
	jmp	exit

CheckIfObjectCanReceiveMessagesDuringUserDoDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfDestinationIsCurrentThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the destination for the current message
		is the current thread.

CALLED BY:	GLOBAL
PASS:		bx - destination of current message
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfDestinationIsCurrentThread	proc	near	uses	ax, bx, cx
	.enter

;	If the message is destined for the current thread, then BX will
;	have the handle of the current thread, or else the process handle.

	mov	cx, bx			;CX <- dest for message
	clr	bx
	mov	ax, TGIT_THREAD_HANDLE
	call	ThreadGetInfo		;AX <- current thread handle
	cmp	ax, cx
	je	isCurrentThread

	call	GeodeGetProcessHandle	;
	cmp	bx, cx
isCurrentThread:
	.leave
	ret
CheckIfDestinationIsCurrentThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			DispatchFromUserDoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine from GeodeDispatchFromQueue, to handle actual
		dispatch of next even on current thread's queue.  If relavent
		to operation of dialog, then dispatch it -- if not, save it
		away in a hold up queue for later.

CALLED BY:	INTERNAL
		LoopDispatchFromUserDoDialog
PASS:		ss:di	- UserDoDialogStruct
		carry	- set if message has data on stack
		ss:[sp+4] - calling thread
		otherwise same as ObjMessage

RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

We have UserDoDialog loop & dispatch only those messages necessary to run
the dialog.  All others would go into the "hold up input" queue, not to be
played until the dialog completes.  Now, WHAT messages should be allowed to
pass through?

As an example, bringing up the "Do you want to exit PC/GEOS" dialog of
Welcome's, the following events come through the queue:

MSG_META_IMPLIED_WIN_CHANGE                                     app
MSG_META_GAINED_FOCUS_EXCL                                      app
MSG_VIS_GRAB_KBD                                                app
MSG_META_GAINED_KBD_EXCL                                        app
MSG_META_KBD_CHAR                                               app

MSG_GEN_INTERACTION_INITIATE_BLOCKING_THREAD_ON_RESPONSE        dialog
MSG_META_EXPOSED                                                dialog
MSG_META_WIN_UPDATE_COMPLETE                                    dialog
MSG_OL_WIN_UPDATE_HEADER                                        dialog
MSG_VIS_VUP_QUERY                                               dialog

MSG_OL_BUTTON_REDRAW                                            trigger
MSG_GEN_TRIGGER_SEND_ACTION                                     trigger

The focus changes result only because this dialog is system modal.  As you
can see, there's actually not much traffic in the event queue, which makes our
job a little easier.  We'll start by allowing anything going to the dialog,
defined as "everything in it's block" (simply because we have no other way
of figuring this out).  This opens the possibility of a screw-up resulting
from the app itself sending force-queued messages to objects in the dialog
before calling UserDoDialog, but there's no way we can figure this out, or for
that matter the case of another thread calling such messages, so we'll just
have to disallow it.  This seems a reasonable limitation.  Next, we need
to decide whether we'll be incredibly leniant or incredibly tight, i.e. whether
we figure out what to exclude, or whether we figure out what to include.  The
blocking UserDoDialog actually allows ALL UI thread messages to continue
flowing, which has not caused problems to date.  On the other hand, it blocks
everything going to the process, data objects, Document object, etc.  What to
do....

How about this:

We need to let input events flow.  We also need to let the UI manipulate
focus/kbd exclusives, & allow the various window messages to come through.
These all go through GenApplication.  Let's try just allowing messages to
be delivered to the app object, but not others (outside the dialog).

We'll see how it goes...

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

Should MetaAppMessages be held up?
Should we allow the app to somehow customize this behavior?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DispatchFromUserDoDialog	proc	far
	pushf
	; OK.  Here's the big decision -- do we dispatch, or save for later?

	;If dialog has has completed, then we should start to let things flow
	; normally:
	;
	;If no queue, just dispatch this message (UserDoDialog
	; will exit when we return).
	;
	;If there is a queue, queue this message up to keep things in order.
	;
	tst	ss:[di].UDDS_complete
	jz	dialogIsNotComplete

	tst	ss:[di].UDDS_queue
	jz	dispatch
	jmp	saveAwayInQueue

dialogIsNotComplete:

	;
	; If the box isn't run by this thread, just stick everything onto
	; the queue, after checking to see if it is a MSG_DETACH for the
	; current thread.
	;

	tst	ss:[di].UDDS_boxRunByCurrentThread
	jz	saveAwayInQueue

	;The message is destined for some object run by this thread. We
	; check to see if that object is allowed to recieve messages.
	;If it isn't, we queue up the message

	call	CheckIfObjectCanReceiveMessagesDuringUserDoDialog
	jnc	saveAwayInQueue

dispatch:
	popf				; get "stack" flag
	mov	di, mask MF_CALL	; perform direct call, nuke event
	jnc	haveStack
	ornf	di, mask MF_STACK
haveStack:
	GOTO	ObjMessage		; dispatch 'em!

;
;--------
;

saveAwayInQueue:
;
;	And we want to do something special if the user's trying to switch
; 	back to this application:
;
;	MSG_META_IACP_PROCESS_MESSAGE - If the message is a new app-mode
;	connection, & the app will be brought to the top on its delivery,
;	bring it to the top now, so that this dialog can be dealt with.
;
	cmp	ax, MSG_META_IACP_PROCESS_MESSAGE
	LONG je	iacpProcessMessage
afterIacpProcessMessage:

	call	CheckIfDestinationIsCurrentThread	;If not destined for
	LONG jne	addToQueue			; this thread, add to
							; queue.

;
;	This is a message being sent to this thread. We want to let a few of
;	these messages through:
;
;	MSG_META_REMOVING_DISK - if this comes through, we want to bring down
;		 the dialog box, and handle the message.
;
;	MSG_META_DETACH - We let this through so we can bring the box down
;		if the user exits the app.
;
;	MSG_META_DISPATCH_EVENT -
;		We let these through if the destination	for the message
;		is an object that can receive messages 
;
;	MSG_META_OBJ_FLUSH_INPUT_QUEUE - 
;		Same as MSG_META_DISPATCH_EVENT.  (Changed 8/16/93 cbh to
; 		not let this though if the message to dispatch is
;		MSG_META_FINAL_OBJ_FREE or MSG_PROCESS_FINAL_BLOCK_FREE,
;		since it is really bad to let this though and destroy the
;		object, while letting messages that were supposed to get
;		flushed before the destroy get flushed.  There are several
;		other messages that use the flush mechanism that may also want
;		to be held up, but I'm sticking to these two for now.)
;
;	MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST - We let this through all the
;		time, if the current thread is an incarnation of GenProcess 
;
;	MSG_PROCESS_CALL_ROUTINE - We let this through all the time because
;		its intent is to make something happen during interrupt code,
;		we should certainly allow it to happen even if a UserDoDialog
;		is in progress
;
;	MSG_META_TEXT_EMPTY_STATUS_CHANGED - We let this through so that
;		text objects can be placed in the dialog box that is being
;		displayed and can generate empty/not-empty notifications
;		-Don 5/24/95
	cmp	ax, MSG_PROCESS_CALL_ROUTINE
	je	dispatch
	cmp	ax, MSG_META_TEXT_EMPTY_STATUS_CHANGED
	je	dispatch
	cmp	ax, MSG_META_REMOVING_DISK
	LONG je detach	
	cmp	ax, MSG_META_DETACH
	LONG je	detach
	cmp	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	stc					;don't allow destroy events thru
	je	checkEventDestination
	cmp	ax, MSG_META_DISPATCH_EVENT
	clc					;don't worry about message
	je	checkEventDestination
	cmp	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
LONG	je	sendToAppGCNList

addToQueue:
	popf				; get "stack" flag

	; Create "event" to save away
	;
	push	di
	mov	di, mask MF_RECORD
	jnc	haveStack2
	ornf	di, mask MF_STACK
haveStack2:
	call	ObjMessage
	mov	ax, di			; keep event in ax
	pop	di

	; Now, get the queue
	;
	mov	bx, ss:[di].UDDS_queue
	tst	bx
	jnz	haveQueue
	call	GeodeAllocQueue
	mov	ss:[di].UDDS_queue, bx
haveQueue:

	mov	si, sp
	clr	cx
	xchg	cx, ss:[si+4]		; si = calling thread
	mov	si, cx

	clr	di			; place in back
	call	QueuePostMessage	; Add event to hold-up queue
	ret

;
;--------
;

	
checkEventDestination:
;
;	If we are flushing the input queues for a message, go ahead and
;	dispatch it if the destination is an object that is allowed to
;	receive messages
;
;	(Changed:  If carry is set, we've discovered we're doing a 
;	MSG_META_FLUSH_INPUT_QUEUE, so we'll avoid sending this though if it 
;	leads to objects being destroyed, as it's too dangerous to let it 
;	though and hold up other stuff.   8/16/93 cbh)
;
; 	Pass: 	carry set if we're to hold up death related events
;
	push	ax, bx, cx, si
	mov	bx, cx				;BX <- event handle

	pushf					;Save whether message checking
						;  is needed

	call	ObjGetMessageInfo		;CX:SI <- dest for event

	popf					;Check messages?
	jnc	checkDest

	cmp	ax, MSG_META_FINAL_OBJ_FREE	;These are always held up.
	je	noDispatchFlushInputQueueEvent
	cmp	ax, MSG_PROCESS_FINAL_BLOCK_FREE
	je	noDispatchFlushInputQueueEvent

checkDest:
	clr	bx
	mov	ax, TGIT_THREAD_HANDLE
	call	ThreadGetInfo			;BX <- handle of current thread


	xchg	bx, cx				;BX:SI <- dest for event
						;CX <- handle of current thread
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo
	tst	ax				;If dest is a queue, dispatch
						; the event
	jz	dispatchFlushInputQueueEvent
	cmp	ax, cx				;If dest is run by different 
	jnz	dispatchFlushInputQueueEvent	; thread (or is a different
						; thread) dispatch the event

	call	CheckIfDestinationIsCurrentThread
	je	noDispatchFlushInputQueueEvent	;Don't let messages through
						; that are destined for
						; this thread.

	call	CheckIfObjectCanReceiveMessagesDuringUserDoDialog
	jc	dispatchFlushInputQueueEvent

noDispatchFlushInputQueueEvent:
	pop	ax, bx, cx, si
	jmp	addToQueue

dispatchFlushInputQueueEvent:
	pop	ax, bx, cx, si
	jmp	dispatch

;
;--------
;

sendToAppGCNList:
;
;	The message was destined for this thread, and the message # was
;	MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST. Just check to be certain
;	that the current thread is a subclass of GenProcessClass.
;	If so, dispatch the event, otherwise queue it up
;
	push	ds, si, es, di
	mov	si, segment GenProcessClass
	mov	ds, si
	mov	si, offset GenProcessClass
	les	di,ss:[TPD_classPointer]
	call	ObjIsClassADescendant
	pop	ds, si, es, di
	LONG jc	dispatch		;Branch if thread is a subclass of
					; GenProcess
	jmp	addToQueue

;
;--------
;

detach:
;
;	The current thread is detaching, so release the blocked thread
;	(Even though we aren't really blocked, this allows the box to
;	perform its own cleanup), then close the dialog boxq
;
	push	ax, bx, cx, si, di
	clr	cx
.assert IC_NULL eq 0
	mov	ax, MSG_GEN_INTERACTION_RELEASE_BLOCKED_THREAD_WITH_RESPONSE
	movdw	bxsi, ss:[di].UDDS_dialog
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	cx, IC_DISMISS
	clr	di
	call	ObjMessage	
	pop	ax, bx, cx, si, di
	jmp	addToQueue

;
;--------
;

iacpProcessMessage:
;
;	Check for a new app-mode connection.  If found, & app will be brought
;	to top on delivery (we're going to just shove it in the queue for
;	now), bring the app to the top NOW so that they can respond to this
;	dialog that's preventing the IACP message from getting through.
;	-- Doug 5/5/93
;
;	Changed to preserve ax, cx, dx, bp across the call to MessageProcess.
;	These registers are effectively destroyed, as they are changed to the
;	registers that are stored in the event in bx.  dloft 4/27/94
;
	push	bx, si, ax, cx, dx, bp
NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	si, SEGMENT_CS					>
FXIP <		push	si						>
	mov	si, offset BringToTopIfNewBringToTopAppConnection
	push	si
	mov	bx, cx			; get event being sent
	mov	si, -1			; preserve event
	call	MessageProcess		; take a peek
	pop	bx, si, ax, cx, dx, bp
	jmp	afterIacpProcessMessage

DispatchFromUserDoDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BringToTopIfNewBringToTopAppConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	With an "Eric" name like BringToTopIfNewBringToTopAppConnection,
		you still need a description?  Well, OK.   Check the passed
		message to see if it's a MSG_META_IACP_NEW_CONNECTION.  If
		so, peek into the AppLaunchBlock to see if this is a new
		"APP_MODE" connection, & hasn't specifically requested that
		we *not* do a BRING_TO_TOP.  If meets all criteria, send
		the app a MSG_GEN_BRING_TO_TOP, so that the user can interact
		with app & deal with the dialog that's on screen.  The
		MSG_META_IACP_NEW_CONNECTION itself will just end up in
		the dialog's hold up queue until the user's responded to
		the dialog.  At least this way, they're not stuck if it's
		not possible to click on the app (such as is the case on
		Zoomer)

CALLED BY:	INTERNAL
PASS:		Message data same as ObjMessage
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/6/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BringToTopIfNewBringToTopAppConnection	proc	far
	cmp	ax, MSG_META_IACP_NEW_CONNECTION
	jne	done

	;
	; if no AppLaunchBlock, may be engine mode, just skip -- brianc 9/25/95
	;
	jcxz	done
	push	ax, bx, di, ds
	mov	bx, cx
	call	MemLock
	push	bx
	mov	ds, ax
	cmp	ds:[ALB_appMode], MSG_GEN_PROCESS_OPEN_APPLICATION
	je	appMode
	tst	ds:[ALB_appMode]
	jnz	doneWithLaunchBlock
appMode:
	;
	; Check for request to defeat MSG_GEN_BRING_TO_TOP
	;
	test	ds:[ALB_launchFlags], mask ALF_DO_NOT_OPEN_ON_TOP
	jnz	doneWithLaunchBlock

	clr	bx
	call	GeodeGetAppObject		;bx:si = application
	mov	ax, MSG_GEN_BRING_TO_TOP
	clr	di		; Will be call, but send to preserve registers
	call	ObjMessage

doneWithLaunchBlock:
	pop	bx
	call	MemUnlock
	pop	ax, bx, di, ds

done:
	ret
BringToTopIfNewBringToTopAppConnection	endp

if FULL_EXECUTE_IN_PLACE

Common	ends
ResidentXIP	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	UserStandardDialog

DESCRIPTION:	Build a standard custom dialog box and call UserDoDialog on
		it.  Destroys the dialog when complete.

CALLED BY:	GLOBAL

PASS:
	on stack: StandardDialogParams structure
		StandardDialogParams	struct
    			SDP_customFlags		CustomDialogBoxFlags
    			SDP_customString	fptr
				(For XIP, *cannot* be in movable XIP resource)
    			SDP_stringArg1		fptr  
				(For XIP, *cannot* be in movable XIP resource)
  			SDP_stringArg2		fptr
				(For XIP, *cannot* be in movable XIP resource)
    			SDP_customTriggers	fptr.StandardDialogResponseTriggerTable
				(For XIP, *CAN* be in movable XIP resource)
			SDP_helpContext		fptr.char
				(For XIP, *CAN* be in movable XIP resource)
		StandardDialogParams	ends

		SDP_customTriggers only used if
		SDP_customFlags.CDBF_INTERACTION_TYPE = GIT_MULTIPLE_RESPONSE

		SDP_customString - string for custom dialog
		SDP_stringArg1 - first string argument (substituted for each
					C_CTRL_A character in string)
		SDP_stringArg2 - second string argument (substituted for each
					C_CTRL_B character in string)
		SDP_customTriggers - pointer to
					StandardDialogReponseTriggerTable.
					This is a table of monikers and response
					values of triggers that should be
					placed in the standard dialog's
					reply bar.  Only used for
					GIT_MULTIPLE_RESPONSE.
		SDP_helpContext - pointer to help context.  If non-zero then a
				  help trigger is put in the dialog box

	(either allocate structure on stack and fill in necessary fields, or
	 push fields individually in reverse order)

RETURN:
	ax - response from dialog trigger
		InteractionCommand or other value if
		CDBF_INTERACTION_TYPE = GIT_MULTIPLE_RESPONSE
		IC_NULL if interaction terminated by system
	parameters removed from stack

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@
USERSTANDARDDIALOG	proc	far	dParams:StandardDialogParams
		.enter

	; NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
	;
	; this trashing of BP works b/c Esp optimizes the .leave to just
	; do a POP BP, as there are no local variables in the frame. I
	; don't suggest you add any -- ardeb 3/18/92
	; 
	; NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE

		lea	bp, dParams			; ss:bp = params
		push	cx, dx
EC <	call	ECCheckStandardDialogParams				>

	;
	; Copy all the data pointed by the fptrs in StandardDialogParams to the
	; stack
	;
		call	UserStandardDialogCopyDataToStack	;dx = # of times of space allocation
	;
	; call the real function
	;
		call	UserStandardDialogReal		;ax = returned
	;
	; Before leaving, return all the space to the stack
	;
		call	UserStandardDialogReturnSpaceToStack
		pop	cx, dx
	.leave
	ret	@ArgSize
USERSTANDARDDIALOG	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserStandardDialogCopyDataToStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the data pointed by the fptrs in the StandardDialogParams
		to the stack, and change those fptrs point to them.

CALLED BY:	(INTERNAL) UserStandardDialogXIP
PASS:		ss:bp	= StandardDialogParams
RETURN:		dx	= # of times of space allocation in stack
DESTROYED:	nothing
SIDE EFFECTS:	
	The fptrs in StandardDialogParams struct point to the data on stack.
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserStandardDialogCopyDataToStack	proc	near
		uses	bx, cx, ds, si
		.enter
if ERROR_CHECK	
	;
	; Verify custom string is in valid resource.
	;
		mov	bx, ss:[bp].SDP_customString.segment
		mov	si, ss:[bp].SDP_customString.offset
		call	ECAssertValidFarPointerXIP			

	;
	; Verify string1 only if it is used.
	;
		pushdw	esdi			; don't trash these registers
		pushdw	bxsi			; save custom string
		movdw	esdi, bxsi					
		call	LocalStringLength	; cx = # chars
		push	cx			; save for 2nd string
		mov	ax, C_CTRL_A					
		LocalFindChar						
		jne	checkString2					
		
		mov	bx, ss:[bp].SDP_stringArg1.segment
		mov	si, ss:[bp].SDP_stringArg1.offset
		call	ECAssertValidFarPointerXIP			

checkString2:							
	;
	; Verify string2 only if it is used.
	;
		pop	cx			; cx = # chars
		popdw	esdi			; es:di = custom string
		mov	ax, C_CTRL_B					
		LocalFindChar
		popdw	esdi			; EC code shouldn't trash regs
		jne	helpContext

		mov	bx, ss:[bp].SDP_stringArg2.segment
		mov	si, ss:[bp].SDP_stringArg2.offset
		call	ECAssertValidFarPointerXIP			

helpContext:							
endif		
		clr	dx				; init counter

		tst	ss:[bp].SDP_helpContext.segment
		je	customTriggers
		inc	dx
		clr	cx
		lea	bx, ss:[bp].SDP_helpContext
		call	UserStandardDialogCopy
		
customTriggers:
		mov	cx, ss:[bp].SDP_customFlags
		andnf	cx, mask CDBF_INTERACTION_TYPE
		cmp	cx, GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE
		jne	exit
		inc	dx
		lea	bx, ss:[bp].SDP_customTriggers
		movdw	dssi, ss:[bp].SDP_customTriggers
		mov	cx, ds:[si].SDRTT_numTriggers	; cx = # of triggers
EC <		tst	ch						>
EC <		ERROR_NE	-1					>
		mov	al, size StandardDialogResponseTriggerEntry
		mul	cl
		add	ax, size word		;for the size of SDRTT_numTriggers
		mov_tr	cx, ax			;cx = total size to copy
		call	UserStandardDialogCopy
exit:
		.leave
		ret
UserStandardDialogCopyDataToStack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserStandardDialogCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the data pointed by the fptr whoes address is pointed
		by ds:si to the stack. 
CALLED BY:	(INTERNAL) UserStandardDialogCopyDataToStack
PASS:		ss:bx = pointing to address of the fptr which points to
			the data for the user dialog.
		cx	= 0 if the data is null-terminated.
			  non-zero (# of bytes to copy to the stack)
RETURN:		nothing
DESTROYED:	ds, si
SIDE EFFECTS:	
		The fptr pointed by ds:si has been changed to point to the
		data in the stack.
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserStandardDialogCopy	proc	near
		.enter
		mov	ds, ss:[bx].segment
		mov	si, ss:[bx].offset
		call	SysCopyToStackDSSI	;data copied to the stack
		mov	ss:[bx].offset, si
		mov	si, ds
		mov	ss:[bx].segment, si	;ss:[bx] = ptr to data on stack
		.leave
		ret
UserStandardDialogCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserStandardDialogReturnSpaceToStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the space used by UserStandardDialogXIP()

CALLED BY:	(INTERNAL) UserStandardDialogXIP
PASS:		dx	= # of times of allocation spaces in the stack
RETURN:		nothing
DESTROYED:	cx
SIDE EFFECTS:	
	The space are released.
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserStandardDialogReturnSpaceToStack	proc	near
		.enter
		mov	cx, dx
		tst	cx
		je	quit
dealloc:
		call	SysRemoveFromStack
		loop	dealloc
quit:
		.leave
		ret
UserStandardDialogReturnSpaceToStack	endp

ResidentXIP	ends
Common	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserStandardDialogReal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute the real code of UserStandardDialog() after all the data
		are copied onto the stack.

CALLED BY:	(INTERNAL) UserStandardDialogXIP
PASS:		ss:bp	= StandardDialogParams
RETURN:		ax - response from dialog trigger
		InteractionCommand or other value if
		CDBF_INTERACTION_TYPE = GIT_MULTIPLE_RESPONSE
		IC_NULL if interaction terminated by system
		parameters removed from stack
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserStandardDialogReal	proc	far
		uses	dx, di
		.enter
		mov	ax, MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG
		mov	dx, size StandardDialogParams
		mov	di, mask MF_CALL or mask MF_STACK
		call	BuildAndDoDialogCommon
		.leave
		ret
UserStandardDialogReal	endp

else

COMMENT @----------------------------------------------------------------------

FUNCTION:	UserStandardDialog

DESCRIPTION:	Build a standard custom dialog box and call UserDoDialog on
		it.  Destroys the dialog when complete.

CALLED BY:	GLOBAL

PASS:
	on stack: StandardDialogParams structure
		(For XIP, the fptrs *can* be pointing to the movable XIP code
			resource.)
		StandardDialogParams	struct
    			SDP_customFlags		CustomDialogBoxFlags
    			SDP_customString	fptr
    			SDP_stringArg1		fptr
    			SDP_stringArg2		fptr
    			SDP_customTriggers	fptr.StandardDialogResponseTriggerTable
			SDP_helpContext		fptr.char
		StandardDialogParams	ends

		SDP_customTriggers only used if
		SDP_customFlags.CDBF_INTERACTION_TYPE = GIT_MULTIPLE_RESPONSE

		SDP_customString - string for custom dialog
		SDP_stringArg1 - first string argument (substituted for each
					C_CTRL_A character in string)
		SDP_stringArg2 - second string argument (substituted for each
					C_CTRL_B character in string)
		SDP_customTriggers - pointer to
					StandardDialogReponseTriggerTable.
					This is a table of monikers and response
					values of triggers that should be
					placed in the standard dialog's
					reply bar.  Only used for
					GIT_MULTIPLE_RESPONSE.
		SDP_helpContext - pointer to help context.  If non-zero then a
				  help trigger is put in the dialog box

	(either allocate structure on stack and fill in necessary fields, or
	 push fields individually in reverse order)

RETURN:
	ax - response from dialog trigger
		InteractionCommand or other value if
		CDBF_INTERACTION_TYPE = GIT_MULTIPLE_RESPONSE
		IC_NULL if interaction terminated by system
	parameters removed from stack

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@


USERSTANDARDDIALOG	proc	far	dParams:StandardDialogParams
	.enter

	; NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
	;
	; this trashing of BP works b/c Esp optimizes the .leave to just
	; do a POP BP, as there are no local variables in the frame. I
	; don't suggest you add any -- ardeb 3/18/92
	; 
	; NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
	
	lea	bp, dParams			; ss:bp = params

EC <	call	ECCheckStandardDialogParams				>

	push	dx, di
	mov	ax, MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG
	mov	dx, size StandardDialogParams
	mov	di, mask MF_CALL or mask MF_STACK
	call	BuildAndDoDialogCommon
	pop	dx, di

	.leave

	ret	@ArgSize
USERSTANDARDDIALOG	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BuildAndDoDialogCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds dialog, call UserDoDialog on it, then destroys it.

CALLED BY:	INTERNAL
PASS:		ax	- message to call on app object to build dialog
		cx, dx, bp 	- data to pass
		di	- ObjMessage flags to use
RETURN:		ax	- response
DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Added documentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BuildAndDoDialogCommon	proc	near
	uses	bx, cx, si
	.enter

	call	BuildDialogCommon
	tst	bx				; Dialog created?
	jnz	continue			; if non-zero, yes, continue
	mov	ax, IC_NULL			; if not, dialog canceled by
	jmp	short done			; the system, exit

continue:

	; MAKE SOME SOUND IF THIS IS AN ERROR BOX

	and	ax, mask CDBF_DIALOG_TYPE
	mov	cx, SST_ERROR
	cmp	ax, CDT_ERROR shl offset CDBF_DIALOG_TYPE
	je	10$
	mov	cx, SST_WARNING
	cmp	ax, CDT_WARNING shl offset CDBF_DIALOG_TYPE
	jne	20$
10$:
	mov_tr	ax, cx
	call	UserStandardSound
20$:

	; put the dialog up

	call	UserDoDialog

	; remove the dialog

	call	UserDestroyDialog

done:
	.leave
	ret
BuildAndDoDialogCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BuildDialogCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds dialog

CALLED BY:	INTERNAL
PASS:		ax	- message to call on app object to build dialog
		cx, dx, bp 	- data to pass
		di	- ObjMessage flags to use
RETURN:		^lbx:si	- dialog, or NULL if unable to create
		ax	- CustomDialogBoxFlags
DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Added documentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BuildDialogCommon	proc	near	uses	cx, dx, bp
	.enter

	; Only processes are defined as having an application object. We
	; might be running on a thread owned by a non-process geode, in
	; which case we want to use the UI's app object.
	; 
	push	ax
	mov	ax, GGIT_ATTRIBUTES
	clr	bx				; => owner of current thread
	call	GeodeGetInfo
	test	ax, mask GA_PROCESS
	pop	ax
	jz	useUI

	; Send method to the application object to build the thing so that	
	; it can be done in the specific UI (and in the UI thread)
	;
	clr	bx
	call	GeodeGetAppObject		;bx:si = application
	;
	; If geode owning the calling thread has no application object itself,
	; provide a great service to the driver or library in question by
	; lending the UI's own app object for this purpose.
	;
	tst	bx
	jz	useUI

	;
	; We have an app object, but it must be USABLE for the dialog box
	; to work.
	;
	push	ax, cx, dx, bp, di
	mov	ax, MSG_GEN_GET_USABLE
	mov	di, mask MF_CALL
	call	ObjMessage			; destroys ax, cx, dx, bp, di
	pop	ax, cx, dx, bp, di
	jc	haveAppObject

useUI:
	mov	bx, handle 0
	call	GeodeGetAppObject		;bx:si = application
haveAppObject:

	call	ObjMessage			;cx:dx = summons
						;bp = CustomDialogBoxFlags
	mov	bx, cx
	mov	si, dx
	mov	ax, bp
	.leave
	ret
BuildDialogCommon	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	UserStandardDialogOptr

DESCRIPTION:	Same as UserStandardCustomDialog, but optrs passed instead on
		fptrs

CALLED BY:	GLOBAL

PASS:
	on stack: StandardDialogOptrParams

		SDOP_customTriggers.handle must be 0 if
		SDOP_customFlags.CDBF_INTERACTION_TYPE != GIT_MULTIPLE_RESPONSE

		SDOP_customString - string for custom dialog
					(SDOP_customString.handle = 0 if none)
		SDOP_strintArg1 - first string argument (substituted for each
					C_CTRL_A character in string)
					(SDOP_stringArg1.handle = 0 if none)
		SDOP_strintArg2 - second string argument (substituted for each
					C_CTRL_B character in string)
					(SDOP_stringArg2.handle = 0 if none)
		SDOP_customTriggers - pointer to
					StandardDialogReponseTriggerTable.
					This is a table of monikers and response
					values of triggers that should be
					placed in the standard dialog's
					reply bar.
					(SDOP_customTriggers.handle = 0 if none)
		SDOP_helpContext - pointer to help context.  If non-zero then a
				   help trigger is put in the dialog box

	(either allocate structure on stack and fill in necessary fields, or
	 push fields individually in reverse order)

RETURN:
	ax - response from dialog trigger
		InteractionCommand or other value if
		CDBF_INTERACTION_TYPE = GIT_MULTIPLE_RESPONSE
		IC_NULL if interaction terminated by system
	parameters removed from stack

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@
USERSTANDARDDIALOGOPTR	proc	far	dParams:StandardDialogParams
	uses	bx, dx, di, si

	.enter

	lea	bp, dParams			; ss:bp = params

EC <	call	ECCheckStandardDialogParams				>

	mov	di, offset SDOP_stringArg1
	call	USDOptrDeref
	push	bx

	mov	di, offset SDOP_stringArg2
	call	USDOptrDeref
	push	bx

	mov	di, offset SDOP_customString
	call	USDOptrDeref
	push	bx

	mov	ax, MSG_GEN_APPLICATION_BUILD_STANDARD_DIALOG
	mov	dx, size StandardDialogParams
	mov	di, mask MF_CALL or mask MF_STACK
	call	BuildAndDoDialogCommon			; ax = response

	pop	bx
	call	USDOptrUnlock			; string arg 2

	pop	bx
	call	USDOptrUnlock			; string arg 1

	pop	bx
	call	USDOptrUnlock			; custom string

	.leave

	ret	@ArgSize
USERSTANDARDDIALOGOPTR	endp

;
; pass:
;	ss:bp = StandardDialogOptrParams structure
;	di = SDOP_stringArg1, SDOP_stringArg2, SDOP_customString offset
; returns:
;	bx = block
; destroys:
;	si
;
USDOptrDeref	proc	near
	uses	ax, ds
	.enter
	mov	bx, ss:[bp][di].handle
	tst	bx
	jz	noString
	call	MemLock				; lock string block
	mov	ss:[bp][di].segment, ax		; store segment
	mov	ds, ax
	mov	si, ss:[bp][di].chunk		; deref string chunk
	mov	ax, ds:[si]
	mov	ss:[bp][di].offset, ax		; store string offset
noString:
	.leave
	ret
USDOptrDeref	endp

;
; pass:
;	bx = string block to unblock
; destroys:
;	bx
;
USDOptrUnlock	proc	near
	tst	bx
	jz	noString
	call	MemUnlock
noString:
	ret
USDOptrUnlock	endp

if ERROR_CHECK
; ss:bp = StandardDialogParams
ECCheckStandardDialogParams	proc	far
	uses	ax, cx
	.enter

	mov	ax, ss:[bp].SDP_customFlags
	test	ax, not mask CustomDialogBoxFlags
	ERROR_NZ	USER_STANDARD_DIALOG_BAD_PARAMS
	and	ax, mask CDBF_DIALOG_TYPE
	mov	cl, offset CDBF_DIALOG_TYPE
	shr	ax, cl
	cmp	ax, CustomDialogType
	ERROR_AE	USER_STANDARD_DIALOG_BAD_PARAMS
	mov	ax, ss:[bp].SDP_customFlags
	and	ax, mask CDBF_INTERACTION_TYPE
	mov	cl, offset CDBF_INTERACTION_TYPE
	shr	ax, cl
	cmp	ax, GenInteractionType
	ERROR_AE	USER_STANDARD_DIALOG_BAD_PARAMS
	;
	; must have custom string
	;	(could have more EC if we seperate USD and USDOptr)
	;
	tst	ss:[bp].SDP_customString.segment
	ERROR_Z	USER_STANDARD_DIALOG_BAD_PARAMS
	;
	; if GIT_MULTIPLE_RESPONSE, must have custom triggers
	;	(could have more EC if we seperate USD and USDOptr)
	;
	mov	ax, ss:[bp].SDP_customFlags
	and	ax, mask CDBF_INTERACTION_TYPE
	cmp	ax, GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE
	jne	notCustom
	tst	ss:[bp].SDP_customTriggers.segment
	ERROR_Z	USER_STANDARD_DIALOG_BAD_PARAMS
notCustom:

	.leave
	ret
ECCheckStandardDialogParams	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			UserCreateDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicates a template dialog block, attaches the dialog to
		an application object, & sets it fully USABLE, so that it
		may be used w/UserDoDialog.  Should be removed & destroyed
		by caller when no longer needed.

CALLED BY:	EXTERNAL
PASS:		^lbx:si	- Template object block, chunk offset of
			  GenInteractionClass within it to invoke.
			  The block must be sharable, read-only, and
			  the top GenInteraction must NOT be linked
			  into any generic tree.
RETURN:		^lbx:si	- created, fully USABLE dialog (or NULL if unable
			  to create)
DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserCreateDialog	proc	far	uses ax, cx, dx, di
	.enter
	mov	cx, bx
	mov	dx, si
	mov	ax, MSG_GEN_APPLICATION_BUILD_DIALOG_FROM_TEMPLATE
	mov	di, mask MF_CALL
	call	BuildDialogCommon
	.leave
	ret
UserCreateDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			UserDestroyDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys passed dialog, typically created using 
		UserCreateDialog.  May only be used on dialogs occupying a
		single block in their generic state, & the block must hold
		nothing other than the dialog.

CALLED BY:	EXTERNAL
PASS:		^bx:si	- dialog to destroy
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserDestroyDialog	proc	far	uses	ax, cx, dx, bp, di
	.enter

	; This is it -- just do it.
	;
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
	call	ObjMessage

	.leave
	ret
UserDestroyDialog	endp

Common ends
