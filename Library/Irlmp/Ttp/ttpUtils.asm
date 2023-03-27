COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Irlmp Library
MODULE:		TinyTP
FILE:		ttpUtils.asm

AUTHOR:		Chung Liu, Dec 21, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/21/95   	Initial revision


DESCRIPTION:
	Various functions for TinyTP
		

	$Id: ttpUtils.asm,v 1.1 97/04/05 01:07:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPMakePDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform TTP user data into a ConnectTTP-PDU.

CALLED BY:	TTPConnectRequest
		TTPDataRequest
PASS:		cx:dx	= IrlmpConnectArgs or IrlmpDataArgs
		al	= initial credit or delta credit
RETURN:		cx:dx	= changed into TinyTP PDU.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPMakePDU	proc	near
initialCredit	local	word			push ax
	uses	ds,si,es,di,ax,bx,cx,dx
	.enter
EC <	test	al, 80h						>
EC <	ERROR_NZ IRLMP_TINY_TP_ILLEGAL_INITIAL_CREDIT			>

	movdw	dssi, cxdx			;ds:si = IrlmpConnectArgs
						;  or IrlmpDataArgs

	cmp	ds:[si].IDA_dataSize, 0
	jz	allocConnectData

EC <	cmp	ds:[si].IDA_dataOffset, TTP_HEADER_SIZE			>
EC < 	ERROR_B IRLMP_TINY_TP_DATA_HEADER_TOO_SMALL			>

makePDU:
	;
	; ds:si = IrlmpConnectArgs
	;
	inc	ds:[si].IDA_dataSize		;one more byte for TTP header
	dec	ds:[si].IDA_dataOffset		;take one byte for TTP header
	mov	dx, ds:[si].IDA_dataOffset	;dx = data offset

	movdw	bxdi, ds:[si].IDA_data		;^lbx:di = buffer

	push	bx				;save data handle
	call	HugeLMemLock			;ax = segment of block

	mov	ds, ax				;*ds:di = buffer
	mov	di, ds:[di]			;ds:di = buffer
	add	di, dx				;ds:di = data

	mov	ax, ss:[initialCredit]
	clr	ah
	mov	ds:[di], al

	pop	bx
	call	HugeLMemUnlock
	
	.leave
	ret

allocConnectData:
	;
	; ds:si = IrlmpDataArgs
	;
	push	ds
	mov	cx, TTP_HEADER_SIZE
	call	UtilsAllocHugeLMemDataLocked	;^ldx:ax = buffer
						;ds:di = buffer
	mov	bx, dx
	call	HugeLMemUnlock

	pop	ds				;ds:si = IrlmpDataArgs
	mov	ds:[si].ICA_dataOffset, TTP_HEADER_SIZE
	movdw	ds:[si].ICA_data, bxax

	jmp	makePDU
TTPMakePDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPCheckIfConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check it TinyTP endpoint is connected

CALLED BY:	TTPDataRequest
PASS:		si	= lptr of endpoint
RETURN:		carry clear if not connected
		carry set if connected
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPCheckIfConnected	proc	near
	uses	ax
	.enter
	mov	ax, MSG_LF_CHECK_IF_CONNECTED
	call	LsapFsmCallByEndpoint
	.leave
	ret
TTPCheckIfConnected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPCheckTxQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send data in TxQueue if possible.

CALLED BY:	TTPIrlmpDataIndication
PASS:		ds:di	= IrlmpEndpoint
		si	= lptr of IrlmpEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPCheckTxQueue	proc	near
argsBuf		local	TTPQueueEntry
	uses	bx,cx,dx,es
	.enter
	;
	; Check if we have any send credits to use.
	;
	tst	ds:[di].IE_sendCredit
	jz	exit

	;
	; Loop to use up as many send credits as possible.
	;
	mov	cx, ss
	lea	dx, ss:[argsBuf]		;cx:dx = TTPQueueEntry buffer
sendLoop:
	call	TTPTxQueueDeQueueHead		;cx:dx = filled in
	jc	exit

	; Each entry in the queue can be a data request or a disconnect
	; request.
	cmp	ss:[argsBuf].TQE_type, TQET_DATA_REQUEST
	jne	disconnect
	;
	; Determine credit to advance to peer when sending data
	;
	call	TTPDetermineCreditToAdvance	;ax = credits to advance
	;
	; Unlock the endpoint block when calling into Irlmp, to avoid 
	; deadlock.
	;
        mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl
	;
	; handle a data request in the queue.
	;
	call	TTPMakePDU
	call	IrlmpDataRequest
EC <	ERROR_C		-1					>
	;
	; Get the endpoint again.  
	;
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint
	;
	; If sending a data-less PDU (in order to advance a credit)
	; don't charge ourselves a send credit.
	;
	push	si
	mov	es, cx
	mov	si, dx				;es:si = IrlmpDataArgs
	cmp	es:[si].IDA_dataSize, 1		;sending credit only?
	pop	si				;si = client handle
	je	sendLoop
	;
	; Otherwise, we just ate a credit.
	;
	dec	ds:[di].IE_sendCredit		;sets Z if result is zero.
	jnz	sendLoop

exit:
	.leave
	ret

