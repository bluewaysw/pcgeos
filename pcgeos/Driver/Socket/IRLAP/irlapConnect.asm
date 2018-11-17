COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		irlapConnect.asm

AUTHOR:		Cody Kwok, Apr 21, 1994

ROUTINES:
	Name				Description
	----				-----------
	IrlapConnectRequest		User requests a connection
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/21/94   	Initial revision


DESCRIPTION:
	Defines IRLAP-SIR connect/disconnect/negotiation actions.
	Note: all action functions can destroy all registers,  the event
		handler will take care of them.  

	$Id: irlapConnect.asm,v 1.1 97/04/18 11:57:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapConnectionCode		segment	resource

;------------------------------------------------------------------------------
;			       NDM 
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectRequestNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User requested a connect request.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds	= station
		es    	= dgroup
		ax    	= event code
		dx    	= IrlapConnectionFlags
		^lcx:bp = QualityOfService buffer (HugeLMem) passed in
			  to NIR_CONNECT_REQUEST.

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	if (!media-busy)
		Generate-Random-ConnectionAdr(ca)
		dest : = da (passed in param cxbp)
		send u:snrm:cmd:P:ca:dest:
			alloc a huge lmem block for it,  store it in
			station's store first dword
			send it,  and unlock it
		start-F-Timer
		retryCount := 0
	else
		Disconnect-Indication

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectRequestNDM	proc	far
		.enter
	;
	; [Prepare negotiation parameters]
	;
		call	PrepareNegotiationParams ; IS_connectionParams filled
						 ; cxbp = destDev address
	;
	; [if this is SniffConnectRequest, perform CONNECT-TO-SNIFFER action]
	;
		mov_tr	ax, dx
		test	ax, mask ICF_SNIFF
		jz	continue
		call	SniffConnectRequestNDM
		jmp	done
continue:
	;
	; [media-busy?]
	;
		mov	bx, ds:IS_serialPort
		call	IrlapCheckMediaBusy	; carry set if media is busy
		jc	mediaBusy
		
EC <		WARNING	CONNECT_REQUEST_NDM				>
	;
	; Generate-Random-ConnectionAdr(ca)
	;
		call	IrlapGenConnAddr	;-> dl = connAddr
		shl	dl, 1			; make room for CR bit
		BitSet	dl, IAF_CRBIT		; we'll be primary
		mov	ds:IS_connAddr, dl
	;
	; dest := da
	;
		movdw	ds:IS_destDevAddr, cxbp
	;
	; Send u:snrm:cmd:P:ca:NA:da
	; ax	= IrlapConnectionFlags
	;
		call	SendSnrmPacket
	;
	; Set a default max turnaround time so that F timer doesn't expire
	; too quickly
	;
		mov	ds:IS_maxTurnAround, IRLAP_DEFAULT_F_TIMER_VALUE
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; NEXT STATE = SETUP
	;
		ChangeState SETUP, ds
done:
		.leave
		ret
mediaBusy:
	;
	; media is busy,  return error condition
	;
		stc
		mov	ax, IC_MEDIA_BUSY
		call	DisconnectIndication
		.leave
		ret
ConnectRequestNDM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisconnectRequestNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing ( this procedure is here simply to discard
		disconnect event )

CALLED BY:	IrlapMessageProcessCallback
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisconnectRequestNDM	proc	far

if _SOCKET_INTERFACE
	;
	; Socket link must be closed if we have a diconnect request here
	;
		BitClr	ds:IS_status, ISS_SOCKET_LINK_OPEN
endif
		BitClr	ds:IS_status, ISS_PENDING_DISCONNECT
	;
	; Send disconnect notification.  Disconnect requests in the queue
	; when IrLAP is unregistering end up being handled here.
	;
		mov	si, SST_IRDA
		mov	di, NII_STATUS_INDICATION
		mov	cx, ISIT_DISCONNECTED
		call	SysSendNotification

		ret
