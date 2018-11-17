COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		irlapPXfer.asm

AUTHOR:		Cody Kwok, Apr 26, 1994

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/26/94   	Initial revision
	SJ	8/24/94		Substantial changes to internal data struct

DESCRIPTION:
	Irlap information transfer procedures: secondary role

	$Id: irlapSXfer.asm,v 1.1 97/04/18 11:56:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapTransferCode		segment	resource

;------------------------------------------------------------------------------
;				  XMIT_S
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnitdataRequestXMIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send Unitdata

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station
		es	= dgroup
		cx	= Data size
		dxbp	= buffer
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
	If in NDM,
		Send unitdata with PF bit set
	elsif in XMIT,
		dec IS_pendingData
		if (IS_window = 1) or (IS_pendingData = 0),
			Send data with PF bit set
			state = RECV
			IS_window = IS_remoteMaxWindows
		if IS_window != 1
			Send data with PF bit off
			dec IS_window
			state = XMIT		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnitdataRequestXMIT_S	proc	far
		.enter
EC <		WARNING	UNITDATA_REQUEST_XMIT_S				>
	;
	; Check window count
	;
		dec	ds:IS_pendingData
	;
	; Set appropriate address
	;
		mov	al, ds:IS_connAddr
if _SOCKET_INTERFACE
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jz	continue
		or	al, IRLAP_BROADCAST_CONNECTION_ADDR ; preserve C/R bit
continue:

endif ;_SOCKET_INTERFACE

	;
	; Decide whether to send the packet with PF bit set
	;
		tst	ds:IS_pendingData
		jz	sendWithPBitOn
		
		cmp	ds:IS_window, 1
		je	sendWithPBitOn
	;
	; Send u:ui:rsp:~F:data
	;
		call	SendUnitdata
	;
	; window := window - 1
	;
		dec	ds:IS_window
done:
		.leave
		ret
sendWithPBitOn:
	;
	; Send u:ui:rsp:F:data
	;
		or	cx, mask URP_PFBIT
		call	SendUnitdata
	;
	; window := windowSize
	;
		movm	ds:IS_window, ds:IS_remoteMaxWindows, al
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		ChangeState	RECV_S, ds
		jmp	done
		
UnitdataRequestXMIT_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataRequestXMIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has requested some data to be delievered

PASS:		ds	= Station
		es 	= dgroup
		ax	= event code
		cx	= size of data
		dx:bp	= hugelmem handle for DataRequestParams chunk
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	[remote is not busy]
	if (window > 1)
		if (pending data != 0) {
			Send-Data-With-P-Bit-Cleared
		} else {
			Send-Data-with-p-bit-set
		}
	else 	{
			Send-Data-With-P-Bit-Set
			change to RECV_S
		}
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataRequestXMIT_S	proc	far
		.enter
EC <		WARNING	DATA_REQUEST_XMIT_S				>
	;
	; pending data?
	;
		dec	ds:IS_pendingData	; "dequeue" the packet
		dec	ds:IS_pendingConnectedData
		tst	ds:IS_pendingData	; any pending data?
		jz	sendWithSet
	;
	; windowCount = 1 ?
	;
		cmp	ds:IS_window, 1
		je	sendWithSet
	;
	; Send-data-with-PFbit-Clear
	;
		call	SendDataWithPFbitClear
done:
		clr	dx			; packet has been consumed
		.leave
		ret
sendWithSet:
	;
	; Send-data-with-PFbit-Set
	;
		call	SendDataWithPFbitSet
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
	;
	; Next state = RECV_S
	;
		ChangeState	RECV_S, ds
		jmp	done
		
DataRequestXMIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisconnectRequestXMIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User requested a disconnection

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisconnectRequestXMIT_S	proc	far
		.enter
EC <		WARNING	DISCONNECT_REQUEST_XMIT_S			>
	;
	; Send u:rd:rsp:F
	;
		clr	bx
		mov	ch, ds:IS_connAddr
		mov	cl, IUR_RD_RSP or mask IUCF_PFBIT
		call	IrlapSendUFrame
	;
	; Release-buffered-data
	;
		call	ReleaseBufferedData
	;
	; Send notification 
	;
		mov	si, SST_IRDA
		mov	di, NII_STATUS_INDICATION
		mov	cx, ISIT_DISCONNECTED
		call	SysSendNotification
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
	;
	; Clear disconnect request flag
	;
		BitClr	ds:IS_status, ISS_PENDING_DISCONNECT
	;
	; Next State = SCLOSE
	;
		ChangeState	SCLOSE, ds
		.leave
		ret
DisconnectRequestXMIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetRequestXMIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has requested connection be reset

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetRequestXMIT_S	proc	far
		.enter

EC <		WARNING	RESET_REQUEST_XMIT_S				>
	;
	; Send u:rnrm:rsp:F
	;
		clr	bx
		mov	ch, ds:IS_connAddr
		mov	cl, IUR_RNRM_RSP or mask IUCF_PFBIT
		call	IrlapSendUFrame
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
	;
	; Next State = RESET
	;
		ChangeState	RESET_S, ds
		.leave
		ret
ResetRequestXMIT_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalBusyDetectedXMIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The local layer is very busy,  and subsequent transmitted
		packts from secondaries may be lost.

CALLED BY:	IrlapMessageProcessCallback (event handler)
PASS:		ds	= station
		es 	= dgroup
		ax	= event code
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalBusyDetectedXMIT_S	proc	far
		.enter
