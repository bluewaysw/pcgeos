COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		messageControlPanel.asm

AUTHOR:		Adam de Boor, May 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/26/94		Initial revision


DESCRIPTION:
	
		

	$Id: messageControlPanel.asm,v 1.1 97/04/05 01:20:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS

MailboxClassStructures	segment	resource
	MessageControlPanelClass
MailboxClassStructures	ends

endif	; _CONTROL_PANELS

MessageUICode	segment	resource

MessageUICodeDerefGen	proc	near
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		ret
MessageUICodeDerefGen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPSetSpecific
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record whether the panel is for a specific transport /
		application or is the system panel

CALLED BY:	MSG_MCP_SET_SPECIFIC
PASS:		*ds:si	= MessageControlPanel object
		ds:di	= MessageControlPanelInstance
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
if	_CONTROL_PANELS
MCPSetSpecific	method dynamic MessageControlPanelClass, MSG_MCP_SET_SPECIFIC
		.enter
EC <		cmp	cx, MCP_IS_SYSTEM				>
EC <		je	flagOK						>
EC <		cmp	cx, MCP_IS_SPECIFIC				>
EC <		ERROR_NE INVALID_MCP_SPECIFIC_FLAG			>
EC <flagOK:								>
	CheckHack <MCP_IS_SYSTEM eq 0>
		jcxz	freeSpec	; if it's a system panel, just need
					;  to free the specific moniker...

	;
	; Set the non-specific tree not-usable, first
	; 
		push	ds:[di].MCPI_specificRoot
		mov	si, ds:[di].MCPI_nonSpecificRoot
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjCallInstanceNoLock
	;
	; Now set the specific tree usable.
	; 
		pop	si		; *ds:si <- MCPI_specificRoot
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
done:
		.leave
		ret

freeSpec:
	;
	; System panel, so blow away the specific moniker.
	; 
		mov	ax, ds:[di].MCPI_specificMoniker
		call	LMemFree

	; EC: so things blow up if they try to use this field for anything
EC <		mov	ds:[di].MCPI_specificMoniker, -1		>
		ornf	ds:[di].MCPI_state, mask MCPS_IS_SYSTEM
		jmp	done
MCPSetSpecific	endm
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPSetCriteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the criteria and notify the message list of them

CALLED BY:	MSG_MCP_SET_CRITERIA
PASS:		*ds:si	= MessageControlPanel object
		ds:di	= MessageControlPanelInstance
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
			= 0 if MDPT_ALL
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for
				  MDPT_BY_MEDIUM
		else
			bp	= garbage
RETURN:		memory block(s) freed
		carry set if no messages fit the criteria. It's then the
			caller's decision whether to bring the box up on-screen
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MCPSetCriteria	method dynamic MessageControlPanelClass, MSG_MCP_SET_CRITERIA
		.enter
		Assert	etype, cx, MailboxDisplayPanelType
	;
	; Free up the existing criteria chunks, please.
	; 
		clr	ax
		xchg	ds:[di].MCPI_primaryCriteria, ax
		tst	ax
		jz	freeSecondary
		call	LMemFree
freeSecondary:
		clr	ax
		xchg	ds:[di].MCPI_secondaryCriteria, ax
		tst	ax
		jz	copyPrimary
		call	LMemFree
copyPrimary:
		cmp	cx, MDPT_ALL
		je	tellList
	;
	; Actually have some criteria. Copy the primary one into our block.
	; 
		call	MCPCopyCriteria		; *ds:ax <- criteria
						; ds:di <- MCPI
		mov	ds:[di].MCPI_primaryCriteria, ax
		cmp	cx, MDPT_BY_TRANSPORT
		jne	maybeTellApp		; => no secondary
	;
	; Primary is BY_TRANSPORT, so we need to copy in the secondary, too.
	; 
		push	dx
		mov	dx, bp
		mov	cx, MDPT_BY_MEDIUM
		call	MCPCopyCriteria
		mov	ds:[di].MCPI_secondaryCriteria, ax
		pop	dx

maybeTellApp:
	;
	; If this is a system panel, we need to let the app know we've changed
	; criteria.
	; 
		jIfSpec	ds:[di], freeBlocks

		call	MCPSysPanelCriteriaChanged
		jmp	tellList

freeBlocks:
		call	MCPNonSysPanelCriteriaChanged

