COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		MailboxApplicationClass
FILE:		uiApplication.asm

AUTHOR:		Adam de Boor, Apr 25, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/25/94		Initial revision


DESCRIPTION:
	Implementation of the MailboxApplicationClass
		

	$Id: uiApplication.asm,v 1.1 97/04/05 01:19:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource

MailboxApplicationClass		; declare class record

ife	_CONTROL_PANELS
	method	OutboxDisplayOutboxPanel, MailboxApplicationClass,
		MSG_MA_DISPLAY_OUTBOX_PANEL
endif

MailboxClassStructures	ends

MBAppCode	segment	resource

MBAppCodeDerefGen	proc	near
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		ret
MBAppCodeDerefGen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMetaAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set uiDisplayType as soon as it's available

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		^hdx	= AppLaunchBlock
		bp	= extra state block
RETURN:		nothing (launch & state blocks not freed)
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMetaAttach 	method dynamic MailboxApplicationClass, MSG_META_ATTACH
		.enter
		mov	di, offset MailboxApplicationClass
		call	ObjCallSuperNoLock
	;
	; Now we're attached, we can safely get the DisplayType for others to
	; use.
	; 
		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
		call	ObjCallInstanceNoLock
		segmov	es, dgroup, di
		mov	es:[uiDisplayType], ah
	;
	; Add ourselves to the shutdown-control list so we can warn the user
	; if anything's being transmitted when s/he tries to shut down.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_SHUTDOWN_CONTROL
		call	GCNListAdd
	;
	; Start up the next-event timer.
	;
		mov	ax, MSG_MA_RECALC_NEXT_EVENT_TIMER
		call	ObjCallInstanceNoLock
		.leave
		ret
MAMetaAttach 	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAGenBringToTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we're not marked as a full-screenable application
		before we allow ourselves to be brought to the top. Being so
		marked really confuses things, since we have to be
		userInteractable to actually take the focus, but we don't
		have anything to take over the screen.

CALLED BY:	MSG_GEN_BRING_TO_TOP
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAGenBringToTop method dynamic MailboxApplicationClass, MSG_GEN_BRING_TO_TOP
	;
	; Clear the GWF_FULL_SCREEN bit so we don't take the full-screen
	; exclusive when brought to the top.
	;
		mov	bx, handle 0
		call	WinGeodeGetFlags
		andnf	ax, not mask GWF_FULL_SCREEN
		call	WinGeodeSetFlags
		mov	ax, MSG_GEN_BRING_TO_TOP
		mov	di, offset MailboxApplicationClass
		GOTO	ObjCallSuperNoLock
MAGenBringToTop	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAGetProgressArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the chunk handle of the array holding the progress
		boxes of the indicated type

CALLED BY:	(INTERNAL)
PASS:		ds:di	= MailboxApplicationInstance
		bp	= MPBType
RETURN:		*ds:si	= chunk array of optrs
		bp	= offset within MailboxApplicationInstance from
			  whence the chunk handle came
		flags set based on whether SI is zero
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MAGetProgressArray proc	near
		class	MailboxApplicationClass
		.enter
			CheckHack <MPBT_INBOX eq 0 and MPBType eq 2>
		tst	bp
		mov	bp, offset MAI_inPanels.MPBD_progressBoxes
		jz	havePointer
		mov	bp, offset MAI_outPanels.MPBD_progressBoxes
havePointer:
		mov	si, ds:[di+bp]
		tst	si
		.leave
		ret
MAGetProgressArray endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAAddProgressBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accept and record another progress box as a child of our
		application object.

CALLED BY:	MSG_MA_ADD_PROGRESS_BOX
PASS:		*ds:si	= MailboxApplication
		ds:di	= MailboxApplicationInstance
		^lcx:dx	= progress box to add
		bp	= MPBType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MAAddProgressBox method dynamic MailboxApplicationClass, MSG_MA_ADD_PROGRESS_BOX
		Assert	optr, cxdx
	;
	; Fetch the chunk handle of the array that tracks the boxes.
	; 
		mov	bx, si			; bx <- app obj, for possibly
						;  storing handle & for later
						;  adding of child
		call	MAGetProgressArray
		jnz	haveArray
	;
	; Don't have an array yet, so we need to allocate it.
	; 
		push	cx, bx
		mov	bx, size optr
		clr	ax, cx			; ax <- no special chunk flags
						; cx <- default header size
		call	ChunkArrayCreate
		pop	cx, bx			; *ds:bx <- app obj
	;
	; Store the handle in le instance data
	; 
		mov	di, ds:[bx]
		add	di, ds:[di].MailboxApplication_offset
		mov	ds:[di+bp], si
haveArray:
	;
	; Append another entry to the array and stuff the progress box's optr
	; into it.
	; 
		call	ChunkArrayAppend
		movdw	({optr}ds:[di]), cxdx
	;
	; Add the box as the first child of the application (we assume it wants
	; to show up on top...)
	; 
		mov	si, bx
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, CCO_FIRST
		call	ObjCallInstanceNoLock
	;
	; Now that it's in, mark it usable.
	; 
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		GOTO	ObjMessage
MAAddProgressBox endm
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAUnhideProgressBoxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-initiate all the boxes we have on record, thus bringing back
		any boxes that were hidden by the user.

CALLED BY:	MSG_MA_UNHIDE_PROGRESS_BOXES
PASS:		*ds:si	= MailboxApplication
		ds:di	= MailboxApplicationInstance
		bp	= MPBType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	MSG_GEN_INTERACTION_INITIATE is sent to all progress boxes
     			recorded in the progress box array for the type

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MAUnhideProgressBoxes method dynamic MailboxApplicationClass, 
					MSG_MA_UNHIDE_PROGRESS_BOXES
		.enter
		mov	bx, offset MAUnhideProgressBoxesCallback
		call	MAEnumProgressBoxes
		.leave
		ret
MAUnhideProgressBoxes endm
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAEnumProgressBoxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback routine for each existing progress box

CALLED BY:	(INTERNAL) MAUnhideProgressBoxes, MAMetaDetach
PASS:		*ds:si	= MailboxApplication object
		cx, dx	= data for callback
		cs:bx	= callback routine (far)
		bp	= MPBType indicating which list to enum
RETURN:		carry set if callback returned carry set
DESTROYED:	bx, di
SIDE EFFECTS:	none here

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 9/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MAEnumProgressBoxes proc	near
		uses	si
		class	MailboxApplicationClass
		.enter
		DerefDI	MailboxApplication
		call	MAGetProgressArray
		jz	done
		mov	di, bx
		mov	bx, cs
		call	ChunkArrayEnum
done:
		.leave
		ret
MAEnumProgressBoxes endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAUnhideProgressBoxesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_GEN_INTERACTION_INITIATE to the current progress box

CALLED BY:	(INTERNAL) MAUnhideProgressBoxes
PASS:		ds:di	= optr of progress box to re-initiate
RETURN:		carry set to stop enumerating
DESTROYED:	bx, si, di allowed
		ax
SIDE EFFECTS:	object block holding the array might conceivably move...

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MAUnhideProgressBoxesCallback proc	far
		.enter
		movdw	bxsi, ({optr}ds:[di])
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		clc
		.leave
		ret
MAUnhideProgressBoxesCallback endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAGenRemoveChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept routine to clean up our own data structures when
		a progress box or control panel is about to be removed.

CALLED BY:	MSG_GEN_REMOVE_CHILD
PASS:		*ds:si	= MailboxApplication
		ds:di	= MailboxApplicationInstance
		^lcx:dx	= child to remove
RETURN:		nothing
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAGenRemoveChild method dynamic MailboxApplicationClass, MSG_GEN_REMOVE_CHILD
		uses	ax, bp
		.enter
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
	;
	; First see if it's a progress box.
	; 
		mov	bp, MPBT_INBOX
		mov	bx, offset MAGenRemoveChildCallback
		call	MAEnumProgressBoxes
		jc	passItOn		; => found the kid (and removed
						;  it from the array in the
						;  callback), so we can let our
						;  superclass do the rest
		mov	bp, MPBT_OUTBOX
		mov	bx, offset MAGenRemoveChildCallback
		call	MAEnumProgressBoxes
		jc	passItOn
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

if	_CONTROL_PANELS
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
	; we need to re-deref di
		DerefDI	MailboxApplication
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

	;
	; Look for the child in the outbox panels list.
	; 
		lea	bx, ds:[di].MAI_outPanels.MPBD_panels-offset MADP_next
		call	MAGenRemoveChildCheckPanels
		jc	passItOn
	;
	; Not there. Try the inbox panels list.
	; 
		lea	bx, ds:[di].MAI_inPanels.MPBD_panels-offset MADP_next
		call	MAGenRemoveChildCheckPanels
		jc	passItOn
endif	; _CONTROL_PANELS

	;
	; Still not there.  Try the confirmation box array.
	;
		mov	bx, offset MARemoveConfirmBoxCallback
		call	MAEnumConfirmBoxes
	;
	; Mighta been dere, but we don't much care: we've cleaned up what we
	; needed to, regardless of what checkPanels returned.
	; 
passItOn::
		.leave
		mov	di, offset MailboxApplicationClass
		GOTO	ObjCallSuperNoLock
MAGenRemoveChild endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAGenRemoveChildCheckPanels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a child is in the list of panels for the inbox or
		outbox (we check only one list here...) and remove its
		entry if so.

CALLED BY:	
PASS:		ds:bx	= head pointer (this is a bit funky, as it points into
			  the MailboxPanelBoxData as if it were a
			  MailboxAppDisplayPanel, lining up the MPBD_panels
			  field with the MADP_next field).
		^lcx:dx	= child being removed
RETURN:		carry set if panel actually found and removed:
			di	= destroyed
	 	carry clear if child not a panel in this list:
			di	= preserved
DESTROYED:	ax, bx
SIDE EFFECTS:	panel chunk freed if found

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS
MAGenRemoveChildCheckPanels proc	near
		class	MailboxApplicationClass
		uses	si
		.enter
		mov	ax, bx

checkPanelsLoop:
	;
	; Get the next panel to check.
	; 
		mov	si, ds:[bx].MADP_next
		tst_clc	si
		jz	done			; => hit end of list w/o finding
						;  the object
	;
	; Deref the MailboxAppDisplayPanel chunk and see if the child is this
	; panel.
	; 
		mov	si, ds:[si]
		cmpdw	ds:[si].MADP_panel, cxdx
		je	nukePanel
	;
	; It's not, point ds:bx to the dereferenced panel data and loop to
	; check the next one.
	; 
		mov	bx, si
		jmp	checkPanelsLoop

nukePanel:
	;
	; Unlink the found chunk from the list.
	; 
		mov_tr	di, ax			; ds:di <- head pointer, for
						;  clearing MPBD_system
		mov	ax, ds:[si].MADP_next
		xchg	ds:[bx].MADP_next, ax	; point prev around the panel
						;  that's being removed,
						;  getting back the handle
						;  of said panel
	;
	; If this is the system panel, clear that pointer, please. (Recall
	; that ds:di is the base of the MailboxPanelBoxData structure plus
	; the difference between the MPBD_panels and MADP_next fields, as
	; was added to get a pointer that pretended to be a MailboxAppDisplay-
	; Panel for the loop.)
	; 
		sub	di, offset MPBD_panels - offset MADP_next
		cmp	ds:[di].MPBD_system, ax
		jne	freeIt
		mov	ds:[di].MPBD_system, 0
freeIt:
		call	LMemFree
		stc
done:
		.leave
		ret
MAGenRemoveChildCheckPanels endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAGenRemoveChildCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to see if a child that's being removed is a progress
		box and delete it from the array if so.

CALLED BY:	(INTERNAL) MAGenRemoveChild via ChunkArrayEnum
PASS:		*ds:si	= progress box array
		ds:di	= current entry to check
		^lcx:dx	= child being removed
RETURN:		carry set to stop enumerating (found progress box)
		carry clear to keep searching
DESTROYED:	nothing
SIDE EFFECTS:	entry may be deleted (will be if found)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MAGenRemoveChildCallback proc	far
		.enter
		cmpdw	({optr}ds:[di]), cxdx
		clc
		jne	done
		call	ChunkArrayDelete
		stc
done:
		.leave
		ret
MAGenRemoveChildCallback endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MARemoveConfirmBoxCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to remove an elememt for this confirm box from the
		array. 

CALLED BY:	(INTERNAL) MAGenRemoveChild via MAEnumConfirmBoxes
PASS:		ds:di	= MAConfirmBoxData
		^lcx:dx	= child being removed
RETURN:		carry clear to keep searching (no match)
		carry set to stop (match)
			array element deleted
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MARemoveConfirmBoxCallback	proc	far

	Assert	objectOD, ds:[di].MACBD_dialog, GenInteractionClass, FIXUP

	cmpdw	cxdx, ds:[di].MACBD_dialog
	clc
	jne	done
	call	ChunkArrayDelete
	stc

done:
	ret
MARemoveConfirmBoxCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADestroyDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the dialog and duplicated block contained in the same
		block as the trigger that sent this message.

CALLED BY:	MSG_MA_DESTROY_DIALOG
PASS:		*ds:si	= MailboxApplication
		^lcx:dx	= optr of GenTrigger that's in the same duplicated
			  block as the dialog that's our child
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	block is freed (after sufficient queue flushing, of course)
     		and dialog is removed as a child

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MADestroyDialog method dynamic MailboxApplicationClass, MSG_MA_DESTROY_DIALOG
		.enter
	;
	; First find the child in the same block as the trigger.
	; 
		clr	ax
		push	ax, ax			; start w/first child
		mov	ax, offset GI_link
		push	ax			; offset of LinkPart
		mov	ax, SEGMENT_CS
		push	ax
		mov	ax, offset MADestroyDialogCallback
		push	ax			; vfptr of callback
		mov	bx, offset Gen_offset	; bx <- master part
		mov	di, offset GI_comp	; di <- offset of CompPart
		call	ObjCompProcessChildren
EC <		ERROR_NC DIALOG_NOT_FOUND				>
	;
	; Tell the child to remove itself.
	;
	; NOTE: UserDestroyDialog is not really an option here, unless you
	; change this code to do what MSG_GEN_REMOVE_CHILD does in cleaning up
	; various references to things that are maintained by the app object.
	; 
		push	si
   		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_REMOVE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	dl, VUM_NOW
		mov	bp, mask CCF_MARK_DIRTY
		call	ObjMessage
	;
	; Then tell it to destroy the block it's in.
	; 
		mov	ax, MSG_META_BLOCK_FREE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Make sure nothing in the dialog remains on any of our GCN lists.
	; 
		pop	si
		mov	cx, bx
		mov	ax, MSG_MA_REMOVE_BLOCK_OBJECTS_FROM_ALL_GCN_LISTS
		call	ObjCallInstanceNoLock
		.leave
		ret
MADestroyDialog endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADestroyDialogCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate a child of the application in
		the same block as the trigger that sent the 
		MSG_MA_DESTROY_DIALOG message.

CALLED BY:	(INTERNAL) MADestroyDialog via ObjCompProcessChildren
PASS:		*ds:si	= child
		*es:di	= composite
		cx	= block that holds the trigger and, therefore, the 
			  dialog
RETURN:		carry set if child is in the block:
			^lcx:dx	= optr of the child to be removed & nuked
		carry clear if child not in the block
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MADestroyDialogCallback proc	far
		.enter
		cmp	ds:[LMBH_handle], cx
		clc
		jne	done
		mov	dx, si
		stc
done:
		.leave
		ret
MADestroyDialogCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MANotifyUnsendable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the user know a particular message cannot be sent

