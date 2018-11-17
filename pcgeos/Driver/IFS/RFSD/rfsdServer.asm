COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		rfsdServer.asm

AUTHOR:		In Sik Rhee, Jun  1, 1992

ROUTINES:
	Name			Description
	----			-----------
	ServerLoop		main server routine - dispatches messages
	SendReplyPassRegisters
	SendReplyRegsAndBufferInDSSI
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/ 1/92		Initial revision


DESCRIPTION:
	Server routines

	$Id: rfsdServer.asm,v 1.1 97/04/18 11:46:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Common	segment	resource
ServerTable	word	MSG_RFS_DISK_DRIVE_NUMBER,
			MSG_RFS_DISK_INIT,
			MSG_RFS_HANDOFF,
			MSG_RFS_HANDOFF,
			0,
			MSG_RFS_HANDOFF,
			MSG_RFS_DISK_INFO,
			MSG_RFS_DISK_RENAME,
			0,0,0,0,
			MSG_RFS_CUR_PATH_SET,
			MSG_RFS_CUR_PATH_GET_ID,
			MSG_RFS_CUR_PATH_DELETE,
			MSG_RFS_CUR_PATH_COPY,
			MSG_RFS_HANDLE_OP,
			MSG_RFS_ALLOC_OP,
			MSG_RFS_PATH_OP,
			0,
			MSG_RFS_FILE_ENUM,
			MSG_RFS_DISK_DRIVE_NUMBER,	;DriveLock
			MSG_RFS_DISK_DRIVE_NUMBER	;DriveUnlock

.assert	size ServerTable eq (FSFunction - DR_FS_DISK_ID)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ServerLoop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Server Process - handles all incoming messages

CALLED BY:	Comm Driver
PASS:		ds:si - buffer
		cx - size	(0 if connection being closed)
RETURN:		nothing
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ServerLoop	proc	far
	uses	ds,bp
	.enter
	segmov	es, dgroup, ax
.assert	SOCKET_DESTROYED	eq	0
	tst	cx
LONG	jz	exit
	cmp	cx, SOCKET_HEARTBEAT
	jnz	10$
	mov	es:[connectionAlive], TRUE
	jmp	exit
10$:
	mov	ax,cx 
	push	cx
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	RFSDMemAlloc
	mov	es,ax
	clr	di
	pop	cx

	call	strncpy					; es:di - input buf
	segmov	ds, dgroup, ax
	tst	ds:[closingConnection]
 	jne	freeExit

;	If this is not a call (the RPC_CALL bit is not set) then it must
;	be a reply...

EC <	test	es:[RPC_flags], not mask RPCFlags			>
EC <	ERROR_NZ	ILLEGAL_RPC_FLAGS				>

	test	es:[RPC_flags],RPC_CALL
	jz	isReply
	
	mov	al, es:[RPC_proc]
EC <	tst	al							>
EC <	ERROR_Z	INVALID_RFS_MESSAGE					>
	cmp	al, RFS_Message						
EC <	ERROR_AE	INVALID_RFS_MESSAGE				>
NEC <	jae	freeExit						>
	clr	ah
	mov_tr	di, ax
	call	cs:[serverJumpTable-2][di]
exit:
	.leave
	ret

freeExit:
	call	MemFree
	jmp	exit

isReply:

; here, this is a reply being sent back, so V the semaphore that the caller
; is waiting on.

EC <	mov	si, es:[RPC_FSFunction]			>
EC <	mov	ds:[debugStat].DS_lastProcReply, si	>
	call	MemUnlock

	PSem	ds, replyData.RD_exclSem

;	The queue of reply data blocks is a list linked by the HM_otherInfo
;	field.

	mov	ax, ds:[replyData].RD_handleList
	mov	ds:[replyData].RD_handleList, bx
	call	MemModifyOtherInfo

	VSem	ds, replyData.RD_exclSem, TRASH_AX_BX
	VSem	ds,replyData.RD_timeoutSem,TRASH_AX_BX
	jmp	exit