DisconnectRequestNDM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvSnrmCmdNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a SNRM frame from remote,  which indicates an
		intention of remote to connect to us.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		ch    = connAddr
		cl    = control field
		dx:bp = packet

RETURN:		dx:bp = packet to be freed or dx = 0 ( packet has been saved )
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		dest := d 	(from packet)
		ca := c		(from packet)
		Connect-Indication

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvSnrmCmdNDM	proc	far
		.enter
EC <		WARNING RECV_SNRM_CMD_NDM				>
	;
	; Check if the packet is for us
	;
		IrlapLockPacket	esdi, dxbp, TRASH_ABX
		mov	si, di
		add	di, es:[di].PH_dataOffset
		cmpdw	ds:IS_devAddr, es:[di].ISF_destDevAddr, ax
		jne	exit
	;
	; dest := da
	; if this device address is broadcast address or null address,
	; we don't accept it
	;
		cmpdw	es:[di].ISF_srcDevAddr, IRLAP_NULL_DEV_ADDR, ax
		je	exit
		cmpdw	es:[di].ISF_srcDevAddr, IRLAP_BROADCAST_DEV_ADDR, ax
		je	exit
		movdw	ds:IS_destDevAddr, es:[di].ISF_srcDevAddr, ax
	;
	; ca := c
	; if this connection address is broadcast address or null address,
	; we just exit without saving it
	;
	;
		mov	ch, es:[di].ISF_connAddr	; ca := c
		BitClr	ch, IAF_CRBIT			; we'll be secondary
		cmp	ch, IRLAP_BROADCAST_CONNECTION_ADDR
		je	exit
		cmp	ch, IRLAP_NULL_CONNECTION_ADDR
		je	exit
		mov	ds:IS_connAddr, ch
	; ----
	; Negotiate connection parameters before giving connect indication
	; to the client.
	;
		push	ax,bx,cx,dx,bp,es,ds
		segmov	es, ds, ax			; es = station
		mov	bx, handle IrlapStrings
		call	MemLock
		mov	ds, ax
	;
	; get default connection parameters from .ini file
	;
		call	InitializeNegotiationParams
		call	MemUnlock
	;
	; negotiate connection paramters
	;
		segmov	ds, es, ax	; ds = station
		call	NegotiateConnectionParameters	;-> IS_connectionParams
		pop	ax,bx,cx,dx,bp,es,ds		; contains negotiated
	;						; parameters
	; Done negotiating
	; ----
		
	;
	; Connect-indication
	;
		call	ConnectIndication		; Connect-Indication
	;
	; State = CONN
	;
		ChangeState	CONN, ds
exit:
	;
	; Save the frame received from the remote side
	; If there was already a frame in there, it will be replaced with the
	; new one, and old one freed.
	;
		IrlapUnlockPacket dx, bx
		xchgdw	ds:IS_remoteSnrmFrame, dxbp
		
		.leave
		ret
RecvSnrmCmdNDM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle various kinds of wild card packet that were not
		recognized in NDM

CALLED BY:	IrlapMessageProcessCallback (Event handler)
PASS:		cx = IrlapCommonHeader
		dx:bp = data
		ds:si = station

RETURN:		nothing
DESTROYED:	all but dx:bp ( packet is to be freed after exit )

PSEUDO CODE/STRATEGY:
	if (recv x:x:cmd:P)
		send u:dm:rsp:x
[	elseif (recv x:x:cmd:-P or recv x:x:rsp:x)	] <-- which is same as
[		do nothing				] 
	DO NOTHING
	free packet
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerNDM		proc	far
		.enter
if	0
	;
	; we don't respond to any unrecognized frames anymore when we are
	; in NDM.  Errata.
	;
