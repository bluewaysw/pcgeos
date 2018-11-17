COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	RFSD
FILE:		rfsdOpenClose.asm

AUTHOR:		Andrew Wilson, Jun  1, 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 1/93		Initial revision

DESCRIPTION:
	Contains code to open and close the remote connection	

	$Id: rfsdOpenClose.asm,v 1.1 97/04/18 11:46:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


InitExit	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitRFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	shut down the RFSD

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	various

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExitRFSD	proc	far
	segmov	es,dgroup,bx

	mov	bx, -1			;Just to cause death if anyone tries
	xchg	bx, es:[clientSem]	; to access this after we are called
	call	ThreadFreeSem

	mov	bx, -1
	xchg	bx, es:[notificationTimerLock]
	call	ThreadFreeThreadLock

	mov	bx, -1
	xchg	bx, es:[fileList].handle
	call	MemFree
	clc
	ret
ExitRFSD	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DisplayMessage

DESCRIPTION:	Display a message

CALLED BY:	INTERNAL

PASS:
	ax - CustomDialogBoxFlags
	si - chunk handle of message (in Strings resource)

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/23/93		Initial version

------------------------------------------------------------------------------@
DisplayMessage	proc	far	uses ax, bx, cx, dx, si, di, bp, ds
	params	local	GenAppDoDialogParams
	.enter

	; do a warning

	mov	params.GADDP_dialog.SDP_customFlags, ax
	clr	bx
	clrdw	params.GADDP_dialog.SDP_stringArg1, bx
	clrdw	params.GADDP_dialog.SDP_stringArg2, bx
	clrdw	params.GADDP_dialog.SDP_customTriggers, bx
	clrdw	params.GADDP_dialog.SDP_helpContext, bx
	clrdw	params.GADDP_finishOD, bx
	mov	bx, handle Strings
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	movdw	params.GADDP_dialog.SDP_customString, dssi

	mov	ax, SGIT_UI_PROCESS
	call	SysGetInfo
	mov_tr	bx, ax
	tst	bx
	jz	noNotify
	call	GeodeGetAppObject

	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	mov	dx, size GenAppDoDialogParams
	mov	di, mask MF_CALL or mask MF_STACK
	push	bp
	lea	bp, params
	call	ObjMessage
	pop	bp

noNotify:
	mov	bx, handle Strings
	call	MemUnlock

	.leave
	ret

DisplayMessage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseConnectionWithNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the current connection after putting up a box to 
		notify the user.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 4/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseConnectionWithNotify	proc	far
	push	ax, si
	mov	ax, mask CDBF_SYSTEM_MODAL or \
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	si, offset LostConnectionError
	call	DisplayMessage
	pop	ax, si
	FALL_THRU	RFCloseConnection
CloseConnectionWithNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFCloseConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close connection, delete drives, and shut down

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFCloseConnection	proc	far
	uses	ax, bx, di, es
	.enter

;	If there is a connection thread, then send a message to it to close
;	it.

	segmov	es,dgroup,bx
	mov	bx, es:[connectionThread]
	tst_clc	bx
	jz	alreadyClosed

	mov	al, TRUE
	xchg	es:[closingConnection],al
	tst_clc	al
	jnz	alreadyClosed

	push	bx
	call	GeodeAllocQueue
	mov	cx, bx			; queue for "ack" 
	pop	bx

	mov	ax, MSG_RFSD_CLOSE_CONNECTION
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	;
	; Now, block until we get an "ack"
	;

	;mov	bx, cx			; queue handle
	;call	QueueGetMessage
	;call	GeodeFreeQueue
	;mov_tr	bx, ax
	;call	ObjFreeMessage
	clc

alreadyClosed:
	.leave
	ret
RFCloseConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitRFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point into Driver. (DR_INIT)
		Registers the FSD

CALLED BY:	Kernel
PASS:		nothing
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
	Initialize Semaphores
	Start Server Thread
	Start Dispatch Thread
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
rfsdString		char	"rfsd",0
noCommError	char	"Could not open RFSD com port",0
noIniError	char	"Could not read RFSD parameters",0
miscError	char	"Could not start RFSD connection",0
doneString	char	"Correctly initialized RFSD connection",0
errString	char	"Error initializing RFSD connection",0
InitRFSD	proc	far
	uses	ax,bx,cx,dx,si
	.enter

; register the file system driver

	segmov	ds, cs
	mov	si, offset rfsdString
	call	LogWriteInitEntry

	segmov	es, dgroup, ax

	mov	bx,1
	call	ThreadAllocSem			;create semaphore [CLIENT]
	call	SetRFSDOwner
	mov	es:[clientSem], bx

	call	ThreadAllocThreadLock		;create semaphore [CLIENT]
	call	SetRFSDOwner
	mov	es:[notificationTimerLock], bx