ServerLoop	endp

serverJumpTable	nptr	RequestDrives, 
			HaveRemoteDriveInfo, 
			CloseConnection, 
			FlushFileChangeNotifications,
			DoFSFunction, 
			Death, 		;RFS_REPLY/RFS_REPLY_ERROR
			Death, 
			RemoteNotification
.assert	(size serverJumpTable+2) eq RFS_Message

;
;	Pass: ds - dgroup
;	      es - segment of call data
;	      bx - handle of call data
;

Death	proc	near
;
; We received an RFS_REPLY/RFS_REPLY_ERROR message, with the RFS_CALL bit
; set. This ain't allowed.
;
EC <	ERROR	INVALID_RFS_MESSAGE					>
NEC <	ret								>
Death	endp
RequestDrives	proc	near

;	We received a "GetDrives" request from the remote machine, so send
;	off the drives.

	call	MemFree		;Free up message data
	mov	ax, MSG_RFSD_SEND_DRIVES_REMOTE
	GOTO	SendToRFSDThread
RequestDrives	endp

HaveRemoteDriveInfo	proc	near
	call	MemUnlock			;Unlock the call data
	mov	ax, MSG_RFSD_USE_REMOTE_DRIVES
	mov	cx, bx				;
	FALL_THRU	SendToRFSDThread
HaveRemoteDriveInfo	endp		

SendToRFSDThread	proc	near
	mov	bx, ds:[connectionThread]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
SendToRFSDThread	endp

CloseConnection	proc	near
	call	MemFree			;Free up message data

;	If we are still trying to connect (we haven't received drives from
;	the remote machine yet) then ignore this message. The code in
;	RFSDOpenConnection creates a timer that will eventually cause the
;	code to try to reestablish the connection again.
;	

	tst	ds:[haveDrives]
	jz	exit
;
;	We're doing an orderly disconnect, so don't bother putting up a
;	dialog box, just disconnect.

	call	RFCloseConnection
exit:
	ret
CloseConnection	endp

DoFSFunction	proc	near
	mov	di, es:[RPC_FSFunction]
EC <	mov	ds:[debugStat].DS_lastProcIN, di			>
EC <	cmp	di, FSFunction 						>
EC <	ERROR_AE	ILLEGAL_FS_FUNCTION				>
	mov	ax, cs:ServerTable[di-DR_FS_DISK_ID]	;Get msg #
	mov	cx, bx
	call	MemUnlock
	GOTO	SendToRFSDThread
DoFSFunction	endp

FlushFileChangeNotifications	proc	near
	call	MemFree
	mov	ax, MSG_RFSD_FLUSH_FILE_CHANGE_NOTIFICATIONS
	GOTO	SendToRFSDThread
FlushFileChangeNotifications	endp


;============================================================================
;
; Extenstion(5/17/94):
;
; RFSD remote notification also recognizes drive change notification
;
;============================================================================

RemoteNotification	proc	near
	;
	; Check for drive change notification
	;
	mov	ax, es:[RPC_ID]
	cmp	ax, RFSDFOD_driveChange
	mov	cx, bx	
	call	MemUnlock
	je	driveChangeNotification	
		
	mov	ax, MSG_RFSD_REMOTE_FILE_CHANGE_NOTIFICATION
	GOTO	SendToRFSDThread
driveChangeNotification:
	mov	ax, MSG_RFSD_REMOTE_DRIVE_CHANGE_NOTIFICATION
	GOTO	SendToRFSDThread
		
RemoteNotification	endp


Common	ends

Server	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendReplyPassRegisters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send reply from server to remote client, include registers

CALLED BY:	RFSD
PASS:		ax,bx,cx,dx - reg value
		bp - FSFunction
		di - RPC_ID for reply
		set carry to pass RPC_CARRY