EC <		WARNING	LOCAL_BUSY_DETECTED_XMIT_S			>
	;
	; Empty
	;
		ChangeState	BUSY_S, ds
		.leave
		ret
LocalBusyDetectedXMIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRrCmdXMIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discard RR frames received in XMIT_S state, to prevent
		them to be queued up for later, since they contain old
		Vr counts that can cause spurious retransmits.

CALLED BY:	IrlapMessageProcessCallback 
PASS:		ds	= station
		es	= dgroup
		ax	= event code
		cx	= packet header
		dx:bp	= packet optr
RETURN:		dx 	= unchanged, so buffer will be freed by caller.
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRrCmdXMIT_S	proc	near
	.enter
EC <	WARNING RECV_RR_CMD_XMIT_S					>
	.leave
	ret
RecvRrCmdXMIT_S	endp

;------------------------------------------------------------------------------
;				  RECV_S
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvICmdPRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received an I frame with F bit on

CALLED BY:	IrlapMessageProcessCallback (Event handler)
PASS:		ds      = station
		es 	= dgroup
		ax	= message #
		ch,cl   = addr, control
		dx:bp	= data
RETURN:		nothing
DESTROYED:	ax, bx, cx
SIDE EFFECTS:	
	If (Nr and Ns expected)
		Data-Indication
		Vr := Vr + 1 mod 8
		Update Nr Received
		Stop-WD-Timer
		If (data-pending)
			State := XMIT
		else
			Wait-Minimum-Delay-Time
			Send s:rr:rsp:Vr:F
			Start-WD-Timer
	else if (Ns unexpected)
		Update Nr received
		Send s:rr:rsp:Vr:F
		start-WD-timer
	else if (Nr unexpected)
		Data-Indication
		Vr := Vr + 1 mod 8
		Update Nr received
		resend rejected	frames
		start-WD-timer

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvICmdPRECV_S		proc	far
		.enter
EC < WARNING	RECV_I_CMD_RECV_S					>

		CheckRecoverFromBlocked		; recover from blocked status?
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Set ISS_CONNECTION_CONFIRMED flag
	;
		BitSet	ds:IS_status, ISS_CONNECTION_CONFIRMED
	;
	; Check if Nr is expected: should be the same as Vs
	; - we check this first because in case of unexpected ns, we need to
	;   update Nr received
	;
		mov	bl, cl
		and	bl, mask IICF_NR	; bl = Nr
		mov	bh, ds:IS_vs		;
		ror4	bh			; bh = Vs
		cmp	bl, bh
		jne	unexpectedNr
	;
	; Check if Ns is expected: should be the same as Vr
	;
		mov	bl, cl
		and	bl, mask IICF_NS	; bl = Ns
		mov	bh, ds:IS_vr		;
		ror4	bh			; bh = Vr
		cmp	bl, bh
		jne	unexpectedNs
	;
	; Expected Ns, Nr
	;
	; Data-Indication
	;
		call	DataIndication
	;
	; before shifting Vr, we make sure to mark this Ns to be out of
	; valid Ns range
	;
		clr	bh
		mov	bl, ds:IS_vr
		shr	bl, 1
		BitClr	ds:[IS_store][bx].IW_flags, IWF_NS_RANGE
	;
	; actually, now that we have received poll bit, we can update
	; the valid Ns range in IrlapWindow array
	;
		push	cx			; always save control header
		clr	ch
		mov	cl, ds:IS_maxWindows
nsRangeLoop:
		add	bx, size IrlapWindow
		cmp	bx, size IrlapWindowArray
		jb	notEnd
EC <		ERROR_A	IRLAP_STRANGE_ERROR				>
		clr	bx			; wrap around
notEnd:
		BitSet	ds:[IS_store][bx].IW_flags, IWF_NS_RANGE
		loop	nsRangeLoop
		pop	cx
	;
	; Vr := Vr + 1 mod 8
	;
		IncVr	ds
	;
	; Update-Nr-received
	;
		call	UpdateNrReceived
	;
	; Stop-WD-Timer
	;
		call	StopWDTimer

	;
	; Check for pending data requests
	;
		tst	ds:IS_pendingData
		jz	noPendingData
	;
	; pending data requests
	;
		ChangeState XMIT_S, ds
		jmp	done

noPendingData:
	;
	; Wait-minimum-delay-time: moved to IrlapSendPacket
	;

	;
	; Send s:rr:rsp:Vr:F
	;
		mov	cl, ISR_RR_RSP or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
done:
		.leave
		ret
unexpectedNs:
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Send s:rr:rsp:Vr:F
	;
		mov	cl, ISR_RR_RSP or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		jmp	done
unexpectedNr:				; Ns is expected value
	;
	; Data-Indication
	;
		call	DataIndication
	;
	; before shifting Vr, we make sure to mark this Ns to be out of
	; valid Ns range
	;
		clr	bh
		mov	bl, ds:IS_vr
		shr	bl, 1
		BitClr	ds:[IS_store][bx].IW_flags, IWF_NS_RANGE
	;
	; actually, now that we have received poll bit, we can update
	; the valid Ns range in IrlapWindow array
	;
		push	cx		; always save cx
		clr	ch
		mov	cl, ds:IS_maxWindows
nsRangeLoop2:
		add	bx, size IrlapWindow
		cmp	bx, size IrlapWindowArray
		jb	notEnd2
