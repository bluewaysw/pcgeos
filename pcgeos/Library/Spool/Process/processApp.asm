COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		System Spooler
FILE:		processApp.asm
AUTHOR:		Jim DeFrisco, 3 April 1990

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_GEN_PROCESS_CLOSE_APPLICATION 
				Finish our life as an application.

    MTD MSG_SPOOL_KILL_FIRST_JOB 
				Kills the first job.

    MTD MSG_SPOOL_PAUSE_FIRST_JOB 
				Pauses the first job.

    INT KillPrinting            All the threads will die of natural causes,
				if we give them a little help. So we tell
				each queue's current job to abort. and
				remove the linkage to any subsequent jobs.

    INT SaveQueueState          Write out the queue to a state file in case
				we die. Kind of like a last will....

    MTD MSG_SPOOL_JOB_REMOVED   Method received when a job exits

    MTD MSG_SPOOL_JOB_ADDED     Method received when a job is added to a
				queue

    INT CreateThreadStart       Start the process of creating a thread for
				a print queue

    INT CreateThreadEnd         Complete the process of creating a thread
				for a print queue

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/13/90		Initial revision

DESCRIPTION:

	This file contains the code to implement the application part of
	the spooler

	$Id: processApp.asm,v 1.1 97/04/07 11:11:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolInit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the Spooler as an application

CALLED BY:	UI (MSG_GEN_PROCESS_OPEN_APPLICATION)
	
PASS:		AX	= Meothd
		CX	= AppAttachFlags
		DX	= Handle to AppLaunchBlock
		BP	= Block handle
		DS, ES	= CoreBlock (DGroup)

RETURN:		Nothing

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/25/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

spoolUICatString	char	"spool", 0
spoolUIKeyString	char	"uiOptions", 0

SpoolOpenApplication	method	SpoolProcClass,	MSG_GEN_PROCESS_OPEN_APPLICATION
	.enter

	; Add the app object to the GCNSLT_SHUTDOWN_CONTROL system notification
	; list so we can object if the user tries to shut down or suspend while
	; we're printing.
	
	push	ax, cx, dx, bp
	mov	cx, handle spoolAppObj
	mov	dx, offset spoolAppObj
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_SHUTDOWN_CONTROL
	call	GCNListAdd
	pop	ax, cx, dx, bp

	; Allocate the error dialog ThreadLock.
	;
	push	bx
	call	ThreadAllocThreadLock
	mov	ds:[errorThreadLock], bx
	pop	bx

	; Restart any printing after we deal with this method
	;
	mov	di, offset SpoolProcClass	; superclass => ES:DI
	call	ObjCallSuperNoLock		; method already in AX

	; Re-start printing
	;
	call	SpoolBirth			; restart printing, please

	; See if we are operating in simple mode
	;
	mov	ax, DEFAULT_SPOOL_UI_OPTIONS
	segmov	ds, cs, cx
	mov	si, offset spoolUICatString
	mov	dx, offset spoolUIKeyString
	call	InitFileReadInteger
	mov	es:[uiOptions], ax		; store SpoolUIOptions

	; Generate MESN_MEDIUM_AVAILABLE messages for all printers, plus
	; MESN_MEDIUM_CONNECTED messages for any that are marked as permanently
	; connected...?

	call	SpoolGenerateMediumNotifies

	.leave
	ret
SpoolOpenApplication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGenerateMediumNotifies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all the printers in the printer::printers key
		and generate an MESN_MEDIUM_AVAILABLE notification for
		each one.

CALLED BY:	(INTERNAL) SpoolOpenApplication
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerCatStr	char	'printer', 0
printersKeyStr	char	'printers', 0
		
SpoolGenerateMediumNotifies proc	near
		uses	ax, bx, cx, dx, si, di, ds, es, bp
		.enter
		segmov	ds, cs, cx
		mov	si, offset printerCatStr
		mov	dx, offset printersKeyStr
		mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
				mask IFRF_READ_ALL
		mov	di, cs
		mov	ax, offset SpoolGenerateMediumNotifiesCallback
		call	InitFileEnumStringSection
		.leave
		ret
SpoolGenerateMediumNotifies endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPrinterNameToMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a printer name into arguments suitable for sending
		out medium notification or for checking to see if the medium
		is available or connected.

