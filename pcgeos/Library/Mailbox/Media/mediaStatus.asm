COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mediaStatus.asm

AUTHOR:		Adam de Boor, Apr 12, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB MediaNotifyMediumAvailable 
				Take note that a particular unit of a
				transmission medium is available for use.

    GLB MediaNotifyMediumNotAvailable 
				Take note that a particular unit of a
				transmission medium is NOT available for
				use.

    GLB MediaNotifyMediumConnected 
				Take note that a particular unit of a
				transmission medium is now connected, so
				someone could conceivably piggyback message
				transmission on top of it.

    GLB MediaNotifyMediumNotConnected 
				Take note that a particular unit of a
				transmission medium is still available, but
				no longer connected.

    INT MSRecord		Record a change in the status of a
				transport medium unit.

    INT MSFindMediumUnit	Lock down the status map and locate a
				record for the passed medium & unit

    INT MSFindUnitInternal	Routine to perform the actual enumeration
				of the status map, because I prefer to
				inherit a frame set up from a separate
				routine than define a structure for the
				various things needed by the ChunkArrayEnum
				callback routine...

    INT MSFindUnitCallback	Callback function to find a particular unit
				of a particular transport medium.

    INT MSCheckMediumCommon	Common routine to see if a particular unit
				of a particular medium exists and is in a
				particular state.

    GLB MailboxCheckMediumAvailable 
				See if the indicated unit of a transmission
				medium exists, so far as the Mailbox
				library is concerned.

    GLB MailboxCheckMediumConnected 
				See if the indicated unit of a transmission
				medium is connected, so far as the Mailbox
				library is concerned.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/12/94		Initial revision


DESCRIPTION:
	Functions for maintaining the transport-media status map.
		

	$Id: mediaStatus.asm,v 1.1 97/04/05 01:20:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the media status map dirty

PASS:		ds	= Media Status map

PSEUDO CODE/STRATEGY:
		If it's in the admin file, call UtilVMDirtyDS
		Else do nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/23/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSDirty	macro
ife	_HAS_SWAP_SPACE
	call	UtilVMDirtyDS
endif
	endm

Media	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaNotifyMediumAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that a particular unit of a transmission medium
		is available for use.

CALLED BY:	(EXTERNAL) MainMailboxSubsystemNotify
PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE)
		al	= MediumUnitType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	user may be asked about sending messages via the medium

PSEUDO CODE/STRATEGY:
	- record medium & unit
	- get transports for medium
	- foreach transport:
		- get outbox messages for the transport that are in-bounds and
		  aren't currently being sent
		- if any message is no_query, begin transmission
		- else ask user, passing the queue of messages to the MMLC
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaNotifyMediumAvailable proc	far
		.enter
		call	MSRecord
		jnc	done
		call	UtilUpdateAdminFile
	;
	; Tell the outbox to do something.
	; 
		call	OutboxNotifyMediumAvailable
		call	MSRecalcEventTimer
done:
		.leave
		ret
MediaNotifyMediumAvailable endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaNotifyMediumNotAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that a particular unit of a transmission medium
		is NOT available for use.

CALLED BY:	(EXTERNAL) MainMailboxSubsystemNotify
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
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaNotifyMediumNotAvailable proc	far
		.enter
		call	MSRecord
		jnc	done
		call	UtilUpdateAdminFile
		call	MSRecalcEventTimer
if	_HONK_IF_MEDIUM_REMOVED
		call	OutboxNotifyMediumNotAvailable
endif	; _HONK_IF_MEDIUM_REMOVED
done:
		.leave
		ret
MediaNotifyMediumNotAvailable endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaNotifyMediumConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that a particular unit of a transmission medium
		is now connected, so someone could conceivably piggyback
		message transmission on top of it.

CALLED BY:	(EXTERNAL) MainMailboxSubsystemNotify
PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE)
		al	= MediumUnitType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	user may be prompted

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaNotifyMediumConnected proc	far
		.enter
		call	MSRecord
		jnc	done
	;
	; Tell the outbox to do something
	; 
		call	OutboxNotifyMediumConnected
		call	MSRecalcEventTimer
done:
		.leave
		ret
MediaNotifyMediumConnected endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaNotifyMediumNotConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that a particular unit of a transmission medium
		is still available, but no longer connected.

CALLED BY:	(EXTERNAL) MainMailboxSubsystemNotify
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
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaNotifyMediumNotConnected proc	far
		.enter
		call	MSRecord
		jnc	done
		call	OutboxNotifyMediumNotConnected
		call	MSRecalcEventTimer
done:
		.leave
		ret
MediaNotifyMediumNotConnected endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSRecalcEventTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the mailbox application object to reexamine its take on
		when the next event should happen.

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSRecalcEventTimer proc	near
		uses	ax
		.enter
		mov	ax, MSG_MA_RECALC_NEXT_EVENT_TIMER
		call	UtilSendToMailboxApp
		.leave
		ret
