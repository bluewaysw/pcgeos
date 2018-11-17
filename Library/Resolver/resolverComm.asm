COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Socket project
MODULE:		resolver
FILE:		resolverComm.asm

AUTHOR:		Steve Jang, Dec 14, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94   	Initial revision

DESCRIPTION:
	Communication module of resolver.		

	$Id: resolverComm.asm,v 1.1 97/04/07 10:42:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResolverResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverServerThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Server thread that loops around receiving packets

CALLED BY:	ThreadCreate
PASS:		cx	= socket handle
RETURN:		never
DESTROYED:	doesn't matter

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverServerThread	proc	far
		sktHandle	local	word
		heapHandle	local	hptr
		buffHandle	local	optr	; current buffer in question
		tempHandle	local	optr	; temporary buffer handle
		ForceRef tempHandle
		.enter
	;
	; Initialize
	;
		mov	sktHandle, cx
		GetDgroup ds, bx
		mov	bx, ds:hugeLMem
		mov	heapHandle, bx
recvLoop:
		call	ResolverPoll	; cx = size of data available
		jc	exit
		call	ResolverReadMsg	; dx = size of pkt when decompressed
		jc	corrupted
					; es:di = buffer containing pkt
					; buffHandle = optr to pkt buffer
		call	ResolverConvertMsg ; es:di = converted to little endian
		call	ResolverUncompressMsg ; es:di = uncompressed
		call	ResolverPostServerMsg ; es:di & buffHandle 
		jmp	recvLoop	      ; not valid any longer
exit:
	;
	; Take care of exit requests
	;
		GetDgroup ds, bx
		mov	bx, ds:socketHandle
		call	SocketClose	; ax = socket error
	;
	; Reinitialize RSF_SHUTTING_DOWN flag and unblock event thread
	;
		BitClr	ds:resolverStatus, RSF_SHUTTING_DOWN
		VSem	ds, exitSem, TRASH_AX_BX
	;
	; Destroy the thread
	;
		clr	cx, dx, bp, si
		jmp	ThreadDestroy
		.leave .unreached
corrupted:
	;
	; Packet is corrupted, flush all data in the socket
	;
;		call	ResolverPoll	; cx = total number of bytes in socket
;		mov	dx, cx
;		call	ResolverReadMsg	; buffHandle, es:di = temp buffer
	;
	; Deallocate the packet
	;
		movdw	axcx, buffHandle
		mov	bx, ax
		call	HugeLMemUnlock
		call	HugeLMemFree
		jmp	recvLoop
ResolverServerThread	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverCheckExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks exit condition
CALLED BY:	Utility
PASS:		nothing
RETURN:		carry set if exit condition is set
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverCheckExit	proc	near
		uses	ds, bx
		.enter
		GetDgroup ds, bx
		test	ds:resolverStatus, mask RSF_SHUTTING_DOWN
		jnz	done_c
	;
	; Try to update cache here
	;
		test	ds:resolverStatus, mask RSF_CACHE_AGE
		jz	done				; CF = 0
	;
	; Post cache refresh event
	;
		mov	ax, RE_UPDATE_CACHE
		ResolverPostEvent_NullESDS
		clc
done:
		.leave
		ret
done_c:
		BitClr	ds:resolverStatus, RSF_SHUTTING_DOWN
		stc
		jmp	done
ResolverCheckExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverPoll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Polls the socket in sktHandle

CALLED BY:	ResolverServerThread
PASS:		sktHandle  = handle of socket to recv data from
RETURN:		carry set if exit condition
		carry clear if continue condition
			cx = total number of bytes available in socket
DESTROYED:	ax, bx, di
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverPoll	proc	near
		.enter	inherit	ResolverServerThread
EC <	; Make sure we blow up if SocketRecv expects a passed buffer.	>
EC <		push	es			; save passed es	>
EC <		segmov	es, 0xa000, ax					>
poll:
		call	ResolverCheckExit	; even if something came in
		jc	done			; we quit if we have to quit
		mov	ax, mask SRF_PEEK	; ax = SocketRecvFlag
		mov	bx, sktHandle		; bx = socket handle
		mov	cx, 0			; cx = just peek 'size'
		push	bp
		mov	bp, RESOLVER_POLL_INTERVAL
		call	SocketRecv
		pop	bp
		jcxz	poll
		call	ResolverCheckExit	; even if something came in
						; we quit if we have to quit
EC <		jc	done						>
TESTP <		WARNING_NC SOMETHING_CAME_IN				>
EC <		ERROR_C	RFE_GENERAL_FAILURE				>
	;
	; ax = SocketError
	; cx = amount of data available
	;
done:
EC <		pop	es			; restore passed es	>
		.leave
		ret
ResolverPoll	endp

ResolverResidentCode	ends

ResolverActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverReadMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the first DNS message from socket

