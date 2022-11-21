COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		stationfsmCode.asm

AUTHOR:		Chung Liu, Mar 16, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95   	Initial revision


DESCRIPTION:
	General code for Station Control FSM.
		

	$Id: stationfsmCode.asm,v 1.1 97/04/05 01:06:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StationFsmCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SFInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a secondary queue and clear the pending event flag.

CALLED BY:	MSG_SF_INITIALIZE
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFInitialize	method dynamic StationFsmClass, 
					MSG_SF_INITIALIZE
	uses	ax,bx,cx,si
	.enter
	call	GeodeAllocQueue			;bx = handle of queue
	mov	ds:[di].SFI_secondaryQueue, bx
	clr	ds:[di].SFI_pendingFlag

	mov	bx, size DiscoveryLog
	clr	ax, cx, si
	call	ChunkArrayCreate		;*ds:si = array
	mov	ds:[di].SFI_discoveryCache, si
	.leave
	ret
SFInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SFCleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the secondary queue.

CALLED BY:	MSG_SF_CLEANUP
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFCleanup	method dynamic StationFsmClass, 
					MSG_SF_CLEANUP
	uses	ax,bx
	.enter
	mov	bx, ds:[di].SFI_secondaryQueue
	call	GeodeFreeQueue
	mov	ax, ds:[di].SFI_discoveryCache
	call	LMemFree
	.leave
	ret
SFCleanup	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SFChangeState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change state, and check the pending event flag, flushing 
		the secondary queue if necessary.

CALLED BY:	MSG_SF_CHANGE_STATE
PASS:		*ds:si	= StationFsmClass object
		ds:di	= StationFsmClass instance data
		dx	= StationFsmState
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SFChangeState	method dynamic StationFsmClass, 
					MSG_SF_CHANGE_STATE
	uses	ax,bx,cx,dx,di,si
	.enter
	;
	; Check if we are really changing state before doing the work.
	;
	cmp	dx, ds:[di].SFI_state
	je	exit
	mov	ds:[di].SFI_state, dx
	;	
	; Check if there are events in the secondary queue.
	;
	tst	ds:[di].SFI_pendingFlag
	jz	exit
	;
	; Flush the secondary queue onto the main queue.
	;
	clr	ds:[di].SFI_pendingFlag

	mov	ax, TGIT_QUEUE_HANDLE
	clr	bx
	call	ThreadGetInfo			;^hax = process's queue
						;bx = process handle
	mov	si, ax				;^hsi = dest. queue for flush

	mov	cx, handle IrlmpStationFsm
	mov	dx, offset IrlmpStationFsm	;^lcx:dx = IrlmpStationFsm

	mov	bx, ds:[di].SFI_secondaryQueue	;^hbx = queue to flush
	mov	di, mask MF_INSERT_AT_FRONT
	call	GeodeFlushQueue
exit:
	.leave
	ret
SFChangeState	endm

StationFsmCode	ends

