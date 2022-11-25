COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		irlmpApi.asm

AUTHOR:		Chung Liu, Mar  6, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 6/95   	Initial revision


DESCRIPTION:
	API for requests and indications for the IrLMP Library

	$Id: irlmpApi.asm,v 1.1 97/04/05 01:07:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlmpCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Client wishes to register 
CALLED BY:	GLOBAL
PASS:		cl	= IrlmpLsapSel to bind locally. (Could be 
			  IRLMP_ANY_LSAP_SEL)
		dx:ax	= vfptr of callback for indications and confirmations.
		bx	= extra word to pass to callback.
			  Callback:	
				Pass:	di	= IrlmpIndicationOrConfirmation
					bx	= extra word
					Other registers depend on di
				Return:		nothing
				Destroy: 	nothing
RETURN:		carry clear if success:
			ax	= IE_SUCCESS
			cl	= IrlmpLsapSel (If IRLMP_ANY_LSAP_SEL was
				  passed in).
			si	= client handle
		carry set if error:
			ax	= IrLMPError
					IE_NO_FREE_LSAP_SEL
					IE_UNABLE_TO_LOAD_IRLAP_DRIVER
			cx, si destroyed
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	Increment Irlap use count.
	Allocate IrlmpClient entry.
	Create LSAP FSM

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpRegister	proc	far
extraWord	local	word		push bx
callback	local	vfptr		push dx,ax		
	uses	bx,dx,ds,di
	.enter
	;
	; See if the server thread is running and start it if not.
	;
	call	UtilsLoadDGroupDS
	mov	bx, ds:[irlmpRegisterSem]
	call	ThreadPSem

	tst	ds:[irlmpClientCount]
	jnz	haveThread

	call	MainCreateServerThread

haveThread:
	inc	ds:[irlmpClientCount]
	call	ThreadVSem

	;
	; Check if Irlap is available. 
	;
	call	IsapCheckIrlap			;ax = IrlmpError
	jc	clientGone
		

	; 
	; Create the LSAP Control FSM
	;
	xchg	al, cl				;al = IrlmpLsapSel

	call	LsapFsmCreate			;^lcx:dx = LSAP FSM
	mov	bx, cx				; ^lbx:dx = LSAP FSM

	xchg	cl, al				;cl = IrlmpLsapSel

	call	UtilsAllocEndpointLocked	;ds:di = IrlmpEndpoint
						;si = lptr of IrlmpEndpoint
						;cl = actual IrlmpLsapSel
	jc	exit
	;
	; Initialize what we can.
	;
	movdw	ds:[di].IE_lsapFsm, bxdx
	movdw	axbx, ss:[callback]
	movdw	ds:[di].IE_callback, axbx	; copy callback
	mov	bx, ss:[extraWord]
	mov	ds:[di].IE_extraWord, bx	; copy extra data
	mov	ds:[di].IE_lsapSel, cl
	movdw	ds:[di].IE_destLsapID.ILI_irlapAddr, 0
	mov	ds:[di].IE_destLsapID.ILI_lsapSel, IRLMP_PENDING_CONNECT
	mov	ds:[di].IE_flags, 0		;assume not TinyTP.
	; 
	; Create the LSAP Control FSM
	;
	push	cx, si				;save Lsap-Sel, endpoint
	;
	; Set the endpoint for the Lsap FSM.
	;
	xchg	si, dx				;dx = lptr endpoint
	movdw	bxsi, ds:[di].IE_lsapFsm	;^lbx:si = lsap fsm
	;
	; Unlock the block here, otherwise we might deadlock when
	; sending the message to the Irlmp thread if the Irlmp thread
	; is waiting to lock the same block.
	;
	push	bx
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared			; unlock utilsEndpointBlock
	pop	bx

	mov	ax, MSG_LF_SET_ENDPOINT
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	cx, si				;cl = Lsap-Sel
						;si = endpoint
	mov	ax, IE_SUCCESS
	clc
exit:
	.leave
	ret

clientGone:
	pushf		
	call	IrlmpClientGone
	popf		
	jmp	exit
		
IrlmpRegister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanup.

CALLED BY:	GLOBAL
PASS:		si	= client handle
RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax 	= IE_LSAP_NOT_DISCONNECTED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Decrement Irlap use count.		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpUnregister	proc	far
	uses	ds,di,bx,si
	.enter
	mov	ax, MSG_LF_CHECK_IF_CONNECTED
	call	LsapFsmCallByEndpoint
	jc	connected

	push	si

	mov	ax, MSG_META_OBJ_FREE
	call	LsapFsmGetByEndpoint		;^lbx:si = LsapFsm
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	pop	si

	;
	; Free the associated object in the database with this
	; client handle if there is any.
	;
	call	IrdbDeleteUsingClientHandle
		
	call	UtilsFreeEndpoint

	mov	ax, IE_SUCCESS
	clc
exit:
	.leave
	ret

connected:
	mov	ax, IE_LSAP_NOT_DISCONNECTED
	stc
	jmp	exit
IrlmpUnregister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpClientGone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that another LsapFsm object has bit the dust,
		which means a prior IrlmpUnregister has completed. This
		may cause the server thread to exit.

