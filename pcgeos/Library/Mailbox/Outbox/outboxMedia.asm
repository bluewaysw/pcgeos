COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxMedia.asm

AUTHOR:		Adam de Boor, Apr 27, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT OMLock			Lock down the outbox media map & fetch the
				two element arrays involved.

    EXT OMGetMedium		Retrieve the MediumType for the unit
				token passed

    EXT OMRegister		Record the medium & unit number for a
				message, along with the transport used for
				the message.

    EXT OMUnregister		Discard the medium & unit number for a
				message, along with the transport/medium
				pairing.

    INT OMFindMTPairCallback	Callback routine to locate an OutboxMTPair
				element

    EXT OMCompare		See if the medium for a message address
				matches the passed medium.

    EXT OMCheckMediumAvailable	See if the medium required by a message is
				currently available

    INT OMPrepareForMediaCall	Set up registers to call the Media module
				with a transport & media token

    EXT OMGetSigAddrBytes	Get the number of bytes that are
				significant in the opaque data for an
				address destined for the indicated medium /
				transport pair.

    EXT OutboxMediaGetTransportString 
				Get the string for a transport/medium pair.

    EXT OutboxMediaGetTransportVerb 
				Get the verb for a transport/medium pair.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/27/94		Initial revision


DESCRIPTION:
	Functions for maintaining the arrays that track the transport/medium
	combos in the current outbox, and the medium used for each address
	in each message.
		

	$Id: outboxMedia.asm,v 1.1 97/04/05 01:21:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Outbox		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the outbox media map & fetch the two
		element arrays involved.

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		*ds:di	= medium/transport array
		*ds:si	= medium/unit array
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMLockFar	proc	far
		call	OMLock
		ret
OMLockFar	endp

OMLock		proc	near
		uses	bx, ax, bp
		.enter
	;
	; Get the vptr of the media map & error-check the heck out of it.
	; 
		call	AdminGetOutboxMedia

EC <		call	ECVMCheckVMFile					>
EC <		push	ax, cx						>
EC <		call	VMInfo						>
EC <		ERROR_C	OUTBOX_MEDIA_MAP_INVALID			>
EC <		cmp	di, MBVMID_OUTBOX_MEDIA				>
EC <		ERROR_NE OUTBOX_MEDIA_MAP_INVALID			>
EC <		pop	ax, cx						>
	;
	; Lock down the block & error-check the heck out of it.
	; 
		call	VMLock
		mov	ds, ax

EC <		mov	bx, bp						>
EC <		call	ECCheckLMemHandle				>
EC <		call	ECLMemValidateHeap				>
	;
	; Load SI and DI with the requisite values (& error-check the...)
	; 
		mov	di, ds:[LMBH_offset]		; di <- medium/transport
		lea	si, ds:[di+2]			; si <- medium/unit

EC <		call	ECLMemValidateHandle				>
EC <		xchg	si, di						>
EC <		call	ECLMemValidateHandle				>
EC <		xchg	si, di						>

		.leave
		ret
OMLock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMGetMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the MediumType for the unit token passed

CALLED BY:	(EXTERNAL) OTrSetupProgressBox
PASS:		ax	= token for medium unit
RETURN:		cxdx	= MediumType
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if MAILBOX_PERSISTENT_PROGRESS_BOXES
_NEED_OMGETMEDIUM	equ TRUE
else
_NEED_OMGETMEDIUM	equ FALSE
endif

if _NEED_OMGETMEDIUM
OMGetMedium	proc	far
		uses	ds, si, di
		.enter
		call	OMLock
		call	ChunkArrayElementToPtr
EC <		ERROR_C	INVALID_OUTBOX_MEDIUM_TOKEN			>
   		movdw	cxdx, ds:[di].OMU_data.MMD_medium
		call	UtilVMUnlockDS
		.leave
		ret
OMGetMedium	endp
endif	; _NEED_OMGETMEDIUM

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMGetMediumDesc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the MailboxMediumDesc for the unit token passed

CALLED BY:	(EXTERNAL) OutboxGetDefaultSystemCriteria
PASS:		ax	= token for medium unit
		es:di	= MailboxMediumDesc to setup
		cx	= number of bytes at es:di
