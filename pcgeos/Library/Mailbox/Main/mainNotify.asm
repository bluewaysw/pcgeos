COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mainNotify.asm

AUTHOR:		Adam de Boor, May 31, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/31/94		Initial revision


DESCRIPTION:
	Code for SST_MAILBOX notifications
		

	$Id: mainNotify.asm,v 1.1 97/04/05 01:21:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MainNotifyCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainMailboxNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate routine, based on the notification type

CALLED BY:	(GLOBAL) SysSendNotification
PASS:		di	= MailboxSubsystemNotification
		ax, bx, cx, dx = notification parameters
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainMailboxNotify proc	far
		uses	bp, di
		.enter
		andnf	di, mask SNT_NOTIFICATION
		Assert	etype, di, MailboxSubsystemNotification
		mov	bp, MSG_MP_MAILBOX_NOTIFY
		call	MNQueueNotify
		.leave
		ret
MainMailboxNotify endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPMailboxNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_MP_MAILBOX_NOTIFY
PASS:		ds	= dgroup
		ss:bp	= MailboxNotifyParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefNotifyMailbox	macro	const, rout
.assert ($-mailboxNotificationRoutines)/4 eq const, \
<Routine for const in wrong slot>
		vfptr	rout
		endm

mailboxNotificationRoutines	label vfptr
DefNotifyMailbox	MSN_APP_LOADED, InboxNotifyAppLoaded
DefNotifyMailbox	MSN_APP_NOT_LOADED, InboxNotifyAppNotLoaded
DefNotifyMailbox	MSN_NEW_FOCUS_APP, InboxNotifyNewForegroundApp
DefNotifyMailbox	MSN_NEW_IACP_BINDING, InboxNotifyNewIACPBinding
DefNotifyMailbox	MSN_REMOVE_IACP_BINDING, InboxNotifyRemoveIACPBinding
.assert ($-mailboxNotificationRoutines)/4 eq MailboxSubsystemNotification

MPMailboxNotify	method dynamic MailboxProcessClass, MSG_MP_MAILBOX_NOTIFY
		.enter
		mov	dx, ss:[bp].MBNP_dx
		mov	cx, ss:[bp].MBNP_cx
		mov	bx, ss:[bp].MBNP_bx
		mov	ax, ss:[bp].MBNP_ax
		mov	di, ss:[bp].MBNP_notification
		shl	di
		shl	di
		pushdw	cs:[mailboxNotificationRoutines][di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		.leave
		ret
MPMailboxNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainMediumNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate routine, based on the notification type

CALLED BY:	(GLOBAL) SysSendNotification
PASS:		di	= MediumSubsystemNotification
		ax, bx, cx, dx = notification parameters
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	8/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainMediumNotify proc far
		uses	bp, di
		.enter
EC <		push	di						>
EC <		andnf	di, mask SNT_NOTIFICATION			>
EC <		Assert	etype, di, MediumSubsystemNotification		>
EC <		pop	di						>
		mov	bp, MSG_MP_MEDIUM_NOTIFY
		call	MNQueueNotify
		.leave
		ret
MainMediumNotify endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MNQueueNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force-queue notification to be handled on the mailbox thread

CALLED BY:	(INTERNAL) MainMediumNotify, MainMailboxNotify
PASS:		bp	= message to queue
		ax, bx, cx, dx = notification data
		di	= notification type
RETURN:		nothing
DESTROYED:	bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MNQueueNotify	proc	near
		class	MailboxProcessClass
		.enter
		push	ax, bx, cx, dx, di
		mov	ax, bp
		mov	bp, sp
		mov	bx, handle 0
		mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	CheckHack <size MediumNotifyParams eq size MailboxNotifyParams>
		mov	dx, size MediumNotifyParams
		call	ObjMessage
		pop	ax, bx, cx, dx, di
		.leave
		ret
MNQueueNotify	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MPMediumNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Eventual handler for medium notification

CALLED BY:	MSG_MP_MEDIUM_NOTIFY
PASS:		ds	= dgroup
		ss:bp	= MediumNotifyParams
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefNotifyMedium		macro	const, rout
.assert ($-mediumNotificationRoutines)/4 eq const, \
<Routine for const in wrong slot>
		vfptr	rout
		endm
mediumNotificationRoutines	label vfptr
DefNotifyMedium	MESN_MEDIUM_AVAILABLE, MediaNotifyMediumAvailable
DefNotifyMedium	MESN_MEDIUM_NOT_AVAILABLE, MediaNotifyMediumNotAvailable
DefNotifyMedium	MESN_MEDIUM_CONNECTED, MediaNotifyMediumConnected
DefNotifyMedium	MESN_MEDIUM_NOT_CONNECTED, MediaNotifyMediumNotConnected
.assert ($-mediumNotificationRoutines)/4 eq MediumSubsystemNotification

MPMediumNotify	method dynamic MailboxProcessClass, MSG_MP_MEDIUM_NOTIFY
		.enter
		movdw	cxdx, ss:[bp].MNP_medium
		mov	bx, ss:[bp].MNP_unit
		mov	al, ss:[bp].MNP_unitType
		mov	di, ss:[bp].MNP_notification
		push	di
		andnf	di, mask SNT_NOTIFICATION
		shl	di
		shl	di
		pushdw	cs:[mediumNotificationRoutines][di]
		shr	di	; convert back to notification
		shr	di	;  type for called routine to use.
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	di
	;
	; Free the unit block, if any.
	;
		test	di, mask SNT_BX_MEM
		jz	done
		call	MemFree
done:
		.leave
		ret
MPMediumNotify	endm

MainNotifyCode	ends



