COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Novell NetWare Driver
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
	$Id: nwHecb.asm,v 1.1 97/04/18 11:48:43 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			NetWareResidentCode
;------------------------------------------------------------------------------

if 0
NetWareResidentCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareInitializeHECB -- DR_NET_INITIALIZE_HECB

DESCRIPTION:	Initialize the passed HugeECB for the specifics of
		this driver. (Eventually, this will do alot more,
		as the Net Library becomes more and more generic.)

PASS:		ds	= segment of HugeECB
		ax	= NLMessageFlags

			  Set the NLMF_CONNECTION_ID_ES bit to create a default
			  SPX listen HugeECB (as opposed to an IPX listen
			  HugeECB.)
			  Set the NLMF_CALL or NLMF_SEND bit to set the
			  callback routine for outgoing packets.

RETURN:		ds	= same
		ax	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/92		Initial version

------------------------------------------------------------------------------@

NetWareInitializeHECB	proc	near

EC <	cmp	ds:[HECB_protect1], HUGE_ECB_PROTECT1			>
EC <	ERROR_NE NW_ERROR						>

	;see whether we are creating an IPX packet or an SPX packet

	mov	ds:[HECB_ecb].ECB_eventServiceRoutine.segment, \
						segment NetWareResidentCode

	test	ax, mask NLMF_CONNECTION_ID_ES
	jnz	spx			;skip if is SPX...

ipx::	;IPX specific information:

	test	ax, mask NLMF_CALL or mask NLMF_SEND
	jnz	40$

	mov	ds:[HECB_ecb].ECB_eventServiceRoutine.offset, \
		offset NetWareResidentCode:NetWareFixedCallbackForIncomingECBs 

	jmp	short done

40$:
	mov	ds:[HECB_ecb].ECB_eventServiceRoutine.offset, \
		offset NetWareResidentCode:NetWareFixedCallbackForDepartingECBs 

	mov	ds:[HECB_msg].NLMPS_spx.IPXSPX_ipx.IPX_packetType, \
					IPXPT_UNKNOWN_PACKET_TYPE
					;is an IPX packet.
	jmp	short done


;NEED TO FINISH THIS

spx:	;SPX specific information:

EC <	ERROR NW_ERROR			;not supported yet!		>

;	mov	ds:[HECB_ecb].ECB_eventServiceRoutine.segment
;	mov	ds:[HECB_msg].NLMPS_spx.IPXSPX_ipx.IPX_packetType, \
;					IPXPT_SEQUENCED_PACKET_PROTOCOL_PACKET
;					;is an SPX packet
;
;is SPXCC_ACK_REQUIRED necessary for SPX receive?
;	mov	ds:[HECB_msg].NLMPS_spx.IPXSPX_connectionControl, \
;				mask SPXCC_ACK_REQUIRED
;
;necessary?
;	mov	ds:[HECB_msg].NLMPS_spx.IPXSPX_sourceConnectionID, dl
;	mov	ds:[HECB_msg].NLMPS_spx.IPXSPX_destConnectionID, dh

done:
	ret
NetWareInitializeHECB	endp


NetWareResidentCode	ends

endif

;------------------------------------------------------------------------------
;			NetWareIPXCode
;------------------------------------------------------------------------------

NetWareIPXCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareLockHECB

DESCRIPTION:	Lock the passed HugeECB on the global heap, and update
		the ECB_fragmentAddress1 field within it.

PASS:		ds	= dgroup
		^hbx	= HugeECB

RETURN:		ds, bx	= same
		es	= segment of HugeECB
		ax	= segment of HugeECB

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareLockHECB	proc	near

	call	MemLock
	mov	es, ax

EC <	cmp	es:[HECB_protect1], HUGE_ECB_PROTECT1			>
EC <	ERROR_NE NW_ERROR						>

	;There is a NLMessagePacketStruc within this HugeECB. Save the 
	;far pointer to it in our ECB structure.

	mov	es:[HECB_ecb].ECB_fragmentAddress1.segment, ax
	mov	es:[HECB_ecb].ECB_fragmentAddress1.offset, offset HECB_msg

	ret
NetWareLockHECB	endp

NetWareIPXCode	ends
