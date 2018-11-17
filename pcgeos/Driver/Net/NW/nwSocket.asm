COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Novell NetWare Driver
FILE:		socket.asm


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
	$Id: nwSocket.asm,v 1.1 97/04/18 11:48:44 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			NetWareResidentCode
;------------------------------------------------------------------------------


if NW_SOCKETS
; This code doesn't work and I have no idea what it's supposed to do
;

NetWareResidentCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareOpenMainSocket

DESCRIPTION:	Open the GeoWorks-reserved static socket, so that all
		PC/GEOS applications which send broadcast packets are
		all talking to each other.

PASS:		cx:dx - fptr to callback routine

RETURN:		dx	= SocketAddress for GeoWorks main socket

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareOpenMainSocket	proc	near

	;open the main socket. Handle errors gracefully, because if the
	;user stumbles across this program using GeoManager, it may be
	;launched AGAIN, just to get an icon. We will try to open the main
	;socket a second time, and fail.

	segmov	ds, <segment dgroup>, ax

	mov	cl, mask NWSI_GEOWORKS_MAIN_SOCKET or mask NWSI_STATIC_SOCKET
	mov	dx, NSA_GEOWORKS_FIXED_SOCKET_ADDRESS
					;dx = socket address
	call	NetWareOpenSocket
EC <	ERROR_C NW_ERROR						>
NEC <	jc	done							>

	;no error: in EC mode, check socket address

EC <	cmp	dx, NSA_GEOWORKS_FIXED_SOCKET_ADDRESS			>
EC <	ERROR_NE NW_ERROR_CANNOT_OPEN_GEOWORKS_FIXED_SOCKET		>

	;set up a "listen" ECB on this socket, so that we can catch any
	;conversations that are flying around.

	mov	cx, MAX_MSG_DATA_SIZE	;make it big enough to handle the
					;biggest IPX packet which arrives.
	clr	di			;pass flag: create for IPX listening.
					;pass dx = socket
	call	NetCreateHECB		;returns ^hbx = NLHugeECB with defaults.
					;dx = socket address still

	mov	cx, bx			;pass ^hcx = ECB
	call	NetWareSubmitECBToListenOnSocket
					;no need for method call, because we
					;are running in the NetLibrary thread.

	;should we set up two HECB's on the socket, in case two packets
	;arrive in quick succession?

	;return no error, dx = SocketAddress

EC <	cmp	dx, NSA_GEOWORKS_FIXED_SOCKET_ADDRESS			>
EC <	ERROR_NE NW_ERROR						>

	clc
	ret
NetWareOpenMainSocket	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCloseMainSocket

DESCRIPTION:	Close the GeoWorks-reserved static socket.

PASS:		ds	= dgroup
		cl	= whether to keep all information about the socket,
			  so that we could re-open it after a shutdown.

			  TRUE means keep the socket info structure, and all
			  pending NLHugeECBs, so that they can be resubmitted
			  after a shutdown.

RETURN:		ds, cx	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareCloseMainSocket	proc	near

	mov	dx, NSA_GEOWORKS_FIXED_SOCKET_ADDRESS
						;dx = socket address
	call	NetWareCloseSocket		;does not trash cx, ds
EC <	ERROR_C NW_ERROR						>

	ret
NetWareCloseMainSocket	endp

NetWareResidentCode	ends

;------------------------------------------------------------------------------
;			NetWareIPXCode
;------------------------------------------------------------------------------


NetWareIPXCode	segment	resource	;start of code resource




COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareSubmitECBToListenOnSocket

DESCRIPTION:	Pass an HECB to NetWare's IPX/SPX facility, so that when
		a packet arrives, this ECB can be used as a buffer for
		the incoming data.

PASS:		ds	= dgroup
		^hcx	= NLHugeECB block, on heap
		dx	= socket address (already recorded inside NLHugeECB)

RETURN:		ds, dx	= same

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

;this will have to change for SPX

NetWareSubmitECBToListenOnSocket	proc	far

	;lock block, update ECB_fragmentAddress1

	mov	bx, cx
	push	es
	call	NetWareLockHECB		;lock HECB in memory, updating
					;the ECB_fragmentAddress1 field.
					;returns es = segment of NLHugeECB

	;now tell IPX to listen for a packet, using this ECB as a buffer.

	clr	si			;set es:si = NLHugeECB