EC <		WARNING DEFAULT_HANDLER_NDM				>
	;
	; [Check C/R bit]
	;
		test	ch, mask IAF_CRBIT
		jz	exit				; response frame
	;
	; [Check P/F bit]
	;
		test	cl, mask IICF_PFBIT
		jz	exit				; P/F bit off
	;
	; this is recv x:x:cmd:P,  send u:dm:rsp:x
	;
		clr	bx
		mov	cx, (IRLAP_BROADCAST_CONNECTION_ADDR)\
			    shl 8 or IUR_DM_RSP
		call	IrlapSendUFrame
exit:
endif
		clc
		.leave
		ret
DefaultHandlerNDM		endp

;------------------------------------------------------------------------------
;			       CONN 
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectResponseCONN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upper layer called NIR_CONNECT_RESPONSE, indicating that
		it is okay to connect.

CALLED BY:	IrlapMessageProcessCallback (Event handler)
PASS:		ds	= station segment
		ds:IS_remoteSnrmFrame = frame received from the remote side
		es	= dgroup
		^lcx:bp	= QualityOfService (HugeLMem buffer) passed to
			NIR_CONNECT_RESPONSE.
			
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	Negotiate-Connection-Parameters
	send u:ua:rsp:F	(use the stored snrm frame in IS_store.IIS_optr)
	Apply-Connection-Parameters
	Initialize-Connection-State
	start-WD-timer
	change state to NRM(S)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectResponseCONN	proc	far
		.enter
EC <		WARNING	CONNECT_RESPONSE_CONN				>
	;
	; Initialize-Connection-State
	;
		call	InitConnectionState
	;
	; If upper layer requests us to use default parameters, we don't
	; need to negotiate parameters again, since we have done that
	; already before we sent connect.indication
	;
		push	es, di, bx
		IrlapLockPacket	esdi, cxbp
		test	es:[di].QOS_flags, mask QOSF_DEFAULT_PARAMS
		IrlapUnlockPacket cx, bx	; flags preserved
		pop	es, di, bx
		jnz	skipNegotiation
	;
	; Upper layer must have passed in a new set of parameters, so
	; re-initialize.  Upper layer is not supposed to extend connection
	; capacity( for instance, incrementing frame size ), but it can
	; _limit_ the capacity( for instance, decrementing frame size ).
	; so we don't need to do negotiation or line capacity calculation
	; again at this point.
	;
		call	PrepareNegotiationParams	;cxbp = destDev addr
	;
	; free the SNRM packet
	;
		clr	ax
		xchgdw	axcx, ds:IS_remoteSnrmFrame
		call	HugeLMemFree
if GENOA_TEST
	;
	; if genoa test, wait 10 ms here to make the test suite happy
	;
		push	ax
		mov	ax, 2
		call	TimerSleep
		pop	ax
endif
skipNegotiationCont:
	;
	; Send u:ua:rsp:F
	;
		call	SendSnrmUaRspFrame
	;
	; we have to make sure that all bytes that we have sent out went out of
	; serial port before we change baudrate in ApplyConnectionParameters.
	;
	; this is done inside ApplyConnectionParameters
	;
	; Apply-connection-parameters
	;
		call	ApplyConnectionParameters
	;
	; Start-WD-Timer
	;
		call	StartCWDTimer
	;
	; Clear ISS_CONNECTION_CONFIRMED flag
	;
		BitClr	ds:IS_status, ISS_CONNECTION_CONFIRMED
	;
	; Next state
	;
		ChangeState	RECV_S, ds
exit:		
		.leave
		ret
skipNegotiation:
	;
	; free QoS parameter buffer in ^lcx:bp
	;
		mov	ax, cx
		mov	cx, bp
		call	HugeLMemFree
		jmp	skipNegotiationCont
ConnectResponseCONN	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisconnectRequestCONN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User requested a disconnection

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds	= station
		es	= dgroup
		ax	= event code
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	send u:dm:rsp:F		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisconnectRequestCONN	proc	far
		.enter		
