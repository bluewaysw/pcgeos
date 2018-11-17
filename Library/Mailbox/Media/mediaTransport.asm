COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Media
FILE:		mediaTransport.asm

AUTHOR:		Adam de Boor, Apr 13, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT MTGetMaps               Load the registers with the handles of the
				chunk arrays that hold the map info

    INT MTLock                  Lock down the media -> transport map &
				fetch the two chunk arrays involved.

    EXT MediaTransportNewMedium	Cope with a new medium entry being added to
				the status map by seeing if it's a type of
				media we've never ever seen. If it is, we
				must call all the known transport drivers
				to see if they handle the medium.

    INT MTFindMedium            See if the indicated medium is known
				already.

    INT MTAddMedium             Add a medium to the media -> transport map

    INT MTAddMediumCallback     Callback routine to ask a particular
				transport driver if it supports a
				particular medium.

    EXT MediaEnsureTransportInfo 
				Make sure we've got the information for
				this transport / transport option / medium
				tuple on file.

    INT MTCheckMediumCommon     Common code to ask a transport driver if it
				supports a particular medium, and add it to
				a MediaTransportMediaElement if it does.

    INT MTCheckTransportAlreadyKnown 
				See if the passed transport driver &
				transport option are already listed as
				supporting the medium. We'll usually get
				into such a situation when a transport
				driver is found via
				MediaEnsureTransportInfo, so the medium
				passed there already has the transport
				listed, but then we come along fielding the
				MSG_MP_NEW_TRANSPORT and do the work again

    INT MTGetMediumParams       Obtain the medium params for the transport
				driver and option, updating the
				media->transport map.

    INT MTCopyMonikerList       Copy all the monikers in the moniker list
				returned by the transport driver into the
				media -> transport block

    INT MTCopyVerb              Copy the returned verb into the media ->
				transport block

    INT MTCopyAbbrev            Copy the returned abbreviation into the
				media -> transport block

    INT MTAddTransport          Find the token for a transport driver,
				adding it to the element array if it's not
				there.

    INT MTNotifySystemPanel     Send some notification to a system panel,
				owing to a new transport with new
				capabilities becoming available

    EXT MediaNewTransport       Note that a new transport driver has been
				discovered

    INT MTMaybeSendUpdate       If something got added to the media ->
				transport map, send out notification to
				update any transport lists.

    INT MTFindTransport         Find a transport's reference token -- this
				is the index of the MediaTransportElement
				for the transport in the transport array of
				the media -> transport map. If the
				transport is not in the map, then it is not
				found.  The driver directory is *not*
				rescanned, even if DMF_DRIVER_DIR_CHANGED
				is set.

    INT MTFindTransportCallback Callback routine to find a particular
				transport in the element array.

    INT MTNewTransportCallback  Callback function to ask a particular
				transport driver whether it supports a
				transport medium

    INT MTFindTransportInMediumEntry 
				Look for a transport+transOption reference
				in the entry for a particular medium

    INT MTCreateMTResultArray   Create a chunk array to hold
				MailboxTransport tokens

    EXT MediaGetTransports      Retrieve the list of transport drivers that
				can work with a particular transport
				medium.

    INT MTGetTransportsCallback Callback routine to first find the
				indicated medium, then to store the
				MailboxTransport tokens of the transport
				drivers that support the medium in the
				passed array.

    EXT MediaGetTransportMoniker 
				Retrieve the moniker for a particular
				transport+medium pair.

    INT MTGetOneMoniker         Fetch the appropriate moniker out of the
				moniker list for a transport.

    EXT MediaGetTransportString Fetch the string for a medium/transport
				combination. The string is extracted from a
				text moniker, with a VMS_TEXT moniker the
				preferred one.

    INT MTGetMediaTransportWord Extract a word from the
				MediaTransportMediaRef for a
				transport/medium combination

    INT MTGetMediaTransportWordCallback 
				Callback function to locate the
				MediaTransportMediaElement for a medium,
				then fetch the requested word out of the
				MediaTransportMediaRef structure for the
				desired transport

    EXT MediaGetTransportVerb   Retrieve the text string for the verb that
				indicates a message is being sent through a
				medium via a transport driver

    EXT	MediaGetTransportAbbrev	Retrieve the text string for the abbreviation
				that indicates a message is being sent through
				a medium via a transport driver

    EXT MediaGetTransportSigAddrBytes 
				Retrieve the number of bytes in an address
				for this medium / transport pair that are
				considered significant when comparing to
				another address for this pair. If an
				address has fewer than this many bytes, it
				and a longer address should be considered
				equal if the entire shorter address matches
				the equivalent bytes of the longer.

    EXT MediaGetAllTransports   Retrieve the list of available transports,
				where a transport is considered available
				if a medium it uses has ever been available
				to the machine.

				Used to build up the list of possible
				transports in various places
				(MailboxTransportListClass)

    INT MTGetAllTransportsCallback 
				Callback routine to create a
				MailboxMediaTransport entry in the passed
				array for each transport driver that uses
				this medium

    EXT MediaGetAllTransportCapabilities 
				Retrieves the union of the
				MailboxTransportCapabilities for all the
				transports that would be returned by
				MediaGetAllTransports. It is intended to
				allow someone to quickly determine whether
				certain functions (notably the sending of
				system/Poof messages and the retrieval of
				new messages) should be made available to
				the user.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/13/94		Initial revision


DESCRIPTION:
	Functions for maintaining/searching the media -> transport map
		

	$Id: mediaTransport.asm,v 1.1 97/04/05 01:20:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Media	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTGetMaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the registers with the handles of the chunk arrays
		that hold the map info

CALLED BY:	(INTERNAL)
PASS:		ds	= locked media -> transport map block
RETURN:		*ds:si	= media array
		*ds:di	= transport array
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTGetMaps	proc	near
		.enter
		mov	si, ds:[LMBH_offset]
   		lea	di, ds:[si+2]
		.leave
		ret
MTGetMaps	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the media -> transport map & fetch the two
		chunk arrays involved.

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		*ds:si	= media array
		*ds:di	= transport array
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTLock		proc	near
		uses	bx, ax, bp
		.enter
	;
	; Get the vptr of the transport map & error-check the heck out of it.
	; 
		call	AdminGetMediaTransportMap

EC <		call	ECVMCheckVMFile					>
EC <		push	ax, cx						>
EC <		call	VMInfo						>
EC <		ERROR_C	MEDIA_TRANSPORT_MAP_INVALID			>
EC <		cmp	di, MBVMID_MEDIA_TRANSPORT			>
EC <		ERROR_NE MEDIA_TRANSPORT_MAP_INVALID			>
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
		call	MTGetMaps

EC <		call	ECLMemValidateHandle				>
EC <		xchg	si, di						>
EC <		call	ECLMemValidateHandle				>
EC <		xchg	si, di						>

		.leave
		ret
MTLock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaTransportNewMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cope with a new medium entry being added to the status map
		by seeing if it's a type of media we've never ever seen. If
		it is, we must call all the known transport drivers to see
		if they handle the medium.

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= MediumType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	New elements may be added to the transport element array,
     			provoking notification of all MailboxTransportList
			objects

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaTransportNewMedium	proc	far
		uses	ds, si, di, ax
		.enter
		call	MTLock		; *ds:si <- media map
					; *ds:di <- transport map
		call	MTFindMedium
		jc	done
	;
	; Not already present, so go add it.
	; 
		call	MTAddMedium
done:
		call	UtilVMUnlockDS
		.leave
		ret
MediaTransportNewMedium	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTFindMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the indicated medium is known already.

CALLED BY:	(INTERNAL) MediaTransportNewMedium
PASS:		*ds:si	= media map
		cxdx	= MediumType to find
RETURN:		carry set if it's there:
			ax	= element #
		carry clear if it's not:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 1/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTFindMedium	proc	near
		uses	bx, di
		.enter
		mov	bx, cs
		mov	di, offset findMediumCallback
		call	ChunkArrayEnum
		.leave
		ret

findMediumCallback:
		cmpdw	ds:[di].MTME_medium, cxdx
		clc
		jne	findMediumCallbackDone
		call	ChunkArrayPtrToElement	; ax <- element #
		stc
findMediumCallbackDone:
		retf
MTFindMedium	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTAddMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a medium to the media -> transport map

CALLED BY:	(INTERNAL) MediaTransportNewMedium, MediaEnsureTransportInfo
PASS:		*ds:si	= media map
		*ds:di	= transport map
		cxdx	= MediumType
RETURN:		ds	= fixed up
		ax	= element #
