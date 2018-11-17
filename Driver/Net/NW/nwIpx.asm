COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Novell NetWare Driver
FILE:		ipx.asm


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
	$Id: nwIpx.asm,v 1.1 97/04/18 11:48:41 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			NetWareResidentCode
;------------------------------------------------------------------------------

NetWareResidentCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareSendHECB -- DR_NET_SEND_HECB

DESCRIPTION:	The Net Library calls this entry point to queue up a single
		HugeECB structure for transmission. We send a message
		to our Process thread, so that it will do the dirty work
		(in sequence with other outgoing blocks) while we are
		blocked within ObjMessage.

PASS:		^hcx	= HugeECB on global heap (unlocked)

RETURN:		nothing (HugeECB freed)

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version
	Eric	2/92		Ported to 2.0

------------------------------------------------------------------------------@

NetWareSendHECB	proc	near

;No need to lock the block yet - the recipient of MSG_NW_QUEUE_HECB_FOR_XMIT
;can do it at the appropriate time. We would only need it locked here if
;we re-enable the PSem code below.
;
;	;For now, we are locking the block before we send it, because since we
;	;don't have a departure queue, the block is going to stay locked until
;	;after transmission, and it has a FPTR inside.
;
;	call	NetWareLockHECB	;returns es = ax = segment of block
;	mov	ds, ax

	;Pass this HugeECB to our process object, via the queue. Essentially,
	;we are using our Process thread queue as our departure queue for
	;HugeECBs.

	mov	cx, bx			;^hcx = HugeECB (unlocked)
	mov	bx, handle 0		;bx = handle of NetWareProcessClass obj
	mov	ax, MSG_NW_QUEUE_HECB_FOR_XMIT
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

;NUKED 8/28/92 BY EDS
;Because there is a nasty timing bug here: what if the MSG we just sent
;arrives before we PSem below? Also, we don't really have a reason to
;wait around yet, since we aren't even checking for error codes placed
;in the HugeECB by IPX. And finally, we might eventually want to support
;"CALL" type messages, and in doing so will probably change this code anyway.
;
;	;Block on the semaphore in the HugeECB (initial value = 0),
;	;so that we go to sleep until the NetLibrary has processed
;	;this request. (It will immediately unlock the block.)
;	;We do this because we want to be able to return the error codes
;	;that IPX returns.
;
;	PSem	ds, HECB_semaphore	;does not trash bx
;
;	;OK: the NetLibrary has finished sending the HugeECB. Check
;	;return codes in the HugeECB, and return to the caller.
;
;	call	MemDerefDS		;restore ds = segment of HugeECB
;					;(is still locked, but may have moved)
;
;because we did not block on the semaphore, we have to let someone else
;free this block.
;
;EC <	cmp	ds:[HECB_protect1], HUGE_ECB_PROTECT1			>
;EC <	ERROR_NE NW_ERROR						>
;
;	call	MemFree

	ret
NetWareSendHECB	endp

NetWareResidentCode	ends

;------------------------------------------------------------------------------
;			NetWareIPXCode
;------------------------------------------------------------------------------

NetWareIPXCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareQueueHECBForXmit -- MSG_NW_QUEUE_HECB_FOR_XMIT

DESCRIPTION:	Pass the specified HugeECB onto IPX for transmission.
		Once IPX has tried to send it, it will call our
		callback routine with the results. At that point, we
		can free the block.
		
		OLD:
		This driver sends this message to itself when running
		in the caller's thread. Doing so allows us to queue
		up our outgoing messages for transmission under our
		process thread. The caller's thread stays blocked within
		ObjMessage until this HECB has actually been sent.

PASS:		ds	= dgroup
		^hcx	= HugeECB on global heap (unlocked)

RETURN:		nothing (HugeECB freed)

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareQueueHECBForXmit	method	NetWareProcessClass, MSG_NW_QUEUE_HECB_FOR_XMIT

	mov	bx, cx			;^hbx = HugeECB

