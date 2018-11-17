COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		RFSD
FILE:		rfsdDispatchProcess.asm

AUTHOR:		In Sik Rhee, May  6, 1992

ROUTINES:
	Name			Description
	----			-----------
	SendDrivesRemote	send selected drives to client
	SendDriveCallBackRoutine callback for InitFileEnumStringSection
	GetRemoteDrive		get drive from remote server
	RFSHandOff		DR_FS_DISK_LOCK, DR_FS_DISK_UNLOCK, 
				DR_FS_DISK_FIND_FREE, DR_FS_CUR_PATH_GET_ID,
				DR_FS_COMPARE_FILES
	RFSDiskDriveNumber	DR_FS_DISK_ID, DR_FS_DRIVE_LOCK/UNLOCK
	RFSDiskInit		DR_FS_DISK_INIT
	RFSDiskInfo		DR_FS_DISK_INFO
	RFSDiskRename		DR_FS_DISK_RENAME
	RFSCurPathSet		DR_FS_CUR_PATH_SET
	RFSCurPathDelete	DR_FS_CUR_PATH_DELETE
	RFSCurPathCopy		DR_FS_CUR_PATH_COPY
	RFSHandleOp		DR_FS_HANDLE_OP
	RFSAllocOp		DR_FS_ALLOC_OP
	RFSPathOp		DR_FS_PATH_OP
	RFSFileEnum		DR_FS_FILE_ENUM
	RFSDFileEnumCallback	callback for DR_FS_FILE_ENUM
	ThreadDispatchCallback	stores/restores all variables (for callback)
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/ 6/92		Initial revision


DESCRIPTION:
	contains all functions pertaining to the dispatch process
		
	$Id: rfsdDispatchProcess.asm,v 1.1 97/04/18 11:46:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; process declarations

DispatchProcessClass	class	ProcessClass
MSG_RFSD_REQUEST_DRIVES_TIMEOUT		message
; This message is sent when the drive request has timed out.

MSG_RFSD_SEND_DRIVES_REMOTE		message
; Sends the exportable drives to the remote machine

MSG_RFSD_USE_REMOTE_DRIVES		message
; Adds drives sent from the remote machine to our system

MSG_RFSD_OPEN_CONNECTION		message
; Opens the connection to the remote machine

MSG_RFSD_CLOSE_CONNECTION		message
; Removes any drives added and closes the connection
;
; Pass:	cx - handle of queue to send ACK to when thread is destroyed

MSG_RFSD_CONNECTION_CLOSED		message
; This method is sent via the queue to clear out the "closingConnection"
; flag, to ensure that no stray remote FS requests are left around

MSG_RFSD_REMOTE_FILE_CHANGE_NOTIFICATION	message
; This method is sent from the remote machine with
; RFSDFileChangeNotificationData.

MSG_RFSD_REMOTE_DRIVE_CHANGE_NOTIFICATION	message
; This method is sent from the remote machine with
; RFSDDriveChangeNotificationData

MSG_RFSD_FLUSH_FILE_CHANGE_NOTIFICATIONS	message
; This method flushes any buffered FileChangeNotifications

MSG_RFSD_FLUSH_REMOTE_NOTIFICATIONS		message
; This method causes a MSG_RFSD_FLUSH_FILE_CHANGE_NOTIFICATIONS to be sent
; to the other side.
; Pass: bp - TimerID

MSG_RFS_HANDOFF				message
MSG_RFS_DISK_DRIVE_NUMBER		message
MSG_RFS_DISK_INIT			message
MSG_RFS_DISK_INFO			message
MSG_RFS_DISK_RENAME			message
MSG_RFS_CUR_PATH_SET			message
MSG_RFS_CUR_PATH_GET_ID			message
MSG_RFS_CUR_PATH_DELETE			message
MSG_RFS_CUR_PATH_COPY			message
MSG_RFS_FILE_ENUM			message

;	Only these three generate file change notifications

MSG_RFS_ALLOC_OP			message
MSG_RFS_HANDLE_OP			message
MSG_RFS_PATH_OP				message

FIRST_FS_MSG	equ	MSG_RFS_HANDOFF
LAST_FS_MSG	equ	MSG_RFS_PATH_OP
DispatchProcessClass	endc

idata	segment
	DispatchProcessClass
idata	ends

Server	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSHandOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_DISK_LOCK, DR_FS_DISK_UNLOCK, DR_FS_DISK_FIND_FREE,
		DR_FS_COMPARE_FILES (any op that we can just pass through)

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx 	= mem handle of buffer from remote machine
	In Buffer:
		bx	= disk handle
		ax,cx,dx = variable
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSHandOff	method dynamic DispatchProcessClass, 
					MSG_RFS_HANDOFF
	.enter
	call	GetRegsFromBuffer		; get ax,bx,cx,dx,di,si,bp
	tst	es:[closingConnection]
	jnz	exit
	push	di				; FSFunction
	push	bp				; save ID of caller
	push 	ax
	call	FSDLockInfoShared
	mov	es,ax
	mov	si,bx				; es:si - DiskDesc
	pop	ax
	cmp	di, DR_FS_DISK_LOCK		; disk lock/unlock requires
	je	diskLock			; kernel call
	cmp	di, DR_FS_DISK_UNLOCK
	je	diskUnlock
	call	CallFSDriverForDrive
reply:
	pop	di				; RPC_ID
	pop	bp				; FSFunction
	call	FSDUnlockInfoShared
	call	SendReplyPassRegisters
exit:
	.leave
	ret
diskLock:
	call	DiskLock
	jmp	reply
diskUnlock:
	call	DiskUnlock
	jmp	reply

RFSHandOff	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallFSDriverForDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the FS driver associated with the passed disk.

CALLED BY:	GLOBAL
PASS:		es:si - DiskDesc
RETURN:		nada
DESTROYED:	bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallFSDriverForDrive	proc	near
	.enter
EC <	push	ds							>
EC <	segmov	ds, es							>
EC <	call	ECCheckBounds						>
EC <	pop	ds							>

	mov	bp, es:[si].DD_drive		; es:bp - DriveStatusEntry
	mov	bp, es:[bp].DSE_fsd		; es:bp - FSDriver
EC <	call	ECCheckFSDriver			>
	call	es:[bp].FSD_strategy		; call it!
	.leave
	ret
CallFSDriverForDrive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSCurPathGetID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_DISK_LOCK, DR_FS_DISK_UNLOCK, DR_FS_DISK_FIND_FREE,
		DR_FS_COMPARE_FILES (any op that we can just pass through)

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx 	= mem handle of buffer from remote machine
	In Buffer:
		bx	= disk handle
		ax,cx,dx = variable
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSCurPathGetID	method dynamic DispatchProcessClass, 
					MSG_RFS_CUR_PATH_GET_ID
	.enter
	call	GetRegsFromBuffer		; get ax,bx,cx,dx,di,si,bp
				;BX <- disk handle
				;DX <- current path
	tst	es:[closingConnection]
	jnz	exit
	call	SetPathAsCurPath
	push	bp				;Save ID

	call	FSDLockInfoShared
	movdw	essi, axbx			;ES:SI <- DiskDesc

	call	CallFSDriverForDrive

	call	FSDUnlockInfoShared

	pop	di		;DI <- RPC_ID
	mov	bp, DR_FS_CUR_PATH_GET_ID
	call	SendReplyPassRegisters
exit:
	.leave
	ret

RFSCurPathGetID	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDiskDriveNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	perform DR_FS_DISK_ID, DR_FS_DRIVE_LOCK, DR_FS_DRIVE_UNLOCK

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx 	= mem handle of buffer from remote machine
	In Buffer:
		al 	- drive number

RETURN:		nothing
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDiskDriveNumber	method dynamic DispatchProcessClass, 
					MSG_RFS_DISK_DRIVE_NUMBER
	.enter
	call	FSDLockInfoShared
	mov	es, ax
	call	GetRegsFromBuffer		; get ax,bx,cx,dx,di,si,bp
	tst	ds:[closingConnection]
	jnz	exit
	push	di				; FSFunction
	push	bp				; ID of caller
	call	DriveLocateByNumber		; es:si DriveStatusEntry
