COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		adminInit.asm

AUTHOR:		Adam de Boor, Apr 11, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/11/94		Initial revision


DESCRIPTION:
	Code to initialize the mailbox admin file.
		

	$Id: adminInit.asm,v 1.1 97/04/05 01:20:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open/Create the administrative file and initialize the
		transient data structures that are stored in the file.

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		carry set if file couldn't be opened/created
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminInit	proc	near
		uses	ax, bx, cx, dx, si, di, bp, ds
		.enter
	;
	; Change first to the spool directory where the mailbox stuff goes.
	; 
		call	MailboxPushToMailboxDir
	;
	; Now attempt to open or create the admin file. We open the thing
	; async-update with block-level synchronization.
	; 
		mov	bx, handle uiAdminFileName
		call	MemLock
		mov	ds, ax
		assume	ds:segment uiAdminFileName
tryAgain:
		mov	dx, ds:[uiAdminFileName]

		mov	ax, (VMO_CREATE shl 8) or \
				mask VMAF_FORCE_READ_WRITE or \
				mask VMAF_ALLOW_SHARED_MEMORY or \
				mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
				mask VMAF_FORCE_DENY_WRITE
		clr	cx		; default compression threshold
		call	VMOpen
		jnc	fileOpen
	;
	; Couldn't open the file. Attempt to delete the existing file (on the
	; assumption it's corrupt). If that succeeds, try the open again, else
	; there's nothing more we can do but declare an error and return.
	; 
deleteAndRetry:
		WARNING	MAILBOX_CANNOT_OPEN_ADMIN_FILE
		call	FileDelete		
		jc	die
	;
	; Admin file successfully deleted.  Now delete all message files, if
	; possible.  Then ignore delete errors and try to create the admin file
	; again.
	;
		call	AdminDeleteMessageFiles
		jmp	tryAgain

die:
		WARNING	MAILBOX_CANNOT_OPEN_OR_DELETE_ADMIN_FILE
		call	UtilUnlockDS
		stc
		jmp	done

fileOpen:
	;
	; Admin file is now open or created. Store the handle away, please.
	; 
		call	UtilUnlockDS
		segmov	ds, dgroup, cx
		assume	ds:dgroup
		mov	ds:[adminInitFile], bx	; for initialization code
	;
	; If the file was just created, it needs to be initialized.
	; 
		cmp	ax, VM_CREATE_OK
		jne	initTransient

noMap:		
		call	AdminInitFile

initTransient:
	;
	; If by some strange chance, the file got created without a map block,
	; pretend the file was just created.
	; 
		call	VMGetMapBlock
		tst	ax
		jz	noMap
		mov	ds:[adminMap], ax
	;
	; Make sure the file is compatible with our expectations, or make it
	; that way...
	; 
		call	AdminInitVerifyProtocol
		jnc	protocolOK
	;
	; Couldn't make it that way -- silently delete the thing and create
	; a new one.
	;
		mov	bx, handle uiAdminFileName
		call	MemLock
		mov	ds, ax
		assume 	ds:segment uiAdminFileName
		mov	dx, ds:[uiAdminFileName]
		jmp	deleteAndRetry
		