DESTROYED:	si, di allowed
SIDE EFFECTS:	all known transport drivers will be loaded and asked about
     			the medium

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTAddMedium	proc	near
		uses	bx, cx, dx, bp
		.enter
	;
	; Make room for a minimal MediaTransportMediaElement at the end of
	; the media map and initialize it with the medium being added.
	; 
		mov	ax, size MediaTransportMediaElement
		call	ChunkArrayAppend
		movdw	ds:[di].MTME_medium, cxdx
	;
	; Remember the new element's number, so we can get back to it.
	; 
		call	ChunkArrayPtrToElement
	;
	; Now fetch the tokens for all known transport drivers.
	; 
		push	ax
		call	AdminGetTransportDriverMap
		call	DMapGetAllTokens
	;
	; Run through all the drivers, asking each in turn whether it uses
	; the medium.
	; 
		pop	bp		; bp <- media map element #, for
					;  callback to use
		mov_tr	si, ax		; *ds:si <- array to enum
		mov	bx, cs
		mov	di, offset MTAddMediumCallback
		; EC: if sendUpdate is TRUE, it means an update wasn't sent
		; when it should have been
		Assert	e, ds:[MTH_sendUpdate], FALSE
NEC <		mov	ds:[MTH_sendUpdate], FALSE			>
		call	ChunkArrayEnum
	;
	; Nuke the array of all drivers.
	; 
		mov_tr	ax, si
		call	LMemFree
	;
	; Send update to MTLC objects if MTH_sendUpdate is non-zero
	; 
		call	MTMaybeSendUpdate
	;
	; Return the element number in AX
	; 
		mov_tr	ax, bp
		.leave
		ret
MTAddMedium	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTAddMediumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to ask a particular transport driver if
		it supports a particular medium.

CALLED BY:	(INTERNAL) MTAddMedium via ChunkArrayEnum
PASS:		ds:di	= MailboxTransport
		ds	= media -> transport map block
		bp	= element number within media map for medium being
			  added
		cxdx	= MediumType being added
RETURN:		carry set to stop enumerating (always returned clear)
		ax	= non-zero if transport added to any medium
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	element may be added to the transport element array
     		medium's entry in media array may be expanded

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTAddMediumCallback proc	far
		.enter
		movdw	axbx, ds:[di]
		call	MTCheckMediumCommon
		clc
		.leave
		ret
MTAddMediumCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaEnsureTransportInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we've got the information for this transport /
		transport option / medium tuple on file.

CALLED BY:	(EXTERNAL)
PASS:		axbx	= MailboxTransport
		cxdx	= MediumType
		si	= MailboxTransportOption
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	EC: FatalError if driver claims to know nothing about
		    this medium

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaEnsureTransportInfo proc	far
medium		local	MediumType		push cx, dx
transport	local	MailboxTransport	push ax, bx
transOption	local	MailboxTransportOption	push si
		uses	ax, bx, cx, dx, si, di, ds
		.enter
	;
	; Locate the entry for the medium in the array.
	; 
		call	MTLock		; *ds:di <- transport array
					; *ds:si <- media array
		push	di, si
		call	MTFindMedium
		jc	haveMedium

		call	MTAddMedium	; ax <- medium token

haveMedium:
	;
	; Now look for the transport + transOption in the transport array
	;
		pop	di, si
		push	ax
		movdw	cxdx, ss:[transport]
		mov	bx, ss:[transOption]
		call	MTFindTransport
		mov_tr	bx, ax
		pop	ax
		jnc	addIt		; => transport not known, so can't be
					;  in media element
	;
	; The transport + transOption has a record. See if it's mentioned in the
	; media element.
	; 
		push	ax		; save media # in case have to add
		call	ChunkArrayElementToPtr	; ds:di <- MTME
		mov_tr	ax, cx		; ax <- element size
		call	MTFindTransportInMediumEntry
		pop	ax		; ax <- media element #
		jc	done		; => already there, so we're happy

addIt:
	;
	; The media + transport pair is not yet in the map, so we must go fetch
	; the relevant particulars from the driver...
	; 
		push	bp
		movdw	cxdx, ss:[medium]
		mov	bx, ss:[transport].low
		mov	bp, ss:[transport].high
		xchg	ax, bp		; axbx <- transport
					; bp <- media element #
		; EC: if sendUpdate is TRUE, it means an update wasn't sent
		; when it should have been
		Assert	e, ds:[MTH_sendUpdate], FALSE
NEC <		mov	ds:[MTH_sendUpdate], FALSE			>
		call	MTCheckMediumCommon
		pop	bp
	; EC: something should have been added to the map, since the driver
	; has claimed that the address is for this medium, and we've determined
	; that the transport+media pair isn't already in the map but should be
EC <		Assert 	ne, ds:[MTH_sendUpdate], FALSE			>
		push	bp
		call	MTMaybeSendUpdate
		pop	bp
done:
		call	UtilVMUnlockDS
		.leave
		ret
MediaEnsureTransportInfo endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTCheckMediumCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to ask a transport driver if it supports a
		particular medium, and add it to a MediaTransportMediaElement
		if it does.

CALLED BY:	(INTERNAL) MTAddMediumCallback, MTNewTransportCallback
PASS:		axbx	= MailboxTransport
		ds	= media -> transport map block
		bp	= element number within media map to which to append
			  transport token # if driver supports the medium
		cxdx	= MediumType to check
RETURN:		ds	= fixed up, as necessary
		ds:[MTH_sendUpdate] = set if transport added to element
DESTROYED:	ax, bx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Load transport driver
	Loop over transport options
		If option supports medium
			call MTGetMediumParams
	Free transport driver

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTCheckMediumCommon proc	near
mediaEltNum	local	word			push bp
transport	local	MailboxTransport	push ax, bx
transOption	local	MailboxTransportOption
paramArgs	local	MBTDGetMediumParamsArgs
		uses	cx, dx, es
		.enter
	;
	; These are used in routines we call, which inherit our stack
	; frame.
	;
		ForceRef mediaEltNum			
		ForceRef transOption			
		ForceRef transport
		ForceRef paramArgs
	;
	; Fetch out the MailboxTransport token and attempt to load the driver
	; in the normal manner.
	; 
		pushdw	cxdx				;save MediumType
		movdw	cxdx, axbx
		call	MailboxLoadTransportDriver	;bx = handle of driver
							;ax is destroyed
		WARNING_C UNABLE_TO_LOAD_TRANSPORT_DRIVER_WHEN_ADDING_MEDIUM
		popdw	cxdx				;cxdx = MediumType
		jc	done

	;
	; The media->transport map has been changed keep track of 
	; which transport options are available for each medium, rather
	; than just which transport drivers are available.  Therefore, 
	; instead of calling DR_MBTD_CHECK_MEDIUM for each transport, 
	; we must now call it for every option of the transport, as 
	; indicated by DR_MBTD_GET_TRANSPORT_OPTIONS_INFO.
	;
		segmov	es, ds				;es = block of 
							;  media->transport map
		mov	ax, cx				;axdx = MediumType
		call	GeodeInfoDriver
		mov	di, DR_MBTD_GET_TRANSPORT_OPTIONS_INFO
		call	ds:[si].DIS_strategy		
	;
	; axdx = MediumType
	; cx = number of transport options for this driver
	; es = segment of media->transport map
	;
transOptionsLoop:
		xchg	ax, cx				;cxdx = MediumType
		mov	di, DR_MBTD_CHECK_MEDIUM
		dec	ax				;zero-based index
		call	MTCheckTransportAlreadyKnown
		jc	nextOption			; => transport already
							;  there, so don't
							;  bother with check
		call	ds:[si].DIS_strategy
		jnc	nextOption
		call	MTGetMediumParams			;es fixed up.
nextOption:
		inc	ax
		xchg	ax, cx				;cx = count
		loop	transOptionsLoop

		call	MailboxFreeDriver
		segmov	ds, es				;return ds fixed up.
done:
		.leave
		ret
MTCheckMediumCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTCheckTransportAlreadyKnown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed transport driver & transport option are
		already listed as supporting the medium. We'll usually
		get into such a situation when a transport driver is found
		via MediaEnsureTransportInfo, so the medium passed there
		already has the transport listed, but then we come along
		fielding the MSG_MP_NEW_TRANSPORT and do the work again

CALLED BY:	(INTERNAL) MTCheckMediumCommon
PASS:		cxdx	= MediumType
		ax	= MailboxTransportOption
		ds:si	= DriverInfoStruct of current transport driver
		es	= segment of media->transport map
