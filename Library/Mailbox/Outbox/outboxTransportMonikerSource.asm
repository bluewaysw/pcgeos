COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxTransportMonikerSource.asm

AUTHOR:		Adam de Boor, Sep 22, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/22/94		Initial revision


DESCRIPTION:
	Implementation of OutboxTransportMonikerSource class, which exists
	to locate/create monikers for transport drivers on behalf of the
	two classes (OutboxTransportList and OutboxTransportMenu) that need
	them.
		

	$Id: outboxTransportMonikerSource.asm,v 1.1 97/04/05 01:21:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource
	OutboxTransportMonikerSourceClass
MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSRebuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rebuild the list of transports, optionally keeping track
		of the position of one transport during the rebuild.

CALLED BY:	MSG_OTMS_REBUILD
PASS:		*ds:si	= OutboxTransportMonikerSource object
		ds:di	= OutboxTransportMonikerSourceInstance
		cx	= transport to track (GIGS_NONE if none)
RETURN:		cx	= new position of tracked transport, or GIGS_NONE if
			  (a) was GIGS_NONE on entry, or (b) the transport
			  being tracked is no longer an option
		ax	= number of transports in the list
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSRebuild	method dynamic OutboxTransportMonikerSourceClass, 
				MSG_OTMS_REBUILD
		.enter
	;
	; For anything but OTMST_PANEL, we need to get the list of all
	; transports the user can access. For OTMST_PANEL, we want the
	; list of those used for messages currently in the outbox.
	; 
			CheckHack <OTMST_PANEL eq 0>
		tst	ds:[di].OTMSI_type
		jnz	getAvailableTransports
	;
	; Fetch all the transport + medium pairs that are known to exist
	; in the outbox.
	; 
		call	OMGetAllMediaTransportPairs	; *ds:ax <- array
	;
	; Append an all-zero entry to the array for "All"
	; 
		xchg	si, ax
		call	ChunkArrayAppend
		xchg	si, ax
		jmp	haveArray

getAvailableTransports:
	;
	; Not for a panel, so get all the known transports from the Media module
	; 
		mov	bl, ds:[di].OTMSI_type
		call	MediaGetAllTransports		; *ds:ax <- array

	;
	; Always filter by at least the MBTC_REQUIRES_TRANSPORT_HINT attribute
	;
		call	OTMSFilterByTransportHintRequirement
	;
	; Filter by OTLI_filter, if necessary.
	; 
			CheckHack <OTMSType eq OTMST_FILTERED+1>
			CheckHack <OTMST_FILTERED eq 3>	; => even parity
			CheckHack <OTMST_PANEL eq 0>
		or	bl, bl
		jpo	haveArray
		call	OTMSFilterArray

haveArray:
	;
	; Map the passed index from the old array to the new
	; 
		mov	di, ds:[si]			; deref obj
		mov	si, ds:[di].OTMSI_transports	; si <- old array
		mov	ds:[di].OTMSI_transports, ax	; store new array

		xchg	ax, si			; ax <- old array, si <- new

		cmp	cx, GIGS_NONE		; any mapping requested?
		je	freeOldArray		; => no, so just free the old

	    ;
	    ; Point ds:dx to the entry in the old array, for comparison.
	    ; 
EC <		tst	ax						>
EC <		ERROR_Z	INVALID_TRANSPORT_INDEX				>
   		push	si			; save new
		mov_tr	si, ax			; si <- old array
		mov	ax, cx			; ax <- index into same
		call	ChunkArrayElementToPtr
EC <		ERROR_C	INVALID_TRANSPORT_INDEX
		mov	dx, di			; ds:dx <- entry in old
		mov_tr	ax, si			; ax <- old array, again
		pop	si			; si <- new array
	    ;
	    ; Enumerate through the entries in the new array looking for one
	    ; that matches the one we found in the old.
	    ; 
		mov	bx, cs
		mov	di, offset OTMSRebuildListCallback
		segmov	es, ds
		clr	cx
		call	ChunkArrayEnum
		jc	freeOldArray		; => found it, so CX is fine

		mov	cx, GIGS_NONE		; signal old entry no longer
						;  valid
freeOldArray:
	;
	; Free the old transport array, now we're done with it.
	; 
	; ax = old array (if any)
	; si = new array
	; 
		tst	ax
		jz	getNumEntries
		call	LMemFree