CALLED BY:	MSG_MA_NOTIFY_UNSENDABLE
PASS:		ss:bp	= MANotifyUnsendableArgs
		*ds:si	= MailboxApplication
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	notification dialog is added to the screen

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife 	_QUERY_DELETE_AFTER_PERMANENT_ERROR	; handled by query code if
						;  unsendable (=> permanent
						;  error)

MANotifyUnsendable method dynamic MailboxApplicationClass, 
				MSG_MA_NOTIFY_UNSENDABLE
	;
	; Make a duplicate of the template resource and add the root as
	; our child.
	; 
		push	si
		mov	bx, handle UnsendableRoot
		mov	si, offset UnsendableRoot
		call	UtilCreateDialogFixupDS
		pop	si
	;
	; Lock the resource down for a while.
	; 
		call	ObjSwapLock
		push	bx
		assume	ds:UnsendableUI
	;
	; Tell the glyph to create a moniker for the message, including the
	; transport (just in case).
	; 
		movdw	cxdx, ss:[bp].MANUA_message
		push	bp
		mov	bp, ss:[bp].MANUA_talID
		mov	ax, MSG_MG_SET_MESSAGE_ALL_VIEW
		mov	si, offset UnsendableMessage
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; Replace the \1 in the UnsendableText object's text with the reason
	; the message cannot be sent.
	; 
		mov	si, offset UnsendableText
		movdw	cxdx, ss:[bp].MANUA_string
		call	UtilReplaceFirstMarkerInTextChunk
	;
	; Bring the dialog up on-screen.
	; 
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	si, offset UnsendableRoot
		call	ObjCallInstanceNoLock
		pop	bx
		call	ObjSwapUnlock
		ret
MANotifyUnsendable endm
endif	; !_QUERY_DELETE_AFTER_PERMANENT_ERROR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAOutboxConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the user know the message is in the outbox, but cannot
		be sent at this time.

CALLED BY:	MSG_MA_OUTBOX_CONFIRMATION
PASS:		cxdx	= MailboxMessage
		bp	= talID of message addresses to display
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version
	AY	1/ 9/95		Changed to use MAInboxOutboxConfirmationCommon

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAOutboxConfirmation method dynamic MailboxApplicationClass, 
				MSG_MA_OUTBOX_CONFIRMATION

if	_OUTBOX_FEEDBACK
	;
	; Confirmation is handled by the feedback box, so just remove the
	; reference to the message.
	;
	call	MARemoveMsgReference
else
	mov	ax, MSG_OC_DISMISS
	push	ax
	push	si
	clr	ax
	push	ax			; push zero, always put up dialog

	mov	bx, handle OutConfirmRoot
	mov	si, offset OutConfirmRoot
	mov	ax, MSG_OC_SET_MESSAGE
	call	MAInboxOutboxConfirmationCommon
endif	; !_OUTBOX_FEEDBACK
	ret
MAOutboxConfirmation endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MARemoveMsgReference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a reference from the passed message.

CALLED BY:	(INTERNAL) MAOutboxConfirmation
			   MAMessageNotificationDone
PASS:		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	message may be destroyed if last reference

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 5/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MARemoveMsgReference proc near
		.enter
		MovMsg	dxax, cxdx
		call	MailboxGetAdminFile
		call	DBQDelRef
		.leave
		ret
MARemoveMsgReference endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAOutboxSendableConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a box to let the user know a message is in the
		outbox and ready to send.

CALLED BY:	MSG_MA_OUTBOX_SENDABLE_CONFIRMATION
PASS:		cxdx	= MailboxMessage
		bp	= TalID
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	message may be submitted for transmission, if it's marked
     			MMF_SEND_WITHOUT_QUERY

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/94		Initial version
	AY	1/ 9/95		Moved common code to
				MAInboxOutboxConfirmationCommon

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAOutboxSendableConfirmation method dynamic MailboxApplicationClass, 
			MSG_MA_OUTBOX_SENDABLE_CONFIRMATION

	mov	ax, MSG_MSND_SEND_MESSAGE_LATER
	push	ax
	push	si
	push	si			; push non-zero, send msg if
					;  MMF_SEND_WITHOUT_QUERY set

if	not _OUTBOX_SEND_WITHOUT_QUERY
	mov	bx, handle OutConfirmSendableRoot
	mov	si, offset OutConfirmSendableRoot
	mov	ax, MSG_MSND_SET_MESSAGE
endif	; not _OUTBOX_SEND_WITHOUT_QUERY
	call	MAInboxOutboxConfirmationCommon

	ret
MAOutboxSendableConfirmation endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAInboxOutboxConfirmationCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to put up all sorts of confirmation boxes.

CALLED BY:	(INTERNAL) MAOutboxSendableConfirmation, MAOutboxConfirmation,
			MAOutboxNotifyTransWinOpen,
			MAOutboxNotifyTransWinClose, MAInboxNotifyTransWinClose

PASS:		cxdx	= MailboxMessage
		bp	= TalID (if applicable)
		^lbx:si	= root of dialog template to duplicate (see note)
		ax	= message to set the MailboxMessage to display (see
			  note)
				Pass:	cxdx	= MailboxMessage w/ 1 extra ref
					bp	= TalID
				Return:	nothing
					ax, cx, dx, bp = destroyed
		ds	= segment of MailboxApplicationClass object

		On stack (pushed in this order):
		- msg to send to dialog box to dismiss it (word), or 0 to not
		  add the dialog to confirmBox array (as an optimization)
		  (e.g. for transWinClose box, which no one else should be
		  kicking it off screen)
		- chunk handle of MailboxApp object (lptr)
		- word-sized flag
		    If non-zero:
			send message via OutboxTransmitMessage if
			MMF_SEND_WITHOUT_QUERY is set, else put up dialog box
		    else
			always put up dialog box

		NOTE: If it is known that MMF_SEND_WITHOUT_QUERY is set in the
		      message, and the word-sized check-send-without-query-bit
		      flag is passed set, bx, si and ax can be passed with
		      garbage.  This is the situation when the feature constant
		      _OUTBOX_SEND_wITHOUT_QUERY is set.

RETURN:		nothing
		parameters removed from stack
DESTROYED:	ax, bx, cx, dx, si, di, ds
SIDE EFFECTS:	es NOT fixed up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAInboxOutboxConfirmationCommon	proc	near	\
					checkSendWithoutQuery:word,
					appObj:lptr.MailboxApplicationBase,
					dismissMsg:word
		class	MailboxApplicationClass
		talID	local	TalID	push	bp
		.enter

		tst	ss:[checkSendWithoutQuery]
		jz	putUpDialog

EC <		push	si						>
EC <		mov	si, ss:[appObj]					>
EC <		Assert	objectPtr, dssi, MailboxApplicationClass	>
EC <		pop	si						>
	;
	; See if the message is marked for sending without asking the user
	; anything. If it is, we want to send it on its way -- the progress
	; box showing up will be confirmation enough that the message is
	; in the outbox.
	; 
		push	ax
		call	MailboxGetMessageFlags
		test	ax, mask MMF_SEND_WITHOUT_QUERY
		pop	ax
		jnz	sendIt

putUpDialog:
	;
	; Duplicate the template resource and add the box as our first child.
	; 
		push	ds:[OLMBH_header].LMBH_handle	; for fixup
		call	UserCreateDialog	; *DOES NOT FIXUP DS*
	;
	; Tell the box the message & addresses it's to display.
	; 
		push	bp
		mov	bp, ss:[talID]
		clr	di			; (DS was destroyed, so no
						; fixup)
		call	ObjMessage		; di = 0
		pop	bp
	;
	; Bring the box up on screen to let the user decide what to do.
	; 
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage
	;
	; Add the box to our array, if requested by caller.
	;
		mov_tr	ax, bx			; ^lax:si = new dialog
		pop	bx			; bx = app obj hptr
		tst	ss:[dismissMsg]
		jz	done			; jump if don't want to add

		call	MemDerefDS
		mov	bx, si			; ^lax:bx = new dialog
		mov	si, ss:[appObj]		; *ds:si = MailboxApp obj
		DerefDI	MailboxApplication
		mov	si, ds:[di].MAI_confirmBoxes
		call	ChunkArrayAppend	; ds:di = MAConfirmBoxData
		movdw	ds:[di].MACBD_dialog, axbx
		movdw	ds:[di].MACBD_msgDisplayed, cxdx
		mov	ax, ss:[dismissMsg]
		mov	ds:[di].MACBD_dismissMsg, ax

		jmp	done

sendIt:
	;
	; Message is marked SEND_WITHOUT_QUERY, so start it sending.
	;
	; XXX: WHAT IF MESSAGE IS IN THE INBOX?
	; 
		MovMsg	dxax, cxdx
		mov	cx, ss:[talID]
		push	ax
		call	OutboxTransmitMessage
		; XXX: DO SOMETHING ABOUT GETTING AN ERROR HERE
		pop	ax
		call	MailboxGetAdminFile ; remove reference from the message
		call	DBQDelRef	;  now that it's been queued

done:
		.leave
		ret	@ArgSize
MAInboxOutboxConfirmationCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADismissConfirmBoxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the corresponding dismiss messages to all confirm
		dialog boxes that are displaying this MailboxMessage.

CALLED BY:	MSG_MA_DISMISS_CONFIRM_BOXES
PASS:		*ds:si	= MailboxApplicationClass object
		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MADismissConfirmBoxes	method dynamic MailboxApplicationClass, 
					MSG_MA_DISMISS_CONFIRM_BOXES

	mov	bx, offset MADismissConfirmBoxWithSameMsgCallback
	call	MAEnumConfirmBoxes

	ret
MADismissConfirmBoxes	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAEnumConfirmBoxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate thru all the dialog boxes stored in the confirm
		box array.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= MailboxApplicationClass object
		cs:bx	= offset of callback routine (for ChunkArrayEnum)
		cx, dx, bp, es = data passed to callback (if any)
RETURN:		ds fixed up
		dx, bp, es = returned from last callback
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAEnumConfirmBoxes	proc	near
	class	MailboxApplicationClass
	uses	ax,cx,si,di
	.enter

	DerefDI	MailboxApplication
	mov	si, ds:[di].MAI_confirmBoxes	; *ds:si = array
	mov	di, bx
	mov	bx, cs			; bx:di = callback
	call	ChunkArrayEnum

	.leave
	ret
MAEnumConfirmBoxes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADismissConfirmBoxWithSameMsgCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the dismiss message to this confirm box if it is
		displaying the specified MailboxMessage.

CALLED BY:	(INTERNAL) MAInboxOutboxConfirmationCommon via
			MAEnumConfirmBoxes
PASS:		*ds:si	= array
		ds:di	= MAConfirmBoxData
		cxdx	= MailboxMessage
RETURN:		carry clear to keep searching (no match)
		carry set to stop (match)
			dialog box dismissed, array element deleted.
DESTROYED:	if no match
			nothing
		if match
			ax, bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We don't need to delete the MAConfirmBoxData element here even if it
	is a match, as sending the dismiss message will invoke
	MSG_GEN_REMOVE_CHILD which in turn will delete the element from the
	array.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MADismissConfirmBoxWithSameMsgCallback	proc	far

	cmpdw	ds:[di].MACBD_msgDisplayed, cxdx
	clc				; assume not match
	jne	done

	;
	; Match found.  Dismiss dialog.
	;
	movdw	bxsi, ds:[di].MACBD_dialog
	mov	ax, ds:[di].MACBD_dismissMsg
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	stc

done:
	ret
MADismissConfirmBoxWithSameMsgCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MANukeEquivalents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring down any equivalent panels displaying a subset of
		the messages for the indicated criteria. If the criteria
		will be for the system panel, "subset" means "improper
		subset", so any specific panel that would display exactly
		the same messages will also be brought down. If the criteria
		will be for a specific panel, a panel showing an improper
		subset will cause the criteria passed to be freed and
		carry returned set, meaning no new panel should be put up.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= MailboxApplication object
		bx	= offset within MailboxApplicationInstance of
			  MailboxPanelBoxData to consult
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for MDPT_BY_MEDIUM
		di	= MCP_IS_SPECIFIC/MCP_IS_SYSTEM
RETURN:		carry set if something's already displaying the messages for the
			criteria.
DESTROYED:	ax
SIDE EFFECTS:	various control panels may be forced down

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MANukeEquivalents proc	near
		uses	bx
		.enter

lookAgain:
		call	MALocateEquivalentPanel	; *ds:ax <-
						;  MailboxAppDisplayPanel

		jc	maybeNuke
		
		cmp	cx, MDPT_BY_TRANSPORT
		jne	createNew		; => no further comparisons
						;  to make...
	;
	; Ok, so nothing for the transport specifically. Let's see if there's
	; something for the medium that would be displaying the transport's
	; messages.
	; 
		push	cx, dx
		mov	cx, MDPT_BY_MEDIUM
		mov	dx, bp
		call	MALocateEquivalentPanel
		pop	cx, dx
		jc	maybeNuke
		
createNew:
		clc
done:
		.leave
		ret

maybeNuke:
	;
	; We've gotten an equivalent panel, but it might be too restrictive.
	; If it is, we want to destroy the panel and look again, the end
	; result being all the panels that are subsets of the more-general
	; criteria we're employing get biffed and then we bring up the
	; more-general one.
	;
	; Possible subsets:
	; 	- we were searching by medium and found a by-transport panel
	;	  that uses the unit (or *a* unit, if this the criteria are
	;	  for any unit) of the medium
	;	- we were searching by medium for any unit and found a
	;	  by-medium for a specific unit of the medium
	;
	; The other possibility we need to consider here is if we were searching
	; for a more-restrictive set of criteria and found the superset of it.
	; This happens on the second pass for a by-transport search, when we're
	; searching by-medium and find a by-medium panel for the same or any
	; unit. In this case, we just free the criteria and boogie, as the
	; panel we found is sufficient to display the messages that want to be
	; displayed.
	; 
	
		push	bx			; save MPBD offset
		mov	bx, ax			; (keep panel chunk in AX for
						;  possible destruction)
		mov	bx, ds:[bx]
		cmp	ds:[bx].MADP_type, cx
		jne	nukeIfSearchByMedium
		
		cmp	cx, MDPT_BY_TRANSPORT
		je	foundSame		; => found exactly what we
						;  were looking for
	;
	; Searching by medium and found a by-medium panel. If the one we found
	; is displaying for any unit of the medium, then we're happy.
	; 
		cmp	ds:[bx].MADP_criteria.MDPC_byMedium.MDBMD_medium.MMD_unitType, MUT_ANY
		je	foundSame		; => panel already for any unit,
						;  so no need to change
	    ;
	    ; Lock down the new criteria and see if they're for any unit...
	    ; 
		push	bx, ax
		mov	bx, dx
		call	MemLock
		mov	es, ax
		cmp	es:[MDBMD_medium.MMD_unitType], MUT_ANY
		call	MemUnlock
		pop	bx, ax
		jne	foundSame		; => found exactly what we were
						;  looking for
		
		jmp	nukePanelAndTryAgain	; else found a specific and want
						;  a general, so biff the
						;  specific and keep looking


nukeIfSearchByMedium:
		cmp	cx, MDPT_BY_MEDIUM
		jne	foundSame		; => found a medium and
						;  wanted a transport, but
						;  medium is displaying the
						;  transport's messages, so
						;  do nothing (XXX: maybe bring
						;  to top?)
		
nukePanelAndTryAgain:
		call	MACallDestroyDialogForPanel
		pop	bx			; bx <- MPBD offset
		jmp	lookAgain

