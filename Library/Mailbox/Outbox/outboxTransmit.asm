COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox -- Message Transmission
FILE:		outboxTransmit.asm

AUTHOR:		Adam de Boor, May  2, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 2/94		Initial revision


DESCRIPTION:
	Functions to perform actual message transmission.
		
    MCA_CANCEL_NONE	User didn't cancel anything.
    
    MCA_CANCEL_MESSAGE	An error other than lost-connection happened when 
			sending the message, so just bail on the one message,
			not the entire batch or queue.

    MCA_CANCEL_CONNECT	Just close the connection and ignore the rest of the 
			batch for the current address.
    
    MCA_CANCEL_ALL	Close the connection and dequeue *all* messages queued 
			for this thread, whether part of the current by-address
			batch or just waiting for their address to be made the
			current destination.

	$Id: outboxTransmit.asm,v 1.1 97/04/05 01:21:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Transmit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrMain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to transmit messages that have been queued in a DBQ
		allocated for this thread.

CALLED BY:	OTCreateThread via ThreadCreate
PASS:		ds, es	= mailbox library's dgroup
RETURN:		cx	= exit code
		^ldx:bp	= OD for MSG_META_ACK
		si	= value to pass in BP for MSG_META_ACK
DESTROYED:	everything
SIDE EFFECTS:	OutboxThreadData deleted and OTD_dbq destroyed before exit

PSEUDO CODE/STRATEGY:
	- setup local frame & set cancelFlag offset variable in dgroup
	- create progress box
	- allocate tal ID for actual transmission
	- store progress box & transmit talID in thread data block
	- load transport driver
	- while there are still messages in the queue (plock data block, then
	  check queue contents. if empty, remove thread entry from data
	  structure, delete the queue, release the block, and exit):
		- find all messages with same significant address bytes in
		  addresses with thread's talID (requires same medium token to
		  bother with comparison), storing them in yet another
		  queue, marking the addresses that match with transmit
		  tal ID.
		- call DR_MBTD_PREPARE_FOR_TRANSPORT for each message in batch
		  queue
			- if first and only message gets TRY_LATER error, notify
			  user of error, remove from thread queue & bail
			- else if TRY_LATER, adjust address tal IDs back to
			  thread's tal ID, and remove from batch queue
		- call DR_MBTD_CONNECT, passing address w/ transmit tal ID from
		  first message in the batch
		- if successful:
			- for each message:
			    - initialize progress box (DBQAddRef, send MM, xmit 
			      tal ID)
			    - initialize cancel flag
			    - call DR_MBTD_TRANSMIT_MESSAGE
			    - add log entry
			    - if successful, mark address(es) as SENT
				- if no more addresses w/thread's talID, remove
				  message from thread queue
				- if no more addresses unsent, delete message
				  from outbox
			    - else if user canceled
				- mark addresses with tal ID of 0
				- ask if entire batch should be canceled.
				- if yes, do same as for connection
				  lost & no retry.
				- if no, then loop
			    - if connection lost
				- notify user and ask if should retry.
				- if yes
					- reset all xmit tal IDs to thread's
				- if no
					- reset all xmit tal IDs to 0
				- in any case, break out of loop
			- call DR_MBTD_END_CONNECT
		- if connect unsuccessful, store reason and mark all addresses
		  with reason token (subr: mark all addresses !SENT & xmit
		  talID with reason token + set talID to 0)
		- destroy batch queue
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrFlags	record
    :4
    OTrF_CANCELED:1		; set if user cancelled a message, if so
				;	we wait before sending next batch
    OTrF_CONNECT_ERR:1		; set if error was from connection
    OTrF_PERMANENT:1		; set if error was permanent
    OTrF_CONNECTED:1		; set if thisConn is valid
OTrFlags	end

OTrMain		proc	far
.warn	-unref_local
cancelFlagPtr	local	nptr.MailboxCancelAction ; flag set by progress box and
					    ; checked by transport driver (and
					    ;  OTrSendBatch)
dbq		local	word		; thread's queue (variable used by
					;  called procedures, to avoid having
					;  to get to the thread data)
transport	local	MailboxTransport; transport for which this thread is
					;  active
if 	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
transOption	local	MailboxTransportOption
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM

driver		local	hptr		; handle of loaded transport driver
strategy	local	fptr.far	; strategy routine of driver (used by
					;  called procedures)
xmitID		local	word		; id for marking addresses being
					;  actively transmitted to
queuedID	local	word		; id with which addresses queued for
					;  this thread are marked
transCaps	local	MailboxTransportCapabilities
					; the capabilities of the loaded driver
	;
	; for OTrCreateBatch:
	; 
batchQ		local	word		; queue on which to place messages
					;  that have at least one address that
					;  matches
thisAddr	local	hptr.OutboxMatchAddr
					; address against which to compare
thisConn	local	word		; current connection (junk if thisAddr
					;  is 0)
	;
	; for OTrPrepareBatch
	;
numPreped	local	word
	;
	; for OTrSendBatch
	; 
curAddr		local	word		; index of current address
curMsg		local	MailboxMessage
reason		local	word		; token of failure reason
					;  (also used by OTrCancelMessages)
	;
	; for OTrCancelMessages
	;
cancelID	local	word

flags		local	OTrFlags	; state flags for the routine
	;
	; for OTrCancelMessagesCallback
	;
	CheckHack <width MTF_TRIES le 8>
numFailures	local	byte
futureDeadline	local	FileDateAndTime

if	_QUERY_DELETE_AFTER_PERMANENT_ERROR

deadlineExt	local	word		; hour.minute

endif	; _QUERY_DELETE_AFTER_PERMANENT_ERROR

.warn	@unref_local
		.enter
	;
	; Set everything up, please.
	;
		call	OTrSetup
		jnc	transmitLoop
	;
	; Need to cancel everything if not able to setup.
	;
		call	MainThreadFindCurrentThread
		push	di
		mov	di, ss:[dbq]		; di <- dbq, for dequeueing
   		mov	ss:[driver], 0		; signal driver not loaded
		jmp	cancelAll

transmitLoop:
	;
	; This is the main loop for transmitting messages. First, we see if
	; there are any messages in the queue. Grab control of MainThreads
	; so we're sure no one is adding messages to our queue while we're
	; checking and possibly going away.
	; 
		call	MainThreadFindCurrentThread ;ds:di = OutboxThreadData
EC <		ERROR_C TRANSMIT_THREAD_DATA_HAS_VANISHED		>

getFirstTransport::		; _TRANSMIT_THREADS_KEYED_BY_MEDIUM
		push	di			; save for transmitDone to
						;  pop
		mov	di, ds:[di].OTD_dbq
		call	MailboxGetAdminFile

if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
	;
	; Make sure the proper transport driver is loaded for the first message
	; in the queue.
	;
		call	OTrMaybeLoadNewTransportDriver
		pop	di
		jc	getFirstTransport	; => couldn't load; all messages
						;  for the transport have been
						;  dequeued, so just loop to
						;  find the next transport we
						;  *can* load.
 if	MAILBOX_PERSISTENT_PROGRESS_BOXES
 		jne	transmitLoop		; => need to recheck to make
						;  sure the same first message
						;  is around, as we unlocked
						;  the MainThreads block
 endif

		push	di
		mov	di, ds:[di].OTD_dbq
		call	MailboxGetAdminFile
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM

		call	OTrFindSendableMessage	; ax <- address to match
						;  Removes messages w/no
						;  queued addresses from dbq...
		mov	ss:[thisAddr], ax
		jc	transmitDone		; => no sendable messages
		inc	sp			; clear OTD offset
		inc	sp
		call	MainThreadUnlock

batchLoop:
		call	OTrMakeAndSendBatch
		jc	cancelConnect

		test	ss:[flags], mask OTrF_CONNECTED
		jz	transmitLoop		; => don't want another batch
						;  for current connection as
						;  there is none
		jmp	batchLoop

cancelConnect:
	;
	; User canceled everything we were doing and possibly everything we 
	; will do.
	;
	; If just canceling the batch, then reset the talIDs marked with the
	; xmitID back to 0 and go back to create a new batch.
	;
	; If canceling everything, also reset the talIDs marked with the
	; queuedID back to 0 and exit the thread.
	; 
		call	MainThreadFindCurrentThread
		
		push	di
		mov	cx, ss:[xmitID]
		mov	ss:[cancelID], cx
		mov	di, ss:[dbq]
		call	OTrCancelMessages

		cmp	ax, MCA_CANCEL_ALL
		je	cancelAll
	;
	; Just canceling that batch. Release the thread data and go look for
	; another batch to send.
	; 
		pop	di			; clear OutboxThreadData off
		call	MainThreadUnlock
		jmp	transmitLoop

cancelAll:
		mov	cx, ss:[queuedID]
		mov	ss:[cancelID], cx
		call	OTrCancelMessages

transmitDone:
	;
	; Call the transport driver's DONE_WITH_TRANSPORT function for all
	; remaining messages in the queue, in case it had been called to
	; prepare them. NOTE: This means it's possible to receive a
	; DONE_WITH_TRANSPORT call without ever having received a
	; PREPARE_FOR_TRANSPORT. The driver will just have to live with it.
	; 
	; di = dbq
	;
		call	MailboxGetAdminFile
		call	OTrFindSendableMessage	; this should remove everything
						;  from the queue, since
						;  nothing should be left
						;  sendable, it all having been
						;  canceled or removed
EC <		ERROR_NC SENDABLE_MESSAGE_REMAINS_ON_QUEUE		>
		pop	di			; ds:di <- OutboxThreadData
	;
	; We've done all we're going to do, so get the heck out.
	; 
		mov	bx, ss:[driver]
		tst	bx
		jz	nukeThread
		call	MailboxFreeDriver
nukeThread:
		.leave
	;
	; Destroy the queue and remove the thread data, releasing the
	; MainThreads block. Also destroys the progress box.
	; 
		call	OTExitThread
		clr	si
	;
	; Remove cancel flag from the stack at stackBot before we return.
	;
		sub	ss:[TPD_stackBot], size word
		ret
OTrMain		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do all the random setup work needed before we can get down
		to the real business of sending messages.

CALLED BY:	(INTERNAL) OTrMain
PASS:		ss:bp	= inherited frame
RETURN:		carry set on error
		carry clear if ok:
			flags		= 0
			thisAddr	= 0
			cancelFlagPtr	= location at stack bottom for cancel
					  flag
			*cancelFlagPtr	= MCA_CANCEL_NONE
			xmitID		= set
			queuedID	= copied from OTD
			dbq		= copied from OTD
			transport	= set to invalid value if keyed by
					  medium
			driver, transCaps, strategy = set if NOT keyed by
						      medium
			driver		= 0 if keyed by medium

			progress box created, if necessary
			progress box setup, if not keyed by medium
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrSetup	proc	near
		.enter	inherit	OTrMain
		mov	ss:[flags], 0		; not connected, and no error
						;  to start with.
	;
	; Why not put the cancel flag into the OutboxThreadData structure?
	; Because then it couldn't be checked quickly by the transport driver.
	; 
		mov	ax, ss:[TPD_stackBot]
		inc	ax
		inc	ax
		xchg	ax, ss:[TPD_stackBot]
		mov	ss:[cancelFlagPtr], ax
		mov	bx, ax
		mov	{MailboxCancelAction}ss:[bx], MCA_CANCEL_NONE

		call	MainThreadFindCurrentThread
		movdw	ds:[di].MTD_cancelFlag, ssax
		call	MainThreadUnlock
		
		mov	ss:[thisAddr], 0	; Signal no address yet.
	;
	; Create the progress box, and allocate a talID for marking addresses
	; to be actively transmitted. Stuff both things into the OTD for this
	; thread.
	; 
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		call	OTrCreateProgressBox	; ^lbx:si <- progress box
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

		call	AdminAllocTALID		; ax <- talID

		mov	ss:[xmitID], ax		; for handy access...

		call	MainThreadFindCurrentThread	; ds:di <- OTD
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		movdw	ds:[di].OTD_meta.MTD_progress, bxsi
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
		mov	ds:[di].OTD_xmitID, ax
		mov	ax, ds:[di].OTD_queuedID
		mov	di, ds:[di].OTD_dbq
		mov	ss:[dbq], di
		mov	ss:[queuedID], ax	; for handy access...
		call	MainThreadUnlock	; keep thread data locked as
						;  little as possible...


if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
	;
	; Initialize transport variables so we don't think anything's loaded.
	;
		mov	ss:[transport].MT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[transport].MT_id, GMTID_LOCAL
		mov	ss:[driver], 0
