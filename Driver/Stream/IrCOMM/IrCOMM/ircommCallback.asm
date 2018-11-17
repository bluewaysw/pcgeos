COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrCOMM
FILE:		ircommCallback.asm

AUTHOR:		Greg Grisco, Jan  3, 1996

ROUTINES:
	Name				Description
	----				-----------
GLB	IrCommTTPCallback		Handles indications & confirmations

INT	IrCommConnectIndication		Peer wants to connect
INT	IrCommConnectConfirm		Peer agrees to connect
INT	IrCommDataIndication		Peer sending data/control
INT	IrCommDisconnectIndication	Peer is disconnecting/refusing connect
INT	IrCommStatusIndication		Peer wants connection status
INT	IrCommStatusConfirmation	Peer is returning the status
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 3/96   	Initial revision


DESCRIPTION:
	Routines to handle indications & confirmations from TinyTP
		

	$Id: ircommCallback.asm,v 1.1 97/04/18 11:46:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrCommCallbackCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommTTPCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle TTP callback for IrCOMM

CALLED BY:	GLOBAL
PASS:		si	= client handle
		di	= IrlmpIndicationOrConfirmation
		bx	= unit index

		other registers depend on di

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommTTPCallback	proc	far
	uses	ds
	.enter

	call	IrCommGetDGroupDS		; ds = dgroup
EC <	call	ECValidateUnitNumber					>

	cmp	di, TTPIC_CONNECT_INDICATION
	jne	testConnConfirm
	call	IrCommConnectIndication
	jmp	done
testConnConfirm:
	cmp	di, TTPIC_CONNECT_CONFIRMATION
	jne	testDisconnInd
	call	IrCommConnectConfirmation
	jmp	done
testDisconnInd:
	cmp	di, TTPIC_DISCONNECT_INDICATION
	jne	testDataInd
	call	IrCommDisconnectIndication
	jmp	done
testDataInd:
	cmp	di, TTPIC_DATA_INDICATION
	jne	testStatInd
	call	IrCommDataIndication
	jmp	done
testStatInd:
	cmp	di, IIC_STATUS_INDICATION
	jne	testStatConf
	call	IrCommStatusIndication
	jmp	done
testStatConf:
	cmp	di, TTPIC_STATUS_CONFIRMATION
	jne	done
	call	IrCommStatusConfirmation
done:
	.leave
	ret
IrCommTTPCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommConnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The peer wants to establish a connection

CALLED BY:	IrCommTTPCallback
PASS:		si	= client handle
		bx	= unit index
		cx:dx	= IrlmpConnectArgs
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommConnectIndication	proc	near
	uses	ax,cx,dx,di,bp,es
	.enter

EC <	cmp	ds:[bx].ISPD_state, ICFS_IDLE				>
EC <	ERROR_NE	IRCOMM_ILLEGAL_STATE				>

	;
	; Store the packet data size (PortEmulatorEstablishConnection
	; will use this to calculate the size of the input stream)
	;
	mov	es, cx
	mov	di, dx
	mov	al, es:[di].ICA_QoS.QOS_param.ICP_dataSize
	mov	ah, es:[di].ICA_QoS.QOS_param.ICP_dataSizeIn
	call	IrlmpGetPacketSize		; cx = packet size
	mov	ds:[bx].ISPD_packetDataSize, cx
	mov	al, ah
	call	IrlmpGetPacketSize
	mov	ds:[bx].ISPD_packetDataSizeIn, cx
	;
	; There might be Initial Control Parameters, check control channel
	;
	call	CheckInitialControlParameters

