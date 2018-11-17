COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		messageUtils.asm

AUTHOR:		Adam de Boor, Apr 19, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/19/94		Initial revision


DESCRIPTION:
	Utility routines, of course.
		

	$Id: messageUtils.asm,v 1.1 97/04/05 01:20:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MessageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageCleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called by DBQ module to clean up data related to a
		MailboxMessageDesc before the item containing the beast
		is freed.

CALLED BY:	(EXTERNAL) DBQ module
PASS:		bx	= VM file handle
		dxax	= DBGroupAndItem
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
mmdChunks	word	MMD_subject,
			MMD_bodyRef,
			MMD_transAddrs

MessageCleanup	proc	far
msg		local	dword	push	dx, ax
	ForceRef	msg
		uses	es, di, si, ds, ax, bx, cx, dx
		.enter
		call	MessageLock	; *ds:di <- MMD
	;
	; Call the transport driver to let it know the thing's going away,
	; if we got that far.
	; 
		call	MUCleanupNotifyTransport

		Assert	segment, ds		; make sure driver didn't
						;  make the thing move...
	;
	; Call the data driver to free the message body, if we got that far.
	; 
		call	MUCleanupDeleteBody
		
	;
	; If message was in the outbox, call OutboxUnregisterMedium for each
	; address.
	; 
		mov	si, ds:[di]
		CmpTok	ds:[si].MMD_transport, MANUFACTURER_ID_GEOWORKS, \
				GMTID_LOCAL
		je	freeChunks
		mov	si, ds:[si].MMD_transAddrs	;*ds:si = addr array
		call	OutboxCleanupAddresses
freeChunks:
	;
	; Now free all the chunks pointed to by the descriptor
	;
		mov	di, ds:[di]
		segmov	es, ds			; es:di <- MMD
		mov	si, size mmdChunks - size nptr
chunkLoop:
		mov	bx, cs:[mmdChunks][si]
		mov	ax, es:[di][bx]
		tst	ax
		jz	nextChunk
		call	LMemFree
nextChunk:
		dec	si
		dec	si
		jns	chunkLoop
	;
	; Set the transport to GMTID_LOCAL, so that we won't call
	; DR_MBTD_DELETE on the same message again in case the system crashes
	; before the message descriptor removal is flushed to disk (or
	; something like that.)
	;
			CheckHack <GMTID_LOCAL eq 0>
			CheckHack <MANUFACTURER_ID_GEOWORKS eq 0>
		clr	ax
		movdw	ds:[di].MMD_transport, axax

		call	DBDirty
		call	DBUnlock
		.leave
		ret
MessageCleanup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUCleanupNotifyTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the transport driver know the message is being nuked, if
		it has a chance of having heard of it.

CALLED BY:	(INTERNAL) MessageCleanup
PASS:		*ds:di	= MailboxMessageDesc
		ss:bp	= inherited stack frame
RETURN:		ds	= updated
DESTROYED:	ax, si, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUCleanupNotifyTransport proc near
		uses	bx, di
		.enter	inherit	MessageCleanup
		mov	bx, ds:[di]
	;
	; Do nothing if transport is GMTID_LOCAL.  This can happen if the
	; system crashed when the message was being deleted, and after reboot
	; we ended up trying to delete the same message again.
	;
		CmpTok	ds:[bx].MMD_transport, MANUFACTURER_ID_GEOWORKS, \
				GMTID_LOCAL
		je	done

		tst	ds:[bx].MMD_transAddrs
		jz	done			; => trans driver can't know
						;  about the message
	;
	; Attempt to load the transport driver.
	; 
		movdw	cxdx, ds:[bx].MMD_transport
		call	MailboxLoadTransportDriver
		jc	eeeeeek
	;
	; Find the driver strategy routine and invoke its DR_MBTD_DELETE
	; function.
	; 
		mov	di, ds:[di]
		movdw	cxdx, ds:[di].MMD_transData
		call	UtilVMUnlockDS		; unlock Message to allow
						;	transport VM access
		call	GeodeInfoDriver		; ds:si <- DIS
		mov	di, DR_MBTD_DELETE
		call	ds:[si].DIS_strategy
		MovMsg	dxax, ss:[msg]
		call	MessageLock		; re-lock Message
	;
	; Unload the driver, thanks.
	; 
		call	MailboxFreeDriver
