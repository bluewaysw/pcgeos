COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		irlapEvent.asm

AUTHOR:		Cody Kwok, May 12, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/12/94   	Initial revision


DESCRIPTION:
	Event handling of IRLAP:
	Event handling loop,
	event handlers for states.
		

	$Id: irlapEvent.asm,v 1.1 97/04/18 11:56:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapResidentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The event handler of the new thread,  never
		returns.

CALLED BY:	MSG_META_ATTACH
PASS:		ds, es	= dgroup
		ax	= MSG_META_ATTACH
RETURN:		nothing
DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapAttach	method dynamic IrlapProcessClass, MSG_META_ATTACH
		.enter
		
	;
	; Get the event queue of current thread
	;
		mov	ax, TGIT_QUEUE_HANDLE
		clr	bx			; get info about current thread
		call	ThreadGetInfo		; ax = queue handle
		mov	dx, ax			; dx = queue handle
		mov	ax, TGIT_THREAD_HANDLE	; get the current thread handle
		call	ThreadGetInfo
		mov	bp, ax			; bp = thread handle
	;
	; Get the station segment.
	; Should be the second message ever sent to this thread.
	;
		mov_tr	bx, dx			;
		call	QueueGetMessage		; ax = event handle
		mov	bx, ax			; bx = event handle
		call	ObjGetMessageInfo	; ax = station segment
		mov	ds, ax		
		call	ObjFreeMessage		; free this dummy
if 0
	;
	; We absolutely need irlap event thread to have priority over other
	; threads; if other threads interrupt this thread, especially if
	; irlap server thread does, protocol integrity is threatened
	;						- SJ
	;
		
	;
	; Setup a continual timer that periodically cranks up the
	; irlap event thread's priority, so that it will run with
	; a certain regularity.  The thread priority is reduced after
	; a packet is transmitted.
	;
		push	dx			;save queue handle
		mov	al, TIMER_ROUTINE_CONTINUAL
		mov	bx, segment IrlapTimerCrankUpPriority
		mov	si, offset IrlapTimerCrankUpPriority
		mov	di, 12			;12 ticks = 200 ms
		mov	cx, 12			;start soon
		mov	dx, bp			;timer data passed in ax
						;  is the thread handle.
		call	TimerStart		;ax = timerID
						;bx = timer handle
		mov	ds:[IS_priorityTimerID], ax
		mov	ds:[IS_priorityTimerHandle], bx
		pop	dx			;dx = queue handle
endif	; 0
		
	;
	; At this point: 
	;	bp 	= thread handle
	;	dx	= queue handle
	;	ds	= station segment
	;
		call	IrlapEventLoop		; infinite loop
		.leave				; not reached
		ret
IrlapAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapEventLoop(V)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The main event loop of IRLAP event threads.

CALLED BY:	IrlapAttach
PASS:		ds = station segment
		dx = event queue handle
		bp = thread handle
		
RETURN:		nothing, never
DESTROYED:	everything:  we can do this since we're last call in a
		message, and btw we never returns, duh.
		
PSEUDO CODE/STRATEGY:

    Pull a event from the event queue
    eventLoop:
	if (event applys to our state)
		call state event handler
		dispose of the event
		do cx times:
			pop an event off the stack
			post it at the front of the event queue
	else
		push it on stack
		inc	cx
		loop eventLoop
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapEventLoop	proc	near	
TATQ_loop:
	;
	; loop invariant:	ds = station
	; 			dx = queue handle
	;
		
	;
	; Destroy the thread if IDC_DETACH message has been posted
	;
		test	ds:IS_extStatus, mask IES_DETACHED
		jnz	killThread
	;
	; Get message to process
	;
		mov	bx, dx			; restore queue handle
		call	QueueGetMessage		; ax = event handle
		mov	bx, ax			; bx = event handle
if	0
	;
	; Now I think we want to be interrupted by Irlap server thread
	;
	; boost priority by resetting current cpu usage count
	; we cannot afford to be interrupted here, especially by
	; irlap server thread
	;
		push	ax, bx
		clr	bx
		mov	ax, mask TMF_ZERO_USAGE shl 8
		call	ThreadModify
		pop	ax, bx
