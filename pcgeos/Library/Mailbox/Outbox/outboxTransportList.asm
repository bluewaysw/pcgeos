COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox
FILE:		outboxTransportList.asm

AUTHOR:		Adam de Boor, May 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/26/94		Initial revision


DESCRIPTION:
 
		

	$Id: outboxTransportList.asm,v 1.1 97/04/05 01:21:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS or _POOF_MESSAGE_CREATION

MailboxClassStructures	segment	resource
	OutboxTransportListClass
MailboxClassStructures	ends

endif	; _CONTROL_PANELS or _POOF_MESSAGE_CREATION


OutboxUICode	segment	resource

OutboxUICodeDerefGen proc near
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		ret
OutboxUICodeDerefGen endp

if	_CONTROL_PANELS or _POOF_MESSAGE_CREATION

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTLRebuildList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create items for the list, maintaining any current selection

CALLED BY:	MSG_OTL_REBUILD_LIST
       		MSG_MB_NOTIFY_NEW_TRANSPORT
PASS:		*ds:si	= OutboxTransportList
		ds:di	= OutboxTransportListInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	dynamic list is reinitialized; notification of a new selection
     			will be generated if there was none before, or if
			there is no longer a message in the outbox for the
			transport+medium that was selected before.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTLRebuildList	method OutboxTransportListClass, MSG_OTL_REBUILD_LIST,
				MSG_MB_NOTIFY_NEW_TRANSPORT
		.enter
	;
	; If this is the first call to this method for this list, and the
	; list is not in panel mode, add the list to the NEW_TRANSPORT
	; GCN list in the mailbox application, so we can update as new
	; transports become available.
	; 
		mov	cx, TRUE
		test	ds:[di].OTLI_attrs, mask OTLA_INITIALIZED
		jnz	preserveSelection
		ornf	ds:[di].OTLI_attrs, mask OTLA_INITIALIZED
		
		push	si
		mov	si, ds:[di].OTLI_monikerSource
		Assert	objectPtr, dssi, OutboxTransportMonikerSourceClass
		mov	ax, MSG_OTMS_GET_TYPE
		call	ObjCallInstanceNoLock
		pop	si
			CheckHack <OTMST_PANEL eq 0>
		tst	al
		jz	initialized		; => displaying transports
						;  used by outbox msgs, not
						;  those that are available
						;  to the user, so no need to
						;  be on the GCN list.
		
		mov	ax, MGCNLT_NEW_TRANSPORT
		call	UtilAddToMailboxGCNList
initialized:
		DerefDI	OutboxTransportList
		clr	cx

preserveSelection:
		push	cx
	;
	; Call the moniker source to rebuild its list. We pass any current
	; selection (trusting the list code to store GIGS_NONE if there is
	; no selection) along for the moniker source to fix up for us.
	; 
			CheckHack <Gen_offset eq OutboxTransportList_offset>
		mov	cx, ds:[di].GIGI_selection
		push	si
		mov	si, ds:[di].OTLI_monikerSource
		mov	ax, MSG_OTMS_REBUILD
		call	ObjCallInstanceNoLock	; cx <- new selection #
						; ax <- # entries
		pop	si
	;
	; Always tell our superclass how many entries we have now. This will
	; deselect everything.
	; 
		push	cx, ax		; save new selection #
		mov_tr	cx, ax		; cx <- # entries
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjCallInstanceNoLock
	;
	; Now see if we got a valid selection back from the source.
	; 
		pop	cx, ax			; cx <- new selection #
						; ax <- # entries
		cmp	cx, GIGS_NONE
		jne	haveNewSelection		; => have same selection
							; (ax must be non-zero
							; therefore)
	;
	; Didn't get a selection back. If the list is non-empty, select the
	; first element of the list.
	; 
		tst	ax
		jz	sendNotification	; (leave ax 0 to signal
						;  forced change to nothing-
						;  selected state)
			CheckHack <GIGS_NONE eq -1>
		inc	cx			; cx <- 0 (1-byte inst)
		clr	ax			; signal forced change

haveNewSelection:
	;
	; Select what we've been told to select.
	; 
		push	ax			; save forced-change flag
		clr	dx			; dx <- we're definite
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
		pop	ax

sendNotification:
		pop	cx		; cx <- 0/TRUE. 0 if this was the
					;  first time we were called, which
					;  means we shouldn't send out
					;  notification, as we'll be told
					;  in a moment what we should select

		tst	ax
		jnz	done			; => not actually any change
						;  (found the same transport
						;  in the list as we had
						;  before)
		DerefDI	OutboxTransportList
		test	ds:[di].OTLI_attrs, mask OTLA_NOTIFY_OF_INITIAL_SET
		jnz	doNotify

		jcxz	done

