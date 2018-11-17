COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		inboxControlPanel.asm

AUTHOR:		Adam de Boor, Jun  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 3/94		Initial revision


DESCRIPTION:
	Implementation of InboxControlPanelClass
		

	$Id: inboxControlPanel.asm,v 1.1 97/04/05 01:21:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS
MailboxClassStructures	segment	resource
	InboxControlPanelClass
MailboxClassStructures	ends
endif	; _CONTROL_PANELS

InboxUICode	segment	resource

InboxUICodeDerefGen proc near
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		ret
InboxUICodeDerefGen endp

if	_CONTROL_PANELS		; REST OF FILE IS A NOP UNLESS THIS IS TRUE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InboxGetDefaultSystemCriteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the criteria to use for the system inbox control panel

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		bp	= 0
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InboxGetDefaultSystemCriteria proc	far
		uses	bx, di, ax, ds, es
		.enter
	;
	; Find out how many things are currently in the inbox. We want to get
	; to the last one in there, since that was the last message added.
	; We're very simple-minded about this selection... Another possibility
	; would be to get the message with the highest priority...
	; 
tryAgain:
		call	AdminGetInbox
		call	DBQGetCount
		
		Assert	e, dx, 0		; not more than 65535 entries :)

		tst	ax
		jz	displayAll		; => box is empty, so display
						;  "everything"
	;
	; Get the reference to that item.
	; 
		dec	ax
		mov_tr	cx, ax
		call	DBQGetItem
		jc	tryAgain		; => message left while we were
						;  checking things...
	;
	; Lock down the message so we can copy its destination app to our
	; criteria block.
	; 
		call	MessageLock		; *ds:di <- message desc
	;
	; Allocate a block for the criteria.
	; 
		push	ax, bx
		mov	ax, size MailboxDisplayByAppData
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	allocFailed
	;
	; Copy the token from the message descriptor to the criteria.
	; 
		mov	es, ax			; es <- criteria block
		mov	di, ds:[di]		; ds:di <- MailboxMessageDesc
		mov	ax, {word}ds:[di].MMD_destApp.GT_chars[0]
		mov	{word}es:[MDBAD_token].GT_chars[0], ax
		
		mov	ax, {word}ds:[di].MMD_destApp.GT_chars[2]
		mov	{word}es:[MDBAD_token].GT_chars[2], ax
		
		mov	ax, ds:[di].MMD_destApp.GT_manufID
		mov	es:[MDBAD_token].GT_manufID, ax
	;
	; Criteria now set up. Release the message and the criteria blocks.
	; 
		CheckHack <size MailboxDisplayByAppData eq size GeodeToken>
		call	UtilVMUnlockDS
		call	MemUnlock
	;
	; Remove the reference to the message.
	; 
		mov	cx, bx
		pop	ax, bx
		call	DBQDelRef
	;
	; Return things in the right registers.
	; 
		mov	dx, cx			; ^hdx <- criteria
		mov	cx, MDPT_BY_APP_TOKEN	; cx <- type
done:
		clr	bp		; just in case (unused secondary
					;  criteria)
		.leave
		ret
allocFailed:
	;
	; Couldn't allocate the criteria block, so remove the reference to the
	; final message and tell the thing to display everything.
	; 
		call	UtilVMUnlockDS
		pop	ax, bx
		call	DBQDelRef

displayAll:
		mov	cx, MDPT_ALL		; cx <- type
		clr	dx			; dx <- 0, when MDPT_ALL
		jmp	done
InboxGetDefaultSystemCriteria endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPRetrieveMessages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do what's necessary to retrieve messages from a particular
		transport.

CALLED BY:	MSG_ICP_RETRIEVE_MESSAGES
PASS:		*ds:si	= InboxControlPanel object
		ds:di	= InboxControlPanelInstance
		cx	= transport # (must call the list back to get the
			  actual transport info)
		dl	= GenItemGroupStateFlags
		bp	= number of selections (0 or 1)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	lots

