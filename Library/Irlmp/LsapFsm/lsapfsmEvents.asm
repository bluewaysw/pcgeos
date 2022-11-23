COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS 
MODULE:		IrLMP Library
FILE:		lsapfsmEvents.asm

AUTHOR:		Chung Liu, Feb 28, 1995

ROUTINES:
	Name			Description
	----			-----------
	LFWatchdogTimeout	watchdog timeout
	LFConnectRequest	LM_Connect.request
	LFDisconnectIndication	LS_Disconnect.indication
	LFConnectConfirm	LS_Connect.confirm
	LFIrlapDataIndication	Irlap_Data.indication
	LFDataPDU		Data LM-PDU
	LFConnectPDU		Connect LM-PDU
	LFConnectConfirmPDU	Connect confirm LM-PDU
	LFDisconnectPDU		Disconnect LM-PDU
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/28/95   	Initial revision


DESCRIPTION:
	Event handling for LSAP Connection Control FSM.

	$Id: lsapfsmEvents.asm,v 1.1 97/04/05 01:06:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LsapFsmCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFWatchdogTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Watchdog timer has expired.

CALLED BY:	MSG_LF_WATCHDOG_TIMEOUT
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	DATA_TRANSFER_READY:
	DISCONNECTED:
		ignore
	CONNECT_PEND:
	SETUP_PEND:
		LS_Disconnect.request
	CONNECT:
		IrLAP_Data.request(
			Disconnect LM_PDU(reason = nonresponsiveUser,
					  expedited = false))
		LS_Disconnect.request
	SETUP:
		LS_Disconnect.request
		LM_Disconnect.indication(nonResponsivePeer)

	After errata corrections, the only watchdog timer left is
	the one that could go off in the SETUP state.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFWatchdogTimeout	method dynamic LsapFsmClass, 
					MSG_LF_WATCHDOG_TIMEOUT
	uses	bp,ax,cx,si
	.enter
	;
	; if LFI_watchdogTimer has already been cleared, then the 
	; watchdog timer was cancelled after the timeout event was 
	; already added to the queue.
	;
	tst	ds:[di].LFI_watchdogTimer
	jz	exit

	cmp	ds:[di].LFI_state, LFS_SETUP
EC <	ERROR_NE IRLMP_WATCHDOG_TIMEOUT_IN_UNEXPECTED_STATE	>
	jne	exit

	mov	ds:[di].LFI_state, LFS_DISCONNECTED
	clr	ds:[di].LFI_watchdogTimer
	clr	ds:[di].LFI_watchdogTimerID
	;
	; LS_Disconnect.request
	;
	mov	bp, ds:[di].LFI_clientHandle
	mov	cx, -1					;disconnect IrLAP
	mov	ax, MSG_SF_LS_DISCONNECT_REQUEST
	call	StationFsmSendFixupDS
	;
	; LM_Disconnect.indication(nonResponsivePeer)
	;
	mov	si, bp				;si = client handle
	mov	al, IDR_NON_RESPONSIVE_LM_MUX_CLIENT
	call	IrlmpDisconnectIndicationNoData
	
exit:
	.leave
	ret
LFWatchdogTimeout	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received LM_Connect.request primitive from client.

CALLED BY:	MSG_LF_LM_CONNECT_REQUEST
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		cx:dx	= IrlmpConnectArgs
RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax	= IrlmpError
					IE_ALREADY_CONNECTED
					IE_INCOMING_CONNECTION
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFConnectRequestActions	nptr.near \
	LFConnectRequestDisconnected,		;LFS_DISCONNECTED
	LFConnectRequestConnect,		;LFS_CONNECT_PEND
	LFConnectRequestConnect,		;LFS_CONNECT
	LFConnectRequestError,			;LFS_DATA_TRANSFER_READY
	LFConnectRequestError,			;LFS_SETUP_PEND
	LFConnectRequestError			;LFS_SETUP
.assert (size LFConnectRequestActions / 2 eq LsapFsmState)

LFConnectRequest	method dynamic LsapFsmClass, 
					MSG_LF_LM_CONNECT_REQUEST
	uses	di
	.enter
	mov	di, ds:[di].LFI_state
	shl	di
	call	cs:[LFConnectRequestActions][di]
	.leave
	ret
LFConnectRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFDisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_Disconnect.indication. 

CALLED BY:	MSG_LF_LS_DISCONNECT_INDICATION
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		dl	= IrlmpDisconnectReason
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFDisconnectIndication	method dynamic LsapFsmClass, 
					MSG_LF_LS_DISCONNECT_INDICATION
	uses	ax,bx,cx,ds,si,di
	.enter
	mov	ax, ds:[di].LFI_state
	;
	; Already disconnected... what's the point.
	;
	cmp	ax, LFS_DISCONNECTED
	je	exit
	;
	; Cancel watchdog only in SETUP state.
	;
	cmp	ax, LFS_SETUP
	jne	nextState
	call	LFCancelWatchdogTimer

nextState:
	;
	; next state: DISCONNECTED
	;
	mov	ds:[di].LFI_state, LFS_DISCONNECTED
	;
	; Clean-up endpoint
	;
	mov	si, ds:[di].LFI_clientHandle
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint
	movdw	ds:[di].IE_destLsapID.ILI_irlapAddr, 0
	mov	ds:[di].IE_destLsapID.ILI_lsapSel, IRLMP_PENDING_CONNECT
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl
	;
	; issue LM_Disconnect.indication
	;
	mov	ax, dx				;al = IrlmpDisconnectReason
	call	IrlmpDisconnectIndicationNoData
exit:
	.leave
	ret
LFDisconnectIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFConnectConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_Connect.confirm from Irlap FSM

CALLED BY:	MSG_LF_LS_CONNECT_CONFIRM
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		cxdx	= 32-bit IrLAP address
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFConnectConfirm	method dynamic LsapFsmClass, 
					MSG_LF_LS_CONNECT_CONFIRM
	.enter
	mov	ax, ds:[di].LFI_state
	cmp	ax, LFS_DISCONNECTED
	je	disconnected
	cmp	ax, LFS_CONNECT_PEND
	je	connectPend
	cmp	ax, LFS_SETUP_PEND
	je	setupPend
	;
	; error.  Ignore it.
	;
	jmp	exit

setupPend:
	call	LFConnectConfirmSetupPend
	jmp	exit

connectPend:
	call	LFConnectConfirmConnectPend
	jmp	exit

disconnected:
	;
	; LS_Disconnect.request
	;
	mov	bp, ds:[di].LFI_clientHandle
	mov	cx, -1					;disconnect IrLAP
	mov	ax, MSG_SF_LS_DISCONNECT_REQUEST
	call	StationFsmSendFixupDS
exit:
	.leave
	ret
LFConnectConfirm	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFIrlapDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Data.indication

CALLED BY:	MSG_LF_IRLAP_DATA_INDICATION
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		ss:bp	= IrlmpDataArgs
		ch	= dest. IrlmpLsapSel
		cl	= source IrlmpLsapSel
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFIrlapDataIndication	method dynamic LsapFsmClass, 
					MSG_LF_IRLAP_DATA_INDICATION
	uses	ax, cx, dx
	.enter
	mov	ax, ds:[di].LFI_state
	;
	; Bail out if state is such that data indication is error condition.
	;
	cmp	ax, LFS_CONNECT_PEND
	je	error
	cmp	ax, LFS_CONNECT
	je	error
	cmp	ax, LFS_SETUP_PEND
	je	error
	;
	; Sub-event depends on the kind of PDU
	;
	call	UtilsGetOpCodeFromPDU		;dl = IrlmpOpCode
	cmp	dl, IOC_DATA
	jne	checkConnect
	call	LFDataPDU
	jmp	exit

checkConnect:
	cmp	dl, IOC_CONNECT
	jne	checkConnectConfirm
	call	LFConnectPDU
	jmp	exit

checkConnectConfirm:
	cmp	dl, IOC_CONNECT_CONFIRM
	jne	checkDisconnect
	call	LFConnectConfirmPDU
	jmp	exit

checkDisconnect:
	cmp	dl, IOC_DISCONNECT
	jne	oops
	call	LFDisconnectPDU
	jmp	exit
oops:
EC <	ERROR_NE IRLMP_INVALID_PDU_OP_CODE				>
	movdw	axcx, ss:[bp].IDA_data
	call	HugeLMemFree
exit:
	.leave
	ret