CALLED BY:	(GLOBAL)
PASS:		ds:si	= null-terminated printer name
RETURN:		carry set if couldn't allocate memory
		carry clear if ok:
			al	= MUT_MEM_BLOCK
			bx	= handle of medium unit block holding
				  name
			cxdx	= MANUFACTURER_ID_GEOWORKS/GMID_PRINTER
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolPrinterNameToMedium proc	far
		uses	es, di, si
		.enter
	;
	; Find the size of the name.
	; 
		movdw	esdi, dssi
		LocalStrSize includeNull
	;
	; Allocate room for the name, being sure to request the block be
	; fully zero-initialized, so any extra cruft given us by the heap
	; is consistently 0.
	; 
		push	cx
SBCS <		Assert	le, cx, MAXIMUM_PRINTER_NAME_LENGTH		>
DBCS <		Assert	le, cx, MAXIMUM_PRINTER_NAME_LENGTH*2		>
		mov	ax, MAXIMUM_PRINTER_NAME_LENGTH*(size TCHAR)
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		pop	cx
		jc	done
	;
	; Copy the bytes of the name (and only those bytes) into the block,
	; which we then unlock.
	; 
		mov	es, ax
		clr	di
		rep	movsb
		call	MemUnlock

		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GMID_PRINTER
		mov	al, MUT_MEM_BLOCK
done:
		.leave
		ret
SpoolPrinterNameToMedium endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGenerateMediumNotifiesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate notification of the existence of a single printer.

CALLED BY:	(INTERNAL) SpoolGenerateMediumNotifies via 
			   InitFileEnumStringSection
PASS:		ds:si	= null-terminated string section
		dx	= section #
		cx	= length of section
RETURN:		carry set to stop enumeration
DESTROYED:	ax, cx, dx, di, si, bp, bx, es all allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Copy the name into a block o' memory
		Generate the notification

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolGenerateMediumNotifiesCallback proc	far
		.enter
	;
	; Create the unit block.
	; 
		call	SpoolPrinterNameToMedium
	;
	; Now generate the notification of the medium being available, being
	; careful to set SNT_BX_MEM in DI so the system knows to free the thing
	; if the mailbox library doesn't actually load.
	; 
		mov	si, SST_MEDIUM
		mov	di, MESN_MEDIUM_AVAILABLE or mask SNT_BX_MEM
		call	SysSendNotification

	;
	; Keep going through the printers, please.
	; 
		clc
		.leave
		ret
SpoolGenerateMediumNotifiesCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolUICreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent attaching to/creating any state file

CALLED BY:	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
PASS:		ds = es	= dgroup
		ax	= MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		cx	= AppAttachMode
		dx	= Block handle of AppInstanceReference
RETURN:		ax	= handle of extra block of state data (=== 0)
DESTROYED:	oh, you know. The usual.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolUICreateNewStateFile method	SpoolProcClass,
					MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		clr	ax
		ret
SpoolUICreateNewStateFile endp

SpoolInit	ends



SpoolExit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolQuit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_QUIT for spooler app

CALLED BY:	GLOBAL

PASS:		ax	- method number

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Check to see if we have any running threads.  If not, just
		exit, else kill everything -- but quietly.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolQuit	method	SpoolProcClass, MSG_META_QUIT
		uses	ax, bx, ds, di
		.enter

		; we just want to ignore all quits (this will happen if the
		; user presses F3 while the PrintControlPanel is up). So
		; send back a message that we're aborting the quit.

        	call    GeodeGetProcessHandle
		mov     cx, -1                          ;Want to abort the quit
		mov     ax, MSG_META_QUIT_ACK             ;
		mov     di, mask MF_FORCE_QUEUE         ;Send ack.
		call    ObjMessage      		;

		.leave
		ret
SpoolQuit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish our life as an application.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		ds = es = dgroup
RETURN:		cx	= handle of extra state block to save (0)
DESTROYED:	ax, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolCloseApplication method dynamic SpoolProcClass, 
		      		MSG_GEN_PROCESS_CLOSE_APPLICATION
	uses	bx
	.enter

	; Remove the app object from the GCNSLT_SHUTDOWN_CONTROL system
	; notification list

	mov	cx, handle spoolAppObj
	mov	dx, offset spoolAppObj
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_SHUTDOWN_CONTROL
	call	GCNListRemove

	; Free the error dialog ThreadLock.
	;
	mov	bx, ds:[errorThreadLock]
	call	ThreadFreeThreadLock

	clr	cx		; no state block to save
	.leave
	ret
SpoolCloseApplication endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolApplicationDetachConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The system is about to detach. Determine if there are any
		spool jobs that are printing, and if so, give the user
		a choice to abort the detach.

