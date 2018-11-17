COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Serial/IR communication
MODULE:		Loopback driver
FILE:		loopback.asm

AUTHOR:		Steve Jang, May 25, 1994

ROUTINES:

REVISION HISTORY:
    INT LoopbackStrategy        Strategy routine

    INT LoopbackInit            Strategy routine

    INT LoopbackExit            Strategy routine

    INT LoopbackDoNothing       Do nothing

    INT LoopbackRegister        Registers a client

    INT LoopbackUnregister      Unregister a client

    INT LoopbackLinkConnect     Establish link connection

    INT LoopbackDataConnect     Make a connection between two ports

    INT LoopbackDisconnect      Disconnection request

    INT LoopbackSendData        Send a sequenced data packet

    INT LoopbackSendDatagram    Send a datagram

    INT LoopbackAttach          Confirm a data connection

    INT LoopbackDetach          Reject an incoming connection

    INT LoopbackGetInfo         Get information about the driver

DESCRIPTION:

	This driver simply forwards the data passed in to a callback routine
passed in in registration routine(DR_SOCKET_REGISTER).  Only a single client
can use this driver at a given time.

	$Id: loopback.asm,v 1.1 97/04/18 11:57:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

DefLoopbackFunction   macro   routine, cnst
.assert ($-LoopbackFunctions) eq cnst*2, <function table is corrupted>
.assert (type routine eq far)
                fptr.far        routine
                endm

LoopbackFunctions	label	fptr.far
 DefLoopbackFunction LoopbackInit,		DR_INIT
 DefLoopbackFunction LoopbackExit,		DR_EXIT
 DefLoopbackFunction LoopbackDoNothing,		DR_SUSPEND
 DefLoopbackFunction LoopbackDoNothing,		DR_UNSUSPEND
 DefLoopbackFunction LoopbackRegister,		DR_SOCKET_REGISTER
 DefLoopbackFunction LoopbackUnregister,	DR_SOCKET_UNREGISTER
 DefLoopbackFunction LoopbackUnsupported,	DR_SOCKET_ALLOC_CONNECTION
 DefLoopbackFunction LoopbackLinkConnect,	DR_SOCKET_LINK_CONNECT_REQUEST
 DefLoopbackFunction LoopbackDataConnect,	DR_SOCKET_DATA_CONNECT_REQUEST
 DefLoopbackFunction LoopbackUnsupported,	DR_SOCKET_STOP_DATA_CONNECT
 DefLoopbackFunction LoopbackDisconnect,	DR_SOCKET_DISCONNECT_REQUEST
 DefLoopbackFunction LoopbackSendData,		DR_SOCKET_SEND_DATA
 DefLoopbackFunction LoopbackUnsupported,	DR_SOCKET_STOP_SEND_DATA
 DefLoopbackFunction LoopbackSendDatagram,	DR_SOCKET_SEND_DATAGRAM
 DefLoopbackFunction LoopbackDoNothing,		DR_SOCKET_RESET_REQUEST
 DefLoopbackFunction LoopbackAttach,		DR_SOCKET_ATTACH
 DefLoopbackFunction LoopbackDetach,		DR_SOCKET_REJECT
 DefLoopbackFunction LoopbackGetInfo,		DR_SOCKET_GET_INFO
 DefLoopbackFunction LoopbackUnsupported,	DR_SOCKET_SET_OPTION
 DefLoopbackFunction LoopbackUnsupported,	DR_SOCKET_GET_OPTION
 DefLoopbackFunction LoopbackResolveAddr,	DR_SOCKET_RESOLVE_ADDR
 DefLoopbackFunction LoopbackUnsupported,	DR_SOCKET_STOP_RESOLVE
 DefLoopbackFunction LoopbackUnsupported,	DR_SOCKET_CLOSE_MEDIUM
 DefLoopbackFunction LoopbackUnsupported,	DR_SOCKET_MEDIUM_CONNECT_REQUEST
 DefLoopbackFunction LoopbackUnsupported,	DR_SOCKET_MEDIUM_ACTIVATED
 DefLoopbackFunction LoopbackUnsupported,	DR_SOCKET_SET_MEDIUM_OPTION
 DefLoopbackFunction LoopbackDoNothing,         DR_SOCKET_RESOLVE_LINK_LEVEL_ADDRESS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine

CALLED BY:	Application
PASS:		di = function code
RETURN:		variable
DESTROYED:	variable
SIDE EFFECTS:	variable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackStrategy	proc	far
		.enter

		shl	di, 1
		cmp	cs:[LoopbackFunctions][di].segment, MAX_SEGMENT
		jae	movable
		call	{fptr.far}cs:[di]
done:		
		.leave
		ret
movable:
		pushdw	cs:[LoopbackFunctions][di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jmp	done
		
LoopbackStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackNewThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call client entry routine with a new thread

CALLED BY:	SCOIndication_newThread macro
PASS:		cx	= RegisterSetStruct mem handle
RETURN:		never
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackNewThread	proc	far
		mov	bx, cx
		push	bx
		call	MemLock
		mov	ds, ax
		push	ds:RSS_ds, ds:RSS_bx, ds:RSS_es
		mov	ax, ds:RSS_ax
		mov	cx, ds:RSS_cx
		mov	dx, ds:RSS_dx
		mov	bp, ds:RSS_bp
		mov	di, ds:RSS_di
		mov	si, ds:RSS_si
		call	MemUnlock
		pop	ds, bx, es
		SCOIndication
		pop	bx
		call	MemFree
		clr     cx, dx, bp, si
		jmp	ThreadDestroy
LoopbackNewThread	endp


Resident	ends

LoopbackCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CALLED BY:	DR_INIT
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackInit	proc	far
		clc
		ret
LoopbackInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CALLED BY:	DR_EXIT
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackExit	proc	far
		ret
LoopbackExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackDoNothing	proc	far
		ret
LoopbackDoNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackUnsupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry

CALLED BY:	Unsupported function call
PASS:		nothing
RETURN:		carry set
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackUnsupported	proc	far
		stc
		ret
LoopbackUnsupported	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers a client
CALLED BY:	DR_SOCKET_REGISTER

PASS:		bx    = domain handle of the driver
 		ds:si = domain name (null terminated)
         	dx:bp = client entry point for SCO functions (virtual fptr)
		cl    = SocketDriverType

RETURN:	carry set if error
 		ax      = SocketDrError (SDE_ALREADY_REGISTERED)
		bx	= client handle
		ch	= min header size for outgoing sequenced packets
		cl	= min header size for outgoing datagram packets

DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackRegister	proc	far
		uses	dx, es, ds
		.enter
	;
	; record client information
	;
		push	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx
		movdw	es:clientStrategy, dxbp
		mov	es:domainHandle, bx
		mov	es:driverType, cl
	;
	; Get domain name size
	;
		mov	dx, ds			; dx:si = domain name
		mov	es, dx			;
		mov	di, si			; 
		call	LocalStringLength	; -> cx = string length
		inc	cx			; include null character
	;
	; Allocate a chunk and copy domain name
	;
		mov	bx, handle LoopbackInfoResource
		call	MemLockExcl
		mov	ds, ax
		mov	es, ax
		clr	ax
		call	LMemAlloc		; ax = handle of new chunk
		mov	es:[LIH_domainName], ax	; record domain name chunk
		mov	di, ax			;
		mov	di, es:[di]		; es:di = new chunk
		mov	ds, dx			; ds:si = domain name
		rep	movsb
		mov	bx, handle LoopbackInfoResource
		call	MemUnlockShared
	;
	; Return paramenters
	;
		mov	bx, LOOPBACK_CLIENT_HANDLE
		mov	ch, size SequencedPacketHeader
		mov	cl, size DatagramPacketHeader
		clr	ax
		
		.leave
		ret
LoopbackRegister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister a client

CALLED BY:	DR_SOCKET_UNREGISTER
PASS:		bx = client handle
RETURN:		bx = domain handle
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackUnregister	proc	far
		uses	ax,bx,ds,es
		.enter
	;
	; Deallocate domain name
	;
		mov	bx, handle LoopbackInfoResource
		call	MemLockShared
		mov	ds, ax
		mov	ax, ds:[LIH_domainName]
		call	LMemFree
	;
	; Destroy all connection
	;
		call	DestroyAllConnections
		call	MemUnlockShared

		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, es:domainHandle
		.leave
		ret
LoopbackUnregister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackLinkConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish link connection
CALLED BY:	DR_SOCKET_LINK_CONNECT_REQUEST

PASS:		cx	= timeout value (ignored)
		bx	= client handle(ignored - there can be only 1 client)
		ds:si	= address string
		ax	= string size

RETURN:		carry set if connection failed
			ax = SocketDrError
 		otherwise
 			ax = connection handle

DESTROYS:	nothing
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackLinkConnect	proc	far
		uses	bx,cx,dx,si,di,ds,es
		.enter
	;
	; Lock info resource block
	;
		push	ax
		push	ds, si
		mov	cx, ax			; cx = address size
		mov	bx, handle LoopbackInfoResource
		call	MemLockExcl
		mov	ds, ax
	;
	; Make two connection entries that are connected to each other
	;
		call	AddConnection		; ax = connection handle
		mov_tr	dx, ax			; ds:si = conneciton entry
		mov_tr	di, si
		call	AddConnection		; ax = connection handle
		mov	ds:[si].LC_remoteConnection, dx
		mov	ds:[di].LC_remoteConnection, ax
		call	MemUnlockShared
	;
	; Indicate link open with connection handle = ax
	;
		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, es:domainHandle
		pop	ds, si			; ds:si = address string
		pop	cx			; cx = address string size
		mov	di, SCO_LINK_OPENED
		SCOIndication
	;
	; Notify interested parties that the GMID_LOOPBACK/MANUF_ID_GEOWORKS
	; medium is now connected.  
	;
		push	dx
	        mov     si, SST_MEDIUM
	        mov     di, MESN_MEDIUM_CONNECTED
	        mov     cx, MANUFACTURER_ID_GEOWORKS
        	mov     dx, GMID_LOOPBACK
	        mov     al, MUT_NONE
		call	SysSendNotification
		pop	dx
	;
	; return connection handle = dx
	;
		mov_tr	ax, dx
		clc
		.leave
		ret
LoopbackLinkConnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackDataConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a connection between two ports

CALLED BY:	DR_SOCKET_DATA_CONNECT_REQUEST
PASS:		cx	= timeout value (in ticks)
		dx	= remote port number 
		bp	= local port number (0 is not valid)
IGNORED:
		ds:si	= address string
		ax	= address string size
		bx	= client handle

RETURN:		carry set if connection failed
			ax = SocketDrError
		otherwise
			ax = connection handle
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackDataConnect	proc	far
		uses	bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; Lock info resource
	;
		push	cx			; save timeout value
		mov	bx, handle LoopbackInfoResource
		call	MemLockExcl
	;
	; Create a connection entry for remote size
	;
		xchg	dx, bp			; switch local & remote
		mov	bx, bp			; 
		call	AddConnection		; -> ax = connection handle
		mov	di, si			;    ds:di = connection entry
	;
	; Allocate a sem for waiting for connection confirm
	;
		clr	bx			; 
		call	ThreadAllocSem		;-> bx = loopback timed sem
		mov	ds:[di].LC_connectionSem, bx
	;
	; Send Connect request indication
	;
		push	di
		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, es:domainHandle
		mov	cx, bp			; port number
		mov	bp, ax			; bp = remote connection handle
		mov	di, SCO_CONNECT_REQUESTED
		SCOIndication			; this shouldn't take long
		pop	di
		jc	connectionRefused
	;
	; Now we create another connection handle for the local port
	;
		xchg	dx, bp			; dx = remote port
		mov	bx, bp			; bx = local port
		call	AddConnection		; ax = connection handle
						;ds:si= local connection handle
		mov	ds:[si].LC_remoteConnection, bp	; local entry
		mov	ds:[di].LC_remoteConnection, ax ; remote entry
		mov	cx, ds:[di].LC_connectionSem	; cx = connection sem
	;
	; Unlock info resource
	;
		mov	bx, handle LoopbackInfoResource
		call	MemUnlockShared
	;
	; Wait for connection confirm
	;	ax = local connection handle
	;	bp = remote connection handle
	;
		mov_tr	bx, cx
		pop	cx			; timout value for connection
		call	ThreadPTimedSem		; block until remote side
		call	ThreadFreeSem		; acknowledges the connection
		cmp	cx, SE_TIMEOUT
		je	connectionTimeout
	;
	; Check if the connction was rejected
	;
		push	ax
		mov	bx, handle LoopbackInfoResource
		call	MemLockShared
		mov	ds, ax
		pop	ax			; restore local connection
		mov	si, ds:[bp]		; ds:si = remote connection
		BitClr	ds:[si].LC_status, LCS_pending
		test	ds:[si].LC_status, mask LCS_dead
		call	MemUnlockShared
		jnz	connectionRejected
		clc
done:
		.leave
		ret
		
connectionRefused:
	;
	; on stack: timeout value
	; ax = connection handle to destroy
	;
		pop	cx
		mov	ax, SDE_CONNECTION_REFUSED
		jmp	errorExit2
		
connectionTimeout:
		mov	ax, SDE_CONNECTION_TIMEOUT
		jmp	errorExit1
connectionRejected:
		mov	ax, SDE_CONNECTION_REFUSED
errorExit1:
	;
	; ax, bp = connection handles to destroy
	;
		mov_tr	bx, bp
		call	RemoveConnection
errorExit2:
		mov_tr	bx, ax
		call	RemoveConnection
		stc
		jmp	done
LoopbackDataConnect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackDisconnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disconnection request

CALLED BY:	DR_SOCKET_DISCONNECT_REQUEST
PASS:		bx	= connection handle
		ax	= SocketCloseType
RETURN:		carry set if not connected
			cx = SocketDrError
DESTROYED:	nothing
ALGORITHM:

if (driver type = data driver)
; if (ax = SCT_HALF)
	if (initial disconnection request) {
		Notify remote side of half disconnection
		Mark our connection entry as dead
	} else { 	; this is response to initial disconnection request
		Notify remote side of full diconnection
		Destroy connection handles
	}
;
; Well, I never block...
;
; else {
; 	Notify remote size of half disconnection
;	Block until DR_SOCKET_DISCONNECT_REQUEST from remote side
;	Destroy both connection handles
; }
;
else
	Notify remote side of full disconnection
	Destroy both connetion handles

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackDisconnect	proc	far
		uses	ax,bx,dx,si,di,bp,ds,es
		.enter
	;
	; If the client is registered with link driver, branch to link driver
	; disconnection
	;
		push	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx
		cmp	es:driverType, SDT_LINK
LONG		je	linkDriverDisconnection
	;
	; Determine if this is a response to the request from remote side
	;
		mov_tr	dx, bx
		mov	bx, handle LoopbackInfoResource
		call	MemLockShared
		mov	ds, ax
		mov	bx, dx
		call	FindConnection		; ds:si = entry; di destroyed
		jc	notFound
		push	si
		mov	bp, bx			; bp = local connection entry
	;
	; Find remote connection entry
	;
		mov	ax, ds:[si].LC_remoteConnection
		mov	bx, ax
		call	FindConnection		; ds:si = entry; di destroyed
		test	ds:[si].LC_status, mask LCS_dead
		pop	si
LONG		jnz	disconnectionConfirm
	;
	; Initial disconnection request
	;	ax	= remote connection entry
	;
		mov	bx, es:domainHandle
		mov	cx, SCT_HALF
		mov	di, SCO_CONNECTION_CLOSED
		SCOIndicationNew
	;
	; Mark local connection entry to be dead
	;
		BitSet	ds:[si].LC_status, LCS_dead
notFound:
		mov	bx, handle LoopbackInfoResource
		call	MemUnlockShared
done:
		.leave
		ret
linkDriverDisconnection:
		mov_tr	dx, bx
		mov	bx, handle LoopbackInfoResource
		call	MemLockShared
		mov	ds, ax
		mov_tr	bx, dx
		call	FindConnection		; ds:si = connection entry
		jc	notFound
		mov_tr	bp, bx
		mov	ax, ds:[si].LC_remoteConnection
		mov	bx, handle LoopbackInfoResource
		call	MemUnlockShared		
disconnectionConfirm:
	;
	; Remove both connection entries
	;	ax	= remoteConnection
	;	bp	= local connection
	;
		mov_tr	bx, bp
		call	RemoveConnection
		mov	bx, ax
		call	RemoveConnection
	;
	; Notify remote side
	;	ax = remote side con
	;
		mov	bx, es:domainHandle
		mov	cx, SCT_FULL
		mov	di, SCO_CONNECTION_CLOSED
		SCOIndicationNew
	;
	; Notify interested parties that the GMID_LOOPBACK/MANUF_ID_GEOWORKS
	; medium is now disconnected.  
	;
	        mov     si, SST_MEDIUM
	        mov     di, MESN_MEDIUM_NOT_CONNECTED
	        mov     cx, MANUFACTURER_ID_GEOWORKS
        	mov     dx, GMID_LOOPBACK
	        mov     al, MUT_NONE
		call	SysSendNotification
		clc
		jmp	done
LoopbackDisconnect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackSendData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a sequenced data packet

CALLED BY:	DR_SOCKET_SEND_DATA
PASS:		dx:bp = optr of buffer to send
 		bx    = connection handle

IGNORED:	cx    = size of data in buffer
		ax    = timeout value
		si    = SocketSendMode

RETURN:		carry set if error
		ax = SocketDrError
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackSendData	proc	far
		uses	ax,bx,cx,si,di,ds,es
		.enter
	;
	; Get remote connection handle
	;
		mov_tr	si, bx
		mov	bx, handle LoopbackInfoResource
		call	MemLockShared
		mov	ds, ax
		mov_tr	bx, si
		call	FindConnection		; ds:si = entry ;di = destroyed
		jc	invalidConnection
		test	ds:[si].LC_status, mask LCS_dead
		jnz	invalidConnection	; dead connection
		mov	si, ds:[si].LC_remoteConnection
		mov	bx, handle LoopbackInfoResource
		call	MemUnlockShared
	;
	; Change the connection handle inside packet
	;
		mov	bx, dx
		call	HugeLMemLock
		mov	es, ax
		mov	di, es:[bp]
		push	bx
		mov	bx, handle dgroup
		call	MemDerefDS
		pop	bx
		segmov	es:[di].PH_domain, ds:[domainHandle], ax
		mov	es:[di].SPH_link, si
		call	HugeLMemUnlock
		movdw	cxdx, dxbp
		mov	di, SCO_RECEIVE_PACKET
		SCOIndication
done:
		.leave
		ret
invalidConnection:
		mov	ax, SDE_INVALID_CONNECTION_HANDLE
		mov	bx, handle LoopbackInfoResource
		call	MemUnlockShared
		stc
		jmp	done
LoopbackSendData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackSendDatagram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a datagram

CALLED BY:	DR_SOCKET_SEND_DATAGRAM

PASS:		dx:bp = optr of buffer send

RETURN:		carry set if error
		ax = SocketDrError

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackSendDatagram	proc	far
		uses	ax,bx,cx,dx,ds,es
		.enter
	;
	; Exchange local port and remote port
	;
		mov	bx, dx
		call	HugeLMemLock
		mov	ds, ax
		mov	si, ds:[bp]
		mov	ax, ds:[si].DPH_localPort
		xchg	ax, ds:[si].DPH_remotePort
		xchg	ax, ds:[si].DPH_localPort
	;
	; set the domain handle
	;
		push	bx
		mov	bx, handle dgroup
		call	MemDerefES
		pop	bx
		segmov	ds:[si].PH_domain, es:[domainHandle], ax
		call	HugeLMemUnlock
	;
	; Forward the data
	;
		mov_tr	cx, dx
		mov_tr	dx, bp
		mov	di, SCO_RECEIVE_PACKET
		SCOIndication
		
		.leave
		ret
LoopbackSendDatagram	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Confirm a data connection

CALLED BY:	DR_SOCKET_ATTACH
PASS:		ax	= connection handle
		cx	= timeout value (in ticks) - ignored
RETURN:		carry set if error
		ax = SocketDrError
DESTROYS: nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackAttach	proc	far
		uses	ax,bx,cx,si,di,ds
		.enter
	;
	; verify connection handle
	;
		mov_tr	cx, ax
		mov	bx, handle LoopbackInfoResource
		call	MemLockShared
		mov	ds, ax
		mov_tr	bx, cx
		call	FindConnection		; ds:si = connection entry
		jc	invalidConnection
	;
	; confirm pending connection by V'ing connection semaphore
	; and clearing dead bit
	;
		BitClr	ds:[si].LC_status, LCS_dead
		mov	bx, ds:[si].LC_connectionSem
		call	ThreadVSem
	;
	; Rest is done in LoopbackDataConnect
	;
done:
		mov	bx, handle LoopbackInfoResource
		call	MemUnlockShared
		.leave
		ret
invalidConnection:
		mov	ax, SDE_INVALID_CONNECTION_HANDLE
		stc
		jmp	done
LoopbackAttach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reject an incoming connection

CALLED BY:	DR_SOCKET_REJECT

PASS:		ax	= connection handle
RETURN:		carry set if invalid connection handle
		ax = SocketDrError

DESTROYS:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackDetach	proc	far
		uses	ax,bx,cx,si,di,ds
		.enter
	;
	; verify connection handle
	;
		mov_tr	cx, ax
		mov	bx, handle LoopbackInfoResource
		call	MemLockShared
		mov	ds, ax
		mov_tr	bx, cx
		call	FindConnection		; ds:si = connection entry
		jc	invalidConnection
	;
	; Reject pending connection by V'ing connection semaphore
	; and setting dead bit
	;
		BitSet	ds:[si].LC_status, LCS_dead
		mov	bx, ds:[si].LC_connectionSem
		call	ThreadVSem
	;
	; Rest is done in LoopbackDataConnect
	;
done:
		mov	bx, handle LoopbackInfoResource
		call	MemUnlockShared
		.leave
		ret
invalidConnection:
		mov	ax, SDE_INVALID_CONNECTION_HANDLE
		stc
		jmp	done
LoopbackDetach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackResolveAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve an address	

CALLED BY:	DR_SOCKET_RESOLVE_ADDR
PASS:		ds:si 	= addr to resolve (non-null terminated)
		cx	= size of addr 
		dx:bp	= buffer for resolved address
		ax	= size of buffer

RETURN:		carry clr if address returned
		  dx:bp = buffer filled w/non-null terminated addr if buffer
			  is big enough
		  cx	= size of resolved address

		If buffer for resolved address is too small, only the size
		is returned.

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackResolveAddr	proc	far
		uses	es, di
		.enter
		
		cmp	ax, cx
		jb	done			; buffer too small, cx is size

		movdw	esdi, dxbp
		rep	movsb
done:
		clc
		.leave
		ret
LoopbackResolveAddr	endp

DefInfoFunction   macro   routine, cnst
.assert ($-getInfoTable) eq cnst, <function table is corrupted>
.assert (type routine eq near)
                nptr        routine
                endm

getInfoTable	label	nptr
DefInfoFunction	LoopbackGetMediaList, 		SGIT_MEDIA_LIST
DefInfoFunction	LoopbackGetMediumAndUnit,	SGIT_MEDIUM_AND_UNIT
DefInfoFunction	LoopbackGetAddrCtrl,		SGIT_ADDR_CTRL
DefInfoFunction	LoopbackGetAddressSize,		SGIT_ADDR_SIZE
DefInfoFunction	LoopbackGetAddress,		SGIT_LOCAL_ADDR
DefInfoFunction	LoopbackGetAddress,		SGIT_REMOTE_ADDR
DefInfoFunction	LoopbackInfoNotAvailable,	SGIT_MTU
DefInfoFunction LoopbackGetPrefCtrl,		SGIT_PREF_CTRL
DefInfoFunction LoopbackGetMediumConnection,	SGIT_MEDIUM_CONNECTION
getInfoTableEnd	label	byte
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the driver

CALLED BY:	LoopbackStrategy
PASS:		ax	= SocketGetInfoType
RETURN:		carry set if info not available
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackGetInfo	proc	far
		.enter
		cmp	ax, offset getInfoTableEnd - offset getInfoTable
		cmc
		jb	done				; jb=jc
		push	di
		mov	di, ax
		mov	ax, cs:[getInfoTable][di]
		pop	di
		call	{nptr}ax
done:
		.leave
		ret
LoopbackGetInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackInfoNotAvailable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackInfoNotAvailable	proc	near
		stc
		ret
LoopbackInfoNotAvailable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackGetMediaList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	List of media supported by loopback

CALLED BY:	LoopbackGetInfo
PASS:		*ds:si	- chunk array
RETURN:		*ds:si	- chunk array of MediumType
		carry set if ChunkArrayAppend failed
		clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackGetMediaList	proc	near
		uses	di
		.enter
		call	ChunkArrayAppend		; ds:di = MediumType
		jc	done
		mov	ds:[di].MET_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ds:[di].MET_id, GMID_LOOPBACK
done:
		.leave
		ret
LoopbackGetMediaList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackGetMediumAndUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the medium and unit of a link

CALLED BY:	LoopbackGetInfo
PASS:		nothing
RETURN:		cx	- MANUFACTURER_ID_GEOWORKS
		dx	- GMIT_LOOPBACK
		bl	- MUT_NONE
		bp	- 0
		carry clear
		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackGetMediumAndUnit	proc	near
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GMID_LOOPBACK
		mov	bl, MUT_NONE
		clr	bp
		ret
LoopbackGetMediumAndUnit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackGetAddressSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of significant bytes in an addres

CALLED BY:	LoopbackGetInfo
PASS:		nothing
RETURN:		ax = 0
		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackGetAddressSize	proc	near
		clr	ax
		ret
LoopbackGetAddressSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackGetAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the local or remote address

CALLED BY:	LoopbackGetInfo
PASS:		ds:bx	- buffer
		dx	- buffer size
RETURN:		ds:bx	- nothing
		ax	- 0
		carry always clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackGetAddress	proc	near
		.enter
		xor	ax, ax		; ax <- address size, carry clear
		.leave
		ret
LoopbackGetAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackGetAddrCtrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns address controller

CALLED BY:	SGIT_ADDR_CTRL
PASS:		dx = media
RETURN:		cx:dx = class pointer
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackGetAddrCtrl	proc	near
		uses	bx
		.enter
		stc
if 0
		mov	bx, handle 0
		call	GeodeAddReference
		mov	cx, segment LoopbackAddressControlClass
		mov	dx, offset LoopbackAddressControlClass
endif
		.leave
		ret
LoopbackGetAddrCtrl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackGetPrefCtrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns pref control class

CALLED BY:	SGIT_PREF_CTRL
PASS:		nothing
RETURN:		cx:dx = class
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackGetPrefCtrl	proc	near
		.enter
ife	NO_PREFERENCES_APPLICATION
	 	mov	cx, segment LoopbackPreferenceControlClass
		mov	dx, offset LoopbackPreferenceControlClass
else
		clr	cx, dx
endif
		.leave
		ret
LoopbackGetPrefCtrl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoopbackGetMediumConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if driver is connected over medium and unit, and
		return address if connected.

CALLED BY:	SGIT_MEDIUM_CONNECTION
PASS:		dx:bx	= MediumAndUnit
		ds:si	= address buffer
		cx	= buffer size in bytes
RETURN: 	carry set if no connection is established over the
			unit of the medium.
		else
		ds:si	= filled in with address, up to value passed
			  in as buffer size.
		cx	= actual size of address in ds:si.  If cx
			  is greater than the buffer size that was
			  passed in, then address in ds:si is 
			  incomplete.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoopbackGetMediumConnection	proc	near
	uses	ds,si,ax,bx
	.enter
	;
	; The only medium acceptable for this driver is GMID_LOOPBACK/
	; MANUFACTURER_ID_GEOWORKS.
	;
	movdw	dssi, dxbx			;ds:si = MediumAndUnit
	cmp	ds:[si].MU_medium.MET_id, GMID_LOOPBACK
	jne	notConnected
	cmp	ds:[si].MU_medium.MET_manuf, MANUFACTURER_ID_GEOWORKS
	jne	notConnected
	;
	; Check if LIH_connection is zero.  If so, then we are not connected.
	;
	mov	bx, handle LoopbackInfoResource
	call	MemLockShared
	mov	ds, ax				;ds:0 = LoopbackInfoHeader
	tst	ds:[LIH_connection]
	call	MemUnlockShared			;flags preserved
	jz	notConnected
	;
	; We are connected.  Since the loopback driver can connect to
	; anyone anytime, return a null address.
	; 
	clr	cx
	clc
exit:
	.leave
	ret

notConnected:
	stc
	jmp	exit
LoopbackGetMediumConnection	endp

LoopbackCode	ends
