COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		commOpenClose.asm

AUTHOR:		Gene Anderson, Apr 28, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/28/93		Initial revision


DESCRIPTION:
	Code for opening & closing ports and sockets

	$Id: commOpenClose.asm,v 1.1 97/04/18 11:48:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitExitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommOpenPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a connection with remote host

CALLED BY:	CommMessaging() (DR_NET_MESSAGING)
PASS:		ds:si 	- buffer (with SerialPortInfo in it)
		cx	- size of buffer (not necessary for this driver)
RETURN:		carry set if error, ax becomes error code
		bx - port token (element #)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	register port as DOMAIN to the net library
	Lock LMEM block
	locate existing entry for specified port
	if it exists, then increment ref count. (make sure baud rates match)
	if not, then find a blank entry or create a new one.
	Allocate ACK and send semaphores, initialize all PortStruct values.	
	open a stream for the port
	launch the server thread.
	each new port is assigned a server thread, so port operations are fully 
	independent and hangups on one port will not affect the others.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EC  <serialDriverName	byte	"serialec.geo",0	>
NEC <serialDriverName	char	"serial.geo", 0 	>

CommOpenPort	proc	far
	uses	cx,dx,si
	.enter

FXIP <	push	bx							>
FXIP <	mov	bx, ds				; bx:si = buffer	>
FXIP <	call	ECAssertValidFarPointerXIP				>
FXIP <  pop	bx							>
	
	mov	cx, ds:[si].SPI_portNumber
EC <	cmp	cx, MAX_NUM_PORTS					>
EC <	ERROR_AE	INVALID_PORT_NUMBER				>

	mov	bp, ds:[si].SPI_baudRate
	segmov	es,dgroup,ax
	mov	bx,es:[lmemBlockHandle]
	call	MemLockExcl
	push	bx
	mov	ds,ax			
	mov	si, es:[portArrayOffset]	;*ds:si - ChunkArray
	mov	bx, cs
	mov	di, offset cs:FindPortCallBack	; bx:di - callback
	call	ChunkArrayEnum
	jnc	newPort				;branch if port doesn't exist
	;
	; here, the port already exists, so we make sure baud rates
	; match then up the refCount
	;
	mov	di, dx				; ds:di - PortStruct
	cmp	bp, ds:[di].PS_baudRate		
	jz	baudRateOK
	;
	; here, wrong baud rates...  tsk tsk.
	;
	mov	ax, NET_ERR_WRONG_BAUD_RATE
EC< 	WARNING	PORT_EXISTS_WITH_DIFFERENT_BAUD_RATE	>
	stc
	jmp	exit

baudRateOK:
EC< 	WARNING	PORT_COUNT_INCR				>
	inc	ds:[di].PS_refCount
	call	ChunkArrayPtrToElement		; ax - port token
	mov	dx, ax
	clc	
	jmp	exit

	;
	; see if a deleted port structure exists.
	;
newPort:
	push	cx
	mov	cx, DELETED_PORT_NUMBER
	mov	bx, cs
	mov	di, offset cs:FindPortCallBack	; bx:di - callback
	call	ChunkArrayEnum
	pop	cx
	jnc	noDeletedPorts			;branch if no deleted ports
	;
	; here, we found a deleted port structure...  no need to create one
	;
	mov	di, dx				;ds:di - PortStruct
	jmp	initPortStruct

	;
	; here, we have to init the port ourselves...
	;
noDeletedPorts:
	call	ChunkArrayAppend
initPortStruct:
	mov	ds:[di].PS_number, cx
	mov	ds:[di].PS_refCount, 1
	mov	ds:[di].PS_maxTimeout, INIT_TIME_OUT_VALUE
	mov	ds:[di].PS_baudRate, bp	
	shr	cx				; cheat :)
	mov	ds:[di].PS_packetID, cx		; offset in packet Table.
	mov	bx,cx
