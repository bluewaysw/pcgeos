COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		netware.asm

AUTHOR:		Adam de Boor, Feb 27, 1994

ROUTINES:
	Name			Description
	----			-----------
    EXT	NetWare_Init
    EXT	NetWare_Exit
    EXT	NetWare_ReadMsg
    EXT	NetWare_SetHardwareType
    EXT	NetWare_WriteMsg
    
    EXT	com_IntLevel		interrupt level used for communication --
				must be made highest priority while stopped
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/27/94		Initial revision


DESCRIPTION:
	Functions to implement Novell Netware support for communications.
	
	Only one incoming and one outgoing packet is allowed at a time. If
	the stub wishes to send something while the previous send is still
	in-progress, this code will loop until the ECB is marked as no longer
	in-use.
	
	A new RECEIVE_PACKET call will not be made until after the data from 
	the previous one have been retrieved.
	
	This code hooks the int 28h idle-time interrupt and the int 8h timer
	interrupt, to check for a packet having been received while 
	not in Rpc_Wait. This has implications for certain types of death.

TO DO:
	To support debugging in an internetwork environment, this code will
	want to, for each packet received from a different address, use
	the GET_RELAY function to find the router to which the packet should
	go.

	$Id: netware.asm,v 1.3 94/06/01 17:33:52 jimmy Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_Netware	= 1
		include	stub.def

ifdef NETWARE		; don't have any of this stuff when not using netware

IPX_MAX_PACKET	equ	546	; max # of data bytes in an IPX packet

IPX_SOCKET_NUM	equ	0x3f00	; high end of the "experimental" range,
				;  expressed in big-endian format

IPXPacketType	etype byte
    IPXPT_UNKNOWN	enum	IPXPacketType, 0
    IPXPT_ROUTE		enum	IPXPacketType, 1
    IPXPT_ECHO		enum	IPXPacketType, 2
    IPXPT_ERROR		enum	IPXPacketType, 3
    IPXPT_DATA		enum	IPXPacketType, 4
    IPXPT_SPX		enum	IPXPacketType, 5 
    IPXPT_NCP		enum	IPXPacketType, 17

IPXAddr		struct
    IPXA_net	byte	4 dup(?)
    IPXA_node	byte	6 dup(?)
    IPXA_socket	byte	2 dup(?)
IPXAddr		ends

IPXHeader	struct		; all multi-byte fields are big-endian (i.e.
				;  opposite of Intel byte-ordering)
    IPXH_checksum	word
    IPXH_length		word
    IPXH_xportCtrl	byte
    IPXH_packetType	IPXPacketType	IPXPT_DATA
    IPXH_dest		IPXAddr
    IPXH_src		IPXAddr
IPXHeader	ends

FragmentDescriptor	struct
    FD_data	fptr		; pointer to data buffer
    FD_size	word		; size of data buffer (Intel byte-ordering)
FragmentDescriptor	ends

ECBComplete	etype	byte
    ECBC_SUCCESS	enum	ECBComplete, 0
    ECBC_NOT_CANCELABLE	enum	ECBComplete, 0xf9
    ECBC_CANCELLED	enum	ECBComplete, 0xfc
    ECBC_BAD_PACKET	enum	ECBComplete, 0xfd
    ECBC_UNDELIVERABLE	enum	ECBComplete, 0xfe
    ECBC_PHYSICAL_ERROR	enum	ECBComplete, 0xff

EventControlBlock struct
    ECB_link		fptr.EventControlBlock	0
    ECB_serviceRoutine	fptr.far	0	; service routine for when
						;  ECB has been handled.
						;  Pass:
						;  	al = ffh (IPX calling)
						;	   = 00h (AES calling)
						;  	es:si = ECB
						;  	ints off
						;  Return:
						;  	ints off (again)
						;  Destroyed:
						;  	anything
						;  
    ECB_inUse		byte		0
    ECB_complete	ECBComplete	0	; completion code
    ECB_socket		word		0	; big-endian
    			byte	4 dup(?)	; IPX workspace
			byte	12 dup(?)	; driver workspace
    ECB_localNode	byte	6 dup(?)	; dest addr (send)
						; src addr (recv)
    ECB_numFragments	word			; big-endian
    ECB_fragments	label	FragmentDescriptor