;	Allocate a chunk array to hold all the files we have open

	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	MemAllocLMem			;Allocate a sharable block
	call	SetRFSDOwner

	mov	ax, mask HF_SHARABLE
	call	MemModifyFlags

	call	MemLock	
	mov	ds, ax

	push	bx
	mov	bx, size hptr
	clr	cx
	clr	si
	clr	al
	call	ChunkArrayCreate
	pop	bx
	movdw	es:[fileList], bxsi
	
	call	MemUnlock

;	HACK! If we are loaded up by the system on startup, then when we
;	close a connection, we want to try to startup a new connection, so
;	we detect that we are loaded on startup by checking to see if the
;	UI has been loaded yet.

	mov	ax, SGIT_UI_PROCESS
	call	SysGetInfo
	tst_clc	ax			;Exit if the UI has already been loaded
	jnz	exit			;...else, connect right now
	mov	es:[alwaysConnected], TRUE

	call	RFOpenConnection
	jnc	exit
	mov	si, offset noIniError
	cmp	ax, RFSDCE_CONFIG_ERROR
	je	logEntry
	mov	si, offset noCommError
	cmp	ax, RFSDCE_COMM_ERROR
	je	logEntry
	mov	si, offset miscError
logEntry:
	segmov	ds, cs
	call	LogWriteEntry
	stc
exit:
	pushf
	segmov	ds, cs
	mov	si, offset doneString
	jnc	99$
	mov	si, offset errString
99$:
	call	LogWriteEntry
	popf
	.leave
	ret
InitRFSD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRFSDOwner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the RFSD own this handle

CALLED BY:	InitRFSD

PASS:		bx - handle to modify

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetRFSDOwner	proc near
		uses	ax
		.enter
		mov	ax, handle 0
		call	HandleModifyOwner
		.leave
		ret
SetRFSDOwner	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfAlwaysConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry set if we should always be connected

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ds - dgroup, carry set if should not always be connected
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfAlwaysConnected	proc	near
	segmov	ds, dgroup, ax
	tst_clc	ds:[alwaysConnected]
	jnz	exit
	stc
exit:
	ret	
CheckIfAlwaysConnected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFOpenConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a connection with remote host

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		carry set if error
			ax - error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFOpenConnection	proc	far
	uses	bx,cx,dx,si
	.enter
	segmov	ds,dgroup,bx

	call	PClientSem			;Returns Z-flag clear if 
						; connection is closing

	mov	ax, RFSDCE_CLOSING_CONNECTION	;If the connection is
	stc					; closing, then exit
	LONG jnz 	exit		

	mov	ax, RFSDCE_ALREADY_CONNECTED	
	tst	ds:[connectionThread]
	stc
	LONG jnz	exit

;	Create a thread to handle events and remote file system requests.

	mov	cx, segment DispatchProcessClass
	mov	dx, offset DispatchProcessClass
	mov	bp, 750				;Use default stack size
	mov	si, handle 0			;SI <- geode to own thread

	mov	ax, MSG_PROCESS_CREATE_EVENT_THREAD_WITH_OWNER
	mov	di, segment ProcessClass
	mov	es, di
	mov	di, offset ProcessClass
	segmov	ds, ss				;Make DS a fixup-able segment
	call	ObjCallClassNoLock
	LONG jc	noThread

	segmov	es, dgroup, cx			;ES <- dgroup
	mov	es:[connectionThread], ax

;	Open a port and socket to talk to the other side

	segmov	ds,cs, cx
	mov	si, offset cs:initCategory
	mov	dx, offset cs:initKeyPort
	call	InitFileReadInteger		; ax - value
EC <	ERROR_C	ERROR_RFSD_NO_COM_PORT	>
LONG   	jc	iniError

	mov	es:[portInfo].SPI_portNumber, ax
	mov	dx, offset cs:initKeyBaud
	call	InitFileReadInteger
EC <	ERROR_C	ERROR_RFSD_NO_BAUD_RATE >
LONG	jc	iniError

	mov	es:[portInfo].SPI_baudRate,ax
	mov	dx, offset cs:initKeyName
	mov	di, offset serverName	;ES:DI <- dest for server name
	mov	bp, SERVER_NAME_SIZE shl offset IFRF_SIZE
	call	InitFileReadString
EC <	ERROR_C ERROR_RFSD_NO_SERVER_NAME >
   	jc	iniError

; call init procedures, first open the port

	segmov	ds, es, si
	mov	si, offset portInfo
	mov	cx, size SerialPortInfo
	call	NetMsgOpenPort
	jc	commError
	mov	es:[port], bx