RETURN:		carry set if transport already listed as supporting the medium
		carry clear if not
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 3/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTCheckTransportAlreadyKnown proc near
		uses	ds, si, ax, cx, dx, bx, di
		.enter	inherit	MTCheckMediumCommon
	;
	; First point to the two arrays, please
	; 
		segmov	ds, es
		call	MTGetMaps
	;
	; See if the transport + option are in the transport array. If not,
	; they can't be in the medium entry.
	; 
		movdw	cxdx, ss:[transport]	; cxdx <- transport
		mov	bx, ax			; bx <- transOption
		call	MTFindTransport		; ax <- token
		jnc	done
	;
	; Transport + option are there -- see if they're in the medium entry
	; 
		mov_tr	bx, ax
		mov	ax, ss:[mediaEltNum]
		call	ChunkArrayElementToPtr
		mov_tr	ax, cx
		call	MTFindTransportInMediumEntry	; CF <- set if there
done:
		.leave
		ret
MTCheckTransportAlreadyKnown endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTGetMediumParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Obtain the medium params for the transport driver and 
		option, updating the media->transport map.	

CALLED BY:	MTCheckMediumCommon
PASS:		cxdx	= MediumType
		ax	= MailboxTransportOption
		ds:si	= DriverInfoStruct of current transport driver.
		es	= segment of media->transport map
		ss:bp	= inherited frame (MTCheckMediumCommon)
RETURN:		es is fixed up if necessary.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get medium params (monikers, verb, sigAddrBytes) for the trans. option.
	Copy monikers and verb into the media->transport block.
	Find or add driver and option into transport elt. array in map.
	Add driver's token & other things to medium entry.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	8/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTGetMediumParams	proc	near
		uses	ax,bx,cx,dx,ds,si,di
		.enter	inherit MTCheckMediumCommon

	;
	; Get the medium params for this transport option.
	;
		movdw	ss:[paramArgs].MBTDGMPA_medium, cxdx
		mov	cx, ss
		lea	dx, paramArgs
		mov	di, DR_MBTD_GET_MEDIUM_PARAMS
		call	ds:[si].DIS_strategy
		jc	done
	;
	; Copy the monikers and verb into the medium->transport map block.
	; 
		mov	bx, ax				;bx = transport option
		segmov	ds, es				;ds = map segment
		call	MTCopyMonikerList		;ax = moniker list chunk
							;ds fixed up
		call	MTCopyVerb			;cx = verb chunk
							;ds fixed up
		call	MTCopyAbbrev			;si = abbrev chunk
							;ds fixed up
		push	ax				;save moniker chunk
		push	si				;save abbrev chunk
		push 	cx				;save verb chunk
		push	ss:[paramArgs].MBTDGMPA_significantAddrBytes	
							;save that too...
	;
	; Find or add the entry for the transpord driver and option in
	; the transport element array of the map.
	;
		call	MTGetMaps		;*ds:di = transport elt. array
						;*ds:si = media chunk array
		movdw	cxdx, ss:[transport]	;cx:dx = transport
		mov	ax, bx			;ax = transport option
		call	MTAddTransport		;ax = transport elt. number
						;ds fixed up.

	;
	; Add a new MediaTransportMediaRef to the end of the 
	; MediaTransportMediaElement of the medium, and fill out the MTMR,
	; linking it to the MediaTransportElement for which we have the
	; element number.
	;
		push	ax			;save trans. elt. number
		mov	ax, ss:[mediaEltNum]
		call	ChunkArrayElementToPtr	;cx = element size
					        ;ds:di = 
						;  MediaTransportMediaElement.
		mov	dx, cx			;save offset for initialization
		add	cx, size MediaTransportMediaRef
		call	ChunkArrayElementResize
		call	ChunkArrayElementToPtr	;ds:di = MTME, cx = size.
		add	di, dx			;ds:di = new MTMR

		pop	ds:[di].MTMR_transport	;element # for transport
						;  within transport array.
		pop	ds:[di].MTMR_sigAddrBytes
		pop	ds:[di].MTMR_verb
		pop	ds:[di].MTMR_abbrev
		pop	ds:[di].MTMR_monikers

	;
	; Mark the block dirty, finally.
	;
		call	UtilVMDirtyDS
		
	;
	; Set the flag indicating something was added.
	; 
		mov	ds:[MTH_sendUpdate], TRUE

	;
	; Return the fixed up value.
	;
		segmov	es, ds		

done:
		.leave
		ret
MTGetMediumParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTCopyMonikerList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy all the monikers in the moniker list returned by
		the transport driver into the media -> transport block

CALLED BY:	(INTERNAL) MTGetMediumParams
PASS:		ds	= map segment
RETURN:		ax	= chunk of moniker list
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTCopyMonikerList proc	near	
		uses	bx, cx, dx, si, di
		.enter 	inherit MTCheckMediumCommon
	;
	; First copy in the entire list chunk. It contains the optrs of the
	; other monikers that we'll copy in afterward.
	; 
		movdw	bxsi, ss:[paramArgs].MBTDGMPA_monikers
		call	UtilCopyChunk	; *ds:si <- copied chunk
	;
	; Figure the size of the list. During the loop, the registers are
	; like this:
	; 	cx	= size of the list chunk (invariant)
	; 	dx	= offset within the list chunk of the current entry
	;		  (because the chunk may move around with each copying
	;		  in of a moniker)
	;	*ds:si	= the list chunk
	;	ds:di	= the current entry (reestablished after each possible
	;		  motion of the list chunk)
	;
		ChunkSizeHandle	ds, si, cx
		clr	dx		; start with first entry, please
EC <		mov	di, ds:[si]					>
EC <		test	ds:[di].VMLE_type, mask VMLET_MONIKER_LIST	>
EC <		ERROR_Z	MONIKERS_RETURNED_BY_TRANSPORT_DRIVER_NOT_A_LIST>

monikerLoop:
	; EC: Make sure we've got a complete entry to look at
EC <		mov	ax, cx						>
EC <		sub	ax, dx						>
EC <		cmp	ax, size VisMonikerListEntry			>
EC <		ERROR_B	INVALID_MONIKER_LIST				>
	;
	; Fetch the optr of this moniker out of the entry.
	; 
		mov	di, ds:[si]
		add	di, dx
		push	si
		movdw	bxsi, ds:[di].VMLE_moniker
	;
	; Make a copy of the moniker, please.
	; 
		call	UtilCopyChunk
		mov_tr	ax, si		; ax <- moniker chunk
		pop	si
	;
	; Replace the chunk portion for the current moniker with the handle
	; of the duplicate. We leave the handle portion as garbage, since this
	; moniker list can't actually be used in situ (it's in a VM block in
	; a non-single-thread VM file...)
	; 
		mov	di, ds:[si]
		add	di, dx
		mov	ds:[di].VMLE_moniker.chunk, ax
	;
	; Advance to the next entry, please.
	; 
		add	dx, size VisMonikerListEntry
		cmp	dx, cx
		jne	monikerLoop
		
		mov_tr	ax, si		; ax <- list chunk
		.leave
		ret
MTCopyMonikerList endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTCopyVerb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the returned verb into the media -> transport block

CALLED BY:	(INTERNAL) MTCheckMediumCommon
PASS:		ds	= media -> transport map segment
RETURN:		ds	= fixed up
		cx	= chunk of verb string
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTCopyVerb	proc	near	
		uses	bx, si
		.enter 	inherit	MTCheckMediumCommon
		movdw	bxsi, ss:[paramArgs].MBTDGMPA_verb
		call	UtilCopyChunk		;ds fixed up
		mov	cx, si
		.leave
		ret
MTCopyVerb	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTCopyAbbrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the returned abbreviation into the media -> transport
		block

CALLED BY:	(INTERNAL) MTCheckMediumCommon
PASS:		ds	= media -> transport map segment
RETURN:		ds	= fixed up
		si	= chunk of verb string
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTCopyAbbrev	proc	near
	uses	bx
	.enter 	inherit	MTCheckMediumCommon

	movdw	bxsi, ss:[paramArgs].MBTDGMPA_abbrev
	call	UtilCopyChunk		; *ds:si = duplicate

	.leave
	ret
MTCopyAbbrev	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTAddTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the token for a transport driver, adding it to the
		element array if it's not there.

CALLED BY:	(INTERNAL) MTGetMediumParams
PASS:		*ds:di	= transport driver element array
		cxdx	= MailboxTransport
		ax	= MailboxTransportOption
