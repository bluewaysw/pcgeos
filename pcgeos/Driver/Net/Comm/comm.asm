COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Serial Communication Driver
FILE:		Comm.asm

AUTHOR:		In Sik Rhee  7/92

ROUTINES:
	Name			Description
	----			-----------
	CommStrategy		Strategy Function
*	CommInit		DR_INIT (Entry Point to Driver)
*	CommExit		DR_EXIT (De-initialization)
	ClosePortCallBack	close given port
*	CommDoNothing		pass
*	CommOpenPort		open port for use
	FindPortCallBack	look up port
	FindDeletedPortCallBack	look up unused port
*	CommClosePort		close port
*	CommCreateSocket	open a socket under a port
	FindSocketIDCallBack	match socket ID with existing one
	FindUnusedSocketCallBack look up unused socket
*	CommDestroySocket	close socket
*	CommCallService		make a call across the connection
*	CommSetTimeOut		set time out value for a socket
	DeleteOrTimeOut		process Delete or TimeOut
	CommServerLoop		server process thread

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	7/28/92		Getting started


DESCRIPTION:

	$Id: comm.asm,v 1.1 97/04/18 11:48:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

NetDriverProcs	nptr.near	\
		Resident:CommInitStub,
		Resident:CommExitStub,
		Resident:CommSuspendUnsuspend,	;DR_SUSPEND
		Resident:CommSuspendUnsuspend,	;DR_UNSUSPEND
		Resident:CommDoNothing,	;userfunction
		Resident:CommDoNothing,	;initHECB
		Resident:CommDoNothing,	;sendHECB
		Resident:CommDoNothing,	;semaphore
		Resident:CommDoNothing,	;getdefconnectionID
		Resident:CommDoNothing,	;getservernametable
		Resident:CommDoNothing,	;getconnectionIDtable
		Resident:CommDoNothing,	;scanforserver
		Resident:CommDoNothing,	;serverattach
		Resident:CommDoNothing,	;serverlogin
		Resident:CommDoNothing,	;serverlogout
		Resident:CommDoNothing,	;changeuserpswd
		Resident:CommDoNothing,	;serververifypswd
		Resident:CommDoNothing, ;mapdrive
		Resident:CommDoNothing, ;servergetnetaddr
		Resident:CommDoNothing, ;servergetWSnetaddr
		Resident:CommMessaging, ; our stuff 
		Resident:CommDoNothing,	;DR_NET_PRINT_FUNCTION
		Resident:CommDoNothing,	;DR_NET_OBJECT_FUNCTION
		Resident:CommDoNothing, ;DR_NET_TEXT_MESSAGE_FUNCTION
		Resident:CommDoNothing,	;DR_NET_GET_VOLUME_NAME
		Resident:CommDoNothing,	;DR_NET_GET_DRIVE_CURRENT_PATH
		Resident:CommDoNothing,	;DR_NET_GET_STATION_ADDRESS
		Resident:CommDoNothing	;DR_NET_UNMAP_DRIVE

.assert	(size NetDriverProcs	eq NetDriverFunction)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommStrategy
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
	ISR	7/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommStrategy	proc	far
	uses	ds,es
	.enter
	;check the function code

	cmp	di, NetDriverFunction
	jae	badCall

	;seems ok. Some more EC:

EC <	test	di, 1							>
EC <	ERROR_NZ NET_ERR_INVALID_DRIVER_FUNCTION			>


	;call the function:
	call	cs:[NetDriverProcs][di]
	jmp 	exit

badCall: ;Error: function code is illegal.

EC <	ERROR	NET_ERR_INVALID_DRIVER_FUNCTION			>

NEC<	stc							>
exit:	.leave
	ret
CommStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommInitStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point into Driver. (DR_INIT)

CALLED BY:	Kernel
PASS:		nothing
RETURN:		carry - set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	initialize LMem Block 
	create Port chunkarray 

NOTE:	LMEM Block contains 1 port chunkarray and multiple socket chunkarrays
	each entry in the port chunkarray points to a socket chunkarray 
	structure...  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommInitStub	proc	near
	.enter

	call	CommInit

	.leave
	ret
CommInitStub	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommExitStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	De-initialization routines (DR_EXIT)

CALLED BY:	KERNEL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Close any ports still left open
	Kill LMem Block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommExitStub	proc	near
	call	CommExit
	ret
CommExitStub	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do Nothing, return carry set