RETURN:		carry set if buffer too small:
			cx	= number of bytes needed
		carry clear if medium descriptor fetched
			cx	= unchanged
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMGetMediumDesc proc	far
		uses	ds, si, di, ax
		.enter
	;
	; Point to the array entry.
	; 
		push	di, cx
		call	OMLock
		call	ChunkArrayElementToPtr	; ds:di <- entry
						; cx <- size of entry
EC <		ERROR_C	INVALID_OUTBOX_MEDIUM_TOKEN			>
  		lea	si, ds:[di].OMU_data	; ds:si <- medium desc
		pop	di, ax
		sub	cx, offset OMU_data	; cx <- # bytes needed for
						;  medium desc
		cmp	ax, cx			; is passed buffer big enough?
		jb	done			; => no, cx is # bytes needed

		rep	movsb			; => yes, so copy
		mov_tr	cx, ax			; return CX unchanged
done:
		call	UtilVMUnlockDS
		.leave
		ret
OMGetMediumDesc	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMCreateElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a block to hold an OutboxMediumUnit from the passed
		data, for use in find or registering a medium unit

CALLED BY:	(INTERNAL) OMRegister
PASS:		cxdx	= MediumType
		bx	= unit number
		al	= MediumUnitType
RETURN:		bx	= handle of block
		es	= OutboxMediumUnit filled in
DESTROYED:	ax, cx, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMCreateElement	proc	near
		uses	si
		.enter
		push	ax			; save real unit type for unlock

		push	bx			; push unit num, in case int
		mov	di, cx			; di <- MediumType.high
		clr	cx			; assume no unit
		cmp	al, MUT_NONE
		je	haveUnit
		cmp	al, MUT_ANY
		je	haveUnit
		
		cmp	al, MUT_INT
		je	intUnit
		cmp	al, MUT_REASON_ENCLOSED
		je	withReason

EC <		cmp	al, MUT_MEM_BLOCK				>
EC <		ERROR_NE UNKNOWN_MEDIUM_UNIT_TYPE			>
	;
	; unit in mem block: find its size and lock the thing down.
	; 
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		mov_tr	cx, ax			; cx <- unit size
		call	MemLock
		mov	ds, ax
		clr	si			; ds:si <- unit data
		mov	al, MUT_MEM_BLOCK	; restore unit type
		jmp	haveUnit

withReason:
		call	MemLock
		mov	ds, ax
		mov	si, offset MUAR_unit
		mov	cx, ds:[MUAR_size]
		mov	al, ds:[MUAR_type]
		jmp	haveUnit

intUnit:
	;
	; Unit is integer. Point ds:si to the MBTDMMA_unit field and set the
	; size appropriately.
	; 
		segmov	ds, ss
		mov	si, sp
		mov	cx, size word

haveUnit:
	;
	; Now need to allocate a block of memory to hold the element we'll be
	; adding. It serves a dual purpose as well, eventually holding the
	; OutboxMTPair element we'll be adding, as well.
	; 
	; cx = # bytes in the unit
	; ds:si = location of unit
	; 
		push	ax			; save unit type
		push	cx			; save unit data size for copy
		add	cx, size OutboxMediumUnit
		mov_tr	ax, cx			; ax <- # bytes to alloc

		cmp	ax, size OutboxMTPair	; we'll be changing this into
		jae	doAlloc			;  an OutboxMTPair, later, so
		mov	ax, size OutboxMTPair	;  make sure there's enough
						;  room
doAlloc:
		mov	cx, ALLOC_FIXED or (mask HAF_NO_ERR shl 8)
						; might as well be fixed, since
						;  it will never be unlocked...
		call	MemAlloc		; bx <- handle, ax <- seg
	;
	; Copy the unit data to the appropriate place in the block.
	; 
		mov	es, ax
		mov_tr	ax, di			; axdx <- medium
		mov	di, offset OMU_data.MMD_unit
		pop	cx			; cx <- unit size
		mov	es:[OMU_data].MMD_unitSize, cx
		rep	movsb
	;
	; Shift the MediumType into the element, as well as the unit type.
	; 
		movdw	es:[OMU_data].MMD_medium, axdx
		pop	ax
		mov	es:[OMU_data].MMD_unitType, al
	;
	; Unlock the passed unit block, if any.
	;
		pop	cx
		pop	ax

		cmp	al, MUT_MEM_BLOCK
		je	unlock
		cmp	al, MUT_REASON_ENCLOSED
		jne	done
unlock:
		xchg	bx, cx			; bx <- unit block, cx <- OMU
		call	MemUnlock
		mov	bx, cx			; bx <- OMU block