MSRecalcEventTimer endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record a change in the status of a transport medium unit.

CALLED BY:	(INTERNAL) MediaNotifyMediumNotConnected,
			   MediaNotifyMediumConnected,
			   MediaNotifyMediumNotAvailable,
			   MediaNotifyMediumAvailable
PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE)
		al	= MediumUnitType
		di	= MediumSubsystemNotification
RETURN:		carry set if actually a change
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Find or create the unit

		If clearing available:
			clear connected & connect count
			clear available
		elif clearing connected:
			if not available, ignore notification
			decrement connect count
			if 0, clear connected
		elif setting connected:
			if not available, ignore notification
			if connect count is 0, set connected
			increment connect count
		elif setting available:
			set available

		if reason given:
			record it
		elif change in CONNECTED/AVAILABLE, free old reason

	There are timing problems that we have to handle.  Available /
	not-available notifications and connected / not-connected
	notifications may not be always nested correctly.  E.g. the
	user can power off or on (or both) the medium unit at any moment even
	when there is already a connection or there, or when a connection has
	just been made and the transmission thread is about to send a
	connected notification.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSRecord proc	near
unitNum		local	word	push bx
unitType	local	word	push ax
notifType	local	MediumSubsystemNotification push di
	ForceRef unitNum		; MSFindMediumUnit
	ForceRef unitType		; MSFindMediumUnit
		uses	ds, si, es, di, ax, bx
		.enter
EC <		cmp	al, MUT_ANY					>
EC <		ERROR_E	MUT_ANY_NOT_ALLOWED_WHEN_NOTIFYING_ABOUT_MEDIA_STATUS>

EC <		cmp	di, length statusChangers			>
EC <		ERROR_AE MEDIA_STATUS_RECORD_ONLY_FOR_AVAILABLE_AND_CONNECTED_BITS>

		call	MSFindMediumUnit	; bl <- real unit type
		jc	changeStatus

	;
	; Didn't find the thing, so append it to the status map.
	; es:di	= unit data
	; ax	= size of same
	; bl	= unit type
	; 
		pushdw	esdi		; save unit data addr
		
		add	ax, offset MSE_unitData	; ax <- # bytes needed for elt
		call	ChunkArrayAppend	; ds:di <- element
	;
	; Initialize the new element.
	; 
		movdw	ds:[di].MSE_medium, cxdx
		segmov	es, ds
		popdw	dssi		; ds:si <- unit data
		push	di, cx
		add	di, offset MSE_unitData	; es:di <- storage for unit data
		sub	ax, offset MSE_unitData	; ax <- # bytes of unit data
		mov_tr	cx, ax
		rep	movsb
		pop	di, cx
		segmov	ds, es			; ds:di <- element, again

		mov	ds:[di].MSE_flags, 0	; init the flags
		mov	ds:[di].MSE_unitType, bl; set the unit type, for EC
	;
	; Call our MailboxMediaTransport sister code to cope with a type of
	; media being seen in the system for the very first time: need to find
	; the transport drivers that are able to handle the medium.
	; 
		call	MediaTransportNewMedium

changeStatus:
	;
	; Change the CONNECTED/AVAILABLE status bits in the element to match
	; those we've been given. 
	; 
		mov	al, ds:[di].MSE_flags	; al <- current flags
		mov	si, ss:[notifType]
		shl	si
		call	cs:[statusChangers][si]

	;
	; Now store the new status we've built up and note what important bits
	; changed, if any.
	;
	; ds:di	= MediaStatusEntry
	; al	= new MediaStatusFlags for the entry
	; 
		xchg	al, ds:[di].MSE_flags
		xor	al, ds:[di].MSE_flags

	;
	; See if we need to bring in a reason chunk or free an existing one.
	;
		cmp	ss:[unitType].low, MUT_REASON_ENCLOSED
		jne	maybeFreeReason		; => no reason, so might
						;  need to free old one
	;
	; We have a possibly new reason. We record it even if there was no
	; change of status.
	;
		jmp	storeReason
done:
	;
	; Dirty and release the array block.
	;
		MSDirty
		call	MSUnlock
	;
	; See if anything actually changed and set carry accordingly.
	; 
		test	al, mask MSF_AVAILABLE or mask MSF_CONNECTED
		jz	exit
		stc
exit:
		.leave
		ret

	;----------
maybeFreeReason:
	;
	; Make sure something changed. If it didn't, leave the reason alone.
	; Ensures that if more than one CONNECTED notification and one provides
	; a reason, that reason remains bound to the medium until the thing
	; is disconnected.
	;
		test	al, mask MSF_AVAILABLE or mask MSF_CONNECTED
		jz	done
	;
	; If the entry used to have a reason for the medium not existing,
	; free it now.
	;
		tst	ds:[di].MSE_reason
		jz	done
		push	ax
		clr	ax
		xchg	ax, ds:[di].MSE_reason
		call	LMemFree
		pop	ax
		jmp	done

	;----------
