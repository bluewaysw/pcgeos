COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	IrLMP Library
MODULE:		TinyTP
FILE:		ttpApi.asm

AUTHOR:		Chung Liu, Dec 19, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/19/95   	Initial revision


DESCRIPTION:
	TinyTP routines.

	$Id: ttpApi.asm,v 1.1 97/04/05 01:07:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register to use TinyTP.

CALLED BY:	GLOBAL
PASS:		cl	= IrlmpLsapSel (could be IRLMP_ANY_LSAP_SEL)
		dx:ax	= vptr of callback for confirmations and indications

		bx	= extra word to be passed to callback (could be
			  caller's dgroup, process handle, or whatever is
			  useful.)

			Callback:
			Pass:	 di	= TTPIndicationOrConfirmation
				 si	= client handle
				 bx	= extra word passed to TTPRegister
				 Other registers depend on di
			Return:	 nothing
			Destroy: nothing

RETURN: 	carry clear if okay:
			ax	= IE_SUCCESS
			cl	= IrlmpLsapSel (actual LSAP-Sel, if 
				  IRLMP_ANY_LSAP_SEL was passed in.)
			si	= client handle
		carry set if error:
			ax	= IrlmpError
					IE_NO_FREE_LSAP_SEL
					IE_UNABLE_TO_LOAD_IRLAP_DRIVER
			cx, si destroyed
	
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPRegister	proc	far
	uses	bx, ds, di
	.enter
	call	IrlmpRegister			;si = client handle
						;cl = IrlmpLsapSel
	jc	exit

	push	cx, si
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	ornf	ds:[di].IE_flags, mask IEF_TINY_TP

	mov	bx, size TTPQueueEntry
	clr	ax, cx, si
	call	ChunkArrayCreate		;*ds:si = array
	mov	ds:[di].IE_txQueue, si

	mov	bx, ds:[LMBH_handle]			
	call	MemUnlockExcl

	pop	cx, si
	clc

exit:
	.leave
	ret
TTPRegister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister TTP endpoint

CALLED BY:	GLOBAL
PASS:		si	= client handle
RETURN:		carry clear if okay:
			ax	= IE_SUCCESS
		carry set if error:
			ax 	= IE_LSAP_NOT_DISCONNECTED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPUnregister	proc	far
	uses	bx,cx,dx,di,ds
	.enter

	;
	; Loop here until the txQueue is empty.
	; We do this in case a disconnect has been queued
	;
waitForUnacked:
	call	TTPStatusRequest
	jc	freeQueue

	mov	ax, 60
	call	TimerSleep
	jmp	waitForUnacked
		
freeQueue:		
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint
	mov	ax, ds:[di].IE_txQueue		;dx = lptr txQueue array
	call	LMemFree

	mov	bx, ds:[LMBH_handle]		
	call	MemUnlockExcl

	call	IrlmpUnregister
EC <	ERROR_C 	-1						>
	.leave
	ret
TTPUnregister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connect to remote TinyTP LSAP.

CALLED BY:	GLOBAL
PASS:		si	= client handle
		cx:dx	= IrlmpConnectArgs
RETURN:		carry clear if okay:
			ax	= IE_SUCCESS (but not connected, until 
				connect.confirm is received.)
		carry set if error:
			ax	= IrlmpError

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPConnectRequest	proc	far
	uses	ds,di,bx
	.enter
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	mov	ds:[di].IE_availCredit, 0
	mov	ds:[di].IE_sendCredit, 0
	mov	ds:[di].IE_remoteCredit, 0

	mov	bx, ds:[LMBH_handle]			
	call	MemUnlockExcl

	mov	al, 0
	call	TTPMakePDU

	call	IrlmpConnectRequest
	.leave
	ret
TTPConnectRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPConnectResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Accept a TTP connection 

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
	CL	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPConnectResponse	proc	far
	uses	ds,di,ax,bx
	.enter
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	mov	ds:[di].IE_availCredit, 0
	mov	ds:[di].IE_remoteCredit, 0

	mov	bx, ds:[LMBH_handle]			
	call	MemUnlockExcl

	mov	al, 0
	call	TTPMakePDU

	call	IrlmpConnectResponse
	.leave
	ret
TTPConnectResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disconnect a TinyTP connection

CALLED BY:	GLOBAL
PASS:		si	= lptr of IrlmpEndpoint (client handle)
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
	CL	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPDisconnectRequest	proc	far
	uses	bx,ds,di
	.enter
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	call	TTPTxQueueGetCount		;ax = data size
	tst	ax
	jnz	queueDisconnect

	mov	bx, ds:[LMBH_handle]			
	call	MemUnlockExcl

	mov	bx, IDR_USER_REQUEST	
	call	IrlmpDisconnectRequest
