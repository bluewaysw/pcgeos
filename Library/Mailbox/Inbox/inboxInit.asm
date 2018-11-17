COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inboxInit.asm

AUTHOR:		Adam de Boor, Apr 19, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/19/94		Initial revision


DESCRIPTION:
	
		

	$Id: inboxInit.asm,v 1.1 97/04/05 01:20:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the inbox queue

CALLED BY:	(EXTERNAL) AdminInitFile
PASS:		bx	= handle of admin file
RETURN:		carry set if couldn't create
		carry clear if inbox created:
			ax	= handle of inbox DBQ
			cx	= handle of application token map.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxCreate	proc	near
		uses	dx, si, ds, bp
		.enter
		call	InboxCreateQueue
		push	ax
	;
	; Now create the block that holds the element array that's keyed by
	; tokens and holds InboxAppData structures.
	; 
		mov	ax, LMEM_TYPE_GENERAL
		mov	cx, size InboxTokenMapHeader
		call	VMAllocLMem
		push	ax, bx
		call	VMLock
		mov	ds, ax
	;
	; Allocate the element array
	; 
		mov	bx, size InboxAppData
		clr	si, cx		; si <- allocate chunk please
					; cx <- use default header
		call	ElementArrayCreate
EC <		cmp	si, ds:[LMBH_offset]				>
EC <		ERROR_NE INBOX_APP_TOKEN_MAP_NOT_FIRST_CHUNK		>
	;
	; Now the name array that holds the filenames for apps (*not* the
	; pathnames -- we let IACP continue to worry about those)
	; 
		clr	bx, si, cx	; bx <- no additional data
					; si <- allocate chunk please
					; cx <- use default header
		call	NameArrayCreate
EC <		mov	ax, ds:[LMBH_offset]				>
EC <		inc	ax						>
EC <		inc	ax						>
EC <		cmp	si, ax						>
EC <		ERROR_NE INBOX_APP_NAME_ARRAY_NOT_SECOND_CHUNK		>
	;
	; We don't have directory trees yet.
	;
		clr	ds:[ITMH_appDirTree], ds:[ITMH_sysAppDirTree]

   		call	VMDirty
		call	VMUnlock
	;
	; Mark the block for later EC
	; 
		pop	ax, bx		; ax <- map handle, bx <- VM file
		mov	cx, MBVMID_APP_TOKENS
		call	VMModifyUserID

		mov_tr	cx, ax		; cx <- map handle
		pop	ax		; ax <- queue handle
		.leave
		ret
InboxCreate 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxCreateQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the inbox queue.

CALLED BY:	(EXTERNAL) InboxCreate, AdminFixRefCounts
PASS:		nothing
RETURN:		carry set if couldn't create
		carry clear if inbox queue created:
			ax	= handle of inbox DBQ
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxCreateQueue	proc	near

	mov	dx, enum InboxMessageAdded
	call	MessageCreateQueue

	ret
InboxCreateQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare inbox for a new GEOS session.

CALLED BY:	(INTERNAL) AdminInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Build directory trees for SP_APPLICATION and SP_SYS_APPLICATION.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxInit	proc	near
	uses	ax,bx,cx,dx,si,di,ds
	.enter

	;
	; Rebuild directory trees
	;
	mov	bx, SP_APPLICATION
	call	IATRebuildDirTree
	mov	bx, SP_SYS_APPLICATION
	call	IATRebuildDirTree

	;
	; Setup inbox check timer
	;
	mov	dx, offset inboxCheckPeriodKey
	mov	ax, INBOX_CHECK_DEFAULT_PERIOD
	mov	di, INBOX_CHECK_MIN_PERIOD
	mov	bx, MSG_MA_START_INBOX_CHECK_TIMER
	call	InboxStartTimerCommon

	.leave
	ret
InboxInit	endp

mailboxCategory		char	"mailbox", C_NULL
inboxCheckPeriodKey	char	"inboxCheckPeriod", C_NULL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxStartTimerCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the app object to start a periodic timer to do something

CALLED BY:	(EXTERNAL) AdminInit, InboxInit
PASS:		cs:dx	= INI file key (under category [mailbox])
		ax	= default period to use (# of minutes)
		di	= min. period to use (# of minutes)
		bx	= message to send to app object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxStartTimerCommon	proc	near
	uses	si
	.enter

	mov	cx, cs			; cx:dx = key
	mov	ds, cx			
	mov	si, offset mailboxCategory	; ds:si = category
	call	InitFileReadInteger	; ax = # of minutes

	;
	; Make sure the # of minutes is in range.
	;
	cmp	ax, 0xffff / 3600
	jbe	checkLowerLimit
	mov	ax, 0xffff / 3600
checkLowerLimit:
	cmp	ax, di
	jae	hasMinute
	mov_tr	ax, di			; use min. period instead

hasMinute:
	;
	; Calculate # of time ticks.
	;
	mov	cx, 3600		; cx = # of ticks in one minute
	mul	cx			; ax = # of ticks in one period

	mov_tr	cx, ax			; cx = period
	mov_tr	ax, bx			; ax = message to send to app object
	call	UtilSendToMailboxApp

	.leave
	ret
InboxStartTimerCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxFix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This used to fix up the reference counts for all the messages
		in the inbox, after a crash. This is now handled in another
		manner in AdminFixFile, but we keep the routine in case we
		find other things that need fixing up...

		(... 13 months later ...)

		Now we do find something that needs fixing up.  :-)

CALLED BY:	(EXTERNAL) AdminFixFile
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxFix	proc	near
		uses	bx, di, cx, dx, ax
		.enter
	;
	; Fix up the element array of app tokens.
	;
		call 	AdminGetAppTokens
		call	UtilFixTwoChunkArraysInBlock
	;
	; Now check the messages in the inbox queue.
	;
		call	AdminGetInbox
		clr	cx
msgLoop:
		call	DBQGetItemNoRef		; dxax <- message
		jc	done
	;
	; See if the message body is still intact.
	;
		call	MessageCheckBodyIntegrity
		jc	removeMsg

		inc	cx			; else, advance to next message
		jmp	msgLoop

removeMsg:
	;
	; If the message body is invalid, we remove it from the inbox
	; in the normal fashion, but without the usual notification of the
	; application object.
	; 
		pushdw	dxax
		call	DBQRemove
		popdw	dxax
		call	DBQFree
		jmp	msgLoop

done:
		.leave
		ret
InboxFix	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxRegisterFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register inbox for file-change notification.

CALLED BY:	(EXTERNAL) AdminInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxRegisterFileChange	proc	near

	mov	cx, vseg InboxNotifyFileChange
	mov	dx, offset InboxNotifyFileChange
	call	UtilRegisterFileChangeCallback

	ret
InboxRegisterFileChange	endp

Init	ends

InboxCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turns off times set up by inbox module.

CALLED BY:	(EXTERNAL) AdminExit
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	12/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxExit	proc	far

	mov	ax, MSG_MA_STOP_INBOX_CHECK_TIMER
	call	UtilSendToMailboxApp

	ret
InboxExit	endp

InboxCode	ends
