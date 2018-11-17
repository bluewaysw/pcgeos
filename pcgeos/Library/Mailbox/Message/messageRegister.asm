COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		messageRegister.asm

AUTHOR:		Adam de Boor, Apr 19, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/19/94		Initial revision


DESCRIPTION:
	
		

	$Id: messageRegister.asm,v 1.1 97/04/05 01:20:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MessageCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxRegisterMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a message with the system

CALLED BY:	(GLOBAL)
PASS:		cx:dx	= MailboxRegisterMessageArgs
RETURN:		carry set on error:
			ax	= MailboxError
			dx	= destroyed
		carry clear on success:
			dxax	= MailboxMessage
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- look at transport and get the appropriate DBQ
	- allocate MailboxMessageDesc from that queue
	- load the storage driver
		- if unable to load, give the appropriate error, if user said
		  retry, do so (user doesn't get retry option if no msg
		  passed), else return error
	- allocate room for the mbox reference based on the driver's
	  MBDDI_mboxRefSize
	- call DR_MBDD_STORE_BODY
	- if error, free mboxref and return the error
	- allocate a chunk in that block for the mbox ref & copy the ref in
	- allocate a chunk for the subject & copy it in
	- allocate a chunk array (var size) for the trans addrs & copy them
	  in, one by one
	- rederef the message descriptor and copy in the fixed-size things
	  (including all the chunk handles for the above)
	- unlock the item
	- add the item to the DBQ
	- if outbox, re-eval retry timer (should provoke initial send, if
	  necessary)
	- if inbox, look for server registered. if registered, attempt immediate
	  delivery, taking into account screening requests, etc.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxRegisterMessage proc	far
dbq		local	dword
msg		local	MailboxMessage
		uses	ds, si, cx, bx, di, es
		.enter
	;
	; Figure into which queue the message should go. If the transport
	; is GEOWORKS/LOCAL, it goes in the inbox. Else it goes in the outbox.
	; 
		movdw	dssi, cxdx
		CmpTok	ds:[si].MRA_transport, \
				MANUFACTURER_ID_GEOWORKS, \
				GMTID_LOCAL, \
				getOutbox
		call	AdminGetInbox

if 	_NO_UNKNOWN_APPS_ALLOWED
		add	si, offset MRA_destApp
   		call	InboxCheckAppUnknown
		lea	si, ds:[si-offset MRA_destApp]
		jnc	haveQueue
		mov	ax, ME_DESTINATION_APPLICATION_UNKNOWN
		jmp	done
else
		jmp	haveQueue
endif	; _NO_UNKNOWN_APPS_ALLOWED

getOutbox:
		call	AdminGetOutbox
haveQueue:
		movdw	ss:[dbq], bxdi
	;
	; Allocate the message descriptor
	; 
		call	DBQAlloc
		jc	allocErr
		movdw	ss:[msg], dxax
	;
	; Lock that puppy down.
	; 
		mov_tr	di, ax
		mov_tr	ax, dx
		call	DBLock		; *es:di <- item
		push	es:[LMBH_flags]
		ornf	es:[LMBH_flags], mask LMF_RETURN_ERRORS
	;
	; Copy the fixed stuff in.
	; 
		call	MRStoreFixedData
		segxchg	ds, es
	;
	; Cope with the body & the error message for the driver.
	; 
		call	MRStoreBody
		jc	cleanup
	
		call	MRStoreSubject
		jc	cleanup
		
		call	MRStoreAddresses
		jc	cleanup
		
		pop	ds:[LMBH_flags]
		segmov	es, ds
		call	DBDirty
		call	DBUnlock
	;
	; Add the item to the queue, now. The add-callback routine for the queue
	; will take care of the initial processing required for the message.
	; 
		movdw	dxax, ss:[msg]
		movdw	bxdi, ss:[dbq]
		call	DBQAdd
	;
	; Make sure the thing will fit.
	; 
		mov	cx, ax			;save ax
		call	VMUpdate		;ax = VMStatus
		jnc	updateOkay

		cmp	ax, VM_UPDATE_BLOCK_WAS_LOCKED
		jne	diskError
	;
	; Call UtilUpdateAdminFile just for the sake of queuing a message to
	; update again later.  (Shorter than queueing a message ourselves.)
	;
		call	UtilUpdateAdminFile	;flags preserved

updateOkay:
		mov	ax, cx			;restore ax destroyed above.
		
done:
		.leave
		ret

allocErr:
		mov	ax, ME_NOT_ENOUGH_MEMORY
		jmp	done

cleanup:
	;
	; Restore the LMBH_flags field.
	; 
		pop	ds:[LMBH_flags]
	;
	; Release the item before we nuke it.
	; 
		push	ax
		segmov	es, ds
		call	DBDirty
		call	DBUnlock
	;
	; Call the regular DBQFree routine. The cleanup handler for the queue
	; will take care of freeing any and all chunks allocated to this point.
	; 
		mov	bx, ss:[dbq].high
freeItem:
		movdw	dxax, ss:[msg]
	;
	; If the body wasn't marked volatile, free the bodyRef before we free
	; the item, so the caller knows it is always responsible for deleting
	; the body on an error.
	; 
		call	MessageLock
		mov	di, ds:[di]
		test	ds:[di].MMD_flags, mask MMF_BODY_DATA_VOLATILE or \
				mask MMF_DELETE_BODY_AFTER_TRANSMISSION
		jnz	unlockAndFree
		push	ax
		clr	ax
		xchg	ds:[di].MMD_bodyRef, ax
		tst	ax
		jz	popUnlockAndFree
		call	LMemFree
		call	UtilVMDirtyDS
