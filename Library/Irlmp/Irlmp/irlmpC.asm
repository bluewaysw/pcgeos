COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Irlmp
FILE:		irlmpC.asm

AUTHOR:		Andy Chiu, Mar  6, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 6/96   	Initial revision


DESCRIPTION:
	C stubs for the Irlmp routines
		

	$Id: irlmpC.asm,v 1.1 97/04/05 01:07:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

IrlmpCode	segment


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpRegister

C DECLARATION:
IrlmpError
_pascal IrlmpRegister(IrlmpLsapSel *lsapSel, word extraData, 
		      PCB(void callback, (ClientHandle client,
					  IrlmpIndicationOrConfirmation type,
					  word extra,
					  dword data, 
					  word status)),
		      ClientHandle *clientHandle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPREGISTER	proc	far	lsapSel:fptr,
				extraData:word,
				callback:vfptr,
				client:fptr
		uses	si,di,ds
		.enter

		Assert	fptr	client;
		Assert	fptr	lsapSel;
	;
	; Save data in the extra block
	;
		mov	bx, extraData
		les	di, lsapSel
		mov	cl, es:[di]
		mov	dx, vseg @CurSeg
		mov	ax, offset _IRLMPREGISTER_callback
		call	IrlmpRegister	; ax <- return value
		jc	exit

		mov	{byte} es:[di], cl	; return LsapSel
		les	di, client
		mov	{word} es:[di], si	; return client handle

		call	UtilsGetEndpointLocked	; ds:di <- IrlmpEndpoint
		movdw	ds:[di].IE_callbackC, callback, si
		mov	bx, ds:[LMBH_handle]
		call	MemUnlockShared
		
exit:		
		.leave
		ret
IRLMPREGISTER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_IRLMPREGISTER_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for IrlmpRegister so it can
		call the C callback

CALLED BY:	IrlmpRegister
PASS:		si	= client handle
		di	= IrlmpIndicationOrConfirmation
		bx	= extra word
		Other registers depend on di
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Callback looks like this:

		      PCB(void callback, (ClientHandle client,
					  IrlmpIndicationOrConfirmation type,
					  word extra,
					  dword data, 
					  word status));
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_IRLMPREGISTER_callback	proc	far
		uses	ax,bx,cx,dx,bp,si,di,ds,es
		.enter

	;
	; In order to consolidate all the parameters that come via
	; the callback, we're going to check what the indication/confirmation
	; is and put it in the parameters.
	;
		clr	bp		; default param
		jmp	cs:indConfTable[di]

	;
	; To make sure all the parameters get push'd, all the
	; sub routines here put the dword parameter in cx:dx
	; and the single word parameter in bp
	;
		
discoverConfirm:
		clr	dh
		mov	bp, dx
discover:
		mov	cx, ds:[LMBH_handle]
		mov_tr	dx, ax
		jmp	pushParams		

disconnect:
		clr	ah
		mov_tr	bp, ax
		jmp	pushParams
getValue:
		clr	dh
		mov	bp, dx
		mov	ss:[TPD_error], ax
		mov	cx, ds:[LMBH_handle]
		mov_tr	dx, ax
		jmp	pushParams
status:
		mov	bp, cx
		clr	cx, dx
data:
connect:
pushParams:
	;
	; Push the parameters on the stack
	;
		push	si
		push	di
		push	bx
		pushdw	cxdx		; dword parameter
		push	bp		; single word paramter
	;
	; Find the callback in the endpoint block.  Push
	; it on the stack.
	;
		call	UtilsGetEndpointLocked	; ds:di <- endpoint
						; *ds:si <- endpoint
		pushdw	ds:[di].IE_callbackC

		mov	bx, ds:[LMBH_handle]
		call	MemUnlockShared
		
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		.leave
		ret

indConfTable	word \
	discover,		; IIC_DISCOVER_DEVICES_INDICATION
	discoverConfirm,	; IIC_DISCOVER_DEVICES_CONFIRMATION
	connect,		; IIC_CONNECT_INDICATION
	connect,		; IIC_CONNECT_CONFIRMATION	
	disconnect,		; IIC_DISCONNECT_INDICATION
	status,			; IIC_STATUS_INDICATION
	status, 		; IIC_STATUS_CONFIRMATION
	data,			; IIC_DATA_INDICATION	
	data,			; IIC_UDATA_INDICATION	
	getValue,		; IIC_GET_VALUE_BY_CLASS_CONFIRMATION
	connect,		; TTPIC_CONNECT_INDICATION
	connect,		; TTPIC_CONNECT_CONFIRMATION
	disconnect,		; TTPIC_DISCONNECT_INDICATION	
	data, 			; TTPIC_DATA_INDICATION
	status			; TTPIC_STATUS_CONFIRMATION

		
CheckHack<size indConfTable eq TinyTPIndicationOrConfirmation>
		
_IRLMPREGISTER_callback	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpUnregister

C DECLARATION:	
	IrlmpError
	  _pascal IrlmpUnregister(ClientHandle client);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPUNREGISTER	proc	far
		C_GetOneWordArg	cx, ax, dx	; cx <- client handle
	;
	; Before we call the real routine, we need to get the
	; mem handle of the block we stored the extra data, so
	; we can free it.
	;
		uses	si
		.enter

		mov	si, cx			; si <- client handle
		call	IrlmpUnregister

		.leave
		ret
IRLMPUNREGISTER	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpDiscoverDevicesRequest

C DECLARATION:	
IrlmpError
_pascal IrlmpDiscoverDevicesRequest(ClientHandle client, word timeSlot);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPDISCOVERDEVICESREQUEST	proc	far
		.enter

		C_GetTwoWordArgs	cx, bx, ax, dx
						; ci <- client handle
						; bl <- IrlapUserTimeSlot
		push	si
		mov	si, cx			; si <- client handle
		call	IrlmpDiscoverDevicesRequest
		pop	si
		jc	error
		
exit:
		.leave
		ret
error:
		mov	ax, TRUE
		jmp	exit
IRLMPDISCOVERDEVICESREQUEST	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpConnectRequest

C DECLARATION:	
	IrlmpError
	  _pascal IrlmpConnectRequest(ClientHandle client,
					IrlmpConnectArgs *connectArgs);	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPCONNECTREQUEST	proc	far
		.enter

		C_GetThreeWordArgs	bx, cx, dx, ax
					; bi <- client handle
					; cx:dx <- IrlmpDataArgs
		push	si
		mov	si, bx
		call	IrlmpConnectRequest
		pop	si
		
		.leave
		ret
IRLMPCONNECTREQUEST	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpConnectResponse

C DECLARATION:	
IrlmpError
_pascal IrlmpConnectResponse(ClientHandle client, IrlmpDataArgs *dataArgs);
	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPCONNECTRESPONSE	proc	far
		.enter

		C_GetThreeWordArgs	bx, cx, dx, ax
					; bx <- client handle
					; cx:dx <- IrlmpDataArgs

		push	si
		mov	si, bx
		call	IrlmpConnectResponse
		pop	si
		
		.leave
		ret
IRLMPCONNECTRESPONSE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpDisconnectRequest

C DECLARATION:	IrlmpError
		_pascal IrlmpDisconnectRequest(ClientHandle client, IrlmpDataArgs *dataArgs, word reason);	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPDISCONNECTREQUEST	proc	far	client:word,
					dataArgs:fptr,
					reason:word
		.enter

		mov	si, client
		movdw	cxdx, dataArgs
		mov	bx, reason
		call	IrlmpDisconnectRequest
		
		.leave
		ret
IRLMPDISCONNECTREQUEST	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpStatusRequest

C DECLARATION:	
	IrlmpError
	   _pascal IrlmpStatusRequest(ClientHandle client);
	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPSTATUSREQUEST	proc	far
		.enter

		C_GetOneWordArg	bx, ax, cx	; bx <- client handle

		push	si
		mov	si, bx
		call	IrlmpStatusRequest
		pop	si
		
		.leave
		ret
IRLMPSTATUSREQUEST	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpDataRequest

C DECLARATION:
     IrlmpError
	_pascal IrlmpDataRequest(ClientHandle client, IrlmpDataArgs *dataArgs);
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPDATAREQUEST	proc	far
		.enter

		C_GetThreeWordArgs	bx, cx, dx, ax
					; bx <- client handle
					; cx:dx <- IrlmpDataArgs

		push	si
		mov	si, bx
		call	IrlmpDataRequest
		pop	si

		.leave
		ret
IRLMPDATAREQUEST	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpUDataRequest

C DECLARATION:	
  IrlmpError
   _pascal IrlmpUDataRequest(ClientHandle client, IrlmpDataArgs *dataArgs);
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPUDATAREQUEST	proc	far
		.enter

		C_GetThreeWordArgs	bx, cx, dx, ax
					; bx <- client handle
					; cx:dx <- IrlmpDataArgs
		push	si
		mov	si, bx
		call	IrlmpUDataRequest
		pop	si
		
		.leave
		ret
IRLMPUDATAREQUEST	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpGetPacketSize

C DECLARATION:	
	word
	  _pascal IrlmpGetPacketSize(IrlmpParamDataSize dataSize);	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPGETPACKETSIZE	proc	far
		.enter

		C_GetOneWordArg	ax, cx, dx	; ax <- dataSize
		call	IrlmpGetPacketSize	; cx <- size
		mov_tr	ax, cx
		
		.leave
		ret
IRLMPGETPACKETSIZE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpDisconnectIas

C DECLARATION:	
	Boolean
	  _pascal IrlmpDisconnectIas(ClientHandle client);	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPDISCONNECTIAS	proc	far
		.enter

		C_GetOneWordArg	bx, ax, dx	; si <- client handle
		push	si
		mov	si, bx
		call	IrlmpDisconnectIas
		pop	si

		.leave
		ret
IRLMPDISCONNECTIAS	endp

FXIP <	IrlmpCode	ends			>
FXIP <  ResidentXIP	segment resource	>

COMMENT @----------------------------------------------------------------------

C FUNCTION:	IrlmpGetValueByClassRequest

C DECLARATION:	
	IrlmpError
	  _pascal IrlmpGetValueByClassRequest(ClientHandle client, 
				    IrlmpGetValueByClassRequestArgs *dataArgs);
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Write the sizes of the strings to the buffer
	Copy the class name to the buffer.
	Copy the attribute name to the buffer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
IRLMPGETVALUEBYCLASSREQUEST	proc	far
		C_GetThreeWordArgs	bx, cx, dx, ax
					; bx <- client handle
					; cx:dx <- dataArgs
		uses	si
		.enter

		mov	si, bx
		call	IrlmpGetValueByClassRequest

		.leave
		ret
IRLMPGETVALUEBYCLASSREQUEST	endp

FXIP <  ResidentXIP	ends			>
NOFXIP<	IrlmpCode	ends			>

	SetDefaultConvention