EC <		WARNING	DISCONNECT_REQUEST_CONN				>
	;
	; Send u:dm:rsp:F
	;
		clr	bx
		mov	cx, \
			(IRLAP_BROADCAST_CONNECTION_ADDR) \
			shl 8 or IUR_DM_RSP
		call	IrlapSendUFrame
	;
	; Clr disconnect request flag
	;
		BitClr	ds:IS_status, ISS_PENDING_DISCONNECT
	;
	; Next state
	;
		ChangeState	NDM, ds
		
		.leave
		ret
DisconnectRequestCONN	endp

	
;------------------------------------------------------------------------------
;				   SETUP
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FTimerExpiredSETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	F timer expired in SETUP state

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds	= station
		es	= dgroup
		ax	= event code
RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FTimerExpiredSETUP	proc	far
		.enter
EC <		WARNING F_TIMER_EXPIRED_SETUP				>
	;
	; retryCount < N3?
	;
		mov	al, ds:IS_retryCount
		cmp	al, ds:IS_retryN3
		jge	noMoreRetries
	;
	; Perform-Random-Backoff: 10 to 30 ticks 
	;
		mov	dl, 30
		call	IrlapGenerateRandom8	; dl = random 0 - 30
		mov	al, dl
		clr	ah
		call	TimerSleep
	;
	; send u:snrm:cmd:P:ca:NA:da
	;
		call	SendSnrmPacket
	;
	; Start-F-Timer
	;
		call	StartFTimer
		inc	ds:IS_retryCount
		
		.leave
		ret
noMoreRetries:
	;
	; Disconnect-Indication
	;
		mov	ax, IC_CONNECTION_FAILURE
		call	DisconnectIndication
	;
	; Next state
	;
		ChangeState	NDM, ds, si
		.leave
		ret
FTimerExpiredSETUP	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvSnrmCmdSETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There is another station trying to establish connection as
		primary.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station segment
		es    = dgroup
		ax    = event code
		cx    = header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything but dx:bp ( packet is to be freed )

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvSnrmCmdSETUP	proc	far
		.enter		