done:
		.leave
		ret
eeeeeek:
	;
	; Must notify the transport driver later, the next time it gets loaded.
	; Register with the transport driver map to be called:
	; cxdx	= MailboxTransport
	;
	; need:
	; sidi	<- MailboxTransport
	; cxdx <- transData (passed to callback)
	; bx <- routine to call
	; ax <- transport map
	; 
		mov	bx, ds:[di]		; ds:bx <- MMD
		movdw	sidi, ds:[bx].MMD_transData
		xchg	si, cx
		xchg	di, dx
		mov	bx, enum MUCleanupDelayedTransportNotify
		call	AdminGetTransportDriverMap
		call	DMapRegisterLoadCallback
		jmp	done
MUCleanupNotifyTransport endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUCleanupDelayedTransportNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Now that the transport driver we needed before has been
		loaded, call it to delete the stuff it had with a message
		that's now gone.

CALLED BY:	(INTERNAL) MUCleanupNotifyTransport via
			   DMapRegisterLoadCallback
PASS:		bx	= transport driver handle
		cxdx	= transData
RETURN:		carry set if callback still needed
		carry clear if callback can be deleted
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUCleanupDelayedTransportNotify proc	far
		uses	ds, si, di
		.enter
		call	GeodeInfoDriver
		mov	di, DR_MBTD_DELETE
		call	ds:[si].DIS_strategy
		clc			; no error possible, so no further
					;  callback needed
		.leave
		ret
MUCleanupDelayedTransportNotify endp

	public	MUCleanupDelayedTransportNotify		; so it can be exported


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUCleanupDeleteBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load and call the data driver for the message to biff the
		message body if necessary.  (Body is only deleted if 
		MMF_DELETE_BODY_AFTER_TRANSMISSION or MMF_BODY_DATA_VOLATILE
		is set.)

CALLED BY:	(INTERNAL) MessageCleanup
PASS:		*ds:di	= MMD
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUCleanupDeleteBody proc	near
		uses	di
		.enter
		mov	bx, ds:[di]
		tst	ds:[bx].MMD_bodyRef
		jz	done			; => data driver can't know
						;  about the message
	;
	; Only delete if message is marked MMF_DELETE_BODY_AFTER_
	; TRANSMISSION or MMF_BODY_DATA_VOLATILE.
	;
		test 	ds:[bx].MMD_flags, \
				mask MMF_DELETE_BODY_AFTER_TRANSMISSION or \
				mask MMF_BODY_DATA_VOLATILE
		jz	done
	;
	; Load the driver, first-off.
	; 
		movdw	cxdx, ds:[bx].MMD_bodyStorage
		call	MailboxLoadDataDriverWithError
		jc	eeeeeek
	;
	; Point cx:dx to the mbox-ref, find the driver's strategy routine, and
	; call the thing.
	; 
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_bodyRef
		mov	cx, ds
		mov	dx, ds:[si]		; cx:dx <- body ref

		push	ds, di			; preserve DS only around this
						;  call, not entire function,
						;  as "eeeeeek" may cause
						;  block to move...
		call	GeodeInfoDriver		; ds:si <- DIS
		mov	di, DR_MBDD_DELETE_BODY
		call	ds:[si].DIS_strategy
		pop	ds, di			; *ds:di <- MMD
		jnc	freeDataDriver
		
		call	MUCleanupDelayBodyDelete

freeDataDriver:
		call	MailboxFreeDriver	; unload the driver, thanks
done:
		.leave
		ret

eeeeeek:
		call	MUCleanupDelayBodyDelete
		jmp	done

