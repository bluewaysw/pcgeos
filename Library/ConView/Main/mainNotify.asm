COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Condo viewer
MODULE:		main - view and text
FILE:		mainNotify.asm

AUTHOR:		Jonathan Magasin, May 10, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	5/10/94   	Initial revision


DESCRIPTION:
	Code that notifies controllers of changes in the
	content's state.
		

	$Id: mainNotify.asm,v 1.1 97/04/04 17:49:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
notificationCount word
idata	ends

BookFileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSendNullNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an empty notification.

CALLED BY:	GLOBAL
PASS:		*ds:si 	- instance data (ContentGenView)
		dx - notification type
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di, es, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentSendNullNotification		proc	near
EC <	call	AssertIsCGV				>	

	; clear the book name from the primary
	mov	ax, MSG_CGV_CHANGE_PRIMARY_MONIKER
	clr	bp				; no book title feature
	call	ObjCallInstanceNoLock

	mov	dx, GWNT_CONTENT_CONTEXT_CHANGE
	clr	bx				;no data block
	call	RecordNotificationEvent		;di <- recorded event
	mov	cx, GAGCNLT_NOTIFY_CONTENT_CONTEXT_CHANGE
	call	SendNotifToAppGCN

	mov	dx, GWNT_CONTENT_BOOK_CHANGE
	clr	bx				;no data block
	call	RecordNotificationEvent		;di <- recorded event
	mov	cx, GAGCNLT_NOTIFY_CONTENT_BOOK_CHANGE
	call	SendNotifToAppGCN
	ret
ContentSendNullNotification		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate and send a help notification

CALLED BY:	GLOBAL
PASS:		*ds:si 	- instance data (ContentGenView)
		ax	- NotifyNavContextChangeFlags
		cx	- number of new page
RETURN: 	nothing
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentSendNotification		proc	near
	uses	si, bp
	.enter
EC <	call	AssertIsCGV				>	
	;
	; Allocate a notification block
	;
	mov	bx, (size NotifyNavContextChange)
	call	AllocHelpNotification		;^hbx=es:0 <- NCBC structure
	;
	; Set the fixed stuff
	;
	mov	es:NNCC_flags, ax
	mov	es:NNCC_page, cx
	;
	; Get the bookFeatures
	;
	call	MUGetFeaturesAndTools
	mov	es:NNCC_bookFeatures, cx
	;
	; Copy the hyperlink file and context name from notify block
	;
	mov	ax, CONTENT_FILENAME		; Get the filename.
	mov	di, offset NNCC_filename	;es:di <- dest
	call	ContentGetStringVardata
EC <		ERROR_NC -1						>

	mov	ax, CONTENT_LINK		; Get the context.
	mov	di, offset NNCC_context		;es:di <- dest
	call	ContentGetStringVardata
EC <		ERROR_NC -1						>
	;
	; Unlock the notification and send it off
	;
	mov	cx, GAGCNLT_NOTIFY_CONTENT_CONTEXT_CHANGE
	mov	dx, GWNT_CONTENT_CONTEXT_CHANGE
	;
	; inc the counter which makes this notification unique
	;
	push	es
NOFXIP<	segmov	es, <segment idata>, ax			; es = dgroup	>
FXIP <	mov	ax, bx					; save notif block>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES				; ds = dgroup	>
FXIP <	mov	bx, ax					; restore notif block>
	inc	es:notificationCount
	mov	ax, es:notificationCount
	pop	es
	mov	es:NNCC_counter, ax			
	call	UnlockSendHelpNotification

	.leave
EC <	call	AssertIsCGV				>	
	ret

ContentSendNotification		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContentSendBookNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a notification that the current book has changed.

CALLED BY:	GLOBAL
PASS:		*ds:si - ConGenView
		ss:bp - ContentTextRequest
			CTR_flags - set
			CTR_bookname - set to book file
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/31/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContentSendBookNotification		proc	near
	class	ContentGenViewClass
	uses	bp
	.enter
EC <	call	AssertIsCGV				>	

	call	MUGetFeaturesAndTools		; cx/dx <- features/tools
	;
	; Change the primary moniker.
	;
	push	cx, dx, bp
	mov	ax, MSG_CGV_CHANGE_PRIMARY_MONIKER
	lea	dx, ss:[bp].CTR_bookname
	mov	bp, cx				; bp <- feature flags 	
	mov	cx, ss				; cx:dx <- book name
	call	ObjCallInstanceNoLock
	;
	; Allocate a notification block
	;
	mov	bx, (size NotifyContentBookChange)
	call	AllocHelpNotification		;^hbx=es:0 <- NCBC structure
	pop	es:NCBC_features, es:NCBC_tools, bp
	;
	; Set the flags
	;
	clr	ax		
	test	ss:[bp].CTR_flags, mask CTRF_restoreFromState
	jz	$10
	mov	ax, mask NCBCF_retnWithState
