COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox
FILE:		outboxNotify.asm

AUTHOR:		Adam de Boor, Jun  1, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 1/94		Initial revision


DESCRIPTION:
	Cope with medium available/connected notifications.
		

	$Id: outboxNotify.asm,v 1.1 97/04/05 01:21:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Outbox	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxNotifyMediumNotAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look to see if there's a message for the medium and
		complain if there is.

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= MediumType
		bx	= unit number
		al	= MediumUnitType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		See if there's an entry in the OutboxMedia block for the
		unit. If so, there's a message and we complain.

		For Responder, we incorporate the medium-not-available
		reason string.  And since GMID_CELL_MODEM and GMID_SM
		are made available/not-available together, we do some
		work to only put up one warning even when there's messages
		for both mediums.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_HONK_IF_MEDIUM_REMOVED


OutboxNotifyMediumNotAvailable proc	far
		uses	ax
		.enter
		call	OMFind			; ax = medium token if found
		jnc	done

		push	si
		mov	si, offset uiMediumRemovedHonk
		call	UtilDoError
		pop	si
done:
		.leave
		ret
OutboxNotifyMediumNotAvailable endp


endif	; _HONK_IF_MEDIUM_REMOVED

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxNotifyMediumAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up a panel to display messages for the given medium.

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE)
		al	= MediumUnitType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	control panel may come up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxNotifyMediumAvailable proc	far
		uses	bp
		.enter
if	_CONNECTED_MEDIUM_NOTIFICATION
		mov	bp, offset ONGenerateByMediumNotify
		call	ONEnumTransports
endif	; _CONNECTED_MEDIUM_NOTIFICATION
	
if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
	;
	; Let any blocked transmit thread continue, now the medium's available
	;
		call	ONWakeupTransmitThread
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM

		.leave
		ret
OutboxNotifyMediumAvailable endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ONWakeupTransmitThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If a transmit thread is blocked waiting for this medium to
		become available/not connected, wake it up.

CALLED BY:	(INTERNAL) OutboxNotifyMediumAvailable
			   OutboxNotifyMediumNotConnected
PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE)
		al	= MediumUnitType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
ONWakeupTransmitThread proc	near
		uses	ax, ds, di
		.enter
		call	OMFind			; ax <- medium token
		jnc	done

		call	OTFindThread		; ds:di <- OTD
		jnc	releaseThreadBlock

		push	bx
		call	OTMaybeWakeup
		pop	bx
releaseThreadBlock:
		call	MainThreadUnlock
done:
		.leave
		ret
ONWakeupTransmitThread endp
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxNotifyMediumConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up a panel to display messages for the address to
		which the given medium is connected.

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE)
		al	= MediumUnitType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	control panel may come up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxNotifyMediumConnected proc	far
if	_CONNECTED_MEDIUM_NOTIFICATION
		uses	bp
		.enter
		mov	bp, offset ONGenerateByTransportNotify
		call	ONEnumTransports
		.leave
endif	; _CONNECTED_MEDIUM_NOTIFICATION
		ret
OutboxNotifyMediumConnected endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxNotifyMediumNotConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that some medium might be available for 
		transmission now it's no longer connected

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE)
		al	= MediumUnitType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	control panel may come up

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxNotifyMediumNotConnected proc	far
		.enter
if	_CONNECTED_MEDIUM_NOTIFICATION
		mov	bp, offset ONGenerateByMediumNotify
		call	ONEnumTransports
endif	; _CONNECTED_MEDIUM_NOTIFICATION

if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM
		call	ONWakeupTransmitThread
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM
		.leave
		ret
OutboxNotifyMediumNotConnected endp

if	_CONNECTED_MEDIUM_NOTIFICATION

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ONGenerateByMediumNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the mailbox application to display a panel for
		messages using this medium

