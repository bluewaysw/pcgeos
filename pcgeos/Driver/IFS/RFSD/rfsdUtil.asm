COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		RFSD
FILE:		rfsdUtil.asm

AUTHOR:		In Sik Rhee, 4/92

ROUTINES:
	Name			Description
	----			-----------
	strncpy			String copy
	strcpy			String copy (0 terminated)
	strlen			length of 0-terminated string
	PClientSem		block until we get Client semaphore
	VClientSem		release client semaphore	
	PackageOutBuffer	package variables into message buffer
	GetRemoteDiskHandle	return mapped disk handle	
	GetRegsFromBuffer	get registers from packaged buffer
	RFSendBuffer		send a buffer to the remote side
	ProcessLink		call FSD, processing any links which show
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/11/92		Initial revision


DESCRIPTION:
	Utility functions for use

	$Id: rfsdUtil.asm,v 1.1 97/04/18 11:46:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Common	 segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks down the file list

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		^lbx:si, *ds:si - file list
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockFileList	proc	far	uses	ax
	.enter
	segmov	ds, dgroup, bx
	movdw	bxsi, ds:[fileList]
	call	MemLock
	mov	ds, ax
	.leave
	ret
LockFileList	endp

if	ERROR_CHECK
ECCheckBoundsESDIFar	proc	far
	call	ECCheckBoundsESDI
	ret
ECCheckBoundsESDIFar	endp
ECCheckBoundsESDI	proc	near
	segxchg	ds, es
	xchg	di, si
	call	ECCheckBounds
	xchg	di, si
	segxchg	ds, es
	ret
ECCheckBoundsESDI	endp

AssertESDgroup	proc	near
	push	ax
	mov	ax, es
	cmp	ax, segment dgroup
	ERROR_NZ	ES_NOT_DGROUP
	pop	ax
	ret
AssertESDgroup	endp
endif	;ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strncpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copies a string given its size

CALLED BY:	GLOBAL
PASS:		ds:si - src
		es:di - dest
		cx - size
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	es:di must have space to fit ds:si string
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
strncpy	proc	far
	uses	cx,si,di
	.enter
EC <	call	ECMemVerifyHeap						>
EC <	call	ECCheckBoundsESDI					>
EC <	call	ECCheckBounds						>
	jcxz	exit
	shr	cx, 1
	jnc	5$
	movsb
5$:
	rep	movsw			;strcpy
EC <	dec	di							>
EC <	dec	si							>
EC <	call	ECCheckBoundsESDI					>
EC <	call	ECCheckBounds						>
EC <	call	ECMemVerifyHeap						>
exit:
	.leave
	ret
strncpy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copies a string (null-terminated)

CALLED BY:	GLOBAL
PASS:		ds:si - src
		es:di - dest
RETURN:		ax - # of chars copied including null
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	es:di must have space to fit ds:si string
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
strcpy	proc	far
	uses	cx,si,di
	.enter
EC <	call	ECMemVerifyHeap						>
EC <	call	ECCheckBoundsESDI					>
EC <	call	ECCheckBounds						>

; 	GET LENGTH OF SRC STRING

	segxchg	ds,es
	push	di
	mov	di,si			;es:di - src
	mov	cx, -1
	clr	ax
	repne	scasb
	not	cx			;CX <- # chars + null in src str
	mov	ax,cx
	segxchg	ds,es
	pop	di			;ds:si - src buf  es:di - dest buf
	shr	cx, 1
	jnc	5$
	movsb
5$:
	rep	movsw			;strcpy
EC <	dec	di							>
EC <	dec	si							>
EC <	call	ECCheckBoundsESDI					>
EC <	call	ECCheckBounds						>
EC <	call	ECMemVerifyHeap						>
	.leave
	ret
strcpy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strlen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets length of null-terminated string

CALLED BY:	GLOBAL
PASS:		ds:si - string
RETURN:		cx - length, including null
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
strlen	proc	far
	uses	ax,es,di
	.enter
EC <	call	ECCheckBounds						>
	segmov	es,ds,cx		;es:di - src
	mov	di,si
	mov	cx, -1 
	clr	al
	repne	scasb
	not	cx			;# of chars + null
	.leave
	ret
