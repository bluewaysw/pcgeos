COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		adminCode.asm

AUTHOR:		Adam de Boor, May  9, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 9/94		Initial revision


DESCRIPTION:
	
		

	$Id: adminCode.asm,v 1.1 97/04/05 01:20:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetAdminFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the handle of the admin file

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		bx	= file handle
DESTROYED:	nothing
SIDE EFFECTS:	fatal-error if file not open yet

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetAdminFile	proc	far
		uses	ds, ax
		.enter
		segmov	ds, dgroup, bx
	;
	; If we're on a mailbox thread, assume we're running init code.
	; (If necessary, we can call ProcInfo to see if we're mailbox:0 and
	; only use adminInitFile then...)
	;
		call	GeodeGetProcessHandle
		cmp	bx, handle 0
		je	getInitFile

		PSem	ds, adminFileSem, TRASH_AX_BX
getFile:
		mov	bx, ds:[adminFile]
		tst	bx
		jnz	done
	;
	; File not publicly available yet, so block on adminInitQueue until
	; initialization is complete.
	;
		mov	ax, ds
		mov	bx, offset adminInitQueue
		call	ThreadBlockOnQueue
		jmp	getFile
done:
		VSem	ds, adminFileSem, TRASH_AX
exit:
		.leave
		ret

getInitFile:
		mov	bx, ds:[adminInitFile]
EC <		tst	bx						>
EC <		ERROR_Z	ADMIN_FILE_NOT_OPEN_YET				>
   		jmp	exit
MailboxGetAdminFile	endp

Resident	ends

Admin		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminLockMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the admin file's map block

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		ds	= locked map block
		bp	= memory handle
		bx	= admin file handle 
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminLockMap	proc	far
		uses	ax
		.enter
		call	MailboxGetAdminFile
		call	VMGetMapBlock
EC <		push	ax, cx, di					>
EC <		call	VMInfo						>
EC <		ERROR_C	ADMIN_MAP_BLOCK_NOT_VALID			>
EC <		cmp	di, MBVMID_MAP_BLOCK				>
EC <		ERROR_NE ADMIN_MAP_BLOCK_NOT_VALID			>
EC <		pop	ax, cx, di					>
		call	VMLock
		mov	ds, ax
		.leave
		ret
AdminLockMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetMapWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a word from the admin file's map block.

CALLED BY:	(INTERNAL)
PASS:		ax	= offset of word to fetch
RETURN:		bx	= admin file
		ax	= word from the map block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetMapWord	proc	near
		uses	ds, bp
		.enter
		call	AdminLockMap
		xchg	ax, bp
		mov	bp, ds:[bp]
		xchg	ax, bp
		call	VMUnlock
		.leave
		ret
AdminGetMapWord	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down the administrative file. Called only when no
		further use can possibly be made of the files, because the
		mailbox library is entirely unhooked from anything that might
		provoke it.

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	adminFile is set to 0 after the file has been flushed to
     			disk and closed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminExit	proc	far
		uses	bx, ax, ds
		.enter

		call	InboxExit

		mov	ax, MSG_MA_STOP_ADMIN_FILE_UPDATE_TIMER
		call	UtilSendToMailboxApp

		segmov	ds, dgroup, ax
		clr	ax, bx
		xchg	ds:[adminFile], bx
		call	VMClose

		.leave
		ret
AdminExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetInbox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the inbox DBQ

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		^vbx:di	= DBQ handle for the inbox
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetInbox	proc	far
		uses	ax
		.enter
		mov	ax, offset AMB_inbox
		call	AdminGetMapWord
		mov_tr	di, ax
		.leave
		ret
AdminGetInbox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetOutbox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the outbox DBQ

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		^vbx:di	= DBQ handle for the outbox
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetOutbox	proc	far
		uses	ax
		.enter
		mov	ax, offset AMB_outbox
		call	AdminGetMapWord
		mov_tr	di, ax
		.leave
		ret