EC <	ERROR_C	ERROR_RFSD_INVALID_DRIVE_NUMBER	>
	cmp	di, DR_FS_DISK_ID
	je	diskID
; we are dealing with DRIVE_LOCK and DRIVE_UNLOCK here
	pop	bp				; restore stack pointer
	pop	bp
	cmp	di, DR_FS_DRIVE_UNLOCK
	je	driveUnlock
	
	;
	; The DriveLockExcl and DriveUnlockExcl have been commented
	; because there would be deadlock when the drive is locked
	; and the connection is broken.
	;
	; If they are enabled, RFSDiskInit must be modified to prevent
	; calling DriveLockExcl and DriveUnlockExcl. Otherwise, there
	; would be deadlock. (See comments there)
	;					-simon 11/23/94
;	call	DriveLockExcl
;EC<	ERROR_C	RFSD_DRIVE_LOCK_FAILED	>
	jmp	exit
driveUnlock:
;	call	DriveUnlockExcl
	jmp	exit
diskID:
	mov	bp, es:[si].DSE_fsd		; fsd descriptor
EC <	call	ECCheckFSDriver			>
	call	es:[bp].FSD_strategy		; call it!
	pop	di				; caller ID
	pop	bp				; FSFunction
	call	SendReplyPassRegisters
exit:
	call	FSDUnlockInfoShared
	.leave
	ret
RFSDiskDriveNumber	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDiskInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_DISK_INIT

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx 	- mem handle of buffer
	In Buffer:
		bl 	- drive number
		cx:dx	- 32-bit disk ID
		al	- DiskFlags
		ah	- MediaType
		bh	- FSDNamelessAction
RETURN:		nothing
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDiskInit	method dynamic DispatchProcessClass, 
					MSG_RFS_DISK_INIT
	.enter
	call	FSDLockInfoShared
	mov	es, ax
	call	GetRegsFromBuffer		; get ax,bx,cx,dx,di,si,bp
	tst	ds:[closingConnection]
	jnz	exit
	push	bp				; save ID of caller
	push	ax
	mov	al, bl
	call	DriveLocateByNumber		; es:si DriveStatusEntry
EC< 	ERROR_C	ERROR_RFSD_INVALID_DRIVE_NUMBER	>
	pop	ax	
	jc	error
	mov	bp, es:[si].DSE_fsd		; fsd descriptor
	segmov	ds, es				; ds:si DriveStatusEntry
	push	bx				; save drive#
	mov	bx, offset FIH_diskList - offset DD_next
diskLoop:
	mov	bx, ds:[bx].DD_next
	tst	bx
	jz	notFound
	cmp	ds:[bx].DD_id.low, dx		; low ID word matches?
	jne	diskLoop			; nope
	cmp	ds:[bx].DD_id.high, cx		; high ID word matches?
	jne	diskLoop			; nope
	cmp	ds:[bx].DD_drive, si		; same drive?
	jne	diskLoop			; nope
; found the disk, we dont need to call DiskAllocAndInit [bx-handle]
	pop	di				; di <- drive #

	pop	bp				; bp <- RPC ID

	push	bp				; RPC_ID
	push	ax				; save ax
	mov_tr	ax, di				; al <- drive #

	;
	; Here we lock drive before getting the information of the
	; disk. It is because it is possible that the disk is being updated
	; (like being formatted) and we want to get the info after the
	; operation is done. Locking the drive can allow us to wait
	; until the current operation is done.
	;
	; This drive lock/unlock mechanism is implemented to cooperate
	; with HandleIfNotOurDrive.
	;
	; *CAUTION*
	;
	; This locking mechanism can be put here because the
	; DR_FS_DRIVE_LOCK and DR_FS_DRIVE_UNLOCK handler on RFSD
	; server (See RFSDriveNumber) is bogus (not performing real
	; locking/unlocking). Otherwise, it can happen that here it
	; tries to lock the drive locked by previous DR_FS_DRIVE_LOCK
	; handler. This would create deadlock this is the only thread
	; that unlock the drive upon receiving DR_FS_DRIVE_UNLOCK. 
	;
	;					-simon 11/23/94
	;
	call	DriveLockExcl			; carry set if si
						; destroyed
	jc	cannotLockDrive			; can't lock drive, exit
EC <	ERROR_C RFSD_DRIVE_LOCK_FAILED					>
	pop	di				; di <- restored ax
	push	ax				; save drive #
	push	bp				; RPC_ID passed on stack
	mov	si,bx				; ds:si - DiskDesc
	add	si, offset DD_volumeLabel	; ds:si - volume label
	mov	di, VOLUME_NAME_LENGTH
	mov	bp, DR_FS_DISK_INIT
	clc
	call	SendReplyRegsAndBufferInDSSI
	pop	ax				; restore drive #
	call	DriveUnlockExcl			; nothing destroyed
	pop 	di				; clean up RPC_ID on stack
	jmp	exit

cannotLockDrive:
	pop	ax				; restore ax
	jmp	error

notFound:
	pop	bx
	push	ax
	mov	al, bl
	call	DriveLockExcl
EC<	ERROR_C	RFSD_DRIVE_LOCK_FAILED	>
	pop	ax
	mov	bh, FNA_SILENT
	call	DiskAllocAndInit		; Unlocks the drive
EC<	ERROR_C	RFSD_DISK_INIT_FAILED	>
	jc	error
	mov	al, ds:[si].DSE_number
;	call	DriveLockExcl
;EC<	ERROR_C	RFSD_DRIVE_LOCK_FAILED	> 

	;
	; Get volume label name
	;
	mov	si,bx				; ds:si - DiskDesc
	add	si, offset DD_volumeLabel	; ds:si - volume label
	mov	di, VOLUME_NAME_LENGTH
	mov	bp, DR_FS_DISK_INIT
	clc					; RPC_ID passed on stack
	call	SendReplyRegsAndBufferInDSSI
	
exit:
	call	FSDUnlockInfoShared
	.leave
	ret

error:  mov	bp,DR_FS_DISK_INIT 		
	pop	di
	stc
	call	SendReplyPassRegisters
	jmp	exit
RFSDiskInit	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDiskInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_DISK_INFO

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= mem handle of buffer
	In Buffer:
		bx	= disk handle
RETURN:		nothing
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDiskInfo	method dynamic DispatchProcessClass, 
					MSG_RFS_DISK_INFO
	.enter
	mov	bx, cx
	tst	es:[closingConnection]
	jnz	exit

	call	FSDLockInfoShared
	mov	es,ax
	call	GetRegsFromBuffer		; get ax,bx,cx,dx,di,si,bp
	push	bp				; save ID of caller
	mov	si,bx				; es:si - DiskDesc

	mov	ax, size DiskInfoStruct
	mov	cx, (mask HF_SWAPABLE) or (((mask HAF_LOCK) or \
			(mask HAF_NO_ERR)) shl 8)
	call	RFSDMemAlloc
	push	bx				; save mem handle
	mov	bx,ax
	clr	cx				; bx:cx - fptr.DiskInfoStruct
	call	CallFSDriverForDrive
EC <	ERROR_C	RFSD_DISK_INFO_FAILED		>
	call	FSDUnlockInfoShared
	pop	bp				; mem handle
	pop	di				; RPC_ID

	push	bp				; Save mem handle

	push	di				;Pass ID on stack to routine
	mov	bp, DR_FS_DISK_INFO
	mov	ds,bx				;DS:SI <- data to send
	clr	si
	mov	di, size DiskInfoStruct
	clc
	call	SendReplyRegsAndBufferInDSSI
	pop	bx
exit:
	call	MemFree
	.leave
	ret
RFSDiskInfo	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDiskRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_DISK_RENAME

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= mem handle of buffer
	In Buffer:
		string containing disk name
		bx	= disk handle
RETURN:		nothing	
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDiskRename	method dynamic DispatchProcessClass, 
					MSG_RFS_DISK_RENAME
	.enter
	mov	bx,cx
	tst	es:[closingConnection]
	jnz	free
	call	MemLock
	push	bx
	mov	ds,ax
	push	ds:[RPC_ID]			; caller ID
	call	FSDLockInfoExcl
	mov	es, ax			
	mov	si, ds:[RPC_regs].RFSR_bx	; es:si - DiskDesc
	mov	dx, firstBuffer			; ds:dx - name
	mov	di, DR_FS_DISK_RENAME
	call	CallFSDriverForDrive
	mov	bp, DR_FS_DISK_RENAME