$10:
	mov	es:[NCBC_flags], ax	
	;
	; Copy the book name to the notification block
	;
	mov	ax, CONTENT_BOOKNAME			; Get the book name.
	mov	di, offset NCBC_bookname		;es:di <- dest
	call	ContentGetStringVardata
	jc	done
	mov	{char}es:[di], 0

done:
	mov	cx, GAGCNLT_NOTIFY_CONTENT_BOOK_CHANGE
	mov	dx, GWNT_CONTENT_BOOK_CHANGE
	call	UnlockSendHelpNotification
		
	.leave
	ret
ContentSendBookNotification		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocHelpNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a notification block

CALLED BY:	INTERNAL
PASS:		bx - size of block to allocate
RETURN:		bx - handle of NotifyNavContextChange
		es - seg addr of NotifyNavContextChange
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocHelpNotification		proc	near
	uses	ax, cx
	.enter

	mov	ax, bx
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	es, ax				;es <- seg addr of block

	.leave
	ret
AllocHelpNotification		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockSendHelpNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send off a help notification to the appropriate GCN lists

CALLED BY:	HelpSendHelpNotification()
PASS:		bx - handle of notification
		cx - GenAppGCNListType
		dx - notification type
RETURN:		none
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockSendHelpNotification		proc	near
		
	;
	; Unlock the notification block
	;
	call	MemUnlock
	;
	; Initialize reference count for one (1) send below
	;
	mov	ax, 1				; ax <- reference count
	call	MemInitRefCount
	;
	; Send the notification to the app GCN list
	;
	mov	ax, cx				; save GenAppGCNListType
	call	RecordNotificationEvent		; di <- recorded event
	mov	cx, ax				; cx <- GenAppGCNListType
	call	SendNotifToAppGCN
	ret
UnlockSendHelpNotification		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordNotificationEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record a notification event for later sending

CALLED BY:	ContentSendNullNotification, UnlockSendHelpNotification
PASS:		bx - notification data handle
		dx - notification type
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
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	di, mask MF_RECORD		;di <- MessageFlags
	call	ObjMessage			;di <- recorded event

	.leave
	ret
RecordNotificationEvent		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNotifToAppGCN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification block to app GCN via the process

CALLED BY:	ContentSendNullNotification, UnlockSendHelpNotification

PASS:		bx - handle of notification block
		cx - GenAppGCNListType
		di - recorded event
RETURN:		none
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendNotifToAppGCN	proc	near
	uses	bx, bp, si
	.enter

	;
	; Send the recorded notification event to the application object
	;
	mov	dx, size GCNListMessageParams	;dx <- size of stack frame
	sub	sp, dx				;create stack frame
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, cx
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	;
	; Set appropriate flags -- always zero so data isn't cached
	;
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
	;
	; Send to the GCN list via the process -- NOTE: do not change
	; this to send via the app obj, as notification may be sent
	; from either the app thread or the UI thread.
	;
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	clr	si
	mov	di, mask MF_STACK 
	call	ObjMessage

	add	sp, dx				;clean up stack

	.leave
	ret
SendNotifToAppGCN	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MNGetPrevNextStatusGivenName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figures out if the "Prev" and "Next"
		triggers should be enabled/disabled
		for a given context (specified by string
		in es:di).
		Returns page of context, too.
		CLEARS other NNCCF flags.

CALLED BY:	
PASS:		*ds:si	- ContentGenView instance
		es:di	- string = context name
RETURN:		ax	- NotifyNavContextChangedFlags
			  with NNCCF_prevEnabled and
			  NNCCF_nextEnabled set
			  appropriately
		cx	- page of context
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MNGetPrevNextStatusGivenName	proc	near
		uses	ds,si,di,dx
		.enter