EventControlBlock ends

IPXFunction	etype	word, 0
;
; IPX seems to destroy registers at will, so be careful.
; 
    IPXF_OPEN_SOCKET	enum	IPXFunction
    ;	Desc:	Open a socket for sending/receiving packets.
    ;
    ;	Pass:	bx	= IPXF_OPEN_SOCKET
    ;		dx	= socket # (big-endian) or 0 to assign a dynamic
    ;			  number
    ;	Return:	al	= 0 if successful
    ;			  feh if socket table full
    ;			  ffh if socket already in use
    ;		dx	= socket number assigned (big-endian)
    ;
    
    IPXF_CLOSE_SOCKET	enum	IPXFunction
    ;	Desc:	Close a socket, of course
    ;
    ;	Pass:	bx	= IPXF_CLOSE_SOCKET
    ;		dx	= socket # (big-endian)
    ;	Return:	nothing
    ;
    
    IPXF_GET_RELAY	enum	IPXFunction
    ;	Desc:	Given an internetwork (10-byte) address, determine the
    ;		node on this network to which to send a packet to have
    ;		it delivered to the desired address.
    ;
    ;	Pass:	bx	= IPXF_GET_RELAY
    ;		es:si	= 10-byte internetwork address
    ;		es:di	= 6-byte buffer into which relay node will be placed
    ;	Return:	al	= 0 if successful
    ;			  dest buffer filled with 6-byte node address
    ;			= fah if unsuccessful
    ;
    
    IPXF_SEND_PACKET	enum	IPXFunction
    ;	Desc:	Put a packet out on the wire. No guarantee of reception is
    ;		made. The ECB_inUse field of the EventControlBlock will
    ;		be set zero when the packet has been sent. ECB_complete will
    ;		indicate if the packet was placed on the wire or not. A
    ;		0 ECB_complete is no guarantee that the packet was actually
    ;		received by its destination, however.
    ;
    ;	Pass:	bx	= IPXF_SEND_PACKET
    ;		es:si	= EventControlBlock
    ;	Return:	nothing
    ;
    
    IPXF_RECEIVE_PACKET	enum	IPXFunction
    ;	Desc:	Wait for a packet to arrive for a socket. The ESR for the
    ;		ECB will be called when a packet arrives (should check the
    ;		completion code, however, to make sure the packet is ok)
    ;
    ;	Pass:	bx	= IPXF_RECEIVE_PACKET
    ;		es:si	= EventControlBlock
    ;	Return:	nothing
    ;
    
    IPXF_SCHEDULE_EVENT	enum	IPXFunction
    ;	Desc:	Set an IPX-related event to happen sometime in the future
    ;
    ;	Pass:	bx	= IPXF_SCHEDULE_EVENT
    ;		ax	= # units until event happens (clock ticks?)
    ;		es:si	= EventControlBlock
    ;	Return:	nothing
    ;
    
    IPXF_CANCEL_EVENT	enum	IPXFunction
    ;	Desc:	Cancel a scheduled event
    ;
    ;	Pass:	bx	= IPXF_CANCEL_EVENT
    ;		es:si	= EventControlBlock
    ;	Return:	al	= 0 if successful
    ;			= 0xf9 if event actively being generated, so could
    ;			  not be cancelled.
    ;			= 0xff if no such event scheduled.
    ;
    
    IPXF_SCHEDULE_SPECIAL_EVENT enum IPXFunction
    ;	Desc:	Set a non-IPX event to happen sometime in the future
    ;
    ;	Pass:	bx	= IPXF_SCHEDULE_SPECIAL_EVENT
    ;		ax	= # units until event happens
    ;		es:si	= EventControlBlock
    ;	Return:	nothing
    ;
    
    IPXF_GET_INTERVAL_MARKER	enum	IPXFunction
    ;	Desc:	I have no idea
    ;
    ;	Pass:	bx	= IPXF_GET_INTERVAL_MARKER
    ;	Return:	ax	= interval marker (clock ticks)
    ;
    
    IPXF_GET_ADDRESS	enum	IPXFunction
    ;	Desc:	Return the internetwork address of the local machine
    ;
    ;	Pass:	bx	= IPXF_GET_ADDRESS
    ;		es:si	= 10-byte buffer for address. First 4 bytes are the
    ;			  network number. Last 6 are the node number
    ;	Return:	buffer filled (si and other registers destroyed)
    ;
    
    IPXF_YIELD		enum	IPXFunction
    ;	Desc:	Let IPX do some work, if it needs to, as the machine is
    ;		safe for such democracy.
    ;
    ;	Pass:	bx	= IPXF_YIELD
    ;	Return:	nothing
    ;

