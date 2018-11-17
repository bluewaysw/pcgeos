COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inboxRegister.asm

AUTHOR:		Adam de Boor, Jun  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 3/94		Initial revision


DESCRIPTION:
	Functions to handle the special parts of adding a message to the inbox
		

	$Id: inboxRegister.asm,v 1.1 97/04/05 01:20:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InboxCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxMessageAdded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification routine called when a message is added to the
		inbox DBQ.

CALLED BY:	(EXTERNAL) DBQAdd, InboxProcessNewAliasToken
PASS:		dxax	= DBGroupAndItem of the message
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Add token and name of dest app to token map.
		See if app is loaded
		If so, see if app is focus app & marked as wanting immediate
			receipt. send message, if it is, else put up by-app
			panel if it's not.
		Send MSG_MA_INBOX_CHANGED notification

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	7/14/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxMessageAdded proc	far
msg		local	MailboxMessage	push	dx, ax
mmdFptr		local	fptr.MailboxMesssageDesc
appFlags	local	InboxAppFlags
msgFlags	local	MailboxMessageFlags
	uses	ax,bx,cx,dx,si,di,ds,es
	.enter

	;
	; Retrive MailboxMessageDesc
	;
	call	MessageLock
	mov	di, ds:[di]		; ds:di = MailboxMessageDesc
	movdw	ss:[mmdFptr], dsdi
	mov	ax, ds:[di].MMD_flags
	mov	ss:[msgFlags], ax

	;
	; If there is a deadline, schedule it with the app object.
	;
	movdw	dxcx, ds:[di].MMD_transWinClose
		CheckHack <MAILBOX_ETERNITY eq -1>
	mov	ax, dx
	and	ax, cx
	inc	ax
	jz	afterTimer		; jump if dxcx = MAILBOX_ETERNITY
	mov	ax, MSG_MA_START_NEXT_EVENT_TIMER
	call	UtilSendToMailboxApp

afterTimer:
	;
	; Allocate InboxAppData on stack and stuff in destApp token
	;
	mov	ax, IAD_UNKNOWN		; assume name unknown if new token
	push	ax			; push IAD_nameRef.IAN_name
	mov	ax, ds:[di].MMD_destApp.GT_manufID
	push	ax			; push IAD_token.GT_manufID
	pushdw	ds:[di].MMD_destApp.GT_chars	; push IAD_token.GT_chars
	sub	sp, offset IAD_token	; ss:sp = InboxAppData
	mov	bx, sp
	clr	dl			; assume not alias if new token
	cmp	ax, MANUFACTURER_ID_GENERIC
	jne	notAlias		; not generic, hence not alias
	mov	dl, mask IAF_IS_ALIAS	; generic, hence alias
notAlias:
	; set alias flag.  We know nothing about IAF_DONT_QUERY_IF_FOREGROUND
	mov	ss:[bx].IAD_flags, dl
	mov	ss:[appFlags], dl

	;
	; Add the new token to token array (or add one reference if exists)
	;
	movdw	cxdx, sssp		; cx:dx = InboxAppData
	call	IATAddIADToTokenArray	; ax = elt #, *ds:si = array, CF
	jnc	alreadyExist

	;
	; This is a new token.  Add one more reference to it such that it
	; will stay around even when all messages bound to it are removed.
	;
	call	ElementArrayAddReference
	mov	ax, 2
	mov	bh, ah			; bhax = 2 (ref count, WordAndAHalf)
	jmp	rebuildAppList

