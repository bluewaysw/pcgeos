COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Irlmp Library
MODULE:		TinyTP
FILE:		ttpCallback.asm

AUTHOR:		Chung Liu, Dec 19, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/19/95   	Initial revision


DESCRIPTION:
	Handle Irlmp callbacks for TinyTP
		

	$Id: ttpCallback.asm,v 1.1 97/04/05 01:07:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPIrlmpDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle data indications for TinyTP

CALLED BY:	TTPIrlmpCallback
PASS:		di	= IIC_DATA_INDICATION
		si	= lptr of IrlmpEndpoint
		cx:dx	= IrlmpDataArgs for TTP data PDU.
RETURN:		carry clear if client should be called:
			cx:dx	= IrlmpDataArgs for client data
		carry set if no client data
			cx:dx	= IrlmpDataArgs.IDA_data buffer freed.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPIrlmpDataIndication	proc	far
	uses	ax,bx,ds,di
	.enter

	call	TTPGetDeltaCreditFromPDU	;al = delta credit
						;bx = data size
						;cx:dx = client data
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint
	clr	ah
	add	ds:[di].IE_sendCredit, ax

	; Only use up a remote credit if there was client data.
	tst	bx
	jz	checkQueue
	dec	ds:[di].IE_remoteCredit	

	; Don't automatically increment availCredit.  Let client app use
	; TTPAdvanceCredit.
	;
	;inc	ds:[di].IE_availCredit	


checkQueue:
	;
	; If there is data in TxQueue, use up these new credits.
	;
	call	TTPCheckTxQueue

	;
	; At this point, either txQueue is empty, or sendCredit = 0.
	; Check if we should advance more credits to peer via a dataless
	; PDU.
	;
	call	TTPCheckCredit
	
unlockEndpoint::
	cmp	bx, 0				;Z if no data
        mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl			;flags preserved

	stc					;return carry set if no data
	jz	exit
	clc					;carry clear if there is
						;  client data.
exit:
	.leave
	ret
TTPIrlmpDataIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPIrlmpConnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle LM_connect.ind for TinyTP.

CALLED BY:	TTPIrlmpCallback
PASS:		si	= client handle
		cx:dx	= IrlmpConnectArgs
RETURN:		cx:dx	= IrlmpConnectArgs changed to be client data.
			If client data size is 0, then ICA_data is freed.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPIrlmpConnectIndication	proc	far
	uses	ax,bx,ds,di
	.enter
	call	TTPGetDeltaCreditFromPDU	;cx:dx = client data
						;al = initial credit
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	clr	ah
	mov	ds:[di].IE_sendCredit, ax
	
        mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl
	.leave
	ret
TTPIrlmpConnectIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPIrlmpConnectConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle LM_Connect.confirm for TinyTP

CALLED BY:	TTPIrlmpCallback
PASS:		si	= client handle
		cx:dx	= IrlmpConnectArgs
RETURN:		cx:dx	= IrlmpConnectArgs changed to be client data.
			If client data size is 0, then ICA_data is freed.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPIrlmpConnectConfirmation	proc	far
	uses	ax,bx,ds,di
	.enter
	call	TTPGetDeltaCreditFromPDU	;cx:dx = client data
						;al = initial credit
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	clr	ah
	mov	ds:[di].IE_sendCredit, ax
	
        mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl
	.leave
	ret
TTPIrlmpConnectConfirmation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPIrlmpDisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free any pending data in the TxQueue.

CALLED BY:	TTPIrlmpCallback
PASS:		si	= client handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPIrlmpDisconnectIndication	proc	far
	uses	ax,si,di,ds
	.enter

	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	call	TTPTxQueueGetCount		;ax = # entries in queue
	tst	ax
	jz	done

	mov	si, ds:[di].IE_txQueue
	call	ChunkArrayZero
done:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl

	.leave
	ret
TTPIrlmpDisconnectIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPIrlmpStatusConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In addition to unacked IrLAP data, we must check for
		data requests pending in the TxQueue.

CALLED BY:	TTPIrlmpCallback
PASS:		si	= client handle
		cx	= ConnectionStatus from IrLAP
RETURN:		cx	= ConnectionStatus accounting for TxQueue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPIrlmpStatusConfirmation	proc	far
	uses	ds,di,ax,bx
	.enter
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint

	call	TTPTxQueueGetCount		;ax = # entries in queue

        mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl

	tst	ax
	jz	exit

	ornf	cx, mask CS_UNACKED_DATA
exit:
	.leave
	ret
TTPIrlmpStatusConfirmation	endp