protocolOK:
		assume	ds:dgroup
	;
	; Now reset the data structures that are per-session.
	; 
		call	VMLock
		mov	ds, ax
	;
	; First, the media status & transport maps. The function is free to
	; change the blocks used for this stuff, so we need to store the
	; results after the call...
	; 
		mov	cx, ds:[AMB_mediaTrans]
		mov	ax, ds:[AMB_media]
		call	MediaInit
		mov	ds:[AMB_mediaTrans], cx
		mov	ds:[AMB_media], ax
	;
	; Next, the VM Store
	; 
		mov	ax, ds:[AMB_vmStore]
		call	VMStoreInit
		mov	ds:[AMB_vmStore], ax
	;
	; Initialize the driver maps.
	; 
		mov	ax, ds:[AMB_dataMap]
		push	ax
		call	DMapInit
		mov	ax, ds:[AMB_transMap]
		push	ax
		call	DMapInit
	;
	; Initialize Inbox
	;
		call	InboxInit
	;
	; Initialize Outbox
	;
		call	OutboxInit
	;
	; That done, we dirty the map block and boogie.
	; 
		call	VMDirty
		call	VMUnlock
	;
	; But wait! There's more! We need to perform some integrity checks on
	; the file, and clean up what we can...
	; 
		call	AdminFixFile
		call	VMUpdate


	;
	; Hook up necessary callbacks to GCNSLT_FILE_SYSTEM.  We don't want to
	; to do it before calling AdminFixFile, or else when it validates
	; message bodies by calling DR_MBDD_CHECK_INTEGRITY, the drivers may
	; change files which will cause MSG_NOTIFY_FILE_CHANGE being queued to
	; this thread.  If there are too many messages in inbox/outbox, we run
	; out of handles.
	;
		pop	ax		; ax = transport driver map
		call	DMapRegisterFileChange
		pop	ax		; ax = data driver map
		call	DMapRegisterFileChange

		call	InboxRegisterFileChange
	;
	; Finally, now the file is ready for prime time, store its handle
	; away and wake up anyone who was waiting on it.
	;
		segmov	ds, dgroup, ax
		mov	ds:[adminFile], bx
		mov	bx, offset adminInitQueue
		call	ThreadWakeUpQueue
	;
	; Set up a timer to periodically synchronize the admin file
	;
		mov	dx, offset adminFileUpdatePeriodKey
		mov	ax, ADMIN_FILE_UPDATE_DEFAULT_PERIOD
		mov	di, ADMIN_FILE_UPDATE_MIN_PERIOD
		mov	bx, MSG_MA_START_ADMIN_FILE_UPDATE_TIMER
		call	InboxStartTimerCommon
	;
	; Get time to wait till automatic-delivery of message.
	;
		call	AdminInitAutoDeliveryTimeout

		clc
done:
		call	FilePopDir
		.leave
		ret
AdminInit	endp

adminFileUpdatePeriodKey	char	"adminFileUpdatePeriod", C_NULL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminDeleteMessageFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete ALL files in privdata\mailbox directory.

CALLED BY:	(INTERNAL) AdminInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Delete errors are ignored.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/ 2/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
allFilesWildcard	TCHAR	"*", C_NULL

AdminDeleteMessageFiles	proc	near
	uses	bx, bp, ds
	.enter

	clr	cx			; for czr and SysCopyToStackDSBX

if	_FXIP
	segmov	ds, cs
	mov	bx, offset allFilesWildcard
	call	SysCopyToStackDSBX
endif	; _FXIP

	sub	sp, size FileEnumParams
	mov	bp, sp
	mov	ss:[bp].FEP_searchFlags, FILE_ENUM_ALL_FILE_TYPES \
			or mask FESF_CALLBACK
	czr	cx, ss:[bp].FEP_returnAttrs.segment
	mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME
	mov	ss:[bp].FEP_returnSize, size FileLongName
	czr	cx, ss:[bp].FEP_matchAttrs.segment
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
	czr	cx, ss:[bp].FEP_skipCount
	mov	ss:[bp].FEP_callback.offset, FESC_WILDCARD
	czr	cx, ss:[bp].FEP_callback.segment
if	_FXIP
	movdw	ss:[bp].FEP_cbData1, dsbx
else
	mov	ss:[bp].FEP_cbData1.segment, cs
	mov	ss:[bp].FEP_cbData1.offset, offset allFilesWildcard
endif	; _FXIP
	call	FileEnum
FXIP <	call	SysRemoveFromStack					>
	jc	done
	jcxz	done

	;
	; Loop thru each FileLongName and try to delete the file.
	;
	call	MemLock
	mov	ds, ax
	clr	dx			; ds:dx = first FileLongName

