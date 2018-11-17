COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox
FILE:		outboxUtils.asm

AUTHOR:		Adam de Boor, May  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 3/94		Initial revision


DESCRIPTION:
	
		

	$Id: outboxUtils.asm,v 1.1 97/04/05 01:21:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Outbox		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OUCompareAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two MailboxInternalTransAddrs for equality

CALLED BY:	(EXTERNAL)
PASS:		ds:si	= address #1
		es:di	= address #2
		bp	= # significant bytes in an address for the medium /
			  transport pair
RETURN:		flags set for je/jne to branch as expected
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Two addresses are the same if their first <bp> bytes are
		the same, up to the length of the shortest address. In other
		words, if one address is 3 bytes, and bp is 6, the addresses
		are the same if the whole 3-byte address matches the first 3
		bytes of the other address. This allows a transport to
		have an optional portion (e.g. a user name for infrared) of
		the significant bytes and still properly compare equal when
		two addresses, one with the optional part and one without,
		that match in their fixed portion are compared.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OUCompareAddresses proc	far
		uses	cx, si, di
		.enter
EC <		mov	cx, ds:[si].MITA_medium				>
EC <		cmp	cx, es:[di].MITA_medium				>
EC <		ERROR_NE	ADDRESSES_USE_DIFFERENT_MEDIUM		>

	;
	; First find the shorter of the two addresses.
	; 
		mov	cx, ds:[si].MITA_opaqueLen
		cmp	cx, es:[di].MITA_opaqueLen
		jb	haveSize
		mov	cx, es:[di].MITA_opaqueLen
haveSize:
	;
	; If the shorter of the two is longer than the number of significant
	; bytes, then compare only the significant bytes, thanks.
	; 
		cmp	cx, bp
		jb	doCompare
		mov	cx, bp
doCompare:
		add	si, offset MITA_opaque
		add	di, offset MITA_opaque
		jcxz	noneSig
		repe	cmpsb
done:
		.leave
		ret
noneSig:
		tst	cx		; set ZF => addresses equal
		jmp	done
OUCompareAddresses endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OUFindNextAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next address with a given talID

CALLED BY:	(EXTERNAL) OSCSetMessage, OTQGetTransport, OTrConnect,
			OTrSendMessage
PASS:		dxax	= message
		cx	= talID
		si	= address index from which to search (inclusive)
RETURN:		carry set if no next marked address
			ds, ax, si, di	= destroyed
		carry clear if found one:
			*ds:di	= message
			ds:si	= MailboxInternalTransAddr
			ax	= index of found address
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OUFindNextAddr	proc	far
		uses	bx, dx
		.enter
	;
	; Lock down the message, s'il vous plais
	; 
		call	MessageLock	; *ds:di <- message
		push	di
	;
	; Arrange the registers for the enum.
	; 
		mov	dx, cx		; dx <- talID
		mov	ax, si		; ax <- starting elt
		mov	cx, -1		; cx <- enum all elements
		mov	di, ds:[di]
		mov	si, ds:[di].MMD_transAddrs
		test	dx, mask TID_ADDR_INDEX
		jnz	checkSent

		mov	bx, cs
		mov	di, offset OUFindNextAddrCallback
		call	ChunkArrayEnumRange	; ax <- index of found,
						; ds:cx <- found addr
		cmc				; return carry clear if found.
	;
	; Set up for return.
	; 
popDone:
		pop	di
		xchg	cx, dx		; cx <- talID, ds:dx <- found addr
		jc	unlockDone	; => not found, so release message block

		mov	si, dx		; ds:si <- found addr
done:
		.leave
		ret

checkSent:
	;
	; TalID is an address #. Make sure the address hasn't been sent to,
	; returning no-such-address if it has.
	;
		mov	ax, dx
		andnf	ax, mask TID_NUMBER
		call	ChunkArrayElementToPtr
		mov	cx, di			; ds:cx <- address (for return)
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jnz	popDone
		stc
		jmp	popDone

