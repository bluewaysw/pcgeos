COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		TCP/IP Driver
FILE:		tcpipSocket.asm

AUTHOR:		Jennifer Wu, Jul  8, 1994

ROUTINES:
	Name			Description
	----			-----------
EXTERNAL:	
	TSocketGetInfoBlock	Get the socket block handle (INTERNAL)
	TSocketLockInfoShared	Gain access to socket info block
	TSocketLockInfoExcl	
	TSocketUnlockInfoShared	Release access to socket info
	TSocketUnlockInfoExcl	
	TSocketLockInfoList	Gain access to socket info list (INTERNAL)

	TSocketCreateSocketList	Create the socket list used to keep track
				of all existing connections
	TSocketGetNumSockets	Get the number of existing connections
	TSocketWakeupWaiter	Wakeup a waiter for a socket connection
	TSocketFindHandle	Find the entry for the given connection
				handle in the socket list
	TSocketCheckDuplicate	Same as SocketFindConnection but returns
				error instead of connection handle.
	TSocketFindConnection	Find the connection in the list with the
				specified local port, remote port and 
				remote address
	TSocketFindOpenConnection
				Same as find connection but also checks 
				that port is open				
	TSocketFindSocketOfDomain
				Check if a connection of the given domain
				type exists.
	TSocketCreateConnection	Create a new TCP connection (no info)
	TSocketStoreConnectionInfo

	TSocketDestroyAllConnections
	TSocketDestroyConnection	Destroy a TCP connection

	TSocketNewOutputData	Add the new data to the output queue for
				the connection
	TSocketSetStateAndGetSem
 				Set the socket state as specified and get
				the connection's semaphore handle

	TSocketCheckIfConnected
				Check the state of a connecting socket to
				determine if the connection has been 
				successfully established

	TSocketCheckLinkBusy	Check if there are any connections on the 
				specified link
	TSocketResetConnectionsOnLink
				Reset all connections on the specified link

	TSocketToTCB		Get the TCB for the specified socket
	TSocketDoError		Process an error for all sockets connected
				to a given address
	TSocketIsConnected	Connection was established by TCP protocol
	TSocketIsConnectedLink
	TSocketIsDisconnected	Connection was terminated by TCP protocol
	TSocketIsDisconnectedData
	TSocketIsDisconnectedLink
	TSocketIsDead		Checks whether a connection is dead
	TSocketGetInfo		Return the addresses and ports for a 
				connection
	TSocketGetLink		Return the link domain handle for this socket
	TSocketGetRecvWin	Return the available space in the socket 
				library's receive buffer for this connection
	TSocketTimeoutHandler	Decrement timers in all connections
	TSocketRecvInput	Pass input data to the socket library
	TSocketProcessConnectRequest
				Handle incoming connect request from 
				remote
	TSocketDropAckedData	Drop the sent data which has been acked
	TSocketHasUrgentData	Inform socket library urgent data exists
	TSocketGetOutputSize	Return the total amount of output data	
				for the socket
	TSocketGetOutputData	Copy specified amount of output data 
				to the passed buffer
	TSocketRecvUdpInput	Deliver udp input to socket library.
	TSocketRecvRawInput	Deliver raw input to raw ip client.
	TSocketNotifyError	Notify socket library of error for UDP.

INTERNAL:	
	TSocketEnumConnections	Use ChunkArrayEnum with the given callback.
	TSocketSetHeaderAndDeliver	
				Fill in domain and flags in PacketHeader
				and deliver to client.
	TSocketCopyOutputData	Do the actual copying of the data
	TSocketGetConnectionDomain
	TSocketLoadSocketLibrary Load and register socket library
	TSocketRegisterSocketLibrary
	TSocketFindHandleCB	Callback routine for TSocketFindHandle
				to compare connectino handle with entry
	TSocketFindConnectionCB	Callback routine for SocketFindConnection
				to do the comparison for an entry
	TSocketFindSocketOfDomainCB
				TSocketFindSocketOfDomain's callback
	TSocketCheckLinkBusyCB	TSocketCheckLinkBusy's callback
	TSocketCreateOutputQueue Create the output queue and initialize
				the header
	TSocketCreateInputQueue	Create input queue for TCP link connections.
	TSocketCreateQueue	Create a queue with the given headers.
	TSocketCreateTCB	Allocate space for the TCB
	TSocketDestroyOutputQueue	
				Destroy the output queue, freeing any buffers
				still in it
	TSocketDestroyOutputQueueCB 
				Callback routine for TSocketDestroyOutputQueue
				to free each data buffer
	TSocketDestroyInputQueue Destroy input queue for TCP link connections.
	TSocketDestroyTCB	Free the chunk for the TCB
	TSocketDoErrorCB	Callback for TSocketDoError
	TSocketDestructTimeoutCB Destroy a dead connection if the destruct 
				timer expires
	TSocketDestroy

	TSocketDropAckedDataCB	Drop specific amount of data that has been
				sent
	TSocketDropData		Drop data from a buffer, freeing it if no	
				data is left
	TSocketMarkPacketBoundary
				Add a 2-byte size to the data for use
				in preserving packet boundaries.
	TSocketRecvLinkInput
				Restore packet boundaries to input data
				before delivering to client.
				
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/ 8/94		Initial revision

DESCRIPTION:
	Code related to sockets in TCP/IP driver.	

	$Id: tcpipSocket.asm,v 1.1 97/04/18 11:57:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TSOCKETCODE	segment	public 'CODE'


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketGetInfoBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the handle of the socket information block or the 
		chunk handle of the list.

CALLED BY:	Internal

PASS:		nothing

RETURN:		bx	= block handle of socket information list 

DESTROYED:	DS (set to dgroup)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/27/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketGetInfoBlock	proc	near
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[socketBlock]
		Assert	lmem bx				
		ret
TSocketGetInfoBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketLockInfoShared/Excl, TSocketUnlockInfoShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain access to socket information for reading by using 
		TSocketLockInfoShared.  If writing, MUST use 
		TSocketLockInfoExcl.  

		Unlock the socket information block.  Unlocking shared
		is the same as unlocking exclusive since MemUnlockExcl
		equals MemUnlockShared.

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		if locking, 		
			ds	= segment of information block 
		else nothing

DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 8/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TSocketLockInfoShared	proc	far
		uses	ax, bx
		.enter
		pushf
		
		call	TSocketGetInfoBlock		; ^hbx = socket block 
		call	MemLockShared
		mov	ds, ax
		Assert	segment	ds						
		
		popf
		.leave
		ret
TSocketLockInfoShared	endp


TSocketLockInfoExcl	proc	far
		uses	ax, bx
		.enter
		pushf
		
		call	TSocketGetInfoBlock		; ^hbx = socket block
 		call	MemLockExcl
		mov	ds, ax
		Assert	segment	ds						
		
		popf
		.leave
		ret
TSocketLockInfoExcl	endp

TSocketUnlockInfoShared	proc	far
		uses	bx, ds
		.enter
		pushf
		
		call	TSocketGetInfoBlock		; ^hbx = socket block
		call	MemUnlockShared
		
		popf
		.leave
		ret
TSocketUnlockInfoShared	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketLockInfoList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the socket info list.

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		*ds:si = socket list

DESTROYED:	bx  (usually not used by caller...)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/27/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketLockInfoListFar	proc	far
		call	TSocketLockInfoList
		ret
TSocketLockInfoListFar	endp

TSocketLockInfoList	proc	near
		uses	ax
		.enter
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[socketBlock]		
		mov	si, ds:[socketList]
		call	MemLockExcl
		mov	ds, ax
		.leave
		ret		
TSocketLockInfoList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCreateSocketList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the socket list used to keep track of all existing
		connections.

CALLED BY:	TcpipInit

PASS:		nothing

RETURN:		carry set if could not create socket list
		else clear if successful

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Alloc the LMem block for all socket info
		Create the chunk array
		Store the LMem block handle and the chunk handle to 
			the chunk array in dgroup

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 8/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCreateSocketList	proc	far
		uses	bx, cx, ds
		.enter

		mov	bx, size TcpSocketElt
		clr	cx			; default header
		call	TSocketCreateQueue	; ^lbx:cx = socket list
		jc	exit
	;
	; Save the block handle and chunk handle to the list.
	;		
		push	bx
		mov	bx, handle dgroup
		call	MemDerefDS
		pop	bx
		mov	ds:[socketBlock], bx
		mov	ds:[socketList], cx
		clc
exit:		
		.leave
		ret
TSocketCreateSocketList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketGetNumSockets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of existing connections.

CALLED BY: 	TcpipSuspend
		TcpipUnregister
		LinkOpenConnection
		TcpipLinkClosed
		EC: TcpipExit

PASS:		nothing

RETURN:		cx	= # of connections

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Find out how many entries are in the socket list
NOTE:
		Socket info block must not be locked exclusively by 
		caller when this is called or deadlock will result.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 8/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketGetNumSockets	proc	far
		uses	bx, si, ds
		.enter

		call	TSocketLockInfoList		; *ds:si = socket list
							; (bx destroyed)
		call	ChunkArrayGetCount		; cx = # connections
		call	TSocketUnlockInfoExcl

		.leave
		ret
TSocketGetNumSockets	endp

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketWakeWaiter

C DECLARATION:	extern word _far
		_far _pascal TSocketWakeWaiter(dword tcpSocket, word code);


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETWAKEWAITER	proc	far	tcpSocket:fptr.TcpSocket,
					code:word
		uses	si, ds
		.enter

		mov	ax, code
		movdw	dssi, tcpSocket
		call	TSocketWakeupWaiter
		
		.leave
		ret
TSOCKETWAKEWAITER	endp
	SetDefaultConvention	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketWakeupWaiter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wake up a waiter on this socket connection.

CALLED BY:	TSOCKETWAKEWAITER

PASS:		ax	= SocketDrError
			(will be stored in TS_error to be found by waiter)
		ds:si	= TcpSocket

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Store the SocketDrError in TS_error
		V the semaphore, zeroing out TS_sem

NOTES:
		Socket info block is already locked by caller

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketWakeupWaiter	proc	far
		uses	bx
		.enter
	;
	; Store error and V the semaphore if the waiter exists.
	; The timed semaphore may have expired and the waiter with it.
	;
		mov	ds:[si].TS_error, ax

		mov	al, TCPIP_NO_WAITER
		xchg	al, ds:[si].TS_waiter			
		cmp	al, TCPIP_NO_WAITER
		je	exit

		mov	ds:[si].TS_waiter, TCPIP_NO_WAITER
		mov	bx, ds:[si].TS_sem

		call	ThreadVSem
exit:
		.leave
		ret
TSocketWakeupWaiter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketFindHandle/TSocketFindHandleNoLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the entry for the given connection handle in the
		socket list.

CALLED BY: 	TcpipStopDataConnect (no lock version)
		TcpipDisconnectRequest
		TcpipSendData
		TcpipStopSendData
		TcpipAttach
		TcpipReject
		TcpipQueueSendDataRequest (no lock version)
		TSocketDestroyConnection (no lock version)
		TSocketNewOutputData (no lock version)
 		EC: TcpipResetRequest
		EC: TcpipGetAddrCommon
		EC: TcpipSetOption
		EC: TcpipGetOption
		EC: TSOCKETTOTCB
		EC: TSocketStoreConnectionInfo
		EC: TcpipDataConnectRequest

PASS:		ax	= connection handle
		TSocketFindHandleNoLock also requires:
		*ds:si  = socket info list 

RETURN:		carry clear if found
		cx	= entry in list		
		else carry set if handle is not found
		cx = garbage


DESTROYED:	nothing (No lock version destroys BX)

PSEUDO CODE/STRATEGY:
		Go through elements in list looking for one with the
		given connection handle.

NOTES:
		Socket info block must not be locked when this is called.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketFindHandle	proc	far
		uses	bx, si, ds
		.enter
		call	TSocketLockInfoList		; *ds:si = socket list
		call	TSocketFindHandleNoLock
		call	TSocketUnlockInfoExcl
		.leave
		ret
TSocketFindHandle	endp

TSocketFindHandleNoLock	proc	far
		uses	di
		.enter

		mov	di, offset TSocketFindHandleCB
		mov	bx, cs
		call	ChunkArrayEnum			; carry set if found
							; cx = elt # of match
		cmc					

		.leave
		ret
TSocketFindHandleNoLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCheckDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the connection with the specified local port,
		remote port and remote address.  

CALLED BY:	TSocketCheckDuplicate:
			TcpipDataConnectRequest

PASS:		disi	= remote IPAddr
		dx	= remote port number  
		bp	= local port number   

RETURN:		carry set if connection exists
		ax = SDE_CONNECTION_EXISTS
		else carry clear

DESTROYED:	ax if not returned

PSEUDO CODE/STRATEGY:
		For each existing connection, compare the local port,
		remote port and remote address.  If all three match,
		then the connection exists.  Stop after first match.

		TSocketCheckDuplicate:
			Socket info block MUST NOT be locked by caller!

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/11/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCheckDuplicate	proc	far
		mov	ax, bp
		call	TSocketFindConnection		; carry set if found
		jnc	exit				
		mov	ax, SDE_CONNECTION_EXISTS
exit:
		ret
TSocketCheckDuplicate	endp

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketFindConnection

C DECLARATION:	extern word _far
		_far _pascal TSocketFindConnection (dword remoteAddr,
			dword localAddr, word lport, word rport);

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETFINDCONNECTION	proc	far	remoteAddr:dword,
					localAddr:dword,
					lport:word,
					rport:word
		uses	si, di
		.enter

		ForceRef localAddr		; don't need local addr...
		
		movdw	disi, remoteAddr
		mov	dx, rport
		mov	ax, lport
		call	TSocketFindConnection	; ax = connection handle or
						;  zero if not found
		.leave
		ret

TSOCKETFINDCONNECTION	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketFindConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the connection with the specified local port,
		remote port and remote address.

CALLED BY:	TSOCKETFINDCONNECTION
		TSocketCheckDuplicate
		TSOCKETPROCESSCONNECTREQUEST		

PASS:		disi	= remote IPAddr
		dx	= remote port number  
		ax	= local port number   

