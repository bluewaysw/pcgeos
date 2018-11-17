COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inboxFetch.asm

AUTHOR:		Adam de Boor, Dec  1, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 1/94		Initial revision


DESCRIPTION:
	Functions for fetching new messages.
		

	$Id: inboxFetch.asm,v 1.1 97/04/05 01:21:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InboxFetch	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxRetrieveMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads a transport driver and asks it to retrieve any
		messages it can.

CALLED BY:	(GLOBAL)
PASS:		axbx	= MailboxTransport
		cxdx	= MediumType
		si	= MailboxTransportOption
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	what's a side-effect?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxRetrieveMessages proc	far
		uses	bx, ds, ax, cx
		.enter
		push	ax, bx, cx
		mov	ax, size MailboxMediaTransport
		mov	cx, ALLOC_FIXED or mask HF_SHARABLE
		mov	bx, handle 0
		call	MemAllocSetOwner
		jc	ack
		mov	ds, ax
		pop	ds:[MMT_transport].MT_manuf,
			ds:[MMT_transport].MT_id,
			ds:[MMT_medium].MET_manuf
		mov	ds:[MMT_medium].MET_id, dx
		mov	ds:[MMT_transOption], si
		call	IFMaybeFetchMessages
done:
		.leave
		ret

ack:
		pop	ax, bx, cx
		jmp	done
MailboxRetrieveMessages endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFMaybeFetchMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there's no thread already spawned to retrieve messages
		for this transport+medium+transopt combo, spawn one ourselves

CALLED BY:	(INTERNAL) MailboxRetrieveMessages, ICPRetrieveMessages
PASS:		bx	= handle of fixed block holding the
			  MailboxMediaTransport for which to search
RETURN:		nothing
DESTROYED:	ax, bx, ds
SIDE EFFECTS:	memory block is freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFMaybeFetchMessages proc	far
		uses	es, di, dx, bp, si, cx, di
		.enter
	;
	; See if there's already a thread running for this combo.
	;
		call	MemDerefES
		push	bx
		mov	bx, SEGMENT_CS
		mov	di, offset IFFindReceiveThread
		call	MainThreadEnum
		pop	bx
		jc	freeDataBlock
		
	;
	; Create the thread to do the work, passing the handle to that function
	; in CX (by leaving it in BX now :).
	; 
		mov	al, PRIORITY_STANDARD
		mov	cx, vseg IFFetchMain
		mov	dx, offset IFFetchMain
		mov	al, PRIORITY_STANDARD
		mov	bp, handle 0
		mov	di, INBOX_RETRIEVE_STACK_SIZE
		call	ThreadCreateVirtual
		jc	freeDataBlock
	;
	; Register the thing.
	;
		mov	ax, MTT_RECEIVE
		mov	cx, size InboxThreadData
		call	MainThreadCreate
	;
	; Fill in the info we've got.
	;
		movdw	ds:[di].ITD_meta.MTD_transport, es:[MMT_transport], ax
		movdw	ds:[di].ITD_medium, es:[MMT_medium], ax
		mov	ax, es:[MMT_transOption]
		mov	ds:[di].ITD_meta.MTD_transOption, ax
done:
	;
	; Release the thread block. This will allow the retrieve thread to
	; actually do something.
	;
		call	MainThreadUnlock
		.leave
		ret
freeDataBlock:
	;
	; Not able to create the thread, so free the data block.
	; 
		call	MemFree
		jmp	done
IFMaybeFetchMessages endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFFindReceiveThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there's already a thread receiving messages for the
		given MailboxMediaTransport

CALLED BY:	(INTERNAL) IFMaybeFetchMessages via MainThreadEnum
PASS:		ds:di	= MainThreadData to check
		es	= MailboxMediaTransport being sought
RETURN:		carry set if found
		carry clear if not
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFFindReceiveThread proc	far
		.enter
		cmp	ds:[di].MTD_type, MTT_RECEIVE
		jne	no
		cmpdw	ds:[di].ITD_meta.MTD_transport, es:[MMT_transport], ax
		jne	no
		cmpdw	ds:[di].ITD_medium, es:[MMT_medium], ax
		jne	no
		mov	ax, es:[MMT_transOption]
		cmp	ds:[di].ITD_meta.MTD_transOption, ax
		jne	no
		stc
done:
		.leave
		ret
no:
		clc
		jmp	done
IFFindReceiveThread endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFFetchMain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Main routine to call a transport driver to retrieve messages.