done:
		.leave
		ret
OMCreateElement	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the medium & unit number for a message, along with
		the transport used for the message.

CALLED BY:	(EXTERNAL) ORGetAndStoreMedium
PASS:		cx:dx	= MBTDMediumMapArgs
		sidi	= MailboxTransport
		bx	= MailboxTransportOption
RETURN:		ax	= token for medium unit
		unit block freed if MUT_MEM_BLOCK
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMRegister 	proc	far
transport	local	MailboxTransport	push si, di
transOption	local	MailboxTransportOption	push bx
		uses	bx, ds, es, si, di, bp
		.enter
	;
	; Create the element for the medium array from the passed media
	; info.
	;
		movdw	esdi, cxdx		; es:si <- MBTDMediumMapArgs

		movdw	cxdx, es:[di].MBTDMMA_medium
		mov	bx, es:[di].MBTDMMA_unit
		mov	al, es:[di].MBTDMMA_unitType
		push	ax, bx
		call	OMCreateElement		; es <- OutboxMediumUnit
		pop	ax, cx
		
		push	bx			; save handle for later free
	;
	; Free the unit number block, if such there be, before we continue
	;
		cmp	al, MUT_MEM_BLOCK
		jne	addElements
		mov	bx, cx			; bx <- unit # block
		call	MemFree

addElements:
	;
	; FINALLY: Lock down the outbox-media map block.
	; 
		call	OMLock			; *ds:si <- medium/unit array
	;
	; Add the medium/unit element to that array.
	; 
		mov	cx, es
		clr	dx			; cx:dx <- element
		mov	ax, es:[OMU_data].MMD_unitSize	; ax <- element size
		add	ax, size OutboxMediumUnit
		clr	bx			; bx <- no comparison callback
		call	ElementArrayAddElement
		push	ax			; save element # for medium/unit
	;
	; Change the element to be an OutboxMTPair, using the transport we
	; were passed.
	; 
		mov	si, di			; *ds:si <- medium/transport
						;   array
		CheckHack <offset OMTP_medium eq offset OMU_data.MMD_medium>
		movdw	es:[OMTP_transport], ss:[transport], ax
		mov	ax, ss:[transOption]
		mov	es:[OMTP_transOption], ax
	;
	; Add the element to the medium/transport array. cx:dx and bx still
	; valid (no comparison callback)
	; 
		mov	ax, size OutboxMTPair
		call	ElementArrayAddElement
	;
	; Make sure we have the info we need for this combo
	; 
		pushf
		movdw	axbx, es:[OMTP_transport]
		movdw	cxdx, es:[OMTP_medium]
		mov	si, es:[OMTP_transOption]
		call	MediaEnsureTransportInfo
		popf
	;
	; If we added something to the OMTP array, update any transport
	; lists in existence.
	; 
		jnc	done			; => element wasn't new
		call	OMSendRebuild
done:
	;
	; Dirty and release the outbox media map
	; 
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS

		pop	ax			; ax <- medium token #
		pop	bx			; bx <- element block
		call	MemFree			;  which we no longer need
		.leave
		ret
OMRegister 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMFind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the token for the given medium unit

CALLED BY:	(EXTERNAL) OutboxNotifyMediumNotAvailable
PASS:		cxdx	= MediumType
		bx	= unit number
		al	= MediumUnitType
RETURN:		carry set if found:
			ax	= token
		carry clear if not found:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM or _HONK_IF_MEDIUM_REMOVED
OMFind		proc	far
		uses	bx, cx, dx, si, di, ds, es
		.enter
	;
	; Copy unit data into a block and lock down the array.
	;
		call	OMCreateElement		; ^hbx, es <- OutboxMediumUnit
		call	OMLock			; *ds:si <- medium/unit array
	;
	; See if there's a matching element.
	;
		push	bx
		mov	bx, cs
		mov	di, offset OMFindCallback
		call	ChunkArrayEnum
		pop	bx
	;
	; Free the unit descriptor and unlock the array before returning
	; our result.
	;
		pushf
		call	MemFree
		call	UtilVMUnlockDS
		popf
		.leave
		ret
OMFind		endp
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM or _HONK_IF_MEDIUM_REMOVED

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMFindCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to see if this element is the one
		being sought.

CALLED BY:	(INTERNAL) OMFind via ChunkArrayEnum
PASS:		*ds:si	= element array
		ds:di	= OutboxMediumUnit to check
		es	= segment of OutboxMediumUnit being sought