EC <	call	ECValidateUnitNumber					>
	;
	; Mark as waiting for our response
	;
	mov	ds:[bx].ISPD_state, ICFS_WAITR
	;
	; Create the streams
	;
	mov	cx, ds:[bx].ISPD_inStreamSize
	mov	dx, ds:[bx].ISPD_outStreamSize
	call	PortEmulatorStreamSetup		; cx = initial credits
	jc	error
	;
	; Send a connect response.
	;
	push	cx
	sub	sp, size IrlmpConnectArgs
	mov	di, sp
	mov	ss:[di].ICA_dataSize, 0
	movdw	cxdx, ssdi
	call	TTPConnectResponse
	add	sp, size IrlmpConnectArgs
	pop	cx				; cx = initial credits
	;
	; We have connection
	;
	mov	ds:[bx].ISPD_state, ICFS_CONN
	mov	ds:[bx].ISPD_irlapStatus, ISIT_OK
	;
	; Set the initial credits to be given to the remote
	;
	call	TTPAdvanceCredit
	;
	; Send Initial Line Settings
	;
	call	PortEmulatorSendInitialLineSettingsFar
done:
	.leave
	ret
error:
	;
	; We are unable to allow the connection.  Send a disconnect
	; request.
	;
	mov	di, bx				; di = unit number
	mov	bl, IDR_USER_REQUEST
	call	IrCommDisconnectRequest
	jmp	done
IrCommConnectIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommConnectConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The peer agrees to our connect request

CALLED BY:	IrCommTTPCallback
PASS:		si	= client handle
		bx	= unit index
		cx:dx	= IrlmpConnectArgs
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Store the negotiated packet sizes so the port emulator can
		figure out how many credits to advance, etc.
	Handle the control parameters being passed
	Free the data block
	Change state to CONNECTED (send any notifications)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommConnectConfirmation	proc	near
	uses	ax,bx,cx,dx,si,di,es
	.enter

	Assert	dgroup ds

EC <	cmp	ds:[bx].ISPD_state, ICFS_WAITI				>
EC <	ERROR_NE	IRCOMM_ILLEGAL_STATE				>

	mov	es, cx
	mov	di, dx				; es:di = IrlmpConnectArgs
	;
	; Store the packet data size (PortEmulatorEstablishConnection
	; will use this to calculate the size of the input stream)
	;
	clr	ax
	mov	al, es:[di].ICA_QoS.QOS_param.ICP_dataSize
	call	IrlmpGetPacketSize		; cx = packet size
	mov	ds:[bx].ISPD_packetDataSize, cx

	mov	al, es:[di].ICA_QoS.QOS_param.ICP_dataSizeIn
	call	IrlmpGetPacketSize		; cx = packet size
	mov	ds:[bx].ISPD_packetDataSizeIn, cx
	;
	; There might be Initial Control Parameters, check control channel
	;
	call	CheckInitialControlParameters
	;
	; We are connected now
	;
	mov	ds:[bx].ISPD_state, ICFS_CONN
	mov	ds:[bx].ISPD_irlapStatus, ISIT_OK
	VSem	ds, connectionSem, TRASH_AX_BX

	.leave
	ret
IrCommConnectConfirmation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Data and/or Control parameters are being sent from the
		peer.

CALLED BY:	IrCommTTPCallback
PASS:		si	= client handle
		bx	= unit index
		cx:dx	= IrlmpConnectArgs
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Handle the control parameters first (if any)
	Copy whatever data there is to the input stream

NOTES:
	Keep track of how much data is being put into the stream so
	that we know how many credits to advance

	We are running on the IrLMP thread, so make it quick.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommDataIndication	proc	near
	uses	ax,bx,cx,dx,si,di,es,ds
	.enter

	mov	es, cx
	mov	di, dx				; es:di = IrlmpDataArgs

	mov	dx, bx				; dx = unit number
	mov	cx, es:[di].IDA_dataSize
	LONG	jcxz	exit			; is there any data?
	;
	; Lock down the data
	;
	movdw	bxsi, es:[di].IDA_data
	pushdw	bxsi				; so we can free it later
	call	HugeLMemLock			; ax = segment of block
	mov	ds, ax
	mov	si, ds:[si]
	add	si, es:[di].IDA_dataOffset	; ds:si = start of data
	;
	; Check if we can advance more credits.  At this point:
	; cx = data size
	;
	call	IrCommGetDGroupES		; es = DGroup, 
	mov	bx, dx				; es:bx = IrSerialPortData