AdminGetOutbox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetDataDriverMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the handle for the data driver map

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		ax	= DMap handle for the data driver map
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetDataDriverMap	proc	far
		uses	bx
		.enter
		mov	ax, offset AMB_dataMap
		call	AdminGetMapWord
		.leave
		ret
AdminGetDataDriverMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetTransportDriverMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the handle for the transport driver map

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		ax	= DMap handle for the transport driver map
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetTransportDriverMap	proc	far
		uses	bx
		.enter
		mov	ax, offset AMB_transMap
		call	AdminGetMapWord
		.leave
		ret
AdminGetTransportDriverMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetVMStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the handle for the vm storage map

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		bx	= admin file
		ax	= handle for the vm storage map
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetVMStore	proc	far
		.enter
		mov	ax, offset AMB_vmStore
		call	AdminGetMapWord
		.leave
		ret
AdminGetVMStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminAllocTALID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a talID for the caller. There is no guarantee that
		the ID is unique (i.e. that no message currently has an address
		marked with the ID), but it is probable that no message
		currently has an address marked with the ID.

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		ax	= talID
DESTROYED:	nothing
SIDE EFFECTS:	map block is dirtied and AMB_nextTALID is updated

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminAllocTALID	proc	far
		uses	bx, ds, bp
		.enter
		call	AdminLockMap
	;
	; Compute the ID to return next time. The ID just cycles through the
	; 15-bit space, hitting each number, other than 0, in turn.
	; 
		mov	ax, ds:[AMB_nextTALID]
		inc	ax
		and	ax, mask TID_NUMBER
		jnz	storeNext
		inc	ax			; return 1 next time, not 0
storeNext:
	;
	; Get value we're supposed to return while setting what should be
	; returned next time.
	; 
		xchg	ds:[AMB_nextTALID], ax
	;
	; Map block is, of course, now dirty.
	; 
		call	VMDirty
		call	VMUnlock
		.leave
		ret
AdminAllocTALID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetOutboxMedia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the handle for the outbox media map

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		bx	= admin file
		ax	= handle for the outbox media map
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetOutboxMedia	proc	far
		.enter
		mov	ax, offset AMB_outboxMedia
		call	AdminGetMapWord
		.leave
		ret
AdminGetOutboxMedia	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetAppTokens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the handle for the app tokens map

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		bx	= admin file
		ax	= handle for the app tokens map
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetAppTokens proc	far
		.enter
		mov	ax, offset AMB_appTokens
		call	AdminGetMapWord
		.leave
		ret
AdminGetAppTokens endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetReasons
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the handle for the failure-reason map

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		bx	= admin file
		ax	= handle for the failure-reason map
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetReasons	proc	far
		.enter
		mov	ax, offset AMB_outboxReasons
		call	AdminGetMapWord
		.leave
		ret
AdminGetReasons	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetMediaStatusMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the handle for the media-status map

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		bx	= admin file
		ax	= handle for the media-status map
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetMediaStatusMap	proc	far
		.enter
		mov	ax, offset AMB_media
		call	AdminGetMapWord
		.leave
		ret
AdminGetMediaStatusMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetMediaTransportMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the handle for the media/transport map

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		bx	= admin file
		ax	= handle for the media/transport map
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetMediaTransportMap	proc	far
		.enter
		mov	ax, offset AMB_mediaTrans
		call	AdminGetMapWord
		.leave
		ret
AdminGetMediaTransportMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminGetAutoDeliveryTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the time to wait before delivering a message
		automatically in the absence of user response.

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		cx	= # of ticks
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminGetAutoDeliveryTimeout	proc	far
	uses	ds
	.enter

	segmov	ds, dgroup, cx
	mov	cx, ds:[adminAutoDeliveryTimeout]

	.leave
	ret
AdminGetAutoDeliveryTimeout	endp

Admin		ends
