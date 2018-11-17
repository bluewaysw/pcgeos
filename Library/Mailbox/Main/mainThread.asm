COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mainThread.asm

AUTHOR:		Adam de Boor, Nov 23, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/23/94	Initial revision


DESCRIPTION:
	Functions for tracking transmission and reception threads.
		

	$Id: mainThread.asm,v 1.1 97/04/05 01:21:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MainThreadCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainThreadLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the thread array for exclusive access

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		*ds:si	= mainThreads
DESTROYED:	nothing
SIDE EFFECTS:	caller must call MainThreadUnlock at some point to release
     			exclusive access

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainThreadLock		proc	far
		uses	ax, bx
		.enter
		mov	bx, handle MainThreads
		call	MemPLock
	;
	; Locate the silly thing.
	; 
		mov	ds, ax
		mov	si, offset mainThreads
		.leave
		ret
MainThreadLock		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainThreadFindCurrentThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the current thread's data in MainThreads

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN: 	ds:di	= MainThreadData (must call MainThreadUnlock
			  when done)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainThreadFindCurrentThread	proc	far
		uses	bx, ax
		.enter
		clr	bx
		mov	ax, TGIT_THREAD_HANDLE
		call	ThreadGetInfo
		call	MainThreadFindByHandle		;returns carry clear if
							; found
							; ds:di = MainThreadData
EC <		ERROR_C CURRENT_THREAD_HAS_NO_THREAD_DATA		>
		.leave
		ret
MainThreadFindCurrentThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainThreadFindByHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the data for a specific thread, whose handle is passed

CALLED BY:	(EXTERNAL) MainThreadFindCurrentThread,
			   MPBGenGupInteractionCommand
PASS:		ax	= thread handle
RETURN:		carry set if not found:
			ds	= PLocked MainThreads block
			di	= destroyed
		carry clear if found:
			ds:di	= MainThreadData
		caller must call MainThreadUnlock when done, regardless of carry
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainThreadFindByHandle proc	far
		uses	cx, si, ax
		.enter
		mov_tr	cx, ax		; cx <- thread handle

		mov	bx, cs
		mov	di, offset MThFindCurrentThreadCallback
		call	MainThreadEnum
	;
	; Return offset in DI.
	; 
		mov_tr	di, ax
	;
	; Return carry clear if found.
	;
		cmc
		.leave
		ret
MainThreadFindByHandle endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MThFindCurrentThreadCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate the current thread

CALLED BY:	(INTERNAL) MainThreadFindCurrentThread via ChunkArrayEnum
PASS:		*ds:si	= threads array
		ds:di	= MainThreadData to check
		cx	= handle of current thread
RETURN:		carry set to stop enumerating:
			ds:ax	= MainThreadData for current thread
		carry clear to keep looking
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MThFindCurrentThreadCallback proc far
		.enter
		cmp	ds:[di].MTD_thread, cx
		clc
		jne	done
		mov_tr	ax, di
		stc
done:
		.leave
		ret
MThFindCurrentThreadCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainThreadUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the MainThreads block

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	EC: ds/es nuked if pointing to block (as usual)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainThreadUnlock	proc	far
		uses	bx
		.enter
		mov	bx, handle MainThreads
		call	MemUnlockV
		.leave
		ret
MainThreadUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECMainThreadDSIsThreadData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECMainThreadDSIsThreadData proc	far
		.enter
		cmp	ds:[LMBH_handle], handle MainThreads
		ERROR_NE	DS_NOT_THREAD_DATA
		.leave
		ret
ECMainThreadDSIsThreadData endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainThreadCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an entry for the newly-spawned thread

CALLED BY:	(EXTERNAL)
PASS:		ds	= PLocked MainThreads block
		ax	= MainThreadType
		bx	= thread handle
		cx	= size of data for entry
RETURN:		ds:di	= array entry, with MTD_thread, MTD_type, and
			  MTD_gen filled in; all else is 0
DESTROYED:	ax, cx
SIDE EFFECTS:	block and thread array may both move
    		mtGeneration is advanced

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainThreadCreate proc	far
		uses	si
		.enter
EC <		call	ECMainThreadDSIsThreadData			>
		Assert	ge, cx, <size MainThreadData>
	;
	; Thread successfully created, so append an entry to the mainThreads
	; array and store the thread handle in there. All the rest is
	; initialized to zero by ChunkArrayAppend
	; 
		mov	si, offset mainThreads
		xchg	ax, cx			; ax <- elt size
		call	ChunkArrayAppend
		mov	ds:[di].MTD_thread, bx
		mov	ds:[di].MTD_type, cl

		mov	ax, ds:[mtGeneration]
		mov	ds:[di].MTD_gen, ax
		inc	ax
		mov	ds:[mtGeneration], ax

		.leave
		ret