popUnlockAndFree:
		pop	ax
unlockAndFree:
		call	UtilVMUnlockDS
	;
	; Finally, free the item.
	; 
		call	DBQFree
	;
	; Make sure the admin file is consistent, again (might have gotten
	; messed up by a failed VMUpdate)
	; 
		call	UtilUpdateAdminFile
	;
	; Restore error and carry flag and boogie.
	; 
		pop	ax
		stc
		jmp	done


diskError:
	;
	; Update of the admin file failed for some reason. Generate an
	; appropriate MailboxError code and nuke the message, after removing
	; it from whatever queue it was put in.
	; 
		cmp	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
		mov	ax, ME_INSUFFICIENT_DISK_SPACE
		je	haveErrorCode
		mov	ax, ME_UNKNOWN_DISK_ERROR
haveErrorCode:
		push	ax
		mov	ax, ss:[msg].low
		call	DBQRemove
		jmp	freeItem
MailboxRegisterMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRStoreFixedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the fixed-size data from the MailboxRegisterMessageArgs
		into the allocated MailboxMessageDesc

CALLED BY:	(INTERNAL) MailboxRegisterMessage
PASS:		ds:si	= MailboxRegisterMessageArgs
		*es:di	= MailboxMessageDesc
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRStoreFixedData proc	near
		uses	di, dx
		.enter
		mov	di, es:[di]
	;
	; Zero-initialize things what need it (so we know whether a chunk's
	; been allocated for the thing).
	; 
		clr	ax
		mov	es:[di].MMD_subject, ax
		mov	es:[di].MMD_bodyRef, ax
		mov	es:[di].MMD_transAddrs, ax
	;
	; Copy in MRA_bodyStorage
	; 
		push	si, di
			CheckHack <offset MRA_bodyStorage eq 0>
		add	di, offset MMD_bodyStorage
			CheckHack <size MRA_bodyStorage eq 4>
		movsw			; bodyStorage.id
		movsw			; bodyStorage.manuf

	;
	; Copy in MRA_bodyFormat
	; 
			CheckHack <MRA_bodyStorage + size MRA_bodyStorage eq \
					offset MRA_bodyFormat>
			CheckHack <MMD_bodyStorage + size MMD_bodyStorage eq \
					offset MMD_bodyFormat>
			CheckHack <size MRA_bodyFormat eq 4>
		movsw
		movsw
	;
	; Copy in MRA_transport and option.
	; 
		add	si, offset MRA_transport - (offset MRA_bodyFormat + size MRA_bodyFormat)
		add	di, offset MMD_transport - (offset MMD_bodyFormat + size MMD_bodyFormat)
			CheckHack <size MRA_transport eq 4>
		movsw
		movsw
		movsw
	;
	; Copy in MRA_destApp
	; 
		add	si, offset MRA_destApp - (offset MRA_transport + size MRA_transport + size MRA_transOption)
		add	di, offset MMD_destApp - (offset MMD_transport + size MMD_transport + size MMD_transOption)
			CheckHack <size MRA_destApp eq 6>
		movsw
		movsw
		movsw

	;
	; Copy in MRA_startBound && MRA_endBound
	; 
			CheckHack <MRA_startBound eq offset MRA_destApp + size MRA_destApp>
		add	di, offset MMD_transWinOpen - (offset MMD_destApp + size MMD_destApp)
			CheckHack <size MRA_startBound eq 4>
			CheckHack <size MRA_endBound eq 4>
			CheckHack <MRA_startBound + size MRA_startBound eq \
					offset MRA_endBound>
			CheckHack <MMD_transWinOpen + size MMD_transWinOpen eq \
					offset MMD_transWinClose>
EC <		call	ECValidateDate					>
EC <		ERROR_C	INVALID_START_TIME				>

		movsw
		movsw

EC <		call	ECValidateDate					>
EC <		ERROR_C	INVALID_END_TIME				>

		movsw
		movsw
	;
	; Copy in MRA_transData
	; 
		add	si, offset MRA_transData - (offset MRA_endBound + size MRA_endBound)
		add	di, offset MMD_transData - (offset MMD_transWinClose + size MMD_transWinClose)
			CheckHack <size MRA_transData eq 4>
		movsw
		movsw
		pop	si, di
	;
	; Copy in & EC MRA_flags
	; 
		mov	ax, ds:[si].MRA_flags
EC <		test	ax, not mask MailboxMessageFlags		>
EC <		ERROR_NZ	INVALID_MESSAGE_FLAGS			>
EC <		push	ax						>
EC <		andnf	ax, mask MMF_PRIORITY				>
EC <		cmp	ax, MailboxMessagePriority shl offset MMF_PRIORITY>
EC <		ERROR_AE	INVALID_MESSAGE_PRIORITY		>
EC <		pop	ax						>
EC <		push	ax						>
EC <		andnf	ax, mask MMF_VERB				>
EC <		cmp	ax, MailboxDeliveryVerb shl offset MMF_VERB	>
EC <		ERROR_AE	INVALID_DELIVERY_VERB			>
EC <		pop	ax						>
		mov	es:[di].MMD_flags, ax
	;
	; Set the message-arrival stamp.
	; 
		call	TimerGetFileDateTime
		movdw	es:[di].MMD_registered, dxax