alreadyExist:
	;
	; This token already exists.  If it's a bound alias, remap message to
	; the real app.  First remove reference to alias token and add
	; reference to real app token.
	;
	call	ChunkArrayElementToPtr	; ds:di = InboxAppData
	mov_tr	cx, ax			; cx = elt # of token
	mov	ax, ds:[di].IAD_meta.REH_refCount.WAAH_low
	mov	bh, ds:[di].IAD_meta.REH_refCount.WAAH_high
	mov	bl, ds:[di].IAD_flags
	mov	ss:[appFlags], bl
	test	bl, mask IAF_IS_ALIAS
	jz	notifyNewMessage	; do nothing if not alias
	cmp	ds:[di].IAD_nameRef.IAN_aliasFor, IAD_UNKNOWN
	je	rebuildAppList		; do nothing if alias not bound
	mov_tr	ax, cx			; ax = elt # of token
	clr	bx			; no callback
	call	ElementArrayRemoveReference	; remove ref to alias token
	mov	ax, ds:[di].IAD_nameRef.IAN_aliasFor
	call	ElementArrayAddReference	; add ref to real app token

	;
	; Change destApp of message to point to real app.
	;
	call	ChunkArrayElementToPtr	; ds:di = IAD of real app
	mov	ax, ds:[di].IAD_meta.REH_refCount.WAAH_low
	mov	bh, ds:[di].IAD_meta.REH_refCount.WAAH_high
					; bhax = ref count
	push	di
	lea	si, ds:[di].IAD_token	; ds:si = GeodeToken src
	les	di, ss:[mmdFptr]
	add	di, offset MMD_destApp	; es:di = GeodeToken dest
		CheckHack <(size GeodeToken and 1) eq 0>
	mov	cx, size GeodeToken / 2
	rep	movsw
	push	bp
	mov	bp, es:[LMBH_handle]
	call	VMDirty			; mark message block dirty
	pop	bp
	pop	ax			; ds:ax <- IAD (need ss:sp to be
					; IAD on the stack...)

	;
	; Also modify GeodeToken within InboxAppData on stack to be the real
	; app token, just for convenience later.
	;
	mov	cx, size GeodeToken
	sub	si, cx			; ds:si = GeodeToken src
	movdw	esdi, sssp
	add	di, offset IAD_token	; es:di = GeodeToken dest
	rep	movsb

	mov_tr	di, ax			; ds:di <- IAD for notification

notifyNewMessage:

rebuildAppList:
	;
	; Unlock stuff first.
	;
	call	UtilVMUnlockDS		; unlock token array block
	mov	ds, ss:[mmdFptr].segment
	call	UtilVMUnlockDS		; unlock message

	;
	; bhax = ref count.  If ref count of token == 2 (which means the 1st
	; message for that token has just been added), notify InboxAppList.
	;
	tst	bh
	jnz	sendNotif
	cmp	ax, 2
	jne	sendNotif
	call	IRSendRebuild		; rebuild app list

sendNotif:
	;
	; Send inbox change notification (queued so it arrives after the
	; MABC_REMOVED notification when a message is redirected after it's
	; already in the inbox)
	;
	push	bp
	mov	ax, MSG_MA_BOX_CHANGED
	movdw	cxdx, ss:[msg]
	mov	bp, (MABC_ALL shl offset MABC_ADDRESS) or \
			(MACT_EXISTS shl offset MABC_TYPE)
	clr	di
	call	UtilForceQueueMailboxApp
	pop	bp

	;
	; Do priority-specific work.
	;
	movdw	esdi, sssp		; es:di = InboxAppData
	add	di, offset IAD_token	; es:di = GeodeToken
	mov	al, ss:[appFlags]
	mov	bx, ss:[msgFlags]
	call	IRDoPrioritySpecific
	add	sp, size InboxAppData

	.leave
	ret
InboxMessageAdded endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IRSendRebuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a MSG_IAL_REBUILD_LIST to the system inbox panel's app
		list, as we've added the first or removed the last message
		for an app, requiring a change in the list.

CALLED BY:	(INTERNAL) InboxMessageAdded
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRSendRebuild	proc	near
if	_CONTROL_PANELS		; no IAL if !_CONTROL_PANELS
	uses	ax,bx,cx,dx,si,di
	.enter

	mov	bx, segment InboxApplicationListClass
	mov	si, offset InboxApplicationListClass
	mov	ax, MSG_IAL_REBUILD_LIST
	mov	di, mask MF_RECORD
	call	ObjMessage		; di = event handle

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	cx, di
	mov	dx, TO_INBOX_APPLICATION_LIST
	clr	di
	call	UtilForceQueueMailboxApp

	.leave
endif	; _CONTROL_PANELS
	ret
IRSendRebuild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IRDoPrioritySpecific
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do priority-specific work for a newly added message in inbox