fileLoop:
	call	FileDelete		; ignore error
	add	dx, size FileLongName
	loop	fileLoop

	call	MemFree			; free FileLongName buffer

done:
	.leave
	ret
AdminDeleteMessageFiles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the Admin file

CALLED BY:	(INTERNAL) AdminInit
PASS:		bx	= handle of the admin file
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminInitFile	proc	near
		uses	di, ds, es
		.enter
	;
	; Set the protocol number for the file.
	; 
		mov	ax, ADMIN_PROTO_MINOR
		push	ax
		mov	ax, ADMIN_PROTO_MAJOR
		push	ax
		mov	di, sp
		segmov	es, ss
		mov	cx, size ProtocolNumber
		mov	ax, FEA_PROTOCOL
		call	FileSetHandleExtAttributes
EC <		ERROR_C	UNABLE_TO_SET_ADMIN_FILE_PROTOCOL		>
		add	sp, 4

	;
	; Allocate a map block for the file and lock it down.
	; 
		mov	cx, size AdminMapBlock
		mov	ax, MBVMID_MAP_BLOCK
		call	VMAlloc
		
		call	VMSetMapBlock
		call	VMLock
		mov	ds, ax

	;
	; Create the inbox & outbox.
	; 
		call	InboxCreate
		mov	ds:[AMB_inbox], ax
		mov	ds:[AMB_appTokens], cx

		call	OutboxCreate
		mov	ds:[AMB_outbox], ax
		mov	ds:[AMB_outboxMedia], cx
		mov	ds:[AMB_outboxReasons], dx
	;
	; Create the data driver map. No one needs to know when a data
	; driver is added to the map, thanks.
	; 
		push	ds, bx
		mov	bx, handle uiDataDriverDir
		call	MemLock
		mov	es, ax
		mov	ds, ax
		assume	es:segment uiDataDriverDir, ds:segment uiDataDriverToken
		mov	ax, MBDD_PROTO_MAJOR
		mov	bx, MBDD_PROTO_MINOR
		mov	cx, enum UtilNewDataDriver
		mov	si, ds:[uiDataDriverToken]
		mov	di, ds:[uiDataDriverDir]
		clr	dx		; no flags here
		call	DMapAlloc
		push	ax		; save handle for stuffing in map block
	;
	; Create the transport driver map. The Media module needs to know each
	; time a transport driver is added to the map.
	; 
		mov	ax, MBTD_PROTO_MAJOR
		mov	bx, MBTD_PROTO_MINOR
		mov	cx, enum MediaNewTransport
		mov	si, ds:[uiTransDriverToken]
		mov	di, ds:[uiTransDriverDir]
		mov	dl, mask DMAPF_AUTO_DETECT
		call	DMapAlloc
		pop	cx		; cx <- data map handle
		call	UtilUnlockDS
		pop	ds, bx
		assume	ds:nothing
		mov	ds:[AMB_transMap], ax
		mov	ds:[AMB_dataMap], cx
	;
	; Initialize the media status map.
	; 
		clr	ax, cx
		call	MediaInit
		mov	ds:[AMB_mediaTrans], cx
		mov	ds:[AMB_media], ax
	;
	; Initialize the VM storage map.
	; 
		clr	ax
		call	VMStoreInit
		mov	ds:[AMB_vmStore], ax
	;
	; Start the tal ID off at 1, as we never want to return 0 (0 => all
	; addresses)
	; 
		mov	ds:[AMB_nextTALID], 1
	;
	; Done.
	; 
		call	VMDirty
		call	VMUnlock
		.leave
		ret
AdminInitFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminInitVerifyProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the file has a compatible protocol, or arrange
		to make it compatible

CALLED BY:	(INTERNAL) AdminInit
PASS:		bx	= handle of admin file
RETURN:		carry set if file is incompatible and can't be made
			compatible:
			bx	= destroyed & file closed.
		carry clear if happy
