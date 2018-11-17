COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethercomLink.asm

AUTHOR:		Todd Stumpf, July 8th, 1998

ROUTINES:

    INT EtherAllocConnect    Allocate a new connection
    INT EtherLinkConnect     Establish link connection
    INT EtherDisconnect      Disconnection request
    INT EtherReset	     Reset and established link

DESCRIPTION:

	Routines to establish and break link connections common to
	all ethernet link drivers

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MovableCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherAllocConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure this is an available connection

CALLED BY:	DR_SOCKET_ALLOC_CONNECTION

PASS:		bx	-> client handle

RETURN:		carry set if unable to allocate connection
			ax <- SocketDrError
 		otherwise
 			ax <- connection handle
DESTROYS:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/ 8/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherAllocConnect	proc	far
		.enter

		Assert	e, bx, ETHER_CLIENT_HANDLE
		mov	ax, ETHER_CONNECTION_HANDLE
		clc

		.leave
		ret
EtherAllocConnect	endp
	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherLinkConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish link connection (easy for ethernet)

CALLED BY:	DR_SOCKET_LINK_CONNECT_REQUEST

PASS:		ds:si	-> address string (LinkParams)
		ax	-> string size
		bx	-> connection handle
		cx	-> timeout value (ignored)
RETURN:		carry set if connection failed
			ax <- SocketDrError
DESTROYS:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/ 8/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherLinkConnect	proc	far
		uses	bx, cx, dx, si, di, bp, ds, es
		.enter

		Assert	buffer, dssi, ax
		Assert	e, bx, ETHER_CONNECTION_HANDLE

	;
	; Establish condition of ethernet card
	;;; (Do we really need this?)
		EthDevCheckLinkAddr
		jc	badAddr

	;
	; Set up our local IP address.  Right now we can only handle LT_ID.
	;
		Assert	etype, ds:[si].LP_type, LinkType
		cmp	ds:[si].LP_type, LT_ID
		jne	badAddr
		cmp	ax, size LinkParams + size LinkID
		jne	badAddr
		mov	ax, {LinkID} ds:[si].LP_params
		GetDGroup	ds, bx
		call	EtherSetAccessIPAddr

	;
	; Tell our process thread to send notification.  Can't do it on
	; the same thread or else we'll deadlock ourselves.
	;
		mov	bx, ds:[etherThread]
		Assert	thread, bx, NULL
		mov	ax, MSG_EP_NOTIFY_CONNECT_CONFIRMED
		clr	di		; must be asynchronous
		call	ObjMessage

if 0 ;;; Will decide later when to send notification.
	;
	; Notify interested parties that the GMID_ETHER/MANUF_ID_GEOWORKS
	; medium is now connected.  
	;
		push	dx
	        mov     si, SST_MEDIUM
	        mov     di, MESN_MEDIUM_CONNECTED
	        mov     cx, MANUFACTURER_ID_GEOWORKS
        	mov     dx, GMID_NETWORK
	        mov     al, MUT_NONE
		call	SysSendNotification
		pop	dx
endif ; if 0

		clc
done:
		.leave
		ret

badAddr:
		mov	ax, SDE_INVALID_ADDR_FOR_LINK
		stc
		jmp	done
EtherLinkConnect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherDisconnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disconnection request

CALLED BY:	DR_SOCKET_DISCONNECT_REQUEST

PASS:		bx	= connection handle
		ax	= SocketCloseType
RETURN:		carry set if not connected
			ax = SocketDrError
DESTROYED:	nothing

ALGORITHM:

	Notify remote side of full disconnection
	Destroy both connetion handles

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherDisconnect	proc	far
		uses	cx,dx,si,di
		.enter
	;
	; Notify interested parties that the GMID_NETWORK/MANUF_ID_GEOWORKS
	; medium is now disconnected.  
	;
	        mov     si, SST_MEDIUM
	        mov     di, MESN_MEDIUM_NOT_CONNECTED
	        mov     cx, MANUFACTURER_ID_GEOWORKS
        	mov     dx, GMID_NETWORK
	        mov     al, MUT_NONE
		call	SysSendNotification
		clc
		.leave
		ret
EtherDisconnect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherResolveAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolve an address	

CALLED BY:	DR_SOCKET_RESOLVE_ADDR

PASS:		ds:si 	= addr to resolve (non-null terminated)
		cx	= size of addr 
		dx:bp	= buffer for resolved address
		ax	= size of buffer
RETURN:		carry clr if no error (always clear)
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
		uses	es, di, cx, si
		.enter
		
		Assert	buffer, dssi, cx
		Assert	buffer, dxbp, ax

		cmp	ax, cx
		jb	done			; buffer too small, cx is size

		movdw	esdi, dxbp
		rep	movsb
done:
		clc
		.leave
		ret
EtherResolveAddr	endp

EtherStopResolveAddr	proc	far
		.enter
		.leave
		ret
EtherStopResolveAddr	endp


EtherReset		proc	far
		.enter
		.leave
		ret
EtherReset		endp


MovableCode		ends