CALLED BY:	(INTERNAL) InboxMessageAdded
PASS:		es:di	= GeodeToken of app
		cxdx	= MailboxMessage
		al	= InboxAppFlags
		bx	= MailboxMessageFlags
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRDoPrioritySpecific	proc	near
mesg	local	MailboxMessage	push	cx, dx
	.enter

		CheckHack <offset MIMF_EXTERNAL + width MIMF_EXTERNAL le 8>
				; make sure MailboxMessageFlags fits in bl
	andnf	bl, mask MMF_PRIORITY

	;
	; If app is focus app and marked no-query-if-foreground, send
	; notification right away.
	;
	test	al, mask IAF_DONT_QUERY_IF_FOREGROUND
	jz	checkPriority
	segmov	ds, dgroup, si
	mov	si, offset inboxFocusApp
		CheckHack <(size GeodeToken and 1) eq 0>
	mov	cx, size GeodeToken / 2
	push	di
	repe	cmpsw
	pop	di			; es:di = GeodeToken of app
	je	sendNotif		; jump if GeodeToken's equal

checkPriority:
	;
	; If MMP_EMERGENCY, send notification right away.
	;
		CheckHack <MMP_EMERGENCY shl offset MMF_PRIORITY eq 0>
	tst	bl			; see if MMP_EMERGENCY
	je	sendNotif

	;
	; If MMP_URGENT, put up inbox panel
	;
	cmp	bl, MMP_FIRST_CLASS shl offset MMF_PRIORITY
	je	firstClass
	ja	done			; jump if MMP_THIRD_CLASS
	mov	ax, size MailboxDisplayPanelCriteria
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	mov	bx, handle 0
	call	MemAllocSetOwner
	movdw	dssi, esdi
	mov	es, ax
		CheckHack <offset MDPC_byApp.MDBAD_token eq 0>
	clr	di			; es:di = MDPC_byApp.MDBAD_token
		CheckHack <(size GeodeToken and 1) eq 0>
	mov	cx, size GeodeToken / 2
	rep	movsw
	call	MemUnlock

	mov	ax, MSG_MA_DISPLAY_INBOX_PANEL
	mov	cx, MDPT_BY_APP_TOKEN
	mov	dx, bx			; ^hdx = MailboxDisplayPanelCriteria
	call	UtilSendToMailboxApp
	jmp	done

sendNotif:
	movdw	cxdx, ss:[mesg]
	call	IRNotifyDestApp

	;
	; Even though the app is notified, we still want to increment the count
	; if it's first-class.
	;
	cmp	bl, MMP_FIRST_CLASS shl offset MMF_PRIORITY
	jne	done

firstClass:
	;
	; First Class.  Increment message count.
	;
	segmov	ds, dgroup, ax
	inc	ds:[inboxNumFirstClassMessages]

done:
	.leave
	ret
IRDoPrioritySpecific	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IRNotifyDestApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_MP_SEND_MESSAGE_AVAILABLE_NOTIFICATION to the
		destination app of the message.  The notification is delayed
		via the mailbox thread.

CALLED BY:	(INTERNAL)
PASS:		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	ax, dx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Force-queue an event to our process object to send out the actual
	notification, such that we don't run into deadlock when calling
	IACPConnect because many things are locked.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRNotifyDestApp	proc	far
	uses	bp, bx, di
	.enter

	;
	; Add a reference to the message so it stays around for the duration.
	;
	call	MailboxGetAdminFile
	MovMsg	dxax, cxdx
	call	DBQAddRef
	MovMsg	cxdx, dxax

	;
	; Get destApp of message
	;
	clr	di			; di <- send even if not loaded
	push	di			; push SMANP_ifLoaded
	pushdw	cxdx			; push SMANP_message
	sub	sp, size SMANP_destApp	; push SMANP_destApp
	movdw	esdi, sssp
	call	MailboxGetDestApp

	;
	; Force-queue a message (to avoid deadlock) to our process to do the
	; job.
	;
	mov	bx, handle 0
	mov	ax, MSG_MP_SEND_MESSAGE_AVAILABLE_NOTIFICATION
	mov	bp, sp
	mov	dx, size SendMsgAvailableNotifParams
	mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
	call	ObjMessage
	add	sp, dx
	.leave
	ret
IRNotifyDestApp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IRSendMessageAvailableNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to the destination application and send its process
		a notification.

