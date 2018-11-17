COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Socket project
MODULE:		IrLAP driver
FILE:		irlapXchg.asm

AUTHOR:		Steve Jang, Mar  7, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95   	Initial revision

DESCRIPTION:
	Station exchange procedures.		

	$Id: irlapXchg.asm,v 1.1 97/04/18 11:56:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapTransferCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrimaryRequestXMIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Above layer requested to become primary when we are already
		primary
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
RETURN:		nothing
DESTROYED:	nothing
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrimaryRequestXMIT_P	proc	far
		.enter
	;
	; Primary-Confirm
	;
		clr	cx
		call	PrimaryConfirm
		.leave
		ret
PrimaryRequestXMIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRxchgRECV_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received Rxchg packet from remote station

CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
		es = dgroup
RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRxchgRECV_P	proc	far
		.enter
	;
	; Primary-Indication
	;
		call	PrimaryIndication
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; Next state = XCHG_P
	;
		ChangeState XCHG_P, ds
		.leave
		ret
RecvRxchgRECV_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrimaryResponseXCHG_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The upper layer responded to remote station's primary
		request.
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
		es = dgroup
		cx = PrimaryXchgFlag
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrimaryResponseXCHG_P	proc	far
		.enter
	;
	; Decide whether to send xchg:cmd or dxchg:cmd
	;
		test	cx, mask PXF_DENIED
		jnz	denied
		mov	cl, IUC_XCHG or mask IUCF_PFBIT
	;
	; If xchg request was granted, next state = XWAIT_P
	;
		ChangeState XWAIT_P, ds
		jmp	cont
denied:
		mov	cl, IUC_DXCHG or mask IUCF_PFBIT
	;
	; If xchg request denied, next state = RECV_P
	;
		ChangeState RECV_P, ds
cont:
		mov	ch, ds:IS_connAddr
	;
	; Send (d)xchg:cmd
	;
		clr	bx
		call	IrlapSendUFrame
	;
	; Stop-P-Timer
	;
		call	StopPTimer
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; State change has already occured
	;
		.leave
		ret
PrimaryResponseXCHG_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisconnectRequestXCHG_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The upper layer requested disconnection

CALLED BY:	IrlapMessageProcessCallback
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisconnectRequestXCHG_P	proc	far
		.enter
	;
	; Stop-P-Timer
	;
		call	StopPTimer
	;
	; Send u:disc:cmd:P
	; Release-Buffered-Data
	; Start-F-Timer
	; retryCount := 0
	; Clr disconnect request flag
	; Change state to PCLOSE
	;
		call	DisconnectRequestXMIT_P
	;
	; Current state = PCLOSE
	;
		.leave
		ret
DisconnectRequestXCHG_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PTimerExpiredXCHG_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	P timer expired

CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
RETURN:		nothing
DESTROYED:	everything
NOTE:		identical to PTimerExpiredXMIT_P
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PTimerExpiredXCHG_P equ PTimerExpiredXMIT_P
;
; Next state = RECV_P
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRrCmdXWAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received RR command while in XWAIT_P

CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = staiton
		ch = address of the packet
		cl = control field of the packet
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRrCmdXWAIT_P	proc	far
		.enter
	;
	; Stop-F-Timer
	;
		call	StopFTimer
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
	; Switch-to-Secondary
	;
		call	SwitchToSecondary
	;
	; State change occured
	;
		.leave
		ret
RecvRrCmdXWAIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvFrmrRspXWAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remote station indicated that sequence numbers are out of
		synch or some other error
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
		cx = packet header
RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvFrmrRspXWAIT_P	proc	far
		.enter
	;
	; Next State = XMIT_P
	;
		ChangeState XMIT_P, ds
		.leave
		ret
RecvFrmrRspXWAIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRdRspXWAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received Rd frame while in XWAIT_P
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
RETURN:		nothing
DESTROYED:	everything
NOTE:	Identical to RecvRdRspRECV_P
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRdRspXWAIT_P equ RecvRdRspRECV_P
;
; State changed to PCLOSE
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscCmdXWAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received Disc frame while in XWAIT_P

CALLED BY:	IrlapMessageProcessCallback
PASS:		ds	= station
		cx	= packet header