error:
	; ignore these kinds of errors for now
	jmp	exit
LFIrlapDataIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFIrlapExpeditedDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Data.indication, expedited = true

CALLED BY:	MSG_LF_IRLAP_EXPEDITED_DATA_INDICATION
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		ss:bp	= IrlmpDataArgs
		ch	= dest. IrlmpLsapSel
		cl	= source IrlmpLsapSel
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFIrlapExpeditedDataIndication	method dynamic LsapFsmClass, 
					MSG_LF_IRLAP_EXPEDITED_DATA_INDICATION
	uses	ax, cx, dx, bp
	.enter
	cmp	ds:[di].LFI_state, LFS_DATA_TRANSFER_READY
	je	dtr
	jmp	exit

dtr:
	sub	ss:[bp].IDA_dataSize, size IrlmpFrameHeader
	add	ss:[bp].IDA_dataOffset, size IrlmpFrameHeader
	mov	si, ds:[di].LFI_clientHandle
	movdw	cxdx, ssbp
	call	IrlmpUDataIndication
exit:
	.leave
	ret
LFIrlapExpeditedDataIndication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFDataPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Data.indication (Data LM-PDU)

CALLED BY:	LFIrlapDataIndication
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		ss:bp	= IrlmpDataArgs
		ch	= dest. IrlmpLsapSel
		cl	= source IrlmpLsapSel
		ax	= LsapFsmState
				LFS_DISCONNECTED
				LFS_DATA_TRANSFER_READY
				LFS_SETUP
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFDataPDU	proc	near
	class	LsapFsmClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	cmp	ax, LFS_DISCONNECTED
	je	disconnected
	cmp	ax, LFS_DATA_TRANSFER_READY
	je	dtr
EC <	cmp	ax, LFS_SETUP					>
EC <	ERROR_NE IRLMP_ILLEGAL_STATE				>
	;
	; Data PDU is error condition in LFS_SETUP state.
	;
	jmp	exit
	
disconnected:
	; data delivered on a disconnected LSAP connection is rejected 
	; with a Disconnect LM-PDU
	mov	bl, IDR_DATA_ON_DISCONNECTED_LSAP
	mov	si, ds:[di].LFI_clientHandle
	call	LFSendDisconnectPDU
	jmp	exit

dtr:
	;
	; Take out the data header
	;
	sub	ss:[bp].IDA_dataSize, size IrlmpFrameHeader
	add	ss:[bp].IDA_dataOffset, size IrlmpFrameHeader
	mov	si, ds:[di].LFI_clientHandle
	movdw	cxdx, ssbp			;cx:dx = IrlmpDataArgs
	call	IrlmpDataIndication

exit:
	.leave
	ret
LFDataPDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFConnectPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Data.indication (Connect LM-PDU)

CALLED BY:	LFIrlapDataIndication
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		ss:bp	= IrlmpDataArgs
		ch	= dest. IrlmpLsapSel
		cl	= source IrlmpLsapSel
		ax	= LsapFsmState
				LFS_DISCONNECTED
				LFS_DATA_TRANSFER_READY
				LFS_SETUP
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFConnectPDU	proc	near
	class	LsapFsmClass
	uses	ax,bx,cx,dx,ds,di,si
	.enter
	cmp	ax, LFS_DISCONNECTED
	je	disconnected
	cmp	ax, LFS_DATA_TRANSFER_READY
	je	dtr
EC <	cmp	ax, LFS_SETUP					>
EC <	ERROR_NE IRLMP_ILLEGAL_STATE				>
	;
	; LFS_SETUP
	;
dtr:
	;
	; Free the PDU data.
	;
	movdw	axcx, ss:[bp].IDA_data
	call	HugeLMemFree
	jmp	exit

disconnected:
	; goto CONNECT_PEND
	mov	ds:[di].LFI_state, LFS_CONNECT_PEND

	;
	; save connect data in LsapFsm's instance data, so it can be
	; passed on to the user at a later time.  Take out the PDU header.
	; 
	mov	ax, ss:[bp].IDA_dataSize
	sub	ax, offset IPDU_data
	mov	ds:[di].LFI_connectDataSize, ax
	tst	ax
	jz	noData				;no data with connect

	movdw	ds:[di].LFI_connectData, ss:[bp].IDA_data, ax
	mov	ax, ss:[bp].IDA_dataOffset
	add	ax, offset IPDU_data
	mov	ds:[di].LFI_connectDataOffset, ax
	jmp	dataCopied