RETURN:		carry set if found:
			ax	= element # of this element
		carry clear if not found:
			ax	= destroyed
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_TRANSMIT_THREADS_KEYED_BY_MEDIUM or _HONK_IF_MEDIUM_REMOVED
OMFindCallback	proc	far
		.enter
		cmp	ds:[di].OMTP_meta.REH_refCount.WAAH_high,
				EA_FREE_ELEMENT
		je	done			; carry clear, not found

		push	si, di
		mov	si, di			; ds:si <- array element
		mov	di, offset OMU_data	; es:di <- MMD to check
		call	OMCompareInternal
		pop	si, di
		jnc	done

		call	ChunkArrayPtrToElement	; ax <- element #
		stc
done:
		.leave
		ret
OMFindCallback	endp
endif	; _TRANSMIT_THREADS_KEYED_BY_MEDIUM or _HONK_IF_MEDIUM_REMOVED

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discard the medium & unit number for a message, along with
		the transport/medium pairing.

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= MailboxTransport
		bx	= MailboxTransportOption
		ax	= token for the medium unit returned by
			  OMRegister
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	outbox control panel may be notified of change in transport
     		list

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMUnregister 	proc	far
transport	local	MailboxTransport	push cx, dx
transOption	local	MailboxTransportOption	push bx
	ForceRef	transport	; OMFindMTPairCallback
	ForceRef	transOption	; OMFindMTPairCallback
		uses	ds, si, di, bx, cx, dx
		.enter
	;
	; Lock down the map block, please.
	; 
		call	OMLock
	;
	; Get the medium using the medium token # (EC the token # at the same
	; time)
	; 
		push	di
		call	ChunkArrayElementToPtr
EC <		ERROR_C	INVALID_OUTBOX_MEDIUM_TOKEN			>
EC <		cmp	ds:[di].OMU_meta.REH_refCount.WAAH_high, \
   				EA_FREE_ELEMENT				>
EC <		ERROR_E	INVALID_OUTBOX_MEDIUM_TOKEN			>
		movdw	cxdx, ds:[di].OMU_data.MMD_medium
	;
	; Now remove a reference from that element. We don't care if this
	; gets rid of the element, as nothing depends on it -- the array
	; exists solely so we can quickly figure out what medium an address
	; uses.
	; 
		clr	bx		; no cleanup routine
		call	ElementArrayRemoveReference
	;
	; Now figure out what element the medium/transport pair is.
	; 
		pop	si		; *ds:si <- OMTP array
	
		mov	bx, cs
		mov	di, offset OMFindMTPairCallback
		clr	ax		; for finding element #
		call	ChunkArrayEnum
EC <		ERROR_NC MEDIUM_AND_TRANSPORT_NOT_IN_OMTP_ARRAY		>
	;
	; That determined, remove a reference from it. If this causes the
	; element to go away, we have to update the list in the outbox
	; control panel.
	; 
		clr	bx
		call	ElementArrayRemoveReference
		jnc	done
		call	OMSendRebuild
done:
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		call	UtilUpdateAdminFile
		.leave
		ret
OMUnregister 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMSendRebuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a MSG_OTL_REBUILD_LIST to the system outbox panel's
		transport list, as we've added or removed a pair from 
		the element array, requiring a change in the list.

CALLED BY:	(INTERNAL) OMRegister, OMUnregister
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMSendRebuild	proc	near
if	_CONTROL_PANELS
		uses	ax, bx, cx, dx, si, di, bp
		.enter
		mov	ax, MSG_OTL_REBUILD_LIST
		mov	bx, segment OutboxTransportListClass
		mov	si, offset OutboxTransportListClass
		mov	di, mask MF_RECORD
		call	ObjMessage		; di <- event

	;
	; NOTE: this update must be queued to make sure we don't rebuild
	; message lists while they're in the middle of a ChunkArrayEnum (as
	; can happen during MLUpdateListRemovedCallback if the list was the
	; thing with the last reference to the message).
	; 
		mov	cx, di
		mov	dx, TO_OUTBOX_TRANSPORT_LIST
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		clr	di
		call	UtilForceQueueMailboxApp
		.leave
endif	; _CONTROL_PANELS
		ret
OMSendRebuild	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMFindMTPairCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to locate an OutboxMTPair element