else 	; !_TRANSMIT_THREADS_KEYED_BY_MEDIUM
	;
	; Get transport and load the driver.
	; 
		call	MailboxGetAdminFile	; ^vbx:di <- thread queue
		mov	cx, ax			; cx = queued talID
		mov	si, TRUE		; si <- call OTrDequeue to
						;  remove message, please
		call	OTQGetFirstTransport	; cxdx <- transport from first
						;  	  queued message
						;  bx <- transport option
EC <		ERROR_C	TRANSMIT_THREAD_STARTED_WITH_NOTHING_TO_DO	>
		movdw	ss:[transport], cxdx
		call	OTrLoadTransportDriver
		jc	done
		
 if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		call	OTrSetupProgressBox
 endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM
		clc
done::
		.leave
		ret
OTrSetup	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrMakeAndSendBatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a batch of messages to send and attempt to send them.

CALLED BY:	(INTERNAL) OTrMain
PASS:		ss:bp	= inherited frame
		^vbx:di	= thread's dbq
RETURN:		ax 	= MailboxCancelAction
		carry set if cancelling connection or everything
DESTROYED:	cx, dx, si, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrMakeAndSendBatch proc near
		uses	bx, di
		.enter	inherit	OTrMain
	;
	; Initialize for cancel handling
	;
		andnf	ss:[flags], not mask OTrF_CANCELED

if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
	;
	; Wait for the medium to be available.
	;
		call	OTrWaitForMedium
		jc	maybeEndConnect
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM
	;
	; Create a queue of messages with eligible addresses that match
	; that selected by OTrFindSendableMessage, marking them with the
	; thread's xmitID
	;
		call	OTrCreateBatch		; di <- batch queue
	;
	; Call the PREPARE_FOR_TRANSPORT function for each message in the
	; batch.
	; 
		call	OTrPrepareBatch	
		mov	ax, MCA_CANCEL_CONNECT	; assume error
		jc	maybeEndConnect		; => nothing could be prepared,
						;  and everything's been marked
						;  properly.
	;
	; Attempt to connect to the destination, using the first marked address
	; from the first message of the batch (do *not* use the one returned
	; by OTrFindSendableMessage, as that message may not have been
	; preparable)
	; 
		call	OTrConnect		; si <- connection
		jc	connectErr
	;
	; Connection succeeded. Attempt to send everything.
	; 
		call	OTrSendBatch		;ax = MailboxCancelAction
	;
	; See if we should attempt to build a new batch.
	;
		test	ss:[transCaps], mask MBTC_CAN_PREPARE_WHILE_CONNECTED
		jz	endConnect		; => can't handle preparation
						;  while connected, so end
						;  the connection now
		cmp	ax, MCA_CANCEL_CONNECT
		jae	maybeEndConnect		; => wants to cancel the
						;  connection, so don't
						;  prolong it with another batch
	;
	; We want to try for a new batch. Destroy the current batch queue
	; and loop to create another batch using the address we've got
	; in ss:[thisAddr].
	;
	; (I know I could just jump back to the top, but I prefer to return
	; and let OTrMain do something)
	;
		call	DBQDestroy
		clc				; return carry clear and
		jmp	exit			;  still connected so caller
						;  will call us again.

connectErr:
	;
	; Mark all the marked messages from the batch as failed, with the
	; reason in ^lcx:dx
	;
	; We set OTrF_CONNECT_ERR so we know whether to tell the user about
	; the problem on the first failed connection for each message.
	; 
		ornf	ss:[flags], mask OTrF_CONNECT_ERR
if	_QUERY_DELETE_AFTER_PERMANENT_ERROR
		test	ax, ME_UNRECOVERABLE
		jz	storeConnectReason
		ornf	ss:[flags], mask OTrF_PERMANENT
storeConnectReason:
endif	; _QUERY_DELETE_AFTER_PERMANENT_ERROR
		call	OTrStoreReasonAndReport
		mov	ax, MCA_CANCEL_CONNECT

maybeEndConnect:
	;
	; If still connected, close down the connection, as we have nothing
	; further to send via it.
	;
		test	ss:[flags], mask OTrF_CONNECTED
		jz	freeAddrBlock
		mov	si, ss:[thisConn]	; si <- connection, in case
						;  jumped to after batch
						;  preparation...
endConnect:
		andnf	ss:[flags], not mask OTrF_CONNECTED
		push	di 			;save batch queue
		mov	di, DR_MBTD_END_CONNECT
		call	ss:[strategy]
		pop	di			;di = batch queue

freeAddrBlock:		
	;
	; If there's an address block, free it.
	;
		push	bx
		clr	bx
		xchg	ss:[thisAddr], bx
		tst	bx
		jz	addrFreed
		call	MemFree
addrFreed:
		pop	bx

	;
	; Nuke the batch queue & loop. Any updating of the thread's queue will
	; be handled by OTrFindSendableMessage, while modification of the 
	; outbox itself was handled by OTrSendBatch
	; 
		call	DBQDestroy
	;
	; Return carry set if cancel_connect or higher
	;
		cmp	ax, MCA_CANCEL_CONNECT
		cmc
exit:
		.leave
		ret
OTrMakeAndSendBatch endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrWaitForMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the medium is available, waiting for it to become
		so if it's not.

CALLED BY:	(INTERNAL) OTrMakeAndSendBatch
PASS:		nothing
RETURN:		carry set if medium not available:
			ax	= MailboxCancelAction
		carry clear if can create batch:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Ideally this would call OMCheckConnectable to cope with
		    the thing being connected somewhere else outside this
		    transmission thread. However, because of the way responder
		    works, where vsser tells us it's connected even if there's
		    no phone call active, we need to check just that the
		    medium's available.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/13/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
OTrWaitForMedium proc	near
		uses	ds, di, bx, es, cx, dx, si
		.enter	inherit	OTrMain
	;
	; See if the medium's connectable to the selected address.
	;
checkMedium:
		call	MainThreadFindCurrentThread
EC <		ERROR_C	TRANSMIT_THREAD_DATA_HAS_VANISHED		>
	;
	; Lock down the address block for the comparison(s).
	;
		mov	bx, ss:[thisAddr]
		call	MemLock
		mov	es, ax

		mov	ax, es:[OMA_medium]
		movdw	cxdx, es:[OMA_transport]
		mov	si, es:[OMA_transOption]
		push	di
		mov	di, offset OMA_addrLen
		call	OMCheckConnectable
		pop	di
		call	MemUnlock
		jc	doneOK
	;
	; It's not -- signal we're waiting and block on the OTD_mediaSem
	;
		mov	ds:[di].OTD_waiting, TRUE
		mov	bx, ds:[di].OTD_mediaSem
		call	MainThreadUnlock
		call	ThreadPSem
	;
	; See if we were canceled somehow.
	;
		mov	bx, ss:[cancelFlagPtr]
		mov	ax, ss:[bx]
		tst_clc	ax
		jz	checkMedium		; => we weren't, so make sure
						;  the medium's actually
						;  available (being paranoid)
	;
	; We were canceled -- return the extent and carry set.
	;
		stc
done:
		.leave
		ret
doneOK:
	;
	; Release the thread block since we're sure the medium exists.
	;
		call	MainThreadUnlock
		clc
		jmp	done
OTrWaitForMedium endp
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrMaybeLoadNewTransportDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the transport we'll need to use for the next batch
		and make sure that driver is loaded.

CALLED BY:	(INTERNAL) OTrMain
PASS:		^vbx:di	= thread's queue
		ss:bp	= inherited frame
		ds	= locked & owned MainThreads block
RETURN:		carry set if couldn't load the driver
		carry clear if we could:
			ss:[driver], ss:[transCaps], ss:[transport],
			ss:[transOption] all set for the current driver
			
			zero flag set if using same driver as before
			zero flag clear if loaded a different driver:
				if using progress boxes:
					MainThreads block is unlocked
					ds = destroyed
					
DESTROYED:	ax, bx, cx, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
OTrMaybeLoadNewTransportDriver proc	near
		.enter	inherit	OTrMain
	;
	; Get the token for the transport of the first message.
	;
		mov	cx, ss:[queuedID]
		mov	si, TRUE		; si <- call OTrDequeue to
						;  remove message, please
		call	OTQGetFirstTransport
	;
	; The descriptors of messages sent by the previous transport have been
	; freed, so sync the admin file now.
	;
		call	UtilUpdateAdminFile

		lahf
		ornf	ah, mask CPU_ZERO	; in case no more messages,
						;  return with ZF set so caller
						;  knows we didn't switch
						;  drivers.
		sahf
		cmc				; (smaller than xoring bit
						;  in AH)
		jnc	done
	;
	; See if it's the one we've already got loaded.
	;
		tst	ss:[driver]
		jz	unloadOldDriver
		CmpTok	ss:[transport], cx, dx
		je	done			; => same as last time

unloadOldDriver:
	;
	; It's not. Record the new details.
	;
		Assert	bitClear, ss:[flags], OTrF_CONNECTED
		movdw	ss:[transport], cxdx	; store transport driver token
						;  away for later use
		mov	ss:[transOption], bx
	    ;
	    ; Unload the previous driver, if it was loaded.
	    ;
		clr	bx
		xchg	ss:[driver], bx
		tst	bx
		jz	loadNewDriver
		call	MailboxFreeDriver

loadNewDriver:
	;
	; Now load the new one.
	;
		call	OTrLoadTransportDriver
		jc	done

 if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		call	MainThreadUnlock	; release the thing so
						;  OTrSetupProgressBox can
						;  find the info again
		call	OTrSetupProgressBox
		or	al, 1			; return CF and ZF clear so
						;  caller will loop again,
						;  making sure the first message
						;  hasn't been canceled while
						;  we've been fussing with the
						;  MainThread block unlocked

 endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
done:
		.leave
		ret
OTrMaybeLoadNewTransportDriver endp
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrLoadTransportDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to load the transport driver for the batch
		we're about to create.

CALLED BY:	(INTERNAL) OTrSetup, OTrMaybeLoadNewTransportDriver
PASS:		ss:bp	= inherited frame:
			  dbq	= thread's queue
		cxdx	= MailboxTransport
		di	= thread's queue
RETURN:		carry set if couldn't load:
			all messages for the transport removed from the queue
			bx	= destroyed
		carry clear if ok:
			bx	= handle of the driver
			ax	= MailboxTransportCapabilities of driver
			driver, transCaps, strategy = set
DESTROYED:	nothing
SIDE EFFECTS:	messages canceled if for transport that can't be loaded.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrLoadTransportDriver proc	near
		uses	cx, dx, si
		.enter	inherit	OTrMain
		call	UtilLoadTransportDriverWithError
		jc	nukeMessages
	;
	; Record the strategy and capabilities of the new driver.
	;
		mov	ss:[driver], bx
		push	ds
		call	GeodeInfoDriver
		movdw	ss:[strategy], ds:[si].DIS_strategy, ax
		mov	ax, ds:[si].MBTDI_capabilities
		mov	ss:[transCaps], ax
		pop	ds
		clc
done:
		.leave
		ret

nukeMessages:
	;
	; Iterate over the messages in the queue removing the ones that
	; use the transport we couldn't load.
	;
	; We don't call OTrDequeue because that would only try to load the
	; transport again.
	;
	; We don't call DBQEnum because we can't remove items from within
	; the callback.
	; 
		call	MailboxGetAdminFile
		clr	cx
		ornf	ss:[flags], mask OTrF_PERMANENT
msgLoop:
		call	DBQGetItemNoRef		; dxax <- message to examine
		jc	done
	;
	; See if the message is for this transport.
	;
		push	di, ds			; save DBQ
		call	MessageLock
		mov	si, ds:[di]
		cmpdw	ds:[si].MMD_transport, ss:[transport], cx
		call	UtilVMUnlockDS
		pop	di, ds
		jne	nextMsg
	;
	; Uses the transport, so cancel it and remove it.
	;
		push	ax, cx, dx, di
		movdw	ss:[curMsg], dxax
		movdw	sidi, dxax
		mov	cx, handle uiCannotLoadDriverStr
		mov	dx, offset uiCannotLoadDriverStr
		call	OTrStoreReason		; (overwrites cancelID)
		mov	ax, ss:[queuedID]
		mov	ss:[cancelID], ax
		call	OTrCancelMessagesCallback
		pop	ax, cx, dx, di
		call	DBQRemove
		dec	cx			; decrement so increment leaves
						;  us at the next message,
						;  since we've removed the
						;  current one