noData:
	;
	; If there is no data for the user, free the data block.
	;
	push	cx				;preserve lsaps
	movdw	axcx, ss:[bp].IDA_data
	call	HugeLMemFree
	pop	cx

dataCopied:
	;
	; Since we're dealing with only one Irlap 
	; connection at a time, we know that the
	; connect PDU came in a data indication from the single Irlap
	; connection we've got.  If there were multiple Irlap connections,
	; then we'd have to figure out the 32-bit Irlap address from the
	; connection handle returned.
	;
	mov	si, ds:[di].LFI_clientHandle
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint
	;
	; Save the other side's LSAP-ID in our endpoint data.
	;
	mov	ds:[di].IE_destLsapID.ILI_lsapSel, cl

	mov	ax, MSG_IAF_CHECK_IF_CONNECTED
	call	IrlapFsmCallFixupDS		;cxdx = irlap address	
EC <	ERROR_NC IRLMP_IRLAP_SHOULD_BE_CONNECTED		>
	movdw	ds:[di].IE_destLsapID.ILI_irlapAddr, cxdx

	mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl	
	;
	; LS_Connect.request to Station Control. 
	;
	push	bp
	mov	bp, si				;bp = lptr endpoint
	mov	ax, MSG_SF_LS_CONNECT_REQUEST
	call	StationFsmSendFixupDS
	pop	bp

exit:
	.leave
	ret
LFConnectPDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFConnectConfirmPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Data.indication (Connnect confirm LM-PDU)

CALLED BY:	LFIrlapDataIndication
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		ss:bp	= IrlmpDataArgs
		ch	= dest. IrlmpLsapSel
		cl	= source IrlmpLsapSel
		ax	= LsapFsmState
				LFS_DISCONNECTED
				LFS_DATA_TRANSFER_READY
				LFS_SETUP
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFConnectConfirmPDU	proc	near
	class	LsapFsmClass
	uses	ax,bx,cx,dx,ds,si,di
	.enter
	cmp	ax, LFS_DISCONNECTED
	je	disconnected
	cmp	ax, LFS_DATA_TRANSFER_READY
	je	dtr
EC <	cmp	ax, LFS_SETUP					>
EC <	ERROR_NE IRLMP_ILLEGAL_STATE				>
	;
	; LFS_SETUP
	;
	call	LFCancelWatchdogTimer
	mov	ds:[di].LFI_state, LFS_DATA_TRANSFER_READY

	mov	si, ds:[di].LFI_clientHandle
	;
	; Grab space for confirm args
	;
	sub	sp, size IrlmpConnectArgs
	segmov	ds, ss
	mov	di, sp				;ds:di = IrlmpConnectArgs

	;
	; Take out the header from the data we pass to connect confirm.
	;
	mov	ax, ss:[bp].IDA_dataSize
	sub	ax, offset IPDU_data
	mov	ds:[di].ICA_dataSize, ax
	tst	ax
	jz	noData

	movdw	ds:[di].ICA_data, ss:[bp].IDA_data, ax
	mov	ax, ss:[bp].IDA_dataOffset
	add	ax, offset IPDU_data
	mov	ds:[di].ICA_dataOffset, ax
	jmp	gotData
noData:	
	;
	; should free the PDU data because no one else will.
	;	
	movdw	axcx, ss:[bp].IDA_data
	call	HugeLMemFree

gotData:
	;
	; Obtain the lsap-ID to which we are now connected.
	;
	call	UtilsEndpointGetDestLsapID	;cxdx = irlap addr
						;al = lsap-sel

	movdw	ds:[di].ICA_lsapID.ILI_irlapAddr, cxdx
	mov	ds:[di].ICA_lsapID.ILI_lsapSel, al

	movdw	cxdx, dsdi
	call	IrlmpConnectConfirm

	add	sp, size IrlmpConnectArgs
	jmp	exit

