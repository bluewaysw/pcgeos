COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Socket
MODULE:		DHCP
FILE:		dhcpMain.asm

AUTHOR:		Eric Weber, Jun 26, 1995

ROUTINES:
	Name			Description
	----			-----------
    INT DHCPBuildRequest        Build a DHCPREQUEST message

    INT DHCPParseAck            Extract the useful information from an ACK

    INT DHCPConvertAndSave      Convert a binary IP address to string form
				and store it in the accpnt database

    INT DHCPQueryNet            Query the network for parameters

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/26/95   	Initial revision


DESCRIPTION:
	
	$Id: dhcpMain.asm,v 1.1 97/04/04 17:53:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixedData	segment

serverAddr	SocketAddress <
	<DHCP_SERVER_PORT, MANUFACTURER_ID_SOCKET_16BIT_PORT>,
	size tcpDomain,
	tcpDomain,
	size rawAddr >

rawAddr TcpAccPntResolvedAddress <3, LT_ID, 0, <255, 255, 255, 255>>

tcpDomain	char	"tcpip",0

FixedData	ends

idata	segment

startupSem	Semaphore	<1,0>

idata	ends

udata	segment

configThread	hptr	0
interruptFlag	byte	0

udata	ends

DHCPCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DHCPConfigure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a DHCP query

CALLED BY:	GLOBAL (resolver library)
PASS:		bx	- access point ID
		dxax	- local IP address
RETURN:		carry set on error
		ax	- DHCPError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	9/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DHCPConfigure	proc	far
		uses	bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; Move args to other regs
	;
		mov_tr	bp, ax
		mov_tr	cx, bx
	;
	; find dgroup
	;
		mov	bx, handle dgroup
		call	MemDerefDS
	;
	; lock the in-use flag and see if library is in use
	;
		mov	ax, ss:[TPD_threadHandle]
		PSem	ds, startupSem
		tst	ds:[configThread]
		jnz	inUse
	;
	; if not in use, store our thread handle
	;
		mov	ds:[configThread], ax
	;
	; unlock the in-use flag
	;
inUse:
		pushf
		VSem	ds, startupSem
		popf
	;
	; if it is in use, abort now
	;
		mov	ax, DE_BUSY
		jnz	done
	;
	; do the actual query
	;
		call	DHCPQueryNet
	;
	; mark lib as not in use, preserving flags
	; it isn't necessary to use the startupSem here, since only
	;   one thread at a time can reach this code
	;
		mov	ds:[configThread], 0
done:
		.leave
		ret
DHCPConfigure	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DHCPBuildRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a DHCPREQUEST message

CALLED BY:	
PASS:		dxax	- our IP address
RETURN:		es:di	- request
			
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DHCPBuildRequest	proc	near
		uses	ax,bx,cx,dx,si,bp
		.enter
	;
	; allocate a block for the REQUEST message
	;
		push	dx,ax
		mov	ax, SIZEOF_DMT_REQUEST + size DHCPBlockHeader
		mov	cx, ALLOC_DYNAMIC_LOCK or ( mask HAF_ZERO_INIT shl 8 )
		call	MemAlloc
		mov	es, ax
		mov	ds, ax
		mov	es:[DBH_block], bx		; put handle in block
		mov	di, size DHCPBlockHeader
		pop	dx,ax
	;
	; dxax = ip addr
	; bx = mem handle
	; es:di = beginning of buffer
	;
		
	;
	; initialize the fixed fields
	;
		mov	ds:[di].DM_op, BO_REQUEST
		mov	ds:[di].DM_htype, HTYPE_SERIAL
		mov	ds:[di].DM_hlen, HTYPE_SERIAL_SIZE
		movdw	ds:[di].DM_ciaddr, dxax
		movdw	ds:[di].DM_yiaddr, dxax
		mov	{word}ds:[di].DM_chaddr, ax
		mov	{word}ds:[di+2].DM_chaddr, dx
		call	NetGenerateRandom32
		movdw	ds:[di].DM_xid, dxax
	;
	; store the cookie
	;
	; we want to store the high byte of the real value first, so
	; we actually write the low word of the permuted constant
	;
		add	di, offset DM_options
		mov	ax, DHCP_PERMUTED_COOKIE and 0ffffh
		stosw
		mov	ax, DHCP_PERMUTED_COOKIE shr 16
		stosw
	;
	; store the message type option
	;
		mov	al, DMO_DHCP_MESSAGE_TYPE
		stosb
		mov	al,1
		stosb
		mov	al, DMT_REQUEST
		stosb
	;
	; store the parameter request option
	;
		mov	al, DMO_PARAMETER_REQUEST
		stosb
		mov	al, 1
		stosb
		mov	al, DMO_DNS
		stosb
	;
	; write an END marker
	;
		mov	al, DMO_END
		stosb
	;
	; determine size of the whole message
	;