foundSame:
	;
	; Found a panel displaying the same as the passed criteria want to
	; see. If the criteria are for the system panel, we want to nuke the
	; panel, rather than return saying there's nothing that needs doing,
	; as the system panel is per the user's explicit request and takes
	; precedence over whatever we put up of our own volition.
	; 
		cmp	di, MCP_IS_SYSTEM
		je	nukePanelAndTryAgain

		pop	bx			; bx <- MPBD offset
	;
	; The existing panel is fine. We just need to free the memory block(s)
	; with the criteria we were given.
	; 
		mov	bx, dx
		call	MemFree
		cmp	cx, MDPT_BY_TRANSPORT
		jne	dontPutUpPanel
		mov	bx, bp
		call	MemFree
dontPutUpPanel:
		stc
		jmp	done
MANukeEquivalents endp
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADisplaySystemOutboxPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the system outbox panel up on screen.

CALLED BY:	MSG_MA_DISPLAY_SYSTEM_OUTBOX_PANEL
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		If system panel not already extant:
			Call the Outbox to get the criteria for the most-recent 
			message.
		
			Destroy any equivalent panels (including improper 
			subsets)
		
			Call MACreateNewPanel(MCP_IS_SYSTEM)
		
		Bring up any outbox progress boxes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS

.warn	-private

if	MAILBOX_PERSISTENT_PROGRESS_BOXES

maOutboxPanelData	UISystemPanelData <
	OutboxGetDefaultSystemCriteria,
	MAI_outPanels,
	MPBT_OUTBOX
>

else

maOutboxPanelData	UISystemPanelData <
	OutboxGetDefaultSystemCriteria,
	MAI_outPanels
>

endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

.warn	@private

MADisplaySystemOutboxPanel method dynamic MailboxApplicationClass, 
				MSG_MA_DISPLAY_SYSTEM_OUTBOX_PANEL
		mov	bx, offset maOutboxPanelData
		FALL_THRU_ECN	MADisplaySystemPanelCommon
MADisplaySystemOutboxPanel endm

endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADisplaySystemPanelCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to bring up the system inbox or outbox control
		panel.

CALLED BY:	(INTERNAL) MADisplaySystemInboxPanel,
			   MADisplaySystemOutboxPanel
PASS:		*ds:si	= MailboxApplication
		ds:di	= MailboxApplicationInstance
		cs:bx	= UISystemPanelData
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MADisplaySystemPanelCommon proc	ecnear
		class	MailboxApplicationClass
		.enter
	;
	; If the system panel is already up, just bring the progress boxes
	; to the fore.
	; 
		mov	bp, cs:[bx].UISPD_panelData
		tst	ds:[di+bp].MPBD_system
		jnz	bringUpProgressBoxes

		push	bx			; save UISPD offset for
						;  unhiding progress boxes
	;
	; Fetch the criteria for what the outbox/inbox module wants us to
	; display
	; 
		push	bp			; save panel data offset
		mov	ax, cs:[bx].UISPD_getCriteria.offset
		mov	bx, cs:[bx].UISPD_getCriteria.segment
		call	ProcCallFixedOrMovable
	;
	; Make sure no other panels are showing anything related to those
	; criteria.
	; 
		pop	bx			; bx <- offset to panel data
		mov	di, MCP_IS_SYSTEM
		call	MANukeEquivalents
	;
	; Create the panel.
	; 
		call	MACreateNewPanel
		pop	bx

bringUpProgressBoxes:
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		mov	bp, cs:[bx].UISPD_type
		mov	ax, MSG_MA_UNHIDE_PROGRESS_BOXES
		call	ObjCallInstanceNoLock
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
		.leave
		ret
MADisplaySystemPanelCommon endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADisplayOutboxPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure there's a modified control panel on-screen to display
		the messages selected by the indicated criteria. When panel is
		MDPT_BY_TRANSPORT, the messages for that transport & address
		are assumed to be on-screen if there's an MDPT_BY_MEDIUM panel
		up whose criteria match the BY_MEDIUM criteria that must also
		be passed. 
		
		If an MDPT_BY_MEDIUM panel is sought and there's an
		MDPT_BY_TRANSPORT panel up that matches, that panel will be 
		destroyed.
		
		Similarly, if an MDPT_BY_MEDIUM panel is found for a specific
		unit when one for any unit of the medium is sought, that
		panel will be destroyed.
		
CALLED BY:	MSG_MA_DISPLAY_OUTBOX_PANEL
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for MDPT_BY_MEDIUM
RETURN:		memory block(s) freed
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MADisplayOutboxPanel	method dynamic MailboxApplicationClass, 
				MSG_MA_DISPLAY_OUTBOX_PANEL
		mov	bx, offset MAI_outPanels
		FALL_THRU_ECN	MADisplayPanelCommon
MADisplayOutboxPanel	endm
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADisplayPanelCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring a specific panel for the inbox or outbox up on-screen,
		if the messages it will display aren't already being displayed

CALLED BY:	(INTERNAL) MADisplayOutboxPanel,
			   MADisplayInboxPanel
PASS:		*ds:si	= MailboxApplicationClass object
		bx	= offset within MailboxApplicationInstance to
			  MailboxPanelData
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for MDPT_MEDIUM
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	panels with criteria that are a subset of those passed will
     			be destroyed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/28/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MADisplayPanelCommon proc	ecnear
		.enter
		Assert	ne, cx, MDPT_ALL
	;
	; See if there's an equivalent panel already on-screen.
	; 
		mov	di, MCP_IS_SPECIFIC
		call	MANukeEquivalents
		jc	done			; => already something up
						;  for these criteria
	;
	; Nothing there yet, so create something specific.
	; 
		mov	di, MCP_IS_SPECIFIC
		call	MACreateNewPanel
done:
		.leave
		ret
MADisplayPanelCommon endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACallDestroyDialogForPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call ourselves to delete a panel in the normal way.

CALLED BY:	(INTERNAL) MADisplayOutboxPanel,
			   MAOutboxSysPanelCriteriaChanged
PASS:		*ds:si	= MailboxApplication
		*ds:ax	= MailboxAppDisplayPanel
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	panel is removed as a kid, the panel chunk is freed, and the
     			panel object block is sent on its way toward death

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MACallDestroyDialogForPanel proc	near
		class	MailboxApplicationClass
		uses	bx, cx, dx, bp
		.enter
		mov_tr	bx, ax
		mov	bx, ds:[bx]
		movdw	cxdx, ds:[bx].MADP_panel
		mov	ax, MSG_MA_DESTROY_DIALOG
		call	ObjCallInstanceNoLock
		.leave
		ret
MACallDestroyDialogForPanel endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MALocateEquivalentPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a panel that is displaying an equivalent set of
		messages to what is being sought. Note that if comparing
		by transport, only the transport information will be
		compared, not the medium information. The caller must
		call again with MDPT_BY_MEDIUM to see if there's a panel
		displaying info for the same transport+medium pair.

CALLED BY:	(INTERNAL) MADisplayOutboxPanel,
			   MADisplayInboxPanel
PASS:		*ds:si	= MailboxApplication object
		bx	= offset within MailboxApplicationInstance of
			  MailboxPanelBoxData
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
RETURN:		carry set if found one:
			*ds:ax	= MailboxAppDisplayPanel
		carry clear if no equivalent:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MALocateEquivalentPanel proc	near
		uses	es, si, di, bx, ds, cx, bp, dx
		class	MailboxApplicationClass
		.enter
	;
	; If there are no panels for this box, there can be no equivalent.
	; 
		DerefDI	MailboxApplication
		mov	si, ds:[di+bx].MPBD_panels
		tst_clc	si
		jz	toDone
	;
	; If the criteria being sought is MDPT_ALL, we want to return everything
	; but the system panel.
	; 
		cmp	cx, MDPT_ALL
		jne	checkSys

		cmp	si, ds:[di+bx].MPBD_system
		jne	returnSI		; head panel not the system one,
						;  so return it

		mov	si, ds:[si]		; else point to the next
		mov	si, ds:[si].MADP_next	;  panel
		tst_clc	si
		jnz	returnSI		; => there is a next, so return
						;  it
toDone:
		jmp	done			; else nothing else that's
						;  equivalent

checkSys:
	;
	; To make life simpler, we check the system panel to see if it's set
	; to MDPT_ALL, which we say is equivalent to everything. The system
	; panel is the only thing that can use such criteria, so we check
	; it once here, and then don't have to worry about MDPT_ALL in the loop.
	; 
		mov	si, ds:[di+bx].MPBD_system
		tst	si
		jz	compareOthers
	    ;
	    ; System panel exists -- see if it's MDPT_ALL
	    ; 
		push	si			; might need to return this...
		mov	si, ds:[si]
		cmp	ds:[si].MADP_type, MDPT_ALL
		pop	si
		jne	compareOthers		; not "All", so do normal
						;  comparison

returnSI:
	;
	; Return *ds:ax as an equivalent panel.
	; 
		mov_tr	ax, si
		stc
		jmp	done

compareOthers:
	;
	; Fetch the head of the list.
	; 
		mov	si, ds:[di+bx].MPBD_panels
	;
	; Now lock down the comparison block.
	; 
		mov	bx, dx
		Assert	handle, bx
		call	MemLock
		push	bx
		mov	es, ax

		mov	ax, offset MACompareTokens
		cmp	cx, MDPT_BY_MEDIUM
			CheckHack <MDPT_BY_APP_TOKEN lt MDPT_BY_MEDIUM>
		jl	compareLoop
		mov	ax, offset MACompareMedia
		je	compareLoop

			CheckHack <MDPT_BY_TRANSPORT gt MDPT_BY_MEDIUM>
		push	cx
		movdw	axbx, es:[MDBTD_transport]
		movdw	cxdx, es:[MDBTD_medium]
		call	MediaGetTransportSigAddrBytes
		pop	cx
		mov_tr	bp, ax
		mov	ax, offset MACompareTransAddr
compareLoop:
	;
	; *ds:si	= panel to check
	; ax		= comparison routine
	; cx		= MailboxDisplayPanelType, so we can figure which
	;		  criteria to use when panel is by_transport
	; es:0		= MailboxDisplayPanelCriteria
	; bp		= significant address bytes, if MDPT_BY_TRANSPORT
	;
	; First point to the right part of the chunk for the criteria to compare
	; 
		push	si, cx
		mov	bx, ds:[si]
		lea	si, ds:[bx].MADP_criteria
		cmp	ds:[bx].MADP_type, cx
		je	haveData
		cmp	cx, MDPT_BY_MEDIUM
		jne	afterCompare		; => looking by transport and
						;  this panel is by medium, so
						;  they're not equivalent (yet;
						;  we'll be called back to
						;  check the medium later...)
		add	si, ds:[si].MDPC_byTransport.MDBTD_addrSize
		add	si, offset MDBTD_addr
haveData:
	;
	; Now call the comparison routine to see if they're equivalent.
	; 
		clr	di			; es:di = thing being sought
		call	ax
afterCompare:
		pop	si, cx			; *ds:si <- panel chunk
		je	unlockReturnSI
		
		mov	si, ds:[bx].MADP_next	; *ds:si <- next panel chunk
		tst_clc	si
		jnz	compareLoop
	;
	; Ran out of panels, so nothing equivalent.
	; 
unlockDone:
		pop	bx			; bx <- criteria block
		call	MemUnlock
done:
		.leave
		ret

unlockReturnSI:
		mov_tr	ax, si
		stc
		jmp	unlockDone
MALocateEquivalentPanel endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACompareTokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two GeodeTokens from two sets of panel criteria to
		see if they're equivalent.

CALLED BY:	(INTERNAL) MALocateEquivalentPanel
PASS:		ds:si	= GeodeToken to check
		es:di	= GeodeToken being sought
RETURN:		flags set so je takes if equivalent
DESTROYED:	si, di, cx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		For tokens, equivalent means equal.
		
		There is the possibility of the server for a generic token
		being found while a panel for each of the generic and
		specific tokens is up, where we'd need to bring one of them
		down and rebuild the list for the other, but we don't worry
		about that for now...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MACompareTokens	proc	near
		.enter
			CheckHack <(size GeodeToken and 1) eq 0>
		mov	cx, size GeodeToken/2
		repe	cmpsw
		.leave
		ret
MACompareTokens	endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACompareMedia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two MailboxDisplayByMediumData structures from two
		sets of panel criteria to see if they're equivalent.

CALLED BY:	(INTERNAL) MALocateEquivalentPanel
PASS:		ds:si	= MailboxDisplayByMediumData to check
		es:di	= MailboxDisplayByMediumData being sought
RETURN:		flags set so je takes if equivalent
DESTROYED:	si, di, cx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Two criteria are equivalent if they are the same transport &
		medium and the same unit of that medium, or if they are the
		same transport & medium, and one (or both) of the criteria isn't
		particular about the unit (i.e. it's MUT_ANY)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MACompareMedia	proc	near
		.enter
	;
	; If medium + transport don't match, they ain't equivalent.
	; 
		push	si, di
	;
	; Make sure that the transport and medium are adjacent, so we
	; can check in one sweep.
	;
			CheckHack <MDBMD_transport eq 0>
			CheckHack <MDBMD_medium.MMD_medium eq 6>
			CheckHack <MDBMD_medium.MMD_unitSize eq 10>
		mov	cx, (offset MDBMD_medium.MMD_unitSize)/2
		repe	cmpsw
		pop	si, di
		jne	done
	;
	; If panel displaying any unit, we found us something.
	; 
		mov	cl, ds:[si].MDBMD_medium.MMD_unitType
		cmp	cl, MUT_ANY
		je	done
	;
	; If any unit being sought, we found us something
	; 
		cmp	es:[di].MDBMD_medium.MMD_unitType, MUT_ANY
		je	done

EC <		cmp	cl, es:[di].MDBMD_medium.MMD_unitType		>
EC <		ERROR_NE INCONSISTENT_UNIT_TYPES_FOR_MEDIUM		>
	;
	; If medium doesn't have units, we found us something (nothing else
	; to compare...).
	; 
   		cmp	cl, MUT_NONE
		je	done
	;
	; Else, compare the unit data between the two criteria.
	; 
   		mov	cx, ds:[si].MDBMD_medium.MMD_unitSize
EC <		cmp	cx, es:[di].MDBMD_medium.MMD_unitSize		>
EC <		ERROR_NE INCONSISTENT_UNIT_SIZES_FOR_MEDIUM		>

		add	si, offset MDBMD_medium.MMD_unit
		add	di, offset MDBMD_medium.MMD_unit
		repe	cmpsb
done:
		.leave
		ret
MACompareMedia	endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACompareTransAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two MailboxDisplayByTransportData structures from two
		sets of panel criteria to see if they're equivalent.

CALLED BY:	(INTERNAL) MALocateEquivalentPanel
PASS:		ds:si	= MailboxDisplayByTransportData to check
		es:di	= MailboxDisplayByTransportData being sought
		bp	= # significant address bytes in address pointed to
			  by es:di
RETURN:		flags set so je takes if equivalent
DESTROYED:	si, di, cx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Two criteria are equivalent if they are for the same transport
		and medium, and the significant address bytes (or all the
		address bytes, if there are fewer than the # significant in
		one or both addresses) of the two match byte-for-byte.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MACompareTransAddr proc	near
		.enter
	;
	; If medium + transport don't match, they ain't equivalent.
	; 
		push	si, di
			CheckHack <MDBTD_transport eq 0>
			CheckHack <MDBTD_transOption eq 4>
			CheckHack <MDBTD_medium eq 6>
		mov	cx, (size MDBTD_transport+size MDBTD_transOption\
				+size MDBTD_medium)/2
		repe	cmpsw
		pop	si, di
		jne	done
		
		mov	cx, ds:[si].MDBTD_addrSize
		cmp	cx, es:[di].MDBTD_addrSize
		jb	checkSigBytes
		mov	cx, es:[di].MDBTD_addrSize

checkSigBytes:
		cmp	cx, bp
		jb	doCompareTransAddr
		mov	cx, bp