CALLED BY:	MSG_MP_SEND_MESSAGE_AVAILABLE_NOTIFICATION
PASS:		ss:bp	= SendMsgAvailableNotifParams
RETURN:		carry set if couldn't connect
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRSendMessageAvailableNotification	method extern MailboxProcessClass, 
				MSG_MP_SEND_MESSAGE_AVAILABLE_NOTIFICATION

	;
	; See if application has already been notified. Do not do it more
	; than once.
	;
	push	ds
	movdw	cxdx, ss:[bp].SMANP_message
	call	MessageLockCXDX
	mov	di, ds:[di]
	mov	ax, ds:[di].MMD_flags
	ornf	ds:[di].MMD_flags, mask MIMF_APPLICATION_NOTIFIED
	call	UtilVMDirtyDS
	call	UtilVMUnlockDS
	pop	ds
	test	ax, mask MIMF_APPLICATION_NOTIFIED
	jnz	delRef
	
	;
	; Handle specially if the message is for mailbox ourselves, i.e.
	; one of the Poof messages.
	;
	cmp	{word} ss:[bp].SMANP_destApp.GT_chars[0],
			MAILBOX_TOKEN_CHARS_0_1
	jne	notPoof
	cmp	{word} ss:[bp].SMANP_destApp.GT_chars[2],
			MAILBOX_TOKEN_CHARS_2_3
	jne	notPoof
	cmp	ss:[bp].SMANP_destApp.GT_manufID,
			MAILBOX_TOKEN_ID
	jne	notPoof

	mov	ax, MSG_META_MAILBOX_NOTIFY_MESSAGE_AVAILABLE
	mov	bx, handle 0
	mov	di, mask MF_FORCE_QUEUE	; in case called from IMLSelect,
					;  can't have the queue moving
					;  around
	call	ObjMessage

	clr	bp			; bp <- no connection to close
	mov	ax, MSG_MA_MESSAGE_NOTIFICATION_DONE
	call	UtilForceQueueMailboxApp

	jmp	doneOK

delRef:
	mov	si, bp
	call	notifDone
	jmp	doneOK

notPoof:
	;
	; Connect via IACP.
	;
	segmov	es, ss
	lea	di, ss:[bp].SMANP_destApp	; es:di = GeodeToken
	clr	dx
	tst	ss:[bp].SMANP_ifLoaded
	jnz	connect

	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock	; ^hdx = AppLaunchBlock
	jc	error