CALLED BY:	(INTERNAL) IFMaybeFetchMessages via ThreadCreateVirtual
PASS:		^hcx	= MailboxMediaTransport to contact
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	lots

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFFetchMain 	proc	far
cancelFlag	local	MailboxCancelAction
		uses	cx
		.enter
	;
	; Set up the cancel flag for the thread. The transport driver can
	; register a progress box later on, and possibly override this cancel
	; flag location, if it likes. This gives us something to mess with
	; in MailboxApplication even in the absence of a progress box. Note
	; that this also provides a syncronization point to make sure the
	; creator has a chance to use the MailboxMediaTransport in the block
	; we've received before we might get around to freeing it.
	;
		mov	ss:[cancelFlag], MCA_CANCEL_NONE
		call	MainThreadFindCurrentThread
		lea	ax, ss:[cancelFlag]
		movdw	ds:[di].MTD_cancelFlag, ssax
		call	MainThreadUnlock

		mov	bx, cx
		call	MemDerefDS		; ds <- MailboxMediaTransport
	;
	; Attempt to load the transport driver.
	; 
		movdw	cxdx, ds:[MMT_transport]
		call	UtilLoadTransportDriverWithError
		jc	done
	;
	; Now call the silly thing, if it supports the call.
	; 
		movdw	cxdx, ds:[MMT_medium]
		mov	ax, ds:[MMT_transOption]
		call	GeodeInfoDriver
		test	ds:[si].MBTDI_capabilities, mask MBTC_MESSAGE_RETRIEVE
		jz	doneOK

		mov	di, DR_MBTD_RETRIEVE_MESSAGES
		call	ds:[si].DIS_strategy
	;
	; Unload the driver and get out of here.
	; 
doneOK:
		clc
done:
	;
	; Locate the data for the current thread before we remove the
	; cancel flag from the stack.
	;
		pushf				; save load-error flag
		push	bx			;  and driver handle
		call	MainThreadFindCurrentThread
		pop	bx
		popf
		.leave
	;
	; Nuke the MailboxMediaTransport block.
	;
		xchg	bx, cx			; bx <- MT block, cx <- driver
		pushf				; save load-error flag
		call	MemFree
		mov	bx, cx			; bx <- driver
	;
	; Delete the thread entry and get any ack od/id we should use.
	;
		call	MainThreadDestroy
	;
	; Finally, now the progress box is being nuked, free the driver, if
	; any.
	;
		popf				; CF <- load error
		jc	exit
		call	MailboxFreeDriver
exit:
		clr	si			; si <- no extra data in ACK
		ret
IFFetchMain 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxRegisterReceiptThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lets the mailbox library know something is receiving messages
		and provides it a progress box to put on-screen. The
		progress box must be a subclass of MailboxProgressBoxClass,
		and the cancel flag must be in memory that will not move
		until MailboxUnregisterReceiptThread is called.

		The progress box should be in a template resource. It will
		be duplicated and run by the Mailbox library's process thread.
		It will be destroyed when you call MailboxUnregisterReceipt-
		Thread

CALLED BY:	(GLOBAL)
PASS:		cx:dx	= address of MailboxCancelAction flag for the
			  progress box to set.

		if MAILBOX_PERSISTENT_PROGRESS_BOXES feature is TRUE
			^lbx:si	= MailboxProgressBox object in its template
				  resource  (bx = 0 means don't have progress
				  box; thread can still be canceled, but only
				  by system detach)
			ss:bp	= additional data to pass in MSG_MPB_SETUP
			ax	= number of bytes of additional data
		else
			bx	= must be 0

RETURN:		if MAILBOX_PERSISTENT_PROGRESS_BOXES feature is TRUE
			^lbx:si	= the duplicated progress box
		else
			bx, si - preserved
DESTROYED:	ds, es if pointing to object block
SIDE EFFECTS:	dialog is duplicated and added to the mailbox application

PSEUDO CODE/STRATEGY:
	In order to avoid crashing in non-EC when a transport driver with
	progress boxes calls this function in a Mailbox lib without progress
	boxes (ie. a transport driver of a wrong product version is used), we
	simply create a progress box whenever a template is passed, regardless
	of whether the Mailbox lib itself supports progress boxes or not.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxRegisterReceiptThread proc	far
		uses	ax, cx, dx, bp, di, ds
		.enter