CALLED BY:	Global
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommDoNothing	proc	near
EC <	WARNING	COMM_UNSUPPORTED_FUNCTION	>
	mov	ax, NET_ERROR_UNSUPPORTED_FUNCTION
	stc
	ret
CommDoNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommSuspendUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry clear so suspension can continue.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/17/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommSuspendUnsuspend	proc	near
	.enter
	clc
	.leave
	ret
CommSuspendUnsuspend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommMessaging
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point into messaging services

CALLED BY:	GLOBAL
PASS:		al - NetMessagingFunction
		other arguments as needed by all routines
RETURN:		variable
DESTROYED:	?
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/30/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommMessaging	proc	near
	clr	ah
	mov_tr	di, ax
EC <	cmp	di, NetMessagingFunction	>
EC <	ERROR_AE ERROR_COMM_INVALID_FUNCTION	>
	call	cs:[NetMessagingProcs][di]
	ret	
CommMessaging	endp

NetMessagingProcs	nptr.near	\
		CommOpenPortStub,
		CommClosePortStub,
		CommCreateSocketStub,
		CommDestroySocketStub,
		CommCallServiceStub,
		CommSetTimeOutStub

.assert	(size NetMessagingProcs	eq NetMessagingFunction)
DefStub	macro	rname
rname&Stub	proc	near
	call	&rname
	ret
rname&Stub	endp
endm

DefStub	CommOpenPort
DefStub CommClosePort
DefStub CommCreateSocket
DefStub CommDestroySocket
DefStub CommCallService
DefStub CommSetTimeOut

Resident	ends

Send	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommCallService
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a buffer across the port/socket.

CALLED BY:	GLOBAL
PASS:		bx - port token
		dx - socket token
		cx - size of buffer
		bp - extra data
		ds:si - buffer
RETURN:		carry set if error, ax - error code
		otherwise successful xmit.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	verify port/socket
	take buffer, break into packet-sized chunks, and send.
	return reply code

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommCallService	proc	far
	uses	bx,cx,dx,si
	.enter
FXIP <	push	bx							>
FXIP <	mov	bx, ds				; bx:si = buffer	>
FXIP <	call	ECAssertValidFarPointerXIP				>
FXIP <  pop	bx							>

EC <	call	ECCheckBounds						>
EC <	push	si							>
EC <	add	si, cx							>
EC <	dec	si							>
EC <	call	ECCheckBounds						>
EC <	pop	si							>
	mov	ax, bx
	mov 	bx, dx
	mov	dx, bp			;dx - extra data
	sub	sp, size StreamVars	; set up local variables
	mov	bp,sp			; ss:bp - StreamVars
	movdw	ss:[bp].SV_data, dssi
	call	VerifyAndGetPortStruct
	push	ax
	mov	ax, NET_ERR_INVALID_PORT_TOKEN
LONG	jc	invalidPortSocket
	;
	; valid port in ds:di
	;
	mov	ss:[bp].SV_extraData, dx
	MOVW	ss:[bp].SV_sendSem, ds:[di].PS_sendSem, ax
	MOVW	ss:[bp].SV_sendPacketSem, ds:[di].PS_sendPacketSem, ax
	MOVW	ss:[bp].SV_ackSem, ds:[di].PS_ackSem, ax
	movdw	ss:[bp].SV_serDrvr, ds:[di].PS_serDrvr, ax
	MOVW	ss:[bp].SV_strToken, ds:[di].PS_strToken, ax
	MOVW	ss:[bp].SV_packetID, ds:[di].PS_packetID, ax
	call	VerifyAndGetSocketStruct
	mov	ax, NET_ERR_INVALID_SOCKET_TOKEN
LONG	jc	invalidPortSocket
	MOVW	ss:[bp].SV_destID, ds:[di].SS_destID, ax
	MOVW	ss:[bp].SV_timeOut, ds:[di].SS_timeOut, ax
EC <	call	ECCommCheckStreamVars					>
	;
	; copied all data from ChunkArray so unlock the memory
	;
	pop	bx
	call	MemUnlockShared

	;
	; lock send semaphore
	;
EC <	call	ECCommCheckStreamVars					>
	mov	bx, ss:[bp].SV_sendSem
	call	ThreadPSem

;	If we've never sent a packet out of this port, then synchronize the
;	port IDs by sending a packet with an ID of 0

	mov	dx,cx			; buffer size
	segmov	es, dgroup, bx
	mov	bx, ss:[bp].SV_packetID
	mov	bl, es:[packetIDout][bx]

	tst	bl			;If the ID is not zero, branch.
	jnz	sendData