; when we supply the callback address, we use a virtual segment so that
; the code doesn't have to reside in fixed memory

	mov	dx, vseg ServerLoop
	mov	ds, dx
	mov	dx, offset ServerLoop
	mov	cx, SID_RFSD
	mov	bp, cx			;Dest socket uses our ID
	call	NetMsgCreateSocket
	jc	socketError
	mov	es:[socket], ax

;	Handshake with the remote machine

	mov	ax, MSG_RFSD_OPEN_CONNECTION
	mov	bx, es:[connectionThread]
	clr	di
	call	ObjMessage
	clc
exit:
	call	VClientSem
	.leave
	ret

noThread:
	mov	ax, RFSDCE_MEM_ERROR
	jmp	errorExit

socketError:

;	We couldn't open the socket, so close the port

	mov	bx, es:[port]
	call	NetMsgClosePort
commError:
	mov	ax, RFSDCE_COMM_ERROR
	jmp	nukeThread

iniError:
	mov	ax, RFSDCE_CONFIG_ERROR
nukeThread:
	push	ax
	mov	ax, MSG_META_DETACH
	clr	cx
	clr	dx
	clr	bp
	clr	bx
	xchg	bx, es:[connectionThread]
	clr	di
	call	ObjMessage
	pop	ax
errorExit:
	stc
	jmp	exit	
RFOpenConnection	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDOpenConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialization thread.

CALLED BY:	SYSTEM [called when thread is created]
PASS:		nothing
RETURN:		nothing
DESTROYED:	variable

PSEUDO CODE/STRATEGY:
LOOP:
	Ask for drive info
Every X seconds UNTIL Reply
	store drive info
	exit thread

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDOpenConnection	method	DispatchProcessClass, MSG_RFSD_OPEN_CONNECTION
	.enter

;	Create an RFSHeader to send the RFS_HANDSHAKE_REQUEST_DRIVE_INFORMATION;       request to the remote machine

	mov	cx, size RFSHeader
	sub	sp, cx
	mov	bp, sp
	segmov	ds, ss
	mov	ds:[bp].RPC_proc, RFS_HANDSHAKE_REQUEST_DRIVE_INFORMATION
	mov	ds:[bp].RPC_flags, RPC_CALL
	mov	si, bp
send:	
	tst	es:[closingConnection]		;Are we closing the connection?
	jnz	exit				;Don't retry, if so.
	call	RFSendBuffer
	jnc	connected
	tst	es:[closingConnection]		;Are we closing the connection?
	jnz	exit				;Don't retry, if so.
	mov	ax, HANDSHAKE_RETRY_WAIT_VALUE
	call	TimerSleep			; wait...
	jmp	send
connected:

;	We have a connection to the remote machine now, so add ourselves to
;	the GCNSLT_FILE_SYSTEM GCN list

	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	mov	cx, es:[connectionThread]
	clr	dx
	call	GCNListAdd

;	It is possible for the remote machine to get our request for drive
;	information, then never send it (they close the connection or go off
;	line, or something stupid like that). So, we create a timer that
;	will go off in 20 seconds or so - if we haven't received the drives
;	within that time, then we request them again.
;
;	It doesn't matter if we end up requesting them twice, because each
;	time we get a new set of drive information, we nuke our old drives.

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, es:[connectionThread]
	mov	bp, handle 0
	mov	cx, DRIVE_REQUEST_TIMEOUT
	mov	dx, MSG_RFSD_REQUEST_DRIVES_TIMEOUT
	call	TimerStartSetOwner
	mov	es:[driveRequestTimerID], ax
	mov	es:[driveRequestTimer], bx
exit:
	add	sp, size RFSHeader
	.leave
	ret
RFSDOpenConnection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDRequestDrivesTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is sent when the driveRequestTimer has
		expired, meaning that we need to re-request drives if
		we haven't already received them.

CALLED BY:	GLOBAL
PASS:		es, ds - dgroup
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDRequestDrivesTimeout	method	DispatchProcessClass,
				MSG_RFSD_REQUEST_DRIVES_TIMEOUT
	.enter
	cmp	bp, es:[driveRequestTimerID]
	jnz	exit
	clr	es:[driveRequestTimer]
	clr	es:[driveRequestTimerID]
	tst	es:[haveDrives]	;If we have drives now, exit
	jnz	exit

;	We haven't received any drives yet, so re-request them.

	mov	ax, MSG_RFSD_OPEN_CONNECTION
	mov	bx, es:[connectionThread]
	clr	di
	call	ObjMessage

exit:
	.leave
	ret
RFSDRequestDrivesTimeout	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDSendDrivesRemote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends All Local Drive Info to remote client

CALLED BY:	
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/ 6/92   	Initial version
	ISR	1/ 21/92   	Revised to batch-send all drives at once
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
initCategory	char "link",0
initKeyDrive	char "drives",0
initKeyBaud	char "baudRate",0
initKeyPort	char "port",0
initKeyName	char "name",0