RETURN:		carry set if connection exists
		ax = connection handle
		else carry clear
		ax = 0

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		For each existing connection, compare the local port,
		remote port and remote address.  If all three match,
		then the connection exists.  Stop after first match.

		Socket info block must not be locked by caller!

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/11/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketFindConnection	proc	near
		uses	cx, di, bp
		.enter
		
		movdw	cxbp, disi			; cxbp = remote IPAddr
		mov	di, offset TSocketFindConnectionCB
		call	TSocketEnumConnections		; ax = connection handle
		jc	exit				; found?
		clr	ax				; not found
exit:		
		.leave
		ret
TSocketFindConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketFindOpenConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an open connection with the given remote address 
		and port numbers.

CALLED BY:	TcpipLinkConnectRequest

PASS:		ds:si	= address string (extended format)
		bp	= local port
		dx	= remote port

RETURN:		carry set if not found
		else 
		bx = connection handle

DESTROYED:	bx if not returned

NOTE:
		Caller MUST NOT have socket info block locked!

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/ 6/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketFindOpenConnection	proc	far
		uses	ax, cx, bp, di, si, ds
		.enter
	;
	; Extract IP address.
	;
		mov_tr	ax, bp				; ax = local port
		mov	bx, ds:[si]			; bx = link addr size
		inc	bx
		inc	bx				; include word for size
		movdw	cxbp, ds:[si][bx]		; cxbp = IP addr
	;
	; Find connection.
	;
		call 	TSocketLockInfoList		; *ds:si = socket list
		mov	bx, cs
		mov	di, offset TSocketFindConnectionCB
		call	ChunkArrayEnum			; carry set if found
							; ax = connection handle
		cmc
		jc	done				; not found
	;
	; Make sure connection is open.
	;
		mov_tr	bx, ax				; bx = connection handle
		mov	di, ds:[bx]			; ds:di = TcpSocket
		cmp	ds:[di].TS_state, TSS_OPEN
		je	done
		stc
done:
		call	TSocketUnlockInfoExcl		; preserves flags

		.leave
		ret
TSocketFindOpenConnection	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketFindSocketOfDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a connection of the specified domain.

CALLED BY:	TcpipUnregister

PASS:		es	= dgroup
		ax	= SocketDriverType

RETURN:		carry set if found

DESTROYED:	ax, di (allowed)

PSEUDO CODE/STRATEGY:
		Enum through the connections looking for a connection
		of a specified type

		Socket info block MUST NOT be locked by caller!

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/28/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketFindSocketOfDomain	proc	far
		mov	di, offset TSocketFindSocketOfDomainCB
		call	TSocketEnumConnections		; carry set if found
		ret
TSocketFindSocketOfDomain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCreateConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new TCP connection. 

CALLED BY:	TcpipAllocConnection
		TSOCKETPROCESSCONNECTREQUEST

PASS: 		nothing

RETURN:		carry set if error
		ax 	= SocketDrError
				SDE_INSUFFICIENT_MEMORY
		carry clear
		ax	= connection handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Alloc a chunk in the socketBlock (size = TcpSocket) 
		Initialize any necessary info  
		Zero out rest of info
		Alloc output queue	(in hugeLmem)
		Append to socket list
		return chunk handle

NOTE:
		Socket info block MUST NOT be locked when this is called. 

		CANNOT create TCB here until we have connection info
		to initialize the template with.


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/11/94			Initial version
	jwu	8/ 1/96			Nonblocking, interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCreateConnection	proc	far
		uses	bx, cx, dx, di, si, es, ds
		.enter
	;
	; Allocate a chunk for the socket info in the socket block.
	;		
		call	TSocketLockInfoExcl		; ds = socket block
		
		clr	al				; not an object
		mov	cx, size TcpSocket
		call	LMemAlloc			; ax = chunk handle
		LONG	jc errorNoFree
	;
	; Zero out TcpSocket, then set state to NEW and 
	; initialize max output queue size.
	;
		mov	si, ax				; si = chunk handle
		mov	di, ds:[si]			; ds:di = TcpSocket

		mov	bx, di
		segmov	es, ds, cx
		mov	cx, size TcpSocket
		shr	cx				
EC <		ERROR_C TCPIP_INTERNAL_ERROR	; size must be even!	>
		clr	ax
		rep	stosw
		mov	di, bx

		mov	ds:[di].TS_state, TSS_NEW
		mov	ds:[di].TS_maxData, DEFAULT_OUTPUT_QUEUE_MAX

	;
	; Create an initially locked semaphore for blocking 
	; calling threads.  
	;		
		push	si
		mov_tr	bx, ax				; bx <- 0
		call	ThreadAllocSem
		mov	ax, handle 0			; change owner to tcpip
		call	HandleModifyOwner		
		mov	ds:[di].TS_sem, bx
		pop	ax				; ax = chunk handle

	;
	; Allocate the output queue and store ptr to it in the socket info.
	;
		call	TSocketCreateOutputQueue	; ^lbx:cx = output queue
		jc	errorFreeSem
		movdw	ds:[di].TS_output, bxcx

	;
	; Append this new connection to the socket list.  The chunk
	; handle is the connection handle. (in AX)
	;		
		mov	bx, handle dgroup
		call	MemDerefES
		mov	si, es:[socketList]		; *ds:si = socket list
		call	ChunkArrayAppend		; ds:di = new element
		jc	errorFreeOutQ

		mov	ds:[di].TSE_socket, ax		
		jmp	done

errorFreeOutQ:
		mov	bx, ds:[di].TS_output.handle
		call	MemFree
errorFreeSem:
		mov	bx, ds:[di].TS_sem
		call	ThreadFreeSem

		call	LMemFree			
errorNoFree:		
		mov	ax, SDE_INSUFFICIENT_MEMORY
		stc
done:
		call	TSocketUnlockInfoExcl			

		.leave
		ret
TSocketCreateConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketStoreConnectionInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the connection info into a preallocated socket.
		If error, caller is responsible for destroying connection.

CALLED BY:	TcpipDataConnectRequest
		TSOCKETPROCESSCONNECTREQUEST

PASS:		ax	= domain handle of opened link
		bx	= connection handle  
		dx	= remote port number
		bp	= local port number
		disi	= remote IPAddr	

RETURN:		carry set if error
			ax	= SocketDrError (SDE_CONNECTION_EXISTS
						 SDE_INSUFFICIENT_MEMORY
						 SDE_INTERRUPTED)
		else carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		verify connection handle
		check for a duplicate connection
		store info into connection
		Create TCB
		Allocate an input queue if creating a TCP link connection.  
		
NOTE:
		Socket info block MUST NOT be locked when this is called.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/ 1/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketStoreConnectionInfo	proc	far
		uses	bx, cx, dx, di, si, ds
lPort		local	word			push bp
linkDomain	local	word			push ax		
		.enter

	;
	; Check for a duplicate connection again, just in case.
	;
		mov	ax, bx				; ax = conn handle
		call	TSocketCheckDuplicate		; ax = error
		jc	exit
	;
	; Get connection and store info.
	;
		mov	ax, bx				; ax = conn handle

EC <		call	TSocketFindHandle		; cx destroyed	>
EC <		ERROR_C TCPIP_INTERNAL_ERROR				>

		mov	bx, si				; dibx = remote IpAddr
		call	TSocketLockInfoExcl		; ds = segment
		mov	si, ax
		mov	si, ds:[si]			; ds:si = TcpSocket
	;
	; Check for interrupted connect request during link open.
	;
		mov	ax, ds:[si].TS_error
		cmp	ax, SDE_INTERRUPTED
		jne	storeInfo

		stc
		jmp	unlock
storeInfo:
		movdw	ds:[si].TS_remoteAddr, dibx
		mov	ds:[si].TS_remotePort, dx
		mov	bx, lPort
		mov	ds:[si].TS_localPort, bx
		mov	bx, linkDomain
		mov	ds:[si].TS_link, bx

		call	LinkGetLocalAddr		; bxcx = local addr
		jc	error				; just use memory error
		movdw	ds:[si].TS_localAddr, bxcx		

	;
	; Create the TCB and initialize the template header.
	;
		call	TSocketCreateTCB		; ^lbx:cx = TCB
		jc	error
		movdw	ds:[si].TS_tcb, bxcx
		
	;
	; Allocate an input queue if this is a TCP link connection.
	;
		mov	bx, lPort
		cmp	bx, GEOS_WELL_KNOWN_TCP_PORT
		jne	wellDone

		call	TSocketCreateInputQueue		; ^lbx:cx = queue
error:
		mov	ax, SDE_INSUFFICIENT_MEMORY
		jc	unlock

		movdw	ds:[si].TS_input, bxcx
wellDone:
		mov	ax, linkDomain			; restore AX
		clc
unlock:
		call	TSocketUnlockInfoExcl		; preserves flags
exit:
		.leave
		ret
TSocketStoreConnectionInfo	endp



COMMENT @-------------------------------------------------------------------

C FUNCTION: 	TSocketDestroyAllConnections

DESCRIPTION:  	Destroy all TCP connections.  They should all be dead.

CALLED BY: 	TcpipDestroyThreadAndTimer via MSG_TCPIP_DESTROY_CONNECTIONS

C DECLARATION: 	extern void _far
		_far _pascal TSocketDestroyAllConnections();

DESTROYED:	ax, bx, cx, dx

STRATEGY:
		This should be called only from TCP thread to prevent
		problems that may arise from destroying a connection that
		may be currently used by the TCP thread.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/28/95			Initial version
	jwu	10/23/95		Converted to C stub

----------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETDESTROYALLCONNECTIONS	proc	far
		uses	bp, di, si, ds
		.enter

		call	TSocketGetNumSockets
		jcxz	exit

		call	TSocketLockInfoList		; *ds:si = socket list
destroyLoop:
		mov	ax, cx
		dec	ax
		call	ChunkArrayElementToPtr		; ds:di = elt
		mov	bx, ds:[di].TSE_socket		; bx = connection handle
		call	TSocketDestroy
		loop	destroyLoop

		call	TSocketUnlockInfoExcl
exit:
		.leave
		ret
TSOCKETDESTROYALLCONNECTIONS	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDestroyConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy a connection.

CALLED BY:	TSocketIsDisconnectedData
		TSocketIsDisconnectedLink
		TcpipLinkConnectRequest
		TcpipDataConnectRequest

PASS:		cx	= connection handle

RETURN:		nothing

DESTROYED:	es

PSEUDO CODE/STRATEGY:
		find entry in socket list
		delete entry in socket list
		free tcb and output queue
		free socket 
NOTE:
		* Socket info block MUST NOT be locked when this is called. 
		* connection may already have been destroyed if client
		  unregisters at the exact moment the last connection was
		  closed (very timing dependent, but may happen)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/11/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDestroyConnection	proc	far
		uses	ax, bx, cx, di, si, ds
		.enter
	;
	; Find the entry in the socket list if it exists.
	;
		call	TSocketLockInfoList		; *ds:si = socket list
		mov_tr	ax, cx				; ax = connection handle
		call	TSocketFindHandleNoLock		; cx = elt #
EC <		WARNING_C TCPIP_CONNECTION_DOES_NOT_EXIST		>
		jc	exit
	;
	; Destroy the socket.
	;
		mov_tr	bx, ax				; bx = connection handle
		mov_tr	ax, cx				; ax = elt # to delete
		call	ChunkArrayElementToPtr		; ds:di = elt
		
		call	TSocketDestroy			; destroys ax
exit:		
		call	TSocketUnlockInfoExcl		
		.leave
		ret
TSocketDestroyConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketNewOutputData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the new data to the output queue for the connection.

CALLED BY:	TcpipSendData

PASS:		dx:bp	= optr of buffer to send
		cx	= size of data in buffer
		ax	= connection handle

RETURN:		carry set if output data could not be added to queue
		ax	= SocketDrError (SDE_CONNECTION_RESET if not open,
					 SDE_NO_ERROR if queue full)

DESTROYED:	ax if not returned

PSEUDO CODE/STRATEGY:
		check that the socket is open.
		ec < check if somebody is already blocked on a send, and
			fatal error if so. >
		check if adding new data will cause output size to overflow
			word size.
		if queue has maximum size, and current size exceeds or equals
			max, return carry set.

		if link connection, add boundary marker to packet data
		append the buffer to the output queue
		increment size of output queue to include new data.

NOTES:
		socket info block must not be locked when this is called.

		Our limits on the output queue can be exceeded, but once 
		the limit is exceeded, future sends will block until 
		the size has dropped below the maximum again.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/11/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketNewOutputData	proc	far
		uses	bx, di, si, ds, es
		.enter
	;
	; Get socket information and make sure socket is open.
	;
		call	TSocketLockInfoList		; *ds:si = socket list
		mov	di, ax				; di = connection handle

		push	cx
		call	TSocketFindHandleNoLock		; destroys cx
		pop	cx
		mov	ax, SDE_CONNECTION_RESET	; assume the worst

EC <		WARNING_C TCPIP_CONNECTION_DOES_NOT_EXIST		>
		jc	exit	

		mov	di, ds:[di]			; ds:di = TcpSocket
		cmp	ds:[di].TS_state, TSS_OPEN
		stc					; assume the worst
		jne	exit
	;
	; Check if data can be added to output queue, allowing extra
	; space for link connections to add size to the buffer data.
	;
EC <		tst	ds:[di].TS_pendingData			>
EC <		ERROR_NE TCPIP_SEND_DATA_CALL_IN_PROGRESS	>

		push	di, cx
		movdw	bxsi, ds:[di].TS_output
		call	MemLock
		mov	es, ax			; *es:si = output queue
		segxchg	es, ds			; *ds:si = output queue
		mov	di, ds:[si]		; ds:di = output queue header
		mov	ax, ds:[di].TOQH_size
		inc	cx			; allow room for link connections
		inc	cx 
		add	cx, ax			; carry set if overflow
		pop	di, cx			; es:di = TcpSocket, cx = size
		jc	unlockQueue
				
		cmp	es:[di].TS_maxData, ax	; exceeded maximum?
		jb	unlockQueue		; carry already set
	;
	; If link connection, include size of packet in data for
	; packet boundaries.
	;
		tst	es:[di].TS_input.handle
		je	appendData			; data connection

		call	TSocketMarkPacketBoundary	; cx = new size in buffer
appendData:	
	;
	; Append data buffer to output queue and increment output size.
	;
		call	ChunkArrayAppend		; ds:di = new element
		movdw	ds:[di].TOE_data, dxbp		
		mov	di, ds:[si]			; ds:di = output queue
		add	ds:[di].TOQH_size, cx		; carry will be clear
