COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasServerCallback.asm

AUTHOR:		Andy Chiu, Dec 14, 1995

ROUTINES:
	Name			Description
	----			-----------
	IasServerCallback
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95   	Initial revision


DESCRIPTION:
	
		

	$Id: iasServerCallback.asm,v 1.1 97/04/05 01:07:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IasCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IasServerCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for the IAS Server FSM endpoint

CALLED BY:	Irlap Driver
PASS:		di	= IrlmpIndicationOrConfirmation
				IIC_CONNECT_INDICATION
				IIC_DISCONNECT_INDICATION
				IIC_DATA_INDICATION
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Since all connect args are being passed to us on the irlmp
	thread and we want our server to run on it`s own thread,
	we're going to copy the arguments and pass it to our
	ServerFsm via MF_STACK


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IasServerCallback	proc	far
		uses	ax,bx,cx,dx,ds,si,es,di,bp
		.enter

		cmp	di, IIC_CONNECT_INDICATION
		jz	connectIndication
		
		cmp	di, IIC_DISCONNECT_INDICATION	
		jz	disconnectIndication

		cmp	di, IIC_DATA_INDICATION
		jz	dataIndication

EC <		cmp	di, IIC_STATUS_INDICATION			>
EC <		jz	exit						>
		
EC <		ERROR_NE IRLMP_IAS_UNEXPECTED_INDICATION_OR_CONFIRMATION >
NEC<		jmp	exit					>

connectIndication:
	;
	; Copy the IrlmpConnectArgs to the stack so we can pass it
	; to our new thread.
	;
		mov	ax, MSG_ISF_LM_CONNECT_INDICATION
		mov	di, size IrlmpConnectArgs
		jmp	sendServer
		
disconnectIndication:
		call	IUFreeDataArgs
		mov	ax, MSG_ISF_LM_DISCONNECT_INDICATION
		mov	di, size IrlmpDataArgs
		jmp	sendServer
		
dataIndication:
		mov	ax, MSG_ISF_LM_DATA_INDICATION
		mov	di, size IrlmpDataArgs
		jmp	sendServer
	;
	; When execution drops here, we expect the following
	; parameters to be set.
	; cx:dx	= data args
	; ax    = Message # to send
	; si 	= client endpoint
	; di    = size of data args
	;
sendServer:
		sub	sp, di
		mov	bp, sp
		push	si			; #1 save client endpoint 
		push	di			; #2 save size of data args

		movdw	esdi, ssbp
		movdw	dssi, cxdx		; ds:si <- args

		pop	dx			; #2 dx <- size of args
		mov	cx, dx			; cx <- size of args
		rep	movsb			; copy data

		pop	si			; #1 si <- client endpoint
		
		call	IasServerFsmSendOnStack

		add	sp, dx			; restore stack
exit::
		.leave
		ret
IasServerCallback	endp

IasCode	ends