tellList:
	;
	; Let the message list know the chunk handles that hold the criteria
	; 
		DerefDI	MessageControlPanel
		push	bp, si
		mov	dx, ds:[di].MCPI_primaryCriteria
		mov	bp, ds:[di].MCPI_secondaryCriteria
		mov	si, ds:[di].MCPI_messageList
		Assert	objectPtr, dssi, MessageListClass
		mov	ax, MSG_ML_SET_CRITERIA
		call	ObjCallInstanceNoLock	; CF <- 1 if empty
		pop	bp, si
	;
	; Mess with the deliver-all trigger.
	; 
		call	MCPSetupDeliveryTrigger	; (flags preserved)
		.leave
		ret
MCPSetCriteria	endm
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPSetupDeliveryTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the deliver-all trigger is in its proper state
		with its proper moniker

CALLED BY:	(INTERNAL) MCPSetCriteria
PASS:		*ds:si	= MessageControlPanel object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di (flags preserved)
SIDE EFFECTS:	delivery trigger is set usable or not
     		delivery trigger's moniker replaced if set usable

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MCPSetupDeliveryTrigger proc	near
		class	MessageControlPanelClass
		.enter
		pushf			; save no-messages result flag

	;
	; If displaying messages for something specific (this is a different
	; distinction than between system/non-system), set the delivery
	; trigger usable after setting up its moniker.
	; 
		mov	ax, MSG_MCP_GET_DELIVERY_VERB
		call	ObjCallInstanceNoLock
		jc	noDelivery
		
		Assert	chunk, ax, ds
		mov_tr	bx, ax		; *ds:bx <- chunk
		DerefDI	MessageControlPanel
		mov	si, ds:[di].MCPI_deliveryTrigger
		Assert	objectPtr, dssi, GenTriggerClass
		mov	ax, ds:[di].MCPI_deliveryMoniker
		Assert	chunk, ax, ds
		call	UtilSetMonikerFromTemplate

		mov_tr	ax, bx		; *ds:ax <- verb chunk
		call	LMemFree	;  which we want freed
		mov	ax, MSG_GEN_SET_USABLE

setUsableNotUsable:
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		popf			; CF <- no-messages result flag
		.leave
		ret
noDelivery:
		DerefDI	MessageControlPanel
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	si, ds:[di].MCPI_deliveryTrigger
		jmp	setUsableNotUsable
MCPSetupDeliveryTrigger endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPSysPanelCriteriaChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the part of MessageControlPanel::MCP_SET_CRITERIA that
		is specific to system control panels

CALLED BY:	(INTERNAL) MCPSetCriteria
PASS:		*ds:si	= MessageControlPanel object
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for MDPT_BY_MEDIUM
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	application object is notified of the change (it will free
     			the criteria block(s))
		subclass is told to initialize its selection list

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MCPSysPanelCriteriaChanged proc	near
		class	MessageControlPanelClass
		.enter
		mov	ax, MSG_MA_OUTBOX_SYS_PANEL_CRITERIA_CHANGED
		mov	di, ds:[si]
		cmp	ds:[di].MB_class.offset, offset OutboxControlPanelClass
		je	tellApp
		mov	ax, MSG_MA_INBOX_SYS_PANEL_CRITERIA_CHANGED
EC <		cmp	ds:[di].MB_class.offset, offset InboxControlPanelClass>
EC <		ERROR_NE UNKNOWN_CONTROL_PANEL_SUBCLASS			>
tellApp:
		push	ds:[LMBH_handle]
		call	UtilSendToMailboxApp
		pop	bx
		call	MemDerefDS
	;
	; Tell our subclass to inform the selection list what the criteria are.
	;
		mov	ax, MSG_MCP_INITIALIZE_SELECTION_LIST
		call	ObjCallInstanceNoLock
		.leave
		ret
MCPSysPanelCriteriaChanged endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPNonSysPanelCriteriaChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the part of MessageControlPanel::MCP_SET_CRITERIA that
		is specific to non-system control panels

CALLED BY:	(INTERNAL) MCPSetCriteria
PASS:		*ds:si	= MessageControlPanel object
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for MDPT_BY_MEDIUM
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	criteria blocks freed
     		control panel moniker changed according to subclass-returned
			title string

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MCPNonSysPanelCriteriaChanged proc	near
		class	MessageControlPanelClass
		.enter
	;
	; Don't need the criteria blocks any more, so free them.
	; 
			CheckHack <MDPT_ALL eq 0>
		jcxz	mangleTitle		; => nothing to free

		mov	bx, dx
		call	MemFree

		cmp	cx, MDPT_BY_TRANSPORT
		jne	mangleTitle
		mov	bx, bp
		call	MemFree
