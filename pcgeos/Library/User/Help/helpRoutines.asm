COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpRoutines.asm

AUTHOR:		Gene Anderson, Nov  3, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	11/ 3/92		Initial revision


DESCRIPTION:
	

	$Id: helpRoutines.asm,v 1.1 97/04/07 11:47:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpControlCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpSendFocusNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate and send a focus help notification

CALLED BY:	GLOBAL
PASS:		^lbx:si - OD of text to use
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpSendFocusNotification		proc	far
EC <	call	ECCheckOD			;>
EC <	ERROR	HELP_FOCUS_HELP_NOT_SUPPORTED	;>
NEC <	ret					;>
HelpSendFocusNotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpSendHelpNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate and send a help notification

CALLED BY:	GLOBAL and HelpSendHelpNotificationXIP
PASS:		ds:si - ptr to help context name (SBCS, NULL-terminated)
		es:di - ptr to help file name (SBCS, NULL-terminated)
		( The fptrs to strings *can* be pointing to the movable
			XIP resource.)
		al - HelpType
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpSendHelpNotification		proc	far
	uses	ax, bx, cx, dx, si, di, ds, es, bp
	.enter

if not DBCS_PCGEOS
EC <	call	LocalStringSize			;>
EC <	cmp	cx, (size FileLongName)		;>
EC <	ERROR_AE HELP_NAME_TOO_LONG		;>
EC <	pushdw	esdi				;>
EC <	segmov	es, ds				;>
EC <	mov	di, si				;es:di <- ptr to context name >
EC <	call	LocalStringSize			;>
EC <	cmp	cx, (size ContextName)		;>
EC <	ERROR_AE HELP_NAME_TOO_LONG		;>
EC <	popdw	esdi				;>
endif

	push	es, di
	;
	; Allocate a notification block
	;
	call	AllocHelpNotification
	;
	; Set the fixed stuff
	;
	mov	es:NHCC_type, al		;set type
	;
	; Copy the help context string
	;
	mov	di, offset NHCC_context		;es:di <- dest
if DBCS_PCGEOS
	LocalCopySBCSToDBCS
else
	LocalCopyString
endif
	;
	; Copy the file name
	;
	pop	ds, si				;ds:si <- ptr to filename
	mov	di, offset NHCC_filename	;es:di <- dest
if DBCS_PCGEOS
	LocalCopySBCSToDBCS
else
	LocalCopyString
endif
	;
	; Get the filename for the TOC from the application object
	;
if DBCS_PCGEOS
	sub	sp, (size FileLongName)
	mov	cx, ss
	mov	dx, sp				;cx:dx <- ptr to buffer
	mov	ax, MSG_META_GET_HELP_FILE
	call	UserCallApplication
	segmov	ds, ss
	mov	si, sp				;ds:si <- ptr to SBCS string
	mov	di, offset NHCC_filenameTOC	;es:di <- ptr to DBCS dest
	LocalCopySBCSToDBCS
	add	sp, (size FileLongName)
else
	mov	ax, MSG_META_GET_HELP_FILE
	mov	cx, es
	mov	dx, offset NHCC_filenameTOC	;cx:dx <- ptr to buffer
	call	UserCallApplication
endif
	;
	; Unlock the notification and send it off
	;
	call	UnlockSendHelpNotification

	.leave
	ret
HelpSendHelpNotification		endp

if FULL_EXECUTE_IN_PLACE

HelpControlCode ends

ResidentXIP	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpSendHelpNotificationXIP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for HelpSendHelpNotification() in XIP version.

CALLED BY:	GLOBAL in XIP version
PASS:		ds:si - ptr to help context name (NULL-terminated)
		es:di - ptr to help file name (NULL-terminated)
		al - HelpType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpSendHelpNotificationXIP	proc	far
		uses	cx, di, si, ds, es
		.enter
	;
	; Copy help file name and help context name onto stack.
	;
		segxchg	ds, es
		xchg	si, di			;ds:si = help file name
						;es:di = help context name
		clr	cx			;cx = null-terminated str
		call	SysCopyToStackDSSI	;ds:si = help filename in stack
		segxchg	ds, es
		xchg	si, di			;es:di = help filename in stack
						;ds:si = help context name
		call	SysCopyToStackDSSI	;ds:si = help context name in stack
		call	HelpSendHelpNotification
	;
	; Restore the stack
	;
		call	SysRemoveFromStack
		call	SysRemoveFromStack
		
		.leave
		ret
		