unlockDone:
		call	UtilVMUnlockDS
		jmp	done
OUFindNextAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OUFindNextAddrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to find the next element with a particular talID

CALLED BY:	(INTERNAL) OUFindNextAddr via ChunkArrayEnumRange
PASS:		ds:di	= MailboxInternalTransAddr
		*ds:si	= address array
		dx	= talID sought
RETURN:		carry set to stop enumerating (found one with talID):
			ax	= index of found element
			ds:cx	= found address
		carry clear if not found
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OUFindNextAddrCallback proc	far
		.enter
		cmp	ds:[di].MITA_addrList, dx
		clc
		jne	done

		call	ChunkArrayPtrToElement
		mov	cx, di
		stc
done:
		.leave
		ret
OUFindNextAddrCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OUUnmarkAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unmakrs all the addresses in this message that are marked
		with this TalID.

CALLED BY:	(INTERNAL) OSCMsndSendMessageLater, OCDismiss
PASS:		dxax	= MailboxMessage
		cx	= TalID to unmark
RETURN:		nothing
DESTROYED:	bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Why don't we simply use a callback to unmark those address whose
	MITA_addrList equal this TalID?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OUUnmarkAddresses	proc	far
	uses	ax,dx,si,ds
	.enter

	;
	; Find the medium for this TalID.
	;
	clr	si			; start from first address
	call	OUFindNextAddr		; ax = address index, *ds:di = MMD,
					;  ds:si = MailboxInternalTransAddr
EC <	ERROR_C		NO_MESSAGE_ADDRESS_MARKED_WITH_GIVEN_ID		>
	mov	dx, ds:[si].MITA_medium

	;
	; Unmark add addresses using this medium.
	;
	clr	cx			; unmark TalID
	mov	si, ds:[di]		; ds:si = MailboxMessageDesc
	mov	si, ds:[si].MMD_transAddrs	; *ds:si = MITA array
		.assert segment ORMessageAddedMarkCallback eq segment @CurSeg
	mov	bx, cs
	mov	di, offset ORMessageAddedMarkCallback
	call	ChunkArrayEnum
	call	UtilVMUnlockDS

	.leave
	ret
OUUnmarkAddresses	endp

Outbox	ends

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OUChangeAddressMarkCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the address has the indicated talID, change it to the
		other one.

CALLED BY:	(EXTERNAL) OTQAddOneMessage via ChunkArrayEnum,
			   OTrPrepareBatch via ChunkArrayEnum
PASS:		ds:di	= MailboxInternalTransAddr
		cx	= talID for which to look
		dx	= new talID to set, if match
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0		; no longer used
OUChangeAddressMarkCallback proc	far
		.enter
		cmp	ds:[di].MITA_addrList, cx
		jne	done
		mov	ds:[di].MITA_addrList, dx
done:
		clc
		.leave
		ret
OUChangeAddressMarkCallback endp
endif	; 0

Resident	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OUDeleteMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a message from the outbox and take down the interaction
		that was displaying it.

CALLED BY:	(INTERNAL) ODDeleteMessage, OSCMsndDeleteMessage
PASS:		dxax	= MailboxMessage
		bx	= talID with TID_ADDR_INDEX set, or 0 if deleting
			  all addresses of the same medium.
		cx	= address index
		*ds:si	= GenInteraction object (to pass to
			  UtilInteractionComplete)
RETURN:		ds fixed up
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/17/95    	Initial version (from ODDeleteMessage)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OUDeleteMessage	proc	far
curMsg		local	dword		; for OUDeleteMessageCallback
		.enter
	;
	; Run through all the addresses, marking them as sent.
	; 
		movdw	ss:[curMsg], dxax
		mov	di, offset OUDeleteMessageCallback
		call	OUAddrEnum
	;
	; Remove the message from the outbox, thereby deleting it if no
	; further references are outstanding.
	; 
		push	ds:[LMBH_handle]
		call	OUDeleteMessageIfNothingUnsent
		pop	bx
		call	MemDerefDS

		call	UtilInteractionComplete
		.leave
		ret
