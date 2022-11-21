COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		irlapfsmEvents.asm

AUTHOR:		Chung Liu, Mar 13, 1995

ROUTINES:
	Name			Description
	----			-----------
	IFConnectRequest	LS_Connect.request
	IFDisconnectRequest	LS_Disconnect.request
	IFConnectConfirm	Irlap_Connect.confirm
	IFConnectConfirmCallback
	IFConnectIndication	Irlap_Connect.indication
	IFDisconnectIndication	Irlap_Disconnect.indication
	IFDisconnectIndicationCallback
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/13/95   	Initial revision


DESCRIPTION:
	
	Methods and routines for the IrLAP Connection Control FSM.

	$Id: irlapfsmEvents.asm,v 1.1 97/04/05 01:06:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapFsmCode	segment resource

;------------------------------------------------------------------------
;
;			Methods for events
;
;------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_Connect.request forwarded from Station Control

CALLED BY:	MSG_IAF_LS_CONNECT_REQUEST
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data
		cxdx	= 32-bit IrLAP address
		bp	= lptr of endpoint which initiated request
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFConnectRequestActions	nptr.near \
	IFConnectRequestStandby,		;IFS_STANDBY
	IFConnectRequestActive,			;IFS_ACTIVE
	IFConnectRequestUConnect		;IFS_U_CONNECT
.assert (size IFConnectRequestActions / 2 eq StationFsmState)

IFConnectRequest	method dynamic IrlapFsmClass, 
					MSG_IAF_LS_CONNECT_REQUEST
	uses	di
	.enter
	mov	di, ds:[di].IFI_state
	shl	di
	call	cs:[IFConnectRequestActions][di]
	.leave
	ret
IFConnectRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_Disconnect.request forwarded from Station Control

CALLED BY:	MSG_IAF_LS_DISCONNECT_REQUEST
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data
		bp	= lptr of endpoint which initiated request
		cx	= non-zero to force IrLAP disconnect if bp is the
			  last connected endpoint.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFDisconnectRequest	method dynamic IrlapFsmClass, 
					MSG_IAF_LS_DISCONNECT_REQUEST
	.enter
	mov	ax, ds:[di].IFI_state
	cmp	ax, IFS_STANDBY
	je	exit
	
	;
	; Remove the endpoint in question from the associated set.
	;
	mov	si, ds:[di].IFI_associatedSet	
	mov	ax, bp
	call	UtilsRemoveFromSet	
	;
	; Check if we should worry about disconnecting IrLAP.
	;
	cmp	cx, 0
	je	exit
	; 
	; Check if there are any more connected endpoints
	;
	call	UtilsCountSet			;cx = number of elements
	jcxz	disconnect
	jmp	exit

disconnect:
	;
	; There are no more connected endpoints.  Disconnect at IrLAP level
	;
	mov	ds:[di].IFI_state, IFS_STANDBY
	clrdw	ds:[di].IFI_peerAddress
	call	IsapDisconnectRequest

exit:
	.leave
	ret
IFDisconnectRequest	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFConnectConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Connect.confirm forwarded from Station Control

CALLED BY:	MSG_IAF_IRLAP_CONNECT_CONFIRM
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFConnectConfirm	method dynamic IrlapFsmClass, 
					MSG_IAF_IRLAP_CONNECT_CONFIRM
	.enter
	mov	ax, ds:[di].IFI_state
	cmp	ax, IFS_U_CONNECT
	je	uConnect

	; ignore error condition
	jmp	exit

uConnect:
	mov	ds:[di].IFI_state, IFS_ACTIVE
	;
	; For each endpoint in associatedSet:
	;	LS_Connect.confirm
	;
	mov	si, ds:[di].IFI_associatedSet		
	mov	bx, cs
	mov	di, offset IFConnectConfirmCallback
	call	UtilsEnumSet
exit:
	.leave
	ret
IFConnectConfirm	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFConnectConfirmCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue LS_Connect.confirm for each endpoint.