EC <		ERROR_A	IRLAP_STRANGE_ERROR				>
		clr	bx			; wrap around
notEnd2:
		BitSet	ds:[IS_store][bx].IW_flags, IWF_NS_RANGE
		loop	nsRangeLoop2
		pop	cx
	;
	; Vr := Vr + 1 mod 8
	;
		IncVr	ds
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Resend-Rejected-Frames
	;
		call	ResendRejFrames
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		jmp	done

RecvICmdPRECV_S		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvICmdNotPRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received an I packet

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	if (Ns expected) {
		Data-Indication
		Vr := Vr + 1
	}
	Update Nr received
	Start-WD-Timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvICmdNotPRECV_S	proc	far
		.enter
EC <		WARNING	RECV_I_CMD_NOT_P_RECV_S				>

		CheckRecoverFromBlocked		; recover from blocked status?
	;
	; Set ISS_CONNECTION_CONFIRMED flag
	;
		BitSet	ds:IS_status, ISS_CONNECTION_CONFIRMED
	;
	; Check if Ns is expected: should be the same as Vr
	;
		mov	bl, cl
		and	bl, mask IICF_NS	; bl = Ns
		mov	bh, ds:IS_vr		;
		ror4	bh			; bh = Vr
		cmp	bl, bh
		jne	unexpectedNs
	;
	; Data-Indication
	;
		call	DataIndication
	;
	; before shifting Vr, we make sure to mark this Ns to be out of
	; valid Ns range
	;
		clr	bh
		mov	bl, ds:IS_vr
		shr	bl, 1
		BitClr	ds:[IS_store][bx].IW_flags, IWF_NS_RANGE
	;
	; Vr := Vr + 1 mod 8
	;
		IncVr	ds
unexpectedNs:
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		.leave
		ret
RecvICmdNotPRECV_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvInvalidSeqRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Either Nr or Ns of the frame is invalid

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvInvalidSeqRECV_S	proc	far
		.enter
EC <		WARNING	RECV_INVALID_SEQ_RECV_S				>
	;
	; prepare FNRM frame
	;
		clr	al		; unspecified rejection of frame
		call	PrepareFrmrFrame
	;
	; if XMIT_FLAG is set, send u:frmr:rsp:F, otherwise
	; prepare FRMR response and go into ERROR state.
	; FRMR will be sent when we receive Poll in ERROR state in this case.
	;
		test	ds:IS_status, mask ISS_XMIT_FLAG
		jz	errorState
	;
	; send fnrm frame
	;
		call	SendFrmrFrame
	;
	; start WD timer
	;
		call	StartWDTimer
	;
	; we are still in RECV_S state at this point
	;
done:
		.leave
		ret
errorState:
	;
	; transition to error state
	;
		ChangeState	ERROR_S, ds
		jmp	done
		
RecvInvalidSeqRECV_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUiCmdNotPRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received unnumbered packet with P bit off

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUiCmdNotPRECV_S	proc	far
		.enter
EC <		WARNING	RECV_UI_CMD_NOT_P_RECV_S			>
	;
	; Unit-Data-Indication
	;
		call	UnitdataIndication
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		.leave
		ret
RecvUiCmdNotPRECV_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUiCmdPRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received Unnumbered Information packet

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = addr + control
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUiCmdPRECV_S	proc	far
		.enter
EC <		WARNING	RECV_UI_CMD_RECV_S				>
	;
	; Unit-Data-Indication
	;
		call	UnitdataIndication
	;
	; Test for pennding disconnect request
	;
		test	ds:IS_status, mask ISS_PENDING_DISCONNECT
		jnz	mayDisconnect
	;
	; Check for pending data
	;
		tst	ds:IS_pendingData
		jz	noPendingData
	;
	; Check for remote busy
	;
		test	ds:IS_status, mask ISS_REMOTE_BUSY
		jnz	remoteBusy
mayDisconnect:
	;
	; Pending data request AND remote not busy
	;
		call	StopWDTimer
	;
	; next state = SMIT
	;
		ChangeState XMIT_S, ds
done:
		.leave
		ret
noPendingData:
remoteBusy:
	;
	; Wait-minimum-turnaround-delay: moved inside IrlapSendPacket
	;

	;
	; Send s:rr:rsp:Vr:F
	;
		mov	cl, ISR_RR_RSP or mask IUCF_PFBIT
		call	IrlapSendSFrame
		jmp	done
		
RecvUiCmdPRECV_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvXidCmdRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received XID frame
	
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvXidCmdRECV_S	proc	far
		.enter
EC <		WARNING	RECV_XID_CMD_RECV_S				>
	;
	; RenogotiateConnection
	;
		call	RenegotiateConnection
		.leave
		ret
RecvXidCmdRECV_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRrCmdRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recv a recv ready frame

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		si    = station offset
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)
PSEUDO CODE:
		remoteBusy := false
		Update-Nr-Received
		if (unexpected Nr)
			Resend-Rejected-Frames
			start-WD-Timer
		else
			stop-WD-Timer
			if (pending data)
				state := XMIT
			else
				Wait-Minimum-Turnaround-Time
				Send s:rr:rsp:Vr:F
				start-WD-Timer
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRrCmdRECV_S		proc	far
		.enter