;BYTES: may not need to push DX

	push	bx, ds, dx
	mov	bx, ISF_IPX_LISTEN_FOR_PACKET	;bx = IPXSPXFunction
	call	NetWareIPXCallFunction
	pop	cx, ds, dx		;^hcx = NLHugeECB
	pop	es			;we don't care about NLHugeECB address
					;anymore.

	;NetWare will return immediately, with an error code (if error).
	;Note that when a packet arrives, we have to check the NLHugeECB
	;itself for any error codes which are returned at that time.

;CHECK NEC CASE
EC <	tst	al							>
EC <	ERROR_NZ NW_ERROR						>

	;now update our SocketInfo structure, indicating that one more
	;NLHugeECB is listening on that socket.

	mov	bx, ds:[nwVars]
	call	MemLock

	push	ds
	mov	ds, ax

	;should check to make sure it does not already exist
	;dx = SocketAddress

	call	NetWareFindSocketInfoInArray ;returns ds:bp = NWSocketInfo
	mov	si, bp

EC <	test	ds:[si].NWSIS_socketInfo, mask NWSI_CONNECTION_ORIENTED	>
EC <	ERROR_NZ NW_ERROR		;make sure is IPX socket 	>

;what if HECB is already in the list? (I.E. would not be pending... would
;be in "standby" mode, coming back from a shutdown...)

	mov	si, ds:[si].NWSIS_listenECBArray ;*ds:si = listen array

	mov	al, mask HECBF_PENDING	;indicate that NetWare has this ECB
					;pass ^hcx = NLHugeECB
	call	NetWareAddHugeECBToArray	;DS WILL MOVE

	pop	ds
	call	MemUnlock

	ret
NetWareSubmitECBToListenOnSocket	endp


;DS WILL MOVE

NetWareAddHugeECBToArray	proc	near

EC <	push	cx							>
EC <	call	ChunkArrayGetCount					>
EC <	cmp	cx, MAX_NUM_LISTEN_ECBS_PER_SOCKET			>
EC <	ERROR_AE NW_ERROR		;make sure not too many listening   >
EC <	pop	cx							>
   
	call	ChunkArrayAppend
EC <	mov	ds:[di].NWPEI_protect, NW_PENDING_ECB_INFO_PROTECT	>
	mov	ds:[di].NWPEI_flags, al	;save flags
	mov	ds:[di].NWPEI_hugeECB, cx	;save handle of this NLHugeECB
	ret
NetWareAddHugeECBToArray	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareProc_RemoveECBFromPendingListenListForSocket

DESCRIPTION:	Update our info for this socket, as we are no longer
		waiting for this HECB to be filled with an incoming packet.

PASS:		^hcx	= NLHugeECB (can be locked or unlocked at this point)
		dx	= SocketAddress

RETURN:		cx, dx = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareRemoveECBFromPendingListenListForSocket	proc	near
	uses	ds, cx, dx

	.enter

	;update our SocketInfo structure, indicating that this NLHugeECB
	;is no longer on the listen list.

	mov	ax, segment dgroup	;ds = dgroup
	mov	ds, ax

	mov	bx, ds:[nwVars]
	call	MemLock
	mov	ds, ax

	;should check to make sure it does not already exist

					 ;pass dx = SocketAddress
	call	NetWareFindSocketInfoInArray ;returns ds:bp = NWSocketInfo
	mov	si, bp			 ;ds:si = NWSocketInfo

EC <	test	ds:[si].NWSIS_socketInfo, mask NWSI_CONNECTION_ORIENTED	>
EC <	ERROR_NZ NW_ERROR		;make sure is IPX socket 	>

	mov	si, ds:[si].NWSIS_listenECBArray ;*ds:si = listen array

					  ;pass ^hcx = NLHugeECB
	call	NetWareRemoveHugeECBFromArray ;DS WILL MOVE

	call	MemUnlock

	.leave
	ret
NetWareRemoveECBFromPendingListenListForSocket	endp


;DS WILL MOVE

NetWareRemoveHugeECBFromArray	proc	near
	uses	bx
	.enter

	;first make sure that the array has at least one item

EC <	push	cx							>
EC <	call	ChunkArrayGetCount					>
EC <	tst	cx							>
EC <	ERROR_Z NW_ERROR						>
EC <	pop	cx							>

	;now search the array for the HugeECB that we want (using its
	;global handle as a key)

	clr	bp			;default: did not find it.
	mov	bx, cs
	mov	di, offset NetWareFindECBInArray_Callback
	call	ChunkArrayEnum		;returns ds:bp = item