;	Synchronize the port by sending an empty packet with the 0 ID. This
;	packet will be eaten by SlipReceive on the remote machine.	

EC <	WARNING	SYNCHRONIZING_PORT				>

	clr	cx
	mov	ss:[bp].SV_header.PH_strLen, cx
	mov	ss:[bp].SV_header.PH_type, SINGLE_PACKET
	clr	di
	call	SlipSend
	LONG jc	sendError

sendData:

;	Now send the data to the remote machine.
;	If the data is < MAX_PACKET_SIZE bytes, just send the data off in
;	one packet.
;
;	Else, send the first packet off with a START_PACKET, send intermediate
;	packets off with type = MID_PACKET, then send the last packet off with
;	type = END_PACKET.
;

	mov	ax,dx			;AX,BX - # bytes to send
	mov	cx, MAX_PACKET_SIZE	; default packet size
	mov	ss:[bp].SV_header.PH_strLen, ax
	mov	ss:[bp].SV_header.PH_type, SINGLE_PACKET
	cmp	ax, MAX_PACKET_SIZE
	jbe	singlePacket

;	We have a multi-packet buffer to send.

	mov	ss:[bp].SV_header.PH_type, START_PACKET
streamLoop:
;
;	AX <- # bytes to send
;

	cmp	ax, MAX_PACKET_SIZE	; do we have enough space?
	jbe	endPacket		; yes, send end packet
	mov	cx, MAX_PACKET_SIZE
	push	ax			;Save bytes left to send
	clr	di
	call	SlipSend		; send packet
	mov	ss:[bp].SV_header.PH_type, MID_PACKET
	pop	cx			;CX <- # bytes left to send
EC <	WARNING_C	ERROR_IN_MIDDLE_OF_STREAM			>
	jc	sendError

	mov_tr	ax, cx
	sub	ax, MAX_PACKET_SIZE	; decrement size counter
EC <	ERROR_C	-1							>
		;Update ptr to next packet of data to send
	add	ss:[bp].SV_data.offset, MAX_PACKET_SIZE
	jmp	streamLoop

endPacket:
	mov	ss:[bp].SV_header.PH_type, END_PACKET
singlePacket:
;
;	AX - packet size
;
	mov	cx,ax			; packet size
	call	SlipSend		; send last packet
	jc	sendError

EC <	call	ECCommCheckStreamVars					>
	mov	bx, ss:[bp].SV_sendSem
	call	ThreadVSem
	add	sp, size StreamVars	; restore stack pointer (clears carry)
EC <	ERROR_C	-1							>
exit:
	.leave
	ret

invalidPortSocket:
	pop	bx
	call	MemUnlockShared
	jmp	error

sendError:

EC <	call	ECCommCheckStreamVars					>
	mov	bx, ss:[bp].SV_sendSem
	call	ThreadVSem
error:
	add	sp, size StreamVars
	stc
	jmp	exit

CommCallService	endp
Send	ends

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommServerLoop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Server Process - handles all incoming messages

CALLED BY:	CommOpenPort
PASS:		cx - port token
RETURN:		nothing
DESTROYED:	variable

PSEUDO CODE/STRATEGY:
	Get 1st buffer - extract stream header
	if END_PACKET then send buffer up.
	otherwise, create buffer, size specified by stream header, 
	Loop:
		Get buffer from SlipReceive
		concat at end of our buffer.
		Free packet buffer
	Until END_PACKET  
	then we send the buffer to our callback routine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	4/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommServerLoop	proc	far

	sub	sp, size ServerStruct
	mov	bp,sp			; ss:bp - ServerStruct
	mov	ss:[bp].SE_portToken, cx
	mov_tr	ax, cx
	call	VerifyAndGetPortStruct
	mov	bx, ax			;bx <- handle of port list block
EC <	ERROR_C	PORT_DELETED_BEFORE_THREAD_EXITED		>
	;
	; Copy the info we're interested in from the PortStruct into
	; our ServerStruct / local vars.
	;
	movdw	ss:[bp].SE_serDrvr, ds:[di].PS_serDrvr, ax
	MOVW	ss:[bp].SE_ackQueue, ds:[di].PS_exitAckQueue, ax
	MOVW	ss:[bp].SE_strToken, ds:[di].PS_strToken, ax
	MOVW	ss:[bp].SE_ackSem, ds:[di].PS_ackSem, ax
	MOVW	ss:[bp].SE_sendPacketSem, ds:[di].PS_sendPacketSem, ax
	MOVW	ss:[bp].SE_socketArray, ds:[di].PS_socketArray, ax
	MOVW	ss:[bp].SE_packetID, ds:[di].PS_packetID, ax
	mov	ss:[bp].SE_packetCount, 0
	mov	ss:[bp].SE_okPacketCount, 0

	movdw	ds:[di].PS_serverPtr, ssbp