nextMsg:
		inc	cx
		jmp	msgLoop
OTrLoadTransportDriver endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrCancelMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel (i.e. set MITA_addrList to 0) any address in
		the given queue marked with the given talID -- the transmit
		of the message has been canceled

CALLED BY:	(INTERNAL) OTrMain
PASS:		di	= DBQ
		ss:bp	= inherited frame
		ss:[cancelID]	= talID
		ss:[reason]	= reason for cancelation
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrCancelMessages proc	near
		uses	bx, cx, dx, ax
		.enter
		call	MailboxGetAdminFile
		mov	cx, SEGMENT_CS
		mov	dx, offset OTrCancelMessagesCallback
		call	DBQEnum
		.leave
		ret
OTrCancelMessages endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrCancelMessagesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to mark any addresses for the given message
		that are marked with the given ID as not being transmitted.

CALLED BY:	(INTERNAL) OTrCancelMessages via DBQEnum,
			   OTrCancelCurrentMessage
PASS:		sidi	= message
		ss:bp	= inherited frame
		ss:[cancelID] = talID for which to search
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	si, di, cx
SIDE EFFECTS:	if the message is past its deadline, the deadline is
     			extended by some amount.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 6/94		Initial version
	ardeb	10/19/94	Removed marking with ss:[reason] since the
				only way ss:[reason] could have been set was
				if OTrStoreReason had been called, which would
				have marked everything our marking was marking.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrCancelMessagesCallback proc	far
		uses	dx, ax, bx, ds
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
		movdw	dxax, sidi	; dxax <- message
		movdw	ss:[curMsg], dxax
	;
	; Then set their address marks to 0, to dequeue them.
	; 
		mov	cx, ss:[cancelID]; cx <- mark to look for
		clr	si		; start from first addr
		pushdw	dxax		; save MailboxMessage
		call	OUFindNextAddr	; *ds:di = MMD, ds:si = MITA
		LONG jc	popDone		; => no address was so marked, but
					;  that's fine, as we might be canceling
					;  the connection...
		mov	ss:[curAddr], ax
		mov	cl, ds:[si].MITA_flags
		andnf	cl, mask MTF_TRIES	; cl = # of failures
		mov	ss:[numFailures], cl
		tst	ss:[driver]
		jz	useDefault		; => driver couldn't be loaded
		push	di			; save MMD lptr
		mov	di, DR_MBTD_ESC_GET_DEADLINE_EXTENSION
		call	ss:[strategy]	; ch/cl = hrs/mins of extension
		pop	di			; *ds:di = MMD
		jnc	getFutureDeadline	; jump if escape supported
useDefault:
		mov	cx, OUTBOX_DEADLINE_EXTENSION

getFutureDeadline:
if	_QUERY_DELETE_AFTER_PERMANENT_ERROR
		mov	ss:[deadlineExt], cx
endif	; _QUERY_DELETE_AFTER_PERMANENT_ERROR

		call	UtilGetFutureFileDateTime  ; dxax = FileDateAndTime
		movdw	ss:[futureDeadline], dxax
		popdw	dxax		; dxax = MailboxMessage
		mov	cx, ss:[cancelID]
		clr	si		; si <- new mark
		mov	bx, (MACT_EXISTS shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		call	OTQChangeAddressMarks
		mov	si, ds:[di]

if	_QUERY_DELETE_AFTER_PERMANENT_ERROR
	;
	; If permanent error, put up a dialog to ask if the user wants to
	; retry.  We need to add one ref to the message first.
	;
		cmp	ss:[numFailures], MAX_TEMPORARY_ERRORS
		jae	notifyError
		test	ss:[flags], mask OTrF_PERMANENT
		jz	tempError

notifyError:
	;
	; Set the retry time to eternity, so that we won't retry until the
	; user presses "Retry" and we set a new retry time.
	;
		movdw	ds:[si].MMD_autoRetryTime, MAILBOX_ETERNITY

		call	MailboxGetAdminFile	; ^vbx = admin file
		call	DBQAddRef		; add 1 ref for dialog
		push	bp			; save frame ptr
		mov	bx, handle MailboxApp
		mov	si, offset MailboxApp
			CheckHack <OERSMA_delay eq OERSetMessageArgs-2>
		push	ss:[deadlineExt]	; push OERSMA_delay
			CheckHack <OERSMA_reason eq OERSetMessageArgs-4>
		push	ss:[reason]		; push OERSMA_reason
			CheckHack <OERSMA_addr eq OERSetMessageArgs-6
		push	ss:[curAddr]
			CheckHack <OERSMA_message eq OERSetMessageArgs-10>
		pushdw	dxax			; push OERSMA_message
			CheckHack <OERSMA_message eq 0>
		mov	ax, MSG_MA_OUTBOX_NOTIFY_ERROR_RETRY
		mov	bp, sp			; ss:bp = OERSetMessageArgs
		mov	dx, size OERSetMessageArgs
		mov	di, mask MF_STACK
		call	ObjMessage
		add	sp, dx			; pop OERSetMessageArgs
		pop	bp			; restore frame ptr
		jmp	done


tempError:
endif	; _QUERY_DELETE_AFTER_PERMANENT_ERROR

if	_CONFIRM_AFTER_FIRST_FAILURE
	;
	; If it's the first error and during connection, put up
	; OutboxConfirmation dialog.
	;
		cmp	ss:[numFailures], 1
		jne	extendBound
		test	ss:[flags], mask OTrF_CONNECT_ERR
		jz	extendBound

		call	MailboxGetAdminFile
		call	DBQAddRef
		MovMsg	cxdx, dxax
		mov	ax, MSG_MA_OUTBOX_CONFIRMATION
		push	bp
		clr	bp			; TalID = 0
		call	UtilSendToMailboxApp
		pop	bp

extendBound:
endif	; _CONFIRM_AFTER_FIRST_FAILURE

if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; Store the retry time.
	;
		movdw	dxax, ss:[futureDeadline]
		movdw	ds:[si].MMD_autoRetryTime, dxax
	;
	; We clear the MIMF_NOTIFIED_TRANS_WIN_OPEN anyway, even if we may
	; also be clearing MIMF_NOTIFIED_TRANS_WIN_CLOSE later when we find
	; that the deadline has already passed.  The code to initiate the send
	; when time is reached should be checking the end-bound first.
	;
		BitClr	ds:[si].MMD_flags, MIMF_NOTIFIED_TRANS_WIN_OPEN
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

	;
	; If the message is past its deadline, extend the deadline by
	; the amount obtained from the transport driver.
	; 
		call	TimerGetFileDateTime
		cmp	ax, ds:[si].MMD_transWinClose.FDAT_date
		jne	afterCmp
		cmp	dx, ds:[si].MMD_transWinClose.FDAT_time
afterCmp:
if	_AUTO_RETRY_AFTER_TEMP_FAILURE
		jb	setAppTimer	; set the app timer with the auto-retry
					;  time
else
		jb	dirty		; no need to set timer
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

	;
	; Extend the deadline.
	;
		movdw	dxax, ss:[futureDeadline]
		mov	ds:[si].MMD_transWinClose.FDAT_time, dx
		mov	ds:[si].MMD_transWinClose.FDAT_date, ax
		BitClr	ds:[si].MMD_flags, MIMF_NOTIFIED_TRANS_WIN_CLOSE

if	_AUTO_RETRY_AFTER_TEMP_FAILURE
setAppTimer:
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; Need to adjust the real-time timer, possibly, so we and the machine
	; get woken up at this new deadline, if nothing else of interest
	; is scheduled between now and then.
	; 
		movdw	dxcx, ss:[futureDeadline]  ; dxcx = FileDateAndTime
		mov	ax, MSG_MA_START_NEXT_EVENT_TIMER
		call	UtilSendToMailboxApp
if	not _AUTO_RETRY_AFTER_TEMP_FAILURE
dirty:
endif	; not _AUTO_RETRY_AFTER_TEMP_FAILURE
		call	UtilVMDirtyDS

if	_QUERY_DELETE_AFTER_PERMANENT_ERROR
done:
endif	; _QUERY_DELETE_AFTER_PERMANENT_ERROR

		call	UtilVMUnlockDS
exit:
		clc
		.leave
		ret
popDone:
		popdw	axax		; restore stack
		jmp	exit
OTrCancelMessagesCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrFindSendableMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first message in the thread's queue that has
		an address queued for us.

CALLED BY:	(INTERNAL) OTrMain
PASS:		ss:bp	= inherited frame
		^vbx:di	= thread's DBQ
		Exclusive access to thread data
RETURN:		carry set if no sendable messages
			ax	= 0
		carry clear if got one:
			^hax	= OutboxMatchAddr
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrFindSendableMessage proc	near
		uses	bx, cx, dx, si, ds
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
messageLoop:
	;
	; Get the first item from the queue.
	; 
		clr	cx
		call	DBQGetItemNoRef
		jc	empty		; => queue is empty
	;
	; Lock down the first message and look for an address marked with the
	; thread's queued talID
	; 
		push	di
		push	ax, bx
		call	MessageLock	; *ds:di <- message
		push	di
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		mov	cx, ss:[queuedID]
		mov	bx, cs
		mov	di, offset OTrFindSendableMessageCallback
		call	ChunkArrayEnum	; cx <- index, if CF=1
		pop	di		; *ds:di <- message
		pop	ax, bx
		jc	haveMessage
	;
	; No address queued for this thread, so remove the message from the
	; queue.
	;
		call	UtilVMUnlockDS
		pop	di		; ^vbx:di <- queue
		call	OTrDequeue
		jmp	messageLoop

empty:
		mov	ax, 0		; return ax = 0 w/o biffing carry
		jmp	done

haveMessage:
	;
	; We've got a first message that has an address queued for this
	; thread. Build an OutboxMatchAddr from the address.
	;
		mov_tr	ax, cx
		push	di			; save message
		call	ChunkArrayElementToPtr	; ds:di <- MITA
	    ;
	    ; Compute the size of block to allocate and allocate it.
	    ;
		mov	ax, ds:[di].MITA_opaqueLen
		add	ax, size OutboxMatchAddr
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
	    ;
	    ; Copy the entire opaque address into the block.
	    ;
		mov	es, ax
		mov	cx, ds:[di].MITA_opaqueLen
		mov	es:[OMA_addrLen], cx
		push	ds:[di].MITA_medium
		lea	si, ds:[di].MITA_opaque
		mov	di, offset OMA_address
		rep	movsb
		pop	ax			; ax <- OM token
		pop	di			; *ds:di <- MMD
	    ;
	    ; Find the number of significant address bytes and, collaterally,
	    ; record the transport and transport option for the message.
	    ;
		push	bx			; save block handle
		mov	si, ds:[di]
		movdw	cxdx, ds:[si].MMD_transport
		mov	bx, ds:[si].MMD_transOption
		movdw	es:[OMA_transport], cxdx
		mov	es:[OMA_transOption], bx
		mov	es:[OMA_medium], ax
		call	OMGetSigAddrBytes
		mov	es:[OMA_sigAddrBytes], ax
	;
	; Release the block and the message and return our happiness.
	;
		pop	bx
		call	MemUnlock
		mov_tr	ax, bx
		call	UtilVMUnlockDS
		pop	di			; di <- queue
		clc
done:
		.leave
		ret
OTrFindSendableMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrDequeue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a message from the transmit queue of the current
		thread, notifying the transport driver.

CALLED BY:	(EXTERNAL) OTrFindSendableMessage,
			   OTQGetFirstTransport
PASS:		dxax	= MailboxMessage to remove
		^vbx:di	= queue from which to remove it
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	transport driver loaded/unloaded

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrDequeue	proc	far
		uses	ds, si, cx
		.enter
		push	bx, di
	;
	; Find the transport for the message and attempt to load the driver.
	;
		push	dx, ax
		call	MessageLock
		mov	si, ds:[di]
		movdw	cxdx, ds:[si].MMD_transport
		call	UtilVMUnlockDS
		call	UtilLoadTransportDriverWithError
		pop	dx, ax
		jc	removeMessage
	;
	; Successfully loaded -- tell it we're done transporting the thing.
	;
		MovMsg	cxdx, dxax
		call	GeodeInfoDriver
		mov	di, DR_MBTD_DONE_WITH_TRANSPORT
		call	ds:[si].DIS_strategy
		MovMsg	dxax, cxdx
	;
	; Unload the driver again.
	;
		call	MailboxFreeDriver

removeMessage:
	;
	; Remove the message from the queue, finally.
	;
		pop	bx, di
		call	DBQRemove
		.leave
		ret
OTrDequeue	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrFindSendableMessageCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate an address marked as queued for
		this thread.

CALLED BY:	(INTERNAL) OTrFindSendableMessage via ChunkArrayEnum
PASS:		ds:di	= MailboxInternalTransAddr
		cx	= talID that signals address queued for this thread
RETURN:		carry set if found an address:
			cx	= index of address
			ax	= destroyed
		carry clear if not found:
			cx	= unchanged
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrFindSendableMessageCallback proc	far
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
		cmp	ds:[di].MITA_addrList, cx
		clc
		jne	done

		call	ChunkArrayPtrToElement		; ax <- elt #
		mov_tr	cx, ax
		stc
done:
		.leave
		ret
OTrFindSendableMessageCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrCreateBatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new queue of messages with addresses that are the
		same as the indicated address marked with the thread's xmit
		ID. The resulting queue is the batch of messages to be
		transmitted during this iteration of the loop.

CALLED BY:	(INTERNAL) OTrMain
PASS:		^vbx:di	= thread's DBQ
		ss:bp	= inherited frame:
			  ss:[thisAddr] = address to match
RETURN:		^vbx:di	= new batch queue, with appropriate addresses
			  marked by the xmitID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		SYNC: it shouldn't generate incorrect behaviour if another
		thread marks a matching message address as queued for this 
		thread after we've already passed over it. We will simply 
		end up transmitting the message to that address in a separate
		batch. This is slightly inefficient, but not wrong, and I
		prefer to keep things locked for exclusive access as little
		as possible...
		
		- create a result queue
		- point to selected address of first message
		- enum the thread queue:
		    - if first message:
		    	- point to selected address & declare a match
		    - else:
		    	- foreach address:
			    - if queued for thread & medium is same:
			        - compare addresses
				- if match, break out of loop
		    - if match:
		        - mark matching address & its duplicates with xmit ID
			- add message to result queue
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrCreateBatch	proc	near
		uses	ds, cx, dx, es
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
	;
	; Create a queue on which to put the messages in the batch.
	; 
		call	OTCreateQueue
		mov	ss:[batchQ], ax
	;
	; Lock down the address block for the comparison(s).
	;
		push	bx
		mov	bx, ss:[thisAddr]
		call	MemLock
		mov	es, ax
		pop	bx
	;
	; Go find the messages and add them to the result queue.
	; 
		mov	cx, SEGMENT_CS
		mov	dx, offset OTrCreateBatchCallback
		call	DBQEnum
	;
	; Release the address block
	; 
		push	bx
		mov	bx, ss:[thisAddr]
		call	MemUnlock
		pop	bx
	;
	; Return the queue handle
	; 
		mov	di, ss:[batchQ]
		.leave
		ret
OTrCreateBatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrCreateBatchCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to find messages that are to be sent to
		the same address as that selected by OTrFindSendableMessage

CALLED BY:	(INTERNAL) OTrCreateBatch via DBQEnum
PASS:		bx	= VM file
		sidi	= message to check
		es:0	= OutboxMatchAddr for comparison
		ss:bp	= inherited frame
RETURN:		carry set to stop enumerating (will be set if trans driver
			allows only one message per transaction, else clear)
		cx	= non-zero
DESTROYED:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		    - if first message:
		    	- point to selected address & declare a match
		    - else:
		    	- foreach address:
			    - if queued for thread & medium is same:
			        - compare addresses
				- if match, break out of loop
		    - if match:
		        - mark matching address & its duplicates with xmit ID
			- add message to result queue
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrCreateBatchCallback proc	far
		uses	si, di, ds
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
	;
	; Lock down the message
	; 
		movdw	dxax, sidi
		call	MessageLock		; *ds:di <- message
	;
	; Run through all the message's addresses looking for ones that match.
	; 
		push	di, bx, ax
		mov	si, ds:[di]

if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
	    ;
	    ; When keyed by medium, we must also make sure the message is
	    ; for the same transport...
	    ;
		cmpdw	ds:[si].MMD_transport, es:[OMA_transport], bx
		jne	noMatch
		mov	bx, ds:[si].MMD_transOption
		cmp	es:[OMA_transOption], bx
		je	checkAddresses
noMatch:
		clc
		jmp	popDone
checkAddresses:
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM
		
		mov	si, ds:[si].MMD_transAddrs
		mov	bx, cs
		mov	di, offset OTrCreateBatchFindMatchCallback
		call	ChunkArrayEnum	; ds:cx <- matching addr, if CF=1
popDone::			; _TRANSMIT_THREADS_KEYED_BY_MEDIUM
		pop	di, bx, ax
		jc	haveAddress
	;
	; No address matches, so ignore the message, returning carry clear
	; to continue enumerating.
	;
		call	UtilVMUnlockDS
		jmp	done

haveAddress:

		mov	si, cx		; ds:si <- matching address

	;
	; We found a match. Mark it and all its duplicates as needing
	; transmission. 
	;
	; ds:si	= matching address
	; *ds:di = MMD
	; dxax	= MailboxMessage
	; 
		xchg	si, di		; ds:di <- match
		mov	si, ds:[si]	; *ds:si <- trans addr array...
		mov	si, ds:[si].MMD_transAddrs	; ...eventually :)
		push	ax		; save MM.low
