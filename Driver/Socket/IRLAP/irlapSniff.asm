COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Serial/IR communication project
MODULE:		SNIFF state machine
FILE:		irlapSniff.asm

AUTHOR:		Steve Jang, Sep 29, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94   	Initial revision


DESCRIPTION:

	Sniff mode procedures		

	$Id: irlapSniff.asm,v 1.1 97/04/18 11:57:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapConnectionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SniffRequestNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user requested sniff

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station offset
		es	= dgroup
RETURN:		nothing
DESTROYED:	everything
PSEUDO CODE/STRATEGY:

	mediaBusy := false
	StartSenseTimer		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SniffRequestNDM	proc	far
		.enter
EC <		WARNING	SNIFF_REQUEST_NDM				>
	;
	; mediaBusy := false( will be done when checking for media busy )
	; Start-Sense-Timer
	;
		call	StartSenseTimer
	;
	; NEXT STATE = POUT
	;
		ChangeState	POUT, ds
		
		.leave
		ret
SniffRequestNDM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SenseTimerExpiredPOUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sense timer expired

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station offset
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:

	If (not mediaBusy)
		Send Sniff-Xid-Rsp
		Start-Sniff-Timer
		state := SNIFF
	else
		disableReceiver
		Start-Sleep-Timer
		state := SLEEP

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SenseTimerExpiredPOUT	proc	far
		.enter
EC <		WARNING	SENSE_TIMER_EXPIRED_POUT			>
	;
	; [Check media]
	;
		call	IrlapCheckMediaBusy	; carry set if busy
		jc	mediaIsBusy
	;
	; Media is not busy
	; : Send-Sniff-Xid-Rsp
	;
		call	SendSniffXidRspFrame
	;
	; Start-Sniff-Timer
	;
		call	StartSniffTimer
	;
	; state := SNIFF
	;
		ChangeState	SNIFF, ds
mediaIsBusy:
	;
	; Disable receiver
	;
		call	IrlapDisableReceiver
	;
	; Start-Sleep-Timer
	;
		call	StartSleepTimer
	;
	; state := SLEEP
	;
		ChangeState	SLEEP, ds
		
		.leave
		ret
SenseTimerExpiredPOUT	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscoveryXidCmdPOUT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a discovery Xid cmd

CALLED BY:	IrlapCheckStationEvent
PASS:		ds	= station
		es	= dgroup
		ax	= event code
		dxbp	= frame buffer
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

	Random(slot)
	frameSent := false
	StartQueryTimer
	State := REPLY

	* same as RecvDiscoveryXidCmdNDM

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscoveryXidCmdPOUT	proc	far
		.enter
EC <		WARNING RECV_DISCOVERY_XID_CMD_POUT			>
	;
	; Identical to RecvDiscoveryXidCmdNDM
	;
		call	RecvDiscoveryXidCmdNDM
	;
	; STATE changed to REPLY
	;
		.leave
		ret
RecvDiscoveryXidCmdPOUT	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscoveryXidCmdSNIFF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a discovery Xid cmd

CALLED BY:	IrlapCheckStationEvent
PASS:		ds	= station
		es	= dgroup
		ax	= event code
		dxbp	= frame buffer
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

	Random(slot)
	frameSent := false
	StartQueryTimer
	State := REPLY

	* same as RecvDiscoveryXidCmdNDM

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscoveryXidCmdSNIFF	proc	far
EC <		WARNING	RECV_DISCOVERY_XID_CMD_SNIFF			>
		call	RecvDiscoveryXidCmdNDM
		ret
RecvDiscoveryXidCmdSNIFF	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvSnrmCmdSNIFF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a connection request frame from remote station

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station
		es	= dgroup
		ax	= event code
		ch	= connAddr
		cl	= control field
		dxbp	= frame buffer
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		Initialize-Connection-State
		Negotiate-Connection-Parameters
		Send-UA-rsp-Frame
		Apply-Connection-Params
		Connect-Confirm
		Start-WD-Timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvSnrmCmdSNIFF	proc	far
		.enter
EC <		WARNING	RECV_SNRM_CMD_SNIFF				>
	;
	; Initialize-Connection-State
	;
		call	InitConnectionState
	;
	; Negotiate-Connection-Parameters
	;
		call	NegotiateConnectionParameters
	;
	; Send-UA-rsp-Frame
	;
		call	SendUaRspFrame
	;
	; Apply-Connection-Params
	;
		call	ApplyConnectionParameters
	;
	; Connect-Confirm
	;
		call	ConnectConfirm
	;
	; Start-WD-Timer
	;
		call	StartWDTimer
	;
	; state := NRM(S)
	;
		ChangeState	RECV_S, ds
		.leave
		ret
