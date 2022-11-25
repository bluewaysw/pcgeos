COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Irlmp
MODULE:		Ttp
FILE:		ttpC.asm

AUTHOR:		Andy Chiu, May  7, 1996

METHODS:
	Name				Description
	----				-----------
	

ROUTINES:
	Name				Description
	----				-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 7/96   	Initial revision


DESCRIPTION:
	C stubs for the tiny TP routines
		

	$Id: ttpC.asm,v 1.1 97/04/05 01:07:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention


COMMENT @----------------------------------------------------------------------

C FUNCTION:	TtpRegister

C DECLARATION:

IrlmpError
_pascal TTPRegister(IrlmpLsapSel *lsapSel, word extraData, 
		      PCB(void, callback, (ClientHandle client,
					   IrlmpIndicationOrConfirmation type,
					   word extra,
					   dword data, 
					   word status)),
		      ClientHandle *clientHandle);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 7/96		Initial Revision

------------------------------------------------------------------------------@
TTPREGISTER	proc	far	lsapSel:fptr,
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
		mov	dx, vseg IrlmpCode
		mov	ax, offset _IRLMPREGISTER_callback
		call	TTPRegister	; ax <- return value
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
TTPREGISTER	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	TtpUnregister

C DECLARATION:	IrlmpError
		_pascal TTPUnregister(ClientHandle client);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 7/96		Initial Revision

------------------------------------------------------------------------------@
TTPUNREGISTER	proc	far
		C_GetOneWordArg	cx, ax, dx	; cx <- client handle
	;
	; Before we call the real routine, we need to get the
	; mem handle of the block we stored the extra data, so
	; we can free it.
	;
		uses	si
		.enter

		mov	si, cx			; si <- client handle
		call	TTPUnregister

		.leave
		ret
TTPUNREGISTER	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	TTPConnectRequest

C DECLARATION:	IrlmpError
			_pascal TTPConnectRequest(ClientHandle client, IrlmpConnectArgs *connectArgs);
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 7/96		Initial Revision

------------------------------------------------------------------------------@
TTPCONNECTREQUEST	proc	far
		C_GetThreeWordArgs	bx, cx, dx, ax
					; bx <- client handle
					; cx:dx <- IrlmpDataArgs
		push	si
		mov	si, bx
		call	TTPConnectRequest
		pop	si

		ret
TTPCONNECTREQUEST	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	TTPConnectResponse

C DECLARATION:	IrlmpError
		_pascal TTPConnectResponse(ClientHandle client, IrlmpDataArgs *dataArgs);
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 7/96		Initial Revision

------------------------------------------------------------------------------@
TTPCONNECTRESPONSE	proc	far
		C_GetThreeWordArgs	bx, cx, dx, ax
					; bx <- client handle
					; cx:dx <- IrlmpDataArgs

		push	si
		mov	si, bx
		call	TTPConnectResponse
		pop	si

		ret
TTPCONNECTRESPONSE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	TTPDataRequest

C DECLARATION:	IrlmpError
		_pascal TTPDataRequest(ClientHandle client, IrlmpDataArgs *dataArgs);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 7/96		Initial Revision

------------------------------------------------------------------------------@
TTPDATAREQUEST	proc	far

		C_GetThreeWordArgs	bx, cx, dx, ax
					; bx <- client handle
					; cx:dx <- IrlmpDataArgs

		push	si
		mov	si, bx
		call	TTPDataRequest
		pop	si

		ret
TTPDATAREQUEST	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	TTPTxQueueGetFreeCount

C DECLARATION:	word
		_pascal TTPTxQueueGetFreeCount(ClientHandle client);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 7/96		Initial Revision

------------------------------------------------------------------------------@
TTPTXQUEUEGETFREECOUNT	proc	far
		C_GetOneWordArg	cx, ax, dx	; cx <- client handle		
		push	si
		mov	si, cx			; si <- client handle
		call	TTPTxQueueGetFreeCount
		mov_tr	ax, cx			; ax <- free count
		pop	si
		
		ret
TTPTXQUEUEGETFREECOUNT	endp
		

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TTPDisconnectRequest

C DECLARATION:	IrlmpError
		_pascal TTPDisconnectRequest(ClientHandle client,
					     IrlmpDataArgs *dataArgs);
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 7/96		Initial Revision

------------------------------------------------------------------------------@
TTPDISCONNECTREQUEST	proc	far	

		C_GetThreeWordArgs	bx, cx, dx, ax
					; bx <- client handle
					; cx:dx <- IrlmpDataArgs

		uses	si
		.enter

		mov	si, bx
		call	TTPDisconnectRequest

		.leave
		ret
TTPDISCONNECTREQUEST	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	TTPStatusRequest

C DECLARATION:	IrlmpError
		_pascal TTPStatusRequest(ClientHandle client);
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 7/96		Initial Revision

------------------------------------------------------------------------------@
TTPSTATUSREQUEST	proc	far
		C_GetOneWordArg	ax, cx, dx	; ax <- client handle

		uses	si
		.enter

		mov_tr	si, ax
		call	TTPStatusRequest

		.leave
		ret
TTPSTATUSREQUEST	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	TTPAdvanceCredit

C DECLARATION:	void
		_pascal TTPAdvanceCredit(ClientHandle client, word credits);
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	5/ 7/96		Initial Revision

------------------------------------------------------------------------------@
TTPADVANCECREDIT	proc	far
		C_GetTwoWordArgs	ax, cx, dx, bx
					; ax <- client handle
					; cx <- credits
		uses	si
		.enter

		mov_tr	si, ax		; si <- client handle
		
		call	TTPAdvanceCredit

		.leave
		ret
TTPADVANCECREDIT	endp
		
		
	SetDefaultConvention