IPX_INSTALL_CHECK	equ	0x7a00
;	Desc:	int 2fh function to check for IPX being loaded
;
;	Pass:	ax	= IPX_INSTALL_CHECK
;	Return:	al	= 0 if not installed
;			= 0xff if installed
;			  es:di	= far pointer to IPX entry (i.e. store
;				  es & di away in an fptr and call through
;				  that fptr to get to IPX)
;


scode	segment

com_IntLevel	byte			; Interrupt level used by network
					;  card

ipx	fptr.far		; IPX entry point

netAddr	byte	10 dup(?)	; Our network address (first 4 bytes are network
				;  number; last 6 are node number)


;
; Packet currently being sent. We have a separate sendData block to allow
; the machine to be continued while the packet is being sent, since we can't
; guarantee the data will remain the same (or in the same place) and there's
; no indication that IPX will perform the copy for us...
; 
sendECB	EventControlBlock	<
	,
	NetWarePacketSent,	; (FOR DEBUGGING) ECB will be polled, if we
				;  need to know when the packet has been sent
	0,
	0,
	IPX_SOCKET_NUM,
	0,
	length sendFrags
>
sendFrags FragmentDescriptor	<
	  sendHeader, size sendHeader
>, <
	sendData, size sendData
>
sendHeader	IPXHeader	<>
sendData	byte	IPX_MAX_PACKET dup(?)

;
; Last packet received.
; 
recvECB	EventControlBlock	<
	,
	NetWarePacketReceived,	; (FOR DEBUGGING) ECB will be polled
	0,
	0,
	IPX_SOCKET_NUM,
	0,
	length recvFrags
>
recvFrags FragmentDescriptor <
	recvHeader, size recvHeader
>, <
	recvData, size recvData
>
recvHeader	IPXHeader	<>
recvData	byte	IPX_MAX_PACKET dup(?)

netwareOldTimer	fptr.far
netwareOldIdle	fptr.far


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareWaitForPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell IPX we're ready to receive another packet

CALLED BY:	(INTERNAL) NetWare_Init, NetWare_ReadMsg
PASS:		ds	= cgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareWaitForPacket proc	far
		uses	bx, es, si, ax, cx, dx, bp
		.enter
	DPC DEBUG_COM_INPUT, 'r'
		mov	bx, IPXF_RECEIVE_PACKET
		segmov	es, ds
		mov	si, offset recvECB
		call	ds:[ipx]
		.leave
		ret
NetWareWaitForPacket endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a packet every 60th of a second

CALLED BY:	Timer0 (int 8h)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	machine may be stopped

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareTimer	proc	far
		push	bx
		mov	bx, offset netwareOldTimer
		jmp	NetWareCheckPacket
NetWareTimer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareIdle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a packet when the kernel has declared the system
		idle.

CALLED BY:	int 28h
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	machine may be stopped

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareIdle	proc	far
		push	bx
		mov	bx, offset netwareOldIdle
		.assert $ eq NetWareCheckPacket
		.fall_thru
NetWareIdle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareCheckPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a packet has been received and we're not in Rpc_Wait

CALLED BY:	timer & idle interrupts
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareCheckPacket proc	far
		push	ax
		push	ds
		on_stack ds ax bx iret
		segmov	ds, cgroup, ax
	;
	; Always pass this thing off ASAP, but call, don't jmp, so we have
	; control when old handler is done.
	; 
		pushf
		call	{fptr.far}ds:[bx]
	;
	; If we're in Rpc_Call or Rpc_Run, then the message will be picked up
	; shortly.
	; 
		test	ds:[sysFlags], mask waiting or mask calling
		jnz	done
	;
	; If ECB is still marked in-use, it means no packet has arrived
	; 
		tst	ds:[recvECB].ECB_inUse
		jnz	done
	;
	; Packet has arrived. Save state and go handle the packet. Note that
	; if the packet is RPC_INTERRUPT, we will *not* return from Rpc_Wait.
	; 
		pop	ds
		pop	ax
		pop	bx
		on_stack	iret
		call	SaveState
	DPC DEBUG_MSG_PROTO, 'M', inv

		call	Rpc_Wait
		dsi			; make sure we don't context-switch
					;  until we iret
		call	RestoreState
		iret