doCompareTransAddr:
		add	si, offset MDBTD_addr
		add	di, offset MDBTD_addr
		repe	cmpsb
done:
		.leave
		ret
MACompareTransAddr endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACreateNewPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We've decided we need to create a new panel, so do it.

CALLED BY:	(INTERNAL) MADisplayOutboxPanel
PASS:		*ds:si	= MailboxApplication
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for 
				  MDPT_BY_MEDIUM
		di	= MCP_IS_SPECIFIC or MCP_IS_SYSTEM
		bx	= offset within MailboxApplicationInstance of
			  MailboxPanelBoxData to mess with
RETURN:		memory block(s) freed
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	MailboxDisplayPanelData allocated and linked in.
		MPBD_system set if MCP_IS_SYSTEM

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MACreateNewPanel proc	near
		class	MailboxApplicationClass
		uses	si, bp
		.enter
	;
	; Create a MailboxAppDisplayPanel chunk from the criteria.
	; 
		call	MACopyCriteria		; *ds:ax <- criteria

	;
	; Link that into the chain for the box, setting MPBD_system to the
	; chunk if this is the system panel for the box.
	; 
		push	cx, dx		; save criteria data

		push	ax		; save chunk for storing root OD

		mov	cx, di		; save spec/system flag

		DerefDI	MailboxApplication
			CheckHack <MCP_IS_SYSTEM eq 0>
		tst	cx
		jne	addToList
	    ;
	    ; Set MPBD_system for the box.
	    ; 
EC <		tst	ds:[di+bx].MPBD_system				>
EC <		ERROR_NZ ALREADY_HAVE_A_SYSTEM_PANEL			>
		mov	ds:[di+bx].MPBD_system, ax

addToList:
		mov	si, ax
		xchg	ds:[di+bx].MPBD_panels, ax
		mov	si, ds:[si]
		mov	ds:[si].MADP_next, ax
	;
	; Duplicate the appropriate resource to get us a control panel.
	; 
		cmp	bx, offset MAI_outPanels
		mov	bx, handle OutboxPanelRoot
		mov	si, offset OutboxPanelRoot
		je	haveRoot
		mov	bx, handle InboxPanelRoot
		mov	si, offset InboxPanelRoot
haveRoot:
		call	UtilCreateDialogFixupDS
		mov	dx, bx			; dx <- dup block
	;
	; Store the optr of the panel in the MailboxAppDisplayPanel (do this
	; now so we can safely call MA_DESTROY_DIALOG at the end, if necessary,
	; and have things cleaned up).
	; 
		pop	bx			; *ds:bx <- MADP
		mov	bx, ds:[bx]
		movdw	ds:[bx].MADP_panel, dxsi
		mov	bx, dx			; ^lbx:si <- new panel
		
		call	ObjSwapLock
		Assert	objectPtr, dssi, MessageControlPanelClass
	;
	; Let the panel know if it's for something specific or it's the system
	; panel.
	; 
		push	cx, bp
		mov	ax, MSG_MCP_SET_SPECIFIC
		call	ObjCallInstanceNoLock
		pop	ax, bp
	;
	; Let the panel know what it's supposed to be displaying.
	; XXX: Is this necessary for a system panel, which will change the
	; criteria once the transport/app list selects its first entry?
	; 
		pop	cx, dx		; cx, dx <- criteria data
		push	ax
		mov	ax, MSG_MCP_SET_CRITERIA
		call	ObjCallInstanceNoLock
		pop	cx
		jc	nukeIfNotSystem
	;
	; Bring the panel up on-screen.
	; 
bringUp:
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjCallInstanceNoLock
		call	ObjSwapUnlock
done:
		.leave
		ret

nukeIfNotSystem:
			CheckHack <MCP_IS_SYSTEM eq 0>
		jcxz	bringUp
	;
	; It's for something specific, but it's not actually displaying
	; anything, so there's no point in bringing it up on screen, or even
	; in it existing. Tell ourselves to destroy the thing.
	; 
		call	ObjSwapUnlock
		mov	dx, si
		mov	cx, bx			; ^lcx:dx <- dialog
		mov	si, offset MailboxApp	; *ds:si <- app object
		mov	ax, MSG_MA_DESTROY_DIALOG
		call	ObjCallInstanceNoLock
		jmp	done
MACreateNewPanel endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACopyCriteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the MailboxDisplayPanelCriteria and MailboxDisplayPanelType
		into a chunk in this block.

CALLED BY:	(INTERNAL) MACreateNewPanel
PASS:		*ds:si	= MessageControlPanel object
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for MDPT_BY_MEDIUM
RETURN:		*ds:ax	= MailboxAppDisplayPanel
DESTROYED:	nothing
SIDE EFFECTS:	block & chunks may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MACopyCriteria	proc	near
		uses	cx, es, bx, si, di, dx
		.enter
EC <		cmp	cx, MDPT_ALL				>
EC <		jnz	checkPrimary				>
EC <		Assert	e, dx, 0				>
EC <		jmp	critOK					>
EC <checkPrimary:						>
EC <		Assert	handle, dx				>
EC <		cmp	cx, MDPT_BY_TRANSPORT			>
EC <		jne	critOK					>
EC <		Assert	handle, bp				>
EC <critOK:							>

		mov	bx, dx

	;
	; Find the number of bytes in the criteria, all of which we need
	; to copy in.
	; 
		call	getSize
		cmp	cx, MDPT_BY_TRANSPORT
		jne	haveSize
	;
	; Add in the number of bytes from the secondary (by-medium) criteria
	; 
		push	dx, cx, bx
		mov_tr	dx, ax			; dx <- primary # bytes
		mov	bx, bp			; bx <- handle of secondary
		Assert	handle, bx
		mov	cx, MDPT_BY_MEDIUM
		call	getSize
		add	ax, dx			; ax <- combined # bytes
		pop	dx, cx, bx

haveSize:
		add	ax, size MailboxAppDisplayPanel
		push	cx
		mov_tr	cx, ax
		clr	al
		call	LMemAlloc		; *ds:ax <- chunk
	;
	; Lock down the criteria block and set up registers for the big
	; move-o-rama.
	; 
		pop	cx			; cx <- display type
		push	cx

		mov_tr	si, ax
		segmov	es, ds
		mov	di, ds:[si]
	;
	; Initialize the fixed-size part of the chunk.
	; 
		mov	ds:[di].MADP_type, cx
		clr	ax
		mov	ds:[di].MADP_next, ax
		movdw	ds:[di].MADP_panel, axax
	;
	; Copy in the primary criteria.
	; 
		add	di, offset MADP_criteria ; es:di <- destination
		call	copyIt
		pop	cx
	;
	; If by-transport, copy in the by-medium data, too.
	; 
		cmp	cx, MDPT_BY_TRANSPORT
		jne	done
		
		mov	cx, MDPT_BY_MEDIUM
		mov	bx, bp
		call	copyIt
done:
		mov_tr	ax, si
		segmov	ds, es			; *ds:ax <- MADP		
		.leave
		ret

	;--------------------
	; Copy exactly the amount of data from the criteria into the chunk.
	;
	; Pass:	cx	= MailboxDisplayPanelType
	;	^hbx	= MailboxDisplayPanelCriteria
	;	es:di	= destination for the copy
	; Return:	es:di	= after copied data
	; Destroyed:	ax, ds, cx
	; 
copyIt:
		call	getSize			; ax <- # bytes to copy
		mov_tr	cx, ax			;  but we need that in cx
		jcxz	copyDone		; => nothing to lock down

		call	MemLock
		mov	ds, ax
		push	si
		clr	si			; ds:si <- source
		rep	movsb
		call	MemUnlock
		pop	si
copyDone:
		retn

	;--------------------
	; Figure the exact number of bytes that make up the criteria.
	;
	; Pass:	cx	= MailboxDisplayPanelType
	;	^hbx	= MailboxDisplayPanelCriteria
	; Return:	ax	= exact # bytes
	; Destroyed:	nothing
	; 
getSize:
		mov	ax, size MailboxDisplayByAppData
		cmp	cx, MDPT_BY_APP_TOKEN
		je	getSizeDone
		clr	ax
		cmp	cx, MDPT_ALL
		je	getSizeDone
		
		push	ds
		call	MemLock
		mov	ds, ax
		mov	ax, size MailboxDisplayByTransportData
		cmp	cx, MDPT_BY_TRANSPORT
		je	addVarSize
		mov	ax, size MailboxDisplayByMediumData
addVarSize:
			CheckHack <MDBTD_addrSize eq MDBMD_medium.MMD_unitSize>
		add	ax, ds:[MDBTD_addrSize]
		call	MemUnlock
		pop	ds

getSizeDone:
		retn
MACopyCriteria	endp
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAOutboxSysPanelCriteriaChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record new criteria and take down any specific panel
		displaying the same info.

CALLED BY:	MSG_MA_OUTBOX_SYS_PANEL_CRITERIA_CHANGED
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for MDPT_BY_MEDIUM
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	see above

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MAOutboxSysPanelCriteriaChanged method dynamic MailboxApplicationClass, 
				MSG_MA_OUTBOX_SYS_PANEL_CRITERIA_CHANGED
		mov	bx, offset MAI_outPanels
		FALL_THRU_ECN	MASysPanelCriteriaChanged
MAOutboxSysPanelCriteriaChanged endm
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MASysPanelCriteriaChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close any specific panels for the box that are displaying
		the same or a subset of the messages selected by the passed
		criteria, then record the criteria as the new criteria for
		the system panel for the box

CALLED BY:	(INTERNAL) MAOutboxSysPanelCriteriaChanged
PASS:		*ds:si	= MailboxApplication
		ds:di	= MailboxApplicationInstance
		bx	= offset to MailboxPanelBoxData
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for MDPT_BY_MEDIUM
RETURN:		criteria memory block(s) freed
DESTROYED:	ax, bx, cx, dx, si, di, bp
SIDE EFFECTS:	block & chunks may move. system panel data moved to the front
     			of the list. MPBD_system will change

PSEUDO CODE/STRATEGY:
		Unlink the system panel from the list of panels for the box,
			so we don't find it as an equivalent and nuke it
		Find all panels deemed equivalent (i.e. showing an improper
		     	subset of the messages shown by the new criteria) and
			destroy them
		Create a new MailboxAppDisplayPanel for the new criteria (easier
			than shoving in the new data)
		Copy the optr of the panel from the old record to the new
		Link the new panel data at the head of the list, setting
			MPBD_system to the new chunk
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MASysPanelCriteriaChanged proc	ecnear
		class	MailboxApplicationClass
		.enter
	;
	; Find the system panel and the prev pointer to it.
	; 
		push	bx
		mov	ax, ds:[di+bx].MPBD_system
		Assert	chunk, ax, ds
		lea	bx, ds:[di+bx].MPBD_panels-offset MADP_next
findSysLoop:
		cmp	ds:[bx].MADP_next, ax
		je	foundSys
		mov	bx, ds:[bx].MADP_next
		Assert	chunk, bx, ds		; if fail, panel list corrupted
		mov	bx, ds:[bx]
		jmp	findSysLoop

foundSys:
	;
	; Unlink the system panel data from the list.
	; 
		push	ax
		mov_tr	di, ax
		mov	di, ds:[di]
		mov	ax, ds:[di].MADP_next
		mov	ds:[bx].MADP_next, ax
		pop	ax		; ax <- system panel chunk
		pop	bx		; bx <- MPBD offset

		push	bx		; save both for setting the new
		push	ax		;  criteria
	;
	; Bring down anything showing anything like this.
	;
		mov	di, MCP_IS_SYSTEM
		call	MANukeEquivalents

	;
	; Ok. We've biffed anything that was displaying what we want to display.
	; Now create a new MailboxAppDisplayPanel chunk from the criteria
	;
		call	MACopyCriteria	; *ds:ax <- new
	;
	; Free up the blocks that made up the criteria, now we've got their
	; contents.
	; 
		cmp	cx, MDPT_ALL
		je	copyOD		; => no block
		mov	bx, dx		; bx <- primary criteria
		call	MemFree
		cmp	cx, MDPT_BY_TRANSPORT
		jne	copyOD
		mov	bx, bp		; bx <- secondary criteria
		call	MemFree
copyOD:
	;
	; Copy the panel's optr from the old to the new criteria.
	; 
		pop	bx		; *ds:bx <- old panel data
		mov	di, ds:[bx]
		movdw	cxdx, ds:[di].MADP_panel
	    ;
	    ; Nuke the old data, now we've got the optr.
	    ; 
		xchg	ax, bx		; *ds:ax <- old panel,
					;  *ds:bx <- new panel
		call	LMemFree
	    ;
	    ; Stuff the optr into the new...
	    ; 
		mov	di, ds:[bx]
		movdw	ds:[di].MADP_panel, cxdx
	;
	; Link the new panel data at the head of the list for the box, setting
	; the MPBD_system field at the same time.
	; 
		mov_tr	ax, bx
		pop	bx		; bx <- MPBD offset
		mov	si, ds:[si]
		add	si, ds:[si].MailboxApplication_offset
		mov	ds:[si+bx].MPBD_system, ax
		xchg	ds:[si+bx].MPBD_panels, ax
		mov	ds:[di].MADP_next, ax
		.leave
		ret
MASysPanelCriteriaChanged endp
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAOutboxNotifyTransWinOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a start-of-transmission-window notificaiton dialog.

CALLED BY:	MSG_MA_OUTBOX_NOTIFY_TRANS_WIN_OPEN
PASS:		cxdx	= MailboxMessage (1 reference already added)
		bp	= TalID
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	Any other confirm boxes showing this message will be dismissed.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAOutboxNotifyTransWinOpen	method dynamic MailboxApplicationClass, 
					MSG_MA_OUTBOX_NOTIFY_TRANS_WIN_OPEN

	mov	ax, MSG_MSND_SEND_MESSAGE_LATER
	push	ax
	push	si
	push	si			; push non-zero, send msg if
					;  MMF_SEND_WITHOUT_QUERY set

if	not _OUTBOX_SEND_WITHOUT_QUERY
	mov	bx, handle OutWinOpenRoot
	mov	si, offset OutWinOpenRoot
	mov	ax, MSG_MSND_SET_MESSAGE
endif	; not _OUTBOX_SEND_WITHOUT_QUERY
	call	MAInboxOutboxConfirmationCommon

	ret
MAOutboxNotifyTransWinOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAOutboxNotifyTransWinClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a end-of-transmission-window notification dialog.

CALLED BY:	MSG_MA_OUTBOX_NOTIFY_TRANS_WIN_CLOSE
PASS:		cxdx	= MailboxMessage (1 reference already added)
		bp	= TalID
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	Any other confirm boxes showing this message will be dismissed.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAOutboxNotifyTransWinClose	method dynamic MailboxApplicationClass, 
					MSG_MA_OUTBOX_NOTIFY_TRANS_WIN_CLOSE

	clr	ax			; don't add it to confirmBoxes array
	push	ax
	push	si
	push	si			; push non-zero, send msg if
					;  MMF_SEND_WITHOUT_QUERY set

if	not _OUTBOX_SEND_WITHOUT_QUERY
	mov	bx, handle OutWinCloseRoot
	mov	si, offset OutWinCloseRoot
	mov	ax, MSG_MSND_SET_MESSAGE
endif	; not _OUTBOX_SEND_WITHOUT_QUERY
	call	MAInboxOutboxConfirmationCommon

	ret
MAOutboxNotifyTransWinClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAOutboxNotifyErrorRetry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up a permenant error notification dialog.

CALLED BY:	MSG_MA_OUTBOX_NOTIFY_ERROR_RETRY
PASS:		ss:bp	= OERSetMessageArgs
		dx	= size OERSetMessageArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_QUERY_DELETE_AFTER_PERMANENT_ERROR