storeReason:
	;
	; The caller passed in a reason for the medium's change -- store it
	; in a chunk and point the entry to it.
	;
	; ss:[unitNum] is the handle of a locked block holding a
	; MediumUnitAndReason from which the reason can be extracted.
	;
		push	ax			; save status changes
		mov	ax, ds:[di].MSE_reason
		tst	ax
		jz	oldReasonFreed
		call	LMemFree
oldReasonFreed:
		mov	bx, ss:[unitNum]
		call	MemDerefES		; es <- MediumUnitAndReason
		mov	si, ds:[LMBH_offset]	; *ds:si <- array, again
		sub	di, ds:[si]		; di <- offset into array
						;  so we can get back to it
						;  after allocation
	;
	; Compute the size of the string.
	;
		push	di
		mov	di, offset MUAR_unit
		add	di, es:[MUAR_size]
		call	LocalStringSize
		LocalNextChar escx
	;
	; Allocate that much.
	;
		call	LMemAlloc
		mov	bx, di
	;
	; Point back to the array entry.
	;
		pop	di
		add	di, ds:[si]
	;
	; Store the new reason chunk away.
	;
		mov	ds:[di].MSE_reason, ax
		mov_tr	di, ax
		mov	di, ds:[di]
		segxchg	ds, es			; es:di <- dest for copy
		mov	si, bx			; ds:si <- src for copy
		rep	movsb
	;
	; Recover MS segment and finish up
	;
		segmov	ds, es
		pop	ax			; ax <- status changes
		jmp	done

	
statusChangers	nptr.near	makeAvailable,
				makeNotAvailable,
				makeConnected,
				makeNotConnected

	;--------------------
	;
	; Make the medium available by setting MSF_AVAILABLE. Nothing else
	; needs doing.
	;
	; Pass:
	; 	al	= current MediaStatusFlags
	; 	ds:di	= MediaStatusElement
	; Return:
	; 	al	= new MediaStatusFlags
	; 
makeAvailable:
		ornf	al, mask MSF_AVAILABLE
		retn

	;--------------------
	;
	; Make sure the medium is marked as connected and record another
	; notification in MSF_CONNECT_COUNT
	;
	; Pass:
	; 	al	= current MediaStatusFlags
	; 	ds:di	= MediaStatusElement
	; Return:
	; 	al	= new MediaStatusFlags
	; 
makeConnected:
		test	al, mask MSF_AVAILABLE
EC <		WARNING_Z MESN_MEDIUM_CONNECTED_RECEIVED_WHEN_MEDIUM_NOT_AVAILABLE>
		jz	changeDone

		ornf	al, mask MSF_CONNECTED
EC <		push	ax						>
EC <		andnf	al, mask MSF_CONNECT_COUNT			>
EC <		cmp	al, -1 and mask MSF_CONNECT_COUNT		>
EC <		ERROR_E	CONNECT_COUNT_OVERFLOW				>
EC <		pop	ax						>
			CheckHack <offset MSF_CONNECT_COUNT eq 0>
		inc	ax
changeDone:
		retn

	;--------------------
	;
	; Reduce the MSF_CONNECT_COUNT and mark the medium as not connected if
	; the count has dropped to 0. Go free recorded addresses if so.
	;
	; Pass:
	; 	al	= current MediaStatusFlags
	; 	ds:di	= MediaStatusElement
	; Return:
	; 	al	= new MediaStatusFlags
	; 
makeNotConnected:
		test	al, mask MSF_CONNECT_COUNT
EC <		WARNING_Z MESN_MEDIUM_NOT_CONNECTED_RECEIVED_WHEN_MEDIUM_NOT_YET_CONNECTED_OR_AVAILABLE>
		jz	changeDone

			CheckHack <offset MSF_CONNECT_COUNT eq 0>
		dec	ax

		test	al, mask MSF_CONNECT_COUNT
		jnz	changeDone
		andnf	al, not mask MSF_CONNECTED
		jmp	maybeFreeConnectAddrs

	;--------------------
	;
	; Mark the medium as being neither available nor connected. Free any
	; recorded addresses.
	;
	; Pass:
	; 	al	= current MediaStatusFlags
	; 	ds:di	= MediaStatusElement
	; Return:
	; 	al	= new MediaStatusFlags
	; 
makeNotAvailable:
			CheckHack <(mask MediaStatusFlags and \
					not (mask MSF_CONNECTED or \
					     mask MSF_AVAILABLE or \
					     mask MSF_CONNECT_COUNT)) eq 0>
		clr	al		; clear all flags & connect count

	;
	; Loop through the list of recorded addresses, freeing each chunk in
	; turn.
	;