RecvSnrmCmdSNIFF	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SniffTimerExpiredSNIFF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sniff timer expired

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station segment
RETURN:		nothing
DESTROYED:	everything
PSEUDO CODE:
		disable-receiver
		start-sleep-timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SniffTimerExpiredSNIFF	proc	far
		.enter
EC <		WARNING	SNIFF_TIMER_EXPIRED_SNIFF			>
	;
	; Disable-receiver
	;
		call	IrlapDisableReceiver
	;
	; Start-Sleep-Timer
	;
		call	StartSleepTimer
	;
	; state := SLEEP
	;
		ChangeState	SLEEP, ds
		.leave
		ret
SniffTimerExpiredSNIFF	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SleepTimerExpiredSLEEP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Station woke up from the sleep

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station segment
RETURN:		nothing
DESTROYED:	everything
PSEUDO CODE/STRATEGY:
	mediaBusy := false
	enable-receiver
	start-sense-timer		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SleepTimerExpiredSLEEP	proc	far
		.enter
EC <		WARNING	SLEEP_TIMER_EXPIRED_SLEEP			>
	;
	; mediaBusy := false ( ignored )
	; enable-receiver
	;
		call	IrlapEnableReceiver
	;
	; start-sense-timer
	;
		call	StartSenseTimer
	;
	; state := POUT
	;
		ChangeState	POUT, ds
		.leave
		ret
SleepTimerExpiredSLEEP	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvSniffXidRspNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a sniff Xid rsp frame

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station segment
		es	= dgroup
		ax	= event code
		ch	= address field
		cl	= control field
		dxbp	= xid frame buffer
RETURN:		nothing
DESTROYED:	everything except for dxbp
PSEUDO CODE/STRATEGY:
		Discovery.Indication(sniff)		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvSniffXidRspNDM	proc	far
		.enter
EC <		WARNING	RECV_SNIFF_XID_RSP_NDM				>
	;
	; Discovery-Indication
	;
		IrlapLockPacket	esdi, dxbp
		add	di, es:[di].PH_dataOffset
		mov	ax, mask DLF_VALID or mask DLF_SNIFF
		call	DiscoveryIndication		
		IrlapUnlockPacket dx, bx
	;
	; NEXT STATE = NDM ( no change )
	;
		.leave
		ret
RecvSniffXidRspNDM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SniffConnectRequestNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User requested "connect to sniffer" procedure

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station segment
		es	= dgroup
RETURN:		nothing
DESTROYED:	everything
PSEUDO CODE/STRATEGY:
		state := SCONN		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SniffConnectRequestNDM	proc	far
EC <		WARNING	SNIFF_CONNECT_REQUEST_NDM			>
		ChangeState	SCONN, ds
		ret
SniffConnectRequestNDM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvSniffXidRspSCONN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detected a sniffer

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station segment
		es	= dgroup
		ax	= event code
		ch	= address field
		cl	= control field
		dxbp	= xid frame buffer
RETURN:		nothing
DESTROYED:	everything
PSEUDO CODE/STRATEGY:

		Generate-random-connection-address
		Send-snrm-cmd-frame
		Start-P-Timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvSniffXidRspSCONN	proc	far
		.enter
EC <		WARNING	RECV_SNIFF_XID_RSP_SCONN			>
	;		
	; Generate-random-connection-address
	;
		call	IrlapGenConnAddr	; dl = connection adderss
		BitSet	dl, IAF_CRBIT		; we will be primary
		mov	ds:IS_connAddr, dl
	;
	; Send-snrm-cmd-frame
	;
		call	SendSnrmPacket
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; NEXT STATE = SSETUP
	;
		ChangeState	SSETUP, ds
		
		.leave
		ret
RecvSniffXidRspSCONN	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PTimerExpiredSSETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PTimer expired

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station segment
		es	= dgroup
RETURN:		nothing
DESTROYED:	everything
PSEUDO CODE/STRATEGY:

	Disconnection-Indication

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PTimerExpiredSSETUP	proc	far
		.enter
EC <		WARNING	PTIMER_EXPIRED_SSETUP				>
	;
	; Disconnection-Indication
	;
		mov	ax, IC_SNIFF_CONNECTION_FAILURE
		call	DisconnectIndication
	;
	; State = NDM
	;
		ChangeState	NDM, ds
		.leave
		ret