CALLED BY:	ResolverServerThread
PASS:		sktHandle  = handle of socket to recv data from
		heapHandle = hugeLMem handle to use
		cx	   = total number of bytes available in the socket
RETURN:		es:di	= buffer that contains DNS message
		buffHandle = optr of the DNS message
		carry set if packet is corrupted
		otherwise carry clear:
			dx = size of the message when it is uncompressed
DESTROYED:	ax, bx, ds
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/19/2000	Merged with ResolverPeek
	SJ	2/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverReadMsg	proc	far
		.enter	inherit	ResolverServerThread
	;
	; Allocate a buffer big enough for available data
	;
retry:
		push	cx
		mov	ax, cx
		mov	bx, heapHandle
		mov	cx, RESOLVER_SERVER_THREAD_SLEEP_COUNT
		call	HugeLMemAllocLock
		mov_tr	bx, cx
		pop	cx
		jc	retry
	;
	; Read data in
	; ds:di	= buffer seg
	; axbx  = buffer optr
	; cx	= size of the buffer
	;
		movdw	buffHandle, axbx
		segmov	es, ds, bx		; es:di	= buffer
		clr	ax			; ax = SocketRecvFlag
		mov	bx, sktHandle		; bx = socket handle
		push	bp
		mov	bp, NO_WAIT
		call	SocketRecv		; es:di filled in
		pop	bp			; cx = no change
EC <		ERROR_C	RFE_GENERAL_FAILURE				>
	;
	; There is a maximum byte count for DNS packets transmitted over UDP.
	; If we get a packet larger than that maximum, discard it.
	;
		cmp	cx, MAX_UDP_RESPONSE_LENGTH
EC <		ERROR_A	RFE_GENERAL_FAILURE				>
		ja	error

	;
	; Convert header information:
	;   this should be done before anything!
	;
		call	ResolverConvertHeader	; es:di header converted
	;
	; Get size of the first message.  At the same time, compute the
	; size of the message when it gets uncompressed.
	;
		call	ResolverGetPacketSize	; carry set if corrupted packet
	;
	; ->
	; cx = amount of data to read from socket for the first DNS message
	; dx = size of DNS message when uncompressed( buffer size )
	;
done::
		.leave
		ret
error::
		stc
		jmp	done
ResolverReadMsg	endp

NUM_RRTS	equ	9
RRTTable	word \
	RRT_A, RRT_NS, RRT_CNAME, RRT_SOA, RRT_WKS, RRT_PTR, RRT_HINFO, \
	RRT_MX, RRT_TXT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverGetPacketSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the size of first DNS message in socket.  Handles
		truncated messages by updating the header to count only
		full RRs and returns byte counts for same.
CALLED BY:	ResolverReadMsg
PASS:		es:di = data read from socket
			( with header converted to our format )
		cx = byte length of data read from socket
RETURN:		carry clear if packet parsed correctly
		  dx = size of DNS message when uncompressed( buffer size )
		  header updated if packet was truncated
		carry set if packet was corrupted
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/19/200	Handle truncated packets
	SJ	2/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverGetPacketSize	proc	near
NEC <		uses	ax,bx,cx,si,di					>
EC <		uses	ax,bx,si,di					>
		rrCount		local	word
		.enter
EC <		push	cx						>
	;
	; Skip header
	;
		mov	si, di
		mov	ax, es:[di].RM_anCount
		add	ax, es:[di].RM_nsCount
		add	ax, es:[di].RM_arCount	; ax = # of RRs
		mov	rrCount, ax		; store in rrCount
		mov_tr	ax, cx			; ax = byte limit
		mov	cx, es:[di].RM_qdCount	; cx = # of questions
		mov	bx, size ResolverMessage
		mov	dx, bx
		add	di, bx
		sub	ax, bx
		jc	corruptedPkt		; where's the header??
	;
	; Skip questions
	; If the question section is truncated, abort with packet corrupted
	;
		jcxz	beforeRrLoop
qLoop:
	;
	; bx = orginal message size (EC ONLY)
	; dx = uncompressed message size
	;
		xchg	ax, cx			; cx = limit, ax = # q's
		jcxz	corruptedPkt		; nothing useful here if
						;  not all q's present
		call	SkipDomainNameBC	; bx, dx, di, cx adjusted
		jc	corruptedPkt		; bail if domain name trunc'd
		add	di, size word + size word ; QTYPE and QCLASS
EC <		add	bx, size word + size word			>
		add	dx, size word + size word ; QTYPE and QCLASS
		sub	cx, size word + size word
		jc	corruptedPkt		; bail if missing
		xchg	ax, cx			; ax = limit, cx = # q's
		loop	qLoop
beforeRrLoop:
		mov_tr	cx, ax			; cx <- byte limit
