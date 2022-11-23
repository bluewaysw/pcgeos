COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		lsapfsmUtils.asm

AUTHOR:		Chung Liu, Mar 16, 1995

ROUTINES:
	Name			Description
	----			-----------
	LsapFsmCreate
	LsapFsmDestroyFixupDS
	LsapFsmGetByEndpoint
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95   	Initial revision


DESCRIPTION:
	Utils for LsapFsm module.

	$Id: lsapfsmUtils.asm,v 1.1 97/04/05 01:06:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LsapFsmCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LsapFsmCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the IrLMP process thread to create a LSAP Connection
		Control FSM for us.  DO NOT CALL THIS WITH ENDPOINT BLOCK
		LOCKED!
CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		^lcx:dx	= IrlmpLsapConnControl object
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LsapFsmCreate	proc	far
	uses	ax,bx,di
	.enter
	mov	ax, MSG_IP_INSTANTIATE_LSAP_FSM
	mov	di, mask MF_CALL
	call	MainMessageServerThread		;^lcx:dx = LSAP Control FSM
	.leave
	ret
LsapFsmCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LsapFsmDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the LSAP Control FSM object.

CALLED BY:	(EXTERNAL) IrlmpUnregister
PASS:		^lbx:si	= IrlmpLsapConnControl object
		ds	= lmem block to be fixed up
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LsapFsmDestroy	proc	far
	uses	di,ax
	.enter
	mov	di, mask MF_FORCE_QUEUE
	mov	ax, MSG_META_OBJ_FREE
	call	ObjMessage
	.leave
	ret
LsapFsmDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LsapFsmGetByEndpoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the LSAP FSM for the client.

CALLED BY:	IrlmpNativeConnectRequest, etc.
PASS:		si	= lptr of endpoint
RETURN:		^lbx:si	= LsapFsm for client
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LsapFsmGetByEndpoint	proc	far
	uses	ds,di,cx
	.enter
	call	UtilsGetEndpointLocked		;ds:di = IrlmpEndpoint
	movdw	cxsi, ds:[di].IE_lsapFsm	;^lcx:si = 
						;  IrlmpLsapConnectionControl
						;  FSM for the LSAP.
	mov	bx, ds:[LMBH_handle]	
	call	MemUnlockShared
	mov	bx, cx

	Assert	objectOD, bxsi, LsapFsmClass
	.leave
	ret
LsapFsmGetByEndpoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LsapFsmCallByEndpoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the LSAP Connection Control FSM for the endpoint.

CALLED BY:	(EXTERNAL)
PASS:		si		= lptr of endpoint
		ax		= message
		cx,dx,bp 	= message args
RETURN:		ax,cx,dx,bp	= depends on message
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LsapFsmCallByEndpoint	proc	far
	uses	bx,si,di
	.enter
	call	LsapFsmGetByEndpoint		;^lbx:si = lsap fsm
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
LsapFsmCallByEndpoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LsapFsmCallByEndpointFixupDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the LSAP Connection Control FSM for the endpoint,
		and fixup DS.

CALLED BY:	(EXTERNAL)
PASS:		si		= lptr of endpoint
		ax		= message
		cx,dx,bp 	= message args
RETURN:		ax,cx,dx,bp	= depends on message
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LsapFsmCallByEndpointFixupDS	proc	far
	uses	bx,si,di
	.enter
	call	LsapFsmGetByEndpoint		;^lbx:si = lsap fsm
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
LsapFsmCallByEndpointFixupDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LsapFsmSendByEndpointFixupDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	(EXTERNAL) IFConnectRequestActive
PASS:		si		= lptr of endpoint
		ax		= message
		cx,dx,bp 	= message args
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LsapFsmSendByEndpointFixupDS	proc	far
	uses	bx,si,di
	.enter
	call	LsapFsmGetByEndpoint		;^lbx:si = lsap fsm
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
LsapFsmSendByEndpointFixupDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LsapFsmSendByEndpointStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message with stack arguments to the LsapFsm 
		for the specified endpoint.

CALLED BY:	(EXTERNAL) IsapDataIndication
PASS:		si	= lptr of endpoint
		ax	= message
		ss:bp	= message args
		dx	= size of args
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LsapFsmSendByEndpointStack	proc	far
	uses	bx,si,di
	.enter
	call	LsapFsmGetByEndpoint		;^lbx:si = lsap fsm
	mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
	call	ObjMessage
	.leave
	ret
LsapFsmSendByEndpointStack	endp


LsapFsmCode	ends
