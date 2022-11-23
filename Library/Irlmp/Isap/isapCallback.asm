COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLAP Library
FILE:		irlapCallback.asm

AUTHOR:		Chung Liu, Feb 24, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95   	Initial revision


DESCRIPTION:
	Interface between IrLMP and Native IrLAP.  This file contains
	routines to handle IrLAP_*.indication and .confirmation events from
	the native IrLAP driver.
		
	$Id: isapCallback.asm,v 1.1 97/04/05 01:07:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IsapCode	segment resource

DefIndicationProc	macro	routine, cnst
.assert ($-IsapIndicationProcs) eq cnst*2, <function table is corrupted>
.assert (type routine eq far)
                fptr.far        routine
                endm

IsapIndicationProcs		label fptr.far
DefIndicationProc IsapDiscoveryIndication,   NII_DISCOVERY_INDICATION
DefIndicationProc IsapDiscoveryConfirmation, NII_DISCOVERY_CONFIRMATION
DefIndicationProc IsapUnitdataIndication,    NII_UNITDATA_INDICATION
DefIndicationProc IsapConnectIndication,     NII_CONNECT_INDICATION
DefIndicationProc IsapConnectConfirmation,   NII_CONNECT_CONFIRMATION
DefIndicationProc IsapDataIndication,        NII_DATA_INDICATION
DefIndicationProc IsapStatusIndication,      NII_STATUS_INDICATION
DefIndicationProc IsapStatusConfirmation,    NII_STATUS_CONFIRMATION
DefIndicationProc IsapQQSIndication,         NII_QOS_INDICATION
DefIndicationProc IsapResetIndication,       NII_RESET_INDICATION
DefIndicationProc IsapResetConfirmation,     NII_RESET_CONFIRMATION
DefIndicationProc IsapDisconnectIndication,  NII_DISCONNECT_INDICATION
DefIndicationProc IsapPrimaryIndication,     NII_PRIMARY_INDICATION
DefIndicationProc IsapPrimaryConfirm         NII_PRIMARY_CONFIRM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapNativeIrlapCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for IrLAP indications and confirmations, passed
		to NIR_REGISTER.

CALLED BY:	IrLAP Driver
PASS:		di	= NativeIrlapIndication
		ax,bx,cx,dx,es,si,bp depend on di.
RETURN:		Depends on di.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapNativeIrlapCallback	proc	far
	;
	; If we already called NIR_UNREGISTER, then ignore incoming IrLAP
	; indications.
	;
	push	ds
	call	UtilsLoadDGroupDS	
	tst	ds:[isapClientHandle]
	pop	ds					;flags preserved
	jz	skip
	;
	; Call the appropriate handler.
	;
	shl	di, 1
	add	di, offset IsapIndicationProcs
	push	cs:[di+2]	; segment
	push	cs:[di]		; offset
	call	PROCCALLFIXEDORMOVABLE_PASCAL
exit:
	ret
skip:
	;
	; Even though we are ignoring Irlap indications, we still must
	; free the data that Irlap throws at us.
	;
	cmp	di, NII_DATA_INDICATION
	jne	checkUnitdata

freeData:
	;
	; free hugeLMem ^ldx:bp = data
	;
	movdw	axcx, dxbp
	call	HugeLMemFree
	jmp	exit
checkUnitdata:
	cmp	di, NII_UNITDATA_INDICATION
	je	freeData

disconnect:
	cmp	di, NII_DISCONNECT_INDICATION
	jne	exit
	;
	; free ^hcx = IrlapUnackedData
	;
	mov	bx, cx
	call	MemFree      
	jmp	exit

IsapNativeIrlapCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapDiscoveryIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Discovery.indication

CALLED BY:	NII_DISCOVERY_INDICATION 
PASS:		bx      = client handle
		ax      = DiscoveryLogFlags
		if DiscoveryLogFlags has DLF_REMOTE or DLF_SNIFF set
			es:si	= DiscoveryLog from remote machine.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Forward IrLAP_Discover.indication to Station Control.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapDiscoveryIndication	proc	far
	uses	ax,cx,dx
	.enter
	;
	; Look for the case where a IrLAP_Discovery.request results in a
	; IrLAP_Discovery.indication with DLF_MEDIA_BUSY.
	;
	test	ax, mask DLF_MEDIA_BUSY
	jz	checkIndication

	clr	dx				;no discovery log block
	mov	ax, MSG_SF_IRLAP_DISCOVER_CONFIRM
	call	StationFsmCall

	jmp	exit
		
checkIndication:
	test	ax, mask DLF_VALID
	jz	exit

	test	ax, mask DLF_REMOTE
	jz	exit

	movdw	cxdx, essi			;cx:dx = DiscoveryLog from 
						;  remote machine.
	mov	ax, MSG_SF_IRLAP_DISCOVER_INDICATION
	call	StationFsmCall
exit:
	.leave
	ret
IsapDiscoveryIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapDiscoveryConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Discovery.confirm

CALLED BY:	NII_DISCOVERY_CONFIRMATION
PASS:		bx	= client handle
		^hdx	= DiscoveryLogBlock
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapDiscoveryConfirmation	proc	far
	uses	ax
	.enter
	;
	; Call instead of send, because Station Control has to process
	; the DiscoveryLogBlock before the callback routine returns.
	;
	mov	ax, MSG_SF_IRLAP_DISCOVER_CONFIRM
	call	StationFsmCall
	.leave
	ret
