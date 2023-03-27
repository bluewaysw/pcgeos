COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasClientActions.asm

AUTHOR:		Chung Liu, May  2, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 2/95   	Initial revision


DESCRIPTION:
	Actions for IAS Client FSM.
		

	$Id: iasClientActions.asm,v 1.1 97/04/05 01:07:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IasCode			segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICACallRequestDisconnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The IAS client FSM received a call-request in the 
		ICFS_DISCONNECTED state.  Establish the IAS connection,
		and proceed to make call.

CALLED BY:	ICFCallRequest
PASS:		ds:di	= IasClientFsmClass instance data
		cx:dx	= IrlmpConnectArgs for peer's IAS LsapSel
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
	CL	5/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICACallRequestDisconnected	proc	near
	class	IasClientFsmClass
	uses	bx,cx,dx,si,di
	.enter
	;
	; Register just like any other Irlmp Library client, and obtain
	; a LSAP with which to do business.
	;
	push	cx, dx
	mov	cl, IRLMP_ANY_LSAP_SEL
	mov	dx, vseg IasIrlmpCallback
	mov	ax, offset IasIrlmpCallback
	call	IrlmpRegister			;cl = IrlmpLsapSel
						;si = client handle
	pop	cx, dx
	jc	exit
	mov	ds:[di].ICFI_clientHandle, si
	;
	; Connect to peer's IAS lsap.
	;
	call	IrlmpConnectRequest
	jc	exit
	;
	; Go to next state, to wait for the LM_Connect.confirm
	;
	mov	dx, ICFS_CONNECTING
	mov	ax, MSG_ICF_CHANGE_STATE
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage

	mov	ax, IE_SUCCESS
	clc
exit:
	.leave
	ret
ICACallRequestDisconnected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICACallRequestMakeCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The IAS Client FSM received a call-request in the 
		ICFS_MAKE_CALL state.  The IrLMP connection to the peer's
		IAS LSAP is already established, so just proceed with
		sending the IAP packet.

CALLED BY:	ICFCallRequest, ICFLmConnectConfirm
PASS:		ds:di	= IasClientFsmClass instance data.  
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If call fits into a single IAP frame:
		send IAP frame
		next state = ICFS_OUTSTANDING
	else:
		send IAP frame with first args
		next state = ICFS_CALLING

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICACallRequestMakeCall	proc	near
	class	IasClientFsmClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Check if the call request can fit in the packet size of the
	; connection we have established.
	;
	mov	al, ds:[di].ICFI_frameSize
	mov	cx, ds:[di].ICFI_dataSize	;cx = size of IAS request
	call	IUCheckIfLastFrame		;cx = bytes to transmit in
						;     this frame.
	;
	; Load up the registers with data args before dealing branching
	;
	movdw	dxax, ds:[di].ICFI_data
	mov	si, ds:[di].ICFI_dataOffset
	mov	bp, ds:[di].ICFI_clientHandle
	jc	lastFrame
	;
	; Looks like this is going to be a multi-frame IAS query.  Send the
	; first args, and adjust data args for next frame.
	;
	sub	ds:[di].ICFI_dataSize, cx
	add	ds:[di].ICFI_dataOffset, cx

	;
	; XXX: multi-frame requests not implemented.
	;
	call	IUMakeNoLastNoAckFrame
	call	IUIrlmpDataRequestLooseArgs
	jc	dataRequestFailed

	mov	dx, ICFS_CALLING
	jmp	changeState

lastFrame:
	;
	; Looks like it will all fit into one IAP frame.  Send it!
	;
	call	IUMakeLastNoAckFrame
	call	IUIrlmpDataRequestLooseArgs
	jc	dataRequestFailed

	mov	dx, ICFS_OUTSTANDING

changeState:
	mov	ax, MSG_ICF_CHANGE_STATE
	mov	di, mask MF_FORCE_QUEUE
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage

exit:
	.leave
	ret
dataRequestFailed:
	; 
	; Data request failed. 
	;
	mov	si, ds:[di].ICFI_requestingClient
	mov	dl, IGVBCRC_IRLMP_ERROR
	call	IrlmpGetValueByClassConfirm
	jmp	exit
ICACallRequestMakeCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICACallingRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received data in ICFS_CALLING state.  We're in the middle
		of transmitting a multi-frame request, so received data
		should be ack frames.

CALLED BY:	ICFLmDataIndication
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
	CL	5/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICACallingRecv	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Currently in the middle of sending a multi-frame command.
	; Each data indication should be an IrlmpIasFrame with IICB_ACK
	; set.
	;
	;XXX: Multi-frame commands not implemented.
	;
	call	IUCheckIfLastFrame
	jc	callingLastFrame

	jmp	exit

callingLastFrame:

exit:
	.leave
	ret
ICACallingRecv	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICAOutstandingRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received data while waiting for the response to a command. 
		(OUTSTANDING state)

CALLED BY:	ICFLmDataIndication
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
	CL	5/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICAOutstandingRecv	proc	near
	class	IasClientFsmClass
	uses	ax,bx,dx,di,si,bp
	.enter
	call	IUGetControlByte		;al = IrlmpIasControlByte
	test	al, mask IICB_ACK
	jnz 	ackFrame

	test	al, mask IICB_LAST
	jnz	lastFrame
	;
	; Not last frame.  Store results and send ack.
	;
	; XXX: Multi-frame responses not implemented.
	mov	dx, ICFS_REPLYING
	jmp	changeState
lastFrame:
	;
	; Received the last frame of the response.  Call confirm with
	; results.
	;
	clr	bp
	xchg	bp, ds:[di].ICFI_requestingClient

	call	ICCallConfirm
	mov	dx, ICFS_MAKE_CALL

changeState:
	mov	ax, MSG_ICF_CHANGE_STATE
	mov	di, mask MF_FORCE_QUEUE
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage
	
exit:
	.leave
	ret
ackFrame:
	;	
	; Received an ack frame.  These are optional and ignored in 
	; the outstanding state.
	;
EC <	test	al, mask IICB_LAST				>
EC <	ERROR_Z		-1					>
	jmp	exit
ICAOutstandingRecv	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICAReplyingRecv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received data in REPLYING state.

CALLED BY:	ICFLmDataIndication
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
	CL	5/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICAReplyingRecv	proc	near
	.enter
	.leave
	ret
ICAReplyingRecv	endp

IasCode			ends