EC <	cmp	bx, size packetIDin					>
EC <	ERROR_AE	COMM_BAD_PACKET_ID				>

	clr	es:[packetIDin][bx]
	clr	es:[packetIDout][bx]		; clear in/out ID's
	;
	; allocate send and ACK semaphores
	;
	mov	bx,1
	call	ThreadAllocSem			;create semaphore [CLIENT]
	call	SetCommOwner
	mov	ds:[di].PS_sendSem,bx
	mov	bx,1
	call	ThreadAllocSem			;create semaphore to ensure
						; exclusive access to the port
						; while sending packets
	call	SetCommOwner
	mov	ds:[di].PS_sendPacketSem,bx
	clr	bx
	call	ThreadAllocSem			;create semaphore [SEND]
	call	SetCommOwner
	mov	ds:[di].PS_ackSem,bx

	call	GeodeAllocQueue			;Create queue for the server
	call	SetCommOwner
	mov	ds:[di].PS_exitAckQueue, bx	; thread to send an ack to when
						; it exits
	;
	; Allocate the socket array for this port.  Because we
	; are allocating in the same block, we rederefence the
	; PortStruct in case the block moved on the heap or the
	; chunk moved within the block.
	;
	call	ChunkArrayPtrToElement		;ax <- element #
	push	ax, si
	mov	bx, size SocketStruct		;bx <- element size
	clr	cx				;cx <- no extra space
	clr	al				;al <- ObjChunFlags
	clr	si				;si <- allocate chunk
	call	ChunkArrayCreate
	mov	dx, si				;dx <- chunk of
	pop	ax, si
	call	ChunkArrayElementToPtr		;ds:di <- PortStruct
	mov	ds:[di].PS_socketArray, dx
	;
	; now we initialize the physical port (open a stream)
	;
	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	push	ds
	segmov	ds,cs,ax			;ds:si - driver filename
	mov	si, offset serialDriverName
	mov	ax, SERIAL_PROTO_MAJOR
	mov	bx, SERIAL_PROTO_MINOR
	call	GeodeUseDriver
	call	FilePopDir
	pop	ds
	mov	ax, NET_ERROR_DRIVER_NOT_FOUND
EC <	ERROR_C	ERROR_COMM_NO_SERIAL_DRIVER	>
NEC <	LONG jc	error				>

	mov	ds:[di].PS_driverHandle, bx

	push	ds
	call	GeodeInfoDriver			;ds:si - DriverInfoStruct
	movdw	dxbx, ds:[si].DIS_strategy	; dx:bx - strategy routine
	pop	ds				;restore chunkarray
	movdw	ds:[di].PS_serDrvr,dxbx		;store routine addr

	mov	bp, di					; ds:bp - element
	mov	di, DR_SERIAL_OPEN_FOR_DRIVER
	mov	ax, mask SOF_NOBLOCK
	mov	bx, ds:[bp].PS_number
	mov	cx, INPUT_STREAM_BUFFER_SIZE		
	mov	dx, OUTPUT_STREAM_BUFFER_SIZE
	mov	si, handle 0
	push	bp
	call	ds:[bp].PS_serDrvr
	pop	bp
	;
	; if carry set here, then the com port is invalid, so we exit
	;
	jc	serialError
	mov	ds:[bp].PS_strToken, bx		; stream token
	mov	di, DR_SERIAL_SET_FORMAT
	mov	al, SL_8BITS
	mov	ah, SM_RAW
	mov	cx, ds:[bp].PS_baudRate		; baud rate
	push	bp
	call	ds:[bp].PS_serDrvr
	pop	bp
	mov	di, DR_SERIAL_SET_FLOW_CONTROL
	clr 	ax				;no flow control
	push	bp
	call	ds:[bp].PS_serDrvr
	pop	bp

;	Set up a notification threshold

	mov	di, DR_STREAM_SET_THRESHOLD
	mov	ax, STREAM_WRITE
	mov	cx, OUTPUT_STREAM_BUFFER_SIZE
	push	bp
	call	ds:[bp].PS_serDrvr
	pop	di				; ds:di - element
	;
	; now we start up the server thread for this port
	;
	mov	si, es:[portArrayOffset]	;*ds:si - chunkarray
	call	ChunkArrayPtrToElement		; ax - element # = port token
	push	ax,bp
	mov	bx, ax				; bx - port token
	mov	al, SERVER_THREAD_PRIORITY
	mov	cx, segment CommServerLoop	;cx:dx - starting point
	mov	dx, offset CommServerLoop	;jumps to that code
	mov	di, SERVER_THREAD_STACK_SIZE
	mov	bp, handle 0 
	call	ThreadCreate
	pop	dx,bp

EC <	ERROR_C ERROR_COMM_COULD_NOT_CREATE_SERVER_THREAD	>
EC <	WARNING	PORT_INITIALIZED				>

   	mov	cx, ds:[bp].PS_number
	call	RegisterPortAsDomain
exit:
	pop	bx
	call	MemUnlockExcl
	mov	bx,dx
	.leave
	ret
serialError:

;	Free up the serial driver, and map the serial error to the appropriate
;	net error.

	mov	di, bp				;DS:DI <- PortStruct
	mov	bx, ds:[di].PS_driverHandle
	call	GeodeFreeDriver
	cmp	ax, STREAM_DEVICE_IN_USE
	mov	ax, NET_ERR_PORT_IN_USE
	je	error
	mov	ax, NET_ERR_INVALID_PORT