disconnected:
	; Connection confirmation delivered on a disconnected LSAP 
	; connection is rejected with a Disconnect LM-PDU.
	mov	bx, IDR_DATA_ON_DISCONNECTED_LSAP
	mov	si, ds:[di].LFI_clientHandle
	call	LFSendDisconnectPDU
	jmp	exit

dtr:
	;error
exit:
	.leave
	ret
LFConnectConfirmPDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFDisconnectPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Data.indication (Disconnect LM-PDU)

CALLED BY:	LFIrlapDataIndication
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		ss:bp	= IrlmpDataArgs
		ch	= dest. IrlmpLsapSel
		cl	= source IrlmpLsapSel
		ax	= LsapFsmState
				LFS_DISCONNECTED
				LFS_DATA_TRANSFER_READY
				LFS_SETUP
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFDisconnectPDU	proc	near
	class	LsapFsmClass
	uses	ax,bx,cx,dx,ds,si,di,bp
	.enter
EC <	WARNING	IRLMP_RECV_DISCONNECT_PDU			>
	cmp	ax, LFS_DATA_TRANSFER_READY
	je	dtr
	cmp	ax, LFS_SETUP
	je	setup
	jmp	exit

setup:
	; Cancel watchdog timer
	call	LFCancelWatchdogTimer

dtr:	
	;
	; next state: DISCONNECTED
	;
	mov	ds:[di].LFI_state, LFS_DISCONNECTED
	;
	; LS_Disconnect.request
	;
	mov	si, ds:[di].LFI_clientHandle
	push	bp, cx
	mov	bp, si
	clr	cx				;don't attempt to disconnect
						; IrLAP on disconnect PDU.
	mov	ax, MSG_SF_LS_DISCONNECT_REQUEST
	call	StationFsmCallFixupDS
	pop	bp, cx

	; Clean-up endpoint
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint
	movdw	ds:[di].IE_destLsapID.ILI_irlapAddr, 0
	mov	ds:[di].IE_destLsapID.ILI_lsapSel, IRLMP_PENDING_CONNECT
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl
	
	;
	; LM_Disconnect.indication
	;
	call	UtilsGetParameterFromPDU	;bl = IrlmpDisconnectReason

	mov	cx, ss:[bp].IDA_dataSize
	sub	cx, offset IPDU_data
	mov	ss:[bp].IDA_dataSize, cx
	jcxz	noData
	add	ss:[bp].IDA_dataOffset, offset IPDU_data
	jmp	gotData
noData:
	;
	; Since no data is being passed to user, free the PDU data.
	;
	movdw	axcx, ss:[bp].IDA_data
	call	HugeLMemFree

gotData:
	movdw	cxdx, ssbp			;cx:dx = IrlmpDataArgs
	mov	al, bl				;al = IrlmpDisconnectReason
	call	IrlmpDisconnectIndication

exit:
	.leave
	ret
LFDisconnectPDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFConnectResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Connect.response

CALLED BY:	MSG_LF_LM_CONNECT_RESPONSE
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		cx:dx	= IrlmpDataArgs
RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax	= IrlmpError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFConnectResponse	method dynamic LsapFsmClass, 
					MSG_LF_LM_CONNECT_RESPONSE
	uses	bx,cx,dx,di
	.enter
	mov	ax, ds:[di].LFI_state
	cmp	ax, LFS_CONNECT
	je	connect
	jmp	error

connect:
	;
	; next state is DTR
	;
	mov	ds:[di].LFI_state, LFS_DATA_TRANSFER_READY
	pushdw	dssi				;save to cancel watchdog

	;
	; send Connect Confirm LM-PDU[userData]
	;
	mov	si, ds:[di].LFI_clientHandle
	call	UtilsEndpointGetLsaps		;bh = DLsap
						;bl = SLsap
	movdw	dsdi, cxdx			;ds:di = data args
	mov	cx, ds:[di].IDA_dataSize
	jcxz	noData

	movdw	dxax, ds:[di].IDA_data
	mov	si, ds:[di].IDA_dataOffset
	jmp	gotData
noData:
	;
	; User did not provide data to be transmitted along with 
	; connect response.  Alloc enough for the PDU only.
	;
	call	UtilsAllocPDUData		;dx,ax,cx,si = data args

gotData:
	call	UtilsMakeConnectConfirmPDU	;si,cx updated
if GENOA_TEST
	push	bx
	clr	bx