RFSDSendDrivesRemote	method dynamic DispatchProcessClass, 
					MSG_RFSD_SEND_DRIVES_REMOTE

;
;	When we start up, we will always send drives to the remote machine
;	before we will receive drives from the remote machine. This means
;	that if we ever get a request for drives while we already have
;	drives, we should nuke our drives and import them again.
;

	tst	es:[haveDrives]
	jz	noDrives

	call	CleanupOldConnection	;Close our drives, and any files
					; we have open for the remote
					; machine

	call	RFSDOpenConnection	;Request new drives before sending
					; our drives to the remote machine

noDrives:

;	Allocate a block to hold all the drive data

	mov	ax, size DriveInformationData
	mov	cx, (mask HF_SWAPABLE) or (((mask HAF_LOCK) or \
			(mask HAF_NO_ERR)) shl 8)

	call	RFSDMemAlloc
	push	bx
	mov	es, ax
	mov	es:[RPC_proc], RFS_HANDSHAKE_DRIVE_INFORMATION
	mov	es:[RPC_flags], RPC_CALL
	clr	es:[DID_numDrives]

	segmov	ds, cs, cx
	mov	si, offset initCategory	;ds:si - category string 
	mov	dx, offset initKeyDrive	;cx:dx - key string
	clr	bp			;InitFileReadFlags
	mov	di, cs
	mov	ax, offset SendDriveCallBackRoutine	; di:ax - callback

	call	InitFileEnumStringSection

;	If no drives listed in the .ini file, export *all* the drives.

	call	MemDerefES
	tst	es:[DID_numDrives]
	jz	createDriveList

	;
	; Find any PCMCIA card already inserted in the slot and export them
	;
		call	FSDLockInfoShared
		mov	es, ax
		mov	si, es:[FIH_driveList]
		tst	si
		jz	unlock
checkPCMCIADrive:
		mov	ax, es:[si].DSE_status
		andnf	al, mask DS_TYPE
		cmp	al, DRIVE_PCMCIA
		jne	checkNextDrive

		call	CheckForDuplicateDrive
		jc	checkNextDrive
		call	AddDriveInformation
checkNextDrive:
		mov	si, es:[si].DSE_next
		tst	si
		jnz	checkPCMCIADrive
		jmp	unlock

sendDrivesOver:

; here, ^hBX:0h is start of buffer to send over...

	call	MemDerefDS
	segmov	es,dgroup,si
	clr	si			;DS:SI <- buffer to send

	call	SortDriveList	;Sort the drive list

;	Get the # bytes to send

	mov	ax, MGIT_SIZE
	call	MemGetInfo
	mov_tr	cx, ax				;CX <- # bytes to send over

;	Sit and try to export these drives until someone closes the connection

	tst	es:[closingConnection]
	jnz	error
	call	RFSendBufferWithRetries
	jc	noExport

	mov	es:[sentDrives], TRUE
	
EC <	WARNING	LOCAL_DRIVES_EXPORTED			>
error:	
	pop	bx
	GOTO	MemFree

createDriveList:

;
;	No drives were listed in the export list, or some other error occured.
;	Just export all the non-removable drives (non-PCMCIA drives) from the
;	system.
;
;	NOTE: There is a difference between a removable drive, and a drive with
;	      removable *media*. We can handle removable media, but if we
;	      export (or import) a removable DRIVE, and the drive gets removed,
;	      we'll croak, as the drive entry will no longer be valid.

	clr	es:[DID_numDrives]
	call	FSDLockInfoShared
	mov	es, ax
	mov	si, es:[FIH_driveList]
	tst	si
	jz	unlock
nextDrive:

	call	AddDriveInformation	;Add information about all drives to
					; the DriveInformationData block whose
					; handle is in BX
	mov	si, es:[si].DSE_next	;ES:SI <- next DriveStatusEntry
	tst	si
	jnz	nextDrive
unlock:
	call	FSDUnlockInfoShared
	jmp	sendDrivesOver
noExport:

;	For some reason, we couldn't export the drives, so re-open the
;	connection.

	pop	bx
	call	MemFree
	GOTO	RFSDOpenConnection
RFSDSendDrivesRemote	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForDuplicateDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for a duplicate drive in the drive list to export.
		In case of PCMCIA card, somebody might have already specified
		in init  file so that it alredy got on the list to export.

CALLED BY:	RFSDSendDrivesRemote
PASS:		bx	- handle of DriveInformationData
		es:[si] - DriveStatusEntry for a drive