if	_AUTO_RETRY_AFTER_TEMP_FAILURE
	;
	; Set retry time to MAILBOX_NOW, such that the message will be sent
	; when MMD_transWinOpen is reached.
	;
movdw	es:[di].MMD_autoRetryTime, MAILBOX_NOW
			CheckHack <MAILBOX_NOW eq 0>
		add	di, offset MMD_autoRetryTime
		clr	ax
		stosw
		stosw
endif	; _AUTO_RETRY_AFTER_TEMP_FAILURE

		.leave
		ret
MRStoreFixedData endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the FileDateAndTime at ds:si

CALLED BY:	(INTERNAL) MRStoreFixedData
PASS:		ds:si	= FileDateAndTime to check
RETURN:		carry set if it's invalid
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECValidateDate	proc	near
		uses	ax, bx, cx
		.enter
	;
	; See if the two parts are the same. We allow them both to be 0 ("Now")
	; or both to be -1 ("Eternity"). If they're not equal, the values have
	; to fall within standard params.
	; 
		mov	ax, ds:[si].FDAT_date
		mov	bx, ds:[si].FDAT_time
		mov	cx, ax
		cmp	cx, bx
		jnz	checkFields

		inc	ax			; both -1?
		jz	ok			; yes -- Eternity
		dec	ax			; both 0?
		jz	ok			; yes -- Now

checkFields:
	;
	; Make sure the checkable parameters are within bounds.
	; 
		mov	cx, mask FD_MONTH	; month: 1 - 12
		and	cx, ax
		jz	bad
		cmp	cx, 12 shl offset FD_MONTH
		ja	bad
		
		mov	cx, mask FD_DAY		; day: 1 - 31
		and	cx, ax
		jz	bad
		cmp	cx, 31
		ja	bad
		
		mov	cx, mask FT_HOUR	; hour: 0 - 23
		and	cx, bx
		cmp	cx, 23 shl offset FT_HOUR
		ja	bad
		
		mov	cx, mask FT_MIN		; min: 0 - 59
		and	cx, bx
		cmp	cx, 59 shl offset FT_MIN
		ja	bad
		
		mov	cx, mask FT_2SEC	; 2sec: 0 - 29 (== 0 - 58 sec)
		and	cx, bx
		cmp	cx, 29 shl offset FT_2SEC
		ja	bad
ok:
		clc
done:
		.leave
		ret
bad:
		stc
		jmp	done
ECValidateDate	endp
endif	; ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRStoreBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Contact the data driver to store the body.

CALLED BY:	(INTERNAL) MailboxRegisterMessage, MailboxChangeBodyFormat
PASS:		*ds:di	= MailboxMessageDesc
		es:si	= MailboxRegisterMessageArgs
RETURN:		carry set if couldn't store:
			ax	= MailboxError
		carry clear if ok:
			ax	= destroyed
		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	chunks allocated and MMD_bodyRef filled in

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRStoreBody proc	near
strat		local	fptr.far
refs		local	MBDDBodyRefs
	ForceRef refs		; MRStoreBodyCallDriver
		uses	bx, si, cx, dx
		.enter
		call	MRCheckBodyFormat
		jc	done

		movdw	cxdx, es:[si].MRA_bodyStorage
		push	si
		call	MessageLoadDataDriver
		pop	si
		jc	done
		movdw	ss:[strat], dxax
	;
	; Allocate room for the mbox-ref in the lmem block with the descriptor
	; and store the chunk in the descriptor.
	; 
		call	LMemAlloc
		jc	allocErr

		push	si
		mov	si, ds:[di]
		mov	ds:[si].MMD_bodyRef, ax
		pop	si
	;
	; Call the driver itself to do its part in storing the body. The
	; driver is unloaded when we get back here, error or no error.
	; 
		call	MRStoreBodyCallDriver
		jc	cleanup
done:
		.leave
		ret

allocErr:
		call	MailboxFreeDriver
		mov	ax, ME_NOT_ENOUGH_MEMORY
		stc
		jmp	done

cleanup:
	;
	; If failed, we have to free the body ref chunk ourselves, so when
	; the descriptor is biffed, the data driver doesn't get called to
	; delete a body it never stored.
	; 
		push	ax		; save error code
		mov	bx, ds:[di]	; ds:bx <- MMD
		clr	ax
		xchg	ds:[bx].MMD_bodyRef, ax
		call	LMemFree
		pop	ax		; ax <- error code
		stc
		jmp	done
MRStoreBody 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRCheckBodyFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check with the transport driver, if any, to make sure that
		the format being registered is acceptable.

CALLED BY:	(INTERNAL) MRStoreBody
PASS:		*ds:di	= MailboxMessageDesc with MRA_bodyFormat,
			  MRA_transport, and MRA_transOption set
RETURN:		carry set if unacceptable:
			ax	= ME_UNSUPPORTED_BODY_FORMAT
		carry clear if ok:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRCheckBodyFormat proc	near
		uses	bx, cx, dx, si
		.enter
	;
	; If it's going to the inbox, the format is fine.
	;
		mov	bx, ds:[di]
		movdw	cxdx, ds:[bx].MMD_transport
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	checkWithTransport
		cmp	dx, GMTID_LOCAL
		je	done			; => inbox