endif	
	call	IsapDataRequest
if GENOA_TEST
	pop	bx
endif
	popdw	dssi				;*ds:si = IrlmpLsapFsm

	mov	ax, IE_SUCCESS
	clc
exit:
	.leave
	ret
error:
	mov	ax, IE_RESPONSE_WITHOUT_INDICATION
	stc
	jmp	exit
LFConnectResponse	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Data.request

CALLED BY:	MSG_LF_LM_DATA_REQUEST
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		cx:dx	= IrlmpDataArgs
RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax	= IrlmpError
					IE_LSAP_DISCONNECTED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Must be in DTR state to transmit data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFDataRequest	method dynamic LsapFsmClass, 
					MSG_LF_LM_DATA_REQUEST
	uses	bx,cx,dx,es,si,di
	.enter
	cmp	ds:[di].LFI_state, LFS_DATA_TRANSFER_READY
	je	dtr
	jmp	error

dtr:
	mov	si, ds:[di].LFI_clientHandle
	call	UtilsEndpointGetLsaps		;bh = DLsap
						;bl = SLsap
	;
	; Transform the user data into a Data LM-PDU, and transmit it.
	;
	movdw	esdi, cxdx			;es:di = IrlmpDataArgs
	movdw	dxax, es:[di].IDA_data
	mov	cx, es:[di].IDA_dataSize
	mov	si, es:[di].IDA_dataOffset		
	call	UtilsMakeDataPDU		;cx, si updated.
if GENOA_TEST
	push	bx
	mov	bx, es:[di].IDA_flags
endif
	call	IsapDataRequest
if GENOA_TEST
	pop	bx
endif
	;
	; return success
	;
	mov	ax, IE_SUCCESS
	clc
exit:
	.leave
	ret
error:
	; 
	; Not in DTR state -- return error.
	;
	mov	ax, IE_LSAP_DISCONNECTED
	stc
	jmp	exit
	
LFDataRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFUDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_UData.request

CALLED BY:	MSG_LF_LM_UDATA_REQUEST
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		cx:dx	= IrlmpDataArgs
RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax	= IrlmpError
					IE_LSAP_DISCONNECTED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFUDataRequest	method dynamic LsapFsmClass, 
					MSG_LF_LM_UDATA_REQUEST
	uses	bx,cx,dx,es,di,si
	.enter
	cmp	ds:[di].LFI_state, LFS_DATA_TRANSFER_READY
	je	dtr
	jmp	error
dtr:
	mov	si, ds:[di].LFI_clientHandle
	call	UtilsEndpointGetLsaps		;bh = DLsap
						;bl = SLsap
	;
	; Transform the user data into a Data LM-PDU, and transmit it.
	;
	movdw	esdi, cxdx			;es:di = IrlmpDataArgs
	movdw	dxax, es:[di].IDA_data
	mov	cx, es:[di].IDA_dataSize
	mov	si, es:[di].IDA_dataOffset

	call	UtilsMakeDataPDU		;cx, si updated.
	call	IsapExpeditedDataRequest

	; return success
	mov	ax, IE_SUCCESS
	clc
exit:
	.leave
	ret
error:
	; not in DTR state -- cannot send data.
	mov	ax, IE_LSAP_DISCONNECTED
	stc
	jmp	exit
LFUDataRequest	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Disconnect.request

CALLED BY:	MSG_LF_LM_DISCONNECT_REQUEST
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		cx:dx	= IrlmpDataArgs
RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax	= IrlmpError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Relevant actions in CONNECT and DTR states.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFDisconnectRequest	method dynamic LsapFsmClass, 
					MSG_LF_LM_DISCONNECT_REQUEST
	uses	bx,cx,dx,ds,di,si,bp
	.enter
	mov	ax, ds:[di].LFI_state
	cmp	ax, LFS_DATA_TRANSFER_READY
	je	disconnect
	cmp	ax, LFS_CONNECT
	je	disconnect
	jmp	error

disconnect:
	;
	; next state: disconnected
	;
	mov	ds:[di].LFI_state, LFS_DISCONNECTED

	;
	; Send Disconnect LM-PDU
	;
	mov	si, ds:[di].LFI_clientHandle
	push	si
	call	UtilsEndpointGetLsaps		;bh = DLsap
						;bl = SLsap
	movdw	dsdi, cxdx			;ds:di = data args
	mov	cx, ds:[di].IDA_dataSize
	jcxz	noData

	movdw	dxax, ds:[di].IDA_data
	mov	si, ds:[di].IDA_dataOffset
	jmp	gotData
