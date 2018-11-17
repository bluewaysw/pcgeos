COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		sysNotification.asm

AUTHOR:		Adam de Boor, Apr 15, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/15/94		Initial revision


DESCRIPTION:
	Functions for reliable-but-potentially-delayed notification of
	various subsystems.
		

	$Id: sysNotification.asm,v 1.1 97/04/05 01:14:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SysNotification	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysPNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	P the semaphore for a SubsystemNotificationEntry

CALLED BY:	(INTERNAL)
PASS:		si	= SysSubsystemType
RETURN:		ds	= dgroup
DESTROYED:	nothing
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysPNotification proc	near
		.enter
		LoadVarSeg	ds
		PSem	ds, [sysNotificationTable][si].SNE_sem
		.leave
		ret
SysPNotification endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysVNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	V the semaphore for a SubsystemNotificationEntry

CALLED BY:	(INTERNAL)
PASS:		ds	= dgroup
		si	= SysSubsystemType
RETURN:		nothing
DESTROYED:	nothing (carry flag preserved, all others trashed)
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysVNotification proc	near
		.enter
		VSem	ds, [sysNotificationTable][si].SNE_sem
		.leave
		ret
SysVNotification endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSubsystemType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC: Make sure the passed subsystem is a valid one

CALLED BY:	(INTERNAL)
PASS:		si	= SysSubsystemType
RETURN:		only if si is valid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECCheckSubsystemType proc near
		.enter
		Assert	etype, si, SysSubsystemType
	CheckHack <SysSubsystemType lt 256>
		push	dx, ax
		mov	ax, si
		mov	dl, 9
		div	dl
		tst	ah
		ERROR_NZ	NOT_VALID_MEMBER_OF_ENUMERATED_TYPE
		pop	dx, ax
		.leave
		ret
ECCheckSubsystemType endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysSendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification to a subsystem. The notification may be
		delayed until the subsystem is actually loaded, or dropped
		on the floor if the subsystem will never be loaded

CALLED BY:	(GLOBAL)
PASS:		si	= SysSubsystemType
		di	= notification type (specific to subsystem)
		ax, bx, cx, dx = notification data (specific to subsystem)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	queue handle will be allocated for subsystem if not hooked
     			and not ignored and has no queue yet.
		event handle will be allocated if notifications being queued

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysSendNotification proc	far
		uses	ds, bp
		.enter
EC <		call	ECCheckSubsystemType				>
		call	SysPNotification
	;
	; For any memory blocks, we need to mark them sharable and owned by
	; the kernel, the latter so they don't go away until the notification
	; happens, and the former so when they're locked down by something
	; other than the kernel, it doesn't blow up in the locker's face.
	; 
	irp	reg, <AX,BX,CX,DX>
	    local	foo
		test	di, mask SNT_&reg&_MEM
		jz	foo
	    ifdif <reg>, <BX>
		xchg	reg, bx
	    endif
		ornf	ds:[bx].HM_flags, mask HF_SHARABLE
		mov	ds:[bx].HM_owner, handle 0
	    ifdif <reg>, <BX>
		xchg	reg, bx
	    endif
foo:
	endm

		tst	ds:[sysNotificationTable][si].SNE_routine.high
		jz	notHooked
	;
	; Notification has been hooked, so call the routine. Easiest to just
	; push the vfptr on the stack and use our friend ProcCallFixedOrMovable:
	; The Stack Version That Pops Its Arguments to transfer control.
	; Once the routine is pushed, we can release the sem and rely on the
	; notification routine to provide its own synchronization.
	; 
		test	ds:[sysNotificationTable][si].SNE_flags, 
				mask SNF_USE_STACK
		jz	doCall
		push	si, di, ax, bx, cx, dx
doCall:
		pushdw	ds:[sysNotificationTable][si].SNE_routine
		call	SysVNotification
		call	PROCCALLFIXEDORMOVABLE_PASCAL
done:
		.leave
		ret

notHooked:
	;
	; The thing hasn't been hooked yet. Three things to discriminate among:
	; 	- notifications ignored (low word is -1; can just return)
	; 	- queue not allocated (low word is 0; need to alloc queue, then
	;	  queue notification)
	; 	- queue allocated (low word is anything else; just queue the
	;	  notification)
	;
		mov	bp, ds:[sysNotificationTable][si].SNE_routine.low
		inc	bp
		jz	release	; => -1 == notification s/b ignored
		dec	bp
		jnz	queueIt	; => not 0, so have queue handle
	;
	; Allocate a queue for the beast, setting the queue to be owned by the
	; kernel (please).
	; 
		mov	bp, bx
		call	GeodeAllocQueue
		mov	ds:[bx].HQ_owner, handle 0
		mov	ds:[sysNotificationTable][si].SNE_routine.low, bx
		xchg	bx, bp
queueIt:
	;
	; Rearrange registers for the queueing:
	; 	bx (notification data) goes into bp
	; 	di (notification type) goes into si
	; 	si (subsystem) is recreated later
	; 
		xchg	bx, bp
		push	si
		mov	si, di
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		mov	di, si
		pop	si
		xchg	bx, bp