doNotify:
	;
	; Force notification to be sent.
	; 
		mov	cx, TRUE
		mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
		call	ObjCallInstanceNoLock
		mov	ax, MSG_GEN_APPLY
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
OTLRebuildList	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTLSetTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our selection to the one for the passed
		MailboxMediaTransport

CALLED BY:	MSG_OTL_SET_TRANSPORT
PASS:		*ds:si	= OutboxTransportList object
		ds:di	= OutboxTransportListInstance
		dx:bp	= MailboxMediaTransport we want selected
RETURN:		carry set if passed MailboxMediaTransport isn't an option
		carry clear if selection set (no notification sent out)
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTLSetTransport	method dynamic OutboxTransportListClass, MSG_OTL_SET_TRANSPORT
		.enter
		push	si
		mov	si, ds:[di].OTLI_monikerSource
		mov	ax, MSG_OTMS_MAP_TRANSPORT
		call	ObjCallInstanceNoLock
		pop	si
		jc	done
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx		; we're definite
		call	ObjCallInstanceNoLock
		clc
done:
		.leave
		ret
OTLSetTransport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTLGenDynamicListQueryItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the moniker for one of our entries

CALLED BY:	MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
PASS:		*ds:si	= OutboxTransportList
		ds:di	= OutboxTransportListInstance
		bp	= position that needs a moniker
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTLGenDynamicListQueryItemMoniker method dynamic OutboxTransportListClass, 
			MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
		.enter
		push	si
		mov	si, ds:[di].OTLI_monikerSource
		mov	cx, bp
		mov	ax, MSG_OTMS_GET_MONIKER
		call	ObjCallInstanceNoLock
		pop	si
	; EC: since all this stuff happens synchronously, there's no excuse
	; for being asked for something we don't have.
EC <		ERROR_C	REQUEST_FOR_INVALID_ITEM_MONIKER		>

	;
	; ^lcx:dx	= optr of moniker to use.
	; ax		= TRUE if should be selectable
	; bp		= item # for which it's destined
	; 
		mov_tr	di, ax			; save selectable state
		mov_tr	ax, bp			; ax <- item #
		sub	sp, size ReplaceItemMonikerFrame
		mov	bp, sp
	;
	; The source is an optr to text/moniker
	; 
		movdw	ss:[bp].RIMF_source, cxdx
		mov	ss:[bp].RIMF_sourceType, VMST_OPTR
		mov	ss:[bp].RIMF_dataType, VMDT_VIS_MONIKER
		mov	ss:[bp].RIMF_length, 0	; null-terminated
		mov	ss:[bp].RIMF_item, ax
		clr	ax			; ax <- nothing special
		tst	di
		jnz	setItemFlags
		mov	ax, mask RIMF_NOT_ENABLED
setItemFlags:
		mov	ss:[bp].RIMF_itemFlags,ax
	;
	; Tell our superclass what the moniker is.
	; 
		push	cx, dx
		mov	dx, size ReplaceItemMonikerFrame
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
		call	ObjCallInstanceNoLock
	;
	; Free the text string/moniker if it's in our block.
	; 
		pop	cx, ax			; ^lcx:ax <- string/moniker
		add	sp, size ReplaceItemMonikerFrame
		cmp	cx, ds:[LMBH_handle]
		jne	done
		call	LMemFree
done:
		.leave
		ret

OTLGenDynamicListQueryItemMoniker endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTLGetTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the actual transport+medium that corresponds to a
		selection in the list, please

CALLED BY:	MSG_OTL_GET_TRANSPORT
PASS:		*ds:si	= OutboxTransportList
		ds:di	= OutboxTransportListInstance
		cx	= list index
		dx:bp	= MailboxMediaTransport buffer to fill in
RETURN:		dx:bp	= filled in (MT_transport is GEOWORKS::GMTID_LOCAL to
			  display all messages => MT_medium is
			  GEOWORKS::GMMID_INVALID)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTLGetTransport	method dynamic OutboxTransportListClass, MSG_OTL_GET_TRANSPORT
		mov	si, ds:[di].OTLI_monikerSource
		mov	ax, MSG_OTMS_GET_TRANSPORT
		GOTO	ObjCallInstanceNoLock
OTLGetTransport	endm

endif	; _CONTROL_PANELS or _POOF_MESSAGE_CREATION

OutboxUICode	ends

