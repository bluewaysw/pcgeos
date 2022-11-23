COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		irlapUtils.asm

AUTHOR:		Chung Liu, Feb 24, 1995

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95   	Initial revision


DESCRIPTION:
	Interface between IrLMP and native IrLAP.
		
	$Id: isapUtils.asm,v 1.1 97/04/05 01:07:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsapCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUDataDemultiplexer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interpret incoming PDU in order to send a PDU message to
		a Lsap FSM.

CALLED BY:	IsapDataIndication
PASS:		^ldx:ax	= data buffer
		cx	= size of data
		si	= offset into the buffer
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Figure out the IrlmpEndpoint (and LsapFsm) to which this data	
	indication should be forwarded.  If the data is a Connect PDU, 
	then look for an endpoint with the corresponding IE_lsapSel, 
	and a IE_destLsapID.ILI_lsapSel of IRLMP_PENDING_CONNECT.
	If a data is a Data PDU or a Connect Confirm PDU, then look
	for the IrlmpEndpoint with both matching IE_lsapSel and 
	IE_destLsapID.ILI_lsapSel.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUDataDemultiplexer	proc	far
dataArgs	local	IrlmpDataArgs
	uses	ax,bx,cx,dx,si
	.enter
	movdw	ss:[dataArgs].IDA_data, dxax
	mov	ss:[dataArgs].IDA_dataOffset, si
	mov	ss:[dataArgs].IDA_dataSize, cx

	call	UtilsGetLsapsFromPDU		;ch = PDU's dest. LsapSel
						;cl = PDU's source LsapSel
	push	cx				;save to pass to Lsap FSM
	push	bp
	lea	bp, ss:[dataArgs]		;ss:bp = IrlmpDataArgs
	call	UtilsGetOpCodeFromPDU		;dl = IrlmpOpCode
	pop	bp

	cmp	dl, IOC_CONNECT
	jne	matchLsap

	;
	; Check to see if this connect is to the IAS server.
	; If it is, we have to start the server up.
	;
	cmp	ch, IRLMP_IAS_LSAP_SEL
	jnz	pendingConnect

	call	IUStartIasServer
	jc	noMatchRestoreStack

pendingConnect:
	;
	; The data is a Connect LM-PDU.  Because connection is not 
	; yet established, look for IrlmpEndpoint with 
	; IE_destLsapID.ILI_lsapSel = IRLMP_PENDING_CONNECT.  IE_lsapSel
	; should match the PDU's destination LsapSel.
	;
	mov	cl, IRLMP_PENDING_CONNECT
	
matchLsap:
	; 
	; ch = PDU's dest. LsapSel
	; cl = PDU's source LsapSel or IRLMP_PENDING_CONNECT
	;
	call	UtilsGetEndpointByLsaps		;si = lptr IrlmpEndpoint
	pop	cx				;saved PDU Lsaps
	jc	noMatch

	push	bp
	lea	bp, ss:[dataArgs]		;ss:bp = IrlmpDataArgs
	mov	dx, size IrlmpDataArgs
	mov	ax, MSG_LF_IRLAP_DATA_INDICATION
	call	LsapFsmSendByEndpointStack
	pop	bp	
exit:
	.leave
	ret
noMatchRestoreStack:
	pop	cx
		
noMatch:
	call	IUFreeAndDisconnect
	jmp	exit

IUDataDemultiplexer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUExpeditedDataDemultiplexer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle incoming expedited data PDU.

CALLED BY:	IsapDataIndication
PASS:		^ldx:ax	= data buffer
		cx	= size of data
		si	= offset into the buffer
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUExpeditedDataDemultiplexer	proc	far
dataArgs	local	IrlmpDataArgs
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	movdw	ss:[dataArgs].IDA_data, dxax
	mov	ss:[dataArgs].IDA_dataOffset, si
	mov	ss:[dataArgs].IDA_dataSize, cx

	call	UtilsGetLsapsFromPDU		;ch = PDU's dest. LsapSel
						;cl = PDU's source LsapSel
	push	bp
	lea	bp, ss:[dataArgs]		;ss:bp = dataArgs
	call	UtilsGetOpCodeFromPDU		;dl = IrlmpOpCode  
	pop	bp
	cmp	dl, IOC_DATA					   
