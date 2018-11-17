COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethercomUtil.asm

AUTHOR:		Todd Stumpf, July 8th, 1998

ROUTINES:
	Name				Description
	----				-----------
	AddConnection			adds a connection entry to InfoResource
	RemoveConnection		removes a conncetion entry from InfoResource
	FindConnection			find a connection entry in InfoResource	
	DestroyAllConnections		remove and and all connections

	EtherCallClientOnNewThread	Call client-supplied callback on new thread
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	07/08/98	Initial revision

DESCRIPTION:
	
	Utility routines common to all ethernet link drivers

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MovableCode	segment resource

if 0	;;; We don't need these now, and may not need them at all.

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a connection entry to EtherInfoResource

CALLED BY:	INTERNAL
PASS:		ds	-> EtherInfoResource segment
		bx	-> local IP port #
		dx	-> remote IP port #
RETURN:		ax	<- connection chunk handle
		ds:si	<- connection entry fptr
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	6/24/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddConnection	proc	near
		uses	bx, cx
		.enter
	;
	; Allocate a connection entry
	;
		mov	cx, size EtherConnection
		clr	al
		call	LMemAlloc	; ax <- new chunk handle

		mov	bx, ax			; bx = new chunk handle
		mov	si, ds:[bx]
		clr	ds:[si].EC_connectionSem
		clr	ds:[si].EC_status
		mov	ds:[si].EC_localPort, bx
		mov	ds:[si].EC_remotePort, dx
		clr	ds:[si].EC_remoteConnection

	;
	; Add the entry to connection list atomically
	;
		pushf
		INT_OFF
		xchg	bx, ds:[EIH_connection]
		mov	ds:[si].EC_next, bx
		popf
		
		.leave
		ret
AddConnection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a connection entry from EtherInfoResource

CALLED BY:	INTERNAL
PASS:		bx	-> connection handle
RETURN:		carry set if connection entry was not found
DESTROYED:	bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	6/24/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveConnection	proc	near
		uses	ax, di, si, ds
		.enter
	;
	; Find the connection, given its handle
	;
		push	bx			; save connection handle
		mov	bx, handle EtherInfoResource
		call	MemLockShared	; ax <- segment of EIR
		mov	ds, ax
		pop	bx			; restore connection handle

		call	FindConnection	; ds:si <- connection entry
					; ds:di <- field to remove conn. handle
		jc	done ; => Which connection?

	;
	; Unlink the connection entry from list...
	;
		mov	ax, ds:[si].EC_next
		xchg	ax, ds:[di]	; ax = connection handle to remove

	;
	; ... then remove it from the block
	;
		call	LMemFree

		mov	bx, handle EtherInfoResource
		call	MemUnlockShared
		clc
done:
		.leave
		ret
RemoveConnection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds a connection entry

CALLED BY:	INTERNAL
PASS:		bx	-> connection handle
		ds	-> EtherInfoResource segment
RETURN:		carry set if not found
		otherwise
			ds:si	<- connection entry
			ds:di	<- memory location that contains the connection
				  handle( for removal )
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	6/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindConnection	proc	near
		.enter
		
		mov 	di, offset EIH_connection
		mov	si, ds:[di]
findLoop:
	;
	; di = mem location that contains a connection handle
	; si = connection handle in ds:[di]
	; bx = connection handle to find
	;
		tst	si
		jz	notFound
		cmp	si, bx
		mov	si, ds:[si]		; deref connection handle
		je	found
		mov	di, si
		add	di, offset EC_next
		mov	si, ds:[si].EC_next	; next connection handle
		jmp	findLoop
notFound:
		stc
found:
		.leave
		ret
FindConnection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyAllConnections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy all existing connections

CALLED BY:	EtherUnregister
PASS:		es	= dgroup
		ds	= EtherInfoResource segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	6/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyAllConnections	proc	near
		uses	ax,si
		.enter
removeLoop:
	;
	; Make sure there's something left...
		mov	si, ds:[EIH_connection]
		tst	si
		jz	done	; => No more...

		call	RemoveConnection
		jmp	removeLoop

done:
		clr	ds:[EIH_connection]
		.leave
		ret
DestroyAllConnections	endp