OUDeleteMessage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OUAddrEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the addresses currently being displayed

CALLED BY:	(INTERNAL)
PASS:		dxax	= message
		bx	= ODI_curID (i.e. either 0 to show all addresses, or
			  a specific address #, with TID_ADDR_INDEX set)
		cx	= selected address
		bp	= value for callback routine
		cs:di	= callback routine
RETURN:		nothing
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OUAddrEnum	proc	near
		uses	ds, si, dx, ax, bx, cx
		.enter
	;
	; Point to the selected address so we can get its medium or whatever.
	; 
		push	di
		call	MessageLock
		mov	dx, di			; *ds:dx <- msg
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		mov_tr	ax, cx
		call	ChunkArrayElementToPtr
		pop	cx			; cs:cx <- callback
		tst	bx
		jz	allForMedium		; => display all

EC <		test	bx, mask TID_ADDR_INDEX				>
EC <		ERROR_Z	CUR_ID_DOESNT_MATCH_SELECTED_ADDRESS		>
EC <		andnf	bx, mask TID_NUMBER				>
EC <		cmp	bx, ax						>
EC <		ERROR_NE CUR_ID_DOESNT_MATCH_SELECTED_ADDRESS		>

		mov	bx, dx		; pass *ds:bx = message
dupLoop::

		call	cx
if 	_DUPS_ALWAYS_TOGETHER
	;
	; Point to the next duplicate, if there is one.
	; 
		mov	ax, ds:[di].MITA_next
			CheckHack <MITA_NIL eq -1>
		inc	ax
		jz	done
		dec	ax
		push	cx
		call	ChunkArrayElementToPtr
		pop	cx
EC <		ERROR_C	INVALID_DUPLICATE_ADDR_LIST			>
EC <			CheckHack <MAS_SENT eq 0>			>
EC <		test	ds:[di].MITA_flags, mask MTF_STATE		>
EC <		ERROR_Z	DUP_ADDRESS_SENT_BEFORE_ORIGINAL		>
		jmp	dupLoop
endif	; _DUPS_ALWAYS_TOGETHER

done:
		call	UtilVMUnlockDS
		.leave
		ret

allForMedium:
	;
	; Call back for all the addresses that are for the same medium.
	;
	; NOTE: We do not worry about whether an address is already being
	; sent to, as that would seem to complicate things needlessly.
	; We'll worry about it if the user actually tells us to send something.
	; 
		push	cx			; pass the callback address
		push	bp			;  and the callback's bp
		mov	bp, sp			;  to our callback
		mov	cx, ds:[di].MITA_medium
		mov	bx, cs
		mov	di, offset allForMediumCallback
		clr	ax
		call	ChunkArrayEnum
		pop	bp
		pop	cx
		jmp	done

	;--------------------
	; Callback to call the callback for an address if it's still unsent and
	; it's for the same medium as that selected by the user.
	; Pass:	ds:di	= MailboxInternalTransAddr
	;	cx	= medium token
	;	ax	= address #
	;	*ds:dx	= message
	;	ss:bp	->	callback's bp
	;			callback
	; Return:	carry set to stop enumerating (always clear)
	; 
allForMediumCallback:
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	callbackDone
		cmp	ds:[di].MITA_medium, cx
		jne	callbackDone
		
		mov	bx, dx
		push	cx
		push	bp
		mov	cx, ss:[bp+2]		; cx <- callback routine
		mov	bp, ss:[bp]		; bp <- callback's bp
		call	cx
		mov_tr	cx, bp			; remember the bp that came
						;  back, just in case
		pop	bp
		mov	ss:[bp], cx
		pop	cx
callbackDone:
		inc	ax
		clc
		retf
OUAddrEnum	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OUDeleteMessageCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark an address as sent to, thus effectively dequeueing it,
		if it's queued for transmission, removing it from any
		control panels, etc.

CALLED BY:	(INTERNAL) OUDeleteMessage via ODAddrEnum
PASS:		ds:di	= MailboxInternalTransAddr
		*ds:bx	= MailboxMessageDesc
		ax	= address #
		ss:bp	= frame inherited from OUDeleteMessage
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	block is dirtied.
     		MA_OUTBOX_CHANGED is queued

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OUDeleteMessageCallback proc	near
		uses	si, ax, cx, dx, di
		.enter	inherit	OUDeleteMessage
		Assert	stackFrame, bp
	;
	; First mark the thing as sent
	; 
			CheckHack <MAS_SENT eq 0>
		BitClr	ds:[di].MITA_flags, MTF_STATE	; MTF_STATE = MAS_SENT
		mov	ds:[di].MITA_addrList, 0
	;
	; Let everyone else know what's up.
	; 
		push	bp
		movdw	cxdx, ss:[curMsg]
			CheckHack <offset MABC_ADDRESS eq 0>
		Assert	bitClear, ax, <not mask MABC_ADDRESS>
		ornf	ax, (MACT_REMOVED shl offset MABC_TYPE) or \
				mask MABC_OUTBOX
		mov_tr	bp, ax
		mov	ax, MSG_MA_BOX_CHANGED
		clr	di
		call	UtilForceQueueMailboxApp
		pop	bp

		call	UtilVMDirtyDS
		.leave
		ret
OUDeleteMessageCallback endp

OutboxUICode	ends

Transmit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OUDeleteMessageIfNothingUnsent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the passed message from the outbox if it has no more
		unsent addresses.

CALLED BY:	(EXTERNAL) OTrSendmessage, OUDeleteMessage
PASS:		dxax	= message to check
RETURN:		carry set if message removed
DESTROYED:	nothing
SIDE EFFECTS:	Message may be removed from the outbox, causing notification
     			to be generated via the MailboxApplication object

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OUDeleteMessageIfNothingUnsent proc	far
msg		local	MailboxMessage		push dx, ax
		uses	bx, di, bp
		.enter
	;
	; See if there are any addresses for the message that remain unsent.
	; If not, we wish to remove the message from the outbox (finally)
	; 
		mov	bx, SEGMENT_CS
		mov	di, offset OUFindUnsentAddrCallback
		call	MessageAddrEnum
		jc	done			; => at least one address still
						;  unsent, so leave the message
						;  in the outbox
	;
	; Fetch the outbox and remove the message. The message will continue
	; to linger until it's removed from the batch and thread queues.
	; 
		call	AdminGetOutbox
		call	DBQRemove		;destroys dx, ax
		movdw	dxax, msg
		jc	done			; => not on outbox.  Someone
						; else already removed the msg.

	;
	; Remove the extra reference placed on the message when it was
	; allocated. As others rebuild their queues, or what have you, the
	; reference count will drop to 0 and the message will be freed.
	; 
		call	DBQFree			;destroys dx, ax
	;
	; Flush the changes to disk.
	;
		call	UtilUpdateAdminFile
	;
	; Tell application about it.
	; 
		movdw	cxdx, msg
		push	bp
		mov	bp, (MACT_REMOVED shl offset MABC_TYPE) or \
				mask MABC_OUTBOX or \
				(MABC_ALL shl offset MABC_ADDRESS)
		mov	ax, MSG_MA_BOX_CHANGED
		call	UtilSendToMailboxApp
		pop	bp
		MovMsg	dxax, cxdx
		clc
done:
		cmc				; want carry *set* if removed
		.leave
		ret
OUDeleteMessageIfNothingUnsent		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OUFindUnsentAddrCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to check the passed address to see if it
		remains unsent. If so, stop enumerating the addresses.

CALLED BY:	(INTERNAL) OUDeleteMessageIfNothingUnsent via MessageAddrEnum
PASS:		ds:di	= MailboxInternalTransAddr
RETURN:		carry set if address still unsent
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OUFindUnsentAddrCallback proc	far
		.enter
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	done		; (carry cleared by "test")
		stc
done:
		.leave
		ret
OUFindUnsentAddrCallback endp

Transmit	ends