endif
		
	;
	; V/P suspend semaphore, this will block irlap event thread if
	; the user requested to suspend IrLAP
	;
		PSem	ds, IS_suspendSem
		VSem	ds, IS_suspendSem
	;
	; handle messages now
	;
		call	ObjGetMessageInfo	; ax = event code(message)
applyEvent::
	;
	; Handle the dispatched event
	;
		call	IrlapCheckStateEvent	; event freed if successful
		jnc	recoverQueue		; event successfully handled
	;
	; Event not recognized
	;
		mov_tr	ax, bx			; ax = event handle
		mov	bx, ds:IS_pendingEventQueue
		clr	si, di			; post in order
		call	QueuePostMessage
		jmp	TATQ_loop

recoverQueue:
	;
	; pop the stack until it's empty, and repost the events at the
	; front of the queue.
	;
		mov	di, mask MF_INSERT_AT_FRONT or mask MF_FORCE_QUEUE
		mov	si, dx			; si = queue handle
		mov	bx, ds:IS_pendingEventQueue
		mov	cx, si			; same handler
		call	GeodeFlushQueue
		mov	bx, dx			; bx = queue
	;
	; Get expedited events( there can be up to MAX_NUM_URGENT_EVENT )
	;
urgentEventLoop:
		call	IrlapGetUrgentEvent	;-> ax = event
		jc	TATQ_loop
		
EC <		cmp	di, mask MF_INSERT_AT_FRONT or mask MF_FORCE_QUEUE>
EC <		ERROR_NE	-1					>
		clr	si
		call	QueuePostMessage	; insert event at front
		jmp	urgentEventLoop
killThread:
	;
	; Free pending event queue
	;
		mov	bx, ds:IS_pendingEventQueue
EC <		call	GeodeInfoQueue			; ax = # events	>
EC <		tst	ax						>
EC <		WARNING_NZ	IRLAP_PENDING_EVENTS_ON_DETACH		>
		call	GeodeFreeQueue
	;
	; deallocate irlap station segment
	;
		mov	bx, ds:IS_stationHandle
		call	MemFree		
	;
	; jump to ThreadDestroy
	;
		clr	cx, dx, bp
		jmp	ThreadDestroy
		
		.warn	-unreach
		ret				; not reached
		.warn 	@unreach
IrlapEventLoop	endp

IrlapResidentCode	ends


IrlapCommonCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapCheckStateEvent(V)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check event for the state,  set carry if event not
		applicable to state,  and dispatch it if applicable.

CALLED BY:	IrlapEventLoop
PASS:		bx	= event handle
		ax	= event code
		ds	= station
RETURN:		carry set if event is not applicable
			in that case, bx = event handle passed
DESTROYED:	nothing
		
PSEUDO CODE/STRATEGY:
	if (localEvent(event code))
		get eventcode.high -- IrlapLocalEvent
		if eventcode.low is in stateLocalEvent[state][eventcode.high]
			find handler function
			call function
			clc
		else stc
	else find handler function
		if (found)
			call handler function
			clc
		else if (found stateDefaultHandler[state])
			call stateDefaultHandler[state]
			clc
		else stc
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapCheckStateEvent	proc	far
		uses	ax, cx, dx, es, di, si, bp
		.enter
EC <		IrlapCheckStation	ds				>
	;
	; Check for external event
	;
		cld					; just to be sure
		mov	bp, ds:IS_state			; bp = current state

		segmov	es, cs, dx
		test	ah, mask IEI_LOCAL
		jz	externalEvent
	;
	; LOCAL EVENT
	; Check for driver control messages: these messages are the one that
	;				     I added outside IrLAP protocol
	;
		cmp	ah, ILE_CONTROL
		jne	processLocalEvents
	;
	; Lookup the appropriate handler and call it
	;
		clr	ah				; ax= offset to handler
		add	ax, offset DriverControlTable	; in DriverControlTable
		mov_tr	di, ax
		mov	dx, cs:[di]
		mov	cx, cs
		push	cx, dx
		mov	di, ds				; di = station segment
		clr	si				; kill the event
		call	MessageProcess			;-> cx, dx popped
		clc
		jmp	exit
		