mangleTitle:
	;
	; Mangle our moniker appropriately, please.
	; 
		mov	ax, MSG_MCP_GET_TITLE_STRING
		call	ObjCallInstanceNoLock
		Assert	chunk, ax, ds

		mov_tr	bx, ax
		DerefDI	MessageControlPanel
		mov	ax, ds:[di].MCPI_specificMoniker
	; EC: so things blow up if they try to use this field for anything
EC <		mov	ds:[di].MCPI_specificMoniker, -1		>
		push	ax
		call	UtilSetMonikerFromTemplate
		pop	ax
		call	LMemFree	; free specificMoniker

		mov_tr	ax, bx
		call	LMemFree
		.leave
		ret
MCPNonSysPanelCriteriaChanged endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPGetTitleString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	EC: Blow up if we get here

CALLED BY:	MSG_MCP_GET_TITLE_STRING
PASS:		*ds:si	= MessageControlPanel object
		ds:di	= MessageControlPanelInstance
RETURN:		not
DESTROYED:	life
SIDE EFFECTS:	death death death

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK and _CONTROL_PANELS
MCPGetTitleString method dynamic MessageControlPanelClass, MSG_MCP_GET_TITLE_STRING
		ERROR	TITLE_STRING_MUST_BE_PROVIDED_BY_SUBCLASS
MCPGetTitleString endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPCopyCriteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the MailboxDisplayPanelCriteria and MailboxDisplayPanelType
		into a chunk in this block.

CALLED BY:	(INTERNAL) MCPSetCriteria
PASS:		*ds:si	= MessageControlPanel object
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
RETURN:		*ds:ax	= MessageControlPanelCriteria
		ds:di	= MessageControlPanelInstance
DESTROYED:	nothing
SIDE EFFECTS:	block & chunks may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MCPCopyCriteria	proc	near
		uses	cx, es, bx, dx
		class	MessageControlPanelClass
		.enter
		mov	bx, dx

	;
	; Find the number of bytes in the criteria, all of which we need
	; to copy in.
	; 
	; XXX: could actually use the number of bytes in the criteria itself,
	; based on the display type...
	; 
		Assert	handle, bx
		push	cx			; save display type
		mov	ax, MGIT_SIZE
		call	MemGetInfo
	;
	; Allocate that much room, plus room for the display type.
	; 
		mov_tr	cx, ax
		add	cx, size MCPC_type	; need room for the display
						;  type, too
		clr	al
		call	LMemAlloc
	;
	; Lock down the criteria block and set up registers for the big
	; move-o-rama.
	; 
		mov	dx, si			; preserve MCP object
		mov_tr	si, ax
		segmov	es, ds
		mov	di, ds:[si]
		add	di, offset MCPC_data	; es:di <- destination

		call	MemLock
		mov	ds, ax
		push	si
		clr	si			; ds:si <- source
	;
	; We like to move words, and we can save a dec cx if we remove the
	; size MCPC_type after the division by two...
	; 
		shr	cx
		CheckHack <size MCPC_type eq 2>
		dec	cx
		rep	movsw
	;
	; Recover the object block segment.
	; 
		pop	si
		segmov	ds, es			; *ds:si <- criteria
	;
	; Store the display type in the criteria.
	; 
		pop	cx			; cx <- display type
		mov	di, ds:[si]
		mov	ds:[di].MCPC_type, cx
	;
	; Set up the return registers
	; 
		mov_tr	ax, si			; *ds:ax <- criteria
		mov	si, dx			; *ds:si <- MCP object
		mov	di, ds:[si]
		add	di, ds:[di].MessageControlPanel_offset
		.leave
		ret
MCPCopyCriteria	endp
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPMessageSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has selected a message in the message list. Map
		the number to a MailboxMessage + address # and invoke
		MSG_MCP_DISPLAY_DETAILS on ourselves

