COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		lsapfsmActions.asm

AUTHOR:		Chung Liu, Mar 15, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial revision


DESCRIPTION:
	Actions for LSAP Connection Control FSM
		

	$Id: lsapfsmActions.asm,v 1.1 97/04/05 01:06:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LsapFsmCode	segment resource

;---------------------------------------------------------------------------
;			Watchdog Timer
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFStartWatchdogTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the watchdog timer

CALLED BY:	(INTERNAL) LFConnectConfirmSetupPend
PASS:		*ds:si	= LsapFsmClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFStartWatchdogTimer	proc	near
	class	LsapFsmClass
	uses	ax,bx,cx,dx,di
	.enter
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[LMBH_handle]		;^lbx:si = oself
	mov	cx, LSAP_WATCHDOG_TIMER_INTERVAL
	mov	dx, MSG_LF_WATCHDOG_TIMEOUT
	call	TimerStart			;ax = timer ID
						;bx = timer handle
	Assert	objectPtr, dssi, LsapFsmClass
	mov	di, ds:[si]
	mov	ds:[di].LFI_watchdogTimer, bx
	mov	ds:[di].LFI_watchdogTimerID, ax
	.leave
	ret
LFStartWatchdogTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFCancelWatchdogTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel the watchdog timer.

CALLED BY:	(INTERNAL) LFDisconnectIndication
			   LFConnectConfirmPDU
			   LFDisconnectPDU
PASS:		*ds:si	= LsapFsmClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFCancelWatchdogTimer	proc	near
	class	LsapFsmClass
	uses	di,ax,bx
	.enter
	mov	di, ds:[si]
	clr	bx
	xchg	bx, ds:[di].LFI_watchdogTimer
	;
	; Make sure there is a timer.
	;
EC <	tst	bx						>
EC <	ERROR_Z	IRLMP_NO_TIMER_TO_CANCEL			>
	clr	ax
	xchg	ax, ds:[di].LFI_watchdogTimerID
	call	TimerStop
	.leave
	ret
LFCancelWatchdogTimer	endp


;---------------------------------------------------------------------------
;   		    Actions for LM_Connect.request
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFConnectRequestDisconnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Action for LM_Connect.request in LFS_DISCONNECTED state.

CALLED BY:	LFConnectRequest
PASS:		*ds:si	= LsapFsmClass object
		cx:dx	= IrlmpConnectArgs
RETURN:		carry clear
		ax	= IE_SUCCESS
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Store connect data
	Issue LS_Connect.request to Station Control
	change state to LFS_SETUP_PEND

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFConnectRequestDisconnected	proc	near
	class	LsapFsmClass
	uses	ds,si,es,di,bx,cx,dx
	.enter
	;
	; Next state = LFS_SETUP_PEND
	;
	mov	di, ds:[si]
	mov	ds:[di].LFI_state, LFS_SETUP_PEND
	;
	; Store user data, so it can be transmitted later.
	;
	movdw	essi, cxdx		;es:si = IrlmpConnectArgs
	movdw	ds:[di].LFI_connectData, es:[si].ICA_data, ax
	mov	ax, es:[si].ICA_dataOffset
	mov	ds:[di].LFI_connectDataOffset, ax
	mov	ax, es:[si].ICA_dataSize
	mov	ds:[di].LFI_connectDataSize, ax

	;
	; Store the destination IrlmpLsapID in the endpoint.
	;
	push	si				;save args offset
	pushdw	es:[si].ICA_lsapID.ILI_irlapAddr
	mov	al, es:[si].ICA_lsapID.ILI_lsapSel

	mov	si, ds:[di].LFI_clientHandle
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	mov	ds:[di].IE_destLsapID.ILI_lsapSel, al
	popdw	ds:[di].IE_destLsapID.ILI_irlapAddr

	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared
	pop	di				;es:di = IrlmpConnectArgs
	;
	; Store away the QOS arguments to be used if it is necessary to
	; establish and IrLAP connection.
	;
	; If multiple LM_Connect.requests come in nearly simultaneously,
	; the requested QOS may not be the one from the first LM_Connect.
	; request.  But it really doesn't matter, since the final QOS is
	; never guaranteed.
	;
	add	di, offset ICA_QoS		;es:di = QualityOfService
	call	UtilsSetRequestedQOS	
	sub	di, offset ICA_QoS		;es:di = IrlmpConnectArgs
	;
	; Issue LS_Connect.request to Station Control
	; 
	push	bp
	movdw	cxdx, es:[di].ICA_lsapID.ILI_irlapAddr
	mov	bp, si				;bp = lptr endpoint
	mov	ax, MSG_SF_LS_CONNECT_REQUEST
	call	StationFsmSend
	pop	bp
	;
	; return code
	;
	mov	ax, IE_SUCCESS
	clc
	.leave
	ret
LFConnectRequestDisconnected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFConnectRequestConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Action for LM_Connect.request, in LFS_CONNECT_PEND and
		LFS_CONNECT states.

CALLED BY:	LFConnectRequest
PASS:		*ds:si	= LsapFsmClass object
		cx:dx	= IrlmpConnectArgs