processLocalEvents:
	;
	; Local events: we check if it's applicable
	;
	; bp = state
	; es = code segment
	;
		shl	bp, 1		; state # x 4 bytes
		shl	bp, 1		;
		mov	dx, ax		; dx = event code
		BitClr	dh, IEI_LOCAL	; get rid of the IEI_LOCAL bit.
		clr	dl		;
		xchg	dl, dh		; dx, di = 0 - 3, depending on which
		mov	di, dx		;         IrlapLocalEvent the event was
		test	al, cs:IrlapStateLocalEventTable[bp][di]
LONG		jz	notApplicable
	;
	; Data requests (ILE_REQUEST + IRV_DATA) are not legal
	; if ISS_REMOTE_BUSY is set in ds:IS_status.
	;
		cmp	ax, ILE_REQUEST shl 8 or mask IRV_DATA
		jne	applicable
	;
	; If NDM and ISS_GOING_AWAY, override ISS_REMOTE_BUSY check as we
	; want DataRequestNDM to free the data.
	;
		cmp	ds:IS_state, IMS_NDM
		jne	notNDM
		test	ds:IS_status, mask ISS_GOING_AWAY
		jnz	applicable
notNDM:
	;	
	; the event is a data request.  Check for ISS_REMOTE_BUSY
	;
		test    ds:IS_status, mask ISS_REMOTE_BUSY
		jz	applicable
		jmp	notApplicable

applicable:

	;
	; Applicable,  so get the events: one of the events in the table
	; MUST be it.
	;
		shr	bp		; state # x 2 bytes
		mov	dx, {word} cs:IrlapHandlerTable[bp]
					; dl = offset, dh = # of locals
		clr	cx
		mov	cl, dh		; cx = # of locals
		clr	dh		;
		shl	dx, 1		; dx = state offset x size word
		add	dx, offset IrlapStateLookupTable
		mov	di, dx		; es:di = start of state
EC <		cmp	dx, di						>
EC <		ERROR_NE	IRLAP_LOCAL_EVENT_NOT_RECOGNIZED	>
EC <		tst	cx						>
EC <		ERROR_Z		IRLAP_LOCAL_EVENT_NOT_RECOGNIZED	>
		repnz	scasw
EC <		ERROR_NZ	IRLAP_LOCAL_EVENT_NOT_RECOGNIZED	>
		jmp	processMessage
	
externalEvent:
	;
	; Clr IES_MIN_TURNAROUND so that we wait minimum turnaroud time
	; before sending another packet
	;
		BitClr	ds:IS_extStatus, IES_MIN_TURNAROUND
	;
	; The idea is lookup abs this state offset (a)
	; abs next state offset (b) and num of local events this state (c).
	; dx = table offset of a. di = table offset of c.  cx = b-a-c
	;
		shl	bp, 1		; state # x 2
		mov	dx, {word} cs:IrlapHandlerTable[bp]
					; dl = offset, dh = # of local
		mov	cx, {word} cs:IrlapHandlerTable[bp].2; cl = next offset
		add	dl, dh		; real offset
		clr	dh
		mov	di, dx		; offset of external events
		sub	cl, dl		; cx = # of externals
		clr	ch
		shl 	di, 1		; es:di = start of external event
					; of state
		add	di, offset IrlapStateLookupTable
		jcxz	defaultHandling	; cx = 0 nothing to search
	;
	; Arrgh... I need to clr Nr field of S frames in order for them to be
	; recognized in the table
	;
		mov	dx, ax		; save original frame header
		test	al, 00000001b
		jz	iFrame
		test	al, 00000010b
		jz	sFrame
		jmp	searchTable	; in case of U frame there is nothing
					; to mask out
iFrame:
		and	al, not mask IICF_NS
sFrame:
		and	al, not mask IICF_NR
