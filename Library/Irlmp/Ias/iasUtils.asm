COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasUtils.asm

AUTHOR:		Chung Liu, May  2, 1995

ROUTINES:
	Name			Description
	----			-----------
	IasClientFsmSend
	IUIrlmpDataRequestLooseArgs
	IUCheckIfLastFrame
	IUFreeDataArgs
	IUGetControlByte
	IUMakeLastNoAckFrame
	IUMakeNoLastNoAckFrame
	IUAppendArgToArray
	IUGetIasValueSize
	IUSaveCallRequestArgs
	IUCompareIrlapAddresses
	IUAddRequestingEndpoint
	IURemoveRequestingEndpoint
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 2/95   	Initial revision


DESCRIPTION:
	Utils for IAS module
		

	$Id: iasUtils.asm,v 1.1 97/04/05 01:07:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IasCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IasClientFsmSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the IAS Client FSM.

CALLED BY:	EXTERNAL
PASS:		ax		= message
		cx,dx,bp	= message args
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IasClientFsmSend	proc	far
	uses	di,bx,si
	.enter
	mov	di, mask MF_FORCE_QUEUE
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage
	.leave
	ret
IasClientFsmSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUIrlmpDataRequestLooseArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call IrlmpDataRequest with args in registers

CALLED BY:	ICFLmConnectConfirm
PASS:		bp	= client handle
		^ldx:ax	= HugeLMem data
		si	= data offset
		cx	= data size
RETURN:		same as IrlmpDataRequest
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUIrlmpDataRequestLooseArgs	proc	near
clientHandle	local	word			push bp
dataArgs	local	IrlmpDataArgs
	uses	cx,dx,si
	.enter
	movdw	ss:[dataArgs].IDA_data, dxax
	mov	ss:[dataArgs].IDA_dataOffset, si
	mov	ss:[dataArgs].IDA_dataSize, cx

	mov	cx, ss
	lea	dx, ss:[dataArgs]
	mov	si, ss:[clientHandle]
	call	IrlmpDataRequest
	.leave
	ret
IUIrlmpDataRequestLooseArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUCheckIfLastFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Based on IrlapParamDataSize, determine if the IAS request 
		can be transmitted in one frame.

CALLED BY:	ICFLmConnectConfirm
PASS:		ax	= IrlapParamDataSize
		cx	= size of control byte plus arguments
RETURN:		if data can be transmitted in one frame:
			carry set
			cx unchanged
		else
			carry clear
			cx	= bytes to transmit in this frame
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUCheckIfLastFrame	proc	near
	uses	dx
	.enter
	push	cx
	mov	dx, cx				
	add	dx, size IrlmpFrameHeader	;dx = data to be transmitted
	call	IrlmpGetPacketSize		;cx = packet size
	cmp	cx, dx
	jb	multipleFrames
	pop	cx
	stc
	jmp	exit
multipleFrames:
	pop	dx
	sub	cx, size IrlmpFrameHeader
	clc	
exit:
	.leave
	ret
IUCheckIfLastFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUFreeDataArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the HugeLMem data in the data args.

CALLED BY:	ICFLmDataIndication
PASS:		cx:dx	= IrlmpDataArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUFreeDataArgs	proc	near
	uses	ax,cx,ds,si
	.enter
	movdw	dssi, cxdx
	tst	ds:[si].IDA_dataSize
	jz	exit
	movdw	axcx, ds:[si].IDA_data

	call	HugeLMemFree

exit:
	.leave
	ret
IUFreeDataArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUGetControlByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the control byte from the data args.

CALLED BY:	ICAOutstandingRecv
PASS:		cx:dx 	= IrlmpDataArgs 
RETURN:		al	= IrlmpIasControlByte
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUGetControlByte	proc	near
	uses	bx,cx,dx,ds,di,si
	.enter
	movdw	dsdi, cxdx
	movdw	dxax, ds:[di].IDA_data
	mov	si, ds:[di].IDA_dataOffset

	movdw	bxdi, dxax
	call	HugeLMemLock
	mov	ds, ax
	mov	di, ds:[di]
	add	di, si				;ds:di = IrlmpIasControlByte

	mov	al, ds:[di]
	call	HugeLMemUnlock
	.leave
	ret
IUGetControlByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUMakeLastNoAckFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set IICB_LAST and clear IICB_ACK of control byte.

CALLED BY:	ICFLmConnectConfirm
PASS:		^ldx:ax	= HugeLMem data buffer
		si	= data offset of IrlmpIasControlByte
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUMakeLastNoAckFrame	proc	near
	uses	ax,bx,ds,di
	.enter
	movdw	bxdi, dxax
	call 	HugeLMemLock			;ax = segment
	mov	ds, ax
	mov	di, ds:[di]
	add	di, si				;ds:di = IrlmpIasControlByte

	ornf	{byte} ds:[di], mask IICB_LAST
	andnf	{byte} ds:[di], not mask IICB_ACK

	call	HugeLMemUnlock
	.leave
	ret
IUMakeLastNoAckFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUMakeNoLastNoAckFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear IICB_LAST and IICB_ACK of control byte.

CALLED BY:	ICFLmConnectConfirm
PASS:		^ldx:ax	= HugeLMem data buffer
		si	= data offset of IrlmpIasControlByte
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUMakeNoLastNoAckFrame	proc	near
	uses	ax,bx,ds,di
	.enter
	movdw	bxdi, dxax
	call 	HugeLMemLock			;ax = segment
	mov	ds, ax
	mov	di, ds:[di]
	add	di, si				;ds:di = IrlmpIasControlByte

	andnf	ds:[di], not (mask IICB_ACK or mask IICB_LAST)

	call	HugeLMemUnlock
	.leave
	ret
IUMakeNoLastNoAckFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUAppendArgToArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append one arg to the chunk array.

CALLED BY:	ICGetValueByClassConfirm
PASS:		*ds:si	= chunk array of args
		es:di	= args
RETURN:		*ds:si	= array (ds may have moved)
		es:di	= next arg
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUAppendArgToArray	proc	near
argsArray	local	dword		push ds, si
	uses	ax,si,cx
	.enter
	movdw	dssi, esdi
	;
	; fixup byte order of object id.
	;
	mov	ax, ds:[si].IIIAV_id
	xchg	al, ah
	mov	ds:[si].IIIAV_id, ax
	
	add	si, size word			;ds:si = IAS value
	call	IUGetIasValueSize		;cx = size of value
	sub	si, size word			;ds:si = obj identifier
	add	cx, size word

	push	ds, si
	movdw	dssi, ss:[argsArray]
	mov	ax, cx				;size
	call	ChunkArrayAppend		;ds:di = new element
	segmov	es, ds				;es:di = new element
	pop	ds, si				;ds:si = obj identifier
	rep	movsb

	segxchg	es, ds				;ds = array segment
	mov	di, si				;es:di = next arg
	.leave
	ret
IUAppendArgToArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUGetIasValueSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the size of the IAS value, and fix up the value's
		byte order, if necessary.

CALLED BY:	IUAppendArgToArray
PASS:		ds:si 	= IrlmpIasAttributeValue
RETURN:		cx	= size 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUGetIasValueSize	proc	near
	uses	ax
	.enter

	mov	al, ds:[si].IIAV_type

	mov	cx, size IrlmpIasValueType
	cmp	al, IIVT_MISSING		; XXX changed to AL
	je	exit

	cmp	al, IIVT_INTEGER
	je	integer

	cmp	al, IIVT_OCTET_SEQUENCE
	je	octetSequence
EC <	cmp	al, IIVT_USER_STRING				>
EC < 	ERROR_NE	-1					>
	;
	; user string
	;
	clr	cx
	mov	cl, ds:[si].IIAV_value.IIVU_userString.IIUSH_size
	add	cx, size IrlmpIasUserStringHeader + size IrlmpIasValueType
	jmp	exit

integer:
	;
	; IAS integers are ordered most significant byte first. We need
	; to flip the bytes around.
	;
	movdw	cxax, ds:[si].IIAV_value.IIVU_integer
	xchg	cx, ax
	xchg	cl, ch
	xchg	al, ah
	movdw	ds:[si].IIAV_value.IIVU_integer, cxax
	
	mov	cx, size IrlmpIasValueType + size IrlmpIasIntegerValue
	jmp	exit

octetSequence:
	;
	; fixup the byte order of the size field.
	;
	mov	cx, ds:[si].IIAV_value.IIVU_octetSequence.IIOSH_size
	xchg	cl, ch
	mov	ds:[si].IIAV_value.IIVU_octetSequence.IIOSH_size, cx
	;
	; return total size in cx
	;
	add	cx, size IrlmpIasValueType + size IrlmpIasOctetSequenceHeader

exit:
	.leave
	ret
IUGetIasValueSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUSaveCallRequestArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the call-request arguments in the client FSM's instance
		data.

CALLED BY:	ICFCallRequest
PASS:		ds:di	= IasClientFsmClass instance data
		cx:dx	= IrlmpConnectArgs.  Data arguments are for 
			control byte plus arguments.
		bp	= client handle of requesting endpoint
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUSaveCallRequestArgs	proc	near
	class	IasClientFsmClass
	uses	es,si,ax
	.enter
	mov	ds:[di].ICFI_requestingClient, bp

	movdw	essi, cxdx			;es:si = IrlmpConnectArgs
	mov	ax, es:[si].ICA_dataSize
	mov	ds:[di].ICFI_dataSize, ax
	mov	ax, es:[si].ICA_dataOffset
	mov	ds:[di].ICFI_dataOffset, ax
	movdw	ds:[di].ICFI_data, es:[si].ICA_data, ax

	.leave
	ret
IUSaveCallRequestArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUCompareIrlapAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the 32-bit Irlap address in IrlmpConnectArgs
		to see if it is the same address to which the IAS Client
		FSM is connected.