CALLED BY:	MSG_META_CONFIRM_SHUTDOWN
	
PASS:		*DS:SI	= SpoolApplicationClass object
		ES	= DGroup
		bp	= GCNShutdownControlType

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolApplicationDetachConfirm	method	SpoolApplicationClass,
					MSG_META_CONFIRM_SHUTDOWN
	;
	; Do nothing if told the system is unsuspending itself.
	; 
		cmp	bp, GCNSCT_UNSUSPEND
		je	exit
	;
	; Gain the exclusive right to ask the user to confirm.
	; 
		mov	ax, SST_CONFIRM_START
		call	SysShutdown
		jc	done			; => already denied, so we
						;  do nothing.

		; See if there are any jobs left to be printed
		;
		ornf	es:[spoolStateFlags], mask SS_DETACH_DIALOG

		call	SpoolQueueCheckJobsWantingWarning
		jnc	done			; => none, so do nothing

		; Else put up dialog box querying the user
		;
		mov	bx, handle ErrorBoxesUI
		call	MemLock
		mov	es, ax
		mov	di, offset ShutDownText
		cmp	bp, GCNSCT_SHUTDOWN
		je	haveText
		mov	di, offset SuspendText
haveText:
		mov	di, es:[di]		; text string => ES:DI

		; Now prepare the arguments for the dialog box
		;
		mov	dx, size GenAppDoDialogParams
		sub	sp, dx
		mov	bp, sp			; SS:BP holds the structure
		mov	ss:[bp].SDP_customFlags, 
		    CustomDialogBoxFlags <1, CDT_QUESTION, GIT_AFFIRMATION,0>
		mov	ss:[bp].SDP_customString.high, es
		mov	ss:[bp].SDP_customString.low, di
		;ss:[bp].SDP_customTriggers not needed for GIT_AFFIRMATION
		mov	bx, ds:[LMBH_handle]		; block handle => BX
		mov	ss:[bp].GADDP_finishOD.handle, bx
		mov	ss:[bp].GADDP_finishOD.chunk, si
		mov	ss:[bp].GADDP_message, MSG_SPOOL_APP_DETACH_CHOICE
		clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
		mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; put up the dialog box
		
		mov	es:[spoolConfirmBox].handle, cx
		mov	es:[spoolConfirmBox].chunk, dx

		; Clean up (stack and unlock the strings resource)
		;
		add	sp, size GenAppDoDialogParams
		mov	bx, handle ErrorBoxesUI
		call	MemUnlock
exit:
		ret				; we're done - DON'T fall thru
done:		
		mov	cx, IC_NULL		; just exit now
		FALL_THRU	SpoolApplicationDetachChoice
SpoolApplicationDetachConfirm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolApplicationDetachChoice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user (or an outside caller) has responded with the choice
		to either shutdown, or to cancel the shutdown. We will
		clean up before abiding by his/her wishes.

CALLED BY:	GLOBAL (MSG_SPOOL_APP_DETACH_CHOICE)
	
PASS:		DS:*SI	= SpoolApplicationClass object
		ES	= DGroup
		CX	= InteractionCommand
				IC_NO - abort the shutdown
				anything else - shutdown
RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolApplicationDetachChoice	method	SpoolApplicationClass, \
					MSG_SPOOL_APP_DETACH_CHOICE
		.enter

		; If user cancels, abort the shutdown
		;
		test	es:[spoolStateFlags], mask SS_DETACH_DIALOG
		jz	done			; if flag cleared, do nothing
		mov	ax, FALSE		; assume no shutdown
		cmp	cx, IC_NO		; cancel the shutdown
		je	callField		; cancel - so go do it!
		mov	ax, TRUE		; yes - we're shutting down

		; Call SysShutdown telling it our decision
		;
callField:
		and	es:[spoolStateFlags], not (mask SS_DETACH_DIALOG)
		mov_tr	cx, ax			; TRUE/FALSE
		mov	ax, SST_CONFIRM_END
		call	SysShutdown

done:
		.leave
		ret
SpoolApplicationDetachChoice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_META_DETACH for spooler app

CALLED BY:	GLOBAL