searchTable:
	;
	; now scan for handler
	;
		repnz	scasw
		jnz	defaultHandling
		mov	ax, dx		; restore frame header(Ns,Nr restored)
	;
	; Convert ax to an error event if it contains invalid control field
	;
		call	DetectInvalidControlField
		mov	bp, ds:IS_state
		jc	externalEvent
processMessage:
	;
	; Find the event handler
	;
		sub	di, offset IrlapStateLookupTable + size word
				; compensate for 1 word overrun of scasw
		shl	di, 1	; offset into dword table of vfptr
				; of action functions: state # x 4 bytes
	;
	; For XIP, this table is kept in Fixed memory.
	; So it no longer resides in the same segment as the other
	; tables.
	;
		push	ax			; save the control field
		add	di, offset IrlapStateActionTable
		movfptr	cxdx, IrlapMessageProcessCallback
		push	cx, dx			; callback routine as argument
EC <		call	ECCheckEventHandle				>
		mov	ds:IS_callVector, di	; store the function to call
		mov	di, ds			; pass station segment as arg
		clr	si			; destroy the event
		call	MessageProcess		; already popped cx, dx
		pop	ax
	;
	; if we have just handled a frame that turns the link around,
	; clear the recvCount so that we can now receive frames
	;
		test	al, mask ISCF_PFBIT
		jz	skipPf
		clr	ds:IS_recvCount
skipPf:
		clc
		jmp	exit
	
notApplicable:
		stc
exit:
		cld
		.leave
		ret

defaultHandling:
	;
	; Invalid frame?
	;
		call	CheckForInvalidFrame	; carry set if invalid frame
		mov	ax, dx
		jc	invalidFrame
	;
	; Restore es to be dgroup
	;
		GetDgroup es, cx
	; 
	; not in table, but the state may handle it with wildcards.
	; if the state can't handle it, we need to discard it; we cannot
	; preserve and pass it along later and expect the protocol to
	; operate correctly on delayed responses.
	;
		mov	cx, ax			; cx = original control field
		mov	di, bp			; di = state x 2
		shl	di, 1			; state # x size vfptr bytes

EC <		IrlapCheckStation	ds				>
		push	bx, ds			; don't trash event handle
		pushdw	cs:IrlapDefaultHandlerTable[di]		
	;
	; all default handlers are passed cx as the event code
	;
		call	PROCCALLFIXEDORMOVABLE_PASCAL ; CF=1 if not handled
		pop	bx, ds			; don't trash station
	;
	; discard the frame no matter what
	;
discardFrame:
		movfptr	cxdx, IrlapMessageProcessNullCallback
		push	cx, dx
EC <		call	ECCheckEventHandle				>
		clr	si			; destroy the event
		call	MessageProcess		; already popped cx, dx
	;
	; whenever an external event is discarded by default, we consider this
	; a link turnaround, and reset receive count so that other frames may
	; be received
	;
		clr	ds:IS_recvCount
		clc
		jmp	exit
invalidFrame:
	;
	; reject the frame with Frmr if we are in secondary mode
	; ds = station
	; es = dgroup
	; dx = original frame
	;
		cmp	ds:IS_connAddr, mask ICA_CR
		jnz	doneHandling		; we are primary
handleInvalidFrame::
		push	ax, cx
		mov	cx, dx
		clr	al
		call	PrepareFrmrFrame
		call	SendFrmrFrame
		pop	ax, cx
doneHandling:
		jmp	discardFrame
		
IrlapCheckStateEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DetectInvalidControlField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS: In case of external events, control field of the packet might be
	  invalid due to operational errors.  For instance, it may contain
	  invalid Vs/Vr values.  The following procedure will find the type
	  of the packet, and perform appropriate checks on control field.
	  If control field is invalid, event code(stored in ax) will change
	  to an appropriate error event.

CALLED BY:	IrlapCheckStateEvent	
PASS:		ax = external event code
		ds = station