PSEUDO CODE/STRATEGY:
		Call the list back to get the relevant stats
		Spawn a thread to do the rest of the work
		
		XXX: DO WE WANT TO LIMIT THIS TO ONE PER DRIVER?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPRetrieveMessages method dynamic InboxControlPanelClass, 
		    		MSG_ICP_RETRIEVE_MESSAGES
		.enter
	;
	; Allocate a block to hold the transport + medium + transOption to
	; pass to the thread.
	; 
		push	cx
		mov	ax, size MailboxMediaTransport
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		pop	cx
		jc	done		; => can't alloc, so can't retrieve
	;
	; Ask the list for the low-down on this here list index.
	; 
		mov	dx, ax
		clr	bp		; dx:bp <- buffer for result
		mov	ax, MSG_OTM_GET_TRANSPORT
		mov	si, offset InboxPanelGetNewTransports
		call	ObjCallInstanceNoLock
		
		call	IFMaybeFetchMessages
done:
		.leave
		ret
ICPRetrieveMessages endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPMcpSetSpecific
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do things we need doing here...

CALLED BY:	MSG_MCP_SET_SPECIFIC
PASS:		*ds:si	= InboxControlPanel object
		ds:di	= InboxControlPanelInstance
		cx	= MCP_IS_SPECIFIC or MCP_IS_SYSTEM
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPMcpSetSpecific method dynamic InboxControlPanelClass, MSG_MCP_SET_SPECIFIC
		push	cx
		mov	di, offset InboxControlPanelClass
		call	ObjCallSuperNoLock
		pop	cx
			CheckHack <MCP_IS_SYSTEM eq 0>
		jcxz	buildList
		Destroy	cx
done:
		mov	ax, MGCNLT_INBOX_CHANGE
		call	UtilAddToMailboxGCNList
		.leave
		ret

buildList:
		push	si
		mov	si, offset InboxPanelApps
		mov	ax, MSG_IAL_REBUILD_LIST
		call	ObjCallInstanceNoLock
		pop	si

	;
	; If no drivers can retrieve messages, leave the list unusable.
	; 
		call	MediaGetAllTransportCapabilities
		test	ax, mask MBTC_MESSAGE_RETRIEVE
		jz	done
		
		mov	ax, MSG_ICP_MESSAGE_RETRIEVAL_NOW_POSSIBLE
		call	ObjCallInstanceNoLock
		jmp	done
ICPMcpSetSpecific endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPMcpSetCriteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mangle the moniker of the panel if it's a specific panel

CALLED BY:	MSG_MCP_SET_CRITERIA
PASS:		*ds:si	= InboxControlPanelClass object
		es 	= segment of InboxControlPanelClass
		ax	= message #
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
			= 0 if should display all messages from the source
			  queue.