getNumEntries:
	;
	; Figure the number of entries in the new array.
	; 
		mov_tr	ax, cx			; save mapped index
		call	ChunkArrayGetCount	; cx <- # entries in new
		xchg	cx, ax			; want them the other order
		.leave
		ret
OTMSRebuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSortTransports
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort the transport array in the Responder order.

CALLED BY:	OTMSRebuild
PASS:		*ds:ax	= chunk array of MailboxMediaTransport's
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSortTransportsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to sort MailboxMediaTransport's in the
		Responder order.

CALLED BY:	OTMSortTransports via ChunkArraySort
PASS:		ds:si	= first MailboxMediaTransport
		es:di	= second MailboxMediaTransport
RETURN:		flags set for jl, je or jg
DESTROYED:	ax, bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The "correct" order of transports in Responder is:
		GMTID_PRINT_SPOOLER
		GMTID_FAX_SEND
		GMTID_SM
		GMTID_SMTP
	Any other transport is placed at the end of the array.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSFilterByTransportHintRequirement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all MailboxMediaTransport pairs from the array for those
		drivers that require an ATTR_MAILBOX_SEND_CONTROL_TRANSPORT_HINT
		on the MailboxSendControl in order to operate properly.

CALLED BY:	(INTERNAL) OTMSRebuild
PASS:		*ds:si	= OutboxTransportMonikerSource
		*ds:ax	= chunk array of MailboxMediaTransport elements
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		First see if our object block output is a MailboxSendControl
		object. If not, we won't allow any driver that has the
		MBTC_REQUIRES_TRANSPORT_HINT attribute set.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSFilterByTransportHintRequirement proc	near
		class	OutboxTransportMonikerSourceClass
		uses	bx, es, bp, di, si, cx, dx, ax
		.enter
	;
	; End up with *cx:dx = MailboxSendControl or cx = 0; bx = MSC block
	; 
		clr	cx			; assume not associated with
						;  MSC
		mov	bx, ds:[OLMBH_output].handle
		tst	bx
		jz	haveMSCParams
	    ;
	    ; Lock down the output's block so we can tell if the thing
	    ; is the right class and so we have it locked for the callback
	    ; 
		push	ds, ax
		mov	si, ds:[OLMBH_output].chunk
		call	ObjLockObjBlock
		mov	ds, ax
		movdw	cxdx, dssi		; *cx:dx <- MSC for callback
		
		segmov	es, <segment MailboxSendControlClass>, di
		mov	di, offset MailboxSendControlClass
		call	ObjIsObjectInClass
		jc	popHaveMSC
	    ;
	    ; We've got an output, but it's not a MailboxSendControl, so it's
	    ; of no use to us.
	    ; 
		call	MemUnlock
		clr	cx, bx
popHaveMSC:
		pop	ds, ax

haveMSCParams:
	;
	; Now iterate over all the MailboxMediaTransport records, looking to
	; nuke those that are inappropriate.
	; 
		push	bx		; save for possible unlock
		mov_tr	si, ax		; *ds:si <- array
		call	AdminGetTransportDriverMap
		mov_tr	bp, ax		; bp <- transport driver dmap
		mov	bx, cs
		mov	di, offset OTMSFilterByTransportHintRequirementCallback
		call	ChunkArrayEnum
		pop	bx
	;
	; Unlock the MSC block, if we found it.
	; 
		tst	bx
		jz	done
		call	MemUnlock
done:
		.leave
		ret
OTMSFilterByTransportHintRequirement endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSFilterByTransportHintRequirementCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the given driver needs to have a transport hint
		in the send control, deleting its entry if it does

CALLED BY:	(INTERNAL) OTMSFilterByTransportHintRequirement
PASS:		ds:di	= MailboxMediaTransport to check
		*cx:dx	= MailboxSendControl object or
			= 0:? if no associated MSC
		bp	= handle of transport driver map
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, es
		bx, si, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSFilterByTransportHintRequirementCallback proc	far
		.enter
	;
	; First fetch the attributes for the driver and see if it's got the
	; requirement bit set.
	; 
		push	cx, dx
		movdw	cxdx, ds:[di].MMT_transport
		mov	ax, bp
		call	DMapGetAttributes