RETURN:		carry set if error seq number was detected
			  ax = error event code in this case
			       ( IEI_SEQINVALID bit set in event code )
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DetectInvalidControlField	proc	near
		uses	bx,cx,dx,si,di,bp
		.enter
	;
	; If this event is already error event, just return carry clear
	; this means that we went through this routine already.
	; Read IrlapCheckStateEvent to see what is going on. Sorry to make
	; this hacky but well IrLAP is already unintelligible code anyways.
	;							-SJ
	;
		test	ah, mask IEI_SEQINVALID
		jnz	done				; carry is clear
	;
	; Determine the type of packet
	;
		test	al, mask IICF_CONTROL_HDR	; check lsb
		jz	iFrameCheckRr
		test	al, mask IICF_CONTROL_HDR shl 1
		jz	sFrameCheckRr
	;
	; we have received something other than supervisory thing
	;
		clr	ds:IS_rr
done:
		.leave
		ret
iFrameCheckRr:
	;
	; clear consecutive supervisory frame count
	;
		clr	ds:IS_rr
		jmp	iFrame
sFrameCheckRr:
	;
	; keep a count of consecutive supervisory count
	;
		cmp	ds:IS_rr, 0xff	; max value for a byte variable
		je	sFrame		; carry clear
		inc	ds:IS_rr
		jmp	sFrame
iFrame:
	;
	; Check Ns:
	;
	; If Ns = Vr, Ns is valid
	; If IrlapWindow[Ns] has IWF_NS_RANGE set, Ns is valid
	;
		mov	bl, al
		and	bl, mask IICF_NS	; bl = Ns shl 1
		mov	bh, ds:IS_vr		; bh = Vr shl 5
		shr	bx, 1			; bl = Ns; bh = Vr shl 4
		mov	cl, 4
		shr	bh, cl
		cmp	bh, bl
		je	sFrame
	;
	; Compare against valid Ns range recored in IrlapWindow array
	;
		shl	bl, cl			; bh = Ns * size IrlapWindow
		clr	bh
		test	ds:[IS_store][bx].IW_flags, mask IWF_NS_RANGE
		jz	invalidCField
sFrame:
	;
	; See if Nr = Vs
	;
		mov	bl, al
		and	bl, mask ISCF_NR
		shr	bl, 1
		mov	bh, ds:IS_vs
		shl	bh, 1
		shl	bh, 1
		shl	bh, 1
		cmp	bl, bh
		je	done		; carry clear
	;
	; Check Nr against unacknowledged frame array
	;
		clr	bh
		test	ds:[IS_store][bx].IW_flags, mask IWF_VALID
		jnz	done			; carry is clear
invalidCField:
	;
	; AL = Control field of packet received
	; Set ISS_XMIT_FLAG if secondary is allowed to send snrm frame
	;
		BitClr	ds:IS_status, ISS_XMIT_FLAG
		test	al, mask ISCF_PFBIT
		jz	notFinal		; this is not final frame
		BitSet	ds:IS_status, ISS_XMIT_FLAG
notFinal:
	;
	; convert ax into error code
	;
		clr	al
		or	ah, mask IEI_SEQINVALID
		stc
		jmp	done
DetectInvalidControlField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForInvalidFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for invalid/unrecognized frame

CALLED BY:	IrlapCheckStateEvent
PASS:		ax	= control field with Ns, Nr, P/F bit stripped off
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
knownFrameTable byte \
IUC_SNRM_CMD, IUC_DISC_CMD, IUC_UI_CMD, IUC_XID_CMD, IUC_TEST_CMD, IUC_XCHG,
IUC_DXCHG, IUR_RNRM_RSP, IUR_UA_RSP, IUR_FRMR_RSP, IUR_DM_RSP, IUR_RD_RSP,
IUR_UI_RSP, IUR_XID_RSP, IUR_TEST_RSP, IUR_RXCHG, ISC_RR_CMD, ISC_RNR_CMD,
ISC_REJ_CMD, ISC_SREJ_CMD, ISR_RR_RSP, ISR_RNR_RSP, ISR_REJ_RSP, ISR_SREJ_RSP,
0		; for I frame

