COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasCode.asm

AUTHOR:		Chung Liu, May 10, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/10/95   	Initial revision


DESCRIPTION:
	Code for IAS FSM.
		

	$Id: iasCode.asm,v 1.1 97/04/05 01:07:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IasCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICFInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize IAS Client FSM

CALLED BY:	MSG_ICF_INITIALIZE
PASS:		*ds:si	= IasClientFsmClass object
		ds:di	= IasClientFsmClass instance data
		ds:bx	= IasClientFsmClass object (same as *ds:si)
		es 	= segment of IasClientFsmClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICFInitialize	method dynamic IasClientFsmClass, 
					MSG_ICF_INITIALIZE
	.enter
	call	UtilsCreateSetFixupDS		;si = set handle
	mov	ds:[di].ICFI_requestingSet, si

	call	GeodeAllocQueue			;bx = queue handle
	mov	ds:[di].ICFI_secondaryQueue, bx
	clr	ds:[di].ICFI_pendingFlag
	.leave
	ret
ICFInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICFExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanup IAS Client FSM

CALLED BY:	MSG_ICF_EXIT
PASS:		*ds:si	= IasClientFsmClass object
		ds:di	= IasClientFsmClass instance data
		ds:bx	= IasClientFsmClass object (same as *ds:si)
		es 	= segment of IasClientFsmClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICFExit	method dynamic IasClientFsmClass, 
					MSG_ICF_EXIT
	.enter
	mov	si, ds:[di].ICFI_requestingSet
	call	UtilsDestroySet

	mov	bx, ds:[di].ICFI_secondaryQueue
	call	GeodeFreeQueue
	.leave
	ret
ICFExit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICFChangeState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change state, flush queue.

CALLED BY:	MSG_ICF_CHANGE_STATE
PASS:		*ds:si	= IasClientFsmClass object
		ds:di	= IasClientFsmClass instance data
		dx	= next state
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICFChangeState	method dynamic IasClientFsmClass, 
					MSG_ICF_CHANGE_STATE
	.enter
	;
	; Check if we are really changing state before doing the work.
	;
	cmp	dx, ds:[di].ICFI_state
	je	exit
	mov	ds:[di].ICFI_state, dx
	;	
	; Check if there are events in the secondary queue.
	;
	tst	ds:[di].ICFI_pendingFlag
	jz	exit
	;
	; Flush the secondary queue onto the main queue.
	;
	clr	ds:[di].ICFI_pendingFlag

	mov	ax, TGIT_QUEUE_HANDLE
	clr	bx
	call	ThreadGetInfo			;^hax = process's queue
						;bx = process handle
	mov	si, ax				;^hsi = dest. queue for flush

	mov	cx, handle IrlmpIasClientFsm
	mov	dx, offset IrlmpIasClientFsm	;^lcx:dx = IrlmpIasClientFsm

	mov	bx, ds:[di].ICFI_secondaryQueue	;^hbx = queue to flush
	mov	di, mask MF_INSERT_AT_FRONT
	call	GeodeFlushQueue
exit:

	.leave
	ret
ICFChangeState	endm


IasCode		ends