EC<	call	ECCheckLMemHandle	>
	call	MemUnlockShared
EC <	call	ECCommCheckServerStruct >
	;
	; Loop to get packets
	;
packetLoop:
	;
	; get 1st packet
	;
	call	SlipReceive
	jc	exit

	call	HandleNewPacket
	jnc	packetLoop
exit:
	mov	dx, ss:[bp].SE_ackQueue
;;; Not necessary, since we are not returning.
;;;	add	sp, (size ServerStruct)	; restore stack pointer
	;
	; NOTE: the call to ThreadDestroy() must be in fixed code and
	; not have been called to from a movable resource, or the
	; resource will not get unlocked since this will not return.
	;
	clr	cx
	clr	bp
	jmp	ThreadDestroy				; suicide

CommServerLoop	endp

Resident	ends

Receive	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallSocketsWithHeartbeat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the callback routines of all the sockets with 
		cx = SOCKET_HEARTBEAT

CALLED BY:	GLOBAL
PASS:		ss:bp - ServerStruct
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallSocketsWithHeartbeat	proc	near	
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter
	segmov	ds,dgroup,ax
	mov	bx, ds:[lmemBlockHandle]
EC<	call	ECCheckMemHandle	>
	call	MemLockShared
	mov	ds, ax
	push	bx, bp
	mov	si, ss:[bp].SE_socketArray	;*ds:si - socket array
	mov	cx, ss:[bp].SE_portToken	;CX <- port token to match
	mov	bx, cs
	mov	di, offset CallSocketWithHeartbeatCallback
	call	ChunkArrayEnum			; ds:di - socket element
	pop	bx, bp
	call	MemUnlockShared
	.leave
	ret
CallSocketsWithHeartbeat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallSocketWithHeartbeatCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the passed socket is attached to the passed port, then
		make a heartbeat call to its callback routine, to let it know
		that the connection is still alive and kicking.

CALLED BY:	GLOBAL
PASS:		ds:di - SocketStruct
		cx - port token
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallSocketWithHeartbeatCallback	proc	far	uses	cx
	.enter
	cmp	cx, ds:[di].SS_portNum
	jne	exit
	movdw	bxax, ds:[di].SS_callback
	mov	cx, SOCKET_HEARTBEAT
	call	ProcCallFixedOrMovable
exit:
	clc
	.leave
	ret
CallSocketWithHeartbeatCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNewPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Processes the data packet that has just been loaded in.

CALLED BY:	GLOBAL
PASS:		ds - segment of packet
		ss:bp - ServerStruct
		cx - socket token
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleNewPacket	proc	far
	.enter
	;
	; Circumvent segment EC in CallSocketsWithHeartbeat
	;
EC <	segmov	es, ds							>
	
	call	CallSocketsWithHeartbeat

processPacket:	

	;
	; Set up pointers and save the size
	;
	segmov	es, ds
	mov	ax, ds:[PH_strLen]
	mov	ss:[bp].SE_size, ax
	mov	si, offset PH_data		; ds:si - src buffer (packet)
	mov	dx, si				; es:dx - src buffer (stream)


EC <	cmp	ds:[PH_type], SINGLE_PACKET				>
EC <	jne	10$							>
EC <	cmp	ax, MAX_PACKET_SIZE					>
EC <	ERROR_A	PACKET_TOO_LARGE					>
EC <	cmp	ax, ds:[PH_dataLen]					>
EC <	ERROR_NE SINGLE_PACKET_DATA_LEN_MUST_MATCH_STREAM_DATA_LEN	>
EC <10$:								>

	;
	; SINGLE_PACKET means it's the only packet in the stream
	;
	mov	bx, ds:[PH_extraData]
	cmp	ds:[PH_type], SINGLE_PACKET
	LONG je 	sendStream

	;If it isn't a SINGLE_PACKET, then it must be a START_PACKET (the
	; start of a muli-packet stream). If it isn't, then we've gotten out
	; of synch (possibly due to a timeout on our side) so drop this packet
	; on the floor).

	cmp	ds:[PH_type], START_PACKET
	LONG jne	freePacket
	;
	; here, buffer is multiple-packet... allocate buffer and copy packets 
	;
	mov	cx, (((mask HAF_LOCK) or (mask HAF_NO_ERR)) shl 8) or \
			mask HF_SHARABLE
	mov	bx, handle 0
	call	MemAllocSetOwner
	mov	es,ax
	clr	di			; es:di - dest buffer