RETURN:		ds	= fixed up
		es	= *DESTROYED* if pointing to DS on entry
		ax	= transport element token
		VM block is *NOT* marked dirty, as caller will do it for us.
DESTROYED:	nothing
SIDE EFFECTS:	block & chunks may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTAddTransport	proc	near
formats		local	word			push ax 	; JUNK
transOption	local	MailboxTransportOption	push ax
transDriver	local	MailboxTransport	push cx, dx
refHeader	local	RefElementHeader
		uses	si, cx, dx, bx
		.enter
CheckHack <size refHeader+size transDriver+size transOption+size formats eq \
						size MediaTransportElement>
CheckHack <offset formats - offset refHeader eq offset MTE_formats>
CheckHack <offset transOption - offset refHeader eq offset MTE_transOption>
CheckHack <offset transDriver - offset refHeader eq offset MTE_transport>

	;
	; Referred to by ElementArrayAddElement because they follow
	; refHeader.
	;
		ForceRef	transDriver	
		ForceRef	transOption
	;
	; Add transport and option to the element array.
	;
		mov	ss:[formats], 0		; initialize to 0
		mov	si, di			;*ds:si = trans elt array
		mov	bx, SEGMENT_CS
		mov	di, offset MTAddTransportCompare
		mov	cx, ss
		lea	dx, ss:[refHeader]	;cx:dx <- element
		call	ElementArrayAddElement	;ax = element number
		push	ax
		jnc	done			;not new

	;
	; Fetch the driver's capabilities and merge them in, since we know
	; this thing's going to be added to a medium's entry in a minute,
	; making it "available".
	; 
		movdw	cxdx, ss:[transDriver]
		call	AdminGetTransportDriverMap	;ax = map handle
		call	DMapGetAttributes		;ax = attributes
EC <		ERROR_C HOW_CAN_TRANSPORT_DRIVER_BE_INVALID?		>
		pop	cx				; cx <- element #
		push	cx
		call	MTGetFormatsIfNecessary
		mov	cx, ds:[MTH_allCaps]
		or	ax, cx
		mov	ds:[MTH_allCaps], ax
if 	_CONTROL_PANELS
		xor	cx, ax				;cx = bits that changed
		jz	done				;nothing changed.
	;
	; Available capabilities has changed.  
	;
		test	cx, mask MBTC_MESSAGE_RETRIEVE
		jz	checkNewPoof
		mov	ax, MSG_ICP_MESSAGE_RETRIEVAL_NOW_POSSIBLE
		mov	dx, TO_SYSTEM_INBOX_PANEL
		call	MTNotifySystemPanel
checkNewPoof:
		test	cx, mask MBTC_CAN_SEND_QUICK_MESSAGE or \
			    mask MBTC_CAN_SEND_FILE or \
			    mask MBTC_CAN_SEND_CLIPBOARD
		jz	done
		mov	ax, MSG_OCP_NEW_POOF_MESSAGE_POSSIBLE
		mov	dx, TO_SYSTEM_OUTBOX_PANEL
		call	MTNotifySystemPanel
endif	; _CONTROL_PANELS
done:
		pop	ax				;ax = elt. number of
							;  transport in the
							;  transport array.
		.leave
		ret
MTAddTransport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTAddTransportCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to compare two elements when adding one
		to the MediaTransport array.

CALLED BY:	(INTERNAL) MTAddTransport via ElementArrayAdd
PASS:		ds:si	= element 1
		es:di	= element 2
		cx	= element size
		ax	= value passed to ElementArrayAdd in bp
RETURN:		carry set if elements equal
DESTROYED:	ax, bx, cx, dx allowed (cx destroyed here)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTAddTransportCompare proc	far
		uses	si, di
		.enter
	;
	; Compare just the transport and transport option
	;
		CheckHack <MTE_transOption eq MTE_transport+size MTE_transport>
		add	si, offset MTE_transport
		add	di, offset MTE_transport
		mov	cx, (size MTE_transport + size MTE_transOption)/2
		repe	cmpsw
		cmc			; assume equal (carry currently clear)
		je	done
		clc
done:
		.leave
		ret
MTAddTransportCompare endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTNotifySystemPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send some notification to a system panel, owing to a
		new transport with new capabilities becoming available

CALLED BY:	(INTERNAL) MTAddTransport
PASS:		ax	= message to send to panel
		dx	= TravelOption to use to get it there
		cx	= new MailboxTransportCapabilities
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		message is queued so if transport discovered on mailbox
			thread, update doesn't happen before data
			structure is ready for it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_CONTROL_PANELS
MTNotifySystemPanel proc near
		uses	bx, si, di, cx
		.enter
	;
	; Record the message for the panel.
	; 
		clr	bx, si		; any class will do
		mov	di, mask MF_RECORD
		call	ObjMessage
	;
	; Now ask the MailboxApp to send it there.
	; 
		mov	cx, di		; cx <- recorded message
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		clr	di
		call	UtilForceQueueMailboxApp
		.leave
		ret
MTNotifySystemPanel endp
endif	; _CONTROL_PANELS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTGetFormatsIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the driver is marked as picky, fetch the list of formats
		it supports.

CALLED BY:	(INTERNAL) MTAddTransport
PASS:		*ds:si	= MediaTransport array
		ax	= MailboxTransportCapabilities
		cx	= element # of transport driver in array
		ss:bp	= inherited frame
RETURN:		ds	= fixed up
DESTROYED:	cx, es if == ds on entry
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTGetFormatsIfNecessary proc	near
		uses	ax, bx, dx, di
		.enter	inherit	MTAddTransport
		test	ax, mask MBTC_PICKY
		jz	done
		
	;
	; Load the transport driver into memory so we can talk to it.
	;
		push	es, cx, si	; save element # & array for setting
					;  MTE_formats

		movdw	cxdx, ss:[transDriver]
		call	MailboxLoadTransportDriver
		jc	fail
	;
	; Point es:si to its DriverInfoStruct for calling the strategy routine
	;
		push	ds
		call	GeodeInfoDriver
		segmov	es, ds
		pop	ds
	;
	; Give it a zero-sized buffer and ask it for its formats. It will tell
	; us how many formats it has without copying anything out.
	;
		clr	ax
EC <		mov	cx, ds						>
EC <		mov	dx, ax	; so cx:dx pointer is valid...		>
		mov	di, DR_MBTD_ESC_GET_FORMATS
		call	es:[si].DIS_strategy		; ax <- # formats
		jc	unloadFail
	;
	; Allocate a chunk to hold that many formats.
	;
			CheckHack <size MailboxDataFormat eq 4>
		push	ax				; save # formats for 
							;  next call
		shl	ax
		shl	ax
		mov_tr	cx, ax				; cx <- chunk size
		clr	ax				; ax <- no special flags
		call	LMemAlloc
		mov_tr	di, ax
	;
	; Call the driver again, passing the buffer we just allocated.
	;
		pop	ax				; ax <- # formats
		push	di
		mov	cx, ds
		mov	dx, ds:[di]			; cx:dx <- buffer
		mov	di, DR_MBTD_ESC_GET_FORMATS
		call	es:[si].DIS_strategy
	;
	; Unload the driver.
	;
		call	MailboxFreeDriver
	;
	; Store the chunk handle in the MTE_formats field for the transport.
	;
		pop	ax				; ax <- buffer chunk
		pop	es, cx, si			; cx <- element #
							; *ds:si <- MT array
		xchg	ax, cx
		call	ChunkArrayElementToPtr
		mov	ds:[di].MTE_formats, cx
done:
		.leave
		ret

unloadFail:
		call	MailboxFreeDriver
fail:
		pop	es, cx, si
EC <		WARNING	FAILED_TO_GET_FORMATS_FROM_PICKY_DRIVER		>
   		jmp	done
MTGetFormatsIfNecessary endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaNewTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a new transport driver has been discovered

CALLED BY:	(EXTERNAL) DMap module
PASS:		ds:si	= driver name
		cxdx	= MailboxTransport
		ax	= dmap
		current dir is driver directory
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We queue a message to our process so we can ensure that we
		always get the media -> transport map before trying for
		the transport driver map (when we're called, the thread
		on which we're operating has the transport driver map grabbed,
		which means we can't go for the media -> transport map here,
		lest there be deadlock).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaNewTransport proc	far
		uses	bx, di, ax
		.enter
		push	ax
		mov	bx, handle 0
		mov	ax, MSG_MP_NEW_TRANSPORT
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	ax			; ax <- transport dmap
	;
	; Register a callback to happen when the thing is first loaded so we
	; can send it the proper escape to tell it it's being loaded for the
	; first time.
	;
		movdw	sidi, cxdx		; sidi <- token
		mov	bx, enum MTNotifyFirstLoad
		call	DMapRegisterLoadCallback
		.leave
		ret