rrLoop:
	;
	; bx = orginal message size (EC ONLY)
	; dx = uncompressed message size
	;
	; Scan each RR.  If any individual RR is corrupted or truncated,
	; abort with packet corrupted.  If all RRs were complete but
	; fewer were present than indicated in the header, update the
	; header with the correct values.
	;
		tst	rrCount			; any more RRs expected?
		jz	done			; done if not
		jcxz	doneTrunc		; no more data: truncated
		call	SkipDomainNameBC
		jc	corruptedPkt		; bail if domain name trunc'd
		mov	ax, es:[di].RRC_type
		xchg	ah, al
		add	di, size ResourceRecordCommon
EC <		add	bx, size ResourceRecordCommon			>
		add	dx, size ResourceRecordCommon
		sub	cx, size ResourceRecordCommon
		jc	corruptedPkt		; bail if RR trunc'd
		push	es, di, cx
		segmov	es, cs, di
		mov	di, offset RRTTable
		mov	cx, NUM_RRTS
		repne scasw	; es:di = off by word from target
		jne	rrLoopAbort
		sub	di, offset RRTTable + size word
		mov	ax, cs:[RRTSkipTable][di]
		pop	es, di, cx
		call	ax			; skip RDATA
		jc	corruptedPkt		; bail if something trunc'd
		dec	rrCount
		jmp	rrLoop
corruptedPkt:
		stc
EC <		pop	cx						>
		jmp	exit
	;
	; if truncation occurred, ensure RMF_TC is set
	;
doneTrunc:
		test	es:[si].RM_flags, mask RMF_TC
		jz	corruptedPkt
	;
	; update the header counts to reflect the number of complete
	; RRs available.
	;
EC <		WARNING RW_FIXING_UP_TRUNCATION				>

		mov	ax, rrCount		; ax = # RRs missing
		lea	di, es:[si].RM_arCount	; start with last section
nextSection:
		mov	cx, es:[di]		; cx = # RRs expected
		cmp	ax, cx			; section has enough RRs to
						;  account for # missing?
		jbe	lastSection		; branch if so
		sub	ax, cx			; reduce missing by # in sect.
		clr	{word}es:[di]		; clear section
		sub	di, size word		; point to prev. section
EC <		push	si						>
EC <		lea	si, es:[si].RM_anCount	; di should not go	>
EC <		cmp	di, si			;  below last section	>
EC <		ERROR_B	-1						>
EC <		pop	si						>
		jmp	nextSection
lastSection:
		sub	es:[di], ax		; reduce sect. by # missing
done:
		clc				; no errors
	;
	; In EC, the computed message size in bx should not exceed original
	; message size passed in cx by the caller.
	;
EC <		pop	cx						>
EC <		cmp	bx, cx						>
EC <		ERROR_A RFE_GENERAL_FAILURE				>
exit:
		.leave
		ret
rrLoopAbort:
		pop	es, di, cx
		jmp	corruptedPkt
		
RRTSkipTable	nptr \
	skipRRT_A, skipRRT_NS, skipRRT_CNAME, skipRRT_SOA, skipRRT_WKS, \
	skipRRT_PTR, skipRRT_HINFO, skipRRT_MX, skipRRT_TXT
	;
	; Skip RDATA portion
	;
	; pass:	es:di	= RDATA portion
	;	es:si	= begining of packet
	; 	bx, dx	= current number of bytes skipped
	;	cx	= number of bytes remaining
	; return:
	;	bx, dx, di,cx adjusted
	;	ax destroyed
	;	carry set if skipping exceeded bounds
	;
skipRRT_A:
		add	di, size dword		; IP address
EC <		add	bx, size dword					>
		add	dx, size dword
		sub	cx, size dword		; carry set if trunc'd
		retn
skipRRT_SOA:
		call	SkipDomainNameBC	; MNAME
		jc	skipDone
		call	SkipDomainNameBC	; RNAME
		add	di, (size dword) * 5
EC <		add	bx, (size dword) * 5				>
		add	dx, (size dword) * 5
		sub	cx, (size dword) * 5	; carry set if trunc'd
skipDone:
		retn
skipRRT_WKS:
		mov	ax, es:[di-2]		; es:[di-2] = dataLen
		xchg	ah, al
EC <		add	bx, ax						>
	; Don't change dx, since we won't uncompress it. -dhunter 10/9/00
;;		add	dx, ax
		add	di, ax
		sub	cx, ax			; carry set if trunc'd
		retn
skipRRT_MX:
		add	di, size word
EC <		add	bx, size word					>
		add	dx, size word
		sub	cx, size word		; carry set if trunc'd
		jc	skipDone
		; FALLTHRU for EXCHANGE
skipRRT_PTR:					; ptr to host
skipRRT_NS:					; NS name
skipRRT_CNAME:					; CNAME
		jmp	SkipDomainNameBC
skipRRT_HINFO:
		call	SkipCharStringBC	; CPU string
		jc	skipDone
		; FALLTHRU to OS string
skipRRT_TXT:					; TXT
		jmp	SkipCharStringBC
ResolverGetPacketSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipDomainNameBC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip a domain name in a packet with bounds checking
CALLED BY:	ResolverGetPacketSize, SkipDomainName
PASS:		es:si = beginning of the packet
		es:di = domain name to skip
		bx    = number of bytes skipped so far (EC ONLY)
		dx    = number of real bytes skipped so far
			(including decompression)
		cx    = number of bytes remaining in packet from es:di
RETURN:		bx, dx, di = adjusted to point at the next piece of data
		cx    = new number of bytes remaining
		carry clear if complete domain name was skipped,
		otherwise set
DESTROYED:	bx (NEC ONLY)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/19/2000    	Added bounds checking
	SJ	1/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipDomainNameBC	proc	near
		uses	ax,si,bp
		.enter
		push	cx			; save cx
		push	di
		push	dx			; save dx
		mov_tr	dx, cx			; dx = bytes remaining
		add	dx, di			; es:dx = end of packet + 1
		dec	dx			; es:dx = end of packet
		clr	cx
EC <		mov	bp, bx			; bp = bx passed in	>
NEC <		clr	bx						>
skipLabelBC:
		cmp	dx, di
		jc	abort			; branch if out of data
		inc	cx
		mov	al, {byte}es:[di]
		inc	di
		tst	al
		jz	stop
		test	al, 11000000b		; looking for 11xxxxxxb
		jz	skipLabel		; zf = 0 if bit 6 or 7 set and
		js	skipPtr			; sf = 1 if bit 7 set
skipLabel:
	;
	; variable-length label, al = length
	;
		clr	ah			; ax = al (zero extended)
		cmp	dx, di
		jc	abort			; branch if out of data
		add	cx, ax
		add	di, ax
		jmp	skipLabelBC
	;
	; compressed domain name
	;
skipPtr:
		cmp	dx, di
		jc	abort			; branch if out of data
		and	al, 00111111b
		mov	ah, al
		inc	cx
		mov	al, {byte}es:[di]	; read lower section of offset
		mov	di, si
		add	di, ax			; es:di = compressed part
EC <		cmp	bx, bp						>
NEC <		tst	bx						>
		jne	skipAdd
		add	bx, cx			; bx = finalized
skipAdd:
		sub	cx, 2			; ptr removed when decomp'd
		jmp	skipLabelBC
stop:
		pop	dx			; dx = comp'd bytes skipped
		add	dx, cx
EC <		cmp	bx, bp						>
NEC <		tst	bx						>
		jne	compressionOccured
		add	bx, cx			; no compression occured
compressionOccured:
		pop	di
EC <		sub	bx, bp			; difference		>
		add	di, bx
		pop	cx			; restore cx
		sub	cx, bx			; cx = bytes remaining
EC <		add	bx, bp						>
	;
	; di = pointing at the next piece of information
	; bx, dx = incremented by the amount of data skiped
	; cx = reduced by amount of data skipped
	; carry cleared
	;
done:
		.leave
		ret
abort:
		pop	dx
		pop	di
		pop	cx
		jmp	done
SkipDomainNameBC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipCharStringBC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip a character string in a packet with bounds checking

CALLED BY:	ResolverGetPacketSize, SkipCharString
PASS:		es:di = character string to skip
		bx    = number of bytes skipped so far
		dx    = number of real bytes skipped so far
			(including decompression)
		cx    = number of bytes remaining in packet from es:di
RETURN:		bx, dx, di = adjusted to point at the next piece of data
		cx    = new number of bytes remaining
		carry clear if complete character string was skipped,
		otherwise set
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/19/2000    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipCharStringBC	proc	near
		dec	cx
		jc	done			; branch if out of data
		call	SkipCharString
		sub	cx, ax			; carrry set if out of data
done:
		ret
SkipCharStringBC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipDomainName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip a domain name in a packet
CALLED BY:	ResolverConvertMsg
PASS:		es:si = beginning of the packet
		es:di = domain name to skip
RETURN:		di = adjusted to point at the next piece of data
DESTROYED:	bx, dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/19/2000    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipDomainName	proc	near
		push	cx
EC <		clr	bx			; prevent overflows	>
		mov	cx, 256			; assume largest name
		call	SkipDomainNameBC
EC <		ERROR_C	RFE_GENERAL_FAILURE	; should never return error >
		pop	cx
		ret
SkipDomainName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipCharString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip a character string in a packet

CALLED BY:	ResolverConvertMsg, SkipCharStringBC
PASS:		es:di = character string to skip
		bx    = number of bytes skipped so far
		dx    = number of real bytes skipped so far
			(including decompression)
RETURN:		bx, dx, di = adjusted to point at the next piece of data
		ax = # octets in string (not including length octet)
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/19/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkipCharString	proc	near
	;
	; A character string is a single length octet followed by that
	; number of octets.
	;
		mov	al, {byte}es:[di]	; al = length octet
		clr	ah			; ax = length octet
		inc	ax			; ax = full string length
		add	bx, ax
		add	dx, ax
		add	di, ax
		ret