done:
	;
	; No packet waiting, so just get out of here.
	; 
		pop	ds
		pop	ax
		pop	bx
		iret
NetWareCheckPacket endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareYield
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let IPX know it can do random things (I hope...)
		This could get screwed if the user stops within DOS...

CALLED BY:	NetWare_ReadMsg
PASS:		ds	= cgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareYield	proc	near
		uses	bx, ax, cx, dx, si, di, bp, es
		.enter
;;;	DPC DEBUG_COM_INPUT, 'Y'
		mov	bx, IPXF_YIELD
		call	ds:[ipx]
		.leave
		ret
NetWareYield	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWare_ReadMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the waiting message, if any

CALLED BY:	(EXTERNAL) Rpc_Wait
PASS:		es:di	= place to store message
		ds	= cgroup
		cx	= size of buffer
RETURN:		carry set if message was corrupt
		carry clear if message was ok:
			cx	= size of message
				= 0 if no message present
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWare_ReadMsg proc	near
		uses	si
		.enter
	;
	; This is a good time to let IPX do some processing.
	; 
		call	NetWareYield
	;
	; See if there's a packet available.
	; 
		tst	ds:[recvECB].ECB_inUse
		jz	getMessage
	;
	; No packet available, so return 0 bytes read.
	; 
		clr	cx
		jmp	done

getMessage:
	DPC DEBUG_COM_INPUT, 'R'
	;
	; Make sure the entire packet will fit in the passed buffer.
	; 
		mov	ax, ds:[recvHeader].IPXH_length
		xchg	al, ah
		sub	ax, size IPXHeader
		cmp	cx, ax
		jb	done		; => packet too big to fit in buffer,
					;  so it's corrupt
	DA  DEBUG_COM_INPUT, <push ax>
	DPC DEBUG_COM_INPUT, 'c'
	DA  DEBUG_COM_INPUT, <pop ax>
	;
	; Copy the packet body into the passed buffer.
	; 
		mov	si, offset recvData
		mov	cx, ax
		shr	cx
		rep	movsw
		jnc	gotit
		movsb
gotit:
		mov_tr	cx, ax

if DEBUG and DEBUG_COM_INPUT
		push	cx
		mov	si, offset recvData
outLoop:
		lodsb
		DPB	DEBUG_COM_INPUT, al
		loop	outLoop
		pop	cx
endif
	;
	; Resubmit the ECB for receiving the next packet.
	; 
		call	NetWareWaitForPacket
		clc
done:
		.leave
		ret
NetWare_ReadMsg endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWare_WriteMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the passed data to the place from which the most
		recent packet was received.

CALLED BY:	(EXTERNAL)
PASS:		ds:si	= buffer to write
		cx	= # bytes in the buffer
RETURN:		nothing
DESTROYED:	si, cx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWare_WriteMsg proc	near
		uses	es, di, bx, ds, dx, bp
		.enter
		segmov	es, cgroup, di
		
	DPC DEBUG_COM_OUTPUT, 'w'
	DPW DEBUG_COM_OUTPUT, cx

	;
	; Wait for the previous packet we sent to actually get out the door.
	; 
waitForPrevPacket:
		tst	es:[sendECB].ECB_inUse
		jnz	waitForPrevPacket
	;
	; Make sure there's not too much data for our buffer.
	; 
		mov	di, offset sendData
		cmp	cx, size sendData
		ja	done
	;
	; Set up the IPXH_length field of the header.
	; 
		mov	ax, cx
		add	ax, size IPXHeader
		xchg	al, ah
		mov	es:[sendHeader].IPXH_length, ax
	;
	; Store the data size in the fragment descriptor for it.
	; 
		mov	es:[sendFrags][1*FragmentDescriptor].FD_size, cx
	;
	; Move the data into our own buffer, to allow the packet to be
	; sent asynchronously.
	; 
		shr	cx
		rep	movsw
		jnc	submitECB
		movsb
