COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrCOMM
FILE:		portemulatorClose.asm

AUTHOR:		Greg Grisco, Jan 11, 1996

ROUTINES:
	Name				Description
	----				-----------
INT	PortEmulatorDisconnect		Handle sending disconnect request
INT	PortEmulatorDestroyStreams	Flush & destroy streams
INT	PortEmulatorClearNotifiers	Clear notification data
INT	PortEmulatorCleanup		Unreg from IAS, TTP, IrComm

	MSG_IRCOMM_DISCONNECT		Disconnect Indication handler
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/11/96   	Initial revision


DESCRIPTION:
	Routines for closing the connection
		

	$Id: portemulatorClose.asm,v 1.1 97/04/18 11:46:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PortEmulatorCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorDisconnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle sending the disconnect request.

CALLED BY:	INTERNAL (PortEmulatorClose)
PASS:		bx	= unit number
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorDisconnect	proc	far
	uses	ax,bx,cx,dx,di,bp
	.enter

EC <	call	ECValidateUnitNumber					>

	mov	di, bx				; di = unit index

	mov	bl, IDR_USER_REQUEST		; user requested disconnect
	call	IrCommDisconnectRequest

	.leave
	ret
PortEmulatorDisconnect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorDestroyStreams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the streams.  If STREAM_LINGER was set, then
		the stream driver will send out the appropriate
		notifications so that we can send any lingering data.
		We also need to wait until TTP and IrLMP have sent all
		of their buffered data.

CALLED BY:	INTERNAL (PortEmulatorClose)
PASS:		ax	= STREAM_LINGER/STREAM_DISCARD
		bx	= unit number
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

NOTES:
	This routine should never be called on the irlmp thread since
	it blocks waiting for the irlmp thread to return status.

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorDestroyStreams	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	call	ECValidateUnitNumber					>

	PSem	ds, streamSemaphore

	clr	si				; will 0 stream token
	xchg	si, bx				; si = unit number
	;
	; Destroy the input stream
	;
	xchg	bx, ds:[si].ISPD_inStream	; bx = stream token
	tst	bx
	jz	flush				; jmp if doesn't exist
	mov	di, DR_STREAM_DESTROY
	call	StreamStrategy
	;
	; If a timer is set, then stop it
	;
if 0
;
; Don't trust the flag.  There could be a timer just waiting to go
; off.
;
	test	ds:[si].ISPD_send, mask ICSF_TIMER
	jz	noTimer
endif
	and	ds:[si].ISPD_send, not mask ICSF_TIMER
	push	ax
	mov	ax, ds:[si].ISPD_timerID
	mov	bx, ds:[si].ISPD_timerHandle
	call	TimerStop
	pop	ax
;noTimer:
	call	PortEmulatorDestroyQueue
	;
	; Destroy the output stream.  Any data in the stream will be
	; flushed if STREAM_LINGER is requested.  If the connection is
	; already gone (e.g. disconnect indication), the data notifier
	; will discard the data when IrCommDataRequest fails.
	;
	push	si
	clr	bx
	xchg	bx, ds:[si].ISPD_outStream
EC <	tst	bx							>
EC <	ERROR_E		-1						>
	call	StreamStrategy
	pop	si				; si = unit number

	cmp	ax, STREAM_DISCARD
	je	done
flush:
	;
	; We need to wait here until all of the TinyTP & IrLMP buffers
	; are empty.
	;
	mov	bx, si
EC <	call	ECValidateUnitNumber					>
waitLoop:
	mov	si, ds:[bx].ISPD_client
	call	IrCommStatusRequest		; carry if data lingering
	jnc	done
	jmp	waitLoop
done:
	VSem	ds, streamSemaphore
	.leave
	ret
PortEmulatorDestroyStreams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorClearNotifiers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the notifier data.

CALLED BY:	IrCommClose
PASS:		bx	= unit number
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorClearNotifiers	proc	far
	.enter

EC <	call	ECValidateUnitNumber					>
	Assert	dgroup	ds

	mov	ds:[bx].ISPD_modemEvent.SN_type, SNM_NONE
	mov	ds:[bx].ISPD_dataEvent.SN_type, SNM_NONE
	mov	ds:[bx].ISPD_errorEvent.SN_type, SNM_NONE
	mov	ds:[bx].ISPD_passiveEvent.SN_type, SNM_NONE

	.leave
	ret
PortEmulatorClearNotifiers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorCleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister from TinyTP and destroy the IAS object.

CALLED BY:	INTERNAL (PortEmulatorClose)
PASS:		bx	= unit number
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorCleanup	proc	far
	uses	bx,cx,dx,bp,si,di
	.enter

EC <	call	ECValidateUnitNumber					>
	Assert	dgroup ds
	;
	; Unregister from TinyTP.  This will remove the IAS entry.
	;
	clr	si
	xchg	si, ds:[bx].ISPD_client
	tst	si
	jz	done
	call	TTPUnregister
if ERROR_CHECK
	;
	; We should not be returned an error since we always
	; disconnect before calling this routine.
	;
	ERROR_C	-1
endif
done:
	.leave
	ret
PortEmulatorCleanup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PortEmulatorDestroyQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the event queue

CALLED BY:	PortEmulatorDestroyStreams
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PortEmulatorDestroyQueue	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	clr	bx
	xchg	ds:[threadHandle], bx		; bx <- process thread
	clr	si				; sending to thread
	clr	dx, bp, cx			; no ID, nor ack OD
	mov	ax, MSG_META_DETACH
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
PortEmulatorDestroyQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPIrcommDisconnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We have received a disconnect indication and must now
		destroy the streams.  We handle this with a method
		on the process thread since we need the thread to
		block while we wait for irlmp to return status
		information to us. 

CALLED BY:	MSG_IRCOMM_DISCONNECT
PASS:		bp	= unit number
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/21/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPIrcommDisconnect	method dynamic IrCommProcessClass, 
					MSG_IRCOMM_DISCONNECT
	uses	ax, cx, dx, bp
	.enter

	mov	bx, bp
EC <	call	ECValidateUnitNumber					>
	call	IrCommGetDGroupDS		; ds = dgroup

	mov	ax, STREAM_DISCARD
	call	PortEmulatorDestroyStreams
	;
	; If the disconnect indication is due to our connect request,
	; then the application thread is blocked on the connectionSem.
	; If we were connected, then don't free the lock again.
	;
	cmp	ds:[bx].ISPD_state, ICFS_WAITI
	jne	notBlocked
	VSem	ds, connectionSem, TRASH_AX
notBlocked:

	.leave
	ret
ICPIrcommDisconnect	endm

PortEmulatorCode	ends