RETURN:		carry set
		ax	= IE_INCOMING_CONNECTION
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Issue LM_Disconnect.indication to user (reason = incomingConnection)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFConnectRequestConnect	proc	near
	class	LsapFsmClass
	uses	di,si
	.enter
	mov	di, ds:[si]
	mov	si, ds:[di].LFI_clientHandle

	mov	al, IDR_UNSPECIFIED
	call	IrlmpDisconnectIndicationNoData

	mov	ax, IE_INCOMING_CONNECTION
	stc
	.leave
	ret
LFConnectRequestConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFConnectRequestError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Action for LM_Connect.request, in LFS_DATA_TRANSFER_READY,
		LFS_SETUP_PEND, and LFS_SETUP states.
CALLED BY:	LFConnectRequest
PASS:		nothing
RETURN:		carry set
		ax	= IE_ALREADY_CONNECTED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFConnectRequestError	proc	near
	.enter
	mov	ax, IE_ALREADY_CONNECTED
	stc
	.leave
	ret
LFConnectRequestError	endp

;-------------------------------------------------------------------------
;			Actions for LS_Connect.confirm
;-------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFConnectConfirmSetupPend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle LS_Connect.confirm in SETUP_PEND state.

CALLED BY:	LFConnectConfirm
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Irlap_Data.request(Connect LM-PDU[connectData], expedited = false)
	StartWatchdogTimer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFConnectConfirmSetupPend	proc	near
	class	LsapFsmClass
	uses	ax,bx,cx,dx,si
	.enter
	;
	; change to SETUP
	;
	mov	ds:[di].LFI_state, LFS_SETUP

	;
	; Obtain the source and destination LSAPs, for the PDU.
	;
	push	si
	mov	si, ds:[di].LFI_clientHandle
	call	UtilsEndpointGetLsaps		;bh = DLsap
						;bl = SLsap

	mov	cx, ds:[di].LFI_connectDataSize
	jcxz	noPassedData
	;
	; Use data provided by user
	;
	movdw	dxax, ds:[di].LFI_connectData
	mov	si, ds:[di].LFI_connectDataOffset
	jmp	gotData

noPassedData:
	;
	; No data was provided with connect request.  Alloc enough
	; for the Connect LM-PDU
	;
	call	UtilsAllocPDUData	;dx,ax,cx,si = data args

gotData:
	call	UtilsMakeConnectPDU	;si, cx are updated.
	call	IsapDataRequest
	;
	; start watchdog timer
	;
	pop	si			;*ds:si = LsapFsm
	call	LFStartWatchdogTimer

	.leave
	ret
LFConnectConfirmSetupPend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFConnectConfirmConnectPend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle LS_Connect.confirm in CONNECT_PEND state.

CALLED BY:	LFConnectConfirm
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		cxdx	= 32-bit IrLAP address
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	LM_Connect.indication(connectData)
	StartWatchdogTimer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFConnectConfirmConnectPend	proc	near
	class	LsapFsmClass
	uses	ax,bx,cx,dx,ds,di,si,bp
	.enter
	push	ds, si				;save for watchdog

	mov	ds:[di].LFI_state, LFS_CONNECT
	mov	si, ds:[di].LFI_clientHandle
	;
	; setup args to pass with connect indication.
	;
	sub	sp, size IrlmpConnectArgs
	mov	bp, sp			;ss:bp	= IrlmpConnectArgs

	mov	ax, ds:[di].LFI_connectDataSize
	mov	ss:[bp].ICA_dataSize, ax
	tst	ax
	jz	copyLsapID

	mov	ax, ds:[di].LFI_connectDataOffset
	mov	ss:[bp].ICA_dataOffset, ax
	movdw	ss:[bp].ICA_data, ds:[di].LFI_connectData, ax

copyLsapID:
	;
	; Copy lsap-id from endpoint
	;
	call	UtilsGetEndpointLocked	;ds:di = IrlmpEndpoint
	movdw	ss:[bp].ICA_lsapID.ILI_irlapAddr, \
			ds:[di].IE_destLsapID.ILI_irlapAddr, ax
	mov	al, ds:[di].IE_destLsapID.ILI_lsapSel
	mov	ss:[bp].ICA_lsapID.ILI_lsapSel, al
	
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared

	movdw	cxdx, ssbp	
	call	IrlmpConnectIndication
	add	sp, size IrlmpConnectArgs

	pop	ds, si				;*ds:si = lsap fsm
	;
	; watchdog
	; DON'T watchdog CONNECT-PEND and CONNECT states.  See errata.
	;
	; call	LFStartWatchdogTimer
	.leave
	ret
LFConnectConfirmConnectPend	endp

;-------------------------------------------------------------------------
;		Actions for IrLAP data indications
;-------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFSendDisconnectPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a Disconnect LM-PDU.

CALLED BY:	LFDataPDU
PASS:		bl	= IrlmpDisconnectReason
		si	= lptr IrlmpEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFSendDisconnectPDU	proc	near
	uses	ax,bx,cx,dx,si,bp
	.enter
	push	bx			
	call	UtilsEndpointGetLsaps		;bh = DLsap
						;bl = SLsap
	call	UtilsAllocPDUData		;dx,ax,cx,si = data args
	pop	bp
	call	UtilsMakeDisconnectPDU		;si, cx updated
EC <	WARNING IRLMP_SENT_DISCONNECT_PDU			>
	call	IsapDataRequest
	.leave
	ret
LFSendDisconnectPDU	endp

LsapFsmCode	ends