MAOutboxNotifyErrorRetry	method dynamic MailboxApplicationClass, 
					MSG_MA_OUTBOX_NOTIFY_ERROR_RETRY

	;
	; Instantiate dialog.
	;
	mov	bx, handle OutErrorRetryRoot
	mov	si, offset OutErrorRetryRoot
	call	UserCreateDialog	; ^lbx:si = instantiated dialog

	;
	; Set the message to display.
	;
	mov	ax, MSG_OER_SET_MESSAGE
	mov	di, mask MF_STACK
	call	ObjMessage		; di = 0

	;
	; Finally, put the dialog on screen.
	;
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GOTO	ObjMessage

MAOutboxNotifyErrorRetry	endm
endif	; _QUERY_DELETE_AFTER_PERMANENT_ERROR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADisplaySystemInboxPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the system inbox panel up on screen.

CALLED BY:	MSG_MA_DISPLAY_SYSTEM_INBOX_PANEL
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		If system panel not already extant:
			Call the Inbox to get the criteria for the most-recent 
			message.
		
			Destroy any equivalent panels (including improper 
			subsets)
		
			Call MACreateNewPanel(MCP_IS_SYSTEM)
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
.warn	-private

if	MAILBOX_PERSISTENT_PROGRESS_BOXES

maInboxPanelData	UISystemPanelData <
	InboxGetDefaultSystemCriteria,
	MAI_inPanels,
	MPBT_INBOX
>

else

maInboxPanelData	UISystemPanelData <
	InboxGetDefaultSystemCriteria,
	MAI_inPanels
>

endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

.warn	@private

MADisplaySystemInboxPanel method dynamic MailboxApplicationClass, 
				MSG_MA_DISPLAY_SYSTEM_INBOX_PANEL
		mov	bx, offset maInboxPanelData
		GOTO_ECN	MADisplaySystemPanelCommon
MADisplaySystemInboxPanel endm
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADisplayInboxPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure there's a modified control panel on-screen to display
		the messages selected by the indicated criteria.

CALLED BY:	MSG_MA_DISPLAY_INBOX_PANEL
PASS:		*ds:si	= MailboxApplicationClass object
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
RETURN:		memory block(s) freed
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	7/ 7/94   	Initial version
	ardeb	9/16/94		Rewrote to be like DISPLAY_OUTBOX_PANEL

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MADisplayInboxPanel	method dynamic MailboxApplicationClass, 
					MSG_MA_DISPLAY_INBOX_PANEL
		mov	bx, offset MAI_inPanels
		GOTO_ECN	MADisplayPanelCommon
MADisplayInboxPanel	endm

elif	_SIMPLE_MESSAGE_NOTIFY

MADisplayInboxPanel	method dynamic MailboxApplicationClass, 
					MSG_MA_DISPLAY_INBOX_PANEL

	Assert	e, cx, MDPT_BY_APP_TOKEN

	;
	; Instantiate notify dialog block.
	;
	mov	bx, handle SimpleMessageNotifyRoot
	mov	si, offset SimpleMessageNotifyRoot
	call	UserCreateDialog	; ^lbx:si = new dialog
	push	bx			; save dialog hptr
	push	si			; save offset of dialog
	call	ObjLockObjBlock		; ax = dialog block
	push	ax			; save dialog sptr

	;
	; Get name of application into the dialog block.
	;
	mov	bx, dx			; ^hbx = MailboxDisplayPanelCriteria
	call	MemLock
	mov	ds, ax
	push	{word} ds:[MDPC_byApp].MDBAD_token.GT_chars[0]
	mov	cx, {word} ds:[MDPC_byApp].MDBAD_token.GT_chars[2]
	mov	dx, {word} ds:[MDPC_byApp].MDBAD_token.GT_manufID
	call	MemUnlock
	pop	bx			; bxcxdx = GeodeToken
	pop	ds			; ds = dialog sptr
	call	InboxGetAppName		; *ds:ax = app name

	;
	; Stuff the name into the notification string
	;
	mov	si, offset SimpleMessageNotifyGlyph
	call	UtilMangleMoniker
	call	LMemFree		; free the app name string

	;
	; Put the dialog on screen.
	;
	pop	si			; *ds:si = SimpleMessageNotifyRoot
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjCallInstanceNoLock

	;
	; Unlock the dialog block.
	;
	pop	bx			; bx = dialog hptr
	GOTO	MemUnlock

MADisplayInboxPanel	endm

endif	; _SIMPLE_MESSAGE_NOTIFY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAInboxSysPanelCriteriaChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_MA_INBOX_SYS_PANEL_CRITERIA_CHANGED
PASS:		*ds:si	= MailboxApplicationClass object
		ds:di	= MailboxApplicationClass instance data
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
RETURN:		memory block(s) freed
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MAInboxSysPanelCriteriaChanged	method dynamic MailboxApplicationClass, 
					MSG_MA_INBOX_SYS_PANEL_CRITERIA_CHANGED

	mov	bx, offset MAI_inPanels
	GOTO_ECN	MASysPanelCriteriaChanged
MAInboxSysPanelCriteriaChanged	endm
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAInboxNotifyTransWinClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a deadline notification dialog.

CALLED BY:	MSG_MA_INBOX_NOTIFY_TRANS_WIN_CLOSE
PASS:		cxdx	= MailboxMessage (1 ref already added)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	Any other confirm boxes showing this message will be dismissed.
		(But there shouldn't be any.)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAInboxNotifyTransWinClose	method dynamic MailboxApplicationClass, 
					MSG_MA_INBOX_NOTIFY_TRANS_WIN_CLOSE

	clr	ax			; don't add it to confirmBoxes array
	push	ax
	push	si
	push	ax			; push zero, always put up dialog

	mov	bx, handle InWinCloseRoot
	mov	si, offset InWinCloseRoot
	mov	ax, MSG_MSND_SET_MESSAGE
	call	MAInboxOutboxConfirmationCommon

	ret
MAInboxNotifyTransWinClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MARegisterFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a callback routine for file-change notification

CALLED BY:	MSG_MA_REGISTER_FILE_CHANGE
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		cx:dx	= vfptr of routine to call:
			  Pass:
				ax	= callback data
				dx	= FileChangeNotificationType (never
					  FCNT_BATCH)
				es:di	= FileChangeNotificationData
			  Return:
			  	nothing
		bp	= callback data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	app object registers with GCNSLT_FILE_SYSTEM list if not
     			already

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MARegisterFileChange method dynamic MailboxApplicationClass, 
				MSG_MA_REGISTER_FILE_CHANGE
		.enter

		Assert	vfptr, cxdx

		tst	ds:[di].MAI_fileChangeCallbacks
		jnz	append

	;
	; First callback registered, so we have to create the array and register
	; for notifications.
	; 
		
		push	cx, dx

		push	si
		clr	ax, cx, si	; ax <- no special ObjChunkFlags
					; cx <- default header
					; si <- alloc chunk
		mov	bx, size MAFileChangeCallback
		call	ChunkArrayCreate
		mov_tr	ax, si
		pop	si
	;
	; Store the chunk in our instance data.
	; 
		DerefDI	MailboxApplication
		mov	ds:[di].MAI_fileChangeCallbacks, ax
	;
	; Register with the system.
	; 
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_FILE_SYSTEM
		call	GCNListAdd

		pop	cx, dx

append:
	;
	; Append an entry to the array.
	; 
		mov	si, ds:[di].MAI_fileChangeCallbacks
		call	ChunkArrayAppend
	;
	; Stuff in the parameters.
	; 
		movdw	ds:[di].MAFCC_callback, cxdx
		mov	ds:[di].MAFCC_data, bp
		
		.leave
		ret
MARegisterFileChange endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cope with non-mailbox objects on our GCN lists by upping the
		detach count once for each such object on any such GCN list

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		cx	= ack ID
		dx:bp	= ack OD
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMetaDetach	method dynamic MailboxApplicationClass, MSG_META_DETACH
		uses	ax, cx, dx, bp, si, es
		.enter
		call	ObjInitDetach
	;
	; Up the count by one if there are any client threads left. Note
	; that we've done so, so if there's a MSG_MA_HAVE_CLIENTS_AGAIN in
	; the queue, we don't do the increment there.
	;
		segmov	es, dgroup, ax
		tst	es:[mainClientThreads]
		jz	offShutdownList
		call	ObjIncDetach
		mov	ax, TEMP_MA_CLIENTS_REMAINING		
		clr	cx
		call	ObjVarAddData

offShutdownList:
	;
	; Remove ourselves from the shutdown-control list now we're going away.
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_SHUTDOWN_CONTROL
		call	GCNListRemove
	;
	; Count up the objects on our GCN lists from other geodes and adjust
	; our detach count accordingly.
	;
		mov	ax, offset MAMetaDetachCallback
		call	MAEnumGCNObjects

		mov	cx, si		; pass app chunk in CX for ObjIncDetach

if	MAILBOX_PERSISTENT_PROGRESS_BOXES
	;
	; Tell any active transmit threads to go away. They will each send us
	; MSG_META_ACK when they go.
	;
		mov	bx, offset MADetachThreadsCallback
		mov	bp, MPBT_OUTBOX
		call	MAEnumProgressBoxes
	;
	; Ditto for any active receipt threads.
	;
		mov	bx, offset MADetachThreadsCallback
		mov	bp, MPBT_INBOX
		call	MAEnumProgressBoxes
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
	;
	; Tell any threads that have no progress box that they should go away.
	;
		segmov	es, ds
		mov	bx, SEGMENT_CS
		mov	di, offset MADetachNoBoxThreadsCallback
		call	MainThreadEnum
		call	MainThreadUnlock
		segmov	ds, es
	;
	; Stop the admin file urgent update timer, if it's going.
	;
		DerefDI	MailboxApplication
		clr	ax
		xchg	ds:[di].MAI_adminFileUpdateUrgentTimerID, ax
		tst	ax
		jz	stopped
		clr	bx
		xchg	bx, ds:[di].MAI_adminFileUpdateUrgentTimerHandle
		call	TimerStop
stopped:
	;
	; Stop the next-event timer, if it's going.
	;
		clr	bx
		xchg	ds:[di].MAI_nextEventTimerHandle, bx
		inc	bx
		jz	done
		dec	bx
		jz	done
		mov	ax, ds:[di].MAI_nextEventTimerID
		call	TimerStop
done:
		.leave
		mov	di, offset MailboxApplicationClass
		call	ObjCallSuperNoLock
		call	ObjEnableDetach
		ret
MAMetaDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADetachNoBoxThreadsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell any running thread that doesn't have a progress box
		that it should go away.

CALLED BY:	(INTERNAL) MAMetaDetach via MainThreadEnum
PASS:		ds:di	= MainThreadData to examine
		*es:cx	= MailboxApplication object
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MADetachNoBoxThreadsCallback proc	far
		.enter
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		tst	ds:[di].MTD_progress.handle
		jnz	done		; => handled by progress box
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

	;
	; Thread has no progress box. Up our detach count, please.
	;
		push	ds, di
		movdw	dssi, escx
		call	ObjIncDetach
		pop	ds, di
	;
	; Now tell the thread to cancel everything.
	;
		push	cx, dx, bp
		mov	ax, MCA_CANCEL_ALL	; ax <- action
		mov	dx, es:[LMBH_handle]
		mov	bp, cx			; ^ldx:bp <- ack OD
		clr	cx			; cx <- ack ID
		call	MainThreadCancel
		pop	cx, dx, bp

done::		; MAILBOX_PERSISTENT_PROGRESS_BOXES
		clc
		.leave
		ret
MADetachNoBoxThreadsCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADetachThreadsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the progress box telling it to detach the
		transmit thread with which it's associated.

CALLED BY:	(INTERNAL) MAMetaDetach via MAEnumProgressBoxes
PASS:		ds:di	= optr of progress box
		*ds:cx	= MailboxApplication object
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, bx, si, di allowed
SIDE EFFECTS:	ObjIncDetach called for app object

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 9/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MADetachThreadsCallback proc	far
		.enter
		mov	si, cx
		call	ObjIncDetach
		movdw	bxsi, ds:[di]
		mov	ax, MSG_MPB_DETACH_THREAD
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		clc
		.leave
		ret
MADetachThreadsCallback endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMetaDetachCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to add a detach count to our app object
		for each object on one of our GCN lists that's not owned
		by us (i.e. for which we must wait for someone else to
		remove the object before we go away)

CALLED BY:	(INTERNAL) MAMetaDetach via MAEnumGCNObjects
PASS:		ds:di	= optr to check
		*ds:bp	= app object
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMetaDetachCallback proc	far
		.enter
	;
	; See if this object is owned by us.
	; 
		mov	bx, ds:[di].handle
		call	MemOwner
		cmp	bx, handle 0
		je	done
	;
	; It isn't, so we must wait until it removes itself from our list before
	; we can go away.
	; 
		mov	si, bp
		call	ObjIncDetach
done:
		clc
		.leave
		ret
MAMetaDetachCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADetaching?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the application is actively detaching

CALLED BY:	(INTERNAL) MAMetaGcnListRemove, MAClientsAllGone,
			   MAHaveClientsAgain
PASS:		*ds:si	= MailboxApplication object
RETURN:		carry set if detaching
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MADetaching?	proc	near
		class	MailboxApplicationClass
		uses	ax, bx
		.enter
		mov	ax, DETACH_DATA
		call	ObjVarFindData
		.leave
		ret
MADetaching?	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAClientsAllGone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're detaching, remove the detach reference added when
		we found that mainClientThreads was non-zero.

CALLED BY:	MSG_MA_CLIENTS_ALL_GONE
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	TEMP_MA_CLIENTS_REMAINING is deleted. Detach count is
		decremented

PSEUDO CODE/STRATEGY:
		We have to handle the case where TEMP_MA_CLIENTS_REMAINING
		doesn't exist, of course, because this message could have
		been in the queue when we received MSG_META_DETACH

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAClientsAllGone method dynamic MailboxApplicationClass, MSG_MA_CLIENTS_ALL_GONE
		.enter
		call	MADetaching?
		jnc	done			; ignore if not detaching

		mov	ax, TEMP_MA_CLIENTS_REMAINING
		call	ObjVarDeleteData
		jc	done			; => didn't think there were
						;  any before
		
		call	ObjEnableDetach
done:
		.leave
		ret
MAClientsAllGone endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAHaveClientsAgain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that we've got client threads and refuse to detach
		until they're gone.

CALLED BY:	MSG_MA_HAVE_CLIENTS_AGAIN
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	TEMP_MA_CLIENTS_REMAINING added
     		detach count incremented

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAHaveClientsAgain method dynamic MailboxApplicationClass, MSG_MA_HAVE_CLIENTS_AGAIN
		.enter
		call	MADetaching?
		jnc	done
		
		mov	ax, TEMP_MA_CLIENTS_REMAINING
		call	ObjVarFindData
		jc	done
	;
	; Didn't already know about the client threads, so note that we know
	; now and up the detach count.
	;
		clr	cx
		call	ObjVarAddData

		call	ObjIncDetach

done:
		.leave
		ret
MAHaveClientsAgain endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMetaDetachComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove ourselves from the GCNSLT_FILE_SYSTEM list if we're
		on it.

CALLED BY:	MSG_META_DETACH_COMPLETE
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	MAI_fileChangeCallbacks is freed and the instvar zeroed

PSEUDO CODE/STRATEGY:
		This gets called at the end of our life as an application.
		Once this is received, any further action as an application
			will be preceded by a GEN_PROCESS_OPEN_APPLICATION,
			which will cause file-change callbacks to be
			reregistered...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMetaDetachComplete method dynamic MailboxApplicationClass, 
				MSG_META_DETACH_COMPLETE
		uses	ax, cx, dx, bp
		.enter
	;
	; Fetch & zero the array chunk. If it was zero, we've nothing special
	; to do...
	; 
		clr	ax
		xchg	ds:[di].MAI_fileChangeCallbacks, ax
		tst	ax
		jz	done
	;
	; Free the array.
	; 
		call	LMemFree
	;
	; Unregister ourselves.
	; 
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_FILE_SYSTEM
		call	GCNListRemove
done:
		.leave
		mov	di, offset MailboxApplicationClass
		GOTO	ObjCallSuperNoLock
MAMetaDetachComplete endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAGcnListRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept to reduce detach count, if present and object
		being removed is actually on the list and owned by someone
		else.

CALLED BY:	MSG_MA_GCN_LIST_REMOVE
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		ss:bp	= MAGCNListParams
RETURN:		carry set if optr found and removed
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAGcnListRemove method dynamic MailboxApplicationClass, 
				MSG_MA_GCN_LIST_REMOVE
		.enter
	;
	; Fetch the owner of the object being removed, while we've got
	; the parameters available.
	; 
		mov	bx, ss:[bp].MAGCNLP_owner
	;
	; Let the superclass do its thang...
	; 
		mov	ax, MSG_META_GCN_LIST_REMOVE
		mov	dx, size GCNListParams
		mov	di, offset MailboxApplicationClass
		call	ObjCallSuperNoLock
		jnc	done		; => not even there, so don't care
	;
	; If we own the object, we need do nothing more.
	; 
		cmp	bx, handle 0
		je	doneFound
	;
	; If we're not detaching, we need do nothing more.
	; 
		call	MADetaching?
		jnc	doneFound
	;
	; Darn. We need do something more -- reduce the detach count by one.
	; 
		call	ObjEnableDetach
doneFound:
		stc			; signal optr was removed
done:
		.leave
		ret
MAGcnListRemove endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MANotifyFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the registered callbacks, coping with FCNT_BATCH
		ourselves...

CALLED BY:	MSG_NOTIFY_FILE_CHANGE
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		dx	= FileChangeNotificationType
		^hbp	= FileChangeNotificationData
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MANotifyFileChange method dynamic MailboxApplicationClass, 
				MSG_NOTIFY_FILE_CHANGE
		uses	ax, dx, bp, si, es
		.enter
		mov	bx, bp
		call	MemLock
		mov	es, ax
		mov	si, ds:[di].MAI_fileChangeCallbacks

		tst	si
		jz	done		; can be 0 if something in the
					;  queue when DETACH_COMPLETE handled

		Assert	chunk, si, ds
		clr	di
		call	MANotifyFileChangeLow
done:
		call	MemUnlock
		.leave
		mov	di, offset MailboxApplicationClass
		GOTO	ObjCallSuperNoLock
MANotifyFileChange endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MANotifyFileChangeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call all the callbacks that have been registered, coping
		with FCNT_BATCH ourselves.

CALLED BY:	(INTERNAL) MANotifyFileChange, self
PASS:		*ds:si	= array of callbacks
		es:di	= FileChangeNotificationData
		dx	= FileChangeNotificationType
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MANotifyFileChangeLow proc near
		uses	bx, dx
		.enter
		cmp	dx, FCNT_BATCH
		je	handleBatch
	;
	; Not a batch, so just call the callbacks.
	; 
		push	di
		mov	bp, di
		mov	bx, cs
		mov	di, offset MANotifyFileChangeCallCallback
		call	ChunkArrayEnum
		pop	di
done:
		.leave
		ret

handleBatch:
	;
	; Fetch the end of the batch and point to the first item.
	; 
		mov	bx, es:[di].FCBND_end
		add	di, offset FCBND_items
		jmp	checkBatchEnd
batchLoop:
	;
	; Fetch the type of notification out and advance to the start of the
	; notification data.
	; 
		mov	dx, es:[di].FCBNI_type
		add	di, offset FCBNI_disk
	;
	; Call the callbacks.
	; 
		call	MANotifyFileChangeLow
	;
	; Advance to the next batch item. We assume the thing has no filename
	; stored with it.
	; 
		add	di, offset FCBNI_name - offset FCBNI_disk
		cmp	dx, FCNT_RENAME
		ja	checkBatchEnd
	;
	; Notification has a filename -- skip it as well.
	; 
			CheckHack <FCNT_CREATE eq 0>
			CheckHack <FCNT_RENAME eq 1>
		add	di, size FileLongName
checkBatchEnd:
		cmp	di, bx		; have we hit the end point?
		jb	batchLoop	; => no
		jmp	done
MANotifyFileChangeLow endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MANotifyFileChangeCallCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a single file-change callback

CALLED BY:	(INTERNAL) MANotifyFileChangeLow via ChunkArrayEnum
PASS:		ds:di	= MAFileChangeCallback to call
		es:bp	= FileChangeNotificationData to pass
		dx	= FileChangeNotificationType
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx, si, di allowed
		dx, ax, cx (if callback nukes it)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MANotifyFileChangeCallCallback proc	far
		uses	es, bp
		.enter
		pushdw	ds:[di].MAFCC_callback
		mov	ax, ds:[di].MAFCC_data
		mov	di, bp
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		clc
		.leave
		ret
MANotifyFileChangeCallCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMetaSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the amusing travel options we support

CALLED BY:	MSG_META_SEND_CLASSED_EVENT
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		^hcx	= classed event
		dx	= TravelOption
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	recorded event is freed, one way or another

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MAMetaSendClassedEvent method dynamic MailboxApplicationClass, 
				MSG_META_SEND_CLASSED_EVENT
		cmp	dx, TO_OUTBOX_TRANSPORT_LIST
		je	outbox
		cmp	dx, TO_SYSTEM_OUTBOX_PANEL
		je	outbox
		cmp	dx, TO_INBOX_APPLICATION_LIST
		je	inbox
		cmp	dx, TO_SYSTEM_INBOX_PANEL
		je	inbox
	;
	; Not something we handle specially.
	; 
		mov	di, offset MailboxApplicationClass
		GOTO	ObjCallSuperNoLock

outbox:
	;
	; Get the outbox control panel data chunk.
	; 
		mov	bx, ds:[di].MAI_outPanels.MPBD_system

sendToPanel:
	;
	; See if there's actually a system panel for the box.
	; 
		tst	bx
		jz	dropIt
	;
	; There is. Send the META_SEND_CLASSED_EVENT to that panel for
	; it to handle.
	; 
		mov	bx, ds:[bx]
		mov	si, ds:[bx].MADP_panel.chunk
		mov	bx, ds:[bx].MADP_panel.handle
		mov	di, mask MF_FIXUP_DS
		GOTO	ObjMessage

inbox:
	;
	; Get the inbox control panel data chunk.
	; 
		mov	bx, ds:[di].MAI_inPanels.MPBD_system
		jmp	sendToPanel

dropIt:
	;
	; No system panel to send this to. Change the destination of the
	; classed event to 0, so it'll be destroyed.
	; 
		mov	bx, cx
		push	si
		clr	cx, si		; ^lcx:si <- null class
		call	MessageSetDestination
		pop	si
		mov	cx, bx		; cx <- event, again
		clr	bx, bp		; no optr to send to -- just biff event
		mov	di, mask MF_FIXUP_DS
		call	FlowDispatchSendOnOrDestroyClassedEvent
		ret
MAMetaSendClassedEvent endm
endif	; _CONTROL_PANELS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MABoxChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the interested parties know there's been a change

CALLED BY:	MSG_MA_BOX_CHANGED
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		cxdx	= MailboxMessage affected
		bp	= MABoxChange
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MABoxChanged	method dynamic MailboxApplicationClass, MSG_MA_BOX_CHANGED
		mov	ax, MSG_MB_NOTIFY_BOX_CHANGE
		mov	bx, MGCNLT_OUTBOX_CHANGE
		test	bp, mask MABC_OUTBOX
		jnz	send
		mov	bx, MGCNLT_INBOX_CHANGE
send:
		FALL_THRU_ECN MASendToGCNList
MABoxChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MASendToGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message out over one of our GCN lists

CALLED BY:	(INTERNAL) MABoxChanged
PASS:		ax	= message to send
		bx	= MailboxGCNListType for list over which to send
		cx, dx, bp = message data
		*ds:si	= MailboxApplication
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MASendToGCNList	proc	ecnear
		.enter
	;
	; Record the message to send.
	; 
		push	bx, si
		clr	bx, si
		mov	di, mask MF_RECORD
		call	ObjMessage
		pop	bx, si
	;
	; Set up the parameters for the send.
	; 
		mov	dx, size GCNListMessageParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].GCNLMP_event, di
		mov	ss:[bp].GCNLMP_flags, 0	; not status, no force-queue
						;  needed
		mov	ss:[bp].GCNLMP_block, 0	; no mem block in params
		mov	ss:[bp].GCNLMP_ID.GCNLT_manuf,
				MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLMP_ID.GCNLT_type, bx
	;
	; Do it, babe.
	; 
		mov	ax, MSG_META_GCN_LIST_SEND
		call	ObjCallInstanceNoLock
		add	sp, size GCNListMessageParams
		.leave
		ret