CALLED BY:	
PASS:		axbx	= MailboxTransport
		si	= MailboxTransportOption
		^hcx	= MailboxDisplayByMediumData
		dx	= unit number, in case it's 
			  MUT_MEM_BLOCK
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, bx, cx, dx, bp, si, di, es allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ONGenerateByMediumNotify proc	near
		uses	ds
		.enter
	;
	; Create a new criteria block specific to this transport, so the
	; mb app can free the thing at its discretion.
	; 
		call	ONDupByMediumBlock	; dx <- new criteria
		jc	done			; => couldn't alloc, so drop
						;  notification on the floor
	;
	; Ask the mailbox app to put up a panel for this combo.
	; 
		mov	cx, MDPT_BY_MEDIUM
		mov	ax, MSG_MA_DISPLAY_OUTBOX_PANEL
		call	UtilSendToMailboxApp
done:
		clc				; always keep enumerating
		.leave
		ret
ONGenerateByMediumNotify endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ONDupByMediumBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the template by-medium criteria block and then
		duplicate it, so it can be sent to the app object

CALLED BY:	(INTERNAL) ONGenerateByMediumNotify,
			   ONGenerateByTransportNotify
PASS:		axbx	= MailboxTransport
		si	= MailboxTransportOption
		^hcx	= template by-medium criteria
RETURN:		carry set if couldn't allocate:
			dx	= destroyed
		carry clear if ok:
			^hdx	= criteria to use
DESTROYED:	ax, bx, cx, ds, es, si, di
SIDE EFFECTS:	template's MDBMD_transport field is modified

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ONDupByMediumBlock proc	near
		.enter
	;
	; Lock down the template criteria.
	; 
		xchg	bx, cx		; cx <- trans.low, bx <- template
		mov_tr	dx, ax		; dx <- trans.high
		call	MemLock
		mov	ds, ax
	;
	; Stuff the transport token into place.
	; 
		movdw	ds:[MDBMD_transport], dxcx
		mov	ds:[MDBMD_transOption], si
		push	bx		; save template handle for unlock
	;
	; Compute the number of bytes in the block & allocate a new one, locked
	; 
		mov	ax, ds:[MDBMD_medium].MMD_unitSize
		add	ax, size MailboxDisplayByMediumData
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		mov	bx, handle 0
		push	ax
		call	MemAllocSetOwner
		pop	cx
		jc	done
	;
	; Move the bytes from the template to the copy.
	; 
		mov	es, ax
		clr	si, di
		rep	movsb
	;
	; Unlock the copy.
	; 
		call	MemUnlock
		mov	dx, bx
done:
	;
	; Unlock the template.
	; 
		pop	bx
		call	MemUnlock
		.leave
		ret
ONDupByMediumBlock endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ONEnumTransports
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback routine, with a MailboxDisplayByMediumData
		block, for each transport that uses the given medium

CALLED BY:	(INTERNAL)  OutboxNotifyMediumAvailable,
		OutboxNotifyMediumConnected.

PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE)
		al	= MediumUnitType
		cs:bp	= callback routine
			  Pass:	axbx	= MailboxTransport
				si	= MailboxTransportOption
			  	^hcx	= MailboxDisplayByMediumData
				dx	= unit number, in case it's 
					  MUT_MEM_BLOCK
			  Return:	carry set to stop enumerating
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	control panels may be put up

PSEUDO CODE/STRATEGY:
	Allocate a MailboxDisplayByMediumData, and fill it in, except for 
		the transport field.
	Obtain a list of tokens for transports that use the medium in 
		question.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ONEnumTransports proc	near
callbackRoutine	local	word		push	bp
unitNum		local	word		push	bx
		uses	ds, bx, cx, ax, dx, si, di, es
		.enter
	;
	; Standard shme to convert from this awkward unit-number format to
	; a far pointer + size for the unit data to copy into the notification
	; block.
	; 
		push	ax, bx, cx
		clr	ah
			CheckHack <MUT_NONE eq 0>
		cmp	al, MUT_NONE
		je	haveUnit
		cmp	al, MUT_INT
		je	useLocalVar
		Assert	ne, al, MUT_ANY	; can't generate notification
						;  for "any" unit...