RETURN:		nothing
DESTROYED:	everything
NOTE:		Identical to RecvDiscCmdRECV_S
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscCmdXWAIT_P equ RecvDiscCmdRECV_S
;
; State changed to NDM
;



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FTimerExpiredXWAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	F timer expired while in XWAIT_P
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
		es = dgroup
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FTimerExpiredXWAIT_P	proc	far
		.enter
	;
	; compare retryCount
	;
		mov	al, ds:IS_retryCount
		cmp	al, ds:IS_retryN2
		jae	disconnect
	;
	; retryCount == N1
	;   Perform-Random-Backoff
	;
		call	PerformRandomBackoff
	;
	; if retryCount = N1, warn the user
	; Status indication: warn the user that we will get disconnected
	;
		cmp	al, ds:IS_retryN1
		jne	skipWarning
		call	StatusIndication
skipWarning:
	;
	; Send u:xchg:cmd:P
	;
		mov	cl, IUC_XCHG or mask ISCF_PFBIT
		mov	ch, ds:IS_connAddr
		clr	bx
		call	IrlapSendUFrame
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; retryCount++
	;
		inc	ds:IS_retryCount
	;
	; No state change occurs
	;
		jmp	done
disconnect:
	;
	; retryCount >= N2
	; Apply-Default-Connection-Parameters
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_CONNECTION_TIMEOUT_P
		call	DisconnectIndication
	;
	; Change state to NDM
	;
		ChangeState	NDM, ds
done:
		.leave
		ret
FTimerExpiredXWAIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerXWAIT_P
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We received a bogus packet while in XWIT_P state
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station segment
		cx = packet header
		dxbp = packet
RETURN:		nothing
DESTROYED:	everything
ALGORITHM:
		if packet = response packet
			if F-bit on
				Send u:xchg:cmd:P
				Start-F-Timer
				retryCount := 0
				[no state change]
		elsif packet = command
			Stop-F-Timer
			Switch-To-Secondary
			Perform-Recv(S)-Action
			[state = NRM(S)]
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerXWAIT_P	proc	far
		.enter
		test	ch, mask IAF_CRBIT
		jnz	command
		test	cl, mask IUCF_PFBIT
		jz	empty
	;
	; Send u:xchg:cmd:P
	;
		mov	cl, IUC_XCHG or mask IUCF_PFBIT
		mov	ch, ds:IS_connAddr
		clr	bx
		call	IrlapSendUFrame
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
		jmp	done
command:
	;
	; Stop-F-Timer
	;
		call	StopFTimer
	;
	; Switch-To-Secondary
	;
		call	SwitchToSecondary
	;
	; Perform-Recv(S)-Action
	;
		call	PerformRecvAction
	;
	; State = NRM(S)
	;
empty:
done:
		.leave
		ret
DefaultHandlerXWAIT_P	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrimaryRequestXMIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The upper layer requested to become primary
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrimaryRequestXMIT_S	proc	far
		.enter
	;
	; Send u:rxchg:rsp:F
	;
		mov	cl, IUR_RXCHG or mask IUCF_PFBIT
		mov	ch, ds:IS_connAddr
		clr	bx
		call	IrlapSendUFrame
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Next state = RXWAIT_S
	;
		ChangeState	RXWAIT_S, ds
		.leave
		ret
PrimaryRequestXMIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvXchgCmdRXWAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received Xchg cmd frame while in RXWAIT_S
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
		cx = packet header
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvXchgCmdRXWAIT_S	proc	far
		.enter
	;
	; Send s:rr:cmd:Vr:P
	;
		mov	al, ds:IS_vr
		or	al, ISC_RR_CMD or mask ISCF_PFBIT
		mov	ah, ds:IS_connAddr
		or	ah, mask IAF_CRBIT	; make it a command
		mov	bx, ds:IS_serialPort
		clr	cx
		call	IrlapSendPacketFar
	;
	; Primary-Confirm
	;
		clr	cx
		call	PrimaryConfirm
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; Nest state = XWAIT_S
	;
		ChangeState XWAIT_S, ds
		.leave
		ret
RecvXchgCmdRXWAIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDxchgRXWAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received Dxchg frame while in RSWAIT_S state
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
		cx = packet header
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDxchgRXWAIT_S	proc	far
		.enter
	;
	; Primary-Confirm(deny)
	;
		mov	cx, mask PXF_DENIED
		call	PrimaryConfirm
	;
	; Next state = XMIT_S
	;
		ChangeState XMIT_S, ds
		.leave
		ret
RecvDxchgRXWAIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscCmdRXWAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received Disc:Cmd while in RXWAIT_S state
CALLED BY:	IrlapMessageProcessCallaback
PASS:		ds = station segment
		cx = packet header
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscCmdRXWAIT_S	proc	far
		.enter
	;
	; Send u:ua:rsp:F
	;
		mov	ch, ds:IS_connAddr
		mov	cl, IUR_UA_RSP or mask IUCF_PFBIT
		clr	bx
		call	IrlapSendUFrame
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
	; Next state = NDM
	;
		ChangeState NDM, ds
		.leave
		ret
RecvDiscCmdRXWAIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerRXWAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle packets that are not recognized by other external
		event handlers for this state.
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
		cx = packet header
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerRXWAIT_S	proc	far
		.enter
	;
	; If P bit is not set, nothing happend
	;
		test	cl, mask IUCF_PFBIT
		jz	done
	;
	; Verify that the packet is a command packet
	;
		test	ch, mask IAF_CRBIT
		jz	done			; not a command packet
	;
	; if retryCount >= N4, give up station exchange
	;
		mov	al, ds:IS_retryCount
		cmp	al, ds:IS_retryN4
		jae	giveup
	;
	; Send u:rxchg:rsp:F
	;
		mov	ch, ds:IS_connAddr
		mov	cl, IUR_RXCHG or mask IUCF_PFBIT
		clr	bx
		call	IrlapSendUFrame
	;
	; retryCount++
	;
		inc	ds:IS_retryCount
	;
	; No state change
	;
		jmp	done
giveup:
	;
	; Primary-Confirm(deny)
	;
		mov	cx, mask PXF_DENIED
		call	PrimaryConfirm
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Next state = XMIT_S
	;
		ChangeState XMIT_S, ds
done:
		.leave
		ret
DefaultHandlerRXWAIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvXchgCmdXWAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received Xchg command frame  while in XWAIT_S state
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
		cx = packet header
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvXchgCmdXWAIT_S	proc	far
		.enter
	;
	; Send s:rr:cmd:P:Vr
	;
		mov	al, ds:IS_vr
		or	al, ISC_RR_CMD or mask ISCF_PFBIT
		mov	ah, ds:IS_connAddr
		or	ah, mask IAF_CRBIT	; make it a command
		mov	bx, ds:IS_serialPort
		clr	cx
		call	IrlapSendPacketFar
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; No state change
	;
		.leave
		ret
RecvXchgCmdXWAIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscCmdXWAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received u:disc:cmd:P while in XWAIT_S
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station segment
		cx = packet header
RETURN:		nothing
DESTROYED:	everything
NOTE:		Identical to RecvDiscCmdRXWAIT_S
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscCmdXWAIT_S equ RecvDiscCmdRXWAIT_S


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvRdCmdXWAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received u:rd:cmd:P
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
		cx = packet header
RETURN:		nothing
DESTROYED:	everything
NOTE:		identical to RecvRdRspRECV_P
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvRdCmdXWAIT_S equ RecvRdRspRECV_P


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FTimerExpiredXWAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	F timer expired XWAIT_S
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FTimerExpiredXWAIT_S	proc	far
		.enter
	;
	; If retryCount when over disconnection threshold, disconnect
	;
		mov	al, ds:IS_retryCount
		cmp	al, ds:IS_retryN2
		jae	disconnect
	;
	; Perform-Random-Backoff
	;
		call	PerformRandomBackoff
	;
	; if retryCount = N1, warn the user
	; Status indication: warn the user that we will get disconnected
	;
		cmp	al, ds:IS_retryN1
		jne	skipWarning
		call	StatusIndication
skipWarning:
	;
	; Send u:xchg:cmd:P
	;
		mov	cl, ISC_RR_CMD or mask ISCF_PFBIT
		mov	ch, ds:IS_connAddr
		clr	bx
		call	IrlapSendUFrame
	;
	; Start-F-Timer
	;
		call	StartFTimer
	;
	; retryCount++
	;
		inc	ds:IS_retryCount
	;
	; No state change occurs
	;
		jmp	done
disconnect:
	;
	; Apply-Default-Connection-Parameters
	;
		call	ApplyDefaultConnectionParams
	;
	; Disconnect-Indication
	;
		mov	ax, IC_CONNECTION_TIMEOUT_S
		call	DisconnectIndication