RETURN:		carry set if there is already an entry for this drive on
		the list to export.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForDuplicateDrive	proc	near
		uses	ds,es,cx,di,ax
		.enter
	;
	; Go throuoght he list of drives to export and see if there is
	; an entry for the same drive passed in 
	;
		segmov	es,ds,cx
		call	MemDerefES
		mov	cx, es:[DID_numDrives]
		mov	di, size DriveInformationData
			; es:di = first DriveInfoStruct
			; ds:si = DriveStatusEntry for PCMCIA drive
		mov	al, ds:[si].DSE_number
checkLoop:
		cmp	al, es:[di].DIS_number
		je	duplicateFound			; carry clear
		add	di, size DriveInfoStruct
		loop	checkLoop
		stc
duplicateFound:
		cmc
		.leave
		ret
CheckForDuplicateDrive	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SortDriveList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sorts the list of drives

CALLED BY:	GLOBAL
PASS:		ds - segment of block containing DriveInformationData
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SortDriveList	proc	near		uses	ax, cx, si
	params	local	QuickSortParameters
	.enter
	mov	cx, ds:[DID_numDrives]
	jcxz	exit
	mov	ax, size DriveInfoStruct
	mov	si, offset DID_driveInfo

	mov	params.QSP_compareCallback.segment, cs
	mov	params.QSP_compareCallback.offset, offset CompareDriveInfoStructs
	clr	params.QSP_lockCallback.segment	;Don't need to lock elements
	clr	params.QSP_unlockCallback.segment

	mov	params.QSP_insertLimit, DEFAULT_INSERTION_SORT_LIMIT
	mov	params.QSP_medianLimit, DEFAULT_MEDIAN_LIMIT
;
;	DS:SI <- ptr to array of DriveInfoStruct structures
;	CX <- # elements in array
;	AX <- size of each element
;	SS:BP - ptr to inheritable QuickSortParameters
;
	call	ArrayQuickSort
exit:
	.leave
	ret
SortDriveList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareDriveInfoStructs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compares two DriveInfoStructs.

CALLED BY:	GLOBAL
PASS:		ds:si, es:di - DriveInfoStruct to compare

RETURN:		flags so caller can jl, je, or jg
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareDriveInfoStructs	proc	far
	.enter
	clr	ah			;Do unsigned comparison of drive
	clr	bh			; numbers.
	mov	al, ds:[si].DIS_number
	mov	bl, es:[di].DIS_number
	cmp	ax, bx
	.leave
	ret
CompareDriveInfoStructs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDriveCallBackRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends Drive Info to client machine

CALLED BY:	InitFileEnumStringSection
PASS:		ds:si 	- drive name
		cx	- string size
		bx - handle of block containing drive information
RETURN:		carry if error 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/ 4/92		Initial version
	ISR	1/ 21/92	Revised to batch-receive all drives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendDriveCallBackRoutine	proc	far
	.enter
	mov	dx,si
	call	FSDLockInfoShared
	mov	es,ax
	call	DriveLocateByName		;es:si - DriveStatusEntry
	jc	error
	call	AddDriveInformation
error:
	call	FSDUnlockInfoShared
	clc
	.leave
	ret
SendDriveCallBackRoutine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddDriveInformation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds drive information for the passed drive

CALLED BY:	GLOBAL
PASS:		bx - handle of DriveInformationData
		es:[si] - DriveStatusEntry for a drive
RETURN:		nada
DESTROYED:	cx, dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddDriveInformation	proc	near
	uses	bx, ds, es, si
	.enter

	segmov	ds,es,cx			; ds:si - DriveStatusEntry
; we must clear the LOCAL_ONLY flag from the DriveExtendedStatus record
EC <	call	ECCheckBounds					>
	andnf	ds:[si].DSE_status, not (mask DES_LOCAL_ONLY)

;	Re-allocate the block to be large enough to hold this drive

	call	MemDerefES
	inc	es:[DID_numDrives]
	mov	ax, es:[DID_numDrives]
	mov	cx, size DriveInfoStruct
	mul	cx
EC <	tst	dx							>
EC <	ERROR_NZ	-1						>

	add	ax, size DriveInformationData
	mov	di, ax
	clr	ch
	call	MemReAlloc			;
	mov	es, ax				;ES

	mov	cl, ds:[si].DSE_number
	mov	es:[di-size DriveInfoStruct].DIS_number, cl

	mov	cl, ds:[si].DSE_defaultMedia
	mov	es:[di-size DriveInfoStruct].DIS_defaultMedia, cl
	mov	cx,  ds:[si].DSE_status
	mov	es:[di-size DriveInfoStruct].DIS_status, cx

	lea	di, es:[di-size DriveInfoStruct].DIS_nameString

