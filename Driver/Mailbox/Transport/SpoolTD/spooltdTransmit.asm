COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		spooltdTransmit.asm

AUTHOR:		Adam de Boor, Oct 27, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/27/94		Initial revision


DESCRIPTION:
	Functions related to "transmitting" a message
		

	$Id: spooltdTransmit.asm,v 1.1 97/04/18 11:40:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_PROGRESS_PERCENTAGE	equ	FALSE

TransmitCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDPrepareForTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare the message to be transmitted.

CALLED BY:	(GLOBAL) DR_MBTD_PREPARE_FOR_TRANSPORT
PASS:		cxdx	= MailboxMessage
RETURN:		ax	= MBTDPrepareError
		carry clear if it's ok for message to be sent
		carry set if the message cannot be sent now
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We have nothing special to do here, until we handle quick-
		messages, when we'll want to convert from the text/ink format
		to a graphics string.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDPrepareForTransport proc	far
		.enter
		clc
		mov	ax, MBTDPE_OK
		.leave
		ret
SpoolTDPrepareForTransport endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to the destination and return a connection handle

CALLED BY:	(GLOBAL) DR_MBTD_CONNECT
PASS:		cx:dx	= transport address
		bx	= address size
		ax	= MailboxTransportOption
RETURN:		carry set if couldn't connect:
			^lax:si	= reason for failure
		carry clear if connected:
			si	= connection handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Might want to signal connected medium
		eventually...
		
		Allocate a queue handle and place it on the job-status
		GCN list.
		
		Also set the queue handle as the cancel destination for the
		thread.
		
		We return the queue handle as the connection handle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDConnect	proc	far
		uses	bx, cx, dx
		.enter
	;
	; Allocate a queue on which we can block waiting for updates or cancels.
	; 
		call	GeodeAllocQueue
	;
	; Add the queue to the job-status list for the spooler so we can track
	; the progress of our print jobs.
	; 
		mov	cx, bx
		clr	dx
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_PRINT_JOB_STATUS
		call	GCNListAdd
	;
	; Set the queue as the action destination for cancelation, so we know
	; immediately to tell the spooler to stop.
	; 
		mov	bx, cx
		clr	si
		mov	ax, MSG_META_DUMMY
		call	MailboxSetCancelAction
	;
	; Return the queue handle as the connection handle.
	; 
		mov	si, bx
		clc
		.leave
		ret
SpoolTDConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDTransmitMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transmit a message

CALLED BY:	(GLOBAL) DR_MBTD_TRANSMIT_MESSAGE
PASS:		cxdx	= MailboxMessage
		ax	= address number
		si	= connection handle returned by DR_MBTD_CONNECT
RETURN:		carry set if message could not be sent
			^lcx:dx	= reason for failure
			ax	= MailboxError
		carry clear if message sent
			ax, cx, dx = destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get the JobParameters for the address
		Fetch the message body.
		If it's not in SP_SPOOL, copy it there, set its name in
			JP_fname & set SO_DELETE
		Else
			clear SO_DELETE
		Call SpoolAddJob(dx:si) & record job id
		free JobParameters
		MailboxReportPercentage(0)
		while (!done)
			event = QueueGetMessage(connection)
			MessageProcess(event, callback, frame)
		finish with message body

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDTransmitMessage proc	far
queueHan	local	hptr		push	si
msg		local	MailboxMessage	push	cx, dx
jobParams	local	hptr
doneFlag		local	byte
body		local	FileDDMaxAppRef
bodyLen		local	word
jobID		local	word
result		local	MailboxError
errMsg		local	optr

if	MAILBOX_PERSISTENT_PROGRESS_BOXES

totalPgs	local	word

endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

		uses	si, bx, di, ds, es
		.enter

		mov	ss:[doneFlag], FALSE
		mov	ss:[result], ME_SUCCESS
if	MAILBOX_PERSISTENT_PROGRESS_BOXES

		mov	ss:[totalPgs], 0

endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
		
		call	MailboxGetBodyFormat
		cmp	bx, MANUFACTURER_ID_GEOWORKS
		jne	formatError
		cmp	ax, GMDFID_STREAM_GSTRING
		jne	formatError

		call	STDGetJobParams		; ^hbx, ds <- JobParameters
		jc	checkResult

		mov	ss:[jobParams], bx
		call	STDGetBodyAndCopyIfNecessary
		jc	checkResult

		mov	dx, ds
		clr	si
		call	SpoolAddJob
		mov	ss:[jobID], cx

		mov	bx, ss:[jobParams]
		call	MemFree
		
if _PROGRESS_PERCENTAGE and MAILBOX_PERSISTENT_PROGRESS_BOXES
		push	bp
		mov	ax, MPT_PERCENTAGE
		clr	cx
		mov	bp, mask MPA_REPLACE or \
				(VUM_NOW shl offset MPA_UPDATE_MODE)
		call	MailboxReportProgress
		pop	bp
endif
msgLoop:
		tst	ss:[doneFlag]
		jnz	finish
		mov	bx, ss:[queueHan]
		call	QueueGetMessage
		
		mov_tr	bx, ax
		mov	di, bp
		clr	si
		mov	ax, SEGMENT_CS
		push	ax
		mov	ax, offset STDTransmitCallback
		push	ax
		call	MessageProcess
		mov	bp, di
		jmp	msgLoop

formatError:
		mov	ss:[result], ME_UNSUPPORTED_BODY_FORMAT
		mov	ss:[errMsg].handle, handle UnsupportedFormatMsg
		mov	ss:[errMsg].chunk, offset UnsupportedFormatMsg
		jmp	checkResult

finish:
		movdw	cxdx, ss:[msg]
		segmov	es, ss
		lea	di, ss:[body]
		mov	ax, ss:[bodyLen]
		call	MailboxDoneWithBody

checkResult:		
		mov	ax, ss:[result]
		tst	ax
		jz	exit
		movdw	cxdx, ss:[errMsg]
		stc
exit:
		.leave
		ret
SpoolTDTransmitMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDTransmitCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to process a message from our event queue

CALLED BY:	(INTERNAL) SpoolTDTransmitMessage via MessageProcess
PASS:		ax	= message (MSG_META_DUMMY [= cancel],
			  MSG_PRINT_STATUS_CHANGE)
		if MSG_PRINT_STATUS_CHANGE:
			cx	= PrintStatusChangeType
			dx	= print job ID
			bp	= change-specific data:
				  PSCT_NEW_PAGE - current physical page #
				  PSCT_COMPLETE - undefined
				  PSCT_CANCELED - undefined?
		ss:di	= inherited frame
		carry set if event has stack data
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di, bp, ds, es all allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDTransmitCallback proc	far
		xchg	bp, di
		.enter	inherit	SpoolTDTransmitMessage
		Assert	stackFrame, bp
	;
	; See if user asked us to stop.
	; 
		cmp	ax, MSG_META_DUMMY
		je	cancelJob
	;
	; Didn't. See if the spooler is telling us of a status change.
	; 
		cmp	ax, MSG_PRINT_STATUS_CHANGE
		jne	done
	;
	; It is. See if it's for the job we're transmitting.
	; 
		cmp	dx, ss:[jobID]
		jne	done
	;
	; It is. If it's not PSCT_NEW_PAGE, it must be complete or canceled
	; 
			CheckHack <PSCT_NEW_PAGE eq 0>
		tst	cx
			CheckHack <(PSCT_COMPLETE eq PSCT_CANCELED-1) and \
				   (PSCT_CANCELED eq PSCT_ERROR-1) and\
				   (PSCT_ERROR eq PrintStatusChangeType-1)>
		jne	jobDone
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
	;
	; Go figure out what percentage we've now gotten through and report
	; that.
	; 
		call	STDComputePercentage
		push	bp
if _PROGRESS_PERCENTAGE
		mov	ax, MPT_PERCENTAGE
else
		mov	ax, MPT_PAGES
endif
		mov	bp, VUM_NOW shl offset MPA_UPDATE_MODE
		call	MailboxReportProgress
		pop	bp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