connect:
	mov	si, bp			; ss:si = SMANP
	mov	ax, mask IACPCF_OBEY_LAUNCH_MODEL or mask IACPCF_FIRST_ONLY \
		    or (IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	mov	bx, dx			; ^hbx = ALB
	call	IACPConnect		; bp = IACPConnection, bx = owner
	jc	error

	;
	; Send message-available notification to app's process.
	;
	; First record the completion message to our application object.
	;
	movdw	cxdx, ss:[si].SMANP_message
	mov	ax, MSG_MA_MESSAGE_NOTIFICATION_DONE
	clr	bx
	push	si
	mov	bx, handle MailboxApp
	mov	si, offset MailboxApp
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	;
	; Now record the message to be sent
	;
	push	bp, si, di

	StructPushBegin	ProcessCallRoutineParams
	StructPushField	PCRP_dataDI, bp
	StructPushField PCRP_dataSI, si
	StructPushField PCRP_dataDX, dx
	StructPushField PCRP_dataCX, cx
	StructPushField PCRP_dataBX, bx
	StructPushField PCRP_dataAX, ax
	mov	bx, vseg IRSendMessageAvailableNotificationFromProcess
	mov	ax, offset IRSendMessageAvailableNotificationFromProcess
	StructPushField PCRP_address, <bx, ax>
	StructPushEnd	ProcessCallRoutineParams
	
	mov	bp, sp
	mov	dx, size ProcessCallRoutineParams
	mov	ax, MSG_PROCESS_CALL_ROUTINE
	mov	bx, segment ProcessClass
	mov	si, offset ProcessClass
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage		; di <= recorded message
	add	sp, dx
	pop	bp, si, cx		; bp <- connection, cx <- completion msg
	
	mov	bx, di
	mov	dx, TO_PROCESS		; dx = TravelOption
	mov	ax, IACPS_CLIENT	; we are the client
	call	IACPSendMessage

	;
	; Leave IACP connection open. XXX: In theory we should let the mailbox
	; app know this thing is open so it doesn't detach until the completion
	; message arrives. Easiest would be to use the client-thread counter,
	; I think. Treat each sent message as a client thread...
	;
doneOK:
	clc
done:
	ret

error:
	;
	; Let app object know notification is complete.
	;
	call	notifDone

	tst	ss:[si].SMANP_ifLoaded
	stc
	jnz	done
	;;;
	;;; display error message
	;;;

	ret

	;--------------------
	; Let app object that notification is complete.
	;
	; Pass:
	; 	ss:si	= SendMsgAvailableNotifParams
	; Return:
	; 	nothing
	; Destroyed:
	; 	cx, dx, bp, ax
	;
notifDone:
	movdw	cxdx, ss:[si].SMANP_message
	clr	bp		; bp <- IACP connection not open
	mov	ax, MSG_MA_MESSAGE_NOTIFICATION_DONE
	clr	di
	call	UtilForceQueueMailboxApp
	retn

IRSendMessageAvailableNotification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IRSendMessageAvailableNotificationFromProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to synchronously send the notification to
		a process thread, so we know if the process actually has
		a method that implements the message. In the absence of such
		a method, we notify the user and delete the message.

CALLED BY:	(INTERNAL) IRSendMessageAvailableNotification via
			   MSG_PROCESS_CALL_ROUTINE sent through IACP
PASS:		cxdx	= MailboxMessage
		di	= IACP connection
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/26/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRSendMessageAvailableNotificationFromProcess proc	far
		.enter
		push	di, cx, dx
		mov	ax, MSG_META_MAILBOX_NOTIFY_MESSAGE_AVAILABLE
		clr	bx
		call	GeodeGetProcessHandle
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp, cx, dx
		jc	done
		
		mov	ax, MSG_MA_MESSAGE_NOTIFICATION_NOT_HANDLED
		mov	bx, segment MailboxApplicationClass
		mov	si, offset MailboxApplicationClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		
		mov	bx, di		; bx <- msg to send
		mov	dx, TO_SELF	; dx <- TravelOption
		clr	cx		; cx <- no completion
		mov	ax, IACPS_SERVER; ax <- server is sending
		call	IACPSendMessage
done:
		.leave
		ret
IRSendMessageAvailableNotificationFromProcess endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxAcknowledgeMessageReceipt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the Mailbox library that the application has taken
		control of the indicated message. The message is removed
		(visually) from the system inbox only when this function
		is called.

		If this function is *not* called following receipt of a
		MSG_META_MAILBOX_NOTIFY_MESSAGE_AVAILABLE and the application
		exits and restarts, the application will again be notified of
		the message's availability.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- call DBQRemove to remove item from inbox queue
	- call IRMessageRemoved, which does
		- send MSG_MA_INBOX_CHANGED with MBNT_MESSAGE_REMOVED
		- remove one reference from the app token in the
		  token array

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxAcknowledgeMessageReceipt	proc	far
	uses	ax,bx,cx,dx,di,ds
	.enter

	;
	; Remove message from inbox queue
	;
	call	AdminGetInbox		; ^vbx:di = DBQ handle for the inbox
	MovMsg	dxax, cxdx
	pushdw	dxax
	call	DBQRemove		; CF set if not in queue
	popdw	dxax
	jc	notInInbox

	;
	; Mark message delivered+acknowledged
	;
	call	MessageLock
	mov	di, ds:[di]
	BitSet	ds:[di].MMD_flags, MIMF_DELIVERED
	call	UtilVMDirtyDS
	call	UtilVMUnlockDS

	;
	; Send notification, remove reference from app token
	;
	call	IRMessageRemoved
	call	UtilUpdateAdminFile

notInInbox:
	.leave
	ret
MailboxAcknowledgeMessageReceipt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IRMessageRemoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification routine called when a message is removed from
		the inbox.

CALLED BY:	(INTERNAL)
PASS:		dxax	= MailboxMessage being removed
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Force-queue MSG_MA_INBOX_CHANGED notification
	Remove reference to token and name of dest app from token map.
	Rebuild app list if last message for that token is removed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IRMessageRemoved	proc	near
	uses	ax,bx,cx,dx,bp,si,di,ds,es
	.enter

	;
	; Send inbox change notification
	;
	MovMsg	cxdx, dxax
	mov	ax, MSG_MA_BOX_CHANGED
	mov	bp, (MACT_REMOVED shl offset MABC_TYPE) or \
			(MABC_ALL shl offset MABC_ADDRESS)
	clr	di
	call	UtilForceQueueMailboxApp

	;
	; Get destApp token stored in message
	;
	call	MessageLockCXDX		; *ds:di = MailboxMessageDesc
	segmov	es, ds
	mov	dx, ds:[di]
	add	dx, offset MMD_destApp	; es:dx = destApp token

	;
	; Locate token in token map
	;
	call	IATFindTokenInArray	; *ds:si = array, CF set if found
	jnc	cleanUp			; something's wrong

	;
	; Remove reference of app token in token array.  Need to rebuild app
	; list if ref count == 1 (which means the last message for that token
	; has just been removed)
	;
	clr	bx			; no callback
	call	ElementArrayRemoveReference
	call	ChunkArrayElementToPtr	; ds:di = IAD
	cmp	ds:[di].IAD_meta.REH_refCount.WAAH_high, 0
	jne	cleanUp
	cmp	ds:[di].IAD_meta.REH_refCount.WAAH_low, 1
	jne	cleanUp
	call	IRSendRebuild

cleanUp:
	call	UtilVMUnlockDS		; unlock token map
	segmov	ds, es
	call	UtilVMUnlockDS		; unlock MailboxMessageDesc

	.leave
	ret
IRMessageRemoved	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxRetargetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the destination application for the message.

CALLED BY:	(EXTERNAL) IATRemapMessageDest
			   MAMessageNotificationNotHandled
PASS:		dxax	= MailboxMessage to change
		ds:si	= new GeodeToken
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	remove/add notifications sent out for the old/new tokens

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 5/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxRetargetMessage proc	far
		uses	es, si, di, cx, bp
		.enter
if 	_NO_UNKNOWN_APPS_ALLOWED
		call	InboxCheckAppUnknown
		jc	done
endif	; _NO_UNKNOWN_APPS_ALLOWED

	;
	; Send remove msg notification, update token map
	;
		call	IRMessageRemoved

	;
	; Overwrite destApp token of message with actual token
	;
		push	ds, ax
		call	MessageLock
		mov	bp, ds:[LMBH_handle]
		call	UtilVMDirtyDS	; mark it dirty while we've got DS
		mov	di, ds:[di]
		andnf	ds:[di].MMD_flags, not mask MIMF_APPLICATION_NOTIFIED
		add	di, offset MMD_destApp
		segmov	es, ds		; es:di = MMD_destApp
		pop	ds, ax

			CheckHack <(size GeodeToken and 1) eq 0>
		mov	cx, size GeodeToken / 2
		push	si
		rep	movsw
		pop	si

		call	VMUnlock

	;
	; Update token map, send add msg notification
	;
		call	InboxMessageAdded

done::
		.leave
		ret
InboxRetargetMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxStoreAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the addresses for an incoming message.

CALLED BY:	(EXTERNAL) MRStoreAddresses
PASS:		cx	= number of addresses
		es:si	= MailboxTransAddr array
		*ds:di	= MailboxMessageDesc (not used)
		ds:bx	= MailboxMessageDesc
		ax	= MailboxTransportOption (not used)
RETURN:		ds fixed up
		carry set on error (always clear for now)
			ax	= MailboxError
		carry clear if ok
			ax destroyed
DESTROYED:	bx, cx, dx, si, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 1/95    	Initial version
	ardeb	2/17/95		Commonized grunt work of storing an address
				for both InboxStoreAddresses and
				ORStoreOneAddress

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxStoreAddresses	proc	far

	clr	ax			; ax <- MITA_medium value (be
					;  consistent)
addrLoop:
	push	cx			; save count
	call	MessageStoreAddress
	pop	cx
	jc	allocErr
	;
	; Loop to next MTA entry
	;
	add	si, size MailboxTransAddr
	loop	addrLoop		; flags preserved

	; return carry clear for now
	clc
done:
	ret

allocErr:
	mov	ax, ME_NOT_ENOUGH_MEMORY
	jmp	done
InboxStoreAddresses	endp

InboxCode	ends