MUCleanupDeleteBody endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUCleanupDelayBodyDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Couldn't delete the message body, either because the driver
		couldn't be loaded or the data driver couldn't nuke it,
		for its own reasons. We cannot, however, just let the
		body dangle, so we set up to call the data driver, the next
		time it loads, to attempt to delete the body again.

CALLED BY:	(INTERNAL) MUCleanupDeleteBody
PASS:		*ds:di	= MailboxMessageDesc
RETURN:		ds	= fixed up, if mbox-ref stored in same item block
			  as MMD
DESTROYED:	ax, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUCleanupDelayBodyDelete proc	near
		uses	bx
		.enter
	;
	; First, allocate an item to hold the mbox-ref for the body.
	; 
		push	di			; save MMD chunk
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_bodyRef	; *ds:si <- mbox-ref
		ChunkSizeHandle	ds, si, cx	; cx <- # bytes needed
		call	MailboxGetAdminFile		; bx <- admin file
		mov	ax, DB_UNGROUPED
		call	DBAlloc			; axdi <- new item (ds fixed up
						;  if item in same item block)
	;
	; Now copy the mbox-ref from the message descriptor to the new item.
	; 
		pushdw	axdi
		call	DBLock			; *es:di <- new chunk
		mov	di, es:[di]		; es:di <- move dest
		mov	si, ds:[si]		; ds:si <- move source
		shr	cx
		rep	movsw
		jnc	refCopied
		movsb
refCopied:
	;
	; Mark the destination item block dirty and release it.
	; 
		call	DBDirty
		call	DBUnlock
	;
	; Now register the callback with the data driver map.
	;
	; cxdx <- DBGroupAndItem of mbox-ref (callback data)
	; bx <- entry-point # of callback routine
	; sidi <- token of data driver
	; 
		popdw	cxdx			; cxdx <- DBGI of new mbox-ref
		pop	di			; *ds:di <- MMD
		mov	di, ds:[di]
		mov	si, ds:[di].MMD_bodyStorage.high
		mov	di, ds:[di].MMD_bodyStorage.low	; sidi <- data driver
		mov	bx, enum MUCleanupDelayBodyDeleteCallback
		call	AdminGetDataDriverMap	; ax <- map handle
		call	DMapRegisterLoadCallback
		.leave
		ret
MUCleanupDelayBodyDelete endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUCleanupDelayBodyDeleteCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to perform the deletion of a message body that
		couldn't be accomplished before.

CALLED BY:	(INTERNAL) MUCleanupDelayBodyDelete via
			   DMapRegisterLoadCallback
PASS:		bx	= data driver handle
		cxdx	= DBGroupAndItem of mbox-ref for body
RETURN:		carry set if body couldn't be deleted (so callback should
			be reissued the next time the driver loads)
		carry clear if callback has served its purpose
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUCleanupDelayBodyDeleteCallback proc	far
		uses	ds, si, es, di, ax
		.enter
	;
	; Lock down the mbox-ref.
	;	
		mov_tr	ax, cx
		mov	di, dx
		pushdw	axdi
		push	bx
		call	MailboxGetAdminFile		
		call	DBLock			;*es:di = item
		pop	bx
	;
	; Call the data driver to ask it to try again.
	; 
		mov	cx, es
		mov	dx, es:[di]		; cx:dx <- mbox-ref
		mov	di, DR_MBDD_DELETE_BODY
		call	GeodeInfoDriver
		call	ds:[si].DIS_strategy
	;
	; Release the mbox-ref now, and recover its DBGroupAndItem, for
	; possible freeing.
	; 
		call	DBUnlock
		popdw	axdi
		jc	done			; => unsuccessful, so need to
						;  try again later
	;
	; Managed to delete the body, so delete the mbox-ref, too, and return
	; with carry clear to signal callback can be biffed.
	; 
		push	bx
		call	MailboxGetAdminFile		
		call	DBFree
		pop	bx
		clc
done:
		.leave
		ret