DESTROYED:	nothing
SIDE EFFECTS:	file protocol possibly changed & map block updated

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminInitVerifyProtocol proc	near
		uses	ax, cx, di, es
		.enter
	;
	; Fetch the file's protocol number.
	; 
		mov	cx, size ProtocolNumber
		sub	sp, cx
		mov	di, sp
		segmov	es, ss
		mov	ax, FEA_PROTOCOL
		call	FileGetHandleExtAttributes
		    CheckHack <size ProtocolNumber eq 4>
		    CheckHack <offset PN_major eq 0>
		    CheckHack <offset PN_minor eq 2>
		popdw	cxax		; cx <- minor, ax <- major
		WARNING_C	ADMIN_FILE_HAS_NO_PROTOCOL
		jc	deathDeathDeath
		
		cmp	ax, ADMIN_PROTO_MAJOR
		WARNING_A	ADMIN_FILE_HAS_LATER_MAJOR_PROTOCOL
		ja	deathDeathDeath
		jb	upgradeMajor
	;
	; We assume a later minor protocol is backwards-compatible and we
	; won't be messing anything up by using the file.
	; 
		cmp	cx, ADMIN_PROTO_MINOR
		WARNING_A	ADMIN_FILE_HAS_LATER_MINOR_PROTOCOL
		jae	ok
	;
	; UPGRADE FROM EARLIER MINOR PROTOCOL HERE
	; 
upgradeMinor::
		clc
ok:
done:
		.leave
		ret

upgradeMajor::
	;
	; UPGRADE FROM EARLIER MAJOR PROTOCOL HERE
	; 
;;; until that work is done, we just delete if major protocol different
;;;		clc
;;;		jmp	ok

deathDeathDeath:
		call	VMClose
		stc
		jmp	done
AdminInitVerifyProtocol endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminInitAutoDeliveryTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the auto-delivery timeout value from the init file.  The
		timeout value is the amount of time we should wait for no
		user input before automatically sending a message.

CALLED BY:	(INTERNAL) AdminInit
PASS:		nothing
RETURN:		ds	= dgroup
DESTROYED:	ax, cx, dx, si
SIDE EFFECTS:	adminAutoDeliveryTimeout initialized

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminInitAutoDeliveryTimeout	proc	near

	mov	cx, cs
	mov	dx, offset adminAutoTimeoutKey	; cx:dx = key
	mov	ds, cx
	mov	si, offset adminMailboxCategory	; ds:si = category
	mov	ax, AUTO_DELIVERY_DEFAULT_TIMEOUT
	call	InitFileReadInteger		; ax = # of seconds

	;
	; convert seconds to ticks
	;
	mov	dx, 60			; # of ticks in one second
	mul	dx
	jnc	inRange			; jump if dxax <= 0xffff
	mov	ax, 0xffff

inRange:
	segmov	ds, dgroup, dx
	mov	ds:[adminAutoDeliveryTimeout], ax

	ret
AdminInitAutoDeliveryTimeout	endp

adminMailboxCategory	char	"mailbox", C_NULL
adminAutoTimeoutKey	char	"autoDeliveryTimeout", C_NULL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminFixFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the file is in a consistent state after a crash.

CALLED BY:	(INTERNAL) AdminInit
PASS:		bx	= admin file
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminFixFile	proc	near
		uses	ax, cx, dx, si, di, ds
		.enter
	;
	; Init all the outbox media reference counts to 1.  This reference will
	; be removed later.
	;
		call	OutboxMediaInitRefCounts
	;
	; Locate all the DBQs and fix up the reference counts for items in
	; them.
	;
		call	AdminFixRefCounts
	;
	; Now remove the one reference we added during initialization above.
	;
		call	OutboxMediaDecRefCounts
	;
	; Nuke all the non-inbox or -outbox DBQs.
	;
		call	AdminNukeUnneededDBQs
	;
	; Any message not in the inbox or outbox will now have a ref count of
	; 2, one from the queue of all known messages, and one from the
	; initial reference added by AdminFixRefCounts. For these messages,
	; we wish to reduce their ref count to 1 so when we biff the
	; queue of all messages, they go away.
	;
		mov	di, bp
		mov	cx, SEGMENT_CS
		mov	dx, offset AdminFixFileCallback
		call	DBQEnum
	;
	; Now biff the queue of all messages.
	;
		call	DBQDestroy
	;
	; Fixup what needs fixing in the outbox.
	;
		call	OutboxFix
	;
	; Ditto for the inbox.
	;
		call	InboxFix
		.leave
		ret
AdminFixFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminFixFileCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove extra reference to the message if the only queue
		it's on is the queue of all messages.

CALLED BY:	(INTERNAL) AdminFixFile via DBQEnum
PASS:		bx	= admin file
		sidi	= MailboxMessage to check
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	si, di, dx, ax
SIDE EFFECTS:	reference removed if refCount currently 2

PSEUDO CODE/STRATEGY:
	Any message not in the inbox or outbox will now have a ref count of
	2, one from the queue of all known messages, and one from the
	initial reference added by AdminFixRefCounts. For these messages,
	we wish to reduce their ref count to 1 so when we biff the
	queue of all messages, they go away.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminFixFileCallback proc	far
		uses	ds
		.enter
		movdw	dxax, sidi
		call	MessageLock
		mov	di, ds:[di]
		Assert	ge, ds:[di].MMD_dbqData.DBQD_refCount, 2
		cmp	ds:[di].MMD_dbqData.DBQD_refCount, 2
		call	UtilVMUnlockDS
		jne	done
		call	DBQDelRef
done:
		clc
		.leave
		ret
AdminFixFileCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminFixRefCounts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all the DBQs in the file and fix up the reference
		counts for the items in them.

CALLED BY:	(INTERNAL) AdminFixFile
PASS:		bx	= admin file
RETURN:		^vbx:bp	= DBQ of all known messages
DESTROYED:	ax, cx, dx, si, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminFixRefCounts proc	near
		.enter
	;
	; Create a queue so we know which messages we've seen.
	;
		mov	dx, DBQ_NO_ADD_ROUTINE
		call	MessageCreateQueue
		mov_tr	bp, ax
		
		clr	di
hugeArrayLoop:
	;
	; Find the next huge array in the file.
	;
		mov	cx, di
		mov	ax, SVMID_HA_DIR_ID
		call	VMFind
		jc	done
	;
	; Discard the huge array if some data blocks are missing.
	;
		push	di, bp
		clr	bp
		call	VMInfoVMChain
		mov_tr	di, ax		; di <- current array
		pop	ax, bp		; ax <- prev array
		jnc	fixArray
		call	HugeArrayDestroy
	;
	; Re-create the inbox queue if we have just destroyed it.
	;
		mov	cx, di		; cx <- array just destroyed
		call	AdminGetInbox	; di <- inbox queue
		cmp	cx, di
		jne	checkOutbox

		mov_tr	di, ax		; di <- prev array
		call	InboxCreateQueue	; ax <- queue
		mov	si, offset AMB_inbox
		jmp	storeQueue
checkOutbox:
	;
	; Re-create the outbox queue if we have just destroyed it.
	;
		call	AdminGetOutbox	; di <- outbox queue
		cmp	cx, di
		mov_tr	di, ax		; di <- prev array
		jne	hugeArrayLoop

		call	OutboxCreateQueue	; ax <- queue
		mov	si, offset AMB_outbox
storeQueue:
		push	bp
		call	AdminLockMap
		mov	ds:[si], ax
		call	VMDirty
		call	VMUnlock
		pop	bp
	;
	; Continue in the loop.  We may or may not run into the newly created
	; queue later.  But if we do, the queue should still be empty and we'll
	; just do nothing.
	;
		jmp	hugeArrayLoop