EC <	tst	bp							>
EC <	ERROR_Z NW_ERROR						>

	mov	di, bp			;ds:di = item in array
	call	ChunkArrayDelete

	.leave
	ret
NetWareRemoveHugeECBFromArray	endp


;for each NWPendingECBInfo in chunk array:

NetWareFindECBInArray_Callback	proc	far

	;get some information on this block (its address, for one)

EC <	cmp	ds:[di].NWPEI_protect, NW_PENDING_ECB_INFO_PROTECT	>
EC <	ERROR_NE NW_ERROR						>

	cmp	cx, ds:[di].NWPEI_hugeECB
	clc
	jne	done
	
	;found it! Return ds:bp = item in array

	mov	bp, di
	stc

done:
	ret
NetWareFindECBInArray_Callback	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareOpenSocket

DESCRIPTION:	Open the specified socket, or allocate a dynamic socket
		and open it. Keep track of this socket, in case PC/GEOS
		shuts down.

CALLED BY:	NetWareSocketOpenMainSocket, utility

PASS:		cl	= NWSocketInfo:
				    NWSI_GEOWORKS_MAIN_SOCKET:1
				    NWSI_STATIC_SOCKET:1
				    NWSI_DYNAMIC_SOCKET:1
				    NWSI_CONNECTION_ORIENTED:1

		dx	= SocketAddress to use (if 0, a dynamic socket
				will be allocated)

RETURN:		dx	- SocketAddress
		carry set if error

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareOpenSocket proc	far
	uses	ds
	.enter

	;open socket (We MUST close sockets during a shutdown, as our
	;callback routine sits in the heap, and is biffed. Therefore,
	;tell NetWare about this.)

	mov	al, SLF_KEEP_SOCKET_UNTIL_APP_EXITS
					;we generally close sockets during
					;shutdown, so tell NetWare so.

					;pass dx = socket address
	mov	bx, ISF_IPX_OPEN_SOCKET	;bx = IPXSPXFunction
	push	cx
	call	NetWareIPXCallFunction
	pop	cx

	;was this socket already opened?

	cmp	al, IOSCC_SUCCESSFUL
	je	socketOpen

socketOpenError:
	ForceRef socketOpenError

EC <	ERROR NW_ERROR_OPENING_SOCKET					>
NEC <	stc								>
NEC <	jmp	short done						>

socketOpen:
	;lock vars block, so we can store info about this new socket

	mov	ax, segment dgroup
	mov	ds, ax
	mov	bx, ds:[nwVars]
EC <	tst	bx							>
EC <	ERROR_Z NW_ERROR						>
	call	MemLock

	push	bx
	mov	ds, ax

	;
	; If it already exists, then we're done
	;

	call	NetWareFindSocketInfoInArray
	jc	unlockBlock


	;create two empty chunk arrays to hold NWPendingECBInfo structures:
	;one for packets listening on this socket, the other for packets
	;we are sending through this socket.

	mov	bx, size NWPendingECBInfo
	clr	ax, si, cx
	call	ChunkArrayCreate	;returns si = chunk array handle
	push	si			;save chunk handle

	mov	bx, size NWPendingECBInfo
	clr	ax, si, cx
	call	ChunkArrayCreate	;returns si = chunk array handle
	push	si			;save chunk handle

	;create a new NWSocketInfoStruc in the chunk array.

	mov	si, ds:[NWVBS_socketArray]
	call	ChunkArrayAppend	;returns ds:di = new element
					;DS WILL MOVE

	mov	ds:[di].NWSIS_socketInfo, cl
	mov	ds:[di].NWSIS_socketAddress, dx

	pop	ds:[di].NWSIS_listenECBArray
	pop	ds:[di].NWSIS_sendECBArray

unlockBlock:
	;unlock the vars block

	pop	bx
	call	MemUnlock
	clc

done::
	.leave
	ret
NetWareOpenSocket	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCloseAllSockets

DESCRIPTION:	Close all remaining static and dynamic sockets that we
		know about.

PASS:		cl	= whether to keep all information about the socket,
			  so that we could re-open it after a shutdown.

			  TRUE means keep the socket info structure, and all
			  pending NLHugeECBs, so that they can be resubmitted
			  after a shutdown.

