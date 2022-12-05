COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasConfirm.asm

AUTHOR:		Chung Liu, May 11, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/11/95   	Initial revision


DESCRIPTION:
	IAS call confirmations.
		
	$Id: iasConfirm.asm,v 1.1 97/04/05 01:07:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IasCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICCallConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out the appropriate IAS confirmation.

CALLED BY:	ICAOutstandingRecv
PASS:		cx:dx	= IrlmpDataArgs for IrlmpIasControlByte plus results.
		al 	= IrlmpIasControlByte
		bp	= client handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICCallConfirm	proc	near
	uses 	ax
	.enter
	andnf	al, mask IICB_OPCODE
	cmp	al, IIOC_GET_VALUE_BY_CLASS
	je	getValue
	
	jmp	exit
getValue:
	call	ICGetValueByClassConfirm
exit:
	.leave
	ret
ICCallConfirm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICGetValueByClassConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_GetValueByClass.confirm

CALLED BY:	ICCallConfirm
PASS:		cx:dx	= IrlmpDataArgs for IrlmpIasControlByte plus results.
		al 	= IIOC_GET_VALUE_BY_CLASS
		bp	= client handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICGetValueByClassConfirm	proc	near
clientHandle		local	word		push bp
hugeLMemBlock		local	hptr
dataPtr			local	dword
returnCode		local	byte
argsChunkArray		local	word		
	uses	ax,bx,cx,dx,ds,es,si,di
	.enter
	;	
	; Lock down the returned data
	;
	movdw	dsdi, cxdx
	movdw	bxax, ds:[di].IDA_data
	mov	cx, ds:[di].IDA_dataSize
	mov	si, ds:[di].IDA_dataOffset

	mov	di, ax				;^lbxdi = data buffer
	mov	ss:[hugeLMemBlock], bx		;save to unlock
	call	HugeLMemLock
	mov	ds, ax
	mov	di, ds:[di]			;ds:di = data buffer
	add	si, di				;ds:si = control byte + results
	
	lodsb					;al = control byte
	lodsb					;al = return code
	mov	ss:[returnCode], al
	cmp	al, IGVBCRC_SUCCESS
	jne	callConfirm			;query failed -- no results.

	movdw	ss:[dataPtr], dssi		;ds:si = list length
	;
	; Create a chunk array in the IAS FSM block, to return the results
	; of the query.
	;
	mov	bx, handle IrlmpIasClientFsm
	call	ObjLockObjBlock
	mov	ds, ax
	clr	ax, bx, cx, si
	call	ChunkArrayCreate		;*ds:si = array
	mov	ss:argsChunkArray, si		;save array chunk to free later

	movdw	esdi, ss:[dataPtr]
	mov	cx, es:[di]			;MSB order
	xchg	cl, ch				
	add	di, size word			;es:di = args

argsLoop:
	call	IUAppendArgToArray
	loop	argsLoop

callConfirm:
	mov	bx, ss:[hugeLMemBlock]
	call	HugeLMemUnlock

	mov	ax, si				;*ds:ax = chunk array
	mov	dl, ss:[returnCode]
	mov	si, ss:[clientHandle]
	call	IrlmpGetValueByClassConfirm

	cmp	ss:[returnCode], IGVBCRC_SUCCESS
	jne	exit

	mov	ax, ss:[argsChunkArray]
	mov	bx, handle IrlmpIasClientFsm
	call	MemDerefDS			; ds:ax <- chunk array
	call	LMemFree
	call	MemUnlock	
exit:
	.leave
	ret
ICGetValueByClassConfirm	endp

IasCode		ends