release:
		call	SysVNotification
		jmp	done
SysSendNotification endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysHookNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Arrange for notifications for the given subsystem to go to
		the given routine.

CALLED BY:	(GLOBAL)
PASS:		si	= SysSubsystemType
		cx:dx	= vfptr of routine to receive the notifications
RETURN:		carry set if notification already hooked or ignored
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysHookNotification proc	far
		uses	ax
		.enter
		clr	ax		; call routine with args in registers
		call	SysHookNotificationInternal
		.leave
		ret
SysHookNotification endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysHookNotificationInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal version for both C and ASM notification routines

CALLED BY:	(INTERNAL) SysHookNotification, SYSHOOKNOTIFICATION
PASS:		si	= SysSubsystemType
		cx:dx	= vfptr of routine
		al	= SubsystemNotificationFlags
RETURN:		carry set if already hooked or ignored
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysHookNotificationInternal		proc	far
routine		local	fptr			push cx, dx
subsystem	local	SysSubsystemType	push si
flags		local	word			push ax
		uses	ds, bx, cx, dx, bp, di
		.enter
EC <		call	ECCheckSubsystemType				>
		Assert	vfptr, cxdx
		call	SysPNotification
		tst	ds:[sysNotificationTable][si].SNE_routine.high
		jnz	fail
		mov	bx, ds:[sysNotificationTable][si].SNE_routine.low
		inc	bx
		jz	fail
	;
	;	Set the flags now, so SysHookNotification callback knows to
	;	pass args to the callback on the stack, in case there are
	;	events to be flushed.
	;
		mov	ax, ss:[flags]
		mov	ds:[sysNotificationTable][si].SNE_flags, al

		dec	bx
		jnz	flush		; => there's a queue that contains
					;  notifications that must be delivered
setRoutine:
		movdw	ds:[sysNotificationTable][si].SNE_routine, cxdx
		clc
done:
		call	SysVNotification
		.leave
		ret
fail:
	;
	; Subsystem already hooked or ignored -- return carry set w/o changing
	; anything.
	; 
		stc
		jmp	done

flush:
	;
	; Need to call the routine with the notifications on the queue. We
	; want to be sure to release the subsystem entry while calling the
	; routine, so we leave the table pointing to the queue until we
	; determine, with the entry locked, that there are no more notifications
	; pending...
	; 
		mov	di, bp		; pass frame pointer in di, always
flushLoop:
	;
	; See if there are any more notifications to be sent.
	; 
		call	GeodeInfoQueue
		tst	ax
		jz	flushDone	; => no
	;
	; Get the next notification off the queue, please.
	; 
		call	QueueGetMessage	; ax <- event

	;
	; Make the call. The callback will release the subsystem table entry
	; before calling the notification routine. (Because the table entry
	; continues to hold the event queue, any notifications that come in
	; while we're dispatching this one will be placed at the end of the
	; queue for us to pick up, eventually)
	; 
		push	bx		; save queue handle
		mov_tr	bx, ax		; bx <- event handle
		push	cs
		mov	ax, offset SysHookNotificationCallback
		push	ax		; push callback routine
		clr	si		; destroy event
		call	MessageProcess
	;
	; Restore registers and grab the table entry for the next iteration.
	; 
		mov	bp, di		; bp <- frame pointer again
		pop	bx
		mov	si, ss:[subsystem]
		call	SysPNotification
		jmp	flushLoop

flushDone:
		call	GeodeFreeQueue
		movdw	cxdx, ss:[routine]
		jmp	setRoutine
SysHookNotificationInternal		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysHookNotificationCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine for dispatching a queued notification
		to the actual notification routine for a subsystem.

CALLED BY:	(INTERNAL) SysHookNotification via MessageProcess
PASS:		ax, cx, dx, bp	= notification data
		ss:di	= inherited stack frame
		si	= notification type
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, si, di
SIDE EFFECTS:	notification table entry released

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysHookNotificationCallback proc	far
		.enter	inherit	SysHookNotificationInternal
EC <		call	AssertDSKdata					>
		mov	bx, bp		; bx <- notification data
		mov	bp, di		; bp <- frame pointer
		mov	di, si		; di <- notification type
		mov	si, ss:[subsystem]

		test	ds:[sysNotificationTable][si].SNE_flags, 
				mask SNF_USE_STACK
		jz	doCall
		push	si, di, ax, bx, cx, dx
doCall:
		call	SysVNotification; release the table slot during the call
		pushdw	ss:[routine]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		.leave
		ret
SysHookNotificationCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysUnhookNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop receiving notification for a subsystem. The call is
		ignored unless the passed vfptr is actually the routine
		that was receiving the notifications.

CALLED BY:	(GLOBAL)
PASS:		si	= SysSubsystemType
		cx:dx	= vfptr of routine that was getting notifications
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysUnhookNotification proc	far
		uses	ds
		.enter
EC <		call	ECCheckSubsystemType				>
		Assert	vfptr, cxdx
		call	SysPNotification
		cmpdw	ds:[sysNotificationTable][si].SNE_routine, cxdx
		jne	done
		clrdw	ds:[sysNotificationTable][si].SNE_routine