CALLED BY:	IFConnectConfirm via UtilsEnumSet (ChunkArrayEnum)
PASS:		*ds:si	= array
		ds:di	= endpoint
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFConnectConfirmCallback	proc	far
	uses	si, ax
	.enter
	mov	si, ds:[di]
	mov	ax, MSG_LF_LS_CONNECT_CONFIRM
	call	LsapFsmSendByEndpointFixupDS
	clc
	.leave
	ret
IFConnectConfirmCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFConnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Connect.indication

CALLED BY:	MSG_IAF_IRLAP_CONNECT_INDICATION
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data
		cxdx	= 32-bit Irlap address
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	STANDBY:
		peerAddress = srcDeviceAddress
		Irlap_Connect.response
		Associated = {}
		goto ACTIVE
	U_CONNECT:
		/* Should never occur because Irlap resolves connection
		 * races */
		Irlap_Connect.response
		for each endpoint in associated set:
			LS_Connect.confirm
	ACTIVE:
		error
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFConnectIndication	method dynamic IrlapFsmClass, 
					MSG_IAF_IRLAP_CONNECT_INDICATION
	uses	ax,si
	.enter
	mov	ax, ds:[di].IFI_state
	cmp	ax, IFS_STANDBY
	je	standby

EC <	cmp	ax, IFS_ACTIVE					>
EC <	ERROR_E	IRLMP_SEVERE_FSM_ERROR				>
	jmp	exit

standby:
	movdw	ds:[di].IFI_peerAddress, cxdx
	call	IsapConnectResponse
	mov	si, ds:[di].IFI_associatedSet
	call	UtilsClearSet
	mov	ds:[di].IFI_state, IFS_ACTIVE

exit:
	.leave
	ret
IFConnectIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFDisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Disconnect.indication

CALLED BY:	MSG_IAF_IRLAP_DISCONNECT_INDICATION
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data
		dx	= IrlapCondition
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFDisconnectIndication	method dynamic IrlapFsmClass, 
					MSG_IAF_IRLAP_DISCONNECT_INDICATION
	uses	ax,bx,di,si
	.enter
	cmp	ds:[di].IFI_state, IFS_STANDBY
	je	exit				;error condition
	;
	; Send LS_Disconnect.indication to each endpoint in associated set
	;
	mov	si, ds:[di].IFI_associatedSet
	push	di
	mov	bx, cs
	mov	di, offset IFDisconnectIndicationCallback
	call	UtilsEnumSet
	pop	di
	;
	; Cleanup connection vestiges.
	;
	call	UtilsClearSet
	clrdw	ds:[di].IFI_peerAddress
	;
	; goto STANDBY state
	;
	mov	ds:[di].IFI_state, IFS_STANDBY	
exit:
	.leave
	ret
IFDisconnectIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFDisconnectIndicationCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send LS_Disconnect.indication to each endpoint

CALLED BY:	IFDisconnectIndication via UtilsEnumSet (ChunkArrayEnum)
PASS:		*ds:si	= array
		ds:di	= endpoint
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFDisconnectIndicationCallback	proc	far
	uses	si,ax,dx
	.enter
	mov	si, ds:[di]
	mov	dl, IDR_USER_REQUEST
	mov	ax, MSG_LF_LS_DISCONNECT_INDICATION
	call	LsapFsmSendByEndpointFixupDS
	clc
	.leave
	ret
IFDisconnectIndicationCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFStatusRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_Status.request forwarded from Station FSM

CALLED BY:	MSG_IAF_LS_STATUS_REQUEST
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data
		bp	= lptr of requesting IrlmpEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFStatusRequest	method dynamic IrlapFsmClass, 
					MSG_IAF_LS_STATUS_REQUEST
	uses	ax,cx,si
	.enter
	mov	si, ds:[di].IFI_statusSet	;si = status set
	call	UtilsCountSet			;cx = number of elements
	jcxz	requestStatus

addToSet:
	mov	ax, bp				;ax = requesting endpoint
	call	UtilsAddToSet
	.leave
	ret

requestStatus:
	call	IsapStatusRequest
	jmp	addToSet
IFStatusRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFStatusIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Status.indication