maybeFreeConnectAddrs:
		push	ax, di
		clr	ax
		xchg	ds:[di].MSE_addrs, ax
freeAddrsLoop:
		tst	ax
		jz	addrsFreed
		mov	di, ax
		mov	di, ds:[di]
		push	ds:[di].MCD_next
		call	LMemFree
		pop	ax
		jmp	freeAddrsLoop
addrsFreed:
		pop	ax, di
		retn

MSRecord 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the media status map

CALLED BY:	(INTERNAL) MSFindMediumUnit, MediaCheckMediumAvailableByptr
PASS:		nothing
RETURN:		*ds:si	= media status array
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLock		proc	near
		uses	bx, ax, di
		.enter
		call	AdminGetMediaStatusMap

ife	_HAS_SWAP_SPACE
EC <		call	ECVMCheckVMFile					>
EC <		push	ax, cx						>
EC <		call	VMInfo						>
EC <		ERROR_C	MEDIA_STATUS_MAP_INVALID			>
EC <		cmp	di, MBVMID_MEDIA_STATUS				>
EC <		ERROR_NE MEDIA_STATUS_MAP_INVALID			>
EC <		pop	ax, cx						>

		push	bp
		call	VMLock
		mov	ds, ax

EC <		mov	bx, bp						>
else
		mov_tr	bx, ax			; bx <- mem block
endif	; !_HAS_SWAP_SPACE

EC <		call	ECCheckLMemHandle				>

if	_HAS_SWAP_SPACE
	;
	; Grab global memory block
	;
		call	MemThreadGrab
		mov	ds, ax
endif	; _HAS_SWAP_SPACE

EC <		call	ECLMemValidateHeap				>

ife	_HAS_SWAP_SPACE
		pop	bp
endif	; !_HAS_SWAP_SPACE

		mov	si, ds:[LMBH_offset]
EC <		call	ECLMemValidateHandle				>
		.leave
		ret
MSLock		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the Media Status map.

CALLED BY:	(INTERNAL)
PASS:		ds	= MediaStatus map
RETURN:		nothing
DESTROYED:	ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/23/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSUnlock	proc	near
		.enter
ife	_HAS_SWAP_SPACE
		call	UtilVMUnlockDS
else
		push	bx
		mov	bx, ds:[LMBH_handle]
		call	MemThreadRelease
		pop	bx
endif	; _HAS_SWAP_SPACE
		.leave
		ret
MSUnlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSFindMediumUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the status map and locate a record for the passed
		medium & unit

CALLED BY:	(INTERNAL) MSRecord, MSCheckMediumCommon
PASS:		cxdx	= MediumType
		ss:bp	= inherited frame. first (in order of declaration)
			  local var is unit number. second local var holds
			  MediumUnitType in low byte. High byte is
			  ignored
RETURN:		*ds:si	= map chunk array
		bl	= unit type (may be different from local var)
		carry set if found in map
			ds:di	= MediaStatusElement
			ax, es = destroyed
		carry clear if not found
			es:di	= unit data (locked mem block if MUT_MEM_BLOCK)
				  (this is garbage if MUT_ANY)
			ax	= number of bytes in unit data
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSFindMediumUnit proc	near
unitNum		local	word
unitType	local	word
		.enter	inherit	far
		call	MSLock			; *ds:si <- map
	;
	; Point es:di to the unit data, whereever it is, setting AX to the
	; number of bytes that make up the data.
	; 
			CheckHack <MUT_NONE eq 0>
		mov	al, ss:[unitType].low
		clr	ah
		cmp	al, MUT_NONE
		je	haveUnit
		cmp	al, MUT_INT
		je	useLocalVar
		cmp	al, MUT_ANY
		je	haveUnit		; will be ignored, so doesn't
						;  matter...

		cmp	al, MUT_REASON_ENCLOSED
		je	handleReason

EC <		cmp	al, MUT_MEM_BLOCK				>
EC <		ERROR_NE	UNKNOWN_MEDIUM_UNIT_TYPE		>
		
		mov	bx, ss:[unitNum]
		call	MemLock
		mov	es, ax
		clr	di			; es:di <- unit data
		mov	ax, MGIT_SIZE
		call	MemGetInfo		; ax <- # bytes
		jmp	haveUnit

useLocalVar:
		segmov	es, ss
		lea	di, ss:[unitNum]
		mov	ax, size unitNum

haveUnit:
	;
	; Locate the medium/unit pair in the map.
	; 
		mov	bl, ss:[unitType].low
haveUnitAndType:
		push	bx
		call	MSFindUnitInternal
		pop	bx

		.leave
		ret

handleReason:
		mov	bx, ss:[unitNum]
		call	MemLock
		mov	es, ax
		mov	bl, es:[MUAR_type]
		mov	di, offset MUAR_unit
		mov	ax, es:[MUAR_size]
		jmp	haveUnitAndType
