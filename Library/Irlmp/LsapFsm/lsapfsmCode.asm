COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		lsapfsmCode.asm

AUTHOR:		Chung Liu, Mar 21, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95   	Initial revision


DESCRIPTION:
	Methods for LsapFsm.

	$Id: lsapfsmCode.asm,v 1.1 97/04/05 01:06:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LsapFsmCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFSetEndpoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the endpoint associated with this FSM.

CALLED BY:	MSG_LF_SET_ENDPOINT
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data
		dx	= lptr IrlmpEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFSetEndpoint	method dynamic LsapFsmClass, 
					MSG_LF_SET_ENDPOINT
	.enter
	mov	ds:[di].LFI_clientHandle, dx
	.leave
	ret
LFSetEndpoint	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFCheckIfConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if LsapFsm is in disconnected state.

CALLED BY:	MSG_LF_CHECK_IF_CONNECTED
PASS:		*ds:si	= LsapFsmClass object
		ds:di	= LsapFsmClass instance data

RETURN:		carry clear if disconnected
		carry set if not disconnected
		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	4/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFCheckIfConnected	method dynamic LsapFsmClass, 
					MSG_LF_CHECK_IF_CONNECTED
	.enter
	cmp	ds:[di].LFI_state, LFS_DISCONNECTED
	je	disconnected
	stc				;not disconnected
exit:
	.leave
	ret
disconnected:
	clc
	jmp	exit
LFCheckIfConnected	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LFMetaFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take care of destroying the server thread when the last
		client is unregistered

CALLED BY:	MSG_META_FINAL_OBJ_FREE
PASS:		*ds:si	= LsapFsm object
		ds:di	= LsapFsmInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	When the object is finally free, we want to destroy the thread.
	But the block may be doing stuff when we want to detach
	and a new thread may come along and inherit the libraries objects.
	This causes a conflict with one thread doing it's stuff and
	the new thread trying to do it's stuff (exactly what, I'm unsure :)
	But I know that the block is locked by this thread,
	and that screws up the lock count for the new thread.
	So the IrlmpClientGone is called after some clean up to make
	everything nifty.		-- AC 3/14/96
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 9/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LFMetaFinalObjFree method dynamic LsapFsmClass, MSG_META_FINAL_OBJ_FREE



	;
	; Get the current thread handle
	;
	mov	ax, TGIT_THREAD_HANDLE
	clr	bx
	call	ThreadGetInfo			; ax <- thread handle

	;
	; Tell this thread to call IrlmpClientGone when it's
	; finished up doing everything else
	;
	mov_tr	bx, ax
	mov	ax, MSG_PROCESS_CALL_ROUTINE
	mov	di, mask MF_FORCE_QUEUE or mask MF_STACK	
	mov	dx, size ProcessCallRoutineParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].PCRP_address.segment, vseg IrlmpClientGone
	mov	ss:[bp].PCRP_address.offset, offset IrlmpClientGone
	call	ObjMessage
	add	sp, dx

	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	di, offset LsapFsmClass
	GOTO	ObjCallSuperNoLock
LFMetaFinalObjFree endm

LsapFsmCode	ends