ife	_DUPS_ALWAYS_TOGETHER
		push	dx
		mov	dx, ss:[queuedID]
endif	; !_DUPS_ALWAYS_TOGETHER

markLoop:
	;
	; Mark the address at ds:di for transmission.
	; 
ife 	_DUPS_ALWAYS_TOGETHER
	    ;
	    ; If duplicates don't always travel in packs, we have to make sure
	    ; this duplicate has been queued before we mark it for transmission
	    ;
		cmp	ds:[di].MITA_addrList, dx
		jne	markNext
endif	; !_DUPS_ALWAYS_TOGETHER

		mov	ax, ss:[xmitID]
		mov	ds:[di].MITA_addrList, ax

ife	_DUPS_ALWAYS_TOGETHER
markNext:
endif	; !_DUPS_ALWAYS_TOGETHER

	;
	; Advance to the next duplicate.
	; 
		mov	ax, ds:[di].MITA_next
				CheckHack <MITA_NIL eq -1>
		inc	ax
		jz	addMessage	; => no more dups
	    ;
	    ; Point to the next duplicate and loop
	    ;
		dec	ax
		call	ChunkArrayElementToPtr
		jmp	markLoop

addMessage:
	;
	; All addresses suitably marked. Now add the message to the batch queue.
	; 
ife	_DUPS_ALWAYS_TOGETHER
		pop	dx
endif	; !_DUPS_ALWAYS_TOGETHER

		pop	ax		; dxax <- message
		mov	di, ss:[batchQ]
		call	DBQAdd
	;
	; Changed at least one address, so dirty the block holding the message
	; 
		call	UtilVMDirtyDS
	;
	; Release the message
	; 
		call	UtilVMUnlockDS
		test	ss:[transCaps], mask MBTC_SINGLE_MESSAGE ; (clears CF)
		jz	done			; => keep enumerating
	;
	; There's only one message allowed per transaction, so stop enumerating
	; now and get on with the business of sending the selected message.
	;
		stc
done:
		.leave
		ret
OTrCreateBatchCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrCreateBatchFindMatchCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to see if an address for a message
		matches that selected from the first message for the batch.

CALLED BY:	(INTERNAL) OTrCreateBatchCallback via ChunkArrayEnum
PASS:		ds:di	= MailboxInternalTransAddr
		ss:bp	= inherited frame
RETURN:		carry set if address matches:
			ds:cx	= MailboxInternalTransAddr
		carry clear if doesn't match
			cx	= destroyed
DESTROYED:	bx, si, di allowed, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrCreateBatchFindMatchCallback proc	far
		uses	es
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
	;
	; Make sure the thing is queued...
	; 
		mov	ax, ss:[queuedID]
		cmp	ds:[di].MITA_addrList, ax
		jne	noMatch

EC <			CheckHack <MAS_SENT eq 0>			>
EC <		test	ds:[di].MITA_flags, mask MTF_STATE		>
EC <		ERROR_Z	WHY_IS_ADDR_LIST_NON_ZERO_WHEN_ADDRESS_HAS_BEEN_SENT>

	;
	; Point to the two addresses. Note that we don't have an actual
	; MailboxInternalTransAddr to point es:di to, but we have the
	; medium, length, and data fields in the same order as in that
	; structure, and those are the only fields OUCompareAddresses uses.
	; So we point es:di at the fake beginning of the structure.
	; 
		CheckNextField OMA_addrLen, OMA_medium
		CheckNextField MITA_opaqueLen, MITA_medium
		
		CheckNextField OMA_address, OMA_addrLen
		CheckNextField MITA_opaque, MITA_opaqueLen

		mov	si, di
		mov	di, offset OMA_medium - offset MITA_medium
	;
	; See if the addresses use the same medium. If not, they can't match
	; 
		mov	ax, ds:[si].MITA_medium
		cmp	es:[OMA_medium], ax
		jne	noMatch
	;
	; They use the same medium -- now compare the addresses themselves.
	; 
		push	bp
		mov	bp, es:[OMA_sigAddrBytes]
		call	OUCompareAddresses
		pop	bp
		je	match
noMatch:
		clc
done:
		.leave
		ret
match:
		mov	cx, si
		stc			; can stop enumerating, as other
					;  duplicates are linked to this
					;  address.
		jmp	done
OTrCreateBatchFindMatchCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrPrepareBatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the transport driver to prepare each message in the
		batch.

CALLED BY:	(INTERNAL) OTrMain
PASS:		^vbx:di	= batch queue
		ss:bp	= inherited frame
RETURN:		carry set if no message could be prepared
		carry clear if at least one message set to be sent
DESTROYED:	nothing
SIDE EFFECTS:	addresses for messages that couldn't be prepared will be
     			marked with thread's queuedID if driver said to retry
			and at least one message had been prepared already,
			else the addresses are marked with 0, effectively
			dequeueing them

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrPrepareBatch proc	near
		uses	cx, dx, ax, si
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
		clr	cx
		mov	ss:[numPreped], cx	; re-use, recycle :) 
msgLoop:
	;
	; Get the next element of the batch queue.
	; 
		call	DBQGetItemNoRef
		jc	done

		movdw	ss:[curMsg], dxax
		clr	ss:[curAddr]
addrLoop:
		push	cx, di
		mov	cx, ss:[xmitID]
		mov	si, ss:[curAddr]
		mov	ax, ss:[curMsg].low	; dxax <- MailboxMessage
		call	OUFindNextAddr		; ds:si <- MITA, ax <- index
		pop	cx, di
		jc	addrsDone
		mov	ss:[curAddr], ax
		push	di, bx
		call	OTrPrepareMessage
		mov_tr	ax, bx			; ax <- error code
		pop	di, bx
		call	UtilVMUnlockDS		; flags preserved
		inc	ss:[curAddr]
		jnc	addrLoop
		jmp	preparationFailed
addrsDone:
	;
	; Success! Note that another message was properly prepared.
	; 
		inc	ss:[numPreped]		; another message prepared
		inc	cx			; go to the next entry in the
						;  queue
		jmp	msgLoop
done:
	;
	; Return carry set if no message could be prepared.
	; 
		tst_clc	ss:[numPreped]
		jnz	exit
canceled::
		stc
exit:
		.leave
		ret

preparationFailed:
	;
	; Figure out why the preparation failed. If the message is simply
	; unsendable, we will cancel the transmit and tell the user that.
	;
	; If the message couldn't be prepared and we've not prepared anything
	; else yet, we assume we won't be able to prepare the message until
	; the user frees up some disk space, so we again cancel the transmit
	; and tell the user of this.
	;
	; If the driver said to retry and we've actually already prepared one
	; message, we change the transmit addrs back to queued addrs so the
	; message will be retried later.
	;
	; First we need to store the reason for the beast.
	; 
		push	cx
		mov	cx, handle uiCouldntPrepareReason
		mov	dx, offset uiCouldntPrepareReason
		call	OTrStoreReasonAndReport
		pop	cx

		ornf	ss:[flags], mask OTrF_PERMANENT
		mov	si, offset uiMessageUnsendable
		cmp	ax, MBTDPE_UNSENDABLE
		je	dequeue

		andnf	ss:[flags], not mask OTrF_PERMANENT
		cmp	ax, MBTDPE_USER_CANCELED
		je	cancel			; don't tell the user anything
						;  since s/he was the one to
						;  cancel it.
		mov	si, offset uiNotEnoughDiskSpace
		tst	ss:[numPreped]		; anything prepared yet?
		jz	dequeue			; no -- can't be prepared now

		mov	ax, ss:[queuedID]	; yes -- requeue the message
		jmp	revert