HelpSendHelpNotificationXIP	endp


ResidentXIP	ends

HelpControlCode	segment	resource

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockSendHelpNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send off a help notification to the appropriate GCN lists

CALLED BY:	HelpSendHelpNotification()
PASS:		bx - handle of notification
RETURN:		none
DESTROYED:	ax, bx, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockSendHelpNotification		proc	far
	.enter

	;
	; Unlock the notification block
	;
	call	MemUnlock
	;
	; Initialize reference count for two (2) sends below
	;
	mov	ax, 2				;ax <- reference count
	call	MemInitRefCount
	;
	; Send the notification to the app GCN list
	;
	call	RecordNotificationEvent		;di <- recorded event
	mov	ax, GAGCNLT_NOTIFY_HELP_CONTEXT_CHANGE
	call	SendNotifToAppGCN
	;
	; Send the notification to the system GCN list
	;
	call	RecordNotificationEvent		;di <- recorded event
	mov	cx, di				;cx <- recorded event
	mov	dx, bx				;dx <- data block
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GAGCNLT_NOTIFY_HELP_CONTEXT_CHANGE
	;
	; force queue to avoid possible deadlock when handler on the
	; same thread also tries to a GCNListSend (contention for
	; GCNListBlock, which is MemPLock'd) - brianc 6/24/93
	;
	mov	bp, mask GCNLSF_FORCE_QUEUE	;bp <- GCNListSendFlags
	call	GCNListSend

	.leave
	ret
UnlockSendHelpNotification		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNotifToAppGCN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification block to app GCN via the process
CALLED BY:	HelpSendHelpNotification()

PASS:		bx - handle of notification block
		ax - GenAppGCNListType
		di - recorded event
RETURN:		none
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendNotifToAppGCN	proc	near
	uses	bx, bp
	.enter

	;
	; Send the recorded notification event to the application object
	;
	mov	dx, size GCNListMessageParams	;dx <- size of stack frame
	sub	sp, dx				;create stack frame
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, ax
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	;
	; Set appropriate flags -- always zero so data isn't cached
	;
	; No -- force queue the notification, to avoid stack overflow
	; errors.  cassie, 6/28/95
	;
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_FORCE_QUEUE
	;
	; Send to the GCN list via the process -- NOTE: do not change
	; this to send via the app obj, as notification may be sent
	; from either the app thread or the UI thread.
	;
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	clr	si
	mov	di, mask MF_STACK		;di <- MessageFlags
	call	ObjMessage

	add	sp, dx				;clean up stack

	.leave
	ret
SendNotifToAppGCN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordNotificationEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record a notification event for later sending

CALLED BY:	SendNotifToAppGCN()
PASS:		bx - notification data handle
RETURN:		di - recorded event
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordNotificationEvent		proc	near
	uses	ax, si, bp
	.enter

	mov	bp, bx				;bp <- handle of notification
	mov	cx, MANUFACTURER_ID_GEOWORKS		;cx <- ManufacturerID
	mov	dx, GWNT_HELP_CONTEXT_CHANGE
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	di, mask MF_RECORD		;di <- MessageFlags
	call	ObjMessage			;di <- recorded event

	.leave
	ret
RecordNotificationEvent		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocHelpNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a help notification block

CALLED BY:	HelpSendHelpNotification(), HelpSendFocusNotification()
PASS:		none
RETURN:		bx - handle of NotifyHelpContextChange
		es - seg addr of NotifyHelpContextChange
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocHelpNotification		proc	far
	uses	ax, cx
	.enter

	mov	ax, (size NotifyHelpContextChange)
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	es, ax				;es <- seg addr of block

	.leave
	ret
AllocHelpNotification		endp

HelpControlCode ends