RETURN:		ds, cx = same

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

;MUST MOVE THIS TO RESIDENT CODE SO DR_INIT CAN CALL IT.

NetWareCloseAllSockets	proc	far
	uses	ds
	.enter

	;lock vars block, so we can nuke info about this socket

	segmov	ds, <segment dgroup>, ax

	mov	bx, ds:[nwVars]
EC <	tst	bx							>
EC <	ERROR_Z NW_ERROR						>
	call	MemLock
	mov	ds, ax

	push	bx
	mov	si, ds:[NWVBS_socketArray]
	mov	bx, cs
	mov	di, offset NetWareCloseSocket_Callback
	call	ChunkArrayEnum
	pop	bx

	;unlock the vars block

	call	MemUnlock

	.leave
	ret
NetWareCloseAllSockets	endp


NetWareCloseSocket_Callback	proc	far
	;close the socket whose NWSocketInfoStruc is at DS:DI.

	call	NetWareCloseSocketDSDI

;PrintMessage <ACK! item will have been deleted from ChunkArray!>

	clc
	ret
NetWareCloseSocket_Callback	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCloseSocket

DESCRIPTION:	Close the specified socket, or allocate a dynamic socket
		and open it. Keep track of this socket, in case PC/GEOS
		shuts down.

CALLED BY:	NetWareSocketCloseMainSocket, utility

PASS:		dx	= Socket address
		cl	= whether to keep all information about the socket,
			  so that we could re-open it after a shutdown.

			  TRUE means keep the socket info structure, and all
			  pending NLHugeECBs, so that they can be resubmitted
			  after a shutdown.

RETURN:		ds, cx, dx = same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareCloseSocket proc	far
	uses	ds
	.enter


	;lock vars block, so we can nuke info about this socket

	mov	ax, segment dgroup
	mov	ds, ax
	mov	bx, ds:[nwVars]
EC <	tst	bx							>
EC <	ERROR_Z NW_ERROR						>
	call	MemLock
	mov	ds, ax

	;find this socket in the array

	call	NetWareFindSocketInfoInArray	;returns ds:bp = NWSocketInfo
						;*ds:si	= socket chunk array
EC <	ERROR_NC NW_ERROR						>
	mov	di, bp

	call	NetWareCloseSocketDSDI		;close the socket using
						;information at DS:DI

	;unlock the vars block

	call	MemUnlock

	.leave
	ret
NetWareCloseSocket	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCloseSocketDSDI

DESCRIPTION:	Close a specific socket.

PASS:		ds:di	= NWSocketInfoStruc in the socket chunk array
		cl	= whether to keep all information about the socket,
			  so that we could re-open it after a shutdown.

			  TRUE means keep the socket info structure, and all
			  pending NLHugeECBs, so that they can be resubmitted
			  after a shutdown.

RETURN:		ds, bx, cx	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareCloseSocketDSDI	proc	near
	uses	bx
	.enter

	;grab two chunk handles from this entry in the socket array,
	;and then nuke this socket entry.

	mov	dx, ds:[di].NWSIS_socketAddress	;dx = socket address

;	mov	ax, ds:[di].NWSIS_departureQueueArray
						;save chunk of depart. array
	push	ds:[di].NWSIS_listenECBArray	;save chunk of listen array
	push	ds:[di].NWSIS_sendECBArray	;save chunk of send array

	tst	cl				;keep socket info structure?
	jnz	20$				;skip if so...

	call	ChunkArrayDelete

;We don't yet have a departure queue.
;	call	LMemFree		;nuke the departure array

20$:	;for each outstanding listen and send ECB on this socket,
	;tell NetWare to nuke it.

	pop	si			;*ds:si = send ECB chunk array
					;pass cl = true/false
	call	NetWareCancelPendingECBsInArray

	tst	cl			;keep send ECB array?
	jnz	30$			;skip if so...

	mov	ax, si
	call	LMemFree

30$:
	pop	si			;*ds:si = listen ECB chunk array
					;pass cl = true/false
	call	NetWareCancelPendingECBsInArray

	tst	cl			;keep listen ECB array?
	jnz	40$			;skip if so...

	mov	ax, si
	call	LMemFree

40$:	;now close the socket

	push	cx
					;pass dx = socket address
	mov	bx, ISF_IPX_CLOSE_SOCKET ;bx = IPXSPXFunction
	call	NetWareIPXCallFunction	;does not return anything
	pop	cx

	.leave
	ret