CALLED BY:	MSG_MCP_MESSAGE_SELECTED
PASS:		*ds:si	= MessageControlPanel object
		ds:di	= MessageControlPanelInstance
		cx	= message #
		dl	= GenItemGroupStateFlags
		bp	= number of selections
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MCPMessageSelected method dynamic MessageControlPanelClass, 
				MSG_MCP_MESSAGE_SELECTED
		.enter
		tst	bp
		jz	done		; => no selection, so do nothing
		
		push	si
		mov	si, ds:[di].MCPI_messageList
		Assert	objectPtr, dssi, MessageListClass
		mov	ax, MSG_ML_GET_MESSAGE
		call	ObjCallInstanceNoLock
		pop	si
		
		mov	ax, MSG_MCP_DISPLAY_DETAILS
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
MCPMessageSelected endm
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPDisplayDetails
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up the proper detail box for the selected message.
		By default, we send MSG_MD_SET_MESSAGE to the MCPI_detailsBox

CALLED BY:	MSG_MCP_DISPLAY_DETAILS
PASS:		*ds:si	= MessageControlPanel object
		ds:di	= MessageControlPanelInstance
		cxdx	= MailboxMessage
		bp	= address # (+ dups) to display, if message is in
			  the outbox.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MCPDisplayDetails method dynamic MessageControlPanelClass, 
				MSG_MCP_DISPLAY_DETAILS
		mov	si, ds:[di].MCPI_detailsBox
		Assert	objectPtr, dssi, MessageDetailsClass
		mov	ax, MSG_MD_SET_MESSAGE
		GOTO	ObjCallInstanceNoLock
MCPDisplayDetails endm
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPMetaBlockFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release the messages displayed in the message list and
		details box before we get destroyed.

CALLED BY:	MSG_META_BLOCK_FREE
PASS:		*ds:si	= MessageControlPanel object
		ds:di	= MessageControlPanelInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		I shouldn't have to notify the details box of this, because
		we should have been set not usable, which should have forced
		the details box down, causing it to release the reference to
		its message in its VIS_CLOSE method.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MCPMetaBlockFree method dynamic MessageControlPanelClass, MSG_META_BLOCK_FREE
		uses	ax, si
		.enter
	;
	; Tell the message list to clear itself out, so the references to the
	; messages are removed.
	; 
		mov	si, ds:[di].MCPI_messageList
		mov	ax, MSG_ML_RELEASE_MESSAGES
		call	ObjCallInstanceNoLock
	;
	; Don't need to worry about GCN lists here, as OutboxTransportList
	; only adds itself when not in panel mode...
	; 
		.leave
		mov	di, offset MessageControlPanelClass
		GOTO	ObjCallSuperNoLock
MCPMetaBlockFree endm
endif	; _CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MCPUpdateList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the MessageList we contain to update properly.

CALLED BY:	(INTERNAL) MessageControlPanel::MB_NOTIFY_BOX_CHANGE
PASS:		*ds:si	= MessageControl
		ds:di	= MessageControlInstance
		cxdx	= MailboxMessage affected
		bp	= MABoxChange
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, si, di
SIDE EFFECTS:	dialog will be destroyed if it's specific and the list is
     			no longer showing any messages

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MCPUpdateList	method dynamic MessageControlPanelClass,
				MSG_MB_NOTIFY_BOX_CHANGE
		class	MessageControlPanelClass
		.enter
	;
	; First call the MessageList with the news.
	; 
		push	si
		mov	si, ds:[di].MCPI_messageList
		Assert	objectPtr, dssi, MessageListClass
		mov	ax, MSG_ML_UPDATE_LIST
		call	ObjCallInstanceNoLock
		pop	si
		jnc	done		; => not empty
	;
	; Message list is now empty. See if we're a specific or a system panel
	; 
		mov	di, ds:[si]
		add	di, ds:[di].MessageControlPanel_offset
		jIfSys	ds:[di], done 	; => system panel, so this is ok.
					;  if we're displaying for a particular
					;  transport or app, we should
					;  momentarily have our criteria changed
					;  by the transport/app list when it
					;  realizes it shouldn't be displaying
					;  that
	;
	; We're a specific panel -- kill ourselves.
	; 
		mov	cx, ds:[LMBH_handle]
		mov	dx, si		; ^lcx:dx <- dialog
		mov	ax, MSG_MA_DESTROY_DIALOG
		call	UtilSendToMailboxApp
done:
		.leave
		ret
MCPUpdateList	endp
endif	; _CONTROL_PANELS

MessageUICode	ends