checkWithTransport:
	;
	; Load the transport driver.
	;
		call	AdminGetTransportDriverMap
		push	ax
		call	DMapLoad
		pop	ax
		cmc
		jnc	done			; if can't load, then we
						;  assume the format is ok?
	;
	; Driver is loaded. Point to MMD_bodyFormat as an array of a single
	; choice and ask the driver to choose from it.
	;
		push	cx, dx, ax
		mov	cx, ds
		mov	dx, ds:[di]
		add	dx, offset MMD_bodyFormat	; cx:dx <- "array"
		push	ds, di
		call	GeodeInfoDriver		; ds:si <- DriverInfoStruct
		mov	bx, 1			; bx <- # of choices
		mov	di, DR_MBTD_CHOOSE_FORMAT
		call	ds:[si].DIS_strategy	; ax <- 0 or -1
		pop	ds, di
	;
	; Unload the transport driver now we've got our answer.
	;
		mov_tr	bx, ax
		pop	cx, dx, ax
		call	DMapUnload
	;
	; See if it accepted the choice we gave it.
	;
		tst_clc	bx
		jz	done
		mov	ax, ME_UNSUPPORTED_BODY_FORMAT
		stc
done:
		.leave
		ret
MRCheckBodyFormat endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageLoadDataDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to load the storage driver & return its handle + 
		strategy

CALLED BY:	(EXTERNAL)
PASS:		cxdx	= MailboxStorage
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			bx	= driver handle
			cx	= base mbox-ref size
			si	= base app-ref size
			dxax	= strategy routine
DESTROYED:	nothing
SIDE EFFECTS:	driver is loaded, of course

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageLoadDataDriver proc far
		uses	ds
		.enter
	;
	; First attempt to load the data driver.
	;
	; XXX: should this use MailboxLoadDataDriverWithError? don't have
	; the error message in a chunk yet...
	; 
		call	MailboxLoadDataDriver
		WARNING_C	UNABLE_TO_LOAD_DATA_DRIVER
		mov	ax, ME_CANNOT_LOAD_DATA_DRIVER
		jc	done
	;
	; Fetch the mbox-ref size and the strategy routine of the driver.
	; 
		call	GeodeInfoDriver
		mov	cx, ds:[si].MBDDI_mboxRefSize
		movdw	dxax, ds:[si].MBDDI_common.DIS_strategy
		mov	si, ds:[si].MBDDI_appRefSize
		clc
done:
		.leave
		ret
MessageLoadDataDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRStoreBodyCallDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the driver to actually store the body

CALLED BY:	(INTERNAL) MRStoreBody
PASS:		es:si	= MailboxRegisterMessageArgs
		*ds:ax	= mbox-ref chunk
		cx	= current size of that chunk
		ss:bp	= inherited frame
		*ds:di	= MailboxMessageDesc
		bx	= driver handle
RETURN:		carry set if couldn't store:
			ax	= MailboxError
		carry clear if ok
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	driver is unloaded

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRStoreBodyCallDriver proc	near
		.enter	inherit	MRStoreBody
		; What is this supposed to do?
		Assert	stackFrame, bp
	;
	; Set up the mbox-ref pointer in the MBDDBodyRefs. (it's an flptr,
	; not an fptr)
	; 
		mov	ss:[refs].MBDDBR_mboxRefLen, cx
		movdw	ss:[refs].MBDDBR_mboxRef, dsax
	;
	; Copy the app-ref info & flags from the register args.
	; 
		Assert	fptr, es:[si].MRA_bodyRef
		movdw	ss:[refs].MBDDBR_appRef, es:[si].MRA_bodyRef, ax
		mov	ax, es:[si].MRA_bodyRefLen
		mov	ss:[refs].MBDDBR_appRefLen, ax
		
		mov	ax, es:[si].MRA_flags
		mov	ss:[refs].MBDDBR_flags, ax
	;
	; Call the driver to do its thang...
	; 
		mov	cx, ss
		lea	dx, ss:[refs]
		push	ds:[LMBH_handle]	; for fixup...
		push	di
		mov	di, DR_MBDD_STORE_BODY
		call	ss:[strat]
		pop	di
	;
	; Fixup ds, in case the driver had to enlarge the mbox ref.
	; 
		XchgTopStack	bx		; bx <- MMD block, save
						;  driver handle
		call	MemDerefDS
		pop	bx			; bx <- driver handle
	;
	; Always unload the driver, regardless of success or failure.
	; 
		pushf
		call	MailboxFreeDriver
		popf
		.leave
		ret
MRStoreBodyCallDriver endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRStoreSubject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the subject string into the block

CALLED BY:	(INTERNAL) MailboxRegisterMessage
PASS:		*ds:di	= MailboxMessageDesc
		es:si	= MailboxRegisterMessageArgs
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			ax	= destroyed
		ds	= fixed up
DESTROYED:	nothing
SIDE EFFECTS:	chunk allocated and MMD_subject filled in

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRStoreSubject proc	near
		uses	bx, es, di, cx, si
		.enter
	    ;
	    ; Figure the size of the string, first.
	    ; 
		mov	bx, di		; *ds:bx <- MMD
		les	di, es:[si].MRA_summary
		Assert	fptr, esdi
		mov	si, di		; save start for copy
		LocalStrSize	includeNull
	    ;
	    ; Allocate a chunk that big.
	    ; 
EC <		cmp	cx, MAILBOX_MAX_SUBJECT				>
EC <		ERROR_A	MESSAGE_SUBJECT_TOO_LONG			>
		call	LMemAlloc
		jc	allocErr
	    ;
	    ; Store its chunk handle away, please.
	    ; 
		mov	bx, ds:[bx]
		mov	ds:[bx].MMD_subject, ax
	    ;
	    ; And copy the data in.
	    ; 
		mov_tr	di, ax
		mov	di, ds:[di]
		segxchg	ds, es
		rep	movsb

		segmov	ds, es		; ds <- MMD seg, again
		clc