endif	; if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherSetAccessIPAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the local IP address for this access point.  If found,
		set it as our address but allow it to be overridden if 
		the peer suggests a different one.

CALLED BY:	EtherLinkConnect

PASS:		ds	= dgroup
		ax	= access point ID

RETURN:		nothing

DESTROYED:	bx, cx, dx, bp, di, si, es (allowed)

PSEUDO CODE/STRATEGY:
		Read address from access point library.
		If found, parse address into binary IP address in host 
		format and set it as our address, allowing override
		Update by Ed - get gateway address and subnet mask. Take
		out the automatic calls, as automatic configuration for
		ethernet means DHCP, which we can't call until after we're
		loaded. So basically the automatic call did nothing.
		If there is no configured netmask, assume 255.255.255.0.
		If there is no configured gateway, assume (ip AND mask) + 1.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version (PPPSetAccessIPAddr)
	ayuen	10/30/98		Shamelessly copied with small changes
	ed	06/06/00		Get gateway & netmask, auto removed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherSetAccessIPAddr	proc	near
		uses	ax
		.enter
	;
	; Get address string from access point, looking for APSP_AUTOMATIC
	; first.
	;
	;		clr	cx, bp			; standard property, alloc buf
	;		mov	dx, APSP_AUTOMATIC or APSP_ADDRESS
	;		call	AccessPointGetStringProperty	; bx = handle of block
							; cx = size of addr
	;	jnc	haveAddr

		clr	cx, bp			; standard property, alloc buf
		mov	dx, APSP_ADDRESS
		call	AccessPointGetStringProperty	; bx = handle of block
							; cx = size of addr
		jc	exit
haveAddr:
DBCS <		shl	cx, 1			; length -> size	>
	;
	; Parse address string into binary IP address.
	; 
		push	ax
		call	EtherParseDecimalAddr	; dxdi = addr in host form
		lahf
		call	MemFree			; free string block
		sahf
		pop	ax
		jc	exit

		xchg	dl, dh
		xchg	dx, di
		xchg	dl, dh
		movdw	ds:[localIpAddr], dxdi

		clr	cx, bp
		mov	dx, APSP_MASK
		call	AccessPointGetStringProperty	; bx = handle of block
							; cx = size of addr
		jc	noMask

	; Parse address string into binary IP address
		push	ax
		call	EtherParseDecimalAddr	; dxdi = addr in host form
		lahf
		call	MemFree			; free string block
		sahf
		pop	ax
		jc	noMask
		xchg	dl, dh
		xchg	dx, di
		xchg	dl, dh
		movdw	ds:[subnetMask], dxdi

getGateway:
		clr	cx, bp
		mov	dx, APSP_GATEWAY
		call	AccessPointGetStringProperty	; bx = handle of block
							; cx = size of addr
		jc	noGateway

		push	ax
		call	EtherParseDecimalAddr	; dxdi = addr in host form
		lahf
		call	MemFree			; free string block
		sahf
		pop	ax
		jc	noGateway
		xchg	dl, dh
		xchg	dx, di
		xchg	dl, dh
		movdw	ds:[gatewayAddr], dxdi

exit:
		.leave
		ret

noMask:
	; No subnet found. Assume 255.255.255.0, since it's usually that.
		movdw	ds:[subnetMask], 0FFFFFF00h
		jmp	getGateway

noGateway:
	; No gateway found. Assume (ip AND mask) + 1, since it's usually that.
		movdw	dxdi, ds:[localIpAddr]
		movdw	axbx, ds:[subnetMask]
		and	dx, ax
		and	di, bx
		inc	dh
		movdw	ds:[gatewayAddr], dxdi
		jmp	exit
EtherSetAccessIPAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherParseDecimalAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse an IP address string in x.x.x.x format into a binary
		IP address.   

CALLED BY:	EtherSetAccessIPAddr

PASS:		bx 	= block holding IP address string (freed by caller)
		cx	= size of address  (may be zero)

RETURN:		carry set if address is invalid
		else carry clear
		dxdi	= address in host format

DESTROYED:	ax, si, es (allowed)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	5/22/95			Initial version (PPPParseDecimalAddr)
	ayuen	10/30/98		Shamelessly copied

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherParseDecimalAddr	proc	near
		uses	bx, cx, ds