EC <	call	ECValidateUnitNumber					>
	;	
	; Calculate and accumulate extra space
	;
	PSem	es, creditSem
	mov	dx, es:[bx].ISPD_packetDataSizeIn
	sub	dx, cx
	add	es:[bx].ISPD_bytesDealtWith, dx
	;
	; Check if we have enough to advance a credit.
	;
	mov	dx, es:[bx].ISPD_packetDataSizeIn
	cmp	dx, es:[bx].ISPD_bytesDealtWith
	ja	controlParams			
	;
	; There is enough extra space in the input stream for another full
	; data packet, so advance a TinyTP credit.
	;
	sub	es:[bx].ISPD_bytesDealtWith, dx
EC <	ERROR_S	-1							>
	push	cx
	mov	cx, 1				; advance one credit
	call	IrCommAdvanceTTPCredit
	pop	cx				; cx = data size

controlParams:	
	VSem	es, creditSem
	;
	; Process the control parameters if any
	;
	dec	cx				;size without clen byte
	lodsb					;al = control length, si adv.
	call	ControlAccountForCredit
	call	IrCommProcessControlParams	; cx = # of data bytes left
						; ds:si = UserData
	jcxz	freeAndExit
	;
	; Copy data to the input stream.  At this point:
	;
	; ds:si	= UserData
	; cx 	= UserData size
	; bx 	= unit number
	; es:bx	= IrSerialPortData
	;
	Assert 	dgroup es
EC <	call	ECValidateUnitNumber					>

	mov	bx, es:[bx].ISPD_inStream	; bx = stream

EC <	mov	dx, cx				;save UserData size	>
	mov	ax, STREAM_NOBLOCK		
	mov	di, DR_STREAM_WRITE

	call	StreamStrategy			;cx = bytes written
	;
	; Because of the TinyTP credit system, we should always have enough
	; room in the stream. 
	;
EC <	cmp	dx, cx							>
EC <	ERROR_NE	-1						>

freeAndExit:
	popdw	axcx				; block optr
	mov	bx, ax
	call	HugeLMemUnlock
	call	HugeLMemFree
exit:
	.leave
	ret
IrCommDataIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommDisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer is ending the connection or refusing our connect
		request

CALLED BY:	IrCommTTPCallback
PASS:		si	= client handle
		bx	= unit index
		al	= IrlmpDisconnectReason
		cx:dx	= IrlmpDataArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	We need to destroy the streams, but cannot do so on this
	thread (irlmp:0) since PortEmulatorDestroyStreams blocks
	waiting for status confirmation from irlmp.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommDisconnectIndication	proc	near
	uses	ax,cx,bx,di,bp,ds
	.enter

	pushdw	cxdx

	call	IrCommGetDGroupDS		; ds = dgroup
EC <	call	ECValidateUnitNumber					>
	mov	ds:[bx].ISPD_irlapStatus, ISIT_DISCONNECTED
	;
	; Destroy the streams
	;
	mov	bp, bx
	mov	bx, ds:[threadHandle]
	tst	bx
	jz	done
	mov	ax, MSG_IRCOMM_DISCONNECT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:
	mov	ds:[bp].ISPD_state, ICFS_IDLE
	popdw	dsdi				; ds:di = IrlmpDataArgs

	tst	ds:[di].IDA_dataSize
	jz	noData

	movdw	axcx, ds:[di].IDA_data
	call	HugeLMemFree
noData:
	.leave
	ret
IrCommDisconnectIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommStatusIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer is requesting status or current connection is in
		jeopardy

CALLED BY:	IrCommTTPCallback
PASS:		si	= client handle
		bx	= unit index
		cx	= IrlapStatusIndicationType
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommStatusIndication	proc	near
	uses	ax, bx, cx, di
	.enter

	;
	; Store the status locally so that the read routines can check
	; if we are in jeopardy of losing the connection.
	;

	mov	ds:[bx].ISPD_irlapStatus, cx

	.leave
	ret
IrCommStatusIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommStatusConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer is sending us the connection status we requested

