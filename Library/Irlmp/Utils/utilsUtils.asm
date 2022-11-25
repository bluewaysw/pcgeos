COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		utilsUtils.asm

AUTHOR:		Chung Liu, Feb 24, 1995

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95   	Initial revision

DESCRIPTION:

	$Id: utilsUtils.asm,v 1.1 97/04/05 01:08:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and initialize endpoint and HugeLMem blocks.

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		if error (insufficient memory):
			carry set 
		else:
			carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsInit	proc	far
	.enter
	call	UEInitTable
	call	UPInit
	.leave
	ret
UtilsInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This should be called by the irlmp thread to clean
		up the endpoint block and it's general purpose
		hugeLMemBlock.

CALLED BY:	IrlmpMetaDetach
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsExit	proc	far
		uses	bx,ds
		.enter

	;
	; Destory the endpoint block
	;
		call	UtilsFreeEndpointTable		
	;
	; Destroy the HugeLMemBlock
	;
		call	UtilsLoadDGroupDS
		clr	bx
		xchg	bx, ds:[utilsHugeLMemBlock]
		tst	bx
		jz	exit

		call	HugeLMemDestroy
exit:
		.leave
		ret
UtilsExit	endp



InitCode	ends

UtilsCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsEndpointGetLsaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the source and destination LSAPs recorded in the
		endpoint.

CALLED BY:	(EXTERNAL) LFConnectConfirmSetupPend
PASS:		si	= lptr IrlmpEndpoint
RETURN:		bh	= destination IrlmpLsapSel
		bl	= source IrlmpLsapSel
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsEndpointGetLsaps	proc	far
	uses	ds, di
	.enter
	call	UtilsGetEndpointLocked		;ds:di = IrlmpEndpoint

	mov	bl, ds:[di].IE_lsapSel		;source LSAP-Sel
	mov	bh, ds:[di].IE_destLsapID.ILI_lsapSel	;dest LSAP-Sel

	push	bx
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared
	pop	bx
	.leave
	ret
UtilsEndpointGetLsaps	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsEndpointGetDestLsapID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the destination Lsap-ID of the endpoint

CALLED BY:	(EXTERNAL)
PASS:		si	= lptr of IrlmpEndpoint
RETURN:		cxdx	= 32-bit Irlap address
		al	= dest LSAP-Sel
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsEndpointGetDestLsapID	proc	far
	uses	ds,di,bx
	.enter
	call	UtilsGetEndpointLocked		;ds:di = IrlmpEndpoint
	movdw	cxdx, ds:[di].IE_destLsapID.ILI_irlapAddr
	mov	al, ds:[di].IE_destLsapID.ILI_lsapSel
	mov	bx, ds:[LMBH_handle]
	call	MemUnlockShared
	.leave
	ret
UtilsEndpointGetDestLsapID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsSetRequestedQOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store away the QualityOfService arguments to be used to
		establish the IrLAP connection.

CALLED BY:	(EXTERNAL) LFConnectRequestDisconnected
PASS:		es:di	= QualityOfService
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsSetRequestedQOS	proc	far
	uses	ds,si,es,di,ax,cx
	.enter
	movdw	dssi, esdi			;ds:si = QualityOfService
	call	UtilsLoadDGroupES
	mov	di, offset utilsRequestedQOS	;es:di = QOS buffer
	mov	cx, size QualityOfService
	rep	movsb
	.leave
	ret
UtilsSetRequestedQOS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsGetRequestedQOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the QOS args of the IrLAP connection.

CALLED BY:	(EXTERNAL) IsapConnectRequest, IsapConnectResponse
PASS:		nothing
RETURN:		ds:si	= QualityOfService
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsGetRequestedQOS	proc	far
	uses	ax
	.enter
	call	UtilsLoadDGroupDS
	mov	si, offset utilsRequestedQOS
	.leave
	ret
UtilsGetRequestedQOS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsGetQOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the QOS args of the IrLAP connection.

CALLED BY:	(EXTERNAL) IrlmpConnectIndication, IrlmpConnectConfirm
PASS:		nothing
RETURN:		ds:si	= QualityOfService
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsGetQOS	proc	far
	uses	ax
	.enter
	call	UtilsLoadDGroupDS
	mov	si, offset utilsQOS
	.leave
	ret
UtilsGetQOS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsSetQOSParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store away the final QOS params of the IrLAP connection.

CALLED BY:	(EXTERNAL) IsapConnectIndication
			   IsapConnectConfirmation
PASS:		es:si	= IrlapConnectionParams
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsSetQOSParams	proc	far
	uses	ds,si,es,di,ax,cx
	.enter
	segmov	ds, es, ax		;ds:si = IrlapConnectionParams
	call	UtilsLoadDGroupES
	mov	di, offset utilsQOS
	add	di, offset QOS_param	;es:di = params buffer
	mov	cx, size IrlapConnectionParams
	rep	movsb
	.leave
	ret
UtilsSetQOSParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsAllocHugeLMemDataLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate HugeLMem data for use by Irlmp.  

CALLED BY:	(EXTERNAL)
PASS:		cx	= size
RETURN:		^ldx:ax	= HugeLMem data block
		ds:di	= data block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsAllocHugeLMemDataLocked	proc	far
	uses	bx,cx,es
	.enter
	call	UtilsLoadDGroupES
	mov	bx, es:[utilsHugeLMemBlock]
	mov	ax, cx
	mov	cx, FOREVER_WAIT
	call	HugeLMemAllocLock		;^lax:cx = buffer
						;ds:di = buffer
	mov	dx, ax
	mov	ax, cx				;^ldx:ax = buffer
	.leave
	ret
UtilsAllocHugeLMemDataLocked	endp

UtilsCode	ends


ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsLoadDGroupDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load DGroup into DS

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		ds	= dgroup
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsLoadDGroupDS proc	far
		uses	bx
		.enter
		mov	bx, handle dgroup
		call	MemDerefDS
		.leave
		ret
UtilsLoadDGroupDS endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilsLoadDGroupES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load DGroup into ES

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		es	= dgroup
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilsLoadDGroupES proc	far
		uses	bx
		.enter
		mov	bx, handle dgroup
		call	MemDerefES
		.leave
		ret
UtilsLoadDGroupES endp

ResidentCode	ends