done:
		.leave
		ret
FTimerExpiredXWAIT_S	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultHandlerXWAIT_S
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle external events that were not recognized by other
		handlers.
CALLED BY:	IrlapMessageProcessCallback
PASS:		ds = station
		cx = packet header
		dx:bp = packet
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultHandlerXWAIT_S	proc	far
		.enter
	;
	; If not response frame, do nothing
	;
		test	ch, mask IAF_CRBIT
		jnz	commandFrame
	;
	; Stop-F-Timer
	;
		call	StopFTimer
	;
	; Switch-To-Primary
	;
		call	SwitchToPrimary
	;
	; retryCount := 0
	;
		clr	ds:IS_retryCount
	;
	; Perform-Recv(P)-Action
	;
		call	PerformRecvAction
commandFrame:
done:
		.leave
		ret
DefaultHandlerXWAIT_S	endp

; ==========================================================================
;
; 		Action code for station exchange procdure
;
; ==========================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrimaryConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the higher layer of primary confirmation

CALLED BY:	PrimaryRequestXMIT_P
		RecvXchgCmdRXWAIT_S
		RecvDxchgCmdRXWAIT_S
		DefaultHandlerRXWAIT_S
PASS:		ds	= station
		cx	= PrimaryXchgFlag
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrimaryConfirm	proc	near
		uses	di
		.enter
		pushdw	ds:IS_clientCallback
		mov	di, NII_PRIMARY_CONFIRM
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		.leave
		ret
PrimaryConfirm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrimaryIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Indicate the remote station requested to become primary
CALLED BY:	RecvRxchgRspRECV_P
PASS:		ds = station segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrimaryIndication	proc	near
		uses	di
		.enter
		pushdw	ds:IS_clientCallback
		mov	di, NII_PRIMARY_INDICATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		.leave
		ret
PrimaryIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwitchToSecondary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change current station to a secondary role
CALLED BY:	RecvRrCmdXWAIT_P, DefaultHandlerXWAIT_P
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwitchToSecondary	proc	near
		uses	ax,bx
		.enter
	;
	; Stop all timers
	;
		call	StopAllTimers
	;
	; Clr CR bit in address
	;
		BitClr	ds:IS_connAddr, IAF_CRBIT
	;
	; Change state to secondary
	;
		ChangeState RECV_S, ds
	;
	; Start WD timer
	;
		call	StartWDTimer		; axbx = timer id + handle
		.leave
		ret
SwitchToSecondary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwitchToPrimary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change current station to a secondary role
CALLED BY:	DefaultHandlerXWAIT_S
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwitchToPrimary	proc	near
		uses	ax,bx
		.enter
	;
	; Stop all timers
	;
		call	StopAllTimers
	;
	; Reverse CR bit in address
	;
		BitSet	ds:IS_connAddr, IAF_CRBIT
	;
	; Change state to secondary
	;
		ChangeState XMIT_P, ds
	;
	; Start F Timer
	;
		call	StartPTimer		; axbx = timer id + handle
		.leave
		ret
SwitchToPrimary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PerformRandomBackoff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait a random number of time units, minimum duration half
		the time taken to trasmit a control frame, maximum duration
		1.5 times the time taken to trasmit a control frame
CALLED BY:	Utility
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PerformRandomBackoff	proc	far
		uses	ax,dx
		.enter
		mov	dl, MAX_RANDOM_BACKOFF
		call	IrlapGenerateRandom8
		mov	al, dl
		clr	ah
		add	al, MIN_RANDOM_BACKOFF
		call	TimerSleep		
		.leave
		ret
PerformRandomBackoff	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PerformRecvAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take appropriate action for a received packet

CALLED BY:	DefaultHandleXWAIT_P, DefaultHandlerXWAIT_S
PASS:		ds	= station
		ch,cl	= addr, ctrl header
		dx:bp	= packet optr
RETURN:		dx	= 0	( buffer will not be deallocated )
DESTROYED:	everything
STRATEGY:
		we make an event out of the packet received and
		send it to the event thread by inserting it to the front
		of the queue. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PerformRecvAction	proc	near
		.enter
		mov	ax, cx
		and	ah, mask IAF_CRBIT
		mov	bx, ds:IS_eventThreadHandle
		mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
		call	ObjMessage
		clr	dx, bp
		.leave
		ret
PerformRecvAction	endp

IrlapTransferCode	ends