done:
		call	SysVNotification
		.leave
		ret
SysUnhookNotification endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysIgnoreNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Drop all past and future notifications for the indicated
		subsystem on the floor. The subsystem will not be activated,
		thus making the notifications unnecessary.

CALLED BY:	(GLOBAL)
PASS:		si	= SysSubsystemType
RETURN:		carry set if subsystem already hooked
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysIgnoreNotification proc	far
		uses	ds, bx, ax, cx, dx, bp
		.enter
EC <		call	ECCheckSubsystemType				>
		call	SysPNotification
		tst	ds:[sysNotificationTable][si].SNE_routine.high
		stc			; assume hooked...
		jnz	done
	;
	; Mark the thing as ignored and nuke any queue and any events in it
	; 
		mov	bx, -1
		xchg	ds:[sysNotificationTable][si].SNE_routine.low, bx
		inc	bx
		jz	doneOK		; => already ignored
		dec	bx
		jz	doneOK		; => nothing to nuke
	;
	; Need to free memory blocks in the queue, too, so can't use just
	; GeodeFreeQueue...
	; 
		push	si
nukeLoop:
		call	GeodeInfoQueue
		tst	ax
		jz	nukeDone	; => no more notifications

		push	bx
		call	QueueGetMessage
		mov_tr	bx, ax		; bx <- event
		push	cs
		mov	ax, offset nukeCallback
		push	ax		; push callback routine
		call	MessageProcess
		pop	bx
		jmp	nukeLoop


nukeDone:
		pop	si
		call	GeodeFreeQueue
doneOK:
		clc
done:
		call	SysVNotification
		.leave
		ret

	;--------------------
	; Pass:	ax, cx, dx	= notification data
	; 	bp		= notification data usually in BX
	; 	si		= SysNotificationType
	; Return:	nothing
	; 
nukeCallback:
		mov	bx, bp		; bx <- notification data BX

	irp	reg, <BX,AX,CX,DX>
	    local	foo
		test	si, mask SNT_&reg&_MEM
		jz	foo
	    ifdif <reg>,<BX>
		mov	bx, reg
	    endif
		call	MemFree
foo:
	endm
		retf
SysIgnoreNotification endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SYSSENDNOTIFICATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification to a subsystem from C

CALLED BY:	(GLOBAL)
PARAMS:		void (SysSubsystemType subsys, SysNotificationType notif,
			word axparam, word bxparam, word cxparam, word dxparam)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
SYSSENDNOTIFICATION proc far	subsys:SysSubsystemType,
		    		notif:SysNotificationType,
				axparam:word,
				bxparam:word,
				cxparam:word,
				dxparam:word
		uses	si, di
		.enter
		mov	ax, ss:[axparam]
		mov	bx, ss:[bxparam]
		mov	cx, ss:[cxparam]
		mov	dx, ss:[dxparam]
		mov	si, ss:[subsys]
		mov	di, ss:[notif]
		call	SysSendNotification
		.leave
		ret
SYSSENDNOTIFICATION endp
SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SYSHOOKNOTIFICATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hook notification for a subsystem

CALLED BY:	(GLOBAL)
PARAMS:		Boolean (SysSubsystemType subsys, void _far (*routine)())
RETURN:		TRUE if hooked successfully
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
SYSHOOKNOTIFICATION proc	far
				; bx <- subsys, cx:dx <- routine, ax <- nuked
		C_GetThreeWordArgs	bx, cx, dx,  ax
		xchg	si, bx	; si <- subsys, bx <- save si
		mov	ax, mask SNF_USE_STACK
		call	SysHookNotificationInternal
		mov	si, bx	; restore si
		mov	ax, 0	; assume failure (don't biff carry)
		jc	done	; => assumption correct
		dec	ax	; actually successful
done:
		ret
SYSHOOKNOTIFICATION endp
SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SYSUNHOOKNOTIFICATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unhook notification for a subsystem

CALLED BY:	(GLOBAL)
PARAMS:		void (SysSubsystemType subsys, void _far (*routine)())
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
SYSUNHOOKNOTIFICATION proc	far
				; ax <- subsys, cx:dx <- routine, bx <- nuked
		C_GetThreeWordArgs	bx, cx, dx,  ax
		xchg	si, bx	; si <- subsys, bx <- save si
		call	SysUnhookNotification
		mov	si, bx	; restore SI
		ret
SYSUNHOOKNOTIFICATION endp
SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SYSIGNORENOTIFICATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Drop all past and future notifications for the indicated
		subsystem on the floor.

CALLED BY:	(GLOBAL)
PARAMS:		Boolean (SysSubsystemType subsys)
RETURN:		TRUE if subsystem successfully ignored (FALSE if already
			hooked)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SYSIGNORENOTIFICATION proc	far
		C_GetOneWordArg	ax,  bx, cx
		xchg	si, ax	; si <- subsys, ax <- save si
		call	SysIgnoreNotification
		mov	si, ax	; restore si

		mov	ax, 0	; assume failure
		jc	done
		dec	ax
done:
		ret
SYSIGNORENOTIFICATION endp

SysNotification	ends
