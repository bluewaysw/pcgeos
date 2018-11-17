COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox
FILE:		outboxControlPanel.asm

AUTHOR:		Adam de Boor, May 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/26/94		Initial revision


DESCRIPTION:
	
		

	$Id: outboxControlPanel.asm,v 1.1 97/04/05 01:21:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS		; REST OF FILE IS A NOP UNLESS THIS IS TRUE

MailboxClassStructures	segment	resource
	OutboxControlPanelClass
MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCPSetTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the search criteria based on what's selected in
		the OutboxTransportList object

CALLED BY:	MSG_OCP_SET_TRANSPORT
PASS:		*ds:si	= OutboxControlPanel object
		ds:di	= OutboxControlPanelInstance
		cx	= transport+medium index
		dl	= GenItemGroupStateFlags
		bp	= number of selections (0 or 1)
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCPSetTransport method dynamic OutboxControlPanelClass, MSG_OCP_SET_TRANSPORT
		.enter
	;
	; If no selection (unlikely :), leave the list alone.
	; 
		tst	bp
		jz	done
	;
	; Contact the transport list to map the index to the transport+medium
	; 
		push	si
		sub	sp, size MailboxMediaTransport
		mov	bp, sp
		mov	dx, ss
		mov	ax, MSG_OTL_GET_TRANSPORT
		mov	si, offset OutboxPanelTransports
		call	ObjCallInstanceNoLock
	;
	; See if the user wants to see everything (both words of the transport
	; are 0)
	; 
		CmpTok	ss:[bp].MMT_transport, MANUFACTURER_ID_GEOWORKS, \
			GMTID_LOCAL
		je	displayAll
	;
	; Nope. Allocate a block to hold a by-medium set of criteria, for any
	; unit (i.e. no unit data).
	; 
		push	ds
		mov	ax, size MailboxDisplayByMediumData
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or \
				(mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	ds, ax
	;
	; Initialize the criteria and unlock the block.
	; 
		movdw	ds:[MDBMD_transport], ss:[bp].MMT_transport, ax
		mov	ax, ss:[bp].MMT_transOption
		mov	ds:[MDBMD_transOption], ax
		movdw	ds:[MDBMD_medium].MMD_medium, ss:[bp].MMT_medium, ax
		mov	ds:[MDBMD_medium].MMD_unitType, MUT_ANY
		mov	ds:[MDBMD_medium].MMD_unitSize, 0
		call	MemUnlock
		pop	ds
	;
	; Pass the block in DX, with the by-medium display type in CX. BP
	; can be garbage for this display type.
	; 
		mov	dx, bx
		mov	cx, MDPT_BY_MEDIUM

tellOurselves:
		add	sp, size MailboxMediaTransport	; clear the stack...
		pop	si
		mov	ax, MSG_MCP_SET_CRITERIA
		call	ObjCallInstanceNoLock
done:
		.leave
		ret

displayAll:
		mov	cx, MDPT_ALL
		clr	dx
		jmp	tellOurselves
OCPSetTransport endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCPMcpSetSpecific
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this is a system panel, tell the transport list to
		rebuild

CALLED BY:	MSG_MCP_SET_SPECIFIC
PASS:		*ds:si	= OutboxControlPanel object
		ds:di	= OutboxControlPanelInstance
		cx	= MCP_IS_SPECIFIC or MCP_IS_SYSTEM
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCPMcpSetSpecific method dynamic OutboxControlPanelClass, MSG_MCP_SET_SPECIFIC
		.enter
		push	cx
		mov	di, offset OutboxControlPanelClass
		call	ObjCallSuperNoLock
		pop	cx
			CheckHack <MCP_IS_SYSTEM eq 0>
		jcxz	buildList
		Destroy	cx
done:
		mov	ax, MGCNLT_OUTBOX_CHANGE
		call	UtilAddToMailboxGCNList
		.leave
		ret

buildList:
		push	si
		mov	si, offset OutboxPanelTransports
		mov	ax, MSG_OTL_REBUILD_LIST
		call	ObjCallInstanceNoLock
		pop	si
		jmp	done
OCPMcpSetSpecific endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCPMetaBlockFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the control panel from the GCN list it's on before
		it goes away.

CALLED BY:	MSG_META_BLOCK_FREE
PASS:		*ds:si	= OutboxControlPanel object
		ds:di	= OutboxControlPanelInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCPMetaBlockFree method dynamic OutboxControlPanelClass, MSG_META_BLOCK_FREE
		push	ax
		mov	ax, MGCNLT_OUTBOX_CHANGE
		call	UtilRemoveFromMailboxGCNList
		pop	ax
		mov	di, offset OutboxControlPanelClass
		GOTO	ObjCallSuperNoLock
OCPMetaBlockFree endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCPMcpInitializeSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the transport list what it should have selected, based
		on our criteria.

CALLED BY:	MSG_MCP_INITIALIZE_SELECTION_LIST
PASS:		*ds:si	= OutboxControlPanel object
		ds:di	= OutboxControlPanelInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	OutboxPanelTransports selection will change

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCPMcpInitializeSelectionList method dynamic OutboxControlPanelClass, 
				MSG_MCP_INITIALIZE_SELECTION_LIST
		uses	bp
		.enter
		Assert	bitSet, ds:[di].MCPI_state, MCPS_IS_SYSTEM
	;
	; Get the MailboxMediaTransport into registers, after making room
	; for the thing on the stack.
	; 
		sub	sp, size MailboxMediaTransport
		mov	bp, sp
		mov	bx, ds:[di].MCPI_primaryCriteria
		clr	cx, dx, si, ax, di	; assume it's "All"
		tst	bx
		jz	storeMT			; => correct
	    ;
	    ; There is actually something we can use -- load it into registers
	    ; 
		mov	bx, ds:[bx]
		movdw	cxdx, \
			 ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_medium.MMD_medium
		mov	si, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_transOption
		movdw	axdi, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_transport

storeMT:
	;
	; Store the criteria in our buffer on the stack to call the OTL:
	; 	axdi	= MailboxTransport
	;	si	= MailboxTransportOption
	;	cxdx	= MailboxMedium
	;
		movdw	ss:[bp].MMT_transport, axdi
		mov	ss:[bp].MMT_transOption, si
		movdw	ss:[bp].MMT_medium, cxdx
	;
	; Now call the list, finally.
	; 
		mov	si, offset OutboxPanelTransports
		mov	ax, MSG_OTL_SET_TRANSPORT
		mov	dx, ss
		call	ObjCallInstanceNoLock
EC <		ERROR_C	OUTBOX_CRITERIA_REFERS_TO_UNAVAILABLE_TRANSPORT	>
   		add	sp, size MailboxMediaTransport
		.leave
		ret
OCPMcpInitializeSelectionList endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCPMcpGetTitleString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the string, based on the criteria, that can be put in
		the title bar of the panel.

CALLED BY:	MSG_MCP_GET_TITLE_STRING
PASS:		*ds:si	= OutboxControlPanel object
		ds:di	= OutboxControlPanelInstance
RETURN:		*ds:ax	= string to use
DESTROYED:	cx, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCPMcpGetTitleString method dynamic OutboxControlPanelClass, 
				MSG_MCP_GET_TITLE_STRING
		.enter
	;
	; Find the criteria chunk that holds both the medium and the transport,
	; so we can get the string for the combo.
	; 
		mov	bx, ds:[di].MCPI_primaryCriteria
		Assert	chunk, bx, ds
		
		mov	bx, ds:[bx]
		cmp	ds:[bx].MCPC_type, MDPT_BY_MEDIUM
		je	haveMedium

		mov	bx, ds:[di].MCPI_secondaryCriteria
		Assert	chunk, bx, ds
		mov	bx, ds:[bx]
EC <		cmp	ds:[bx].MCPC_type, MDPT_BY_MEDIUM		>
EC <		ERROR_NE SECONDARY_CRITERIA_NOT_BY_MEDIUM		>

haveMedium:
	;
	; ds:bx	= MessageControlPanelCriteria for MDPT_BY_MEDIUM
	;
	; Extract the pair and get the string for it.
	;
		movdw	cxdx, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_medium.MMD_medium
		mov	si, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_transOption
		mov	ax, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_transport.high
		mov	bx, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_transport.low
		call	MediaGetTransportString
EC <		ERROR_C	HOW_CAN_MEDIA_TRANSPORT_BE_INVALID?		>
		.leave
		ret
OCPMcpGetTitleString endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCPMcpGetDeliveryVerb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If it's reasonable, fetch the delivery verb for the current
		display criteria.

CALLED BY:	MSG_MCP_GET_DELIVERY_VERB
PASS:		*ds:si	= OutboxControlPanel object
		ds:di	= OutboxControlPanelInstance
RETURN:		carry set if not appropriate:
			ax	= destroyed
		carry clear if have verb:
			*ds:ax	= verb to use
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCPMcpGetDeliveryVerb method dynamic OutboxControlPanelClass, 
				MSG_MCP_GET_DELIVERY_VERB
		.enter
	;
	; Find the criteria chunk that holds both the medium and the transport,
	; so we can get the verb for the combo.
	; 
		mov	bx, ds:[di].MCPI_primaryCriteria
		tst	bx
		stc
		jz	done			; => displaying All, so no
						;  delivery possible
		Assert	chunk, bx, ds
		
		mov	bx, ds:[bx]
		cmp	ds:[bx].MCPC_type, MDPT_BY_MEDIUM
		je	haveMedium

		mov	bx, ds:[di].MCPI_secondaryCriteria
		Assert	chunk, bx, ds
		mov	bx, ds:[bx]
EC <		cmp	ds:[bx].MCPC_type, MDPT_BY_MEDIUM		>
EC <		ERROR_NE SECONDARY_CRITERIA_NOT_BY_MEDIUM		>

haveMedium:
	;
	; ds:bx	= MessageControlPanelCriteria for MDPT_BY_MEDIUM
	;
	; Extract the pair and get the verb for it.
	;
		movdw	cxdx, \
			 ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_medium.MMD_medium
		mov	si, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_transOption
		mov	ax, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_transport.high
		mov	bx, ds:[bx].MCPC_data.MDPC_byMedium.MDBMD_transport.low
		call	MediaGetTransportVerb
EC <		ERROR_C	HOW_CAN_MEDIA_TRANSPORT_BE_INVALID?		>
done:
		.leave
		ret
OCPMcpGetDeliveryVerb endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCPMetaSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the TO_OUTBOX_TRANSPORT_LIST and TO_SYSTEM_OUTBOX_PANEL,
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
OCPMetaSendClassedEvent method dynamic OutboxControlPanelClass, 
				MSG_META_SEND_CLASSED_EVENT
		cmp	dx, TO_OUTBOX_TRANSPORT_LIST
		je	toTransList
		cmp	dx, TO_SYSTEM_OUTBOX_PANEL
		je	dispatch
		mov	di, offset OutboxControlPanelClass
		GOTO	ObjCallSuperNoLock
toTransList:
	;
	; Pass the thing off to the transport list to cope with.
	; 
		mov	si, offset OutboxPanelTransports
dispatch:
	; EC: must be the system panel
		Assert	ne, ds:[di].MCPI_specificMoniker, 0
		mov	dx, TO_SELF		; send classed event to
						;  *this* object, please
						;  (will recurse, I know, but)
		GOTO	ObjCallInstanceNoLock
OCPMetaSendClassedEvent endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxGetDefaultSystemCriteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the criteria to use when the system outbox panel
		comes up on-screen initially.

CALLED BY:	(EXTERNAL) MailboxApplication::MA_DISPLAY_SYSTEM_OUTBOX_PANEL
PASS:		nothing
RETURN:		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for MDPT_BY_MEDIUM
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxGetDefaultSystemCriteria proc	far
		uses	bx, di, ax, ds, es, si
		.enter
	;
	; Find out how many things are currently in the outbox. We want to get
	; to the last one in there, since that was the last message added.
	; We're very simple-minded about this selection... Another possibility
	; would be to get the message with the highest priority...
	; 
tryAgain:
		call	AdminGetOutbox
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
	; Lock down the message so we can copy out things for the criteria.
	; 
		call	MessageLock
	;
	; Allocate a block for the criteria.
	; 
		push	ax, bx
		mov	ax, size MailboxDisplayByMediumData
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	allocFailed

		mov	es, ax			; es <- criteria block
		mov	si, ds:[di]		; ds:si <- MMD
	;
	; Copy the transport and transport option to the criteria.
	; 
		movdw	es:[MDBMD_transport], ds:[si].MMD_transport, ax
		mov	ax, ds:[si].MMD_transOption
		mov	es:[MDBMD_transOption], ax

		call	OCPGetMediumForFirstUnsentAddress
		jc	addressError
	;
	; Criteria now set up. Release the message and the criteria blocks.
	; 
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
		mov	cx, MDPT_BY_MEDIUM	; cx <- type
done:
		clr	bp		; just in case (unused secondary
					;  criteria)
		.leave
		ret

addressError:
		tst	ax
		jz	getNewEnd

		call	MemFree

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

getNewEnd:
	;
	; Message finished being transmitted while we were here, so don't
	; use it -- go back and get the new end of the outbox.
	; 
		call	MemFree			; discard criteria block
		call	UtilVMUnlockDS		; release message
		pop	ax, bx			; bx <- admin file,
						; dxax <- msg
		call	DBQDelRef
		jmp	tryAgain
OutboxGetDefaultSystemCriteria endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OCPGetMediumForFirstUnsentAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first unsent address for the message and extract
		the MediumType for it into the criteria being built by
		the caller.

CALLED BY:	(INTERNAL) OutboxGetDefaultSystemCriteria
PASS:		es, ^hbx= MailboxDisplayByMediumData
		ds:si	= MailboxMessageDesc
RETURN:		carry set on error:
			ax	= 0 if no unsent address (message got sent
				  after we got its reference)
			ax	= ERROR_INSUFFICIENT_MEMORY if couldn't
				  enlarge the criteria block to hold the
				  medium unit
		carry clear if ok:
			es	= fixed up
			ax	= destroyed
DESTROYED:	si, di, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OCPGetMediumForFirstUnsentAddress proc	near
		.enter

	;
	; Now find the first address for the message to which we've not yet
	; sent the message.
	; 
		mov	si, ds:[si].MMD_transAddrs
		clr	ax
findUnsentLoop:
		call	ChunkArrayElementToPtr
		jc	getNewEnd		; => message finished
						;  transmitting while we were
						;  looking
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jnz	haveAddress		; => we can use this one

		inc	ax			; else advance to next addr #
		jmp	findUnsentLoop		; and look again

haveAddress:
	;
	; Fetch the MailboxMediumDesc that corresponds to the medium index
	; we've got in the address. The thing gets stored right in the criteria
	; block.
	; 
		mov	ax, ds:[di].MITA_medium
		mov	di, offset MDBMD_medium
		mov	cx, size MailboxDisplayByMediumData - \
				offset MDBMD_medium
getMedium:
		call	OMGetMediumDesc
		jnc	done			; => the thing fit
	;
	; Medium descriptor didn't fit in the criteria block, so enlarge that
	; block.
	; 
		push	ax, cx			; save medium index & number
						;  of bytes we will have
		mov_tr	ax, cx			; ax <- size needed
		add	ax, size MailboxDisplayByMediumData - \
				size MailboxMediumDesc
		clr	cx			; cx <- no special flags
		call	MemReAlloc		; ax <- new segment
		mov	es, ax
		pop	ax, cx			; ax <- medium index
						; cx <- # bytes at MDBMD_medium
		jnc	getMedium		; => success
	;
	; Couldn't enlarge -- return error to tell the caller this
	; 
		mov	ax, ERROR_INSUFFICIENT_MEMORY
done:
		.leave
		ret

getNewEnd:
		clr	ax			; indicate message was sent
		stc				;  so couldn't complete, but
						;  please retry
		jmp	done
OCPGetMediumForFirstUnsentAddress endp

OutboxUICode	ends

endif	; _CONTROL_PANELS