CheckForInvalidFrame	proc	near
		uses	ax,cx,di
		.enter
	;
	; scan for this thing
	;
		and	al, not mask ISCF_PFBIT		; clear P/F bit
		push	es
		segmov	es, cs, cx
		mov	di, offset knownFrameTable
		mov	cx, size knownFrameTable
		repne	scasb
		pop	es
		clc
		je	done		; carry clear, frame recognized
		stc
done:
		.leave
		ret
CheckForInvalidFrame	endp

; **************************************************************************
; **************************************************************************
; ********************   Internal Control Messages   ***********************
; **************************************************************************
; **************************************************************************

;
; Internal Control Messages control implementation specific operations of
; IRLAP driver.  It has nothing to do with original IRLAP protocol.
; Parameters passed in are limited to ds(station segment) right now.
; (see IrlapCheckStateEvent)
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDCDetach(V)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the event thread.

CALLED BY:	ILE_CONTROL shl 8 or IDC_DETACH
PASS:		ds	= station
RETURN:		never
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDCDetach	proc	far
if 0
	;
	; I set event thread priority to TIME_CRITICAL permanently
	;   -SJ
	;
		
	;
	; the continuous timer that cranks up the irlap event thread's
	; priority periodically.
	;
		mov	bx, ds:IS_priorityTimerHandle
		mov	ax, ds:IS_priorityTimerID
		call	TimerStop
endif
	;
	; Stop all timers
	;
		call	StopAllTimers
	;
	; Free any unacked data
	;
		call	ReleaseBufferedData
	;
	; Kill the thread
	;
		BitSet	ds:IS_extStatus, IES_DETACHED
		ret
IDCDetach	endp



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDCAddressSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Address is selected; V the block semaphore so that
		RunAddressDialog may continue

CALLED BY:	IrlapAddressDialog object
PASS:		di	= IrlapStation segment
		ds:IS_selectedAddr = selected address
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDCAddressSelected	proc	far
		.enter
EC <		WARNING	_ADDRESS_SELECTED				>
	;
	; if user selected CANCEL_CONNECTION, abort connection request,
	; otherwise convert address index into real 32 bit device address
	;

	;
	; Unblock RunAddressDialog
	;
		mov	ds, di
		GetDgroup es, ax
		mov	bx, ds:IS_clientHandle
		mov	bx, es:[bx].IC_addrDialogBlockSem
		call	ThreadVSem		; ax destroyed
		
		.leave
		ret
IDCAddressSelected	endp

endif ;_SOCKET_INTERFACE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDCAbortSniff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Aborts any sniff procedure, and restores the station to NDM

CALLED BY:	IrlapCheckStateEvent
PASS:		di	= station segment
RETURN:		nothing
DESTROYED:	everything
ALGORITHM:
	if (we are sniffing)
		restore port configuration
		restore server thread
		apply default connection params
		state := NDM
	else
		do nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDCAbortSniff	proc	far
		.enter
	;
	; Check if we are in sniff mode
	;
		mov	ds, di
		cmp	ds:IS_state, IMS_NDM
		je	done
		test	ds:IS_status, mask ISS_IRLAP_CONNECT_PROGRESS
		jnz	done
		cmp	ds:IS_state, IMS_QUERY
		je	done
		cmp	ds:IS_state, IMS_REPLY
		je	done
	;
	; We must be in Sniff mode
	;	Stop-Timer
	;	If (we are in SLEEP)
	;		enable-receiver
	;	state := NDM
	;
		movdw	axbx, ds:IS_pTimer
		call	TimerStop
		call	IrlapEnableReceiver
		ChangeState	NDM, ds
done:
		.leave
		ret
IDCAbortSniff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDCStartFlushDataRequests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush data requests

CALLED BY:	IDC_START_FLUSH_DATA_REQUESTS
PASS:		di	= station segment
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDCStartFlushDataRequests	proc	far
		uses	ax, bx, ds
		.enter
EC <		WARNING FLUSH_DATA_REQUEST_START			>
	;
	; Save the state and change to FLUSH_DATA state
	;
		mov	ds, di
		movm	ds:IS_savedState, ds:IS_state, ax
	;
	; Change state to FLUSH_DATA state
	;
		ChangeState	FLUSH_DATA, ds
		
		.leave
		ret