SkipCharString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverConvertMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the message to the format PC uses, namely little
		endian
CALLED BY:	ResolverServerThread
PASS:		es:di	= packet
RETURN:		es:di was converted
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverConvertMsg	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Skip header( header is converted separately )
	;
		mov	si, di
		mov	cx, es:[di].RM_qdCount	; cx = # of questions
		mov	ax, es:[di].RM_anCount
		add	ax, es:[di].RM_nsCount
		add	ax, es:[di].RM_arCount	; ax = # of RRs
		mov	bx, size ResolverMessage
		mov	dx, bx
		add	di, bx
	;
	; Convert questions
	;
		jcxz	beforeRrLoop
		push	ax
qLoop:
		call	SkipDomainName		; bx, dx destroyed
		ConvertWordESDI			; QTYPE
		ConvertWordESDI			; QCLASS
		loop	qLoop
		pop	ax
beforeRrLoop:
		mov	cx, ax
		jcxz	done
rrLoop:
		call	SkipDomainName
		mov	ax, es:[di].RRC_type
		xchg	ah, al
		push	ax
		ConvertWordESDI		; type
		ConvertWordESDI		; class
		ConvertDwordESDI	; ttl
		ConvertWordESDI		; dataLen
		pop	ax
		push	es, di, cx
		segmov	es, cs, di
		mov	di, offset RRTTable
		mov	cx, NUM_RRTS
		repne scasw		; es:di is off by word
EC <		ERROR_NE RFE_GENERAL_FAILURE				>
		sub	di, offset RRTTable + size word
		mov	ax, cs:[RRTConvertTable][di]
		pop	es, di, cx
		call	ax			; process RDATA
		loop	rrLoop
done:
		.leave
		ret
RRTConvertTable	nptr \
	convRRT_A, convRRT_NS, convRRT_CNAME, convRRT_SOA, convRRT_WKS, \
	convRRT_PTR, convRRT_HINFO, convRRT_MX, convRRT_TXT
	;
	; Skip RDATA portion
	;
	; pass:	es:di	= RDATA portion
	; return:
	;	es:di	= converted
	;	di adjusted
	; destroyed:
	;	bx, dx, ax
	;
convRRT_A:
		add	di, size dword
		retn
convRRT_SOA:
		call	SkipDomainName	; MNAME
		call	SkipDomainName	; RNAME
		ConvertDwordESDI
		ConvertDwordESDI
		ConvertDwordESDI
		ConvertDwordESDI
		ConvertDwordESDI
		retn
convRRT_WKS:
	;
	; In this case, skip the entire data section
	;
		add	di, es:[di-2]	; es:[di-2] = size of data
		retn
convRRT_MX:
		ConvertWordESDI
		; FALLTHRU for EXCHANGE
convRRT_PTR:				; ptr to host
convRRT_NS:				; NS name
convRRT_CNAME:				; CNAME
		jmp	SkipDomainName
convRRT_HINFO:
		call	SkipCharString	; CPU string
		; FALLTHRU to OS string
convRRT_TXT:
		jmp	SkipCharString
ResolverConvertMsg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverConvertHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the header information to a desired format

CALLED BY:	ResolverServerThread
PASS:		es:di = ResolverMessage
RETURN:		es:di = header converted from little endian to big endian and
			big to little
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverConvertHeader	proc	far
		uses	ax, cx, di
		.enter
	;
	; Don't convert ID and flags
	;
		add	di, size word + size word
		mov	cx, 4
headerLoop:
		ConvertWordESDI		; destroys ax, di inc'ed by 2
		loop	headerLoop
		.leave
		ret
ResolverConvertHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverUncompressMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompress an incoming packet

CALLED BY:	ResolverServerThread
PASS:		es:di	= packet to uncompress
		dx	= uncompressed packet size
RETURN:		es:di	= a new buffer containing uncompressed data
DESTROYED:	various unimportant things
SIDE EFFECTS:	buffHandle changed, original buffer freed
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	8/19/00		Rearrange buffer usage
	SJ	1/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverUncompressMsg	proc	far
		.enter	inherit	ResolverServerThread
	;
	; Allocate the new buffer
	;
		mov	si, di			; es:si = buffer
		GetDgroup ds, bx
EC <		mov	ax, dx			; ax = new buffer size	>
NEC <		mov_tr	ax, dx			; ax = new buffer size	>
		mov	bx, ds:hugeLMem
		mov	cx, NO_WAIT
		call	HugeLMemAllocLock	; ds:di = new buffer
	LONG	jc	exit