CALLED BY:	(INTERNAL) OMUnregister
PASS:		ds:di	= OutboxMTPair to check
		cxdx	= MediumType
		ax	= element #
		ss:bp	= inherited frame
RETURN:		carry set if found:
			ax	= element #
		carry clear if not found:
			ax	= next element #
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMFindMTPairCallback proc	far
		.enter	inherit	OMUnregister
		cmp	ds:[di].OMTP_meta.REH_refCount.WAAH_high,
				EA_FREE_ELEMENT
		je	notFound		; carry clear, not found

	;
	; First check the medium.
	; 
		cmpdw	ds:[di].OMTP_medium, cxdx
		jne	notFound
	;
	; Now check the transport
	; 
		cmpdw	ss:[transport], ds:[di].OMTP_transport, bx
		jne	notFound

		mov	bx, ss:[transOption]
		cmp	bx, ds:[di].OMTP_transOption
		jne	notFound
	
		stc		; found it -- leave AX alone
done:
		.leave
		ret
notFound:
		inc	ax
		clc
		jmp	done
OMFindMTPairCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the medium for a message address matches the passed
		medium.

CALLED BY:	(EXTERNAL) OMLCheckMediumCompatible
PASS:		ax	= medium token (from OMRegister)
		cx:dx	= MailboxDisplayByMediumData. 
RETURN:		carry set if they are equal
		carry clear if they are not equal
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMCompare 	proc	far
		uses	ds, si, es, di, cx, ax
		.enter
	;
	; Lock down the media map, first.
	; 
		call	OMLock
	;
	; Point to the OutboxMediumUnit structure for the token.
	; 
		mov	es, cx			; (cx about to be biffed)
		call	ChunkArrayElementToPtr
	;
	; Compare the MediumType values against each other.
	; 
		mov	si, di			; ds:si <- OMU
		mov	di, dx			; es:di <- MDBMD
		add	di, offset MDBMD_medium ; es:di <- MailboxMediumDesc
		call	OMCompareInternal
		call	UtilVMUnlockDS
		.leave
		ret
OMCompare 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMCompareInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare an entry in the OutboxMedia array to a given
		medium descriptor to see if it matches

CALLED BY:	(INTERNAL) OMCompare, OMFindCallback
PASS:		ds:si	= OutboxMediumUnit to check
		es:di	= MailboxMediumDesc against which to compare
RETURN:		carry set if it matches
		carry clear if it doesn't
DESTROYED:	ax, cx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMCompareInternal proc	near
		.enter
		cmpdw	ds:[si].OMU_data.MMD_medium, es:[di].MMD_medium, ax
		jne	notIt
	;
	; Well, it's the right medium. See if it's the right unit. If the
	; transport driver said any unit would do for the message, then it's
	; a match.
	; 
		cmp	ds:[si].OMU_data.MMD_unitType, MUT_ANY
		je	it
	;
	; And if we're looking for a token that can be any unit of the medium,
	; we're also happy.
	;
		cmp	es:[di].MMD_unitType, MUT_ANY
		je	it
	;
	; EC: the specific unit type and size must be consistent for all units
	; of the medium.
	; 
EC <		mov	al, es:[di].MMD_unitType			>
EC <		cmp	al, ds:[si].OMU_data.MMD_unitType		>
EC <		ERROR_NE INCONSISTENT_UNIT_TYPES_FOR_MEDIUM		>
EC <		mov	ax, es:[di].MMD_unitSize			>
EC <		cmp	ax, ds:[si].OMU_data.MMD_unitSize		>
EC <		ERROR_NE INCONSISTENT_UNIT_SIZES_FOR_MEDIUM		>
	;
	; Compare the unit data itself.
	; 
		mov	cx, ds:[si].OMU_data.MMD_unitSize
		jcxz	it
		add	si, offset OMU_data.MMD_unit
		add	di, offset MMD_unit
		repe	cmpsb
		jne	notIt
it:
		stc
done:
		.leave
		ret
notIt:
		clc
		jmp	done
OMCompareInternal endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMCheckMediumAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the medium required by a message is currently available

CALLED BY:	(EXTERNAL) OutboxMessageAddedCallback
PASS:		ax	= medium token, returned by OMRegister
RETURN:		carry set if it is
		carry clear if it ain't
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMCheckMediumAvailable proc	far
		uses	ds, si, es, di, cx
		.enter
		call	OMLock
		call	ChunkArrayElementToPtr
		segmov	es, ds
		add	di, offset OMU_data
		call	MediaCheckMediumAvailableByPtr
		call	UtilVMUnlockDS
		.leave
		ret