MediaNewTransport endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTNotifyFirstLoad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the transport driver know it's being loaded for the first
		time.

CALLED BY:	(EXTERNAL) DMap module
PASS:		bx	= driver handle
RETURN:		carry clear if callback may be deleted
		carry set if callback should be made on next load
DESTROYED:	cx, dx allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTNotifyFirstLoad proc	far
		uses	ds, si, di
		.enter
		call	GeodeInfoDriver
		mov	di, DR_MBTD_ESC_FIRST_TIME_LOADED
		call	ds:[si].DIS_strategy
		clc
		.leave
		ret
MTNotifyFirstLoad endp
		public	MTNotifyFirstLoad


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTNewTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cope with a new transport driver being added to the transport
		driver map, asking it about all the media we've encountered
		so far.

CALLED BY:	MSG_MP_NEW_TRANSPORT
PASS:		cxdx	= MailboxTransport
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
		bx, si, di, ds (preserved by kernel)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTNewTransport	method extern MailboxProcessClass, 
				MSG_MP_NEW_TRANSPORT
		.enter
	;
	; Run through the all the media and ask the transport driver for each
	; of its options whether it supports the medium. The callback will
	; take care of detecting if the transport driver was discovered through
	; some other means before we could handle this message.
	; 
		call	MTLock
		mov	si, ds:[LMBH_offset]	; *ds:si <- media map
		mov	bx, cs			; bx:di <- callback routine
		mov	di, offset MTNewTransportCallback

		; EC: if sendUpdate is TRUE, it means an update wasn't sent
		; when it should have been
		Assert	e, ds:[MTH_sendUpdate], FALSE
NEC <		mov	ds:[MTH_sendUpdate], FALSE			>

		call	ChunkArrayEnum

		call	MTMaybeSendUpdate

		call	UtilVMUnlockDS
		.leave
		ret
MTNewTransport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTMaybeSendUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If something got added to the media -> transport map, send
		out notification to update any transport lists.

CALLED BY:	(INTERNAL) MTNewTransport, MTAddMedium
PASS:		ds	= segment of media -> transport map
RETURN:		nothing
DESTROYED:	ax, bx, si, di, dx, bp
SIDE EFFECTS:	notification is force-queued to mb app

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 3/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTMaybeSendUpdate proc	near
		.enter
		tst	ds:[MTH_sendUpdate]
		jz	done

EC <		mov	ds:[MTH_sendUpdate], FALSE			>
	;
	; Record message for everyone interested.
	; 
		mov	ax, MSG_MB_NOTIFY_NEW_TRANSPORT
		clr	bx, si			; ^lbx:si <- no destination
		mov	di, mask MF_RECORD
		call	ObjMessage		; di <- event
	;
	; Set up the parameters for the send.
	; 
		mov	dx, size GCNListMessageParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].GCNLMP_event, di
		mov	ss:[bp].GCNLMP_flags, 0	; not status, no force-queue
						;  needed
		mov	ss:[bp].GCNLMP_block, 0	; no mem block in params
		mov	ss:[bp].GCNLMP_ID.GCNLT_manuf,
				MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLMP_ID.GCNLT_type, 
				MGCNLT_NEW_TRANSPORT
	;
	; Do it, babe.
	; 
		mov	di, mask MF_STACK
		mov	ax, MSG_META_GCN_LIST_SEND
		call	UtilForceQueueMailboxApp
		add	sp, size GCNListMessageParams
done:
		.leave
		ret
MTMaybeSendUpdate endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTFindTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a transport's reference token -- this is the 
		index of the MediaTransportElement for the transport
		in the transport array of the media -> transport map.
		If the transport is not in the map, then it is not
		found.  The driver directory is *not* rescanned, even
		if DMF_DRIVER_DIR_CHANGED is set.

CALLED BY:	(INTERNAL) MTNewTransport, MTGetMediaTransportWord
PASS:		*ds:di	= transport array
		cxdx	= MailboxTransport
		bx	= MailboxTransportOption.  
			If bx = MAILBOX_ANY_TRANSPORT_OPTION, then the 
			first reference found (if any) with a matching 
			MailboxTransport is returned, regardless of its
			MailboxTransportOption.
RETURN:		carry set if found:
			ax	= reference token
		carry clear if not found:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTFindTransport	proc	near
		uses	bx, si, di, bp
		.enter
		mov	bp, bx			; bp = MailboxTransportOption
		mov	si, di			; *ds:si <- array
		mov	bx, cs
		mov	di, offset MTFindTransportCallback
		clr	ax
		call	ChunkArrayEnum		; ax <- token #, if driver found
		.leave
		ret
MTFindTransport	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTFindTransportCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to find a particular transport in the
		element array.

CALLED BY:	(INTERNAL) MTFindTransport via ChunkArrayEnum
PASS:		ds:di	= MediaTransportElement
		ax	= index of current element
		bp	= MailboxTransportOption
		cxdx	= MailboxTransport we're seeking
RETURN:		carry set to stop enumerating (found transport):
			ax	= index of found element
		carry clear to keep looking:
			ax	= index of next element
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTFindTransportCallback	proc	far
		.enter
		inc	ax		; assume no match
		cmp	ds:[di].MTE_meta.REH_refCount.WAAH_high,
				EA_FREE_ELEMENT
		je	done		; (carry clear: keep looking)
		cmpdw	ds:[di].MTE_transport, cxdx
		clc
		jne	done
	;
	; should we skip transOption comparison?
	;
		cmp	bp, MAILBOX_ANY_TRANSPORT_OPTION		
		je	done
		cmp	ds:[di].MTE_transOption, bp
		clc
		jne	done
		dec	ax		; point back to this elt
		stc			;  and stop enumerating
done:
		.leave
		ret
MTFindTransportCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTNewTransportCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to ask a particular transport driver
		whether it supports a transport medium

CALLED BY:	(INTERNAL) MTNewTransport via ChunkArrayEnum,
			   MTNewTransportFilteredCallback
PASS:		*ds:si	= media array
		ds:di	= MediaTransportMediaElement
		ax	= size of the element
		cxdx	= MailboxTransport
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	bx, si, di allowed, ax
SIDE EFFECTS:	transport may be appended to element

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTNewTransportCallback proc	far
		uses	bp, cx, dx
		.enter
		call	ChunkArrayPtrToElement
		mov_tr	bp, ax				; bp <- elt num
		movdw	axbx, cxdx			; axbx <- transport
		movdw	cxdx, ds:[di].MTME_medium	; cxdx <- medium to
							;  check
		call	MTCheckMediumCommon
		clc
		.leave
		ret
MTNewTransportCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTFindTransportInMediumEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a transport+transOption reference in the entry for
		a particular medium

CALLED BY:	(INTERNAL) MTCheckTransportAlreadyKnown
			   MediaEnsureTransportInfo
PASS:		ds:di	= MediaTransportMediaElement to check
		ax	= size of the element
		bx	= transport driver token # for which to check
RETURN:		carry set if driver found
		carry clear if not found
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTFindTransportInMediumEntry proc	near
		uses	di, ax
		.enter
	;
	; First make sure the transport driver isn't already known to support
	; the medium.
	; 
		add	ax, di		; ax <- end of the chunk
		dec	ax		; so we can jb and have NZ...
		add	di, offset MTME_transports

checkTransport:
		cmp	ax, di
		jb	checkDone
		cmp	ds:[di].MTMR_transport, bx
		je	checkDone
		add	di, size MediaTransportMediaRef
		jmp	checkTransport
checkDone:
		stc
		jz	done
		clc
done:
		.leave
		ret
MTFindTransportInMediumEntry		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTCreateMTResultArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a chunk array to hold MailboxTransport tokens

CALLED BY:	(INTERNAL) MediaGetTransports
PASS:		ds	= block in which to allocate
RETURN:		*es:bp	= allocated array
		ds	= fixed up
DESTROYED:	ax, si, bx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTCreateMTResultArray proc	near
		uses	cx
		.enter
		mov	bx, size MailboxTransportAndOption
		clr	cx, si, ax
		call	ChunkArrayCreate
		mov	bp, si
		segmov	es, ds		; *es:bp <- result array, for callback
		.leave
		ret
MTCreateMTResultArray endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaGetTransports
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the list of transport drivers that can work with
		a particular transport medium.