exit:
	clc	
	mov	ax, IE_SUCCESS
	.leave
	ret

queueDisconnect:
	;
	; ds:di	= IrlmpEndpoint
	; cx:dx = IrlmpDataArgs
	;
	mov	al, TQET_DISCONNECT_REQUEST
	call	TTPTxQueueAppendTail

	mov	bx, ds:[LMBH_handle]			
	call	MemUnlockExcl
	jmp	exit
TTPDisconnectRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send data through TTP connection.

CALLED BY:	GLOBAL
PASS:		si	= lptr of IrlmpEndpoint (client handle)
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
	CL	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPDataRequest	proc	far
	uses	ds,di,bx
	.enter
	call	TTPCheckIfConnected
	mov	ax, IE_LSAP_DISCONNECTED
	jnc	exit
	;
	; Ignore requests to send no data.
	;
	call	TTPGetDataRequestSize		;ax = data size
	cmp	ax, 0
	jz	exitSuccess

	;
	; If sendCredit > 0, send the data across.  Otherwise, queue the
	; request.
	;
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	call	TTPTxQueueGetCount		;ax = queue count.
	cmp	ax, TTP_MAX_TX_QUEUE_COUNT
	jae	queueIsFull

	cmp	ds:[di].IE_sendCredit, 0	;Z set if no credits.
	jz	queueDataRequest

	;
	; sendCredit is non-zero, so there shouldn't be anything in the
	; queue.
	;
EC <	cmp	ax, 0						>
EC <	ERROR_NZ 	-1					>

	call	TTPDetermineCreditToAdvance	;ax = credit to advance
	dec	ds:[di].IE_sendCredit		;use up one send credit.

	mov	bx, ds:[LMBH_handle]			
	call	MemUnlockExcl

	call	TTPMakePDU
	call	IrlmpDataRequest	;-> carry set if IE_LSAP_DISCONNECTED
exit:					;   carry clear if IE_SUCCESS
	.leave
	ret
exitSuccess:
	mov	ax, IE_SUCCESS
	clc	
	jmp	exit

queueIsFull:
	;
	; ds:di = IrlmpEndpoint.
	;
	mov	bx, ds:[LMBH_handle]			
	call	MemUnlockExcl

	mov	ax, IE_TTP_TX_QUEUE_FULL
	stc
	jmp	exit

queueDataRequest:
	;
	; cx:dx = IrlmpDataArgs
	; ds:di	= locked IrlmpEndpoint
	;
	mov	ax, TQET_DATA_REQUEST
	call	TTPTxQueueAppendTail

	mov	bx, ds:[LMBH_handle]			
	call	MemUnlockExcl

	mov	ax, IE_SUCCESS
	clc
	jmp	exit
TTPDataRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPTxQueueGetFreeCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the number of calls to TTPDataRequest that can be
		handled before the TxQueue is full.

CALLED BY:	GLOBAL
PASS:		si	= client handle
RETURN:		cx	= free count (send credits + free TxQueue entries)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPTxQueueGetFreeCount	proc	far
	uses	ax,bx,ds,di
	.enter
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	mov	cx, TTP_MAX_TX_QUEUE_COUNT
	call	TTPTxQueueGetCount		;ax = queue count
	sub	cx, ax				;cx = remaining free entries
						;  in TxQueue.

	add	cx, ds:[di].IE_sendCredit	;cx = number of data requests
						;  that can be handled.

	mov	bx, ds:[LMBH_handle]			
	call	MemUnlockExcl
	.leave
	ret
TTPTxQueueGetFreeCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPAdvanceCredit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increase the send credits available to advance to the 
		remote entity.

CALLED BY:	GLOBAL
PASS:		si	= client handle
		cx	= # credits
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPAdvanceCredit	proc	far
	uses	ds, di, bx
	.enter
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint
	add	ds:[di].IE_availCredit, cx
	mov	bx, ds:[LMBH_handle]			
	;
	; We cannot wait for the client to send data before we
	; actually transfer the credit (it might never happen!).
	; Instead, send a data-less PDU every time we are advanced a
	; credit.
	;
	call	TTPCheckCredit			;send data-less PDU

	call	MemUnlockExcl
	.leave
	ret
TTPAdvanceCredit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPStatusRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In addition to checking if there is pending IrLAP data, we
		must see if there are pending requests in TxQueue.

CALLED BY:	GLOBAL
PASS:		si	= client handle
RETURN:		same as IrlmpStatusRequest
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPStatusRequest	proc	far
	.enter
	call	IrlmpStatusRequest
	.leave
	ret
TTPStatusRequest	endp
