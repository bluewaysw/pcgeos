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
DataRequestXMIT_P          		XMIT state routines
DisconnectRequestXMIT_P    
ResetRequestXMIT_P         
LocalBusyDetectedXMIT_P    
PTimerExpiredXMIT_P        
			   
RecvIRspFRECV_P            		RECV_P state routines
RecvIRspNotFRECV_P         
RecvInvalidSeqRECV_P       
RecvRnrmRspRECV_P          
RecvRdRspRECV_P            
RecvFrmrRspRECV_P          
RecvRejRspRECV_P           
RecvSrejRspRECV_P          
RecvRrRspRECV_P            
RecvRnrRspRECV_P           
FTimerExpiredRECV_P        
LocalBusyDetectedRECV_P    
RecvUiRspFRECV_P           
RecvUiRspNotFRECV_P        
RecvXidRspRECV_P           
DefaultHandlerRECV_P       
			   
ResetRequestRESET_WAIT_P   		RESET_WAIT_P state routines
			   
RecvUaRspRESET_P           		RESET_P state routines
RecvDmRspRESET_P           
FTimerExpiredRESET_P       
DefaultHandlerRESET_P      
			   
DataRequestBUSY_P          		BUSY_P state routines
LocalBusyClearedBUSY_P     
PTimerExpiredBUSY_P        
			   
RecvIRspFBUSY_WAIT_P       		BUSY_WAIT_P state routines
RecvIRspNotFBUSY_WAIT_P    
RecvUiRspFBUSY_WAIT_P      
RecvRrRspBUSY_WAIT_P       
RecvRejRspBUSY_WAIT_P      
FTimerExpiredBUSY_WAIT_P   
DefaultHandlerBUSY_WAIT_P  
			   
RecvUaRspPCLOSE            		PCLOSE state routines
FTimerExpiredPCLOSE        
			   
StartPTimer                		Primary transfer specific procedures
StartFTimer                

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/26/94   	Initial revision


DESCRIPTION:
	Irlap information transfer procedures: primary role

	$Id: irlapPXfer.asm,v 1.1 97/04/18 11:56:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapTransferCode		segment	resource

;------------------------------------------------------------------------------
;				  XMIT_P
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUIFrameNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a UI frame

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station
		es	= dgroup
		cx	= addr+control field
		dxbp	= buffer
RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUIFrameNDM	proc	far
		.enter
	;
	; Indicate Unitdata
	; ds	= station
	; cx	= data size
	; dxbp	= unitdata buffer
	;
		call	UnitdataIndication		; dx	= 0
		
		.leave
		ret
RecvUIFrameNDM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnitdataRequestNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If media flag is not busy, send Unitdata

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station
		es	= dgroup
		cx	= Data size
		dxbp	= buffer
RETURN:		nothing
DESTROYED:	everything

STRATEGY:
	If in NDM,
		Send unitdata with PF bit set
	elsif in XMIT,
		if IS_window = 1,
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
	SJ	10/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnitdataRequestNDM	proc	far
		.enter
EC <		WARNING	UNITDATA_REQUEST_NDM				>
	;
	; Check for media flag
	;
		dec	ds:IS_pendingData
		test	ds:IS_status, mask ISS_MEDIA_BUSY
		jnz	exit
		or	cx, mask URP_PFBIT
		mov	al, IRLAP_BROADCAST_CONNECTION_ADDR
		call	SendUnitdata
exit:
		.leave
		ret
UnitdataRequestNDM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataRequestNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore data requests in NDM, but make sure data is freed.

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station
		es	= dgroup
		cx	= data size
		^ldx:bp	= HugeLMem buffer of DataRequestParams
RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataRequestNDM	proc	far
		.enter
EC <		WARNING	DATA_REQUEST_NDM				>
	;
	; keep track of how many packets we discarded!!!
	;
		dec	ds:IS_pendingData
		cmp	ds:IS_pendingConnectedData, 1
		jl	skipConnectedDataCount		; there could have been
		dec	ds:IS_pendingConnectedData	; udata requests
skipConnectedDataCount:
		call	IrlapUnwrapDataRequestParams	;^ldx:bp = buf
							;si = data offset
		movdw	axcx, dxbp
		call	HugeLMemFree
		.leave
		ret
DataRequestNDM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnitdataRequestXMIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send Unitdata

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station
		es	= dgroup
		cx	= Data size
		dxbp	= DataRequestParams buffer
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
UnitdataRequestXMIT_P	proc	far
		.enter
EC <		WARNING	UNITDATA_REQUEST_XMIT_P				>
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
		or	al, IRLAP_BROADCAST_CONNECTION_ADDR; preserve C/R bit
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
	; Send u:ui:cmd:~P:data
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
	; Stop-P-Timer
	;
		push	ax
		call	StopPTimer
		pop	ax
	;
	; Send u:ui:cmd:P:data
	;
		or	cx, mask URP_PFBIT
		call	SendUnitdata
	;
	; window := windowSize
	;
		movm	ds:IS_window, ds:IS_remoteMaxWindows, al
	;
	; Start-F-Timer
	;
		call	StartFTimer
		ChangeState	RECV_P, ds
		jmp	done
		