EC <		push	dx			; save for later	>
		movdw	tempHandle, axcx
		segxchg	ds, es, ax		; ds:si = old buffer,
						; es:di = new buffer
		mov	bx, si			; ds:bx = start of packet
	;
	; uncompress the copy and write the result to original buffer
	;

	;
	; Copy header
	;
		mov	ax, ds:[si].RM_qdCount
		mov	cx, ds:[si].RM_anCount
		add	cx, ds:[si].RM_nsCount
		add	cx, ds:[si].RM_arCount
		push	cx			; save cx
		copybuf	ResolverMessage		; si, di after header
		pop	cx			; restore cx
	;
	; Uncompress questions
	;
		tst	ax
		jz	beforeRrLoop
		push	cx
		mov	cx, ax
questionLoop:
		push	cx
		call	UncompressName		; di, si adjusted
		mov	cx, size word + size word ; QTYPE + QCLASS
		rep movsb
		pop	cx
		loop	questionLoop
		pop	cx
beforeRrLoop:
		jcxz	done
rrLoop:
		call	UncompressName		; di, si adjusted
		mov	ax, ds:[si].RRC_type
		push	cx
		mov	cx, size ResourceRecordCommon
		rep movsb
		push	es, di
		segmov	es, cs, di
		mov	di, offset RRTTable
		mov	cx, NUM_RRTS
		repne scasw ; es:di is off by word from the target
		sub	di, offset RRTTable + size word
		mov	ax, cs:[RRTUncompressTable][di]
		pop	es, di
		call	ax		; cx,dx destroyed
cont::
		pop	cx		
		loop	rrLoop

done:
	;
	; Deallocate the old packet buffer and store the new buffer's
	; handle in the old one's place.  Also for EC's benefit,
	; validate how much data we uncompressed against the length we
	; computed earlier to make sure we got the buffer length right.
	;
		movdw	axcx, buffHandle
		mov	bx, ax
		call	HugeLMemUnlock
		call	HugeLMemFree
EC <		mov	si, di			; *es:si = buffer end	>
EC <		pop	dx						>
EC <		sub	si, dx			; si should = di below	>
		movdw	axdi, tempHandle	; *es:di = new buffer
		movdw	buffHandle, axdi
		mov	di, es:[di]		; es:di = new buffer
EC <		cmp	si, di			; do they match?	>
EC <		ERROR_NE RFE_GENERAL_FAILURE				>
exit::
		.leave
		ret
		
RRTUncompressTable	nptr \
	UncompressRRT_A, UncompressRRT_NS, UncompressRRT_CNAME, \
	UncompressRRT_SOA, UncompressRRT_WKS, UncompressRRT_PTR, \
	UncompressRRT_HINFO, UncompressRRT_MX, UncompressRRT_TXT
	;
	; pass:
	;    ds:si = something to uncompress
	;    ds:bx = start of packet
	;    es:di = buffer to write to
	; return:
	;    di,si = adjusted
	; destroys: cx, dx
	;
UncompressRRT_A:
		movsw			; moves dword
		movsw
		retn
UncompressRRT_SOA:
	;
	; Update the length of the data too
	;
		mov	dx, di
		call	UncompressName	; MNAME
		call	UncompressName	; RNAME
		mov	cx, (size dword) * 5 / 2
		rep movsw
		mov	cx, di
		sub	cx, dx
		xchg	dx, di		; di = value on the entry 
		mov	{word}es:[di-2], cx
		xchg	dx, di		; restore proper di
		retn
UncompressRRT_WKS:
	;
	; ignored for now( to implement: see RFC-1010 )
	;
		clr	cx		; cx = new size of data
		xchg	cx, es:[di-2] 	; cx = orig. size of data
		add	si, cx		; skip it
		retn
UncompressRRT_MX:
		movsw
UncompressRRT_NS:
UncompressRRT_CNAME:
UncompressRRT_PTR:
	;
	; Update the length of the data too
	;
		mov	cx, di
		call	UncompressName
		mov	dx, di
		sub	dx, cx
		xchg	cx, di
		mov	{word}es:[di-2], dx
		xchg	cx, di
		retn
UncompressRRT_HINFO:
	;
	; Strings are copied verbatim
	;
		lodsb			; al = string length
		clr	ah		; ax = string length
		mov	cx, ax
		rep	movsb		; copy string
		; FALLTHRU to OS string
UncompressRRT_TXT:
		lodsb			; al = string length
		clr	ah		; ax = string length
		mov	cx, ax
		rep	movsb		; copy string
		retn
ResolverUncompressMsg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UncompressName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompress a name and put the result into buffer

CALLED BY:	ResolverUncompressPacket
PASS:		ds:si 	= name to uncompress
		ds:bx	= start of packet
		es:di	= buffer for resutl
RETURN:		di,si	= adjusted
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UncompressName	proc	near
		uses	ax,bx,cx,dx
		.enter
		clr	dx
again:
		lodsb
		tst	al
		jz	lastByte

		test	al, 11000000b		; looking for 11xxxxxxb
		jz	normalByte		; zf = 0 if bit 6 or 7 set and
		jns	normalByte		; sf = 1 if bit 7 set
		and	al, 00111111b
		mov_tr	ah, al
		lodsb
		tst	dx
		jz	storeLastSI