CALLED BY:	IrCommTTPCallback
PASS:		si	= client handle
		bx	= unit index
		cx	= ConnectionStatus
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommStatusConfirmation	proc	near
	.enter

	mov	ds:[connStatus], cx
	;
	; Free the thread which sent the status request
	;
	VSem	ds, statusSem

	.leave
	ret
IrCommStatusConfirmation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlServiceType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer has sent us the Service Type parameter.

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_SERVICE_TYPE
		dl	= 1
		ds:si	= IrCommServiceType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlServiceType	proc	near
	uses	ax,dx,ds
	.enter

EC <	cmp	dh, ICCP_SERVICE_TYPE					>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 1							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	mov	al, {byte} ds:[si]		; al = IrCommServiceType

EC <	test	al, not (mask ICST_9_WIRE or mask ICST_3_WIRE)		>
EC <	ERROR_NZ	IRCOMM_SERVICE_TYPE_NOT_SUPPORTED		>

	call	IrCommGetDGroupDS		; ds = dgroup
	mov	ds:[bx].ISPD_serviceType, al

	.leave
	ret
IrCommControlServiceType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlDataRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer has sent us the Data Rate parameter

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_DATA_RATE
		dl	= 4
		ds:si	= double word numeric baud rate
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlDataRate	proc	near
	uses	ax,cx,dx,ds
	.enter

EC <	cmp	dh, ICCP_DATA_RATE					>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 4							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	movdw	dxcx, ds:[si]
	xchg	ch, cl
	xchg	dh, dl				; cxdx = baud rate

	call	IrCommGetDGroupDS		; ds = dgroup

	call	IrCommGetBaudRate		; ax = SerialBaud
	mov	ds:[bx].ISPD_curState.SPS_baud, ax

	.leave
	ret
IrCommControlDataRate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlDataFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer has sent us the Data Format parameter

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_DATA_FORMAT
		dl	= 1
		ds:si	= IrCommDataFormat
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlDataFormat	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

EC <	cmp	dh, ICCP_DATA_FORMAT					>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 1							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	mov	al, {byte} ds:[si]		; al = IrCommDataFormat
	call	IrCommGetDGroupDS		; ds = dgroup

	mov	dl, al
	test	al, mask ICDF_PARITY_EN
	jnz	enabled
	or	ds:[bx].ISPD_curState.SPS_format, (SP_NONE shl offset SF_PARITY)
	jmp	checkCharLen
enabled:
	and	al, mask ICDF_PARITY
	mov	cl, offset ICDF_PARITY
	shr	al, cl
	and	ds:[bx].ISPD_curState.SPS_format, not mask SF_PARITY
	or	ds:[bx].ISPD_curState.SPS_format, (SP_ODD shl offset SF_PARITY)
	tst	al
	jz	checkCharLen

	and	ds:[bx].ISPD_curState.SPS_format, not mask SF_PARITY
	or	ds:[bx].ISPD_curState.SPS_format, (SP_EVEN shl offset SF_PARITY)
	test	al, 1
	jz	checkCharLen

	and	ds:[bx].ISPD_curState.SPS_format, not mask SF_PARITY
	or	ds:[bx].ISPD_curState.SPS_format, (SP_MARK shl offset SF_PARITY)
	test	al, 2
	jz	checkCharLen

	and	ds:[bx].ISPD_curState.SPS_format, not mask SF_PARITY
	or	ds:[bx].ISPD_curState.SPS_format, (SP_SPACE shl offset SF_PARITY)
checkCharLen:
	mov	al, dl
	or	ds:[bx].ISPD_curState.SPS_format, (SL_5BITS shl offset SF_LENGTH)
	and	al, mask ICDF_CHAR_LEN
	jz	checkStop

	or	ds:[bx].ISPD_curState.SPS_format, (SL_6BITS shl offset SF_LENGTH)
	cmp	al, 1
	je	checkStop

	or	ds:[bx].ISPD_curState.SPS_format, (SL_7BITS shl offset SF_LENGTH)
	cmp	al, 2
	je	checkStop

	or	ds:[bx].ISPD_curState.SPS_format, (SL_8BITS shl offset SF_LENGTH)