done:
		.leave
		ret
allocErr:
		mov	ax, ME_NOT_ENOUGH_MEMORY
		jmp	done
MRStoreSubject endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRStoreAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store all the addresses for the message.

CALLED BY:	(INTERNAL)
PASS:		*ds:di	= MMD
		es:si	= MailboxRegisterMessageArgs
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRStoreAddresses proc	near
		uses	es, si, cx, bx, dx, di, bp
		.enter
	;
	; Do nothing if there's no address.
	;
		tst_clc	es:[si].MRA_numTransAddrs
		jz	checkInbox
	;
	; Create a chunkarray containing variable-sized elements to hold
	; the addresses.
	; 
		clr	bx, cx
		push	si
		clr	si
		call	ChunkArrayCreate
		mov_tr	ax, si
		pop	si
	;
	; Store the chunk away.
	; 
		mov	bx, ds:[di]
		mov	ds:[bx].MMD_transAddrs, ax
	;
	; Fetch the length & start of the address array.
	; 
		mov	ax, es:[si].MRA_transOption
		mov	cx, es:[si].MRA_numTransAddrs
		CmpTok	es:[si].MRA_transport, \
				MANUFACTURER_ID_GEOWORKS, \
				GMTID_LOCAL
		les	si, es:[si].MRA_transAddrs
EC <		pushf			; in case Assert fptr no longer	>
EC <					;  preserve flags		>
EC <		Assert	fptr, essi					>
EC <		popf							>
		je	inbox

		call	OutboxStoreAddresses
		jmp	done
inbox:
		call	InboxStoreAddresses

done:
		.leave
		ret

checkInbox:
	;
	; It's only legal to have no addresses if the message is going into
	; the inbox.
	;
		CmpTok	es:[si].MRA_transport, \
				MANUFACTURER_ID_GEOWORKS, \
				GMTID_LOCAL
		je	done
		mov	ax, ME_ADDRESS_INVALID
		stc
		jmp	done
MRStoreAddresses endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageStoreAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a MailboxTransAddr to the end of the MMD_transAddrs
		array for a message.

CALLED BY:	(EXTERNAL) InboxStoreAddresses,
			   ORStoreOneAddress
PASS:		*ds:di	= MailboxMessageDesc
		es:si	= MailboxTransAddr to add
		ax	= value to store in MITA_medium
RETURN:		carry set on error (allocation error)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MessageStoreAddress proc	far
		uses	ax, bx, cx, dx, si, di
		.enter
	;
	; Compute the size of the user-readable transport address. If the
	; segment is 0, we'll just store a null character for the string.
	; 
SBCS <		mov	cx, 1						>
DBCS <		mov	cx, 2						>
		tst	es:[si].MTA_userTransAddr.segment
		jz	haveUserSize

		push	di, es, ax
		les	di, es:[si].MTA_userTransAddr
		LocalStrSize	includeNull
		pop	di, es, ax
haveUserSize:
	;
	; Add in the size of the fixed portion of the address, plus the
	; size of the supplied opaque address to yield the final size of
	; the element to append.
	; 
		add	cx, size MailboxInternalTransAddr
		add	cx, es:[si].MTA_transAddrLen
	;
	; Append the appropriate-sized element to the array of transport
	; addresses.
	; 
		push	si, ax, di
		mov	ax, cx
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		call	ChunkArrayAppend	; ds:di = MITA, all zeroed
		pop	si, ax, bx
		jc	done
	;
	; Store away the medium token.
	; 
		mov	ds:[di].MITA_medium, ax
	;
	; Initialize the flags & address list token to 0. No duplicate known,
	; as yet.
	; 
		mov	ds:[di].MITA_flags, MailboxTransFlags <MAS_EXISTS,0,0>
		mov	ds:[di].MITA_next, MITA_NIL
		mov	ds:[di].MITA_reason, -1
	;
	; Copy in the opaque data.
	; 
		mov	ax, es:[si].MTA_transAddrLen
		mov	ds:[di].MITA_opaqueLen, ax
		segxchg	ds, es		; es:di <- internal addr
					; ds:si <- external addr
		push	ds, si		; save ext addr for copy user addr
		lds	si, ds:[si].MTA_transAddr
		xchg	ax, cx		; cx <- opaque size, ax <- total size
		sub	ax, cx		; ax <- user size + fixed size
		add	di, offset MITA_opaque
		call	copyBytes
		pop	ds, si
	;
	; Figure if there's a user-readable string and copy it in if, so. If
	; not, just manufacture an empty string.
	;
	; es:di = just after the opaque data
	; ax = user size + fixed size
	; 
		tst	ds:[si].MTA_userTransAddr.segment
		jz	justNull

		push	ds, si
		lds	si, ds:[si].MTA_userTransAddr
		sub	ax, size MailboxInternalTransAddr
		mov_tr	cx, ax
		call	copyBytes
		pop	ds, si
		jmp	doneok
justNull:
		mov	{TCHAR}es:[di], 0
doneok:
		segxchg	ds, es
		clc
done:
		.leave
		ret
	;--------------------
	; Pass:	ds:si	= source
	;	es:di	= dest
	;	cx	= # bytes
	; Return:	es:di	= just past copied data
	; Destroy:	si, di, cx