EC <	WARNING	RECV_SNRM_CMD_SETUP					>
	;
	; We had sent a connection request SNRM frame,  but we also
	; received snrm from remote.  Resolve "contending SNRM" by comparing
	; addr, and the smaller one yield.
 	; sa > NA?  (notice that sa != NA)
	;
		IrlapLockPacket	esdi, dxbp
		add	di, es:[di].PH_dataOffset
 		cmpdw	es:[di].ISF_srcDevAddr, ds:IS_devAddr, ax
		IrlapUnlockPacket dx, bx
		jb	snrmSETUPexit	; we are primary, we'll wait for UA
					; and no change in state
	;
	; now we comply to what the other station dictates
	; dest := d
	;
		IrlapLockPacket	esdi, dxbp
		add	di, es:[di].PH_dataOffset
		movdw	ds:IS_destDevAddr, es:[di].ISF_srcDevAddr, ax
	;
	; ca := c
	;
		mov	ch, es:[di].ISF_connAddr	; ca := c
		BitClr	ch, IAF_CRBIT			; we'll be secondary
		mov	ds:IS_connAddr, ch
		IrlapUnlockPacket dx, bx
		movdw	ds:IS_remoteSnrmFrame, dxbp
	;
	; sa > NA: Remote wins and we're secondary now. stop-F-timer
	;
		movdw	axbx, ds:IS_fTimer
		call	TimerStop

		GetDgroup es, bx
		push	dx, bp
	;
	; Send u:ua:rsp:F
	;
		call	SendSnrmUaRspFrame
	;
	; we have to make sure that all bytes that we have sent out went out of
	; serial port before we change baudrate in ApplyConnectionParameters.
	;
	; this is done inside ApplyConnectionParameters
	;
	; Apply-connection-parameters
	;
		call	ApplyConnectionParameters
	;
	; Start-WD-Timer
	;
		call	StartCWDTimer
	;
	; Clear ISS_CONNECTION_CONFIRMED flag
	;
		BitClr	ds:IS_status, ISS_CONNECTION_CONFIRMED
	;
	; Connect-confirm
	;
		call	ConnectConfirm	; state already changed to NRM_S
	;
	; Start-WD-Timer again ( doesn't hurt )
	;
		call	StartCWDTimer
	;
	; Wait 1 turnaround before transmitting data... Give the other side
	; a chance to send data first
	;
		BitSet	ds:IS_status, ISS_YIELD_DATA_XMIT
	;
	; Next state
	;
		ChangeState	RECV_S, ds
		pop	dx, bp		; dx:bp will be freed by event thread
snrmSETUPexit:
		
		.leave
		ret
RecvSnrmCmdSETUP	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUaRspSETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connection was confirmed by the remote station	

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station offset (IrlapInfoResource block is locked)
		es    = dgroup
		ax    = event code
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything but dx:bp

PSEUDO CODE/STRATEGY:
	stop-F-timer
	Initi		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUaRspSETUP	proc	far
		.enter		
EC <		WARNING	RECV_UA_RSP_SETUP				>
	;
	; Stop-F-Timer
	;
		movdw	axbx, ds:IS_fTimer
		call	TimerStop
	;
	; Negotiate-Connection-Parameters
	;
		call	NegotiateConnectionParameters
		jc	exit
	;
	; Initialize-Connection-state
	;
		call	InitConnectionState
	;
	; Apply--connection-parameters
	;
		call	ApplyConnectionParameters
	;
	; Send s:rr:cmd:P
	;
		mov	cl, ISC_RR_CMD or mask ISCF_PFBIT
		call	IrlapSendSFrame
	;
	; Connect-Confirm
	;
		call	ConnectConfirm
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; Next state
	;
		ChangeState RECV_P, ds
exit:
		.leave
		ret
RecvUaRspSETUP	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDmRspSETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	we received DM or DISC packets

IMPL NOTES:	This is also RecvDiscRspSETUP

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code
		cx    = IrlapCommonHeader
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything but dx:bp

PSEUDO CODE/STRATEGY:
	Disconnet-Indication
	change to NDM
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDmRspSETUP		proc	far
		.enter	
EC <		WARNING	RECV_DM_RSP_SETUP				>
	;
	; Disconnect-Indication
	;
		mov	ax, IC_REMOTE_DISCONNECTION
		call	DisconnectIndication
		ChangeState	NDM, ds
		.leave
		ret
RecvDmRspSETUP		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartCWDTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts the secondary's primary watch dog (WD) timer

CALLED BY:	ConnectResponseCONN
		RecvSnrmCmdSETUP
PASS:		ds   = station
RETURN:		axbx = timer id + timer handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Stop the old WD timer
	restart the timer
	; not the most efficient way but it works
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartCWDTimer	proc	far
		uses	cx,dx
		.enter
		movdw	axbx, ds:IS_wdTimer
		call	TimerStop
EC <		WARNING	_START_WD_TIMER					>
		mov	bx, ds:IS_eventThreadHandle	;start-WD-timer
		mov	cx, ds:IS_maxTurnAround		;turnaround time

		shl	cx, 1				;double it?

		mov	al, TIMER_EVENT_ONE_SHOT
		mov	dx, ILE_TIME_EXPIRE shl 8 or mask ITEV_WD
if	SLOW_TIMEOUT
		shl	cx, 1
		shl	cx, 1
endif
		call	TimerStart
 		movdw	ds:IS_wdTimer, axbx
		.leave
		ret
StartCWDTimer		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopCWDTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops the WD timer
		This 2 line procedure is intented to ease code reading
		and save some space

CALLED BY:	various SXfer routines
PASS:		nothing
RETURN:		axbx = WD timer handle + ID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	6/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopCWDTimer	proc	near
		.enter
EC <		WARNING	_STOP_WD_TIMER					>
		clr	ds:IS_retryCount
		movdw	axbx, ds:IS_wdTimer
		call	TimerStop
		.leave
		ret
StopCWDTimer		endp
	
IrlapConnectionCode		ends