submitECB:
	;
	; Copy the src from recvHeader for use as the dest in sendHeader.
	; Note that the protocol we use when talking to Swat is such that
	; we will never send a packet without having received one from
	; Swat. This is what allows us just copy the src of the recv to the
	; dest of the send without concern.
	; 
		segmov	ds, es
		mov	si, offset recvHeader.IPXH_src
		mov	di, offset sendHeader.IPXH_dest
			CheckHack <(size IPXH_src and 1) eq 0>
		mov	cx, size IPXH_src/2
		rep	movsw
		
		mov	si, offset recvECB.ECB_localNode
		mov	di, offset sendECB.ECB_localNode
		mov	cx, size ECB_localNode/2
			CheckHack <(size ECB_localNode and 1) eq 0>
		rep	movsw
	;
	; Now call IPX to send the packet.
	; 
	DPC DEBUG_COM_OUTPUT, 'o'
		mov	bx, IPXF_SEND_PACKET
		mov	si, offset sendECB
		call	ds:[ipx]

;;if DEBUG and DEBUG_COM_OUTPUT
;;waitLoop:
;;		tst	ds:[sendECB].ECB_inUse
;;		jnz	waitLoop
;;	
;;	DPC DEBUG_COM_OUTPUT, 'O', inv
;;endif

done:
		.leave
		ret
NetWare_WriteMsg endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWarePacketReceived
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWarePacketReceived proc	far
		.enter
		DPC DEBUG_COM_INPUT, 'I'
		.leave
		ret
NetWarePacketReceived endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWarePacketSent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWarePacketSent proc	far
		.enter
		DPC DEBUG_COM_INPUT, 'O'
		.leave
		ret
NetWarePacketSent endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWare_Exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up

CALLED BY:	(EXTERNAL) Rpc_Exit
PASS:		ds	= cgroup
		ax = 0 if calling afer call to SaveState
		ax = 1 if not calling from after call to SaveState 
		ss:bp = state block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWare_Exit	proc	near
		uses	ax, es, ds, si, di, bx
		.enter
	;
	; Release the timer interrupt, again. Note that we don't get called
	; until GEOS has been torn down, so this is fine.
	;
	; RestoreState will restore whatever was in the timer interrupt when
	; we return, so the only way to actually restore the timer interrupt
	; to what's in netwareOldTimer is to adjust the state block at ss:[bp]
	; 
		tst	ax
		jnz	normalReset
		movdw	ss:[bp].state_timerInt, ds:[netwareOldTimer], ax
		jmp	resetIdle
normalReset:
DPC	DEBUG_NETWARE, 'E'
DPW	DEBUG_NETWARE, ds:[netwareOldTimer].segment
DPW	DEBUG_NETWARE, ds:[netwareOldTimer].offset
		mov	bx, offset netwareOldTimer
		mov	ax, 8
		call	ResetInterrupt
resetIdle:
DPC	DEBUG_NETWARE, 'E'
DPW	DEBUG_NETWARE, ds:[netwareOldIdle].segment
DPW	DEBUG_NETWARE, ds:[netwareOldIdle].offset
		mov	bx, offset netwareOldIdle
		mov	ax, 28h
		call	ResetInterrupt
		
		segmov	es, ds
	;
	; Cancel any outstanding send or receive on the socket.
	; 
		mov	si, offset sendECB
		mov	bx, IPXF_CANCEL_EVENT
		call	ds:[ipx]
		
		mov	si, offset recvECB
		mov	bx, IPXF_CANCEL_EVENT
		call	ds:[ipx]
	;
	; Close down the socket itself.
	; 
		mov	dx, ds:[recvECB].ECB_socket
		mov	bx, IPXF_CLOSE_SOCKET
		call	ds:[ipx]
		
		.leave
		ret
NetWare_Exit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWare_SetHardwareType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing routine to cope with parsing of /h flag

CALLED BY:	(EXTERNAL) MainHandleInit
PASS:		ax	= HardwareType
		ds	= cgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWare_SetHardwareType proc	far
		.enter
		.leave
		ret