checkStop:
	mov	al, dl

	or	ds:[bx].ISPD_curState.SPS_format, mask SF_EXTRA_STOP
	test	al, mask ICDF_STOP_BITS
	jz	done

	and	ds:[bx].ISPD_curState.SPS_format, not mask SF_EXTRA_STOP
done:
	.leave
	ret
IrCommControlDataFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlFlowControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer has sent us the Flow Control parameter

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_FLOW_CONTROL
		dl	= 1
		ds:si	= IrCommFlowControl
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlFlowControl	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

EC <	cmp	dh, ICCP_FLOW_CONTROL					>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 1							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	mov	al, {byte} ds:[si]		; al = IrCommFlowControl
	call	IrCommGetDGroupDS		; ds = dgroup
	;
	; Is software flow control enabled?
	;
	clr	ah				; ah = SerialFlow
	test	al, mask ICFC_XON_XOFF_INPUT or mask ICFC_XON_XOFF_OUTPUT
	jz	checkHardware
	mov	ah, mask SF_SOFTWARE
checkHardware:
	;
	; Check if any of the hardware flow control methods are set
	;
	test	al, not (mask ICFC_XON_XOFF_INPUT or mask ICFC_XON_XOFF_OUTPUT)
	jz	checkInOut
	or	ah, mask SF_HARDWARE
	;
	; Which hardware flow control method are we using?
	;
	test	al, mask ICFC_RTS_CTS_INPUT or mask ICFC_RTS_CTS_OUTPUT	
	jz	checkDsrDtr
	mov	ds:[bx].ISPD_stopCtrl, mask SMC_RTS
	mov	ds:[bx].ISPD_stopSignal, mask SMS_CTS
	jmp	checkInOut
checkDsrDtr:
	test	al, mask ICFC_DSR_DTR_INPUT or mask ICFC_DSR_DTR_OUTPUT
	jz	checkEnqAck
	mov	ds:[bx].ISPD_stopCtrl, mask SMC_RTS
	mov	ds:[bx].ISPD_stopSignal, mask SMS_CTS
	jmp	checkInOut
checkEnqAck:
PrintMessage < "Enq/Ack not supported by serial driver.  Do something here">
checkInOut:
	tst	ah
	jz	done
	;
	; One of the methods was set.  Check for input or output
	;
	test	al, (mask ICFC_XON_XOFF_INPUT or mask ICFC_RTS_CTS_INPUT or mask ICFC_DSR_DTR_INPUT or mask ICFC_ENQ_ACK_INPUT)
	jz	checkOutput
	or	ah, mask SF_INPUT
checkOutput:
	test	al, (mask ICFC_XON_XOFF_OUTPUT or mask ICFC_RTS_CTS_OUTPUT or mask ICFC_DSR_DTR_OUTPUT or mask ICFC_ENQ_ACK_OUTPUT)
	jz	done
	or	ah, mask SF_OUTPUT
done:
	mov	ds:[bx].ISPD_flow, ah

	.leave
	ret
IrCommControlFlowControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlXonXoff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer has sent us the Xon/Xoff parameter

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_XON_XOFF
		dl	= 2
		ds:si	= parameter value
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
	It doesn't do us any good saving the the values for the
	XON/XOFF characters since the serial driver API doesn't allow
	for getting or setting the values, 0x11 & 0x13 are always
	used.

	If necessary, such functionality could be added to the serial
	driver API.  This would require additional functions, and
	replacing the hard-coded XON/XOFF values with variables.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlXonXoff	proc	near
	.enter

EC <	cmp	dh, ICCP_XON_XOFF					>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 2							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	.leave
	ret
IrCommControlXonXoff	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlEnqAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer has sent us the Enq/Ack parameter

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_ENQ_ACK
		dl	= 2
		ds:si	= parameter value
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Enq/Ack is not supported by the serial driver.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlEnqAck	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	cmp	dh, ICCP_ENQ_ACK					>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 2							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	.leave
	ret
