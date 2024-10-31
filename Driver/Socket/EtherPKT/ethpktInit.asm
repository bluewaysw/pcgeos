COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Edward Di Geronimo Jr. 2002.  All rights reserved.

PROJECT:	Native Ethernet Support
MODULE:		Ethernet packet driver
FILE:		ethpktInit.asm

AUTHOR:		Edward Di Geronimo Jr., 2/24/02

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	2/24/02   	Initial revision


DESCRIPTION:
		
	Init and exit code for EtherPkt.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;global EthPktRecvHandlerThread


InitCode		segment	resource

pktSignatureString	byte	"PKT DRVR",0
PKT_SIGNATURE_LENGTH	equ	9

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktContactDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish communicaiton with the packet driver

CALLED BY:	EtherInit

PASS:		nothing
RETURN:		carry set on error
DESTROYED:	ax, cx, dx, si, di, bp, ds, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	2/24/02    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktContactDriver	proc	near
		uses	bx
temp		local	word
		.enter

	;
	;  The packet driver can be on any interrupt from 60h to 80h.
	;  GEOS uses 80h, so it's not there. The interrupt will have the
	;  string "PKT DRVR" starting 3 bytes after the address of the
	;  interrupt handler.

		mov	bx, 60h * size dword
		clr	ax
		mov	dx, cs
trySlot:
		mov	ds, ax
		mov	di, ds:[bx].segment
		mov	es, di
		mov	di, ds:[bx].offset
		add	di, 3

		mov	cx, PKT_SIGNATURE_LENGTH
		mov	ds, dx
		mov	si, offset pktSignatureString
		repe	cmpsb
		je	foundIt

		add	bx, size dword		; move to next entry
		cmp	bx, 80h * size dword
		je	failure
		jmp	trySlot

foundIt:
	; bx = interrupt number * 4. So shift right twice and store it away.
		shr	bx
		shr	bx
		GetDGroup	ds, ax
		mov	ds:[offset intInstruction + 1], bl

	; Get driver info.
		mov	ah, PDF_DRIVER_INFO
		mov	al, 255
		call	callPacketDriver
		jc	oldDriver

		cmp	ch, DEVICE_CLASS_ETHERNET
		jne	failure

	; Found an ethernet device. Begin access.
		GetDGroup	ds, ax
		mov_tr	bx, dx
		call	setAccessType
		mov	cx, size word
		;pusha
		mov	temp, sp
		push	ax, cx, dx, bx
		push	temp 
		push 	bp, si, di
		push	es
		call	callPacketDriver
		jc	failure
		jmp	gotAccess

oldDriver:
	; We've got an old packet driver. Need to get a handle.
	; Try all types from 1 to 127.
		mov	cx, 127
		call	setAccessType
typeCheckLoop:
		mov_tr	bx, cx
		mov	cx, size word
		;pusha		; 16 bytes
		mov	temp, sp
		push	ax, cx, dx, bx
		push	temp
		push	bp, si, di

		push	es	; 18 bytes
		call	callPacketDriver
		jnc	gotAccess
		pop	es
		pop	bp, si, di
		pop	temp
		pop	ax, cx, dx, bx
		;mov	sp, temp
		;popa
		loop	typeCheckLoop
		jmp	failure

gotAccess:
		mov	ds:[pktIpHandle], ax
		pop	es
		pop	bp, si, di
		pop	temp
		pop	ax, cx, dx, bx
		;mov	sp, temp
		;popa
		mov	si, offset packetTypeARP
		mov	cx, size word
		call	callPacketDriver
		jc	arpAccessFailed
		mov	ds:[pktArpHandle], ax

		mov	ds:[linkEstablished], TRUE
		clc
done:
		.leave
		ret

arpAccessFailed:
		mov	ah, PDF_RELEASE_TYPE
		mov	bx, ds:[pktIpHandle]
		call	callPacketDriver
failure:
		stc
		jmp	done	

setAccessType	label	near
		mov	ah, PDF_ACCESS_TYPE
		mov	al, DEVICE_CLASS_ETHERNET
		clr	dx
		mov	si, offset packetTypeIP
		mov	di, segment EthPktRecvHandler
		mov	es, di
		mov	di, offset EthPktRecvHandler
		retn
EthPktContactDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktInitRecvBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init the link list of free buffers

CALLED BY:	EthDevInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	si, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We use ECB_nextLink.offset to maintain a linked list of free ECBs.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	04/24/02	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktInitRecvBuffers	proc	near

	;
	; Make the list head point to the first array entry.
	;
	GetDGroup	ds, ax
	mov	di, offset recvBuffers
	mov	ds:[recvBufFreeList], di
	mov	cx, NUM_RECV_BUFFERS - 1

next:
	;
	; Make each array entry point to the next one.
	;
	mov	si, di
	add	di, size ReceiveBuffer
	mov	ds:[si].RB_nextLink, di
	loop	next

	;
	; Null-terminate the last array entry.
	;
	mov	ds:[di].RB_nextLink, NULL

	mov	al, PRIORITY_HIGH

	mov	bx, ds     ; thread function parameter
	mov	cx, segment EthPktRecvHandlerThread
	mov	dx, offset EthPktRecvHandlerThread
	mov	di, 1024
	mov	bp, handle 0   ; owner
	;call	ThreadCreate

	ret
EthPktInitRecvBuffers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthPktDetachPkt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister stack, and stop communication with LSL.

CALLED BY:	EthDevExit
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	04/24/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthPktDetachPkt	proc	near
		GetDGroup	ds, ax
		mov	ds:[linkEstablished], FALSE
		mov	ah, PDF_RELEASE_TYPE
		mov	bx, ds:[pktIpHandle]
		call	callPacketDriver
		mov	ah, PDF_RELEASE_TYPE
		mov	bx, ds:[pktArpHandle]
		call	callPacketDriver
		ret
EthPktDetachPkt	endp

InitCode		ends