NetWare_SetHardwareType endp

scode		ends


stubInit	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWare_Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the communication subsystem

CALLED BY:	(EXTERNAL) Rpc_Init
PASS:		es, ds	= cgroup
RETURN:		Nothing
DESTROYED:	ax, bx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWare_Init	proc	near
		uses	es
		.enter
		
		mov	ax, IPX_INSTALL_CHECK
		int	2fh
		tst	al
		jz	noNetware
		
		movdw	ds:[ipx], esdi
		segmov	es, ds
		
		call	NetWareOpenSocket
		jc	done
	;
	; Let user know our address, so s/he can tell Swat.
	; 
		call	NetWarePrintAddress
	;
	; Queue initial receive for the socket.
	; 
		call	NetWareWaitForPacket
	;
	; Hook the interrupts that will allow us to regain control when
	; a packet has arrived.
	; 
		call	NetWareHookInts
	;
	; Look for a flag telling us what the card's interrupt level is
	; XXX: SHOULD BE ABLE TO GET THIS FROM IPX.
	; 
		call	NetWareGetNetworkIRQ
		clc
done:
		.leave
		ret
noNetware:
		call	NetWarePrintNoIpxWarning
		stc
		jmp	done
NetWare_Init	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareOpenSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the socket over which we communicate

CALLED BY:	(INTERNAL) NetWare_Init
PASS:		ds	= cgroup
		ds:[ipx] = set
RETURN:		carry set if couldn't open the socket
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareOpenSocket proc	near
		.enter
		mov	bx, IPXF_OPEN_SOCKET
		mov	al, 0		; open until closed or job terminates
		mov	dx, IPX_SOCKET_NUM
		mov	ds:[recvECB].ECB_socket, dx
		call	ds:[ipx]
		
		tst	al
		jz	done		; => opened
		
		push	ds
		mov	dx, offset cannotOpenSocketStr
		mov	ah, MSDOS_DISPLAY_STRING
		segmov	ds, cs
		int	21h
		pop	ds
		stc
done:
		.leave
		ret
NetWareOpenSocket endp

cannotOpenSocketStr	char	'Unable to open netware socket\r\n$'


noIpxStr	char	'Ipx not loaded\r\n$'

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWarePrintNoIpxWarning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	print a warning to the user

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/23/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetWarePrintNoIpxWarning	proc	near
		.enter
	;
	; Print out the initial info.
	; 
		push	ds
		segmov	ds, cs
		mov	dx, offset noIpxStr
		mov	ah, MSDOS_DISPLAY_STRING
		int	21h
		pop	ds
		.leave
		ret
NetWarePrintNoIpxWarning	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWarePrintAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print out the address the user should use to communicate
		with us.

CALLED BY:	(INTERNAL) NetWareInit
PASS:		ds	= cgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	netAddr is set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWarePrintAddress proc near
		.enter
		mov	bx, IPXF_GET_ADDRESS
		segmov	es, ds
		mov	si, offset netAddr
		call	ds:[ipx]

	;
	; Print out the initial info.
	; 
		push	ds
		segmov	ds, cs
		mov	dx, offset networkAddressStr
		mov	ah, MSDOS_DISPLAY_STRING
		int	21h
		pop	ds
	;
	; First the network.
	; 
		mov	cx, 4
		mov	si, offset netAddr
		mov	di, offset sendHeader.IPXH_src.IPXA_net
		call	printAndCopyLoop
		
		mov	ax, (0eh shl 8) or ':'
		int	10h
	;
	; Now the node.
	; 
		mov	cx, 6
		mov	di, offset sendHeader.IPXH_src.IPXA_node
		call	printAndCopyLoop
		
		mov	ax, (0eh shl 8) or ':'
		int	10h

	;
	; Finally the socket.
	; 
		mov	si, offset ds:[recvECB].ECB_socket
		mov	di, offset sendHeader.IPXH_src.IPXA_socket
		mov	cx, 2
		call	printAndCopyLoop
		
		push	ds
		mov	dx, offset crlfStr
		segmov	ds, cs
		mov	ah, MSDOS_DISPLAY_STRING
		int	21h
		pop	ds
		.leave
		ret

	;--------------------
	; Print out a hex number (stored in big-endian format) and copy
	; it into some part of the sendHeader
	;
	; Pass:	ds:si	= number to print (big-endian)
	; 	es:di	= place to store it
	; 	cx	= # bytes
	; Return:	nothing
	; Destroyed:	al, cx, si, di