;	Create a drive name: <serverName>-<localDriveName>

	push	ds,si
	segmov	ds, dgroup,ax
	mov	si, offset serverName		
	call	strcpy				; pre-pend server name
	add	di, ax
	mov	{char} es:[di-1], '-'
	pop	ds,si
	add	si, offset DSE_name		; append drive name
	call	strcpy				;
	.leave
	ret
AddDriveInformation	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDUseRemoteDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use drive information for a remote drive and initialize it

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx 	= mem handle of buffer from remote machine
RETURN:		nothing
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

	DriveInformationData<>
	array of DriveInfoStruct structures

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDUseRemoteDrives	method dynamic DispatchProcessClass, 
					MSG_RFSD_USE_REMOTE_DRIVES
	.enter

;
;	We've finally gotten the drive information for which we've been
;	waiting. Nuke the retry timer.
;
	clr	bx
	xchg	es:[driveRequestTimer], bx
	tst	bx
	jz	noDriveRequestTimer
	clr	ax
	xchg	es:[driveRequestTimerID], ax
	call	TimerStop
noDriveRequestTimer:
	
;
;	We got a new connection from the remote machine, so close any drives
;	we've previously imported, then add these new ones.
;

	push	cx
	call	CloseImportedDrives

	mov	es:[haveDrives], TRUE
	mov	cx, segment RFStrategy
	mov	dx, offset RFStrategy
	mov	ax, FSD_FLAGS
	mov	bx, handle 0
	mov	di, size DDPrivateData		; privdata for disks 
	call	FSDRegister
	mov	es:[fsdOffset], dx
	pop	bx

	call	MemLock				; lock buffer
	push	bx
	mov	es,ax
	mov	bp, es:[DID_numDrives]
	lea	di, es:[DID_driveInfo]
	tst	bp
	jz	exit
doloop:
	call	FSDLockInfoExcl			; lock for exclusive access
	mov	ds,ax
	mov	cx, size RFSPrivateData
	call	LMemAlloc			; allocate private data chunk
	mov_tr	si,ax				; ds:si - lmem chunk
	segmov	ds:[si].RFS_number, es:[di].DIS_number, al
	call	FSDUnlockInfoExcl
	mov	al, -1				; need a net drive #
	mov	ah, es:[di].DIS_defaultMedia
	mov	bx, si
	mov	cx, es:[di].DIS_status		; cx <- DriveExtendedStatus

	;
	; Since RFSD doesn't support DR_FS_DISK_FORMAT, we don't mark
	; any remote drives formattable. When we do support remote
	; disk formatting, we can remove the below instruction.
	;					-simon  11/30/94
	;
	BitClr	cx, DES_FORMATTABLE
	
	segmov	ds,es,dx
	push	es
	segmov	es,dgroup,dx
	mov	dx, es:[fsdOffset]
	pop	es
	mov	si, di
	add	si, offset DIS_nameString	; ds:si - drive name
	call	FSDInitDrive			; dx - offset DriveStatusEntry
; loop and process remaining drives
	add	di, size DriveInfoStruct
	dec	bp
	jnz	doloop
exit:
	pop	bx
	call	MemFree				; free buffer 
EC <    WARNING REMOTE_DRIVE_RECEIVED		>
	.leave
	ret
RFSDUseRemoteDrives	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseFilesInFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes all the files in the file list

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseFilesInFileList	proc	near	uses	ax, bx, di
	.enter
	call	LockFileList
	push	bx
	mov	bx, cs
	mov	di, offset CloseFileFromListCallback
	call	ChunkArrayEnum

;	Make sure all the files were freed

EC <	push	cx							>
EC <	call	ChunkArrayGetCount					>
EC <	tst	cx							>
EC <	ERROR_NZ	-1						>
EC <	pop	cx							>
	pop	bx
   	call	MemUnlock
	.leave
	ret
CloseFilesInFileList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseFileFromListCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes a file from the file list

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to file handle
RETURN:		nada
DESTROYED:	ax, bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseFileFromListCallback	proc	far 
	.enter
	clr	al
	mov	bx, ds:[di]
	call	FileClose
	call	ChunkArrayDelete
	clc
	.leave
	ret
CloseFileFromListCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CleanupOldConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleans up any stuff we have hanging around from an old 
		connection, such as open files, current paths, imported
		drives, etc.

CALLED BY:	GLOBAL
PASS:		*ds:si - Cleans up the old connection
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CleanupOldConnection	proc	near
	.enter

;	Sit in a loop, and nuke all open paths, then set the path to the
;	root directory

nukePath:
	mov	bx, ss:[TPD_curPath]
	call	MemLock
	mov	ds, ax
	tst	ds:[FP_prev]	;If FP_prev is 0, then we've reached the head
	call	MemUnlock	; of the chain.
	jz	done
	call	FilePopDir
	jmp	nukePath
done:

;	Set the CWD to the top of our directory structure

	segmov	ds, cs
	mov	dx, offset null
	mov	bx, SP_TOP
	call	FileSetCurrentPath
	
	call	CloseFilesInFileList
	call	CloseImportedDrives
	.leave
	ret

null	char	C_NULL
CleanupOldConnection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDCloseConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the connection to the remote drives

CALLED BY:	GLOBAL

PASS:		cx - handle of queue to send ACK to when connection is closed.

RETURN:		nothing 

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDCloseConnection	method DispatchProcessClass, 
			MSG_RFSD_CLOSE_CONNECTION

	push	cx		; ACK handle

;	NOTE: There is still a slight synchronization hole. The system sets
;	the closingConnection flag to "TRUE", but a request from the remote
;	machine could still sneak in after this code is called. It should not
;	make a difference, as SendReplyRegsAndBufferInDSSI and
;	SendReplyPassRegisters check the closingConnection flag (which is
;	set by RFCloseConnection) and do not try to send if it is set.


EC <	tst	es:[closingConnection]					>
EC <	ERROR_Z	-1							>

	call	PClientSem			; Ensure that nobody is 
	call	VClientSem			; trying to send data remotely


;	We are nuking the connection to the remote machine now, so remove
;	ourselves from the GCNSLT_FILE_SYSTEM GCN list, as we don't care
;	about them anymore

	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	mov	cx, es:[connectionThread]
	clr	dx
	call	GCNListRemove

	call	CloseRemoteRFSD			;

	call	CleanupOldConnection

;	We can be assured that nobody is making any calls to us (we've
;	unregistered), so we can nuke the notification timer and be assured
;	that nobody will start it up.
;

	clr	bx
	xchg	es:[notificationTimer], bx
	tst	bx
	jz	noNotificationTimer
	clr	ax
	xchg	es:[notificationTimerID], ax
	call	TimerStop
noNotificationTimer:

;	We may have been waiting for drives to arrive from the remote machine.
;	If so, nuke the timer.

	clr	bx
	xchg	es:[driveRequestTimer], bx
	tst	bx
	jz	noDriveRequestTimer
	clr	ax
	xchg	es:[driveRequestTimerID], ax
	call	TimerStop
noDriveRequestTimer:

;
;	Flush out any file change notifications that have been queued up
;
	call	FileFlushChangeNotifications

;	If we should always be connected, then restart the connection (don't
;	close the port/socket).

	call	CheckIfAlwaysConnected
	jnc	reConnect

;	Destroy the port and socket.

	mov	bx, -1
	mov	dx, bx
	xchg	bx, es:[port]
	xchg	dx, es:[socket]

	push	bx
	call	NetMsgDestroySocket
	pop	bx
	call	NetMsgClosePort

;	We flush the input queue before clearing out the closingConnection
;	variable, to ensure that no delayed FS requests come through. 

	clr	bx
	xchg	es:[connectionThread], bx

	mov	ax, MSG_RFSD_CONNECTION_CLOSED
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

		pop	dx			; Ack handle
		clr	dx
	mov	ax, MSG_META_DETACH
	mov	di, mask MF_FORCE_QUEUE
	clr	cx, bp
	GOTO	ObjMessage

reConnect:

	; Just send the "ack", since this thread won't be going away.
	;
	pop	bx
	mov	ax, MSG_META_ACK
	clr	di
	call	ObjMessage 

;	Clear out the event queue, then reopen the connection.

	mov	ax, MSG_RFSD_CONNECTION_CLOSED
	mov	bx, es:[connectionThread]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	mov	ax, MSG_RFSD_OPEN_CONNECTION
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage
RFSDCloseConnection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDConnectionClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears out the closingConnection variable. This is done via
		a method so we can clear out the queue first.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDConnectionClosed	method	DispatchProcessClass, 
			MSG_RFSD_CONNECTION_CLOSED
	.enter
	clr	es:[closingConnection]
	.leave
	ret
RFSDConnectionClosed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseImportedDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes any drives we've imported

CALLED BY:	GLOBAL
PASS:		es - dgroup
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseImportedDrives	proc	near
	uses	es
	.enter

	clr	al
	xchg	al, es:[haveDrives]
	tst	al
	jz	exit

; now we delete the drive descriptors...

	mov	al, MAX_DRIVE_NUMBER		; 254
deleteLoop:
	call	FSDLockInfoSharedES
nextDrive:
	call	DriveLocateByNumber		;Get the DriveStatusEntry for
	jc	next				; this drive. Branch if this
						; drive doesn't exist.

	mov	bx, es:[si].DSE_fsd
	cmp	es:[bx].FSD_handle, handle 0
	je	removeOurDrive			;Try to delete the drive if
						; possible