EC <	WARNING	COMM_INVALID_PORT					>
error:
	mov	si, di
	call	NukePortStruct
	stc
	jmp	exit
CommOpenPort	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCommOwner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the Comm driver own this handle so that it
		doesn't go away when the app that loaded us exits.

CALLED BY:	CommOpenPort

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
SetCommOwner	proc near
		uses	ax
		.enter
		mov	ax, handle 0
		call	HandleModifyOwner

		.leave
		ret
SetCommOwner	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegisterPortAsDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers the port as a domain to the Net Library

CALLED BY:	CommOpenPort
PASS:		cx - port number
RETURN:		carry set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RegisterPortAsDomain	proc	near
	uses	ax,bx,cx,dx,ds,si
	.enter

	mov	bx, cx				;bx <- port #
	segmov	ds, cs
	mov	si, ds:domainNameTable[bx]	;ds:si <- ptr to domain name
	mov	cx, segment CommStrategy
	mov	dx, offset CommStrategy		;cx:dx <- strategy routine
	mov	bx, handle 0			;bx <- handle of Comm driver
	call	NetRegisterDomain
	.leave
	ret
RegisterPortAsDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnregisterPortAsDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregisters the port as a domain to the Net Library

CALLED BY:	CommOpenPort
PASS:		cx - port number
RETURN:		carry set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnregisterPortAsDomain	proc	near
	uses	ax,bx,cx,dx,ds,si
	.enter
	mov	bx, cx				;bx <- port #
	segmov	ds, cs
	mov	si, ds:domainNameTable[bx]	;ds:si <- ptr to domain name
	call	NetUnregisterDomain
EC <	ERROR_C	CANNOT_UNREGISTER_DOMAIN				>
	.leave
	ret
UnregisterPortAsDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPortCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tries to match ChunkArray entry with given port #

CALLED BY:	ChunkArrayEnum
PASS:		ds:di - array element
		cx - port #		
RETURN:		carry set if match, dx - offset to element
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindPortCallBack	proc	far
	mov	dx, di
	cmp	ds:[di].PS_number, cx
	stc
	jz	exit
	clc
exit:
	ret
FindPortCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommClosePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close selected port

CALLED BY:	CommMessaging() (DR_NET_MESSAGING)
PASS:		bx - port token
RETURN:		carry set if error, ax - error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Find Port
	Decrement ref count
	if ref count = 0 then 
		delete socket chunkarray
		delete semaphores
		mark deleted
		close stream

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommClosePort	proc	far
	uses	bx,cx,dx,di
	.enter
	mov	ax, bx
	call	VerifyAndGetPortStruct
	push	ax				; mem handle
	mov	ax, NET_ERR_INVALID_PORT_TOKEN
	jc	exit
	;
	; if refCount > 0 then we still have active sockets
	;
EC <	call	ECCommCheckPortStruct					>
	dec	ds:[di].PS_refCount
	jnz	noError			;branch if still references

	call	ClosePortAndAwaitAck

	mov	bx, ds:[di].PS_driverHandle
	call	GeodeFreeDriver			;Nuke the serial driver
noError:
	clc
exit:
	pop	bx
	call	MemUnlockShared
	.leave
	ret
CommClosePort	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClosePortAndAwaitAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the com port and awaits an ack from the thread 
		servicing that port.

CALLED BY:	GLOBAL
PASS:		ds:di - PortStruct
RETURN:		nada
DESTROYED:	ax, bx, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClosePortAndAwaitAck	proc	near	uses	di
	.enter
	mov	si, di

FXIP <	mov	bx, ds			; bx:si = buffer		>	
FXIP <	call	ECAssertValidFarPointerXIP				>

PrintMessage <hack to allow exiting >
;;;

;	If we are doing a dirty shutdown, then the serial driver may already
;	have exited. If so, don't try to close the port, just free up the
;	semaphores and exit.

	mov	cx, ds:[si].PS_serDrvr.segment
	call	MemSegmentToHandle
	jnc	skipClose			;branch if serial driver gone
;;;

	;
	; Wait twice the max retry interval in the hope that the server will
	; be able to process any retransmitted packets.
	;
	; We wait twice the retry interval following the last valid data packet
	; received.
	;
	push	es
	segmov	es, dgroup, bx
	les	bx, ds:[si].PS_serverPtr
	mov	dx, es:[bx].SE_packetCount	; dx <- current new count

waitFullDelayLoop:
	mov	cx, es:[bx].SE_okPacketCount	; cx <- current valid count
	mov	di, 4				; di <- sleep iteration count

