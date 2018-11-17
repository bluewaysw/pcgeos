COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 198 -- All Rights Reserved

PROJECT:	Native Ethernet Support
MODULE:		Ether driver
FILE:		etherMain.asm

AUTHOR:		Todd Stumpf, July 8th, 1998

ROUTINES:

REVISION HISTORY:
    INT EtherStrategy        Strategy routine
    INT EtherInit            Strategy routine
    INT EtherExit            Strategy routine
    INT EtherDoNothing       Do nothing
    INT EtherRegister        Registers a client
    INT EtherUnregister      Unregister a client
    INT EtherLinkConnect     Establish link connection
    INT EtherDataConnect     Make a connection between two ports
    INT EtherDisconnect      Disconnection request
    INT EtherSendData        Send a sequenced data packet
    INT EtherSendDatagram    Send a datagram
    INT EtherAttach          Confirm a data connection
    INT EtherDetach          Reject an incoming connection
    INT EtherGetInfo         Get information about the driver

DESCRIPTION:

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

	DefEtherFunction	macro	routine, cnst
		.assert ($-EtherFunctions) eq cnst*2, <function table is corrupted>
		.assert (type routine eq far)
                fptr.far        routine
	endm

EtherFunctions	label	fptr.far
	DefEtherFunction EtherInit,			DR_INIT
	DefEtherFunction EtherExit,			DR_EXIT
	DefEtherFunction EtherDoNothing,		DR_SUSPEND
	DefEtherFunction EtherDoNothing,		DR_UNSUSPEND
	DefEtherFunction EtherRegister,			DR_SOCKET_REGISTER
	DefEtherFunction EtherUnregister,		DR_SOCKET_UNREGISTER
	DefEtherFunction EtherLinkConnect,		DR_SOCKET_LINK_CONNECT_REQUEST
	DefEtherFunction EtherDataConnect,		DR_SOCKET_DATA_CONNECT_REQUEST
	DefEtherFunction EtherDisconnect,		DR_SOCKET_DISCONNECT_REQUEST
	DefEtherFunction EtherSendData,			DR_SOCKET_SEND_DATA
	DefEtherFunction EtherSendDatagram,		DR_SOCKET_SEND_DATAGRAM
	DefEtherFunction EtherDoNothing,		DR_SOCKET_RESET_REQUEST
	DefEtherFunction EtherAttach,			DR_SOCKET_ATTACH
	DefEtherFunction EtherDetach,			DR_SOCKET_REJECT
	DefEtherFunction EtherGetInfo,			DR_SOCKET_GET_INFO
	DefEtherFunction EtherUnsupported,		DR_SOCKET_LINK_ACTIVATED
	DefEtherFunction EtherUnsupported,		DR_SOCKET_SET_OPTION
	DefEtherFunction EtherUnsupported,		DR_SOCKET_GET_OPTION
	DefEtherFunction EtherResolveAddr,		DR_SOCKET_RESOLVE_ADDR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine

CALLED BY:	GLOBAL

PASS:		di -> DR_SOCKET_* funciton to call
RETURN:		variable
DESTROYED:	variable
SIDE EFFECTS:	variable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/8/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherStrategy	proc	far
		.enter
	;
	;  See if the function is fixed, or movable, knowing that
	;  all movable segments are stored as virtual segments.
		shl	di, 1
		cmp	cs:[EtherFunctions][di].segment, MAX_SEGMENT
		jae	movable	; => virtual segment

		call	{fptr.far}cs:[EtherFunctions][di]
done:
		.leave
		ret