IrCommControlEnqAck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlLineStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer has sent us the Line Status parameter

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_LINE_STATUS
		dl	= 1
		ds:si	= parameter value
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlLineStatus	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	cmp	dh, ICCP_LINE_STATUS					>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 1							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	.leave
	ret
IrCommControlLineStatus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlBreak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer has sent us the Control Break parameter.  Notify
		the error handler if one exists.

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_BREAK
		dl	= 1
		ds:si	= parameter value
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlBreak	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	cmp	dh, ICCP_BREAK						>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 1							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	test	{byte} ds:[si], mask ICB_SET
	jz	done				; jump if break not set
	;
	; Break is set.  Notify the Error handler.
	;
	call	IrCommGetDGroupDS
	mov	ax, STREAM_READ
	mov	bx, ds:[bx].ISPD_inStream
	mov	cx, mask SE_BREAK		; cx = SerialError
	mov	di, DR_STREAM_SET_ERROR
	call	StreamStrategy
done:
	.leave
	ret
IrCommControlBreak	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlDTE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer has sent us the DTE line settings parameter,
		either because the settings have changed, or in
		response to our poll.  Save the settings locally and
		call the modem notifier routine if one exists.  The
		settings are also sent at connection time (with delta
		bits 0).

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_DTE
		dl	= 1
		ds:si	= IrCommDTESetting
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Decode the IrCommDTESetting and store in SerialModemStatus

	Call SerialModemNotify routine to notify the client of the
	  changed modem status

NOTES:
	It seems that both this and the DCE routine should only be
	called in a 9-wire service type connection.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlDTE	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	.enter

EC <	cmp	dh, ICCP_DTE						>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 1							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	mov	al, {byte} ds:[si]		; al = IrCommDTESetting
	call	IrCommGetDGroupDS		; ds = dgroup

	mov	ds:[bx].ISPD_peerRole, SR_DTE
CheckHack < SNM_NONE eq 0 >
	tst	ds:[bx].ISPD_modemEvent.SN_type
	jz	done
	clr	cl				; cl = SerialModemStatus
	;
	; Map IrCommDTESetting to SerialModemStatus.
	;
	test	al, mask ICDTE_RTS_DELTA
	jz	checkDTR
	or	cl, mask SMS_RTS_CHANGED
	test	al, mask ICDTE_RTS_STATE
	jz	checkDTR
	or	cl, mask SMS_RTS
checkDTR:
	test	al, mask ICDTE_DTR_DELTA
	jz	callNotify
	or	cl, mask SMS_DTR_CHANGED
	test	al, mask ICDTE_DTR_STATE
	jz	callNotify
	or	cl, mask SMS_DTR
callNotify:
	mov	ds:[bx].ISPD_modemStatus, cl
	mov	ax, ds:[bx].ISPD_inStream
	mov	es, ax
	mov	ah, STREAM_NOACK
	lea	di, ds:[bx].ISPD_modemEvent
	call	StreamNotify
done:
	.leave
	ret
IrCommControlDTE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlDCE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Peer has sent us the DCE line settings parameter

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_DCE
		dl	= 1
		ds:si	= IrCommDCESetting
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlDCE	proc	near
	uses	ax,bx,cx,dx,di,si,ds,es,bp
	.enter

EC <	cmp	dh, ICCP_DCE						>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 1							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	mov	al, {byte} ds:[si]		; al = IrCommDCESetting
	call	IrCommGetDGroupDS		; ds = dgroup

	mov	ds:[bx].ISPD_peerRole, SR_DCE
	;
	; The IrCommDCESetting struct is the same as
	; SerialModemStatus.  Just call the notifier routine.
	;
CheckHack < SNM_NONE eq 0 >
	tst	ds:[bx].ISPD_modemEvent.SN_type
	jz	done

	mov	cl, al				; cl = SerialModemStatus
	mov	ds:[bx].ISPD_modemStatus, cl
	lea	di, ds:[bx].ISPD_modemEvent
	mov	ax, ds:[bx].ISPD_inStream
	mov	es, ax				; es = stream token
	call	StreamNotify
