COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		stationfsmEvents.asm

AUTHOR:		Chung Liu, Feb 24, 1995

ROUTINES:
	Name			Description
	----			-----------
	SFDiscoverRequest	LM_Discover.request
	SFIrlapDiscoverConfirm	Irlap_Discover.confirm
	SFConnectRequest	LM_Connect.request
	SFIrlapConnectConfirm	Irlap_Connect.confirm
	SFIrlapConnectIndication Irlap_Connect.indication
	SFIrlapDiscoverIndication Irlap_Discover.indication
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/24/95   	Initial revision


DESCRIPTION:
	Event handling for Station Control FSM.

	$Id: stationfsmEvents.asm,v 1.1 97/04/05 01:06:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StationFsmCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFDiscoverRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate IrLAP discovery, or, if already connected, return 
		results of last discovery.  

CALLED BY:	MSG_SF_LM_DISCOVER_DEVICES_REQUEST
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
		dx	= lptr of endpoint
		cl	= IrlapUserTimeSlot
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFDiscoverRequestActions nptr.near \
	SFDiscoverRequestReady,			;SFS_READY
 	SFLeavePendingFixupDS,			;SFS_DISCOVERY
	SFLeavePendingFixupDS			;SFS_RESOLVE_ADDRESS
.assert (size SFDiscoverRequestActions / 2 eq StationFsmState)

SFDiscoverRequest	method dynamic StationFsmClass, 
					MSG_SF_LM_DISCOVER_DEVICES_REQUEST
	uses	di
	.enter
	mov	di, ds:[di].SFI_state
	shl	di
	call	cs:[SFDiscoverRequestActions][di]
	.leave
	ret
SFDiscoverRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFIrlapDiscoverConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process Irlap_Discover.confirm received from Irlap driver.

CALLED BY:	MSG_SF_IRLAP_DISCOVER_CONFIRM
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
		^hdx	= DiscoveryLogBlock
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	SFS_READY:
	SFS_RESOLVE_ADDRESS:
		error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFDiscoverConfirmActions nptr.near \
	SFError,				;SFS_READY
 	SFDiscoverConfirmDiscover,		;SFS_DISCOVERY
	SFError					;SFS_RESOLVE_ADDRESS
.assert (size SFDiscoverConfirmActions / 2 eq StationFsmState)

SFIrlapDiscoverConfirm	method dynamic StationFsmClass, 
					MSG_SF_IRLAP_DISCOVER_CONFIRM
	uses	di
	.enter
	mov	di, ds:[di].SFI_state
	shl	di
	call	cs:[SFDiscoverConfirmActions][di]
	.leave
	ret
SFIrlapDiscoverConfirm	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFIrlapDiscoverIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Discover.indication

CALLED BY:	MSG_SF_IRLAP_DISCOVER_INDICATION
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
		cx:dx	= DiscoveryLog
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFIrlapDiscoverIndication	method dynamic StationFsmClass, 
					MSG_SF_IRLAP_DISCOVER_INDICATION
	uses	ds,si,es,di,ax,cx,dx
	.enter
	;
	; ignore unless in READY state
	;
	cmp	ds:[di].SFI_state, SFS_READY
	jne	exit
	;
	; Replace cache log
	;
	mov	si, ds:[di].SFI_discoveryCache	;*ds:si = DiscoveryLog array
	call	ChunkArrayZero
	call	ChunkArrayAppend		;ds:di = new DiscoveryLog
	push	ds, si
	segmov	es, ds, ax			;es:di = new DiscoveryLog
	movdw	dssi, cxdx			;ds:si = DiscoveryLog from
						;  Irlap indication.
	mov	cx, size DiscoveryLog
	rep	movsb
	;
	; LM_DiscoverDevices.indication(status = passive, Log)
	;
	pop	ds, ax				;*ds:ax = DiscoveryLog array
	mov	ch, IRLMP_XID_DISCOVERY_SAP 
	call	UtilsGetEndpointByLocalLsap	;si = discovery endpoint
	jc	exit

	mov	dl, IDS_PASSIVE
	call	IrlmpDiscoverIndication
	
exit:
	.leave
	ret
SFIrlapDiscoverIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_connect.request sent from from LSAP FSM.

CALLED BY:	MSG_SF_LS_CONNECT_REQUEST
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
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
SFConnectRequest	method dynamic StationFsmClass, 
					MSG_SF_LS_CONNECT_REQUEST
	.enter
	mov	di, ds:[di].SFI_state
	cmp	di, SFS_READY
	jne	leavePending
	;
	; READY state.
	;
	call	SFConnectRequestReady
	jmp	exit
leavePending:
	;
	; In DISCOVER and RESOLVE_ADDRESS states, leave event pending
	;
	call	SFLeavePendingFixupDS
exit:
	.leave
	ret
SFConnectRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFIrlapConnectConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IrLAP_Connect.confirm sent from ISAP.

CALLED BY:	MSG_SF_IRLAP_CONNECT_CONFIRM
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFIrlapConnectConfirm	method dynamic StationFsmClass, 
					MSG_SF_IRLAP_CONNECT_CONFIRM
	uses	ax
	.enter
	mov	ax, ds:[di].SFI_state
	cmp	ax, SFS_READY
	jne	exit			;error condition
	;
	; Forward to IrlapFsm
	;
	mov	ax, MSG_IAF_IRLAP_CONNECT_CONFIRM
	call	IrlapFsmCallFixupDS