movable:
	;
	; We've got a vfptr to the routine, so use the canned
	; kernel routines to transform it to a call...
		pushdw	cs:[EtherFunctions][di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jmp	done

EtherStrategy	endp

Resident	ends

EtherCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CALLED BY:	DR_INIT

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherInit	proc	far
		clc
		ret
EtherInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CALLED BY:	DR_EXIT

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherExit	proc	far
		ret
EtherExit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherDoNothing	proc	far
		ret
EtherDoNothing	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherUnsupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry

CALLED BY:	Indicate unsupported function call

PASS:		nothing
RETURN:		carry set
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherUnsupported	proc	far
		stc
		ret
EtherUnsupported	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Registers the socket library with this driver

CALLED BY:	DR_SOCKET_REGISTER

PASS:		bx    -> domain handle of the driver
 		ds:si -> domain name (null terminated)
         	dx:bp -> socketLib entry point for SCO functions (virtual fptr)
		cl    -> SocketDriverType
RETURN:		carry set if error
 		ax    <- SocketDrError (SDE_ALREADY_REGISTERED | SDE_MEDIUM_BUSY)
		bx    <- client handle
		ch    <- min header size for outgoing sequenced packets
		cl    <- min header size for outgoing datagram packets
				(min header sizes include space for
					Sequenced/DatagramPacketHeaders)
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherRegister	proc	far
		uses	dx, si, di, es, ds
		.enter
		GetDgroupES
	;
	; Record passed SocketLibrary information
	;
		movdw	es:[socketLibStrategy], dxbp
		mov	es:[domainHandle], bx
		mov	es:[driverType], cl		; used as link or data driver?

	;
	; Calc size of passed domain name...
	;
		mov	dx, ds				; dx = segment of domain name

		mov	es, dx
		mov	di, si				; es:di -> ptr to start of string
		call	LocalStringLength	; cx <- string length (sans null)
		inc	cx				; include null character

	;
	; Allocate space in InfoResource for passed domain name
	;
		mov	bx, handle EtherInfoResource	; bx -> handle of block
		call	MemLockExcl		; ax <- segment of block

		mov	ds, ax
		mov	es, ax
		clr	ax
		call	LMemAlloc		; ax <- handle of new chunk

	;
	;  Note which chunk contains the domain.
	;
		mov	es:[EIH_domainName], ax

	;
	;  Copy the passed domain into its new home
	;
		mov	di, ax
		mov	di, es:[di]		; es:di = dereferenced domain chunk

		mov	ds, dx			; ds:si = domain name

		shr	cx, 1
		rep	movsw
		adc	cx, cx
		rep	movsb

		mov	bx, handle EtherInfoResource
		call	MemUnlockShared

	;
	; Return ethernet parameters...
	;
		mov	bx, ETHER_CLIENT_HANDLE
		mov	ch, size SequencedPacketHeader
		mov	cl, size DatagramPacketHeader
		clr	ax

		.leave
		ret
EtherRegister	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister the socket library

CALLED BY:	DR_SOCKET_UNREGISTER

PASS:		bx = client handle
RETURN:		bx = domain handle
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/ 8/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherUnregister	proc	far
		uses	ax, bx, ds, es
		.enter
	;
	; Deallocate domain name
	;
		mov	bx, handle EtherInfoResource
		call	MemLockShared

		mov	ds, ax
		mov	ax, ds:[EIH_domainName]
		call	LMemFree

	;
	; Destroy all connection
	;
		call	DestroyAllConnections
		call	MemUnlockShared

		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, es:[domainHandle]
		.leave
		ret
EtherUnregister	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherLinkConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish link connection (easy for ethernet)

CALLED BY:	DR_SOCKET_LINK_CONNECT_REQUEST

PASS:		ds:si	-> address string
		ax	-> string size
		bx	-> client handle (ignored - there can be only 1 client)
		cx	-> timeout value

RETURN:		carry set if connection failed
			ax <- SocketDrError
 		otherwise
 			ax <- connection handle
DESTROYS:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/ 8/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherLinkConnect	proc	far
		uses	bx, cx, dx, si, di, ds, es
		.enter
if 0
		push	ax
		push	ds, si

	;
	; Lock info resource block
	;
		mov	cx, ax				; cx = address size
		mov	bx, handle EtherInfoResource
		call	MemLockExcl	; ax <- segment of EIR
		mov	ds, ax				; ds <- segment of EIR
endif
	;
	; Establish condition of ethernet card
		call	EtherCheckLinkAddress
		jc	badAddress
if 0
		mov	ds:[si].LC_remoteConnection, dx
		mov	ds:[di].LC_remoteConnection, ax
		call	MemUnlockShared
endif
	;
	; Indicate link open with connection handle = ax
	;
		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, es:[domainHandle]

		pop	ds, si			; ds:si = address string
		pop	cx			; cx = address string size
		mov	di, SCO_LINK_OPENED
		SCOIndication

	;
	; Notify interested parties that the GMID_ETHER/MANUF_ID_GEOWORKS
	; medium is now connected.  
	;
		push	dx
	        mov     si, SST_MEDIUM
	        mov     di, MESN_MEDIUM_CONNECTED
	        mov     cx, MANUFACTURER_ID_GEOWORKS
        	mov     dx, GMID_ETHER
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
EtherLinkConnect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherDataConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a connection between two ports

CALLED BY:	DR_SOCKET_DATA_CONNECT_REQUEST

PASS:		bx	-> client handle
		ds:si	-> address string (IP address)
		ax	-> address string size
		dx	-> remote IP port number
		bp	-> local IP port number (0 is not valid)
		cx	-> timeout value (in ticks)

RETURN:		carry set if connection failed
			ax <- SocketDrError
		otherwise
			ax <- connection handle
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherDataConnect	proc	far
		uses	bx, cx, dx, si, di, bp, ds, es
		.enter
	;
	; Lock info resource
	;
		push	cx			; save timeout value
		mov	bx, handle EtherInfoResource
		call	MemLockExcl

	;
	; Create a connection entry for remote size
	;
		xchg	dx, bp			; switch local & remote
		mov	bx, bp			; 
							; bx -> local port
							; dx -> remote port
							; ds -> segment of EIR
		call	AddConnection	; ax <- connection handle

		mov	di, si			;    ds:di = connection entry

	;
	; Allocate a sem for waiting for connection confirm
	;
		clr	bx			; 
		call	ThreadAllocSem		;-> bx = ether timed sem
		mov	ds:[di].LC_connectionSem, bx

	;
	; Send Connect request indication
	;
		push	di
		mov	bx, handle dgroup
		call	MemDerefES			; ES <- dgroup
		mov	bx, es:[domainHandle]
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
		mov	bx, handle EtherInfoResource
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
		mov	bx, handle EtherInfoResource
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
EtherDataConnect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherDisconnect
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
EtherDisconnect	proc	far
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
		cmp	es:[driverType], SDT_LINK
LONG		je	linkDriverDisconnection
	;
	; Determine if this is a response to the request from remote side
	;
		mov_tr	dx, bx
		mov	bx, handle EtherInfoResource
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
		mov	bx, handle EtherInfoResource
		call	MemUnlockShared
done:
		.leave
		ret
linkDriverDisconnection:
		mov_tr	dx, bx
		mov	bx, handle EtherInfoResource
		call	MemLockShared
		mov	ds, ax
		mov_tr	bx, dx
		call	FindConnection		; ds:si = connection entry
		jc	notFound
		mov_tr	bp, bx
		mov	ax, ds:[si].LC_remoteConnection
		mov	bx, handle EtherInfoResource
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
	; Notify interested parties that the GMID_ETHER/MANUF_ID_GEOWORKS
	; medium is now disconnected.  
	;
	        mov     si, SST_MEDIUM
	        mov     di, MESN_MEDIUM_NOT_CONNECTED
	        mov     cx, MANUFACTURER_ID_GEOWORKS
        	mov     dx, GMID_ETHER
	        mov     al, MUT_NONE
		call	SysSendNotification
		clc
		jmp	done
EtherDisconnect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherSendData
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
EtherSendData	proc	far
		uses	ax,bx,cx,si,di,ds,es
		.enter
	;
	; Get remote connection handle
	;
		mov_tr	si, bx
		mov	bx, handle EtherInfoResource
		call	MemLockShared
		mov	ds, ax
		mov_tr	bx, si
		call	FindConnection		; ds:si = entry ;di = destroyed
		jc	invalidConnection
		test	ds:[si].LC_status, mask LCS_dead
		jnz	invalidConnection	; dead connection
		mov	si, ds:[si].LC_remoteConnection
		mov	bx, handle EtherInfoResource
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
		mov	bx, handle EtherInfoResource
		call	MemUnlockShared
		stc
		jmp	done
EtherSendData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherSendDatagram
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
EtherSendDatagram	proc	far
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
EtherSendDatagram	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherAttach
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
EtherAttach	proc	far
		uses	ax,bx,cx,si,di,ds
		.enter
	;
	; verify connection handle
	;
		mov_tr	cx, ax
		mov	bx, handle EtherInfoResource
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
	; Rest is done in EtherDataConnect
	;
done:
		mov	bx, handle EtherInfoResource
		call	MemUnlockShared
		.leave
		ret
invalidConnection:
		mov	ax, SDE_INVALID_CONNECTION_HANDLE
		stc
		jmp	done
EtherAttach	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherDetach
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
EtherDetach	proc	far
		uses	ax,bx,cx,si,di,ds
		.enter
	;
	; verify connection handle
	;
		mov_tr	cx, ax
		mov	bx, handle EtherInfoResource
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
	; Rest is done in EtherDataConnect
	;
done:
		mov	bx, handle EtherInfoResource
		call	MemUnlockShared
		.leave
		ret

invalidConnection:
		mov	ax, SDE_INVALID_CONNECTION_HANDLE
		stc
		jmp	done
EtherDetach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherResolveAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve an address	

CALLED BY:	DR_SOCKET_RESOLVE_ADDR

PASS:		ds:si 	= addr to resolve (non-null terminated)
		cx	= size of addr 
		dx:bp	= buffer for resolved address
		ax	= size of buffer
RETURN:		carry clr if address returned
			dx:bp	= buffer filled w/non-null terminated addr if
					buffer is big enough
			cx	= size of resolved address

		If buffer for resolved address is too small, only the size
		is returned.
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherResolveAddr	proc	far
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
EtherResolveAddr	endp

DefInfoFunction   macro   routine, cnst
.assert ($-getInfoTable) eq cnst, <function table is corrupted>
.assert (type routine eq near)
                nptr        routine
                endm

getInfoTable	label	nptr
DefInfoFunction	EtherGetMediaList, 		SGIT_MEDIA_LIST
DefInfoFunction	EtherGetMediumAndUnit,		SGIT_MEDIUM_AND_UNIT
DefInfoFunction	EtherGetAddrCtrl,		SGIT_ADDR_CTRL
DefInfoFunction	EtherGetAddressSize,		SGIT_ADDR_SIZE
DefInfoFunction	EtherGetAddress,		SGIT_LOCAL_ADDR
DefInfoFunction	EtherGetAddress,		SGIT_REMOTE_ADDR
DefInfoFunction	EtherInfoNotAvailable,		SGIT_MTU
DefInfoFunction EtherGetPrefCtrl,		SGIT_PREF_CTRL
DefInfoFunction EtherGetMediumConnection,	SGIT_MEDIUM_CONNECTION
getInfoTableEnd	label	byte
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the driver

CALLED BY:	EtherStrategy

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
EtherGetInfo	proc	far
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
EtherGetInfo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherInfoNotAvailable
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
EtherInfoNotAvailable	proc	near
		stc
		ret
EtherInfoNotAvailable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetMediaList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	List of media supported by ether

CALLED BY:	EtherGetInfo

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
EtherGetMediaList	proc	near
		uses	di
		.enter
		call	ChunkArrayAppend		; ds:di = MediumType
		jc	done
		mov	ds:[di].MET_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ds:[di].MET_id, GMID_ETHER
done:
		.leave
		ret
EtherGetMediaList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetMediumAndUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the medium and unit of a link

CALLED BY:	EtherGetInfo

PASS:		nothing
RETURN:		cx	- MANUFACTURER_ID_GEOWORKS
		dx	- GMIT_ETHER
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
EtherGetMediumAndUnit	proc	near
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GMID_ETHER
		mov	bl, MUT_NONE
		clr	bp
		ret
EtherGetMediumAndUnit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetAddressSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of significant bytes in an addres

CALLED BY:	EtherGetInfo

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
EtherGetAddressSize	proc	near
		clr	ax
		ret
EtherGetAddressSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the local or remote address

CALLED BY:	EtherGetInfo

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
EtherGetAddress	proc	near
		.enter
		xor	ax, ax		; ax <- address size, carry clear
		.leave
		ret
EtherGetAddress	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetAddrCtrl
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
EtherGetAddrCtrl	proc	near
		uses	bx
		.enter
		stc
if 0
		mov	bx, handle 0
		call	GeodeAddReference
		mov	cx, segment EtherAddressControlClass
		mov	dx, offset EtherAddressControlClass
endif
		.leave
		ret
EtherGetAddrCtrl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetPrefCtrl
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
EtherGetPrefCtrl	proc	near
		.enter
ife	NO_PREFERENCES_APPLICATION
	 	mov	cx, segment EtherPreferenceControlClass
		mov	dx, offset EtherPreferenceControlClass
else
		clr	cx, dx
endif
		.leave
		ret
EtherGetPrefCtrl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherGetMediumConnection
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
EtherGetMediumConnection	proc	near
	uses	ds, si, ax, bx
	.enter
	;
	; The only medium acceptable for this driver is GMID_ETHER/
	; MANUFACTURER_ID_GEOWORKS.
	;
	movdw	dssi, dxbx			;ds:si = MediumAndUnit
	cmp	ds:[si].MU_medium.MET_id, GMID_ETHER
	jne	notConnected
	cmp	ds:[si].MU_medium.MET_manuf, MANUFACTURER_ID_GEOWORKS
	jne	notConnected
	;
	; Check if LIH_connection is zero.  If so, then we are not connected.
	;
	mov	bx, handle EtherInfoResource
	call	MemLockShared
	mov	ds, ax				;ds:0 = EtherInfoHeader
	tst	ds:[LIH_connection]
	call	MemUnlockShared			;flags preserved
	jz	notConnected
	;
	; We are connected.  Since the ether driver can connect to
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
EtherGetMediumConnection	endp

EtherCode	ends