EC <		WARNING	RECV_RR_CMD_RECV_S				>
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; see if we are recovering from a blocked status
	;
		test	ds:IS_status, mask ISS_WARNED_USER
		jz	normalCase
	;
	; in this case, we were sort of blocked
	; notify the user that we recovered from status: BLOCKED
	;
		push	cx
		BitClr	ds:IS_status, ISS_WARNED_USER
		mov	cx, ISIT_OK
		call	StatusIndication
		pop	cx
normalCase:
	;
	; Set ISS_CONNECTION_CONFIRMED flag
	;
		BitSet	ds:IS_status, ISS_CONNECTION_CONFIRMED		
	;
	; remoteBusy := false
	;
		BitClr	ds:IS_status, ISS_REMOTE_BUSY
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Check if Nr is expected: should be the same as Vs
	;
		mov	bl, cl
		and	bl, mask IICF_NR	; bl = Nr
		mov	bh, ds:IS_vs		;
		ror4	bh			; bh = Vs
		cmp	bl, bh
		jne	unexpectedNr
	;
	; Check for pending disconnect.request( MODIFICATION )
	;
		test	ds:IS_status, mask ISS_PENDING_DISCONNECT
		jnz	disconnectRequest
	;
	; Stop-WD-Timer
	;
		call	StopWDTimer
	;
	; Check for pending data
	;
		test	ds:IS_status, mask ISS_YIELD_DATA_XMIT
		jnz	noPendingData
		tst	ds:IS_pendingData
		jz	noPendingData
disconnectRequest:
		ChangeState	XMIT_S, ds
		jmp	done
yieldDataXmit:
	;
	; Do not yield next time
	;
		BitClr	ds:IS_status, ISS_YIELD_DATA_XMIT
noPendingData:
	;
	; Wait-Minimum-Turn-Around-Time: moved inside IrlapSendPacket
	;

	;
	; Send s:rr:rsp:Vr:F
	;
		mov	cl, ISR_RR_RSP or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
done:
		.leave
		ret
unexpectedNr:
	;
	; Resend-Rejected-Frames
	;
		call	ResendRejFrames
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		jmp	done
RecvRrCmdRECV_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRejCmdRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a reject RSP

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = addr + control
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRejCmdRECV_S	proc	far
		.enter

EC <		WARNING	RECV_REJ_CMD_RECV_S				>
	;
	; retry count = 0
	;
		clr	ds:IS_retryCount
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Resend-Rejected-Frames
	;
		call	ResendRejFrames
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		.leave
		ret
RecvRejCmdRECV_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvSrejCmdRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recv a SREJ response frame

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvSrejCmdRECV_S	proc	far
		.enter
EC <		WARNING	RECV_SREJ_CMD_RECV_S				>
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Resend-(single)-rejected-frame
	;
		call	ResendSrejFrame
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		.leave
		ret
RecvSrejCmdRECV_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRnrCmdRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a receive-not-ready frame

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRnrCmdRECV_S	proc	far
		.enter
EC <		WARNING	RECV_RNR_CMD_RECV_S				>
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; remoteBusy := true
	;
		BitSet	ds:IS_status, ISS_REMOTE_BUSY	; remoteBusy := true
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Wait-Minimum-Turnaround-delay: moved inside IrlapSendPacket
	;
		
	;
	; Send s:rr:rsp:Vr:F
	;
		mov	cl, ISR_RR_RSP or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		.leave
		ret
RecvRnrCmdRECV_S	endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscCmdRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received diconnect frame from the primary

CALLED BY:	server thread
PASS:		ds    = station
		es    = dgroup
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	all except for dxbp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscCmdRECV_S		proc	far
		.enter
EC < 		WARNING	RECV_DISC_CMD_RECV_S				>
	;
	; Send u:ua:rsp:F
	;
		call	SendUaRspFrame
	;
	; Apply-Default-Connection-Params
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_REMOTE_DISCONNECTION
		call	DisconnectIndication
	;
	; Release-Buffered-Data
	;
		call	ReleaseBufferedData
		ChangeState	NDM, ds
		.leave
		ret
RecvDiscCmdRECV_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalBusyDetectedRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Local service user is too busy to accept any data packets
		currently.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalBusyDetectedRECV_S	proc	far
		.enter
EC <		WARNING	LOCAL_BUSY_DETECTED_BUSY_S			>
	;
	; Empty
	;
		ChangeState BUSY_WAIT_S, ds
		.leave
		ret
LocalBusyDetectedRECV_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvSnrmCmdRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recv a request nrm RSP

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvSnrmCmdRECV_S	proc	far
		.enter
EC <		WARNING	RECV_SNRM_CMD_RECV_S				>
	;
	; Go into RESET_CHECK_S mode only if connection was confirmed
	; ( ISS_CONNECTION_CONFIRMED makes connection establishment procedure
	;   3-way handshaking )
	;
		test	ds:IS_status, mask ISS_CONNECTION_CONFIRMED
		jz	done
	;
	; Stop-All-Timers
	;
		call	StopAllTimers
	;
	; Reset-Indication
	;
		mov	cx, IRIT_REMOTE
		mov	ax, IC_REMOTE_RESET
		call	ResetIndication
	;
	; Next State = RESET_CHECK
	;
		ChangeState	RESET_CHECK_S, ds
done:
		.leave
		ret
RecvSnrmCmdRECV_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvTestCmdRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received TEST frame while in RECV_S state