exit:
	.leave
	ret
SFIrlapConnectConfirm	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFIrlapConnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Connect.indication

CALLED BY:	MSG_SF_IRLAP_CONNECT_INDICATION
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
		cxdx	= 32-bit Irlap address
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	READY:
		forward to IrlapFsm
	DISCOVER:
	RESOLVE_ADDR:
		Irlap_Disconnect.request 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFIrlapConnectIndication	method dynamic StationFsmClass, 
					MSG_SF_IRLAP_CONNECT_INDICATION
	uses	ax
	.enter
	mov	ax, ds:[di].SFI_state
	cmp	ax, SFS_READY
	je	ready

EC <	cmp	ax, SFS_DISCOVERY				>
EC <	je	okay						>
EC <	cmp	ax, SFS_RESOLVE_ADDRESS				>
EC <	ERROR_NE IRLMP_ILLEGAL_STATE				>
EC <okay:							>
	;
	; For DISCOVER and RESOLVE_ADDR, issue Irlap_Disconnect.request
	;
	call	IsapDisconnectRequest
	jmp	exit
ready:
	;
	; For READY state, forward to IrlapFsm
	;
	mov	ax, MSG_IAF_IRLAP_CONNECT_INDICATION
	call	IrlapFsmCallFixupDS
exit:
	.leave
	ret
SFIrlapConnectIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFIrlapDisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Disconnect.indication

CALLED BY:	MSG_SF_IRLAP_DISCONNECT_INDICATION
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
		dx	= IrlapCondition
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFIrlapDisconnectIndication	method dynamic StationFsmClass, 
					MSG_SF_IRLAP_DISCONNECT_INDICATION
	uses	ax
	.enter
	mov	ax, ds:[di].SFI_state
	cmp	ax, SFS_READY
	jne	exit
	;
	; in READY state, forward to IrlapFsm
	;
	mov	ax, MSG_IAF_IRLAP_DISCONNECT_INDICATION
	call	IrlapFsmSendFixupDS

exit:
	.leave
	ret
SFIrlapDisconnectIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_Disconnect.request

CALLED BY:	MSG_SF_LS_DISCONNECT_REQUEST
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
		bp	= lptr of IrlmpEndpoint that wants to disconnect
		cx	= non-zero to force IrLAP disconnect if bp is the
			  last connected endpoint.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if in READY state, forward to IrlapFsm.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFDisconnectRequest	method dynamic StationFsmClass, 
					MSG_SF_LS_DISCONNECT_REQUEST
	uses	ax
	.enter
	cmp	ds:[di].SFI_state, SFS_READY
	jne	exit			;error condition
	;
	; Forward to IrlapFsm
	;
	mov	ax, MSG_IAF_LS_DISCONNECT_REQUEST
	call	IrlapFsmCallFixupDS
exit:
	.leave
	ret
SFDisconnectRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFStatusRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_Status.request

CALLED BY:	MSG_SF_LS_STATUS_REQUEST
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
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
SFStatusRequest	method dynamic StationFsmClass, 
					MSG_SF_LS_STATUS_REQUEST
	uses	ax
	.enter
	cmp	ds:[di].SFI_state, SFS_READY
	jne	exit			;error condition
	;
	; Forward to IrlapFsm
	;
	mov	ax, MSG_IAF_LS_STATUS_REQUEST
	call	IrlapFsmCallFixupDS
exit:
	.leave
	ret
SFStatusRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFIrlapStatusIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Status.indication

CALLED BY:	MSG_SF_IRLAP_STATUS_INDICATION
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
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
SFIrlapStatusIndication	method dynamic StationFsmClass, 
					MSG_SF_IRLAP_STATUS_INDICATION
	uses	ax
	.enter
	cmp	ds:[di].SFI_state, SFS_READY
	jne	exit			;error condition
	;
	; Forward to IrlapFsm
	;
	mov	ax, MSG_IAF_IRLAP_STATUS_INDICATION
	call	IrlapFsmCallFixupDS
exit:
	.leave
	ret
SFIrlapStatusIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFIrlapStatusConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Status.confirmation

CALLED BY:	MSG_SF_IRLAP_STATUS_CONFIRMATION
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
		cx	= ConnectionStatus
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFIrlapStatusConfirmation	method dynamic StationFsmClass, 
					MSG_SF_IRLAP_STATUS_CONFIRM
	uses	ax
	.enter
	cmp	ds:[di].SFI_state, SFS_READY
	jne	exit			;error condition
	;
	; Forward to IrlapFsm
	;
	mov	ax, MSG_IAF_IRLAP_STATUS_CONFIRM
	call	IrlapFsmCallFixupDS
exit:
	.leave
	ret
SFIrlapStatusConfirmation	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFIrlapResetIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Irlap_Reset.indication

CALLED BY:	MSG_SF_IRLAP_RESET_INDICATION
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFIrlapResetIndication	method dynamic StationFsmClass, 
					MSG_SF_IRLAP_RESET_INDICATION
	uses	ax
	.enter
	cmp	ds:[di].SFI_state, SFS_READY
	jne	exit			;error condition
	;
	; Forward to IrlapFsm
	;
	mov	ax, MSG_IAF_IRLAP_RESET_INDICATION
	call	IrlapFsmCallFixupDS
exit:
	.leave
	ret
SFIrlapResetIndication	endm


StationFsmCode		ends