strlen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PClientSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Block until we get the Client semaphore

CALLED BY:	RFFileEnum, SendMessageRemote,  RFOpenConnection, 
       		RFSDCloseConnection
PASS:		nothing
RETURN:		z flag clear if closing the connection
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PClientSem	proc	far
	uses	ax,bx,ds
	.enter
	segmov	ds,dgroup,bx
	mov	bx, ds:[clientSem]
	call	ThreadPSem
	tst	ds:[closingConnection]
	.leave
	ret
PClientSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VClientSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	release Client semaphore

CALLED BY:	RFFileEnum, SendMessageRemote,  RFOpenConnection, 
       		RFSDCloseConnection
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VClientSem	proc	far
	uses	ax,bx,ds
	.enter
	pushf
	segmov	ds,dgroup,bx
	mov	bx,ds:[clientSem]
	call	ThreadVSem
	popf
	.leave
	ret
VClientSem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabNotificationTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a ThreadGrabThreadLock of the notification timer semaphore

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabNotificationTimer	proc	far	uses	es, bx
	.enter
	pushf
	segmov	es, dgroup, bx
	mov	bx, es:[notificationTimerLock]
	call	ThreadGrabThreadLock
	popf
	.leave
	ret
GrabNotificationTimer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReleaseNotificationTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Releases the notification timer semaphore

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReleaseNotificationTimer	proc	far	uses	es, bx
	.enter
	pushf
	segmov	es, dgroup, bx
	mov	bx, es:[notificationTimerLock]
	call	ThreadReleaseThreadLock
	popf
	.leave
	ret
ReleaseNotificationTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PackageOutBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	packages variables into a message buffer

CALLED BY:	CallRemote, SendReplyPassRegisters
		SendReplyRegsAndBufferInDSSI
PASS:		ax,bx,cx,dx,si - variables
		di - FSFunction (only for CallRemote)
		di = 0 for Reply
			bp - FSFunction
RETURN:		bx - mem handle
		cx - size of buffer
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PackageOutBuffer	proc	far
	uses	ax,ds
	.enter
EC <  	call	ECCheckSegments						>
	push	ax, bx, cx
	mov	ax, (size RFSHeader) + (size RFSRegisters)
	mov	cx, (mask HF_SWAPABLE) or (((mask HAF_LOCK) or \
			(mask HAF_NO_ERR)) shl 8)
	call	RFSDMemAlloc
	mov	ds, ax
	clr	ds:[RPC_flags]			; clear all flags
	mov	ds:[RPC_proc], RFS_REPLY	; assume reply
	mov	ds:[RPC_FSFunction], bp
	tst	di
	jz	isReply				; continue if reply
	mov	ds:[RPC_proc], RFS_FSFUNCTION	; fs call
	mov	ds:[RPC_FSFunction], di		
EC <	cmp	ds:[RPC_FSFunction], FSFunction				>
EC <	ERROR_AE	ILLEGAL_FS_FUNCTION				>
isReply:
	mov	ds:[RPC_regs].RFSR_dx, dx
	mov	ds:[RPC_regs].RFSR_si, si

	pop	ds:[RPC_regs].RFSR_ax, ds:[RPC_regs].RFSR_bx, ds:[RPC_regs].RFSR_cx
	mov	cx, (size RFSHeader) + (size RFSRegisters)
	call	MemUnlock
	.leave
	ret
PackageOutBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSendBufferWithRetries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tries to send the buffer a few times

CALLED BY:	GLOBAL
PASS:		same as RFSendBuffer
RETURN:		carry set if couldn't send
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSendBufferWithRetries	proc	far	uses	dx
	.enter
	mov	dx, NUM_RETRIES
resend:
	call	RFSendBuffer
	jnc	exit
	dec	dx				;Does not affect carry
	jnz	resend
	;Carry should be set here
EC <	ERROR_NC	-1						>
exit:
	.leave
	ret
RFSendBufferWithRetries	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RFSendBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a buffer to the remote side

CALLED BY:	GLOBAL
PASS:		ds:si - buffer
		cx - size
		es - dgroup