cont:
		mov	si, bx
		add	si, ax	; ds:si = rest of data
		jmp	again
normalByte:
		stosb
		clr	ah			; ax = al (zero extended)
		mov	cx, ax			; cx = # bytes in label
		rep movsb			; copy entire label
		jmp	again
lastByte:
		stosb
		tst	dx
		jz	done
		mov_tr	si, dx
done:
		.leave
		ret
storeLastSI:
		mov	dx, si
		jmp	cont
UncompressName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverPostServerMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Post DNS response to resolver event thread

CALLED BY:	ResolverServerThread
PASS:		es:di	= response packet to post
		buffHandle contains optr of the packet to post
RETURN:		various unimportant things
DESTROYED:	bufferHandle = 0

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverPostServerMsg	proc	far
		.enter	inherit	ResolverServerThread
	;
	; Unlock buffer
	;
		mov	bx, es:LMBH_handle
		call	HugeLMemUnlock
	;
	; Post event: packet will be discarded by event handler
	;
		push	bp
		clr	bx, ax
		xchg	bx, buffHandle.high
		xchg	ax, buffHandle.low
		mov	bp, ax
		mov	ax, RE_RESPONSE
		ResolverPostEvent_NullESDS
		pop	bp
		
		.leave
		ret
ResolverPostServerMsg	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverSendMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a query packet to the specified address
CALLED BY:	Utility
PASS:		axdx	= address to send the packet to
		cx	= size of the data in the packet
		es	= data packet
		ds:bp	= RequestNode
RETURN:		carry set on error
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverSendMessage	proc	far
		uses	ax,bx,cx,dx,si,di,ds,es
		.enter
	;
	; save data segment
	;
		push	es
	;
	; es:di = address structure
	;
		GetDgroup es, di
		mov	di, offset socketAddress

		mov	es:[socketAddress].SA_port.SP_port, \
			DOMAIN_NAME_SERVER_PORT
		mov	es:[socketAddress].SA_port.SP_manuf, \
			MANUFACTURER_ID_SOCKET_16BIT_PORT
		mov	es:[socketAddress].SA_domainSize, \
			RESOLVER_DOMAIN_NAME_SIZE
		mov	bx, es
		mov	es:[socketAddress].SA_domain.high, bx
		mov	es:[socketAddress].SA_domain.low, offset socketDomain
		movdw	es:[ipAddress], axdx
		mov	es:[linkDataSize], LINK_DATA_SIZE	; = 3
		mov	es:[linkType], LT_ID			; 
		segmov	es:[linkId], ds:[bp].RN_accessId, ax	; ID = accessId
	;
	; bx = socket handle
	;
		mov	ax, mask SSF_ADDRESS
		mov	bx, es:socketHandle
		pop	ds
		clr	si			; ds:si = data to send
		call	SocketSend
		
		.leave
		ret
ResolverSendMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueryNameServers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send query messages to name servers
CALLED BY:	ResolverEventResponse
PASS:		ds:si	= RequestNode
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueryNameServers	proc	near
		uses	ax,bx,cx,di,si,bp,es
		.enter
	;
	; Compose a query packet
	;
		GetDgroup es, bx
		mov	bx, es:queryMessage
		push	bx
		call	MemLock
		mov	es, ax
	;
	; Fill in header information
	;
		segmov	es:RM_id, ds:[si].RN_id, di
		mov	es:RM_qdCount, 1
		mov	di, offset RM_data
	;
	; Fill in the question section + STYPE and SCLASS
	;
		mov	dx, ds:[si].RN_nameLen
		mov	cx, dx
		push	si
		add	si, offset RN_name
		rep movsb
		pop	si
		mov	ax, ds:[si].RN_stype
		stosw
		mov	ax, ds:[si].RN_sclass
		stosw
	;
	; Convert message
	;
		clr	di
		call	ResolverConvertMsg
		call	ResolverConvertHeader
	;
	; Send the message to the first name server on slist
	; es = resolver message block
	;
		push	si
		mov	cx, dx			; cx = query packet size
		add	cx, size ResolverMessage + size word + size word
		mov	bp, si			; ds:bp = RequestNode
		mov	si, ds:[si].RN_slist
		mov	ax, 0			; first element
		push	cx
		call	ChunkArrayElementToPtr	; ds:di = first entry in slist
		jc	slistEmpty
	;
	; record the name server entry that we are querying now
	;
		segmov	ds:[bp].RN_nsQueried, ds:[di].SE_serverName, ax
		pop	cx
		call	QueryNameServerCallback
		pop	si
	;
	; Convert the message back to its original format
	;
		clr	di
		call	ResolverConvertHeader
		call	ResolverConvertMsg
	;
	; Unlock query message block
	;
		pop	bx
		call	MemUnlock
	;
	; Start query timer
	;
		mov	dx, ds:[si].RN_id
		mov	cx, ds:[si].RN_queryTimeout
		push	si
		mov	al, TIMER_ROUTINE_ONE_SHOT
		mov	bx, segment QueryTimerCallback
		mov	si, offset QueryTimerCallback
		mov	bp, handle 0
		call	TimerStart
		pop	si
		movdw	ds:[si].RN_queryTimer, axbx