MUCleanupDelayBodyDeleteCallback endp

	public	MUCleanupDelayBodyDeleteCallback	; so it can be exported

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageCreateQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front-end for DBQCreate to create a DBQ in the admin file
		to hold messages.

CALLED BY:	(EXTERNAL) OutboxCreate, InboxCreate, OMLMlRescan, 
			OTCreateQueue.
PASS:		dx	= entry-point number of routine to call when a
			  new item is added to the queue (DBQ_NO_ADD_ROUTINE
			  if none)
RETURN:		carry set if couldn't allocate
		carry clear if queue created:
			ax	= queue handle
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/25/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageCreateQueue proc	far
		uses	bx, cx
		.enter
		call	MailboxGetAdminFile
		mov	cx, enum MessageCleanup
		mov	ax, size MailboxMessageDesc
		call	DBQCreate
		.leave
		ret
MessageCreateQueue endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageAddrEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the addresses for a message. Note that nothing
		particularly strenuous should be done this way (e.g. no
		calling the transport driver in the callback routine), as
		we're trying not to do a whole heck of a lot with a message
		locked, to avoid synchronization headaches.

CALLED BY:	(EXTERNAL) OMLSelect
PASS:		dxax	= message whose addresses are to be enumerated
		bx:di	= vfptr of callback routine:
			  Pass:
			  	ds:di	= MailboxInternalTransAddr
				*ds:si	= address array
			  	*ds:bx 	= MailboxMessageDesc
				cx, bp, es	= callback data
			  Return:
				carry set if enum should stop:
					bx, cx, bp, di, es = return values
				carry clear to keep going:
					cx, bp, es	= data for next callback
				callback should call UtilVMDirtyDS if it
					dirties the block, as OUAddrEnum will
					not do so on its behalf before unlocking
					the message
		cx, bp, es	= callback data
RETURN:		carry set if callback returned carry set:
			bx, cx, bp, di, es = as returned from callback
		carry clear if callback never returned carry set:
			bx, cx, bp, di, es = as returned from callback, or as
					 passed in if message had no addresses
					 (!?)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageAddrEnum	proc	far
cbBP		local	word		push	bp
callback	local	vfptr		push	bx, di
cbBX		local	word
cbDI		local	word
msgChunk	local	word
	ForceRef	cbBP
	ForceRef	callback
		uses	ds, si, ax
		.enter
		call	MessageLock		; *ds:di <- MMD
		mov	ss:[msgChunk], di
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		mov	bx, cs
		mov	di, offset MUAddrEnumCallback
EC <		test	ds:[LMBH_flags], mask LMF_IS_VM			>
EC <		WARNING_Z MAILBOX_MESSAGE_BLOCK_NOT_VM?			>
EC <		BitSet	ds:[LMBH_flags], LMF_IS_VM			>
		call	ChunkArrayEnum
		call	UtilVMUnlockDS
		mov	bx, ss:[cbBX]
		mov	di, ss:[cbDI]
		.leave
		ret
MessageAddrEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MUAddrEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the (potentially-movable) callback routine with
		this address.

CALLED BY:	(INTERNAL) MessageAddrEnum via ChunkArrayEnum
PASS:		ds:di	= MailboxInternalTransAddr
		*ds:si	= address array
		cx	= callback data
		ss:bp	= inherited frame
RETURN:		carry set to stop enumerating (carry returned from callback)
DESTROYED:	bx, ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MUAddrEnumCallback proc	far
		.enter	inherit	MessageAddrEnum
		mov	bx, ss:[msgChunk]	; *ds:bx <- MailboxMessageDesc
		push	bp
		pushdw	ss:[callback]		; put callback on the stack for
						;  PCFOM_P
		mov	bp, ss:[cbBP]		; bp <- callback data
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		mov_tr	ax, bp			; preserve returned callback
						;  data
		pop	bp
	;
	; Store possible return values for recovery by OUAddrEnum
	; 
		mov	ss:[cbBP], ax
		mov	ss:[cbBX], bx
		mov	ss:[cbDI], di
		.leave
		ret