done:
		.leave
		ret

cancelJob:
	;
	; Ask that it be biffed. We do *not* set the done flag here until
	; we receive confirmation over the GCN list that the thing has
	; indeed been canceled (PSCT_CANCELED) or made it through anyhow
	; (PSCT_COMPLETE).
	; 
		mov	cx, ss:[jobID]
		call	SpoolDelJob
		jmp	done

jobDone:
	;
	; Job is complete. Tell our caller this.
	; 
		mov	ss:[doneFlag], TRUE
		cmp	cx, PSCT_COMPLETE
		je	report100Pct
		cmp	cx, PSCT_ERROR
		je	commError
	;
	; Job is complete b/c it was nuked. Set the error code and message
	; appropriately before returning.
	; 
		mov	ss:[result], ME_USER_CANCELED
		mov	ss:[errMsg].handle, handle CanceledMsg
		mov	ss:[errMsg].chunk, offset CanceledMsg
report100Pct:
	;
	; Bring the gauge up to 100% before the box comes down. Gives the user
	; a warm fuzzy...
	; 
if _PROGRESS_PERCENTAGE and MAILBOX_PERSISTENT_PROGRESS_BOXES
		push	bp
		mov	ax, MPT_PERCENTAGE
		mov	cx, 100
		mov	bp, VUM_NOW shl offset MPA_UPDATE_MODE
		call	MailboxReportProgress
		pop	bp
endif
		jmp	done

commError:
		mov	ss:[result], ME_LOST_CONNECTION
		mov	ss:[errMsg].handle, handle PrinterErrorMsg
		mov	ss:[errMsg].chunk, offset PrinterErrorMsg
		jmp	report100Pct
STDTransmitCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDGetJobParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the JobParameters block for the print job

CALLED BY:	(INTERNAL) SpoolTDTransmitMessage
PASS:		ss:bp	= inherited frame
		cxdx	= MailboxMessage
RETURN:		carry set if not enough memory:
			ss:[result], ss:[errMsg] set
			bx, ds = destroyed
		carry clear if have parameters:
			^hbx, ds, es = fixed JobParameters block
DESTROYED:	ax, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDGetJobParams	proc	near
		.enter	inherit	SpoolTDTransmitMessage

		Assert	stackFrame, bp
	;
	; Find out how much memory we need for the address.
	; 
		clr	ax, bx			; ax <- buffer size
						; bx <- address #
		call	MailboxGetTransAddr	; ax <- # bytes needed

		Assert	ne, ax, 0		; message or address cannot be
						;  invalid
	;
	; Allocate a fixed block that big.
	; 
		push	cx, ax			; save msg.high & addr size
		mov	cx, ALLOC_FIXED
		call	MemAlloc		; ^hbx <- JP block
		mov	ds, ax			; ds <- JP block
		mov	es, ax			; es <- ditto
		pop	cx, ax			; cx <- msg.high
						; ax <- addr size
		jc	memErr
	;
	; Now really fetch the address.
	; 
		push	bx
		clr	bx, di
		call	MailboxGetTransAddr
	;
	; Move the JobParameters down over the "significant" part of the address
	; 
		mov	si, MAXIMUM_PRINTER_NAME_LENGTH
		sub	ax, MAXIMUM_PRINTER_NAME_LENGTH
		mov_tr	cx, ax
		rep	movsb
		pop	bx			; ^hbx <- JobParameters
	;
	; Set the SO_SHUTDOWN_ACTION flag, please, as the Mailbox library will
	; take care of warning the user if s/he attempts to shut down while this
	; thing is queued.
	;
	CheckHack <SSJA_CANCEL_JOB eq 1 and width SO_SHUTDOWN_ACTION eq 1>
		ornf	ds:[JP_spoolOpts], mask SO_SHUTDOWN_ACTION
		clc
done:
		.leave
		ret

memErr:
		mov	ss:[result], ME_NOT_ENOUGH_MEMORY
		mov	ss:[errMsg].handle, handle InsufficientMemoryMsg
		mov	ss:[errMsg].chunk, offset InsufficientMemoryMsg
		stc
		jmp	done