laddr		local	dword
		.enter
	;
	; Make sure address is a reasonable length.
	;
		jcxz	error

DBCS <		shr	cx					>
		cmp	cx, MAX_IP_DECIMAL_ADDR_LENGTH
		ja	error

		call	MemLock
		mov	ds, ax
		clr	si				; ds:si = address
	;
	; Strip any trailing garbage (non-digit) in the address.
	;
		push	si
		add	si, cx
DBCS <		add	si, cx					>
		clr	ax
scanLoop:
		LocalPrevChar	dssi			; ds:si = last valid char
		LocalGetChar	ax, dssi, NO_ADVANCE	
		call	LocalIsDigit
		jnz	stopScanning

		dec	cx
		jnz	scanLoop			
stopScanning:
		pop	si
		jcxz	error
	;
	; Convert the string to the binary address, detecting
	; any errors.  Each part of the address must begin with 
	; a digit.  The rest may be a digit or a dot, except for
	; the last part.  Max value of each part is 255.
	;
		lea	di, laddr
		mov	bx, MAX_IP_ADDR_OFFSET
digitOnly:
		clr	ax
		LocalGetChar	ax, dssi
		sub	ax, '0'
		cmp	ax, 9
		ja	error				; not a digit
		dec	cx
		jz	noMore
digitOrDot:
		clr	dx
		LocalGetChar	dx, dssi
		cmp	dx, '.'
		je	isDot
		sub	dx, '0'
		cmp	dx, 9
		ja	error				; not a digit

		push	cx
		mov	cl, 10
		mul	cl
		pop	cx
		add	ax, dx
		tst	ah
		jnz	error				; overflow

		loop	digitOrDot
		jmp	noMore
isDot:
		mov	ss:[bx][di], al
		dec	bx
		js	error

		loop	digitOnly
		jmp	error
noMore:
	;
	; Store the final value and make sure there are enough parts
	; for a valid IP address.
	;
		mov	ss:[bx][di], al
		tst_clc	bx
		je	exit
error:		
		stc
exit:
		movdw	dxdi, laddr			; return address
		.leave
		ret
EtherParseDecimalAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareIpToLocalSubnet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the passed ip address is on the same subnet as the
		local ip address.

PASS:		dxax	= ip address

RETURN:		carry set if address is on another subnet
		else carry clear

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	ed	06/07/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareIpToLocalSubnet	proc	near
		checkIp		local	dword
		uses	ax, dx, bx, ds
		.enter

		mov	bx, dgroup
		mov	ds, bx
	;		xchg	dl, dh
	;		xchg	al, ah
		and	dx, ({dword}ds:[subnetMask]).high
		and	ax, ({dword}ds:[subnetMask]).low
		movdw	checkIp, dxax
		movdw	dxax, ds:[localIpAddr]
	;		xchg	al, ah
	;		xchg	dl, dh
		and	dx, ({dword}ds:[subnetMask]).high
		and	ax, ({dword}ds:[subnetMask]).low
		cmpdw	dxax, checkIp
		clc
		je sameSubnet
		stc

sameSubnet:
		.leave
		ret
CompareIpToLocalSubnet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForBroadcastAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the passed ip address is a broadcast address.
		Checks for both 255.255.255.255 and for the
		((NOT subnet) OR ip) broadcast address.

PASS:		dxax	= ip address

RETURN:		carry set if address is a broadcast address
		else carry clear

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	ed	06/07/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForBroadcastAddress	proc	near
		uses	bx, cx, ds
		.enter

	; check for all 1's broadcast (255.255.255.255)
		cmpdw	dxax, 0FFFFFFFFh
		je	foundBroadcast

	; check for ((NOT subnet) OR ip) broadcast
		mov	cx, dgroup
		mov	ds, cx
		movdw	cxbx, ds:[subnetMask]
		not	cx
		not	bx
		or	cx, ({dword}ds:[localIpAddr]).high
		or	bx, ({dword}ds:[localIpAddr]).low
		cmpdw	dxax, cxbx
		je	foundBroadcast

		clc
exitBroadcast:
		.leave
		ret

foundBroadcast:
		stc
		jmp exitBroadcast

CheckForBroadcastAddress	endp

MovableCode	ends

