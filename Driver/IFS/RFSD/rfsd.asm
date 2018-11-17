COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		RFS (Remote File System) Driver
FILE:		rfsd.asm

AUTHOR:		In Sik Rhee  4/92

ROUTINES:
	Name			Description
	----			-----------
	RFStrategy		Strategy Function
	RFSecondaryStrategy	2nd strat.
	RFEntryCallFunction	Dispatches calls to the correct function
	InitRFSD		DR_INIT (Entry Point to Driver)
	RFOpenConnection	open a connection with remote host
	InitHandShake		initialization thread
	ExitRFSD		DR_EXIT
	RFCloseConnection	close current connection
	RFGetStatus		return current status of RFSD
	RFDoNothing		Unsupported FSFunctions go here
	RFHandOff		DR_FS_DISK_LOCK, DR_FS_DISK_UNLOCK, 
				DR_FS_DISK_FIND_FREE, DR_FS_CUR_PATH_GET_ID
	RFDiskDriveNumber	DR_FS_DISK_ID, DR_FS_DRIVE_LOCK, 
				DR_FS_DRIVE_UNLOCK
	RFDiskInit		DR_FS_DISK_INIT
	RFDiskInfo		DR_FS_DISK_INFO
	RFDiskSave		DR_FS_DISK_SAVE
	RFDiskRename		DR_FS_DISK_RENAME
	RFCurPathSet		DR_FS_CUR_PATH_SET
	RFCurPathDelete		DR_FS_CUR_PATH_DELETE
	RFCurPathCopy		DR_FS_CUR_PATH_COPY
	RFHandleOp		DR_FS_HANDLE_OP
	RFAllocOp		DR_FS_ALLOC_OP
	RFPathOp		DR_FS_PATH_OP
	RFCompareFiles		DR_FS_COMPARE_FILES
	RFFileEnum		DR_FS_FILE_ENUM
	CallRemote		Makes remote call
	SendMessageRemote	sends message to remote machine, returns reply

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	4/10/92		Getting started