waitQuarterDelayLoop:
	mov	ax, ds:[si].PS_maxTimeout
	shr	ax				; wait 1/4 the interval, for
						;  greater precision, you know
	call	TimerSleep
	cmp	dx, es:[bx].SE_packetCount
	jne	packetAckWaitDone		; => got past the last one
						;  we received while there was
						;  still a socket open
	cmp	cx, es:[bx].SE_okPacketCount
	jne	waitFullDelayLoop		; => got a valid data packet,
						;  but not a new one, so reset
						;  the sleep interval
	dec	di
	jnz	waitQuarterDelayLoop

packetAckWaitDone:
	pop	es

	mov	ax, STREAM_BOTH
	mov	di, DR_STREAM_FLUSH			; flush any input
	mov	bx, ds:[si].PS_number
	call	ds:[si].PS_serDrvr

	mov	di, DR_STREAM_CLOSE
	mov	ax, STREAM_DISCARD
	mov	bx, ds:[si].PS_number		; unit #
	call	ds:[si].PS_serDrvr		; kill stream

;	When the thread exits, it'll send an MSG_META_ACK to the ackQueue, so
;	hang out here and wait for it.

	mov	bx, ds:[si].PS_exitAckQueue
	call	QueueGetMessage			;Wait here until the thread
						; exits
	mov_tr	bx, ax
	call	ObjFreeMessage			;Just free the ack message


skipClose:
	clr	ax
	xchg	ax, ds:[si].PS_socketArray	;ax <- socket Chunkarray handle
	call	LMemFree			;destroy it

	mov	cx, ds:[si].PS_number
	call	UnregisterPortAsDomain
	call	NukePortStruct

EC <	WARNING	PORT_CLOSED			>
	.leave
	ret
ClosePortAndAwaitAck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NukePortStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up semaphores, queues, etc related to the port 
		structure.

CALLED BY:	GLOBAL
PASS:		ds:si - PortStructure
RETURN:		nada
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NukePortStruct	proc	near
	.enter

FXIP <	mov	bx, ds				; bx:si = buffer	>
FXIP <	call	ECAssertValidFarPointerXIP				>
	
	mov	ds:[si].PS_number, DELETED_PORT_NUMBER	; mark deleted
	mov	bx, ds:[si].PS_exitAckQueue
	call	GeodeFreeQueue

	mov	bx, ds:[si].PS_sendSem
	call	ThreadFreeSem
	mov	bx, ds:[si].PS_sendPacketSem
	call	ThreadFreeSem
	mov	bx, ds:[si].PS_ackSem
	call	ThreadFreeSem
	.leave
	ret
NukePortStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommCreateSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a socket in the specified port