unlockQueue:
		call	MemUnlock			
		mov	ax, SDE_NO_ERROR		; preserve carry!
exit:		
		call	TSocketUnlockInfoExcl		
		.leave
		ret
TSocketNewOutputData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketSetStateAndGetSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some initial set up for establishing a socket connection.

CALLED BY:	TcpipDataConnectRequest
		TcpipResetRequest
		TcpipAttach
		TcpipReject

PASS:		ax	= connection handle
		bl	= TcpSocketState
			if TcpSocketState is TSS_DISCONNECTING
			cx	= SocketCloseType 

RETURN:		bx	= semaphore handle (or unchanged if no sem required)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the socket state as specified
		allocate the semaphore to block on and save its handle

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/11/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketSetStateAndGetSem	proc	far
		uses	si, ds
		.enter
	;
	; Set the socket state and get the semaphore.
	;		
		call	TSocketLockInfoExcl		
		mov	si, ax				
		mov	si, ds:[si]			; ds:si = TcpSocket
		mov	ds:[si].TS_state, bl

EC <		tst	ds:[si].TS_waiter				>
EC <		ERROR_NZ TCPIP_OPERATION_IN_PROGRESS			>

		mov	ds:[si].TS_waiter, TCPIP_WAITER_EXISTS
		mov	bx, ds:[si].TS_sem
		call	TSocketUnlockInfoExcl

		.leave
		ret
TSocketSetStateAndGetSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCheckIfConnected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the state of a connecting socket to determine if 
		the connection has been successfully established. 

CALLED BY:	TcpipAttach

PASS:		cx	= connection handle
		ax	= SemaphoreError (SE_TIMEOUT if timeout)

RETURN:		carry set if error
		ax = SocketDrError
			(SDE_CONNECTION_TIMEOUT
			 SDE_CONNECTION_REFUSED
			 SDE_CONNECTION_RESET
			 SDE_CONNECTION_RESET_BY_PEER)
		otherwise
		carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if timed out, do not destroy connection here.  set 
		the destruct timer.  this protects against destroying
		the socket while the driver's thread may be using it.

		if it is open, the connection has been successfully 
		established.  

		if it is closed, return the error.  Do not destroy 
		connection here because TSocketIsDisconnectedData 
		will take care of that for us.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/11/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCheckIfConnected	proc	far
		uses	si, ds
		.enter
	;
	; Determine if connection has been successfully established.
	;
		call	TSocketLockInfoShared		; ds = segment
		mov	si, cx				; si = connection handle
		mov	si, ds:[si]			; ds:si = TcpSocket

		cmp	ax, SE_NO_ERROR
		jne	timeout

		mov	ax, ds:[si].TS_error		; get error in case...
		cmp	ds:[si].TS_state, TSS_OPEN
		je	unlock
		jmp	error
timeout:
	;
	; We timed out, set the state to dead, clear the waiter field,
	; set the destruct timer and return SDE_CONNECTION_TIMEOUT as the 
	; error.  
	;		
		mov	ds:[si].TS_state, TSS_DEAD
		mov	ds:[si].TS_destructTime, CONNECTION_DESTRUCT_TIME
		mov	ds:[si].TS_waiter, TCPIP_NO_WAITER
		mov	ax, SDE_CONNECTION_TIMEOUT
error:
		stc
unlock:		
		call	TSocketUnlockInfoShared		; preserves flags
exit::
		.leave
		ret

TSocketCheckIfConnected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCheckLinkBusy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if any connections are using the given link.

CALLED BY:	TcpipCloseMedium
		LinkOpenConnection

PASS:		ax	= link domain handle

RETURN:		carry set if connection exists or LO_ALWAYS_BUSY set

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Enum through connections until we find one using the link.

NOTES:
		Cannot check LO_ALWAYS_BUSY flag in here because
		caller may have link table locked and we'll deadlock.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/12/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCheckLinkBusy	proc	far
		uses	di, ds
		.enter

	;
	; Check each connections to find one using the link.
	;
		mov	di, offset TSocketCheckLinkBusyCB
		call	TSocketEnumConnections

		.leave
		ret
TSocketCheckLinkBusy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketResetConnectionsOnLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset each connection using the given link.

CALLED BY:	TcpipCloseMedium
		TcpipLinkClosed

PASS:		ax	= link domain handle
		dx	= SocketDrError 
				(SDE_CONNECTION_RESET, possibly or-ed with
				SpecSocketDrError from link driver)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Cannot use ChunkArrayEnum because socket block cannot 
		remain locked while calling TCP thread.  Instead, manually
		loop through the connections.  Go backwards, because 
		some connections may be deleted.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/12/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketResetConnectionsOnLink	proc	far
		uses	ax, bx, cx, dx, bp, di, si, ds
		.enter
	;
	; Find out how many times to loop.  
	;
		call	TSocketLockInfoList	; *ds:si = socket list
		call	ChunkArrayGetCount	; cx = count
		jcxz	exit
	;
	; Go backwards as connections will be deleted when reset.
	; Only reset active connections using the given link, unless 
	; the connection is a "loopback" on the link.
	;
		dec	cx			; zero-based index
resetLoop:
		xchg	ax, cx			; ax = index 
						; cx = link domain handle
		call	ChunkArrayElementToPtr	; ds:di = TcpSocketElt
EC <		ERROR_C TCPIP_INTERNAL_ERROR	; array changed while unlocked?>
		mov	bx, ds:[di].TSE_socket	
		mov	bx, ds:[bx]		; ds:bx = TcpSocket
		cmp	cx, ds:[bx].TS_link
		jne	next

		cmp	ds:[bx].TS_state, TSS_DEAD
		je	next

		push	ax, bx, dx		; destroyed by C stub
		push	cx
		pushdw	ds:[bx].TS_remoteAddr
		call	LINKCHECKLOCALADDR	; ax = 0 if link addr
		tst	ax
		pop	ax, bx, dx
		je	next
	;
	; Reset the connection by marking the state closed, waking up a 
	; blocked send request and telling the TCP thread to reset the
	; connection. 
	;
		push	ax, cx			; save index and domain handle
		mov	ds:[bx].TS_state, TSS_CLOSED
		tst	ds:[bx].TS_pendingData
		je	sendMsg
		mov	bx, ds:[bx].TS_sendSem
		call	ThreadVSem
sendMsg:
	;
	; Have TCP thread reset connection.  MUST release access to 
	; socket info list first.  Use MF_CALL so we know socket has
	; been destroyed when code returns.
	;
		mov	cx, ds:[di].TSE_socket	; cx = connection handle
		call	TSocketUnlockInfoExcl

		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[driverThread]
		mov	ax, MSG_TCPIP_RESET_CONNECTION_ASM
		mov	di, mask MF_CALL		
		call	ObjMessage

		call	TSocketLockInfoExcl	; *ds:si = socket list
		pop	ax, cx			; ax = index
						; cx = link domain handle
next:
	;
	; Keep going until index becomes negative 1.  Cannot use loop
	; instruction or first connection will be skipped.
	;
		xchg	ax, cx			; cx = index
						; ax = link domain handle
		dec	cx
		jns	resetLoop
exit:
		call	TSocketUnlockInfoExcl

		.leave
		ret
TSocketResetConnectionsOnLink	endp




COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketToTCB

DESCRIPTION:	Get the Tcp control block for the specified connection.

C DECLARATION:	extern optr _far 
		_far _pascal TSocketToTCB (word connection);

STRATEGY:	If connection no longer exists, return zero.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
	jwu	9/27/95		Added warning, removed fatal error 

-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETTOTCB	proc	far	connection:word

		uses	si, ds
		.enter

		mov	ax, connection				
		call	TSocketFindHandle	; cx destroyed 	
		jnc	getTCB

EC <		WARNING TCPIP_CONNECTION_DOES_NOT_EXIST			>
		clrdw	dxax
		jmp	exit
getTCB:
		call	TSocketLockInfoShared		; ds = segment
		mov	si, connection
		mov	si, ds:[si]			; ds:si = tcpsocket
		movdw	dxax, ds:[si].TS_tcb
		call	TSocketUnlockInfoShared
exit:		
		.leave
		ret
TSOCKETTOTCB	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketDoError

DESCRIPTION:	Process an error for all connections to remote addr
		equal to "sndr".
		
C DECLARATION:	extern void _far
		_far _pascal TSocketDoError(word code, dword sndr);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETDOERROR		proc	far		code:word,
						sndr:dword
		uses	di
		.enter
		
		mov	ax, code
		movdw	cxdx, sndr
		mov	di, offset TSocketDoErrorCB
		call	TSocketEnumConnections

		.leave
		ret
TSOCKETDOERROR	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketIsConnected

DESCRIPTION:	Connection was established by Tcp protocol.
		
C DECLARATION:	extern void _far
		_far _pascal TSocketIsConnected(word connection);

STRATEGY:
		if interrupted, don't bother notifying
		set socket state to open.
		if link connection, process separately
		else
			wakeup the waiter, if any
			else send notification (SCO_CONNECT_CONFIRMED)
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
	jwu	8/ 1/96		Nonblocking, interruptible version

-------------------------------------------------------------------------@
	SetGeosConvention	
TSOCKETISCONNECTED	proc	far	connection:word
		
		uses	si, di, ds
		.enter
	;
	; If interrupted, don't notify or wake client.  Connection
	; is closing.
	;
		call	TSocketLockInfoExcl		; ds = segment
		mov	si, connection
		mov	si, ds:[si]			; ds:si = tcpsocket

		cmp	ds:[si].TS_error, SDE_INTERRUPTED
		je	exit

		mov	cl, TSS_OPEN
		xchg	cl, ds:[si].TS_state
		cmp	ds:[si].TS_localPort, GEOS_WELL_KNOWN_TCP_PORT
		jne	doData

		call	TSocketIsConnectedLink
		jmp	unlock
doData:
	;
	; Process newly opened data connection by waking a blocked client
	; or sending a connect confirmed notification.
	;
		tst	ds:[si].TS_waiter
		je	notify

		mov	ds:[si].TS_waiter, TCPIP_NO_WAITER
		mov	bx, ds:[si].TS_sem
		call	ThreadVSem
		jmp	unlock
notify:
	; 
	; Send confirmation of data connect request.  Okay to 
	; keep socket info block locked.  Client should not be
	; calling us back for anything.
	;
		mov	bx, handle dgroup
		call	MemDerefES
		pushdw	es:[clients].TCI_data.CI_entry
		mov	ax, connection
		mov	bx, es:[clients].TCI_data.CI_domain
		mov	di, SCO_CONNECT_CONFIRMED
		call	PROCCALLFIXEDORMOVABLE_PASCAL
unlock:
		call	TSocketUnlockInfoExcl
exit:
		.leave
		ret
TSOCKETISCONNECTED	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketIsConnectedLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a newly opened TCP link connection.

CALLED BY:	TSocketIsConnected

PASS:		ds:si 	= TcpSocket
		cl	= former TcpSocketState
		inherited stack frame

RETURN:		nothing

DESTROYED:	ax, bx, cx, di, es

PSEUDO/STRATEGY:
		If no link client, load socket library and register
		as link driver. 
		
		If failed to get client, state connection state to
		CLOSED and queue message for driver's thread to 
		close connection.  

		Else notify client link connection is opened.
		If former state is CONNECTING, use SCO_CONNECT_CONFIRMED
		else if CONNECT_REQUESTED, use SCO_LINK_OPENED.

NOTES:
		Caller has socket info block locked and expects
		it to be returned that way.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/ 1/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketIsConnectedLink	proc	near

		.enter inherit TSOCKETISCONNECTED

EC <		tst	ds:[si].TS_input.handle				>
EC <		ERROR_E TCPIP_INTERNAL_ERROR  	; not link connection!	>

	;
	; Make sure we have a link client.  If not, load socket library
	; and register as link driver.  
	;	
		mov	bx, handle dgroup		
		call	MemDerefES

		mov	bx, es:[regSem]
		call	ThreadPSem			; get access

		test	es:[regStatus], mask RS_LINK
		jnz	notify
		
		segxchg	es, ds
		mov	dl, SDT_LINK
		call	TSocketLoadSocketLibrary
		segxchg	es, ds
		jnc	notify
	;
	; No client.  Mark connection as closed and queue a message
	; for driver's thread to reset the connection.
	;
		mov	ds:[si].TS_state, TSS_CLOSED
		mov	bx, es:[driverThread]				
		mov	cx, connection
		mov	ax, MSG_TCPIP_CLOSE_CONNECTION_ASM
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage		
		jmp	releaseSem
notify:
	;
	; Notify socket library link opened. 
	;
		mov	di, SCO_CONNECT_CONFIRMED
		cmp	cl, TSS_CONNECTING
		je	notifyNow

EC <		cmp	cl, TSS_CONNECT_REQUESTED			>
EC <		ERROR_NE TCPIP_BAD_SOCKET_STATE			   	>
		mov	di, SCO_LINK_OPENED
notifyNow:
		add	si, offset TS_remoteAddr	; ds:si = addr
		mov	cx, IP_ADDR_SIZE
		mov	ax, connection			; link handle
		mov	bx, es:[clients].TCI_link.CI_domain	; domain handle
		pushdw	es:[clients].TCI_link.CI_entry
		call	PROCCALLFIXEDORMOVABLE_PASCAL
releaseSem:
		mov	bx, es:[regSem]
		call	ThreadVSem

		.leave
		ret
TSocketIsConnectedLink	endp


COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketIsDisconnected

DESCRIPTION:	Connection was disconnected by Tcp protocol.
		
C DECLARATION:	extern void _far
		_far _pascal TSocketIsDisconnected(word connection, 
			word error, SocketCloseType closeType, 
			Boolean destroyOK);
