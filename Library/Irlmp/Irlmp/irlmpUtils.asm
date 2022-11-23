COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		irlmpUtils.asm

AUTHOR:		Chung Liu, Mar 17, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95   	Initial revision


DESCRIPTION:
	Utilities for Irlmp module
		

	$Id: irlmpUtils.asm,v 1.1 97/04/05 01:07:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlmpCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUCallEndpoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the endpoint's callback, or pass the indication or
		confirmation to TinyTP.

CALLED BY:	INTERNAL
PASS:		di	= IrlmpIndicationOrConfirmation
		si	= lptr of IrlmpEndpoint
		other regs depend on di
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUCallEndpoint	proc	far
indication	local	IrlmpIndicationOrConfirmation	push di
callback	local	vfptr
extraWord	local	word
	uses	bx
	.enter
	push	ds
	call	UtilsGetEndpointLocked		;ds:di = IrlmpEndpoint
	movdw	ss:[callback], ds:[di].IE_callback, bx
	mov	bx, ds:[di].IE_extraWord
	mov	ss:[extraWord], bx

	; Check if this is a TinyTP endpoint
	test	ds:[di].IE_flags, mask IEF_TINY_TP
						;Z set if not TinyTP

	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared			;flags preserved
	pop	ds			

	jnz	ttpCallback		

	pushdw	ss:[callback]
	mov	bx, ss:[extraWord]
	mov	di, ss:[indication]
	call	PROCCALLFIXEDORMOVABLE_PASCAL

exit:
	.leave
	ret

ttpCallback:
	call	TTPIrlmpCallback
	jmp	exit
IUCallEndpoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPIrlmpCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle Irlmp callback for TinyTP.

CALLED BY:	IUCallEndpoint
PASS:		ss:bp	= inherited frame
				indication	= IrlmpIndicationOrConfirmation
				callback	= vptr endpoint callback
				extraWord	= word
		other regs depend on ss:indication
		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/19/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPIrlmpCallback	proc	near
	uses	bx
	.enter inherit IUCallEndpoint
	
	Assert	stackFrame, bp

	mov	di, ss:[indication]

	cmp	di, IIC_DATA_INDICATION
	jne	checkConnectIndication

	call	TTPIrlmpDataIndication		
	jc	exit
	mov	di, TTPIC_DATA_INDICATION
	jmp	callIt

checkConnectIndication:
	cmp	di, IIC_CONNECT_INDICATION
	jne	checkConnectConfirmation

	call	TTPIrlmpConnectIndication

	mov	di, TTPIC_CONNECT_INDICATION
	jmp	callIt

checkConnectConfirmation:
	cmp	di, IIC_CONNECT_CONFIRMATION
	jne	checkStatus

	call	TTPIrlmpConnectConfirmation

	mov	di, TTPIC_CONNECT_CONFIRMATION
	jmp	callIt

checkStatus:
	cmp	di, IIC_STATUS_CONFIRMATION
	jne	checkDisconnect

	call	TTPIrlmpStatusConfirmation

	mov	di, TTPIC_STATUS_CONFIRMATION
	jmp	callIt

checkDisconnect:
	cmp	di, IIC_DISCONNECT_INDICATION
	jne	callIt

	call	TTPIrlmpDisconnectIndication
	mov	di, TTPIC_DISCONNECT_INDICATION

callIt:

	pushdw	ss:[callback]
	mov	bx, ss:[extraWord]
	call	PROCCALLFIXEDORMOVABLE_PASCAL
exit:

	.leave
	ret
TTPIrlmpCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpDisconnectIndicationNoData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue LM_Disconnect.indication with no data.

CALLED BY:	(EXTERNAL) 	LFDisconnectIndication
				LFConnectRequestConnect
PASS:		si	= lptr IrlmpEndpoint
		al	= IrlmpDisconnectReason
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpDisconnectIndicationNoData	proc	far
dataArgs	local	IrlmpDataArgs
	uses	cx, dx
	.enter
	mov	cx, ss
	lea	dx, ss:[dataArgs]
	mov	ss:[dataArgs].IDA_dataSize, 0
	call	IrlmpDisconnectIndication
	.leave
	ret
IrlmpDisconnectIndicationNoData	endp

IrlmpCode	ends