EC <		call	AssertIsCGV				>
	;
	; If this file was not generated by studio, it will have
	; prev/next buttons, but they will be disabled.
	;
		call	MFGetFileFlags			;cx<-file flags
		clr	ax				;Assume prev/next
							;disabled
		test	cx, mask HFF_CREATED_BY_STUDIO
		jz	done			;Not created by Studio.

	;
	; ax is still clr, which is what we want to pass to this
	; routine, so that it doesn't lock the search text object's
	; name array...  
	;
		call	MNLockNameArray			;*ds:si<- name array

		push	ax
		call	MLGetContextElementNumber	;ax<-element number
EC <		ERROR_NC CONTEXT_NAME_ELEMENT_NOT_FOUND 		>
		call	ChunkArrayElementToPtr		;ds:di <- name elt.
EC <		ERROR_C ILLEGAL_CONTEXT_ELEMENT_NUMBER			>
		pop	ax		

		call	MNGetPrevNextStatusCommon	;ax<- NNCC_flags
		mov	cx, ds:[di].PNAE_pageNumber	;cx<-page
		call	MNUnlockNameArray

done:
		.leave
EC <		call	AssertIsCGV				>
		call	MNCheckPageValid
		ret
MNGetPrevNextStatusGivenName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MNGetPrevNextStatusCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for getting the status
		of the "Prev" and "Next" triggers
		for the given context (specified
		by a pointer).
		ALSO clears the NNCCF_updateHistory

CALLED BY:	MNGetPrevNextStatusGivenToken,
		MNGetPrevNextStatusGivenName
PASS:		ds:di	- name array element
			  of the context
RETURN:		ax	- NotifyNavContextChangeFlags
			  updated for prev/next status
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MNGetPrevNextStatusCommon	proc	near
	.enter

	clr	ax				;assume both disabled
	cmp	ds:[di].PNAE_prevPage, -1
	je	getNextStatus
	or	ax, mask NNCCF_prevEnabled

getNextStatus:	
	cmp	ds:[di].PNAE_nextPage, -1
	je	done
	or	ax, mask NNCCF_nextEnabled

done:
	.leave
	ret
MNGetPrevNextStatusCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MNCheckPageValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the passed page number to zero
		if it is an invalid number because
		the current file doesn't have any
		page numbers.  Only files created
		with Studio will have valid page
		numbers.

CALLED BY:	
PASS:		*ds:si	- ContentGenView instance
		cx	- page number
RETURN:		cx	- page number, or 0
			  if passed page number
			  wasn't legitimate
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JM	6/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MNCheckPageValid	proc	near
EC <	call	AssertIsCGV				>

	push	cx
	call	MFGetFileFlags			;cx<-CFMB_flags
	test	cx, mask HFF_CREATED_BY_STUDIO
	jnz	pageOK

	pop	cx
	clr	cx
	ret

pageOK:
	pop	cx
	ret
MNCheckPageValid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVChangePrimaryMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes the primary's moniker to be the passed string
		Or to the default moniker if BFF_BOOK_TITLE is not set.
		
CALLED BY:	MSG_CGV_CHANGE_PRIMARY_MONIKER
PASS:		*ds:si	= ContentGenViewClass object
		ds:di	= ContentGenViewClass instance data
		ds:bx	= ContentGenViewClass object (same as *ds:si)
		es 	= segment of ContentGenViewClass
		ax	= message #
		
		cx:dx 	= fptr to source null-terminated text string
		bp	= book features (BookFeatureFlags)
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	9/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVChangePrimaryMoniker			method dynamic ContentGenViewClass, 
					MSG_CGV_CHANGE_PRIMARY_MONIKER
	.enter
	;
	; Is title a feature?
	;
	test	bp, mask BFF_BOOK_TITLE
	jnz	usePassedTitle
	;
	; No, so use default title.
	;
	mov	bx, handle ContentStrings
	call	MemLock
	mov	es, ax
	mov	di, offset defaultTitleString
	mov	cx, es		
	mov	dx, es:[di]			;cx:dx <- default title
	push	bx
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	call	sendUpdateMessage
	pop	bx
	call	MemUnlock
	jmp	done
	;
	; Title is a feature, so show filename as title.
	;
usePassedTitle:
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		;cx:dx <- book name
	call	sendUpdateMessage

done:
	.leave
	ret

sendUpdateMessage:
	push	si
	mov	bp, VUM_NOW
	mov	bx, segment GenPrimaryClass
	mov	si, offset GenPrimaryClass
	mov	di, mask MF_RECORD 
	call	ObjMessage			;di<-handle recorded event
	mov	cx, di	
	pop	si
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock
	retn
CGVChangePrimaryMoniker	endm

BookFileCode	ends
