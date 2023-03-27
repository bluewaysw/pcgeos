COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		irlmpCallback.asm

AUTHOR:		Chung Liu, Mar 15, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial revision


DESCRIPTION:
	Routines to call the IrLMP callback with confirmations and
	indications.
		

	$Id: irlmpCallback.asm,v 1.1 97/04/05 01:07:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlmpCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpConnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IIC_CONNECT_INDICATION

CALLED BY:	(EXTERNAL) LFConnectConfirmConnectPend
PASS:		si	= lptr of IrlmpEndpoint
		cx:dx	= IrlmpConnectArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpConnectIndication	proc	far
	uses	ds,si,es,di
	.enter
	push	si
	call	UtilsGetQOS			;ds:si = QualityOfService
	clr	ds:[si].QOS_flags
	movdw	esdi, cxdx			;es:di = IrlmpConnectArgs
	add	di, offset ICA_QoS		;es:di = QOS arg
	mov	cx, size QualityOfService
	rep	movsb

	mov	cx, es				;cx:dx = IrlmpConnectArgs
	mov	di, IIC_CONNECT_INDICATION
	pop	si
	call	IUCallEndpoint
	.leave
	ret
IrlmpConnectIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpConnectConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IIC_CONNECT_CONFIRMATION

CALLED BY:	(EXTERNAL) LFConnectConfirmPDU
PASS:		si	= lptr of IrlmpEndpoint
		cx:dx	= IrlmpConnectArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpConnectConfirm	proc	far
	uses	ds,si,es,di
	.enter
	push	si				;save endpoint
	;
	; Obtain QOS from Irlap_Connect.confirm.
	;
	call	UtilsGetQOS			;ds:si = QualityOfService
	;
	; Clear defaults flag
	;
	clr	ds:[si].QOS_flags
	movdw	esdi, cxdx			;es:di = IrlmpConnectArgs
	add	di, offset ICA_QoS		;es:di = QOS arg
	mov	cx, size QualityOfService
	rep	movsb

	mov	cx, es				;cx:dx = IrlmpConnectArgs

	mov	di, IIC_CONNECT_CONFIRMATION
	pop	si				;di = lptr IrlmpEndpoint
	call	IUCallEndpoint
	.leave
	ret
IrlmpConnectConfirm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpDisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IIC_DISCONNECT_INDICATION.
		Call the client with disconnect indication.

CALLED BY:	(EXTERNAL) LFDisconnectPDU
			   IrlmpDisconnectIndicationNoData
PASS:		si	= lptr of IrlmpEndpoint
		al	= IrlmpDisconnectReason
		cx:dx	= IrlmpDataArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpDisconnectIndication	proc	far
	uses	di
	.enter
EC <	WARNING	IRLMP_DISCONNECT_INDICATION			>
	mov	di, IIC_DISCONNECT_INDICATION
	call	IUCallEndpoint
	.leave
	ret
IrlmpDisconnectIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpStatusIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IIC_STATUS_INDICATION

CALLED BY:	(EXTERNAL)
PASS:		si	= lptr of IrlmpEndpoint
		cx	= IrlapStatusIndicationType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpStatusIndication	proc	far
	uses	di
	.enter
	mov	di, IIC_STATUS_INDICATION
	call	IUCallEndpoint
	.leave
	ret
IrlmpStatusIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpStatusConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IIC_STATUS_CONFIRMATION

CALLED BY:	(EXTERNAL)
PASS:		si	= lptr of IrlmpEndpoint
		cx	= ConnectionStatus
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpStatusConfirm	proc	far
	uses	di
	.enter
	mov	di, IIC_STATUS_CONFIRMATION
	call	IUCallEndpoint
	.leave
	ret
IrlmpStatusConfirm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IIC_DATA_INDICATION

CALLED BY:	(EXTERNAL)
PASS:		si	= lptr of IrlmpEndpoint
		cx:dx	= IrlmpDataArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpDataIndication	proc	far
	uses	di
	.enter
	mov	di, IIC_DATA_INDICATION
	call	IUCallEndpoint
	.leave
	ret
IrlmpDataIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpUDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IIC_UDATA_INDICATION

CALLED BY:	(EXTERNAL)
PASS:		si	= lptr of IrlmpEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpUDataIndication	proc	far
	uses	di
	.enter
	mov	di, IIC_UDATA_INDICATION
	call	IUCallEndpoint
	.leave
	ret
IrlmpUDataIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpDiscoverConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IIC_DISCOVER_DEVICES_CONFIRMATION

CALLED BY:	(EXTERNAL) SFDiscoverRequestReady
			   SFDiscoverConfirmDiscover
PASS:		si	= lptr of IrlmpEndpoint
		dl	= IrlmpDiscoveryStatus
		*ds:ax	= chunk array of DiscoveryLog.  Not valid after
			  callback exits.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpDiscoverConfirm	proc	far
	uses	di
	.enter
	mov	di, IIC_DISCOVER_DEVICES_CONFIRMATION
	call	IUCallEndpoint
	.leave
	ret
IrlmpDiscoverConfirm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpDiscoverIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IIC_DISCOVER_DEVICES_INDICATION

CALLED BY:	(EXTERNAL)
PASS:		si	= lptr of IrlmpEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpDiscoverIndication	proc	far
	uses	di
	.enter
	mov	di, IIC_DISCOVER_DEVICES_INDICATION
	call	IUCallEndpoint
	.leave
	ret
IrlmpDiscoverIndication	endp

IrlmpCode	ends