copyBytes:
		shr	cx
		rep	movsw
		adc	cx, cx		; cx <- CF (0 or 1)
		rep	movsb
		retn

MessageStoreAddress endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxChangeBodyFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores a new body for a message

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		es:di	= MailboxChangeBodyFormatArgs
RETURN:		carry set on error:
			ax	= MailboxError (invalid message, body currently
				  in-use)
		carry clear if successful:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Call data driver to delete body.  Free body ref and error msg.
	Then fake a MailboxRegisterMessageArgs and call MRStoreBody to
	add the new body.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxChangeBodyFormat	proc	far
mrmArgs		local	MailboxRegisterMessageArgs
	uses	bx,cx,dx,si,di,ds,es
	.enter

	Assert	fptr, esdi
	Assert	fptr, es:[di].MCBFA_bodyRef

	;
	; Fake arguments for MRStoreBody.  It happens that the beginning of
	; MailboxChangeBodyFormatArgs is the same as the beginning of
	; MailboxRegisterMessageArgs.
	;
	MovMsg	dxax, cxdx
	movdw	dssi, esdi
	mov	bx, ds:[si].MCBFA_newBodyFlags
	segmov	es, ss
	lea	di, ss:[mrmArgs]
		CheckHack <MRA_bodyStorage eq MCBFA_bodyStorage >
		CheckHack <MRA_bodyFormat eq MCBFA_bodyFormat >
		CheckHack <MRA_bodyRef eq MCBFA_bodyRef >
		CheckHack <MRA_bodyRefLen eq MCBFA_bodyRefLen >
		CheckHack <((MCBFA_bodyRefLen + size MCBFA_bodyRefLen) and 1) \
				eq 0>
	mov	cx, (MCBFA_bodyRefLen + size MCBFA_bodyRefLen) / 2
	rep	movsw

	;
	; Call data driver to free message body
	;
	call	MessageLock		; *ds:di = MailboxMessageDesc
	jc	done
	push	bx			; save new body flags
	call	MUCleanupDeleteBody
	pop	ax			; ax = new body flags

	;
	; Free body-ref.  Zero-out pointers in case new body-ref isn't stored.
	;
	mov	si, ds:[di]		; ds:si = MailboxMessageDesc

	Assert	bitClear, ax, <not (mask MMF_BODY_DATA_VOLATILE \
			or mask MMF_DELETE_BODY_AFTER_TRANSMISSION)	>
	andnf	ds:[si].MMD_flags, not (mask MMF_BODY_DATA_VOLATILE \
			or mask MMF_DELETE_BODY_AFTER_TRANSMISSION \
			or mask MIMF_BODY_STOLEN)
	ornf	ax, ds:[si].MMD_flags
	mov	ds:[si].MMD_flags, ax	; set flags that should be set
		CheckHack <mask MIMF_EXTERNAL eq 0x00ff>
	clr	ah			; only pass external flags
	mov	ss:[mrmArgs].MRA_flags, ax

	clr	ax
	xchg	ax, ds:[si].MMD_bodyRef
	tst	ax
	jz	noBodyRef
	call	LMemFree

noBodyRef:

	;
	; Store new body with data driver.
	;
	movdw	ds:[si].MMD_bodyFormat, ss:[mrmArgs].MRA_bodyFormat, ax
	movdw	ds:[si].MMD_bodyStorage, ss:[mrmArgs].MRA_bodyStorage, ax
	segmov	es, ss
	lea	si, ss:[mrmArgs]
	call	MRStoreBody
	call	MRDirtyDSAndUpdate

done:
	.leave
	ret
MailboxChangeBodyFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxBodyReformatted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that someone has taken the body of a message and
		reformatted it *IN PLACE*. This is different from
		MailboxChangeBodyFormat, where you are replacing one
		body with another. This function just records the new
		format for the body but assumes the reference to the body
		is still valid.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		axbx	= MailboxDataFormat
		bp	= MailboxMessageFlags for new message body (Only
			  MMF_BODY_DATA_VOLATILE and MMF_DELETE_BODY_AFTER
			  _TRANSMISSION can be passed and are used.)  Does not
			  affect old body.
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/12/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxBodyReformatted proc	far
		uses	di, bp, ds
		.enter
		call	MessageLockCXDX
		jc	done
		mov	di, ds:[di]		; ds:di <- MMD
		movdw	ds:[di].MMD_bodyFormat, axbx

		Assert	bitClear, bp, <not (mask MMF_BODY_DATA_VOLATILE \
				or mask MMF_DELETE_BODY_AFTER_TRANSMISSION)>
		andnf	ds:[di].MMD_flags, not (mask MMF_BODY_DATA_VOLATILE \
				or mask MMF_DELETE_BODY_AFTER_TRANSMISSION)
		ornf	ds:[di].MMD_flags, bp	; set flags that should be set
		; Carry flag cleared by "ornf" above.

		call	MRDirtyDSAndUpdate
done:
		.leave
		ret
MailboxBodyReformatted endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRDirtyDSAndUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dirty and unlock the block pointed to by DS then update the
		admin file

CALLED BY:	(INTERNAL)
PASS:		ds	= locked VM block
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/12/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRDirtyDSAndUpdate proc	near
		.enter
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		call	UtilUpdateAdminFile
		.leave
		ret