CALLED BY:	IrlapMessageProcessCallback
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr
RETURN:		nothing
DESTROYED:	everything but dxbp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvTestCmdRECV_S	proc	far
		uses	dx,si,bp
		.enter
	;
	; Lock the packet
	;
		IrlapLockPacket esdi, dxbp
		mov	bx, es:[di].PH_dataSize
		add	di, es:[di].PH_dataOffset
	;
	; send back the same information back to the sender
	;
		mov	ch, ds:IS_connAddr
		mov	cl, IUR_TEST_RSP or mask IUCF_PFBIT
		call	IrlapSendUFrame
	;
	; Unlock the block
	;
		IrlapUnlockPacket dx, bx
	;
	; dx:bp will be freed by MessageProcessCallback
	;
		.leave
		ret
RecvTestCmdRECV_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WDTimerExpiredRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	F timer expired

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	if (retryCount < N2 and != N1)
		retryCount := retryCount + 1
		Start-WD-Timer
	else if (retryCount = N1)
		Status-Indication
		retryCount := retryCount + 1
		Start-WD-Timer
	else if (retryCount >= N2)
		Apply-Default-Connection-Parameters
		Disconnect-Indication
		change to NDM

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WDTimerExpiredRECV_S	proc	far
		.enter
EC <		WARNING	WD_TIMER_EXPIRED_RECV_S				>
	;
	; Check for retryCount
	;
		mov	al, ds:IS_retryCount
		cmp	al, ds:IS_retryN1		
		je	disconnWarning
		cmp	al, ds:IS_retryN2
		jae	disconnLink
continue:
	;
	; retryCount := retryCount + 1
	;
		inc	ds:IS_retryCount
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
done:
		.leave
		ret
disconnWarning::
	;
	; Status-Indication
	;
		mov	cx, ISIT_BLOCKED
		call	StatusIndication		; warn user
		BitSet	ds:IS_status, ISS_WARNED_USER
		jmp	continue
disconnLink:
	;
	; Apply-Default-Connection-Params
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indciation
	;
		mov	ax, IC_CONNECTION_TIMEOUT_S
		call	DisconnectIndication
	;
	; release-Buffered-Data
	;
		call	ReleaseBufferedData
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Next State = NDM
	;
		ChangeState	NDM, ds
		jmp	done
		
WDTimerExpiredRECV_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerRECV_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received some unrecognized packet

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerRECV_S	proc	far
		.enter
EC <		WARNING	DEFAULT_HANDER_RECV_S				>

		push	cx
		and	cl, mask IUCF_CONTROL_HDR
		cmp	cl, mask IUCF_CONTROL_HDR
		pop	cx
		je	notApplicable			; U frame
		test	ch, mask IAF_CRBIT
		jnz	notApplicable			; Command frame
	;
	; Disconnect procedure
	; ApplyDefaultConnectionParams
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_PRIMARY_CONFLICT
		call	DisconnectIndication
	;
	; Next State := NDM
	;
		ChangeState	NDM, ds
		.leave
		ret
notApplicable:
	;
	; if not applicable, send out FRMR frame
	; cx  = packet header
	;
		push	ax
		clr	al
		call	PrepareFrmrFrame
		call	SendFrmrFrame
		pop	ax
		.leave
		ret
DefaultHandlerRECV_S	endp

;------------------------------------------------------------------------------
;			       ERROR_S
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscCmdPERROR_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received disconnect packet in ERROR_S state

CALLED BY:	IrlapMessageDispatchCallback
PASS:		ds	= station segment
		ax	= event code
		cx	= packet header
		es	= dgroup
		dx:bp	= packet optr
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscCmdPERROR_S	proc	far
		uses	ax,bx,cx,dx
		.enter
	;
	; Send u:ua:rsp:F frame
	;
		call	SendUaRspFrame
	;
	; Release-Buffered-Data
	;
		call	ReleaseBufferedData
	;
	; Apply-Default-Connection_Parameters
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_REMOTE_DISCONNECTION
		call	DisconnectIndication
	;
	; Change to NDM
	;
		ChangeState NDM, ds
		
		.leave
		ret
RecvDiscCmdPERROR_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDmRspPERROR_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received DM frame in ERROR_S state

CALLED BY:	IrlapMessageDispatchCallback
PASS:		ds	= station segment
		ax	= event code
		cx	= packet header
		es	= dgroup
		dx:bp	= packet optr
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDmRspPERROR_S	proc	far
		uses	ax,bx,cx,dx
		.enter
	;
	; Release-Buffered-Data
	;
		call	ReleaseBufferedData
	;
	; Apply-Default-Connection-Parameters
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_REMOTE_DISCONNECTION
		call	DisconnectIndication
	;
	; Change to NDM
	;
		ChangeState NDM, ds
		.leave
		ret
RecvDmRspPERROR_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerERROR_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler for ERROR_S state

CALLED BY:	IrlapMessageDispatchCallback
PASS:		ds	= station segment
		ax	= event code
		cx	= packet header
		es	= dgroup
		dx:bp	= packet optr
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerERROR_S	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; if P/F bit is off, only start WD timer
	;
		test	cl, mask ISCF_PFBIT
		jz	wdTimer
		call	SendFrmrFrame
	;
	; transition back to RECV_S state
	;
		ChangeState	RECV_S, ds	
wdTimer:	
	;
	; Start-WD-Timer in either case
	;
		call	StartWDTimer
		
		.leave
		ret
DefaultHandlerERROR_S	endp