EC< 	ERROR_C	RFSD_DISK_RENAME_FAILED	>
	jc	error
; successful name change, so we return the new volume label to the client
; (incase there was an uppercase conversion)
	segmov	ds,es,di		
	add	si, offset DD_volumeLabel	; ds:si - volume name
	mov	di, VOLUME_NAME_LENGTH
	call	SendReplyRegsAndBufferInDSSI
exit:
	pop	bx
	call	FSDUnlockInfoExcl
free:
	call	MemFree
	.leave
	ret
error:
	pop	di				; RPC_ID
	call	SendReplyPassRegisters
	jmp	exit
RFSDiskRename	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPathAsCurPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes the passed path handle the current path

CALLED BY:	GLOBAL
PASS:		dx - current path
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPathAsCurPath	proc	near	uses	bx
	.enter
EC <	call	ECCheckValidPath					>
	mov	bx, ss:[TPD_curPath]
	cmp	bx, dx
	jz	exit

	push	ax, ds, es
top:
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[FP_prev]
EC <	tst	ax							>
EC <	ERROR_Z	INVALID_PATH_HANDLE					>
	cmp	ax, dx
	jz	found
	call	MemUnlock
	mov_tr	bx, ax			;BX <- next path in list
	jmp	top
found:

;	We've found the path in the list of current paths:
;
;	DX - path we want to move to the top of the linked list
;	BX - path preceding our path in the linked list
;

	push	bx
	mov	bx, dx
	call	MemLock
	mov	es, ax			;ES:0 - path we want to move to the top
					;DS:0 - path linked to path in ES:0

	mov	ax, ss:[TPD_curPath]	;Move this path to the front of the 
	xchg	ax, es:[FP_prev]	; list
	mov	ds:[FP_prev], ax

	call	MemUnlock
	pop	bx
	call	MemUnlock
	mov	ss:[TPD_curPath], dx
EC <	call	ECCheckValidPath					>
	pop	ax, ds, es
exit:
	.leave
	ret
SetPathAsCurPath	endp

if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckValidPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure that the current path is valid.

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
ECCheckValidPath	proc	near	uses	bx, ds, ax
	.enter
	mov	bx, ss:[TPD_curPath]
loopTop:
	tst	bx
	jz	exit
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[FP_prev]
	call	MemUnlock
	mov	bx, ax
	jmp	loopTop

exit:
	.leave
	ret
ECCheckValidPath	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskLockCallFSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the FSD associated with the passed disk handle after
		ensuring the disk is in the drive.

CALLED BY:	EXTERNAL
PASS:		si	= disk handle
		di	= FSFunction
		es	= locked FSInfoResource
		al	= FILE_NO_ERRORS bit set if disk lock may not be
			  aborted.
RETURN:		carry set if lock aborted,
			ax	= ERROR_DISK_UNAVAILABLE
		else whatever the FSD returns.
DESTROYED:	bp, si, di (at least)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiskLockCallFSD proc	near
		.enter
		push	si		; save disk handle for drive unlock

		tst	si		; 0 disk handle => no lock, just
		jz	usePrimary	;  call primary FSD


		call	DiskLock
		jc	bailOut
	;
	; Now call the intended function.
	; 
		call	es:[bp].FSD_strategy

	;
	; Unlock the disk.
	; 
		pop	si
		call	DiskUnlock
		
done:
		.leave
		ret

bailOut:
	;
	; (The silly) User aborted the lock, so return an error
	; to our caller. Carry is already set.
	; 
		pop	si
		mov	ax, ERROR_DISK_UNAVAILABLE
		jmp	done

usePrimary:
		mov	bp, es:[FIH_primaryFSD]
		call	es:[bp].FSD_strategy
		pop	si
		jmp	done
DiskLockCallFSD endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetLinkDataCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to deref the block of link data and
		restore the disk, if any

CALLED BY:	FileGetLinkData, FileReadLink

PASS:		^hbx - FSPathLinkData

RETURN:		bx - disk handle, or zero if none
		ds:dx - target path returned from DOS driver

DESTROYED:	ax,cx,si,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetLinkDataCommon	proc far
		.enter
	;
	; Dereference the block of link data (since the FSD was
	; supposed to leave it locked), and fetch the pathname
	;

		call	MemDerefDS
		lds	dx, ds:[FPLD_targetPath]

	;
	; If there's a saved disk, then restore it
	;
		clr	bx
		tst	ds:[FPLD_targetSavedDiskSize]
		jz	done
	;
	; Restore the saved disk handle
	;
		mov	si, offset FPLD_targetSavedDisk
		clr	cx
		call	DiskRestore
		mov_tr	bx, ax
		jc	mapError

done:
		.leave
		ret

mapError:
	;
	; Map the DiskRestoreError into a FileError
	; 
		mov	ax, ERROR_NETWORK_NOT_LOGGED_IN
		cmp	bx, DRE_NOT_ATTACHED_TO_SERVER
		je	haveCode
		mov	ax, ERROR_ACCESS_DENIED
		cmp	bx, DRE_PERMISSION_DENIED
		je	haveCode
		mov	ax, ERROR_DISK_UNAVAILABLE
haveCode:
		stc
		jmp	done
FileGetLinkDataCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileGetLinkData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the link data as returned by the FSD 

CALLED BY:	FileOpOnPathLow, SetCurPath

PASS:		bx - handle of (locked) FSPathLinkData block

RETURN:		if error
			ax - FileError
			bx - destroyed
		else
			ds:dx - path of link's target
			bx    - disk handle of target

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	The CALLER must free the memory block in BX after the data at
	ds:dx is no longer needed.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileGetLinkData	proc near
		uses	es, si, cx

		.enter

	;
	; Deref the block, and restore the disk, if any
	;

		call	FileGetLinkDataCommon
		jc	done
		tst	bx
		jnz	done

	;
	; There was no saved disk, so use  FileGetDestinationDisk
	; to get a disk handle from the path
	;

		call	FileGetDestinationDisk

done:
		.leave
		ret

FileGetLinkData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurrentPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does what FileSetCurrentPath does, w/o the standard path shme.

CALLED BY:	GLOBAL
PASS:		ds:dx - absolute path
		bx - disk handle
RETURN: 	bx -  disk handle
		carry set if error
		ax = error

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/11/93   	Stolen from SetCurPath

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCurrentPath	proc	near	uses	cx, dx, bp, si, di, es
	.enter
	;
	; Lock the FSIR for DiskLockCallFSD to use.
	; 
	call	FSDLockInfoShared
	mov	es, ax

	push	bp
	mov	si, bx			; disk handle
	mov	di, DR_FS_CUR_PATH_SET
	clr	al			; allow lock aborts
	call	DiskLockCallFSD
	pop	bp
	call	FSDUnlockInfoShared
	jnc	storeActual

	cmp	ax, ERROR_LINK_ENCOUNTERED
	stc
	jne	done

	;
	; A link was encountered, so follow it, and try again.
	; bx = mem handle of link data
	;

	push	ds, dx, cx
	push	bx

	;
	; Fetch the link data and then set the new returned path,
	; unless we can't
	;

	call	FileGetLinkData
	jc	afterSet

	call	SetCurrentPath
	mov	cx, bx		; returned disk handle
afterSet:
	pop	bx
	pushf
	call	MemFree
	popf

	mov	bx, cx		; returned disk handle
	pop	ds, dx, cx
		

	;
	; bx - disk handle returned from called routine
	;

	jc	done