RETURN:		nothing
DESTROYED:	ax,bx,cx,si,ds,es,bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendReplyPassRegisters	proc	near
	.enter
	push	di
	mov	di,0					; preserve flags
	jnc	cont
	mov	di,RPC_CARRY				; carry flag
cont:
	push	di	
	clr	di
	call	PackageOutBuffer
	pop	bp
	pop	di
	call	MemLock
	mov	ds,ax
	clr	si
	mov	ds:[si].RPC_ID, di
	segmov	es,dgroup,ax
	mov	ax, bp
	or	ds:[si].RPC_flags, al			; set carry bit?

	tst	es:[closingConnection]
	jnz	freeAndExit
	call	RFSendBufferWithRetries
	jc	closeConnection
freeAndExit:
	call	MemFree					; free message buffer
exit:
	.leave
	ret

closeConnection:
	call	MemFree

if 	DEBUGGING
	WARNING	RFSD_LOST_REMOTE_CONNECTION
endif
	call	CloseConnectionWithNotify
	jmp	exit
SendReplyPassRegisters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendReplyRegsAndBufferInDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replies to a function, passing registers and a buffer
		in ds:si

CALLED BY:	RFSDiskInit,RFSDiskInfo
PASS:		ax,bx,cx,dx 	- registers
		ds:si		- buffer
		di		- buffer size (include null char)
		bp - FSFunction
		ss:sp		- RPC_ID (word) passed on stack for reply
		set carry to pass RPC_CARRY
RETURN:		nothing
DESTROYED:	variable 

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
SendReplyRegsAndBufferInDSSI	proc	near	id:word
	uses	ds,si
	function	local	FSFunction	\
			push	bp
	bufferSize	local	word	\
			push	di
	.enter
EC <	pushf								>
EC <	call	ECCheckBounds						>
EC <	tst	bufferSize						>
EC <	jz	skipCheck						>
EC <	push	si							>
EC <	add	si, bufferSize						>
EC <	dec	si							>
EC <	call	ECCheckBounds						>
EC <	pop	si							>
EC <skipCheck:								>
EC <	popf								>

;	Save the carry state

	push	si
	mov	di,0
	jnc	cont
	mov	di, RPC_CARRY
cont:
	push	di					;Save flags

;	Package up the registers into a RFSHeader/RFSRegisters structure

	push	bp
	clr	di
	mov	si, id					;Pass RPC_ID in SI
	mov	bp, function
	call	PackageOutBuffer
	pop	bp
	pop	si					;SI <- flags

;	Append the extra data (preceded by the size) to the end of the
;	data block, and send it off to the destination.

	mov	ax,bufferSize				; dx - buf size
	add	ax, cx					;Append extra data
							; to end of buffer
	inc	ax
	inc	ax					; add word for SIZE
	mov	ch, (mask HAF_LOCK) or (mask HAF_NO_ERR)
	call	MemReAlloc
	mov	es,ax
	mov	ax, id
	mov	es:[RPC_ID], ax

	mov	ax, si
	or	es:[RPC_flags], al			; get carry cond
	mov	di, (size RFSHeader) + (size RFSRegisters) ; skip hdrs
	mov	ax, bufferSize				;Store size of extra
	stosw						; data

	mov_tr	cx, ax
	pop	si					;DS:SI <- extra data
	call	strncpy
	segmov	ds,es,ax
	clr	si
	segmov	es,dgroup,ax
	tst	es:[closingConnection] 
	jnz	freeAndExit
	add	cx, firstBuffer				 ; total bufsize

	call	RFSendBufferWithRetries
	jc	closeConnection
freeAndExit:
	call	MemFree					; free message buffer
exit:
	.leave
	ret
closeConnection:
	call	MemFree

if 	DEBUGGING
	WARNING	RFSD_LOST_REMOTE_CONNECTION
endif
	call	CloseConnectionWithNotify
	jmp	exit
SendReplyRegsAndBufferInDSSI	endp

Server	ends