PASS:		ax	- method number

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Check to see if we have any running threads.  If not, just
		exit, else kill everything -- but quietly.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolDetach	method	SpoolProcClass, MSG_META_DETACH
		.enter

		; lock the Queue to see if anything there

		PSem	ds, queueSemaphore	; exclusive access
		mov	ds:[spoolAckOD].handle, 0; init OD to zero
		mov	ds:[spoolAckOD].chunk, 0	
		ornf	ds:[spoolStateFlags], mask SS_DETACHING ; set a flag

		; see if there are still threads printing

		tst	ds:[queueHandle]	; anything printing ?
		jnz	killPrintThreads	;  yes, kill them

		; nothing printing. just pass along the DETACH

		VSem	ds, queueSemaphore
		.leave
		mov	di, offset SpoolProcClass
		GOTO	ObjCallSuperNoLock

killPrintThreads:
		; kill all the threads.  
		; must wait until all the threads are gone before we pass
		; this message on to our superclass.

		mov	ds:[spoolAckOD].handle, dx 	; Save Ack OD
		mov	ds:[spoolAckOD].chunk, bp	
		mov	ds:[spoolAckID], cx		; save ID as well	

		call	KillPrinting		; kill it baby

		VSem	ds, queueSemaphore, TRASH_AX_BX
		.leave
		ret
SpoolDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KillPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	All the threads will die of natural causes, if we give them
		a little help. So we tell each queue's current job to abort.
		and remove the linkage to any subsequent jobs.

CALLED BY:	MSG_META_DETACH (see above)

PASS:		ds	- dgroup
		have queueSemaphore 

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lock the queue;
		for each printer queue
			tell the first job to abort
			set the first job's next ptr null
		free the queue;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Don	10/90		Clean up detach preparation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KillPrinting	proc	near
		uses	ax, bx, di, si, ds
		.enter

		; lock down the queue and kill all the threads

		mov	bx, ds:[queueHandle]	; lock the queue
		call	MemLock			; ax = segment
		mov	ds, ax			; ds -> queue
		call	SaveQueueState		; write the file to disk

		; loop through each queue
		;
		mov	si, ds:[PQ_firstQueue]	; chunk handle of 1st queue
queueLoop:
		mov	si, ds:[si]		; get pointer to QueueInfo
		mov	ds:[si].QI_error, SI_DETACH ; set abort signal
		mov	si, ds:[si].QI_next	; get handle of next one
		tst	si			; all done ?
		jnz	queueLoop		;  no, continue

		; Clean up
		;
		call	MemUnlock		; release the queue

		.leave
		ret
KillPrinting	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveQueueState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the queue to a state file in case we die.
		Kind of like a last will....

CALLED BY:	KillPrinting

PASS:		ds	- pointer to Queue block
		Queue semaphore down

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just write out the current state of things;

		The "official" state file for the spooler is spoolsta.dat
		and it is kept in the spool directory.  When the system 
		boots, it looks for this file and will start things going 
		if it finds it.  

		To ensure that we always have something, this routine
		goes throught the following steps:
			* rename the current spoolsta.dat to spoolsta.bak
			* write out the current state block to spoolsta.dat


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaveQueueState	proc	near
		uses	ds, es, di, si, ax, bx, cx, dx
		.enter 

		; save the current directory and get to the spool directory

		push	ds			; save pointer to block
		mov	ax, SP_SPOOL		; just use standard call
		call	FileSetStandardPath

		; delete the old one

		mov	dx, dgroup		; filenames in idata
		mov	ds, dx
		mov	es, dx			; we'll need it here later
		mov	dx, offset dgroup:stateFile 
		call	FileDelete

		; now create a new one

		mov	ah, FILE_CREATE_TRUNCATE
		mov	al, FILE_DENY_W or FILE_ACCESS_W
		mov	cx, FILE_ATTR_NORMAL
		call	FileCreate			; create the file

		; calc how much to write

		pop	ds				; restore ptr to blk
		push	ax				; save file handle
		mov	bx, ds:[PQ_header].LMBH_handle	; fetch handle
		mov	ax, MGIT_SIZE
		call	MemGetInfo			; return info

		; write out the contents of the current buffer. We set
		; LMBH_handle to the current nextJobID so we don't confuse
		; the issue when restarting.

		mov_tr	cx, ax				; all we want is size
		mov_tr	ax, bx				; ax <- block handle
		pop	bx				; restore file handle
		push	ax
		mov	ax, es:[nextJobID]
		mov	ds:[LMBH_handle], ax
		mov	al, FILE_NO_ERRORS		; set some flags
		clr	dx				; ds:dx -> buffer
		call	FileWrite
		call	FileClose			; all done
		pop	ds:[LMBH_handle]		; restore block handle

		.leave
		ret
SaveQueueState	endp

SpoolExit	ends



QueueManagement	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolThreadExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Printing thread exiting notification