CALLED BY:	(EXTERNAL) ONEnumTransports 
PASS:		cxdx	= MediumType
		ds	= locked lmem block
RETURN:		*ds:ax	= chunk array of MailboxTransportAndOption, for 
			  drivers that support the medium
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaGetTransports proc	far
		uses	es, si, di, bx, bp
		.enter
	;
	; First off, create the result array.
	; 
		call	MTCreateMTResultArray	; *es:bp <- array
	;
	; Now lock down the media -> transport map
	; 
		call	MTLock
	;
	; Find the requested medium and get its supporting transport drivers.
	; 
		mov	bx, cs
		mov	di, offset MTGetTransportsCallback
		call	ChunkArrayEnum
	;
	; Release the media -> transport map.
	; 
		call	UtilVMUnlockDS
	;
	; Return the result array in *ds:ax
	; 
		segmov	ds, es
		mov_tr	ax, bp
		.leave
		ret
MediaGetTransports endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTGetTransportsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to first find the indicated medium, then
		to store the MailboxTransport tokens of the transport drivers
		that support the medium in the passed array.

CALLED BY:	(INTERNAL) MediaGetTransports via ChunkArrayEnum
PASS:		*ds:si	= media array
		ds:di	= MediaTransportMediaElement to check
		cxdx	= MediumType being sought
		*es:bp	= result array for when medium is found
		ax	= size of this element
RETURN:		carry set to stop enumerating (found medium)
DESTROYED:	ax, bx, si, di
SIDE EFFECTS:	things may be added to the result array, ya know

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTGetTransportsCallback proc	far
		uses	dx
		.enter
		cmpdw	ds:[di].MTME_medium, cxdx
		clc
		jne	done

	;
	; Point to the array of transport indices and figure how many there are
	; for this medium.
	; 
		push	cx
		add	di, offset MTME_transports
		sub	ax, offset MTME_transports
		clr	dx		; dxax = size of this elt
		mov	cx, size MediaTransportMediaRef
		div	cx		; ax = # MediaTransportMediaElement's
		Assert	e, dx, 0
		mov_tr	cx, ax
	;
	; Fetch the handle of the transport element array.
	; 
		push	di
		call	MTGetMaps
		pop	si		; ds:si <- index array
		jcxz	haveTransports
transportLoop:
	;
	; ds:si = next index to fetch
	; *ds:di = transport element array
	; *es:bp = result array
	; cx = # indices left to process.
	; 
	; First, point to the MediaTransportElement for the next driver that
	; supports the medium.
	; 
			CheckHack <MTMR_transport eq 0>
		lodsw			; ax <- next index
		push	si		; save offset of next index
		mov	si, di		; *ds:si <- transport elt array
		call	ChunkArrayElementToPtr
	;
	; Fetch the transport token out.
	; 
		movdw	axbx, ds:[di].MTE_transport
		push	ds:[di].MTE_transOption
	
	;
	; Now append an element to the result array.
	; 
		segxchg	ds, es
		xchg	si, bp
		call	ChunkArrayAppend
	;
	; And store the transport token in the new element.
	; 
		movdw	ds:[di].MTAO_transport, axbx
		pop	ds:[di].MTAO_transOption
		
	;
	; Restore loop registers.
	; 
		segxchg	ds, es
		xchg	si, bp

		mov	di, si		; *ds:di <- transport elt array
		pop	si		; ds:si <- next index
		add	si, MediaTransportMediaRef - size MTMR_transport
		loop	transportLoop
haveTransports:
		pop	cx
		stc			; => all done enumerating
done:
		.leave
		ret
MTGetTransportsCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaGetTransportMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the moniker for a particular transport+medium pair.

CALLED BY:	(EXTERNAL)
PASS:		ds	= locked lmem block (run by current thread, of course)
		ss:bp	= MediaGetTransportMonikerArgs
RETURN:		carry set if transport+medium combination is invalid
			ax	= destroyed
		carry clear if ok
			*ds:ax	= chunk holding selected moniker
DESTROYED:	es, if pointing to ds on entry
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaGetTransportMoniker proc	far
		uses	bx, di, si, es, cx, dx
		.enter

		push	bp
		segmov	es, ds
		movdw	axbx, ss:[bp].MGTMA_transport
		movdw	cxdx, ss:[bp].MGTMA_medium
		mov	si, ss:[bp].MGTMA_transOption
		mov	bp, offset MTMR_monikers
		call	MTGetMediaTransportWord; *ds:si <- chunk
		pop	bp
		jc	done
		
	;
	; Make sure the search flags perform the proper operation: copying the
	; chosen moniker into the destination block, not replacing the moniker
	; list (we need the moniker list intact for later calls, you know).
	; 
		mov	cx, ss:[bp].MGTMA_searchFlags
		andnf	cx, not mask VMSF_REPLACE_LIST
		mov	dh, ss:[bp].MGTMA_displayType
		call	MTGetOneMoniker
done:
	;
	; Release the media -> transport map and return result.
	; 
		call	UtilVMUnlockDS
		segmov	ds, es			; ds <- fixed up dest block
		.leave
		ret
MediaGetTransportMoniker endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTGetOneMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the appropriate moniker out of the moniker list for a
		transport.

CALLED BY:	(INTERNAL) MediaGetTransportMoniker
PASS:		*ds:si	= moniker list for media+transport
		es	= dest block
		cx	= VisMonikerSearchFlags
		dh	= DisplayType
RETURN:		*es:ax	= moniker
DESTROYED:	nothing
SIDE EFFECTS:	moniker chunk is copied into es, possibly causing the block
     			to move.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTGetOneMoniker proc	near
		uses	ds, di, bx, cx, bp, dx, si
		.enter
EC <		test	cx, mask VMSF_COPY_CHUNK			>
EC <		ERROR_NZ SEARCH_FLAGS_CORRUPTED				>
EC <		test	cx, mask VMSF_REPLACE_LIST			>
EC <		ERROR_NZ SEARCH_FLAGS_CORRUPTED				>
	;
	; First we need to point the handles in the moniker list to the
	; map block, so VisFindMoniker can copy the thing out. We don't
	; mark the block dirty as the block remains locked for the duration
	; and we don't care if the new handles get written out, as we'll be
	; overwriting them next time we need to do this anyway...
	; 
		mov	bp, cx			; bp <- search flags (for
						;  VisFindMoniker)
		mov	di, ds:[si]
		ChunkSizePtr	ds, di, cx	; cx <- list size
		mov	ax, ds:[LMBH_handle]	; ax <- handle to store
setHandleLoop:
		mov	ds:[di].VMLE_moniker.handle, ax
		add	di, size VisMonikerListEntry
		sub	cx, size VisMonikerListEntry
		jnz	setHandleLoop
	;
	; Now find and copy out the moniker. Can't use VMSF_COPY_CHUNK as that
	; will lock & unlock the source moniker block, which we've got locked
	; with VMLock. These two things do not mix (THREAD_RELEASE_NOT_OWNER
	; death results).
	; 
		mov	di, si			; *ds:di <- moniker list
		mov	bh, dh			; bh <- DisplayType
		call	VisFindMoniker		; dx <- moniker chunk
		
		mov	si, dx			; *ds:si <- moniker
		ChunkSizeHandle ds, si, cx	; cx <- # bytes in same
		push	ds
		segmov	ds, es
		mov	al, mask OCF_DIRTY
		call	LMemAlloc		; *ds:ax <- new copy of moniker
		mov	di, ax
		mov	di, ds:[di]		; es:di <- new moniker
		pop	ds
		mov	si, ds:[si]		; ds:si <- orig moniker
		rep	movsb
		.leave
		ret
MTGetOneMoniker endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaGetTransportString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the string for a medium/transport combination. The
		string is extracted from a text moniker, with a VMS_TEXT
		moniker the preferred one.

CALLED BY:	(EXTERNAL) OCPMcpSetCriteria
PASS:		ds	= locked lmem block
		axbx	= MailboxTransport
		cxdx	= MediumType
		si	= MailboxTransportOption
RETURN:		carry set if combination is invalid
			ax	= destroyed
		carry clear if ok
			*ds:ax	= text chunk holding the string
DESTROYED:	nothing
SIDE EFFECTS:	ds, and chunks in it, may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaGetTransportString proc	far
		uses	es, bx, si, di, bp, cx
		.enter
	;
	; First locate the moniker list, if there is one.
	; 
		segmov	es, ds			; save dest seg
		mov	bp, offset MTMR_monikers
		call	MTGetMediaTransportWord; *ds:si <- moniker list
		jc	done
	;
	; Have the moniker list. Now find a VMS_TEXT text one, if possible.
	; 
		mov	di, ds:[si]
		ChunkSizePtr	ds, di, bx
		add	bx, di