if	ERROR_CHECK and not MAILBOX_PERSISTENT_PROGRESS_BOXES
	tst	bx
	ERROR_NZ PROGRESS_BOXES_NOT_SUPPORTED_BY_THIS_PRODUCT_VERSION_OF_MAILBOX_LIB
endif	; ERROR_CHECK and not MAILBOX_PERSISTENT_PROGRESS_BOXES

	;
	; Duplicate the progress box. The thing is run by the mailbox process
	; thread (which runs the mailbox app object) and owned by the mailbox
	; library (so it doesn't go away if the owner of the current thread
	; gets unloaded before the duplicated block can be freed).
	; 
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		push	ax
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
		push	cx, dx
		tst	bx
		jz	haveBox

		push	bx
		mov	bx, handle MailboxApp
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
		mov_tr	cx, ax			; cx <- run by app thread
		pop	bx			; bx <- resource to dup
		mov	ax, handle 0		; ax <- owned by us
		call	ObjDuplicateResource
haveBox:

	;
	; Lock down the thread list block so we can create a new entry.
	;
		push	si, bx
	;
	; See if the current thread already has an entry. Don't use
	; MainThreadFindCurrentThread b/c that'll error if it's not found.
	; 
		mov	ax, TGIT_THREAD_HANDLE
		clr	bx
		call	ThreadGetInfo		; ax, bx <- current thread

		call	MainThreadFindByHandle	; (nukes bx, but not ax)
		jnc	haveData
	;
	; Create an entry for the current thread.
	;
		mov	cx, size InboxThreadData; cx <- elt size
		mov	ax, MTT_RECEIVE		; ax <- thread type
		call	MainThreadCreate
		mov_tr	ax, bx			; ax <- save thread handle for
						;  setting up progress box
haveData:
		pop	si, bx

		pop	cx, dx			; cx:dx <- cancel flag
	;
	; Record the progress box and cancel flag addresses in the entry
	;
		movdw	ds:[di].MTD_cancelFlag, cxdx
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		movdw	ds:[di].MTD_progress, bxsi

		pop	cx			; cx <- # extra bytes for setup
	;
	; Initialize the setup args for the progress box. We set MPBSA_show-
	; Progress TRUE so if the box has a progress gauge, it gets left
	; alone, but the caller isn't forced to have a progress gauge (the
	; progress box assumes the thing starts out usable...)
	;
		sub	sp, cx			; room for extra data
			CheckHack <size MPBSetupArgs eq 6>
		mov	dx, TRUE
			CheckHack <offset MPBSA_showProgress eq 4>
		push	dx
		mov	dx, ds:[di].MTD_gen
			CheckHack <offset MPBSA_gen eq 2>
		push	dx
			CheckHack <offset MPBSA_thread eq 0>
		push	ax

		mov	dx, size MPBSetupArgs
		add	dx, cx			; add room for extra data
		mov	di, bp			; ss:di <- extra data
		mov	bp, sp
		jcxz	doSetup
	    ;
	    ; Copy in the extra data.
	    ;
		push	si, ds, es
		mov	si, di			; ss:si <- extra data
		lea	di, ss:[bp+size MPBSetupArgs]
		mov	ax, ss
		mov	ds, ax			; ds:si <- extra data
		mov	es, ax			; es:di <- room for it
		rep	movsb
		pop	si, ds, es
doSetup:
		mov	ax, MSG_MPB_SETUP
		mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
		push	dx			; save stack adjustment, please
		call	ObjMessage
		pop	dx
		add	sp, dx
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
	;
	; Release the thread data block *after* sending the message so the
	; progress box doesn't get messages from anyone else before it gets
	; its setup info.
	;
		call	MainThreadUnlock
		.leave
		ret
MailboxRegisterReceiptThread endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxUnregisterReceiptThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current thread is about to finish receiving messages. The
		progress box that was created should be destroyed.

		If the thread is going to do something else before destroying
		itself, it should send MSG_META_ACK to the returned OD, so
		long as the OD is non-zero.

CALLED BY:	(GLOBAL)
PASS:		nothing
RETURN:		cx	= ack ID to pass to ThreadDestroy
		dx:bp	= ack OD to pass to ThreadDestroy
DESTROYED:	nothing
SIDE EFFECTS:	progress box is destroyed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxUnregisterReceiptThread proc	far
		uses	ds, di
		.enter
		call	MainThreadFindCurrentThread
		call	MainThreadDestroy
		.leave
		ret
MailboxUnregisterReceiptThread endp


InboxFetch	ends