EC <		cmp	al, MUT_MEM_BLOCK				>
EC <		ERROR_NE	UNKNOWN_MEDIUM_UNIT_TYPE		>
		
		call	MemLock
		mov	ds, ax
		clr	si			; ds:si <- unit data
		mov	ax, MGIT_SIZE
		call	MemGetInfo		; ax <- # bytes
		jmp	haveUnit

useLocalVar:
		segmov	ds, ss
		lea	si, ss:[unitNum]
		mov	ax, size unitNum

haveUnit:
	;
	; ds:si	= unit data
	; ax	= # bytes
	;
	; Allocate a block to hold the by-medium criteria.
	; 
		push	ax
		add	ax, size MailboxDisplayByMediumData
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		call	MemAlloc
		pop	cx			; cx <- # bytes of unit data
		jc	allocErr		; oh well
	;
	; Copy the unit data in.
	; 
		mov	es, ax
		mov	es:[MDBMD_medium].MMD_unitSize, cx
		mov	di, offset MDBMD_medium.MMD_unit
		rep	movsb
		mov	si, bx
		pop	ax, bx, cx		; ax <- unit type
						; bx <- unit number
						; cx <- medium.high
	;
	; Fill in the other parts of the criteria.
	; 
		mov	es:[MDBMD_medium].MMD_unitType, al
		movdw	es:[MDBMD_medium].MMD_medium, cxdx
	;
	; Unlock the unit block for now, if that's what we were passed.
	; 
		cmp	al, MUT_MEM_BLOCK
		jne	allocLMem
		call	MemUnlock
allocLMem:
	;
	; Allocate an lmem block into which MediaGetTransports can copy the
	; array of transport driver tokens that use the medium for which we
	; received notification.
	; 
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		push	bx			; save unit # for passing to
						;  callback
		call	MemAllocLMem		; bx <- handle (no err)
		call	MemLock
		mov	ds, ax
		mov	cx, es:[MDBMD_medium].MMD_medium.high
		call	MediaGetTransports	; *ds:ax <- array
		pop	dx			; dx <- unit # for callback

	;
	; Now enumerate those transports, calling the callback for each.
	; 
		push	bx			; save lmem block handle for
						;  later free
		mov	bx, si			; bx <- criteria block
		call	MemUnlock		;  which no longer needs to be
						;   locked
		mov	cx, si			; cx <- criteria block for
						;  callback
		push	bp
		mov	bp, callbackRoutine
		mov	bx, cs
		mov	di, offset ONEnumTransportsCallback
		mov_tr	si, ax			; *ds:si <- array to enumerate
		call	ChunkArrayEnum
		pop	bp
	;
	; Free the block with the array
	; 
		pop	bx
		call	MemFree
	;
	; Free the criteria block.
	; 
		mov	bx, cx
		call	MemFree
	;
	; We leave the unit number block for the caller to handle.
	; 
done:
		.leave
		ret

allocErr:
	;
	; If we can't allocate the criteria block, we just don't tell the user
	; about the messages that could be sent. no big wup.
	; 
		pop	ax, bx, cx
		jmp	done
ONEnumTransports endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ONEnumTransportsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to call another callback for each transport
		that uses a particular medium

CALLED BY:	(INTERNAL) ONEnumTransports via ChunkArrayEnum
PASS:		ds:di	= MailboxTransportAndOption for which to call
		^hcx	= MailboxDisplayByMediumData block
		dx	= unit number, in case it's MUT_MEM_BLOCK
		cs:bp	= callback routine to call:
			  Pass:	axbx	= MailboxTransport
				si	= MailboxTransportOption
			  	^hcx	= MailboxDisplayByMediumData
				dx	= unit number, in case it's 
					  MUT_MEM_BLOCK
			  Return:	carry set to stop enumerating
