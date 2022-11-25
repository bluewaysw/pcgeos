COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		irlapRequest.asm

AUTHOR:		Chung Liu, Mar 15, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial revision


DESCRIPTION:
	Routines to call the IrLAP Driver with requests.

	$Id: isapRequest.asm,v 1.1 97/04/05 01:07:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsapCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue IrLAP_Data.request to IrLAP Driver

CALLED BY:	(EXTERNAL) LFDataRequest
PASS:		cx	= number of bytes to send
		si	= offset into the buffer
		dxax	= user data buffer ( HugeLMem optr )
if GENOA_TEST
		bx	= IrlmpDataArgFlag
endif

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapDataRequest	proc	far
	uses	ax,si,di,bp
	.enter
EC <	WARNING	IRLMP_IRLAP_DATA_REQUEST			>
if GENOA_TEST
	;
	; I am adding this solely for testing purpose.
	;						- SJ
	;
		test	bx, mask IDAF_SUSPEND_IRLAP
		jz	skipSusp
		mov	di, DR_SUSPEND
		call	IUCallIrlap
skipSusp:
endif
		
	mov	bp, ax				;^ldx:bp = HugeLMem data
	mov	ax, si				;ax = offset into buffer
	clr	si
	mov	di, NIR_DATA_REQUEST
	call	IUCallIrlap

if GENOA_TEST
	;
	; I am adding this solely for testing purpose.
	;						- SJ
	;
		test	bx, mask IDAF_UNSUSPEND_IRLAP
		jz	skipUnsusp
		mov	di, DR_UNSUSPEND
		call	IUCallIrlap
skipUnsusp:
endif
	.leave
	ret
IsapDataRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapExpeditedDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expedited and unreliable IrLAP_Data.request.

CALLED BY:	(EXTERNAL) LFUDataRequest
PASS:		cx	= number of bytes to send
		si	= offset into the buffer
		dxax	= user data buffer ( HugeLMem optr )
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapExpeditedDataRequest	proc	far
	uses	ax,si,di,bp
	.enter
	mov	bp, ax				;^ldx:bp = HugeLMem data
	mov	ax, si				;ax = offset into buffer
	mov	si, mask IDRT_EXPEDITED
	mov	di, NIR_DATA_REQUEST or IRLAP_URGENT_REQUEST_MASK
	call	IUCallIrlap
	.leave
	ret
IsapExpeditedDataRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapUnitDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue IrLAP_UnitData.request to IrLAP Driver

CALLED BY:	(EXTERNAL)
PASS:		cx	= number of bytes to send
		si	= offset into the buffer
		dxax	= user data buffer ( HugeLMem optr )
RETURN:		carry set on error
		di	= IrlapError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapUnitDataRequest	proc	far
	uses	di, bp
	.enter
	mov	bp, ax				;^ldx:bp = HugeLMem data
	mov	di, NIR_UNITDATA_REQUEST
	call	IUCallIrlap
	.leave
	ret
IsapUnitDataRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue IrLAP_Connect.request to IrLAP Driver

CALLED BY:	(EXTERNAL)
PASS:		ax	= IrlapConnectionFlags
		cxdx	= 32-bit IrLAP address
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapConnectRequest	proc	far
	uses	ds,si,di
	.enter
	;
	; Get the QOS arguments originally passed in by the user when
	; IrlmpConnect was called.
	;
	call	UtilsGetRequestedQOS		;ds:si = QualityOfService

	movdw	ds:[si].QOS_devAddr, cxdx

	push	bp, cx
	mov	di, NIR_CONNECT_REQUEST		;trashes bp, cx
	call	IUCallIrlap
	pop	bp, cx
	.leave
	ret
IsapConnectRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapConnectResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue IrLAP_Connect.response to IrLAP Driver

CALLED BY:	(EXTERNAL) IFConnectIndication
PASS:		cxdx	= 32-bit IrLAP address
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapConnectResponse	proc	far
	uses	ds,si,di
	.enter
	;
	; Respond with default QOS params.
	;
	call	UtilsGetRequestedQOS		;ds:si = QualityOfService
	ornf	ds:[si].QOS_flags, mask QOSF_DEFAULT_PARAMS
	movdw	ds:[si].QOS_devAddr, cxdx

	push	bp, cx
	mov	di, NIR_CONNECT_RESPONSE
	call	IUCallIrlap			;trashes cx, bp
	pop	bp, cx
	.leave
	ret
IsapConnectResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue IrLAP_Disconnect.request to IrLAP Driver

CALLED BY:	(EXTERNAL) SFIrlapConnectIndication, IFResetIndication
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapDisconnectRequest	proc	far
	uses	di
	.enter
EC <	WARNING IRLMP_IRLAP_DISCONNECT_REQUEST			>
	mov	di, NIR_DISCONNECT_REQUEST
	call	IUCallIrlap
	.leave
	ret
IsapDisconnectRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapStatusRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue IrLAP_Status.request to IrLAP Driver

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapStatusRequest	proc	far
	uses	di
	.enter
	mov	di, NIR_STATUS_REQUEST
	call	IUCallIrlap
	.leave
	ret
IsapStatusRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapNewAddressRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue IrLAP_NewAddress.request to IrLAP Driver

CALLED BY:	(EXTERNAL)
PASS:		bl	= IrlapUserTimeSlot
		dxax	= 32-bit IrLAP Address.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapNewAddressRequest	proc	far
	uses	cx,di,bp
	.enter
	mov	cx, bx				;cl = IrlapUserTimeSlot
	mov	bp, ax				;dxbp = address
	mov	ch, IDT_ADDRESS_RESOLUTION
	mov	di, NIR_DISCOVERY_REQUEST
	call	IUCallIrlap
	.leave
	ret
IsapNewAddressRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapDiscoverRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue IrLAP_Discover.request to the IrLAP Driver

CALLED BY:	(EXTERNAL) SFDiscoverRequestReady
PASS:		bl	= IrlapUserTimeSlot
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapDiscoverRequest	proc	far
	uses	es,bx,cx
	.enter
	mov	di, NIR_DISCOVERY_REQUEST
	mov	cx, bx				;cl = IrlapUserTimeSlot
	mov	ch, IDT_DISCOVERY
	call	IUCallIrlap
	.leave
	ret
IsapDiscoverRequest	endp

IsapCode	ends