next:
	dec	al
	cmp	al, -1
	jne	nextDrive

	call	FSDUnlockInfoShared

	segmov	es, dgroup, dx
	mov	dx, es:[fsdOffset]
	tst	dx
	jz	exit
	call	FSDUnregister
EC <	WARNING_C	RFSD_COULD_NOT_UNREGISTER			>
exit:
	.leave
	ret

removeOurDrive:

;	Notify the world that we are removing this drive.

	mov	di, es:[FIH_diskList]

;	Scan through all the disks that are open to this drive, and notify
;	the system that they are going away.

scanDiskList:
EC <	push	ds, si							>
EC <	segmov	ds, es							>
EC <	mov	si, di							>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>
	;ES:DI <- DiskDesc
	mov	bx, es:[di].DD_drive
	cmp	es:[bx].DSE_number, al
	jne	tryNextDisk
	mov	bx, di			;BX <- disk handle (offset of DiskDesc)
	push	ax, di
	call	FFSRNotify
	pop	ax, di
tryNextDisk:
	mov	di, es:[di].DD_next
	tst	di
	jnz	scanDiskList
	call	FSDUnlockInfoShared
	call	FSDDeleteDrive
	jnc	deleteLoop

;	Somebody has a file open on this drive or something, so sleep until
;	it is closed.

	push	ax
	mov	ax, 8 * 60		;Sleep for 8 seconds and try nuking
	call	TimerSleep		; the drive again
	pop	ax

	call	FSDLockInfoSharedES
	jmp	removeOurDrive

FSDLockInfoSharedES:
	push	ax
	call	FSDLockInfoShared
	mov	es, ax
	pop	ax
	retn
CloseImportedDrives	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FFSRNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify everyone to stop using the disk.

CALLED BY:	DeleteDrives
PASS:		bx	= handle of disk being removed
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/20/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FFSRNotify	proc	far
		.enter
	;
	; Send out a MSG_META_REMOVING_DISK to tell everyone to stop using
	; the thing.
	; 
		mov	cx, bx
		clr	dx			; no data block.
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	si, GCNSLT_REMOVABLE_DISK
		mov	ax, MSG_META_REMOVING_DISK
		mov	di, mask GCNLSF_FORCE_QUEUE
		push	cx
		call	GCNListRecordAndSend
		pop	cx
	;
	; Send out a MSG_META_REMOVING_DISK to tell everyone to stop using
	; the thing.
	; 
		clr	dx			; no data block.
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	si, GCNSLT_FILE_SYSTEM
		mov	ax, MSG_META_REMOVING_DISK
		mov	di, mask GCNLSF_FORCE_QUEUE
		push	cx
		call	GCNListRecordAndSend
		pop	cx
	;
	; To make life simpler for people, also broadcast the message to all
	; owners of files open to the disk.
	; 
		mov	di, cs
		mov	si, offset FFSRCR_callback
		clr	bx			; process entire list
		call	FileForEach
		.leave
		ret
FFSRNotify	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FFSRCR_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to notify the owners of all files open to
		the in-use disk that's being removed.

CALLED BY:	FFSRCardReinserted via FileForEach
PASS:		bx	= handle of open file
		ds	= kdata
		cx	= handle of affected disk
RETURN:		carry set to stop
DESTROYED:	di, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FFSRCR_callback	proc	far
		uses	bx
		.enter
		cmp	ds:[bx].HF_disk, cx	; on affected disk?
		jne	done			; no

		mov	bx, ds:[bx].HF_owner
		mov	ax, GGIT_ATTRIBUTES
		call	GeodeGetInfo
		test	ax, mask GA_PROCESS	; is owner a process?
		jz	done			; no
		
		cmp	bx, handle geos		; is owner the kernel?
		je	done			; yes -- not a real process
	;
	; Queue it a message, then.
	; 
		mov	ax, MSG_META_REMOVING_DISK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		clc
		.leave
		ret
FFSRCR_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseRemoteRFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call remote system to close connection

CALLED BY:	RFCloseConnection
PASS:		es - dgroup
RETURN:		nothing
DESTROYED:	various
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseRemoteRFSD	proc	near		uses	ds, si, cx
	.enter

;	Don't bother closing the remote connection if we never made one -
;	if we never sent any drives to the remote machine.

	tst	es:[sentDrives]
	jz	exit

	mov	cx, size RFSHeader
	sub	sp, cx
	mov	si, sp
	segmov	ds, ss		;DS:SI <- RFSHeader
	mov	ds:[si].RPC_proc, RFS_HANDSHAKE_CLOSE_CONNECTION
	mov	ds:[si].RPC_flags, RPC_CALL
	call	RFSendBuffer
	add	sp, cx
	clr	es:[sentDrives]
exit:
	.leave
	ret
CloseRemoteRFSD	endp

InitExit	ends