MSFindMediumUnit endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSFindUnitInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to perform the actual enumeration of the status map,
		because I prefer to inherit a frame set up from a separate
		routine than define a structure for the various things
		needed by the ChunkArrayEnum callback routine...

CALLED BY:	(INTERNAL) MSFindMediumUnit,
			   MediaRecordConnectionAddress
PASS:		cxdx	= MediumType
		es:di	= unit data
		ax	= # bytes of unit data
		bx	= unit type
		*ds:si	= chunk array
RETURN:		carry set if found:
			ds:di	= found element
		carry clear if not found:
			di	= preserved
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSFindUnitInternal proc	near
; THESE FIRST VARIABLES MUST MATCH THOSE IN MediaCheckAvailable
unitAddr	local	fptr		push es, di
unitSize	local	word		push ax
unitType	local	word		push bx
	ForceRef	unitAddr	; MSFindUnitCallback
	ForceRef	unitSize	; MSFindUnitCallback
	ForceRef	unitType	; MSFindUnitCallback
		uses	ax
		.enter
		mov	bx, cs
		mov	di, offset MSFindUnitCallback
		clr	ax
		call	ChunkArrayEnum
		jnc	reloadDI
		mov_tr	di, ax
done:
		.leave
		ret
reloadDI:
		mov	di, ss:[unitAddr].low
		jmp	done
MSFindUnitInternal endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSFindUnitCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to find a particular unit of a particular
		transport medium.

CALLED BY:	(INTERNAL) MSFindUnitInternal via ChunkArrayEnum
PASS:		*ds:si	= the array
		ds:di	= MediaStatusElement
		cxdx	= MediumType
		ax	= size of the element
		ss:bp	= inherited frame
RETURN:		carry set if this is the element being sought:
			ds:ax	= found element
		carry clear if it isn't
			ax	= destroyed
DESTROYED:	bx, es, si
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSFindUnitCallback proc	far
		.enter	inherit	MSFindUnitInternal
	;
	; See if it's the same medium.
	; 
		cmpdw	ds:[di].MSE_medium, cxdx
		jne	noMatch
	;
	; It is. If any unit is acceptable, we're done.
	; (else EC: Make sure the unit type is what we were passed.)
	; 
		cmp	ss:[unitType].low, MUT_ANY
		je	found

EC <		mov	bl, ss:[unitType].low				>
EC <		cmp	ds:[di].MSE_unitType, bl			>
EC <		ERROR_NE	INCONSISTENT_UNIT_TYPES_FOR_MEDIUM	>
	;
	; Figure how many bytes of unit data there are by subtracting out the
	; fixed-size of the element. If there aren't the same number of bytes
	; in the unit for which we're searching, this can't be a match.
	; 
		sub	ax, offset MSE_unitData
		cmp	ax, ss:[unitSize]
		jne	noMatch
	;
	; Compare all the bytes of the unit data. This is why memory blocks
	; that hold unit data must be allocated HAF_ZERO_INIT...
	; 
		push	di, ds, cx
		lea	si, ds:[di].MSE_unitData	; ds:si <- elt data
		les	di, ss:[unitAddr]		; es:di <- unit being
							;  sought
		mov_tr	cx, ax			; cx <- # bytes
		repe	cmpsb
		pop	di, ds, cx
		jne	noMatch
	;
	; On a match, we wish to return the offset of the start of the found
	; element in AX, then set the carry to stop enumerating.
	; 
found:
		mov_tr	ax, di
		stc
done:
		.leave
		ret

noMatch:
		clc
		jmp	done
MSFindUnitCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSCheckMediumCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to see if a particular unit of a particular
		medium exists and is in a particular state.

CALLED BY:	(INTERNAL) MailboxCheckMediumAvailable,
			   MailboxCheckMediumConnected
PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE or MUT_ANY)
		al	= MediumUnitType
		ah	= MediaStatusFlags for which to check
RETURN:		if MUT_MEM_BLOCK, unit number block is freed
		carry set if medium is in the indicated state
		carry clear if medium either doesn't exist or isn't in the
			indicated state
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSCheckMediumCommon proc	near
unitNum		local	word		push bx
unitTypeAndStat	local	word		push ax
		uses	ds, si, es, di, bx
		.enter
	;
	; First find the medium/unit record.
	; 
		call	MSFindMediumUnit
		pushf
	;
	; Free the unit data block, if such there is, before processing
	; result.
	; 
		cmp	ss:[unitTypeAndStat].low, MUT_MEM_BLOCK
		jne	freeUnitDone
		mov	bx, ss:[unitNum]
		call	MemFree
freeUnitDone:
		popf
		jnc	done
	;
	; Found it
	; 
		mov	al, ss:[unitTypeAndStat].high
		test	ds:[di].MSE_flags, al
		jz	done		; (test clears carry)
		stc			; => found and in requested state
done:
		call	MSUnlock
		.leave
		ret
MSCheckMediumCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxCheckMediumAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the indicated unit of a transmission medium exists,
		so far as the Mailbox library is concerned.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE or MUT_ANY)
		al	= MediumUnitType
RETURN:		carry set if medium & unit exist (if any unit of the medium
			exists, if al was MUT_ANY)
		carry clear if that unit (no unit, if MUT_ANY) of the medium
			exists
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxCheckMediumAvailable proc far
		uses	ax
		.enter
		mov	ah, mask MSF_AVAILABLE
		call	MSCheckMediumCommon
		.leave
		ret
MailboxCheckMediumAvailable endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxCheckMediumConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the indicated unit of a transmission medium is 
		connected, so far as the Mailbox library is concerned.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MediumType
		bx	= unit number (ignored if MUT_NONE or MUT_ANY)
		al	= MediumUnitType
RETURN:		carry set if medium & unit are connected (if any unit of the
			medium is connected, if al was MUT_ANY)
		carry clear if that unit (no unit, if MUT_ANY) of the medium
			is connected
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxCheckMediumConnected proc far
		uses	ax
		.enter
		mov	ah, mask MSF_CONNECTED
		call	MSCheckMediumCommon
		.leave
		ret
MailboxCheckMediumConnected endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaCheckMediumAvailableByPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Like MailboxCheckMediumAvailable, but accepts a pointer to a
		MailboxMediumDesc instead of the usual registers.

CALLED BY:	(EXTERNAL) OMLMlRescan
PASS:		es:di	= MailboxMediumDesc
RETURN:		carry set if medium exists
		carry clear if medium is absent
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaCheckMediumAvailableByPtr proc	far
		uses	di, cx, dx, ax, bx, ds, si
		.enter
	;
	; Lock down the map.
	; 
		call	MSLock
	;
	; Load up the registers appropriately.
	; 
		movdw	cxdx, es:[di].MMD_medium
		mov	ax, es:[di].MMD_unitSize
		mov	bl, es:[di].MMD_unitType
		add	di, offset MMD_unit
	;
	; Look for the thing.
	; 
		call	MSFindUnitInternal
	;
	; If no entry for it, or MSF_AVAILABLE isn't set, return carry clear
	;
		jnc	done
		test	ds:[di].MSE_flags, mask MSF_AVAILABLE
		jz	done
		stc
done:
	;
	; Release the map, preserving the carry that is our result.
	; 
		call	MSUnlock
		.leave
		ret
MediaCheckMediumAvailableByPtr endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetFirstMediumUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the first available unit of the indicated medium. For
		use when a transport driver just wants to use a particular
		medium but doesn't care which one.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MediumType
RETURN:		ax	= MediumUnitType (MUT_NONE if none available)
		bx	= unit number (caller must, of course, free the
			  memory block if MUT_MEM_BLOCK)
DESTROYED:	nothing
SIDE EFFECTS:	fatal-error if called on a medium that uses no unit numbers

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetFirstMediumUnit proc	far
unitNum		local	word
unitType	local	word
	ForceRef	unitNum ; garbage, but needed by MSFindMediumUnit
		uses	ds, si, es, di, cx
		.enter
	;
	; Go look for the first unit of the indicated type.
	; 
		mov	ss:[unitType], MUT_ANY
		call	MSFindMediumUnit
		jnc	returnNone
	;
	; Fetch the unit type out so we can return the proper data.
	; 
		clr	ax
		mov	al, ds:[di].MSE_unitType