RETURN:		carry set to stop enumerating
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ONEnumTransportsCallback proc	far
		uses	cx, dx, bp
		.enter
		movdw	axbx, ds:[di].MTAO_transport
		mov	si, ds:[di].MTAO_transOption
		call	bp
		.leave
		ret
ONEnumTransportsCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ONGenerateByTransportNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this transport driver can cope with the connection
		we've been told exists over a medium. If it can, tell the
		mailbox application to display a panel for messages to the
		address to which the transport driver says the connection 
		was made.

CALLED BY:	OutboxNotifyMediumConnected, via ONEnumTransports
PASS:		axbx	= MailboxTransport
		si	= MailboxTransportOption
		^hcx	= MailboxDisplayByMediumData
		dx	= unit number, in case it's 
			  MUT_MEM_BLOCK
RETURN:		carry set to stop enumerating (set if driver said the 
			connection was something it could handle)
DESTROYED:	ax, bx, cx, dx, bp, si, di, es allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		load transport driver. if that fails, bail
		find DIS and call to get the max address size.
		allocate a by-transport block to hold that big an address
		setup the MBTDMediumMapArgs
		talk to the driver
		if driver is happy, fill in the rest of the by-transport block,
			dup the by-medium block and notify the app

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ONGenerateByTransportNotify proc	near
origByMedium	local	hptr			push cx
transport	local	MailboxTransport	push ax, bx
transOption	local	MailboxTransportOption	push si
transDriver	local	hptr
strat		local	fptr.far
mapArgs		local	MBTDMediumMapArgs
		uses	ds
		.enter
	;
	; First load the transport driver.
	; 
		mov	ss:[mapArgs].MBTDMMA_unit, dx
		movdw	cxdx, axbx
		call	MailboxLoadTransportDriver
		jnc	haveDriver
		clc			; => keep enumerating
		jmp	done
haveDriver:
	;
	; Got it. Now find the thing's strategy routine.
	; 
		mov	ss:[transDriver], bx
		call	GeodeInfoDriver
		movdw	ss:[strat], ds:[si].DIS_strategy, ax
	;
	; Extract the medium & unit type (original unit "number" is already
	; in the map args) from the by-medium criteria and store them in the
	; driver args.
	; 
		mov	bx, ss:[origByMedium]
		call	MemLock
		mov	ds, ax
		movdw	cxdx, ds:[MDBMD_medium].MMD_medium
		mov	al, ds:[MDBMD_medium].MMD_unitType
		mov	ss:[mapArgs].MBTDMMA_unitType, al
		movdw	ss:[mapArgs].MBTDMMA_medium, cxdx
		call	MemUnlock
	;
	; Ask the driver how much room we need to store an address for this
	; medium.
	;
		mov	ax, ss:[transOption] 
		mov	di, DR_MBTD_GET_MAX_ADDRESS_SIZE
		call	ss:[strat]
	;
	; Stuff that in the map args and allocate a by-transport block big
	; enough to hold that big an address at its end.
	; 
		mov	ss:[mapArgs].MBTDMMA_transAddrLen, ax
		add	ax, size MailboxDisplayByTransportData
		mov	bx, handle 0
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
		call	MemAlloc
		LONG jc	allocErr
	;
	; Point the map args to the address portion of the by-transport block.
	; 
		mov	ss:[mapArgs].MBTDMMA_transAddr.segment, ax
		mov	ss:[mapArgs].MBTDMMA_transAddr.offset,
				offset MDBTD_addr
	;
	; Set up what we can of the by-transport block from the map args,
	; so we don't have to rely on the driver leaving them alone...
	; 
		mov	ds, ax
		movdw	ds:[MDBTD_medium], ss:[mapArgs].MBTDMMA_medium, ax
	;
	; Also need the transport option in mapArgs.
	;
		mov	ax, ss:[transOption]
		mov	ss:[mapArgs].MBTDMMA_transOption, ax
	;
	; Now ask the driver if it can use the connection on this medium.
	; 
		mov	di, DR_MBTD_CHECK_MEDIUM_CONNECTION
		mov	cx, ss
		lea	dx, ss:[mapArgs]
		call	ss:[strat]
		jnc	noCanDo			; => no
	;
	; Store the actual size of the address in the by-transport block.
	; 
		mov	ds, ss:[mapArgs].MBTDMMA_transAddr.segment
		mov	ax, ss:[mapArgs].MBTDMMA_transAddrLen
		mov	ds:[MDBTD_addrSize], ax
	;
	; Store the MailboxTransport in the by-transport block, too, then
	; release the thing.
	; 
		movdw	ds:[MDBTD_transport], ss:[transport], ax
		mov	ax, ss:[transOption]
		mov	ds:[MDBTD_transOption], ax 
		call	MemUnlock
	;
	; Set up a copy of the by-medium block properly, now we know we'll
	; be using it.
	; 
		push	bx
		movdw	axbx, ss:[transport]
		mov	si, ss:[transOption]
		mov	cx, ss:[origByMedium]
		call	ONDupByMediumBlock
		pop	bx
	;
	; Tell the app object to put up an appropriate panel.
	; 
		push	bp
		mov	bp, dx			;^hbp = byMedium block
		mov	dx, bx			;^hdx = byTransport block
		call	MediaRecordConnectionAddress
		mov	cx, MDPT_BY_TRANSPORT
		mov	ax, MSG_MA_DISPLAY_OUTBOX_PANEL
		call	UtilSendToMailboxApp
		pop	bp
	;
	; Unload the transport driver, its work being now accomplished.
	; 
		mov	bx, ss:[transDriver]
		call	MailboxFreeDriver
	;
	; We stop enumerating once we find one connection, on the assumption
	; that a medium can only handle a connection to one address at a time.
	; 
		stc
