COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasEvents.asm

AUTHOR:		Chung Liu, May  2, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 2/95   	Initial revision


DESCRIPTION:
	Event handling for IAS FSM.
		

	$Id: iasClientEvents.asm,v 1.1 97/04/05 01:07:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IasCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICELeavePending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add event to secondary queue

CALLED BY:	ICFCallRequest
PASS:		*ds:si	= IasClientFsmClass object
		ds:di	= IasClientFsmClass object
		ax	= message to add to secondary queue.
		cx, dx, bp = message arguments

		ss:bp 	= ICFCallRequestArgs
RETURN:		carry clear
		ax	= IE_SUCCESS
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICELeavePending	proc	near
	class	IasClientFsmClass
	uses	di, si, bx
	.enter
	;
	; Take note that there are pending events in the secondary queue.
	;
	mov	ds:[di].ICFI_pendingFlag, -1
	;
	; ObjMessage directly to the secondary queue.
	;
	mov	bx, ds:[di].ICFI_secondaryQueue
	clr	si
	mov	dx, size ICFCallRequestArgs
	mov	di, mask MF_FORCE_QUEUE or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; return success
	;
	mov	ax, IE_SUCCESS
	clc	
	.leave
	ret
ICELeavePending	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICFCallRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call request for an IAS query.

CALLED BY:	MSG_ICF_CALL_REQUEST
PASS:		*ds:si	= IasClientFsmClass object
		ds:di	= IasClientFsmClass instance data
		ss:bp	= ICFCallRequestArgs
				contains:
				Client handle of requesting endpoint.
				IrlmpConnectArgs - Data arguments are for 
				control byte plus arguments.
		dx	= number of parameters in bytes

RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax	= IrlmpError
DESTROYED:	data in IrlmpConnectArgs is consumed.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	DISCONNECTED:
		LM_Connect.request
		next state = ICFS_CONNECTING
	MAKE_CALL:
		Send IAP frame
		next state = ICFS_OUTSTANDING or ICFS_CALLING

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICFCallRequest	method dynamic IasClientFsmClass, 
					MSG_ICF_CALL_REQUEST
	.enter

	mov	cx, ss
	lea	dx, ss:[bp].ICFCRA_connectArgs	; cx:dx <- IrlmpConnectArgs
	mov	bx, bp				; ss:bx <- ICFCallRequestArgs
	mov	bp, ss:[bp].ICFCRA_clientHandle		
		
	cmp	ds:[di].ICFI_state, ICFS_DISCONNECTED
	je	disconnected

	cmp	ds:[di].ICFI_state, ICFS_MAKE_CALL
	je	makeCall

	mov	bp, bx				; ss:bp <- ICFCallRequestArgs
	call	ICELeavePending
	jmp	exit

disconnected:
	call	IUAddRequestingEndpoint
	;
	; The data arguments in IrlmpConnectArgs are saved so that the
	; call-request can be made after the IrLMP connection is established.
	;
	call	IUSaveCallRequestArgs
	;
	; We don't want any data to be transmitted along with the connect
	; request.
	;
	movdw	essi, cxdx
	mov	es:[si].ICA_dataSize, 0
	;
	; Remember the irlap address of our prospective peer.
	;
	movdw	ds:[di].ICFI_irlapAddr, es:[si].ICA_lsapID.ILI_irlapAddr, ax
	call	ICACallRequestDisconnected
	jmp	exit

makeCall:
	call	IUAddRequestingEndpoint
	;
	; Check that we are connected to the right address.  If not, then
	; the call cannot be made now.
	;
	call	IUCompareIrlapAddresses
	jne	differentAddress

	call	IUSaveCallRequestArgs
	call	ICACallRequestMakeCall
exit:
	.leave
	ret
differentAddress:
	mov	ax, IE_IAS_CONNECTED_TO_ANOTHER_ADDRESS	
	stc
	jmp	exit
ICFCallRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICFLmDisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Disconnect_indication received by the IAS client endpoint.
		Note: If piggybacked data existed, it was already freed.

CALLED BY:	MSG_ICF_LM_DISCONNECT_INDICATION
PASS:		*ds:si	= IasClientFsmClass object
		ds:di	= IasClientFsmClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICFLmDisconnectIndication	method dynamic IasClientFsmClass, 
					MSG_ICF_LM_DISCONNECT_INDICATION
	uses	ax,dx
	.enter

	call	IUNotifyAndRemoveRequestingEndpoints
	;
	; Check first if already disconnected (Maybe user called
	; IrlmpDisconnectIas.)
	;
	clr	si
	xchg	si, ds:[di].ICFI_clientHandle
	tst	si
	jz	exit

	call	IrlmpUnregister

	mov	dx, ICFS_DISCONNECTED
	mov	ax, MSG_ICF_CHANGE_STATE
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage

exit:
	.leave
	ret
ICFLmDisconnectIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICFLmConnectConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Connect.confirm received by IAS Client FSM endpoint.

CALLED BY:	MSG_ICF_LM_CONNECT_CONFIRM
PASS:		*ds:si	= IasClientFsmClass object
		ds:di	= IasClientFsmClass instance data
		cx:dx	= IrlmpConnectArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	After receiving a LM_Connect.confirm in the ICFS_CONNECTING state,
	the FSM should send the IAS call request data packet.  Depending
	on whether the request fits in one single packet, the request 
	packet control byte is different.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICFLmConnectConfirm	method dynamic IasClientFsmClass, 
					MSG_ICF_LM_CONNECT_CONFIRM
	uses	ax,cx,dx
	.enter
	;
	; LM_Connect.confirm is only expected in the ICFS_CONNECTING state.
	; 
	cmp	ds:[di].ICFI_state, ICFS_CONNECTING
EC <	WARNING_NE IRLMP_ILLEGAL_STATE_AND_EVENT_COMBINATION	>
NEC <	jne	exit						>
	;
	; From the connect args, we're mostly interested in the packet size.
	;
	movdw	essi, cxdx			;es:si = IrlmpConnectArgs
	clr	ax
	mov 	al, es:[si].ICA_QoS.QOS_param.ICP_dataSize
						;al = IrlapParamDataSize
	mov	ds:[di].ICFI_frameSize, al
	;
	; Go straight into the call-request handler for ICFS_MAKE_CALL state.
	;
	call	ICACallRequestMakeCall
exit::	
	.leave
	ret
ICFLmConnectConfirm	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICFLmDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Data.indication

CALLED BY:	MSG_ICF_LM_DATA_INDICATION
PASS:		*ds:si	= IasClientFsmClass object
		ds:di	= IasClientFsmClass instance data
		cx:dx	= IrlmpDataArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICFLmDataIndication	method dynamic IasClientFsmClass, 
					MSG_ICF_LM_DATA_INDICATION
	uses	ax, bp
	.enter
	mov	ax, ds:[di].ICFI_state
	cmp	ax, ICFS_CALLING
	je	calling
	cmp	ax, ICFS_OUTSTANDING
	je	outstanding
	cmp	ax, ICFS_REPLYING
	je	replying
EC <	WARNING_NE IRLMP_ILLEGAL_STATE_AND_EVENT_COMBINATION		>
	jmp	exit
calling:
	;
	; In the middle of sending out a multi-frame call request.
	;
	call	ICACallingRecv
	jmp	exit
outstanding:
	;
	; Waiting for the response for a command.
	;
	call	ICAOutstandingRecv
	jmp	exit
replying:
	;
	; Currently collecting a multi-part response.
	;
	call	ICAReplyingRecv
exit:
	.leave
	ret
ICFLmDataIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICFDisconnectIas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminate the IAS connection

CALLED BY:	MSG_ICF_DISCONNECT_IAS
PASS:		*ds:si	= IasClientFsmClass object
		ds:di	= IasClientFsmClass instance data
		bp	= requesting client
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
	CL	5/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICFDisconnectIas	method dynamic IasClientFsmClass, 
					MSG_ICF_DISCONNECT_IAS
requestingClient	local	word		push bp
dataArgs		local	IrlmpDataArgs
	uses	cx,dx
	.enter
	;
	; Remove the client that requested the IAS disconnect from the
	; set of requesting clients. 
	;
	mov	ax, ss:[requestingClient]
	call	IURemoveRequestingEndpoint		;cx = number of 
							;  remaining elements
	mov	ax, IE_LSAP_NOT_CONNECTED_TO_IAS
	jc	exit
	jcxz 	disconnectIt
	mov	ax, IE_SUCCESS
	clc
exit:
	.leave
	ret

disconnectIt:
	;
	; Maybe already disconnected, if a LM_Disconnect.indication arrived.
	;
	clr	si
	xchg	si, ds:[di].ICFI_clientHandle
	tst	si
	jz	alreadyDisconnected
	;
	; Disconnect IrLMP connection to remote IAS Lsap-Sel.
	;
	mov	ss:[dataArgs].IDA_dataSize, 0
	mov	bl, IDR_UNSPECIFIED
	mov	cx, ss
	lea	dx, ss:[dataArgs]
	call	IrlmpDisconnectRequest
EC <	ERROR_C		-1						>
	;
	; Also unregister, since we're re-registering if reconnecting.
	;
	call	IrlmpUnregister
EC <	ERROR_C		-1						>
	;
	; next-state = ICFS_DISCONNECTED
	;
	mov	dx, ICFS_DISCONNECTED
	mov	ax, MSG_ICF_CHANGE_STATE
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage

alreadyDisconnected:
	clc	
	mov	ax, IE_SUCCESS
	jmp	exit
ICFDisconnectIas	endm

IasCode		ends