findTextStyleLoop:
		mov	ax, ds:[di].VMLE_type
		andnf	ax, mask VMLET_STYLE or mask VMLET_GSTRING
			CheckHack <offset VMLET_STYLE ge 8>
			CheckHack <offset VMLET_GSTRING lt 8>
		cmp	ah, VMS_TEXT shl (offset VMLET_STYLE-8)
		jne	nextTextStyleLoop
		test	al, mask VMLET_GSTRING
		jz	found
nextTextStyleLoop:
		add	di, size VisMonikerListEntry
		cmp	di, bx
		jb	findTextStyleLoop
EC <		ERROR_A	INVALID_MONIKER_LIST				>
   	;
	; Didn't find a VMS_TEXT text moniker, so look for any text moniker.
	; 
		mov	di, ds:[si]
findTextLoop:
		test	ds:[di].VMLE_type, mask VMLET_GSTRING
		jz	found
		add	di, size VisMonikerListEntry
		cmp	di, bx
		jb	findTextLoop
		stc
		jmp	done
found:
	;
	; ds:di is the VisMonikerListEntry of the moniker from which to extract
	; the string. Figure out how big the string is from the size of the
	; moniker chunk.
	; 
		mov	si, ds:[di].VMLE_moniker.chunk
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx
		sub	cx, offset VMT_text + offset VM_data
		add	si, offset VMT_text + offset VM_data
	;
	; Allocate a chunk that big in ES
	; 
		push	ds
		segmov	ds, es
		mov	al, mask OCF_DIRTY
		call	LMemAlloc
	;
	; Deref the new chunk, and move the data from the map block to the
	; dest block.
	; 
		mov	di, ax
		mov	di, ds:[di]
		pop	ds
		rep	movsb
	;
	; Signal happiness.
	; 
		clc
done:
		call	UtilVMUnlockDS
		segmov	ds, es
		.leave
		ret
MediaGetTransportString endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTGetMediaTransportWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract a word from the MediaTransportMediaRef for a
		transport/medium combination

CALLED BY:	(INTERNAL) MediaGetTransportString, MediaGetTransportVerb
PASS:		axbx	= MailboxTransport
		cxdx	= MediumType
		si	= MailboxTransportOption
		bp	= offset within MediaTransportMediaRef where the
			  desired word is stored
RETURN:		carry set if combination invalid
			ds	= media -> transport map
			si	= destroyed
		carry clear if ok:
			si	= desired word
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTGetMediaTransportWord proc	near
wordOff		local	word	push bp
transOption	local	word	push si
transToken	local	word
	ForceRef	wordOff	; MTGetMediaTransportWordCallback
		uses	di
		.enter
EC <		cmp	ss:[wordOff], size MediaTransportMediaRef	>
EC <		ERROR_AE	INVALID_MTMR_OFFSET			>
	;
	; First find the reference token for the transport driver. If there
	; is none, then the medium can't possibly be used by the transport, so
	; there's nothing to return.
	; 
		call	MTLock
		pushdw	cxdx
		movdw	cxdx, axbx
		mov	bx, transOption
		call	MTFindTransport
		jnc	noTransport
	;
	; Now find the medium itself, and let the callback extract the chunk
	; we need.
	; 
		popdw	cxdx
		mov	ss:[transToken], ax
		mov	bx, cs
		mov	di, offset MTGetMediaTransportWordCallback
		call	ChunkArrayEnum
		mov_tr	si, ax
done:
		cmc
		.leave
		ret
noTransport:
		popdw	cxdx
		jmp	done
MTGetMediaTransportWord endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTGetMediaTransportWordCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate the MediaTransportMediaElement
		for a medium, then fetch the requested word out of the
		MediaTransportMediaRef structure for the desired transport

CALLED BY:	(INTERNAL) MTGetMediaTransportWord via ChunkArrayEnum
PASS:		ds:di	= MediaTransportMediaElement
		cxdx	= MediumType
		ax	= element size
		ss:bp	= inherited local vars (from MTGetMediaTransportWord)
RETURN:		carry set if found:
			ax	= desired word
		carry clear if not found:
			ax	= destroyed
DESTROYED:	bx, si, di allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTGetMediaTransportWordCallback proc	far
		.enter	inherit MTGetMediaTransportWord
	;
	; See if the entry is for the right medium.
	; 
		cmpdw	ds:[di].MTME_medium, cxdx
		clc				; assume not
		jne	done			; assumption was correct
	;
	; Found the entry. Loop through all the transports looking for the one
	; with the right token.
	; 
		add	di, offset MTME_transports - size MediaTransportMediaRef
		sub	ax, offset MTME_transports - size MediaTransportMediaRef
		mov	bx, ss:[transToken]
transLoop:
	;
	; Advance to the next entry in the array. If none left, we didn't
	; find it (obviously). The side-effect of returning carry clear here
	; is that the search will continue through later entries in the
	; chunk array, even though we know there isn't another one with the
	; right medium. The caller's been a boob, anyway, and deserves to wait.
	; 
		add	di, size MediaTransportMediaRef
		sub	ax, size MediaTransportMediaRef
		jz	done			; (carry clear)

	; EC: we're assuming there won't be more than 32K in the transport array
	; for a particular medium. this seems a valid assumption...
EC <		ERROR_S	INVALID_MEDIUM_TRANSPORT_ARRAY			>

		cmp	ds:[di].MTMR_transport, bx
		jne	transLoop
	;
	; Found the entry, so extract the chunk from the proper place within it.
	; 
		mov	bx, ss:[wordOff]
		mov	ax, ds:[di][bx]
		stc			; stop enumerating
done:
		.leave
		ret
MTGetMediaTransportWordCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaGetTransportVerb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the text string for the verb that indicates a message
		is being sent through a medium via a transport driver

CALLED BY:	(EXTERNAL)
PASS:		ds	= locked lmem block
		axbx	= MailboxTransport
		cxdx	= MediumType
		si	= MailboxTransportOption
RETURN:		carry set if combination is invalid
			ax	= destroyed
		carry clear if ok
			*ds:ax	= text chunk holding the string
DESTROYED:	nothing
SIDE EFFECTS:	ds, and chunks in it, may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/ 3/95    	Initial version to use common routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaGetTransportVerb	proc	far

	push	bp
	mov	bp, offset MTMR_verb
	FALL_THRU MTGetStringChunkCommon, bp

MediaGetTransportVerb	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTGetStringChunkCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to return a string for a media/transport.

CALLED BY:	(INTERNAL) MeidaGetTransportVerb, MediaGetTransportAbbrev
PASS:		ds	= locked lmem block
		axbx	= MailboxTransport
		cxdx	= MediumType
		si	= MailboxTransportOption
		bp	= offset within MediaTransportMediaRef where the
			  lptr of the desired string is stored
RETURN:		carry set if combination is invalid
			ax	= destroyed
		carry clear if ok
			*ds:ax	= text chunk holding the string
DESTROYED:	nothing
SIDE EFFECTS:	ds, and chunks in it, may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/27/94		Initial version (MediaGetTransportVerb)
	AY	4/ 3/95		Renamed to be a common routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTGetStringChunkCommon	proc	far
		uses	es, bx, si, di, cx
		.enter
	;
	; First locate the chunk, if there is one.
	; 
		segmov	es, ds			; save dest seg
		call	MTGetMediaTransportWord; *ds:si <- chunk
		jc	done
	;
	; Figure how big the text chunk is.
	; 
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx
	;
	; Allocate a chunk that big in ES
	; 
		push	ds
		segmov	ds, es
		mov	al, mask OCF_DIRTY
		call	LMemAlloc
	;
	; Deref the new chunk, and move the data from the map block to the
	; dest block.
	; 
		mov	di, ax
		mov	di, ds:[di]
		pop	ds
		rep	movsb
	;
	; Signal happiness.
	; 
		clc
done:
		call	UtilVMUnlockDS
		segmov	ds, es
		.leave
		FALL_THRU_POP	bp
		ret
MTGetStringChunkCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaGetTransportAbbrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the text string for the abbreviation that indicates
		a message is being sent through a medium via a transport
		driver.

CALLED BY:	(EXTERNAL)
PASS:		ds	= locked lmem block
		axbx	= MailboxTransport
		cxdx	= MediumType
		si	= MailboxTransportOption