DESCRIPTION:

	The RFSD works like this:

	first, a port is opened and a callback routine (server loop) supplied.
	this is our server.  any messages that the server processes (incoming)
	gets sent to the dispatch thread (an event process).  This way, the
	server is free to process other incoming messages while the dispatch
	thread does its job.

	an initialization is spawned.  it's sole purpose is to try
	to send a handshake message to the remote machine.  when the server
	receives a handshake message, then the server will send the drive
	descriptions to the client, and a 1-way connection will be made
	between the host and server.  (since both RFSD's will send init
	messages, we are ending up with a 2-way connection, with a server
	on both sides).  

	when a client (app, kernel, or other drivers) makes a call to a 
	drive that belongs on the server side, then the RFSD will package
	the call (RFSHeader and RFSRegisters, plus extra data if necessary)
	and make the remote call.  the remote server will extract the data
	and call it's FSD, and return a reply.  The client (which waits until
	a reply is given, or times out) will then unpackage the reply and
	return it to the user.  

	since the RFSD is a completely application transparent driver, any
	file function that is possible *should* work the same way remotely
	(i.e. create/open/close/write/read files, launch app's, etc)

	the RFSD's multi-threaded design allows several applications to
	request remote file services at once.  the requests will be sent
	out the port in order, and the replies processed in order (not
	necessary the same order as the requests).  this means that app A
	and B may do a file action simultaneously, and whichever task
	gets done first will regain execution first.

	also, since both machines play host, machine B may be utilizing 
	machine A's drives as machine A accesses machine B's.  (performance
	will, of course, be dramatically slower)

	the RFSD is not serial-dependent, although that's what it utilizes
	at this moment.  once a 2-way parallel driver exists, the RFSD can
	be modified utilize that, or any other peer-to-peer connection which 
	can be implemented between 2 machines (infra-red, modem, etc)

	$Id: rfsd.asm,v 1.1 97/04/18 11:46:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

DefFSFunction	macro	routine, constant
.assert ($-fsFunctions) eq constant*2, <Routine for constant in the wrong slot>
.assert (type routine eq far)
		fptr.far	routine
		endm

fsFunctions	label	fptr.far
DefFSFunction InitRFSD,			DR_INIT
DefFSFunction ExitRFSD,			DR_EXIT
DefFSFunction RFDoNothing,		DR_SUSPEND		;Unsupported
DefFSFunction RFDoNothing,		DR_UNSUSPEND		;Unsupported
DefFSFunction RFDoNothing,		DRE_TEST_DEVICE		;Unsupported
DefFSFunction RFDoNothing,		DRE_SET_DEVICE		;Unsupported
DefFSFunction RFDiskDriveNumber,	DR_FS_DISK_ID
DefFSFunction RFDiskInit,		DR_FS_DISK_INIT
DefFSFunction RFHandOff,		DR_FS_DISK_LOCK
DefFSFunction RFHandOff,		DR_FS_DISK_UNLOCK
DefFSFunction RFDoNothing,		DR_FS_DISK_FORMAT	;Unsupported, all imported drives are marked unformattable now (See RFSDUseRemoteDrives)
DefFSFunction RFHandOff,		DR_FS_DISK_FIND_FREE
DefFSFunction RFDiskInfo,		DR_FS_DISK_INFO
DefFSFunction RFDiskRename,		DR_FS_DISK_RENAME	
DefFSFunction RFDoNothing,		DR_FS_DISK_COPY		;Unsupported
DefFSFunction RFDiskSave,		DR_FS_DISK_SAVE
DefFSFunction RFDoNothing,		DR_FS_DISK_RESTORE	;Unsupported
DefFSFunction RFDoNothing,		DR_FS_CHECK_NET_PATH	;Unsupported
DefFSFunction RFCurPathSet,		DR_FS_CUR_PATH_SET
DefFSFunction RFCurPathGetID,		DR_FS_CUR_PATH_GET_ID
DefFSFunction RFCurPathDelete,		DR_FS_CUR_PATH_DELETE
DefFSFunction RFCurPathCopy,		DR_FS_CUR_PATH_COPY
DefFSFunction RFHandleOp,		DR_FS_HANDLE_OP		
DefFSFunction RFAllocOp,		DR_FS_ALLOC_OP	
DefFSFunction RFPathOp,			DR_FS_PATH_OP		
DefFSFunction RFCompareFiles,		DR_FS_COMPARE_FILES	
DefFSFunction RFFileEnum,		DR_FS_FILE_ENUM		
DefFSFunction RFDiskDriveNumber,	DR_FS_DRIVE_LOCK
DefFSFunction RFDiskDriveNumber,	DR_FS_DRIVE_UNLOCK
CheckHack <($-fsFunctions)/2 eq FSFunction>

DefSFSFunction	macro	routine, constant
.assert ($-rfsdFunctions) eq (constant-FSFunction)*2, <Routine for constant in the wrong slot>
.assert (type routine eq far)
		fptr.far	routine
		endm
rfsdFunctions	label	fptr.far
DefSFSFunction	RFOpenConnection,	DR_RFS_OPEN_CONNECTION
DefSFSFunction	RFCloseConnection,	DR_RFS_CLOSE_CONNECTION
DefSFSFunction	RFGetStatus		DR_RFS_GET_STATUS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy Routine

CALLED BY:	Kernel
PASS:		di - function code
RETURN:		variable
DESTROYED:	variable

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFStrategy	proc	far
	uses	ds,es
	.enter
EC <	cmp	di, RFSFunction					>
EC <	ERROR_AE	INVALID_FS_FUNCTION			>
EC <	test	di, 1						>
EC <	ERROR_NZ	INVALID_FS_FUNCTION			>
	cmp	di, DR_FS_DRIVE_UNLOCK
	ja	localCall
	cmp	di, DR_FS_DISK_ID
	jae	nonLocalCall
localCall:
	jmp	doCall	
nonLocalCall:
	push	es,di
	segmov	es,dgroup,di
	tst	es:[closingConnection]
	jz	connected
EC <  	WARNING WARNING_DISCONNECTED					>
	pop	es,di

;	We still want people to be able to close their files, even though
;	the connection is broken, so allow FSHOF_CLOSE and FSHOF_CHECK_DIRTY
;	to work

	cmp	di, DR_FS_HANDLE_OP
	jne	doExit
	cmp	ah, FSHOF_CLOSE
	je	noErr
	cmp	ah, FSHOF_CHECK_DIRTY
	jne	doExit
noErr:
	clr	ax			;Nuke error flag/dirty status
	clc
	jmp	exit
doExit:
	mov	ax, ERROR_DRIVE_NOT_READY
	stc
	jmp	exit
connected:

;
;	We are doing a FS call. Once we do an operation that will cause a
;	file change notification to be created, we start a timer to flush
;	out the batched notifications when we haven't gotten an FS call in
;	a few seconds. If a timer exists already, we stop it, and restart
;	it after this call.
;
;	If no timer exists, we only create one if the operation we are
;	performing will cause a file change notification to be generated.
;
	push	ax, bx
	call	GrabNotificationTimer
	clr	bx
	xchg	bx, es:[notificationTimer]
	clr	ax
	xchg	ax, es:[notificationTimerID]
	tst	bx
	jz	noTimer
	call	TimerStop
	pop	ax, bx
	pop	es,di

createTimerAfterCall:

	shl	di
	add	di, offset fsFunctions
	call	RFEntryCallFunction

;	Start the new timer here.

	pushf
	push	ax, bx, cx, dx, bp, es
	segmov	es, dgroup, ax
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, es:[connectionThread]
	mov	cx, IDLE_TIME_UNTIL_NOTIFICATION_FLUSH
	mov	dx, MSG_RFSD_FLUSH_REMOTE_NOTIFICATIONS
	mov	bp, handle 0
	call	TimerStartSetOwner
	mov	es:[notificationTimerID], ax
	mov	es:[notificationTimer], bx
	call	ReleaseNotificationTimer
	pop	ax, bx, cx, dx, bp, es
	popf
	jmp	exit
noTimer:

;	We don't have a timer running yet. If this is an operation that can
;	generate FileChange notifications, then start the timer up. Otherwise
;	just perform the operation.

	pop	ax, bx
	pop	es, di
	cmp	di, DR_FS_HANDLE_OP
	jz	createTimerAfterCall
	cmp	di, DR_FS_ALLOC_OP
	jz	createTimerAfterCall
	cmp	di, DR_FS_PATH_OP
	jz	createTimerAfterCall
	call	ReleaseNotificationTimer

doCall:	
	shl	di
	add	di, offset fsFunctions
	call	RFEntryCallFunction

exit:
	.leave
	ret
RFStrategy	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSecondaryStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Secondary strategy routine

CALLED BY:	Primary IFS driver
PASS:		di - RFSFunction
RETURN:		variable
DESTROYED:	variable

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSecondaryStrategy	proc	far
	.enter
EC <	cmp	di, RFSFunction					>	
EC <	ERROR_AE	INVALID_SECONDARY_FUNCTION		>
EC <	test	di, 1						>
EC <	ERROR_NZ	INVALID_SECONDARY_FUNCTION		>
	shl	di
	add	di, offset rfsdFunctions
	call	RFEntryCallFunction
	.leave
	ret
RFSecondaryStrategy	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFEntryCallFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the function whose fptr is pointed to by cs:di

CALLED BY:	RFStrategy, RFSecondaryStrategy
PASS:		cs:di = fptr.fptr.far
		si    = function code
RETURN:		variable
DESTROYED:	bp destroyed before target function called

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RFMovableFrame	struct
    RFMF_routine	fptr.far
    RFMF_handle		hptr
RFMovableFrame	ends

RFEntryCallFunction proc near
		.enter
		cmp	cs:[di].segment, MAX_SEGMENT
		jae	movable
		call	{fptr.far}cs:[di]
done:
		.leave
		ret
movable:
	;
	; Target is movable, so lock down the code resource and call
	; it.
	; 
		sub	sp, size RFMovableFrame
		mov	bp, sp
		push	ax, bx
		mov	bx, cs:[di].segment
		shl	bx		; shift left four
		shl	bx		;  times to convert
		shl	bx		;  virtual segment to
		shl	bx		;  handle
		call	MemLock

		mov	ss:[bp].RFMF_routine.segment, ax
		mov	ss:[bp].RFMF_handle, bx	; save handle for unlock
		mov	ax, cs:[di].offset
		mov	ss:[bp].RFMF_routine.offset, ax
		pop	ax, bx

		call	ss:[bp].RFMF_routine
	;
	; Unlock the code resource and clear the stack of our little frame.
	; 
		CheckHack <offset RFMF_handle+size RFMF_handle eq \
				size RFMovableFrame>

		mov	bp, sp
		xchg	bx, ss:[bp].RFMF_handle	; bx <- code handle, saving
						;  possible return value
		call	MemUnlock
		lea	sp, ss:[bp].RFMF_handle	; clear extra stuff off the
						;  stack
		pop	bx			;  and recover bx for return
		jmp	done
RFEntryCallFunction endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDMemAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a memory block, making it owned by the RFSD
		driver, rather than whatever random app loaded this
		driver.  This is necessary, because if the app exits,
		the block will be freed, which is bad.

CALLED BY:	internal

PASS:		same as MemAlloc

RETURN:		same as MemAlloc

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDMemAlloc	proc far
		mov	bx, handle 0
		GOTO	MemAllocSetOwner
RFSDMemAlloc	endp


Resident ends

Client	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFGetStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns current status of the driver

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		ax - RFStatus
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFGetStatus	proc	far
	uses	es
	.enter
	segmov	es, dgroup, ax
	mov	ax, RFS_DISCONNECTED
	tst	es:[connectionThread]
	jz	exit

;	We have a connection thread, so see if we're disconnecting or not.

	mov	ax, RFS_DISCONNECTING
	tst	es:[closingConnection]
	jnz	exit

	mov	ax, RFS_CONNECTED
	tst	es:[haveDrives]
	jnz	exit
	mov	ax, RFS_CONNECTING
exit:
	.leave
	ret
RFGetStatus	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pass.

CALLED BY:	lots of things
PASS:		nothing
RETURN:		carry clear
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFDoNothing	proc	far
	clc
	ret
RFDoNothing	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFHandOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hand off a function to the remote server

CALLED BY:	DR_FS_DISK_LOCK, DR_FS_DISK_UNLOCK, DR_FS_DISK_FIND_FREE,
		DR_FS_CUR_PATH_GET_ID, DR_FS_COMPARE_FILES
PASS:		es:si - DiskDesc
		ax,cx,dx - variables
RETURN:		variable
DESTROYED:	variable

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFHandOff	proc	far
	uses	bx,si
	.enter
;convert DI back to its FSFunction enum
	sub	di, offset fsFunctions
	shr	di
	call	GetRemoteDiskHandle		; bx - remote disk handle
	clr	bp
	call	CallRemote
ifdef DEBUGGING
	WARNING_NC	RF_HANDOFF
	WARNING_C	RF_HANDOFF_CARRY
endif
	.leave
	ret
RFHandOff	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurPathHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the remote handle corresponding to the current path

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		dx - handle of current path
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurPathHandle	proc	near	uses	ax, bx, es
	.enter
	mov	bx, ss:[TPD_curPath]
	call	MemLock
	mov	es,ax
	mov	dx,es:[HF_private]		; dx - remote path handle
	call	MemUnlock
	 .leave
	ret
GetCurPathHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFCurPathGetID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current path ID

CALLED BY:	DR_FS_CUR_PATH_GET_ID
PASS:		es:si - DiskDesc
		ax,cx,dx - variables
RETURN:		variable
DESTROYED:	variable

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFCurPathGetID	proc	far
	uses	bx,si
	.enter
	mov	di, DR_FS_CUR_PATH_GET_ID
	call	GetCurPathHandle		;DX <- current path handle
	call	GetRemoteDiskHandle		;BX <- remote disk handle
	clr	bp
	call	CallRemote
ifdef DEBUGGING
	WARNING_NC	RF_GET_ID
	WARNING_C	RF_GET_ID_CARRY
endif
	.leave
	ret
RFCurPathGetID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFDiskDriveNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_DISK_ID, DR_FS_DRIVE_LOCK, DR_FS_DRIVE_UNLOCK

CALLED BY:	strategy routine
PASS:		es:si = DriveStatusEntry for the drive
RETURN:		DR_FS_DISK_ID:
		carry set if ID couldn't be determined
		carry clear if it could:
			cx:dx = 32-bit ID
			al    = DiskFlags for disk
			ah    = MediaType for disk
		DR_FS_DRIVE_LOCK, DR_FS_DRIVE_UNLOCK:
		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFDiskDriveNumber	proc	far
	uses	bx
	.enter
;convert DI back to its FSFunction enum
	sub	di, offset fsFunctions
	shr	di
	mov	bp, es:[si].DSE_private		; deref to private data
	cmp	di, DR_FS_DISK_ID		
	jz	diskID				
	push	ax				; if DR_FS_DRIVE_*, then 
	push	cx				; save all registers
	push	dx
	mov	al, es:[bp].RFS_number		; remote drive number
	clr	bp
	call	CallRemote
	pop	dx
	pop	cx
	pop	ax
exit:
ifdef DEBUGGING
	WARNING_NC	RF_DRIVE_NUMBER
	WARNING_C	RF_DRIVE_NUMBER_CARRY
endif
	.leave
	ret
diskID:
	mov	al, es:[bp].RFS_number		; remote drive number
	push	ax
	clr	bp
	call	CallRemote
	pop	bx
	jc	exit

;	A disk ID of 0 is only to be used for fixed (non-removable) disks.
;	We map disk IDs of 0 to unique disk IDs. If we exit and restart
;	RFSD, the DiskDesc structures will be reused, because the disk IDs
;	will match.

	tstdw	cxdx
	clc
	jnz	exit
	mov	cx, 'RF'
	mov	dx, 'SD'
	clr	bh			;BX <- drive number
	add	dx, bx
	adc	cx, 0			;Will clear the carry
EC <	ERROR_C	-1							>
	jmp	exit	
RFDiskDriveNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFDiskInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_DISK_INIT

CALLED BY:	RFSD
PASS:		es:si	- DiskDesc
		ah	- FSDNamelessAction
RETURN:		carry set on failure
		carry clear on success:
			es	= fixed up if a chunk was allocated by the FSD
			DD_volumeLabel filled in (space-padded, not
				null-terminated).
			DD_private holding the offset of a chunk of private
				data, if one was allocated.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFDiskInit	proc	far
	uses	ax,bx,cx,dx,si,ds
	.enter
	mov	bh, ah			; bh - FSDNamelessAction
	movdw	cxdx, es:[si].DD_id
	;
	; Cope with the (bizarre) mapping of 0:0 to 'RFSD' by mapping the ID
	; back to the 0:0 that the server is expecting, lest we cause the
	; server to create 2 disk handles for the same fixed disk, thereby
	; mucking up all sorts of in-use checks -- ardeb 10/29/93
	; 
	cmp	cx, 'RF'
	jne	haveID

	mov	di, es:[si].DD_drive
	mov	di, es:[di].DSE_private
	mov	di, {word}es:[di].RFS_number
	andnf	di, 0xff
	add	di, 'SD'

	cmp	dx, di
	jne	haveID
	clrdw	cxdx
haveID:
	mov	di, DR_FS_DISK_INIT
	mov	al, es:[si].DD_flags
	mov	ah, es:[si].DD_media
	mov	bp, es:[si].DD_drive
	mov	bp, es:[bp].DSE_private	
	mov	bl, es:[bp].RFS_number	; bl - drive number (remote)
	clr	bp
	call	CallRemote		; bx - remote handle of disk
	jc	exit
; successful, so we must get to DD_private and fill it with the remote
; disk handle and also fill in DD_volumeLabel
	push	di			; save handle for volume name
	mov	di, es:[si].DD_private	; get to private data
		
	; Private data = remote disk handle

EC <	push	ds, si						>
EC <	segmov	ds, es						>
EC <	mov	si, di						>
EC <	call	ECCheckLMemChunk				>
EC <	pop	ds, si						>

	mov	es:[di].DDPD_RemoteHandle, bx
	pop	bx
	call	MemLock
	mov	ds,ax
	mov	di,si			; es:di - DiskDesc
	clr	si			; ds:si - volume name
	add 	di, offset DD_volumeLabel
	mov	cx, VOLUME_NAME_LENGTH
	call	strncpy			; copy volume name!
	call	MemFree			; free our volume name buffer
	clc
exit:	
ifdef DEBUGGING
	WARNING_NC	RF_DISK_INIT
	WARNING_C	RF_DISK_INIT_CARRY
endif
	.leave
	ret
RFDiskInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFDiskInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_DISK_INFO

CALLED BY:	RFSD
PASS:		bx:cx	- fptr.DiskInfoStruct
		es:si	- DiskDesc of disk whose info is desired (disk is 
				locked shared)
RETURN:		carry set on error
			ax	= error code
		carry clear if successful
			buffer filled in.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFDiskInfo	proc	far
	uses	bx,cx,dx,si,es,ds
	.enter
	mov	di, DR_FS_DISK_INFO
	pushdw	bxcx
	call	GetRemoteDiskHandle
	clr	bp
	call	CallRemote
	mov	bx,di
	popdw	esdi				; es:di - buffer to copy to
	jc	exit

	call	MemLock
	mov	ds,ax
	clr	si				; ds:si - returned buffer
	mov	cx, size DiskInfoStruct
	call	strncpy				; copy DiskInfoStruct
	call	MemFree
ifdef DEBUGGING
	WARNING	RF_DISK_INFO
endif
	clc
exit:
	.leave
	ret
RFDiskInfo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFDiskSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_DISK_SAVE

CALLED BY:	RFSD
PASS:		nothing
RETURN:		cx - 0
		carry clear
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFDiskSave	proc	far
	clr	cx
ifdef DEBUGGING
	WARNING RF_DISK_SAVE
endif
	clc
	ret
RFDiskSave	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFDiskRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_DISK_RENAME

CALLED BY:	RFSD
PASS:		es:si = DiskDesc of disk to be renamed (locked for exclusive
			access)
		ds:dx = new name for disk
RETURN:		carry set on error:
			ax - error code
		carry clear if successfull
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFDiskRename	proc	far
	uses	bx,cx,dx,si
	.enter
	mov	di, DR_FS_DISK_RENAME
	call	GetRemoteDiskHandle		; bx - remote disk handle
	push	si	
	mov	si, dx				; ds:si - name for disk
	call	strlen
	pushdw	dssi				;Pass ptr to extra data and
	push	cx				; size of string
	call	CallRemoteWithBuffer	
	mov	bx,di
	pop	di				; es:di - DiskDesc
	jc	exit
; here, we successfully renamed the volume label so we copy the new volume
; label in our Disk Descriptor
	add	di, DD_volumeLabel		; es:di - target buffer
	call	MemLock
	mov	ds,ax
	clr	si				; ds:si - reply buffer
	mov	cx, VOLUME_NAME_LENGTH	
	call	strncpy
	call	MemFree
	clc
exit:	
ifdef DEBUGGING
	WARNING_NC	RF_DISK_RENAME
	WARNING_C	RF_DISK_RENAME_CARRY
endif
	.leave
	ret
RFDiskRename	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFCurPathSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_CUR_PATH_SET

CALLED BY:	RFSD
PASS:		ds:dx	= path to set, w/o drive specifier
		es:si	= DiskDesc of disk on which the path resides
RETURN:		carry clear if directory-change was successful:
			TPD_curPath block altered to hold the new path and
			any private data required by the FSD (the disk
			handle will be set by the kernel). The FSD may
			have resized the block.
			FP_pathInfo must be set to FS_NOT_STANDARD_PATH
			FP_stdPath must be set to SP_NOT_STANDARD_PATH
			FP_dirID must be set to the 32-bit ID for the directory
		carry set if the directory to which the thread was attempting
		    to change doesn't exist
			ax	= ERROR_PATH_NOT_FOUND
			TPD_curPath may not be altered in any way.
		    or link was encountered.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

When the path gets set, the remote path handle is stored in FP_remotePathHandle

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFCurPathSet	proc	far
	uses	ax,bx,cx,dx,si,es
	.enter
	mov	di, DR_FS_CUR_PATH_SET
	call	GetRemoteDiskHandle		; bx - remote disk handle

;
;	For every client with a CWD on a remote drive, there will be a
;	FilePath handle on the ss:TPD_curPath stack on the remote RFSD
;	thread.
;
;	Every time the client does a FileSetCurrentPath, a
;	DR_FS_CUR_PATH_DELETE call will be made to the fs driver that ran the
;	old path.
;

	mov	si,dx				; ds:si - path to set
	call	strlen				; cx - path length
	pushdw	dssi				;Pass ptr and length
	push	cx
	call	CallRemoteWithBuffer		; bx - path handle
	jc	error
	push	bx				; save path handle
	mov	bx, ss:[TPD_curPath]

; Tell the old FSD we're taking over. 

	call	FSDInformOldFSDOfPathNukage

; Shrink the block down just large enough to store our private data

	mov	ax, size word + size FilePath
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc		; block isn't locked yet...
	pop	cx			;CX <- remote path handle
EC <	call	EnsureNoDuplicatePath					>

	call	MemLock
	mov	es, ax

;	The remote path handle is stored in the private data of the
;	local path handle, so we know what remote path to delete when the 
;	FS_CUR_PATH_DELETE call is made.

	mov	es:[FP_remotePathHandle], cx
	mov	es:[FP_path], offset FP_remotePathHandle + size hptr

; Perform the remaining pieces of initialization.
	mov	es:[FP_stdPath], SP_NOT_STANDARD_PATH
	mov	es:[FP_pathInfo], FS_NOT_STANDARD_PATH

; And unlock the path block; it's ready to go.

	call	MemUnlock
	clc	
error:	
ifdef DEBUGGING
	WARNING_NC	RF_CUR_PATH_SET
	WARNING_C	RF_CUR_PATH_SET_CARRY
endif
	.leave
	ret
RFCurPathSet	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFCurPathDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_CUR_PATH_DELETE

CALLED BY:	RFSD

PASS:		bx	= path handle
		es:si	= DiskDesc on which path is located
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFCurPathDelete	proc	far
	uses	ax,bx,cx,dx,es
	.enter
	mov	ax,bx				; temp storage
	call	GetRemoteDiskHandle		; bx - remote disk handle
	push	bx
	mov	bx,ax
	call	MemLock
	mov	es,ax
	clr	dx
	xchg	dx, {word} es:[FP_remotePathHandle] ; dx - remote path handle
EC <	tst	dx							>
EC <	ERROR_Z RF_CUR_PATH_DELETE_ALREADY_CALLED 			>
	call	MemUnlock

	mov	di, DR_FS_CUR_PATH_DELETE
	clr	bp
	pop	bx
	call	CallRemote	
	clc
ifdef DEBUGGING
	WARNING	RF_CUR_PATH_DELETE
endif
	.leave
	ret
RFCurPathDelete	endp

if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureNoDuplicatePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to be sure that the returned path handle is not already
		being used locally.

CALLED BY:	GLOBAL
PASS:		cx - path handle
		es - segment of FSInfo resource
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureNoDuplicatePath	proc	near	uses	ax, bx, di, es, ds
	.enter
	mov	bx, ss:[TPD_curPath]
loopTop:
	call	MemLock
	mov	ds, ax
	mov	di, ds:[FP_logicalDisk]
	test	di, 0x01			;If odd, is standard path
	jne	notOurs

EC <	call	ECCheckBoundsESDIFar					>
	mov	di, es:[di].DD_drive
EC <	call	ECCheckBoundsESDIFar					>
	mov	di, es:[di].DSE_fsd
EC <	call	ECCheckBoundsESDIFar					>
	cmp	es:[di].FSD_handle, handle 0
	jne	notOurs

;	This path is on one of our drives. Check the privata data field.

	cmp	cx, ds:[FP_remotePathHandle]
EC <	ERROR_Z	DUPLICATE_PATH						>

notOurs:
	mov	ax, ds:[FP_prev]	
	call	MemUnlock
	mov_tr	bx, ax
	tst	bx
	jnz	loopTop
	.leave
	ret
EnsureNoDuplicatePath	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFCurPathCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_CUR_PATH_COPY

CALLED BY:	RFSD

PASS:		bx	= path handle	(new block)
		cx	= path handle 	(old block)
		es:si	= DiskDesc on which path is located
RETURN:		nothing
DESTROYED:	si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFCurPathCopy	proc	far
	uses	ax,bx,cx,dx,es
	.enter
	call	GetCurPathHandle	;DX <- remote path handle
	mov	di, DR_FS_CUR_PATH_COPY
	clr	bp
	push	bx
	call	CallRemote
	pop	bx

;	Set the FP_remotePathHandle field of the newly created path block to
;	hold the path handle on the remote machine

EC <	call	EnsureNoDuplicatePath					>
	call	MemLock
	mov	es,ax
	mov	{word} es:[FP_remotePathHandle],cx	; cx - path handle
	call	MemUnlock
	clc
ifdef DEBUGGING
	WARNING	RF_CUR_PATH_COPY
endif
	.leave
	ret
RFCurPathCopy	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFHandleOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_HANDLE_OP

CALLED BY:	RFSD
PASS:		ah	= FSHandleOpFunction to perform
		bx	= handle of open file
		es:si	= DiskDesc (FSInfoResource and affected drive locked
			  shared)
		other parameters as appropriate.
RETURN:		carry set on error:
			ax	= error code
		carry clear if successful:
			return values depend on subfunction
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RFHandleOp	proc	far
	uses	bx,si
	fileHan			local	hptr	\
				push	bx
	dataCX			local	word	\
				push	cx	
	dataDX			local	word	\
				push	dx
	;dataCX/DX are local variables used to return values for certain
	; FS functions.

	remoteDiskHandle	local	word
	localFEAD		local	FileExtAttrDesc
	; This is used below where we want to read a single FileExtAttr
	function		local	FSHandleOpFunction

	amountRead		local	word
	; The amount of data that has already been read from the file

	amountToRead		local	word
	; The amount of data we're trying to read in this call

	amountWritten		local	word
	; The amount of data that has already been written to the file

	amountToWrite		local	word
	; The amount of data we're trying to write in this call

if	ERROR_CHECK
	ecValue			local	word
endif	
	.enter

;	So much crap is being pushed and popped, I'm a little concerned
;	that I'll mis push/pop, or trash BP, so I'll do some error checking
;	before exiting

	mov	function, ah
EC <	mov	ecValue, 0x1234						>
EC <	mov	bx, 0x4321						>
EC <	push	bx							>
	call	GetRemoteDiskHandle		; bx - remote disk handle
	mov	remoteDiskHandle, bx
	mov	bx, fileHan


	mov	es, es:[FIH_dgroup]
EC <	call	ECCheckSegments						>
	mov	bx, es:[bx].HF_private		; bx - remote file handle

;	Call the appropriate code based on passed here FSHandleOpFunction

	push	ax
	mov	al,ah
	clr	ah
	shl	ax
	mov	di,ax
	pop	ax
EC <	cmp	di, size HandleOpJmpTable				>
EC <	ERROR_AE	RFHANDLEOP_ERROR				>
	jmp	cs:[HandleOpJmpTable][di]

HandleOpJmpTable	nptr	\
	read,      ; FSHOF_READ                  
	write,	   ; FSHOF_WRITE                 
	normal,	   ; FSHOF_POSITION              
	normal,	   ; FSHOF_TRUNCATE              
	normal,	   ; FSHOF_COMMIT                
	lockFile,  ; FSHOF_LOCK                  
	lockFile,  ; FSHOF_UNLOCK                
	normal,	   ; FSHOF_GET_DATE_TIME         
	normal,	   ; FSHOF_SET_DATE_TIME         
	normal,	   ; FSHOF_FILE_SIZE             
	normal,	   ; FSHOF_ADD_REFERENCE        
	normal,	   ; FSHOF_CHECK_DIRTY           
	normal,	   ; FSHOF_CLOSE                 
	normal,	   ; FSHOF_GET_FILE_ID           
	checkNative, ; FSHOF_CHECK_NATIVE          
	getExtAttr,; FSHOF_GET_EXT_ATTRIBUTES    
	setExtAttr,; FSHOF_SET_EXT_ATTRIBUTES    
	getAllAttr,; FSHOF_GET_ALL_EXT_ATTRIBUTES
	normal,	   ; FSHOF_FORGET                
	doNothing  ; FSHOF_SET_FILE_NAME
         
CheckHack <length HandleOpJmpTable eq FSHandleOpFunction>
;
; Registers other than AX returned by functions:
;
;	FSHOF_POSITION			- DX
;	FSHOF_FILE_SIZE			- DX
;	FSHOF_GET_DATE_TIME		- CX,DX
;	FSHOF_GET_FILE_ID		- CX,DX
;	FSHOF_CHECK_NATIVE	     	- carry
;	FSHOF_GET_ALL_EXT_ATTRIBUTES 	- CX 
;

checkNative:
ifdef	DEBUGGING
	WARNING	RF_HANDLE_OP_CHECK_NATIVE
endif

	mov	si, remoteDiskHandle
	push	bp, ax
	clr	bp
	mov	di, DR_FS_HANDLE_OP
	call	CallRemote		;Returns CX non-zero if carry set
	pop	bp, ax

;    FSHOF_CHECK_NATIVE	enum	FSHandleOpFunction
;	Pass:	ch	= FileCreateFlags
;	Return:	carry set if file is compatible with the FCF_NATIVE flag
;		passed in CH.
;
;	If carry set here, this means the call failed - return carry clear to
;	cause the caller to abort the create (we would not be called here
;	unless the caller was trying to create a native mode file).
;


	jnc	10$			;
	clr	cx			;CX = 0 => carry returned clear
10$:
	tst_clc	cx
	jz	exit
	stc
	jmp	exit

	
normal:
	mov	si, remoteDiskHandle
	push	bp
	clr	bp
	mov	di, DR_FS_HANDLE_OP
	call	CallRemote
	pop	bp
	jnc	checkForReturnValues

;	When closing a file, we want to force the error flag to be clear, so
;	if a connection is broken, the file will be closed locally (when
; 	the remote RFSD shuts down, any files still open will be physically
;	closed).

	cmp	function, FSHOF_CLOSE	;Always exit with carry clear, if 
	je	exit			; closing the file.
	stc
	jmp	exit

checkForReturnValues:

;
;	Some of the functions have return values in CX/DX - others expect these
;	to be preserved.
;
;	Handle the extra return values in CX and DX:
;

	cmp	function, FSHOF_POSITION
	je	returnDX
	cmp	function, FSHOF_FILE_SIZE
	je	returnDX
	cmp	function, FSHOF_GET_DATE_TIME
	je	returnCXDX
	cmp	function, FSHOF_GET_FILE_ID
	jne	noReturnValues
returnCXDX:
	mov	dataCX, cx
returnDX:
	mov	dataDX, dx
noReturnValues:
	clc
exit:
ifdef DEBUGGING
	WARNING_NC	RF_HANDLE_OP_NORMAL
	WARNING_C	RF_HANDLE_OP_CARRY
endif
EC <	pop	bx						>
EC <	pushf							>
EC <	cmp	bx, 0x4321					>
EC <	ERROR_NZ	RFHANDLEOP_ERROR			>
EC <	cmp	ecValue, 0x1234					>
EC <	ERROR_NZ	RFHANDLEOP_ERROR			>
EC <	popf							>
	mov	dx, dataDX
	mov	cx, dataCX
	.leave
	ret
sendWithBuffer:
	mov	si, remoteDiskHandle
	mov	di, DR_FS_HANDLE_OP
	call	CallRemoteWithBuffer
	jmp	exit

read:	
ifdef DEBUGGING
	WARNING	RF_HANDLE_OP_READ
endif

;	Now, we sit in a loop and read in hunks of data until all the requested
;	data has been read. We don't want to be in a position where we have
;	to allocate huge buffers either locally or remotely, so we break up
;	large reads into smaller, more manageable amounts.

	clr	amountRead
readLoop:
	cmp	cx, MAXIMUM_AMOUNT_TO_READ_OR_WRITE_AT_ONCE
	jbe	doRead
	mov	cx, MAXIMUM_AMOUNT_TO_READ_OR_WRITE_AT_ONCE
doRead:
	mov	amountToRead, cx
	mov	si, remoteDiskHandle
	push	bx, dx, bp
	clr	bp
	mov	ah, FSHOF_READ
	mov	di, DR_FS_HANDLE_OP
	call	CallRemote
	pop	bx, dx, bp
	jc	exit
	tst	ax				;If no bytes read, branch
	jz	doneReading			; to exit


;	Copy the data from the reply buffer to the buffer at DS:SI

	push	ds, bx
	mov	bx,di				;BX <- reply buffer
	mov	cx,ax				; cx - # bytes read
	mov	di, dx	
	add	di, amountRead			;ES:DI <- place to copy data
	segmov	es,ds				;
	call	MemLock
	mov	ds,ax				
	clr	si				; ds:si - src buffer
	call	strncpy
	call	MemFree
	pop	ds, bx

;	Update the amount of data that we've read. If we had a short read,
;	then abort the loop. Otherwise, calculate the # bytes left to read
;	and branch back up.

	add	amountRead, cx			;Update the amount of data
						; we've read
	cmp	cx, amountToRead		;If our last read came up
						; short, then stop the loop
EC <	ERROR_A	READ_TOO_MUCH_DATA					>
	jne	doneReading

	mov	cx, dataCX			;CX <- total amount to read
	sub	cx, amountRead			;CX <- # bytes left to read
EC <	ERROR_C	READ_TOO_MUCH_DATA					>
	jne	readLoop

doneReading:
	mov	ax, amountRead			;AX <- total # bytes read in
doNothing:
	clc
	jmp	exit
write:	
ifdef DEBUGGING
	WARNING	RF_HANDLE_OP_WRITE
endif

;	If we are writing out a large amount of data, we don't want to be in
;	a position where we're trying to allocate 20K blocks of memory on
;	either machine, so we break up the write into more manageable chunks.

	clr	amountWritten

writeLoop:
	cmp	cx, MAXIMUM_AMOUNT_TO_READ_OR_WRITE_AT_ONCE
	jbe	writeData
	mov	cx, MAXIMUM_AMOUNT_TO_READ_OR_WRITE_AT_ONCE
writeData:
	push	bx, dx			;Save remote file handle
	add	dx, amountWritten	;DS:DX <- ptr to next byte to write
	pushdw	dsdx
	push	cx
	mov	amountToWrite, cx
	mov	si, remoteDiskHandle
	mov	ah, FSHOF_WRITE
	mov	di, DR_FS_HANDLE_OP
	call	CallRemoteWithBuffer
	pop	bx, dx			;Restore remote file handle
	jc	gotoExit

	add	amountWritten, ax	;Check for a short write. If so, then
					; just exit, returning how much we've
					; written already
	cmp	ax, amountToWrite
EC <	ERROR_A	WROTE_TOO_MUCH_DATA					>
	jne	doneWriting

	mov	cx, dataCX		;CX <- # bytes left to write
	sub	cx, amountWritten
EC <	ERROR_C	WROTE_TOO_MUCH_DATA					>
   	jne	writeLoop
doneWriting:
	mov	ax, amountWritten
	clc
gotoExit:
	jmp	exit
	

lockFile:
ifdef DEBUGGING
	WARNING	RF_HANDLE_OP_LOCK_UNLOCK
endif
	pushdw	sscx
	mov	cx, size FSHLockUnlockFrame
	push	cx
	jmp	sendWithBuffer
getExtAttr:
ifdef DEBUGGING
	WARNING	RF_HANDLE_OP_GET_EXT
endif

;	ss:dx - FSHandleExtAttrData
;	cx    - if FEA_MULTIPLE, is # entries
;		else size of buffer at ss:dx

	mov	si, dx
	mov	ax, ss:[si].FHEAD_attr
	cmp	ax, FEA_MULTIPLE		; multiple attr's?
	je	multiple

; it's a single entry so we fix it so it's equivalent to multiple entries 
; of only one entry... get it?

	mov	localFEAD.FEAD_attr, ax
	mov	localFEAD.FEAD_size, cx

	push	dx			;Save ptr to FSHandleExtAttrData
	mov	ah, FSHOF_GET_EXT_ATTRIBUTES
	lea	di, localFEAD
	mov	si, remoteDiskHandle
	pushdw	ssdi
	mov	cx, size localFEAD
	push	cx
	mov	cx, 1			;Read in one attribute
	mov	di, DR_FS_HANDLE_OP
	call	CallRemoteWithBuffer
	pop	si				; ss:si - FSHandleExtAttrData
	jc	gotoExit

	push	ax
	mov	bx,di				; BX <- data returned from call
	mov	cx, localFEAD.FEAD_size
	les	di, ss:[si].FHEAD_buffer
	call	MemLock				;Copy over returned data
	mov	ds,ax
	mov	ax, ss:[si].FHEAD_attr
	clr	si				; ds:si - returned buffer
	call	CopyExtendedAttribute
	pop	ax
mapGetExtAttrError:
	call	MemFree				;Free up reply buffer
;
;	The RPC mechanism will not return data from the remote machine
;	if there was an error. For some errors (unsupported attributes)
;	we want to return the data for the *supported* attributes, so we
;	return carry clear at the server, and then return the carry set
;	locally if the error code is non-zero.
;
	cmp	ax, ERROR_ATTR_NOT_SUPPORTED
	je	getExtAttrErr
	cmp	ax, ERROR_ATTR_NOT_FOUND
	clc
	jne	noGetExtAttrErr
getExtAttrErr:
	stc	
noGetExtAttrErr:
	jmp	exit

multiple:
;
;	SS:SI <- FSHandleExtAttrData
;	BX <- remote file handle
;	CX <- # entries
;
	push	cx				;Save # entries
	pushdw	ss:[si].FHEAD_buffer		;Save ptr to buffer
	pushdw	ss:[si].FHEAD_buffer		;Pass ptr to FileExtendedAttrs
	mov	al, size FileExtAttrDesc	
	mul	cl
	push	ax				;Pass size of data to pass
	mov	si, remoteDiskHandle
	mov	ah, FSHOF_GET_EXT_ATTRIBUTES
	mov	di, DR_FS_HANDLE_OP
	call	CallRemoteWithBuffer
	popdw	esax				;es:ax - array of FEAD structs
	pop	cx				;Restore # of entries
	jc	gotoExit

EC <	push	di							>
EC <	mov	di, bp							>
EC <	call	ECCheckBoundsESDIFar					>
EC <	pop	di							>

; here, we got a reply with the buffer of attributes (packed in order)

	push	bp, ax
	mov_tr	bp, ax				;es:bp - array of FEAD structs
	mov	bx, di
	call	MemLock
 	mov	ds, ax
	clr	si				; ds:si - buffer of attr(s)
loopCopy:
	push	es, cx
	mov	ax, es:[bp].FEAD_attr
	mov	cx, es:[bp].FEAD_size
	les	di, es:[bp].FEAD_value
	call	CopyExtendedAttribute
	add	si, cx				; ds:si - next attr to copy
	add	bp, size FileExtAttrDesc
	pop	es, cx				; es:bp - next FEAD
	loop	loopCopy
	pop	bp, ax
	jmp	mapGetExtAttrError

setExtAttr:
; given a buffer of FEADs we need to copy this buffer plus all attribute
; values in a send buffer.

;
;	BX - Remote file handle
;	ss:dx - FSHandleExtAttrData
;	cx - size of FHEAD_buffer or # attributes (if FEA_multiple)
;
ifdef DEBUGGING
	WARNING	RF_HANDLE_OP_SET_EXT
endif
	push	bx				; remote file handle
	mov	si, dx
	mov	dx, ss:[si].FHEAD_attr
	cmp	dx, FEA_MULTIPLE		; multiple attr's?
	je	setMultiple
; copy the FEAD to the send buffer
	mov	ax, size FileExtAttrDesc	; buffer size = size of header
	add	ax, cx				; 	+ attribute size
	push	ax				;Save buffer size
	mov	di, cx				;DI <- attribute size
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	RFSDMemAlloc
	mov	es,ax
EC <	cmp	dx, FEA_DISK						>
EC <	ERROR_Z	CANNOT_SET_FEA_DISK					>

	mov	es:[FEAD_attr], dx
	mov_tr	es:[FEAD_size], di
	lds	si, ss:[si].FHEAD_buffer
	mov	di, size FileExtAttrDesc	; es:di - dest buffer
	mov	es:[FEAD_value].offset, di
	mov	cx, es:[FEAD_size]
EC<	cmp	cx, 256			>	; too big?
EC<	ERROR_A	ERROR_RFSD_VALUE_OUT_OF_RANGE	>
	call	strncpy
	clr	si				; es:si - buffer to send
	pop	dx				; buffer size
	mov	cx,1				; # of attrs

callSet:
;
;	Pass:
;
;	BX <- data handle
;	ES:SI <- buffer holding data to pass to remote machine
;	dx - size of buffer
;	ss:bp - locals
;	(on stack - remote file handle)
;
	mov_tr	ax, bx				;AX <- data handle 
	pop	bx				; remote file handle
	push	ax
	pushdw	essi				;Save ptr to data to send
	push	dx				;Save size
	mov	si, remoteDiskHandle
	mov	di, DR_FS_HANDLE_OP
	mov	ah, FSHOF_SET_EXT_ATTRIBUTES
	call	CallRemoteWithBuffer
	pop	bx
	pushf	
	call	MemFree
	popf
	jmp	exit

setMultiple:
	lds	si, ss:[si].FHEAD_buffer

; how much space do we need for the headers?

	mov	al, size FileExtAttrDesc
	mul	cl

	push	cx				; # of attrs
	push	ax				; size of headers

;	Calculate how much extra space we need for the values

	push	si
getSp:
	add	ax, ds:[si].FEAD_size
	add	si, size FileExtAttrDesc
	loop	getSp				; ax - space needed
	pop	si

	mov	dx,ax				;DX <- total space
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	RFSDMemAlloc
	mov	es,ax				;ES:DI <- data to copy
	clr	di
	pop	cx				;Copy over the FEAD structs
	call	strncpy				; es:di - FEAD's

; go down the array of FECD's and copy the values into the buffer that
; trails the headers.  Afterwards, fix the offsets.

	pop	cx				; # of attributes
	mov	al, size FileExtAttrDesc
	mul	cl
	mov_tr	di, ax				;ES:DI <- ptr to buffer space
						; beyond FEADs
	clr	bp				; es:bp - FEAD's
	push	cx, bp				;Save # attributes
setVal:
EC <	cmp	es:[bp].FEAD_attr, FEA_DISK				>
EC <	ERROR_Z	CANNOT_SET_FEA_DISK					>
	lds	si, es:[bp].FEAD_value
EC <	xchg	di, bp							>
EC <	call	ECCheckBoundsESDIFar					>
EC <	xchg	di, bp							>

	mov	es:[bp].FEAD_value.offset, di	; fix offset
	push	cx
	mov	cx, es:[bp].FEAD_size
EC<	cmp	cx, 256			>	; too big?
EC<	ERROR_A	ERROR_RFSD_VALUE_OUT_OF_RANGE	>

	call	strncpy
	add	di, cx				; es:di - next value ptr
	pop	cx
	add	bp, size FileExtAttrDesc	; es:bp - next FEAD
	loop	setVal
	pop	cx, bp 				; # of entries

;	Make the call to the remote machine to set the attributes

	jmp	callSet

getAllAttr:
ifdef DEBUGGING
	WARNING	RF_HANDLE_OP_GET_ALL
endif
	mov	si, remoteDiskHandle
	push	bp
	clr	bp
	mov	di, DR_FS_HANDLE_OP
	call	CallRemote
	pop	bp
	LONG jc	exit


	call	FixupFEABlock

	mov	dataCX, cx			;CX <- # entries in block
	mov	ax,di
	clc
	jmp	exit				; leave block LOCKED 
RFHandleOp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyExtendedAttribute
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies an extended attribute from the remote buffer to the
		local one

CALLED BY:	GLOBAL
PASS:		ds:si - FEAD from remote
		cx - size of data
		es:di - local buffer
		ax - FileExtendedAttribute
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyExtendedAttribute	proc	near	uses	si
	.enter
EC <	cmp	ax, FEA_LAST_VALID				>
EC <	ERROR_A	-1						>
EC<	cmp	cx, 256			>	; too big?
EC<	ERROR_AE ERROR_RFSD_VALUE_OUT_OF_RANGE	>
	call	strncpy
	cmp	ax, FEA_DISK
	jne	notDisk

;	Map the remote disk handle to be a local version

	mov	si, es:[di]
	call	MapRemoteDiskHandle
EC <	ERROR_C	COULD_NOT_MAP_DISK_HANDLE				>
	mov	es:[di], si
	jmp	exit
notDisk:
	cmp	ax, FEA_FILE_ATTR
	jne	notFileAttr
	andnf	{byte} es:[di], not mask FA_LINK
notFileAttr:
exit:
	.leave
	ret
CopyExtendedAttribute	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupFEABlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixes up the disk handle and internal segment pointers in
		the passed block with FileExtAttribute data in it.

CALLED BY:	GLOBAL
PASS:		di - handle of block
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixupFEABlock	proc	near	uses	ax, bx, cx, di, si, es
	.enter
	mov	bx,di
	call	MemLock
	mov	es,ax
	clr	di
setSeg:
EC <	call	ECCheckBoundsESDIFar					>
EC <	cmp	es:[di].FEAD_attr, FEA_LAST_VALID			>
EC <	ERROR_A	RFHANDLEOP_ERROR					>

	cmp	es:[di].FEAD_attr, FEA_DISK
	jne	noDiskMapping

;	Map the remote disk handle to a local disk handle

	mov	si, es:[di].FEAD_value.offset
	mov	si, es:[si]
	call	MapRemoteDiskHandle
EC <	ERROR_C	COULD_NOT_MAP_DISK_HANDLE				>
	mov	ax, si
	mov	si, es:[di].FEAD_value.offset
EC <	xchg	di, si							>
EC <	call	ECCheckBounds						>
EC <	xchg	di, si							>
	mov	es:[si], ax
	jmp	next
noDiskMapping:
	cmp	es:[di].FEAD_attr, FEA_FILE_ATTR
	jne	notFileAttr
	mov	si, es:[di].FEAD_value.offset
	andnf	{byte} es:[si], not mask FA_LINK
notFileAttr:

next:
;	We have a block copied from the remote machine. None of the internal
;	segment values are valid (this block lies at a different place in
;	memory on this machine) so fix up all the pointers.

	mov	es:[di].FEAD_value.segment,es	; fix all the segment pointers
	add	di, size FileExtAttrDesc	; of the data to match our
	loop	setSeg				; block
	.leave
	ret
FixupFEABlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFAllocOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_ALLOC_OP

CALLED BY:	RFSD
PASS:		al	= FullFileAccessFlags
		ah	= FSAllocOpFunction to perform.
		ds:dx	= path
		es:si	= DiskDesc on which the operation will take place,
			  locked into drive (FSInfoResource and affected drive
			  locked shared). si may well not match the disk handle
			  of the thread's current path, in which case ds:dx is
			  absolute.
FSAOF_CREATE -	cl	= FileAttrs
		ch	= FileCreateFlags

RETURN:		Carry clear if operation successful:
			al	= SFN of open file
			ah	= non-zero if opened to device, not file.
			dx	= private data word for FSD
		Carry set if operation unsuccessful:
			ax	= error code.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFAllocOp	proc	far
	uses	bx,cx,si
	.enter
	mov	di, DR_FS_ALLOC_OP
	call	GetRemoteDiskHandle		; bx - remote disk handle
	mov	si,dx				; ds:si - path to set
	call	GetCurPathHandle

	push	cx
	call	strlen				; cx - path length
	mov	bp,cx				; bp - path length
	pop	cx

	pushdw	dssi
	push	bp
	call	CallRemoteWithBuffer		; bx - path handle
						;Returns DX = remote file han
ifdef DEBUGGING
	WARNING_NC	RF_ALLOC_OP
	WARNING_C	RF_ALLOC_OP_CARRY
endif
	.leave
	ret
RFAllocOp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFPathOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_PATH_OP

CALLED BY:	RFSD
PASS:		ah	= FSPathOpFunction to perform
		ds:dx	= path on which to perform the operation
		es:si	= DiskDesc for disk on which to perform it, locked
			  into drive (FSInfoResource and affected drive locked
			  shared). si may well not match the disk handle
			  of the thread's current path, in which case ds:dx is
			  absolute.
		bx, cx  - function-specific data

RETURN:		carry clear if successful:
			return values vary by function
		carry set if unsuccessful:
			ax	= error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFPathOp	proc	far
	uses	bx,dx,si
	dataBX			local	word	\
				push	bx
	dataCX			local	word	\
				push	cx
	;NOTE: dataCX is used to return values in CX for those operations
	; that require it

	function		local	FSPathOpFunction
	remoteDiskHandle	local	word
	remotePathHandle	local	word
	pathLen			local	word
	totalLen		local	word
	; The total length of the buffer we create for the move/rename
	; functions
	headerSize		local	word
	; For setExtMultiple, the size of the FileExtAttrDesc in the
	; send buffer

if	ERROR_CHECK
	ecValue		local	word
endif
	.enter
	mov	function, ah

;	So much crap is being pushed and popped, I'm a little concerned
;	that I'll mis push/pop, or trash BP, so I'll do some error checking
;	before exiting

EC <	mov	ecValue, 0x1234						>
EC <	mov	bx, 0x4321						>
EC <	push	bx							>

	call	GetRemoteDiskHandle		; bx - remote disk handle
	mov	remoteDiskHandle, bx

;	Get the private path handle

	mov	si,dx				; ds:si - path

	call	GetCurPathHandle		; dx - remote path handle
	mov	remotePathHandle, dx

	call	strlen
	mov	pathLen,cx			; path length

	push	ax
	mov	al,ah
	clr	ah
	shl	ax
	mov	di,ax
	pop	ax
	mov	bx, dataBX
	mov	cx, dataCX
EC <	cmp	di, size PathOpJmpTable					>
EC <	ERROR_AE	RFPATHOP_ERROR					>
	jmp	cs:[PathOpJmpTable][di]

PathOpJmpTable	nptr	\
	normal,				;FSPOF_CREATE_DIR
	normal,				;FSPOF_DELETE_DIR
	normal,				;FSPOF_DELETE_FILE
	rename,				;FSPOF_RENAME_FILE
	moveFile,			;FSPOF_MOVE_FILE
	normal,				;FSPOF_GET_ATTRIBUTES
	normal,				;FSPOF_SET_ATTRIBUTES
	getExt,				;FSPOF_GET_EXT_ATTRIBUTES
	getAllExt,			;FSPOF_GET_ALL_EXT_ATTRIBUTES
	setExt,				;FSPOF_SET_EXT_ATTRIBUTES
	unsupported,			;FSPOF_MAP_VIRTUAL_NAME
	unsupported,			;FSPOF_MAP_NATIVE_NAME
	unsupported,			;FSPOF_CREATE_LINK
	linkPathOp,			;FSPOF_READ_LINK
	linkPathOp,			;FSPOF_SET_LINK_EXTRA_DATA
	linkPathOp,			;FSPOF_GET_LINK_EXTRA_DATA
	normal				;FSPOF_CREATE_DIR_WITH_NATIVE_SHORT_NAME


;
; We need to preserve CX for every operation except:
;	FSPOF_GET_ATTRIBUTES
;	FSPOF_GET_ALL_EXT_ATTRIBUTES
;	FSPOF_READ_LINK
;	FSPOF_GET_LINK_EXTRA_DATA
;

CheckHack <length PathOpJmpTable eq FSPathOpFunction>
normal:
;
;	DX <- remote path handle
;	DS:SI <- path
;

	pushdw	dssi
	push	pathLen
	mov	si, remoteDiskHandle
	mov	di, DR_FS_PATH_OP
	call	CallRemoteWithBuffer
	jc	exit
	cmp	function, FSPOF_GET_ATTRIBUTES
	clc
	jne	exit
	andnf	cx, not mask FA_LINK		;Links look just like regular
						; files to the client side, so
						; nuke the link bit.
	mov	dataCX, cx		;For FSPOF_GET_ATTRIBUTES, return CX
exit:
ifdef DEBUGGING
	WARNING_NC	RF_PATH_OP_NORMAL
	WARNING_C	RF_PATH_OP_CARRY
endif
EC <	pop	bx						>
EC <	pushf							>
EC <	cmp	bx, 0x4321					>
EC <	ERROR_NZ	RFPATHOP_ERROR			>
EC <	cmp	ecValue, 0x1234					>
EC <	ERROR_NZ	RFPATHOP_ERROR			>
EC <	popf							>
	mov	cx, dataCX	;Ops that need to return CX stuff the return
				; value in dataCX	
	.leave
	ret

unsupported:
ifdef DEBUGGING
	WARNING	RF_PATH_OP_UNSUPPORTED
endif
	mov	ax, ERROR_UNSUPPORTED_FUNCTION
	stc
	jmp	exit

linkPathOp:
ifdef DEBUGGING
	WARNING	RF_PATH_OP_LINK
endif
	mov	ax, ERROR_NOT_A_LINK
	stc
	jmp	exit

rename:
;
;	BX:CX - new name for file
;
	pushdw	bxcx
	jmp	twoStr
moveFile:
;
;	SS:BX - FSMoveFileData
;	ES:CX - DiskDesc of destination
;
	pushdw	ss:[bx].FMFD_dest

	push	si
	mov	si,cx				;
	call	GetRemoteDiskHandle		;BX <- remote disk handle
	mov	cx,bx				; cx - remote DiskDesc of dest
	pop	si

twoStr:
; for any operation that involves passing 2 strings, the format is:
; <1st string> [null-terminated]
; <2nd string> [null-terminated]

	segmov	es,ds,di			; temp storage
	mov	di,si				; es:di - 1st str
	popdw	dssi				; ds:si - 2nd str

;	Copy the two strings into a block, one after the other

	push	cx				;Save value passed in CX
						; (ES:CX - DiskDesc)
	call	strlen				; cx - length of 2nd str
	mov	ax,pathLen
	add	ax,cx				;AX = size of path + size
						; of extra string being passed
	pushdw	dssi
	mov	totalLen, ax
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	RFSDMemAlloc
	segmov	ds,es,cx
	mov	si,di				; ds:si - 1st str
	mov	es,ax
	clr	di				; es:di - out buffer
	mov	cx, pathLen
	call	strncpy				
	mov	di,cx				; es:di - ptr to end of buffer
	popdw	dssi				; ds:si - next str to copy (2)
	call	strcpy
	pop	cx				; CX <- value passed in

	mov	ah, function
	mov	di, DR_FS_PATH_OP
	mov	si, remoteDiskHandle		; remote disk handle
	push	bx				;Save handle of buffer
	clr	bx
	pushdw	esbx
	push	totalLen
	call	CallRemoteWithBuffer
EC <	ERROR_C	RFSD_PATH_OP_FAILED		>
	pop	bx				;Restore handle of buffer and
	pushf
	call	MemFree				; free it up
	popf
	jmp	exit

getExt:
; ds:si - path
; ss:bx/ss:dataBX = FSPathExtAttrData
; cx/dataCX = size/# entries (depending upon whether FEA_MULTIPLE set)

ifdef DEBUGGING
	WARNING	RF_PATH_OP_GET_EXT
endif
	mov	dx, ss:[bx].FPEAD_attr
	cmp	dx, FEA_MULTIPLE		; multiple attr's?
	je	multiple

; it's a single entry so we fix it so it's equivalent to multiple entries 
; of only one entry... get it?

;	First, copy the path into a buffer, with room at the end for a
;	FileExtAttrDesc structure

	mov	ax, pathLen
	add	ax, size FileExtAttrDesc	; total buffer size
	push	ax
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	RFSDMemAlloc
	mov	es, ax
	clr	di
	call	strcpy
	pop	ax				;AX = total buffer size
	segmov	ds, es
	mov	si, pathLen			; ds:si - FileExtAttrDesc at
						; end of path
;	Fill in the FileExtAttrDesc structure

	mov	ds:[si].FEAD_attr, dx
	mov	cx, dataCX
	mov	ds:[si].FEAD_size, cx
	mov	cx,1				; single attribute

;	Now, pass this copy off to the remote machine

	push	bx				;Save handle of buffer
	mov	dx, remotePathHandle
	mov	si, remoteDiskHandle
	clr	bx
	pushdw	dsbx				;DS:BX <- ptr to data to send
	push	ax				;Save data size

	mov	ah, FSPOF_GET_EXT_ATTRIBUTES
	mov	di, DR_FS_PATH_OP
	call	CallRemoteWithBuffer		; cx - carry condition
	pop	bx
	jc	err
	call	MemFree				; free send buffer
	mov	bx,di				; return buffer mem handle

;	Copy the reply into the return buffer

	push	ax
	call	MemLock
 	mov	ds, ax
	clr	si				; ds:si - buffer of attr
	mov	di, dataBX			;SS:DI <- FSPathExtAttrData
	mov	ax, ss:[di].FPEAD_attr
	les	di, ss:[di].FPEAD_buffer	;ES:DI <- dest buffer
	mov	cx, dataCX
	call	CopyExtendedAttribute
getExtExit:
	pop	ax				;Restore error code
;
;	The RPC mechanism will not return data from the remote machine
;	if there was an error. For some errors (unsupported attributes)
;	we want to return the data for the *supported* attributes, so we
;	return carry clear at the server, and then return the carry set
;	locally if the error code is non-zero.
;
	cmp	ax, ERROR_ATTR_NOT_FOUND
	je	err
	cmp	ax, ERROR_ATTR_NOT_SUPPORTED
	je	err
EC <	tst	ax							>
EC <	ERROR_NZ	-1						>
	call	MemFree				; kill reply buffer
	clc
	jmp	exit
err:
	call	MemFree			;Kill send buffer (or reply buffer
					; if unsupported attribute error)
	stc
	jmp	exit

multiple:

; ds:si - path
; ss:bx/ss:dataBX = FSPathExtAttrData
; cx/dataCX = size/# entries (depending upon whether FEA_MULTIPLE set)

	mov	al, size FileExtAttrDesc
	mul	cl				; size of entries - ax

	add	ax, pathLen			; ax - total size of buffer

;	Allocate a buffer to hold the path and the FileExtAttrDesc structures,
;	and copy the path and the FileExtAttrDesc into the buffer

	mov	totalLen, ax			;Save total buffer size
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	RFSDMemAlloc
	mov	es, ax
	clr	di				;
	call	strcpy				; copy path name
	mov	ax, totalLen

	mov	di, pathLen		; es:di - ptr to space for FEADs
	mov	cx, totalLen
	sub	cx, di			;CX - size of FEADs
	mov	si, dataBX
	lds	si, ss:[si].FPEAD_buffer	; ds:si - entries
	call	strncpy				;Copy the FileExtAttrDescs over

	mov	cx, dataCX				; # of entries
	push	bx				; save mem handle
	mov	dx, remotePathHandle
	mov	si, remoteDiskHandle

	clr	bx
	pushdw	esbx
	push	totalLen
	mov	ah, FSPOF_GET_EXT_ATTRIBUTES
	mov	di, DR_FS_PATH_OP
	call	CallRemoteWithBuffer

	pop	bx
	jc	err

	call	MemFree				; free send buffer

	mov	bx,di				; return buffer mem handle

; 	Here, we got a reply with the buffer of attributes (packed in order)
;	Copy them out to the destination buffer

	push	ax				;Save reply values
	call	MemLock
 	mov	ds, ax
	mov	cx, dataCX				; # of entries

	mov	di, dataBX
	les	di, ss:[di].FPEAD_buffer	;ES:DI - FileExtAttrDescs
	push	bx				;Save mem handle of reply 
	clr	si				; ds:si - buffer to copy from
loopCopy:

;	CX - # entries to copy
;	ES:DI - ptr to next FileExtAttrDesc passed by caller
;	DS:SI - ptr to value to copy out

	push	cx
	mov	ax, es:[di].FEAD_attr
	mov	cx, es:[di].FEAD_size
	pushdw	esdi
	les	di, es:[di].FEAD_value
	call	CopyExtendedAttribute
	popdw	esdi
	add	si, cx				; ds:si - next attr to copy
	add	di, size FileExtAttrDesc
	pop	cx
	loop	loopCopy
	pop	bx
	jmp	getExtExit			;Free reply buffer and get
						; return values from stack

getAllExt:
ifdef DEBUGGING
	WARNING	RF_PATH_OP_GET_ALL
endif
	mov	si, remoteDiskHandle
	push	bp
	clr	bp
	mov	di, DR_FS_PATH_OP
	call	CallRemote			;DI <- handle of reply data
						;CX <- # attrs
	pop	bp
	jc	gotoExit

	call	FixupFEABlock
	mov	dataCX,cx			;Return # attrs in CX
	mov	ax,di				;AX <- locked reply block
gotoExit:
	jmp	exit
setExt:
; ds:si - path
; dx - remote path handle
; ss:bx - FSPathExtAttrData
; cx - size/#of entries

; given a buffer of FEADs we need to copy this buffer plus all attribute
; values in a send buffer.
ifdef DEBUGGING
	WARNING	RF_PATH_OP_SET_EXT
endif
	mov 	dx,ss:[bx].FPEAD_attr
	cmp	dx,FEA_MULTIPLE
	je	setMultiple


; copy the path and FEAD to the send buffer

;	CX = size of attribute we are setting

	mov	ax, pathLen
	add	ax, size FileExtAttrDesc	; buffer size = size of path
	add	ax, cx				; + header + attribute
	mov	totalLen, ax
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	mov	bx, handle 0
	call	MemAllocSetOwner			; temp buffer
	mov	es,ax
	clr	di				;ES:DI <- data
	mov	cx, pathLen
	call	strncpy
	mov	di,cx				;ES:DI <- ptr after path
EC <	cmp	dx, FEA_DISK						>
EC <	ERROR_Z	CANNOT_SET_FEA_DISK					>
	mov	es:[di].FEAD_attr, dx
	mov	cx, dataCX
	mov	es:[di].FEAD_size, cx
	push	bx				; mem handle
	mov	bx,dataBX
	lds	si, ss:[bx].FPEAD_buffer	;DS:SI <- ptr to attribute data
	add	di, size FileExtAttrDesc	; es:di - points to value
	mov	es:[di-size FileExtAttrDesc].FEAD_value.offset, di
	call	strncpy
	mov	cx, 1				; # of attrs
callSet:
;
;	ES - data to send off
;	totalLen - size of data to send off
;	on stack - handle of buffer holding send data
;
	clr	si
	pushdw	essi
	push	totalLen
	mov	si, remoteDiskHandle
	mov	dx, remotePathHandle
	mov	ah, FSPOF_SET_EXT_ATTRIBUTES
	mov	di, DR_FS_PATH_OP
	call	CallRemoteWithBuffer
	pop	bx				;Restore mem handle
	pushf
	call	MemFree
	popf
	jmp	exit

setMultiple:
;
;	SS:BX - FSPathExtAttrData
;	CX - # entries to set
;	DX - attribute
;


	les	di, ss:[bx].FPEAD_buffer

; Determine how much space we nead for the FileExtAttrDesc

	mov	ax, size FileExtAttrDesc
	mul	cl				; ax - space needed


	mov	headerSize, ax
	add	ax,pathLen

; how much space do we need for the values?

getSp:
	add	ax, es:[di].FEAD_size
	add	di, size FileExtAttrDesc
	loop	getSp				; ax - space needed

	mov	totalLen, ax
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	RFSDMemAlloc
	push	bx				;Save handle of buffer
	mov	es,ax				;ES:DI <- buffer of data we
	clr	di				; send to remote machine

;	Copy the path over to the send buffer, then the FileExtAttrDesc, then
;	the values we are setting.

	call	strcpy				; copy path
	mov	di, pathLen
	mov	si, dataBX
	lds	si, ss:[si].FPEAD_buffer
	mov	cx,headerSize			;
	call	strncpy				; copy headers

; go down the array of FECD's and copy the values into the buffer that
; trails the headers.  Afterwards, fix the offsets.

	mov	ax, dataCX			;AX <- # attributes
	push	bp
	mov	bp, di				; es:bp - FEAD's
	add	di, cx				; es:di - beginning of values
	mov	cx, ax				; # of attr's
setVal:	
	push	cx
EC <	cmp	es:[bp].FEAD_attr, FEA_DISK				>
EC <	ERROR_Z	CANNOT_SET_FEA_DISK					>
	lds	si, es:[bp].FEAD_value
	mov	es:[bp].FEAD_value.offset, di	; fix offset
	mov	cx, es:[bp].FEAD_size
EC<	cmp	cx, 256			>	; too big?
EC<	ERROR_AE	ERROR_RFSD_VALUE_OUT_OF_RANGE	>
	call	strncpy
	add	di, cx				; es:di - next value ptr
	add	bp, size FileExtAttrDesc	; es:bp - next FEAD
	pop	cx
	loop	setVal
	pop	bp
	mov	cx, dataCX
	jmp	callSet	
RFPathOp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFCompareFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare 2 Files

CALLED BY:	DR_FS_COMPARE_FILES
PASS:		nothing
RETURN:		ax
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

Unsupported - returns FALSE automatically

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFCompareFiles	proc	far
	.enter
	or	al, 1		; flag not-equal
	lahf
ifdef DEBUGGING
	WARNING	RF_COMPARE_FILES
endif
	.leave
	ret
RFCompareFiles	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFFileEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_FILE_ENUM		

CALLED BY:	RFSD

PASS:		cx:dx	= routine to call back
		ds	= segment of FileEnumCallbackData
		es:si	= DiskDesc of current path, with FSIR and drive locked
			  shared. Disk is locked into drive.
		ss:bx	= stack frame to pass to callback
RETURN:		carry set if no files/dirs to enumerate:
			ax	= ERROR_NO_MORE_FILES
		else carry & registers as set by callback routine.
DESTROYED:	ax, bx, cx, dx may all be nuked before the callback is
		called, but not if it returns carry set.
		bp may be destroyed before & after the callback.

PSEUDO CODE/STRATEGY:
		The callback function is called as:
			Pass:	ds	= segment of FileEnumCallbackData.
					  Any attribute descriptor for which
					  the file has no corresponding
					  attribute should have the
					  FEAD_value.segment set to 0. All
					  others must have FEAD_value.segment
					  set to DS when their value is stored.
				ss:bp	= ss:bx passed to FSD
			Return:	carry set to stop enumerating files:
					ax	= error code
			Destroy:es, bx, cx, dx, di, si

		If the filesystem supports the "." and ".." special directories,
		they must *not* be passed to the callback routine.

		FileEnumCallbackData isn't actually a defined structure, but
		is a concept. The start is an array of FileExtAttrDesc
		structures, terminated by one with FEA_END_OF_LIST as its
		attribute. After that comes the room for the attribute
		values. All the FEAD_value.offset fields are offsets into
		this single segment.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFFileEnum	proc	far
	uses	si,ds,es
	.enter
	call	PClientSem			; grab client semaphore
	stc
	mov	ax, ERROR_DRIVE_NOT_READY
LONG 	jnz	done				;If exiting, return error

if	DEBUGGING
	WARNING	DOING_RF_FILE_ENUM
endif

	push	bx				;Save stack frame


; find the size of the FECD so we can copy it and send it across

	push	cx
	mov	cx, ds
	call	MemSegmentToHandle
	mov	bx, cx			;BX <- handle of FileEnumCallbackData
	pop	cx

	mov	ax, MGIT_SIZE
	call	MemGetInfo
	mov_tr	bp, ax			;BP <- size of buffer

	call	GetRemoteDiskHandle		; bx - remote disk handle

	segmov	es,dgroup,ax
	movdw	es:[callback], cxdx


	clr	si				; ds:si - FECD
	mov	di, DR_FS_FILE_ENUM
	mov	al, FILE_ENUM_START
	call	GetCurPathHandle		;DX <- handle of remote path
	pushdw	dssi
	push	bp
	call	CallRemoteWithBuffer
	jc	done
common:
	cmp	al, FILE_ENUM_END		; done?
	jz	done				;Exit with carry clear
	mov	bx,di
	call	MemLock	
	segmov	es, ds, si			; FECD
	mov	ds,ax
	clr	si				; ds:si - reply buffer
	clr	di
zeroLoop:

;	ES:DI <- FileEnumCallbackData
;
;	We clear out the segments of any attributes that the file doesn't
;	have.
;

	clr	es:[di].FEAD_value.segment	; gotta zero the segments
	cmp	es:[di].FEAD_attr, FEA_END_OF_LIST
	lea	di, es:[di+size FileExtAttrDesc]
	jne	zeroLoop
copyLoop:

;	DS:SI - ptr to array of data:
;		{word} offset into FileEnumCallbackData
;		       data corresponding to attr
;				...
;		{byte} END_OF_ATTR

	cmp	{byte} ds:[si], END_OF_ATTR	; end of attrs?
	jz	endLoop
	mov	di, ds:[si]			; copy the offset
	mov	es:[di].FEAD_value.segment, es	; set the segment
	mov	cx, es:[di].FEAD_size		; get size
EC<	cmp	cx, 256			>	; too big?
EC<	jna	cont			>
EC<	ERROR	ERROR_RFSD_VALUE_OUT_OF_RANGE	>
EC<	cont:				>
	mov	ax, es:[di].FEAD_attr
	mov	di, es:[di].FEAD_value.offset	; es:di - value
	inc	si				; get to value  in src buffer
	inc	si
	call	CopyExtendedAttribute		; copy!
	add	si,cx				; point to next attr
	jmp	copyLoop
endLoop:
	call	MemFree				; free reply buffer 
	segmov	ds,es,ax			; ds is FECD
	pop	bp
	push	bp
	segmov	es,dgroup,ax
	push	ds
	movdw	bxax, es:[callback]
	call	ProcCallFixedOrMovable		; call the callback routine
	pop	ds				; FECD
	mov	di, DR_FS_FILE_ENUM
	jc	stopEnum
	mov	al, FILE_ENUM_NEXT
	clr	bp
	call	CallRemote
	jnc	common
done:
	call	VClientSem
	pop	bp
ifdef DEBUGGING
	WARNING_NC	RF_FILE_ENUM
	WARNING_C	RF_FILE_ENUM_CARRY
endif
	.leave
	ret
stopEnum:
	mov	al, FILE_ENUM_END
	clr	bp
	call	CallRemote
	jmp	done
RFFileEnum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRemoteWithBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the remote file system driver with extra data

CALLED BY:	GLOBAL
PASS:		di - FSFunction
		ax, bx, cx, dx, si - regs sent to remote system
		on stack
			fptr - buffer to send
			word - size
RETURN:		variable
		carry set on error
		if buffer returned, di - buffer handle
DESTROYED:	ax, bx, cx, dx possibly
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
CallRemoteWithBuffer	proc	near	bufPtr:fptr, bufSize:word
	uses	ds, si, es
	.enter
EC <	call	ECCheckSegments						>
	call	PackageOutBuffer
	lds	si, bufPtr
EC <	call	ECCheckBounds						>

	add	cx, bufSize			; add buffersize + 2
	inc	cx				; since we store the size
	inc	cx				; in our stream as well

	mov_tr	ax, cx
	push	ax
	mov	ch, (mask HAF_LOCK) or (mask HAF_NO_ERR)
	call	MemReAlloc
	mov	es,ax
	mov	di, (size RFSHeader) + (size RFSRegisters)
EC <	call	ECCheckBoundsESDIFar					>
	mov	cx, bufSize
	mov	es:[di], cx			; store size of buffer
	inc	di
	inc	di
	call	strncpy
	call	MemUnlock
	pop	cx			;CX <- total size of data to send
	call	SendRemoteWithReply
	.leave
	ret
CallRemoteWithBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRemote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make Remote call passing registers and a buffer in DS:SI
		(optional)

CALLED BY:	RFSD 
PASS:		di - FSFunction
		(ax,bx,cx,dx,si - sent to remote system)

RETURN:		variable
		carry set on error
		if buffer returned, di - buffer handle
DESTROYED:	(ax,bx,cx,dx possibly) 
			
PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallRemote	proc	near
	.enter
EC <	tst	bp							>
EC <	ERROR_NZ	-1						>
EC <	call	ECCheckSegments						>
	call	PackageOutBuffer

	call	SendRemoteWithReply
	.leave
	ret
CallRemote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendRemoteWithReply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends data to the remote with reply

CALLED BY:	GLOBAL
PASS:		bx - handle of data to send (RPCHeader)
		cx - size of data
RETURN:		carry set if error
			ax, cx, dx - return data from RPCHeader
		if carry clear:
			di - handle of block of extra data returned
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendRemoteWithReply	proc	far
	uses	ds, es, si, bp
	.enter	

	push	bx				; save message buffer handle

;	Send the message off, and get a reply if one is available

	call	SendMessageRemote
LONG	jc	sendError			; close the connection if error

	cmp	ax, REPLY
	mov_tr	ax,bx				;Save reply buffer
	pop	bx
LONG	jne	replyError			; no reply?
	call	MemFree				; free our message buffer

	mov_tr	bx,ax
	call	MemLock				; lock reply buffer
	mov	ds,ax
	clr	si
	cmp	ds:[si].RPC_proc, RFS_REPLY_ERROR	; error ?
	je	replyError

;	If extra data was returned, copy the data into a separate block, and
;	return it in DI

	mov	ax, MGIT_SIZE
	call	MemGetInfo
	cmp	ax, (size RFSHeader) + (size RFSRegisters)
	jbe	noString
	mov	si, (size RFSHeader) + (size RFSRegisters)
	lodsw					;AX <- str length
	tst	ax				; is it > 0 ?
	jz	noString

	test	ds:[RPC_flags], RPC_CARRY	;If carry set, then don't
	jnz	noString			; copy any data out (error
						; occurred)
	push	bx				; reply buffer handle
	push	ax				;Save string length
 	mov	cx, (mask HF_SWAPABLE) or (((mask HAF_LOCK) or \
			(mask HAF_NO_ERR)) shl 8)

	call	RFSDMemAlloc
	mov	es,ax	
	clr	di				; es:di - empty buffer
	pop	cx				; cx - size of string
	call	strncpy				; copy it to our buffer
	call	MemUnlock			; unlock buffer
	mov	di, bx				; our return handle
	pop	bx				; mem handle of reply data

noString:
	mov	ax,ds:[RPC_regs].RFSR_ax
	mov	cx,ds:[RPC_regs].RFSR_cx
	mov	dx,ds:[RPC_regs].RFSR_dx
	push	ds:[RPC_regs].RFSR_bx		; need to free mem handle first
	mov 	bp, {word}ds:[RPC_flags]
EC <	test	ds:[RPC_flags], not mask RPCFlags			>
EC <	ERROR_NZ	ILLEGAL_RPC_FLAGS				>
	call	MemFree
	pop	bx
	test	bp, RPC_CARRY			;Clears carry
	jz	exit
	stc					; carry was set on reply
exit:
	.leave
	ret

sendError:

;	We tried and failed to connect remotely, so close the connection

if	DEBUGGING
	WARNING	RFSD_LOST_REMOTE_CONNECTION
endif

	call	CloseConnectionWithNotify

	pop	bx				;BX <- message buffer
replyError:
	call	MemFree
	mov	ax, ERROR_DRIVE_NOT_READY
	stc
	jmp	exit
SendRemoteWithReply	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMessageRemote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the remote system, and returns reply
		if any

CALLED BY:	GLOBAL
PASS:		bx	- handle of buffer with message to send
			  (RPC_proc - filled)
		cx	- size
RETURN:		ax - REPLY/NO_REPLY
		bx - handle of buffer with result
		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	fill RPC Header
	if function requires no reply, just send
	send buffer
	wait for reply
	return reply
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NUM_RETRIES	equ	3
SendMessageRemote	proc	near
	uses	cx,dx,di,es,ds,si,bp
	.enter
	call	MemLock
	mov	ds,ax
	push	bx				; mem handle
	clr	si				; ds:si - buffer
EC <	test	ds:[RPC_flags], not mask RPCFlags			>
EC <	ERROR_NZ	ILLEGAL_RPC_FLAGS				>
	or	ds:[RPC_flags], RPC_CALL	; set flag
	segmov	es,dgroup,ax

;	If we are being called as part of a FileEnum, do not P the client
;	semaphore, as FileEnum already does it as part of its work

	cmp	ds:[RPC_FSFunction], DR_FS_FILE_ENUM
	jz	isEnum
	call	PClientSem
	stc
LONG	jnz	exit	
	

;	Some routines don't need a reply back, so just branch

	cmp	ds:[RPC_FSFunction], DR_FS_CUR_PATH_DELETE	
LONG	jz	noReply
	cmp	ds:[RPC_FSFunction], DR_FS_DRIVE_LOCK
LONG	jz	noReply
	cmp	ds:[RPC_FSFunction], DR_FS_DRIVE_UNLOCK
LONG	jz	noReply

isEnum:

;	We need a reply back, so we find a non-empty place in the queue
;	table. Since only one client at a time can come in here, it is
;	unclear why we would possibly need a queue (why not just a single
;	variable), so I nuked this code.
;
;	mov	di, offset threadQueue-(size ThreadQueueTable)
;findBlank:
;EC <	cmp	di, offset threadQueue + (size threadQueue)		>
;EC <	ERROR_AE	THREAD_QUEUE_TABLE_FULL				>
;
;	add	di, size ThreadQueueTable
;	tst	es:[di].TQT_blocked
;	jne	findBlank
;
;	inc	es:[di].TQT_blocked

	inc	es:[curRPCID]
	mov	di, es:[curRPCID]
	mov	ds:[RPC_ID], di
	mov	bp,ds:[RPC_FSFunction]		; save Function name
EC <	cmp	bp, FSFunction						>
EC <	ERROR_AE	ILLEGAL_FS_FUNCTION				>

;	Send out a message to the remote machine

	call	sendMessage			;
LONG	jc	exit			;Exit if we couldn't send the message

getReply:								

;	Wait for the remote machine to reply

	clr	es:[connectionAlive]
	PTimedSem es,replyData.RD_timeoutSem,MESSAGE_TIME_OUT_VALUE,TRASH_AX_BX_CX
	jnc	haveData

;	We've timed out. Exit if we haven't received any heartbeats since
;	we blocked on the semaphore. Otherwise, keep waiting

	tst	es:[connectionAlive]
	jnz	getReply
if	DEBUGGING
	WARNING	RFSD_CALL_TIMED_OUT_WHILE_WAITING_FOR_REPLY
endif
	jmp	exit
haveData:

;	DI = current RPC ID

	PSem	es, [replyData].RD_exclSem

;	Remote the block at the tail of the list. Only in very rare cases will
;	there ever be more than one block in the list, so in general we won't
;	have to do anything but take the first handle in the list.

	mov	bx, es:[replyData].RD_handleList
	mov	ax, MGIT_OTHER_INFO
	call	MemGetInfo
	clr	es:[replyData].RD_handleList
	tst	ax
	jz	atListHead
	mov	es:[replyData].RD_handleList, bx

loopTop:
	mov	dx, bx			;DX <- previous block in list
	mov	bx, ax
	mov	ax, MGIT_OTHER_INFO
	call	MemGetInfo
	tst	ax
	jnz	loopTop

;	BX now has the last block in the linked list

	xchg	bx, dx			;BX <- next-to-last block in list
	clr	ax			;Nuke its next pointer
	call	MemModifyOtherInfo
	mov	bx, dx			;BX <- block we removed from list
	
atListHead:
	VSem	es, [replyData].RD_exclSem


EC<	clr	es:[debugStat].DS_lastProcReply	>
	call	MemLock
	mov	ds,ax
	cmp	di, ds:[RPC_ID]
if	DEBUGGING
	WARNING_NE	RFSD_PACKET_NOT_IN_SYNCH
endif
	jne	noMatch

EC <	cmp	ds:[RPC_FSFunction], FSFunction			>
EC <	ERROR_AE	INVALID_FS_FUNCTION			>
	cmp	bp, ds:[RPC_FSFunction]		; compare reply fsfunction
						; with called fsfunction. 
						; Ignore reply if they don't
						; match.
if	DEBUGGING
	WARNING_NZ	RFSD_REPLY_FS_FUNCTION_MISMATCH
endif
	jnz	noMatch

	call	MemUnlock
	mov	ax,bx				; ax - temp storage
	mov	cx,REPLY
	clc
exit:
	pop	bx
	call	MemUnlock
	pushf					;Save error status
	cmp	bp, DR_FS_FILE_ENUM
	je	noVSem
	call	VClientSem
noVSem:
	popf					;Restore error status	
	mov_tr	bx,ax				; mem handle of reply
	mov_tr	ax, cx
	.leave
	ret
noMatch:

	call	MemFree							
	jmp	getReply

noReply:
	call	sendMessage
	mov	cx, NO_REPLY
	jmp	exit

sendMessage:
	call	RFSendBufferWithRetries
	retn
SendMessageRemote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRemoteDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the remote (mapped) disk handle

CALLED BY:	RFSD
PASS:		es:si - DiskDesc
RETURN:		bx - remote disk handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRemoteDiskHandle	proc	near
	.enter
	mov	bx, es:[si].DD_private
EC <	push	di							>
EC <	mov	di, si							>
EC <	call	ECCheckBoundsESDIFar					>
EC <	mov	di, bx							>
EC <	call	ECCheckBoundsESDIFar					>
EC <	pop	di							>

	mov	bx, es:[bx]
	.leave
	ret
GetRemoteDiskHandle	endp

Client	ends