CALLED BY:	(EXTERNAL) LFMetaFinalObjFree
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	irlmpClientCount decremented
     		server thread may be detached

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpClientGone proc	far
	uses	ax, bx, ds
	.enter
	call	UtilsLoadDGroupDS
	mov	bx, ds:[irlmpRegisterSem]
	call	ThreadPSem
	
	dec	ds:[irlmpClientCount]
	jnz	done
	
	call	MainDestroyServerThread
done:
	call	ThreadVSem
	.leave
	ret
IrlmpClientGone endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpDiscoverDevicesRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for remote machines.  If link is currently in use,
		the cached results of the last discovery operation is
		returned.  Otherwise, initiate IrLAP discovery.  

CALLED BY:	GLOBAL
PASS:		si	= client handle, bound to IRLMP_XID_DISCOVERY_SAP.
		bl	= IrlapUserTimeSlot to use for IrLAP discovery.
RETURN:		carry clear
		ax	= IE_SUCCESS

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpDiscoverDevicesRequest	proc	far
	uses	dx,cx
	.enter
	;
	; Forward the request to the Station Control FSM.
	;
	mov	dx, si			;dx = client handle
	mov	cx, bx			;cl = IrlapUserTimeSlot
	mov	ax, MSG_SF_LM_DISCOVER_DEVICES_REQUEST
	call	StationFsmSend

	mov	ax, IE_SUCCESS
	clc
	.leave
	ret
IrlmpDiscoverDevicesRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request that a connection be established to a remote
		LSAP-ID.

CALLED BY:	GLOBAL
PASS:		si	= lptr of IrlmpEndpoint (client handle)
		cx:dx	= IrlmpConnectArgs
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
	CL	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpConnectRequest	proc	far
	.enter
	mov	ax, MSG_LF_LM_CONNECT_REQUEST
	call	LsapFsmCallByEndpoint			;ax = IrlmpError
	.leave
	ret
IrlmpConnectRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpConnectResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accept a connection initiated by a remote device.
		(To reject a connection, use IrlmpDisconnectRequest)

CALLED BY:	GLOBAL
PASS:		si	= lptr of IrlmpEndpoint (client handle)
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
	CL	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpConnectResponse	proc	far
	.enter
	mov	ax, MSG_LF_LM_CONNECT_RESPONSE
	call	LsapFsmCallByEndpoint			;ax = IrlmpError
	.leave
	ret
IrlmpConnectResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Terminate a connection

CALLED BY:	GLOBAL
PASS:		si	= lptr of IrlmpEndpoint (client handle)
		bl	= IrlmpDisconnectReason
		cx:dx	= IrlmpDataArgs.  There is no guarantee that
			  the data will be delivered.
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
	CL	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpDisconnectRequest	proc	far
	uses	bp
	.enter
	mov	bp, bx			;bp.low = IrlmpDisconnectReason
	mov	ax, MSG_LF_LM_DISCONNECT_REQUEST
	call	LsapFsmCallByEndpoint	;ax = IrlmpError
	.leave
	ret
IrlmpDisconnectRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpStatusRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if there is unacknowledged data in the IrLAP queue.

CALLED BY:	GLOBAL
PASS:		si	= client handle
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
	CL	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpStatusRequest	proc	far
	.enter
	mov	ax, MSG_LF_LM_STATUS_REQUEST
	call	LsapFsmCallByEndpoint		;ax = IrlmpError
	.leave
	ret
IrlmpStatusRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send data through the connection

CALLED BY:	GLOBAL
PASS:		si	= lptr of IrlmpEndpoint (client handle)
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
	CL	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpDataRequest	proc	far
	.enter
	mov	ax, MSG_LF_LM_DATA_REQUEST
	call	LsapFsmCallByEndpoint			;ax = IrlmpError
	.leave
	ret
IrlmpDataRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpUDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send UI frame data.

CALLED BY:	GLOBAL
PASS:		si	= lptr of IrlmpEndpoint (client handle)
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
	CL	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpUDataRequest	proc	far
	.enter
	mov	ax, MSG_LF_LM_UDATA_REQUEST
	call	LsapFsmCallByEndpoint			;ax = IrlmpError
	.leave
	ret
IrlmpUDataRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpGetPacketSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the packet size in bytes, given IrlapParamDataSize
		record.

CALLED BY:	GLOBAL
PASS:		ax	= IrlapParamDataSize
RETURN:		cx	= data size
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpGetPacketSize	proc	far
	.enter
	mov	cx, 2048
	test	ax, mask IPDS_2048BYTES
	jnz	exit

	mov	cx, 1024
	test	ax, mask IPDS_1024BYTES
	jnz	exit

	mov	cx, 512
	test	ax, mask IPDS_512BYTES
	jnz	exit

	mov	cx, 256
	test	ax, mask IPDS_256BYTES
	jnz	exit

	mov	cx, 128
	test	ax, mask IPDS_128BYTES
	jnz	exit

	mov	cx, 64
exit:
	.leave
	ret
IrlmpGetPacketSize	endp

IrlmpCode	ends