RETURN:		carry set if combination is invalid
			ax	= destroyed
		carry clear if ok
			*ds:ax	= text chunk holding the string
DESTROYED:	nothing
SIDE EFFECTS:	ds, and chunks in it, may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaGetTransportSigAddrBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the number of bytes in an address for this medium /
		transport pair that are considered significant when comparing
		to another address for this pair. If an address has fewer than
		this many bytes, it and a longer address should be considered
		equal if the entire shorter address matches the equivalent
		bytes of the longer.

CALLED BY:	(EXTERNAL)
PASS:		axbx	= MailboxTransport
		si	= MailboxTransportOption
		cxdx	= MediumType
RETURN:		carry set if combination is invalid
			ax	= destroyed
		carry clear if ok
			ax	= # significant bytes
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaGetTransportSigAddrBytes proc	far
		uses	ds, si, bp, bx
		.enter
		mov	bp, offset MTMR_sigAddrBytes
		call	MTGetMediaTransportWord; si <- # bytes
		mov_tr	ax, si
		call	UtilVMUnlockDS
		.leave
		ret
MediaGetTransportSigAddrBytes endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaGetAllTransports
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the list of available transports, where a transport 
		is considered available if a medium it uses has ever been 
		available to the machine.

		Used to build up the list of possible transports in various
		places (MailboxTransportListClass)

CALLED BY:	(EXTERNAL)
PASS:		ds	= locked lmem block
RETURN:		*ds:ax	= ChunkArray of MailboxMediaTransport structures
DESTROYED:	nothing
SIDE EFFECTS:	ds may have moved

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaGetAllTransports proc	far
		uses	es, si, di, bx, bp, cx, dx
		.enter
	;
	; First off, create the result array.
	; 
		mov	bx, size MailboxMediaTransport
		clr	cx, si, ax
		call	ChunkArrayCreate
		mov	bp, si
		segmov	es, ds		; *es:bp <- result array, for callback
	;
	; Now lock down the media -> transport map
	; 
		call	MTLock
	;
	; Iterate over all media and build the list of pairs.
	; 
		mov	bx, cs
		mov	di, offset MTGetAllTransportsCallback
		call	ChunkArrayEnum
	;
	; Release the media -> transport map.
	; 
		call	UtilVMUnlockDS
	;
	; Return the result array in *ds:ax
	; 
		segmov	ds, es
		mov_tr	ax, bp
		.leave
		ret
MediaGetAllTransports endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MTGetAllTransportsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to create a MailboxMediaTransport entry in the
		passed array for each transport driver that uses this medium

CALLED BY:	(INTERNAL) MediaGetAllTransports via ChunkArrayEnum
PASS:		*ds:si	= media array
		ds:di	= MediaTransportMediaElement to process
		*es:bp	= result array
		ax	= size of this element
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	ax, bx, si, di, cx, dx
SIDE EFFECTS:	things may be added to the result array, ya know

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MTGetAllTransportsCallback proc	far
		.enter
	;
	; Point to the array of transport indices and figure how many there are
	; for this medium.
	; 
		mov	bx, di		; remember this for copying medium
					;  into new element(s)
		add	di, offset MTME_transports
		sub	ax, offset MTME_transports
		clr	dx		; dxax = size of this elt
		mov	cx, size MediaTransportMediaRef
		div	cx		; ax = # MediaTransportMediaElement's
		Assert	e, dx, 0
		mov_tr	cx, ax
	;
	; Fetch the handle of the transport element array.
	; 
		push	di
		call	MTGetMaps
		pop	si		; ds:si <- index array
		jcxz	done
transportLoop:
	;
	; ds:si = next index to fetch
	; *ds:di = transport element array
	; ds:bx = MediaTransportMediaElement being processed
	; *es:bp = result array
	; cx = # indices left to process.
	; 
	; First, point to the MediaTransportElement for the next driver that
	; supports the medium.
	; 
			CheckHack <MTMR_transport eq 0>
		lodsw			; ax <- next index
		push	si		; save offset of next index
		mov	si, di		; *ds:si <- transport elt array
		call	ChunkArrayElementToPtr
	;
	; Fetch the transport token out.
	; 
		push	bx			;preserve bx
		movdw	axdx, ds:[di].MTE_transport
		mov	bx, ds:[di].MTE_transOption
	;
	; Now append an element to the result array.
	; 
		segxchg	ds, es
		xchg	si, bp
		call	ChunkArrayAppend
	;
	; And store the transport token in the new element.
	; 
		movdw	ds:[di].MMT_transport, axdx
		mov	ds:[di].MMT_transOption, bx
		pop	bx			;restore bx
	;
	; Copy the medium into the new element as well.
	; 
		movdw	ds:[di].MMT_medium, es:[bx].MTME_medium, ax
	;
	; Restore loop registers.
	; 
		segxchg	ds, es
		xchg	si, bp

		mov	di, si		; *ds:di <- transport elt array
		pop	si		; ds:si <- next index
		add	si, MediaTransportMediaRef - size MTMR_transport
		loop	transportLoop
done:
		clc			; on to the next one
		.leave
		ret
MTGetAllTransportsCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaGetAllTransportCapabilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieves the union of the MailboxTransportCapabilities for
		all the transports that would be returned by
		MediaGetAllTransports. It is intended to allow someone to
		quickly determine whether certain functions (notably the
		sending of system/Poof messages and the retrieval of new
		messages) should be made available to the user.

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		ax	= union of all MailboxTransportCapabilities from
			  all available transports
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaGetAllTransportCapabilities proc	far
		uses	ds, si, di
		.enter
		call	MTLock
		mov	ax, ds:[MTH_allCaps]
		call	UtilVMUnlockDS
		.leave
		ret
MediaGetAllTransportCapabilities endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaCheckSupportedFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Consults the list of formats recorded as acceptable to a
		particular transport option of a transport driver and see
		if it contains any of the passed list of creatable formats

CALLED BY:	(EXTERNAL)
PASS:		axbx	= MailboxTransport to check
		si	= MailboxTransportOption to check
		cx:dx	= array of MailboxDataFormat descriptors, ending with
			  a GEOWORKS/GMDFID_INVALID entry, indicating the
			  formats in which the body can be created
RETURN:		carry set if at least one of the passed formats is acceptable
		carry clear if none of the passed formats is acceptable
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaCheckSupportedFormat proc	far
		uses	ds, si, di, bp, ax, bx, es
		.enter
	;
	; See if the transport & option are in the array. It's supposed to
	; be, since we're called by the OutboxTransportMonikerSource, which
	; works only from things that are known by us.
	;
		push	cx, dx
		mov	bp, si
		call	MTLock
		movdw	cxdx, axbx		; cxdx <- MailboxTransport
		mov	bx, bp			; bx <- MailboxTransportOption
		call	MTFindTransport
		mov	si, di			; *ds:si <- transport array
		pop	es, bx			; es:bx <- array to check
EC <		WARNING_NC	ASKED_FOR_FORMATS_OF_UNKNOWN_TRANSPORT	>
		jnc	done
	;
	; See if the entry has any format restrictions.
	;
		call	ChunkArrayElementToPtr
		mov	si, ds:[di].MTE_formats
		tst	si
		jz	supported		; => no restrictions, so passed
						;  formats are acceptable.

	;
	; Figure how many supported formats there are for the transport.
	;
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx
		Assert	bitClear, cx, 0x3
		shr	cx
		shr	cx
possibleFormatLoop:
	;
	; Now for each possible format we were given, see if it's in the
	; list of acceptable formats for the transport. Which array we loop
	; through in the outer loop makes little difference, except we've got
	; the size of the acceptable format array, so it's less overhead to
	; loop over that in the inner loop.
	;
		movdw	axdx, es:[bx]
	CheckHack <MANUFACTURER_ID_GEOWORKS eq 0 and GMDFID_INVALID eq 0>
		mov	di, ax
		or	di, dx
		jz	done			; => hit end of possible formats
						;  without finding one that's
						;  acceptable (carry clear)

		push	cx, si
acceptableFormatLoop:
		cmp	ds:[si].MDF_id, dx
		jne	nextAcceptable
		cmp	ds:[si].MDF_manuf, ax
nextAcceptable:
		lea	si, [si+size MailboxDataFormat]
		loopne	acceptableFormatLoop
		pop	cx, si
		lea	bx, [bx+size MailboxDataFormat]
		jne	possibleFormatLoop
supported:
		stc
done:
	;
	; Release the map block before return, thanks.
	;
		call	UtilVMUnlockDS
		.leave
		ret
MediaCheckSupportedFormat endp


Media	ends
