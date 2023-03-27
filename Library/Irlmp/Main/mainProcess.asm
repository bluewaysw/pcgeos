COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrLMP Library
FILE:		mainProcess.asm

AUTHOR:		Chung Liu, Mar  8, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 8/95   	Initial revision


DESCRIPTION:
	Methods for IrlmpProcessClass.

	$Id: mainProcess.asm,v 1.1 97/04/05 01:08:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpAddRemoveShutdownControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add or remove this thread from the shutdown-control
		system-wide GCN list

CALLED BY:	(INTERNAL) IrlmpMetaAttach, IrlmpMetaDetach
PASS:		si	= non-zero to add, zero to remove
RETURN:		cx	= current thread handle
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpAddRemoveShutdownControl proc	near
	.enter
	mov	ax, TGIT_THREAD_HANDLE
	clr	bx
	call	ThreadGetInfo
	mov_tr	cx, ax

	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_SHUTDOWN_CONTROL
	tst	si
	jz	remove
	call	GCNListAdd
done:
	.leave
	ret
remove:
	call	GCNListRemove
	jmp	done
IrlmpAddRemoveShutdownControl endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpMetaAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init the process thread.

CALLED BY:	MSG_META_ATTACH
PASS:		ds	= dgroup
		es 	= segment of IrlmpProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Add to shutdown list, so we have a chance to clean up.
	Create a secondary queue for Station Control
	Create and init endpoint block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpMetaAttach	method dynamic IrlmpProcessClass, 
					MSG_META_ATTACH
	.enter
	;
	; Let superclass do its thing. We have to set DS = SS to allow DS to
	; be "fixed up" by ObjCallSuperNoLock. Alas.
	;
	push	ds
	segmov	ds, ss
	mov	di, offset IrlmpProcessClass
	call	ObjCallSuperNoLock
	pop	ds
	;
	; Add ourselves to the shutdown-control list.
	;
	mov	si, 1
	call	IrlmpAddRemoveShutdownControl
	;
	; Set ourselves as the burden thread for our object blocks.
	;
	mov	ax, cx
	mov	bx, handle IrlmpFsmObjects
	call	MemModifyOtherInfo

	mov_tr	ax, cx
	mov	bx, handle IasFsmObjects
	call	MemModifyOtherInfo
	;
	; Initialize assorted stuff
	;
	call	UtilsInit
	jc	error
	;
	; Initialize IAS client FSM
	;
	mov	ax, MSG_ICF_INITIALIZE
	mov	di, mask MF_CALL
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage
	;
	; Initialize statically defined FSM objects.
	;
	mov	ax, MSG_SF_INITIALIZE
	call	StationFsmCall

	mov	ax, MSG_IAF_INITIALIZE
	call	IrlapFsmCall
	
exit:
	mov	ax, ds
	mov	bx, offset mainServerWaitQ
	call	ThreadWakeUpQueue

	.leave
	ret

error:
	;
	; Something in the library could not be properly initialized.
	; Probably the HugeLMem block could not be created for lack
	; of enough memory.  It is not clear to me what to do at this
	; point.
	; 
	;XXX
	jmp	exit
IrlmpMetaAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanup what is necessary before process thread exits.

CALLED BY:	MSG_META_DETACH
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Remove from shutdown control.
	Free Station Control's secondary queue
	Free the endpoint block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpMetaDetach	method dynamic IrlmpProcessClass, 
					MSG_META_DETACH
	.enter
	;
	; Remove ourselves from the shutdown list, since we're going away.
	;
	clr	si
	call	IrlmpAddRemoveShutdownControl

	;
	; cleanup IAS client FSM
	;
	mov	ax, MSG_ICF_EXIT
	mov	di, mask MF_CALL
	mov	bx, handle IrlmpIasClientFsm
	mov	si, offset IrlmpIasClientFsm
	call	ObjMessage

	;
	; Free Station Control's secondary queue.
	;
	mov	ax, MSG_SF_CLEANUP
	call	StationFsmCall

	;
	; Clean up the stuff we did in Utils
	;
	call	UtilsExit
	
	mov	ax, ds
	mov	bx, offset mainServerWaitQ
	call	ThreadWakeUpQueue

	;
	; Let superclass do its thing. We have to set DS = SS to allow DS to
	; be "fixed up" by ObjCallSuperNoLock. Alas.
	;
	push	ds
	segmov	ds, ss
	mov	ax, MSG_META_DETACH
	mov	di, offset IrlmpProcessClass
	call	ObjCallSuperNoLock
	pop	ds

	.leave
	ret
IrlmpMetaDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpMetaConfirmShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanup and confirm shutdown.