EC <		cmp	al, MUT_NONE					>
EC <		ERROR_E	THERE_IS_NO_POINT_CALLING_THIS_FOR_MEDIA_WITH_NO_UNITS>
	;
	; Assume the thing is an integer and return the word at MSE_unitData
	; 
		mov	bx, {word}ds:[di].MSE_unitData
		cmp	al, MUT_MEM_BLOCK
		jne	done
	;
	; No such luck. We now have to copy the data into a memory block. The
	; only way to find the size, however, is to call ChunkArrayElementToPtr
	; but we need to know an element number to do that, so...
	; 
		call	ChunkArrayPtrToElement
		call	ChunkArrayElementToPtr	; cx <- element size
	    ;
	    ; Allocate a block large enough to hold the unit data. Remember to
	    ; zero-init the thing to avoid getting random data after the unit
	    ; data... (in theory, all the extra bytes are already 0, of course,
	    ; since the size we used to create this entry was based on the
	    ; heap's rounding, but...)
	    ;
		sub	cx, offset MSE_unitData
		mov_tr	ax, cx
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or \
				(mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		jc	allocErr
	    ;
	    ; Copy the data from the array element to the allocated block.
	    ; 
		mov	es, ax
		lea	si, ds:[di].MSE_unitData
		clr	di
		rep	movsb
	    ;
	    ; Unlock the unit data block and return the right unit type.
	    ; 
		call	MemUnlock
		mov	ax, MUT_MEM_BLOCK
done:
	;
	; Release the media status map, now we've got our answer.
	; 
		call	MSUnlock
		.leave
		ret
allocErr:
		WARNING	UNABLE_TO_ALLOCATE_UNIT_DATA_BLOCK
returnNone:
		mov	ax, MUT_NONE
		jmp	done
MailboxGetFirstMediumUnit endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaRecordConnectionAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the address to which a unit of media is connected.

CALLED BY:	(EXTERNAL)
PASS:		^hdx	= MailboxDisplayByTransportData
		^hbp	= MailboxDisplayByMediumData
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/18/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaRecordConnectionAddress proc	far
		uses	ds, si, di, cx, ax, bx, es
		.enter
	;
	; Get the unit data from the passed block
	;
		push	dx			; save the by-transport handle
		mov	bx, bp
		call	MemLock
		mov	ds, ax
		movdw	cxdx, ds:[MDBMD_medium].MMD_medium
		mov	es, ax			; es:di <- unit data
		mov	di, offset MDBMD_medium.MMD_unit
		mov	si, {word}ds:[MDBMD_medium].MMD_unitType
		mov	ax, ds:[MDBMD_medium].MMD_unitSize
		mov	bx, si		; bx <- unitType
	;
	; Locate the entry for the medium.
	;
		call	MSLock
		call	MSFindUnitInternal
		pop	dx
		mov	bx, bp
		call	MemUnlock		; release by-medium block now
EC <		WARNING_NC ATTEMPTING_TO_RECORD_ADDRESS_FOR_NON_EXISTENT_UNIT>
		jnc	unlockDone

		test	ds:[di].MSE_flags, mask MSF_CONNECTED
EC <		WARNING_Z RECORDING_ADDRESS_FOR_NON_CONNECTED_UNIT	>
		jz	unlockDone
	;
	; Figure how big a chunk to allocate for the address data.
	;
		mov	bx, dx
		call	MemLock
		mov	es, ax
		mov	cx, es:[MDBTD_addrSize]
		add	cx, size MediaConnectedData
		sub	di, ds:[si]		; di <- offset into array of
						;  element, for rederef...
	;
	; Allocate a chunk that big, naturally.
	;
		clr	ax
		call	LMemAlloc
	;
	; Link the address to the unit's chain of addresses.
	;
		add	di, ds:[si]
		mov	bx, ax			; *ds:bx <- address chunk
		xchg	ds:[di].MSE_addrs, ax
		mov	di, ds:[bx]
		mov	ds:[di].MCD_next, ax
	;
	; Copy from the byTransport block into the new chunk.
	;
		segxchg	ds, es
		clr	si
		add	di, offset MCD_data
		sub	cx, offset MCD_data
		rep	movsb
	;
	; Release the by-transport block.
	;
		segmov	ds, es
		MSDirty
		mov	bx, dx
		call	MemUnlock
unlockDone:
	;
	; Unlock the map 
	;
		call	MSUnlock
		.leave
		ret
MediaRecordConnectionAddress endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaCheckConnectable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the indicated medium is available for connection
		to the indicated address.

CALLED BY:	(EXTERNAL)
PASS:		cx:dx	= MailboxMediumDesc
		es:di	= connection address for comparison. size of the
			  address is the first word (size does not include
			  the size word itself)
		axbx	= MailboxTransport
		si	= MailboxTransportOption
RETURN:		carry set if medium is available for the address
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/18/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaCheckConnectable proc	far
; THESE FIRST VARIABLES MUST MATCH THOSE IN MSFindUnitInternal
unitAddr	local	fptr
unitSize	local	word
unitType	local	word
manuf		local	ManufacturerID
matchAddr	local	fptr
transport	local	MailboxTransport
transOption	local	MailboxTransportOption
		uses	ds, si, di, ax, bx, cx, dx
		.enter
	;
	; Set up the local variables for the massive numbers of comparisons
	; we'll have to do.
	;
		movdw	ss:[matchAddr], esdi
		movdw	ss:[transport], axbx
		mov	ss:[transOption], si

		movdw	dssi, cxdx
		mov	ax, ds:[si].MMD_unitSize
		mov	ss:[unitSize], ax

		mov	al, ds:[si].MMD_unitType
		mov	ss:[unitType], ax

		movdw	cxdx, ds:[si].MMD_medium
		mov	ss:[manuf], cx

		add	si, offset MMD_unit
		movdw	ss:[unitAddr], dssi
	;
	; Now lock down the status array and repeatedly use ChunkArrayEnumRange
	; to find the next unit of the passed medium.
	;
		call	MSLock
		clr	ax		; start w/element 0
unitLoop:
		mov	cx, -1		; all elements
		mov	bx, cs
		mov	di, offset MSMediaCheckConnectableCallback
		call	ChunkArrayEnumRange
		jnc	done		; => no suitable medium found
	;
	; Check the unit we found. If it's not connected, then it's available.
	;
		mov_tr	di, ax
		CheckHack <offset MSF_CONNECTED lt 8>	; parity only done
		CheckHack <offset MSF_AVAILABLE lt 8>	; on low 8 bits...
		test	ds:[di].MSE_flags, 
			mask MSF_CONNECTED or mask MSF_AVAILABLE
		jz	nextUnit	; => not available
		jpo	available	; => not connected
	;
	; See if we have any addresses + transports on record for it. If not,
	; then the connection isn't suitable for a transport driver to use,
	; else it would have told us about it.
	;
		mov	bx, ds:[di].MSE_addrs
addrLoop:
		tst	bx
		jz	nextUnit
	;
	; See if any are for the passed transport driver & option.
	;
		mov	bx, ds:[bx]
		cmpdw	ds:[bx].MCD_data.MDBTD_transport, ss:[transport], cx
		jne	nextAddr
		mov	cx, ds:[bx].MCD_data.MDBTD_transOption
		cmp	ss:[transOption], cx
		jne	nextAddr
	;
	; Compare the two addresses up to the size of the smaller of the two.
	;
		mov	ax, ds:[bx].MCD_data.MDBTD_addrSize
		push	si, di
		les	di, ss:[matchAddr]
		scasw
		jbe	haveSize	; stored address <= passed address, so
					;  use stored address size
		mov	ax, es:[di-2]	; ax <- passed address size
haveSize:
		lea	si, ds:[bx].MCD_data.MDBTD_addr
		xchg	ax, cx
		repe	cmpsb
		pop	si, di
		je	available

nextAddr:
		mov	bx, ds:[bx].MCD_next
		jmp	addrLoop

nextUnit:
	;
	; See if we should loop (only if the passed unit type was MUT_ANY)
	;
		cmp	ss:[unitType], MUT_ANY
		clc
		jne	done		; => found the sole unit, and it ain't
					;  free
	;
	; Figure out what index we found and start searching from the next one.
	;
		call	ChunkArrayPtrToElement
		inc	ax
		jmp	unitLoop
available:
		stc
done:
		call	MSUnlock
		.leave
		ret
MediaCheckConnectable endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSMediaCheckConnectableCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate a medium record to see if it's
		available.

CALLED BY:	(INTERNAL) MediaCheckConnectable via ChunkArrayEnumRange
PASS:		dx	= low word of MediumType
		ss:bp	= inherited frame, suitable for passing to
			  MSFindUnitCallback
		ax	= size of the record
		ds:di	= MediaStatusElement
		*ds:si	= the array
RETURN:		carry set if this is an element being sought:
			ds:ax	= found element
		carry clear if it isn't
			ax	= destroyed
DESTROYED:	bx, es, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/18/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSMediaCheckConnectableCallback proc	far
		.enter	inherit	MediaCheckConnectable
		mov	cx, ss:[manuf]
		GOTO	MSFindUnitCallback
		.leave	.unreached
MSMediaCheckConnectableCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaGetReason
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the reason a unit of media isn't available

CALLED BY:	(EXTERNAL)
PASS:		cx:dx	= MailboxMediumDesc
		ds	= VM block into which to copy the reason
RETURN:		*ds:ax	= reason string, ax = 0 if no reason stored (or unit
			  doesn't exist)
DESTROYED:	es if = ds on entry
SIDE EFFECTS:	memory block freed if MUT_MEM_BLOCK

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaGetReason	proc	far
		uses	es, si, di, cx, bx, dx
		.enter
	;
	; Locate the unit, if we can, and see if it's got a reason stored.
	;
		movdw	esdi, cxdx
		movdw	cxdx, es:[di].MMD_medium
		mov	ax, es:[di].MMD_unitSize
		mov	bl, es:[di].MMD_unitType
		add	di, offset MMD_unit
		push	ds
		call	MSLock
		call	MSFindUnitInternal
		jnc	notFound
		mov	bx, ds:[di].MSE_reason
		tst	bx
		jz	notFound
	;
	; It does. Compute the size and allocate that big a chunk in the dest
	; block.
	;
		ChunkSizeHandle	ds, bx, cx
		mov	si, ds
		pop	ds			; ds <- dest block
		clr	al
		call	LMemAlloc
	;
	; Copy the data into the chunk.
	;
		mov	di, ax
		mov	di, ds:[di]
		segmov	es, ds			; es:di <- dest chunk
		mov	ds, si
		mov	si, ds:[bx]		; ds:si <- src chunk
		rep	movsb
		call	MSUnlock
		segmov	ds, es
done:
		.leave
		ret

notFound:
	;
	; Couldn't find the unit, or it has no reason, so release the
	; status block and return 0.
	;
		call	MSUnlock
		pop	ds
		clr	ax
		jmp	done
MediaGetReason	endp

Media		ends