done:
		.leave
		ret

noCanDo:
	;
	; Driver couldn't handle the connection, so free the by-transport block
	; and unload the driver.
	; 
		call	MemFree
allocErr:
	;
	; Couldn't allocate the by-transport block, so just unload the driver
	; and get out.
	; 
		mov	bx, ss:[transDriver]
		call	MailboxFreeDriver
		clc
		jmp	done
ONGenerateByTransportNotify endp

endif	; _CONNECTED_MEDIUM_NOTIFICATION


ife	_CONTROL_PANELS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxDisplayOutboxPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle notification of a panel needing to come up in the
		case where panels aren't supported

CALLED BY:	MSG_MA_DISPLAY_OUTBOX_PANEL
PASS:		*ds:si	= MailboxApplication object
		ds:di	= MailboxApplicationInstance
		cx	= MailboxDisplayPanelType
		^hdx	= MailboxDisplayPanelCriteria
		if MDPT_BY_TRANSPORT:
			^hbp	= MailboxDisplayPanelCriteria for
				  MDPT_BY_MEDIUM
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	memory block(s) freed

PSEUDO CODE/STRATEGY:
		If it's by-transport, we actually queue messages going to
			the equivalent address if they're just hanging out
			in the outbox.

		If it's by-medium, we queue messages using the same medium
			if they're just hanging out in the outbox.

		Exceptions: in the Retry state

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxDisplayOutboxPanel method extern dynamic MailboxApplicationClass, 
					MSG_MA_DISPLAY_OUTBOX_PANEL
byMedium	local	hptr.MailboxDisplayByMediumData		push	bp
byTrans		local	hptr.MailboxDisplayByTransportData	push	dx
talID		local	TalID
now		local	FileDateAndTime
byMediumSeg	local	sptr.MailboxDisplayByMediumData
		.enter
		cmp	cx, MDPT_BY_TRANSPORT
		je	doQueue
		
		mov	ss:[byMedium], dx
		clr	dx
		mov	ss:[byTrans], dx