UnitdataRequestXMIT_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataRequestXMIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has requested some data to be delivered

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station offset
		es 	= dgroup
		ax	= event code
		cx	= data size
		dx:bp	= hugelmem handle for DataRequestParams
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	[remote is not busy]
		if (window > 1) {
			Send-Data-With-P-Bit-Cleared
		}
		else 	{
			Send-Data-With-P-Bit-Set
			[note: start-F-timer is not included as in the
			spec, it's defined in this function.  This allows
			secondary to reuse Send-Data-With-P-Bit-Set.]
			change to RECV_P
		}
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataRequestXMIT_P	proc	far
		.enter
EC < 		WARNING	DATA_REQUEST_XMIT_P				>
	;
	; remoteBusy is checked before this message is sent
	; 
		dec	ds:IS_pendingData
		dec	ds:IS_pendingConnectedData
		jz	sendWithP		; no more pending data
		cmp	ds:IS_window, 1
		je	sendWithP
	;
	; Send-data-with-P-bit-clear
	;
		call	SendDataWithPFbitClear
exit:
		clr	dx			; packet has been consumed
		.leave
		ret
sendWithP:
	;
	; Send-data-with-P-bit-set
	;
		call	SendDataWithPFbitSet
	;
	; Start-F-Timer
	;
		; This is already called in SendDataWithPFbitSet. -Chung 12/6
		;call	StartFTimer
	;
	; Next State
	;
		ChangeState	RECV_P, ds
		jmp	exit

DataRequestXMIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetRequestXMIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has requested connect be reset

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds	= station
		es    	= dgroup
		ax    	= event code
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	stop-P-timer
	Send snrm
	retryCount := 0		
	start-F-timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetRequestXMIT_P	proc	far
		.enter
EC < 		WARNING	RESET_REQUEST_XMIT_P				>
	;
	; Stop-P-Timer
	;
		call	StopPTimer
	;
	; send u:snrm:cmd:P:ca:NA:da
	;
		call	SendSnrmPacket
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
		BitClr	ds:IS_status, ISS_WARNED_USER
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; Next state
	;
		ChangeState	RESET_P, ds
		.leave
		ret
ResetRequestXMIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisconnectRequestXMIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User requested a disconnection

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds	= station
		es	= dgroup
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisconnectRequestXMIT_P	proc	far
		.enter
EC <		WARNING	DISCONNECT_REQUEST_XMIT_P			>
	;
	; Send u:disc:cmd:P
	;
		mov	ch, ds:IS_connAddr
		mov	cl, IUC_DISC_CMD or mask IUCF_PFBIT
		clr	bx
		call	IrlapSendUFrame
	;
	; Release-Buffered-Data
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
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount	; retryCount := 0
		BitClr	ds:IS_status, ISS_WARNED_USER
	;
	; Clr disconnect request flag
	;
		BitClr	ds:IS_status, ISS_PENDING_DISCONNECT
	;
	; Next State
	;
		ChangeState	PCLOSE, ds

		.leave
		ret
DisconnectRequestXMIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalBusyDetectedXMIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The local layer is very busy,  and subsequent transmitted
		packts from secondaries may be lost.

CALLED BY:	IrlapMessageProcessCallback (event handler)
PASS:		ds	= station
		es 	= dgroup
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalBusyDetectedXMIT_P	proc	far
		.enter
EC <		WARNING	LOCAL_BUSY_DETECTED_XMIT_P			>
	;
	; Empty
	;
		ChangeState	BUSY_P, ds
		.leave
		ret
LocalBusyDetectedXMIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PTimerExpiredXMIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Poll timer expired

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PTimerExpiredXMIT_P	proc	far
		.enter
EC < 		WARNING	P_TIMER_EXPIRED_XMIT_P				>
	;
	; Send s:rr:Vr:P
	;
		mov	cl, ISC_RR_CMD or mask ISCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; Next State
	;
		ChangeState	RECV_P, ds
		.leave
		ret
PTimerExpiredXMIT_P	endp


;------------------------------------------------------------------------------
;				  RECV_P
;------------------------------------------------------------------------------
;
;	All event handling routines should not trash dxbp on exiting.
;   The event routines that passed the buffer off to the user must clear
;   dx to prevent IrlapMessageProcessCallback from freeing the buffer.
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvIRspFRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received an I frame with F bit on

CALLED BY:	IrlapMessageProcessCallback (Event handler)
PASS:		ds      = station
		es 	= dgroup
		ax	= message #
		ch,cl   = addr, control
		dx:bp	= data
RETURN:		dx	= 0 if the packet was received
		dx:bp	= preserved if the packet is ignored