NetWareCloseSocketDSDI	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCancelPendingECBsInArray

DESCRIPTION:	For each of the NWPendingECBInfo items in this chunk array,
		tell NetWare to cancel the ECB. This prevents our callback
		routine from being called when we exit to DOS.

CALLED BY:	NetWareCloseSocket

PASS:		*ds:si	= pending ECB chunk array
					(contains NWPendingECBInfo items)
		cl	= TRUE if should keep NLHugeECB structures.

RETURN:		ds, si, dx = same

DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareCancelPendingECBsInArray	proc	near
	uses	es, si, dx
	.enter
	mov	bx, cs
	mov	di, offset NetWareCancelPendingECB_Callback
	call	ChunkArrayEnum
	.leave
	ret
NetWareCancelPendingECBsInArray	endp


;for each NWPendingECBInfo in chunk array:

NetWareCancelPendingECB_Callback	proc	far

	;get some information on this block (its address, for one)

EC <	cmp	ds:[di].NWPEI_protect, NW_PENDING_ECB_INFO_PROTECT	>
EC <	ERROR_NE NW_ERROR						>

	mov	bx, ds:[di].NWPEI_hugeECB	;^hbx = NLHugeECB
	push	bx, cx, di

	;first, make sure that it is locked

EC <	push	ax							>
EC <	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT				>
EC <	call	MemGetInfo		;returns ah = lock count	>
EC <	cmp	ah, 1			;lock count should be 1		>
EC <	ERROR_NE NW_ERROR		;argh...			>
EC <	pop	ax							>

	;get its address

	call	MemDerefES		;es = segment of locked block

	;verify the address, and the contents of the block

EC <	call	MemLock			;lock it so we can examine it	>
EC <	mov	si, es
EC <	cmp	si, ax			;do we have the right segment?	>
EC <	ERROR_NE NW_ERROR						>
EC <	cmp	es:[HECB_protect1], HUGE_ECB_PROTECT1			>
EC <	ERROR_NE NW_ERROR		;is not a NLHugeECB!		>
EC <	call	MemUnlock						>

	clr	si			;set es:si = NLHugeECB

	mov	bx, ISF_IPX_CANCEL_EVENT ;bx = IPXSPXFunction
	call	NetWareIPXCallFunction

	;special case: IPX may have just released an ECB to us, but our
	;process thread has not yet handled the message from the callback
	;routine, to update these structures. So, if IPX is complaining
	;that an ECB cannot be cancelled, don't worry about it.

	cmp	al, ECBCC_FAILURE
	je	80$

EC <	tst	al			;check completion code		>
EC <	ERROR_NZ NW_ERROR						>

80$:	;indicate that this NLHugeECB is no longer pending

	pop	bx, cx, di
EC <	cmp	ds:[di].NWPEI_protect, NW_PENDING_ECB_INFO_PROTECT	>
EC <	ERROR_NE NW_ERROR						>
	ANDNF	ds:[di].NWPEI_flags, not (mask HECBF_PENDING)

	;now nuke the NLHugeECB block if requested.

	tst	cx			;keep the NLHugeECB around?
	jnz	done			;skip if so...

	call	MemFree

done:
	clc
	ret
NetWareCancelPendingECB_Callback	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareFindSocketInfoInArray

DESCRIPTION:	See if this socket is already in our table of open sockets.

CALLED BY:	NetWareOpenSocket, NetWareCloseSocket

PASS:		ds	= dgroup
		dx	= SocketAddress

RETURN:		ds, ax, bx, cx, dx = same	
		carry set if found
		ds:bp	= NWSocketInfoStruc
		*ds:si	= socket chunk array

DESTROYED:	di, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareFindSocketInfoInArray	proc	near
	uses	ax, bx
	.enter
	mov	si, ds:[NWVBS_socketArray]
	mov	bx, cs
	mov	di, offset NetWareFindSocket_Callback
	call	ChunkArrayEnum
	.leave
	ret
NetWareFindSocketInfoInArray	endp


NetWareFindSocket_Callback	proc	far
	cmp	dx, ds:[di].NWSIS_socketAddress
	clc
	jne	done

	mov	bp, di		;return ds:bp = item
	stc			;stop loop here
done:
	ret
NetWareFindSocket_Callback	endp



NetWareIPXCode	ends

endif