MASendToGCNList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MARemoveBlockObjectsFromAllGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run through the GCN lists on ourselves and remove any objects
		that are in the passed block.

CALLED BY:	MSG_MA_REMOVE_BLOCK_OBJECTS_FROM_ALL_GCN_LISTS
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		cx	= handle of block containing objects that are to be
			  removed
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MARemoveBlockObjectsFromAllGcnLists method dynamic MailboxApplicationClass, 
			MSG_MA_REMOVE_BLOCK_OBJECTS_FROM_ALL_GCN_LISTS
		uses	bp
		.enter
	;
	; Figure if we need to enable detach for each object removed from
	; each list. We decide this based on:
	;	- We're in the process of detaching
	; 	- The containing block being owned by someone other than us
	;	  (which means the ObjIncDetach will have been done)
	;
		clr	dx		; assume no ObjEnableDetach needed
		call	MADetaching?
		jnc	doEnum

		mov	bx, cx
		call	MemOwner
		cmp	bx, handle 0
		je	doEnum

		dec	dx		; indicate ObjEnableDetach required
					;  for each deletion
doEnum:
		mov	ax, offset MARemoveBlockObjectsCallback
		call	MAEnumGCNObjects
		.leave
		ret
MARemoveBlockObjectsFromAllGcnLists endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAEnumGCNObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate through all the objects in all the GCN lists
		attached to the application object

CALLED BY:	(INTERNAL) MARemoveBlockObjectsFromAllGcnLists,
			   MAMetaDetach
PASS:		*ds:si	= MailboxApplication object
		cs:ax	= callback routine to call:
				Pass:	ds:di	= optr of object
					cx, dx	= callback data
					*ds:bp	= app object
				Return:	carry set to stop enumerating
					carry clear to keep going
				Destroyed:	bx, si, di
		cx, dx	= data for callback
RETURN:		carry set if callback returned carry set
DESTROYED:	bp, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 5/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAEnumGCNObjects proc	near
		uses	si
		.enter
		push	ax
		mov	ax, TEMP_META_GCN
		call	ObjVarFindData
		pop	ax
		jnc	done		; => no GCN lists, so can't be anything
					;  on one...

		mov	bp, si		; *ds:bp <- app obj
		mov	si, ds:[bx].TMGCND_listOfLists
		Assert	ChunkArray, dssi
		mov	bx, cs
		mov	di, offset MAEnumGCNObjectsCallback
		call	ChunkArrayEnum
done:
		.leave
		ret
MAEnumGCNObjects endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAEnumGCNObjectsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to process a list, looking for objects
		in a particular object block to remove

CALLED BY:	(INTERNAL) MAEnumGCNObjects via ChunkArrayEnum
PASS:		ds:di	= GCNListOfListsElement
		cs:ax	= callback to call for each object in the list
		cx, dx	= data to pass to callback
		*ds:bp	= app object
RETURN:		carry set to stop enumerating
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAEnumGCNObjectsCallback proc	far
		.enter
		mov	si, ds:[di].GCNLOLE_list
		mov	bx, cs
		mov	di, ax
		call	ChunkArrayEnum
		.leave
		ret
MAEnumGCNObjectsCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MARemoveBlockObjectsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to check an element of a specific list to see
		if it contains an object within the given block, and to
		delete the element if so.

CALLED BY:	(INTERNAL) MARemoveBlockObjectsFromAllGcnListsCallback via
			   ChunkArrayEnum
PASS:		ds:di	= GCNListElement
		cx	= handle of object block whose objects are to
			  be removed
		dx	= non-zero if ObjEnableDetach needs to be called for
			  each object removed from a list
		*ds:bp	= app object
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MARemoveBlockObjectsCallback proc	far
		.enter
		cmp	ds:[di].GCNLE_item.handle, cx
		jne	done
	;
	; Found one -- just nuke the element. There should be nothing else we
	; have to do.
	; 
		call	ChunkArrayDelete
		call	ObjMarkDirty	; mark chunk dirty, since we changed
					;  it...
		tst	dx
		jz	done
		mov	si, bp
		call	ObjEnableDetach
done:
		clc
		.leave
		ret
MARemoveBlockObjectsCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMetaMupAlterFtvmcExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we get and release the focus for the field, too

CALLED BY:	MSG_META_MUP_ALTER_FTVMC_EXCL
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		^lcx:dx	= object doing the asking
		bp	= MetaAlterFTVMCExclFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	if grabbing, parent field will also grab

PSEUDO CODE/STRATEGY:
		if grab, 
			call the superclass,
			call GRAB_FOCUS_EXCL on ourselves
			call GRAB_FOCUS_EXCL on our parent

		if release,
			call the superclass
			queue ENSURE_ACTIVE_FT (modal not released yet)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMetaMupAlterFtvmcExcl method dynamic MailboxApplicationClass, 
			MSG_META_MUP_ALTER_FTVMC_EXCL
		.enter
		push	bp
		mov	di, offset MailboxApplicationClass
		call	ObjCallSuperNoLock
		pop	bp
		test	bp, mask MAEF_NOT_HERE
		jnz	done			; => doing it for ourselves,
						;  so do nothing else special

		test	bp, mask MAEF_GRAB
		jz	ensureActive
	;
	; When something below us grabs the focus or target, we need to grab
	; it from our field and tell the field to grab it from the system, else
	; our dialog boxes never get the focus or target.
	; 
		ornf	bp, mask MAEF_NOT_HERE
		mov	cx, ds:[LMBH_handle]		; ^lcx:dx <- object 
		mov	dx, si				;  doing the grabbing
		mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
		mov	di, offset MailboxApplicationClass
		push	bp
		call	ObjCallSuperNoLock
		pop	bp

	;
	; We should only grab the focus for our field if there is currently
	; no modal geode under the system object, or if we are the modal
	; geode under the system object.  This fixes the problem where we
	; mistakenly grab the focus from a system modal dialog that appears
	; above one of our system modal dialogs.  The system modal geode is
	; correctly set to the owning geode of the topmost system modal window
	; in MSG_GEN_SYSTEM_NOTIFY_SYS_MODAL_WIN_CHANGE -- brianc 2/10/96
	;
		push	bp
		mov	ax, MSG_GEN_SYSTEM_GET_MODAL_GEODE
		call	UserCallSystem			; ^lcx:dx = modal geode
		pop	bp
		jcxz	getFieldFocus			; no modal geode
		cmp	cx, ds:[LMBH_handle]
		jne	done				; we're not modal geode
		cmp	dx, si
		jne	done				; we're not modal geode

getFieldFocus:


		call	VisFindParent			; ^lbx:si <- field
		movdw	cxdx, bxsi			; ^lcx:dx <- grabby obj
		mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
		mov	di, mask MF_FIXUP_DS		; (bp still has
							;  MAEF_NOT_HERE set)