CALLED BY:	MSG_META_CONFIRM_SHUTDOWN
PASS:		*ds:si	= IrlmpProcessClass object
		ds:di	= IrlmpProcessClass instance data
		bp	= GCNShutdownControlType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpMetaConfirmShutdown	method dynamic IrlmpProcessClass, 
					MSG_META_CONFIRM_SHUTDOWN
	uses	bx
	.enter
	cmp	bp, GCNSCT_UNSUSPEND
	je	exit
	;
	; Check if someone already denied shutdown.
	;
	mov	ax, SST_CONFIRM_START
	call	SysShutdown
	jc	exit				;someone else denied shutdown
	;
	; Perform IrLMP Library cleanup.
	;
	; XXX

	;
	; Confirm shutdown.
	;
	mov	cx, -1				;non-zero to allow shutdown
	mov	ax, SST_CONFIRM_END
	call	SysShutdown
	
exit:
	.leave
	ret
IrlmpMetaConfirmShutdown	endm

InitCode	ends

IrlmpCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpProcessCreateLsapFSM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Instantiate a LSAP Connection Control FSM.

CALLED BY:	MSG_IP_CREATE_LSAP_FSM
PASS:		*ds:si	= IrlmpProcessClass object
		ds:di	= IrlmpProcessClass instance data
RETURN:		^lcx:dx	= new IrlmpLsapConnControlClass object
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpProcessCreateLsapFSM	method dynamic IrlmpProcessClass, 
					MSG_IP_INSTANTIATE_LSAP_FSM
	uses	es,di
	.enter
	mov	bx, handle IrlmpFsmObjects
	segmov	es, <segment LsapFsmClass>, di
	mov	di, offset LsapFsmClass
	call	ObjInstantiate		;^lbx:si = LSAP FSM
					;  ds may have moved.
	movdw	cxdx, bxsi
	.leave
	ret
IrlmpProcessCreateLsapFSM	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpProcessStartIasServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the IAS server thread if it doesn't exist.  
		Then create a new FSM for the IAS server connection.

CALLED BY:	MSG_IP_START_IAS_SERVER
PASS:		*ds:si	= IrlmpProcessClass object
		ds:di	= IrlmpProcessClass instance data
		ds:bx	= IrlmpProcessClass object (same as *ds:si)
		es 	= segment of IrlmpProcessClass
		ax	= message #
		^ldx:bp	= data buffer
		cx	= data size
		si	= data offset
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/13/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpProcessStartIasServer	method dynamic IrlmpProcessClass, 
					MSG_IP_START_IAS_SERVER
		.enter
	;
	; Check to see if we have a server already going. 
	; If so then don't create the thread.
	;
		call	UtilsLoadDGroupDS
		PSem	ds, iasServerSem

		tst	ds:[iasServerCount]
		jnz	haveThread

	;
	; Create an event thread to handle the IAS Server FSM
	; 
		push	bp
		mov	cx, segment IasServerProcessClass
		mov	dx, offset IasServerProcessClass
		;clr	bp			; default stack size
		mov	bp, 1024
		mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD
		mov	di, mask MF_CALL 
		call	MainMessageServerThread	; ax = new thread
						; handle
		pop	bp

NEC <		jc	done						>
EC<		ERROR_C	IRLMP_CANNOT_CREATE_IAS_SERVER_THREAD		>

	;
	; Create an ObjBlock to have objects run on the thread
	; 	
		mov	ds:[iasServerThread], ax

		mov_tr	bx, ax			; bx <- current thread
						; to run block
		call	UserAllocObjBlock	; bx <- handle of block

		mov_tr	ds:[iasServerBlock], bx

	;
	; Create an IasServerFsm to run the connection.
	; We must free the semaphore here, because irlmp:1
	; may try to grab it.  And we are blocking here
	; on irlmp:1 when we create the object.
	; 
haveThread:
		inc	ds:[iasServerCount]
		VSem	ds, iasServerSem

		segmov	es, <segment IasServerFsmClass>, di
		mov	di, offset IasServerFsmClass
		mov	bx, ds:[iasServerBlock]

		call	ObjInstantiate	; si <- handle of new object
	;
	; Register the server with Irlmp.
	;
		push	bx, si		; save fsm object
		mov	cl, IRLMP_IAS_LSAP_SEL
		mov_tr	bx, si			; bx <- ptr to fsm
		mov	dx, vseg IasServerCallback
		mov	ax, offset IasServerCallback
		call	IrlmpRegister		; si <- client handle
		pop	bx, cx			; ^lbx:cx <- fsm object
	;
	; Tell the Ias Server FSM what it's handle is to the
	; Irlmp library
	;
		xchg	cx, si			; ^lbx:si <- fsm object
						; cx <- handle to irlmp 
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_ISF_SET_SERVER_IRLMP_HANDLE
		call	ObjMessage
done::
		
		.leave
		ret

IrlmpProcessStartIasServer	endm

IrlmpCode	ends