STDGetJobParams endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDGetBodyAndCopyIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the name of the body and make sure it's in the
		SP_SPOOL directory

CALLED BY:	(INTERNAL) SpoolTDTransmitMessage
PASS:		ss:bp	= inherited frame
		ds = es	= JobParameters
RETURN:		carry set if couldn't get to file or copy it into SP_SPOOL:
			jobParams block freed
			result, errMsg set
			MailboxDoneWithBody called, if necessary
		carry clear if ok:
			ss:[body], ss:[bodyLen] set
			JP_fname & JP_spoolOpts.SO_DELETE set properly
DESTROYED:	ax, bx, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		MailboxGetBodyRef
		if successful:
			store bodyLen
			if FMAR_diskHandle not SP_SPOOL or FMAR_filename
				isn't just a file name:
				SpoolCreateSpoolFile(JP_fname)
				FileClose(handle)
				FileCopy(appRef, SP_SPOOL, JP_fname)
				JP_spoolOpts.SO_DELETE = TRUE
			else
				JP_spoolOpts.SO_DELETE = FALSE
				XXX: make sure JP_fname matches?


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDGetBodyAndCopyIfNecessary proc	near
		.enter	inherit	SpoolTDTransmitMessage
	;
	; Ask the Mailbox library for the app-ref for the message body.
	; 
		movdw	cxdx, ss:[msg]
		segmov	es, ss
		lea	di, ss:[body]
		mov	ax, size (ss:[body])
		call	MailboxGetBodyRef
		jc	getBodyErr
	;
	; Got it. See if it's a file in SP_SPOOL.
	; 
		mov	ss:[bodyLen], ax
		cmp	ss:[body].FMAR_diskHandle, SP_SPOOL
		jne	copyIt		; => not in SP_SPOOL, so must copy

	    ;
	    ; Look for a backslash in the filename (other than at the start),
	    ; which indicates the thing is in a subdirectory of SP_SPOOL, for
	    ; some unknown reason.
	    ; 
		mov_tr	cx, ax		; cx <- app-ref size
		add	di, offset FMAR_filename	; es:di <- path
		sub	cx, offset FMAR_filename	; cx <- # bytes in path
DBCS <		shr	cx						>
		mov	ax, C_BACKSLASH
		LocalNextChar esdi	; backslash as first char doesn't count
		dec	cx
		jz	badBody		; => body is SP_SPOOL itself. We
					;  should never take this branch,
					;  but I'm naturally cautious...
		LocalFindChar
		je	copyIt
	;
	; It's a file in SP_SPOOL, so we can just use it directly. Make sure
	; SO_DELETE is clear so the Mailbox library gets to decide whether
	; to biff the thing or no.
	; 
		andnf	ds:[JP_spoolOpts], not mask SO_DELETE
		jmp	done

getBodyErr:
		mov	ss:[result], ax
		mov	ss:[errMsg].handle, handle CannotOpenMsg
		mov	ss:[errMsg].chunk, offset CannotOpenMsg
		stc
		jmp	done


copyIt:
	;
	; Not in the right place, so we have to copy the file into the spool
	; directory. First set SO_DELETE so the file we create gets biffed.
	; 
		ornf	ds:[JP_spoolOpts], mask SO_DELETE
	;
	; Now call the spooler's nice library routine to create a spool file
	; for us.
	; 
		mov	dx, ds
		mov	si, offset JP_fname
		call	SpoolCreateSpoolFile
		tst	ax
		jz	cannotCreate		; => unsuccessful
	;
	; Can't pass a handle for the destination, so close down the handle
	; the spooler gave us -- we should still be able to use the name
	; without a problem, right?
	; 
		mov_tr	bx, ax
		call	FileClose
	;
	; Now call FileCopy to copy the thing into the spool directory
	; 
		segmov	es, ds
		mov	di, offset JP_fname	; es:di <- dest path
		mov	dx, SP_SPOOL		; dx <- dest disk
		segmov	ds, ss
		lea	si, ss:[body].FMAR_filename	; ds:si <- src path
		mov	cx, ss:[body].FMAR_diskHandle	; cx <- src disk
		call	FileCopy
		segmov	ds, es			; ds <- JobParameters, again
		jc	copyErr