CALLED BY:	CommMessaging() (DR_NET_MESSAGING)
PASS:		bx - port token
		cx - socket ID specified by caller (a UNIQUE #)
		bp - destination socket ID
		ds:dx - callback routine (0 if using a dispatch thread)
		si - data to pass to callback in bx
RETURN:		carry set if error, ax - error code
		ax - socket token 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	check to see if port exists
	check to see if socket exists under the same token (no-no)
	create ChunkArrayElement for socket
	initialize socket data, store callback addr

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommCreateSocket	proc	far
	uses	cx,dx,si,bp
	destID		local	SocketID	\
			push	bp
	socketID	local	SocketID	\
			push	cx
	portToken	local	word		\
			push	bx
	callback	local	fptr.far	\
			push	ds, dx
	callbackData	local	word		\
			push	si
	portDataBlock	local	hptr		
	.enter
	mov	ax, portToken
	call	VerifyAndGetPortStructExcl
	mov	portDataBlock, ax
	mov	ax, NET_ERR_INVALID_PORT_TOKEN
	jc	exit
	;
	; here, we have a valid port in ds:di
	;
	mov	ax, socketID
	mov	si, ds:[di].PS_socketArray	;*ds:si - Socket ChunkArray
	mov	bx, segment FindSocketIDCallBack
	mov	di, offset FindSocketIDCallBack
	call	ChunkArrayEnum			; see if socket exists for ID
	jnc	socketOK
EC< 	WARNING	DUPLICATE_SOCKET_ID		>
	mov	ax, NET_ERR_SOCKET_ID_IN_USE
	stc					;carry <- error
	jmp	exit

	;
	; here, we have a good port and a socket ID.
	;  so create the ChunkArrayElement
	;
socketOK:
	mov	bx, cs
	mov	di, offset cs:FindUnusedSocketCallBack
	call	ChunkArrayEnum
	mov	di, dx				;ds:di - SocketStruct
	jc	initSocketStruct		;branch if no deleted sockets

	;
	; here, we have to init the socket ourselves...
	;

	call	ChunkArrayAppend		;ds may change
initSocketStruct:
	MOVW	ds:[di].SS_socketID, socketID, ax
	MOVW	ds:[di].SS_destID, destID, ax
	MOVW	ds:[di].SS_portNum, portToken, ax
	movdw	ds:[di].SS_callback, callback, ax
	MOVW	ds:[di].SS_cbData, callbackData, ax
	mov	ds:[di].SS_timeOut, INIT_TIME_OUT_VALUE
	call	ChunkArrayPtrToElement	; ax - element # = socket token
	clc
EC<	WARNING	SOCKET_OPENED			>
exit:
	mov	bx, portDataBlock
	call	MemUnlockExcl
	.leave
	ret
CommCreateSocket	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindUnusedSocketCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tries to find an unused socket

CALLED BY:	ChunkArrayEnum
PASS:		ds:di - array element
RETURN:		carry set if match, dx - offset to element
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindUnusedSocketCallBack	proc	far
	mov	dx, di
	cmp	ds:[di].SS_portNum, DELETED_SOCKET_NUMBER
	stc
	jz	exit
	clc
exit:
	ret
FindUnusedSocketCallBack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommDestroySocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a socket

CALLED BY:	CommMessaging() (DR_NET_MESSAGING)
PASS:		bx - port token
		dx - socket token
RETURN:		carry - set if error
			ax - NetDriverError
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommDestroySocket	proc	far
	uses	bx,cx,ds,di
	.enter

	call	FindSocket
	jc	exit				;branch if error
	;
	; Delete the socket entry
	;
	push	bx
	mov	ds:[di].SS_portNum, DELETED_SOCKET_NUMBER
	clr	ds:[di].SS_socketID
	clr	ds:[di].SS_destID
	movdw	bxax, ds:[di].SS_callback
.assert	SOCKET_DESTROYED	eq 0
	clr	cx			;cx <- tell socket we're closing
	call	ProcCallFixedOrMovable
EC<	WARNING	SOCKET_WAS_DESTROYED	>
	pop	bx

	;
	; Done with the socket array
	;
	call	MemUnlockExcl
exit:

	.leave
	ret
CommDestroySocket	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommSetTimeOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the time out value for a socket

CALLED BY:	GLOBAL
PASS:		bx - port token
		dx - socket token
		cx - timeout value (in 1/60 sec)
RETURN:		carry - set if error
			ax - NetDriverError

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommSetTimeOut	proc	far
	uses	bx, ds, di
	.enter

	mov	ax, bx				;ax <- port token
	mov	bx, dx				;bx <- socket token
	;
	; Find the port
	;
	call	VerifyAndGetPortStructExcl
	push	ax
	mov	ax, NET_ERR_INVALID_PORT_TOKEN
	jc	done

	;
	; Adjust the port's maxTimeout if timeout being set is larger than
	; previous max.
	; 
	cmp	cx, ds:[di].PS_maxTimeout
	jbe	findSocket
	mov	ds:[di].PS_maxTimeout, cx

findSocket:
	;
	; Now find the socket structure so we can set the timeout there.
	;
	call	VerifyAndGetSocketStruct
	mov	ax, NET_ERR_INVALID_SOCKET_TOKEN
	jc	done

	mov	ds:[di].SS_timeOut, cx		;set timeout
done:
	pop	bx
	call	MemUnlockExcl

	.leave
	ret

CommSetTimeOut	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the the specified socket

CALLED BY:	CommDestroySocket(), CommSetTimeOut()
PASS:		bx - port token
		dx - socket token
RETURN:		carry - set if error
			ax - NetDriverError
		else:
			ds:di - ptr to SocketStruct
			bx - handle of socket/port array
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/28/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindSocket		proc	near
	.enter

	mov	ax, bx				;ax <- port token
	mov	bx, dx				;bx <- socket token
	;
	; Find the port
	;
	call	VerifyAndGetPortStructExcl
	push	ax
	mov	ax, NET_ERR_INVALID_PORT_TOKEN
	jc	exitError

	;
	; Find the socket on the port
	;
	call	VerifyAndGetSocketStruct
	mov	ax, NET_ERR_INVALID_SOCKET_TOKEN
	jc	exitError
	pop	bx			;BX <- handle of block
done:
	.leave
	ret

exitError:
	pop	bx
	call	MemUnlockExcl
	jmp	done
FindSocket		endp

InitExitCode	ends
