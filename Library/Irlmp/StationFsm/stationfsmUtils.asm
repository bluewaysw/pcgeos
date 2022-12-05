COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		stationfsmUtils.asm

AUTHOR:		Chung Liu, Mar 16, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95   	Initial revision


DESCRIPTION:
	Utility routines for StationFsm module
		
	$Id: stationfsmUtils.asm,v 1.1 97/04/05 01:06:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StationFsmCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StationFsmCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the Station Control FSM.

CALLED BY:	(EXTERNAL)
PASS:		ax		= message
		cx,dx,bp	= arguments for message
RETURN:		ax, cx, dx, bp	= depends on message
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StationFsmCall	proc	far
	uses	di
	.enter
	mov	di, mask MF_CALL
	call	SUObjMessage
	.leave
	ret
StationFsmCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StationFsmCallFixupDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the Station Control FSM.

CALLED BY:	(EXTERNAL)
PASS:		ax		= message
		cx,dx,bp	= arguments for message
		ds		= lmem block
RETURN:		ax,cx,dx,bp	= depends on message
		ds		= fixed up.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StationFsmCallFixupDS	proc	far
	uses	di
	.enter
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	SUObjMessage
	.leave
	ret
StationFsmCallFixupDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StationFsmSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to Station FSM.

CALLED BY:	(EXTERNAL)
PASS:		ax		= message
		cx,dx,bp	= arguments for message
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StationFsmSend	proc	far
	uses	di
	.enter
	mov	di, mask MF_FORCE_QUEUE
	call	SUObjMessage
	.leave
	ret
StationFsmSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StationFsmSendFixupDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to StationFsm, and fixup DS

CALLED BY:	(EXTERNAL)
PASS:		ax		= message
		cx,dx,bp	= args
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StationFsmSendFixupDS	proc	far
	uses	di
	.enter
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	call	SUObjMessage
	.leave
	ret
StationFsmSendFixupDS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StationFsmSendStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to Station FSM, passing arguments on stack.

CALLED BY:	(EXTERNAL)
PASS:		ax	= message
		ss:bp	= arguments on stack
		dx	= argument size
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StationFsmSendStack	proc	far
	uses	di
	.enter
	mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
	call	SUObjMessage
	.leave
	ret
StationFsmSendStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SUObjMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ObjMessage to Station FSM.

CALLED BY:	(INTERNAL)
PASS:		di	= MessageFlags
		other args same as ObjMessage
RETURN:		same as ObjMessage
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SUObjMessage	proc	near
	uses	bx, si
	.enter
	mov	bx, handle IrlmpStationFsm
	mov	si, offset IrlmpStationFsm
	call	ObjMessage
	.leave
	ret
SUObjMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SUFindAddressConflicts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	SFDiscoverConfirmDiscover
PASS:		*ds:ax	= chunk array of DiscoveryLog
RETURN:		carry clear if no conflicts:
		carry set if conflicts:

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SUFindAddressConflicts	proc	near
	.enter
	clc
	.leave
	ret
SUFindAddressConflicts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SUUpdateDiscoveryCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store away the DiscoveryLogBlock.

CALLED BY:	SFDiscoverConfirmDiscover
PASS:		^hdx	= DiscoveryLogBlock from Irlap Driver
			(or 0 if discovery wasn't carried out, probably
			because of DLF_MEDIA_BUSY discovery indication).
		*ds:ax	= cache (chunk array of DiscoveryLog)
RETURN:		*ds:ax 	= discovery logs from ^hdx.
			  ds may have moved
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SUUpdateDiscoveryCache	proc	near
	uses	ax,bx,cx,es,si,di,dx,bp
	.enter
	mov	si, ax			;*ds:si = cache array
	call	ChunkArrayZero
	mov	bx, dx	
	;
	; check for the case where there's no discovery log block.
	;
	tst	bx
	jz	reallyExit

	call	MemLock
	mov	es, ax			;es = DiscoveryLogBlock

	mov_tr	dx, ax			; dx <- log block, for loop
	;
	; Check if log is empty
	;
	test	es:[DLB_flags], mask DBF_LOG_RCVD
	jz	exit
	mov	cl, es:[DLB_lastIndex]
	clr	ch
	mov	di, offset DLB_log
logLoop:
	test	es:[di].DL_flags, mask DLF_VALID
	jz	nextEntry
	push	si, cx
	push	di
	;
	; We're such cheaters!  Let's just put one DiscoveryLog into 
	; the array.
	;
	call	ChunkArrayAppend	;ds:di = new element
	mov	bp, ds
	mov	ds, dx
	mov	es, bp			;es:di = new element
	pop	si			;ds:si = DiscoveryLog
	push	si
	mov	cx, size DiscoveryLog
	rep	movsb
	mov	ds, bp
	mov	es, dx
	pop	di
	pop	si, cx
nextEntry:
	add	di, size DiscoveryLog
	loop	logLoop

exit:
	call	MemUnlock

reallyExit:
	.leave
	ret
SUUpdateDiscoveryCache	endp


StationFsmCode	ends