EC <		ERROR_C	HOW_CAN_TRANSPORT_DRIVER_BE_INVALID?		>
		test	ax, mask MBTC_REQUIRES_TRANSPORT_HINT
   		pop	cx, dx
		jz	done
	;
	; It does require the hint. See if the MailboxSendControl has the
	; hint for this transport.
	; 
		jcxz	nukeEntry		; => no MSC, so don't include

		push	ds, bp, di, si, cx, dx
		movdw	bxbp, ds:[di].MMT_transport	; bxbp <- transport for
							;  callback to check
		movdw	dssi, cxdx		; *ds:si <- MSC
		mov	dx, bx			; make that dxbp <- transport
		clr	cx			; cx <- assume not found
		segmov	es, cs
		mov	di, offset findTransportHandlerTable
		mov	ax, length findTransportHandlerTable
		call	ObjVarScanData
		tst	cx			; was it found?
		pop	ds, bp, di, si, cx, dx
		jnz	done			; => it was

nukeEntry:
	;
	; Delete this entry from the array.
	; 
		call	ChunkArrayDelete
done:
		clc
		.leave
		ret
OTMSFilterByTransportHintRequirementCallback endp

findTransportHandlerTable	VarDataHandler \
	<ATTR_MAILBOX_SEND_CONTROL_TRANSPORT_HINT, OTMSProcessTransportHint>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSProcessTransportHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the found transport hint is for the desired driver

CALLED BY:	(INTERNAL) OTMSFilterByTransportHintRequirementCallback via
			   ObjVarScanData
PASS:		*ds:si	= MailboxSendControl
		ds:bx	= MailboxTransportAndOption for the hint
		cx	= 0 if not found yet
		dxbp	= MailboxTransport for which hint is being sought
RETURN:		cx	= non-zero if hint was for transport
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSProcessTransportHint proc	far
		.enter
		jcxz	checkIt
done:
		.leave
		ret

checkIt:
		CmpTok	ds:[bx].MTAO_transport, dx, bp, done
		dec	cx
		jmp	done
OTMSProcessTransportHint endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSFilterArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all transports from the array that don't have the
		desired capability bit set.

CALLED BY:	(INTERNAL) OTMSRebuild
PASS:		*ds:si	= OutboxTransportMonikerSource
		*ds:ax	= chunk array of MailboxMediaTransport elements
RETURN:		nothing
DESTROYED:	di, bx
SIDE EFFECTS:	entries may be deleted from the array, possibly ending up
     			with none left. If this concerns you, you should
			call MediaGetAllTransportCapabilities to make
			sure there's one transport that has the capability
			you want.

PSEUDO CODE/STRATEGY:
		Call callback for each element of the array that fetches
			the capabilities of the driver and ensures the
			necessary bit(s) is(are) set.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSFilterArray	proc	near
		uses	cx, dx, ax, si
		class	OutboxTransportMonikerSourceClass
		.enter
		mov	di, ds:[si]
		mov	cx, ds:[di].OTMSI_filter
EC <		tst	cx						>
EC <		ERROR_Z FILTERED_TRANSPORT_LIST_MISSING_FILTER		>
		mov_tr	si, ax
		call	AdminGetTransportDriverMap
		mov_tr	dx, ax
		mov	bx, cs
		mov	di, offset OTMSFilterArrayCallback
		call	ChunkArrayEnum
		.leave
		ret
OTMSFilterArray	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSFilterArrayCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to remove a transport from the array of
		possibilities if it doesn't have the indicated filter bit(s)
		set.

CALLED BY:	(INTERNAL) OTMSFilterArray via ChunkArrayEnum
PASS:		ds:di	= MailboxMediaTransport to check
		cx	= MailboxTransportCapabilities that must be set
		dx	= transport driver map handle
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax
SIDE EFFECTS:	current entry is deleted if it doesn't have the right stuff

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSFilterArrayCallback proc	far
		.enter
	;
	; Fetch the capabilities of the driver.
	; 
		push	cx, dx
		mov_tr	ax, dx
		movdw	cxdx, ds:[di].MMT_transport
		call	DMapGetAttributes		; ax <- capabilities
		pop	cx, dx
	;
	; See if the necessary bits are set. (all bits must be set)
	; 
		and	ax, cx
		cmp	ax, cx
		je	filterDone
	;
	; Not all set, so delete this entry, please.
	; 
		call	ChunkArrayDelete
filterDone:
		clc
		.leave
		ret
OTMSFilterArrayCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSRebuildListCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate the current index of the
		selection that was active before the list got rebuilt.

CALLED BY:	(INTERNAL) OTMSRebuild via ChunkArrayEnum
PASS:		ds:di	= MailboxMediaTransport to check
		ds:dx	= MailboxMediaTransport in old array for comparison
		es	= ds
		cx	= index of this element
RETURN:		carry set if this is the pair we want:
			cx	= the index of the element
		carry clear if this isn't it:
			cx	= the index of the next element
DESTROYED:	si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSRebuildListCallback proc	far
		uses	ax
		.enter
		mov	si, dx
		push	cx
		mov	cx, size MailboxMediaTransport/2
		repe	cmpsw
		pop	cx
		jne	notFound
		stc			; stop enumerating, and leave CX
					;  alone, since it's the index for
					;  this element
done:
		.leave
		ret
notFound:
		inc	cx		; advance the index
		clc			; keep enumerating
		jmp	done
OTMSRebuildListCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSGetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the appropriate moniker for a transport

CALLED BY:	MSG_OTMS_GET_MONIKER
PASS:		*ds:si	= OutboxTransportMonikerSource object
		ds:di	= OutboxTransportMonikerSourceInstance
		cx	= transport index
RETURN:		carry set on error
		carry clear if moniker returned:
			^lcx:dx	= moniker to use (control passes to called if
				  cx == ds:[LMBH_handle])
			ax	= TRUE if transport should be selectable
				= FALSE if it shouldn't
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
searchFlags	VisMonikerSearchFlags	OTMST_PANEL_SEARCH_FLAGS,
					OTMST_MENU_SEARCH_FLAGS,
					OTMST_TOOL_SEARCH_FLAGS,
					OTMST_FILTERED_SEARCH_FLAGS
	.assert	length searchFlags eq OTMSType

OTMSGetMoniker method dynamic OutboxTransportMonikerSourceClass, 
				MSG_OTMS_GET_MONIKER
		uses	bp
		.enter
	;
	; Point to the proper element and fetch out the transport & medium
	; 
		push	si
		mov	si, ds:[di].OTMSI_transports
		Assert	chunk, si, ds	; if you die here, you probably forgot
					;  to call MSG_OTMS_REBUILD before
					;  coming up on screen. OutboxControl-
					;  Panel does this in its OCP_SET_-
					;  SPECIFIC method, for example
		mov	ax, cx
   		call	ChunkArrayElementToPtr
		jc	done		; => out-of-bounds

	;
	; If the transport is GMTID_LOCAL, it means this is the "All" entry
	; 
		CmpTok	ds:[di].MMT_transport, MANUFACTURER_ID_GEOWORKS, \
				GMTID_LOCAL, getMoniker
	;
	; Load up the optr for the "All" string and go to common code.
	; 
		mov	cx, handle uiAllMoniker
		mov	dx, offset uiAllMoniker
		pop	si
		mov	ax, TRUE
		jmp	haveMoniker

getMoniker:
		pop	si
		call	OTMSCheckSelectable
		push	ax
	;
	; Fetch the display type out of our dgroup, where we fetched it during
	; initialization. We need it to figure the right moniker to use.
	; 
		segmov	es, dgroup, ax
		mov	ax, {word}es:[uiDisplayType]

	;
	; Compute the search flags to use, based on the type of list we are.
	; 
		CheckHack <MGTMA_displayType eq MediaGetTransportMonikerArgs-2>
		push	ax		; push MGTMA_displayType

		mov	bx, ds:[si]
		mov	bl, ds:[bx].OTMSI_type
		clr	bh
			CheckHack <type searchFlags eq 2>
		shl	bx
		mov	bx, cs:[searchFlags][bx]

		CheckHack <MGTMA_searchFlags eq MediaGetTransportMonikerArgs-4>
		push	bx
	;
	; Stuff the medium into the argument structure.
	; 
		CheckHack <MGTMA_medium eq MediaGetTransportMonikerArgs-8>
		pushdw	ds:[di].MMT_medium
	;
	; Stuff the transport into the argument structure.
	; 
		CheckHack <MGTMA_transOption eq MediaGetTransportMonikerArgs-10>
		push	ds:[di].MMT_transOption
		CheckHack <MGTMA_transport eq MediaGetTransportMonikerArgs-14>
		pushdw	ds:[di].MMT_transport
	;
	; Args all set -- now go get the moniker.
	; 
		CheckHack <MediaGetTransportMonikerArgs eq 14>
		mov	bp, sp
		call	MediaGetTransportMoniker