copyLoop:
	mov	si, offset PH_data	; skip header
	mov	cx, ds:[PH_dataLen]	; size to copy
EC <	cmp	cx, MAX_PACKET_SIZE					>
EC <	ERROR_NE	INTERMEDIATE_PACKET_BAD_SIZE			>

EC <	push	di							>
EC <	add	di, cx							>
EC <	cmp	di, ds:[PH_strLen]					>
EC <	pop	di							>
EC <	ERROR_AE	TOO_MANY_BYTES_RECEIVED				>

	call	strncpy			; copy buffers!
	add	di,cx			; increment dest pointer

	mov	cx,ds
	call	MemSegmentToHandle
	mov	bx,cx
	call	MemFree			; free packet buffer

	call	SlipReceive		; next packet!
	LONG	jc	exit

	call	CallSocketsWithHeartbeat

;	If the next packet we've received is not a MID or END packet, then
;	there was some error on the other side sending that stream, so we
;	need to nuke the data we were building out, and process this new
;	stream.

	cmp	ds:[PH_type], END_PACKET				
	je	endOfStream

	cmp	ds:[PH_type],MID_PACKET
	je	copyLoop


;	Nuke the packet we were building out, and branch back up to process
;	the new packet.

EC <	WARNING_NZ	BAD_PACKET_IN_MIDDLE_OF_STREAM			>


	push	cx			;Save socket ID
	mov	cx, es
	call	MemSegmentToHandle	;
	mov	bx, cx
	call	MemFree			;Free up the old block
	pop	cx			;Restore socket ID
	jmp	processPacket

endOfStream:
	;
	; Last packet -- copy it to our buffer and free the packet
	;
	push	cx			; socket token
	mov	cx,ds
	call	MemSegmentToHandle
	mov	bx,cx
	mov	dx, ds:[PH_extraData]
	mov	cx, ds:[PH_dataLen]
	call	strncpy
	call	MemFree			; free packet buffer
	mov	bx, dx			;BX <- extra data
	clr	dx			; es:dx - buffer
	pop	cx			; socket token

sendStream:
	;
	; pass data to callback routine
	; es:dx - buffer, cx - socket token, bx - extra data
	;
	mov	si, dx				;ES:SI <- buffer	
	mov	dx, bx				;DX <- extra data

EC <	push	si							>
EC <	segmov	ds, es							>
EC <	add	si, ss:[bp].SE_size					>
EC <	dec	si							>
EC <	call	ECCheckBounds						>
EC <	pop	si							>

	;
	; Find the appropriate socket
	;
	segmov	ds,dgroup,ax
	mov	bx, ds:[lmemBlockHandle]
EC<	call	ECCheckMemHandle					>
	call	MemLockShared
	mov	ds, ax

	push	si
	mov	si, ss:[bp].SE_socketArray	;*ds:si - socket array
	mov_tr	ax, cx				;AX <- index of socket
	call	ChunkArrayElementToPtr		; ds:di - socket element
	pop	si

;	If the socket was deleted between the time the packet came in and when
;	we went to call the callback, then just delete the data

	jc	unlockFreePacket

	cmp	ds:[di].SS_portNum, DELETED_SOCKET_NUMBER
	je	unlockFreePacket
	movdw	bxax, ds:[di].SS_callback	;bx:ax <- callback
	mov	di, ds:[di].SS_cbData

	;
	; Call the callback routine
	;
	segmov	ds, es				;DS:SI <- data
	mov	cx, ss:[bp].SE_size		;cx <- size
	push	es
	call	ProcCallFixedOrMovable
	pop	es

unlockFreePacket:
	segmov	ds, dgroup, bx			;Unlock the block *after* 
	mov	bx, ds:[lmemBlockHandle]	; calling the callback, to
	call	MemUnlockShared			; ensure that the socket
						; does not get destroyed.

freePacket:
	;
	; Free the input stream and loop for more packets
	;
	mov	cx, es
	call	MemSegmentToHandle
EC <	ERROR_NC	-1						>
	mov	bx, cx				;bx <- handle of input stream
	call	MemFree				; free our input stream
	clc
exit:	
	.leave
	ret
HandleNewPacket	endp

Receive	ends