if _QUERY_DELETE_AFTER_PERMANENT_ERROR
cancel:
		ornf	ss:[flags], mask OTrF_CANCELED
dequeue:
	;
	; In this case we use the usual message-cancelation routine, rather
	; than a special routine in the application, as cancelation allows
	; the user to delete the message if there was a permanent error.
	;
		push	cx, di
		mov	ax, ss:[xmitID]
		mov	ss:[cancelID], ax
		movdw	sidi, ss:[curMsg]
		call	OTrCancelMessagesCallback
		pop	cx, di
		movdw	dxax, ss:[curMsg]
		call	DBQRemove
		jmp	msgLoop
else ;!_QUERY_DELETE_AFTER_PERMANENT_ERROR
dequeue:
	;
	; Call (do not send) our application object to tell the user the thing
	; is unsendable. We need to call and pass the xmitID so the moniker-
	; generation code knows what addresses to tell the user about.
	; Immediately afterwards, however, we need to mark those addresses as
	; neither queued nor transmitting, thus the need to call, not send.
	; 
		movdw	dxax, ss:[curMsg]
		call	DBQAddRef
		push	cx, di, bp
			CheckHack <MANUA_message eq 6>
		pushdw	dxax
		mov	ax, handle ROStrings
			CheckHack <MANUA_string eq 2>
		pushdw	axsi
			CheckHack <MANUA_talID eq 0>
		push	ss:[xmitID]
			CheckHack <size MANotifyUnsendableArgs eq 10>
		mov	dx, size MANotifyUnsendableArgs
		mov	bp, sp
		mov	ax, MSG_MA_NOTIFY_UNSENDABLE
		mov	di, mask MF_STACK
		call	UtilCallMailboxApp
		add	sp, size MANotifyUnsendableArgs
		pop	cx, di, bp
		jmp	short cancelDequeueCommon

cancel:
		ornf	ss:[flags], mask OTrF_CANCELED
cancelDequeueCommon:
		clr	ax		; set addrList's to 0
endif	; !_QUERY_DELETE_AFTER_PERMANENT_ERROR

revert:
	;
	; Change all the addresses of the current message that are marked
	; with xmitID to be marked with ax instead.
	; 
		mov_tr	si, ax
		movdw	dxax, ss:[curMsg]
		push	cx, bx

