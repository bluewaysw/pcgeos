COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inboxMessageList.asm

AUTHOR:		Adam de Boor, Jun  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 3/94		Initial revision


DESCRIPTION:
	
		

	$Id: inboxMessageList.asm,v 1.1 97/04/05 01:21:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS		; REST OF FILE IS A NOP UNLESS THIS IS TRUE

MailboxClassStructures	segment	resource
	InboxMessageListClass
MailboxClassStructures	ends


InboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IMLMlGetScanRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ML_GET_SCAN_ROUTINES
PASS:		*ds:si	= InboxMessageListClass object
		ds:di	= InboxMessageListClass instance data
		ds:bx	= InboxMessageListClass object (same as *ds:si)
		es 	= segment of InboxMessageListClass
		ax	= message #
		cx:dx	= fptr.MLScanRoutines to fill in
RETURN:		MLScanRoutines filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	7/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMLMlGetScanRoutines	method dynamic InboxMessageListClass, 
					MSG_ML_GET_SCAN_ROUTINES

		movdw	dssi, cxdx
		mov	ds:[si].MLSR_select.segment, vseg IMLSelect
		mov	ds:[si].MLSR_select.offset, offset IMLSelect

		mov	ds:[si].MLSR_compare.segment, vseg IMLCompare
		mov	ds:[si].MLSR_compare.offset, offset IMLCompare

		ret
IMLMlGetScanRoutines	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IMLSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this message should be displayed

CALLED BY:	(INTERNAL) IMLMlRescan via MessageList::ML_RESCAN
PASS:		dxax	= MailboxMessage to check
		bx	= admin file
		*ds:si	= InboxMessageList object
RETURN:		*ds:si	= same object (ds fixed up)
DESTROYED:	nothing
SIDE EFFECTS:	message+address(es) may be added to the list

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMLSelect	proc	far
	class	InboxMessageListClass
	uses	cx, bp, di, es
	.enter

	;
	; Get criteria
	;
	DerefDI	InboxMessageList
	mov	di, ds:[di].MLI_primaryCriteria
					; *ds:di = MessageControlPanelCriteria
	tst	di
	jz	addMsg			; if null, it means MDPT_ALL
	Assert	chunk, di, ds
	mov	di, ds:[di]

	;
	; Check if message is for the selected application by comparing
	; GeodeToken's
	;
	Assert	e, ds:[di].MCPC_type, MDPT_BY_APP_TOKEN
	push	si				; save self lptr
	segmov	es, ds
	lea	si, ds:[di].MCPC_data.MDPC_byApp.MDBAD_token
					; es:si = GeodeToken of criteria
	call	MessageLock		; *ds:di = MailboxMessageDesc
	mov	di, ds:[di]
	add	di, offset MMD_destApp	; ds:di = GeodeToken of message
	xchg	si, di			; es:di = criteria, ds:si = message
		CheckHack <(size GeodeToken and 1) eq 0>
	mov	cx, size GeodeToken / 2
	repe	cmpsw
	call	UtilVMUnlockDS		; flags preserved
	segmov	ds, es
	pop	si			; *ds:si = self
	jne	done

addMsg:
	;
	; Add message to list.  We use 0 for address #.
	;
	push	ds
	call	MessageLock
	mov	di, ds:[di]

	test	ds:[di].MMD_flags, mask MIMF_NOTIFIED
	jnz	notified		; jump if already seen before
	BitSet	ds:[di].MMD_flags, MIMF_NOTIFIED
	call	UtilVMDirtyDS

	call	IMLMaybeSendWithoutQuery
	jc	unlock			; => sent, so don't add