EC <	ERROR_NE IRLMP_EXPEDITED_DATA_IS_NOT_DATA_PDU		   >
	jne	exit				;ignore if not data PDU.
	
	call	UtilsGetEndpointByLsaps		;si = lptr IrlmpEndpoint
	jc	noMatch
	
	push	bp
	lea	bp, ss:[dataArgs]		;ss:bp = IrlmpDataArgs
	mov	dx, size IrlmpDataArgs
	mov	ax, MSG_LF_IRLAP_EXPEDITED_DATA_INDICATION
	call	LsapFsmSendByEndpointStack
	pop	bp

exit:
	.leave
	ret

noMatch:
	call	IUFreeAndDisconnect
	jmp	exit
IUExpeditedDataDemultiplexer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUFreeAndDisconnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There was no matching IrlmpEndpoint for the Lsaps in the PDU.
		We must now free the data and reply with a Disconnect LM-PDU.

CALLED BY:	IUDataDemultiplexer, IUExpeditedDataDemultiplexer
PASS:		ch	= PDU's dest. LsapSel
		cl	= PDU's source LsapSel
		ss:bp	= inherited frame
				dataArgs = IrlmpDataArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUFreeAndDisconnect	proc	near
dataArgs	local	IrlmpDataArgs
	.enter	inherit far
	push	ax,bx,cx,dx,si,bp
	;
	; swap dest and source lsap-sels for disconnect PDU
	;
	mov	bl, ch				;bl = source lsap (non-
						;  existant lsap-sel that
						;  was the destination of
						;  the PDU.
	mov	bh, cl				;bh = dest lsap (source
						;  of the PDU for which 
						;  we find no matching
						;  endpoint.
	;
	; should free the data because no one else will.
	;
	movdw	axcx, ss:[dataArgs].IDA_data
	call	HugeLMemFree
	;
	; Generate a Disconnect LM-PDU to return to originator of Connect.
	;
	call	UtilsAllocPDUData		;dx,ax,cx,si = data args
	mov	bp, IDR_DATA_ON_DISCONNECTED_LSAP
	call	UtilsMakeDisconnectPDU		;si, cx updated
	call	IsapDataRequest

	pop	ax,bx,cx,dx,si,bp
	.leave
	ret
IUFreeAndDisconnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUCallIrlap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the Irlap Driver's strategy routine.

CALLED BY:	(INTERNAL)
PASS:		di	= NativeIrlapRequest
		other regs depend on di.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUCallIrlap	proc	near
	uses	es,bx
	.enter
	call	UtilsLoadDGroupES
	mov	bx, es:[isapClientHandle]
	pushdw	es:[isapStrategy]
	call	PROCCALLFIXEDORMOVABLE_PASCAL
	.leave
	ret
IUCallIrlap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUStartIasServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell Irlmp to create a thread for the IAS Server
		and handle the connect message.

CALLED BY:	IUDataDemultiplexer
PASS:		nothing
RETURN:		carry set if error
		ax	= server handle to irlmp library
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUStartIasServer	proc	near
		uses	ax,bx,cx,dx,di,bp,ds
		.enter

EC <		cmp	ch, IRLMP_IAS_LSAP_SEL				>
EC <		ERROR_NZ -1						>
	;
	; Check to see if the ias server is already going.
	; If it is, then just send a disconnect.  In the future,
	; we would like to handle multiple IAS queries, but
	; for now, just send a disconnect.
	;
if 0
		call	UtilsLoadDGroupDS
		PSem	ds, iasServerSem
		tst	ds:[iasServerCount]
		pushf
		VSem	ds, iasServerSem
		popf
		jnz	disconnect
endif
	;
	; Send the message to the main server thread to create
	; the IAS server.
	;
		mov	ax, MSG_IP_START_IAS_SERVER
		mov	di, mask MF_CALL
		call	MainMessageServerThread	; bunch of stuff trashed

		clc
exit:		
		.leave
		ret
	;
	; We experienced an error and can't let them connect.
	;
if 0
disconnect:
		stc
		jmp	exit
endif
		
IUStartIasServer	endp


IsapCode	ends