DESTROYED:	ax, bx, cx
SIDE EFFECTS:	
	If (Nr and Ns expected)
		stop-F-timer
		Data-Indication
		Vr := Vr + 1 mod 8
		Update Nr Received
		=transition to RECV_P=
	else if (Ns and Nr are invalid)
		stop-all-timers
		Reset-Indication
	else if (Ns unexpected)
		Update Nr received ( doesn't matter, they will send again )
		Send s:rej:cmd:P:Vr
		start-F-timer
	else if (Ns expected but Nr unexpected)
		Data-Indication
		Vr := Vr + 1 mod 8
		Update Nr received
		resend rejected	frames
		start-F-timer

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/26/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvIRspFRECV_P		proc	far
		.enter
EC <		WARNING	RECV_I_RSP_RECV_P				>

		CheckRecoverFromBlocked		; recover from blocked status?
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
	; Check if Nr is expected: should be the same as Vs
	;
		mov	bl, cl
		and	bl, mask IICF_NR	; bl = Nr
		mov	bh, ds:IS_vs		;
		ror4	bh			; bh = Vs
		cmp	bl, bh
		jne	unexpectedNr
	;
	; Expected Ns, Nr
	; Stop-F-Timer
	;
		call	StopFTimer
	;
	; Data-Indication
	;
		call	DataIndication		; dx = 0
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
		push	cx			; always save control header!
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
	; Vr := Vr + 1 mod 8 (bl = current Vr)
	;
		IncVr	ds
	;
	; Update Nr received
	;
		call	UpdateNrReceived
        ;
        ; As we have inaccurate timer[0 to 16ms for the first tick], we might
        ; as well not use P timer for turning the link around.  Instead, we
        ; turn the link around right now if there are no data requests pending.
        ;
        ; Another difference between this and starting the timer is that this
        ; way we know for sure that we have handled iFrame with F bit set
        ; before sending out RR.
        ;
        ; In some cases, 4 asynchronous events such as serial ints, timer ints,
        ; event thread event, server thread event create strange IrLAP state.
        ;
                tst     ds:IS_pendingData
                jz      turnLinkAround  ; we don't start P timer, hew...
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; Next state
	;
		ChangeState	XMIT_P, ds
done:
		.leave
		ret

turnLinkAround:
        ;
        ; basically do the same thing as when PTimer expired
        ;
                call    PTimerExpiredXMIT_P
                jmp     done

unexpectedNs:
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	; 
	; Send s:rr:cmd:P:Vr
	;
		mov	cl, ISC_RR_CMD or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-F-Timer
	;
		call	StartFTimer
		jmp	done
unexpectedNr:
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
		push	cx
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
	; Resend-rejected-frames
	;
		call	ResendRejFrames
	;
	; Start-F-Timer
	;
		call	StartFTimer
		jmp	done
	
RecvIRspFRECV_P		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvIRspNotFRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	I frames with P bit off

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

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvIRspNotFRECV_P	proc	far
		.enter
EC <		WARNING	RECV_I_RSP_NOT_F_RECV_P				>
	;
	; Check if Ns is expected: should be the same as Vr
	; ( We don't check Nr until secondary is done sending all its packets )
	;
		mov	bl, cl
		and	bl, mask IICF_NS	; bl = Ns
		mov	bh, ds:IS_vr		;
		ror4	bh			; bh = Vr
		cmp	bl, bh
		jne	unexpectedNs
	;
	; Expected Ns: normal case
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
		.leave
		ret

RecvIRspNotFRECV_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvInvalidSeqRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Either Nr or Ns of the frame is invalid

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = control field
		dx:bp = buffer

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvInvalidSeqRECV_P	proc	far
		.enter
EC <		WARNING	RECV_INVALID_SEQ_RECV_P				>
	;
	; Stop-all-timers
	;
		call	StopAllTimers
	;
	; Reset-Indication
	;
		mov	cx, IRIT_LOCAL
		call	ResetIndication
	;
	; NextState
	;
		ChangeState	RESET_WAIT_P, ds
		
		.leave
		ret
RecvInvalidSeqRECV_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUiRspNotFRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a unit data packet with F bit off
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		Unit-Data-Indication

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUiRspNotFRECV_P	proc	far
		.enter
EC <		WARNING	RECV_UI_NOT_F_RSP_RECV_P			>
	;
	; Unit-Data-Indication
	;
		call	UnitdataIndication
		.leave
		ret
RecvUiRspNotFRECV_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUiRspFRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a unit data packet
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = addr + control
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		Unit-data-indication

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUiRspFRECV_P	proc	far
		.enter
EC <		WARNING	RECV_UI_RSP_RECV_P				>
	;
	; Stop-F-Timer
	;
		call	StopFTimer
	;
	; Unit-Data-Indication
	;
		call	UnitdataIndication
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; NextState = XMIT
	;
		ChangeState	XMIT_P, ds
		.leave
		ret
RecvUiRspFRECV_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvXidRspRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received XID rsp frame
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvXidRspRECV_P	proc	far
		.enter
EC <		WARNING	RECV_XID_RSP_RECV_P				>
	;
	; Renegoitiate connection
	;
		call	RenegotiateConnection
	;
	; Next State
	;
		ChangeState	XMIT_P, ds
		
		.leave
		ret
RecvXidRspRECV_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRrRspRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recv a recv ready frame
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)
PSEUDO CODE/STRATEGY:
	if Nr is expected
		stop-F-Timer
		remoteBusy := false		* the same as in the other case
		UpdateNrReceived		* (below)
		Start-P-Timer
		state := XMIT
	else ( Nr is unexpected )
		remoteBusy := false		*
		UpdateNrReceived		*
		resend-rejected-frames
		start-F-Timer
		state := RECV( unchanged )

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRrRspRECV_P		proc	far
		.enter
EC <		WARNING	RECV_RR_RSP_RECV_P				>

		CheckRecoverFromBlocked		; recover from blocked status?
	;
	; remoteBusy := false
	;
		BitClr	ds:IS_status, ISS_REMOTE_BUSY
	;
	; UpdateNrReceived
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
	; Stop-F-Timer
	;
		call	StopFTimer
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; Next State
	;
		ChangeState	XMIT_P, ds
done:
		.leave
		ret
unexpectedNr:
	;
	; resend-rejected-frames
	;
		call	ResendRejFrames
	;
	; Start-F-Timer
	;
		call	StartFTimer
		jmp	done
RecvRrRspRECV_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRejRspRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a reject rsp
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = addr + control
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		Update-Nr-Received
		Resend-rejected-frames
		Start-F-Timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRejRspRECV_P	proc	far
		.enter
EC <		WARNING	RECV_REJ_RSP_RECV_P				>
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Resend-Rejected-Frames
	;
		call	ResendRejFrames
	;
	; Start-F-Timer
	;
		call	StartFTimer
		.leave
		ret
RecvRejRspRECV_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvSrejRspRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recv a SREJ response frame
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = buffer

RETURN:		nothing
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
		Update-Nr-Received
		Resend-Rejected-Frame
		Start-F-Timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvSrejRspRECV_P	proc	far
		.enter
EC <		WARNING	RECV_SREJ_RSP_RECV_P				>
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Resend-Rejeceted-Frame( just one frame )
	;
		call	ResendSrejFrame
	;
	; Start-F-Timer
	;
		call	StartFTimer
		.leave
		ret
RecvSrejRspRECV_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRnrRspRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a receive-not-ready frame
		Secondary station might be busy

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		Stop-F-Timer
		remoteBusy := True
		Start-P-Timer
		State = XMIT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRnrRspRECV_P	proc	far
		.enter
EC <		WARNING	RECV_RNR_RSP_RECV_P				>
	;
	; Stop-F-Timer
	;
		call	StopFTimer
	;
	; remoteBusy := true
	;
		BitSet	ds:IS_status, ISS_REMOTE_BUSY
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Start-F-Timer
	;
		call	StartPTimer
	;
	; Next State
	;
		ChangeState	XMIT_P, ds
		.leave
		ret
RecvRnrRspRECV_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvFrmrRspRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	(primary)
		Recv a frame reject response
		
IMPL NOTES:	(alternative action available)
		You can ignore this packet and return to XMIT_P state
		- what do I do with the frmr frame data?

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		Stop-All-Timers
		ResetIndication

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvFrmrRspRECV_P	proc	far
		.enter
EC <		WARNING	RECV_FRMR_RSP_RECV_P				>
	;
	; Stop-All-Timers
	;
		call	StopAllTimers
	;
	; Reset-Indication
	;
		mov	cx, IRIT_LOCAL
		call	ResetIndication
	;
	; Next State
	;
		ChangeState	RESET_WAIT_P, ds
		.leave
		ret
RecvFrmrRspRECV_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRdRspRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a request disconnect rsp from secondary
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		Send  u:disc:cmd:P
		Release-buffered-data
		start-F-Timer
		retry-count

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRdRspRECV_P		proc	far
		.enter
EC <		WARNING	RECV_RD_RSP_RECV_P				>
	;
	; Send  u:disc:cmd:P
	;
		mov	ch, ds:IS_connAddr
		mov	cl, IUC_DISC_CMD or mask IUCF_PFBIT
		clr	bx
		call	IrlapSendUFrame
	;
	; Release-buffered-data
	;
		call	ReleaseBufferedData
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
		BitClr	ds:IS_status, ISS_WARNED_USER
	;
	; Next State
	;
		ChangeState	PCLOSE, ds
		.leave
		ret
RecvRdRspRECV_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRnrmRspRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recv a RNRM rsp: secondary station requests reset.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		stop-all-timers
		Reset-indication
		Send u:snrm:cmd:P
		Initialize-Connection-State
		start-F-Timer
		state -> RESET

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRnrmRspRECV_P	proc	far
		.enter
EC <		WARNING	RECV_RNRM_RSP_RECV_P				>
	;
	; Stop-all-timers
	;
		call	StopAllTimers
	;
	; Reset-Indication
	;
		push	cx
		mov	cx, IRIT_REMOTE
		call	ResetIndication		; Reset-Indication(remote)
		pop	cx
	;
	; Send u:snrm:cmd:P
	;
		call	SendSnrmPacket
	;
	; Initialize-connection-state
	;
		call	InitConnectionState
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; Next State
	;
		ChangeState	RESET_P, ds
		.leave
		ret
RecvRnrmRspRECV_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalBusyDetectedRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Local machine cannot accept incoming data for the moment

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		empty
		State -> BUSY_WAIT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalBusyDetectedRECV_P	proc	far
		.enter
EC <		WARNING	LOCAL_BUSY_DETECTED_RECV_P			>
	;
	; Empty
	;
		ChangeState BUSY_WAIT_P, ds
		.leave
		ret
LocalBusyDetectedRECV_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FTimerExpiredRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	F timer expired

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	if (retryCount < N2 and != N1)
		Send s:rr:cmd:Vr:P
		Start-F-Timer
		retryCount := retryCount + 1
	else if (retryCount = N1)
		Status-Indication
		send s:rr:cmd:Vr:P
		start-F-timer
		retryCount := retryCount + 1
	else if (retryCount >= N2)
		Apply-Default-Connection-Parameters
		Disconnect-Indication
		change to NDM

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FTimerExpiredRECV_P	proc	far
		.enter
EC < 		WARNING	F_TIMER_EXPIRED_RECV_P				>
	;
	; Check retry count
	;
		mov	al, ds:IS_retryCount
		cmp	al, ds:IS_retryN1		
		je	disconnWarning		; retry count == N1
		cmp	al, ds:IS_retryN2
		jae	disconnLink		; retry count >= N2
normalTimeout:
	;
	; Send
	;
		mov	cl, ISC_RR_CMD or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; Send s:rr:cmd:Vr:P
	;
		call	StartFTimer
	;
	; inc retryCount
	;
		inc	ds:IS_retryCount
done:
		.leave
		ret
disconnWarning:
	;
	; Status-Indication
	;
		mov	cx, ISIT_BLOCKED
		call	StatusIndication		; warn user
		BitSet	ds:IS_status, ISS_WARNED_USER
		jmp	normalTimeout
disconnLink:
	;
	; Apply-Default-Connection-Params
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_CONNECTION_TIMEOUT_P
		call	DisconnectIndication
	;
	; Release-buffered data	( MODIFICATION ) needed for socket lib
	;
		call	ReleaseBufferedData
	;
	; Next State
	;
		ChangeState	NDM, ds
		jmp	done
		
FTimerExpiredRECV_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	received x:x:x:x packet

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerRECV_P	proc	far
		.enter
EC <		WARNING	DEFAULT_HANDLER_RECV_P				>
	;
	; Check frame type
	;
		and	cl, mask IUCF_CONTROL_HDR
		cmp	cl, mask IUCF_CONTROL_HDR	
		je	seeIfPoll		; U frame ( = 00 )
		test	ch, mask IAF_CRBIT
		jnz	disconnect		; it's either s:cmd or i:cmd

seeIfPoll:
		test	al, mask IICF_PFBIT
		jz	exit
	;
	; Final bit on
	;
		call	StopFTimer
		call	StartPTimer
	;
	; Next state
	;
		ChangeState	XMIT_P, ds
exit:
		clc
		.leave
		ret
disconnect:
	;
	; Primary conflict
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_PRIMARY_CONFLICT
		call	DisconnectIndication
	;
	; Next State
	;
		ChangeState	NDM, ds
		jmp	exit
		
DefaultHandlerRECV_P	endp

;------------------------------------------------------------------------------
;			       RESET_WAIT_P
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetRequestRESET_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User requested reset

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	send u:snrm:cmd:P
	start-F-timer		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetRequestRESET_WAIT_P	proc	far
		.enter
EC <		WARNING	RESET_REQUEST_RESET_WAIT_P			>
	;
	; if XMIT_FLAG is set, send Snrm frame otherwise skip that
	;
		test	ds:IS_status, mask ISS_XMIT_FLAG
		jz	skipSnrm
	;
	; Send-snrm-packet
	;
		clr	ax		; normal connection snrm frame
		call	SendSnrmPacket
skipSnrm:
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; Next State = RESET
	;
		ChangeState	RESET_P, ds
		.leave
		ret
ResetRequestRESET_WAIT_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisconnectRequestRESET_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;; same as DisconnectRequestXMIT_P


;------------------------------------------------------------------------------
;			       RESET_CHECK_P
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetResponseRESET_CHECK_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;;  same as ResetRequestRESET_WAIT_P


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisconnectRequestRESET_CHECK_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;;  same as DisconnectRequestRESET_WAIT_P

;------------------------------------------------------------------------------
;			      RESET_P
;------------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUaRspRESET_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remote station comfirmed reset

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	stop-f-timer
	initialize-connection-state
	reset-confirm
	remoteBusy := false
	start-p-timer
	change to XMIT_P

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUaRspRESET_P	proc	far
		.enter
EC <		WARNING	RECV_UA_RSP_RESET_P				>
	;
	; Stop-F-Timer
	;
		call	StopFTimer
	;
	; InitConnectionState
	;
		call	InitConnectionState
	;
	; Reset-Confirm
	;
		call	ResetConfirm
	;
	; remoteBusy := false
	;
		and	ds:IS_status, not (mask ISS_REMOTE_BUSY)
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; Next State = XMIT
	;
		ChangeState	XMIT_P, ds
		.leave
		ret
RecvUaRspRESET_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDmRspRESET_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remote station wants to disconnect

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDmRspRESET_P	proc	far
		.enter
EC < 		WARNING	RECV_DM_RSP_RESET_P				>
	;
	; Stop-F-Timer
	;
		call	StopFTimer
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
	; Next State = NDM
	;
		ChangeState	NDM, ds, si
		.leave
		ret
RecvDmRspRESET_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FTimerExpiredRESET_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timer expired while waiting for response from remote side

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code
		cx    =
		dx:bp =

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	if (retryCount < N3)
		send u:snrm:cmd:P
		start-F-timer
	else
		Apply-Default-connection-parameters
		disconnect-indication		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FTimerExpiredRESET_P	proc	far
		.enter
EC <		WARNING	F_TIMER_EXPIRED_RESET_P				>
	;
	; check retryCount
	;
		mov	al, ds:IS_retryCount
		cmp	al, ds:IS_retryN3
		jae	disconnect
	;
	; retryCount < N3
	;
		call	ResetRequestRESET_WAIT_P
	;
	; increment retry count
	;
		inc	ds:IS_retryCount
done:
		.leave
		ret
disconnect:
	;
	; Apply-Default-Connection-Params
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_CONNECTION_TIMEOUT_P
		call	DisconnectIndication
	;
	; Next State = NDM
	;
		ChangeState	NDM, ds, si
		jmp	done
FTimerExpiredRESET_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerRESET_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

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
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerRESET_P	proc	far
		.enter
EC <		WARNING	DEFAULT_HANDLER_RESET_P				>
	;
	; Check for response with PF bit set
	;
		test	ch, mask IAF_CRBIT
		jnz	exit
		test	cl, mask IICF_PFBIT
		jz	exit
	;
	; Send-Snrm-Packet
	;
		call	SendSnrmPacket
	;
	; Start-F-Timer
	;
		call	StartFTimer
exit:
		clc
		.leave
		ret
DefaultHandlerRESET_P	endp


;------------------------------------------------------------------------------
;				  BUSY_P
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataRequestBUSY_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User requested some data to be transmitted
		(what a cliche way of saying this...)

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		dx:bp = data

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataRequestBUSY_P	proc	far
		.enter
EC <		WARNING	DATA_REQUEST_BUSY_P				>
	;
	; keep track of counts
	;
		dec	ds:IS_pendingData	; "dequeue" the packet
		dec	ds:IS_pendingConnectedData
		cmp	ds:IS_window, 1
		je	sendWithRnr
	;
	; Send-data-with-PF-bit-clear
	;
		call	SendDataWithPFbitClear
done:
		.leave
		ret
sendWithRnr:
	;
	; Stop-P-Timer
	;
		call	StopPTimer
	;
	; Send-Data-With-PF-bit-Clear
	;
		call	SendDataWithPFbitClear
	;
	; Send s:rnr:Vr:P
	;
		mov	cl, ISC_RNR_CMD or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; window := windowSize
	;
		movm	ds:IS_window, ds:IS_remoteMaxWindows, al
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; Next state = BUSY_WAIT
	;
		ChangeState	BUSY_WAIT_P, ds
		jmp	done
		
DataRequestBUSY_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisconnectRequestBUSY_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;; same as DisconnectRequestXMIT_P 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalBusyClearedBUSY_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The local station is now available to receive data

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		Stop-P-Timer
		Send s:rr:cmd:P
		Start-F-Timer		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalBusyClearedBUSY_P	proc	far
		.enter
EC <		WARNING	LOCAL_BUSY_CLEARED_BUSY_P			>
	;
	; Stop-P-Timer
	;
		call	StopPTimer
	;
	; Send s:rr:cmd:P
	;
		mov	cl, ISC_RR_CMD or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; state = RECV_P
	;
		ChangeState	RECV_P, ds
		.leave
		ret
LocalBusyClearedBUSY_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PTimerExpiredBUSY_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timer expired while waiting for busy condition to be cleared

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		send s:rnr:Vr:P
		Start-F-Timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PTimerExpiredBUSY_P	proc	far
		.enter
EC <		WARNING	P_TIMER_EXPIRED_BUSY_P				>
	;
	; send s:rnr:Vr:P
	;
		mov	cl, ISC_RNR_CMD or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; Next state
	;
		ChangeState	BUSY_WAIT_P, ds
		.leave
		ret
PTimerExpiredBUSY_P	endp


;------------------------------------------------------------------------------
;				BUSY_WAIT_P
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BusyClearedBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Busy condition was cleared

CALLED BY:	Event loop
PASS:		ds = station segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BusyClearedBUSY_WAIT_P	proc	far
		.enter
	;
	; this is not in spec but I think it's necessary, but Genoa test
	; suite fails when we have this.
	;
	;	ChangeState	RECV_P, ds
	;
		.leave
		ret
BusyClearedBUSY_WAIT_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvIRspNotFBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received data packet while local client is too busy to accept
		it.

IMPL NOTES:	since we're not processing the packet anymore, we free it

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	Update Nr recevied
	(packet will be freed in IrlapMessageProcessCallback)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvIRspNotFBUSY_WAIT_P	proc	far
		.enter
EC <		WARNING	RECV_I_RSP_BUSY_WAIT_P				>
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
		
		.leave
		ret
RecvIRspNotFBUSY_WAIT_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvIRspNotFBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Data packet received while the service user is busy

IMPL NOTES:	we also free the I packet here since we're not processing it

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvIRspFBUSY_WAIT_P	proc	far
	.enter
EC <		WARNING	RECV_I_RSP_NOT_F_BUSY_WAIT_P			>
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; Update-Nr-Received
	;
		call	UpdateNrReceived
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; Next state = BUSY
	;
		ChangeState	BUSY_P, ds
	;
	; Data packet will be deallocated by IrlapMessageProcessCallback
	;
		.leave
		ret
RecvIRspFBUSY_WAIT_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUiRspNotFBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;; do nothing no state change and free packet


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUiRspFBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unnumbered Information frame received

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet buffer

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		stop-F-timer
		start-P-timer		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUiRspFBUSY_WAIT_P	proc	far
		.enter
EC <		WARNING	RECV_UI_RSP_BUSY_WAIT_P				>
	;
	; Stop-F-Timer
	;
		call	StopFTimer
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; Next state = BUSY
	;
		ChangeState	BUSY_P, ds
	;
	; packet gets freed in IrlapMessageProcessCallback
	;
		.leave
		ret
RecvUiRspFBUSY_WAIT_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRrRspBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a receive-ready notice from the remote side

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRrRspBUSY_WAIT_P	proc	far
		.enter
EC <		WARNING	RECV_RR_RSP_BUSY_WAIT_P				>
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; Update Nr received
	;
		call	UpdateNrReceived
	;
	; remoteBusy := false
	;
		BitClr	ds:IS_status, ISS_REMOTE_BUSY
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; Next state = BUSY
	;
		ChangeState	BUSY_P, ds
		.leave
		ret
RecvRrRspBUSY_WAIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			RecvRnrRspBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;; same as RecvRrRspBUSY_WAIT_P


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRejRspBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Packet rejeceted at remote side

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = buffer

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	Do the same thing as in RECV_P, except state change		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRejRspBUSY_WAIT_P	proc	far
		.enter
EC <		WARNING	RECV_REJ_RSP_BUSY_WAIT_P			>
	
		call	RecvRejRspRECV_P
				;
				; UpdateNrReceived
				; Resend-rejected-frames
				; start-F-Timer
				;
	;
	; Next state = BUSY-WAIT
	;
		ChangeState	BUSY_WAIT_P, ds
		.leave
		ret
RecvRejRspBUSY_WAIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			RecvRdRspBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;; same as RecvRdRspRECV_P


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FTimerExpiredBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timer expired

IMPL NOTES:	This is a clone of FTimerExpiredRECV_P which sends RNR
		instead of RR frames (not a good idea to clone but more
		confusion if I don't,  I guess....)

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
FTimerExpiredBUSY_WAIT_P  	proc	far
		.enter
EC <		WARNING	F_TIMER_EXPIRED_BUSY_WAIT_P			>
	;
	; Check retry count
	;
		mov	bl, ds:IS_retryCount
		cmp	bl, ds:IS_retryN1		
		je	disconnWarning
		cmp	bl, ds:IS_retryN2
		jae	disconnLink
normalTimeout:
	;
	; (retry count < N2) and (retry count != N1)
	; Send s:rnr:cmd:Vr:P
	;
		mov	cl, ISC_RNR_CMD or mask IUCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; retryCount := retryCount + 1
	;
		inc	ds:IS_retryCount
done:
		.leave
		ret		
disconnWarning:
	;
	; status-indication
	;
		mov	cx, ISIT_BLOCKED
		call	StatusIndication		; warn user
		BitSet	ds:IS_status, ISS_WARNED_USER
		jmp	normalTimeout

disconnLink:
	;
	; Apply-default-connection-params
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-indication
	;
		mov	ax, IC_CONNECTION_TIMEOUT_P
		call	DisconnectIndication
		ChangeState	NDM, ds, si
		jmp	done
FTimerExpiredBUSY_WAIT_P	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerBUSY_WAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received x:x:x:x packet

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerBUSY_WAIT_P	proc	far
		.enter
EC <		WARNING	DEFAULT_HANDLER_BUSY_WAIT_P			>
	;
	; Check PF bit
	;
		test	cl, mask IICF_PFBIT
		jz	exit
	;
	; Stop-F-Timer
	;
		call	StopFTimer
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; Next State
	;
		ChangeState	BUSY_P, ds
exit:
		.leave
		ret
DefaultHandlerBUSY_WAIT_P	endp


;------------------------------------------------------------------------------
;				  PCLOSE
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUaRspPCLOSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a close confirmation from the remote side
CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		cx    = packet header
		dx:bp = packet

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
		Stop-F-Timer
		Apply-Default-Connection-Params
		Disconnect-Indication

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUaRspPCLOSE		proc	far
		.enter
EC < 		WARNING	RECV_UA_RSP_PCLOSE				>
	;
	; Stop-F-Timer
	;
		call	StopFTimer
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
	; Next State
	;
		ChangeState	NDM, ds, si
		.leave
		ret
RecvUaRspPCLOSE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDmRspPCLOSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;; same as RecvUaRspPCLOSE 



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FTimerExpiredPCLOSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timer expired while waiting for a response from the remote
		station about disconnection.

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
FTimerExpiredPCLOSE	proc	far
		.enter
EC <		WARNING	F_TIMER_EXPIRED_PCLOSE				>
		
		mov	al, ds:IS_retryCount
		cmp	al, ds:IS_retryN3
		jae	disconnect
	;
	; Send u:disc:cmp:P
	;
		mov	ch, ds:IS_connAddr
		mov	cl, IUC_DISC_CMD or mask IUCF_PFBIT
		clr	bx
		call	IrlapSendUFrame
	;
	; Start-F-Timer
	;
		call	StartFTimer
		inc	ds:IS_retryCount
done:
		.leave
		ret
disconnect:
	;
	; Apply-Connection-Params
	;
		call	ApplyConnectionParameters
	;
	; Disconnect-Indication
	;
		mov	ax, IC_REMOTE_DISCONNECTION
		call	DisconnectIndication
	;
	; Next State = NDM
	;
		ChangeState	NDM, ds, si
		jmp	done
		
FTimerExpiredPCLOSE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartPTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts a P or F timer

CALLED BY:	various
PASS:		ds   = station
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PTimerTable	byte \
  2,
  2,
  3,
  3,
  7,
  9,
  15,
  27

StartPTimer	proc	far
		uses	bx, cx, dx, di
		.enter		
EC <		WARNING	_START_P_TIMER					>
		movdw	axbx, ds:IS_pTimer
		call	TimerStop
	;
	; determine P timer timeout value:
	;   P timer timeout value(in ticks) should be 0 < n < IS_maxTurnAround
	;   And the number of ticks to use in each case is determined by the
	;   number of consecutive supervisory frame received.
	;
		mov	cx, ds:IS_maxTurnAround
		clr	bh
		mov	bl, ds:IS_rr
		cmp	bx, size PTimerTable
		ja	useMaxTurnAround
		clr	ch
		mov	cl, cs:[PTimerTable][bx]
useMaxTurnAround:
		cmp	cx, ds:IS_maxTurnAround
		jb	cont
		mov	cx, ds:IS_maxTurnAround
cont:
		mov	bx, ds:IS_eventThreadHandle	; start-F-timer
		mov	al, TIMER_EVENT_ONE_SHOT	; max turn around
		mov	dx, ILE_TIME_EXPIRE shl 8 or mask ITEV_P
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
		movdw	ds:IS_pTimer, axbx
	;
	; if event thread has been detached, stop the timer.
	;
		tst	ds:IS_eventThreadHandle
		jz	stopTimer
done:
		.leave
		ret
stopTimer:
		call	TimerStop
		jmp	done
StartPTimer		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartFTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts a F timer

CALLED BY:	various
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	stop previous F timer
	start new F timer	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartFTimer	proc	far
		uses	cx, dx
		.enter		
EC <		WARNING	_START_F_TIMER					>
		movdw	axbx, ds:IS_fTimer
		call	TimerStop
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	bx, ds:IS_eventThreadHandle
		mov	cx, IRLAP_NORMAL_FTIMER_TIMEOUT
		mov	dx, ILE_TIME_EXPIRE shl 8 or mask ITEV_F
if	SLOW_TIMEOUT
		shl	cx, 1
		shl	cx, 1
endif
	;
	; if thread handle is 0, the thread is dead
	;
		tst 	bx
		jz	done
	;
	; start the timer
	;
		call	TimerStart
		movdw	ds:IS_fTimer, axbx
	;
	; if event thread has been detached, stop the timer.
	;
		tst	ds:IS_eventThreadHandle
		jz	stopTimer
done:
		.leave
		ret
stopTimer:
		call	TimerStop
		jmp	done
StartFTimer		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopFTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops the F timer

CALLED BY:	INTERNAL GLOBAL
PASS:		ds	= station segment
RETURN:		axbx	= timer ID + handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
	clear retryCount	( not in protocol )
		; we do this since this only happens when a state transition
		; occurs and retryCount should be set to 0
	stop the timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	6/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopFTimer	proc	near
		.enter
EC <		WARNING	_STOP_F_TIMER					>
		clr	ds:IS_retryCount
		BitClr	ds:IS_status, ISS_WARNED_USER
		movdw	axbx, ds:IS_fTimer
		call	TimerStop
		.leave
		ret
StopFTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopPTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops the P timer

CALLED BY:	Utility
PASS:		nothing
RETURN:		axbx = timer ID + handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	clear retryCount	( not in protocol )
		; we do this since this only happens when a state transition
		; occurs and retryCount should be set to 0
	stop the timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	6/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopPTimer	proc	far
		.enter
EC <		WARNING	_STOP_P_TIMER					>
		clr	ds:IS_retryCount
		BitClr	ds:IS_status, ISS_WARNED_USER
		movdw	axbx, ds:IS_pTimer
		call	TimerStop
		.leave
		ret
StopPTimer	endp
	
IrlapTransferCode	ends