done:
		.leave
		ret
slistEmpty:
	;
	; this should never happen
	;
		pop	ax, ax
		clr	di
		call	ResolverConvertHeader
		call	ResolverConvertMsg
		pop	bx
		call	MemUnlock
		stc
		jmp	done
QueryNameServers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueryNameServerCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a query message to a name server
CALLED BY:	QueryNameServers
PASS:		es = query message block
		cx = query message total size
		ds:bp = Request node
		ds:di = current SlistElement
RETURN:		nothing( carry clear )
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueryNameServerCallback	proc	far
		uses	ax, cx, dx, bp
		.enter
	;
	; Find address for the name server
	;
		movdw	axdx, ds:[di].SE_address
		tst	ax
		jz	findAddress
TESTP <		WARNING	TEST_AT_QN_2					>
cont:
	;
	; Send the packet to the server
	; 	es = query message block
	;	cx = query message total size
	;	axdx = address to send packet to
	;	ds:bp= current RequestNode
	;	ds:di= current SlistElement
	;
		call	ResolverSendMessage
		jc	error
doneClr:
		clc	; we go through other name servers anyways
done:
		.leave
		ret
error:
	;
	; record send error
	;
		BitSet	ds:[di].SE_flags, SF_SEND_ERROR
		jmp	doneClr
findAddress:
		push	ds		; save ResolverRequestBlock seg
		push	es		; save packet seg
		push	di		; save SlistElement
		segmov	es, ds
		mov	di, es:[di].SE_serverName
		mov	di, es:[di]	; es:di = server name
		mov	dx, RRT_A
		call	RecordFindFar	; ds:si = RR found or ds:si destroyed
		pop	di		; 
		pop	es		; es = packet
		jc	spawnRequest
		call	FindBestAddress	; axdx = IP address; ds,si destroyed
		pop	ds		; ds:di = current SlistElement
TESTP <		WARNING	TEST_AT_QN_3					>
		jmp	cont
spawnRequest:
		pop	ds		; recover request block
	;
	; If address is not found, spawn another request
	; ds:bp	= RequestNode
	; ds:di = current SlistElement
	;
		mov	ax, ds:[bp].NC_flags
		and	ax, mask NF_LEVEL
		cmp	ax, RESOLVER_MAX_REQUEST_TREE_LEVEL
EC <		WARNING_A RW_REQUEST_TREE_TOO_DEEP			>
		ja	done		; CF = 0
	;
	; serverName nptr = cx
	; Find current node handle with current node Id
	;
		mov	cx, ds:[di].SE_serverName
		mov	dx, ds:[bp].RN_id
		mov	si, bp
		call	TreeGotoParentFar	; ds:si = parent
EC <		ERROR_C	RFE_TREE_CORRUPTED				>
		call	TreeRecursiveSearchIdFar; ds:si/*bp = current node
EC <		ERROR_C	RFE_REQUEST_NOT_FOUND				>
	;
	; Post an event to create child request
	; cx	    = domain name chunk handle in ResolverRequestBlock
	; dx	    = resquest id of parent
	; bp	    = parent request node handle
	;
	; ES should be NULL_SEGMENT at the time this events get to the handler
	; since ES(currently message packet) will be unlocked by that time.
	;
		mov	ax, RE_SPAWN_CHILD_QUERY
		ResolverPostEvent_NullESDS
TESTP <		WARNING	TEST_AT_QN_4					>
		jmp	done
QueryNameServerCallback	endp

ResolverActionCode	ends

ResolverResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueryTimerCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query timer expired

CALLED BY:	kernel
PASS:		ax	= Request ID ( in RN_id )
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	7/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueryTimerCallback	proc	far
		uses	ax
		.enter
	;
	; post timer expire event to resolver event queue
	; we cannot do this directly because this routine is called on timer
	; interrupt and ResolverPostEvent requires P'ing a semaphore.
	; We will borrow other thread to do this.
	;
		mov	si, segment QueryTimerCallbackReal
		mov	di, offset QueryTimerCallbackReal
		call	CallOnUiThread
		.leave
		ret
QueryTimerCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueryTimerCallbackReal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Real callback routine that enqueues timer expiration event

CALLED BY:	QueryTimerCallback on UI thread
PASS:		ax	= request id( RN_id )
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	7/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueryTimerCallbackReal	proc	far
		uses	ax, dx
		.enter
		mov_tr	dx, ax			; dx = request id
		mov	ax, RE_QUERY_TIMER_EXPIRED
		call	ResolverPostEvent
		.leave
		ret
QueryTimerCallbackReal	endp


ResolverResidentCode	ends