fixArray:
	;
	; Go thru all the chunk arrays in this huge array and reset all
	; CAH_curOffset to 0.  (Do it even if it's not a DBQ.)
	;
		call	UtilFixHugeArray
	;
	; See if it's a DBQ
	;
		call	DBQCheckIsDBQ
		jnc	hugeArrayLoop		; => not a DBQ
	;
	; Please don't process the list of all messages we're building. This
	; will add an extra reference to the message that will never be removed.
	;
		cmp	di, bp
		je	hugeArrayLoop
	;
	; It is -- process all the items in it.
	;
		mov	cx, SEGMENT_CS
		mov	dx, offset AdminFixRefCountsCallback
		call	DBQEnum
		jmp	hugeArrayLoop

done:
		.leave
		ret
AdminFixRefCounts endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminFixRefCountsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a reference to this message for being in this queue.

CALLED BY:	(INTERNAL) AdminFixRefCounts via DBQEnum
PASS:		bx	= admin file
		sidi	= DBGroupAndItem
		bp	= DBQ of messages that have been seen already
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	si, di, bx
SIDE EFFECTS:	entry may be added to ^vbx:bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminFixRefCountsCallback proc	far
		uses	ds
		.enter
	;
	; See if we've initialized the reference count yet. We know we've
	; initialized it if the thing's in ^vbx:bp
	;
		movdw	dxax, sidi
		mov	di, bp
		call	DBQCheckMember
		jc	addRef
	;
	; Haven't yet -- start the count at 1 please, so a DBQFree is needed
	; to finally get rid of the thing.
	;
	; 11/1/95: clear the trans-win flags here, as a convenient place to
	; do it (we want to do it for both inbox and outbox) -- ardeb
	;
		call	MessageLock
		mov	di, ds:[di]
		mov	ds:[di].MMD_dbqData.DBQD_refCount, 1
		andnf	ds:[di].MMD_flags, 
			not (mask MIMF_NOTIFIED_TRANS_WIN_OPEN or \
			     mask MIMF_NOTIFIED_TRANS_WIN_CLOSE)

		mov	si, ds:[di].MMD_transAddrs
		tst	si
		jz	addrsFixed
		call	UtilFixChunkArray
addrsFixed:
		CmpTok	ds:[di].MMD_transport, MANUFACTURER_ID_GEOWORKS, \
				GMTID_LOCAL
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		je	addToDBQ
	;
	; This message is in outbox.  Add media references for its addresses.
	;
		call	OutboxMediaAddRefForMsg
addToDBQ:
	;
	; Now add the thing to our temporary queue so we don't do this again...
	;
		mov	di, bp
		call	DBQAdd
addRef:
	;
	; Add another reference to the message for being in this queue.
	;
		call	DBQAddRef
		
		clc			; keep enumerating
		.leave
		ret
AdminFixRefCountsCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdminNukeUnneededDBQs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete any DBQ we find that's neither the inbox nor the
		outbox, as no other queues should exist now.

CALLED BY:	(INTERNAL) AdminFixFile
PASS:		bx	= admin file
		bp	= DBQ of all messages
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdminNukeUnneededDBQs proc	near
		.enter
	;
	; Locate all the huge arrays and check with the DBQ module to delete
	; them if they are a DBQ and neither the inbox nor the outbox
	; 
		call	AdminGetOutbox
		mov	si, di
		call	AdminGetInbox
		mov	dx, di
		clr	ax
hugeArrayLoop:
		mov_tr	cx, ax
		mov	ax, SVMID_HA_DIR_ID
		call	VMFind
		jc	done

		cmp	ax, si		; outbox?
		je	hugeArrayLoop	; yes -- leave it
		cmp	ax, dx		; inbox?
		je	hugeArrayLoop	; yes -- leave it
		cmp	ax, bp		; all-messages?
		je	hugeArrayLoop	; yes -- leave it

		mov	di, ax
		call	DBQCheckIsDBQ
		jnc	hugeArrayLoop

		call	DBQDestroy
		jmp	hugeArrayLoop

done:
		.leave
		ret
AdminNukeUnneededDBQs endp

Init	ends