IDCStartFlushDataRequests	endp

IrlapCommonCode	ends

IrlapConnectionCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			EmptyHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A default handler that does nothing, and no change in state

IMPL NOTES:

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code
		cx    =
		dx:bp =

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmptyHandler	proc	far
		.enter
	;
	; Empty,  no change in state
	;
		clc
		.leave
		ret
EmptyHandler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			NullHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is not a handler,  it just says this state has no
		default handler.

IMPL NOTES:

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code
		cx    = control field
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NullHandler	proc	far
		.enter
		stc
		.leave
		ret
NullHandler	endp

IrlapConnectionCode		ends


	
IrlapResidentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapMessageProcessCallback(V)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The callback proc for MessageProcess.  We dispatch the
		event from the offset in di into IrlapStateActionTable
		Notice the last entries in IrlapStateActionTable are
		default callbacks for states.

CALLED BY:	MessageProcess
Pass:		di = station segment
		station:IS_callVector =
		offset of function to call in IrlapStateActionTable

		Carry - set if event has stack data
		ss:[sp+4] (right above return address) - calling thread
Return:
	none
Destroy:
	ax, cx, dx, si, di, bp, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
	[notes: all u and s frames will be freed. No I frames are freed]
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapMessageProcessCallback	proc	far
		uses	ds, es, si
		.enter
if 0
	;
	; boost priority by resetting current cpu usage count
	; we cannot afford to be interrupted here, especially by
	; irlap server thread	- I don't think so...
	;
		push	ax, bx
		clr	bx
		mov	ax, mask TMF_ZERO_USAGE shl 8
		call	ThreadModify
		pop	ax, bx
endif
	; 
	; why MessageProcess doesn't save ds si??!
	; It certainly saves dx,di,bp,bx
	;
	; The table IS_callVector now references a table in fixed for
	; XIP in this same code segment.  
	;
NOFXIP <	GetResourceSegmentNS	IrlapCommonCode, es, TRASH_BX	>
FXIP <		segmov	es, cs						>
		mov	ds, di
		mov	di, ds:IS_callVector
EC <		IrlapCheckStation ds					>
		push	ax			   ; event code
		push	es:[di+2]		   ; segment
		push	es:[di]			   ; offset
		GetDgroup es, di
		call	PROCCALLFIXEDORMOVABLE_PASCAL ; call event handler
		pop	bx			   ; bx = event code
		
		test	bh, mask IEI_LOCAL	   ; exit if local event
		jnz	exit
	;
	; The routines that need to hold on to the buffer or already
	; deallocated the buffer should clear dx so that it is not freed again
	;
		tst	dx			   ; exit if there is no buffer
		jz	exit
	;
	; This is place where most incoming valid data packets are freed.
	; Exception: UI(freed by the user), and I frames.
	;
		movdw	axcx, dxbp
		call	HugeLMemFree
exit:
		.leave
		ret
IrlapMessageProcessCallback	endp

;
; this empty call back is used in default handling
;
IrlapMessageProcessNullCallback	proc	far
		push	ax, cx, dx, bp
		tst	dx
		jz	skipFree
		movdw	axcx, dxbp
		call	HugeLMemFree
skipFree:
		pop	ax, cx, dx, bp
		ret
IrlapMessageProcessNullCallback	endp

if 0
;
; Irlap event thread's priority was permanently set to be TIME_CRITICAL
; by Steve Jang
;

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapTimerCrankUpPriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Crank up the priority of the irlap event thread.

CALLED BY:	TimerStart
PASS:		ax	= thread handle
		cx:dx	= tick count
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapTimerCrankUpPriority	proc	far
	.enter
	mov	bx, ax				;bx = thread handle
	mov	ah, mask TMF_BASE_PRIO
	mov	al, PRIORITY_HIGH
	call	ThreadModify			;bx = thread handle
	.leave
	ret
IrlapTimerCrankUpPriority	endp
endif

IrlapResidentCode	ends	
