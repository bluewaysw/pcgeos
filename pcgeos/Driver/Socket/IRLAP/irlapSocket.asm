COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Serial/IR communication
MODULE:		socket interface
FILE:		irlapSocket.asm
AUTHOR:		Steve Jang, Aug 10, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/10/94   	Initial revision

DESCRIPTION:
	
	Functions needed to interface raw IrlapDriver and Socket library.

	$Id: irlapSocket.asm,v 1.1 97/04/18 11:57:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapResidentCode	segment	resource

; ****************************************************************************
; ****************************************************************************
; *************    Indication handlers for Socket Lib Interface    ***********
; ****************************************************************************
; ****************************************************************************

DefIndicationProc	macro	routine, cnst
.assert ($-IndicationProcs) eq cnst*2, <function table is corrupted>
.assert (type routine eq far)
                fptr.far        routine
                endm

IndicationProcs   label fptr.far
DefIndicationProc IrlapSocketDiscoveryIndication,   NII_DISCOVERY_INDICATION
DefIndicationProc IrlapSocketDiscoveryConfirmation, NII_DISCOVERY_CONFIRMATION
DefIndicationProc IrlapSocketUnitdataIndication,    NII_UNITDATA_INDICATION
DefIndicationProc IrlapSocketConnectIndication,     NII_CONNECT_INDICATION
DefIndicationProc IrlapSocketConnectConfirmation,   NII_CONNECT_CONFIRMATION
DefIndicationProc IrlapSocketDataIndication,        NII_DATA_INDICATION
DefIndicationProc IrlapSocketStatusIndication,      NII_STATUS_INDICATION
DefIndicationProc IrlapSocketStatusConfirmation,    NII_STATUS_CONFIRMATION
DefIndicationProc IrlapSocketQOSIndication,         NII_QOS_INDICATION
DefIndicationProc IrlapSocketResetIndication,       NII_RESET_INDICATION
DefIndicationProc IrlapSocketResetConfirmation,     NII_RESET_CONFIRMATION
DefIndicationProc IrlapSocketDisconnectIndication   NII_DISCONNECT_INDICATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketIndicationHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine for NII indications	

CALLED BY:	Irlap native driver
PASS:		di	= NativeIrlapIndication
		rest	= variable
RETURN:		variable
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketIndicationHandler	proc	far
		shl	di, 1
		add	di, offset IndicationProcs
		push	cs:[di+2]	; segment
		push	cs:[di]		; offset
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		ret
IrlapSocketIndicationHandler	endp

IrlapResidentCode	ends

IrlapCommonCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketDiscoveryIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remote machine requests dicovery information

CALLED BY:	NII_DISCOVERY_INDICATION
PASS:		bx	= client handle
RETURN:		es:di	= DiscoveryLog from remote machine
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketDiscoveryIndication	proc	far
		.enter
	;
	; Do nothing
	;
		.leave
		ret
IrlapSocketDiscoveryIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketDiscoveryConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Diconvery procedure has been completed

CALLED BY:	NII_DISCOVERY_CONFIRMATION
PASS:		bx	= client handle
		dx	= discoveryLogs
RETURN:		nothing
DESTROYED:	nothing
NOTE:
	DiscoveryLogBlock was already placed in station:IS_discoveryLogBlock
	by discovery procedure.  Now we V blockSem, so that IrlapSocket-
	DoDiscovery can continue and access doscoveryLogs.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketDiscoveryConfirmation	proc	far
		uses	ax,bx,ds
		.enter
	;
	; V discovery semaphore so that IrlapSocketDoDiscovery can continue
	;
		GetDgroup ds, ax
		mov	bx, ds:[bx].IC_discoveryBlockSem
		call	ThreadVSem	; ax - destroyed
		
		.leave
		ret
IrlapSocketDiscoveryConfirmation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketUnitdataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unitdata has arrived
		The only use for unit data is datagrams

CALLED BY:	NII_UNITDATA_INDICATION
PASS:		ax	= seqInfo
		bx	= client handle
		cx	= data size
		si	= data offset
		dx:bp	= data buffer
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketUnitdataIndication	proc	far
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; See if this is the first packet of a datagram or a middle packet
	; by checking the signature
	;
		IrlapLockPacket	esdi, dxbp
		add	di, si
		mov_tr	si, bx			; si = client handle
		mov	bl, FT_FIRST
		cmp	es:[di+2].IDI_sig1, IRLAP_DATAGRAM_SIG1 ; +2 = size
		jne	middle					;      seqInfo
		cmp	es:[di+2].IDI_sig2, IRLAP_DATAGRAM_SIG2 ;
middle:
		IrlapUnlockPacket dx
		je	firstFragment
		mov	bl, FT_MIDDLE
firstFragment:
		GetDgroup ds, di
		mov	es, ds:[si].IC_station
		mov	di, offset IS_datagramPacket
	;
	; Reassemble the fragment
	; es	= station segment
	; es:di	= station:IS_datagramPacket
	; ax	= seqInfo
	; bl	= FragmentType
	; cx	= fragment size
	; dxbp	= data buffer
	; si	= client handle
	;
		call	IrlapReassemblePacket
		jc	error
		tst	dx
		clc
		jz	packetNotCompleteYet
	;
	; Re-adjust datagram header if our local address match the address
	; in the packet
	;
		push	si
		IrlapLockPacket	dsdi, dxbp
		mov	bx, di
		add	di, ds:[di].PH_dataOffset
		mov	ax, di
		clr	ch
		mov	cl, ds:[di].IDI_addrOffset
		add	di, cx
	;
	; Compare addresses
	;
		mov	si, IS_discoveryInfo
		mov	cl, ds:[bx].IDI_addrSize
		xchg	di, si	; esdi = local address, dssi = addr in packet

		SBCompareStrings

		mov	di, ax		; restore beginning of datagram
		jne	incorrectAddr
	;
	; Copy DatagramPacketHeader info
	; : Please don't change this section unless you know what the packet
	;   received by IrLAP really looks like( somewhat hacky )
	;
		movm	ds:[bx].DPH_addrSize, ds:[di].IDI_addrSize, al
		movm	ds:[bx].DPH_addrOffset, ds:[di].IDI_addrOffset, al
		mov	ax, ds:[bx].PH_dataOffset  ; ATTENTION!!!!!!
		add	ds:[bx].DPH_addrOffset, al ; AH must be 0
		mov	ax, ds:[di].IDI_dataOffset
		sub	ds:[bx].PH_dataSize, ax
		add	ds:[bx].PH_dataOffset, ax
		movm	ds:[bx].DPH_localPort, ds:[di].IDI_localPort, ax
		movm	ds:[bx].DPH_remotePort, ds:[di].IDI_remotePort, ax
		mov	ds:[bx].PH_flags, PT_DATAGRAM
		cmp	al, al				; set zero flag
incorrectAddr:
		IrlapUnlockPacket dx
		pop	si
		jnz	discardMisdeliveredDatagram
	;
	; Send it up as unitdata if the addresses match
	;
		GetDgroup es, cx
		mov_tr	cx, dx
		mov_tr	dx, bp
		pushdw	es:[si].IC_scoCallback
		mov	di, SCO_RECEIVE_PACKET
		call	PROCCALLFIXEDORMOVABLE_PASCAL
packetNotCompleteYet:
done:
		.leave
		ret
discardMisdeliveredDatagram:
		movdw	axcx, dxbp
		call	HugeLMemFree
EC <		WARNING	_IRLAP_MISDELIVERED_DATAGRAM			>
		jmp	done
error:
	;
	; One of the datagram fragments was lost or multiple stations are
	; trying to send datagrams at the same time.
	;
EC <		WARNING	_IRLAP_CORRUPTED_PACKET_FRAGMENT_DISCARDED	>
		jmp	done
IrlapSocketUnitdataIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketConnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	remote machine requested connection

CALLED BY:	NII_CONNECT_INDICATION
PASS:		ax	= IrlapConnectionFlags
		bx	= connection handle
		cxdx	= 32 bit remote device address
		es:si	= remote address
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketConnectIndication	proc	far
		uses	ax, bx, di, si, ds
		.enter
		GetDgroup ds, di
		mov	ds, ds:[bx].IC_station
	;
	; irlap connection successful
	;
		clr	ds:IS_connFailureCount
		BitSet	ds:IS_status, ISS_IRLAP_CONNECT_PROGRESS
		test	ds:IS_status, mask ISS_SOCKET_LINK_OPEN
		jz	skipCleanUp
	;
	; if this is the initial connection, set LinkOpen
	;
		BitSet	ds:IS_status, ISS_SOCKET_LINK_OPEN
	;
	; if this is the initial connection, clean up input/output buffers
	;
		test	ax, mask ICF_SOCKET_INIT
		jz	skipCleanUp
	;
	; clean up data transfer
	;
		call	IrlapCleanUpDataTransfer
	;
	; if we are in socket Link open mode, do the proper notifications
	; : this happens when our irlap connection was disconnected but
	;   socket library level data link connection was alive, and if
	;   station other than the one we are supposed to be connected to
	;   requested connection.
	;
		push	ds, bx
		mov	di, ds:IS_domainHandle
		GetDgroup ds, ax
		pushdw	ds:[bx].IC_scoCallback
		mov	ax, bx
		mov_tr	bx, di
		mov	cx, SCT_FULL
		mov	di, SCO_LINK_CLOSED
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	ds, bx
skipCleanUp:
	;
	; Convert this confirmation into SCO_ function
	;	Find station structure, and get domain handle
	;
		BitSet	ds:IS_status, ISS_SOCKET_LINK_OPEN
		push	ds, bx
		mov	di, ds:IS_domainHandle
		GetDgroup ds, ax
		pushdw	ds:[bx].IC_scoCallback
		mov	ax, bx
		mov	cx, IRLAP_GEOS_ADDRESS_SIZE	; = 16
	;
	; Address string in ds:si
	;
		segmov	ds, es			; ds:si = remote address
		mov_tr	bx, di
		mov	di, SCO_LINK_OPENED
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	ds, bx			; ds = station, bx = client
	;
	; Automatically accept the connection by calling
	; IrlapNativeConnectResponse
	; ds = segment
	; bx = client handle
	;
		mov	si, offset IS_qos	; ds:si = QOS struct
		BitSet	ds:[si].QOS_flags, QOSF_DEFAULT_PARAMS
		call	IrlapNativeConnectResponse
		.leave
		ret
IrlapSocketConnectIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketConnectConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connection has been established

CALLED BY:	NII_CONNECT_CONFIRMATION
PASS:		ax	= seqInfo
		bx	= client handle
		cx	= size of data
		si	= data offset
		dx:bp	= data buffer
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketConnectConfirmation	proc	far
		uses	ax, bx, cx, ds
		.enter
	;
	; Reinitialize socket link related
	;
		GetDgroup ds, ax
		mov	cx, ds:[bx].IC_connectBlockSem
		mov	ds, ds:[bx].IC_station
		mov_tr	bx, cx
		call	ThreadVSem	; ax trashed
		clr	ds:IS_connFailureCount
		.leave
		ret
IrlapSocketConnectConfirmation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Data has arrived

CALLED BY:	NII_DATA_INDICATION
PASS:		ax	= seqInfo ( remaining number of bytes to receive )
		bx	= connection handle (= client handle )
		cx	= data size
		si	= data offset( ignored )
		dx:bp	= data buffer
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketDataIndication	proc	far
		uses	ax,bx,cx,dx,bp,si,di,es,ds
		.enter
	;
	; Get station segment
	;
		GetDgroup ds, di
		mov_tr	si, bx
		mov	es, ds:[si].IC_station
		mov	di, offset IS_seqPacket
		mov	bl, FT_FIRST
		tst	es:[di].IPA_packet.high
		jz	firstPacket
		mov	bl, FT_MIDDLE
firstPacket:
	;
	;	es	= station segment
	;	es:di	= station:IS_seqPacket
	;	ax	= seqInfo
	;	bl	= FragmentType	(byte)
	;	cx	= data size
	;	dxbp	= data buffer
	;	si	= client handle
	;
		call	IrlapReassemblePacket
		jc	error
	;
	; dxbp = data packet to send up
	; dx = 0 if the packet is still in reassembly process
	; si = client handle
	;
		tst	dx
		clc
		jz	done
		
		IrlapLockPacket	dsdi, dxbp
		mov	ds:[di].PH_flags, PT_SEQUENCED		; = 0000 0001
		movm	ds:[di].PH_domain, es:IS_domainHandle, ax
		mov	ds:[di].SPH_link, si
		IrlapUnlockPacket dx
	;
	; dxbp = data packet to send up
	; bx   = client handle
	;
		GetDgroup es, cx
		mov_tr	cx, dx
		mov_tr	dx, bp
		pushdw	es:[si].IC_scoCallback
		mov	di, SCO_RECEIVE_PACKET
		call	PROCCALLFIXEDORMOVABLE_PASCAL
done:
		.leave
		ret
error:
	;
	; These should be the packets duplicated over an irlap disconnection
	; and reconnection
	;
EC <		WARNING	_IRLAP_CORRUPTED_PACKET_FRAGMENT_DISCARDED	>
		jmp	done
IrlapSocketDataIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketStatusIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remote device requested status, or connection is in jeopardy

CALLED BY:	NII_STATUS_INDICATION
PASS:		bx	= connection handle (= client handle )
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketStatusIndication	proc	far
		uses	ax
		.enter
	;
	; beep 5 times
	;
		mov	ax, SST_WARNING
		call	UserStandardSound
		mov	ax, SST_WARNING
		call	UserStandardSound
		mov	ax, SST_WARNING
		call	UserStandardSound
		mov	ax, SST_WARNING
		call	UserStandardSound
		mov	ax, SST_WARNING
		call	UserStandardSound
		
		.leave
		ret
IrlapSocketStatusIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketStatusConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received connection status from remote machine

CALLED BY:	NII_STATUS_CONFIRMATION
PASS:		bx	= connection handle (= client handle )
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketStatusConfirmation	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Currently not supported by the station
	;
		.leave
		ret
IrlapSocketStatusConfirmation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketQOSIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Currently not supported

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketQOSIndication	proc	far
		.enter
		
		.leave
		ret
IrlapSocketQOSIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketResetIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remote machine requested reset

CALLED BY:	NII_RESET_INDICATION
PASS:		bx	= connection handle (= client handle )
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketResetIndication	proc	far
	;
	; Automatically agree to reset
	;
		call	IrlapNativeResetResponse
		ret
IrlapSocketResetIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketResetConfirmation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	connection has been reset

CALLED BY:	NII_RESET_CONFIRMATION
PASS:		bx	= connection handle (= client handle )
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketResetConfirmation	proc	far
	;
	; do nothing at this time; there is no way we can notify socket
	; library of this event
	;
		ret
IrlapSocketResetConfirmation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketDisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connection has been terminated

CALLED BY:	NII_DISCONNECT_INDICATION
PASS:		ax	= IrlapCondition
		bx	= connection handle (= client handle )
		cx	= IrlapUnackedData
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketDisconnectIndication	proc	far
		uses	ax,bx,cx,ds,di
		.enter
	;
	; Get station segment & Clear irlapConnectProgress flag
	;
		GetDgroup ds, di
		mov	ds, ds:[bx].IC_station
		BitClr	ds:IS_status, ISS_IRLAP_CONNECT_PROGRESS
		
		cmp	ax, IC_CONNECTION_TIMEOUT_P
		je	connectionTimeout
		cmp	ax, IC_CONNECTION_TIMEOUT_S
		jne	connectionFailure
connectionTimeout:
		call	IrlapSocketConnectionTimeout	; ax,bx,cx,dx,di
		jmp	done				; = destroyed
connectionFailure:
		cmp	ax, IC_CONNECTION_FAILURE
		jne	mediaBusy
		call	IrlapSocketConnectionFailure	; nothing destroyed
		jc	linkClosed			;
		jmp	done