doQueue:
	;
	; Lock down the by-medium block for our callback to use.
	;
		mov	bx, ss:[byMedium]
		call	MemLock
		mov	ss:[byMediumSeg], ax
	;
	; Lock down the by-transport for the callback and so we can point
	; to it when calling DBQMatch
	;
		tst	dx
			CheckHack <MDBMD_transport eq MDBTD_transport>
			CheckHack <MDBMD_transOption eq MDBTD_transOption>
		jz	getTransQueue

		mov	bx, dx
		call	MemLock
		mov	es, ax			; es <- *byTrans for callback
getTransQueue:
		mov_tr	dx, ax
			CheckHack <MDBTD_transport eq 0>
		clr	si			; dx:si <- bytes to match
			CheckNextField MDBTD_transOption, MDBTD_transport
			CheckNextField MMD_transOption, MMD_transport

		mov	cx, size MDBTD_transport + size MDBTD_transOption
		mov	ax, offset MMD_transport; ax <- offset of bytes to
						;  match in each message
		call	AdminGetOutbox
		call	DBQMatch		; ^vbx:ax <- queue for transport
	;
	; Allocate a TalID for marking suitable addresses with.
	;
		mov_tr	di, ax
		call	AdminAllocTALID
		mov	ss:[talID], ax
	;
	; Find the current time so we can easily see if a message is
	; transmittable
	;
		call	TimerGetFileDateTime	; get now for transmission 
		mov	ss:[now].FDAT_date, ax	;  window check in callback
		mov	ss:[now].FDAT_time, dx
	;
	; Now mark those addresses that match in messages that are within their
	; transmission window.
	;
		mov	cx, SEGMENT_CS
		mov	dx, offset ONDisplayOutboxPanelCallback
		call	DBQEnum
	;
	; Free the notification blocks, as we need them no longer.
	;
		mov	bx, ss:[byMedium]
		call	MemFree
		mov	bx, ss:[byTrans]
		tst	bx
		jz	transmit
		call	MemFree
transmit:
	;
	; Submit any marked messages for transmission. This is a NOP if there
	; are no suitable messages.
	;
		mov	cx, ss:[talID]
		call	OutboxTransmitMessageQueue
		jnc	done
		call	OutboxCleanupFailedTransmitQueue
done:
		.leave
		ret
OutboxDisplayOutboxPanel endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ONDisplayOutboxPanelCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for addresses equivalent to the passed one and mark
		them for transmission. We assume the passed one contains
		no insignificant bytes

CALLED BY:	(INTERNAL) OutboxDisplayOutboxPanel via DBQEnum
PASS:		sidi	= MailboxMessage to examine
		ss:bp	= inherited frame
		es	= segment of MailboxDisplayByTransportData containing
			  the address to check
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	address(es) may be marked with the talID

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ONDisplayOutboxPanelCallback proc	far
		uses	ds, bx
		.enter	inherit	OutboxDisplayOutboxPanel
		
		movdw	dxax, sidi
		call	MessageLock
	;
	; If not marked send-without-query, we do nothing.
	;
		mov	si, ds:[di]
ife	_OUTBOX_SEND_WITHOUT_QUERY
		test	ds:[si].MMD_flags, mask MMF_SEND_WITHOUT_QUERY
		jz	done
endif	; !_OUTBOX_SEND_WITHOUT_QUERY

	;
	; If we're not past the opening of its transmission window,
	; we do nothing.
	;
		mov	bx, ss:[now].FDAT_date
		cmp	ds:[si].MMD_transWinOpen.FDAT_date, bx
		ja	done
		mov	bx, ss:[now].FDAT_time
		cmp	ds:[si].MMD_transWinOpen.FDAT_time, bx
		ja	done