notified:
	pop	bp			; bp = InboxMessageList blk

	StructPushBegin	MLMessage
		CheckHack <offset MIMF_EXTERNAL + width MIMF_EXTERNAL le 8>
	mov	ch, ds:[di].MMD_flags.low
	andnf	ch, mask MMF_PRIORITY
	mov	cl, offset MMF_PRIORITY
	shr	ch, cl			; ch = MailboxMessagePriority
	StructPushField	MLM_state, cx	; MLM_state + MLM_priority (we don't
					;  use MLM_state for comparison so we
					;  are pushing trash here
	StructPushField	MLM_registered, <ds:[di].MMD_registered.FDAT_time, \
					 ds:[di].MMD_registered.FDAT_date>
if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	StructPushSkip	<MLM_autoRetryTime, MLM_medium, MLM_transport>
else
	StructPushSkip	<MLM_medium, MLM_transport>
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE
	clr	cx
	StructPushField	MLM_address, cx
	StructPushField	MLM_message, <dx, ax>
	StructPushEnd

	call	UtilVMUnlockDS
	mov	ds, bp			; *ds:si = InboxMessageList
	mov	bp, sp
	call	MessageListAddMessage	; ds fixed up
	add	sp, size MLMessage
	jmp	done

unlock:
	call	UtilVMUnlockDS
	pop	ds

done:
	.leave
	ret
IMLSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IMLMaybeSendWithoutQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If message marked send-without-query and the app is
		loaded, tell it about the message.

CALLED BY:	(INTERNAL) IMLSelect
PASS:		ds:di	= MailboxMessageDesc
		dxax	= MailboxMessage
RETURN:		carry set if message sent to app
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 7/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMLMaybeSendWithoutQuery proc	near
		uses	ax, bx, cx, dx, si, di, bp, es
		.enter
		test	ds:[di].MMD_flags, mask MMF_SEND_WITHOUT_QUERY
		jz	done		; (carry clear)
	;
	; Call common routine that will only connect if it's possible to
	; connect.
	;
		mov	cx, BB_TRUE
		push	cx		; SMANP_ifLoaded
		pushdw	dxax		; SMANP_message
		push	ds:[di].MMD_destApp.GT_manufID
		push	{word}ds:[di].MMD_destApp.GT_chars[2]
		push	{word}ds:[di].MMD_destApp.GT_chars[0]
		mov	bp, sp
		call	IRSendMessageAvailableNotification
	;
	; Clear the stack without destroying the carry.
	;
		mov	bp, sp
		lea	sp, ss:[bp+size SendMsgAvailableNotifParams]
		cmc			; return carry set if could send
done:
		.leave
		ret
IMLMaybeSendWithoutQuery endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IMLCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to compare two messages from the inbox
		to sort them in ascending order.

CALLED BY:	(EXTERNAL) MLSortMessages
PASS:		ds:si	= MLMessage #1
		es:di	= MLMessage #2 (ds = es)
RETURN:		flags set so caller can jl, je, or jg according as
			ds:si is less than, equal to, or greater than es:di
DESTROYED:	ax, bx (ax, bx, cx, dx, di, si allowed)
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
	Sort by priority (primary) and date that message is registered
	(secondary).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMLCompare	proc	far

	;
	; Compare priorities
	;
	mov	al, ds:[si].MLM_priority
	cmp	al, ds:[di].MLM_priority
if (MailboxMessagePriority le 80h)
	jne	done			; no need to compare dates
	clr	al			; for signed cmp later
else
	mov	al, 0			; for signed cmp later (preserve flags)
	jb	lessThan
	ja	greaterThan
endif
	;
	; Since priorities are the same, we now compare dates and times of
	; registration.
	;
	; Can't use "cmpdw" on FileDateAndTime, since FDAT_time is in the
	; most significant word and FDAT_date in the LSW.
	; Also, FileDate and FileTime are "unsigned", in that 8000h is larger
	; than 7fffh.  Thus we have to convert the flags for unsigned
	; comparison to flags for signed comparison (because ArrayQuickSort
	; expects so.)
	;

	;
	; Compare dates
	;
	mov	bx, ds:[si].MLM_registered.FDAT_date
	cmp	bx, ds:[di].MLM_registered.FDAT_date
	jb	lessThan		; first date is earlier
	ja	greaterThan		; second date is earlier

	;
	; Dates are the same.  Compare times
	;
	mov	bx, ds:[si].MLM_registered.FDAT_time
	cmp	bx, ds:[di].MLM_registered.FDAT_time
	jb	lessThan		; first date is earlier
	ja	greaterThan		; second date is earlier

done:
	ret

lessThan:
	;
	; Set flags for signed less-than
	;
	cmp	al, 1
	ret

greaterThan:
	;
	; Set flags for signed greater-than
	;
	cmp	al, -1
	ret

IMLCompare	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPDeliverAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the destination app for each message we're displaying
		that the message is available.

CALLED BY:	MSG_ML_DELIVER_ALL
PASS:		ds:di	= InboxMessageListClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMLDeliverAll	method dynamic InboxMessageListClass, MSG_ML_DELIVER_ALL
		CheckHack <InboxMessageList_offset eq MessageList_offset>
	mov	si, ds:[di].MLI_messages
	tst	si
	jz	done
	
	mov	bx, cs
	mov	di, offset IMLDeliverAllCallback
	call	ChunkArrayEnum
done:
	ret
IMLDeliverAll	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IMLDeliverAllCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to request delivery of this entry of our
		message list

CALLED BY:	(INTERNAL) IMLDeliverAll via ChunkArrayEnum
PASS:		ds:di	= MLMessage structure
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, cx, dx, es
SIDE EFFECTS:	object message is queued to process to perform the delivery

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IMLDeliverAllCallback proc	far
		.enter
		movdw	cxdx, ds:[di].MLM_message
		call	IRNotifyDestApp
		clc
		.leave
		ret
IMLDeliverAllCallback endp

InboxUICode	ends

endif	; _CONTROL_PANELS