done:
	.leave
	ret
IrCommControlDCE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlPoll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The peer is requesting the current state of the line
		settings.  We need to respond with DTE line settings
		if we are a DTE, or else the DCE settings.  The
		response to this poll should set the delta bits to
		zero. 

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit index
		dh	= ICCP_POLL
		dl	= 0
		ds:si	= parameter value
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlPoll	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

EC <	cmp	dh, ICCP_POLL						>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>
EC <	cmp	dl, 0							>
EC <	ERROR_NE	IRCOMM_ILLEGAL_PARAMETER			>

	sub	sp, 4
	mov	si, sp
	mov	{byte} ss:[si], 3		; control length

	call	IrCommGetDGroupDS		; ds = dgroup
	cmp	ds:[bx].ISPD_clientRole, SR_DCE
	je	sendDCE
	;
	; Respond with the DTE line settings
	;
	mov	cl, ds:[bx].ISPD_dteSetting	; current DTE setting
	mov	{byte} ss:[si+1], ICCP_DTE	; PI
	mov	{byte} ss:[si+2], 1		; PL
	mov	{byte} ss:[si+3], cl		; PV
send:
	segmov	ds, ss, ax
	call	PortEmulatorWriteControlDataFar
	add	sp, 4

	.leave
	ret
sendDCE:
	;
	; Respond with the DCE line settings
	;
	mov	cl, ds:[bx].ISPD_dceSetting	; current DCE setting
	mov	{byte} ss:[si+1], ICCP_DCE	; PI
	mov	{byte} ss:[si+2], 1		; PL
	mov	{byte} ss:[si+3], cl		; PV
	jmp	send
IrCommControlPoll	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommProcessControlParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the encode control parameters

CALLED BY:	IrCommDataIndication, CheckInitialControlParameters
PASS:		bx	= unit number
		al	= control length
		cx	= # of total data bytes 
		ds:si	= buffer which holds encoded data (the first
			  byte is the one immediately following the control 
			  length)
RETURN:		cx	= # of leftover bytes (UserData size)
		ds:si	= adjusted to start of actual data (after
			  control params)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

NOTES:
	Since we are consuming the control data right away, this
	routine must account for the number of control bytes in
	figuring out when to advance a credit.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParamRoutineEntry	struct
	PRE_param	IrCommControlParameters
	PRE_routine	word
ParamRoutineEntry	ends

controlParamTable ParamRoutineEntry \
<ICCP_SERVICE_TYPE, IrCommControlServiceType>,
<ICCP_DATA_RATE, IrCommControlDataRate>,
<ICCP_DATA_FORMAT, IrCommControlDataFormat>,
<ICCP_FLOW_CONTROL, IrCommControlFlowControl>,
<ICCP_XON_XOFF, IrCommControlXonXoff>,
<ICCP_ENQ_ACK, IrCommControlEnqAck>,
<ICCP_LINE_STATUS, IrCommControlLineStatus>,
<ICCP_BREAK, IrCommControlBreak>,
<ICCP_DTE, IrCommControlDTE>,
<ICCP_DCE, IrCommControlDCE>,
<ICCP_POLL, IrCommControlPoll>,
<-1,-1>

IrCommProcessControlParams	proc	near
	uses	ax,dx,di
	.enter
	tst	al
	jz	done				;jmp if no control data

	clr	ah
	sub	cx, ax
	xchg	ax, cx				;ax = UserData size 
						;cx = control length
	push	ax				;save to return
	
paramLoop:
	;
	; cx = leftover control length
	;
	lodsw					;al = PI, ah = PL, si advanced
	mov	di, offset controlParamTable

findParam:
	cmp	cs:[di].PRE_param, -1
EC <	WARNING_E	IRCOMM_UNSUPPORTED_PARAMETER_RECEIVED		>
	je	next
	cmp	cs:[di].PRE_param, al
	je	found
	add	di, size ParamRoutineEntry
	jmp	findParam
found:
	xchg	ah, al				;al = PL, ah = PI
	mov	dx, ax
	call	cs:[di].PRE_routine		; call param function
