COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		irlapfsmCode.asm

AUTHOR:		Chung Liu, Mar 20, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95   	Initial revision


DESCRIPTION:
	Methods and routines for IrLAP Connection Control FSM.

	$Id: irlapfsmCode.asm,v 1.1 97/04/05 01:06:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapFsmCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IAFCheckIfConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If IrLAP layer is connected, return the peer address.

CALLED BY:	MSG_IAF_CHECK_IF_CONNECTED
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data
RETURN:		carry clear if not connected
			cx, dx destroyed
		carry set if connected
			cxdx	= 32-bit IrLAP address of peer
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IAFCheckIfConnected	method dynamic IrlapFsmClass, 
					MSG_IAF_CHECK_IF_CONNECTED
	.enter
	movdw	cxdx, ds:[di].IFI_peerAddress
	tstdw	cxdx
	jz	notConnected
	stc
exit:
	.leave
	ret
notConnected:
	clc
	jmp	exit
IAFCheckIfConnected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IAFInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the associated set.

CALLED BY:	MSG_IAF_INITIALIZE
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
IAFInitialize	method dynamic IrlapFsmClass, 
					MSG_IAF_INITIALIZE
	uses	ax,si
	.enter
	call	UtilsCreateSetFixupDS	;si = set lptr
	mov	ds:[di].IFI_associatedSet, si

	call	UtilsCreateSetFixupDS	;si = set lptr
	mov	ds:[di].IFI_statusSet, si
	call	IsapInitIrlap
	.leave
	ret
IAFInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IAFExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleaup IrlapFsm.

CALLED BY:	MSG_IAF_EXIT
PASS:		*ds:si	= IrlapFsmClass object
		ds:di	= IrlapFsmClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IAFExit	method dynamic IrlapFsmClass, 
					MSG_IAF_EXIT
	uses	si
	.enter
	;
	; Force IrLAP FSM into STANDBY state, since we're destroying
	; everything on which it depends.
	;
	mov	ds:[di].IFI_state, IFS_STANDBY

	mov	si, ds:[di].IFI_associatedSet
	call	UtilsDestroySet
	mov	si, ds:[di].IFI_statusSet
	call	UtilsDestroySet
	call	IsapExitIrlap
	.leave
	ret
IAFExit	endm

IrlapFsmCode	ends