;------------------------------------------------------------------------------
;			       RESET_CHECK_S
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetResponseRESET_CHECK_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The service user responded to Reset Indication

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetResponseRESET_CHECK_S	proc	far
		.enter
EC <		WARNING	RESET_RESPONSE_RESET_CHECK_S			>
	;
	; Send u:ua:rsp:F
	;
		call	SendUaRspFrame
	;
	; Intialize-Connection-State
	;
		call	InitConnectionState
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
	;
	; Next State := RECV
	;
		ChangeState	RECV_S, ds
		.leave
		ret	
ResetResponseRESET_CHECK_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisconnectRequestRESET_CHECK_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The service user wants to disconnect

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisconnectRequestRESET_CHECK_S	proc	far
		.enter
EC < 		WARNING	DISCONNECT_REQUEST_RESET_CHECK_S		>
	;
	; Send u:ua:rsp:F
	;
		call	SendRdRspFrame
	;
	; Send notification 
	;
		mov	si, SST_IRDA
		mov	di, NII_STATUS_INDICATION
		mov	cx, ISIT_DISCONNECTED
		call	SysSendNotification
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
	;
	; Clr DisconnectRequest Flag
	;
		BitClr	ds:IS_status, ISS_PENDING_DISCONNECT
	;
	; Next State := SCLOSE
	;
		ChangeState	SCLOSE, ds
		.leave
		ret
DisconnectRequestRESET_CHECK_S	endp


;------------------------------------------------------------------------------
;			      RESET_S
;------------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvSnrmCmdRESET_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received SNRM packet while trying to reset

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	initialize-connection-state
	send u:ua:rsp:F
	Reset-confirm
	change to XMIT_S

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvSnrmCmdRESET_S	proc	far
		.enter
EC <		WARNING	RECV_SNRM_CMD_RESET_S				>
	;
	; Init-Connection-State
	;
		call	InitConnectionState
	;
	; Send u:ua:rsp:F
	;
		call	SendUaRspFrame
	;
	; Reset-Confirm
	;
		call	ResetConfirm
	;
	; Next State := XMIT 
	;
		ChangeState	XMIT_S, ds
		.leave
		ret
RecvSnrmCmdRESET_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDmCmdRESET_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a disconnection notice from the other side

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDmCmdRESET_S	proc	far
		.enter
EC <		WARNING	RECV_DM_CMD_RESET_S				>
	;
	; Stop-WD-Timer
	;
		call	StopWDTimer
		call	WDTimerExpiredRESET_S
				;
				; Release-Buffered-Data
				; Apply-Default-Connection-Params
				; Disconnect-Indication
				;
		.leave
		ret
RecvDmCmdRESET_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WDTimerExpiredRESET_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timer expired while waiting for a response to our reset
		request from remote station.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WDTimerExpiredRESET_S	proc	far
		.enter
EC <		WARNING	WD_TIMER_EXPIRED_RESET_S			>
	;
	; Apply-Default-Connection-Params
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_CONNECTION_TIMEOUT_S
		call	DisconnectIndication
	;
	; Release-Buffered-Data
	;
		call	ReleaseBufferedData
	;
	; Next state := NDM
	;
		ChangeState	NDM, ds
		.leave
		ret
WDTimerExpiredRESET_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerRESET_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handle for packets arriving while we are waiting for
		a response to our reset request.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerRESET_S	proc	far
		.enter
EC <		WARNING	DEFAULT_HANDLER_RESET_S				>
	;
	; Is this x:x:cmd:P?
	;
		and	cx, mask IEI_BITCR shl 8 or mask IICF_PFBIT
		cmp	cx, mask IICF_PFBIT
		stc
		jnz	exit
	;
	; Send u:rnrm:rsp:F
	;
		clr	bx
		mov	ch, ds:IS_connAddr
		mov	cl, IUR_RNRM_RSP or mask IUCF_PFBIT
		call	IrlapSendUFrame
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		clc
exit:
		.leave
		ret
DefaultHandlerRESET_S	endp


;------------------------------------------------------------------------------
;				  BUSY_S
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataRequestBUSY_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received send data request from the service user.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataRequestBUSY_S	proc	far
		.enter
EC <		WARNING	DEFAULT_HANDLER_BUSY_S				>
	;
	; Send-Data-With-PFbit-Clear
	;
		call	SendDataWithPFbitClear
	;
	; Check if we can send data packets now
	;
		dec	ds:IS_pendingConnectedData
		dec	ds:IS_pendingData
		jz	skipWindowCheck
		cmp	ds:IS_window, 1
		jne	done
skipWindowCheck:
	;
	; send s:rnr:rsp:F
	;
		mov	cl, ISR_RNR_RSP or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; window := windowSize (= remoteMaxWindows)
	;
		movm	ds:IS_window, ds:IS_remoteMaxWindows, al
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
	;
	; Next State = BUSY_WAIT
	;
		ChangeState	BUSY_WAIT_S, ds
done:
		.leave
		ret
DataRequestBUSY_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalBusyClearedBUSY_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Local service user can now accept incoming data packets

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalBusyClearedBUSY_S	proc	far
		.enter
EC <		WARNING	LOCAL_BUSY_CLEARED_BUSY_S			>
	;
	; Send s:rr:rsp:F
	;
		mov	cl, ISR_RR_RSP or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
	;
	; Next State = RECV_S
	;
		ChangeState	RECV_S, ds
		.leave
		ret