noData:
	;
	; User did not provide data to be transmitted along with 
	; connect response.  Alloc enough for the PDU only.
	;
	call	UtilsAllocPDUData		;dx,ax,cx,si = data args

gotData:
	mov	bp, IDR_USER_REQUEST
	call	UtilsMakeDisconnectPDU		;si,cx updated
EC <	WARNING IRLMP_SENT_DISCONNECT_PDU			>
if	GENOA_TEST
	push	bx
	clr	bx
endif
	call	IsapDataRequest
if GENOA_TEST
	pop	bx
endif	
	;
	; LS_Disconnect.request to Station Control
	;
	pop	bp				;bp = lptr of IrlmpEndpoint
	mov	cx, -1				;disconnect IRLAP
	mov	ax, MSG_SF_LS_DISCONNECT_REQUEST
	call	StationFsmSendFixupDS

	;
	; Cleanup endpoint
	;
	mov	si, bp
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint
	movdw	ds:[di].IE_destLsapID.ILI_irlapAddr, 0
	mov	ds:[di].IE_destLsapID.ILI_lsapSel, IRLMP_PENDING_CONNECT
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared

	mov	ax, IE_SUCCESS
	clc	
exit:
	.leave
	ret
error:
	mov	ax, IE_LSAP_DISCONNECTED
	stc
	jmp	exit
LFDisconnectRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFStatusRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Status.request

CALLED BY:	MSG_LF_LM_STATUS_REQUEST
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data

RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax	= IrlmpError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFStatusRequest	method dynamic LsapFsmClass, 
					MSG_LF_LM_STATUS_REQUEST
	uses	bp
	.enter
	mov	ax, ds:[di].LFI_state
	cmp	ax, LFS_CONNECT
	je	okay
	cmp	ax, LFS_SETUP
	je	okay
	cmp	ax, LFS_DATA_TRANSFER_READY
	je	okay
	jmp	error

okay:
	;
	; LS_Status.request
	;
	mov	bp, ds:[di].LFI_clientHandle
	mov	ax, MSG_SF_LS_STATUS_REQUEST
	call	StationFsmSendFixupDS
	
	mov	ax, IE_SUCCESS
	clc
exit:
	.leave
	ret
error:
	mov	ax, IE_LSAP_DISCONNECTED
	stc
	jmp	exit
LFStatusRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFStatusConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_Status.confirm

CALLED BY:	MSG_LF_LS_STATUS_CONFIRM
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		cx	= ConnectionStatus
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFStatusConfirm	method dynamic LsapFsmClass, 
					MSG_LF_LS_STATUS_CONFIRM
	uses	ax,si
	.enter
	mov	ax, ds:[di].LFI_state
	cmp	ax, LFS_DISCONNECTED
	je	exit
	cmp	ax, LFS_CONNECT_PEND
	je	exit
	;
	; LM_Status.confirm
	;
	mov	si, ds:[di].LFI_clientHandle
	call	IrlmpStatusConfirm
exit:
	.leave
	ret
LFStatusConfirm	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFStatusIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_Status.indication

CALLED BY:	MSG_LF_LS_STATUS_INDICATION
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		cx	= IrlapStatusIndicationType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFStatusIndication	method dynamic LsapFsmClass, 
					MSG_LF_LS_STATUS_INDICATION
	uses	ax,si
	.enter

; This message is only sent to LsapFsm objects in the IrlapFsm's associated
; set, which means the state is connected.  The only exception is the
; monitor LSAP, which should get called with a status indication in any
; state.
if 0
	mov	ax, ds:[di].LFI_state
	cmp	ax, LFS_DISCONNECTED
	je	exit
	cmp	ax, LFS_CONNECT_PEND
	je	exit
endif
	;
	; LM_Status.indication
	;
	mov	si, ds:[di].LFI_clientHandle
	call	IrlmpStatusIndication
exit:
	.leave
	ret
LFStatusIndication	endm

LsapFsmCode	ends