CALLED BY:	MSG_PROCESS_NOTIFY_THREAD_EXIT

PASS:		cx	- thread ID of exiting thread
		dx	- exit code

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		printing thread has exited, check to see if we should boogie

		try to lock the queue.  if we can, then we don't exit, else
		check to see if the spoolAckOD is zero.  If not, then send
		a MSG_META_DETACH to it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolThreadExit	method		SpoolProcClass,
					MSG_PROCESS_NOTIFY_THREAD_EXIT

		call	LockQueue	; lock it down
		jc	noJobsLeft	; bad PrintQueue - means no jobs left

		; OK, there is a printQueue.  This means that either there are
		; other threads printing, or the thread we're being notified
		; about has been killed by something else (like an out of 
		; memory error that the user has signaled "abort").  To make
		; sure that the thread that is leaving has exited properly,
		; we need to go through all the queues, and search for a 
		; match for the thread ID.  If we find a match, then we need
		; to remove all the jobs from that queue, remove the queue,
		; and check again for more printing threads.

		mov	es, ax			; es -> printQueue
		mov	di, es:[PQ_firstQueue]	; handle of first queue
qLoop:
		mov	si, es:[di]		; dereference the queue
		cmp	es:[si].QI_thread, cx	; is this our beautiful thread?
		je	murderMurder		; we were killed.  
		mov	di, es:[si].QI_next	; follow down the next thread
		tst	di			; any more to check ?
		jnz	qLoop			;  yes, keep checking
done:
		call	UnlockQueue		; still going, just continue
		ret

		; bad queue handle, time to quit. Check for non-zero spoolAckOD
noJobsLeft:
		test	es:[spoolStateFlags], mask SS_DETACH_DIALOG
		jz	finishNoJobs

	;
	; Pretend the user clicked Yes so we confirm with the system the
	; shutdown/suspend is ok by us.
	; 
		mov	bx, es:[spoolConfirmBox].handle
		mov	si, es:[spoolConfirmBox].chunk
		mov	cx, IC_YES
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		clr	di
		call	ObjMessage
		jmp	done

finishNoJobs:
	;
	; If MSG_META_DETACH was received, pass it on to our superclass
	; (finally).
	; 
		test	es:[spoolStateFlags], mask SS_DETACHING
		jz	done

		clr	dx, bp
		xchg	ds:[spoolAckOD].handle, dx
		xchg	ds:[spoolAckOD].chunk, bp  ; ACK OD => DX:BP
		mov	cx, ds:[spoolAckID]	   ; set up ID as well
		mov	di, offset SpoolProcClass
		mov	ax, MSG_META_DETACH	; set up method to send
		CallSuper	MSG_META_DETACH
		jmp	done

		; OK, the thread was knocked off by something else (memory
		; full error ?).  We need to remove the cancer from the 
		; PrintQueue and get outta here.  If this was the only job
		; left, then just biff the block and continue with the detach.
		; We also need to biff the use of the printer driver and port
		; driver, so that they get freed.
murderMurder:
		mov	bx, es:[si].QI_portHan	; remove the port driver
		tst	bx			; don't remove unfit drivers
		jz	tryPrinterDriver
		call	GeodeFreeDriver
tryPrinterDriver:
		mov	bx, es:[si].QI_pdHan	; remove the printer driver
		tst	bx
		jz	howManyQueues
		call	GeodeFreeDriver
howManyQueues:
		cmp	es:[PQ_numQueues], 1	; is ours the only one ?
		jne	elimOneQueue		;  yes, kill the SOB

		; this is the only queue.  so biff the block and leave.

		mov	bx, es:[LMBH_handle]	; get handle of this block
		call	MemFree			; be gone with it
		clr	ds:[queueHandle]	; no queue left
		jmp	noJobsLeft		;  and be gone

		; There are other print queues to be considered.  Just get
		; rid of our queue and all the jobs in it.  Currently, we
		; have ds:si -> our queue, di = lmem handle to our queue
elimOneQueue:
		cmp	di, es:[PQ_firstQueue]	; were we the first ?
		jne	followQueues		;  no, keep going
		mov	di, es:[si].QI_next	; get the next handle
		mov	es:[PQ_firstQueue], di	;  and save it as head
		jmp	weAreHistory		; unlock the queue and wait more
followQueues:
		mov	bx, es:[PQ_firstQueue]	; load up the first queue
sonOfQLoop:
		mov	bx, es:[bx]		; get pointer to next queue