RETURN:		carry set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RFSendBuffer	proc	far
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	.enter
EC <	call	ECCheckBounds						>
EC <	call	AssertESDgroup						>
EC <	call	ECMemVerifyHeap						>

;	Check that the start and end of the buffer are in bounds.

EC <	push	si							>
EC <	call	ECCheckBounds						>
EC <	add	si, cx							>
EC <	dec	si							>
EC <	call	ECCheckBounds						>
EC <	pop	si							>
	mov	bx, es:[port]
	mov	dx, es:[socket]
	call	NetMsgSendBuffer		; ax - socket token
	.leave
	ret
RFSendBuffer	endp

if 	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	process any links encountered.

CALLED BY:	RFSD
PASS:		called after FSD returns a carry set
		ax - error code
		bx - if ax = ERROR_LINK_ENCOUNTERED, mem block of link info
RETURN:		carry set if ax != ERROR_LINK_ENCOUNTERED (no link)
		ds:dx - path
		es:bp - FSDriver
		es:si - diskdesc
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/28/92		Initial version

; commented out!

ProcessLink	proc	near
	uses	ax,cx
	.enter
; here, carry was set, see if AX=ERROR_LINK_ENCOUNTERED and act accordingly
	cmp	ax, ERROR_LINK_ENCOUNTERED
	stc
	jnz	exit
; here, we have encountered a symbolic link, so we must call the FSD with
; the correct disk handle / path...
	call	MemLock
	mov	ds, ax
	mov	si, offset FSLH_savedDisk
	clr	cx
	call	DiskRestore		; ax - disk handle
	pop	cx
EC<	ERROR_C	RFSD_CANT_RESTORE_DISK	>
	mov	si, ax			; es:si - DiskDesc
	mov	dx, size FSLinkHeader
	add	dx, ds:[FSLH_diskSize]	; ds:dx - path
	mov	bp, es:[si].DD_drive	; es:bp - DriveStatusEntry
	mov	bp, es:[bp].DSE_fsd	; es:bp - FSDriver
	clc
exit:	.leave
	ret
ProcessLink	endp

		DoPathOpAndLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call FSD for PathOp and process links

CALLED BY:	RFSD
PASS:		called before FSD is called
RETURN:		results of FSD call
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/31/92		Initial version

DoPathOpAndLink	proc	near
	.enter
	push	ax
	push	bx
	push	cx
	call	es:[bp].FSD_strategy		; call it!
dolink:	jnc	reply
;	call	ProcessLink
	jc	reply
	mov	di,bx
	pop	cx
	pop	bx
	pop	ax
	push	ax
	push	bx
	push	cx
	push	di
	mov	di, DR_FS_PATH_OP
	call	es:[bp].FSD_strategy		; call pathOp
	mov	di,bx
	pop	bx
	call	MemUnlock
	mov	bx,di			
	jmp	dolink
reply:	pop	di				; don't care about stored
	pop	di				; values 
	pop	di
	.leave
	ret
DoPathOpAndLink	endp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
endif

if	ERROR_CHECK

	; ensure that interrupts are on here...

AssertInterruptsEnabled	proc	far
	pushf
	push	ax

	pushf
	pop	ax
	test	ax, mask CPU_INTERRUPT
	ERROR_Z	INTERRUPTS_OFF_WHEN_THEY_SHOULD_NOT_BE
	test	ax, mask CPU_DIRECTION
	ERROR_NZ DIRECTION_FLAG_SET_INCORRECTLY

	pop	ax
	popf
	ret

AssertInterruptsEnabled	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckFSDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure es:bp points to FSDriver

CALLED BY:	GLOBAL
PASS:		es:bp	pointer to FSDriver
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckFSDriver	proc	far
	.enter
	xchg	di, bp							
	call	ECCheckBoundsESDI					
	xchg	di, bp
	tst	es:[bp].FSD_diskPrivSize
	jnz	error				; 0 - all except RFSD
exit:
	.leave
	ret
error:
	WARNING	NOT_FSDRIVER
	jmp	exit				; *** set breakpoint here.
ECCheckFSDriver	endp
endif

Common	ends