if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; If we're in retry state and we're not past the retry time, we only
	; do this if the medium is now connected to the same address and the
	; connection is reusable. Else we wait for the retry time
	;			       	-- ardeb 11/14/95
	;
		mov	bx, ss:[now].FDAT_date
		cmp	bx, ds:[si].MMD_autoRetryTime.FDAT_date
		ja	lookForAddresses
		mov	bx, ss:[now].FDAT_time
		cmp	bx, ds:[si].MMD_autoRetryTime.FDAT_time
		jae	lookForAddresses
	    ;
	    ; We're before the retry time. See if we're looking by-transport,
	    ; which means the thing's connected.
	    ;
		tst	ss:[byTrans]
		jz	done		; => not by-transport, so do nothing
	;
	; Now distinguish between Retry and Upon Request. Upon Request is
	; indicated by retry time being MAILBOX_ETERNITY. If Upon Request,
	; we never auto-queue the message.
	;
			CheckHack <MAILBOX_ETERNITY eq -1>
		mov	bx, ds:[si].MMD_autoRetryTime.FDAT_date
		and	bx, ds:[si].MMD_autoRetryTime.FDAT_time
		cmp	bx, -1
		je	done
		
	;
	; Ok. We're in Retry mode, but only want to queue if the transport can
	; actually reuse the same connection, else we'll wait for the retry.
	;
		push	cx, dx, ax
		movdw	cxdx, ds:[si].MMD_transport
		call	AdminGetTransportDriverMap
		call	DMapGetAttributes
		test	ax, mask MBTC_CAN_PREPARE_WHILE_CONNECTED
		pop	cx, dx, ax
		jz	done

lookForAddresses:
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

	;
	; Else look for appropriate addresses.
	;
		mov	bx, SEGMENT_CS
		mov	di, offset checkAddress
		call	MessageAddrEnum
		
done:
		call	UtilVMUnlockDS
		clc
		.leave
		ret

	;--------------------
	; Callback to check a single address for suitability.
	;
	; Pass:	ds:di	= MailboxInternalTransAddr
	; 	*ds:si	= address array
	; 	*ds:bx	= MailboxMessageDesc
	; 	ss:bp	= inherited frame
	; 	es	= MailboxDisplayByTransportData
	; Return: 	carry set to stop enumerating (always clear)
	; Destroyed:	ax, cx, dx, si
checkAddress:
	;
	; If the message is in the process of being transmitted,
	; or has already been sent to this address (i.e. the state
	; is anything but MAS_EXISTS), we do nothing with the address.
	;
CheckHack <offset MTF_STATE + width MTF_STATE eq width MailboxTransFlags>
		mov	dl, ds:[di].MITA_flags
		andnf	dl, mask MTF_STATE
		cmp	dl, MAS_EXISTS shl offset MTF_STATE
		jne	checkAddressDone
	;
	; Make sure it's for the same unit of media
	;
		mov	cx, ss:[byMediumSeg]
		clr	dx
		mov	ax, ds:[di].MITA_medium
		call	OMCompare
		jnc	checkAddressDone

	;
	; If by-medium, no address to compare, so queue it.
	;
		tst	ss:[byTrans]
		jz	equal
	;
	; Now compare the address bytes.
	;
		mov	cx, es:[MDBTD_addrSize]
		cmp	cx, ds:[di].MITA_opaqueLen
		jbe	doCompare
		mov	cx, ds:[di].MITA_opaqueLen
doCompare:
		jcxz	equal		; => all addresses are good
		push	di
		lea	si, ds:[di].MITA_opaque
		mov	di, offset MDBTD_addr
		repe	cmpsb
		pop	di
		jne	checkAddressDone
equal:
	;
	; Want to queue the thing -- mark it
	;
		mov	ax, ss:[talID]
EC <		tst	ds:[di].MITA_addrList				>
EC <		WARNING_NZ OVERWRITING_EXISTING_ADDRESS_MARK		>
		mov	ds:[di].MITA_addrList, ax
		call	UtilVMDirtyDS
checkAddressDone:
		clc
		retf
ONDisplayOutboxPanelCallback endp

endif	; !_CONTROL_PANELS

Outbox		ends