EC <		test	bp, mask MAEF_NOT_HERE				>
EC <		ERROR_Z	-1						>
EC <		test	bp, not mask MetaAlterFTVMCExclFlags		>
EC <		ERROR_NZ	-1					>
		call	ObjMessage
done:
		.leave
		ret

ensureActive:
	;
	; When releasing, force-queue an ENSURE_ACTIVE_FT to ourselves so if
	; there's nothing focusable under us, we release the thing. We have to
	; force-queue because the modal-window grab hasn't been released at
	; this point, and a direct call here would yield the thing that's
	; releasing the focus being given it right back again.
	; 
		mov	ax, MSG_META_ENSURE_ACTIVE_FT
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	done
MAMetaMupAlterFtvmcExcl endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMetaNotifyNoFocusWithinNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for something we can give the focus to, or release
		our own focus grab if we can't find anything.

CALLED BY:	MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We have nothing to which to give the focus, so release the
		focus, then check with the field to see if it has any focus now.
		if it doesn't, tell it to release the focus and invoke
		ENSURE_ACTIVE_FT on the system object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMetaNotifyNoFocusWithinNode method dynamic MailboxApplicationClass, 
				MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE
		.enter
		mov	di, offset MailboxApplicationClass
		call	ObjCallSuperNoLock
	;
	; See if we found anything to give the focus to.
	; 
		mov	ax, MSG_VIS_FUP_QUERY_FOCUS_EXCL
		call	ObjCallInstanceNoLock
		jcxz	findDialogOnSystem
done:
		.leave
		ret

findDialogOnSystem:
	;
	; Standard code didn't find anything. Look for something of ours
	; below the system object.
	; 
		mov	ax, MSG_VIS_QUERY_WINDOW
		call	ObjCallInstanceNoLock	; cx <- field window (because
						;  of the funky way these things
						;  work...)
					
		jcxz	releaseFocus		; if no window, then we can't
						;  do anything here but must be
						;  shutting down...

		mov	di, cx
		push	si
		mov	si, WIT_PARENT_WIN
		call	WinGetInfo		; ax <- system
		mov_tr	di, ax

		mov	bx, SEGMENT_CS
		mov	si, offset MAMetaNotifyNoFocusWithinNodeCallback
		clr	cx, dx			; cx <- no window found
						; dx <- is_parent_win flag
		call	WinForEach
		pop	si
		jcxz	releaseFocus
	;
	; Ask our superclass to do it so we don't grab the focus away just
	; because one of our dialogs has gone down...
	; 
		mov	bp, mask MAEF_FOCUS or mask MAEF_GRAB
		mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
		mov	di, offset MailboxApplicationClass
		call	ObjCallSuperNoLock
		jmp	done

releaseFocus:
	;
	; Find the field on which we sit.
	; 
		mov	cx, ds:[LMBH_handle]	; ^lcx:dx <- us, for releasing
		mov	dx, si			;  within the field
		call	VisFindParent
	;
	; Find who runs the thing.
	; 
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
	;
	; Tell that thread to run our MAFutzWithFieldFocus routine to do this
	; all synchronously.
	; 
			CheckHack <PCRP_dataDI eq ProcessCallRoutineParams-2>
			CheckHack <PCRP_dataSI eq ProcessCallRoutineParams-4>
			CheckHack <PCRP_dataDX eq ProcessCallRoutineParams-6>
			CheckHack <PCRP_dataCX eq ProcessCallRoutineParams-8>
			CheckHack <PCRP_dataBX eq ProcessCallRoutineParams-10>
			CheckHack <PCRP_dataAX eq ProcessCallRoutineParams-12>
		push	di, si, dx, cx, bx, ax
			CheckHack <PCRP_address eq ProcessCallRoutineParams-16>
		mov	ax, vseg MAFutzWithFieldFocus
		push	ax
		mov	ax, offset MAFutzWithFieldFocus
		push	ax
			CheckHack <ProcessCallRoutineParams eq 16>
		mov	bp, sp
		mov	dx, size ProcessCallRoutineParams
		mov	bx, ss:[bp].PCRP_dataAX		; bx <- burden thread
		mov	ax, MSG_PROCESS_CALL_ROUTINE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
		call	ObjMessage
		add	sp, size ProcessCallRoutineParams
		.leave
		ret
MAMetaNotifyNoFocusWithinNode endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMetaNotifyNoFocusWithinNodeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to find a window below the system object
		that belongs to us, so we can give it the focus

CALLED BY:	(INTERNAL) MAMetaNotifyNoFocusWithinNode via WinForEach
PASS:		di	= window to examine
		dx	= 0 if di is system window
RETURN:		carry clear to keep processing:
			di	= next window to examine
			dx	= non-z
		carry set if found something
			^lcx:dx	= window's input object
DESTROYED:	ax, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMetaNotifyNoFocusWithinNodeCallback proc	far
		.enter
		tst	dx
		jz	isParent

		mov	bx, di
		call	MemOwner
		cmp	bx, handle 0
		jne	nextSib
	;
	; Found one of ours, so return its input object to be given the focus.
	; 
		mov	si, WIT_INPUT_OBJ
		call	WinGetInfo
		stc
done:
		.leave
		ret
nextSib:
	;
	; Window isn't one of ours, so move to the next sibling.
	; 
		mov	si, WIT_NEXT_SIBLING_WIN
		jmp	getInfoAndContinue

isParent:
	;
	; Still at the system level -- get to the first child now we've got
	; the tree semaphore grabbed and the tree can't be changing.
	; 
		dec	dx			; dx <- non-z (1-byte inst)
		mov	si, WIT_FIRST_CHILD_WIN

getInfoAndContinue:
		call	WinGetInfo		; ax <- window to process next
		mov_tr	di, ax			; no, make that DI
		clc				; CF <- keep going, please
		jmp	done
MAMetaNotifyNoFocusWithinNodeCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAFutzWithFieldFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Amusing little routine to synchronously release our focus
		and make sure the field has something it can do, and release
		its focus if not. This thing runs in the thread that runs
		the field, so we can be sure we're not messing with anything
		anyone else is doing when we do this.

CALLED BY:	(INTERNAL) MAMetaNotifyNoFocusWithinNode via 
			   Process::PROCESS_CALL_ROUTINE
PASS:		^lbx:si	= field to futz with
		^lcx:dx	= our application object
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAFutzWithFieldFocus proc	far
		.enter
	;
	; Tell the field to release the focus for our object.
	; 
		mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
		mov	bp, mask MAEF_FOCUS or mask MAEF_OD_IS_WINDOW
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Tell the field to make sure there's a focus node.
	; 
		mov	ax, MSG_META_ENSURE_ACTIVE_FT
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Now see if it was able to find anything.
	; 
		mov	ax, MSG_META_GET_FOCUS_EXCL
		mov	di, mask MF_CALL
		call	ObjMessage
		jcxz	tellFieldToRelease	; => didn't
	;
	; It found something, so do nothing further.
	; 
done:
		.leave
		ret

tellFieldToRelease:
	;
	; The field has no focus in it, so tell it to release the focus
	; (this doesn't seem to be the default behaviour, at least if the
	; field has a notification OD, which the system one has [though I
	; don't know why, since the UI doesn't respond to any of the
	; notifications the field sends out...])
	; 
		mov	ax, MSG_META_RELEASE_FOCUS_EXCL
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Now tell the system to make sure it's got a focus node.
	; 
		mov	ax, MSG_META_ENSURE_ACTIVE_FT
		call	UserCallSystem
		jmp	done
MAFutzWithFieldFocus endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMetaNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cheat by passing all geoworks notifications to the generic
		UI's process to handle, as it knows better what to do about
		having the focus when one isn't on the default field.

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		cx	= ManufacturerID
		dx	= NotificationType
		bp	= data
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/15/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMetaNotify	method dynamic MailboxApplicationClass, MSG_META_NOTIFY,
					MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	bx, handle ui
		call	GeodeGetAppObject
		clr	di
		GOTO	ObjMessage
MAMetaNotify	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAStartInboxCheckTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up a one-shot timer that calls itself to check whether
		there is any new unseen first-class messages added to the
		inbox during this period.

CALLED BY:	MSG_MA_SETUP_INBOX_CHECK_TIMER
PASS:		*ds:si	= MailboxApplicationClass object
		ds:di	= MailboxApplicationClass instance data
		ax	= message #
		cx	= # of timer ticks, or 0 to use current value
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAStartInboxCheckTimer	method dynamic MailboxApplicationClass, 
					MSG_MA_START_INBOX_CHECK_TIMER

	call	TimerGetFileDateTime	; ax = FileDate, dx = FileTime
	movdw	ds:[di].MAI_lastCheckTime, dxax
	add	di, offset MAI_inboxCheckPeriod
	mov	ax, MSG_MA_CHECK_INBOX
	FALL_THRU	MAStartTimerCommon

MAStartInboxCheckTimer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAStartTimerCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to start a one-shot timer.

CALLED BY:	(INTERNAL) MAStartInboxCheckTimer, MAStartAdminFileUpdateTimer
PASS:		*ds:si	= MailboxApplicationClass object
		ds:di	= either MAI_inboxCheckPeriod or
			  MAI_adminFileUpdatePeriod
		cx	= # of timer ticks, or 0 to use current value
		ax	= message to send when timer expires
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAStartTimerCommon	proc	far
	class	MailboxApplicationClass

	CheckHack <MAI_inboxCheckPeriod + size word eq MAI_inboxTimerHandle>
	CheckHack <MAI_inboxCheckPeriod + 2 * size word eq MAI_inboxTimerID>
	CheckHack <MAI_adminFileUpdatePeriod + size word eq \
						MAI_adminFileUpdateTimerHandle>
	CheckHack <MAI_adminFileUpdatePeriod + 2 * size word eq \
						MAI_adminFileUpdateTimerID>

	jcxz	useCurrentPeriod
	mov	ds:[di], cx		; store new period in MAI_xxxPeriod

hasTicks:
	;
	; Start a timer.
	;
	mov_tr	dx, ax			; dx = timer message
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[OLMBH_header].LMBH_handle	; ^lbx:si = self
	call	TimerStart
	mov	ds:[di + size word], bx	; store in MAI_xxxTimerHandle
	mov	ds:[di + 2 * size word], ax	; store in MAI_xxxTimerID

	ret

useCurrentPeriod:
	mov	cx, ds:[di]		; get current period from MAI_xxxPeriod
	jmp	hasTicks

MAStartTimerCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MACheckInbox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS	Inform user if there are new first-class messages

CALLED BY:	MSG_MA_CHECK_INBOX
PASS:		ds:di	= MailboxApplicationClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MACheckInbox	method dynamic MailboxApplicationClass, MSG_MA_CHECK_INBOX
lastCheckTime		local	FileDateAndTime	\
				push	ds:[di].MAI_lastCheckTime.FDAT_time, \
					ds:[di].MAI_lastCheckTime.FDAT_date
timerHandle		local	hptr	\
				push	ds:[di].MAI_inboxTimerHandle
inboxQueueHandle	local	word
firstClassMsgCount	local	word
curMsg			local	MailboxMessage
	.enter

	;
	; See if there's any first class message in the last check period.
	;
	segmov	ds, dgroup, ax
	assume	ds:dgroup
	clr	ax
	xchg	ax, ds:[inboxNumFirstClassMessages]
	tst	ax
	jz	done
	mov	ss:[firstClassMsgCount], ax

	;
	; Traverse the inbox queue, starting from the end.
	;
	call	AdminGetInbox		; ^vbx:di = inbox queoe
	mov	ss:[inboxQueueHandle], di
	call	DBQGetCount		; dxax = count
	Assert	e, dx, 0
	mov_tr	cx, ax			; cx = queue count

msgLoop:
	jcxz	done			; jump if we've reached the beginning
	dec	cx			; previous message

	;
	; See if message is registered within the last period.
	;
	mov	di, ss:[inboxQueueHandle]	; ^vbx:di = inbox queue
	call	DBQGetItem		; dxax = MailboxMessage
	movdw	ss:[curMsg], dxax	; for releasing reference...

	call	MessageLock		; *ds:di = MMD
	mov	si, ds:[di]
	movdw	dxax, ds:[si].MMD_registered	; ax = FileDate, dx = FileTime
	cmp	ax, ss:[lastCheckTime].FDAT_date
	jne	afterCmpTime
	cmp	dx, ss:[lastCheckTime].FDAT_time
afterCmpTime:
	jb	tooOld
	
	call	MAMaybeShowInboxPanelForMessage

previous:
	;
	; loop to previous message in queue.
	;
	call	UtilVMUnlockDS		; unlock message

	movdw	dxax, ss:[curMsg]
	call	DBQDelRef		; release ref added by DBQGetItem

	tst	ss:[firstClassMsgCount]
	jnz	msgLoop

done:
	tst	ss:[timerHandle]
	jz	exit			; => left over timer.  Don't start
					;  another one.

	;
	; Start the timer again.
	;
	mov	ax, MSG_MA_START_INBOX_CHECK_TIMER
	clr	cx			; use current value
	call	UtilSendToMailboxApp

exit:
	.leave
	ret

tooOld:
	;
	; This message is too old, so are all previous messages.  Hence we
	; can stop checking now.
	;
	clr	cx			; a hack such that we will break out
					;  of the loop after unlocking the msg
	jmp	previous

MACheckInbox	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMaybeShowInboxPanelForMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the message is first-class and hasn't been seen before,
		ask our application object to put up a panel to show it to
		the user.

CALLED BY:	(INTERNAL) MACheckInbox
PASS:		*ds:di	= MailboxMessageDesc
		ds:si	= same
		bx	= admin file
		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	ax, dx, si, es, di