MRDirtyDSAndUpdate endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxDeleteMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To be called only after MailboxAcknowledgeMessageReceipt,
		this indicates the application has finished handling the
		message and the Mailbox library is free to delete the message
		when it sees fit.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		nothing
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If in inbox queue
		- call MailboxAcknowledgeMessageReceipt
	Else if in outbox queue
		- call DBQRemove
		- force-queue MSG_MA_OUTBOX_CHANGED with MABC_ALL
	Endif

	- call DBQFree to free the item, which does
		- call MessageCleanup.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxDeleteMessage	proc	far
	uses	ax,bx,bp,di
	.enter

	MovMsg	dxax, cxdx

	;
	; If message is in inbox queue, remove it from inbox.
	;
	call	AdminGetInbox		; ^vbx:di = inbox
	call	DBQCheckMember		; CF set if in queue
	jnc	checkOutbox
	MovMsg	cxdx, dxax
	call	MailboxAcknowledgeMessageReceipt
	jmp	freeMesgCXDX

checkOutbox:
	;
	; If message is in outbox queue, remove it from outbox.
	;
	call	AdminGetOutbox		; ^vbx:di = outbox
	call	DBQCheckMember		; CF set if in queue
	jnc	freeMesg
	mov	cx, dx			; cx = MailboxMessage.high
	push	ax
	call	DBQRemove
	pop	dx			; cxdx = MailboxMessage
	mov	ax, MSG_MA_BOX_CHANGED
	mov	bp, (MACT_REMOVED shl offset MABC_TYPE) or mask MABC_OUTBOX \
			or (MABC_ALL shl offset MABC_ADDRESS)
	clr	di			; (will be or'd with MF_FORCE_QUEUE)
	call	UtilForceQueueMailboxApp

freeMesgCXDX:
	MovMsg	dxax, cxdx

freeMesg:
	;
	; Free the message, whether it's in inbox, outbox, or neither.
	;
	call	DBQFree
	call	UtilUpdateAdminFile

	.leave
	ret
MailboxDeleteMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxReplyToMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a message as a reply to a message in the mailbox.

CALLED BY:	(GLOBAL)
PASS:		cx:dx	= MailboxReplyToMessageArgs
RETURN:		carry set on error:
			ax	= MailboxError
			dx	= destroyed
		carry clear on success:
			dxax	= MailboxMessage
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxReplyToMessage	proc	far
	uses	bx,cx,si,di,bp,ds,es
	.enter

	;
	; Copy non-address arguments to MailboxRegisterMessageArgs.
	;
	movdw	dssi, cxdx
	Assert	fptr, dssi
	Assert	fptr, ds:[si].MRTMA_bodyRef
	Assert	record, ds:[si].MRTMA_flags, MailboxMessageFlags
	Assert	fptr, ds:[si].MRTMA_summary
	
	sub	sp, size MailboxRegisterMessageArgs
	movdw	esdi, sssp

		CheckHack <MRA_bodyStorage eq 0>
		; es:di = MRA_bodyStorage

	add	si, offset MRTMA_bodyStorage	; ds:si = MRTMA_bodyStorage

		CheckHack <MRA_bodyFormat - MRA_bodyStorage \
			eq MRTMA_bodyFormat - MRTMA_bodyStorage>
		CheckHack <MRA_bodyRef - MRA_bodyStorage \
			eq MRTMA_bodyRef - MRTMA_bodyStorage>
		CheckHack <MRA_bodyRefLen - MRA_bodyStorage \
			eq MRTMA_bodyRefLen - MRTMA_bodyStorage>

		CheckHack<((MRA_bodyRefLen + size MRA_bodyRefLen \
			- MRA_bodyStorage) and 1) eq 0>
	mov	cx, (MRA_bodyRefLen + size MRA_bodyRefLen - MRA_bodyStorage) \
			/ 2
	rep	movsw

		CheckHack <MRTMA_bodyRefLen + size MRTMA_bodyRefLen \
			eq MRTMA_transData>
		; ds:si = MRTMA_transData

	add	di, MRA_transData - (MRA_bodyRefLen + size MRA_bodyRefLen)
		; es:di = MRA_transData

		CheckHack <MRA_flags - MRA_transData \
			eq MRTMA_flags - MRTMA_transData>
		CheckHack <MRA_summary - MRA_transData \
			eq MRTMA_summary - MRTMA_transData>
		CheckHack <MRA_destApp - MRA_transData \
			eq MRTMA_destApp - MRTMA_transData>
		CheckHack <MRA_startBound - MRA_transData \
			eq MRTMA_startBound - MRTMA_transData>
		CheckHack <MRA_endBound - MRA_transData \
			eq MRTMA_endBound - MRTMA_transData>

		CheckHack <((MRA_endBound + size MRA_endBound \
			- MRTMA_transData) and 1) eq 0>
	mov	cx, (MRA_endBound + size MRA_endBound - MRA_transData) / 2
	rep	movsw

	;
	; Get transport and transport option from original message.
	;
	mov	si, dx			; ds:si = MailboxReplyToMessageArgs
	mov	bp, sp			; ss:bp = MailboxRegisterMessageArgs
					;  (use bp to avoid segment override)
	movdw	dxax, ds:[si].MRTMA_message
	call	MessageLock		; *ds:di = MailboxMessageDesc
	jc	done			; return ax = MailboxMessage if error
	mov	di, ds:[di]
	movdw	ss:[bp].MRA_transport, ds:[di].MMD_transData, ax
					; the transport of the source address
					;  is stored in MMD_transData
	mov	ax, ds:[di].MMD_transOption
	mov	ss:[bp].MRA_transOption, ax

	;
	; Get address.
	;
	mov	si, ds:[di].MMD_transAddrs	; *ds:si = MITA array
	mov	ax, ME_REPLY_ADDRESS_NOT_AVAILABLE
	tst	si			; if null, no address to reply to
	stc
	jz	errorUnlockMsg
	call	ChunkArrayGetCount	; cx = count
	Assert	ne, cx, 0
	mov	ss:[bp].MRA_numTransAddrs, cx
	call	MRBuildReplyAddress	; ^hcx = es = MTA block, CF on error
	call	UtilVMUnlockDS		; flags preserved
	mov	ax, ME_NOT_ENOUGH_MEMORY
	jc	done
	mov	ss:[bp].MRA_transAddrs.segment, es
	clr	ss:[bp].MRA_transAddrs.offset

	;
	; Finally, register the thing.
	;
	mov	bx, cx			; bx = MTA block hptr
	movdw	cxdx, ssbp		; cx:dx = MailboxRegisterMessageArgs
	call	MailboxRegisterMessage	; dxax = MailboxMessage, CF on error,
					;  ax = MailboxError

	;
	; Free the MTA block.
	;
	pushf
	call	MemFree
	popf

done:
	;
	; We have to preserve ax and CF.
	;
	lea	sp, ss:[bp + size MailboxRegisterMessageArgs]

	.leave
	ret

errorUnlockMsg:
	call	UtilVMUnlockDS		; flags preserved
	jmp	done

MailboxReplyToMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRBuildReplyAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a MailboxTransAddr array from a MailboxInternalTransAddr
		chunk array.

CALLED BY:	(INTERNAL) MailboxReplyToMessage
PASS:		*ds:si	= MailboxInternalTransAddr chunk array
		cx	= # of elts in array
RETURN:		carry clear if no error
			es	= locked block containing MailboxTransAddr
				  structures, followed by data pointed to by
				  MTA_transAddr and MTA_userTransAddr fields.
				  Must be freed by caller.
			cx	= hptr of block at es
		carry set if out of memory
			cx, es destroyed
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRBuildReplyAddress	proc	near
	uses	bx,dx,di,bp
	.enter

	;
	; First allocate a block large enough for MailboxTranAddr array.
	;
	mov	ax, size MailboxTransAddr
	mul	cx
	Assert	e, dx 0			; make sure not too many addresses
	mov	bp, ax			; bp = size of block
	mov	cx, (mask HAF_ZERO_INIT shl 8) or ALLOC_DYNAMIC_LOCK
	call	MemAlloc		; bx = hptr, ax = sptr
	jc	done			; just return error

	;
	; Enumerate the addresses to fill in MailboxTransAddr's.
	;
	mov	es, ax
	clr	dx			; es:dx = first MailboxTransAddr
	mov	cx, bx			; cx = hptr of block
	mov	bx, cs
	mov	di, offset MRBuildReplyAddressCallback
	call	ChunkArrayEnum		; CF set if out of memory
	jc	reAllocError

done:
	.leave
	ret

reAllocError:
	;
	; Free MTA block.
	;
	mov	bx, cx			; bx = hptr of MTA block
	call	MemFree
	stc
	jmp	done

MRBuildReplyAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MRBuildReplyAddressCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to convert one MailboxInternalTransAddr to
		MailboxTransAddr, and copy the actual address bytes.

CALLED BY:	(INTERNAL) MRBuildReplyAddress via ChunkArrayEnum
PASS:		ds:di	= MailboxInternalTransAddr
		ax	= size of this MailboxInternalTransAddr entry
		es:dx	= MailboxTransAddr entry to fill in
		cx	= hptr of block in es
		bp	= current size of block in es
RETURN:		carry clear if no error
			es:dx	= next MailboxTransAddr entry to fill in (es
				  possibly moved)
			bp	= new size of block in es
		carry set if error (not enough memory)
			dx, bp, es unchanged
DESTROYED:	ax, bx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MRBuildReplyAddressCallback	proc	far
	uses	cx
	.enter

	;
	; Find the size needed for opaque address and user-readable address.
	;
	sub	ax, size MailboxInternalTransAddr	; ax = size of data at
							;  MITA_opaque
	push	ax			; save size of addrs
	add	ax, bp			; ax = desired size
	mov	bx, cx			; bx = hptr of MTA block
	clr	ch			; no HeapAllocFlags
	call	MemReAlloc		; ax = new sptr of block
	jc	outOfMem
	mov	es, ax

	;
	; Fill in MailboxTransAddr.
	;
	mov	si, dx			; es:si = MailboxTransAddr
	movdw	es:[si].MTA_transAddr, esbp
	mov	cx, ds:[di].MITA_opaqueLen
	mov	es:[si].MTA_transAddrLen, cx
	add	cx, bp			; es:cx = user trans addr buffer
	movdw	es:[si].MTA_userTransAddr, escx

	;
	; Copy data driver and user-readable trans addrs.
	;
	lea	si, ds:[di].MITA_opaque	; ds:di = MITA_opaque
	mov	di, bp			; es:di = buffer for addrs
	pop	cx			; cx = size of addrs
	add	bp, cx			; bp = new size of MTA block
	rep	movsb

	add	dx, size MailboxTransAddr	; es:dx = next MTA, and we know
						;  that CF is cleared here.

done:
	.leave
	ret

outOfMem:
	pop	ax			; no use, just restore stack
	jmp	done

MRBuildReplyAddressCallback	endp

MessageCode	ends
