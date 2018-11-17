COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inboxUtils.asm

AUTHOR:		Adam de Boor, Feb 27, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/27/95		Initial revision


DESCRIPTION:
	Random utility routines.
		

	$Id: inboxUtils.asm,v 1.1 97/04/05 01:20:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUGetDeliveryVerbInMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get delivery verb specified in message

CALLED BY:	(INTERNAL)
PASS:		cxdx	= MailboxMessage
		bx	= INBOX_DELIVERY_VERB_ACTIVE or
			  INBOX_DELIVERY_VERB_PASSIVE
		ds	= LMem block to store verb
RETURN:		*ds:ax	= verb to use (ds fixed up)
		es	= ds
DESTROYED:	bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUGetDeliveryVerbInMessage	proc	far

	call	MailboxGetMessageFlags	; ax = MailboxMessageFlags

	;
	; Get verb string to use
	;
	push	ds			; save object block sptr
	andnf	ax, mask MMF_VERB
		CheckHack <offset MMF_VERB eq 1>
	add	ax, bx			; ax = lptr to verb string
	mov_tr	si, ax
	mov	bx, handle ROStrings
	call	MemLock
	mov	ds, ax
	mov_tr	dx, ax			; dx = verb string sptr
	mov	si, ds:[si]		; dx:si = verb string
	ChunkSizePtr	ds, si, cx	; cx = size of verb string

	;
	; Allocate chunk in object block.  Copy the verb.
	;
	pop	ds			; ds = object block
	mov	al, mask OCF_DIRTY
	call	LMemAlloc		; *ds:ax = new chunk
	mov	di, ax
	mov	di, ds:[di]
	segmov	es, ds			; es:di = buffer for verb (dest)
	mov	ds, dx			; ds:si = verb string (src)
	rep	movsb
	segmov	ds, es			; *ds:ax = string

	GOTO	MemUnlock		; unlock verb string

IUGetDeliveryVerbInMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IUDeleteMessageCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to delete a message and dismiss the dialog
		displaying it.

CALLED BY:	(INTERNAL) IDDeleteMessage, ITWCMsndDeleteMessage
PASS:		cxdx	= MailboxMessage
		*ds:si	= GenInteractionClass object
RETURN:		ds fixed up
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IUDeleteMessage	proc	far

	mov	bx, ds:[OLMBH_header].LMBH_handle	; for re-deref

	;
	; Call mailbox routine to delete the message.  All kinds of
	; notifications will be generated automatically.
	;
	call	MailboxDeleteMessage

	call	MemDerefDS		; *ds:si = GenInteraction obj
	call	UtilInteractionComplete

	ret
IUDeleteMessage	endp

InboxUICode	ends