EC <		tst	bx			; we are hosed if this is 0 >
EC <		ERROR_Z SPOOL_PRINT_Q_IS_MESSED_UP ; whoa.  
		cmp	es:[bx].QI_next, di	; found it yet ?
		je	foundUs			;  yes
		mov	bx, es:[bx].QI_next	;  no, keep looking
		jmp	sonOfQLoop

		; we found ourselves. relink.
foundUs:
		mov	di, es:[si].QI_next	; stuff our next pointer
		mov	es:[bx].QI_next, di	; into prev's next field
weAreHistory:
		dec	es:[PQ_numQueues]	; done with one more...
		jmp	done
SpoolThreadExit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCommError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There's a problem with a parallel port....

CALLED BY:	MSG_SPOOL_COMM_ERROR

PASS:		cx	- print queue handle for affected queue
		dx	- error type

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Set the error flag in the print queue, so the printing thread
		can find it next time it looks.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCommError 	method	SpoolProcClass, MSG_SPOOL_COMM_ERROR
		uses	ax,bx,si
		.enter

		; lock the print queue and set the error flag.  The thread
		; will query the comm driver to figure out what the error
		; was.

		call	LockQueue			; ax -> queue block
		mov	ds, ax				; ds -> queue block

		; before we go tromping on some other block, make sure the
		; queue we're after still exists.  Just follow the chain of
		; queues until we find one that matches.  It will probably
		; be the first one, since there won't be but one queue most
		; of the time.

		mov	si, ds:[PQ_firstQueue]		; get first queue hand
qSearchLoop:
		cmp	si, cx				; if we have a match
		je	foundQueue
		tst	si				; if NULL, we're sunk
		jz	done
		mov	si, ds:[si]			; follow queue chain
		jmp	qSearchLoop

		; found one we like.  Set the error flag.
foundQueue:
		CallMod	CommPortErrorHandler		; *ds:si -> queue
		jnc	done				;  no error
		mov	si, ds:[si]			; deref queue han
		mov	ds:[si].QI_error, SI_ABORT	; set abort flag
done:
		call	UnlockQueue			; release the queue
		.leave
		ret
SpoolCommError 	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCommInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There's data coming in !  Ignore it !

CALLED BY:	MSG_SPOOL_COMM_INPUT

PASS:		cx	- print queue handle for affected queue
		dx	- error type

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Set the error flag in the print queue, so the printing thread
		can find it next time it looks.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCommInput 	method	SpoolProcClass, MSG_SPOOL_COMM_INPUT
		uses	ax,bx,si
		.enter

		; lock the print queue and set the error flag.  The thread
		; will query the comm driver to figure out what the error
		; was.

		call	LockQueue			; ax -> queue block
		mov	ds, ax				; ds -> queue block

		; before we go tromping on some other block, make sure the
		; queue we're after still exists.  Just follow the chain of
		; queues until we find one that matches.  It will probably
		; be the first one, since there won't be but one queue most
		; of the time.

		mov	si, ds:[PQ_firstQueue]		; get first queue hand
qSearchLoop:
		cmp	si, cx				; if we have a match
		je	foundQueue
		tst	si				; if NULL, we're sunk
		jz	done
		mov	si, ds:[si]			; follow queue chain
		jmp	qSearchLoop

		; found one we like.  Read the data and quit.
foundQueue:
		CallMod	CommPortInputHandler		; *ds:si -> queue
		jnc	done				;  no error
		mov	si, ds:[si]			; deref queue han
		mov	ds:[si].QI_error, SI_ABORT	; set abort flag
done:
		call	UnlockQueue			; release the queue
		.leave
		ret
SpoolCommInput 	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolJobRemoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method received when a job exits

PASS:		cx - job id
		dx - PrinterPortType 
		bp - ParallelPortNum or SerialPortNum


RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANEL
SpoolJobRemoved		method dynamic SpoolProcClass, MSG_SPOOL_JOB_REMOVED
		.enter

		mov_tr	ax, dx
		mov	bx, bp
		call	SpoolPanelJobRemoved

		.leave
		ret
SpoolJobRemoved		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolJobAdded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method received when a job is added to a queue

PASS:		cx - job id
		dx - PrinterPortType 
		bp - ParallelPortNum or SerialPortNum


RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANEL
SpoolJobAdded		method dynamic SpoolProcClass, MSG_SPOOL_JOB_ADDED
		.enter

		mov_tr	ax, dx
		mov	bx, bp
		call	SpoolPanelJobAdded

		.leave
		ret
