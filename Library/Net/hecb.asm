COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Net Library
FILE:		hecb.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version
	Eric	8/92		Ported to 2.0.

DESCRIPTION:
	This library allows PC/GEOS applications to access the Novell NetWare
	Applications Programmers Interface (API). This permits an application
	to send and receive packets, set up connections between nodes on the
	network, access Novell's "Bindery", which contains information about
	network users, etc.

RCS STAMP:
	$Id: hecb.asm,v 1.1 97/04/05 01:25:05 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			NetMessageCode
;------------------------------------------------------------------------------

NetMessageCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetCreateHECB

DESCRIPTION:	Create a block containing a default HugeECB structure
		on the global heap. (Calls the specific network driver
		to fill in some of the details.)

PASS:		cx	= amount of data you expect to place in the
			"NLMPS_msgData" (stack and data block) portion
			of the HECB. Min = 0. Max = MAX_MSG_DATA_SIZE. 

		di	= Set the NLMF_CONNECTION_ID_ES bit to create a default
			  SPX listen HugeECB (as opposed to an IPX listen
			  HugeECB.)
			  Set the NLMF_CALL or NLMF_SEND bit to set the
			  callback routine for outgoing packets.

		You also have the option of passing:

		dx	= SocketAddress

		For SPX packets, you have the option of passing:

			bl	= source connection ID
			bh	= dest connection ID

			NOT SUPPORTED YET.

		Or you could just fix those values later.

RETURN:		ds, dx, si, di, bp	= same
		^hbx	= HugeECB

DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetCreateHECB	proc	far
	uses	ds, dx, si
	.enter

	mov	ax, cx

	;First adjust the size of the data portion, if it is too big.
	;(this might not be programmer error: the global block passed
	;to us is sized on paragraph boundaries, so it may be bigger
	;than the caller expected.)

	cmp	ax, MAX_MSG_DATA_SIZE
	jbe	10$

	mov	ax, MAX_MSG_DATA_SIZE	;just drop the extra data on the floor

10$:	;figure out how big this HECB should be to start

	add	ax, size NLMessagePacketStruct
					 ;add space for IPX and SPX header
					 ;fields, and our message info.

	;a quick reality check

EC <	cmp	ax, MAX_IPXSPX_PACKET_SIZE				>
EC <	ERROR_A NL_ERROR						>

	push	ax, bx
	add	ax, HECB_SIZE_WITHOUT_MESSAGE_PACKET
					;ax = total size of HECB, including
					;the size packet we requested.

	;create the block

	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE or \
		    (mask HAF_ZERO_INIT shl 8)
					;allocate as HF_SWAPABLE, HF_SHARABLE,
					;HAF_ZERO_INIT, and HAF_LOCK.

	mov	bx, handle 0		;set ^hbx = handle of this library
					;(It should be the owner of this block.)
	call	MemAllocSetOwner	;returns bx = handle of block
					;and ax = segment of block

	mov	ds, ax			;set DS = segment of block (is locked)

	;set up misc

	mov	ds:[HECB_handle], bx
	mov	ds:[HECB_protect1], HUGE_ECB_PROTECT1

	;set up EventControlBlockStruc

	mov	ds:[HECB_ecb].ECB_socketAddress, dx
					;save socket to listen on

	pop	ax, dx			;get size of packet, connection IDs

	mov	ds:[HECB_ecb].ECB_fragmentCount, 1
					;we only have one buffer for packet
					;(is within this HECB block)

EC <	mov	ds:[HECB_ecb].ECB_fragmentAddress1.segment, 0xA000	>
EC <	mov	ds:[HECB_ecb].ECB_fragmentAddress1.offset, 0x0000	>
					;in case we mess up, have packet written
					;to video memory.

	mov	ds:[HECB_ecb].ECB_fragmentSize1, ax
					;size of first and only buffer holding
					;our IPX/SPX packet.

	;set up IPX_SPXPacketHeaderStruc

	mov	ds:[HECB_msg].NLMPS_spx.IPXSPX_ipx.IPX_length.low, ah
	mov	ds:[HECB_msg].NLMPS_spx.IPXSPX_ipx.IPX_length.high, al
					;save length of packet, in Hi-Lo order

	;set up rest of NLMessagePacketStruct

	push	bx, dx, di
	segmov	es, ds			;es = HugeECB

	mov	bx, handle 0		;get handle for NetLibrary
	mov	di, offset HECB_msg.NLMPS_nlProtocol
					;pass es:di = location to stuff
					;ProtocolNumber structure.
	mov	ax, GGIT_GEODE_PROTOCOL
	call	GeodeGetInfo
;	mov	ds:[HECB_msg].NLMPS_nlProtocol.PN_major, si
;	mov	ds:[HECB_msg].NLMPS_nlProtocol.PN_minor, di

	call	GeodeGetProcessHandle	;returns ^hbx = process handle
	mov	di, offset HECB_msg.NLMPS_appProtocol
					;pass es:di = location to stuff
					;ProtocolNumber structure.
	mov	ax, GGIT_GEODE_PROTOCOL
	call	GeodeGetInfo
;	mov	ds:[HECB_msg].NLMPS_appProtocol.PN_major, si
;	mov	ds:[HECB_msg].NLMPS_appProtocol.PN_minor, di
	pop	bx, dx, di

	;now call the specific network driver, so it can fill in
	;any other specifics that are necessary.

	segmov	es, <segment dgroup>, ax
	mov	ax, di				;ax = NLMessageFlags
	mov	di, DR_NET_INITIALIZE_HECB
	call	NetCallDriver
	mov	di, ax				;di = NLMessageFlags

	;unlock block

	call	MemUnlock

	.leave
	ret
NetCreateHECB	endp


NetMessageCode	ends