printAndCopyLoop:
		lodsb
		stosb
		call	NetWarePrintByte
		loop	printAndCopyLoop
		retn
NetWarePrintAddress endp

networkAddressStr	char	'Address for Swat: $'
crlfStr			char	'\r\n$'

netwareNibbles	db	"0123456789ABCDEF"
NetWarePrintByte proc near
		push	bx
		push	ax
		mov	bx, offset netwareNibbles
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		and	al, 0fh
		xlatb	cs:
		mov	ah, 0eh		; print char
		int	10h		; video BIOS
		pop	ax
		push	ax
		and	al, 0fh
		xlatb	cs:
		mov	ah, 0eh		; print char
		int	10h		; video BIOS
		pop	ax
		pop	bx
		ret
NetWarePrintByte endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareHookInts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hook the interrupt(s) that will allow us to gain control of
		the machine when a packet comes in.

CALLED BY:	(INTERNAL) NetWare_Init
PASS:		ds	= cgroup
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	netwareOldTimer

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareHookInts	proc	near
		uses	bx, dx
		.enter
		mov	ax, 8
		mov	bx, offset netwareOldTimer
		mov	dx, offset NetWareTimer
		call	SetInterrupt
DPC	DEBUG_NETWARE, 'I'
DPW	DEBUG_NETWARE, ds:[netwareOldTimer].segment
DPW	DEBUG_NETWARE, ds:[netwareOldTimer].offset
		mov	ax, 28h
		mov	bx, offset netwareOldIdle
		mov	dx, offset NetWareIdle
		call	SetInterrupt
DPW	DEBUG_NETWARE, ds:[netwareOldIdle].segment
DPW	DEBUG_NETWARE, ds:[netwareOldIdle].offset
		.leave
		ret
NetWareHookInts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareGetNetworkIRQ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out at what interrupt level the network card is
		operating, so we can make sure it has the highest priority
		when the machine is stopped.

CALLED BY:	(INTERNAL) NetWare_Init
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	com_IntLevel, COM_Mask1, and COM_Mask2 all set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
netwareIRQArg	char	'n', 0
netwareIRQ	char	'f'
		
NetWareGetNetworkIRQ proc	near
		uses	es, dx, cx, di, bx
		.enter
	;
	; Look for /n followed by a single character (the interrupt level)
	; 
		segmov	es, cs
		mov	di, offset netwareIRQArg
		mov	bx, offset netwareIRQ
		mov	dx, 1
		call	FetchArg
	;
	; Fetch either the value or the default, if no /n flag passed.
	; 
		mov	al, cs:[netwareIRQ]
		cmp	al, '0'
		jb	useDefault
		cmp	al, '9'
		ja	checkUpper

		sub	al, '0'		; al <- 0-9
		jmp	haveLevel

checkUpper:
		cmp	al, 'A'
		jb	useDefault
		cmp	al, 'F'
		ja	checkLower

		sub	al, 'A' - 10	; al <- 10-15
		jmp	haveLevel

checkLower:
		cmp	al, 'a'
		jb	useDefault
		cmp	al, 'f'
		ja	useDefault

		sub	al, 'a' - 10	; al <- 10-15
haveLevel:
		mov	ds:[com_IntLevel], al
		mov_tr	cx, ax
		mov	ax, 0xfffe
		rol	ax, cl		; ax <- inverse mask for level
		mov	ds:[COM_Mask1], al
		mov	ds:[COM_Mask2], ah
		.leave
		ret

useDefault:
	;
	; Bitch about the argument value.
	; 
		push	ds
		mov	dx, offset invalidNetIRQStr
		segmov	ds, cs
		mov	ah, MSDOS_DISPLAY_STRING
		int	21h
		pop	ds
	;
	; Use IRQ 15.
	; 
		mov	al, 15
		jmp	haveLevel

invalidNetIRQStr char	'Invalid interrupt level for /n:<l> argument\r\n$'

NetWareGetNetworkIRQ endp

stubInit	ends

endif	; NETWARE
