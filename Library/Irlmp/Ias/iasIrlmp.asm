COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasIrlmp.asm

AUTHOR:		Chung Liu, May  2, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 2/95   	Initial revision


DESCRIPTION:
	Irlmp interface for IAS
		

	$Id: iasIrlmp.asm,v 1.1 97/04/05 01:07:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IasCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IasIrlmpCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for the IAS Client FSM endpoint.

CALLED BY:	IUCallEndpoint
PASS:		di	= IrlmpIndicationOrConfirmation
				IIC_DISCONNECT_INDICATION
				IIC_CONNECT_CONFIRM
				IIC_DATA_INDICATION
		other args depend on di
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IasIrlmpCallback	proc	far
	uses	ax,bx,di,si
	.enter
	cmp	di, IIC_CONNECT_CONFIRMATION
	je	connectConfirm
	cmp	di, IIC_DISCONNECT_INDICATION
	je	disconnectIndication
	cmp	di, IIC_DATA_INDICATION
	je	dataIndication
	cmp	di, IIC_STATUS_INDICATION
	je	exit
EC <	ERROR_NE IRLMP_IAS_UNEXPECTED_INDICATION_OR_CONFIRMATION 	>
NEC <	jmp	exit							>

connectConfirm:
	;
	; cx:dx	= IrlmpConnectArgs
	;
	mov	ax, MSG_ICF_LM_CONNECT_CONFIRM
	jmp	callClientFsm

disconnectIndication:
	;
	; cx:dx	= IrlmpDataArgs
	;
	mov	ax, MSG_ICF_LM_DISCONNECT_INDICATION
	jmp	callClientFsm

dataIndication:
	;
	; cx:dx = IrlmpDataArgs
	;
	mov	ax, MSG_ICF_LM_DATA_INDICATION
callClientFsm:
	push	cx, dx		; save IrlmpConnectArgs/IrlmpDataArgs
	mov	di, mask MF_CALL
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage
	pop	cx, dx		; cx:dx = IrlmpConnectArgs/IrlmpDataArgs

	CheckHack <IDA_data eq ICA_data>
	call	IUFreeDataArgs
exit:	
	.leave
	ret
IasIrlmpCallback	endp

IasCode		ends