MUAddrEnumCallback endp

MessageCode	ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the passed MailboxMessage

CALLED BY:	(EXTERNAL)
PASS:		dxax	= MailboxMessage
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			*ds:di	= MailboxMessageDesc (use UtilVMUnlockDS to
				  unlock)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		currently doesn't verify the descriptor, but it should and
		return the carry flag appropriately

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageLock	proc	far
		uses	es, ax, bx, cx
		.enter
		mov_tr	di, ax			; di <- item
		mov	ax, dx			; ax <- group
		call	MailboxGetAdminFile	; bx <- admin VM file handle
		call	DBInfo
		jc	done
		call	DBLock			; *es:di <- MMD
		segmov	ds, es
		clc
done:
		.leave
		jc	err
exit:
		ret
err:
		mov	ax, ME_INVALID_MESSAGE
		jmp	exit
MessageLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageLockCXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the passed MailboxMessage

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= MailboxMessage
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			*ds:di	= MailboxMessageDesc (use UtilVMUnlockDS to
				  unlock)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageLockCXDX	proc	far
		.enter
		xchg	ax, cx			; ax <- high, cx <- saved ax
		xchg	dx, ax			; ax <- low, dx <- high
		push	ax			; might get biffed by error
						;  code...
		call	MessageLock
		jc	err
		MovMsg	cxdx, dxax		; restore cxdx from dxax
		inc	sp			; and clear saved mm.low
		inc	sp
done:
		.leave
		ret
err:
		mov	cx, dx
		pop	dx			; cxdx <- MailboxMessage
		jmp	done
MessageLockCXDX	endp

Resident	ends

MessageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageCheckIfValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the passed MailboxMessage is valid.

CALLED BY:	(EXTERNAL)
PASS:		dxax	= MailboxMessage
RETURN:		carry set if message invalid (e.g. already deleted)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/25/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageCheckIfValid	proc	far
	uses	bx, cx
	.enter

	call	MailboxGetAdminFile	; ^hbx = admin file
	xchg	di, dx			; diax = msg, dx = old di
	xchg	ax, di			; axdi = msg
	call	DBInfo			; CF clear if valid, cx = size
	xchg	di, ax			; diax = msg
	xchg	dx, di			; dxax = msg, di restored

	.leave
	ret
MessageCheckIfValid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageCheckBodyIntegrity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the integrity of the message body.

CALLED BY:	(EXTERNAL) InboxFix, OutboxFix
PASS:		dxax	= MailboxMessage (assumed valid)
RETURN:		carry set if message body invalid
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageCheckBodyIntegrity	proc	far
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	call	MessageLock		; *ds:di = MailboxMessageDesc
	mov	di, ds:[di]
	;
	; Make sure the message has a body. If not, we say it has no
	; integrity...
	;
	tst	ds:[di].MMD_bodyRef
	stc
	jz	done

	;
	; Assume the body is intact if we can't load data driver.
	;
	movdw	cxdx, ds:[di].MMD_bodyStorage
	call	MessageLoadDataDriver	; bx = handle, dx:ax = strategy
	cmc
	jnc	done

	;
	; Call data driver to check body.
	;
	pushdw	dxax			; push strategy fptr
	mov	bp, sp			; ss:[bp] = strategy
	mov	cx, ds
	mov	di, ds:[di].MMD_bodyRef
	mov	dx, ds:[di]		; cx:dx = mbox-ref
	mov	di, DR_MBDD_CHECK_INTEGRITY
	call	{fptr} ss:[bp]		; CF clear if valid
	popdw	axax			; discard strategy

	lahf
	call	MailboxFreeDriver
	sahf

done:
	call	UtilVMUnlockDS		; unlock message (flags preserved)

	.leave
	ret
MessageCheckBodyIntegrity	endp

MessageCode	ends
