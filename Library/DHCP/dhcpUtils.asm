COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Socket
MODULE:		DHCP
FILE:		dhcpUtils.asm

AUTHOR:		Eric Weber, Jun 27, 1995

ROUTINES:
	Name			Description
	----			-----------
    GLB DHCPEntry               Entry point for DHCP library

    INT DHCPUnparseIPAddr       Convert a binary address to dotted decimal

    INT DHCPGetBroadcastAddr    Get the broadcast address to use

    INT DHCPParseDecimalAddr    Parse an IP address string in x.x.x.x
				format

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/27/95   	Initial revision


DESCRIPTION:
	
		

	$Id: dhcpUtils.asm,v 1.1 97/04/04 17:53:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


idata	segment

randomSeed	word

idata	ends

DHCPCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DHCPEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for DHCP library

CALLED BY:	GLOBAL (kernel geode code)
PASS:		di	- LibraryCallType
RETURN:		carry clear
DESTROYED:	ax,bx,ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DHCPEntry	proc	far
		ForceRef	DHCPEntry
		.enter
		cmp	di, LCT_ATTACH
		jne	done
	;
	; initialize random number generator
	;
		mov	bx, handle dgroup
		call	MemDerefDS
		call	TimerGetCount		; bxax = counter
		mov	ds:[randomSeed], ax
	;
	; read the broadcast address
	;
		call	DHCPGetBroadcastAddr
done:
		clc
		.leave
		ret
DHCPEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DHCPUnparseIPAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a binary address to dotted decimal

CALLED BY:	DHCPConvertAndSave
PASS:		ds:si	- binary address
		es:di	- buffer for dotted decimal
			  should be MAX_IP_DECIMAL_ADDR_LENGTH_ZT chars long
RETURN:		es:di	- null terminated dotted decimal string
		ds:si	- pointing past address
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	6/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DHCPUnparseIPAddr		proc	near
		uses	ax,bx,cx,dx,di,bp
		.enter
EC <		Assert	fptrXIP, esdi					>
	;
	; initialize the loop
	;
		clr	dx
		mov	bp,4
	;
	; convert each byte to decimal
	;
top:
		clr	ah
		lodsb
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii
		dec	bp
		jz	done
		add	di,cx
	;
	; replace the null with a period
	;
EC <		Assert	fptr, esdi					>
		mov	ax, C_PERIOD
		LocalPutChar	esdi, ax
		jmp	top
done:
		.leave
		ret
DHCPUnparseIPAddr		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DHCPGetBroadcastAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the broadcast address to use

CALLED BY:	DHCPEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	2/ 6/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dhcpCategory	char	"DHCP",0
broadcastKey	char	"broadcast address",0
DHCPGetBroadcastAddr	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; read the init file string
	;
		mov	cx, cs
		mov	dx, offset broadcastKey		; cx:dx = key
		mov	ds, cx
		mov	si, offset dhcpCategory		; ds:si = category
		clr	bp				; allocate a block
		call	InitFileReadString		; bx = handle of block
		jc	done
		jcxz	cleanup
	;
	; parse it
	;
		call	MemLock
		mov	ds, ax
		clr	si
		call	DHCPParseDecimalAddr		; dxax = address
		jc	cleanup
	;
	; store it
	;
		segmov	ds, <segment rawAddr>, cx
		mov	si, offset rawAddr
		mov	{word}ds:[si].TAPRA_ipAddr, ax
		mov	{word}ds:[si].TAPRA_ipAddr[2], dx
cleanup:
		call	MemFree
done:
		.leave
		ret
DHCPGetBroadcastAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DHCPParseDecimalAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse an IP address string in x.x.x.x format into a binary
		IP address.  MUST NOT destroy passed in string!

CALLED BY:	TcpipResolveAddr

PASS:		ds:si	= address string (not null terminated)
		cx	= string length 

RETURN:		carry set if invalid address string
		else
		dxax	= IP address in network order

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if string size is too long, return error

		Warning will get printed more than once but I didn't know
		where else to put it in the loop...

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	10/31/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DHCPParseDecimalAddr	proc	far
		uses	bx, cx, di, si, es
laddr		local	dword		
		.enter
	;
	; Make sure address is a reasonable length, stripping any
	; trailing white space.  Any non-digits end up getting stripped
	; as well.
	;
		push	si
		add	si, cx
DBCS <		add	si, cx						>
		clr	ax
scanLoop:
		LocalPrevChar	dssi			; ds:si = last valid char
		LocalGetChar	ax, dssi, NO_ADVANCE	
		call	LocalIsDigit
		jnz	doneScanning

		dec	cx
EC <		WARNING ALLOWING_INVALID_DESTINATION_BUT_PLEASE_FIX_IT_BUB >
		jnz	scanLoop	
doneScanning:
		pop	si

		jcxz	error
		cmp	cx, MAX_IP_DECIMAL_ADDR_LENGTH
		ja	error
	;
	; Convert the string to the binary address, detecting
	; any errors.  Each part of the address must begin with 
	; a digit.  The rest may be a digit or a dot, except for
	; the last part.  Max value of each part is 255.
	;
		lea	di, laddr
		clr	bx				; offset into laddr
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
		inc	bx
		cmp	bx, NUM_DOTS_IN_DECIMAL_IP_ADDR
		ja	error				; too many parts

		loop	digitOnly
		jmp	error				; cannot end with dot
noMore:
	;
	; Store the final value and make sure there are enough
	; parts for a valid IP address.
	;
		mov	ss:[bx][di], al
		cmp	bx, NUM_DOTS_IN_DECIMAL_IP_ADDR
		jne	error

		movdw	dxax, laddr
		jmp	exit				; carry clear
error:
EC <		WARNING INVALID_DESTINATION_IN_INIT_FILE		>
		stc
exit:
		.leave 
		ret

DHCPParseDecimalAddr	endp

DHCPCode	ends