CALLED BY:	MSG_IAF_IRLAP_STATUS_INDICATION
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data
		cx	= IrlapStatusIndicationType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFStatusIndication	method dynamic IrlapFsmClass, 
					MSG_IAF_IRLAP_STATUS_INDICATION
	uses	si,bx,di
	.enter
	cmp	ds:[di].IFI_state, IFS_STANDBY
	je	exit
	;
	; call IRLMP_MONITOR_LSAP_SEL with this indication
	;
	push	cx
	mov	ch, IRLMP_MONITOR_LSAP_SEL 
	call	UtilsGetEndpointByLocalLsap		;si = endpoint
	pop	cx					;cx = IrlapStatusIndicationType
	jc	callAssoc

	mov	ax, MSG_LF_LS_STATUS_INDICATION
	call	LsapFsmSendByEndpointFixupDS

callAssoc:
	;
	; Call the connected LSAPs.
	;
	mov	si, ds:[di].IFI_associatedSet
	mov	bx, cs
	mov	di, offset IFStatusIndicationCallback
	call	UtilsEnumSet
exit:
	.leave
	ret
IFStatusIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFStatusIndicationCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to send LS_Status.indication to each endpoint
		of the associated set.

CALLED BY:	IFStatusIndication via UtilsEnumSet
PASS:		*ds:si	= array
		ds:di	= endpoint
		cx	= ConnectionStatus
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFStatusIndicationCallback	proc	far
	uses	si, ax
	.enter
	mov	si, ds:[di]
	mov	ax, MSG_LF_LS_STATUS_INDICATION
	;
	; Send rather than call, because utilsEndpointBlock is locked now.
	;
	call	LsapFsmSendByEndpointFixupDS
	clc
	.leave
	ret
IFStatusIndicationCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFStatusConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Status.confirm

CALLED BY:	MSG_IAF_IRLAP_STATUS_CONFIRM
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data
		cx	= ConnectionStatus
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFStatusConfirm	method dynamic IrlapFsmClass, 
					MSG_IAF_IRLAP_STATUS_CONFIRM
	uses	si,bx,di
	.enter
	cmp	ds:[di].IFI_state, IFS_STANDBY
	je	exit

	mov	si, ds:[di].IFI_statusSet
	mov	bx, cs
	mov	di, offset IFStatusConfirmCallback
	call	UtilsEnumSet

	call	UtilsClearSet
exit:
	.leave
	ret
IFStatusConfirm	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFStatusConfirmCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to send LS_Status.confirm to each endpoint of
		the status set.

CALLED BY:	IFStatusConfirm via UtilsEnumSet
PASS:		*ds:si	= array
		ds:di	= endpoint
		cx	= ConnectionStatus
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFStatusConfirmCallback	proc	far
	uses	si, ax
	.enter
	mov	si, ds:[di]
	mov	ax, MSG_LF_LS_STATUS_CONFIRM
	call	LsapFsmSendByEndpointFixupDS
	clc
	.leave
	ret
IFStatusConfirmCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFResetIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Reset.indication

CALLED BY:	MSG_IAF_IRLAP_RESET_INDICATION
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFResetIndication	method dynamic IrlapFsmClass, 
					MSG_IAF_IRLAP_RESET_INDICATION
	uses	dx,si,di,bx
	.enter
	cmp	ds:[di].IFI_state, IFS_ACTIVE
	jne	exit

	call 	IsapDisconnectRequest
		
	mov	ds:[di].IFI_state, IFS_STANDBY
	clrdw	ds:[di].IFI_peerAddress

	mov	dx, IDR_IRLAP_RESET
	mov	si, ds:[di].IFI_associatedSet
	mov	bx, cs
	mov	di, offset IFResetIndicationCallback
	call	UtilsEnumSet

	call	UtilsClearSet
exit:
	.leave
	ret
IFResetIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFResetIndicationCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send LS_Disconnect.indication to each endpoint in associated
		set.

CALLED BY:	IFResetIndication via UtilsEnumSet
PASS:		ds:di	= endpoint
		dx	= IrlmpDisconnectReason
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFResetIndicationCallback	proc	far
	uses	ax,si
	.enter
	mov	si, ds:[di]
	mov	ax, MSG_LF_LS_DISCONNECT_INDICATION
	call	LsapFsmSendByEndpointFixupDS
	clc
	.leave
	ret
IFResetIndicationCallback	endp

IrlapFsmCode	ends