ife	_QUERY_DELETE_AFTER_PERMANENT_ERROR
		mov	bx, (MACT_EXISTS shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		tst	si		; canceling message?
		jz	changeMarks	; => yes
endif	; !_QUERY_DELETE_AFTER_PERMANENT_ERROR

		mov	bx, (MACT_QUEUED shl offset MABC_TYPE) or \
				mask MABC_OUTBOX	; else requeueing
changeMarks::
		mov	cx, ss:[xmitID]
		call	OTQChangeAddressMarks
		pop	cx, bx
	;
	; Remove the message from the batch.
	; 
		call	DBQRemove
		jmp	msgLoop		; removed a message, so leave the
					;  current message index alone --
					;  just loop
OTrPrepareBatch endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrPrepareMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare a single address of a message

CALLED BY:	(INTERNAL) OTrPrepareBatch
PASS:		ds:si	= MailboxInternalTransAddr
		ax	= address #
		ss:bp	= inherited frame
RETURN:		ds	= locked message block, possibly moved
		carry set if enum should stop:
			bx	= MBTDPrepareError
		carry clear if should keep going:
			bx	= destroyed
DESTROYED:	ax, si, di
SIDE EFFECTS:	driver called

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrPrepareMessage proc	near
		uses	cx, dx
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
		
if	_DUPS_ALWAYS_TOGETHER
	;
	; If transport is single-message, we don't prepare any duplicate
	; addresses; the second copy must be sent in a subsequent connection.
	;
		test	ss:[transCaps], mask MBTC_SINGLE_MESSAGE
		jz	getAddressIndex
		test	ds:[si].MITA_flags, mask MTF_DUP
		jnz	done			; (carry cleared by test)
getAddressIndex:
endif	; _DUPS_ALWAYS_TOGETHER
	;
	; Notify everyone the thing's being prepared.
	;
		andnf	ds:[si].MITA_flags, not mask MTF_STATE
		ornf	ds:[si].MITA_flags, 
				(MAS_PREPARING shl offset MTF_STATE)
		call	UtilVMDirtyDS
	;
	; It is to be transmitted. Convert the address index to an index
	; for use by the progress box and the driver and box-change
	; notification.
	; 
		push	ax, bp
		movdw	cxdx, ss:[curMsg]
		ornf	ax, (MACT_PREPARING shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		mov_tr	bp, ax
		mov	ax, MSG_MA_BOX_CHANGED
		call	UtilSendToMailboxApp
		pop	ax, bp

if	MAILBOX_PERSISTENT_PROGRESS_BOXES
	;
	; Let progress box know, if necessary.
	; 
		test	ss:[transCaps], mask MBTC_PREPARATION_NEEDS_FEEDBACK
		jz	doPrepare

		push	ax, bp
		mov_tr	bp, ax			; bp <- addr index
		MovMsg	dxax, cxdx
		mov	cx, MSG_OP_SET_PREPARING_MESSAGE
		call	OTrProgressForMessageCommon
		pop	ax, bp

doPrepare:
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

		call	OTrPrepareCallDriver
if	_DUPS_ALWAYS_TOGETHER
done:
endif	; _DUPS_ALWAYS_TOGETHER
		.leave
		ret
OTrPrepareMessage endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrPrepareCallDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actually call the driver to prepare the message

CALLED BY:	(INTERNAL) OTrPrepareMessage
PASS:		ss:bp	= inherited frame
		ds	= locked message block
		ax	= address # being prepared
RETURN:		carry set if couldn't prepare
		bx	= MBTDPrepareError
		ds	= locked message block, possibly moved
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrPrepareCallDriver proc near
		.enter	inherit OTrMain
	;
	; Arrange the registers and tell the driver to prepare the message.
        ; Release the message during the preparation, to avoid nasty
        ; synchronization hierarchy issues.
        ;
              	call    UtilVMUnlockDS
		movdw	cxdx, ss:[curMsg]
		mov	di, DR_MBTD_PREPARE_FOR_TRANSPORT
		push	ax
		call	ss:[strategy]
		pop	bx
		xchg	ax, bx		; ax <- addr # for notification
					; bx <- error code, if any
	;
	; Lock the message down so we can change the address's state.
	;
		pushf			; save any error flag
		call	MessageLockCXDX
		popf
		jc	done		; => state change will
					;  happen in caller when
					;  thing goes back to being
					;  queued or is canceled
	;
	; Change the address state to READY
	;
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		push	cx			; save msg.high
		call	ChunkArrayElementToPtr
		pop	cx
		andnf	ds:[di].MITA_flags, not mask MTF_STATE
		ornf	ds:[di].MITA_flags,
				(MAS_READY shl offset MTF_STATE)
		call	UtilVMDirtyDS
	;
	; Send notification that the thing is ready for sending.
	;
		push	bp
		ornf	ax, (MACT_READY shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		mov_tr	bp, ax
		mov	ax, MSG_MA_BOX_CHANGED
		call	UtilSendToMailboxApp
		pop	bp
		clc
done:
		.leave
		ret
OTrPrepareCallDriver endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to connect, using the first address of the first
		message marked for transmission.

CALLED BY:	(INTERNAL) OTrMain
PASS:		^vbx:di	= batch queue
		ss:bp	= inherited frame
RETURN:		carry set if failed:
			^lcx:dx	= reason for failure
			ax	= MailboxError
			curMsg  = MailboxMessage with failed address
		carry clear if connected:
			si	= connection handle
			ax	= destroyed
			curMsg  = MailboxMessage with connected address
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrConnect	proc	near
		uses	ds, di, bx, es
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
	;
	; Get the handle for the first message for setting curMsg
	;
		andnf	ss:[flags], not mask OTrF_CONNECT_ERR
		clr	cx		
		call	DBQGetItemNoRef
	; EC: if queue is empty, this should have been caught in OTrPrepareBatch
EC <		ERROR_C	NO_MESSAGES_LEFT_TO_SEND			>

		movdw	ss:[curMsg], dxax

if	MAILBOX_PERSISTENT_PROGRESS_BOXES
	;
	; Have the progress box alert the user we're connecting to something
	;
		clr	si			; search from first addr
		mov	cx, ss:[xmitID]		; cx <- talID to find
		pushdw	dxax
		call	OUFindNextAddr		; ds:si <- addr, *ds:di <- msg
						; ax <- addr #
	; EC: message with no address marked for transmit should not have been
	; added, or should have been removed by OTrPrepareBatch
EC <		ERROR_C	FIRST_MESSAGE_HAS_NO_XMIT_ADDR			>

	;
	; Tell the progress box what we're up to.
	; 
		mov_tr	cx, ax			; cx <- addr #
		popdw	dxax			; dxax <- MailboxMessage
		call	OTrProgressConnecting
		call	UtilVMUnlockDS
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

	;
	; Use the address returned by OTrFindSendableMessage to ask the driver
	; to connect, if we're not connected already.
	;
		mov	si, ss:[thisConn]
		test	ss:[flags], mask OTrF_CONNECTED	; (carry clear)
		jnz	done

		mov	bx, ss:[thisAddr]
		call	MemLock
		mov	ds, ax
		mov_tr	cx, ax
		mov	dx, offset OMA_address
		mov	bx, ds:[OMA_addrLen]
		mov	ax, ds:[OMA_transOption]
		mov	di, DR_MBTD_CONNECT
		call	ss:[strategy]

	;
	; Release the address and record the connection handle, if we
	; succeeded in connecting.
	; 
		mov	bx, ss:[thisAddr]
		call	MemUnlock
		jnc	connected
	
	;
	; If user cancelled, flag this for later
	;
		cmp	ax, ME_USER_CANCELED
		jne	connectError
		ornf	ss:[flags], mask OTrF_CANCELED
connectError:
		stc
		jmp	short done

connected:
		ornf	ss:[flags], mask OTrF_CONNECTED
		mov	ss:[thisConn], si
		
done:
		.leave
		ret
OTrConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrSendBatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send each message in the batch queue that has one or
		more addresses marked with the thread's xmit ID

CALLED BY:	(INTERNAL) OTrMain
PASS:		di	= batch queue
		si	= connection handle
		ss:bp	= inherited frame
RETURN:		carry set if canceled:
			ax	= MailboxCancelAction
		carry clear if ok
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		- for each message:
		    - call OTrSendMessage


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrSendBatch	proc	near
		uses	bx, cx
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
		call	MailboxGetAdminFile
		clr	cx
messageLoop:
		call	DBQGetItemNoRef		; dxax <- message
		cmc
		jnc	done			; => no more messages

		call	OTrSendMessage
		inc	cx			; advance to next message
		jnc	messageLoop
		
	;
	; If just the one message canceled, loop back for the next item.
	; 
		cmp	ax, MCA_CANCEL_MESSAGE
		je	messageLoop
	;
	; At the least, the batch has been canceled -- return the verdict to
	; our caller.
	; 
		stc
done:
		.leave
		ret
OTrSendBatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrSendMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send one or more copies of a message through the connection.
		The number of copies is determined by the number of addresses
		marked for transmission.

CALLED BY:	(INTERNAL) OTrSendBatch
PASS:		dxax	= message to send
		si	= connection through which to send it
		bx	= admin file
		di	= batch queue
RETURN:		carry set if batch should be canceled:
			ax	= MailboxCancelAction
		carry clear if message sent successfully:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	see below

PSEUDO CODE/STRATEGY:
		- for each marked address:
		    - call OTrSendMessageToAddress
		    - loop if carry clear
		- if no more addresses unsent, delete message
		  from outbox (leave in batch & thread queue until bq
		  destroyed & next iteration in OTrMain happens)
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrSendMessage	proc	near
		uses	cx, di, si, ds, bx
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
	;
	; Loop through all the addresses marked for transmission.
	; 
		mov	ss:[curAddr], 0
		movdw	ss:[curMsg], dxax
addrLoop:
		mov	cx, ss:[xmitID]		; cx <- talID sought
		push	si, ax
		mov	si, ss:[curAddr]	; si <- first addr to check
		call	OUFindNextAddr		; ds:si <- addr
						; *ds:di <- message
						; ax <- index of ds:si
		mov	ss:[curAddr], ax	; save for next iteration
		mov	bx, si			; ds:bx <- address
		pop	si, ax
		jc	checkUnsent		; => no more addresses for
						;  this message
	;
	; Have an address that needs sending to, so do it, please.
	; 
		call	OTrSendMessageToAddress
		inc	ss:[curAddr]		; start search in next iteration
						;  with the address *after*
						;  this one, please
		jc	messageDone
	;
	; If driver is single-message, we do not send to duplicate addresses.
	;
		test	ss:[transCaps], mask MBTC_SINGLE_MESSAGE
		jnz	unmarkDups
		jmp	addrLoop
messageDone:
	;
	; Regardless of the extent of the cancelation, we're done sending
	; this message, and its addresses have been marked accordingly.
	; Propagate the extent to our caller.
	; 
		mov_tr	ax, bx
done:
		.leave
		ret

unmarkDups:
	;
	; Driver accepts just one message per connection, so we Need to revert
	; any duplicate addresses back to being just queued.
	;
		movdw	dxax, ss:[curMsg]
		mov	cx, ss:[xmitID]
		mov	si, ss:[queuedID]
		push	bx
		mov	bx, (MACT_QUEUED shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		call	OTQChangeAddressMarks
		pop	bx

checkUnsent:
	;
	; Remove the message from the outbox if there are no remaining
	; unsent-to addresses.
	;
		call	OUDeleteMessageIfNothingUnsent
		clc
		jmp	done
OTrSendMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrSendMessageToAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the current message to a single address through an
		established connection.

CALLED BY:	(INTERNAL) OTrSendMessage
PASS:		ds:bx	= MailboxInternalTransAddr
		si	= connection handle
		ss:bp	= inherited stack frame (curAddr == index of address)
		dxax	= MailboxMessage to send.
RETURN:		carry set if batch was canceled:
			bx	= MailboxCancelAction
		carry clear if message sent successfully:
			bx	= destroyed
DESTROYED:	cx, di, ds
SIDE EFFECTS:	message is unlocked

PSEUDO CODE/STRATEGY:
		- initialize progress box (DBQAddRef, send MM, 
		  addr index | TID_ADDR_INDEX)
		- call DR_MBTD_TRANSMIT_MESSAGE
		- add log entry
		- if successful, mark address as SENT
		- else if user canceled
		    - reinitialize cancel flag
		    - mark message's xmitID addresses with tal ID of 0
		    - ask if entire batch should be canceled.
		    - if yes, return MCA_CANCEL_ALL
		    - if no, return MCA_CANCEL_MESSAGE
		- else if connection lost
		    - notify user and ask if should retry.
		    - if yes
			    - reset all xmit tal IDs to thread's
		    - if no
			    - reset all xmit tal IDs to 0
		    - in any case, return MCA_CANCEL_BATCH
		- else
		    - notify user via progress box
		    - cancel the message, but nothing else
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrSendMessageToAddress proc	near
		uses	si, dx, ax
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
	;
	; Change the address state to sending and notify the world.
	;
EC <		push	ax					>
EC <		mov	al, ds:[bx].MITA_flags			>
EC <		andnf	al, mask MTF_STATE			>
EC <		cmp	al, MAS_READY shl offset MTF_STATE	>
EC <		ERROR_NE	MESSAGE_NOT_READY_FOR_SENDING	>
EC <		pop	ax					>
			CheckHack <MAS_SENDING eq MAS_READY + 1>
		add	ds:[bx].MITA_flags, 1 shl offset MTF_STATE
		call	UtilVMDirtyDS
		
		MovMsg	cxdx, dxax
		push	bp
		mov	bp, ss:[curAddr]
		ornf	bp, (MACT_SENDING shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		mov	ax, MSG_MA_BOX_CHANGED
		call	UtilSendToMailboxApp
		pop	bp
		MovMsg	dxax, cxdx
	;
	; Release the message during the transmission, to avoid nasty
	; synchronization hierarchy issues.
	;
		call	UtilVMUnlockDS
	;
	; Tell the progress box which message & address we're sending to
	; 
		call	OTrProgressSetMessage
	;
	; Check cancel flag at the start.
	; 
		mov	di, ss:[cancelFlagPtr]
		tst	{MailboxCancelAction}ss:[di]
		jz	sendIt
		mov	ax, ME_USER_CANCELED
		mov	cx, handle uiUserCanceled
		mov	dx, offset uiUserCanceled
		stc
		jmp	transmitDone
sendIt:
	;
	; Call the transport driver with the requisite parameters
	; 
		xchg	ax, dx
		mov_tr	cx, ax		; cxdx <- message
		mov	ax, ss:[curAddr]; ax <- address #
		mov	di, DR_MBTD_TRANSMIT_MESSAGE
		call	ss:[strategy]	; CF, ax, ^lcx:dx <- results

transmitDone:
	; ADD LOG ENTRY HERE
		jc	error
	;
	; Transmission was successful. Mark this address as sent and zero the
	; addrList field, just to be cautious.
	; 
		movdw	dxax, ss:[curMsg]
		call	MessageLock
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		mov	ax, ss:[curAddr]
		call	ChunkArrayElementToPtr
			CheckHack <MAS_SENT eq 0>
		BitClr	ds:[di].MITA_flags, MTF_STATE	; MTF_STATE = MAS_SENT
ifdef PERPETUAL_SEND
		ornf	ds:[di].MITA_flags, (MAS_QUEUED shl offset MTF_STATE)
		mov	ax, ss:[queuedID]
		mov	ds:[di].MITA_addrList, ax
else
		mov	ds:[di].MITA_addrList, 0
	;
	; Clear the MTF_DUP flag for the next one in the chain, making it 
	; the primary address.
	; 
EC <		test	ds:[di].MITA_flags, mask MTF_DUP		>
EC <		ERROR_NZ DUP_ADDRESS_SENT_BEFORE_ORIGINAL		>
		mov	ax, ds:[di].MITA_next
		inc	ax
		jz	notifyOthers
		dec	ax
		call	ChunkArrayElementToPtr
		andnf	ds:[di].MITA_flags, not mask MTF_DUP
notifyOthers:
endif	; PERPETUAL_SEND

	;
	; Tell our app object to notify everyone else that this address is
	; outta here.
	; 
		movdw	cxdx, ss:[curMsg]
			CheckHack <offset MABC_ADDRESS eq 0>
		push	bp
		mov	bp, ss:[curAddr]
		Assert	bitClear, bp, <not mask MABC_ADDRESS>
ifdef PERPETUAL_SEND
		ornf	bp, (MACT_QUEUED shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
else
		ornf	bp, (MACT_REMOVED shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
endif	; PERPETUAL_SEND

		mov	ax, MSG_MA_BOX_CHANGED
		clr	di
		call	UtilForceQueueMailboxApp
		pop	bp
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
	;
	; Return happiness
	; 
		clc
done:
		.leave
		ret

error:
if	_QUERY_DELETE_AFTER_PERMANENT_ERROR
		andnf	ss:[flags], not mask OTrF_PERMANENT
		test	ax, ME_UNRECOVERABLE
		jz	checkCanceled
		ornf	ss:[flags], mask OTrF_PERMANENT
checkCanceled:
endif	; _QUERY_DELETE_AFTER_PERMANENT_ERROR

	;
	; Handle ME_LOST_CONNECTION and ME_USER_CANCELED specially
	; 
		cmp	ax, ME_USER_CANCELED
		jne	checkLostConnection
		call	OTrStoreReason		; Store the error string
						;  away, then mark all remaining
						;  addresses with the reason
						;  cx <- reason ref token

		call	OTrHandleCancelation
		stc
		jmp	done

checkLostConnection:
		cmp	ax, ME_LOST_CONNECTION
		jne	cancelMessage
		call	OTrStoreReason		; Store the error string
						;  away, then mark all remaining
						;  addresses with the reason
						;  cx <- reason ref token

		call	OTrHandleLostConnection
		stc
		jmp	done

cancelMessage:
	;
	; For anything else, just tell the progress box to tell the user
	; (addresses already marked with reason) and return that the message
	; has been canceled.
	; 
		call	OTrStoreReasonAndReport	; Store the error string
						;  away, then mark all remaining
						;  addresses with the reason
						;  cx <- reason ref token

		call	OTrCancelCurrentMessage
		mov	bx, MCA_CANCEL_MESSAGE
		stc
		jmp	done
OTrSendMessageToAddress endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrCancelCurrentMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel the transmission for the addresses of the current message
		that were marked for transmission.

CALLED BY:	(INTERNAL) OTrSendMessageToAddress
PASS:		ss:bp	= inherited stack frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrCancelCurrentMessage proc	far
		uses	dx, ax, si, cx, di
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
		mov	si, ss:[xmitID]
		mov	ss:[cancelID], si
		movdw	sidi, ss:[curMsg]
		call	OTrCancelMessagesCallback
		.leave
		ret
OTrCancelCurrentMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrHandleCancelation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the user about his/her cancel request, to see if all
		the messages should be canceled, or just the one that was
		being sent at the time.

CALLED BY:	(INTERNAL) OTrSendMessageToAddress
PASS:		ss:bp	= inherited frame
RETURN:		bx	= MailboxCancelAction
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If there are other messages still in the queue that are
		marked for transmission, ask the user what she meant by "Stop"
		
		If user says to cancel message, use OTrMungeCurrentMessage
		to do so.
		
		If user says to cancel all, just return MCA_CANCEL_ALL

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrHandleCancelation proc	near
		uses	cx, dx, si, di
		.enter	inherit	OTrMain
		Assert	stackFrame, bp

if	_QUERY_AFTER_CANCEL
		call	MailboxGetAdminFile
		mov	di, ss:[dbq]
		mov	cx, SEGMENT_CS
		mov	dx, offset OTrHandleCancelationFindOtherMessageCallback
		call	DBQEnum
	;
	; Change the address marks for the current message from xmit to queued,
	; so the progress box can display all the addresses that are queued.
	; We'll also be able to cancel them all at once.
	; 
		pushf
		movdw	dxax, ss:[curMsg]
		mov	cx, ss:[xmitID]
		mov	si, ss:[queuedID]
		mov	bx, (MACT_QUEUED shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		call	OTQChangeAddressMarks
		
	;
	; Now call the progress box to ask the user about life.
	; 
		MovMsg	cxdx, dxax
		mov	ax, IC_YES		; assume no other message,
						;  and this causes the least
						;  work...
		popf
		jnc	haveAnswer		; nothing else being sent, so
						;  no need to ask the user

	    ;
	    ; But first, see if the thing that set the flag had anything in
	    ; mind beyond stopping the current message.
	    ; 
		mov	bx, ss:[cancelFlagPtr]
		mov	bx, ss:[bx]
		cmp	bx, MCA_CANCEL_MESSAGE
		jne	done			; => it did -- respect its
						;  wishes

		push	bp
		mov	bp, si
		mov	bx, handle OutboxCancelRoot
		mov	si, offset OutboxCancelRoot
		mov	ax, offset OutboxCancelMessage
		mov	di, MSG_MG_SET_MESSAGE_ALL_VIEW
		call	OTrDoDialog
		pop	bp
haveAnswer:		
	;
	; Return the cancel extent to our caller.
	; 
		mov	bx, MCA_CANCEL_MESSAGE
		cmp	ax, IC_YES		; continue sending?
		je	done			; yes -- just this message
						;  canceled
		mov	bx, MCA_CANCEL_ALL	; no -- cancel all queued
done:
	;
	; Always cancel all aspects of the current message, even those addresses
	; that weren't being sent to.
	;
		mov	si, ss:[queuedID]
		mov	ss:[cancelID], si
		movdw	sidi, ss:[curMsg]
		call	OTrCancelMessagesCallback
else	; !_QUERY_AFTER_CANCEL
	;
	; Cancel the addresses we were transmitting to for the current message.
	;
		call	OTrCancelCurrentMessage
	;
	; Return whatever cancel extent we were told to. This will always be
	; at least MCA_CANCEL_MESSAGE, which is what we'd return given our
	; druthers...
	;
		mov	bx, ss:[cancelFlagPtr]
		mov	bx, ss:[bx]
	;
	; Flag user-cancel for later.
	;
		ornf	ss:[flags], mask OTrF_CANCELED
endif	; _QUERY_AFTER_CANCEL

	;
	; Reset the cancel flag for the next batch.
	; 
		mov	si, ss:[cancelFlagPtr]
		mov	{MailboxCancelAction}ss:[si], MCA_CANCEL_NONE
		.leave
		ret
OTrHandleCancelation endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrHandleCancelationFindOtherMessageCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to find a message that's not the
		current one that has an unsent address marked with the
		xmitID or the queuedID

CALLED BY:	(INTERNAL) OTrHandleCancelation via DBQEnum
PASS:		bx	= admin file
		sidi	= MailboxMessage
		ss:bp	= inherited frame (OTrMain)
RETURN:		carry set if found one (stop enumerating)
DESTROYED:	bx, si, di allowed by DBQEnum
		cx, dx, ax allowed by OTrHandleCancelation
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_QUERY_AFTER_CANCEL
OTrHandleCancelationFindOtherMessageCallback proc far
		.enter	inherit	OTrMain
		Assert	stackFrame, bp

		cmpdw	ss:[curMsg], sidi
		je	done
		movdw	dxax, sidi
		mov	bx, SEGMENT_CS
		mov	di, offset checkAddress
		call	MessageAddrEnum
done:
		.leave
		ret
	;--------------------
	; Callback to examine an address to see if it's queued for
	; transmission.
	;
	; Pass:	ds:di	= MailboxInternalTransAddr
	;	ss:bp	= inherited frame
	; Return:	carry set to stop enumerating (found sendable addr)
	; 
checkAddress:
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	checkAddressDone	; jump if MAS_SENT
		test	ds:[di].MITA_flags, mask MTF_DUP
		jnz	checkAddressDone
		mov	ax, ss:[xmitID]
		cmp	ds:[di].MITA_addrList, ax
		je	checkAddressFound
		mov	ax, ss:[queuedID]
		cmp	ds:[di].MITA_addrList, ax
		clc
		jne	checkAddressDone
checkAddressFound:
		stc
checkAddressDone:
		retf
OTrHandleCancelationFindOtherMessageCallback endp
endif	; _QUERY_AFTER_CANCEL

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrDoDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog to ask the user something.

CALLED BY:	(INTERNAL) OTrHandleCancelation
PASS:		^lbx:si	= template dialog
		cxdx	= MailboxMessage
		bp	= talID
		^lbx:ax	= MessageGlyph to which to send the MailboxMessage
			  before calling UserDoDialog. ax = 0 means no
			  glyph in the dialog.
		di	= message to send it
RETURN:		ax	= InteractionCommand response to the dialog.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_QUERY_AFTER_CANCEL
OTrDoDialog	proc	near
		uses	si, bx, di
		.enter
	;
	; First create the dialog from the template.
	; 
		call	UserCreateDialog	; ^lbx:si <- new dialog
		tst	ax
		jz	doDialog		; => no glyph to setup
	;
	; Add the requisite extra reference to the message.
	; 
		push	si
		mov_tr	si, ax			; ^lbx:si <- glyph
		push	bx
		MovMsg	dxax, cxdx
		call	MailboxGetAdminFile
		call	DBQAddRef
		MovMsg	cxdx, dxax
		pop	bx
	;
	; Tell the glyph to display the address(es) and the message.
	; 
		Assert	objectOD, bxsi, MessageGlyphClass
		mov	ax, di
		Assert	etype, di, MessageGlyphMessages
		clr	di			; no fixup, no call needed,
						;  preserves cx, dx, bp
		call	ObjMessage
		pop	si			; ^lbx:si <- dialog
doDialog:
	;
	; Bring the dialog up.
	; 
		call	UserDoDialog		; ax <- InteractionCommand
	;
	; Now it's down, destroy it, please.
	; 
		call	UserDestroyDialog
		.leave
		ret
OTrDoDialog	endp
endif	; _QUERY_AFTER_CANCEL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrHandleLostConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the user know the connection was lost and ask if the
		connection should be retried.

CALLED BY:	(INTERNAL) OTrSendMessageToAddress
PASS:		ss:bp	= inherited frame
RETURN:		bx	= MailboxCancelAction
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If user says not to retry, just return MCA_CANCEL_BATCH,
		leaving the current and subsequent messages alone. Those
		addresses marked with the xmitID will be canceled in the
		main loop.
		
		If user says to retry, reset all the xmitIDs to queuedIDs and
		return MCA_CANCEL_BATCH. This will bail back to the main
		loop, but not actually cancel any of the messages.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrHandleLostConnection proc	near
		Assert	stackFrame, bp
if	_QUERY_AFTER_LOST_CONNECTION
		uses	cx, dx, si, di
		.enter	inherit	OTrMain
	;
	; Ask the user, first.
	; 
		mov	bx, handle OutboxLostConnectionRoot
		mov	si, offset OutboxLostConnectionRoot
		mov	ax, offset OutboxLostConnectionMessage
		movdw	cxdx, ss:[curMsg]
		mov	di, MSG_MG_SET_MESSAGE_LOST_CONNECTION
		push	bp
		mov	bp, ss:[curAddr]
		ornf	bp, mask TID_ADDR_INDEX
		call	OTrDoDialog
		pop	bp

		cmp	ax, IC_YES
		jne	done
	;
	; User wants to retry the messages, so revert their talIDs back to
	; the queued state, thereby allowing them to escape cancelation when
	; we return MCA_CANCEL_BATCH.
	; 
		call	MailboxGetAdminFile
		mov	di, ss:[dbq]
		mov	cx, SEGMENT_CS
		mov	dx, offset OTrReQueueCallback
		call	DBQEnum
done:
		.leave
endif	; _QUERY_AFTER_LOST_CONNECTION
		mov	bx, MCA_CANCEL_CONNECT
		ret
OTrHandleLostConnection endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrReQueueCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert any address marked with the thread's transmit ID to
		be marked with its queued ID, so it will be processed again.

CALLED BY:	(INTERNAL) OTrHandleLostConnection via DBQEnum
PASS:		bx	= admin file
		sidi	= MailboxMessage to possibly requeue
		ss:bp	= inherited frame
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx, si, di allowed by DBQEnum
		ax, dx, cx allowed by OTrHandleLostConnection
SIDE EFFECTS:	talIDs that were ss:[xmitID] are changed to ss:[queuedID]

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrReQueueCallback proc	far
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
		movdw	dxax, sidi
		mov	cx, ss:[xmitID]
		mov	si, ss:[queuedID]
		mov	bx, (MACT_QUEUED shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		call	OTQChangeAddressMarks
		clc
		.leave
		ret
OTrReQueueCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrStoreReasonAndReport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the reason for failure in the remaining marked addresses
		for the current message, incrementing the retry counter for
		each. Tell the progress box to display the error.
		
		Addresses are not unmarked, as the decision of whether to
		abort the send or retry it is made later.

CALLED BY:	(INTERNAL) OTrSendMessageToAddress
PASS:		^lcx:dx	= reason
		ss:bp	= inherited frame w/curMsg and xmitID set
RETURN:		cx	= reason token (from outboxReason.asm)
		ss:[reason] = same
DESTROYED:	nothing
SIDE EFFECTS:	ss:[cancelID] set to ss:[xmitID]
		progress box is notified of the error

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/24/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrStoreReasonAndReport proc	near
		uses	ax
		.enter	inherit OTrMain
		Assert	stackFrame, bp
		call	OTrStoreReason		; cx <- reason token

if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		mov	ax, MSG_OP_SET_ERROR
		call	OTrSendToProgressBox
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
		.leave
		ret
OTrStoreReasonAndReport endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrStoreReason
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the reason for failure in the remaining marked addresses
		for the current message, incrementing the retry counter for
		each.
		
		Addresses are not unmarked, as the decision of whether to
		abort the send or retry it is made later.

CALLED BY:	(INTERNAL) OTrSendMessageToAddress,
			   OTrStoreReasonAndReport,
			   OTrMain
PASS:		^lcx:dx	= reason
		ss:bp	= inherited frame w/curMsg set.
		if curMsg is 0 (mark all messages in the queue):
			cancelID = set to ID for messages to mark

RETURN:		cx	= reason token (from outboxReason.asm)
		ss:[reason] = same
DESTROYED:	nothing
SIDE EFFECTS:	ss:[cancelID] set to ss:[xmitID]

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrStoreReason	proc	near
		uses	ds, si, di, bx, ax, dx
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
		call	ORStoreReason
		mov	ss:[reason], ax

		movdw	dxax, ss:[curMsg]

		mov	cx, ax
		or	cx, dx
		jz	markQueue

		mov	cx, ss:[xmitID]
		mov	ss:[cancelID], cx
		call	markMessage
done:
		mov	cx, ss:[reason]
		.leave
		ret

markQueue:
	;
	; Mark everything in the queue that has ss:[cancelID] for its talID
	;
		call	MailboxGetAdminFile
		mov	di, ss:[dbq]
		mov	cx, SEGMENT_CS
		mov	dx, offset markQueueCallback
		call	DBQEnum
		jmp	done

	;--------------------
	; Callback to mark the next message in the queue.
	;
	; Pass:	sidi	= MailboxMessage
	; 	ss:bp	= inherited frame
	; Return:	carry set to stop enumerating
	; Destroy:	bx, si, di
	; 		ax, cx, dx our caller doesn't need, so we can nuke
markQueueCallback:
		MovMsg	dxax, sidi
		call	markMessage
		clc		; keep enumerating
		retf

	;--------------------
	; Store the reason in all addresses of a message marked with the
	; cancelID
	;
	; Pass:	dxax	= MailboxMessage
	; 	ss:bp	= inherited frame
	; Return:	nothing
	; Destroy:	bx, di
markMessage:
		mov	bx, SEGMENT_CS
		mov	di, offset OTrStoreReasonCallback
		call	MessageAddrEnum
		retn

OTrStoreReason	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrStoreReasonCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to set the failure reason for any marked
		address.

CALLED BY:	(INTERNAL) OTrStoreReason via MessageAddrEnum
PASS:		ds:di	= MailboxInternalTransAddr
		ss:bp	= inherited frame
		cancelID, reason = set
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrStoreReasonCallback proc	far
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
	;
	; See if this address was marked for transmission.
	; 
		mov	ax, ss:[cancelID]
		cmp	ds:[di].MITA_addrList, ax
		jne	done
	;
	; It was. Store the reason.
	; 
		mov	ax, ss:[reason]
		mov	ds:[di].MITA_reason, ax
	;
	; Increment the MTF_TRIES field, so long as it won't overflow.
	; 
		mov	al, ds:[di].MITA_flags
		andnf	al, mask MTF_TRIES
		cmp	al, MTF_INFINITY shl offset MTF_TRIES
		je	dirty
			CheckHack <offset MTF_TRIES eq 0>
		inc	ds:[di].MITA_flags
dirty:
		call	UtilVMDirtyDS
done:
		clc
		.leave
		ret
OTrStoreReasonCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrCreateProgressBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a progress box for the thread

CALLED BY:	(INTERNAL) OTrMain
PASS:		nothing
RETURN:		^lbx:si	= progress box
DESTROYED:	nothing
SIDE EFFECTS:	the OutProg resource is duplicated.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
OTrCreateProgressBox proc	near
		uses	ax, cx
		.enter
		mov	bx, handle OutProgRoot
		clr	ax		; owned by mailbox, which owns the
					;  current thread
		mov	cx, -1		; burden thread is dictated by the
					;  block itself
		call	ObjDuplicateResource
		mov	si, offset OutProgRoot
		.leave
		ret
OTrCreateProgressBox endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrSetupProgressBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the progress box for the thread, attaching it to
		the UI tree, setting its title moniker, and bringing it up
		on screen

CALLED BY:	(INTERNAL) OTrMain
PASS:		ax	= driver's MailboxTransportCapabilities
		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	progress box comes up on screen (not synchronous with this
     			call, though -- it happens on the burden thread)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
OTrSetupProgressBox proc near
		uses	ds, di, bx, si, bp, dx, cx
		.enter	inherit	OTrMain
if 	_TRANSMIT_THREADS_KEYED_BY_MEDIUM

		movdw	cxdx, ss:[transport]
		mov	si, ss:[transOption]

endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM

	;
	; Make room for the args we pass.
	; 
		sub	sp, size OPSetupArgs
		mov	bp, sp
	;
	; Figure what to set OPSA_showPercent to, by looking at the 
	; capabilities of the driver.
	; 
		clr	bx			; assume not
		test	ax, mask MBTC_REPORTS_PROGRESS
		jz	setPercentageFlag
		dec	bx			; driver can report it, so
						;  box should show it
setPercentageFlag:
		mov	ss:[bp].OPSA_meta.MPBSA_showProgress, bl

	;
	; Find the data for the current thread so we can get the transport,
	; medium, and the optr of the progress box itself.
	; 
		call	MainThreadFindCurrentThread	; ds:di <- thread data

if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
	;
	; Transport & option not recorded in OTD, so store from local vars
	; we loaded into registers before.
	;
		movdw	ss:[bp].OPSA_transport, cxdx
		mov	ss:[bp].OPSA_transOption, si
else	; !_TRANSMIT_THREADS_KEYED_BY_MEDIUM
	;
	; Transfer the transport token into the args wholesale.
	; 
		movdw	ss:[bp].OPSA_transport, ds:[di].MTD_transport, ax
		mov	ax, ds:[di].MTD_transOption
		mov	ss:[bp].OPSA_transOption, ax
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM

	;
	; don't forget the generation number.
	;
		mov	ax, ds:[di].OTD_meta.MTD_gen
		mov	ss:[bp].OPSA_meta.MPBSA_gen, ax
	;
	; Extract the medium token & progress box before releasing the
	; MainThreads block (avoid possible synchronization headache by
	; not holding the block while fetching the MediumType itself...).
	; 
		mov	ax, ds:[di].OTD_medium
		movdw	bxsi, ds:[di].MTD_progress

		call	MainThreadUnlock
	;
	; Consult outboxMedia.asm to map the medium-unit token into just the
	; medium, as that's all the progress box needs to know.
	; 
		call	OMGetMedium		; cxdx <- medium token
		movdw	ss:[bp].OPSA_medium, cxdx
	;
	; Stuff in our thread handle, too.
	; 
		push	bx
		clr	bx
		mov	ax, TGIT_THREAD_HANDLE
		call	ThreadGetInfo
		pop	bx
		mov	ss:[bp].OPSA_meta.MPBSA_thread, ax
	;
	; Args set up, now ship them off with the MSG_MPB_SETUP to the box.
	; The box will take care of bringing itself on-screen.
	; 
		mov	dx, size OPSetupArgs
		mov	ax, MSG_MPB_SETUP
		mov	di, mask MF_STACK
		call	ObjMessage
		add	sp, size OPSetupArgs
		
		.leave
		ret
OTrSetupProgressBox endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrProgressSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the progress box what message & address is being sent
		to.

CALLED BY:	(INTERNAL) OTrSendMessageToAddress
PASS:		ss:bp	= inherited frame, with curAddr set to address index
		dxax	= MailboxMessage
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	extra reference added to the message
    		notification sent out that message is being transmitted

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrProgressSetMessage proc near
		uses	cx, bp
		.enter	inherit	OTrMain
		Assert	stackFrame, bp
	;
	; Let the world know the thing is being transmitted.
	;
		MovMsg	cxdx, dxax
		mov	bp, ss:[curAddr]
		Assert	bitClear, bp, <not mask MABC_ADDRESS>
		ornf	bp, (MACT_SENDING shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		mov	ax, MSG_MA_BOX_CHANGED
		call	UtilSendToMailboxApp
		MovMsg	dxax, cxdx

if	MAILBOX_PERSISTENT_PROGRESS_BOXES
	;
	; Mark the address index as an index.
	; 
		andnf	bp, mask MABC_ADDRESS
		ornf	bp, mask TID_ADDR_INDEX
	;
	; Send the message to the box, please.
	; 
		mov	cx, MSG_OP_SET_MESSAGE
		call	OTrProgressForMessageCommon
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
		.leave
		ret
OTrProgressSetMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrSendToProgressBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message (do not call) to the current thread's progress
		box.

CALLED BY:	(INTERNAL) OTrProgressSetMessage,
			   OTrStoreReason
PASS:		ax	= message to send
		cx, dx, bp = parameters
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
OTrSendToProgressBox proc near
		uses	di
		.enter
		clr	di		; just send the thing (preserves
					;  cx, dx, and bp for us...)
		call	MainThreadMessageProgressBox
		.leave
		ret
OTrSendToProgressBox endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrProgressForMessageCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the progress box about a particular
		MailboxMessage, adding a reference to the message in
		question before shipping it off to the progress box.

CALLED BY:	(INTERNAL) OTrProgressPreparing, OTrProgressConnecting
PASS:		dxax	= MailboxMessage
		cx	= message to send to the progress box
		bp	= additional data for box
RETURN:		nothing
DESTROYED:	cx
SIDE EFFECTS:	reference added to the message, of course

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
OTrProgressForMessageCommon proc near
		uses	bx, dx, ax
		.enter
	;
	; Add an extra reference to the message before sending its 32-bit handle
	; off.
	; 
		call	MailboxGetAdminFile
		call	DBQAddRef
	;
	; Send the message to the progress box
	; 
		MovMsg	cxdx, dxax
		call	OTrSendToProgressBox
		.leave
		ret
OTrProgressForMessageCommon endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrProgressConnecting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the user know we're connecting to an address

CALLED BY:	(INTERNAL) OTrConnect
PASS:		dxax	= MailboxMessage
		cx	= address # being used for the connection
RETURN:		nothing
DESTROYED:	cx
SIDE EFFECTS:	reference added to the message

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
OTrProgressConnecting proc	near
		uses	bp
		.enter
		mov	bp, cx
		mov	cx, MSG_OP_SET_CONNECTING	; cx <- obj msg
		call	OTrProgressForMessageCommon
		.leave
		ret
OTrProgressConnecting endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetRemainingMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of messages remaining to be sent using
		the current connection. If called from DR_MBTD_TRANSMIT_MESSAGE,
		the count will include the message currently being transmitted.

		NOTE: This routine may only be called from the PREPARE_FOR_-
		TRANSPORT, CONNECT, TRANSMIT_MESSAGE, or END_CONNECT functions
		of a transport driver. Any other use will generate a fatal
		error.

CALLED BY:	(GLOBAL)
PASS:		nothing
RETURN:		cx	= number of messages remaining
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/20/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetRemainingMessages proc	far
xmitID		local	TalID
queuedID	local	TalID
		ForceRef	xmitID	; used by common code
		ForceRef	queuedID; used by common code
		uses	ds, di, dx, bp, ax, bx
		.enter
		call	OTrCountRemainingSetup
		mov	ss:[queuedID], 0	; only want things in this
						;  batch, not things queued

		mov	di, ds:[di].OTD_dbq
		mov	cx, SEGMENT_CS
		mov	dx, offset OTrRemainingCountCommon
		call	DBQEnum			; cx <- # messages

		call	MainThreadUnlock
		.leave
		ret
MailboxGetRemainingMessages endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAILBOXGETREMAININGMESSAGES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the number of messages left to transmit during this
		connection.

CALLED BY:	(GLOBAL)
PASS:		word (void)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAILBOXGETREMAININGMESSAGES proc	far
		.enter
		call	MailboxGetRemainingMessages
		mov_tr	ax, cx
		.leave
		ret
MAILBOXGETREMAININGMESSAGES endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrRemainingCountCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the addresses for the current message that are in
		the current batch/queued for transmission, and the number
		that remain to be sent to.

CALLED BY:	(INTERNAL) MailboxGetRemainingMessages via DBQEnum
			   MailboxGetRemainingDestinations
PASS:		bx	= admin file
		sidi	= MailboxMessage
		cx	= number of addresses in batch, so far
		dx	= number of addresses unsent to, so far
		ss:bp	= inherited frame
RETURN:		carry set to stop enumerating
		cx	= number of addresses in batch, so far
		dx	= number of addresses unsent to, so far
DESTROYED:	si, di, ax, bx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/20/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrRemainingCountCommon proc	far
xmitID		local	TalID
queuedID	local	TalID
		uses	es, ds
		.enter	inherit
		mov_tr	ax, si		; axdi <- DBGroupAndItem
		call	DBLock		; *es:di <- MMD

		segmov	ds, es
		mov	di, ds:[di]
		mov	si, ds:[di].MMD_transAddrs
		mov	bx, cs
		mov	di, offset OTrRemainingCountCallback
		call	ChunkArrayEnum

		call	DBUnlock
		clc
		.leave
		ret
OTrRemainingCountCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrRemainingCountCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to count up addresses that are queued for
		transmission or that haven't been sent to yet.

CALLED BY:	(INTERNAL) OTrRemainingCountCommon via ChunkArrayEnum
PASS:		ds:di	= MailboxInternalTransAddr
		cx	= number queued for transmission, so far
		dx	= number unsent, so far
		ss:bp	= inherited frame containing xmitID and queuedID.
			  cx gets incremented if the current address is
			  unsent and its MITA_addrList matches the xmitID or,
			  if queuedID is non-zero, queuedID
RETURN:		carry set to stop enumerating (always clear)
		cx	= number queued for transmission
		dx	= number unsent
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/20/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrRemainingCountCallback proc	far
		.enter	inherit	OTrRemainingCountCommon
		Assert	stackFrame, bp
	;
	; Screen out sent-to addresses, and track the unsent ones.
	;
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	done
		inc	dx
	;
	; See if in current batch.
	;
		mov	ax, ds:[di].MITA_addrList
		cmp	ax, ss:[xmitID]
		jne	checkQueued		; => not, but might be queued
inBatch:
		inc	cx
done:
		clc				; keep going, please
		.leave
		ret
checkQueued:
		tst	ss:[queuedID]		; curious about queued?
		jz	done			; => no, so no compare

		cmp	ax, ss:[queuedID]
		je	inBatch
		jmp	done
OTrRemainingCountCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetRemainingDestinations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of destinations to which the passed message
		still needs to be sent. If called from DR_MBTD_TRANSMIT_MESSAGE,
		the count will include the destination currently being sent to.

		NOTE: This routine may only be called from the PREPARE_FOR_-
		TRANSPORT, CONNECT, TRANSMIT_MESSAGE, or END_CONNECT functions
		of a transport driver. Any other use will generate a fatal
		error.

CALLED BY:	(GLOBAL)
PASS:		dxax	= MailboxMessage
RETURN:		cx	= number of destinations queued for transmission (i.e.
			  that will be sent to "soon", barring errors)
		ax	= total number of destinations yet to be sent to,
			  queued or not.
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/20/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetRemainingDestinations proc	far
xmitID		local	TalID
queuedID	local	TalID
		ForceRef	xmitID	; used by common code
		ForceRef	queuedID; used by common code
		uses	ds, di, si, bx, dx
		.enter
		call	OTrCountRemainingSetup

		movdw	sidi, dxax
		clr	cx, dx		; start counters at 0, please
		call	OTrRemainingCountCommon

		mov_tr	ax, dx		; ax <- # unsent
		call	MainThreadUnlock
		.leave
		ret
MailboxGetRemainingDestinations endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MAILBOXGETREMAININGDESTINATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the number of destinations left to transmit to for
		this message.

CALLED BY:	(GLOBAL)
PASS:		dword (MailboxMessage)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAILBOXGETREMAININGDESTINATIONS proc	far
		C_GetOneDWordArg	dx, ax, bx, cx	; dxax <- MailboxMessage
		call	MailboxGetRemainingDestinations
		mov_tr	dx, cx
		.leave
		ret
MAILBOXGETREMAININGDESTINATIONS endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrCountRemainingSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set things up for counting addresses

CALLED BY:	(INTERNAL) MailboxGetRemainingMessages,
			   MailboxGetRemainingDestinations
PASS:		ss:bp	= inherited frame
RETURN:		bx	= admin file
		ss:[queuedID], ss:[xmitID] set
		ds:di	= OutboxThreadData for the current thread
DESTROYED:	cx
SIDE EFFECTS:	caller must call MainThreadUnlock when done

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/20/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrCountRemainingSetup proc	near
xmitID		local	TalID
queuedID	local	TalID
		.enter	inherit far
	;
	; Locate data for the current thread.
	;
		call	MainThreadFindCurrentThread
	;
	; Transfer the two TalIDs into the local vars.
	;
		mov	cx, ds:[di].OTD_xmitID
		mov	ss:[xmitID], cx
		mov	cx, ds:[di].OTD_queuedID
		mov	ss:[queuedID], cx
	;
	; Fetch the admin file handle.
	;
		call	MailboxGetAdminFile
		.leave
		ret
OTrCountRemainingSetup endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTrGracePeriod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sleep to allow user to use phone after cancelled send

CALLED BY:	(INTERNAL) OTrMakeAndSendBatch
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTrGracePeriod	proc	near
	ret
OTrGracePeriod	endp

Transmit	ends
