COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxInit.asm

AUTHOR:		Adam de Boor, Jun  9, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 9/94		Initial revision


DESCRIPTION:
	
		

	$Id: outboxInit.asm,v 1.1 97/04/05 01:21:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the outbox queue

CALLED BY:	(EXTERNAL) AdminInitFile
PASS:		bx	= handle of admin file
RETURN:		carry set if couldn't create
		carry clear if outbox created:
			ax	= handle of outbox DBQ
			cx	= handle of outbox media maps
			dx	= handle of outbox transmission-failure
				  reason map
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxCreate	proc	near
		uses	si, bp, ds
		.enter
		call	OutboxCreateQueue
		push	ax
	;
	; Now create the block that holds two element arrays:
	; 	- one with variable-sized elements that holds medium & unit
	;	  information (indices into this array go in the MITA_medium
	;	  field of each MailboxInternalTransAddr record)
	;	- one with fixed-size elements that holds OutboxMTPair
	;	  structures, so we know for what transports we need to
	;	  display the moniker in the outbox control panel.
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		call	VMAllocLMem
		push	ax, bx
		call	VMLock
		mov	ds, ax
	;
	; First comes the element array that holds the OutboxMTPair elements
	; 
		mov	bx, size OutboxMTPair
		clr	si, cx		; si <- allocate chunk please
					; cx <- use default header
		call	ElementArrayCreate
EC <		cmp	si, ds:[LMBH_offset]				>
EC <		ERROR_NE OUTBOX_MEDIUM_TRANSPORT_MAP_NOT_FIRST_CHUNK	>
	;
	; Now the array that holds the medium/unit pairs for addresses.
	; 
		clr	bx, si, cx	; bx <- variable size
					; si <- allocate chunk please
					; cx <- use default header
		call	ElementArrayCreate
EC <		mov	ax, ds:[LMBH_offset]				>
EC <		inc	ax						>
EC <		inc	ax						>
EC <		cmp	si, ax						>
EC <		ERROR_NE OUTBOX_MEDIUM_UNIT_ARRAY_NOT_SECOND_CHUNK	>
   		call	VMDirty
		call	VMUnlock

	;
	; Mark the block for later EC
	; 
		pop	ax, bx		; ax <- map handle, bx <- VM file
		mov	cx, MBVMID_OUTBOX_MEDIA
		call	VMModifyUserID

		push	ax

	;
	; Now create the block that holds the transmission-failure-reason
	; name array.
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		call	VMAllocLMem
		push	ax, bx
		call	VMLock
		mov	ds, ax
	;
	; Allocate a NameArray with no additional data/element
	; 
		clr	bx		; bx <- no data other than the name
		clr	si, cx		; si <- allocate chunk please
					; cx <- use default header
		call	NameArrayCreate
EC <		cmp	si, ds:[LMBH_offset]				>
EC <		ERROR_NE OUTBOX_REASON_MAP_NOT_FIRST_CHUNK		>
   		call	VMDirty
		call	VMUnlock
	;
	; Mark the block for later EC
	; 
		pop	ax, bx		; ax <- map handle, bx <- VM file
		mov	cx, MBVMID_OUTBOX_REASONS
		call	VMModifyUserID

		mov_tr	dx, ax
		pop	cx		; cx <- map handle
		pop	ax		; ax <- queue handle
		.leave
		ret
OutboxCreate 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxCreateQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the outbox queue.

CALLED BY:	(EXTERNAL) OutboxCreate, AdminFixRefCounts
PASS:		nothing
RETURN:		carry set if couldn't create
		carry clear if outbox queue created:
			ax	= handle of outbox DBQ
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxCreateQueue	proc	near

	mov	dx, enum OutboxMessageAdded
	call	MessageCreateQueue

	ret
OutboxCreateQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxFix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that all the messages currently in the outbox
		have a reference count of 0, or are removed from the outbox
		if they have no unsent addresses.

CALLED BY:	(EXTERNAL) AdminInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We use our own iteration here because (1) we don't have to worry about
	synchronization and consistency, and (2) DBQEnum can't cope with 
	having stuff deleted during the enumeration, which is what we want to
	do if a message has no unsent addresses in it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxFix	proc	near
		uses	bx, di, cx, dx, ax, ds
		.enter
	;
	; Fix the element array of OutboxMTPair elements, and the element
	; array of medium/unit pairs.
	;
		call	AdminGetOutboxMedia
		call	UtilFixTwoChunkArraysInBlock
	;
	; Fix the name array of reason strings.
	;
		call	AdminGetReasons
		call	UtilFixOneChunkArrayInBlock
	;
	; Now check the messages in the inbox queue.
	;
		call	AdminGetOutbox
		clr	cx
msgLoop:
		call	DBQGetItemNoRef		; dxax <- message
		jc	done
		push	di, bx, cx
	;
	; Run through the message's addresses, looking for any that remain
	; unsent, and clearing all the message's talIDs, as an extra precaution.
	; 
		mov	bx, SEGMENT_CS
		mov	di, offset OutboxFixCallback
		clr	cx			; assume nothing unsent
		call	MessageAddrEnum
		tst	cx
		pop	di, bx, cx
		jz	removeMsg		; assumption correct
	;
	; See if the message body is still intact.
	;
		call	MessageCheckBodyIntegrity
		jc	removeMsg

		inc	cx			; else, advance to next message
		jmp	msgLoop

removeMsg:
	;
	; If the message has no unsent addresses, we remove it from the outbox
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
OutboxFix	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxFixCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to fix up a message address and see if it's
		been sent to.

CALLED BY:	(INTERNAL) OutboxFix via MessageAddrEnum
PASS:		ds:di	= MailboxInternalTransAddr
RETURN:		carry set to stop enumerating (always clear)
		cx	= non-zero if address hasn't been sent to yet,
			  unchanged (same as passed cx) if address is sent.
DESTROYED:	nothing
SIDE EFFECTS:	message block is marked dirty + MITA_addrList is set 0

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxFixCallback proc	far
		.enter
		mov	ds:[di].MITA_addrList, 0
	;
	; Do nothing if address state is MAS_SENT.
	;
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE	; clears carry
		jz	done
	;
	; Change any other address state to MAS_EXISTS.
	;
		BitClr	ds:[di].MITA_flags, MTF_STATE
		or	ds:[di].MITA_flags, MAS_EXISTS shl offset MTF_STATE
						; clears carry
		mov	cx, TRUE
done:
		call	UtilVMDirtyDS
		.leave
		ret
OutboxFixCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare the outbox for operation

CALLED BY:	(EXTERNAL) AdminInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Responder: indicator notified of outbox contents

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxInit	proc	near
		.enter
		.leave
		ret
OutboxInit	endp

Init	ends