EC <		cmp	di, SIZEOF_DMT_REQUEST + size DHCPBlockHeader	>
EC <		ERROR_A BLOCK_TOO_SMALL					>
		mov	di, size DHCPBlockHeader
		mov	ds:[DBH_size], SIZEOF_DMT_REQUEST
		.leave
		ret
DHCPBuildRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DHCPParseAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the useful information from an ACK

CALLED BY:	
PASS:		es:di	- ACK
		ds:di	- request
		dx	- access point to update
RETURN:		si	- DHCPInfo found
		carry set if not an ACK
DESTROYED:	nothing
SIDE EFFECTS:	update accpnt

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DHCPParseAck	proc	near
		uses	ax,bx,cx,dx,di,bp,ds
		.enter
		mov_tr	si,di
		clr	di
		mov	bx,dx
	;
	; First do some cursory verification of the message
	;
                cmp     es:[DBH_size], SIZEOF_DHCP_MINIMAL_MESSAGE
                jb      abort                           ; jb=jc
                cmp     es:[si].DM_op, BO_REPLY
                stc
                jne     abort
                cmpdw   ds:[si].DM_xid, es:[si].DM_xid, ax
                stc
                jne     abort
		add	si, size DHCPMessage
		segmov	ds,es
		mov	bp, ds:[DBH_size]
		add	bp, size DHCPBlockHeader-1	; bp = max index
	;
	; check the cookie, accounting for network byte order
	;
		push	bx
		lodsw
		mov	bx, ax				; bx = low word
		lodsw					; ax = high word
		cmpdw	axbx, DHCP_PERMUTED_COOKIE
		stc
		pop	bx
		jne	abort
	;
	; analyze each option in turn
	;
top:
		cmp	bp,si
		jb	abort
		clr	ah
		lodsb
option::
	;
	; END and PAD can be handled trivially
	;
		cmp	al, DMO_END
		je	abort			; carry is clear
		cmp	al, DMO_PAD
		je	top
	;
	; all other options have at least two additional bytes,
	; so check here to see if we can read them
	;
		inc	si
		inc	si
		cmp	bp,si
		jb	abort
		dec	si
		dec	si
	;
	; if we have a message type, make sure it says ACK
	;
		cmp	al, DMO_DHCP_MESSAGE_TYPE
		jne	noMessage
		lodsb
		lodsb
		cmp	al, DMT_ACK
		je	top
		stc
	;
	; get out of the loop
	;
abort:
		jmp	done
noMessage:
	;
	; if there's a mask, write it out
	;
		cmp	al, DMO_SUBNET_MASK
		jne	noMask
		ornf	di, mask DI_NETMASK
		lodsb
	;
	; verify the size field
	;
		cmp	ax,4
		stc
		jne	done
		add	ax,si
		cmp	bp,ax
		jb	done
		mov	dx, APSP_MASK
		call	DHCPConvertAndSave
	;
	; this is a waypoint for conditional jumps back to the
	; top of the loop
	;
next:
		jmp	top
noMask:
	;
	; if there's a list of DNS servers, write out the first two
	;
		cmp	al, DMO_DNS
		jne	noDNS
		ornf	di, mask DI_NAMESERVER
		cmp	bp,si
		jb	done
		lodsb				; al = size
	;
	; make sure the size is divisible by four
	;
		test	al, 3
		stc
		jnz	done
	;
	; make sure the end of this option is within bounds
	;
		push	ax
		add	ax,si
		cmp	bp,ax
		pop	ax
		jb	done
	;
	; go ahead and parse two addresses
	;
		mov	dx, APSP_DNS1
		call	DHCPConvertAndSave	; write out first address
		sub	al,4
		jz	top			; any more?
		mov	dx, APSP_DNS2
		call	DHCPConvertAndSave	; write out second address
		sub	al,4
		add	si,ax			; skip the rest
		jmp	top
noDNS:
	;
	; ignore all other options
	;
		lodsb
		add	si,ax
		cmp	bp,si
		jae	next
done:
		mov	si,di
		.leave
		ret
DHCPParseAck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DHCPConvertAndSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a binary IP address to string form and store it
		in the accpnt database

CALLED BY:	DHCPParseAck
PASS:		dx	- AccessPointStandardProperty
		bx	- access point ID
		ds:si	- IP address to convert
RETURN:		ds:si	- advanced past address
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DHCPConvertAndSave	proc	near
		uses	ax,bx,cx,dx,di,bp,es
		.enter
	;
	; convert address to string
	;