LocalBusyClearedBUSY_S	endp

;------------------------------------------------------------------------------
;				BUSY_WAIT_S
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BusyClearedBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Busy state is cleared

CALLED BY:	event loop
PASS:		ds = station segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BusyClearedBUSY_WAIT_S	proc	far
		.enter
	;
	; This is not in spec, but I will just put it in so that we can get
	; out of this dreadfull BUSY_WAIT_S state when local busy is cleared.
	;                                       10/15/96 Steve Jang
	;
		ChangeState	RECV_S, ds
	
		.leave
		ret
BusyClearedBUSY_WAIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvICmdNotPBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received I frame with P bit off

IMPL NOTES:	we also free the I packet here since we're not processing it

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvICmdNotPBUSY_WAIT_S	proc	far
		.enter
EC <		WARNING	RECV_I_CMD_NOT_P_BUSY_WAIT_S			>
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		.leave
		ret
RecvICmdNotPBUSY_WAIT_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvICmdPBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received an Information frame with P bit set

IMPL NOTES:	since we're not processing the packet anymore, we free it

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	Update Nr recevied

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvICmdPBUSY_WAIT_S	proc	far
	.enter

EC <		WARNING	RECV_I_CMD_BUSY_WAIT_S				>
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Check for pending data requests
	;
		tst	ds:IS_pendingData
		jz	noPendingData
		test	ds:IS_status, mask ISS_REMOTE_BUSY
		jnz	remoteBusy
	;
	; Stop-WD-Timer
	;
		call	StopWDTimer
exit:
	;
	; Next state := BUSY
	;
		ChangeState	BUSY_S, ds
done:
		.leave
		ret
noPendingData:
remoteBusy:
		call	BusyWaitBusyOrNoPending
				;
				; Wait-Minimum-Turnaround-Delay
				; Send s:rnr:rsp:F
				; Start-WD-Timer
				;
		jmp	done
RecvICmdPBUSY_WAIT_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUiCmdNotPBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	received an unnumbered packet

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUiCmdNotPBUSY_WAIT_S	proc	far
		.enter
EC < 		WARNING	RECV_UI_CMD_NOT_P_BUSY_WAIT_S			>
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		.leave
		ret
RecvUiCmdNotPBUSY_WAIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUiCmdPBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received unnumbered information packet with P bit set

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	stop-F-timer
	start-P-timer		
	free packet
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUiCmdPBUSY_WAIT_S	proc	far
		.enter
EC <		WARNING	RECV_UI_CMD_BUSY_WAIT_S				>
	;
	; Check for pending data or remoteBusy
	;
		tst	ds:IS_pendingData
		jz	noPendingData
		test	ds:IS_status, mask ISS_REMOTE_BUSY
		jnz	remoteBusy
	;
	; Stop-WD-Timer
	;
		call	StopWDTimer
	;
	; Next State := BUSY
	;
		ChangeState	BUSY_S, ds
done:
		.leave
		ret
noPendingData:
remoteBusy:
		call	BusyWaitBusyOrNoPending
		jmp	done
RecvUiCmdPBUSY_WAIT_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvXidCmdBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received an XID frame
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvXidCmdBUSY_WAIT_S	proc	far
		.enter
EC < 		WARNING	RECV_XID_CMD_BUSY_WAIT_S			>
		call	BusyWaitBusyOrNoPending
		.leave
		ret
RecvXidCmdBUSY_WAIT_S	endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRrCmdBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a receive-ready frame from remote side

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRrCmdBUSY_WAIT_S	proc	far
		.enter
EC <		WARNING	RECV_RR_CMD_BUSY_WAIT_S				>
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Stop-WD-Timer
	;
		call	StopWDTimer
	;
	; UpdateNrReceived
	;
		call	UpdateNrReceived
	;
	; Check for pending data or remoteBusy
	;
		tst	ds:IS_pendingData
		jz	noPendingData
		test	ds:IS_status, mask ISS_REMOTE_BUSY
		jnz	remoteBusy
	;
	; remoteBusy := false
	;
		BitClr	ds:IS_status, ISS_REMOTE_BUSY
	;
	; Next state := BUSY
	;
		ChangeState	BUSY_S, ds
done:
		.leave
		ret
noPendingData:
remoteBusy:
		call	BusyWaitBusyOrNoPending
		jmp	done
RecvRrCmdBUSY_WAIT_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRnrCmdBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	received a receive-not-ready frame

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRnrCmdBUSY_WAIT_S	proc	far
		.enter
EC <		WARNING	RECV_RNR_CMD_BUSY_WAIT_S			>
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; remoteBusy := true
	;
		BitSet	ds:IS_status, ISS_REMOTE_BUSY
		call	BusyWaitBusyOrNoPending
		.leave
		ret
RecvRnrCmdBUSY_WAIT_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRejCmdBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received rejected frame notice

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	Do the same thing as in RECV_S, except state change		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRejCmdBUSY_WAIT_S	proc	far
		.enter
EC <		WARNING	RECV_REJ_CMD_BUSY_WAIT_S			>
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Resend-reject-frames
	;
		call	ResendRejFrames
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		.leave
		ret
RecvRejCmdBUSY_WAIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WDTimerExpiredBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timer expired

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WDTimerExpiredBUSY_WAIT_S	proc	far
		.enter