MainThreadCreate endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainThreadDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the entry for a thread, returning the ack OD/ID
		registered for the thing.

CALLED BY:	(EXTERNAL)
PASS:		ds:di	= MainThreadData to nuke
RETURN:		cx	= ack ID
		dx:bp	= ack OD
DESTROYED:	ds
SIDE EFFECTS:	MainThreads block is released
     		progress box is destroyed, if it existed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainThreadDestroy proc	far
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		uses	si, ax, bx
else
		uses	si
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
		.enter
EC <		call	ECMainThreadDSIsThreadData			>
 	;
	; Load up registers for our caller to return.
	;
		mov	cx, ds:[di].MTD_ackID
		movdw	dxbp, ds:[di].MTD_ackOD
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		movdw	bxax, ds:[di].MTD_progress
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

	;
	; Remove the OutboxThreadData
	; 
		mov	si, offset mainThreads
		call	ChunkArrayDelete
	;
	; Release the OutboxThreads block, finally.
	; 
		call	MainThreadUnlock

if	MAILBOX_PERSISTENT_PROGRESS_BOXES
	;
	; Destroy the progress box, if it exists.
	;
		tst	bx
		jz	progressGone
	;
	; Take the progress box down and nuke the block it's in.
	; 
		push	cx, dx, bp
		mov_tr	si, ax
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		clr	bp
		clr	di
		call	ObjMessage
		mov	ax, MSG_META_BLOCK_FREE
		mov	di, mask MF_CALL	; Insist on calling, so
						;  class is definitely changed
						;  by the time we return
		call	ObjMessage
		pop	cx, dx, bp
progressGone:
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
		.leave
		ret
MainThreadDestroy endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainThreadEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the known transmit/receive threads

CALLED BY:	(EXTERNAL)
PASS:		bx:di	= callback routine (vfptr)
			Pass:
				ds:di	= MainThreadData
				*ds:si	= chunk array
				cx, dx, bp, es = callback data
			Return:
				carry set to stop enumerating:
					ax, cx, dx, bp, es = data to return
			   	carry clear to keep going:
			   		cx, dx, bp, es = data for next callback
		cx, dx, bp, es = data for callback routine
RETURN:		carry set if callback returned carry set
			ax, cx, dx, bp, es = as returned by callback
	   	carry clear if callback never returned carry set
			ax, cx, dx, bp, es = as returned by callback
	   	ds = PLocked MainThreads block
DESTROYED:	nothing
SIDE EFFECTS:	caller must call MainThreadUnlock when done

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainThreadEnum	proc	far
		uses	si
		.enter
		call	MainThreadLock			; ds <- MainThreads
		call	ChunkArrayEnum
		.leave
		ret
MainThreadEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainThreadMessageProgressBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the progress box for the current thread

CALLED BY:	(EXTERNAL)
PASS:		ax	= message to send
		cx, dx, bp = data to pass
		di	= MessageFlags
RETURN:		whatever ObjMessage returns
DESTROYED:	whatever
SIDE EFFECTS:	whatever

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
MainThreadMessageProgressBox proc	far
		uses	bx, si
		.enter
		push	di, ds
		call	MainThreadFindCurrentThread	; ds:di <- data
		movdw	bxsi, ds:[di].MTD_progress
		call	MainThreadUnlock
		pop	di, ds
		call	ObjMessage
		.leave
		ret
MainThreadMessageProgressBox endp
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxReportProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the progress display on this thread's progress box

CALLED BY:	(GLOBAL)
PASS:		ax	= MailboxProgressType
			  MPT_PERCENTAGE:
			  	cx	= percentage to display
			  MPT_PAGES:
				cx	= current page
				dx	= total pages (0 to not give total)
			  MPT_STRING:
			  	^lcx:dx	= optr of string
		bp	= MailboxProgressAction
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The RESPONDER version of this routine stores the progress
		string at the end of the MailboxInternalTransAddr, right
		after the human readable version of the address.

		To find the status string, you move past the opaque data,
		(MITA_opaqueLen gets you the size of that data), then
		find the end of the human readable string, that is where
		the status string begins.  It is null terminated.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxReportProgress proc	far
if	MAILBOX_PERSISTENT_PROGRESS_BOXES
		uses	di
		.enter
		push	bp, 			; MPBSPA_action
			cx,			; MPBSPA_cx
			dx,			; MPBSPA_dx
			ax			; MPBSPA_type
		mov	bp, sp
		mov	dx, size MPBSetProgressArgs
		mov	di, mask MF_STACK

	;
	; If the things are strictly numeric, and thus there's no danger of
	; them going away while the progress box dawdles its way through the
	; method, we can just ship the message off.
	;
		cmp	ax, MPT_PERCENTAGE
		je	sendMessage
		cmp	ax, MPT_PAGES
		je	sendMessage
		cmp	ax, MPT_BYTES
		je	sendMessage
	;
	; Args might be volatile -- wait until the method completes to return.
	;
		ornf	di, mask MF_CALL