SBCS <		sub	sp, MAX_IP_DECIMAL_ADDR_LENGTH_ZT		>
DBCS <		sub	sp, 2*MAX_IP_DECIMAL_ADDR_LENGTH_ZT		>
		segmov	es,ss,ax
		mov	di,sp
		call	DHCPUnparseIPAddr		; buffer filled
	;
	; store the string
	;
		mov	ax,bx
		clr	cx
		or	dx, APSP_AUTOMATIC
		call	AccessPointSetStringProperty
SBCS <		add	sp, MAX_IP_DECIMAL_ADDR_LENGTH_ZT		>
DBCS <		add	sp, 2*MAX_IP_DECIMAL_ADDR_LENGTH_ZT		>
		.leave
		ret
DHCPConvertAndSave	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DHCPQueryNet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query the network for parameters

CALLED BY:	DHCPProcessConfigure
PASS:		cx	- access point ID
		dxbp	- IP address
RETURN:		carry set on error or timeout
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	
     1.	send a REQUEST
     2.	read an ACK
     3. if no ACK arrives in 10 seconds, give up
     4. if we do get an ACK, and it contains a value we want, broadcast
	the value and stop wanting it
     4.	repeat 2-4 until we don't want anything or no ACK arrives in 10 sec

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DHCPQueryNet	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; set up the socket
	;
		push	cx
		push	dx, bp, cx		; save IP address, access ID
		mov	ax, SDT_DATAGRAM
		call	SocketCreate		; bx = socket handle
		jc	createError
		mov	cx, MANUFACTURER_ID_SOCKET_16BIT_PORT
		mov	dx, DHCP_CLIENT_PORT
		clr	bp
		call	SocketBind
		pop	dx, ax, cx
		jc	bindError
	;
	; build a DHCPREQUEST message
	;
		call	DHCPBuildRequest	; es:di = request message
		segmov	ds,es
	;
	; compute initial timeout
	;
		mov	dl, DHCP_QUERY_TIMEOUT_DELTA
		call	NetGenerateRandom8
		clr	dh
		add	dx, DHCP_QUERY_TIMEOUT_BASE
		mov	bp,dx
		pop	dx			; dx = access point ID
		mov	si, mask DI_NETMASK or mask DI_NAMESERVER
						; si = DHCPInfo,
		jmp	transmit

	;
	; adjust timeout value on retries
	;
timeout:
		cmp	ax, SE_TIMED_OUT
EC <		WARNING_NE UNEXPECTED_SOCKET_ERROR			>
		jne	cleanup
retry:
		shl	bp
		cmp	bp, DHCP_QUERY_TIMEOUT_MAX
		ja	cleanupC
	;
	; send the message
	;
transmit:
		push	si,dx
		mov	si, size DHCPBlockHeader ; ds:si = DHCPMessage
		segmov	es, <segment FixedData>, ax
		mov	di, offset serverAddr
		mov	es:[di].SA_address.TAPRA_accPntID, dx
		mov	cx, ds:[DBH_size]
		mov	ax, mask SSF_ADDRESS
		call	SocketSend
		pop	si,dx			; si = DHCPInfo,
		jc	timeout			; dx = access point ID
	;
	; wait for responses
	;
		mov	ax, mask SRF_PEEK
		clr	cx
		call	SocketRecv		; cx = packet size
		jc	timeout
	;
	; allocate a buffer for the response
	;
parse::
		push	bx
		push	cx
		mov	ax,cx
		add	ax,size DHCPBlockHeader
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; bx = handle, ax = segment
		mov	es,ax			
		pop	cx
		mov	es:[DBH_block], bx
		mov	es:[DBH_size], cx
		pop	bx
	;
	; read the response
	;
response::
		mov	di, size DHCPBlockHeader
		clr	ax
		call	SocketRecv
EC <		ERROR_C PACKET_THIEF_AT_WORK				>
	;
	; parse and discard the response
	; es = response block
	;
		call	DHCPParseAck		; carry set if rejected
EC <		WARNING_C NOT_AN_ACK					>
		push	bx
		mov	bx, es:[DBH_block]
		call	MemFree
		pop	bx
	;
	; retry if we didn't get a DNS address
	;
		test	si, mask DI_NAMESERVER		; clears carry
		jz	retry
cleanup:
	;
	; destroy socket that we are done using
	;
		pushf
		call	SocketClose
	;
	; free request message block
	; ds = request block
	;
		mov	bx, ds:[DBH_block]
		call	MemFree
		popf
done:
		.leave
		ret
cleanupC:
		stc
		jmp	cleanup
createError:
		pop	dx, bp, cx
		pop	cx
		stc
		jmp	done
bindError:
	;
	; Destroy socket
	;
		call	SocketClose
		pop	cx
		stc
		jmp	done
DHCPQueryNet	endp

DHCPCode	ends