EC <		ERROR_C	HOW_CAN_MEDIA_TRANSPORT_BE_INVALID?		>
   		add	sp, size MediaGetTransportMonikerArgs
	;
	; Load ^lcx:dx with the optr of the moniker, bp gets the item # again,
	; and bx gets the data type of the moniker (namely, a vis moniker).
	; 
		mov	cx, ds:[LMBH_handle]
		mov_tr	dx, ax
		pop	ax		; ax <- whether it's selectable
haveMoniker:
		clc
done:
		.leave
		ret
OTMSGetMoniker	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSCheckSelectable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the given transport should be selectable

CALLED BY:	(INTERNAL) OTMSGetMoniker
PASS:		ds:di	= MailboxMediaTransport to check
		*ds:si	= OutboxTransportMonikerSource
RETURN:		ax	= TRUE if should be selectable
			= FALSE if shouldn't be
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSCheckSelectable proc near
		uses	bx, si, cx, dx, di, bp
		.enter
		mov	ax, ATTR_OTMS_AVAILABLE_FORMATS
		call	ObjVarFindData
		jnc	selectable		; => no restrictions
		
		mov	cx, ds
		mov	dx, bx
		movdw	axbx, ds:[di].MMT_transport
		mov	si, ds:[di].MMT_transOption
		call	MediaCheckSupportedFormat
		mov	ax, FALSE		; assume none acceptable w/o
						;  biffing carry flag
		jnc	done
selectable:
		mov	ax, TRUE
done:
		.leave
		ret
OTMSCheckSelectable endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSSetAvailableFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the list of available formats for deciding whether
		items are selectable.
		
		It's up to the caller to reinitialize the list that uses
		us.

CALLED BY:	MSG_OTMS_SET_AVAILABLE_FORMATS
PASS:		*ds:si	= OutboxTransportMonikerSource object
		ds:di	= OutboxTransportMonikerSourceInstance
		cx:dx	= array of MailboxDataFormats, ending with one that
			  is MANUFACTURER_ID_GEOWORKS/GMDFID_INVALID
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	ATTR_OTMS_AVAILABLE_FORMATS set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSSetAvailableFormats method dynamic OutboxTransportMonikerSourceClass, 
			MSG_OTMS_SET_AVAILABLE_FORMATS
		.enter
		mov	ax, ATTR_OTMS_AVAILABLE_FORMATS
		call	MSCStoreFormats
		.leave
		ret
OTMSSetAvailableFormats endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSGetTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the MailboxMediaTransport for an index

CALLED BY:	MSG_OTMS_GET_TRANSPORT
PASS:		*ds:si	= OutboxTransportMonikerSource object
		ds:di	= OutboxTransportMonikerSourceInstance
		cx	= transport index
		dx:bp	= MailboxMediaTransport buffer to fill in
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSGetTransport method dynamic OutboxTransportMonikerSourceClass, 
				MSG_OTMS_GET_TRANSPORT
		.enter
		Assert	fptr, dxbp

		mov	es, dx		; es:bp <- buffer
	;
	; Point to the proper element.
	; 
		mov	si, ds:[di].OTMSI_transports
		Assert	chunk, si, ds
		mov_tr	ax, cx

   		call	ChunkArrayElementToPtr
		jc	returnAllToken
	;
	; Copy the element out to the passed buffer.
	; 
		mov	si, di
		mov	di, bp
		mov	cx, size MailboxMediaTransport
		rep	movsb
done:
		.leave
		ret

returnAllToken:
	;
	; Asked for something beyond the end of our array, so pretend the thing
	; is "All"
	; 
EC <		WARNING	RETURNING_ALL_FOR_TRANSPORT			>
		clr	ax
		movdw	es:[bp].MMT_transport, axax
		movdw	es:[bp].MMT_medium, axax
		mov	es:[bp].MMT_transOption, ax
		jmp	done
OTMSGetTransport endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSGetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the list type bound to this object.

CALLED BY:	MSG_OTMS_GET_TYPE
PASS:		*ds:si	= OutboxTransportMonikerSource object
		ds:di	= OutboxTransportMonikerSourceInstance