;NUKED 8/28/92, because our caller DID NOT lock the block.
;	;NetObjMessage was unable to unlock this block, because it fell
;	;asleep on the semaphore within the block. So let's unlock it
;	;here, for the duration of the time that the block is on
;	;our departure queue.
;
;	call	MemDerefES
;
;instead, we use:

	;lock the block before giving it to IPX, using a special routine
	;which knows to update a FTPR inside the block.

	call	NetWareLockHECB		;returns es = ax = segment of block
					;Performs ERROR CHECKING

	mov	dx, es:[HECB_ecb].ECB_socketAddress
					;DX = dest. SocketAddress for block.

;Support for the departure queue was not completed. Do we need it at all?
;	;place on queue. pass ^hcx = HugeECB, dx = socket #
;
;	call	NetWareAddHugeECBToQueueForSocket
;
;instead, use:

	;pass the HECB directly to IPX/SPX. Once IPX has dealt with it,
	;our callback will be called. It will ensure that the block is
	;nuked.

	call	NetWareSendHECBToNet

;what if socket was invalid?

;This comment does not apply anymore, since our caller is not blocked
;waiting on this block.
;	;we're done. Caller will be woken up by NetWareCheckXmitResults.

	ret
NetWareQueueHECBForXmit	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareAddHugeECBToQueueForSocket

DESCRIPTION:	Add the passed HugeECB to the departure queue for the
		specified socket. We don't want to try to send this thing
		immediately, because in SPX, we have to carefully sequence
		all of the packets that we send.

PASS:		ds	= dgroup
		^hcx	= HugeECB
		dx	= socket address

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

if 0	;not used yet
not debugged yet

NetWareAddHugeECBToQueueForSocket	proc	near
	;lock vars block, so we can store info about this new socket

	mov	bx, ds:[nlVars]
EC <	tst	bx							>
EC <	ERROR_Z NW_ERROR						>
	call	MemLock
	mov	ds, ax			;ds = NLVarsBlockStruc

	;find this socket in our list of legal sockets

	call	NW_FindSocketInfoInArray ;does not trash bx, cx, dx
EC <	ERROR_NC NW_ERROR		 ;socket does not exist!	>

	mov	si, ds:[bp].NLSIS_departureQueueArray
					;*ds:si = departure queue chunk array

	;add an NLDepartureQueueECBInfo entry to the end of the departure queue.

	call	ChunkArrayAppend	;DS WILL MOVE
	mov	ds:[di].NLDQEI_hugeECB, cx

	;unlock the nlVars block

	call	MemUnlock

	;now send message to self, so will examine this queue to pass
	;top item onto IPX. (We don't do this immediately, because we
	;want to allow other events to come in.)

					;pass dx = socket address
	mov	ax, MSG_NW_EXAMINE_DEPARTURE_QUEUE_FOR_SOCKET
	mov	bx, handle 0		;bx = handle of this process
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
NetWareAddHugeECBToQueueForSocket	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareSendHECBToNet

DESCRIPTION:	Pass this HugeECB directly onto IPX.

PASS:		es	= HugeECB (locked on global heap)

RETURN:		nothing (assume that the HugeECB has been freed)

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareSendHECBToNet	proc	near

	;update the ECB with some info

EC <	cmp	es:[HECB_protect1], HUGE_ECB_PROTECT1			>
EC <	ERROR_NE NW_ERROR						>

	clr	es:[HECB_ecb].ECB_completionCode
					;init completion code

	;now tell IPX to send this packet

	mov	si, offset HECB_ecb	;set es:si = ECB to send
	mov	bx, ISF_IPX_SEND_PACKET	;bx = IPXSPXFunction
	call	NetWareIPXCallFunction

	;no errors are returned. We have to look into the HugeECB when
	;IPX calls our fixed callback routine, to see if things went ok.

	ret
NetWareSendHECBToNet	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCheckXmitResults

DESCRIPTION:	This message is sent by our fixed callback routine which is
		called by IPX/SPX when it is done transmitting a packet.