RETURN:		memory block(s) freed
		carry set if no messages fit the criteria. it's then the
			caller's decision whether to bring the box up
			on-screen
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPMcpSetCriteria	method dynamic InboxControlPanelClass, 
					MSG_MCP_SET_CRITERIA
	uses	bp
	.enter

	mov	di, offset InboxControlPanelClass
	call	ObjCallSuperNoLock
	jc	exit

	;
	; Do nothing if we're a system panel
	;
	DerefDI	InboxControlPanel
	jIfSys	ds:[di], done

	;
	; Get first message in list.  (There must be one or else specific
	; panel won't be brought up.)
	;
	push	ds:[di].MCPI_specificRoot
	mov	si, ds:[di].MCPI_messageList
	mov	ax, MSG_ML_GET_MESSAGE
	clr	cx
	call	ObjCallInstanceNoLock	; cxdx = MailboxMessage

	;
	; Get passive verb to stuff into panel moniker
	;
	mov	bx, INBOX_DELIVERY_VERB_PASSIVE
	call	IUGetDeliveryVerbInMessage	; *ds:ax = passive verb
	pop	si			; *ds:si = specificRoot
	call	UtilMangleMoniker
EC <	segmov	es, ds			; to avoid ILLEGAL_SEGMENT when >
EC <					;  using ECF_SEGMENT, since	>
EC <					;  UtilMangleMoniker only fixup ds>
	call	LMemFree		; free verb
done:
	clc				; signal we have a message
exit:

	.leave
	ret
ICPMcpSetCriteria	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPMetaBlockFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the control panel from the GCN list it's on before
		it goes away.

CALLED BY:	MSG_META_BLOCK_FREE
PASS:		*ds:si	= InboxControlPanelClass object
		es 	= segment of InboxControlPanelClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPMetaBlockFree	method dynamic InboxControlPanelClass, 
					MSG_META_BLOCK_FREE

	push	ax
	mov	ax, MGCNLT_INBOX_CHANGE
	call	UtilRemoveFromMailboxGCNList
	pop	ax
	mov	di, offset InboxControlPanelClass
	GOTO	ObjCallSuperNoLock

ICPMetaBlockFree	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPMessageRetrievalNowPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make it possible for the user to retrieve messages, now we
		know there's a transport driver out there that can handle it.

CALLED BY:	MSG_ICP_MESSAGE_RETRIEVAL_NOW_POSSIBLE
PASS:		*ds:si	= InboxControlPanel object
		ds:di	= InboxControlPanelInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	Get New list is set usable and rebuilt

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPMessageRetrievalNowPossible method dynamic InboxControlPanelClass, 
			MSG_ICP_MESSAGE_RETRIEVAL_NOW_POSSIBLE
	; EC: must be the system panel
		Assert	bitSet, ds:[di].MCPI_state, MCPS_IS_SYSTEM

		mov	si, offset InboxPanelGetNewTransports
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock

		mov	ax, MSG_OTM_REBUILD_LIST
		GOTO	ObjCallInstanceNoLock
ICPMessageRetrievalNowPossible endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPMetaSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the TO_INBOX_APPLICATION_LIST and TO_SYSTEM_INBOX_PANEL
		travel options

CALLED BY:	MSG_META_SEND_CLASSED_EVENT
PASS:		*ds:si	= OutboxControlPanel object
		ds:di	= OutboxControlPanelInstance
		^hcx	= classed event
		dx	= TravelOption
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	event freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPMetaSendClassedEvent method dynamic InboxControlPanelClass, 
				MSG_META_SEND_CLASSED_EVENT
		cmp	dx, TO_INBOX_APPLICATION_LIST
		je	toAppList
		cmp	dx, TO_SYSTEM_INBOX_PANEL
		je	dispatch
		mov	di, offset InboxControlPanelClass
		GOTO	ObjCallSuperNoLock
toAppList:
	;
	; Pass the thing off to the transport list to cope with.
	; 
		mov	si, offset InboxPanelApps
dispatch:
	; EC: must be the system panel
		Assert	bitSet, ds:[di].MCPI_state, MCPS_IS_SYSTEM
		mov	dx, TO_SELF		; send classed event to
						;  *this* object, please
						;  (will recurse, I know, but)
		GOTO	ObjCallInstanceNoLock
ICPMetaSendClassedEvent endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPSetApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ICP_SET_APPLICATION
PASS:		*ds:si	= InboxControlPanelClass object
		ds:di	= InboxControlPanelClass instance data
		ds:bx	= InboxControlPanelClass object (same as *ds:si)
		es 	= segment of InboxControlPanelClass
		ax	= message #
		cx	= application index # (must be mapped via ?)
		dl	= GenItemGroupStateFlags
		bp	= number of selections (0 or 1)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPSetApplication	method dynamic InboxControlPanelClass, 
					MSG_ICP_SET_APPLICATION

	;
	; Do nothing if no selection.  (Unlikely)
	;
	tst	bp
	jz	done

	;
	; Ask the app list to map the index to GeodeToken of the app
	;
	push	si			; save self lptr
	mov	si, offset InboxPanelApps
	mov	ax, MSG_IAL_GET_APPLICATION
	call	ObjCallInstanceNoLock	; cxdxbp = GeodeToken
	jc	displayAll

	;
	; Allocate criteria block
	;
	push	ds			; save object block
	push	cx			; save first two chars of token
	mov	ax, size MailboxDisplayPanelCriteria
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK	; just die if we can't even
						;  allocate such a small block!
	call	MemAlloc
	mov	ds, ax
	pop	{word} ds:[MDPC_byApp].MDBAD_token.GT_chars[0]
	mov	{word} ds:[MDPC_byApp].MDBAD_token.GT_chars[2], dx
	mov	ds:[MDPC_byApp].MDBAD_token.GT_manufID, bp
	; don't bother unlocking it since we're *calling* ourselves
	mov	cx, MDPT_BY_APP_TOKEN
	mov	dx, bx			; ^hdx = MailboxDisplayPanelCriteria
	pop	ds			; ds = object block

tellOurselves:
	pop	si			; *ds:si = self
	mov	ax, MSG_MCP_SET_CRITERIA
	GOTO	ObjCallInstanceNoLock

done:
	ret

displayAll:
		CheckHack <MDPT_ALL eq 0>
	clr	cx, dx			; cx = MDPT_ALL, dx = no criteria block
	jmp	tellOurselves

ICPSetApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPMcpGetTitleString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the app name to be inserted into the
		MCPI_specificMoniker

CALLED BY:	MSG_MCP_GET_TITLE_STRING
PASS:		ds:di	= InboxControlPanelClass instance data
RETURN:		*ds:ax	= string to insert into the moniker
DESTROYED	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPMcpGetTitleString	method dynamic InboxControlPanelClass, 
					MSG_MCP_GET_TITLE_STRING

	;
	; Get name of application in criteria
	;
	mov	di, ds:[di].MCPI_primaryCriteria
	Assert	chunk, di, ds
	mov	di, ds:[di]		; ds:di = MessageControlPanelCriteria
	Assert	e, ds:[di].MCPC_type, MDPT_BY_APP_TOKEN
	movdw	cxbx, ds:[di].MCPC_data.MDPC_byApp.MDBAD_token.GT_chars
	mov	dx, ds:[di].MCPC_data.MDPC_byApp.MDBAD_token.GT_manufID
	call	InboxGetAppName		; *ds:ax = app name
	ret

ICPMcpGetTitleString	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPMcpGetDeliveryVerb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_MCP_GET_DELIVERY_VERB
PASS:		ds:di	= InboxControlPanelClass instance data
RETURN:		carry set if deliverAll trigger should not be usable
		carry clear if it should be:
			ax	= lptr of string with which to abuse the
				  deliverAllMoniker
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPMcpGetDeliveryVerb	method dynamic InboxControlPanelClass, 
					MSG_MCP_GET_DELIVERY_VERB
	uses	bp
	.enter

	;
	; Don't use deliverAll trigger if we're display all messages.
	;
	mov	si, ds:[di].MCPI_primaryCriteria
	tst	si
	jz	dontUseTrigger
	mov	si, ds:[si]		; ds:si = MessageControlPanelCriteria
	cmp	ds:[si].MCPC_type, MDPT_ALL
	je	dontUseTrigger

	;
	; Don't use deliverAll trigger either if there're no messages.
	;
	mov	si, ds:[di].MCPI_messageList
	mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
	call	ObjCallInstanceNoLock	; cx = # of messages
	jcxz	dontUseTrigger

	;
	; Get the first message in the list.  (If messages have different
	; verbs, we use the verb from the first message.)
	;
	mov	ax, MSG_ML_GET_MESSAGE
	clr	cx			; get first message
	call	ObjCallInstanceNoLock	; cxdx = MailboxMessage
	mov	bx, INBOX_DELIVERY_VERB_ACTIVE
	call	IUGetDeliveryVerbInMessage	; *ds:ax = lptr of verb to use

	clc

done:
	.leave
	ret

dontUseTrigger:
	stc
	jmp	done
ICPMcpGetDeliveryVerb	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ICPMcpInitializeSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the application list to display the correct item

CALLED BY:	MSG_MCP_INITIALIZE_SELECTION_LIST
PASS:		ds:di	= InboxControlPanelClass instance data
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ICPMcpInitializeSelectionList	method dynamic InboxControlPanelClass, 
					MSG_MCP_INITIALIZE_SELECTION_LIST
	uses	bp
	.enter

	;
	; Get GeodeToken of application in criteria.
	;
	mov	si, ds:[di].MCPI_primaryCriteria
	mov	bp, INBOX_TOKEN_NUM_ALL
	tst	si
	jz	setSelection		; jump if "All" should be selected
	mov	si, ds:[si]		; ds:si = MessageControlPanelCriteria
	Assert	e, ds:[si].MCPC_type, MDPT_BY_APP_TOKEN
	movdw	dxcx, ds:[si].MCPC_data.MDPC_byApp.MDBAD_token.GT_chars
	mov	bp, ds:[si].MCPC_data.MDPC_byApp.MDBAD_token.GT_manufID
					; cxdxbp = GeodeToken
setSelection:
	;
	; Send selection to application list
	;
	mov	si, offset InboxPanelApps
	mov	ax, MSG_IAL_SET_APPLICATION
	call	ObjCallInstanceNoLock

	.leave
	ret
ICPMcpInitializeSelectionList	endm

endif	; _CONTROL_PANELS

InboxUICode	ends
