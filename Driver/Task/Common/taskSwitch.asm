COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskSwitch.asm

AUTHOR:		Adam de Boor, Sep 21, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/21/91		Initial revision


DESCRIPTION:
	Functions for suspending and resuming PC/GEOS.
		

	$Id: taskSwitch.asm,v 1.1 97/04/18 11:58:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskBeginSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the process of suspending the system by querying all
		applications that have expressed a desire to have control.

CALLED BY:	TaskSwitch, TaskDosExec
PASS:		ds = es = dgroup
		ax	= message to send to ourselves when all apps have
			  confirmed. If suspension is denied, message ax+1
			  will be dispatched, rather than ax.
		cx, dx, bp = data to send then
RETURN:		carry set if suspend is already in-progress:
			ax, cx, dx, bp	= preserved
		carry clear if suspend started:
			ax, cx, dx, bp	= destroyed
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskBeginSuspend proc	far
		.enter
		tst	ds:[continueSuspendMsg]
		jnz	error
	;
	; Record the message to be sent when continueSuspendCount reaches 0
	; 
		mov	bx, handle 0
		clr	si
		mov	di, mask MF_RECORD
		call	ObjMessage
	;
	; Store that handle.
	; 
		mov	ds:[continueSuspendMsg], di

		mov	ax, SST_SUSPEND
		mov	cx, handle 0		; notify us when confirmed
						;  or denied
		clr	dx
		mov	bp, MSG_TD_SUSPEND_CONFIRMED
		call	SysShutdown
		jc	errorNukeMessage
done:
		.leave
		ret

errorNukeMessage:
		clr	bx
		xchg	ds:[continueSuspendMsg], bx
		call	ObjFreeMessage
error:
		stc
		jmp	done
TaskBeginSuspend endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TDSuspendConfirmed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an answer from the system to our SST_SUSPEND request

CALLED BY:	MSG_TD_SUSPEND_CONFIRMED
PASS:		ds = es = dgroup
		cx	= TRUE to allow the suspend
			= FALSE to disallow the suspend
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDSuspendConfirmed method dynamic TaskDriverClass, MSG_TD_SUSPEND_CONFIRMED
		.enter
		mov	bx, ds:[continueSuspendMsg]
		jcxz	abort
	;
	; Suspend confirmed. Dispatch the recorded message to its proper
	; place after finishing with the suspend.
	; 
		mov	di, offset suspendFailedMsg
		push	bx
		call	DosExecSuspend
		pop	bx
		jc	notifyAndAbort

		clr	ax, cx, si
;sendMessage:
	;
	; Mark message dispatched and dispatch it.
	; 
		mov	ds:[continueSuspendMsg], 0
		mov	di, mask MF_CALL
		call	MessageDispatch
done:
		.leave
		ret
notifyAndAbort:
	;
	; Notify the user of why the suspend was denied using an error dialog
	; 
		mov	bx, handle TaskStrings
		call	MemLock

		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags,CustomDialogBoxFlags <
			1,			; CDBF_SYSTEM_MODAL
			CDT_ERROR,		; CDBF_TYPE
			GIT_NOTIFICATION,	; CDBF_RESPONSE_TYPE
			0
		>
		mov	ds, ax
		assume	ds:TaskStrings
		mov	ss:[bp].SDP_customString.segment, ds
		mov	ax, ds:[unableToSuspendMsg]
		mov	ss:[bp].SDP_customString.offset, ax
		mov	ss:[bp].SDP_stringArg1.segment, es
		mov	ss:[bp].SDP_stringArg1.offset, offset suspendFailedMsg
		movdw	ss:[bp].SDP_helpContext, 0
		call	UserStandardDialog
		
		call	MemUnlock		; unlock TaskStrings
		segmov	ds, es
		assume	ds:dgroup
		mov	bx, ds:[continueSuspendMsg]		
abort:
	;
	; Dispatch the recorded message + 1 to signal the thing was
	; aborted. 
	;
		mov	ds:[continueSuspendMsg], 0
		push	cs			; push callback routine
		mov	di, offset TDSCAbortCallback
		push	di
		mov	si, 0			; destroy event
		call	MessageProcess
		jmp	short done

TDSuspendConfirmed endm

TDSCAbortCallback	proc	far
	inc	ax				; abort message
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
TDSCAbortCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskResume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the system back to life again after being suspended.

CALLED BY:	TaskSwitch, TaskDosExec
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskResume	proc	far
		uses	ax, bx, cx, dx, si, di, bp, ds, es
		.enter
	;
	; Tell the kernel to resurrect everything.
	; 
		call	DosExecUnsuspend
		
	;
	; Now refresh the screen.
	; 
		call	ImGetPtrWin
		mov	cx, di
		mov	dx, di
		mov	bx, handle ui
		mov	ax, MSG_META_INVAL_TREE
		clr	di
		call	ObjMessage
	;
	; Notify all OD's interested that we've resumed.
	;
		mov	ax, MSG_META_CONFIRM_SHUTDOWN
		clr	cx, dx
		mov	bp, GCNSCT_UNSUSPEND
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	si, GCNSLT_SHUTDOWN_CONTROL
		clr	di
		call	GCNListRecordAndSend

		.leave
		ret
TaskResume	endp

Movable		ends