RETURN:		al	= OTMSType
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSGetType	method dynamic OutboxTransportMonikerSourceClass, 
					MSG_OTMS_GET_TYPE
		.enter
		mov	al, ds:[di].OTMSI_type
		.leave
		ret
OTMSGetType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSSetType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the list type and possibly the filter for the object.
		Caller must rebuild the list by hand if desired

CALLED BY:	MSG_OTMS_SET_TYPE
PASS:		*ds:si	= OutboxTransportMonikerSource object
		ds:di	= OutboxTransportMonikerSourceInstance
		cl	= OTMSType
		dx	= MailboxTransportCapabilities if cl is OTMST_FILTERED
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	OTMSI_type and OTMSI_filter are set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSSetType	method dynamic OutboxTransportMonikerSourceClass, 
		       		MSG_OTMS_SET_TYPE
		.enter
		Assert	etype, cl, OTMSType
EC <		cmp	cl, OTMST_FILTERED				>
EC <		jne	filterOK					>
EC <		tst	dx						>
EC <		ERROR_Z	FILTERED_TRANSPORT_LIST_MISSING_FILTER		>
EC <filterOK:								>
		mov	ds:[di].OTMSI_type, cl
		cmp	cl, OTMST_FILTERED
		je	setFilter
		clr	dx
setFilter:
		mov	ds:[di].OTMSI_filter, dx
		.leave
		ret
OTMSSetType	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSMapTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map from a MailboxMediaTransport to a list index

CALLED BY:	MSG_OTMS_MAP_TRANSPORT
PASS:		*ds:si	= OutboxTransportMonikerSource object
		ds:di	= OutboxTransportMonikerSourceInstance
		dx:bp	= MailboxMediaTransport
RETURN:		carry set if not found
		carry clear if found:
			cx	= 0-based index
DESTROYED:	ax, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSMapTransport method dynamic OutboxTransportMonikerSourceClass, 
			MSG_OTMS_MAP_TRANSPORT
		.enter
		mov	si, ds:[di].OTMSI_transports
		Assert	chunk, si, ds
		mov	bx, cs
		mov	di, offset OTMSMapTransportCallback
		mov	es, dx		; es:bp <- MailboxMediaTransport
		clr	cx
		call	ChunkArrayEnum
		cmc
		.leave
		ret
OTMSMapTransport endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OTMSMapTransportCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to find a transport index given its
		MailboxMediaTransport structure

CALLED BY:	OTMSMapTransport via ChunkArrayEnum
PASS:		ds:di	= MailboxMediaTransport to check
		es:bp	= MailboxMediaTransport being sought
		cx	= index of this element
RETURN:		carry set to stop enumerating:
			cx	= unchanged (found element)
		carry clear to keep searching:
			cx	= cx+1
DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OTMSMapTransportCallback proc	far
		.enter
	;
	; Compare the transport first-off.
	; 
		mov	ax, ds:[di].MMT_transport.MT_manuf
		cmp	es:[bp].MMT_transport.MT_manuf, ax
		jne	notFound

		mov	ax, ds:[di].MMT_transport.MT_id
		cmp	es:[bp].MMT_transport.MT_id, ax
		jne	notFound
	;
	; Transport compared. See if it's 0_0, meaning it's "All" and the
	; other fields are meaningless.
	; 
		or	ax, ds:[di].MMT_transport.MT_manuf
			CheckHack <GMTID_LOCAL eq 0>
		jz	found		; => "All"
	;
	; Looking for something specific, so compare the transOption.
	; 
		mov	ax, ds:[di].MMT_transOption
		cmp	es:[bp].MMT_transOption, ax
		jne	notFound
	;
	; That matched. Check the medium, finally.
	; 
		mov	ax, ds:[di].MMT_medium.MET_manuf
		cmp	es:[bp].MMT_medium.MET_manuf, ax
		jne	notFound
		
		mov	ax, ds:[di].MMT_medium.MET_id
		cmp	es:[bp].MMT_medium.MET_id, ax
		je	found

notFound:
	;
	; Make cx be index for next element, and return carry clear to keep
	; searching.
	; 
		inc	cx
		clc
done:
		.leave
		ret

found:
	;
	; Found it. Leave CX alone (it's the index we want) and return carry
	; set to stop searching.
	; 
		stc
		jmp	done
OTMSMapTransportCallback endp

OutboxUICode	ends
