COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inboxDetails.asm

AUTHOR:		Adam de Boor, Jun  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 3/94		Initial revision


DESCRIPTION:
	
		

	$Id: inboxDetails.asm,v 1.1 97/04/05 01:20:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS		; REST OF FILE IS A NOP UNLESS THIS IS TRUE

MailboxClassStructures	segment	resource
	InboxDetailsClass
MailboxClassStructures	ends

InboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDMdSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the gadgets in the outbos details box that are specific
		to us.

CALLED BY:	MSG_MD_SET_MESSAGE
PASS:		*ds:si	= InboxDetailsClass object
		es 	= segment of InboxDetailsClass
		ax	= message #
		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDMdSetMessage	method dynamic InboxDetailsClass, MSG_MD_SET_MESSAGE

	push	si, ax, es, cx, dx

	;
	; Add ourselves to the appropriate GCN list, so we know if the message
	; goes away.
	; 
	mov	ax, MGCNLT_INBOX_CHANGE
	call	UtilAddToMailboxGCNList

	;
	; Show details specific to inbox.
	;
		CheckHack <MessageDetails_offset eq InboxDetails_offset>
	push	ds, ds:[di].MDI_boundText
	call	MessageLockCXDX
	mov	di, ds:[di]
	segmov	es, ds			; es:di = MailboxMessageDesc
	pop	ds, si			; *ds:si = boundText
	call	IDShowBound
	call	IDShowPriority
	call	IDShowSize
	mov	bp, es:[LMBH_handle]
	call	VMUnlock		; unlock message

	;
	; Call superclass to do the rest.
	;
	pop	si, ax, es, cx, dx	; *ds:si = self, cxdx = MailboxMessage
	mov	di, offset InboxDetailsClass	; es:di = class
	GOTO	ObjCallSuperNoLock

IDMdSetMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDShowPriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show priority of message on screen

CALLED BY:	(INTERNAL) IDMdSetMessage
PASS:		ds	= block where inbox panel objects are
		es:di	= MailboxMessageDesc
RETURN:		ds fixed up
DESTROYED:	ax, bx, cx, dx, bp, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDShowPriority	proc	near
	uses	es
	.enter

	;
	; Calculate correct string chunk to use.
	;
	mov	bp, es:[di].MMD_flags

; Make sure MailboxMessageFlags is in low byte of MailboxInternalMessageFlags
.assert offset MIMF_EXTERNAL eq 0
.assert mask MailboxMessageFlags le 0xff

	andnf	bp, mask MMF_PRIORITY
		CheckHack <offset MMF_PRIORITY eq 4>
	shr	bp
	shr	bp
	shr	bp
	add	bp, offset uiPriorityEmergency	; bp = lptr to priority string

	;
	; Lock string block
	;
	mov	bx, handle ROStrings
	call	MemLock
	mov	es, ax
	mov_tr	dx, ax
	mov	bp, es:[bp]		; dx:bp = priority string

	;
	; Pass string to text object
	;
	mov	si, offset InboxPanelDetailsPriority
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx
	call	ObjCallInstanceNoLock

	call	MemUnlock		; unlock string block

	.leave
	ret
IDShowPriority	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDShowSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show size of message body on screen.

CALLED BY:	(INTERNAL) IDMdSetMessage
PASS:		ds	= block where inbox panel objects are
		es:di	= MailboxMessageDesc
RETURN:		ds fixed up
DESTROYED:	ax, bx, cx, dx, bp, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDShowSize	proc	near
	uses	es, di
	.enter

	;
	; Get MailboxStorage of message.  Load data driver.
	;
	movdw	cxdx, es:[di].MMD_bodyStorage
	call	MessageLoadDataDriver	; bx = driver handle, dxax = strategy
	jc	cantGetSize

	;
	; Call data dirver to get body size.
	;
	pushdw	dxax			; ss:[sp] = strategy
	mov	di, es:[di].MMD_bodyRef	; *es:di = mbox-ref
	mov	cx, es
	mov	dx, es:[di]		; cx:dx = mbox-ref
	mov	di, DR_MBDD_BODY_SIZE
	mov	bp, sp
	call	{fptr} ss:[bp]		; dxax = body size (-1 if unavailable)
	mov	bp, sp
	lea	sp, ss:[bp+size fptr]

	;
	; Unload data driver.
	;
	pushf
	call	MailboxFreeDriver
	popf
	jc	messageErr
	cmpdw	dxax, -1
	je	cantGetSize

	;
	; Set the value on screen
	;
	sub	sp, UHTA_NULL_TERM_BUFFER_SIZE
	movdw	esdi, sssp				; es:di = buffer
	mov	cx, mask UHTAF_THOUSANDS_SEPARATORS \
			or mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii	; cx = length of string
	movdw	dxbp, sssp		; dx:bp = string
	clr	bx			; string is on stack, nothing to unlock
	jmp	gotString