storeActual:
	;
	; We know that we've finally set a REAL directory.  Store the
	; ACTUAL disk in the otherInfo field, to be used when calling
	; the FS driver.  The logical disk is whatever the caller
	; wants it to be...
	;
	;	bx = actual disk handle

	mov_tr	ax, bx			; actual disk handle
	push	ax
	mov	bx, ss:[TPD_curPath]
	call	MemModifyOtherInfo
	pop	bx


	;
	; Figure out the length of the path tail
	;
	push	bx, cx
	mov	bp, bx		; bp <- disk handle for setting
				;  FP_logicalDisk
	mov	si, dx		;DS:SI <- ptr to path
	call	strlen		;CX <- size of user-specified path (+ null)

	;
	; Reallocate the path block to fit.
	;
		
	mov	bx, ss:[TPD_curPath]
	call	MemLock
	mov	es, ax

	push	cx		; size of path
	add	cx, es:[FP_path]
	mov_tr	ax, cx
	clr	ch
	call	MemReAlloc
	pop	cx
	jnc	copyIt
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jmp	unlock
	;
	; copy the path data in
	;
copyIt:
	mov	es, ax
	mov	di, es:[FP_path]
	call	strncpy

	;
	; Set the logical disk handle as well
	;
	mov	es:[FP_logicalDisk], bp
	clc
unlock:
	call	MemUnlock
	pop	bx, cx
		
done:
	.leave
	ret
SetCurrentPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleLinkError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want all links to look like regular files/paths to the
		client, so we map link errors to other more innocuous errors,
		that don't make the client machine try to follow the link.

CALLED BY:	GLOBAL
PASS:		carry set:
			ax - error code
			if ax=ERROR_LINK_ENCOUNTERED
				bx = handle of locked FSPathLinkData block
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleLinkError	proc	near
	.enter
PrintMessage <Some operations on links are not currently supported>
	jnc	exit			;Exit if no error
	cmp	ax, ERROR_TOO_MANY_LINKS
	je	linkError
	cmp	ax, ERROR_LINK_ENCOUNTERED
	jne	haveError
	call	MemFree			;Free up FSPathLinkData
if	DEBUGGING
	WARNING	ENCOUNTERED_LINK_ERROR
endif
linkError:
	mov	ax, ERROR_PATH_NOT_FOUND
haveError:
	stc
exit:
	.leave
	ret
HandleLinkError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSCurPathSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_CUR_PATH_SET

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= mem handle of buffer
	In Buffer:
		string containing path name
		bx	= disk handle
RETURN:		nothing
	To Remote:
		bx	- FilePath handle 
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/27/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSCurPathSet	method dynamic DispatchProcessClass, 
					MSG_RFS_CUR_PATH_SET
	.enter
EC <	call	ECCheckValidPath					>
	push	cx
	tst	es:[closingConnection]
	jnz	exit
	mov	bx,cx
	call	MemLock
	mov	ds,ax
	mov	di,ds:[RPC_ID]		; caller ID
	mov	bx, ds:[RPC_regs].RFSR_bx	; get disk handle

	call	CopyCurrentPath		;DX <- new path handle
	call	SetPathAsCurPath
	push	dx			;Save handle of current path

	mov	dx, firstBuffer		; ds:dx - path

;	We don't call FileSetCurrentPath here, as we don't want to deal with
;	standard paths.

	call	SetCurrentPath
	jc	error
	pop	bx			;BX <- handle of current path

sendReply:

	mov	bp, DR_FS_CUR_PATH_SET
	call	SendReplyPassRegisters	; send BX - handle of FilePath

exit:
	pop	bx
	call	MemFree			; free our input buffer
EC <	call	ECCheckValidPath					>
	.leave
	ret
error:
	call	HandleLinkError
	call	FilePopDir		;If the SetCurrentPath failed, then
					; there's no need to keep around this
					; dir
	pop	bx			;Clean up stack
	mov	bx, -1
	jmp	sendReply
RFSCurPathSet	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSCurPathDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_CUR_PATH_DELETE

CALLED BY:	RFSDD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= mem handle of buffer
	In Buffer:
		dx	= path handle
		bx	= disk handle
RETURN:		nothing
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSCurPathDelete	method dynamic DispatchProcessClass, 
					MSG_RFS_CUR_PATH_DELETE
	.enter
EC <	call	ECCheckValidPath					>
	mov	bx, cx
	call	GetRegsFromBuffer		; get ax,bx,cx,dx,di,si,bp
		;BX <- Disk handle
		;DX <- path handle

	call	SetPathAsCurPath
	call	FilePopDir
EC <	call	ECCheckValidPath					>
	.leave
	ret
RFSCurPathDelete	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSCurPathCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_CUR_PATH_COPY

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= mem handle of buffer
	In Buffer:
		dx	= path handle 

RETURN:		To Client:
		cx	= new path handle
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSCurPathCopy		method dynamic DispatchProcessClass, 
					MSG_RFS_CUR_PATH_COPY
	.enter
	call	GetRegsFromBuffer		; get ax,bx,cx,dx,di,si,bp
			;DX <- our path handle
	tst	es:[closingConnection]
	jnz	exit
	call	SetPathAsCurPath

EC <	push	dx							>
	call	CopyCurrentPath			;Returns new handle in DX
	mov	cx, dx
EC <	pop	dx							>
EC <	cmp	cx, dx							>
EC <	ERROR_Z	RFSD_INTERNAL_ERROR					>

	xchg	di,bp				; ID, FSFunction
	clc	
	call	SendReplyPassRegisters
exit:
	.leave
	ret
RFSCurPathCopy		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCurrentPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a copy of the current path, using FilePushDir

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		dx - handle of new FilePath 
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyCurrentPath	proc	near	uses	ax, bx, ds
	.enter
	call	FilePushDir			;Copies the path handle

;	FilePushDir puts the new Path handle *after* the first handle in
;	the path list.

	mov	bx, ss:[TPD_curPath]		; get path handle
	call	MemLock
	mov	ds, ax
	mov	dx, ds:[FP_prev]
	call	MemUnlock

	.leave
	ret
CopyCurrentPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSHandleOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_HANDLE_OP

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= mem handle of buffer
	In Buffer:
		si	= disk handle
		ah	= FSHandleOpFunction to perform.
		bx	= file handle
		(optional) buffer embedded
RETURN:		nothing
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSHandleOp	method dynamic DispatchProcessClass, 
					MSG_RFS_HANDLE_OP
	.enter
	push	cx
	tst	es:[closingConnection]
	LONG jnz	free
	call	FileBatchChangeNotifications
	mov	bx,cx
	call	MemLock
	mov	ds,ax
	push	ds:[RPC_ID]			; save ID of caller
	call	FSDLockInfoShared		
	mov	es,ax				
	mov	ax, ds:[RPC_regs].RFSR_ax		
	mov	bx, ds:[RPC_regs].RFSR_bx	; file handle
	mov	cx, ds:[RPC_regs].RFSR_cx
	mov	dx, ds:[RPC_regs].RFSR_dx
	mov	si, ds:[RPC_regs].RFSR_si	; es:si - DiskDesc
	mov	bp, es:[si].DD_drive		; es:bp - DriveStatusEntry
	mov	bp, es:[bp].DSE_fsd		; es:bp - FSDriver
EC <	call	ECCheckFSDriver						>
	push	ax
	mov	al,ah
	clr	ah
	shl	ax
	mov	di,ax
	pop	ax
	jmp	cs:[SHandleOpJmpTable][di]
SHandleOpJmpTable	nptr	\
	read,
	write,
	callit,
	callit,
	callit,
	lockFile,
	lockFile,
	callit,			;GET_DATE_TIME
	callit,			;SET_DATE_TIME
	callit,
	callit,
	callit,
	close,
	callit,
	checkNative,			;CHECK_NATIVE
	getExtAttr,
	setExtAttr,
	getAllAttr,
	callit,
	callit
CheckHack <length SHandleOpJmpTable eq FSHandleOpFunction>

checkNative:
EC <	call	ECCheckFSDriver			>
	mov	di, DR_FS_HANDLE_OP
	call	es:[bp].FSD_strategy		; call it!

;	FSHOF_CHECK_NATIVE returns the carry - so return the carry value in CX

	mov	cx, 0			;CX = 0 if carry clear
	jnc	reply
	mov	cx, -1
	clc
	jmp	reply

callit:
EC <	call	ECCheckFSDriver			>
	mov	di, DR_FS_HANDLE_OP
	call	es:[bp].FSD_strategy		; call it!
reply:
	pop	di				; RPC_ID
	mov	bp, DR_FS_HANDLE_OP
if	DEBUGGING
	WARNING_C	RF_HANDLE_OP_REMOTE_CARRY
