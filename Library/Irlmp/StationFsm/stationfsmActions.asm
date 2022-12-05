COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		stationfsmActions.asm

AUTHOR:		Chung Liu, Mar 15, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial revision


DESCRIPTION:
	Actions for Station Control FSM.

	$Id: stationfsmActions.asm,v 1.1 97/04/05 01:06:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StationFsmCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unexpected event in a state gave rise to error condition.
		Ignore the event.

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFError	proc	near
	.enter
	.leave
	ret
SFError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFLeavePending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the event to the secondary queue.

CALLED BY:	SFDiscoverRequest
PASS:		*ds:si	= StationFsmClass object
		ax	= message #
		cx, dx, bp = message arguments
RETURN:		carry clear
		ax	= IE_SUCCESS
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFLeavePendingFixupDS	proc	near
	uses	di
	.enter
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	SFLeavePendingLow
	.leave
	ret
SFLeavePendingFixupDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFLeavePendingLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add event to secondary queue.

CALLED BY:	SFLeavePending, SFLeavePendingStack
PASS:		di	= MessageFlags
PASS:		*ds:si	= StationFsmClass object
		ax	= message #
		if MF_STACK:		
			ss:bp	= args
			dx	= args size
		else:
			cx,dx,bp = args
RETURN:		carry clear
		ax	= IE_SUCCESS
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFLeavePendingLow	proc	near
	class	StationFsmClass
	uses	si, bx
	.enter
	;
	; Take note that there are pending events in the secondary queue.
	;
	push	di				;save MessageFlags
	mov	di, ds:[si]
	mov	ds:[di].SFI_pendingFlag, -1
	;
	; ObjMessage directly to the secondary queue.
	;
	mov	bx, ds:[di].SFI_secondaryQueue
	clr	si
	pop	di				;di = MessageFlags
	call	ObjMessage
	;
	; return success
	;
	mov	ax, IE_SUCCESS
	clc	
	.leave
	ret
SFLeavePendingLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFDiscoverRequestReady
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Action for LM_DiscoverDevices.request in SFS_READY state.

CALLED BY:	SFDiscoverRequest
PASS:		*ds:si	= StationFsmClass object
		dx	= lptr of endpoint
		cl	= IrlapUserTimeSlot
RETURN:		ds 	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If connected:
		issue LM_DiscoverDevices.confirm with cached DiscoveryInfo.
	If not connected:
		issue IrLAP_Discover.request to IrLAP Driver.
		change to SFS_DISCOVER

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFDiscoverRequestReady	proc	near
	class	StationFsmClass
	uses	ax,bx,cx,dx,si
	.enter
	mov	di, ds:[si]
	mov	si, dx				;si = lptr of endpoint
	mov	bx, cx				;bl = IrlapUserTimeSlot
	;
	; Check if connected
	;
	mov	ax, MSG_IAF_CHECK_IF_CONNECTED
	call	IrlapFsmCallFixupDS		;cxdx = Irlap address
	jnc	notConnected
	;
	; Already connected, so call discovery confirmation callback, 
	; passing the cached discovery info.
	;
	mov	ax, ds:[di].SFI_discoveryCache	;*ds:ax = DiscoveryLog array
	mov	dl, IDS_CACHED
	call	IrlmpDiscoverConfirm
	jmp	exit

notConnected:
	;
	; Not connected, so initiate IrLAP discovery.
	;
	mov	ds:[di].SFI_discoveryRequester, si
	call	IsapDiscoverRequest
	;
	; go to SFS_DISCOVERY state
	;
	mov	dx, SFS_DISCOVERY
	mov	ax, MSG_SF_CHANGE_STATE
	call	StationFsmCallFixupDS
	;
	; return success
	;
exit:
	.leave
	ret
SFDiscoverRequestReady	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFDiscoverConfirmDiscover
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Station FSM received Irlap_Discover.confirm in the
		DISCOVER state.  

CALLED BY:	SFIrlapDiscoverConfirm
PASS:		*ds:si	= StationFsmClass object
		^hdx	= DiscoveryLogBlock (or 0 if discovery wasn't 
			carried out, probably because media is busy.)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If no address conflicts:
		CacheLog = Log
		LM_DiscoverDevices.confirm(status = newLog, Log)		
		goto READY

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFDiscoverConfirmDiscover	proc	near
	class	StationFsmClass
	uses	di,si,ax,bx,cx,dx
	.enter
	mov	di, ds:[si]
	mov	ax, ds:[di].SFI_discoveryCache	;*ds:ax = DiscoveryLog array
	call	SUUpdateDiscoveryCache		;ds may have moved
	call	SUFindAddressConflicts		
	jc	conflicts

	;
	; go to SFS_READY state
	;
	push	ax
	mov	dx, SFS_READY
	mov	ax, MSG_SF_CHANGE_STATE
	call	StationFsmCallFixupDS
	pop	ax

	mov	si, ds:[di].SFI_discoveryRequester
	mov	dl, IDS_DISCOVERY
	call	IrlmpDiscoverConfirm
exit:
	.leave
	ret

conflicts:
	call	SFDiscoverConfirmResolveConflicts
	jmp	exit
SFDiscoverConfirmDiscover	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFDiscoverConfirmResolveConflicts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve address conflicts.

CALLED BY:	SFDiscoverConfirmDiscover
PASS:		?
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFDiscoverConfirmResolveConflicts	proc	near
	.enter
	.leave
	ret
SFDiscoverConfirmResolveConflicts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFConnectRequestReady
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle LS_Connect.request in READY state

CALLED BY:	SFConnectRequest
PASS:		*ds:si	= StationFsmClass object
		cxdx	= 32-bit IrLAP address
		bp	= lptr of endpoint which initiated request
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If (connected to deviceAddress) or (not connected)
		Forward LS_Connect.request to IrlapFsm
	else:
		LS_Disconnect.indication(noIrLAPConnection)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFConnectRequestReady	proc	near
	uses	ax,bx,cx,dx,di,si
	.enter
	;
	; Check if connected
	;
	movdw	bxdi, cxdx			;bxdi = address to connect
	mov	ax, MSG_IAF_CHECK_IF_CONNECTED
	call	IrlapFsmCallFixupDS		;cxdx = Irlap address
	jnc	forwardToIrlap			;not connected
	
	cmpdw	cxdx, bxdi
	je	forwardToIrlap
	;
	; Connected to another Irlap address.  Send LS_disconnect.indication
	; to LSAP FSM, with reason = noIrlapConnection.
	;
	mov	si, bp
	mov	dl, IDR_FAILED_TO_ESTABLISH_IRLAP_CONNECTION 
	mov	ax, MSG_LF_LS_DISCONNECT_INDICATION
	call	LsapFsmCallByEndpointFixupDS
	jmp	exit

forwardToIrlap:
	;
	; Forward LS_Connect.request to IrlapFsm
	;
	movdw	cxdx, bxdi
	mov	ax, MSG_IAF_LS_CONNECT_REQUEST
	call	IrlapFsmCallFixupDS

exit:
	.leave
	ret
SFConnectRequestReady	endp


StationFsmCode		ends