EC < 		WARNING	WD_TIMER_EXPIRED_BUSY_WAIT_S			>
	;
	; Check Retry count
	;
		mov	al, ds:IS_retryCount
		cmp	al, ds:IS_retryN1		
		je	disconnWarning
		cmp	al, ds:IS_retryN2
		jae	disconnLink
		jmp	startTimer
disconnWarning:
		mov	cx, ISIT_BLOCKED
		call	StatusIndication		; warn user
		BitSet	ds:IS_status, ISS_WARNED_USER
startTimer:
	;
	; give it another try
	;
		call	StartWDTimer
		inc	ds:IS_retryCount
done:
		.leave
		ret
disconnLink:
	;
	; Apply-default-Connection-Params
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_CONNECTION_TIMEOUT_S
		call	DisconnectIndication
	;
	; Next state := NDM
	;
		ChangeState	NDM, ds
		jmp	done
WDTimerExpiredBUSY_WAIT_S	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			RecvRdRSPBUSY_WAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;; same as RecvRdCmdRECV_S


;------------------------------------------------------------------------------
;				  SCLOSE
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscCmdSCLOSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	received a disconnection request from remote side
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscCmdSCLOSE		proc	far
EC <		WARNING	RECV_DISC_CMD_SCLOSE				>
	;
	; Send u:ua:rsp:F
	;
		call	SendUaRspFrame
	;
	; rest is the same as RecvDmRspSCLOSE
	;
		FALL_THRU RecvDmRspSCLOSE
				;
				; Stop-WD-Timer
				; Apply-Default-Connecion-Params
				; Disconnect-Indication
				; Next state := NDM
				;
RecvDiscCmdSCLOSE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDmRspSCLOSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a disconnect notice from the other side

CALLED BY:	Irlap server thread
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr
RETURN:		nothing
DESTROYED:	dxbp preserved		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDmRspSCLOSE		proc	far
EC <		WARNING	RECV_DM_RSP_SCLOSE				>
	;
	; Stop-WD-Timer
	;
		call	StopWDTimer
	;
	; Apply Default-Connection-Params
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_REMOTE_DISCONNECTION
		call	DisconnectIndication
	;
	; Next State := NDM
	;
		ChangeState	NDM, ds
		ret
RecvDmRspSCLOSE		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WDTimerExpiredSCLOSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timer expired in SCLOSE state

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WDTimerExpiredSCLOSE	proc	far
		.enter
EC <		WARNING	WD_TIMER_EXPIRED_SCLOSE				>
	;
	; Apply-Default-Connection-Params
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_CONNECTION_TIMEOUT_S
		call	DisconnectIndication
	;
	; Next state := NDM
	;
		ChangeState	NDM, ds
		.leave
		ret
WDTimerExpiredSCLOSE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerSCLOSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a packet other than the ones we recognized

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet optr

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerSCLOSE	proc	far
		.enter
EC <		WARNING	DEFAULT_HANDLER_SCLOSE				>
		test	cl, mask IICF_PFBIT		; is it x:x:x:P
		jz	exit
	;
	; send u:rd:rsp:F
	;
		clr	bx
		mov	ch, ds:IS_connAddr
		mov	cl, IUR_RD_RSP or mask IUCF_PFBIT
		call	IrlapSendUFrame
exit:
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		clc
		.leave
		ret
DefaultHandlerSCLOSE	endp

;------------------------------------------------------------------------------
;				Utility
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BusyWaitBusyOrNoPending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait-Minimum-Turnaround-Delay
		Send s:rnr:rsp:Vr:F
		StartWDTimer
CALLED BY:	various routines in this file
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BusyWaitBusyOrNoPending	proc	near
		.enter
	;
	; Wait-Minimum-Turnaround-Delay: moved inside IrlapSendPacket
	;

	;
	; Send s:rnr:rsp:Vr:F
	;
		mov	cl, ISR_RNR_RSP or mask ISCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
		.leave
		ret
BusyWaitBusyOrNoPending		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartWDTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts the secondary's primary watch dog (WD) timer

CALLED BY:	various
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
StartWDTimer	proc	far
		uses	cx,dx
		.enter
		movdw	axbx, ds:IS_wdTimer
		call	TimerStop
EC <		WARNING	_START_WD_TIMER					>
		mov	bx, ds:IS_eventThreadHandle	;start-WD-timer
		mov	cx, ds:IS_maxTurnAround		;turnaround time
	;	PrintMessage <hack>
	;	add	cx, 3
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	dx, ILE_TIME_EXPIRE shl 8 or mask ITEV_WD
if	SLOW_TIMEOUT
		shl	cx, 1
		shl	cx, 1
endif
	;
	; if thread handle is 0, the thread is dead
	;
		tst	bx
		jz	done
	;
	; start the timer
	;
		call	TimerStart
		movdw	ds:IS_wdTimer, axbx
	;
	; if event thread has been detached, stop the timer
	;
		tst	ds:IS_eventThreadHandle
		jz	stopTimer
done:
		.leave
		ret
stopTimer:
		call	TimerStop
		jmp	done
StartWDTimer		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopWDTimer
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
StopWDTimer	proc	near
		.enter
EC <		WARNING	_STOP_WD_TIMER					>
		clr	ds:IS_retryCount
		movdw	axbx, ds:IS_wdTimer
		call	TimerStop
		.leave
		ret
StopWDTimer		endp
	
IrlapTransferCode	ends
