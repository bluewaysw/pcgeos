COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		irlapfsmActions.asm

AUTHOR:		Chung Liu, Mar 16, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95   	Initial revision


DESCRIPTION:
	Actions for IrlmpFsm.

	$Id: irlapfsmActions.asm,v 1.1 97/04/05 01:06:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapFsmCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFConnectRequestStandby
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_connect.request event in STANDBY state.

CALLED BY:	IFConnectRequest
PASS:		*ds:si	= IrlapFsmClass object
		cxdx	= 32-bit IrLAP address
		bp	= lptr of endpoint which initiated request
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	peerDevice = dstDeviceAddr
	IrLAP_Connect.request
	Associated = { endpoint }

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFConnectRequestStandby	proc	near
	class	IrlapFsmClass
	uses	si,di,ax
	.enter
	;
	; update peerAddress
	;
	mov	di, ds:[si]
	movdw	ds:[di].IFI_peerAddress, cxdx
	;
	; make requesting endpoint the only element in the associated set.
	;
	mov	si, ds:[di].IFI_associatedSet
	call	UtilsClearSet
	mov	ax, bp
	call	UtilsAddToSet
	;
	; Irlap_Connect.request
	;
	clr	ax				;no connection flags
	call	IsapConnectRequest
	;
	; goto U_CONNECT
	;
	mov	ds:[di].IFI_state, IFS_U_CONNECT
	.leave
	ret
IFConnectRequestStandby	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFConnectRequestUConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_connect.request event in U_CONNECT state.

CALLED BY:	IFConnectRequest
PASS:		*ds:si	= IrlapFsmClass object
		cxdx	= 32-bit IrLAP address
		bp	= lptr of endpoint which initiated request
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
			

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFConnectRequestUConnect	proc	near
	class	IrlapFsmClass
	uses	ax,di,si
	.enter
	;
	; Add endpoint to associated set.
	;
	mov	di, ds:[si]
	mov	si, ds:[di].IFI_associatedSet
	mov	ax, bp
	call	UtilsAddToSet
	.leave
	ret
IFConnectRequestUConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IFConnectRequestActive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LS_connect.request event in ACTIVE state.

CALLED BY:	IFConnectRequest
PASS:		*ds:si	= IrlapFsmClass object
		cxdx	= 32-bit IrLAP address
		bp	= lptr of endpoint which initiated request
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IFConnectRequestActive	proc	near
	class	IrlapFsmClass
	uses	ax,di,si
	.enter
	;
	; Add endpoint to associated set.
	;
	mov	di, ds:[si]
	mov	si, ds:[di].IFI_associatedSet
	mov	ax, bp
	call	UtilsAddToSet
	;
	; LS_Connect.confirm
	;
	mov	si, ax				;si = endpoint handle
	mov	ax, MSG_LF_LS_CONNECT_CONFIRM
	call	LsapFsmSendByEndpointFixupDS
		
	.leave
	ret
IFConnectRequestActive	endp


IrlapFsmCode	ends