next:
	clr	ah				;ax = PL
	add	si, ax				;ds:si = next param (or start
						;  of UserData)
	sub	cx, 2				; sub size of PI & PL
	sub	cx, ax				;# param bytes left
	js	error				;invalid control length
	jcxz	popSizeDone
	jmp	paramLoop

popSizeDone:
	pop	cx				;return cx = user data size

done:
	;
	; ds:si = UserData
	;
	clc
exit:
	.leave
	ret
error:
	pop	cx
	stc
	jmp	exit

IrCommProcessControlParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommGetBaudRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts from IrCOMM encoded data rate to SerialBaud

CALLED BY:	IrCommControlDataRate
PASS:		cxdx	= numerical data rate
RETURN:		ax	= SerialBaud
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommGetBaudRate	proc	near
	.enter

	jcxz	checkLower
	mov	ax, SB_115200
	cmp	cx, 0x11
	jge	done

	mov	ax, SB_57600
	cmp	cx, 0x5
	jge	done

	mov	ax, SB_38400
	cmp	cx, 0x3
	jge	done

	mov	ax, SB_19200
	cmp	cx, 0x1
	jge	done
checkLower:
	mov	ax, SB_9600
	cmp	dx, 0x960
	jge	done

	mov	ax, SB_2400
done:
	.leave
	ret
IrCommGetBaudRate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ControlAccountForCredit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accounts for the number of bytes in the control
		channel for figuring out when to advance a TinyTP
		credit.

CALLED BY:	IrCommDataIndication
PASS:		bx	= unit number
		al	= Control Length
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ControlAccountForCredit	proc	near
	uses	ax,cx,dx,di,ds
	.enter

	call	IrCommGetDGroupDS		; ds = dgroup

	clr	ah
	inc	al				; + control length byte
	;	
	; Calculate and accumulate extra space
	;
	PSem	ds, creditSem
	add	ds:[bx].ISPD_bytesDealtWith, ax
	;
	; Check if we have enough to advance a credit.
	;
	mov	dx, ds:[bx].ISPD_packetDataSizeIn
	cmp	dx, ds:[bx].ISPD_bytesDealtWith
	ja	done
	;
	; There is enough extra space in the input stream for another full
	; data packet, so advance a TinyTP credit.
	;
	sub	ds:[bx].ISPD_bytesDealtWith, dx
EC <	ERROR_S	-1							>
	mov	cx, 1				; advance one credit
	call	IrCommAdvanceTTPCredit
done:
	VSem	ds, creditSem

	.leave
	ret
ControlAccountForCredit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckInitialControlParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for Initial Control Parameters sent to us in a
		Connect Indication or Confirmation.

CALLED BY:	IrCommConnectIndication, IrCommConnectConfirmation
PASS:		ds	= dgroup
		bx	= unit number
		es:di	= IrlmpConnectArgs
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	

	Frees the HugeLMem if control data was passed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	3/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckInitialControlParameters	proc	near
	uses	bx, cx, si, bp
	.enter

	mov	cx, es:[di].ICA_dataSize
	jcxz	noData

	push	ds
	mov	bp, bx				; bp = unit number
	movdw	bxsi, es:[di].ICA_data
	mov	dx, si
	call	HugeLMemLock			; ax = block segment
	mov	ds, ax
	mov	si, ds:[si]
	add	si, es:[di].ICA_dataOffset	; ds:si = start of data
						; cx = # of bytes
	xchg	bx, bp
EC <	call	ECValidateUnitNumber					>
	
	dec	cx				;size without clen byte
	lodsb					;al = control length, si adv.
	call	IrCommProcessControlParams
	xchg	bp, bx

	movdw	axcx, bxdx			; ^lax:cx = chunk
	call	HugeLMemUnlock	
	call	HugeLMemFree
	mov	bx, bp
	pop	ds				; ds:si IrSerialPortData
noData:
	.leave
	ret
CheckInitialControlParameters	endp


IrCommCallbackCode	ends