CALLED BY:	ICFCallRequest
PASS:		ds:di	= IasClientFsmClass instance data
		cx:dx	= IrlmpConnectArgs.  
RETURN:		Z flag is set if two addresses are equal.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUCompareIrlapAddresses	proc	near
	class	IasClientFsmClass
	uses	cx,dx,es,si
	.enter
	movdw	essi, cxdx
	movdw	cxdx, es:[si].ICA_lsapID.ILI_irlapAddr
	cmpdw	cxdx, ds:[di].ICFI_irlapAddr
	.leave
	ret
IUCompareIrlapAddresses	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUAddRequestingEndpoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the endpoint to the set of requesting endpoints

CALLED BY:	ICFCallRequest
PASS:		ds:di	= IasClientFsmClass instance data
		bp	= client handle of requesting endpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUAddRequestingEndpoint	proc	near
	class	IasClientFsmClass
	uses	ax,si
	.enter
	;
	; Only add the endpoint to the set if not already there.
	;
	mov	ax, bp
	mov	si, ds:[di].ICFI_requestingSet
	call	UtilsMemberpSet
	jc	exit

	call	UtilsAddToSet
exit:
	.leave
	ret
IUAddRequestingEndpoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IURemoveRequestingEndpoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the endpoint from the set of requesting endpoints

CALLED BY:	ICFDisconnectIas
PASS:		ds:di	= IasClientFsmClass instance data
		ax	= requesting client
RETURN:		carry clear if okay (endpoint removed):
			cx	= number of elements remaining in set.
		carry set if endpoint was not member of set
			cx destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IURemoveRequestingEndpoint	proc	near
	class	IasClientFsmClass
	uses	si
	.enter
	mov	si, ds:[di].ICFI_requestingSet
	call	UtilsMemberpSet
	jnc	notMember

	call	UtilsRemoveFromSet
	call	UtilsCountSet
	clc
exit:
	.leave
	ret
notMember:
	stc
	jmp	exit
IURemoveRequestingEndpoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUNotifyAndRemoveRequestingEndpoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify all endpoints of loss of IrLAP connection, and
		clear the requesting endpoint set.

CALLED BY:	ICFLmDisconnectIndication
PASS:		ds:di	= IasClientFsmClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUNotifyAndRemoveRequestingEndpoints	proc	near
	class	IasClientFsmClass
	uses	bx,si,di
	.enter
	mov	si, ds:[di].ICFI_requestingSet
	mov	bx, cs
	mov	di, offset IUNotifyAndRemoveRequestingEndpointsCallback
	call	UtilsEnumSet
	call	UtilsClearSet
	.leave
	ret
IUNotifyAndRemoveRequestingEndpoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUNotifyAndRemoveRequestingEndpointsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue LM_GetValueByClass.confirm to each endpoint,
		notifying of loss of IrLAP connection

CALLED BY:	IUNotifyAndRemoveRequestingEndpoints via UtilsEnumSet
PASS:		*ds:di	= array
		ds:di	= endpoint
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUNotifyAndRemoveRequestingEndpointsCallback	proc	far
	uses	si,ax,dx
	.enter
	mov	si, ds:[di]
	mov	dl, IGVBCRC_IRLMP_ERROR
	mov	ax, IE_DISCONNECT_INDICATION
	call	IrlmpGetValueByClassConfirm
	.leave
	ret
IUNotifyAndRemoveRequestingEndpointsCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IasServerFsmSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an event to the IAS Server FSM.

CALLED BY:	EXTERNAL (IasServerCallback)
PASS:		ax		= Message
		cx, dx, bp 	= Message args
		bx		= lptr to Server Fsm
		si		= lptr to client endpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IasServerFsmSend	proc	near
		uses	bx,si,di,ds
		.enter

		mov_tr	bp, si			; bp <- client endpoint
		mov_tr	si, bx			; bx <- lptr of ServerFsm
		mov	di, mask MF_FORCE_QUEUE
		call	UtilsLoadDGroupDS		
		PSem	ds, iasServerSem
		mov	bx, ds:[iasServerBlock]
		VSem	ds, iasServerSem
		call	ObjMessage

		.leave
		ret
IasServerFsmSend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IasServerFsmSendOnStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an event to the IAS Server FSM.

CALLED BY:	EXTERNAL (IasServerCallback)
PASS:		ax		= Message
		ss:bp		= Arguments
		dx		= size of Arguments
		bx		= lptr to server fsm
		si		= lptr to client endpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IasServerFsmSendOnStack	proc	near
		uses	ax,bx,cx,si,di,ds
		.enter

		mov	cx, si			; cx <- lptr to client endpoint
		mov	si, bx			; bx <- lptr of ServerFsm
		mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
		call	UtilsLoadDGroupDS
		PSem	ds, iasServerSem
		mov	bx, ds:[iasServerBlock]
		VSem	ds, iasServerSem
		call	ObjMessage

		.leave
		ret
IasServerFsmSendOnStack	endp

IasCode	ends