SpoolJobAdded		endp
endif

QueueManagement	ends



;-------------------------------------------------------------------------
;
;	START OF IDATA (FIXED) SEGMENT
;
;-------------------------------------------------------------------------

idata	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCreateThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a printing thread

CALLED BY:	SpoolAddJob (via method call)

PASS:		cx	- chunk handle of Job to create thread for

RETURN:		nothing

DESTROYED:	doesn't matter

PSEUDO CODE/STRATEGY:
		Allocate a device queue and create a print thread

		To minimize the amount of code in fixed space,
		most of the code implementing this function has been
		moved into a non-fixed resource. This may add a few
		cross-module calls, but it reduces the spooler's dgroup.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCreateThread method SpoolProcClass, MSG_SPOOL_CREATE_THREAD
		.enter

		; insert the job into the queue, or find that the
		; queue doesn't yet exist.

		call	CreateThreadStart
		jc	incNumJobs		; if inserted, go finish up

		; now that everything is in order, create the queue and thread
		; we need to copy the JobInfoStruct onto the stack, so we can 
		; pass a valid pointer to it.  If we leave it in the block, then
		; the first LMemReAlloc (done right away in AllocDeviceQueue) 
		; will move our JIS block and cause all sorts of pain.

		mov	si, cx			; pass job handle
		call	AllocDeviceQueue
		mov	si, ds:[si]		; dereference handle again
		tst	bx			; problems allocating queue?
		jz	done			;  yes, just quit

		; now insert the job into the queue

		call	CreateThreadEnd

		; job inserted, so inc the number of jobs to do
incNumJobs:
		inc	ds:[PQ_numJobs]		; one more job in queue

		; notify process that a job has been added

		mov	bx, cx	
		call	SendJobAddedNotification
done:
		call	UnlockQueue		; release it

		.leave
		ret
SpoolCreateThread endm

idata	ends



QueueManagement	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateThreadStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the process of creating a thread for a print queue

CALLED BY:	SpoolCreateThread

PASS:		cx	- JobInfoStruct chunk handle

RETURN:		ds:si	- JobInfoStruct in locked queue block
		bx	- queue handle (may be zero)
		carry	- clear if no queue, set otherwise

DESTROYED:	ax, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateThreadStart	proc	far
		.enter
	
		; get a hold of the PrintQueue.  We know the block exists,
		; since our caller created one if it didn't exist before.

		call	LockQueue		; lock it down
		mov	ds, ax			; ds -> PrintQueue
		mov	si, cx			; *ds:si -> print job info
		mov	si, ds:[si]		; dereference handle

		; now we have the job info.  Before we go allocating another
		; queue and printing thread, we should make sure that one
		; didn't get created between the time the method was sent and
		; now.  This could happen if a few jobs get queued up right
		; in a row.

		segmov	es, ds			; es -> PrintQueue
		add	si, JIS_info.JP_portInfo
		call	FindRightQueue		; see if it has been created
		sub	si, JIS_info.JP_portInfo
		tst	bx
		jz	done			; carry is clear

		mov	ds:[si].JIS_queue, bx	; save queue handle for job
		mov	ax, cx			; get job handle in ax
		call	InsertJobIntoQueue	; insert the job
		stc				; indicate job was inserted
done:
		.leave
		ret
CreateThreadStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateThreadEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete the process of creating a thread for a print queue

CALLED BY:	SpoolCreateThread

PASS:		ds:si	- JobInfoStruct
		cx	- JobInfoStruct handle
		bx	- queue handle

RETURN:		Nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateThreadEnd	proc	far
		.enter
	
		; save the handle of the queue in the job info struct

		mov	ds:[si][JIS_queue], bx	; save queue handle in job info

		; the job block is all initialized, so 
		; now that we have the queue, insert the job
		; dereference the queue handle.  If there are no jobs yet,
		; just make this one the current job.  Else follow the chain
		; until we hit the end.

		mov	bx, ds:[bx]		; ds:bx -> queue info block
		cmp	ds:[bx].QI_curJob, 0	; any jobs in the queue ?
		jne	followChain		;  yes, follow the chain
		mov	ds:[bx].QI_curJob, cx	; store the job handle
		clr	ax
		mov	ds:[bx].QI_fileHan, ax	; clear out all the other info
		mov	{word} ds:[bx].QI_filePos, ax
		mov	{word} ds:[bx].QI_filePos+2, ax
		mov	ds:[bx].QI_curPage, ax
done:
		.leave
		ret

		; at least one job is in the queue, follow the links