IsapDiscoveryConfirmation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapUnitdataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Unitdata.indication

CALLED BY:	NII_UNITDATA_INDICATION
PASS:		bx	= client handle
		cx	= size of data
		di	= offset into the buffer
		dx:bp	= data buffer
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapUnitdataIndication	proc	far
	.enter
	.leave
	ret
IsapUnitdataIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapConnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLMP_Connect.indication

CALLED BY:	NII_CONNECT_INDICATION
PASS:		bx	= connection handle/client handle
		cxdx	= 32-bit IrLAP address of remote device.
		es:si	= IrlapConnectionParams
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapConnectIndication	proc	far
	uses	ax
	.enter
	call	UtilsSetQOSParams
	mov	ax, MSG_SF_IRLAP_CONNECT_INDICATION
	call	StationFsmSend
	.leave
	ret
IsapConnectIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapConnectConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Connect.confirm

CALLED BY:	NII_CONNECT_CONFIRMATION
PASS:		bx	= connection handle
		ds:si	= IrlapConnectionParams
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapConnectConfirmation	proc	far
	uses	ax,es
	.enter
	segmov	es, ds, ax			;es:si = IrlapConnectionParams
	call	UtilsSetQOSParams

	mov	ax, MSG_SF_IRLAP_CONNECT_CONFIRM
	call	StationFsmSend
	.leave
	ret
IsapConnectConfirmation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Data.indication

CALLED BY:	NII_DATA_INDICATION
PASS:		bx	= connection handle
		cx	= size of data
		si	= offset into the buffer
		^ldx:bp	= HugeLMem data buffer
		ax	= IrlapDataRequestType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapDataIndication	proc	far
	uses	ax
	.enter
	test	ax, mask IDRT_EXPEDITED
	mov	ax, bp				;^ldx:ax = data buffer
	jnz	expeditedData

	call	IUDataDemultiplexer
	jmp	exit

expeditedData:
	call	IUExpeditedDataDemultiplexer
exit:
	.leave
	ret
IsapDataIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapStatusIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Status.indication

CALLED BY:	NII_STATUS_INDICATION
PASS:		bx	= connection handle
		cx	= IrlapStatusIndicationType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapStatusIndication	proc	far
	uses	ax, cx
	.enter
if 0
;
; The IrlapStatusIndicationType should be passed on
;
	clr	cx			;should be quality of link.
endif
	mov	ax, MSG_SF_IRLAP_STATUS_INDICATION
	call	StationFsmSend
	.leave
	ret
IsapStatusIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapStatusConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Status.confirm

CALLED BY:	NII_STATUS_CONFIRMATION
PASS:		bx	= connection handle
		ax	= ConnectionStatus
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapStatusConfirmation	proc	far
	uses	ax, cx
	.enter
	mov	cx, ax				;cx = ConnectionStatus
	mov	ax, MSG_SF_IRLAP_STATUS_CONFIRM
	call	StationFsmSend
	.leave
	ret
IsapStatusConfirmation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapQQSIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsupported

CALLED BY:	NII_QQS_INDICATION
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapQQSIndication	proc	far
	.enter
	.leave
	ret
IsapQQSIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapResetIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Reset.indication

CALLED BY:	NII_RESET_INDICATION
PASS:		bx	= client handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapResetIndication	proc	far
	uses	ax
	.enter
	mov	ax, MSG_SF_IRLAP_RESET_INDICATION
	call	StationFsmSend
	.leave
	ret
IsapResetIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapResetConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Reset.confirmation

CALLED BY:	NII_RESET_CONFIRMATION
PASS:		bx	= connection handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapResetConfirmation	proc	far
	uses	ax
	.enter
	mov	ax, MSG_SF_IRLAP_RESET_CONFIRM
	call	StationFsmSend
	.leave
	ret
IsapResetConfirmation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapDisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Disconnect.indication

CALLED BY:	NII_DISCONNECT_INDICATION
PASS:		ax	= IrlapCondition
				IC_CONECTION_FAILURE
				IC_CONNECTION_TIMEOUT
				IC_REMOTE_DISCONNECTION
				IC_MEDIA_BUSY
				IC_PRIMARY_CONFLICT
		bx	= connection handle
		^hcx	= IrlapUnackedData.  User should free this block
			  after using it.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapDisconnectIndication	proc	far
	uses	ax,bx,dx
	.enter
EC <	WARNING	IRLMP_IRLAP_DISCONNECT_INDICATION		>	
	mov	bx, cx			;^hbx = unacked data
	call	MemFree

	mov	dx, ax			;dx = IrlapCondition
	mov	ax, MSG_SF_IRLAP_DISCONNECT_INDICATION
	call	StationFsmSend
	.leave
	ret
IsapDisconnectIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapPrimaryIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapPrimaryIndication	proc	far
	.enter
	.leave
	ret
IsapPrimaryIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsapPrimaryConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsapPrimaryConfirm	proc	far
	.enter
	.leave
	ret
IsapPrimaryConfirm	endp


IsapCode	ends