PTimerExpiredSSETUP	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvUaRspSSETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received a response from the remote station, accepting
		our connection request

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station segment
		es	= dgroup
		ch	= address field
		cl	= control field
		dxbp	= ui frame buffer
RETURN:		nothing
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:

	Stop-P-Timer
	Initialize-Connection-State
	Negotiate-Connection-Parameters
	Apply-Connection-Parameters
	Connect-Confirm
	Send-Rr-Frame
	Start-P-Timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvUaRspSSETUP	proc	far
		.enter
EC <		WARNING	RECV_UA_RSP_SSETUP				>
	;
	; Stop-P-Timer
	;
		movdw	axbx, ds:IS_pTimer
		call	TimerStop
	;
	; Initialize-Connection-State
	;
		call	InitConnectionState
	;
	; Negotiate-Connection-Parameters
	;
		call	NegotiateConnectionParameters
	;
	; Apply-Connection-Parameters
	;
		call	ApplyConnectionParameters
	;
	; Connect-Confirm
	;
		call	ConnectConfirm
	;
	; Send-Rr-Frame
	;
		mov	cl, ISC_RR_CMD or mask ISCF_PFBIT
		call	IrlapSendSFrame
	;
	; Start-P-Timer
	;
		call	StartPTimer
	;
	; State := XMIT_P
	;
		ChangeState	RECV_P, ds
		.leave
		ret
RecvUaRspSSETUP	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDmRspSSETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received disconnection notice from remote station

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= station
		es	= dgroup
		ch	= address field
		cl	= control field
		dxbp	= dm frame buffer
RETURN:		nothing
DESTROYED:	everything except dxbp
PSEUDO CODE/STRATEGY:
	Disconnection-Indication

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDmRspSSETUP	proc	far
		.enter
EC <		WARNING RECV_DM_RSP_SSETUP				>
	;
	; Disconnect-Indication
	;
		mov	ax, IC_SNIFF_CONNECTION_FAILURE
		call	DisconnectIndication
	;
	; state := NDM
	;
		ChangeState	NDM, ds
		.leave
		ret
RecvDmRspSSETUP	endp


; ===========================================================================
;
; 		Utility functions for SNIFF procedures
;
; ===========================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendSniffXidRspFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a sniff Xid frame

CALLED BY:	SenseTimerExpiredPOUT
PASS:		ds	= station
		ds:IS_sniffXidFrame = sniff xid frame to send
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendSniffXidRspFrame	proc	near
		uses	ax,bx,cx,es,di
		.enter
	;
	; Send XID frame
	;
		segmov	es, ds, ax
		mov	di, offset IS_discoveryXIDFrame
		mov	bx, size IrlapDiscoveryXidFrame
		mov	cx, IRLAP_BROADCAST_CONNECTION_ADDR shl 8 or \
			    IUR_XID_RSP or mask IUCF_PFBIT
		call	IrlapSendUFrame		
		.leave
		ret
SendSniffXidRspFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartSniffTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start sniff timer

CALLED BY:	Sniff routines
PASS:		ds	= station segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartSniffTimer	proc	near
EC <		WARNING	_START_SNIFF_TIMER				>
		GOTO	StartSenseTimerCode
StartSniffTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartSenseTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a sense timer

CALLED BY:	Sniff routines
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartSenseTimer	proc	near
EC <		WARNING	_START_SENSE_TIMER				>
StartSenseTimerCode	label	near
		push	cx, dx
		movdw	axbx, ds:IS_senseTimer
		call	TimerStop
		mov	bx, ds:IS_eventThreadHandle
		mov	cx, IRLAP_SENSE_SNIFF_TIMEOUT_TICKS
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	dx, ILE_TIME_EXPIRE shl 8 or mask ITEV_P
		call	TimerStart
		movdw	ds:IS_pTimer, axbx
		pop	cx, dx
		ret
StartSenseTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartSleepTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start sleep timer

CALLED BY:	Sniffing routines
PASS:		ds	= station segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartSleepTimer	proc	near
		uses	cx, dx
		.enter
EC <		WARNING	_START_SLEEP_TIMER				>
		movdw	axbx, ds:IS_senseTimer
		call	TimerStop
		mov	bx, ds:IS_eventThreadHandle
		mov	cx, ds:IS_sleepTime
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	dx, ILE_TIME_EXPIRE shl 8 or mask ITEV_P
		call	TimerStart
		movdw	ds:IS_pTimer, axbx
		.leave
		ret
StartSleepTimer	endp


IrlapConnectionCode	ends


