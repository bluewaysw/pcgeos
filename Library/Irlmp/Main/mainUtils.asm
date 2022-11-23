COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mainUtils.asm

AUTHOR:		Adam de Boor, Jun  6, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 6/95		Initial revision


DESCRIPTION:
	Utility routines for use by other modules.
		

	$Id: mainUtils.asm,v 1.1 97/04/05 01:08:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainServerThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate an event queue and attach to it

CALLED BY:	(INTERNAL) MainCreateServerThread via ThreadCreate
PASS:		ds = es = dgroup
RETURN:		never
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainServerThread proc	far
		call	MainCreateEventQueue
		jmp	ThreadAttachToQueue
MainServerThread endp

ResidentCode	ends

InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainCreateEventQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and prepare the event queue for the server thread.

CALLED BY:	(INTERNAL) MainServerThread
PASS:		ds	= dgroup
RETURN:		bx	= event queue
		cx:dx	= process class
DESTROYED:	ax, si, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainCreateEventQueue proc	far
		.enter
	;
	; Allocate a queue for the thread.
	;
		call	GeodeAllocQueue
	;
	; Send an ATTACH message to the thread, so the process class gets it
	; when we attach to the queue.
	;
		mov	ax, MSG_META_ATTACH
		clr	cx, dx, bp
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; Return the process class...
	;
		mov	cx, segment IrlmpProcessClass
		mov	dx, offset IrlmpProcessClass
		.leave
		ret
MainCreateEventQueue endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainCreateServerThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the server thread, now that it's needed.

CALLED BY:	(EXTERNAL) IrlmpRegister
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		In an ideal world we could just call
		MSG_PROCESS_CREATE_EVENT_THREAD on our process class, but
		of course that ends up with the server thread owned by
		God-knows-who, so...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainCreateServerThread proc	far
		uses	ax, bx, cx, dx, si, di, bp
		.enter
		mov	al, PRIORITY_STANDARD
		mov	cx, segment MainServerThread
		mov	dx, offset MainServerThread
		mov	di, MAIN_SERVER_THREAD_SIZE
		mov	bp, handle 0
		call	ThreadCreate
EC <		ERROR_C	IRLMP_CANNOT_CREATE_SERVER_THREAD		>

   		mov	ds:[mainServerThread], bx

		mov	ax, ds
		mov	bx, offset mainServerWaitQ
		call	ThreadBlockOnQueue
		.leave
		ret
MainCreateServerThread endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainDestroyServerThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the server thread and wait until it's gone enough
		to return.

CALLED BY:	(EXTERNAL) IrlmpUnregister
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainDestroyServerThread proc	far
		uses	ax, bx, cx, dx, bp, di
		.enter
		
	;
	; Exit IrLAP first so that we don't get any IrLAP indications 
	; while we're cleaning up.
	;
		mov	ax, MSG_IAF_EXIT
		call	IrlapFsmCall

		clr	bx
		xchg	ds:[mainServerThread], bx
		mov	ax, MSG_META_DETACH
		clr	cx, dx, bp
		clr	di
		call	ObjMessage
		
		mov	ax, ds
		mov	bx, offset mainServerWaitQ
		call	ThreadBlockOnQueue
		.leave
		ret
MainDestroyServerThread endp

InitCode	ends

UtilsCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainMessageServerThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the server thread

CALLED BY:	(EXTERNAL)
PASS:		ax	= message to send
		cx, dx, bp = data
		di	= MessageFlags to use
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di, possibly
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainMessageServerThread proc	far
		uses	bx
		.enter
		push	ds
		call	UtilsLoadDGroupDS
		mov	bx, ds:[mainServerThread]
		pop	ds
		call	ObjMessage
		.leave
		ret
MainMessageServerThread endp

UtilsCode	ends
