COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethercomProcess.asm

AUTHOR:		Allen Yuen, Oct 29, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/29/98   	Initial revision


DESCRIPTION:
		
	Code for EtherProcessClass.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EtherClassStructures	segment	resource

EtherProcessClass	mask CLASSF_NEVER_SAVED

EtherClassStructures	ends

MovableCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPNotifyConnectConfirmed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the client that a connection requested has now been
		established.

CALLED BY:	MSG_EP_NOTIFY_CONNECT_CONFIRMED

PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/29/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPNotifyConnectConfirmed	method dynamic EtherProcessClass, 
					MSG_EP_NOTIFY_CONNECT_CONFIRMED
	.enter

	mov	di, SCO_CONNECT_CONFIRMED
	mov	ax, ETHER_CONNECTION_HANDLE
	mov	bx, ds:[clientDomainHandle]
	Assert	ne, bx, 0
	SCOIndication

	.leave
	ret
EPNotifyConnectConfirmed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPSendPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a packet.

CALLED BY:	MSG_EP_SEND_PACKET

PASS:		ds	= dgroup
		^ldx:bp	= HugeLMem chunk of buffer to send
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	Buffer either already freed or will be freed later.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	11/07/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPSendPacket	method dynamic EtherProcessClass, 
					MSG_EP_SEND_PACKET
	.enter

	;
	; Make sure link has been set up to our linking.
	;
	tst	ds:[linkEstablished]
	jz	error

	EthDevSendDXBP			; CF set on error, ax = SocketError
	jc	error

exit:
	.leave
	ret

error:
	movdw	axcx, dxbp	; ^lax:cx = buffer to send
	call	HugeLMemFree	; free the buffer
	jmp	exit

EPSendPacket	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPSendPacketDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees the packet now that it has been sent completely.

CALLED BY:	MSG_EP_SEND_PACKET_DONE

PASS:		^ldx:cx	= HugeLMem chunk (locked) of packet to free
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	11/06/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPSendPacketDone	method dynamic EtherProcessClass, 
					MSG_EP_SEND_PACKET_DONE
	.enter

	Assert	optr, dxcx
	mov	bx, dx
	call	HugeLMemUnlock
	mov_tr	ax, bx			; ^lax:cx = packet
	call	HugeLMemFree

	.leave
	ret
EPSendPacketDone	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPProcessIpPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process an incoming IP packet.

CALLED BY:	MSG_EP_PROCESS_IP_PACKET

PASS:		ds	= dgroup
		Other parameters depend on particular Ethernet driver
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	11/07/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPProcessIpPacket	method dynamic EtherProcessClass, 
					MSG_EP_PROCESS_IP_PACKET
	.enter

	EthDevProcessIpPacket

	.leave
	ret
EPProcessIpPacket	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPMetaAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signs up for the DHCP GCN list.

CALLED BY:	MSG_META_ATTACH

PASS:		*ds:si	= EtherProcessClass object
		ds:di	= EtherProcessClass instance data
		ds:bx	= EtherProcessClass object (same as *ds:si)
		es 	= segment of EtherProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/03/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPMetaAttach	method dynamic EtherProcessClass, 
					MSG_META_ATTACH
	.enter

	; Commenting this out cuz it causes a crash. There is no default
	; handler for this message, so we won't worry about it.
	mov	di, offset EtherProcessClass
	call	ObjCallSuperNoLock

	mov	cx, ss:[0].TPD_threadHandle
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TCPIP_STATUS_NOTIFICATIONS
	call	GCNListAdd

	.leave
	ret
EPMetaAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove self from GCN list

CALLED BY:	MSG_META_DETACH

PASS:		*ds:si	= EtherProcessClass object
		ds:di	= EtherProcessClass instance data
		ds:bx	= EtherProcessClass object (same as *ds:si)
		es 	= segment of EtherProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/03/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPMetaDetach	method dynamic EtherProcessClass, 
					MSG_META_DETACH
	uses	ax, bx, cx, dx
	.enter

	mov	cx, ss:[0].TPD_threadHandle
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	cx, GCNSLT_TCPIP_STATUS_NOTIFICATIONS
	call	GCNListRemove

	.leave
	mov	di, offset EtherProcessClass
	call	ObjCallSuperNoLock

	ret
EPMetaDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EPMetaNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receives DHCP status notifications, updates settings

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK

PASS:		*ds:si	= EtherProcessClass object
		ds:di	= EtherProcessClass instance data
		ds:bx	= EtherProcessClass object (same as *ds:si)
		es 	= segment of EtherProcessClass
		ax	= message #
		cx	= manufacturer id (we want MANUFACTURER_ID_GEOWORKS)
		dx	= notification type (we want GWNT_TCPIP_DHCP_STATUS)
		bp	= MemHandle
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/03/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EPMetaNotifyWithDataBlock	method dynamic EtherProcessClass, 
					MSG_META_NOTIFY_WITH_DATA_BLOCK
	uses	bx, cx, dx, si, bp, ds, es
	.enter

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	done
	cmp	dx, GWNT_TCPIP_DHCP_STATUS
	jne	done
	mov	bx, handle dgroup
	call	MemDerefDS
	mov	bx, bp
	call	MemLock
	mov	es, ax
	cmp	es:[0].TDND_status, TDSNT_CONFIGURATION
	jne	checkExpire
	movdw	({dword}ds:[localIpAddr]), ({dword}es:[0].TDND_ipAddr), ax
	movdw	cxax, ({dword}es:[0].TDND_netmask)
	tstdw	cxax
	jnz	gotSubnet	
	movdw	cxax, 000FFFFFFh
gotSubnet:
	movdw	({dword}ds:[subnetMask]), cxax
	movdw	cxax, ({dword}es:[0].TDND_gateway)
	tstdw	cxax
	jnz	gotGateway
	; Test stored gateway address to see if it matches what we would
	; compute it to be if there was no ip address in accpnt.
	; If so, compute new one. Note this gateway is not certain, but
	; simply an educated guess.
	cmpdw	({dword}ds:[gatewayAddr]), 01000000h
	jne	unlockBlock	; No gateway from DHCP but had from accpnt
	movdw	cxax, ({dword}ds:[localIpAddr])
	and	cx, ({dword}ds:[subnetMask]).high
	and	ax, ({dword}ds:[subnetMask]).low
	inc	ch
gotGateway:
	movdw	({dword}ds:[gatewayAddr]), cxax
unlockBlock:
	call	MemUnlock

	mov	bx, ss:[0].TPD_threadHandle
	mov	ax, MSG_EP_NOTIFY_CONNECT_CONFIRMED
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	.leave
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	di, offset EtherProcessClass
	call	ObjCallSuperNoLock

	ret

wrongPacket:
	call	MemUnlock
	jmp	done

checkExpire:
	cmp	es:[0].TDND_status, TDSNT_LEASE_EXPIRED
	jne	wrongPacket
	clr	ax
	clrdw	ds:[localIpAddr], ax
	clrdw	ds:[subnetMask], ax
	clrdw	ds:[gatewayAddr], ax
	jmp	done

EPMetaNotifyWithDataBlock	endm

MovableCode	ends