done:		
		.leave
		ret

badBody:
		mov	ss:[result], ME_CANNOT_OPEN_MESSAGE_FILE
		mov	ss:[errMsg].handle, handle BadBodyMsg
		mov	ss:[errMsg].chunk, offset BadBodyMsg
		jmp	doneWithBody

cannotCreate:
		mov	cx, ME_INSUFFICIENT_DISK_SPACE
		jmp	haveErrCode

copyErr:
		mov	cx, ME_INSUFFICIENT_DISK_SPACE
		cmp	ax, ERROR_SHORT_READ_WRITE
		je	haveErrCode
		mov	cx, ME_CANNOT_OPEN_MESSAGE_FILE
haveErrCode:
		mov	ss:[result], cx
		mov	ss:[errMsg].handle, handle CannotCopyMsg
		mov	ss:[errMsg].chunk, offset CannotCopyMsg

doneWithBody:
		movdw	cxdx, ss:[msg]
		segmov	es, ss
		lea	di, ss:[body]
		mov	ax, ss:[bodyLen]
		call	MailboxDoneWithBody
		stc
		jmp	done
STDGetBodyAndCopyIfNecessary endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDComputePercentage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure how far along we are

CALLED BY:	(INTERNAL) STDTransmitCallback
PASS:		ss:bp	= inherited frame
		di	= current physical page #
RETURN:		cx	= percentage
DESTROYED:	
SIDE EFFECTS:	ss:[totalPgs] set, if wasn't set before

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
STDComputePercentage proc	near
		.enter	inherit	SpoolTDTransmitMessage
	;
	; See if we've already asked the spooler for the total number of pages
	; for this beast.
	; 
		tst	ss:[totalPgs]
		jnz	haveTotal
	;
	; We haven't. Get the status for the job.
	; 
		mov	dx, ss:[jobID]
		mov	cx, SIT_JOB_INFO
		call	SpoolInfo
		clr	cx			; assume couldn't get it, so
						;  use 0 for percentage
		cmp	ax, SPOOL_OPERATION_SUCCESSFUL
		jne	done
	;
	; Fetch the total # of physical pages from the status block.
	; 
		call	MemLock
		mov	es, ax
		Assert	e, es:[JS_printing], SJP_PRINTING
		mov	ax, es:[JS_totalPage]
		call	MemFree
	;
	; Remember the total in the stack frame.
	; 
		mov	ss:[totalPgs], ax

haveTotal:
if _PROGRESS_PERCENTAGE
		dec	di			; just starting this page,
						;  so don't act like we just
						;  finished it...
		mov	ax, 100
		mul	di			; dxax <- phys page * 100
		div	ss:[totalPgs]		; ax <- percentage
		mov_tr	cx, ax
else
		mov	cx, di			; cx <- cur page
		mov	dx, ss:[totalPgs]	; dx <- total pages
endif
done:
		.leave
		ret
STDComputePercentage endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDEndConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down a connection

CALLED BY:	(GLOBAL) DR_MBTD_END_CONNECT
PASS:		si	= connection handle
RETURN:		nothing
DESTROYED:	si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDEndConnect proc	far
		uses	ax, bx, cx, dx
		.enter
	;
	; Remove ourselves from the job-status list
	; 
		mov	cx, si
		clr	dx
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_PRINT_JOB_STATUS
		call	GCNListRemove
	;
	; Set the cancel action back to nothing
	; 
		clr	bx, si, ax
		call	MailboxSetCancelAction
	;
	; Destroy the queue, now there are no more references to it. We
	; don't care about any remaining messages.
	; 
		mov	bx, cx
		call	GeodeFreeQueue
		.leave
		ret
SpoolTDEndConnect endp

TransmitCode	ends