SIDE EFFECTS:	ss:[firstClassMsgCount] may be decremented
     		message's destApp may change, if it was directed to a
			previously-unknown-but-now-known alias token

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/19/94	Initial version (extracted from MACheckInbox)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMaybeShowInboxPanelForMessage proc	near
	uses	cx
	.enter	inherit	MACheckInbox
	;
	; See if this message is first-class.
	;
	mov	ax, ds:[si].MMD_flags
		; Make sure MailboxMessageFlags is in low byte of
		;  MailboxInternalMessageFlags
		CheckHack <offset MIMF_EXTERNAL eq 0>
		CheckHack <mask MailboxMessageFlags le 0xff>
	andnf	al, mask MMF_PRIORITY
	cmp	al, MMP_FIRST_CLASS shl offset MMF_PRIORITY
	jne	done
	dec	ss:[firstClassMsgCount]	; we've found one

	;
	; We've found a first-class message.  Check if user has seen it before.
	;
		CheckHack <offset MIMF_NOTIFIED ge 8>
	test	ax, mask MIMF_NOTIFIED	; (still ok b/c only messed with
					;  low byte when checking prio)
	jnz	done			; jump if already notified

	;
	; Fetch the application name now so any alias token remapping happens
	; before we try to put the control panel up.
	;
	push	bx
	mov	bx, {word}ds:[si].MMD_destApp.GT_chars[0]
	mov	cx, {word}ds:[si].MMD_destApp.GT_chars[2]
	mov	dx, ds:[di].MMD_destApp.GT_manufID
	call	InboxGetAppName
	call	LMemFree
	pop	bx
	
	mov	si, ds:[di]

	;
	; This message should be displayed.  Put up specific by-app panel.
	;
	mov	dx, bx			; dx = admin file handle
	lea	si, ds:[si].MMD_destApp	; ds:si = GeodeToken of destApp
	mov	ax, size MailboxDisplayPanelCriteria
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc		; bx = hptr, ax = sptr

	mov	es, ax
		CheckHack <offset MDPC_byApp.MDBAD_token eq 0>
	clr	di			; es:di = MDPC_byApp.MDBAD_token
		CheckHack <(size GeodeToken and 1) eq 0>
	mov	cx, size GeodeToken / 2
	rep	movsw
	call	MemUnlock

	xchg	dx, bx			; ^hdx = criteria, bx = admin file
	mov	ax, MSG_MA_DISPLAY_INBOX_PANEL
	mov	cx, MDPT_BY_APP_TOKEN
	call	UtilSendToMailboxApp	; send to ourselves (let's be lazy :-)
done:
	.leave
	ret
MAMaybeShowInboxPanelForMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAStopInboxCheckTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop any pending timer for inbox checking.

CALLED BY:	MSG_MA_STOP_INBOX_CHECK_TIMER
PASS:		ds:di	= MailboxApplicationClass instance data
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAStopInboxCheckTimer	method dynamic MailboxApplicationClass, 
					MSG_MA_STOP_INBOX_CHECK_TIMER

	add	di, offset MAI_inboxTimerHandle
	FALL_THRU	MAStopTimerCommon

MAStopInboxCheckTimer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAStopTimerCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to stop a timer

CALLED BY:	(INTERNAL) MAStopInboxCheckTimer, MAStopAdminFileUpdateTimer
PASS:		ds:di	= MAI_inboxTimerHandle or
			  MAI_adminFileUpdateTimerHandle
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAStopTimerCommon	proc	far
	class	MailboxApplicationClass

	CheckHack <MAI_inboxTimerHandle + size hptr eq MAI_inboxTimerID>
	CheckHack <MAI_adminFileUpdateTimerHandle + size hptr eq \
						MAI_adminFileUpdateTimerID>

	clr	bx
	xchg	bx, ds:[di]		; bx = timer handle
	mov	ax, ds:[di + size hptr]	; ax = timer ID
	GOTO	TimerStop

MAStopTimerCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAStartAdminFileUpdateTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup a timer that periodically updates the admin file on disk.

CALLED BY:	MSG_MA_START_ADMIN_FILE_UPDATE_TIMER
PASS:		*ds:si	= MailboxApplicationClass object
		ds:di	= MailboxApplicationClass instance data
		cx	= # of timer ticks, or 0 to use current value
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAStartAdminFileUpdateTimer	method dynamic MailboxApplicationClass, 
					MSG_MA_START_ADMIN_FILE_UPDATE_TIMER

	add	di, offset MAI_adminFileUpdatePeriod
		CheckHack <MSG_MA_START_ADMIN_FILE_UPDATE_TIMER + 1 eq \
			MSG_MA_UPDATE_ADMIN_FILE>
	inc	ax			; ax = MSG_MA_UPDATE_ADMIN_FILE
	GOTO	MAStartTimerCommon

MAStartAdminFileUpdateTimer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAUpdateAdminFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the VM file on disk, and starts the next timer.

CALLED BY:	MSG_MA_UPDATE_ADMIN_FILE
PASS:		ds:di	= MailboxApplicationClass instance data
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAUpdateAdminFile	method dynamic MailboxApplicationClass, 
					MSG_MA_UPDATE_ADMIN_FILE

	call	UtilUpdateAdminFile
	tst	ds:[di].MAI_adminFileUpdateTimerHandle
	jz	done			; => left-over timer.  Don't start
					;  another one.

	;
	; Start the timer again.
	;
		CheckHack <MSG_MA_UPDATE_ADMIN_FILE - 1 eq \
				MSG_MA_START_ADMIN_FILE_UPDATE_TIMER>
	dec	ax		; ax = MSG_MA_START_ADMIN_FILE_UPDATE_TIMER
	clr	cx			; use current value
	call	UtilSendToMailboxApp

done:
	ret
MAUpdateAdminFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAStopAdminFileUpdateTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop any pending timer for updating the admin file.

CALLED BY:	MSG_MA_STOP_ADMIN_FILE_UPDATE_TIMER
PASS:		ds:di	= MailboxApplicationClass instance data
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAStopAdminFileUpdateTimer	method dynamic MailboxApplicationClass, 
					MSG_MA_STOP_ADMIN_FILE_UPDATE_TIMER

	add	di, offset MAI_adminFileUpdateTimerHandle
	GOTO	MAStopTimerCommon

MAStopAdminFileUpdateTimer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAUpdateAdminFileUrgent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try to update the admin file again, after an update has just
		failed due to locked VM blocks.

CALLED BY:	MSG_MA_UPDATE_ADMIN_FILE_URGENT
PASS:		ds:di	= MailboxApplicationClass instance data
		ax	= message #
		if sent by utility code (UtilUpdateAdminFile)
			bp	= 0
		if sent by timer event
			bp	= timer ID
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	UtilUpdateAdminFile can be called many times within a short period
	of time (from same or different thread) and they can all fail because
	of locked blocks.  In that case, we will be invoked many times both
	from the timer and from utility code.  Then we have to make sure we
	either cancel or ignore the previous timer when we override it with a
	new one, so that there won't be a dangling message if the system is
	shutting down and the app object is going away.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAUpdateAdminFileUrgent	method dynamic MailboxApplicationClass, 
					MSG_MA_UPDATE_ADMIN_FILE_URGENT

	mov_tr	dx, ax			; dx = MSG_MA_UPDATE_ADMIN_FILE_URGENT
					;  for later TimerStart call

	;
	; If this is a left-over timer event (not the one we are expecting),
	; just drop it.  This can happen when VMUpdate failed again after a
	; timer had already started, or when mailbox is about to exit.
	;
	mov	ax, ds:[di].MAI_adminFileUpdateUrgentTimerID
	tst	bp
	jz	doIt			; => sent by mailbox code, so do it
					;  regardless
	cmp	ax, bp
	jne	done			; => either ax is a different ID or ax
					;  is zero.  Either way this timer
					;  event was meant to be canceled.

doIt:
	;
	; Turn off other pending timer, if any.  (We may be trying to cancel
	; the one that just expired and invoked ourselves, but who cares.)
	;
	tst	ax
	jz	update			; => no pending timer

	clr	bx, ds:[di].MAI_adminFileUpdateUrgentTimerID
	xchg	bx, ds:[di].MAI_adminFileUpdateUrgentTimerHandle
	call	TimerStop

update:
	call	MailboxGetAdminFile
	call	VMUpdate		; ax = VMStatus
EC <	jnc	ok							>
EC <	cmp	ax, VM_UPDATE_BLOCK_WAS_LOCKED				>
EC <	WARNING_NE ADMIN_FILE_CANT_BE_UPDATED				>
EC <ok:									>
	cmp	ax, VM_UPDATE_BLOCK_WAS_LOCKED
	jne	done			; => success, or some other error

	;
	; Start a timer to update again later.
	;
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[OLMBH_header].LMBH_handle
	mov	cx, ADMIN_FILE_UPDATE_URGENT_RETRY_DELAY
	call	TimerStart

	mov	ds:[di].MAI_adminFileUpdateUrgentTimerHandle, bx
	mov	ds:[di].MAI_adminFileUpdateUrgentTimerID, ax

done:
	ret
MAUpdateAdminFileUrgent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAStartNextEventTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts a timer to call us back when it's time to do the next
		interesting event in the mailbox.

CALLED BY:	MSG_MA_START_NEXT_EVENT_TIMER
PASS:		*ds:si	= MailboxApplicationClass object
		ds:di	= MailboxApplicationClass instance data
		dxcx	= FileDateAndTime of next interesting event
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAStartNextEventTimer	method dynamic MailboxApplicationClass,
					MSG_MA_START_NEXT_EVENT_TIMER

	;
	; Do nothing if the new event is a later event than the old one.
	;
	mov	bx, ds:[di].MAI_nextEventTimerHandle
	inc	bx
	jz	startNewTimer
	dec	bx
	jz	startNewTimer
		;
		; If MAI_nextEventTimerHandle is not null, either the old timer
		; still hasn't expired, or it has expired but the message is
		; still in our event queue.  In the first case we can stop the
		; old timer and start a new one.  In the second case it is
		; still safe to start a new timer, because when the old timer
		; message finally reaches our method, it will process other
		; mailbox events as well as this earlier one.  When the new
		; timer expires and reaches our method, it will find nothing
		; to do (becasue this earlier event is already processed) and
		; gracefully returns.
		;
	cmp	cx, ds:[di].MAI_nextEventDateTime.FDAT_date
	jne	afterCmpTime
	cmp	dx, ds:[di].MAI_nextEventDateTime.FDAT_time
afterCmpTime:
	jae	done			; jump if new date/time is later

	;
	; New time is earlier.  Stop old timer
	;
	mov	ax, ds:[di].MAI_nextEventTimerID
	call	TimerStop		; CF set if old timer already expired

startNewTimer:
	call	MAStartNextEventTimerCommon

done:
	ret
MAStartNextEventTimer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAStartNextEventTimerCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to start the next-interesting-event timer.

CALLED BY:	(INTERNAL) MAStartNextEventTimer
PASS:		*ds:si	= MailboxApplicationClass object
		ds:di	= MailboxApplicationClass instance data
		dxcx	= FileDateAndTime of new timer
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAStartNextEventTimerCommon	proc	near
	class	MailboxApplicationClass

	movdw	ds:[di].MAI_nextEventDateTime, dxcx

	;
	; Convert FileTime in dx to dh = hour, dl = minute
	;
	shr	dx
	shr	dx
	shr	dx			; dh = hour
	shr	dl
	shr	dl			; dl = minute

	push	di			; save self offset
	mov	al, TIMER_EVENT_REAL_TIME
	mov	bx, ds:[OLMBH_header].LMBH_handle	; ^lbx:si = self
	mov	di, dx			; di = hour (high) and min (low)
	mov	dx, MSG_MA_DO_NEXT_EVENT
	call	TimerStart
	pop	di
	mov	ds:[di].MAI_nextEventTimerHandle, bx
	mov	ds:[di].MAI_nextEventTimerID, ax

	ret
MAStartNextEventTimerCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MARecalcNextEventTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the time for the next event to occur.

CALLED BY:	MSG_MA_RECALC_NEXT_EVENT_TIMER
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	timer is stopped, events may occur if we're passed their time.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MARecalcNextEventTimer method dynamic MailboxApplicationClass, 
				MSG_MA_RECALC_NEXT_EVENT_TIMER
		.enter
	;
	; Stop any existing timer, first.
	;
		mov	bx, -1
		xchg	ds:[di].MAI_nextEventTimerHandle, bx
		inc	bx
		jz	recalc
		dec	bx
		jz	recalc
		mov	ax, ds:[di].MAI_nextEventTimerID
		call	TimerStop
		jc	done		; => MA_DO_NEXT_EVENT is already in
					;  the queue, so do nothing.
recalc:
	;
	; Now pretend like the timer fired. This will figure out the next
	; appropriate event time and schedule a timer for it. It will also
	; dispatch any events that are now possible and whose time has passed.
	;
		mov	ax, MSG_MA_DO_NEXT_EVENT
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
MARecalcNextEventTimer endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MADoNextEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform all the events that are scheduled to happen now or
		earlier.

CALLED BY:	MSG_MA_DO_NEXT_EVENT
PASS:		*ds:si	= MailboxApplicationClass object
		ds:di	= MailboxApplicationClass instance data
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	Another timer is set up for the next event in the future (if
		any).

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MADoNextEvent	method dynamic MailboxApplicationClass, MSG_MA_DO_NEXT_EVENT
;
; WARNING: These local variables must match those in InboxDoEvent and
; OutboxDoEvent!
;
currentTime	local	FileDateAndTime
nextEventTime	local	FileDateAndTime
	.enter

	tst	ds:[di].MAI_nextEventTimerHandle
	jz	done			; do nothing if timer stopped and this
					;  is a stray message

	clr	ds:[di].MAI_nextEventTimerHandle
	movdw	ss:[nextEventTime], MAILBOX_ETERNITY

	;
	; Get current time.  It's more convenient and accurate this way than
	; using the hour/min passed with the message.
	;
	call	TimerGetFileDateTime
	movdw	ss:[currentTime], dxax

	;
	; Go thru messages in outbox.
	;
	call	AdminGetOutbox		; ^vbx:di = outbox DBQ
	mov	cx, vseg OutboxDoEvent
	mov	dx, offset OutboxDoEvent
	call	DBQEnum

	;
	; Go thru message in inbox.
	;
	call	AdminGetInbox		; ^vbx:di = inbox DBQ
	mov	cx, vseg InboxDoEvent
	mov	dx, offset InboxDoEvent
	call	DBQEnum

	;
	; Schedule a timer for the next event (if any).
	;
	movdw	dxcx, ss:[nextEventTime]
		CheckHack <MAILBOX_ETERNITY eq -1>
	mov	ax, dx
	and	ax, cx
	inc	ax
	je	done			; jump if dxcx = MAILBOX_ETERNITY
	mov	ax, MSG_MA_START_NEXT_EVENT_TIMER
	call	UtilSendToMailboxApp

done:
	.leave
	ret
MADoNextEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMetaConfirmShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're transmitting anything, ask the user if s/he
		really wants to shutdown.

CALLED BY:	MSG_META_CONFIRM_SHUTDOWN
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		bp	= GCNShutdownControlType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 9/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMetaConfirmShutdown method dynamic MailboxApplicationClass, 
				MSG_META_CONFIRM_SHUTDOWN
		.enter
		cmp	bp, GCNSCT_UNSUSPEND
		je	done
	;
	; Prepare for confirmation/denial & see if we should even bother.
	;
		mov	ax, SST_CONFIRM_START
		call	SysShutdown
		jc	done			; => someone else has denied,
						;  so do nothing.

		call	MainThreadCheckForThreads
		jnc	allowShutdown 		; No threads active, so just
						;  allow the thing to happen,
						;  whatever it is.
	;
	; Something's happening -- confirm with the user before we allow the
	; shutdown.
	;
		cmp	bp, GCNSCT_SUSPEND
		je	denyShutdown		; for now, deny suspend when
						;  transmitting or receiving

		mov	si, offset uiConfirmShutdownStr
		call	UtilDoConfirmation
		cmp	ax, IC_YES
		je	allowShutdown

denyShutdown:
		clr	cx
		jmp	finishConfirm

allowShutdown:
		mov	cx, TRUE
finishConfirm:
		mov	ax, SST_CONFIRM_END
		call	SysShutdown

done:
		.leave
		ret
MAMetaConfirmShutdown endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMessageNotificationDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that the application has been notified of the
		message and been given a chance to do what it wants with it

CALLED BY:	MSG_MA_MESSAGE_NOTIFICATION_DONE
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		cxdx	= MailboxMessage
		bp	= IACP connection to close (0 if none)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 5/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMessageNotificationDone method dynamic MailboxApplicationClass, 
					MSG_MA_MESSAGE_NOTIFICATION_DONE
		.enter
		call	MARemoveMsgReference
		tst	bp
		jz	done
		clr	cx
		call	IACPShutdown
done:
		.leave
		ret
MAMessageNotificationDone		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAMessageNotificationNotHandled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with having tried to deliver a message to an application
		that does not handle receiving Clavin messages

CALLED BY:	MSG_MA_MESSAGE_NOTIFICATION_NOT_HANDLED
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		cxdx	= affected message
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 5/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAMessageNotificationNotHandled method dynamic MailboxApplicationClass,
				MSG_MA_MESSAGE_NOTIFICATION_NOT_HANDLED
		.enter

ife	_CONTROL_PANELS
	;
	; Just delete the thing. In theory we should tell the user about it,
	; but I don't feel like writing it at the moment.
	;
		call	MailboxDeleteMessage
else
	;
	; If the user's got a control panel to use, we let him/her delete the
	; thing. Right?
	;

endif	; !_CONTROL_PANELS

done::
		.leave
		ret
MAMessageNotificationNotHandled endm

MBAppCode	ends