sendMessage:
		mov	ax, MSG_MPB_SET_PROGRESS
		call	MainThreadMessageProgressBox
		pop	bp, 			; MPBSPA_action
		dx,			; MPBSPA_dx
		cx,			; MPBSPA_cx
		ax			; MPBSPA_type
		.leave
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES
		ret
MailboxReportProgress endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxReportGetMailboxMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find the MailboxMessage we are sending, and locate the
		MailboxInternalTransAddr that goes with it

CALLED BY:	MailboxReportProgress

PASS:		nothing

RETURN:		dxax	= MailboxMessage
		ds:si	= trans addr array
		ds:di	= MailboxInternalTransAddr
		cx	= size of MailboxInternalTransAddr

		carry set if failed

DESTROYED:	bx

NOTES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxReportLocateStatusString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find the end of the user-readable address, which is the
		beginning of where the status string will go

CALLED BY:	MailboxReportProgress

PASS:		es:di is MailboxInternalTransAddr
		cx is size of element

RETURN:		es:di is end of address (one past the null)
		es:si is the passed MailboxInternalTransAddr
		cx is bytes left after address

DESTROYED:	ax

NOTES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGenerateStatusMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	allocates a block and puts a status string into it

CALLED BY:	MailboxReportProgress

PASS:		ax	MailboxProgressType
			  MPT_PERCENTAGE:
			  	cx	= percentage to display
			  MPT_PAGES:
				cx	= current page
				dx	= total pages (0 to not give total)
			  MPT_STRING:
			  	^lcx:dx	= optr of string
			  MPT_BYTES:
				cxdx	= number of bytes

RETURN:		ds:si	= status string
		cx	= size of string (including null)
		bx	= handle of locked block (that might need to be freed)

DESTROYED:	nothing

NOTES:		The handle returned in bx needs to be freed if the
		MailboxProgressType is anything other than MPT_STRING

		In the case of MPT_STRING the block must be unlocked.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Get*Template
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the template string for the passed MailboxProgressType

CALLED BY:	MailboxGenerateStatusMessage

PASS:		bp is stack frame
		bx is MailboxProgressType

RETURN:		si is chunk holding template, 0 if invalid
		cx = routine to call for \1
		dx = routine to call for \2

DESTROYED:	nothing

NOTES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainThreadCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the cancel flag for a thread.

CALLED BY:	(EXTERNAL)
PASS:		ds:di	= MainThreadData to use
		ax	= MailboxCancelAction to set
		cx	= ack ID
		dx:bp	= ack OD
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	cancelAction will be sent out, if registered

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainThreadCancel proc	far
		uses	es, bx, di, si
		.enter
EC <		call	ECMainThreadDSIsThreadData			>
	;
	; If no ack OD set for the thread yet, set it to what we were passed.
	;
		tst	ds:[di].MTD_ackOD.handle
		jnz	findFlag
		
		movdw	ds:[di].MTD_ackOD, dxbp
		mov	ds:[di].MTD_ackID, cx
EC <		clr	dx						>
findFlag:
EC <		tst	dx						>
EC <		ERROR_NZ MULTIPLE_ACK_ODS_FOR_THREAD			>

	;
	;Point to the flag and set it and the extent (just this message, unless
	;the user says otherwise). Note: we must set the extent first, lest
	;the thread look at the potential garbage in OCF_extent between
	;when we would have set the flag and would have set the extent.
	; 
		les	bx, ds:[di].MTD_cancelFlag

		Assert	fptr, esbx
		mov	es:[bx], ax			; set the flag
	;
	; If cancel action registered for the thread, send out that message.
	; 
		mov	bx, ds:[di].MTD_cancelAction.AD_OD.handle
		tst	bx
		jz	checkTransmit

		mov_tr	cx, ax				; pass action in CX
		mov	si, ds:[di].MTD_cancelAction.AD_OD.chunk
		mov	ax, ds:[di].MTD_cancelAction.AD_message
		push	di
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	di
checkTransmit:
		cmp	ds:[di].MTD_type, MTT_TRANSMIT
		jne	done
		call	OutboxThreadCancel
done:
		.leave
		ret
MainThreadCancel endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainThreadCheckForThreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there are any threads registered

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		carry set if there are any threads registered
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/20/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainThreadCheckForThreads proc	far
		uses	ds, si, cx
		.enter
		call	MainThreadLock
		call	ChunkArrayGetCount
		clc
		jcxz	done
		stc
done:
		call	MainThreadUnlock
		.leave
		ret
MainThreadCheckForThreads endp


MainThreadCode	ends