disconnect:
EC <	cmp	ss:[argsBuf].TQE_type, TQET_DISCONNECT_REQUEST		>
EC <	ERROR_NE 	-1						>
	;
	; Handle a disconnect request in the queue.
	; 	si = lptr IrlmpEndpoint
	;	cx:dx = data args from queue
	;	ds:di = IrlmpEndpoint
	;
	call	TTPTxQueueFlush

        mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl

	mov	bx, IDR_USER_REQUEST	
	call	IrlmpDisconnectRequest

	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint
	jmp	exit
TTPCheckTxQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPGetDeltaCreditFromPDU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the delta credit from a TTP Data PDU, turning it
		into client data.

CALLED BY:	TTPIrlmpDataIndication
PASS:		cx:dx	= IrlmpDataArgs with TTP data PDU
RETURN:		cx:dx	= IrlmpDataArgs adjusted to data for client
			If client data size is 0, then data block is
			freed.
		al	= delta credit
		bx	= data size
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPGetDeltaCreditFromPDU	proc	near
	uses	cx,dx,ds,si,di
	.enter
	;
	; Grab the incoming delta credit from the data
	;
	movdw	dssi, cxdx			;ds:si = IrlmpDataArgs

EC <	tst	ds:[si].IDA_dataSize					>
EC <	ERROR_Z IRLMP_TINY_TP_INVALID_DATA_PDU				>

	mov	dx, ds:[si].IDA_dataOffset	;get offset before changing it
	dec	ds:[si].IDA_dataSize	
	inc	ds:[si].IDA_dataOffset

	mov	cx, ds:[si].IDA_dataSize	
	movdw	bxdi, ds:[si].IDA_data		;^lbx:di = buffer

	push	bx, di
	call	HugeLMemLock			;ax = segment of buffer
	
	mov	ds, ax
	mov	di, ds:[di]
	add	di, dx
	
	mov	al, ds:[di]			;al = delta credit
	andnf	al, 127				;ignore M bit.
	
	pop	bx, di				;^lbx:di = buffer
	call	HugeLMemUnlock
	
	jcxz	freeData
	mov	bx, cx				;return size in bx
exit:
	.leave
	ret
freeData:
	push	ax				;save delta credit
	movdw	axcx, bxdi			;^lax:cx = buffer
	call	HugeLMemFree
	pop	ax				;al = delta credit
	clr	bx				;return size = 0
	jmp	exit

TTPGetDeltaCreditFromPDU	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPCheckCredit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if we should advance more credits to the remote.
		If so, advance credits in a dataless Data TTP-PDU.

CALLED BY:	TTPIrlmpDataIndication
PASS:		ds:di	= IrlmpEndpoint.  Must be connected.
		si	= client handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPCheckCredit	proc	near
dataArgs	local	IrlmpDataArgs
	uses	ax,bx,cx,dx,si,di,bp
	.enter

if 0
; Advance credit whenever available, rather than waiting to go above 
; the low credit threshold.
	cmp	ds:[di].IE_remoteCredit, TTP_LOW_CREDIT_THRESHOLD
	ja	exit
endif

	cmp	ds:[di].IE_availCredit, 0
	jz	exit

	mov	ss:[dataArgs].IDA_dataSize, 0
	mov	cx, ss
	lea	dx, ss:[dataArgs]		;cx:dx = IrlmpDataArgs

	call	TTPDetermineCreditToAdvance	;ax = credits to advance

        mov	bx, ds:[LMBH_handle]
	call	MemUnlockExcl

	call	TTPMakePDU
	call	IrlmpDataRequest	
EC <	ERROR_C		-1					>
	;
	; Get the endpoint again.  
	;
	call	UtilsGetEndpointLockedExcl	;ds:di = IrlmpEndpoint
	
exit:	
	.leave
	ret
TTPCheckCredit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPDetermineCreditToAdvance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine credit available to advance to peer

CALLED BY:	TTPCheckCredit
PASS:		ds:di	= IrlmpEndpoint
RETURN:		ax	= credit to advance (<= 127)
		ds:di	= IrlmpEndpoint
			IE_availCredit = remaining available credit.
			IE_remoteCredit = ajusted to include credit to advance
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPDetermineCreditToAdvance	proc	near
	.enter
	clr	ax
	xchg	ax, ds:[di].IE_availCredit
	cmp	ax, 127
	jbe	gotCredit

	sub	ax, 127
	mov	ds:[di].IE_availCredit, ax
	mov	ax, 127

gotCredit:
	;
	; ax = credit to advance to peer (<= 127)
	;
	add	ds:[di].IE_remoteCredit, ax
	.leave
	ret
TTPDetermineCreditToAdvance	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPGetDataRequestSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the size of data args

CALLED BY:	TTPDataRequest
PASS:		cx:dx	= IrlmpDataArgs or IrlmpConnectArgs
RETURN:		ax	= IrlmpDataArgs.IDA_dataSize
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPGetDataRequestSize	proc	near
	uses	ds,si
	.enter
	movdw	dssi, cxdx
	mov	ax, ds:[si].IDA_dataSize
	.leave
	ret
TTPGetDataRequestSize	endp