PASS:		ds	= dgroup
		cx	= segment of HugeECB (in fixed block in memory)

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareCheckXmitResults	method	NetWareProcessClass,
						MSG_NW_CHECK_XMIT_RESULTS

	;FUTURE: need to build HugeECB from small ECB pieces here...

	;get the segment for the HugeECB

	mov	ds, cx			;ds = HugeECB

EC <	cmp	ds:[HECB_protect1], HUGE_ECB_PROTECT1			>
EC <	ERROR_NE NW_ERROR						>

;NUKED 8/28/92 by EDS.
;Because no one is blocked waiting for this block. We simply have to
;free it ourselves.
;	;wake up the application thread that is sleeping waiting for
;	;this HugeECB to be sent.
;
;	VSem	ds, HECB_semaphore
;instead, we use:

	;Free this block now, since IPX has transmitted its contents
	;and our caller has already continued on to greener pastures.

	mov	bx, ds:[HECB_handle]
	call	MemFree

	ret
NetWareCheckXmitResults	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareGrabIncomingECB -- MSG_NW_GRAB_INCOMING_ECB

DESCRIPTION:	This message is sent by our fixed callback routine which is
		called by IPX/SPX when it received a packet from the
		network.

PASS:		ds	= dgroup
		cx	= segment of HugeECB (in fixed block in memory)

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:
	grab data out of this HECB

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareGrabIncomingECB	method	NetWareProcessClass,
					MSG_NW_GRAB_INCOMING_ECB

	;make sure is ok

	mov	ds, cx			;ds = HugeECB

EC <	cmp	ds:[HECB_protect1], HUGE_ECB_PROTECT1			>
EC <	ERROR_NE NW_ERROR						>

	;first remove this HECB from the list of HECBs pending for listening.

	mov	dx, ds:[HECB_msg].NLMPS_spx.IPXSPX_ipx.IPX_dest.NNSAS_socket
					;pass dx = socket

	mov	cx, ds:[HECB_handle]	;pass ^hcx = HugeECB (which is locked)

	call	NetWareRemoveECBFromPendingListenListForSocket

	;create another ECB, and submit it for listening on that
	;same socket.

if NW_DYNAMIC_SOCKETS
PrintMessage <MAKE SURE THIS WORKS when source and dest socket>
PrintMessage <have different values...>
endif

	push	ds
	mov	cx, MAX_MSG_DATA_SIZE	;make it big enough to handle the
					;biggest IPX packet which arrives.
	clr	di			;pass flag: create for IPX listening.
	call	NetCreateHECB		;returns ^hbx = HugeECB with defaults.
					;dx = socket address still

	mov	ax, segment dgroup
	mov	ds, ax			;pass ds = dgroup
	mov	cx, bx			;pass ^hcx = ECB
	call	NetWareSubmitECBToListenOnSocket
					;no need for method call, because we
					;are running in the NW Driver thread.
	pop	ds

	;from small ECBS coming in, build a HugeECB here...

;		(NOT SUPPORTED YET)

	;we now have a HugeECB. If is a message "CALL", then
	;pass on to a new thread, which can block waiting for the
	;local recipient object to handle it.

	test	ds:[HECB_msg].NLMPS_nlMessageFlags, mask NLMF_CALL
	jz	isSendType

EC <	ERROR NW_ERROR			;NOT SUPPORTED YET		>
;	call	NetWareCreateThreadForLocalMsgCall
;	ret

isSendType:
	;call the Net Library to process this HugeECB, delivering it
	;to as many applications or objects as necessary.

	call NetUnpackHugeECBAndDispatchLocalMessage
	ret
NetWareGrabIncomingECB	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareIPXCallFunction

DESCRIPTION:	Call the specified NetWare IPX/SPX function.

PASS:		bx	= IPXSPXFunction enum

RETURN:		ds	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareIPXCallFunction	proc	far