mediaBusy:
		cmp	ax, IC_MEDIA_BUSY
		jne	primaryConflict
	;
	; Notify the user that there are other traffic out there
	;
		mov	ax, mask CDBF_SYSTEM_MODAL or \
			(CDT_WARNING shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		mov	si, offset mediaBusyStr
		call	DisplayMessage
		jmp	linkClosed
primaryConflict:		
		cmp	ax, IC_PRIMARY_CONFLICT
		je	linkClosed
cannotConnect:
EC <		cmp	ax, IC_REMOTE_DISCONNECTION			>
EC <		ERROR_NE IRLAP_INVALID_DISCONNECTION_REASON		>
linkClosed:
	;
	; Check if we reached here as the result of
	; IrlapSocketConnectRequest::addressNotFound.
	; ( this can happen when connection request successfully went through,
	;   but the request timed out before Connection.confirmation. )
	;
		GetDgroup ds, ax
		movdw	cxdi, ds:[bx].IC_scoCallback  ; cxdi = callback routine
		mov	ds, ds:[bx].IC_station
		test	ds:IS_status, mask ISS_CONNECT_REQ_TIMED_OUT
		jnz	connectionTimeoutFailure; this is actually a connection
	;					; failure due to timeout
	; Indicate that the connection has gone away
	; Convert this confirmation into SCO_ function
	;	Find station structure, and get domain handle
	;
		mov_tr	ax, bx
		mov	bx, ds:IS_domainHandle
		pushdw	cxdi
		mov	cx, SCT_FULL
		mov	di, SCO_LINK_CLOSED
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	;
	; Clr link open flag
	;
		BitClr	ds:IS_status, ISS_SOCKET_LINK_OPEN
connectionTimeoutFailure:
	;
	; reinitialize some of the variables
	;
		mov	ds:IS_sleepTime, IRLAP_SLEEP_TIMEOUT_TICKS
	;
	; Free all the data request events in the queue
	;
		call	IrlapCleanUpDataTransfer
done:
		.leave
		ret
IrlapSocketDisconnectIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketConnectionTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An Irlap connection timed out.  But socket library level
		LINK conneciton will be kept alive.

CALLED BY:	IrlapSocketDisconnectionIndication
PASS:		ax	= IC_CONNECTION_TIMEOUT_P or IC_CONNECTION_TIMEOUT_S
		bx	= client handle
		cx	= IrlapUnackedData handle
		ds	= station segment
RETURN:		nothing
DESTROYED:	ax,bx,cx,ds,di

PSEUDO CODE/STRATEGY:

	if (unacked data)
		resend unacked data

	if (sniff link)
		sniff.request

	if (we were primary)
		reconnect
	else
		do nothing
	free(unacked data block)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketConnectionTimeout	proc	near
		.enter
	;
	; if there is any unacked data, resend them
	;
		tst	cx
		jz	finish
		push	bx			; save client handle
		mov_tr	bx, cx			; bx = IrlapUnackedData block
		mov	cx, ax			; cx = IrlapCondition passed in
		call	MemLock
		mov	es, ax
		mov	ax, es:IUD_numUnackedFrames
		tst	ax
		jz	unlockDone
	;
	; resend data
	; ax = num of unacked frames
	; es = IrlapUnackedData block
	;
		call	ResendUnackedFrames
		call	MemUnlock
		call	MemFree
		pop	bx			; restore client handle
	;
	; if we are primary and there was unacked data, then reconnect
	;
		cmp	cx, IC_CONNECTION_TIMEOUT_P
		jne	finish
		jmp	reconnect
unlockDone:
		call	MemUnlock
		call	MemFree
		pop	bx
finish:
	;
	; If there are pending data request, reopen connection
	;
		GetDgroup ds, di
		mov	ds, ds:[bx].IC_station
		tst	ds:IS_pendingConnectedData
		jz	done
reconnect:
		call	IrlapSocketReconnect
done:
		.leave
		ret
IrlapSocketConnectionTimeout	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketConnectionFailure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connection attempt failed

CALLED BY:	IrlapSocketDisconnectionIndication
PASS:		bx	= client handle
		ds	= station segment
RETURN:		carry set if conneciton failure threshold was exceeded
DESTROYED:	none

PSEUDO CODE/STRATEGY:

	Warn the user that the remote party is not reachable
	Inc( failure count )
	if (failure threshold is not exceeded)
		reconnect
	else
		return error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketConnectionFailure	proc	near
		uses	ax,bx,cx,ds
		.enter
	;
	; Increment failure count
	;
		inc	{byte}ds:IS_connFailureCount
	;
	; if failure count < connection failure threshold,
	;	Warn the user
	; 	attempt reconnection
	; else return carry set
	;
		cmp	{byte}ds:IS_connFailureCount,\
			IRLAP_CONN_FAILURE_THRESHOLD
		ja	linkDown			; carry set
		mov	ax, mask CDBF_SYSTEM_MODAL or \
			(CDT_WARNING shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		mov	si, offset connectFailed
		call	DisplayMessage
	;
	; Try to reconnect
	;
		call	IrlapSocketReconnect
		clc
done:
		.leave
		ret
linkDown:
		stc
		jmp	done
IrlapSocketConnectionFailure	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketReconnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reestablish irlap connection with the same destination
		device address
CALLED BY:	IrlapSocketConnectionTimeout, IrlapSocketConnectionFailure
PASS:		bx	= connection handle
		ds	= station segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketReconnect	proc	far
		uses	ax,cx,bp
		.enter
EC <		IrlapCheckStation	ds				>
	;
	; Set irlapConnected flag
	;
		test	ds:IS_status, mask ISS_IRLAP_CONNECT_PROGRESS
		jnz	done
		BitSet	ds:IS_status, ISS_IRLAP_CONNECT_PROGRESS
	;
	; Check link management mode	
	;
		mov	ax, ds:IS_linkMgtMode
		movdw	cxbp, ds:IS_destDevAddr
		call	IrlapNativeConnectRequest
done:
		.leave
		ret
IrlapSocketReconnect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResendUnackedFrames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resends all unacked frames

CALLED BY:	IrlapSocketConnectionTimeouot
PASS:		ax	= num of unacked frames
		es	= IrlapUnackedData block
		ds	= station segment
RETURN:		carry set if the operation was aborted because of memory
		problem
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResendUnackedFrames	proc	near
		uses	ax, bx, cx, di, dx, bp, si
		.enter
	;
	; reverse order of sending these frames since IRLAP_URGENT_REQUEST_MASK
	; will insert requests to the front of the event queue
	;
		mov	cl, size UnackedFrame
		dec	al
		mul	cl
		add	ax, offset IUD_optrArray	; get last frame in
		mov	di, ax				; IrlapUnackedData blck
	;
	; parameters to NIR_DATA_REQUEST
	;	bx = client handle
	;	cx = data size
	;	si = offset into buffer
	;	dxbp = user data buffer( hugelmem handle )
	;
		mov	bx, ds:IS_clientHandle
		clr	dx, bp
		jmp	firstResend
resendLoop:
	;
	; compare current optr with last optr, if they are the same, the
	; last optr has been duplicated so we don't need to duplicate it
	; again.
	;
		pushdw	dxbp			   ; save last optr sent
		movdw	dxbp, es:[di].UF_optr
		mov	si, di
		add	si, size UnackedFrame
		cmpdw	dxbp, es:[si].UF_optr
		popdw	dxbp
		je	skipCopy
firstResend:
	;
	; We need to duplicate the buffer no matter what if this is the first
	; frame being sent
	;
		mov	ax, es:[di].UF_dataOffset
		mov	cx, es:[di].UF_size
		movdw	dxbp, es:[di].UF_optr
		call	DuplicateDataBuffer	   ; dxbp = new hugelmem buffer
		jc	notEnoughMemory		   ; do not send if no more
						   ; memory is available
skipCopy:
	;
	; dxbp = buffer to send
	;
		clr	ax			   ; data begins at front
		mov	si, es:[di].UF_seqInfo
		push	di
		mov	di, NIR_DATA_REQUEST or IRLAP_URGENT_REQUEST_MASK
		call	IrlapNativeDataRequest
		pop	di
		cmp	di, offset IUD_optrArray
		je	wasLastFrame
	;
	; Go to the previous frame
	;
		sub	di, size UnackedFrame
		jmp	resendLoop
notEnoughMemory:
wasLastFrame:
		.leave
		ret
ResendUnackedFrames	endp


; ****************************************************************************
; ****************************************************************************
; *****************    Socket Lib Interface Utilities    *********************
; ****************************************************************************
; ****************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeSocketClient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Access IRLAP client table, and initialize a socket client

CALLED BY:	IrlapSocketRegister
PASS:		bx	= client handle
		dxbp	= callback routine for SCO_ functions
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializeSocketClient	proc	near
		uses	ax,es
		.enter
	;
	; Set ICF_SOCKET flag and set IC_scoCallback in the client entry
	;
		GetDgroup es, ax
		BitSet	es:[bx].IC_flags, ICF_SOCKET
		movdw	es:[bx].IC_scoCallback, dxbp
		mov	es, es:[bx].IC_station
		BitSet	es:IS_status, ISS_SOCKET_CLIENT
		
		.leave
		ret
InitializeSocketClient	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MatchAddressInDiscoveryLog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Matches an address passed in to addresses discovered by
		IrLAP.  DiscoveryLogBlock contains at least 1 log entry.

CALLED BY:	RunAddressDialog
PASS:		es	= DiscoveryLogBlock segment
		ds:si	= address passed in
		
RETURN:		dx	= index to the item found
		cxbp	= dev address if address is found
		carry set if not found
		cxbp	= unchanged if address is not found

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MatchAddressInDiscoveryLog	proc	near
		uses	ax, bx, di
		.enter
	;
	; is there log entries?
	;
		push	cx
		test	es:DLB_flags, mask DBF_LOG_RCVD
		jz	notFound
	;
	; ax = last log entry offset
	; bx = current log entry offset
	; cx = max # of characters to compare
	; di = current discovered address string offset
	; dx = current log entry index
	;
		mov	bx, size DiscoveryLogBlock
		mov	ax, size DiscoveryLog
		mov	cl, es:DLB_lastIndex
		mul	cl
		add	ax, bx
		clr	cx, dx			; cmp null terminated strings
		mov	di, bx
		add	di, offset DL_info
matchLoop:
		cmp	bx, ax
		jae	notFound

		SBCompareStrings

		je	found
		add	bx, size DiscoveryLog
		add	di, size DiscoveryLog
		inc	dl
		jmp	matchLoop
found:
		pop	cx
		movdw	cxbp, es:[bx].DL_devAddr
		clc
done:
		.leave
		ret
notFound:
		pop	cx
		stc
		jmp	done
MatchAddressInDiscoveryLog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapFragmentAndSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fragments a packet into right sizes and send them over
		IRLAP link.

CALLED BY:	IrlapSocketSendData
PASS:		dx:bp = hugelmem buffer to send
 		cx    = size of data
		ax    = offset to real data in buffer
		ds    = station segment
		di    = NIR_UNITDATA_REQUEST or NIR_DATA_REQUEST
RETURN:		carry set if data not sent
		di    = IrlapError
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	I allocate memory chunk(hugelmem) to pass parameters to the handlers.
Parameter block consists of: dataOffset, buffer optr, sequence info

	numBytesLeft = totalSize
	F_LOOP
		Allocate(ParamBlock)
		ParamBlock.dataOffset = dataOffset
		ParamBlock.bufferOptr = bufferOptr
		ParamBlock.seqInfo = numBytesLeft

		if numBytesLeft < defaultDataSize
			dataSize = numBytesLeft
		else
			dataSize = defaultDataSize

		DataRequest( dataSize, ParamBlock )
		numBytesLeft = numBytesLeft - dataSize

		if ( numBytesLeft == 0 )
			exit
		else
			dataOffset = dataOffset + dataSize
			jmp	F_LOOP

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapFragmentAndSend	proc	far
		uses	ax,bx,cx,dx,si,bp,ds
		.enter
	;
	; Initialize Loop Variables
	;
		mov_tr	bx, cx			; bx = num bytes left to send
fragmentationLoop:
	;
	; ax	= offset to the real data
	; bx	= number of bytes left to send
	; cx	= numBytes to send = IS_maxIFrameSize
	; dxbp	= buffer optr
	; ds	= station
	;
		mov	cx, ds:IS_maxIFrameSize
	;
	; If last fragment, dataSize := numBytesLeft
	;
		cmp	bx, cx
		ja	notLast
		mov	cx, bx
notLast:		
	;
	; parameters to IrlapNativeDataRequest:
	;	ax = offset into buffer
	;	bx = connection handle
	;	cx = number of bytes to send
	;	si = seqInfo = numBytesLeft to send
	;	dxbp = user databuffer
	;
		mov_tr	si, bx			; save numBytesLeft
		mov	bx, ds:IS_clientHandle	; bx = connection handle
		push	di
		call	IrlapStrategy		; di = error
		jc	error
		pop	di
		mov_tr	bx, si
	;
	; numBytesLeft := numBytesLeft - numBytesTransmitted
	; if numBytesLeft == 0, exit
	;
		sub	bx, cx
		tst	bx
		jz	exit
	;
	; dataOffset := dataOffset + numBytesTransmitted
	;
		add	ax, cx
		jmp	fragmentationLoop
exit:
		.leave
		ret
error:
	;
	; di = IrlapError
	;
		pop	ax
		jmp	exit			; carry set
		
IrlapFragmentAndSend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapReassemblePacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reassembles a packet received from remote side

CALLED BY:	IrlapSocketDataIndication, IrlapSocketUnitdataIndication
PASS:		es	= station segment
		es:di	= IrlapPacketAssembly structure to use
		ax	= seqInfo
		bl	= FragmentType	(byte)
		cx	= data size
		dxbp	= data buffer( this will be deallocated within this
			               routine )
		
RETURN:		dxbp 	= a complete packet to send up to socket library
			  [ PH_dataSize, PH_datasOffset, PH_domain filled in
			    the caller needs to fill in the rest of header.  ]
		dx	= 0 if there are still some fragments not delivered
			  yet.
		if error,
			carry set
			dx = IrlapError
				IE_MEM_ALLOC_ERROR or
				IE_OUT_OF_SEQUENCE_FRAME
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

FirstFragment?
Yes => Reinitialize IrlapPacketAssembly structure
       goto copy:
No  => Expected fragment?
copy:  Yes => Copy fragment into reassmbly buffer
	      Complete packet?
	      Yeah => return dxbp = IPA_packet buffer
	      No   => return dx = 0
       No  => return dx = 0

dx = 0 also means that the data frame has been deallocated
		       
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapReassemblePacket	proc	near
		uses	ax,bx,cx,si,di,es,ds
		.enter
	;
	; ds = dgroup
	;
		GetDgroup ds, si
		sub	cx, size word			; (dataSize - seqInfo)
	;
	; Is this the first fragment of a packet?
	;
		cmp	bl, FT_FIRST
		jne	middleFragment
	;
	; Re-initialize IrlapPacketAssembly structure:
	; 1. If there is a packet being reassembled, deallocate it
	;
		push	ax, cx
		tst	es:[di].IPA_packet.high
		jz	skipDeallocation
EC <		WARNING _DISCARDING_PACKET_IN_REASSEMBLY		>
		movdw	axcx, es:[di].IPA_packet
		call	HugeLMemFree
skipDeallocation:
	;
	; 2. allocate a new reassembly buffer
	; 3. initialize IrlapPacketAssembly structure
	;
		mov	si, ax				; ax = total data size
		mov	es:[di].IPA_curOffset, size DatagramPacketHeader
		add	ax, size DatagramPacketHeader	; enough room for seq
							; packet header too
		mov	es:[di].IPA_packetBound, ax
		push	di
		mov	bx, ds:hugeLMemHandle
		mov	cx, IRLAP_HUGELMEM_TIMEOUT
		call	HugeLMemAllocLock		;axcx= optr, dsdi= fptr
	;
	; Fill in PacketHeader
	;
		mov	ds:[di].PH_dataSize, si
		mov	ds:[di].PH_dataOffset, size DatagramPacketHeader
		movm	ds:[di].PH_domain, es:IS_domainHandle, si
		pop	di
		jc	memError
		movdw	es:[di].IPA_packet, axcx
		mov_tr	bx, ax
		call	HugeLMemUnlock
		pop	ax, cx
		jmp	storeFragment
middleFragment:
	;
	; ax = seqInfo
	; cx = current fragment size
	; dxbp = data buffer
	; esdi = IrlapPacketAssembly structure to use
	; es   = station segment
	; ds   = dgroup
	;
		
	;
	; Expected fragment?
	;
		tst	es:[di].IPA_packet.high
		jz	outOfSequence
		cmp	cx, ax
		ja	outOfSequence
		mov	bx, es:[di].IPA_curOffset
		add	bx, ax
		cmp	bx, es:[di].IPA_packetBound
		jne	outOfSequence
storeFragment:
	;
	; ax = seqInfo
	; cx = current fragment size
	; dxbp = data buffer
	; esdi = IrlapPacketAssembly structure to use
	; es   = station segment
	; ds   = dgroup
	;
		push	ax, cx
		push	dx, bp, es, di
		IrlapLockPacket dssi, dxbp
		add	si, ds:[si].PH_dataOffset	; + real data offset
		add	si, size word			; + size seqInfo
		mov	ax, es:[di].IPA_curOffset
		add	es:[di].IPA_curOffset, cx	; increment curOffset
		movdw	dxbp, es:[di],IPA_packet
		IrlapLockPacket	esdi, dxbp
		add	di, ax				; + curOffset
		shr	cx, 1
		jnc	cxEven
		movsb
cxEven:
		rep	movsw
		IrlapUnlockPacket dx
		pop	dx, bp, es, di
		mov	bx, dx
		call	HugeLMemUnlock
		movdw	axcx, dxbp
		call	HugeLMemFree
	;
	; Complete packet?
	;
		clr	dx
		pop	ax, cx
		cmp	cx, ax
		jb	finish
EC <		ERROR_A	IRLAP_INVALID_SEQ_INFO				>
		clr	bp
		xchgdw	dxbp, es:[di].IPA_packet	; dxbp = packet to
finish:							;        send up
		clc
done:
		.leave
		ret
memError:
		pop	ax, cx
		movdw	axcx, dxbp
		call	HugeLMemFree
		mov	dx, IE_MEM_ALLOC_ERROR
		stc
		jmp	done
outOfSequence:
EC <		WARNING	_IRLAP_OUT_OF_SEQUENCE_FRAGMENT			>
		movdw	axcx, dxbp
		call	HugeLMemFree
		mov	dx, IE_OUT_OF_SEQUENCE_FRAME
		stc
		jmp	done
IrlapReassemblePacket	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketDoDiscovery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Carry out discovery process, and return the
		DiscoveryLogBlock

CALLED BY:	IrlapSocketConnectRequest, IrlapSocketSendDatagram
PASS:		bx	= client handle
RETURN:		cx	= number of discoveryLogs in discoveryLogBlock
		station:IS_discoveryLogBlock = discoveryLogBlock
		carry set if no other devices were discovered
DESTROYED:	nothing
ALGORITHM:

	call	IrlapNativeDiscoveryRequest
	P(client.blockSem)	; V'ed by SocketDiscoveryConfirm
	station.IS_discoveryLogBlock := discoveryLogBlock
	LockES ( station.IS_discoveryLogBlock )

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketDoDiscovery	proc	far
		uses	ax,bx,dx,bp,es,di,ds
		.enter
	;
	; Call IrlapNativeDiscoveryRequest
	;
		GetDgroup es, ax
		mov	ds, es:[bx].IC_station
		clr	ds:IS_retryCount
		mov	ch, IDT_DISCOVERY
doDiscovery:
		BitClr	ds:IS_status, ISS_DISCOVERY_ERROR
		mov	cl, IUTS_6_SLOT
		call	IrlapNativeDiscoveryRequest
	;
	; wait for Discovery.confirm
	;
		mov	bx, es:[bx].IC_discoveryBlockSem
		call	ThreadPSem
		mov	bx, ds:IS_clientHandle
	;
	; Check if there are duplicate device address
	;
		call	CheckDuplicateDeviceAddress ; cx = num of discoveryLogs
		jnc	continue
	;
	; dxbp = conflicting address, returned by CheckDuplicateDeviceAddress
	;
		mov	ch, IDT_ADDRESS_RESOLUTION
		jmp	doDiscovery
continue:
	;
	; Check for ISS_discoveryError, if there was error in discovery
	; process re-do discovery
	;
		test	ds:IS_status, mask ISS_DISCOVERY_ERROR
		jz	exit
	;
	; Test if failure count
	;
		cmp	ds:IS_retryCount, IRLAP_DISCOVERY_FAILURE_THRESHOLD
		jbe	doDiscovery
exit:
		.leave
		ret
IrlapSocketDoDiscovery	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDuplicateDeviceAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run through discovery log block, and find out how many
		discovery log entries there are.
		For each entry, give it an index(from 0 to n increasing by 1)
CALLED BY:	IrlapSocketDoDiscovery
PASS:		ds	= station segment
RETURN:		cx	= number of discoveryLog entries
		if there are duplicate addresses,
			carry set
			dxbp = conflicting device address
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDuplicateDeviceAddress	proc	near
		uses	ax, bx, si, di, ds
		.enter
		
		mov	bx, ds:IS_discoveryLogBlock
		call	MemLock
		mov	ds, ax
		mov	ch, ds:DLB_flags
		mov	cl, ds:DLB_lastIndex
		test	ch, mask DBF_LOG_RCVD
		mov	ch, 0
		jz	finish
		push	cx
matchLoop:
		push	cx
		dec	cl			; get last index (= i)
		jz	endLoop			; there is only one entry
	;
	; compare Log[i] with Log[0] - Log[i-1]
	;
		mov	ax, size DiscoveryLog
		mul	cl
		add	ax, size DiscoveryLogBlock + offset DL_devAddr
		mov	si, ax			; ds:si = Log[i]
		mov	di, si			;
		sub	di, size DiscoveryLog	; ds:di = Log[i-1]
findLoop:
		cmp	di, size DiscoveryLogBlock + offset DL_devAddr
		pushf
		cmpdw	ds:[si], ds:[di], ax
		je	duplicateAddress
		sub	di, size DiscoveryLog
		popf
		jne	findLoop
endLoop:
		pop	cx
		loop	matchLoop
		pop	cx			; cx = num of log entries in
		clc				;      discoveryLog block
finish:
		call	MemUnlock
		.leave
		ret
duplicateAddress:
		popf
		pop	cx
		pop	cx
		movdw	dxbp, ds:[si], ax
		stc
		jmp	finish
CheckDuplicateDeviceAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolveConnectionAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Examines the address passed in for connection and determines
		the actual address to connect to.
CALLED BY:	IrlapSocketConnectRequest
PASS:		bx	= client handle
		cx	= number of log entries in discovery block
		ds:si	= address passed in

RETURN:		cxbp	= 32 bit device address to connect to
		carry set if address could not be resolved

IMPORTANT:	Do not call this routine from IRLAP event thread as it will
		block on a semaphore which is to be V'ed by IRLAP event thread.

DESTROYED:	nothing
PSEUDO CODE/STRATEGY:

	If (discoveryLogCount = 1) AND (address passed in = default string)
		return deviceAddress[0] if not connected yet
		rerurn IS_destDevAddr if already connected
	elsif (discoveryLogCount = 0)
		goto launchDialog
	elsif (address[0] = IRLAP_INDEFINITE_ADDR_CHAR)
		goto launchDialog
	elsif (address passed in matches an address in discovery block)
		return deviceAddress[matching index]
	else
launchDialog:
		LaunchAddressDialog
		Return device address chosen

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
currentAddressStr	char	IRLAP_CURRENT_LINK_ADDR
ResolveConnectionAddress	proc	near
		uses	ax,bx,dx,si,di,es,ds
		.enter
	;
	;(discoveryLogCount = 1) AND (address passed in = default string)
	;	return deviceAddress[0]
	;
		cmp	cx, 1
		jne	checkForNullLog

		segmov	es, cs, di
		mov	di, offset currentAddressStr
	;
	; es:di = current address string
	;
		push	cx		; save # of DiscoveryLog entries
		mov	ax, si		; save address offset
		mov	cx, IRLAP_CURRENT_ADDR_LEN
		repe	cmpsb
		mov	si, ax		; restore address offset
		pop	cx
		jne	checkForNullLog
	;
	; Return deviceAddress[0] if not connected yet,
	; or return current IS_destDevAddr if already connected
	;
		GetDgroup ds, di
		mov	ds, ds:[bx].IC_station
		test	ds:IS_status, mask ISS_SOCKET_LINK_OPEN
		jnz	linkAlreadyOpen
	;
	; Get the device address of discoveryLog[0]
	;
		mov	bx, ds:IS_discoveryLogBlock
		call	MemLock
		mov	es, ax
		mov	di, size DiscoveryLogBlock
		movdw	cxbp, es:[di].DL_devAddr
		call	MemUnlock
		clc
		jmp	done
linkAlreadyOpen:
		movdw	cxbp, ds:IS_destDevAddr
		clc
		jmp	done
checkForNullLog:
	;
	; bx	= client handle
	; cx	= number of discovery logs found
	; ds:si	= address passed in
	;
		GetDgroup es, di
		mov	es, es:[bx].IC_station		; es = IrlapStation
	;
	; If (discoveryLogCount = 0)
	;
		tst	cx
		jz	launchDialog
	;
	; Check for indefinite address character
	;
		cmp	{byte}ds:[si], IRLAP_INDEFINITE_ADDR_CHAR
		je	launchDialog
	;
	; Match the address passed in
	;
		push	bx
		mov	bx, es:IS_discoveryLogBlock
		mov	di, es
		call	MemLock
		mov	es, ax
		call	MatchAddressInDiscoveryLog	; cxbp = dev address
		mov	es, di				;        if matched
		pop	bx
		jc	launchDialog			; cxbp not changed
		jmp	done
launchDialog:
	;
	; es	= station
	; cx	= number of entries in discovery log
	; ds:si = address passed in
	;
		mov	bx, es:IS_clientHandle
		mov	di, IADT_CONNECTION
		call	LaunchAddressDialog		; dx = return value
		cmp	dx, IRLAP_ADDRESS_NOT_SELECTED
		je	done_C
		GetDgroup es, di
		mov	es, es:[bx].IC_station
		mov	di, IADT_CONNECTION
		mov	bx, es:IS_discoveryLogBlock
		call	MemLock
		mov	ds, ax
		mov	ax, size DiscoveryLog
		mul	dl
		add	ax, size DiscoveryLogBlock + offset DL_devAddr
			; ax = index * LogSz + header + offset to devAddr field
		mov	di, ax
		movdw	cxbp, ds:[di]			; cxbp = address to
							;        connect to 
		call	MemUnlock			; unlock log block
		clc	
done:
		.leave
		ret
done_C:
		stc
		jmp	done
ResolveConnectionAddress	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LaunchAddressDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launches a desired address dialog and returns the result

CALLED BY:	Utility
PASS:		bx	= client handle
		cx	= number of log entries
		di	= IrlapAddressDialogType
			  (IADT_CONNECTION, IADT_DATAGRAM)
		ds:si	= address passed in from the user
RETURN:		dx	= index of the selected addr or
			  IRLAP_ADDRESS_NOT_SELECTED
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LaunchAddressDialog	proc	near
		logEntryCount	local	word
		dialogType	local	IrlapAddressDialogType	; size = word
		originalAddress	local	fptr
		clientHandle	local	word
		uses	ax,bx,cx,si,di,bp,ds
		.enter
	;
	; Save parameters in local variables
	;
		mov	logEntryCount, cx
		mov	dialogType, di
		movdw	originalAddress, dssi
		mov	clientHandle, bx
		push	bp			; save bp
	;
	; Launch address dialog
	;
		mov	bx, handle ui
		mov	ax, bx			; ax = geode to own resource
		call	ProcInfo		;
		mov	cx, bx			; cx = thread handle = ui
		mov	bx, handle IrlapUI	; bx = resource to duplicate
		call	ObjDuplicateResource	; bx = duplicated resource
	;
	; Get UI application object
	;
		mov	cx, bx			; cx = duplicated resource
		mov	bx, ax			; bx = ui process
		call	GeodeGetAppObject	; ^lbx:si = appObject
	;
	; Attach the new object to ui
	; ^lbx:si = ui app object
	; ^lcx:dx = object to attach
	;
		mov	dx, offset IrlapAddressSelector
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, mask CCF_MARK_DIRTY
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; Initialize dialog
	;
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; Initialize the dialog according to our needs
	; bx = duplicated IrlapUI resource
	;
		pop	bp			; restore all local variables
		mov	di, clientHandle
		GetDgroup ds, ax
	;
	; MSG_IRLAP_SET_DIALOG_INFO
	;
		mov	cx, ds:[di].IC_station
		mov	dx, dialogType
		mov	di, mask MF_FIXUP_DS
		mov	ax, MSG_IRLAP_SET_DIALOG_INFO
		call	ObjMessage		; bp unchanged
	;
	; Set original address display in the dialog
	;
		movdw	cxdx, originalAddress
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		mov	ax, MSG_IRLAP_SET_ORIGINAL_ADDRESS
		call	ObjMessage		; bp unchanged
	;
	; Initialize IrlapAddressList
	;
		push	bp
		mov	cx, logEntryCount
		mov	si, offset IrlapAddressList
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	ObjMessage
	;
	; Initiate dialog
	;
		mov	si, offset IrlapAddressSelector
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessage
	;
	; Block until interaction complete
	;
		pop	bp
		mov_tr	di, bx
		mov	bx, clientHandle
		mov	bx, ds:[bx].IC_addrDialogBlockSem
		call	ThreadPSem			; ax = destroyed
		mov_tr	bx, di
	;
	; Remove dialog from UI
	;
		push	bp
		mov	ax, MSG_GEN_REMOVE
		mov	dl, VUM_NOW
		clr	di
		mov	di, mask MF_FIXUP_DS
		mov	bp, mask CCF_MARK_DIRTY
		call	ObjMessage
	;
	; Free the duplicated resource
	;
		mov	ax, MSG_META_BLOCK_FREE
		clr	di
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
	;
	; Get device address for the human readable address selected in dialog
	;
		mov	bx, clientHandle
		mov	ds, ds:[bx].IC_station
		mov	dx, ds:IS_selectedAddr
		.leave
		ret
LaunchAddressDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketResolveDatagramAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resolves the address in datagram and specifies a new address
		in the datagram if necessary
CALLED BY:	IrlapSocketSendDatagram
PASS:		es	= station segment
		ds:si	= datagram buffer containing
			[DatagramPacketHeader][IrlapDatagramInfo][???][data]
RETURN:		carry set if address has not been resolved
		carry clear if address has been resolved
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:

	if address passed in is 'default address',
		return carry clear
		; The datagram will be broadcasted

	if not in NDM
		goto checkAlias

	if no discoveryLogBlock and in NDM
		doDiscovery

checkAlias:

	if (address == indefinite address)
		goto launchDialog

	search for address passed in in the log
	if found, return carry clear

	if alias_key = addr passed in
		replace address with alias_value
		return carry clear
	else
launchDialog:
		Launch address dialog
		if address was chosen
		   replace address with address chosen
		   alias_key := address passed in
		   alias_value := new address chosen in address dialog if any
		   return carry clear
		else
		   return carry set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketResolveDatagramAddress	proc	near
		uses	ax,bx,cx,dx,bp,si,di,es,ds
		.enter
	;
	; Check for default address string
	;
                mov     dx, si                  ; dx = datagram packet offset
                clr     ah
                mov     al, ds:[si].DPH_addrOffset
                add     si, ax                  ; ds:si = address
                push    es, si
                segmov  es, cs, di
                mov     di, offset currentAddressStr
                mov     cx, IRLAP_CURRENT_ADDR_LEN
                repe    cmpsb
                pop     es, si
                je      success
	;
	; ds:si = address string
	; ds:dx = beginning of datagram buffer
	; es 	= station segment
	;

	;
	; If the station is not in NDM mode, go to CHECK_ALIAS
	;
		cmp	es:IS_state, IMS_NDM
		jne	checkAlias
	;
	; If there is no discovery log block already, get one
	;
		tst	es:IS_discoveryLogBlock
		jnz	checkAlias
		mov	bx, es:IS_clientHandle
		call	IrlapSocketDoDiscovery
			; cx	= number of discovery logs
			; es:IS_discoveryLogBlock = discoveryLogBlock
checkAlias:
	;
	; ds:si	= target address
	; ds:dx	= beginning of datagram buffer
	; es	= station segment
	;
		cmp	{byte}ds:[si], IRLAP_INDEFINITE_ADDR_CHAR
		je	launchDialog
	;
	; search for the address passed in in discovery log block
	; if found, return carry clear
	;
		mov	bx, es:IS_discoveryLogBlock
		tst	bx
		jz	success	; send datagram to the user specified addr
		push	dx, es
		call	MemLock
		mov	es, ax
		call	MatchAddressInDiscoveryLog
			; carry clear if address found
			;   dx	= index to the item found
			;   cxbp= dev address if address was found
			; carry set if address not found
		call	MemUnlock
		pop	dx, es
		jnc	done
	;
	; ds:si	= target address
	; ds:dx	= beginning of datagram buffer
	; es	= station segment
	;
	; If alias_key = address passed in,
	; replace address with alias_value
	;
		clr	cx
		mov	di, offset IS_addressAlias + offset IAA_key

		SBCompareStrings

		jne	launchDialog
	;
	; Replace the address in datagram
	;
		segxchg	ds, es
		mov	di, dx		; es:di = datagram buffer
		mov	si, offset IS_addressAlias + offset IAA_value
					; ds:si = new address( alias value )
		mov	es:[di].DPH_addrOffset,\
			offset IDH_info + offset IDI_userAddr
		add	di, offset IDH_info + offset IDI_userAddr
		mov	cx, IRLAP_ADDRESS_LEN
		push	di
		rep	movsb
		pop	di

		SBStringLength			; cx = new address size

		sub	di, offset IDH_info + offset IDI_userAddr
		mov	es:[di].DPH_addrSize, cl
		jmp	success
launchDialog:
	;
	; ds:si	= target address
	; ds:dx	= beginning of datagram buffer
	; es	= station segment
	;
	; Launch address dialog
	;
		mov	bp, es:IS_clientHandle
		mov	bx, es:IS_discoveryLogBlock
		push	dx, es
		call	MemLock
		mov	es, ax
		clr	ch
		mov	cl, es:DLB_lastIndex	; cx = number of logs received
		call	MemUnlock
		mov	di, IADT_DATAGRAM
		xchg	bx, bp			; bx = client handle
		call	LaunchAddressDialog	; dx = index to selected addr
		xchg	bx, bp
		cmp	dx, IRLAP_ADDRESS_NOT_SELECTED
		pop	bx, es
		je	done_C
		call	ReplaceDatagramAddress
		call	SetupDatagramAlias
success:
		clc
done:
		.leave
		ret
done_C:
		stc
		jmp	done
		
IrlapSocketResolveDatagramAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceDatagramAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the address within a datagram packet with an entry
		in discoveryLogBlock
CALLED BY:	IrlapSocketResolceDatagramAddress
PASS:		es	= station segment
		dx	= index entry for the selected item within
			  discovery log block
		ds:bx	= datagram packet
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/26/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceDatagramAddress	proc	near
		uses	ax,bx,cx,dx,si,di,ds,es
		.enter

		segxchg	es, ds
		mov_tr	di, bx			; es:di = datagram packet
		mov	es:[di].DPH_addrOffset,\
			offset IDH_info + offset IDI_userAddr
		add	di, offset IDH_info + offset IDI_userAddr
		mov	bx, ds:IS_discoveryLogBlock
		call	MemLock
		mov	ds, ax
		mov	si, size DiscoveryLogBlock + offset DL_info
		mov	ax, size DiscoveryLog
		mul	dl
		add	si, ax			; ds:si = info field
		mov	cx, IRLAP_ADDRESS_LEN
		push	di
		rep	movsb
		pop	di			; es:di = address string

		SBStringLength			; cx = address size

		call	MemUnlock
	;
	; Store address size
	;
		sub	di, offset IDH_info + offset IDI_userAddr
		mov	es:[di].DPH_addrSize, cl
		.leave
		ret
ReplaceDatagramAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupDatagramAlias
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the address passed in from the user as datagram alias
		key and the address selected in discovery log block as
		alias value.
CALLED BY:	IrlapSocketResolveDatagramAddress
PASS:		es	= station segment
		dx	= index entry for the selected item within
			  discovery log block
		ds:bx	= datagram packet
		ds:si	= addres passed in
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupDatagramAlias	proc	near
		uses	ax,bx,cx,ds,si,di
		.enter
	;
	; copy alias key
	;
		mov	di, offset IS_addressAlias + offset IAA_key
		mov	cx, IRLAP_ADDRESS_LEN
		rep	movsb
	;
	; copy alias value
	;
		mov	bx, es:IS_discoveryLogBlock
		call	MemLock
		mov	ds, ax
		mov	si, size DiscoveryLogBlock + offset DL_info
		mov	ax, size DiscoveryLog
		mul	dl
		add	si, ax		; ds:si = address chosen
		mov	di, offset IS_addressAlias + offset IAA_value
		mov	cx, IRLAP_ADDRESS_LEN
		rep	movsb
		call	MemUnlock
		.leave
		ret
SetupDatagramAlias	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IADIrlapSetStationInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the callback routine to commnucate with IrlapDriver

CALLED BY:	MSG_IRLAP_SET_CALL_BACK
PASS:		ds:di	= IrlapAddressDialogClass instance data
		cx	= irlap station segment
		dx	= IrlapAddressDialogType
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddressDialogPurposeTable	nptr \
	offset	irlapConnectionAddressDialog,
	offset	irlapDatagramAddressDialog
IADIrlapSetStationInfo	method dynamic IrlapAddressDialogClass, 
		MSG_IRLAP_SET_DIALOG_INFO
		uses	es, bp
		.enter
		mov	es, cx
		movm	ds:[di].IADI_client, es:IS_clientHandle, ax
		mov	ds:[di].IADI_irlapStation, cx
		movm	ds:[di].IADI_discoveryLogs, es:IS_discoveryLogBlock, ax
		mov	ds:[di].IADI_selection, IRLAP_ADDRESS_NOT_SELECTED
	;
	; Set appropriate moniker for IrlapAddressDialogPurpose
	;
		mov	di, dx
		mov	di, cs:[AddressDialogPurposeTable][di]
		mov	bx, handle IrlapStrings
		call	MemLock
		mov	es, ax
		mov	cx, ax
		mov	dx, es:[di]
		mov	bp, VUM_MANUAL
		mov	si, offset IrlapAddressDialogPurpose
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		call	ObjCallInstanceNoLock		; ax destroyed
		call	MemUnlock
		
		.leave
		ret
IADIrlapSetStationInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IADIrlapSetOriginalAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the original address display in address dialog

CALLED BY:	MSG_IRLAP_SET_ORIGINAL_ADDRESS
PASS:		ds:di	= IrlapAddressDialogClass instance data
		cxdx	= fptr to original address
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IADIrlapSetOriginalAddress	method dynamic IrlapAddressDialogClass, 
					MSG_IRLAP_SET_ORIGINAL_ADDRESS
		uses	ax, cx, dx, bp
		.enter
	;
	; Replace string in OriginalAddress with the one passed in
	;
		mov_tr	bp, dx
		mov_tr	dx, cx				; dxbp = address
		clr	cx				; null terminated
		mov	si, offset OriginalAddress
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock
		
		.leave
		ret
IADIrlapSetOriginalAddress	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IADIrlapSetAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current address as the one passed in

CALLED BY:	MSG_IRLAP_SET_ADDRESS
PASS:		ds:di	= IrlapAddressDialogClass instance data
		cx	= index of address
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IADIrlapSetAddress	method dynamic IrlapAddressDialogClass, 
					MSG_IRLAP_SET_ADDRESS
		mov	ds:[di].IADI_selection, cx
	;
	; Enable connect button
	;
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_ENABLED	; enable the user to connect
		mov	si, offset SelectButton
		call	ObjCallInstanceNoLock
		ret
IADIrlapSetAddress	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IADIrlapGetAddressStr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent by genDynamicList to get moniker for its items

CALLED BY:	MSG_IRLAP_GET_ADDRESS_STR
PASS:		*ds:si	= IrlapAddressDialogClass object
		ds:di	= IrlapAddressDialogClass instance data
		bp	= item index( for new moniker )
RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IADIrlapGetAddressStr	method dynamic IrlapAddressDialogClass, 
					MSG_IRLAP_GET_ADDRESS_STR
		.enter
	;
	; find the appropriate address string in IDAI_discoveryLogs
	;
		mov	bx, ds:[di].IADI_discoveryLogs
		call	MemLock
		mov	cx, ax
		mov	ax, size DiscoveryLog
		mov	dx, bp
		mul	dl				; index * elt size
		add	ax, size DiscoveryLogBlock + offset DL_info
			; ax = index * LogSz + header + offset to info field
		mov_tr	dx, ax
	;
	; Send a message to genDynamicList
	; cxdx = address string
	;
		mov	si, offset IrlapAddressList
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjCallInstanceNoLock
		call	MemUnlock			; unlock log block

		.leave
		ret
IADIrlapGetAddressStr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IADIrlapDoDiscovery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do discovery again.

CALLED BY:	MSG_IRLAP_DO_DISCOVERY
PASS:		*ds:si	= IrlapAddressDialogClass object
		ds:di	= IrlapAddressDialogClass instance data
		ds:bx	= IrlapAddressDialogClass object (same as *ds:si)
		es 	= segment of IrlapAddressDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	all but es, ds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IADIrlapDoDiscovery	method dynamic IrlapAddressDialogClass, 
					MSG_IRLAP_DO_DISCOVERY
		uses	ax, cx, dx, bp
		.enter
	;
	; Disable select button
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		mov	si, offset SelectButton
		call	ObjCallInstanceNoLock
	;
	; Do discovery again
	;
		mov	bx, ds:[di].IADI_client
		call	IrlapSocketDoDiscovery	; cx = # of discovered addrs
		segmov	es, ds:[di].IADI_irlapStation, ax
		movm	ds:[di].IADI_discoveryLogs, es:IS_discoveryLogBlock, ax
		mov	ds:[di].IADI_selection, IRLAP_ADDRESS_NOT_SELECTED
	;
	; Reinitialize address list
	;
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	si, offset IrlapAddressList
		call	ObjCallInstanceNoLock
		
		.leave
		ret
IADIrlapDoDiscovery	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IADGenGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept this message and send appropriate notification to
		Irlap driver before this dialog closes

CALLED BY:	MSG_GEN_GUP_INTERACTION_COMMAND
PASS:		*ds:si	= IrlapAddressDialogClass object
		ds:di	= IrlapAddressDialogClass instance data
		ds:bx	= IrlapAddressDialogClass object (same as *ds:si)
		es 	= segment of IrlapAddressDialogClass
		ax	= message #
		cx	= InteractionCommand
RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IADGenGupInteractionCommand	method dynamic IrlapAddressDialogClass, 
					MSG_GEN_GUP_INTERACTION_COMMAND
		.enter
	;
	; Callsuper
	;
		mov_tr	dx, di
		mov	di, offset IrlapAddressDialogClass
		call	ObjCallSuperNoLock
		mov_tr	di, dx
		pushf
	;
	; Call the IRLAP's callback routine to send selected address 
	;
		mov	bp, ds:[di].IADI_selection
		cmp	cx, IC_YES			; continue normally
		je	continue
		cmp	cx, IC_NO
		jne	done
		mov	bp, IRLAP_ADDRESS_NOT_SELECTED	; cancel connection
continue:
	;
	; Send a message to irlap station to set address selected in
	; IrlapAddressDialog
	;
		mov	si, ds:[di].IADI_irlapStation
		mov	es, si
		mov	es:IS_selectedAddr, bp
		mov	bx, es:IS_eventThreadHandle
		mov	ah, ILE_CONTROL
		mov	al, IDC_ADDRESS_SELECTED
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		popf
		.leave
		ret
IADGenGupInteractionCommand	endm


IrlapCommonCode	ends

IrlapActionCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketGetInfoReal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about our domain

CALLED BY:	IrlapSocketGetInfo
PASS:		ax	= SocketGetInfoType
		rest	= depends on each type
	Other paramters for each SocketGetInfoType
	  Flags are destroyed in all functions
	  SGIT_MEDIA_LIST:
		Pass: 	*ds:si	= chunk array to be filled with MediumType
				  (chunk array MUST be empty)
		Return: *ds:si 	= chunk array of MediumType

	  SGIT_MEDIUM_AND_UNIT:
		Pass: 	ds:si	= non-null terminated address string 
			dx	= address size 
		Return:	cxdx	= MediumType
			bl	= MediumUnitType
			bp	= MediumUnit

	  SGIT_LOCAL_ADDR: 
	  SGIT_REMOTE_ADDR:
		Pass:	cx	= connection handle (or 0 if connectionless)
				  MUST be non-zero for SGIT_REMOTE_ADDR
			ds:bx	= buffer for address
		Return: ds:bx	= buffer filled w/non-null terminated addr
				  string
			ax	= address size

	  SGIT_ADDR_SIZE:
	  SGIT_MTU:
		Pass: no other paramters
		Return: ax	= value

	  SGIT_ADDR_CTRL:
		Pass:	dx	= medium
		Return:	carry set if error
			else
			cx:dx	= pointer to class
	  SGIT_PREF_CTRL:
		Pass:	nothing
		Return: carry set on error
			else
			cx:dx	= pointer to class
	DESTROYS: ax if not holding a value

RETURN:		varies
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetInfoRoutine	macro	routine, getinfoType
		.assert	($-IrlapSocketGetInfoTable) eq getinfoType, \
			<function table is corrupted>
		.assert (type routine eq near)		
		nptr	routine
endm

IrlapSocketGetInfoTable	label	nptr
GetInfoRoutine	IrlapSocketMediaList, SGIT_MEDIA_LIST
GetInfoRoutine	IrlapSocketMediumAndUnit, SGIT_MEDIUM_AND_UNIT
GetInfoRoutine	IrlapSocketAddrCtrl, SGIT_ADDR_CTRL
GetInfoRoutine	IrlapSocketAddrSize, SGIT_ADDR_SIZE
GetInfoRoutine	IrlapSocketLocalAddr, SGIT_LOCAL_ADDR
GetInfoRoutine	IrlapSocketRemoteAddr, SGIT_REMOTE_ADDR
GetInfoRoutine	IrlapSocketMtu, SGIT_MTU
GetInfoRoutine	IrlapSocketPrefCtrl, SGIT_PREF_CTRL
GetInfoRoutine	IrlapSocketMediumConnection, SGIT_MEDIUM_CONNECTION
GetInfoRoutine	IrlapSocketMediumLocalAddr, SGIT_MEDIUM_LOCAL_ADDR

.assert ($-IrlapSocketGetInfoTable) eq SocketGetInfoType, \
	<missing some function(s)>
	
IrlapSocketGetInfoReal	proc	far
	;
	; Look up the table and call the appropriate function
	;
		xchg	ax, bx
		push	ax
		mov	ax, cs:[IrlapSocketGetInfoTable][bx]
		pop	bx
		call	ax
		ret
IrlapSocketGetInfoReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketMediaList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a list of available media

CALLED BY:	SGIT_MEDIA_LIST
PASS:		*ds:si = chunk array to be filled in
RETURN:		*ds:si = chunk array filled in
DESTROYED:	flags

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketMediaList	proc	near
		uses	ax,bx,cx,dx,di,bp
		.enter
		clr	bx				; first entry
makeList:
		call	ChunkArrayAppend		; ds:di = new element
		jc	exit
		
		mov	ax, cs:mediaTable[bx]
		mov	ds:[di].MET_id, ax
		mov	ds:[di].MET_manuf, MANUFACTURER_ID_GEOWORKS
		
		inc	bx	
		inc	bx
		cmp	bx, size mediaTable
		jb	makeList
		clc
exit:
		.leave
		ret
IrlapSocketMediaList	endp

mediaTable	word \
	GMID_INFRARED


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketMediumAndUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the medium associated with the address
		If nobody is registered with us currently, we can't provide
		this information.

CALLED BY:	SGIT_MEDIUM_AND_UNIT
PASS:		ds:si	= none null terminated address string
		dx	= address size
RETURN:		cxdx	= MediumType
		bl	= MediumUnitType
		bp	= MediumUnit
DESTROYED:	flags
ALGORITHM:
	If somebody is registered with us
		return the medium type currently being used
	else
		return nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketMediumAndUnit	proc	near
		uses	ax,si,di,es,ds
		.enter
	;
	; Is anybody registered with us?
	;
		GetDgroup es, bx
		call	IrlapFindSocketClient	; es:si = IrlapClient struct
		jc	notFound
	;
	; We found the socket library client
	; return medium type and unit it is currently using
	;
		mov	ax, es:[si].IC_station
		mov	ds, ax
		mov	bx, ds:IS_serialPort
		clr	cx				; cx <- get primary
							;  medium
		mov	di, DR_SERIAL_GET_MEDIUM
		call	{fptr.far}es:serialStrategy	; dxax = medium type
		jc	notFound			; STREAM_NO_DEVICE
		mov_tr	cx, dx
		mov_tr	dx, ax
		mov	bl, MUT_INT
		mov	bp, ds:IS_serialPort
done:
		.leave
		ret
notFound:
	;
	; Return invalid result
	;
		mov	cx, GMID_INVALID
		mov	dx, MANUFACTURER_ID_GEOWORKS
		jmp	done
IrlapSocketMediumAndUnit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketMediumConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if this driver is connected over the MediumAndUnit
		specified.  If so, return address of connection.

CALLED BY:	SGIT_MEDIUM_CONNECTION
PASS:		dx:bx	= MediumAndUnit
		ds:si	= address buffer
		cx	= buffer size in bytes
RETURN: 	carry set if no connection is established over the
			unit of the medium.
		else
		ds:si	= filled in with address, up to value passed
			  in as buffer size.
		cx	= actual size of address in ds:si.  If cx
			  is greater than the buffer size that was
			  passed in, then address in ds:si is 
			  incomplete.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (connected) and (unit = current port)
		check current port for medium( call to serialDr )
		if they match what passed in,
			return remote address( null or else )
		else
			return error
	else
		return error

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketMediumConnection	proc	near
mediumAndUnit	local	fptr.MediumAndUnit	push dx, bx
addrBuf		local	fptr			push ds, si
bufSize		local	word			push cx
remoteAddress	local	IrlapUserAddress
		uses 	ds,si,es,di,ax,bx
		.enter
	;
	; Is anybody registered with us?  If not, then we can't be 
	; connected.
	;
		GetDgroup es, bx
		call	IrlapFindSocketClient	;es:si = IrlapClient struct
		jc	exit
	;
	; Check if we are connected, by checking IS_status for
	; ISS_SOCKET_LINK_OPEN.
	;
		mov	ax, es:[si].IC_station
		mov	ds, ax			;ds:0 = IrlapStation
		test	ds:[IS_status], mask ISS_SOCKET_LINK_OPEN
		jz	notConnected
	;
	; Check if the port number matches.
	;
		mov	ax, ds:[IS_serialPort]	;ax = SerialPortNum
		lds	di, mediumAndUnit	;ds:di = MediumAndUnit
EC <		cmp	ds:[di].MU_unitType, MUT_INT		>
EC <		ERROR_NE IRLAP_INVALID_MEDIUM_TYPE		>
		cmp	ax, ds:[di].MU_unit
		jne	unitMismatch
	;
	; Get the medium of the port
	;
		push	di
		mov	di, DR_SERIAL_GET_MEDIUM
		clr	cx			;primary medium
		mov	bx, ax			;bx = SerialPortNum
		call	es:[serialStrategy]	;dxax = MediumType
		pop	di			;ds:di = MediumAndUnit 
						;   passed in.
		jc	mediumNotFound
	;
	; Check if the medium for the port matches the medium that was
	; passed in.
	;
		cmpdw	ds:[di].MU_medium, dxax
		jne	mediumMismatch
	;
	; At this point we established that there is a connection over
	; the specified medium and unit.  Return the connection address.
	;
		mov	ax, es:[si].IC_station
		mov	ds, ax			;ds:0 = IrlapStation
		mov	cx, ds:[IS_clientHandle];connection handle
		segmov	ds, ss, bx
		lea	bx, ss:[remoteAddress]
		call	IrlapSocketRemoteAddr	;ax = addressSize
		xchg	ax, ss:[bufSize]
		mov	cx, ax			;cx = size of addrBuf
		cmp	cx, ss:[bufSize]	;use the smaller of either the
						; address size or the buffer 
						; size.
		jle	gotSize
		mov	cx, ss:[bufSize]
gotSize:
		les	di, addrBuf
		mov	si, bx			;ds:si = remoteAddress
		rep	movsb
		mov	cx, ss:[bufSize]	;return actual addr. size
		clc
exit:
		.leave
		ret

mediumMismatch:
mediumNotFound:
unitMismatch:
notConnected:
		stc
		jmp	exit
	
IrlapSocketMediumConnection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketAddrCtrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns an address controller

CALLED BY:	SGIT_ADDR_CTRL
PASS:		dx	= medium
RETURN:		carry set if error
		else
			cx:dx = pointer to class
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketAddrCtrl	proc	near
		uses	bx
		.enter
		mov	bx, handle 0
		call	GeodeAddReference
		mov	cx, segment IrlapAddressControlClass
		mov	dx, offset IrlapAddressControlClass
		clc
		.leave
		ret
IrlapSocketAddrCtrl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketAddrSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the significant digit for the address strings

CALLED BY:	SGIT_ADDR_CTRL
PASS:		nothing
RETURN:		ax	= value
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketAddrSize	proc	near
		.enter
		mov	ax, IRLAP_ADDRESS_LEN
		.leave
		ret
IrlapSocketAddrSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketLocalAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the address of the local side

CALLED BY:	SGIT_LOCAL_ADDR
PASS:		cx	= connection handle
		ds:bx	= buffer for address
RETURN:		ds:bx	= filled in with non null terminated addr string
		ax	= address size
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketLocalAddr	proc	near
		uses	bx,cx,dx,si,di,es
		.enter
		GetDgroup es, ax
		mov_tr	di, cx
		mov	cx, es:[di].IC_station
		mov	es, cx
		segxchg	es, ds
		mov	si, IS_userAddress
		mov	di, bx
		mov	cx, IRLAP_ADDRESS_LEN
		push	di
		rep	movsb
		pop	di

		SBStringLength		  ; cx = address length without NULL

		segmov	ds, es		  ; es:bx = address string stored
		mov_tr	ax, cx		  ; ax = address length
		.leave
		ret
IrlapSocketLocalAddr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketRemoteAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the address of remote side

CALLED BY:	SGIT_REMOTE_ADDR
PASS:		cx	= connection handle
		ds:bx	= buffer for address
RETURN:		ds:bx	= filled in with non null terminated addr string
		ax	= address size
DESTROYED:	nothing
ALGORITHM:
	If not connected, we return 0
	Else
	   Look find the address string in discovery log block using
	   IS_chosenIndex
	   Copy the address

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketRemoteAddr	proc	near
		uses	bx,cx,dx,si,di,es
		.enter
	;
	; Check if connected
	;
		GetDgroup es, ax
		mov_tr	di, cx
		mov	cx, es:[di].IC_station
		mov	es, cx
	;
	; Copy remote address
	;
		mov	dx, es:IS_chosenIndex
		push	bx
		mov	bx, es:IS_discoveryLogBlock
		call	MemLock
		mov	es, ax
		mov	si, size DiscoveryLogBlock + DL_info
		mov	ax, size DiscoveryLog
		mul	dl
		add	si, ax
		segxchg	ds, es			; ds:si = remote address
		pop	di			; es:di = buffer to fill
		mov	cx, IRLAP_ADDRESS_LEN
		mov_tr	dx, di
		rep	movsb
		mov_tr	di, dx

		SBStringLength			; cx = address size w/out NULL

		call	MemUnlock		; unlock disoveryLogBlock
		segmov	ds, es, ax		; restore buffer seg
		mov_tr	ax, cx
		.leave
		ret
IrlapSocketRemoteAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketMtu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the maximum transmission unit size
		( IrLAP does not provide this since the value varies from
		  connection to connection )

CALLED BY:	SGIT_MTU
PASS:		nothing
RETURN:		ax	= value
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketMtu	proc	near
EC <		WARNING	_IRLAP_DOES_NOT_PROVIDE_MTU_INFO		>
		ret
IrlapSocketMtu	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketPrefCtrl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a controller for IrLAP preference custom UI

CALLED BY:	SGIT_PREF_CTRL
PASS:		nothing
RETURN:		cx:dx	= irlap pref control class
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketPrefCtrl	proc	near
		.enter
ife	NO_PREFERENCES_APPLICATION
		mov	cx, segment IrlapPreferenceControlClass
		mov	dx, offset IrlapPreferenceControlClass
else
		clr	cx, dx
endif
		clc
		.leave
		ret
IrlapSocketPrefCtrl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapSocketMediumLocalAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the local address of the connection on a medium

CALLED BY:	SGIT_MEDIUM_LOCAL_ADDR
PASS:		ds:bx	= MediumAndUnit
		ds:si	= address buffer
		cx	= buffer size in bytes
RETURN:		carry set if no connection
		else
		  ds:si = filled in with local address, up to buffer size
		  cx	= actual size of address before truncation
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	NOT IMPLEMENTED

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	11/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapSocketMediumLocalAddr	proc	near
		PrintMessage <IrlapSocketMediumLocalAddr not implemented>
		stc
		ret
IrlapSocketMediumLocalAddr	endp

IrlapActionCode		ends