OMCheckMediumAvailable endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMCheckConnectable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the system can readily connect to the indicated
		address over the given medium using the given transport.

CALLED BY:	(EXTERNAL) OutboxDoEventEachAddr
PASS:		ax	= medium token
		cxdx	= MailboxTransport
		es:di	= destination address, with size word at start
			  (size doesn't include size word)
		si	= MailboxTransportOption
RETURN:		carry set if connectable
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The answer is yes if the medium is not connected but available,
		or is connected to the same place.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/18/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMCheckConnectable proc	far
		uses	ds, cx, dx, bx, ax
		.enter
		push	si, di
		call	OMLock
		push	cx
		call	ChunkArrayElementToPtr
		pop	ax
		mov	bx, dx			; axbx <- MailboxTransport
		mov	cx, ds			; cx:dx <- MailboxMediumDesc
		lea	dx, ds:[di].OMU_data
		pop	si, di			; si <- trans opt
						; es:di <- dest addr
		call	MediaCheckConnectable
		call	UtilVMUnlockDS
		.leave
		ret
OMCheckConnectable endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMPrepareForMediaCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up registers to call the Media module with a transport
		& media token.
		
		THIS IS A CO-ROUTINE THAT CALLS ITS CALLER BACK. BE CAREFUL.
		CALLER MAY NOT HAVE ANYTHING ON THE STACK AT THE TIME OF THE
		CALL.

CALLED BY:	(INTERNAL) OMGetSigAddrBytes, OutboxMediaGetTransportString
PASS:		cxdx	= MailboxTransport
		bx	= MailboxTransportOption
		ax	= medium token
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Caller is called back immediately after its call to us with
		the following protocol:
			Pass:	axbx	= MailboxTransport
				cxdx	= MediumType
				si	= MailboxTransportOption
				ds, di	= as passed
			Return:	ds, ax	= possible return values
				carry set if media + transport + option
					is invalid
			May destroy: bx, cx, dx, si
		When the caller returns to us, we clean up and return to our
		caller's caller.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMPrepareForMediaCall proc	near
		push	bp
		mov	bp, sp
		uses	bx, cx, dx, si
		.enter
		push	ds, di
	;
	; Lock down the array of medium / unit data.
	; 
		call	OMLock		; *ds:si <- media array
	;
	; Point to the specific medium / unit for the message.
	; 
		push	cx
		call	ChunkArrayElementToPtr
		pop	ax
		mov	si, bx		; si <- MailboxTransportOption
		mov	bx, dx		; axbx <- transport
	;
	; Fetch the medium token out & release the map
	; 
		movdw	cxdx, ds:[di].OMU_data.MMD_medium
		call	UtilVMUnlockDS
		pop	ds, di
	;
	; Call the caller back.
	; 
		push	cs
		call	{nptr.far}ss:[bp+2]
EC <		ERROR_C	HOW_CAN_MEDIA_TRANSPORT_BE_INVALID?		>
	;
	; Clean up and return to the caller's caller.
	;
		.leave
		pop	bp
		inc	sp
		inc	sp
		retf
OMPrepareForMediaCall endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMGetSigAddrBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of bytes that are significant in the opaque
		data for an address destined for the indicated medium /
		transport pair.

CALLED BY:	(EXTERNAL) 
PASS:		ax	= medium token, returned by OMRegister
		cxdx	= MailboxTransport
		bx	= MailboxTransportOption
RETURN:		ax	= # of significant bytes
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMGetSigAddrBytes proc	far
		.enter
		call	OMPrepareForMediaCall
	;
	; Call the Media module to get the number of address bytes
	; 
		call	MediaGetTransportSigAddrBytes
		.leave
		ret
OMGetSigAddrBytes endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxMediaGetTransportString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the string for a transport/medium pair.

CALLED BY:	(EXTERNAL) 
PASS:		ds	= locked lmem block in which to place the string
		ax	= medium token, returned by OMRegister
		cxdx	= MailboxTransport
		bx	= MailboxTransportOption
RETURN:		*ds:ax	= the string
DESTROYED:	nothing
SIDE EFFECTS:	block and/or chunks may move around

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxMediaGetTransportString proc	far
		.enter
		call	OMPrepareForMediaCall
	;
	; Call the Media module to get the string
	; 
		call	MediaGetTransportString
		.leave
		ret
OutboxMediaGetTransportString endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxMediaGetTransportVerb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the verb for a transport/medium pair.

CALLED BY:	(EXTERNAL) OSCSetMessage, ODMdGetDeliveryVerb
PASS:		ds	= locked lmem block in which to place the string
		ax	= medium token, returned by OMRegister
		cxdx	= MailboxTransport
		bx	= MailboxTransportOption
RETURN:		*ds:ax	= the string
DESTROYED:	nothing
SIDE EFFECTS:	block and/or chunks may move around

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxMediaGetTransportVerb proc	far
		.enter
		call	OMPrepareForMediaCall
	;
	; Call the Media module to get the verb
	; 
		call	MediaGetTransportVerb
		.leave
		ret
OutboxMediaGetTransportVerb endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMGetAllMediaTransportPairs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an array of the currently-valid MailboxMediaTransport
		pairs.

CALLED BY:	(EXTERNAL) OTLRebuildList
PASS:		ds	= destination lock
RETURN:		*ds:ax	= chunkarray of MailboxMediaTransport structures
DESTROYED:	es if pointing to ds on entry
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Another possibility is to copy the element array in
		wholesale and trim it all back.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMGetAllMediaTransportPairs proc far
		uses	es, bx, di, si, cx, dx
		.enter
	;
	; Create a new array to hold MailboxMediaTransport result structures.
	; 
		mov	bx, size MailboxMediaTransport
		clr	ax, cx, si
		call	ChunkArrayCreate

		mov	cx, si
		segmov	es, ds		; *es:cx <- result array, for callback
	;
	; Lock down the media/transport array and iterate over it.
	; 
		call	OMLock
		mov	si, di
		mov	bx, cs
		mov	di, offset OMGetAllMediaTransportPairsCallback
		call	ChunkArrayEnum
		call	UtilVMUnlockDS
	;
	; Return le results.
	; 
		segmov	ds, es
		mov_tr	ax, cx		; *ds:ax <- result array
		.leave
		ret
OMGetAllMediaTransportPairs endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMGetAllMediaTransportPairsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to change a potentially-sparse element
		array of OutboxMTPair structures into a new compact array
		of MailboxMediaTransport structures, for return by
		OMGetAllMediaTransportPairs

CALLED BY:	(INTERNAL) OMGetAllMediaTransportPairs via ChunkArrayEnum
PASS:		ds:di	= OutboxMTPair structure, possibly free
		*es:cx	= result array
RETURN:		carry set to stop enumerating (always clear)
		es	= fixed up
DESTROYED:	ax, bx, si, di, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMGetAllMediaTransportPairsCallback proc	far
		.enter
		cmp	ds:[di].OMTP_meta.REH_refCount.WAAH_high,
				EA_FREE_ELEMENT
		je	done
		
	;
	; Fetch the medium & transport out of the array.
	; 
		push	ds, cx, bp
		mov	si, cx			;*es:si = result array
		movdw	axbx, ds:[di].OMTP_transport
		movdw	cxdx, ds:[di].OMTP_medium
		mov	bp, ds:[di].OMTP_transOption
	;
	; Append an entry to the result array.
	; 
		segmov	ds, es
		call	ChunkArrayAppend
	;
	; Initialize it.
	; 
		movdw	ds:[di].MMT_medium, cxdx
		movdw	ds:[di].MMT_transport, axbx
		mov	ds:[di].MMT_transOption, bp
	;
	; Return ES fixed up, please
	; 
		segmov	es, ds
		pop	ds, cx, bp
done:
		clc			; => keep enumerating
		.leave
		ret
OMGetAllMediaTransportPairsCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxMediaGetTransportAbbrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the abbreviation for a transport/medium pair.

CALLED BY:	(EXTERNAL)
PASS:		ds	= locked lmem block in which to place the string
		ax	= medium token, returned by OMRegister
		cxdx	= MailboxTransport
		bx	= MailboxTransportOption
RETURN:		*ds:ax	= the string
DESTROYED:	nothing
SIDE EFFECTS:	block and/or chunks may move around

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Outbox	ends

MessageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxCleanupAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister the medium & medium+transport stuff for each
		address of the message.

CALLED BY:	(EXTERNAL) MessageCleanup
PASS:		*ds:si	= trans addr array (si may be 0, e.g. if failed to
			  store body during registration)
		*ds:di	= MailboxMessageDesc
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	transport lists may update, as elements may be removed from 
			the media+transport array maintained by this module.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxCleanupAddresses proc	far
		uses	bx, cx, di, ax, bp
		.enter
		tst	si
		jz	done
		mov	di, ds:[di]
		movdw	cxdx, ds:[di].MMD_transport
		mov	bp, ds:[di].MMD_transOption	;pass to callback.
		mov	bx, cs
		mov	di, offset nukeMedium
		call	ChunkArrayEnum
done:
		.leave
		ret

nukeMedium:
	; cxdx = MailboxTransport
	; bp = MailboxTransportOption
		mov	ax, ds:[di].MITA_medium
		mov	bx, bp				;bx = transport option
		call	OMUnregister
		clc
		retf
OutboxCleanupAddresses endp

MessageCode	ends

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxMediaInitRefCounts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the reference counts of all media tokens to 1.

CALLED BY:	(EXTERNAL) AdminFixFile
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxMediaInitRefCounts	proc	near
	uses	bx, si, di, ds
	.enter

	;
	; Enum the OutboxMedia array setting the reference count for
	; non-free elements to 1
	;
	call	OMLockFar		; *ds:si = media array
	mov	bx, cs
	mov	di, offset OMInitRefCountsCallback
	call	ChunkArrayEnum
	call	UtilVMUnlockDS

	.leave
	ret
OutboxMediaInitRefCounts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMInitRefCountsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to set the reference count of a medium token to 1

CALLED BY:	(INTERNAL) OutboxMediaInitRefCounts via ChunkArrayEnum
PASS:		ds:di	= OutboxMediumUnit
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMInitRefCountsCallback	proc	far

	cmp	ds:[di].OMU_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	done			
	mov	ds:[di].OMU_meta.REH_refCount.WAAH_low, 1
	andnf	ds:[di].OMU_meta.REH_refCount.WAAH_high, 0	; clears carry
	call	UtilVMDirtyDS

done:
	ret
OMInitRefCountsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxMediaAddRefForMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a reference to the medium token for each address of the
		message.

CALLED BY:	(EXTERNAL) AdminFixRefCountsCallback
PASS:		dxax	= MailboxMessage
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxMediaAddRefForMsg	proc	near
	uses	bx, di
	.enter

	mov	bx, SEGMENT_CS
	mov	di, offset OMAddRefForMsgCallback
	call	MessageAddrEnum

	.leave
	ret
OutboxMediaAddRefForMsg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMAddRefForMsgCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to add a reference to the medium token for
		one address.

CALLED BY:	(INTERNAL) OutboxMediaAddRefForMsg vis MessageAddrEnum
PASS:		ds:di	= MailboxInternalTransAddr
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMAddRefForMsgCallback	proc	far
	uses	ax, si, di, ds
	.enter

	mov	ax, ds:[di].MITA_medium
	call	OMLockFar		; *ds:si = OutboxMedia array
	call	ElementArrayAddReference	; array marked dirty
	call	UtilVMUnlockDS
	clc

	.leave
	ret
OMAddRefForMsgCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxMediaDecRefCounts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a reference from all non-free media tokens.

CALLED BY:	(EXTERNAL) AdminFixFile
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxMediaDecRefCounts	proc	near
	uses	ax, bx, si, di, ds
	.enter

	call	OMLockFar		; *ds:si = OutboxMedia array
	mov	bx, cs
	mov	di, offset OMDecRefCountsCallback
	call	ChunkArrayEnum
	call	UtilVMUnlockDS

	.leave
	ret
OutboxMediaDecRefCounts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OMDecRefCountsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to remove a reference from a non-free medium.

CALLED BY:	(INTERNAL) OutboxMediaDecRefCounts via ChunkArrayEnum
PASS:		*ds:si	= OutboxMedia array
		ds:di	= OutboxMediumUnit
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, bx (bx, si, di allowed by ChunkArrayEnum)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OMDecRefCountsCallback	proc	far

	cmp	ds:[di].OMU_meta.REH_refCount.WAAH_high, EA_FREE_ELEMENT
	je	done
	call	ChunkArrayPtrToElement	; ax = elt #
	clr	bx			; no callback
	call	ElementArrayRemoveReference	; array marked dirty

done:
	clc

	ret
OMDecRefCountsCallback	endp

Init	ends