EC <	call	ECNetWareAssertIPXExists				>

	;Because we are essentially calling into DOS, we must grab DOS for our
	;exclusive use for a second

	call	SysLockBIOS

	;set ds = our dgroup

	push	ds
	push	ax
	mov	ax, segment dgroup
	mov	ds, ax
	pop	ax

	;call IPX entry point in the DOS NetWare IPX code

	call	ds:[ipxEntryPoint]
	pop	ds

	;release DOS for use by others

	call	SysUnlockBIOS	;does not affect flags

	;return with whatever registers the IPX function returned

	ret
NetWareIPXCallFunction	endp


if ERROR_CHECK

ECNetWareAssertIPXExists	proc	near
	pushf
	push	ax, ds
	mov	ax, segment dgroup
	mov	ds, ax
	tst	ds:[ipxEntryPoint].high
	jnz	done

	tst	ds:[ipxEntryPoint].low
	ERROR_Z NW_ERROR_NEED_TO_CALL_IPX_INITIALIZE_FIRST

done:
	pop	ax, ds
	popf
	ret
ECNetWareAssertIPXExists	endp

endif

NetWareIPXCode	ends

;------------------------------------------------------------------------------
;			NetWareResidentCode
;------------------------------------------------------------------------------

NetWareResidentCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareFixedCallbackForDepartingECBs

DESCRIPTION:	The NetWare IPX/SPX facility will call this fixed callback
		routine when it has completed the transmission of an
		outgoing packet (ECB).

		SEE NOTE BELOW.

PASS:		ds	= dgroup
		es:si	= ECB structure which has been relinquished
			  to our control by IPX/SPX.

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

	**********************************************************************

	DO NOT DO ANYTHING WEIRD IN THIS ROUTINE. THIS IS RUN BY A THE
	IPX/SPX INTERRUPT THREAD.

	**********************************************************************

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareFixedCallbackForDepartingECBs	proc	far

	;EC: We always give IPX a fptr which is segment:0. Let's assume they
	;are always returned that way. If this ever fails, then just
	;pass cx:dx as the address of the HugeECB.

.assert (offset HECB_ecb) eq 0
EC <	tst	si							>
EC <	ERROR_NZ NW_ERROR						>

	;send a message to the NetLibrary process object, so it can take
	;ownership of this ECB.

	mov	cx, es			;cx:dx = ECB
;	mov	dx, si			;NO NECESSARY - see EC code above

	mov	ax, MSG_NW_CHECK_XMIT_RESULTS
	mov	bx, handle 0		;^hbx = NetLibrary process object
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	ret
NetWareFixedCallbackForDepartingECBs	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareFixedCallbackForIncomingECBs

DESCRIPTION:	The NetWare IPX/SPX facility will call this fixed callback
		routine when it has completed the transmission of an
		outgoing packet (ECB).

		SEE NOTE BELOW.

PASS:		ds	= dgroup
		es:si	= ECB structure which has been relinquished
			  to our control by IPX/SPX.

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

	**********************************************************************

	DO NOT DO ANYTHING WEIRD IN THIS ROUTINE. THIS IS RUN BY A THE
	IPX/SPX INTERRUPT THREAD.

	**********************************************************************

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareFixedCallbackForIncomingECBs	proc	far

	;EC: We always give IPX a fptr which is segment:0. Let's assume they
	;are always returned that way. If this ever fails, then just
	;pass cx:dx as the address of the HugeECB.

.assert (offset HECB_ecb) eq 0
EC <	tst	si							>
EC <	ERROR_NZ NW_ERROR						>

	;send a message to the NW Process object, so it can take
	;ownership of this ECB.

	mov	cx, es			;cx:dx = ECB (locked)
;	mov	dx, si			;NO NECESSARY - see EC code above

	mov	ax, MSG_NW_GRAB_INCOMING_ECB
	mov	bx, handle 0		;^hbx = NW Process object
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	;might want to feed IPX another listen packet at this point...

	ret
NetWareFixedCallbackForIncomingECBs	endp

NetWareResidentCode	ends