messageErr:
	mov	bp, offset ROStrings:uiMessageInvalid
	jmp	getROString

cantGetSize:
	;
	; Can't get size of message.  Use "unavailable" string.
	;
	mov	bp, offset ROStrings:uiUnavailable

getROString:
	mov	bx, handle ROStrings
	call	MemLock
	mov	es, ax
	mov_tr	dx, ax
	mov	bp, es:[bp]		; dx:bp = string

gotString:
	;
	; Show string on screen.
	;
	mov	si, offset InboxPanelDetailsSize
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx			; null-terminated
	call	ObjCallInstanceNoLock

	tst	bx
	jz	strOnStack
	call	MemUnlock		; unlock "unavailable" string
	jmp	done

strOnStack:
	add	sp, UHTA_NULL_TERM_BUFFER_SIZE	; pop string from stack

done:
	.leave
	ret
IDShowSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDShowBound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show bounds (ie. deadline) of message on screen

CALLED BY:	(INTERNAL) IDMdSetMessage
PASS:		*ds:si	= bound object
		es:di	= MailboxMessageDesc
RETURN:		ds fixed up
DESTROYED:	ax, bx, cx, dx, bp, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDShowBound	proc	near

	;
	; Create date-time string.
	;
	movdw	bxax, es:[di].MMD_transWinClose	; bx = FileTime, ax = FileDate
		CheckHack <UFDTF_SHORT_FORM eq 0>
	clr	cx			; cx = UFDTF_SHORT_FORM
	call	UtilFormatDateTime	; *ds:ax = date-time string

	;
	; Pass string to text object
	;
	mov	dx, ds:[OLMBH_header].LMBH_handle
	mov_tr	bp, ax			; ^ldx:bp = string
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	clr	cx			; null-terminated
	call	ObjCallInstanceNoLock

	ret
IDShowBound	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDMdGetTitleString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_MD_GET_TITLE_STRING
PASS:		ds:di	= InboxDetailsClass instance data
		MDI_message
RETURN:		ax	= lptr of chunk in the same block with string to use
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDMdGetTitleString	method dynamic InboxDetailsClass, 
					MSG_MD_GET_TITLE_STRING

	;
	; Get GeodeToken of destination app of the message
	;
	movdw	cxdx, ds:[di].MDI_message
	sub	sp, size GeodeToken
	movdw	esdi, sssp
	call	MailboxGetDestApp
	pop	dx, cx, bx		; bxcxdx = GeodeToken of destApp

	call	InboxGetAppName		; *ds:ax = app name

	ret
IDMdGetTitleString	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDMdGetDeliveryVerb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the verb according to MailboxDeliveryVerb of the message

CALLED BY:	MSG_MD_GET_DELIVERY_VERB
PASS:		ds:di	= InboxDetailsClass instance data
		MDI_message
RETURN:		ax	= lptr of chunk in the same block with string to use
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDMdGetDeliveryVerb	method dynamic InboxDetailsClass,
					MSG_MD_GET_DELIVERY_VERB

	;
	; Get MailboxDeliveryVerb of message.
	;
	movdw	cxdx, ds:[di].MDI_message
	mov	bx, INBOX_DELIVERY_VERB_ACTIVE
	GOTO	IUGetDeliveryVerbInMessage

IDMdGetDeliveryVerb	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDMdReleaseMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove ourselves from the GCN list to which we added ourselves
		in MSG_MD_SET_MESSAGE

CALLED BY:	MSG_MD_RELEASE_MESSAGE
PASS:		*ds:si	= InboxDetailsClass object
		es 	= segment of InboxDetailsClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDMdReleaseMessage	method dynamic InboxDetailsClass,
					MSG_MD_RELEASE_MESSAGE

	push	ax
	mov	ax, MGCNLT_INBOX_CHANGE
	call	UtilRemoveFromMailboxGCNList
	pop	ax

	mov	di, offset InboxDetailsClass
	GOTO	ObjCallSuperNoLock

IDMdReleaseMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDSendMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the message to the application, loading the app if
		necessary.

CALLED BY:	MSG_ID_SEND_MESSAGE
PASS:		ds:di	= InboxDetailsClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDSendMessage	method dynamic InboxDetailsClass, MSG_ID_SEND_MESSAGE

	movdw	cxdx, ds:[di].MDI_message
	call	IRNotifyDestApp

	ret
IDSendMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDDeleteMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the currently-displayed message.

CALLED BY:	MSG_ID_DELETE_MESSAGE
PASS:		*ds:si	= InboxDetailsClass object
		ds:di	= InboxDetailsClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDDeleteMessage	method dynamic InboxDetailsClass, MSG_ID_DELETE_MESSAGE

	movdw	cxdx, ds:[di].MDI_message
	GOTO	IUDeleteMessage

IDDeleteMessage	endm


InboxUICode	ends

endif	; _CONTROL_PANELS