endif
	call	SendReplyPassRegisters
exit:
	call	FSDUnlockInfoShared
free:
	pop	bx
	call	MemFree				; free input buffer
	.leave
	ret
read:
if	DEBUGGING
	WARNING	RF_HANDLE_OP_REMOTE_READ
endif
	mov	ax,cx				; size to read
	push	bx				; file handle
	mov	di,cx
	mov	cx, ((mask HAF_LOCK) or (mask HAF_NO_ERR)) shl 8
	call	RFSDMemAlloc
	mov	ds,ax
	mov	cx,di	
	pop	ax
	push	bx				; save mem handle
	mov	bx, ax				; file handle
	mov	ah, FSHOF_READ
	clr	dx				; ds:dx - read buffer
EC <	call	ECCheckFSDriver			>
	mov	di, DR_FS_HANDLE_OP
	call	es:[bp].FSD_strategy		; call it!
	call	HandleLinkError
EC <	ERROR_C	RFSD_READ_FAILED		>
	mov	di,ax				; bytes read
	pop	bx
replyBuffer:
	mov	si,0	; ds:si - buffer (don't change to CLR)
	pop	bp				; RPC_ID

	push	bx				; save mem handle
	push	bp				;Pass RPC_ID on stack
	mov	bp, DR_FS_HANDLE_OP
	call	SendReplyRegsAndBufferInDSSI
	pop	bx

	call	MemFree
	jmp	exit
write:
if	DEBUGGING
	WARNING	RF_HANDLE_OP_REMOTE_WRITE
endif
	mov	dx, firstBuffer 		; ds:dx buffer
	jmp	callit
lockFile:	
	sub	sp, size FSHLockUnlockFrame	
	mov	si, sp
	push	es
	segmov	es,ss,di
	mov	di,si				; es:di dest
	mov	cx, size FSHLockUnlockFrame	; size
	mov	si, firstBuffer			; ds:di src
	call	strncpy
	mov	cx,di				; ss:cx - FSHLockUnlockFrame
	pop	es
EC <	call	ECCheckFSDriver			>
	mov	di, DR_FS_HANDLE_OP
	call	es:[bp].FSD_strategy		; call it!
	add	sp, size FSHLockUnlockFrame	; restore stack
	jmp	reply
close:
	mov	ax, bx				;AX <- handle of file
	call	RemoveFromFileList
	clr	al
	call	FileClose			; let Kernel take care of it
	jmp	reply
getExtAttr:
; buffer - array of FileExtAttrDesc
; cx - # of entries
	sub	sp, size FSHandleExtAttrData	
	mov	di, sp
	mov	dx, sp				; ss:sp - FSHandleExtAttrData
	mov	ss:[di].FHEAD_attr, FEA_MULTIPLE
	mov	ss:[di].FHEAD_buffer.segment, ds
	mov	ss:[di].FHEAD_buffer.offset, firstBuffer
; we're almost ready, but first we have to prepare a reply buffer
; so first, "run-through" the array and compute required space.
	clr	ax
	push	cx
	mov	di, firstBuffer			; ds:di - start of array
getSp:



	mov	ds:[di].FEAD_value.offset, ax 	; offset of where to copy data
	add	ax, ds:[di].FEAD_size		; size of return buffer
	add	di, size FileExtAttrDesc	; next attr 
	loop	getSp
	mov	cx, ((mask HAF_LOCK) or (mask HAF_NO_ERR)) shl 8
	push	ax			
	push	bx				; file handle
	call	RFSDMemAlloc
	mov	di,bx
	pop	bx				; file handle
	pop	si				; size of return buffer
	pop	cx				; # of entries
	push	di				; mem handle
	push	si
	push	cx
	mov	di, firstBuffer			; ds:di - array
setVp:	mov	ds:[di].FEAD_value.segment, ax	; segment of where to copy data
	add	di, size FileExtAttrDesc	; next attr 
	loop	setVp
	pop	cx
	mov	di, DR_FS_HANDLE_OP
	mov	ah, FSHOF_GET_EXT_ATTRIBUTES
EC <	call	ECCheckFSDriver			>
	call	es:[bp].FSD_strategy		; call it!
	call	HandleLinkError
; now our reply buffer is filled....  soooooo return it!

	pop	di				; size of buffer
	pop	bx
	call	MemDerefDS

;	Restore stack w/o trashing registers

	mov	bp, sp
	lea	bp, ss:[bp + size FSHandleExtAttrData]
	mov	sp, bp
	jc	getExtError
	clr	ax
getExtNoErr:
EC <	ERROR_C		-1						>
	jmp	replyBuffer		;If no error, reply

getExtError:
;
;	In general, if an operation returns an error, we return the carry
;	set and do not return a buffer of data. In the case where we
;	have an error because of an unsupported attribute, we want to
;	return the buffer of supported attributes, so we clear the carry.
;
;	We'll detect this case in RFHandleOp(), and set the carry before
;	returning.
;

	cmp	ax, ERROR_ATTR_NOT_SUPPORTED
	je	getExtNoErr		;Clears the carry
	cmp	ax, ERROR_ATTR_NOT_FOUND
	je	getExtNoErr		;Clears the carry
	stc
	jmp	reply
setExtAttr:
	sub	sp, size FSHandleExtAttrData	
	mov	si, sp
	mov	dx, sp				; ss:dx - FSHandleExtAttrData
	mov	ss:[si].FHEAD_attr, FEA_MULTIPLE
	mov	ss:[si].FHEAD_buffer.segment, ds
	mov	ss:[si].FHEAD_buffer.offset, firstBuffer
	push	si
	mov	si, firstBuffer			; ds:si - FECD's
	mov	di,cx
; loop through and set the segment:offset pointers
setPt:
	mov	ds:[si].FEAD_value.segment, ds
	add	ds:[si].FEAD_value.offset, firstBuffer
	add	si, size FileExtAttrDesc
	loop	setPt
	mov_tr	cx,di
	pop	si				; es:si - diskdesc
EC <	call	ECCheckFSDriver			>
	mov	di, DR_FS_HANDLE_OP
	call	es:[bp].FSD_strategy		; call it!
EC <	ERROR_C	RFSD_HANDLE_SET_EXT_FAILED	>
	add	sp, size FSHandleExtAttrData	; restore stack
	jmp	reply	
getAllAttr:
EC <	call	ECCheckFSDriver			>
	mov	di, DR_FS_HANDLE_OP
	call	es:[bp].FSD_strategy
	call	HandleLinkError
EC <	ERROR_C	RFSD_HANDLE_OP_FAILED		>
	pushf
	mov	bx, ax
	call	MemDerefDS
	mov	ax, MGIT_SIZE
	call	MemGetInfo			; ax - size 
	mov	di, ax
	popf
	jmp	replyBuffer

RFSHandleOp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddToFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the passed file to the file list

CALLED BY:	GLOBAL
PASS:		ax - file handle to add
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddToFileList	proc	near	uses	bx, si, di, ds
	.enter
	call	LockFileList
	call	ChunkArrayAppend
	mov	ds:[di], ax
	call	MemUnlock
	.leave
	ret
AddToFileList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveFromFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the passed file from the file list

CALLED BY:	GLOBAL
PASS:		ax - file handle to add
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveFromFileList	proc	near	uses	ds, bx, di, si
	.enter
	call	LockFileList
	push	bx
	mov	bx, cs
	mov	di, offset RemoveFileFromListCallback
	call	ChunkArrayEnum
EC <	ERROR_NC	RFSD_FILE_NOT_IN_OPEN_FILE_LIST			>
	pop	bx
	call	MemUnlock
	.leave
	ret
RemoveFromFileList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveFileFromListCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a file from the file list

CALLED BY:	GLOBAL
PASS:		ax - handle of file to remove
RETURN:		carry set if current file matches file we are searching for
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveFileFromListCallback	proc	far
	.enter
	cmp	ax, ds:[di]
	clc
	jnz	exit
	call	ChunkArrayDelete
	stc
exit:
	.leave
	ret
RemoveFileFromListCallback	endp

if	0	;Used for link support

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushToRoot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push to the root directory of the given volume. Just does
		a FilePushDir if the passed handle is 0

CALLED BY:	FileCopy, FileMove
PASS:		cx	= handle of disk volume to which to push
RETURN:		carry set if can't change to root:
			ax = error code
		carry clear if change successful:
			original working directory saved on directory stack.
			ax = destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/10/90		Initial version
	CDB	8/27/92		Stolen from kernel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
rootDir		char	'\\', 0
PushToRoot	proc	near	uses ds, dx
		.enter
	;
	; Push a directory so we don't mangle the thread's current dir
	;
		call	FilePushDir
		clc
		jcxz	exit
	;
	; Now call FileSetCurrentPath to go to the root of the passed volume.
	;
		segmov	ds, cs
		mov	dx, offset rootDir
		xchg	bx, cx
		call	FileSetCurrentPath
		jnc	done
	;
	; Yrg. Root doesn't exist. Pop the pushed directory and return carry
	; set (ax untouched).
	;
		call	FilePopDir
		stc
done:
		xchg	bx, cx
exit:
		.leave
		ret
PushToRoot	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSAllocOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_ALLOC_OP

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= mem handle of buffer
	In Buffer:
		buffer containing path string
		al	= FullFileAccessFlags
		ah	= FSAllocOpFunction to perform.
		bx	= disk handle
		dx 	= path handle
FSAOF_CREATE -	cl	= FileAttrs
		ch	= FileCreateFlags
RETURN:		nothing
DESTROYED:	variable

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSAllocOp	method dynamic DispatchProcessClass, 
					MSG_RFS_ALLOC_OP

EC <	call	ECCheckValidPath				>
   	tst	es:[closingConnection]
	LONG jnz	free
	call	FileBatchChangeNotifications
	call	FSDLockInfoShared
	mov	es,ax
	mov	bx,cx
	call	MemLock
	push	bx			; (2)
	mov	ds,ax
	push	ds:[RPC_ID]		; caller ID	(3)
	mov	dx, ds:[RPC_regs].RFSR_dx
	call	SetPathAsCurPath
	mov	ax, ds:[RPC_regs].RFSR_ax	; ax argument
	mov	cx, ds:[RPC_regs].RFSR_cx	; get CX 
	mov	si, ds:[RPC_regs].RFSR_bx	; es:si - DiskDesc
	mov	dx, firstBuffer		; ds:dx - path
	push	ax			; (4)
	call	DoAllocOpCall
	pop	di			; di.high <- FSAOF_*
					;  di.low <- FullFileAccessFlags
	jc	error
	push	ax			; (4)
	call	FSDAllocFileHandle

	push	bx
	mov_tr	bx, ax
	mov	ax, handle 0
	call	HandleModifyOwner
	mov_tr	ax, bx
	pop	bx

	call	AddToFileList
	mov	dx,ax			;Return the remote file handle in DX
	pop	ax			; (4)
	clc
reply:
	pop	di			; RPC_ID	(3)
	mov	bp, DR_FS_ALLOC_OP
	call	SendReplyPassRegisters	; send AX - file handle
	pop	bx			; (2)
	call	MemFree			; free our input buffer
	call	FSDUnlockInfoShared	
EC <	call	ECCheckValidPath				>
	ret
error:
	call	HandleLinkError
	jmp	reply

DoAllocOpCall:
	mov	di, DR_FS_ALLOC_OP
	call	CallFSDriverForDrive
;
;	This doesn't really work, as it gets fouled up trying to deal
;	with standard paths (trying to copy a linked file out of the
;	server's WORLD directory). So we just give an error instead.
;	To support links, the code in FileOpOnPathLow would need to be
;	copied out here.
;
if 0
;;;	jnc	noErr
;;;	cmp	ax, ERROR_LINK_ENCOUNTERED
;;;	je	followLink
;;;	stc
;;;noErr:
;;;
;;;	retn
;;;followLink:
;;;
;;;;	Stolen from FileOpOnPathLow
;;;
;;;	;
;;;	; A link was encountered, so follow it, and try again.
;;;	;
;;;		push	ds, dx, bx		; mem handle of link data
;;;		call	FileGetLinkData
;;;		jc	afterFollowLink
;;;
;;;	; bx - disk handle of target,
;;;	; ds:dx - path to target.
;;;
;;;		push	cx
;;;		mov	cx, bx
;;;		call	PushToRoot
;;;		pop	cx
;;;		jc	afterFollowLink
;;;
;;;	;
;;;	; Now, try again with the new path.  Restore the path when done.
;;;	;
;;;
;;;		mov	bx, -1
;;;		call	FileGetDestinationDisk
;;;		mov	bx, sp
;;;		mov	bx, ss:[bx+6]		; bx <- as originally passed
;;;		call	DoAllocOpCall
;;;
;;;		call	FilePopDir
;;;
;;;afterFollowLink:
;;;
;;;		pop	ds, dx, bx
;;;		pushf
;;;		call	MemFree
;;;		popf
endif
		retn
free:
		mov	bx, cx
		GOTO	MemFree
RFSAllocOp	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSPathOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_PATH_OP

CALLED BY:	RFSD
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
	In Buffer:
		string containing path name
		si	= disk handle
		dx	= path handle
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/12/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSPathOp	method dynamic DispatchProcessClass, 
					MSG_RFS_PATH_OP

	.enter
EC <	call	ECCheckValidPath					>
	push	cx
	tst	es:[closingConnection]
	LONG jnz	free
	call	FileBatchChangeNotifications
	mov	bx,cx
	call	MemLock
	mov	ds,ax
	push	ds:[RPC_ID]			; save ID of caller
	call	FSDLockInfoShared		
	mov	es,ax				
	mov	bx, ds:[RPC_regs].RFSR_bx
	mov	cx, ds:[RPC_regs].RFSR_cx
	mov	dx, ds:[RPC_regs].RFSR_dx
	call	SetPathAsCurPath
	mov	ax, ds:[RPC_regs].RFSR_ax		
	mov	dx, firstBuffer			; ds:dx path
	mov	si, ds:[RPC_regs].RFSR_si		; es:si - DiskDesc
	mov	bp, es:[si].DD_drive		; es:bp - DriveStatusEntry
	mov	bp, es:[bp].DSE_fsd		; es:bp - FSDriver
EC <	call	ECCheckFSDriver						>
	mov	di, DR_FS_PATH_OP
	cmp	ah, FSPOF_RENAME_FILE
	je	rename
	cmp	ah, FSPOF_MOVE_FILE
	je	moveFile
	cmp	ah, FSPOF_GET_EXT_ATTRIBUTES
LONG	je	getExt
	cmp	ah, FSPOF_SET_EXT_ATTRIBUTES
LONG	je	setExt
	cmp	ah, FSPOF_GET_ALL_EXT_ATTRIBUTES
LONG	je	getAllExt
callit:
EC <	call	ECCheckFSDriver						>
	call	es:[bp].FSD_strategy
reply:
	pop	di				; RPC_ID
	mov	bp, DR_FS_PATH_OP
	call	HandleLinkError
	call	SendReplyPassRegisters
exit:
	call	FSDUnlockInfoShared
free:
	pop	bx
	call	MemFree				; free input buffer
EC <	call	ECCheckValidPath					>
	.leave
	ret
rename:	push	si
	mov	si, firstBuffer
	call	strlen				
	add	si, cx				; ds:si - 2nd string
	mov	cx, si
	mov	bx, ds				; bx:cx - 2nd string
	pop	si	
	jmp	callit
moveFile:
	push	cx				; DiskDesc	(1)
	push	si				; (2)
	mov	si, firstBuffer
	call	strlen				
	add	cx, si				; ds:cx - 2nd str
	pop	si				; (2)
	mov	bx, cx				; ds:bx - 2nd str
	pop	cx				; (1)
	sub	sp, size FSMoveFileData
	mov	di, sp
	mov	ss:[di].FMFD_dest.segment, ds
	mov	ss:[di].FMFD_dest.offset, bx	; points to 2nd str
	mov	bx, sp				; ss:bx - FSMoveFileData 
	mov	di, DR_FS_PATH_OP
EC <	call	ECCheckFSDriver			>
	call	es:[bp].FSD_strategy
;EC <	ERROR_C	RFSD_PATH_OP_FAILED		>
   	mov	di, sp
   	lea	di, ss:[di+size FSMoveFileData]
	mov	sp, di
	jmp	reply
getExt:	
; buffer - array of FileExtAttrDesc
; cx - # of entries
	sub	sp, size LocalData
	mov	di, bp
	mov	bp, sp				; ss:bp - localVariables
	mov	ss:[bp].LD_tmp3, di		; FSDriver offset
	mov	ss:[bp].LD_tmp2, si		; DiskDesc
	mov	ss:[bp].LD_tmp1, cx		; # of entries
	sub	sp, size FSPathExtAttrData	
	mov	bx, sp				; ss:sp - FSPathExtAttrData
	mov	si, firstBuffer			; ds:si - path name
	call	strlen				; cx - length of path name
	add	cx, firstBuffer			; ds:cx - FPEAD buffer
	mov	ss:[bx].FPEAD_attr, FEA_MULTIPLE
	mov	ss:[bx].FPEAD_buffer.segment, ds
	mov	ss:[bx].FPEAD_buffer.offset, cx
; we're almost ready, but first we have to prepare a reply buffer
; so first, "run-through" the array and compute required space.
	clr	ax
	mov	di, cx				; ds:di - start of array
	push	di				
	mov	cx, ss:[bp].LD_tmp1
getSp:	mov	ds:[di].FEAD_value.offset, ax 	; offset of where to copy data
	add	ax, ds:[di].FEAD_size		; size of return buffer
	add	di, size FileExtAttrDesc	; next attr 
	loop	getSp
	mov	cx, ((mask HAF_LOCK) or (mask HAF_NO_ERR)) shl 8
	push	ax
	push	bx				; (1)
	call	RFSDMemAlloc
	mov	cx,bx
	pop	bx				; (1)
	pop	dx
	pop	di				; ds:di - array
	push	dx
	push	cx				; mem handle	;(1)
	mov	cx, ss:[bp].LD_tmp1
setVp:	mov	ds:[di].FEAD_value.segment, ax	; segment of where to copy data
	add	di, size FileExtAttrDesc	; next attr 
	loop	setVp
	mov	di, DR_FS_PATH_OP
	mov	ah, FSPOF_GET_EXT_ATTRIBUTES
	mov	dx, firstBuffer			; ds:dx - path
	mov	cx, ss:[bp].LD_tmp1		; # of entries
	mov	si, ss:[bp].LD_tmp2		; es:si - DiskDesc
	mov	bp, ss:[bp].LD_tmp3		; es:bp - FSDriver offset
EC <	call	ECCheckFSDriver			>
	call	es:[bp].FSD_strategy
	call	HandleLinkError
	jnc	noGetExtError

;
;	In general, if an operation returns an error, we return the carry
;	set and do not return a buffer of data. In the case where we
;	have an error because of an unsupported attribute, we want to
;	return the buffer of supported attributes, so we clear the carry.
;
;	We'll detect this case in RFPathOp(), and set the carry before
;	returning.
;

	cmp	ax, ERROR_ATTR_NOT_SUPPORTED
	jz	benignError
	cmp	ax, ERROR_ATTR_NOT_FOUND
	stc	
	jnz	sendGetExtReply
benignError:
	clc
	jmp	sendGetExtReply
noGetExtError:
	clr	ax		;Clears the carry - denote "no error"
sendGetExtReply:
	pop	bx				; (1)
	pop	di				; size of buffer
	call	MemDerefDS

	mov	si, sp
	lea	si, ss:[si+size FSPathExtAttrData + size LocalData]
	mov	sp, si
	mov	si, 0	; ds:si - buffer (Don't trash carry)
	pop	bp				; RPC_ID

	push	bx				; save mem handle
	push	bp				;Pass RPC_ID on stack
	mov	bp, DR_FS_PATH_OP
	call	SendReplyRegsAndBufferInDSSI
	pop	bx
	call	MemFree
	jmp	exit
getAllExt:
EC <	call	ECCheckFSDriver			>
	call	es:[bp].FSD_strategy
	call	HandleLinkError
;EC <	ERROR_C	RFSD_PATH_OP_FAILED		>

	push	ax
	pushf
	mov	bx, ax
	call	MemDerefDS
	mov	ax, MGIT_SIZE
	call	MemGetInfo			; ax - size 
	mov	di, ax
	clr	si				; ds:si - buffer
	popf
	pop	ax

	pop	bp				; RPC_ID

	push	bx				; save mem handle
	push	bp				;Pass RPC_ID on stack
	mov	bp, DR_FS_PATH_OP
	call	SendReplyRegsAndBufferInDSSI
	pop	bx
	call	MemFree
	jmp	exit
setExt:
	sub	sp, size LocalData
	mov	di, sp
	mov	ss:[di].LD_tmp1, si		; DiskDesc
	mov	ss:[di].LD_tmp2, cx		; # of attr's
	mov	si, firstBuffer
	call	strlen				; cx - size of path
	add	cx, firstBuffer			; cx - offset to FECD
	sub	sp, size FSHandleExtAttrData	
	mov	bx, sp				; ss:bx - FSPathExtAttrData
	mov	ss:[bx].FPEAD_attr, FEA_MULTIPLE
	mov	ss:[bx].FPEAD_buffer.segment, ds
	mov	ss:[bx].FPEAD_buffer.offset, cx
	mov	si, cx
	mov	cx, ss:[di].LD_tmp2		; cx - # of attr
; loop through and set the segment:offset pointers
setPt:	mov	ds:[si].FEAD_value.segment, ds
	add	ds:[si].FEAD_value.offset, firstBuffer
	add	si, size FileExtAttrDesc	; next attr
	loop	setPt
	mov	si,ss:[di].LD_tmp1		; DiskDesc
	mov	cx,ss:[di].LD_tmp2		; # of attr's
	mov	di, DR_FS_PATH_OP
EC <	call	ECCheckFSDriver			>
	call	es:[bp].FSD_strategy
	mov	di, sp
	lea	di, ss:[di+size FSHandleExtAttrData + size LocalData]
	mov	sp, di				;Restore stack w/o trashing 
						; carry
	jmp	reply
RFSPathOp	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSFileEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DR_FS_FILE_ENUM

CALLED BY:	
PASS:		*ds:si	= DispatchProcessClass object
		ds:di	= DispatchProcessClass instance data
		ds:bx	= DispatchProcessClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= mem handle of buffer
	In Buffer:
		for FILE_ENUM_START, a buffer containing the FECD
		bx	= disk handle
		dx 	= remote disk handle
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSFileEnum	method dynamic DispatchProcessClass, 
					MSG_RFS_FILE_ENUM

; start of FILE_ENUM_START

	mov	bx,cx
	tst	es:[closingConnection]
	LONG jnz	free
	call	MemLock			; lock buffer
	mov	ds,ax
	mov	dx, ds:[RPC_regs].RFSR_dx
	call	SetPathAsCurPath
	mov	ax, ds:[RPC_ID]	; caller ID
	mov	es:[replyID], ax
	push	ds:[RPC_regs].RFSR_bx		; disk handle
	mov	si, (size RFSHeader) + (size RFSRegisters)
	lodsw				;AX <- size of FECD
	mov	dx,ax			; temp. storage
	mov	cx, (mask HF_SWAPABLE) or (((mask HAF_LOCK) or \
			(mask HAF_NO_ERR)) shl 8)
	push	bx			; save our memhandle
	call	RFSDMemAlloc
	mov	es,ax
	clr	di			; es:di - our new buffer for FECD
	mov	cx,dx			; cx - size
	call	strncpy			; copy FECD to es:di
	mov	dx,bx			; save the new buffer handle for now
	pop	bx			; old buffer 
	call	MemFree
	segmov	ds,es,ax		; ds - segment of FECD
	call	FSDLockInfoShared	
	mov	es,ax
EC <	call	AssertInterruptsEnabled					>
	pop	si			; es:si - DiskDesc
	push	dx			; mem handle for FECD
	mov	cx,cs
	mov	dx,offset cs:RFSDFileEnumCallback	; cx:dx - callback routine
	mov	bx,sp				; ss:bx - stack frame
	mov	di,DR_FS_FILE_ENUM
	call	CallFSDriverForDrive
EC <	call	AssertInterruptsEnabled					>
	call	FSDUnlockInfoShared	
	pop	bx
	call	MemFree			; free FECD buffer
	segmov	ds,dgroup,bx
	mov	di,ds:[replyID]
	mov	bp, DR_FS_FILE_ENUM
	mov	al, FILE_ENUM_END
	clc
	call	SendReplyPassRegisters
	ret
free:
	GOTO	MemFree
RFSFileEnum	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSDFileEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call-back routine for DR_FS_FILE_ENUM

CALLED BY:	RFSFileEnum (sorta)
PASS:		ds	= segment of FileEnumCallbackData.
			  Any attribute descriptor for which
			  the file has no corresponding
			  attribute should have the
			  FEAD_value.segment set to 0. All
			  others must have FEAD_value.segment
			  set to DS when their value is stored.
			  ss:bp	= ss:bx passed to FSD
RETURN:		Return:	carry set to stop enumerating files:
			ax	= error code
DESTROYED:	es, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSDFileEnumCallback	proc	far
	uses	ax,bp,ds
	.enter
EC <	call	ECMemVerifyHeap						>
	mov	ax, 512				; hack (max size)
	mov	cx, (mask HF_SWAPABLE) or (((mask HAF_LOCK) or \
			(mask HAF_NO_ERR)) shl 8)
	call	RFSDMemAlloc
	push	bx				; save mem handle
	mov	es,ax
	clr	di				; es:di - blank buffer
	clr	si				; ds:si - 1st FileExtAttrDesc
copyLoop:
	cmp	ds:[si].FEAD_attr, FEA_END_OF_LIST
	jz	cont				; end of the list, quit 
	tst	ds:[si].FEAD_value.segment	; is the attribute set?
	jz	next				; no, then don't copy anything
	mov	es:[di],si			; attribute offset in FECD
	inc	di
	inc	di
	push	si
	mov	cx, ds:[si].FEAD_size
	mov	si, ds:[si].FEAD_value.offset	; ds:si - attribute value
EC<	cmp	cx, 256			>	; too big?
EC<	jna	cont1			>
EC<	ERROR	ERROR_RFSD_VALUE_OUT_OF_RANGE	>
EC<	cont1:				>
	call	strncpy
	pop	si
	add	di, cx
next:
	lea	si, ds:[si+size FileExtAttrDesc]
	jmp	copyLoop			; next attribute!	
; now we have copied all the attributes that hold values into es:di, so 
; we must send it to the client as a reply, then block on the thread for
; our next action.
cont:
	mov 	{byte} es:[di], END_OF_ATTR	; signifies end-of-attr
	inc	di
	segmov	ds,es,ax
	clr	si				; ds:si - buffer
	mov	bp, DR_FS_FILE_ENUM
	segmov	es,dgroup,ax
	push	es:[replyID]			;Pass RPC_ID on stack
	clc
	call	SendReplyRegsAndBufferInDSSI	; di is still buffer size

EC <	call	ECMemVerifyHeap						>

; now we sent the buffer, so we must wait for a call from the client
; so we stop the thread.

	pop	bx				; mem handle
	call	MemFree				; free our buffer first
EC <	call	ECMemVerifyHeap						>

nextMessage:
;
;	Wait in a loop and process the messages coming in from the remote
;	machine.
;
;	If the connection is closed, then exit.
;

	tst	es:[closingConnection]
       	jnz	stopEnum

	mov	ax, TGIT_QUEUE_HANDLE
	clr	bx
	call	ThreadGetInfo
	mov_tr	bx, ax
	call	QueueGetMessage			; ax = message
	mov_tr	bx, ax				; bx = message

	tst	es:[closingConnection]
	jnz	dispatchMessage

	push	cs
	mov	si, offset cs:FileEnumHandleMessage
	push	si
	clr	si				; destroy event after dispatch
	call	MessageProcess			;

;	If the message was MSG_RFS_FILE_ENUM, then this returns CX = block of
;	data containing either FILE_ENUM_NEXT or FILE_ENUM_END.
;
;	Otherwise, the message was dispatched normally. If this message means
;	that we should quit doing the FileEnum (for example, if the connection
;	was broken, and we got a MSG_RFSD_SEND_DRIVES_REMOTE) this returns
;	CX=-1. Otherwise, CX=0.
;	

	jcxz	nextMessage
	cmp	cx, -1
	jz	stopEnum

EC <	call	ECMemVerifyHeap						>

; we got our next message from the client now...  what is it?

	mov	bx,cx
	call	MemLock
	mov	ds, ax
	clr	di				; es:di - message
	segmov	es:[replyID],ds:[RPC_ID], ax
	mov	ax, ds:[RPC_regs].RFSR_ax
	call	MemFree
	cmp	al, FILE_ENUM_NEXT
	clc
	jz	exit
; here, we have a FILE_ENUM_END
EC <	cmp	al, FILE_ENUM_END					>
EC <	ERROR_NZ	INVALID_FILE_ENUM_COMMAND			>
stopEnum:
	stc
exit:
EC <	call	ECMemVerifyHeap						>
	.leave
	ret
dispatchMessage:

;	We are closing the connection, so dispatch this message normally,
;	then stop the enumeration. If it is MSG_RFS_FILE_ENUM, it's still
;	OK, because the handler just exits if closingConnection is non-zero.

	clr	di
	call	MessageDispatch
	jmp	stopEnum
RFSDFileEnumCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileEnumHandleMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	stores all variables (or restores them)

CALLED BY:	GeodeDispatchFromQueue
PASS:		data from message handle
RETURN:		cx - data handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	6/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileEnumHandleMessage	proc	far
	.enter
	cmp	ax, MSG_RFS_FILE_ENUM					
	je	exit

;	If we get an FS request, this means that there was some kind of remote
;	error (such as a timeout). If so, queue up the message, and abort
;	the file enum.

	cmp	ax, FIRST_FS_MSG					
	jb	notFSMsg
	cmp	ax, LAST_FS_MSG						
	ja	notFSMsg
EC <	WARNING		FS_MSG_CAME_IN_DURING_FILE_ENUM			>
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	jmp	abortFileEnum

notFSMsg:								
;
;	This is not a FS request, so dispatch it, then determine whether or
;	not to abort the file enum.
;
   	push	ax
	clr	di
	call	ObjMessage
	pop	ax

;	Now, if this is a benign message, like REMOTE_FILE_CHANGE_NOTIFICATION,
;	return CX=0 to continue the FileEnum.
;	Otherwise, return CX=-1.

	clr	cx

;	If we receive MSG_RFSD_SEND_DRIVES_REMOTE, this means that the
;	connection has been reset, so stop the FileEnum.

	cmp	ax, MSG_RFSD_SEND_DRIVES_REMOTE
	jne	exit
abortFileEnum:
	mov	cx, -1
exit:
	.leave
	ret
FileEnumHandleMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRegsFromBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get register values from packaged buffer

CALLED BY:	GLOBAL
PASS:		cx - handle to buffer
RETURN:		ax,bx,cx,dx,si - values
		di - FSFunction
		bp - RPC_ID
		buffer freed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRegsFromBuffer	proc	near
	uses	ds
	.enter
  	mov	bx,cx
	call	MemLock
	mov	ds,ax
	mov	di, ds:[RPC_FSFunction]
	mov	bp, ds:[RPC_ID]
	mov	ax, ds:[RPC_regs].RFSR_ax
	mov	cx, ds:[RPC_regs].RFSR_cx
	mov	dx, ds:[RPC_regs].RFSR_dx
	mov	si, ds:[RPC_regs].RFSR_si
	push	ds:[RPC_regs].RFSR_bx
	call	MemFree
	pop	bx
	.leave
	ret
GetRegsFromBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSFlushFileChangeNotifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is sent when the remote machine has not received any
		file operations in a while.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSFlushFileChangeNotifications	method	DispatchProcessClass,
				MSG_RFSD_FLUSH_FILE_CHANGE_NOTIFICATIONS
	.enter
if	DEBUGGING
	WARNING	FLUSHING_FILE_CHANGE_NOTIFICATIONS
endif
	call	FileFlushChangeNotifications
	.leave
	ret
RFSFlushFileChangeNotifications	endp

Server	ends