followChain:
		mov	si, ds:[bx].QI_curJob
linkLoop:
		mov	si, ds:[si]		; dereference next handle
		cmp	ds:[si].JIS_next, 0	; is this the end ?
		je	foundIt			;  yes, finish up
		mov	si, ds:[si].JIS_next	;  no, get next link
		jmp	linkLoop
foundIt:
		mov	ds:[si].JIS_next, cx	; save link
		jmp	done
CreateThreadEnd	endp

QueueManagement	ends


if _PRINTING_DIALOG
PrintThread	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		SpoolProcKillFirstJob -- 
		MSG_SPOOL_KILL_FIRST_JOB for SpoolProcClass

DESCRIPTION:	Kills the first job.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPOOL_KILL_FIRST_JOB
		cx	- handle of resource holding dialog box

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
	chris	11/30/93         Initial Version

------------------------------------------------------------------------------@

SpoolProcKillFirstJob	method dynamic	SpoolProcClass, \
				MSG_SPOOL_KILL_FIRST_JOB

		; lock down the queue and kill the first print job.

		mov	bx, ds:[queueHandle]	; lock the queue
		tst	bx
		jz	updateUI
		call	MemLock			; ax = segment
		mov	ds, ax			; ds -> queue
		mov	si, ds:[PQ_firstQueue]	; chunk handle of 1st queue
		tst	si			; is there a queue?
		jz	unlock			; ...no - we're done
		mov	si, ds:[si]		; get pointer to QueueInfo
		mov	ds:[si].QI_error, SI_ABORT ; set abort signal

		; I have no ides why we're doing this, but the code was
		; already there so I hope it works. Sigh.  -Don 5/14/00

		mov	di, ds:[si].QI_curJob	; handle of first job => DI
		tst	di			; is there a job ?
		jz	unlock			; ...no - we're done
		mov	di, ds:[di]		; JobInfoStruct => DS:DI
		mov	ds:[di].JIS_next, 0	; clear any next pointer
unlock:
		call	MemUnlock		; release the queue

		; update the UI so the user sees something immediately
updateUI:
		mov	bx, cx
		mov	ax, MSG_GEN_SET_NOT_USABLE	
		mov	si, offset PDPrintingGlyph
		call	sendMessage

		mov	ax, MSG_GEN_SET_NOT_USABLE	
		mov	si, offset PDExplanation
		call	sendMessage

		mov	ax, MSG_GEN_SET_NOT_USABLE	
		mov	si, offset PDChoice
		call	sendMessage

		mov	ax, MSG_GEN_SET_USABLE
		mov	si, offset PDCancelledGlyph
		call	sendMessage

		; disable the Cancel and Pause trigger.

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	si, offset PDCancelTrigger
		call 	sendMessage

ife _NO_PAUSE_RESUME_UI
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	si, offset PDPauseTrigger
		call	sendMessage
endif
		ret

		; send a message - doing this to save a few bytes
sendMessage:
		mov	dl, VUM_NOW
		clr	di			; no message flag.
		call	ObjMessage
		retn
SpoolProcKillFirstJob	endm


COMMENT @----------------------------------------------------------------------

METHOD:		SpoolProcPauseFirstJob -- 
		MSG_SPOOL_PAUSE_FIRST_JOB for SpoolProcClass

DESCRIPTION:	Pauses the first job.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPOOL_PAUSE_FIRST_JOB

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
	chris	11/30/93         Initial Version

------------------------------------------------------------------------------@

ife _NO_PAUSE_RESUME_UI
SpoolProcPauseFirstJob	method dynamic	SpoolProcClass, \
				MSG_SPOOL_PAUSE_FIRST_JOB

		; lock down the queue and Pause the first print job.

		mov	bx, ds:[queueHandle]	; lock the queue
		call	MemLock			; ax = segment
		mov	ds, ax			; ds -> queue

		mov	si, ds:[PQ_firstQueue]	; chunk handle of 1st queue
		mov	si, ds:[si]		; get pointer to QueueInfo
		cmp	ds:[si].QI_error, SI_KEEP_GOING
		je	10$
		cmp	ds:[si].QI_error, SI_PAUSE
		jne	20$
10$:
		xor	ds:[si].QI_error, SI_PAUSE
20$:
		call	MemUnlock		; release the queue
		ret
SpoolProcPauseFirstJob	endm
endif ; !_NO_PAUSE_RESUME_UI

PrintThread	ends
endif	; if _PRINTING_DIALOG