STRATEGY:
		wakeup any waiter, storing error in socket.  (connection 
			will be destroyed when waiter awakes)
		if no waiters, then just destroy the connection and 
			notify the socket library with 
			SCO_CONNECTION_CLOSED.
		
		Well, that was the basic idea.  Then all these special
		cases popped up... :(

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
	jwu	9/28/95		Added destroyOK parameter
	jwu	8/ 1/96		Interruptible version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETISDISCONNECTED	proc	far		connection:word,
						error:word, 
						closeType:SocketCloseType,
						destroyOK:word
		uses	di, ds
		ForceRef closeType
		ForceRef destroyOK
		.enter
	;
	; Store the error in the socket info and determine the 
	; connection type.  Do NOT store the error if already
	; set to SDE_INTERRUPTED.
	;
		call	TSocketLockInfoExcl
		mov	di, connection
		mov	di, ds:[di]

		cmp	ds:[di].TS_error, SDE_INTERRUPTED
		jne	storeError

		mov	error, SDE_INTERRUPTED
		jmp	afterError
storeError:
		mov	ax, error
		mov	ds:[di].TS_error, ax
afterError:
		mov	ax, ds:[di].TS_localPort
		call	TSocketUnlockInfoExcl
		
		cmp	ax, GEOS_WELL_KNOWN_TCP_PORT
		je	doLink

		call	TSocketIsDisconnectedData
		jmp	exit		
doLink:
		call	TSocketIsDisconnectedLink
exit:
		.leave
		ret

TSOCKETISDISCONNECTED	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketIsDisconnectedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a disconnection for a data connection.

CALLED BY:	TSOCKETISDISCONNECTED

PASS:		inherited stack frame
		socket info block unlocked

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, ds (preserved by caller)
		es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 9/95			Initial version
	jwu	8/ 1/96			Nonblocking, Interruptible version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketIsDisconnectedData	proc	near
		.enter inherit TSOCKETISDISCONNECTED

	;
	; If connection is closing completely, then set the state to
	; TSS_DEAD to prevent other segments for this connection from
	; being processed.
	;
		call	TSocketLockInfoExcl
		mov	di, connection
		mov	di, ds:[di]

		mov	dl, ds:[di].TS_state		; dl = former state
		mov	ax, closeType
		cmp	ax, SCT_HALF
		je	stateOK
		
		mov	ds:[di].TS_state, TSS_DEAD
stateOK:
	;
	; If current state is TSS_DISCONNECTING and there is a waiter,
	; simply exit because we don't want the connection to be destroyed
	; yet.  (Means this is a half close and the client did a full
	; close.)
	;		
		cmp	ds:[di].TS_state, TSS_DISCONNECTING
		jne	normalCase
		tst	ds:[di].TS_waiter
		je	normalCase

		call	TSocketUnlockInfoExcl
		jmp	exit
normalCase:
	;
	; If full close, be sure to wake any pending sends.
	;
		cmp	ax, SCT_HALF
		je	noSender
		tst	ds:[di].TS_pendingData
		je	noSender
EC <		WARNING TCPIP_ABORTING_SEND_DATA_REQUEST	>		
		mov	bx, ds:[di].TS_sendSem
		call	ThreadVSem
noSender:
	;
	; Wake up the waiter if any.  (Means waiter did a full close.)
	;
		clr	cx
		mov	cl, TCPIP_NO_WAITER
		xchg	cl, ds:[di].TS_waiter

		mov	bx, ds:[di].TS_sem
		call	TSocketUnlockInfoExcl
		
		jcxz	noWaiter
		call	ThreadVSem
	;
	; Set the destruct timeout if connection allowed to be
	; destroyed.  Can't do it here in case waiter uses it
	; after waking up.
	;
		tst	destroyOK
		jz	exit

		call	TSocketLockInfoExcl
		mov	di, connection
		mov	di, ds:[di]			; ds:di = TcpSocket
		mov	ds:[di].TS_destructTime, CONNECTION_DESTRUCT_TIME
		call	TSocketUnlockInfoExcl
		jmp	exit
noWaiter:
	;
	; Notify the client, unless connection was already marked dead.
	;
		mov_tr	cx, ax				; cx = SocketCloseType
		mov	ax, connection
		cmp	dl, TSS_DEAD
		je	destroy

		mov	di, SCO_CONNECT_FAILED
		cmp	dl, TSS_CONNECTING
		je	notifyNow

		mov	di, SCO_CONNECTION_CLOSED
notifyNow:
		mov	bx, handle dgroup
		call	MemDerefDS

		mov	bx, ds:[clients].TCI_data.CI_domain
		mov	dx, error
		pushdw	ds:[clients].TCI_data.CI_entry
		call	PROCCALLFIXEDORMOVABLE_PASCAL
destroy:
	;
	; Destroy connection if this is a full close and if allowed.
	;
		cmp	cx, SCT_HALF
		je	exit

		tst	destroyOK
		jz	exit

		mov_tr	cx, ax				; cx = connection
		call	TSocketDestroyConnection
exit:
		.leave
		ret
TSocketIsDisconnectedData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketIsDisconnectedLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a disconnection for a link connection.

CALLED BY:	TSOCKETISDISCONNECTED

PASS:		inherited stack frame
		socket info block unlocked

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, ds (preserved by caller)
		es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	2/ 9/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketIsDisconnectedLink	proc	near
		.enter inherit TSOCKETISDISCONNECTED
	;
	; If peer has closed their end of the connection, automatically 
	; disconnect the local end.  MUST use half close or will deadlock!
	;
		cmp	closeType, SCT_FULL
		je	fullClose

		mov	ax, SCT_HALF
		mov	bx, connection
		mov	di, DR_SOCKET_DISCONNECT_REQUEST
		call	TcpipStrategy
		jmp	exit	
fullClose:
	;
	; Mark socket as DEAD.  
	;
		call	TSocketLockInfoExcl
		mov	di, connection
		mov	di, ds:[di]
		mov	dl, TSS_DEAD
		xchg	dl, ds:[di].TS_state		; dl = former state
	;
	; Wake up any pending sends.
	;
		tst	ds:[di].TS_pendingData
		je	noSender
EC <		WARNING TCPIP_ABORTING_SEND_DATA_REQUEST	>		
		mov	bx, ds:[di].TS_sendSem
		call	ThreadVSem
noSender:
	; 
	; If there is a waiter, wake them up.
	;
		clr	cx
		mov	cl, TCPIP_NO_WAITER
		xchg	cl, ds:[di].TS_waiter

		mov	bx, ds:[di].TS_sem
		call	TSocketUnlockInfoExcl

		jcxz	noWaiter
		call	ThreadVSem
	;
	; Set the destruct timeout if connection allowed to be
	; destroyed.  Can't do it here in case waiter uses it 
	; after waking up.
	;
		tst	destroyOK
		jz	exit

		call	TSocketLockInfoExcl
		mov	di, connection
		mov	di, ds:[di]			; ds:di = TcpSocket
		mov	ds:[di].TS_destructTime, CONNECTION_DESTRUCT_TIME
		call	TSocketUnlockInfoExcl
		jmp	exit
noWaiter:
	;
	; Notify the client if the client knows about the link (former
	; state != CONNECT_REQUESTED or DEAD).  
	;
		CheckHack < TSS_DEAD gt TSS_CONNECT_REQUESTED>
		CheckHack < TSS_DEAD eq TcpSocketState - 1>
		mov	ax, connection
		cmp	dl, TSS_CONNECT_REQUESTED
		jae	destroy

		mov	di, SCO_CONNECT_FAILED
		cmp	dl, TSS_CONNECTING
		je	notifyNow

		mov	di, SCO_CONNECTION_CLOSED
notifyNow:
		mov	bx, handle dgroup
		call	MemDerefDS

		movdw	bxdx, ds:[clients].TCI_link.CI_entry
		tstdw	bxdx
		jz	destroy				; no client

		pushdw	bxdx
		mov	bx, ds:[clients].TCI_link.CI_domain
		mov	dx, error
		call	PROCCALLFIXEDORMOVABLE_PASCAL
destroy:
	;
	; Destroy the connection, if allowed.  Do this AFTER notification.
	; 
		tst	destroyOK
		jz	exit

		mov	cx, connection
		call	TSocketDestroyConnection
exit:
		.leave
		ret
TSocketIsDisconnectedLink	endp



COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketIsDead

DESCRIPTION:	Determine if the Socket is about to be destroyed.
		
C DECLARATION:	extern word _far
		_far _pascal TSocketIsDead(word connection);

STRATEGY:
		check the state of the socket and return non-zero if it
		is TSS_DEAD.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETISDEAD	proc	far		connection:word
		uses	di, ds
		.enter

		call	TSocketLockInfoShared
		mov	di, connection
		mov	di, ds:[di]		; ds:di = TcpSocket

		mov	al, ds:[di].TS_state
		call	TSocketUnlockInfoShared

		cmp	al, TSS_DEAD
		je	exit
		
		clr	ax			; good socket
exit:
		.leave
		ret
TSOCKETISDEAD	endp	
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketGetInfo

DESCRIPTION:	Get the local address, remote address, local port and
		remote port for a connection.
		
C DECLARATION:	extern void _far
		_far _pascal TSocketGetInfo(word connection, byte *src,
			byte *dst, word *lport, word *rport);
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETGETINFO	proc	far		connection:word,
					src:fptr.dword,
					dst:fptr.dword,
					lport:fptr.word,
					rport:fptr.word
		uses	di, si, ds
		.enter

		call	TSocketLockInfoShared	; ds = segment
		mov	bx, connection
		mov	bx, ds:[bx]		; ds:bx = TcpSocket
		
		les	di, lport
		lea	si, ds:[bx].TS_localPort
		movsw

		les	di, rport
		lea	si, ds:[bx].TS_remotePort
		movsw

		les	di, src
		lea	si, ds:[bx].TS_localAddr	; ds:si = local addr
		mov	cx, (size IPAddr / 2)
		rep	movsw

		les	di, dst
		lea	si, ds:[bx].TS_remoteAddr	; ds:si = remote addr
		mov	cx, (size IPAddr / 2)
		rep	movsw

		call	TSocketUnlockInfoShared

		.leave
		ret
TSOCKETGETINFO	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketGetLink

DESCRIPTION: 	Return the link domain handle for this socket.

C DECLARATION:	extern word _far
		_far _pascal TSocketGetLink(word connection);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETGETLINK		proc	far		connection:word
		uses	si, ds
		.enter

		call	TSocketLockInfoShared		; ds = segment
		mov	si, connection
		mov	si, ds:[si]			; ds:si = TcpSocket

		mov	ax, ds:[si].TS_link
		
		call	TSocketUnlockInfoShared
		
		.leave
		ret
TSOCKETGETLINK		endp
	SetDefaultConvention


COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketGetRecvWin

DESCRIPTION:	Get the amount of space availabe in the socket library's
		receive buffer for this connection.
		
C DECLARATION:	extern dword _far
		_far _pascal TSocketGetRecvWin(word connection);

NOTES:
	DS should already be dgroup.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
	jwu	8/ 6/96		Don't query for link connections

-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETGETRECVWIN	proc	far	connection:word
		uses	di, ds
		.enter
	;
	; If link connection, no need to query.  Link connection 
	; does not depend on client to do flow control.  Simply 
	; return maximum adjusted by buffered input.
	;
		segmov	es, ds, bx			; es = dgroup

		call	TSocketLockInfoShared
		mov	bx, connection
		mov	di, ds:[bx]
		mov	cx, ds:[di].TS_input.handle
		jcxz	doData

		mov	dx, -1

		movdw	bxdi, ds:[di].TS_input
		call	MemLock
		mov	ds, ax				; *ds:di = input array
		mov	di, ds:[di]			; ds:di = array header
		clr	ax
		xchg	ax, dx				; dxax = space in buffer
		sub	ax, ds:[di].TLIH_bytesRecvd
		jns	unlock
		clr	ax
unlock:
		call	MemUnlock
		call	TSocketUnlockInfoShared
		jmp	done
doData:
	;
	; Get client's idea of space in receive buffer.
	;
		call	TSocketUnlockInfoShared

		pushdw	es:[clients].TCI_data.CI_entry
		mov	dx, es:[clients].TCI_data.CI_domain
		mov	ax, SCIT_RECV_BUF
		mov	di, SCO_GET_INFO
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; dxax = space in buffer
EC <		tst	dx						>
EC <		ERROR_NZ TCPIP_INTERNAL_ERROR				>

done:
		.leave 
		ret

TSOCKETGETRECVWIN	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketTimeoutHandler

DESCRIPTION:	For all connections, decrement counters as needed and
		do some processing when the counter reaches zero.
		
C DECLARATION:	extern void _far
		_far _pascal TSocketTimeoutHandler();

STRATEGY:
		Decrement destruct timers first.
		Decrement TCP timers in each connection, unless the
		connection hasn't had a TCB created yet.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
	jwu	8/ 6/96		Nonblocking, interruptible version

-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETTIMEOUTHANDLER	proc	far
		uses	di, si, bp, ds
		.enter
	;
	; Process destruct timers in dead connections first, so
	; socket info block can be unlocked for Tcp timer processing.
	;
		call	TSocketLockInfoList	; *ds:si = socket list

		mov	bx, cs
		mov	di, offset TSocketDestructTimeoutCB
		call	ChunkArrayEnum
		
		call	ChunkArrayGetCount	; cx = # connections left
		call	TSocketUnlockInfoExcl
		
		jcxz	exit
	;
	; Check if any Tcp timers need to be processed.  Unlock
	; the socket info block before calling Tcp level to prevent 
	; deadlock.  (Can't use ChunkArrayEnum)  Work backwards through 
	; list as connections may be destroyed when some timers expire.
	; SI already contains socket list chunk handle.
	;		
tcpTimerLoop:
		mov	ax, cx
		dec	ax			; index 

		call	TSocketLockInfoExcl	; *ds:si = socket list
		call	ChunkArrayElementToPtr	; ds:di = TcpSocketElt
EC <		ERROR_C	TCPIP_INTERNAL_ERROR	; array changed while unlocked? >
		mov	bx, ds:[di].TSE_socket	; bx = connection handle
		mov	di, ds:[bx]		; ds:di = TcpSocket
		mov	al, ds:[di].TS_state
		movdw	bpdi, ds:[di].TS_tcb	; bp:di = optr of TCB
		call	TSocketUnlockInfoExcl

		tst	bp			; no TCB yet!
		jz	next

		push	cx, si			; save regs around c call
		pushdw	bpdi			; pass tcb
		push	bx			; pass connection handle
		call	TcpTimeoutHandler 	; may destroy all but bp
		pop	cx, si			; restore regs around c call
next:
		loop	tcpTimerLoop
exit:				
		.leave
		ret

TSOCKETTIMEOUTHANDLER	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketRecvInput

DESCRIPTION: 	Pass incoming data to the socket library.  Adjust domain
		in packet header to be tcp/ip driver's domain handle.
		Put connection handle into SPH_link of buffer.  

RETURN:		Remaining space available in socket library's receive 
		buffer (in bytes).  
		
C DECLARATION:	extern dword _far
		_far _pascal TSocketRecvInput(optr dataBuffer, word connection);

NOTES:
		DS should already be dgroup.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		nitial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETRECVINPUT		proc	far	dataBuffer:optr,
						connection:word

		uses	di
		.enter		
	;
	; Find out if this is a data connection or a link connection.
	;
		mov	cx, connection
		call	TSocketGetConnectionDomain	; bx = domain handle
		jnc	link		
	;
	; Fill in domain handle and connection handle into the 
	; packet header.  Set packetType to sequenced.
	;
		push	bx
		movdw	bxdx, dataBuffer
		call	HugeLMemLock
		mov	es, ax
		mov	di, dx				; *es:di = packet header
		mov	di, es:[di]			; es:di = packet header
		pop	ax				; ax = domain handle
		
		mov	es:[di].SPH_link, cx
		mov	es:[di].PH_domain, ax
		mov	cx, es:[di].PH_dataSize
		mov	es:[di].PH_flags, PacketFlags <0, 0, PT_SEQUENCED>
		call	HugeLMemUnlock
	;
	; And away it goes... if there's data, that is.
	;
		mov	di, offset TCI_data
		jcxz	discardPacket

		mov	cx, bx				; ^lcx:dx = data buffer
		mov	di, SCO_RECEIVE_PACKET				
		movdw	bxax, ds:[clients].TCI_data.CI_entry
		call	ProcCallFixedOrMovable		; dxax = remaining space

EC <		ERROR_C	TCPIP_BAD_DELIVERY 			>
EC <		tst	dx					>
EC <		ERROR_NZ TCPIP_INTERNAL_ERROR			>
exit:		
		.leave
		ret

discardPacket:
		movdw	axcx, bxdx			; ^lax:cx = data buffer
		call	HugeLMemFree
		clr	cx				; no buffered input
		jmp	getSpace

link:
	;
	; If no link client, discard packet.  
	;
		mov	di, offset TCI_link
		movdw	bxdx, dataBuffer
		test	ds:[regStatus], mask RS_LINK
		jz	discardPacket

		call	TSocketRecvLinkInput		; cx = bytes recvd
getSpace:
	;
	; Compute remaining space in receive buffer for this connection,
	; subtracting any buffered input.
	;
		movdw	dxax, -1			; no limit if no client
		tstdw 	ds:[clients][di].CI_entry
		jz	exit

		pushdw	ds:[clients][di].CI_entry
		mov	dx, ds:[clients][di].CI_domain
		mov	ax, SCIT_RECV_BUF
		mov	bx, connection
		mov	di, SCO_GET_INFO
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; dxax = space in buffer

EC <		tst	dx						>
EC <		ERROR_NZ TCPIP_INTERNAL_ERROR				>

		sub	ax, cx				; subtract buffered input
		jns	exit		
		clr	ax				
		jmp	exit


TSOCKETRECVINPUT		endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketProcessConnectRequest

DESCRIPTION: 	Create a temporary socket connection and find out
		if there is a listener.
		
C DECLARATION:	extern word _far
		_far _pascal TSocketProcessConnectRequest(dword remoteAddr,
			word rport, word lport, word link);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
	jwu	8/ 1/96		Nonblocking, interruptible version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETPROCESSCONNECTREQUEST	proc	far	remoteAddr:dword,
						rport:word,
						lport:word,
						link:word
		uses	di, si, ds
		.enter
	;
	; If data connection, make sure we have a data client.  If not,
	; load socket library and register as data driver.
	;
		mov	bx, ds:[regSem]
		call	ThreadPSem			; get access

		cmp	rport, GEOS_WELL_KNOWN_TCP_PORT
		je	create

		test	ds:[regStatus], mask RS_DATA
		jnz	create

		mov	dl, SDT_DATA
		call	TSocketLoadSocketLibrary
		LONG	jc	error
create:
	;
	; Create the connection and set its state to TSS_CONNECT_REQUESTED.
	;
		call	TSocketCreateConnection		; ax = error or handle
		LONG	jc	error

		push	bp				; stack vars
		mov_tr	bx, ax				; bx = connection handle
		mov	ax, link
		movdw	disi, remoteAddr
		mov	dx, rport
		mov	bp, lport
		call	TSocketStoreConnectionInfo	; ax = error 
		pop	bp				
		jc	errorDestroy

		call	TSocketLockInfoExcl
		mov	si, ds:[bx]			; ds:si = TcpSocket
		mov	ds:[si].TS_state, TSS_CONNECT_REQUESTED
		call	TSocketUnlockInfoExcl
	;
	; If incoming link connection, queue a message for driver's thread
	; to accept the connection.  Must use MF_FORCE_QUEUE because driver
	; must finish processing current segment first!
	;
		mov_tr	ax, bx				; ax = connection handle
		mov	bx, handle dgroup
		call	MemDerefDS
		
		cmp	rport, GEOS_WELL_KNOWN_TCP_PORT
		jne	notify

		mov_tr	cx, ax				; cx = connection
		mov	bx, ds:[driverThread]
		mov	ax, MSG_TCPIP_ACCEPT_CONNECTION_ASM
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		mov_tr	ax, cx				; ax = connection
		jmp	exit
notify:
	;
	; Ask data client if there is a listener on this local port.
	; If no listener, destroy temporary connection.  
	; DX = remote port, AX = connection handle.
	;
		mov	cx, lport
		mov	bx, ds:[clients].TCI_data.CI_domain
		mov	di, SCO_CONNECT_REQUESTED
		pushdw	ds:[clients].TCI_data.CI_entry
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jnc	exit

		mov_tr	bx, ax				; bx = connection handle
		clr	ax				; no error
errorDestroy:
	;
	; Set state to TSS_DEAD and set destruction timer.  Do not destroy
	; immediately so that we only have to process incoming SYNs for 
	; this connection once.  
	;
		call	TSocketLockInfoExcl
		mov	di, ds:[bx]
		mov	ds:[di].TS_state, TSS_DEAD
		mov	ds:[di].TS_destructTime, CONNECTION_DESTRUCT_TIME
		call	TSocketUnlockInfoExcl

	;
	; If connection already exists, return its connection handle.
	;
		cmp	ax, SDE_CONNECTION_EXISTS
		jne	error

		mov	ax, lport
		call	TSocketFindConnection		; ax = connection handle
		jnc	exit
error:
		clr	ax
		mov	bx, handle dgroup
		call	MemDerefDS
exit:
		push	ax
		mov	bx, ds:[regSem]
		call	ThreadVSem			; release access
		pop	ax
		.leave
		ret

TSOCKETPROCESSCONNECTREQUEST	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketDropAckedData

DESCRIPTION: 	Drop the number of bytes of sent data from the output 
		queue.  If the number of bytes to drop exceeds the amount
		of data that has been sent, and there is no unsent data
		left, and the state is disconnecting, then that means
		our fin was acked.  (Set finacked to nonzero, else leave 
		unchanged.) Returns the number of bytes actually dropped.  
		
RETURN:  	Actual number of bytes dropped.

C DECLARATION:	extern word _far
		_far _pascal TSocketDropAckedData(word connection, 
				word numBytes, word *finAcked);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETDROPACKEDDATA	proc	far	connection:word,
					numBytes:word,
					finAcked:fptr.word
		uses	di, si, ds
tcpSocket	local	fptr
		.enter
	;
	; Get the output queue.
	;	
		call	TSocketLockInfoExcl		; ds = segment
		mov	di, connection
		mov	di, ds:[di]			; ds:di = TcpSocket
		segmov	es, ds, si			; es:di = TcpSocket
		movdw	tcpSocket, esdi

		movdw	bxsi, es:[di].TS_output		; ^lbx:si = output queue
		call	MemLock				
		mov	ds, ax				; *ds:si = output queue
	; 
	; Compute remaining bytes in output queue.
	;
		push	bx
		mov	bx, ds:[si]			; ds:si = output q hdr
		mov	ax, ds:[bx].TOQH_size
		mov	cx, numBytes		

		sub	ax, cx				; ax = remaining bytes
		jnc	dropData			; output size >= # acked
	;
	; Acked bytes exceed size of ouput queue.  If disconnecting, 
	; our fin has been acked.  otherwise, it was our SYN.
	;		
		add	cx, ax				; cx = bytes to drop
		clr	ax				; reset remaining bytes
		cmp	es:[di].TS_state, TSS_DISCONNECTING
		jne	dropData

		les	di, finAcked
		mov	{word}es:[di], TRUE		; non-zero		
dropData:
	;		
	; Drop data buffers from the queue until numbytes has been
	; dropped.  
	;
		mov_tr	dx, ax				; dx = new output size
		mov	ds:[bx].TOQH_size, dx		; store new size
		jcxz	doneDropping

		mov	ax, cx				; ax = bytes to drop
		mov	bx, cs
		mov	di, offset TSocketDropAckedDataCB
		call	ChunkArrayEnum			
doneDropping:		
		pop	bx				; ^hbx = output queue
		call	MemUnlock			; unlock output queue
		mov_tr	ax, cx				; ax = bytes dropped 
	;
	; See if there is any send data waiting for space in the output 
	; queue.  Only wake the waiter if output size is below maximum.
	;
		lds	di, tcpSocket
		tst	ds:[di].TS_pendingData		; anybody waiting?
		je	done				

		cmp	dx, ds:[di].TS_maxData		
		jae	done				

		add	dx, ds:[di].TS_pendingData	
		jc	done	

		clr	bx
		mov	ds:[di].TS_pendingData, bx
		xchg	bx, ds:[di].TS_sendSem
		call	ThreadVSem		
done:
		call	TSocketUnlockInfoExcl
		
		
		.leave
		ret

TSOCKETDROPACKEDDATA		endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketHasUrgentData

DESCRIPTION: 	Inform socket library that urgent data exists and deliver
		the byte of urgent data.

C DECLARATION:	extern void _far
		_far _pascal TSocketHasUrgentData (word connection, 
					byte *urgData);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETHASURGENTDATA	proc	far	connection:word,
					urgData:fptr.byte
		
		uses	di, si, ds
		.enter
		
		mov	bx, handle dgroup
		call	MemDerefDS
		
		mov	di, SCO_RECEIVE_URGENT_DATA
		mov	cx, 1			; single byte urgent data only
		mov	ax, connection 
		mov	bx, ds:[clients].TCI_data.CI_domain
		pushdw	ds:[clients].TCI_data.CI_entry
		lds	si, urgData		; ds:si = urgent byte
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		.leave
		ret

TSOCKETHASURGENTDATA	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketGetOutputSize

DESCRIPTION: 	Return the total amount of output data for the socket.

C DECLARATION:	extern word _far
		_far _pascal TSocketGetOutputSize(word connection);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETGETOUTPUTSIZE	proc	far	connection:word

		uses	si, ds
		.enter
		
		call	TSocketLockInfoShared		; ds = segment
		mov	si, connection
		mov	si, ds:[si]			; ds:si = TcpSocket

		movdw	bxsi, ds:[si].TS_output		; ^lbx:si = output queue
		call	MemLock
		mov	ds, ax				; *ds:si = output q
		mov	si, ds:[si]			; ds:si = output q hdr
		
		mov	ax, ds:[si].TOQH_size
		
		call	MemUnlock			; unlock output queue
		call	TSocketUnlockInfoShared

		.leave
		ret

TSOCKETGETOUTPUTSIZE	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketGetOutputData

DESCRIPTION: 	Copy specified amount of output data to the passed buffer.

RETURN:		number of bytes copied to the buffer

C DECLARATION:	extern void _far
		_far _pascal TSocketGetOutputData(byte *buffer, 
				word off, word len, word connection);

STRATEGY:
		Find start of data to copy.  ("off" indicates offset
			into output queue's data at which to start)

		Copy the data
		
		Return the total number of bytes copied.   

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETGETOUTPUTDATA	proc	far	buffer:fptr.byte,
					off:word,
					len:word,
					connection:word
		uses	di, si, ds
		.enter
	;
	; Get the output queue.
	;
		call	TSocketLockInfoExcl		; ds = segment
		mov	si, connection
		mov	si, ds:[si]			; ds:si = TcpSocket

		movdw	bxsi, ds:[si].TS_output		; ^lbx:si = output queue
		call	MemLock
		mov	ds, ax				; *ds:si = output queue
	;
	; Copy the data to the buffer.  "off" indicates offset into 
	; output queue's data at which to start copying.
	;
		mov	dx, off
		mov	cx, len				

EC <		push	cx						      >
EC <		mov	di, ds:[si]			; ds:di = output q hdr>
EC <		add	cx, dx						      >
EC <		cmp	cx, ds:[di].TOQH_size				      >
EC <		ERROR_A TCPIP_NOT_ENOUGH_OUTPUT_DATA			      >
EC <		pop	cx						      >

 		movdw	esdi, buffer			; es:di = buffer
		call	TSocketCopyOutputData		

		call	MemUnlock
		call	TSocketUnlockInfoExcl

		.leave
		ret
		
TSOCKETGETOUTPUTDATA	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketRecvUdpInput

DESCRIPTION: 	Deliver UDP data to the socket library.
		
C DECLARATION:	extern word _far
		_far _pascal TSocketRecvUdpInput(optr dataBuffer);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/14/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETRECVUDPINPUT	proc	far	dataBuffer:optr
		uses	di
		.enter
	;
	; Make sure we have a data client.  If not, load socket library.
	;
		mov	bx, ds:[regSem]
		call	ThreadPSem

		test	ds:[regStatus], mask RS_DATA
		jnz	deliver

		mov	dl, SDT_DATA
		call	TSocketLoadSocketLibrary
		jnc	deliver

		mov	cx, SDE_DESTINATION_UNREACHABLE
		jmp	exit
deliver:
	;
	; Deliver datagram to data client.  
	;
		movdw	bxdx, dataBuffer
		mov	di, TCI_data

		mov	cl, PacketFlags <0, 0, PT_DATAGRAM>
		call	TSocketSetHeaderAndDeliver	
		clr	cx			; delivered
exit:
		mov	bx, ds:[regSem]
		call	ThreadVSem
		mov_tr	ax, cx			; ax = result
		.leave
		ret

TSOCKETRECVUDPINPUT	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketRecvRawInput

DESCRIPTION: 	Deliver Raw Ip datagram to raw Ip client.
		
C DECLARATION:	extern void _far
		_far _pascal TSocketRecvRawInput(optr dataBuffer);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/10/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETRECVRAWINPUT		proc	far	dataBuffer:optr
		uses	di, ds
		.enter
	;
	; Make sure we have a raw ip client.  If not, drop packet.
	;
		mov	bx, handle dgroup
		call	MemDerefDS

		test	ds:[regStatus], mask RS_RAW_IP
		jnz	deliver

		movdw	axcx, dataBuffer
		call	HugeLMemFree
		jmp	exit
deliver:
		movdw	bxdx, dataBuffer
		mov	di, TCI_rawIp
		mov	cl, mask RIF_IP_HEADER		; IP header included
		call	TSocketSetHeaderAndDeliver
exit:
		.leave
		ret

TSOCKETRECVRAWINPUT	endp
	SetDefaultConvention


COMMENT @----------------------------------------------------------------

C FUNCTION:	TSocketNotifyError

DESCRIPTION: 	Deliver UDP error to the socket library.
		
C DECLARATION:	extern void _far
		_far _pascal TSocketNotifyError(word code, word lport);

NOTE:		Take advantage of DS being dgroup as we are called from 
		C code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	10/10/94		Initial version
-------------------------------------------------------------------------@
	SetGeosConvention
TSOCKETNOTIFYERROR	proc	far	code:word,
					lport:word
		uses	di
		.enter

	;
	; No use complaining if nobody is there to listen...
	;		
		test	ds:[regStatus], mask RS_DATA
		jz	exit
	;
	; Whine.
	;		
		mov	di, SCO_EXCEPTION
		mov	ax, code
		mov	bx, lport
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		mov	dx, ds:[clients].TCI_data.CI_domain
		movdw	bxax, ds:[clients].TCI_data.CI_entry
		call	ProcCallFixedOrMovable
exit:
		.leave
		ret
TSOCKETNOTIFYERROR	endp
	SetDefaultConvention

;---------------------------------------------------------------------------
;		INTERNAL
;---------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketEnumConnections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call ChunkArrayEnum on the connections in the socket list
		using the given callback routine.

CALLED BY:	TSocketFindHandle
		TSocketFindConnection
		TSocketDoError

PASS:		di	= offset of callback routine in code segment
		paramters for callback 

RETURN:		depends on callback

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/24/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketEnumConnections	proc	near
		uses	bx, si, ds
		.enter

		call	TSocketLockInfoList	; *ds:si = socket list
		mov	bx, cs
		call	ChunkArrayEnum
		call	TSocketUnlockInfoExcl

		.leave
		ret
TSocketEnumConnections	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketSetHeaderAndDeliver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in several fields in PacketHeader and deliver to client.

CALLED BY:	TSOCKETRECVUDPINPUT, TSOCKETRECVRAWINPUT

PASS:		di	= offset to correct ClientInfo in TcpipClientInfo
		cl	= flags to set in PH_flags field
		^lbx:dx	= dataBuffer
		ds	= dgroup

RETURN:		nothing

DESTROYED:	bx, cx, dx, di	(preserved by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketSetHeaderAndDeliver	proc	near
		uses	si, es
		.enter
	;
	; Fill in domain handle in packet and set flags in packet header.
	;
		call	HugeLMemLock
		mov	es, ax
		mov	si, dx
		mov	si, es:[si]			; es:si = packet header

		mov	ax, ds:[clients][di].CI_domain
		mov	es:[si].PH_domain, ax
		mov	es:[si].PH_flags, cl
		call	HugeLMemUnlock
	;
	; Deliver to client.  Packet will be freed by client on error.
	;
		mov	cx, bx				; ^lcx:dx = data buffer
		movdw	bxax, ds:[clients][di].CI_entry
		mov	di, SCO_RECEIVE_PACKET
		call	ProcCallFixedOrMovable	

		.leave
		ret
TSocketSetHeaderAndDeliver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCopyOutputData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the output data to the passed buffer, starting at
		the specified location in the output queue.

CALLED BY:	TSocketGetOutputData

PASS:		*ds:si 	= output queue
		es:di	= buffer to copy data to
		cx	= max number of bytes to copy
		dx	= offset into output data to start copying from

RETURN:		nothing

DESTROYED:	cx, dx, di	(saved by caller)

PSEUDO CODE/STRATEGY:
		
		Use ChunkArrayEnum to go through the buffers.
		
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/10/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCopyOutputData	proc	near
		
		uses	bx, bp
		.enter

		mov	bp, di			; es:bp = dest buffer
		mov	bx, cs
		mov	di, offset TSocketCopyOutputDataCB
		call	ChunkArrayEnum		; cx = remaining bytes to copy

EC <		tst	cx							>
EC <		ERROR_NE TCPIP_INTERNAL_ERROR	; didn't copy requested bytes!	>
		
		.leave
		ret
TSocketCopyOutputData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCopyOutputDataCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy data from buffer if needed.

CALLED BY:	TSocketCopyOutputData via ChunkArrayEnum

PASS:		*ds:si	= output queue
		ds:di	= TOE_data
		cx	= # bytes to copy
		dx	= offset into data at which to start copying
		es:bp	= dest for data

RETURN:		carry set if done copying
		else
		cx	= remaining bytes to copy
		dx	= remaining offset
		es:bp	= dest for next part of data


DESTROYED:	bx, si, di	(allowed)

PSEUDO CODE/STRATEGY:
		Get buffer.
		if offset is greater than size of data in buffer,
			decrement offset by data size and return
		else 
			determine how many bytes to copy
			copy the bytes
			adjust remaining bytes to copy
			if no more bytes, return with carry set
			else
				adjust ptr in destination buffer
				set offset to zero
		unlock buffer
			
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	11/10/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCopyOutputDataCB	proc	far
		uses	ax, ds
		.enter
	;
	; Determine if any data should be copied.
	;
		movdw	bxdi, ds:[di].TOE_data	; ^lbx:di = optr of data buffer
		call	HugeLMemLock
		mov	ds, ax
		mov	di, ds:[di]		; ds:di = SPH of data buffer

		mov	ax, ds:[di].PH_dataSize

		cmp	dx, ax
		jb	copyData
	;
	; No copying.  Adjust offset and unlock buffer.
	;
		sub	dx, ax			; dx = remaining offset
EC <		ERROR_C	TCPIP_INTERNAL_ERROR	; offset cannot be negative! >
		jmp	unlockBuffer
copyData:
	;
	; Get ptrs to data and destination buffer.
	;		
		add	di, ds:[di].PH_dataOffset 
						; ds:di = start of buffer's data
		add	di, dx			; ds:di = start of desired data
		mov	si, bp			; es:si = dest buffer
		xchg	di, si			; es:di = dest for data
						; ds:si = data to copy
	;
	; Compute # of bytes to copy.
	;
		sub	ax, dx			; ax = bytes in buffer after
						;        the offset
		mov	dx, cx			; dx = save total bytes to copy
		cmp	cx, ax			; enough data in buffer?
		jbe	copy			; yes
		
		mov_tr	cx, ax			; cx = bytes available for copy
copy:
		sub	dx, cx			; dx = remaining bytes to copy
		shr	cx, 1
		rep	movsw
		jnc	checkDone
		movsb
checkDone:
		mov	cx, dx			; cx = remaining bytes to copy
		clr	dx			; no more offset
		mov	bp, di			; es:bp = end of copied data
		
		stc				; assume done
		jcxz	unlockBuffer
		
		clc				; more to copy...
unlockBuffer:
		call	HugeLMemUnlock		; preserves flags

		.leave
		ret

TSocketCopyOutputDataCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketGetConnectionDomain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the connection is using the TCP/IP driver
		as a link or data driver and return the appropriate 
		domain handle.

CALLED BY:	TSOCKETRECVINPUT
		TSOCKETGETRECVWIN

PASS:		cx	= connection handle

RETURN:		bx	= domain handle for connection
		carry set if data domain

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/25/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketGetConnectionDomain	proc	near
		uses	si, ds, es
		.enter

		mov	bx, handle dgroup
		call	MemDerefES
		
		call	TSocketLockInfoShared	; ds = segment of socket block
		mov	si, cx			; si = connection handle
		mov	si, ds:[si]		; ds:si = TcpSocket		

		tst_clc	ds:[si].TS_input.handle	
		jne 	link
		
		mov	bx, es:[clients].TCI_data.CI_domain		
		stc
		jmp	unlock
link:
		mov	bx, es:[clients].TCI_link.CI_domain ; carry is clear
unlock:				
		call	TSocketUnlockInfoShared

		.leave
		ret
TSocketGetConnectionDomain	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketLoadSocketLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load and register socket library, saving socket library's
		handle and entry point for SCO functions and the domain
		handle of this driver in dgroup.  

CALLED BY:	TSOCKETPROCESSCONNECTREQUEST
		TSOCKETRECVUDPINPUT
		TSOCKETISCONNECTED

PASS:		ds	= dgroup
		dl	= type of registration to use (SocketDriverType)

RETURN:		carry set if unable to load socket library
		else carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Load socket library
		verify protocol
		if error, unload it, return failure
		else add domain of passed driver type
		unload socket library to remove our reference to it
		return success

NOTE: 		Caller MUST have P-ed the regSem to gain exclusive
		access for updating the driver's client information.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/22/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString	socketLibName,	<"socketec.geo", 0> 	>
NEC<LocalDefNLString	socketLibName,	<"socket.geo", 0>	>

TSocketLoadSocketLibrary	proc	near
		uses	ax, bx, cx, dx, di, si, ds, es
connType	local	byte		
libHandle	local	word
		.enter	
	;
	; Load the socket library.
	;
		mov	connType, dl
		segmov	es, ds, ax			; es = dgroup

		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		jc	restoreDir

		clr	ax, bx				; any protocol
		segmov	ds, cs, si
		mov	si, offset socketLibName		
		call	GeodeUseLibrary			; bx = handle of library
restoreDir:
		call	FilePopDir
		jc	exit

		mov	libHandle, bx
	;
	; Verify protocol of socket library is compatible with driver.
	;
		mov	ax, enum SocketRegister
		call	ProcGetLibraryEntry	; bxax = vfptr of SocketRegister
		mov	di, SCO_GET_PROTOCOL
		call	ProcCallFixedOrMovable	; cx = major protocol
						; dx = minor protocol
		cmp	cx, TCPIP_PROTO_MAJOR
		jne	bad
		cmp	dx, TCPIP_PROTO_MINOR
		ja	bad
	;
	; Register with socket library as specified type of driver.
	;
		mov	bx, libHandle
		mov	dl, connType
		call	TSocketRegisterSocketLibrary 	
		jmp	unload
bad:
		stc
unload:
	;
	; Unload socket library, even if successful, to remove tcp's
	; reference to it. 
	;		
		pushf
		mov	bx, libHandle
		call	GeodeFreeLibrary
		popf
exit:
		.leave
		ret

TSocketLoadSocketLibrary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketRegisterSocketLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register with the socket library as both a link and data
		driver, if not already registered.

CALLED BY:	TSocketLoadSocketLibrary

PASS:		es	= dgroup
		bx	= socket library handle
		dl	= SocketDriverType

RETURN:		carry set if error

DESTROYED:	ax, bx, cx, dx, di, si, ds (preserved by caller)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/25/94			Initial version
	PT	7/24/96			DBCS'ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketRegisterSocketLibrary	proc	near
		uses	bp
		.enter
	;
	; Get address of SocketRegister routine.
	;		
		mov	ax, enum SocketRegister
		call	ProcGetLibraryEntry	; bxax = vfptr of SocketRegister
	;
	; Determine client handle to assign and where info will be stored.
	;
		mov	cx, mask RS_DATA		; assume data client
		mov	di, TCI_data
		cmp	dl, SDT_DATA
		je	register
		mov	cx, mask RS_LINK		
		mov	di, TCI_link
register:
		push	es, di, cx		; save dgroup, client info and
						;   client handle 
		pushdw	bxax			; for proccallfixedormovable...
	;
	; Get domain name and add the domain to the socket library.
	;
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, offset tcpipDomainString
		cmp	dl, SDT_DATA
		je	gotString
		mov	si, offset linkDomainString 
gotString:
		mov	si, ds:[si]			; ds:si = domain name
		
		mov	bx, segment TcpipStrategy
		mov	es, bx
		mov	bx, offset TcpipStrategy	; es:bx = TcpipStrategy
		
		mov_tr	ax, cx				; ax = client handle
		mov	cx, (TCPIP_SEQUENCED_PACKET_HDR_SIZE shl 8) or \
					TCPIP_DATAGRAM_PACKET_HDR_SIZE
		
		mov	bp, handle 0
		mov	di, SCO_ADD_DOMAIN
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; bx = link domain
							; cx:dx = sco entry
		pop	es, di, ax			
		jc	done

		ornf	es:[regStatus], ax
		mov	es:[clients][di].CI_domain, bx
		movdw	es:[clients][di].CI_entry, cxdx
		clc
done:
		mov	bx, handle Strings
		call	MemUnlock

		.leave
		ret
TSocketRegisterSocketLibrary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketFindHandleCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare passed connection handle to one in TcpSocketElt.

CALLED BY:	TSocketFindHandle via ChunkArrayEnum

PASS:		ax	= connection handle
		*ds:si 	= socket list
		ds:[di]	= TcpSocketElt

RETURN:		carry set if found
		cx = element # whose handle matched
		else carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketFindHandleCB	proc	far
		uses	ax, di
		.enter

		cmp	ax, ds:[di].TSE_socket		; ^ldi = connection
		jne	noMatch
		
		call	ChunkArrayPtrToElement		; ax = elt number
		mov_tr	cx, ax				; cx = elt number
		stc					; found it
		jmp	exit
noMatch:
		clc
exit:		
		.leave
		ret
TSocketFindHandleCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketFindConnectionCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if this connection is the one being looked for.

CALLED BY:	TSocketFindConnection via ChunkArrayEnum
		TSocketCheckDuplicateNoLock via ChunkArrayEnum

PASS:		*ds:si 	= socket list
		ds:di 	= TcpSocketElt
		ax	= local port number 
		dx	= remote port number 
		cxbp	= remote IPAddr  
 
RETURN:		carry set if found
		ax	= connection handle
		else carry clear
		ax unchanged

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

NOTES:
		Socket info block is already locked by caller.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketFindConnectionCB	proc	far
		uses	bx, di
		.enter
	;
	; Get the connection handle and deref the socket data.
	;	
		mov	bx, ds:[di].TSE_socket		; bx = connection handle
		mov	di, ds:[bx]			; ds:di = TcpSocket
	;
	; Compare the local port number, remote port number, and remote
	; IPAddr, stopping after first mismatch.
	;
		cmp	ax, ds:[di].TS_localPort
		jne	noMatch
		
		cmp	dx, ds:[di].TS_remotePort
		jne	noMatch	

		cmpdw	cxbp, ds:[di].TS_remoteAddr	
		jne	noMatch

		stc					; found it		
		mov_tr	ax, bx
		jmp	exit
noMatch:
		clc		
exit:		
		.leave
		ret
TSocketFindConnectionCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketFindSocketOfDomainCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the connection is of the specified domain.

CALLED BY:	TSocketFindSocketOfDomain via ChunkArrayEnum

PASS:		*ds:si 	= socket list
		ds:di	= TcpSocketElt
		ax	= SocketDriverType

RETURN:		carry set if found

DESTROYED:	di (allowed)

PSEUDO CODE/STRATEGY:
		Don't bother checking if connection is dead.

		Determine the type of the connection.  Then compare 
		against the opposite type of the connection so that
		carry will be clear if we DON'T find what we want.
	
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	3/28/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketFindSocketOfDomainCB	proc	far

		mov	di, ds:[di].TSE_socket		; di = connection handle
		mov	di, ds:[di]			; ds:di = TcpSocket

		cmp	ds:[di].TS_state, TSS_DEAD
		je	exit

		tst	ds:[di].TS_input.handle
		jne	isLink

		cmp	ax, SDT_LINK			
		jmp	checkFound
isLink:
		cmp	ax, SDT_DATA
checkFound:
		je	exit				; not found
		stc
exit:
		ret
TSocketFindSocketOfDomainCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCheckLinkBusyCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the connection is using the given link.

CALLED BY:	TSocketCheckLinkBusy via ChunkArrayEnum

PASS:		*ds:si	= socket list
		ds:di	= TcpSocketElt
		ax	= link domain handle

RETURN:		carry set if connection uses link 

DESTROYED:	di (allowed)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/12/95			Initial version
	jwu	10/3/95			Do not count dead connections

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCheckLinkBusyCB	proc	far

		mov	di, ds:[di].TSE_socket
		mov	di, ds:[di]			; ds:di = TcpSocket

		cmp	ds:[di].TS_state, TSS_DEAD
		je	exit				

		cmp	ax, ds:[di].TS_link
		cmc					; sets carry if equal
		je	exit
		clc					
exit:
		ret
TSocketCheckLinkBusyCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCreateOutputQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the output queue and initialize the header.

CALLED BY:	TSocketCreateConnection

PASS:		nothing

RETURN:		carry set if error
		else 
		^lbx:cx = optr to output queue

DESTROYED:	bx, cx, if not returned

PSEUDO CODE/STRATEGY:
		Cannot allocate this in the huge lmem block or bad things
		will happen if a tcb happens to be allocated in the same
		block as an output queue.  Output queue may move the 
		block when new data is added.
		
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCreateOutputQueue	proc	near
		mov	bx, size TcpOutputElt
		mov	cx, size TcpOutputQueueHeader
		call	TSocketCreateQueue
		ret
TSocketCreateOutputQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCreateInputQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the input queue.

CALLED BY:	TSocketCreateConnection

PASS: 		nothing

RETURN:		carry set if error
		else 
		^lbx:cx = input queue

DESTROYED:	bx, cx if not returned

PSEUDO CODE/STRATEGY:
		Cannot allocate this in the huge lmem block or BAD things
		will happen if a tcb happens to be allocated in the same
		block as an input queue.  Input queue may move the block
		when new data is received, invalidating the C code.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/26/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCreateInputQueue	proc	near
		mov	bx, size TcpLinkInputElt
		mov	cx, size TcpLinkInputHeader
		call	TSocketCreateQueue
		ret
TSocketCreateInputQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCreateQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a queue with the given headers.

CALLED BY:	TSocketCreateSocketList
		TSocketCreateOutputQueue
		TSocketCreateInputQueue

PASS:		bx	= size of queue elements
		cx	= size of queue header

RETURN:		carry set if error
		else
		^lbx:cx = queue

DESTROYED:	bx, cx, if not returned

PSEUDO CODE/STRATEGY:
		Create a chunk array in an lmem block.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/26/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCreateQueue	proc	near
		uses	ax, si, ds
eltSize		local	word		push	bx
hdrSize		local	word		push	cx		
		.enter
	;
	; Allocate the LMem block for the queue and make sure
	; we own it.
	;
		mov	ax, LMEM_TYPE_GENERAL	
		clr	cx				; default block header
		call	MemAllocLMem			; bx <- block handle
	
		mov	ax, handle 0
		call	HandleModifyOwner
		
		mov	ax, mask HF_SHARABLE
		call	MemModifyFlags
	;
	; Create the chunk array.  Extra space initialized to zero's 
	; for us by ChunkArrayCreate.
	;
		push	bx
		call	MemLock				
		mov	ds, ax
		mov	bx, eltSize
		mov	cx, hdrSize
		clr	ax, si				; alloc a chunk
		call	ChunkArrayCreate		; *ds:si = array
		pop	bx				; ^lbx:si = array
		
		mov	cx, si				; ^lbx:cx = array
		call	MemUnlock
		jnc	exit
		
		call	MemFree
		stc
exit:
		.leave
		ret
TSocketCreateQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCreateTCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate space for the TCB.

CALLED BY:	TSocketStoreConnectionInfo

PASS:		ax	= connection handle
		ds:si	= TcpSocket

RETURN:		carry set if error
		bx, cx = garbage
		else carry clear and
		^lbx:cx = optr to TCB 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCreateTCB	proc	near
		uses	ax, dx, si, di, ds, es
		.enter
	;
	; Allocate the chunk in the HugeLMem block and then unlock the
	; new chunk.
	;
		mov	bx, handle dgroup
		call	MemDerefES

		push	ds				; save TcpSocket segment
		
		mov	ax, TCB_BLOCK_SIZE
		mov	bx, es:[hugeLMemBlock]
		mov	cx, HUGELMEM_ALLOC_WAIT_TIME
		call	HugeLMemAllocLock		; ^lax:cx = chunk
							; ds:di = TCB
		push	ds
		pop	es				; es:di = TCB
		pop	ds				; ds:si = TcpSocket
		jc	exit
	;
	; Zero out and initialize the new TCP control block.
	;
		mov	bx, di				; save start of TCB
		
		push	ax, cx				; save chunk for TCB
		mov	cx, TCB_BLOCK_SIZE		; cx = TCB block size
		shr	cx, 1				; convert to words
EC <		ERROR_C	TCPIP_INTERNAL_ERROR		; use even block size!	>
		clr	ax				; store zeros
		rep	stosw

		pushdw	esbx				; pass TCB
		movdw	axcx, ds:[si].TS_localAddr
		pushdw	axcx				
		movdw	axcx, ds:[si].TS_remoteAddr
		pushdw	axcx				
		mov	ax, ds:[si].TS_localPort
		push	ax
		mov	ax, ds:[si].TS_remotePort
		push	ax
		call	TcpInitTCB			; only es,bp preserved

		pop	bx, cx				; ^lbx:cx = TCB chunk
		call	HugeLMemUnlock
		clc

exit:
		.leave
		ret
TSocketCreateTCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDestroyOutputQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the output queue, freeing any buffers in it.

CALLED BY:	TSocketDestroy

PASS:		ds:si 	= TcpSocket

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Free each data buffer in the list.  There may be some if
		this connection was terminated by a reset or error.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDestroyOutputQueue	proc	near
		uses	ax, bx, cx, di, si, ds
		.enter

if ERROR_CHECK
		cmp	ds:[si].TS_state, TSS_OPEN		
		ERROR_E	TCPIP_BAD_SOCKET_STATE			

	;
	; Waking up the blocked sender would lead to awful memory 
	; trashing as sender tries to access the socket after its 
	; destroyed.  This EC code is mainly to detect any weird
	; case of a send still being blocked so that a workaround
	; can be made.
	;
		tst	ds:[si].TS_pendingData			
		ERROR_NE TCPIP_SEND_DATA_CALL_IN_PROGRESS	
endif
	;
	; Free all buffers in the output queue and the queue itself.
	;
		movdw	bxsi, ds:[si].TS_output		; ^lbx:si = output queue
		
		push	bx
		call	MemLock				
		mov	ds, ax				; *ds:si = output queue

 		mov	bx, cs
		mov	di, offset TSocketDestroyOutputQueueCB
		call	ChunkArrayEnum			; ax, cx destroyed

		pop	bx
		call	MemFree		

		.leave
		ret
TSocketDestroyOutputQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDestroyOutputQueueCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the data buffer in this element.

CALLED BY:	TSocketDestroyOutputQueue via ChunkArrayEnum

PASS:		*ds:si 	= output queue
		ds:di 	= TcpOutputElt

RETURN:		carry clear (enumerate all)

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDestroyOutputQueueCB	proc	far

		movdw	axcx, ds:[di].TOE_data
		call	HugeLMemFree
		clc
		ret
TSocketDestroyOutputQueueCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDestroyInputQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the input queue, freeing any buffers in it.

CALLED BY:	TSocketDestroy

PASS:		ds:si	= TcpSocket

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Free each data buffer in the list.  There may be some
		if this connection was terminated by a reset or error.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/26/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDestroyInputQueue	proc	near
		uses	ax, bx, cx, si, ds
		.enter

		movdw	bxsi, ds:[si].TS_input		; ^lbx:si = input queue
		push	bx
		call	MemLock
		mov	ds, ax				; *ds:si = input queue

		mov	bx, cs
		mov	di, offset TSocketDestroyInputQueueCB
		call	ChunkArrayEnum			; ax, cx destroyed

		pop	bx
		call	MemFree

		.leave
		ret
TSocketDestroyInputQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDestroyInputQueueCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the data buffer in this element.

CALLED BY:	TSocketDestroyInputQueue via ChunkArrayEnum

PASS:		*ds:si 	= input queue
		ds:di 	= TcpLinkInputElt

RETURN:		carry clear so all elts will be processed

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/26/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDestroyInputQueueCB	proc	far
		movdw	axcx, ds:[di].TLIE_data
		call	HugeLMemFree
		clc
		ret
TSocketDestroyInputQueueCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDestroyTCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the chunk for the TCB

CALLED BY:	TSocketDestroy

PASS:		ds:si	= TcpSocket

RETURN:		nothing

DESTROYED:	es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/12/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDestroyTCB	proc	near
		uses	ax, bx, cx, dx, si, di, ds
		.enter
	;
	; Free up memory used by the TCP control block, including the
	; TCB itself.
	;
		pushdw	ds:[si].TS_tcb	; pass optr of TCB
		call	TcpFreeTCB	; may destroy all but bp

		.leave
		ret
TSocketDestroyTCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDoErrorCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the connection is connected to specified remote
		address, process an error for it.

CALLED BY:	TSOCKETDOERROR via ChunkArrayEnum.

PASS:		ax	= error code
		cxdx	= IPAddr of remote
		*ds:si 	= socket list
		ds:di	= TcpSocketElt

RETURN:		carry clear  (process ALL connections)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/20/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDoErrorCB	proc	far
		uses	ax, bx, cx, dx, di, si, ds, es
		.enter
	;
	; Determine if this socket is connected to the remote addr.
	; 
		mov	bx, ds:[di].TSE_socket		; bx = connection handle
		mov	bx, ds:[bx]			; ds:bx = TcpSocket

		cmpdw	cxdx, ds:[bx].TS_remoteAddr	
		jne	exit
	;
	; Process an error for this connection.
	;
		pushdw	dsbx				; pass ptr to TcpSocket 
		pushdw	ds:[bx].TS_tcb			; pass optr of TCB
		push	ax				; pass code
		call	TcpError	; may destroy all but bp
exit:
		clc
		.leave
		ret
TSocketDoErrorCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDestructTimeoutCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement destruct timers if connection is dead.
		If timeout occurs, destroy the connection.

CALLED BY:	TSocketTimeoutHandler via ChunkArrayEnum

PASS:		*ds:si 	= socket list
		ds:di	= TcpSocketElt

RETURN:		carry clear so all elements will be processed

DESTROYED:	es

PSEUDO CODE/STRATEGY:
		NOTE:  Does not call TSocketDestroyConnection because
		will result in deadlock when it tries to lock socket
		info block which is locked by caller.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/ 1/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDestructTimeoutCB	proc	far
		uses	ax, bx
		.enter
	;
	; If socket is not DEAD, do nothing.
	;
		mov	bx, ds:[di].TSE_socket	; bx = connection handle
		mov	ax, bx			; ax = connection handle
		mov	bx, ds:[bx]		; ds:bx = TcpSocket
		cmp	ds:[bx].TS_state, TSS_DEAD
		jne	done
	;
	; Decrement the destruct timer if set.  Destroy socket if 
	; timer expires.
	;
		tst	ds:[bx].TS_destructTime
		je	done

		dec	ds:[bx].TS_destructTime
		jnz	done

		mov	bx, ax			; bx = connection handle
		call	TSocketDestroy		
done:
		clc		
		.leave
		ret

TSocketDestructTimeoutCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			    TSocketDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys the connection by deleting it from the socket list,
		freeing the semaphore, TCB, output queue and the chunk for
		the socket itself.

CALLED BY:	TSocketDestructTimeoutCB
		TSocketDestroyConnection

PASS:		*ds:si	= socket list
		ds:di 	= TcpSocketElt
		bx	= connection handle

RETURN:		nothing

DESTROYED:	ax, es

PSEUDO CODE/STRATEGY:

NOTE:	Socket info block MUST be locked exclusively by caller.
	
	Can no longer have EC code to check the state because
	connection can be interrupted before it has connected.
	Code simply destroys the connection without setting the
	state first.
	
		
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/31/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDestroy		proc	near
		uses	si, bx
		.enter

		call	ChunkArrayDelete
	
		mov	si, ds:[bx]		; ds:si = TcpSocket

EC <		tst	ds:[si].TS_waiter				>
EC <		ERROR_NE TCPIP_CANNOT_DESTROY_CONNECTION		>
		
		mov_tr	ax, bx			; ax = connection handle
		mov	bx, ds:[si].TS_sem
		call	ThreadFreeSem

		call	TSocketDestroyOutputQueue
		tst	ds:[si].TS_input.handle
		je	destroyTcb
		call	TSocketDestroyInputQueue
destroyTcb:
		tst	ds:[si].TS_tcb.handle
		je	afterTCB
		call	TSocketDestroyTCB
afterTCB:
		call	LMemFree

		.leave
		ret
TSocketDestroy		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDropAckedDataCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Drop specified amount of data that has been sent.  

CALLED BY:	TSOCKETDROPACKEDDATA via ChunkArrayEnum

PASS:		*ds:si	= output queue
		ds:di	= output queue element
		ax	= # bytes to drop

RETURN:		ax	= # bytes remaining to drop
		carry set if done

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Deref the data buffer
		Find the size of data in the buffer
		Calculate amount to drop:
			min(bytes to drop, data buffer size)
		if (amount to drop == data buffer size)
			free buffer
			decrement unsent index in output queue header
		else
			increment dataOffset by amount dropped (in dwords)
			decrement dataSize by amount dropped
		compute remaining acked bytes to drop
		stop if no more bytes to drop 
				
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/26/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDropAckedDataCB	proc	far
		uses	bx, cx, dx
		.enter
	;
	; Drop the data from the buffer.  If buffer freed, delete entry
	; in output queue.
	;
		movdw	bxdx, ds:[di].TOE_data		; ^lbx:bp = data buffer
		call	TSocketDropData			; cx = # bytes dropped
		jnc	whatsLeft

		call	ChunkArrayDelete
whatsLeft:
	;
	; Compute number of remaining bytes to drop.
 	;
		sub	ax, cx			; ax = remaining bytes to drop
EC <		ERROR_C	TCPIP_INTERNAL_ERROR	; dropped too many bytes :( >	
		
		jnz	exit			; any more? (carry is clear)
		stc				; all done...
exit:		
		.leave
		ret
TSocketDropAckedDataCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDropData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Drop data from a buffer, freeing it if no data is left.

CALLED BY:	TSocketDropAckedDataCB

PASS:		^lbx:dx	= data buffer
		ax	= # bytes acked

RETURN:		cx	= # bytes dropped
		carry set if buffer freed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/26/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDropData	proc	near
		uses	ax, di, ds
		.enter
	;
	; Find out size of data in buffer.
	;
		mov_tr	cx, ax				; cx = # bytes acked
		
		call	HugeLMemLock
		mov	ds, ax
		mov	di, dx				; *ds:di = data buffer
		mov	di, ds:[di]			; ds:di = data buffer
		mov	ax, ds:[di].PH_dataSize
	;
	; Calculate the amount of data to drop.  This is the minimum of 
	; the data buffer size and the # of bytes acked.
	;
		cmp	cx, ax				; acked <= buffer size?
		jbe	drop

		mov	cx, ax				; cx = buffer size
drop:
	;
	; Drop the bytes from the data buffer.  If all the data
	; in the buffer is to be dropped, just free the buffer.
	; CX = bytes to drop.
	;
		add	ds:[di].PH_dataOffset, cx

		sub	ax, cx				; ax = remaining bytes
		mov	ds:[di].PH_dataSize, ax
		call	HugeLMemUnlock			; preserves flags
		jnz	exit				; carry already clear
	;
	; All data in buffer has been dropped so free it.
	;
		push	cx				
		movdw	axcx, bxdx
		call	HugeLMemFree
		pop	cx				; cx = bytes dropped
		stc
exit:
		.leave
		ret
TSocketDropData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketMarkPacketBoundary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a 2 byte at the start of the packet to indicate
		the data size.  Size does not include the 2 bytes.

CALLED BY:	TSocketNewOutputData

PASS:		cx	= size of data in buffer
		^ldx:bp	= optr of data buffer

RETURN:		cx	= new data size

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/28/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketMarkPacketBoundary	proc	near
		uses	ax, bx, di, si, ds
		.enter
		
		mov	bx, dx				; ^lbx:bp = buffer
		call	HugeLMemLock
		mov	ds, ax
		mov	di, ds:[bp]			; ds:di = SPH
	;
	; Fill in 2-byte size in data, adjusting dataOffset and dataSize.
	;
		mov	ax, ds:[di].PH_dataOffset
		dec	ax
		dec	ax				
		mov	ds:[di].PH_dataOffset, ax	; new data offset

		mov	si, di
		add	si, ax				; ds:di = data
		mov	ds:[si], cx			; store boundary marker

		inc	cx
		inc	cx
		mov	ds:[di].PH_dataSize, cx		; new data size

		call	HugeLMemUnlock

		.leave
		ret
TSocketMarkPacketBoundary	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketRecvLinkInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore packet boundaries in the input and deliver 
		each complete packet to socket library.

CALLED BY:	TSOCKETRECVINPUT

PASS:		^lbx:dx	= optr of input buffer
		cx	= connection handle

RETURN:		cx	= amount of buffered input

DESTROYED:	ax, bx, dx (preserved by caller)

PSEUDO CODE/STRATEGY:
		Find out size of data in buffer 
		If no data, discard buffer and get amount of buffered input
		
		Increment bytesRecvd by amount of new data
		Append input buffer to chunk array of input data

		Check for complete packets.
		Return amount of buffered input

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/28/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketRecvLinkInput	proc	near
		uses	di, ds, es
connection	local	word		push	cx		
		.enter
	;
	; Determine size of input data in buffer.
	;
		call	HugeLMemLock
		mov	es, ax				
		mov	di, dx
		mov	di, es:[di]			; es:di = packet header
		mov	cx, es:[di].PH_dataSize
		call	HugeLMemUnlock
		jcxz	freeBuffer	
	;
	; Append input buffer to input array.  
	;
		call	TSocketLockInfoShared
		mov	si, connection
		mov	si, ds:[si]			; ds:si = TcpSocket
		push	cx				; save size
		mov	cx, bx				; ^lcx:dx = input buffer
		movdw	bxsi, ds:[si].TS_input
		call	MemLock
		mov	ds, ax				; *ds:si = input array

		call	ChunkArrayAppend		; ds:di = new element
		movdw	ds:[di].TLIE_data, cxdx
	;
	; Update bytesRecvd.
	;		
		pop	cx				; cx = data size
		mov	di, ds:[si]			; ds:di = array header
		add	ds:[di].TLIH_bytesRecvd, cx
	;
	; Check for complete packets and deliver them to socket library.
	;
		mov	dx, connection
		call	TSocketUnlockInfoShared

		call	TSocketDeliverLinkInput		; cx = # bytes recvd
		call	MemUnlock
exit:
		.leave
		ret
freeBuffer:
	;
	; Free buffer and get amount of buffered input.
	;
		movdw	axcx, bxdx
		call	HugeLMemFree

		call	TSocketLockInfoShared
		mov	si, connection
		mov	si, ds:[si]			; ds:si = TcpSocket
		movdw	bxsi, ds:[si].TS_input
		call	TSocketUnlockInfoShared

		call	MemLock
		mov	ds, ax				; *ds:si = input array
		mov	di, ds:[si]			; ds:si = array header
		mov	cx, ds:[di].TLIH_bytesRecvd
		call	MemUnlock
		jmp	exit

TSocketRecvLinkInput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketDeliverLinkInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check input data to see if any complete packets
		are ready to be delivered to the socket library.

CALLED BY:	TSocketRecvLinkInput

PASS:		*ds:si	= input chunk array
		ds:di	= TcpLinkInputHeader
		dx	= connection

RETURN:		cx	= # bytes buffered in link input

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	loop:	If packetSize is zero 
			Set packetSize to 1st word of input data 
			decrement bytesRead
			drop 1st word of input data.

		If bytesRecvd >= packetSize
			allocate a data buffer and initialize SPH
			copy packetSize bytes to new buffer, dropping
				bytes copied from input data and
				decrementing bytesRecvd accordingly
			deliver packet to socket library
		If bytesRecvd > 0, loop


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/28/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketDeliverLinkInput	proc	near
		uses	ax, bx, dx, di, es
newBuffer 	local	optr		
		.enter
	
		mov	bx, handle dgroup
		call	MemDerefES
	
	;
	; Get packetSize from input data if not already set.
	;		
		mov	ax, ds:[di].TLIH_packetSize
		tst	ax
		jne	haveSize
inputLoop:
		call	TSocketGetPacketSize		; ax = size
		LONG	jc	done
		mov	ds:[di].TLIH_packetSize, ax
haveSize:
	;
	; If input contains at least packetSize bytes, then there
	; is a complete packet.
	;		
		cmp	ax, ds:[di].TLIH_bytesRecvd
		ja	done
	;
	; Allocate a new data buffer of packetSize bytes and fill in 
	; packet header.
	;
		mov	cx, es:[clients].TCI_link.CI_domain
		push	ax, cx, ds
		add	ax, size SequencedPacketHeader
		mov	bx, es:[hugeLMemBlock]
		mov	cx, HUGELMEM_ALLOC_WAIT_TIME
		call	HugeLMemAllocLock		; ^lax:cx = buffer
							; ds:di = buffer
		movdw	newBuffer, axcx
		segmov	es, ds				; es:di = buffer
		pop	ax, cx, ds		; size, domain, array segment
		jc	done				

		mov	es:[di].PH_flags, PacketFlags <0, 0, PT_SEQUENCED>
		mov	es:[di].PH_dataOffset, \
				size SequencedPacketHeader
		mov	es:[di].PH_dataSize, ax
		mov	es:[di].PH_domain, cx
		mov	es:[di].SPH_link, dx	
		add	di, size SequencedPacketHeader	; es:di = place for data
	;
	; Copy packetSize bytes of input data into the new buffer.
	;
		push	ax, dx				
		call	TSocketCopyLinkInputData		
		movdw	bxdx, newBuffer
		call	HugeLMemUnlock
	;
	; Deliver the data.
	;		
		mov	cx, bx				; ^lcx:dx = data buffer
		mov	bx, handle dgroup
		call	MemDerefES
		mov	di, SCO_RECEIVE_PACKET
		movdw	bxax, es:[clients].TCI_link.CI_entry
		call	ProcCallFixedOrMovable
		pop	ax, dx				; ax = data size
							; dx = connection
	;
	; If we have more input data, check for more complete packets.
	;
		mov	di, ds:[si]			; ds:di = array hdr
		mov	ds:[di].TLIH_packetSize, 0
		sub	ds:[di].TLIH_bytesRecvd, ax
		LONG	jnz	inputLoop
done:
		mov	cx, ds:[di].TLIH_bytesRecvd
		.leave
		ret
TSocketDeliverLinkInput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketGetPacketSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get packet size from 1st word of input data.

CALLED BY:	TSocketDeliverLinkInput

PASS:		*ds:si	= input array
		ds:di	= input array header

RETURN:		carry clear if successful
		ax	= size
		else carry set

DESTROYED:	ax if not returned

PSEUDO CODE/STRATEGY:
		If input contains less than 2 bytes, return carry set.

		Decrement received bytes by 2.

		Use TSocketCopyLinkInputData to extract the first
		2 bytes of input data, dropping any buffers that 
		are left empty after reading the data.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/28/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketGetPacketSize	proc	near
		uses	di, es
theSize		local	word
		.enter
	;
	; Check if there is enough data.
	;
		mov	ax, size word
		cmp	ds:[di].TLIH_bytesRecvd, ax
		jb	exit				; carry already set

		sub	ds:[di].TLIH_bytesRecvd, ax
	;
	; Copy the first 2 bytes.  
	;
		segmov	es, ss
		lea	di, theSize			; es:di = dest for data
		call	TSocketCopyLinkInputData

		mov	ax, theSize
		clc	
exit:
		.leave
		ret
TSocketGetPacketSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSocketCopyLinkInputData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy input data to the passed buffer, dropping copied
		bytes from input.  Caller has already checked that the
		input contains enough bytes for the copy.

CALLED BY:	TSocketDeliverLinkInput
		TSocketGetPacketSize

PASS:		ax	= # bytes to copy
		es:di	= destination for data
		*ds:si	= input array

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	While there are bytes to copy{
		Get 1st input buffer
		if data in buffer <= bytes to copy
			copy entire buffer's data
			drop the buffer
			decrease bytes to copy by amount copied
		else	
			copy needed bytes
			advance dataOffset to drop copied bytes
			decrease dataSize by copied bytes
			unlock buffer
			return
	}
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/28/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSocketCopyLinkInputData	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter

		mov	dx, ax			; dx = # bytes to copy
copyLoop:	
	;
	; Get start of input.
	;				
		push	ds, si			; save array
		
		push	di			; save current buffer location
		clr	ax
		call	ChunkArrayElementToPtr	; ds:di = element
		
		movdw	bxbp, ds:[di].TLIE_data	; ^lbx:bp = input buffer
		call	HugeLMemLock		
		mov	ds, ax
		mov	si, ds:[bp]		; ds:si = SPH of input buffer
		pop	di			; es:di = dest for data
		
		push	ds, si			; save SPH 
		mov	ax, ds:[si].PH_dataSize
		add	si, ds:[si].PH_dataOffset ; ds:si = data
	;
	; Figure out how many bytes to copy.
	;
		mov	cx, dx			
		cmp	cx, ax			; enough bytes in buffer?
		jbe	haveSize		; yup
	
		mov	cx, ax			; buffer's data size
haveSize:
		push	cx
		shr	cx, 1			; get word size
		rep	movsw
		jnc	copied
		movsb				; copy odd byte
copied:
		pop	cx			; cx = bytes copied
		pop	ds, si			; ds:si = SPH of input buffer
	;		
	; Drop copied bytes from buffer.
	;		
		add	ds:[si].PH_dataOffset, cx
		sub	ds:[si].PH_dataSize, cx
EC <		ERROR_C TCPIP_INTERNAL_ERROR	; copied too many bytes!>
		call	HugeLMemUnlock		; preserves flags
		
		pop	ds, si			; *ds:si = input array
		jnz	done			; flag from subtracting data size
	;
	; Free buffer and remove from input array.
	;		
		sub	dx, cx			; dx = remaining bytes to copy
		movdw	axcx, bxbp
		call	HugeLMemFree
		
		clr	ax			
		mov	cx, 1			; just delete one
		call	ChunkArrayDeleteRange
		
		tst	dx			; any more to copy?
		jnz	copyLoop		; keep going...
done:		
		.leave
		ret
TSocketCopyLinkInputData	endp


TSOCKETCODE	ends

		



