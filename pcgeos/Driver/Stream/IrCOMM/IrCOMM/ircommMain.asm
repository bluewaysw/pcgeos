COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		IrCOMM
FILE:		ircommMain.asm

AUTHOR:		Greg Grisco, Dec  4, 1995

ROUTINES:
	Name				Description
	----				-----------
EXT	IrCommConnectRequest		Connection request from client
EXT	IrCommConnectResponse		Client ack of host's connect indication
EXT	IrCommDataRequest		Client wants to send data
EXT	IrCommControlRequest		Change in control parameters
EXT	IrCommDisconnectRequest		Client requests a disconnect

EXT	IrCommStatusRequest		Request status connection
EXT	IrCommAdvanceTTPCredit		Advance credit with data-less PDU

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/ 4/95   	Initial revision


DESCRIPTION:
	IrCOMM API code
		

	The IrCOMM frame format looks like this:


|<------------------------------ packet data size -------------->|
|                                                                |
|<---4 bytes-->|<---- 1 --->|               |<----- variable --->|

+--------------+------------+---------------+--------------------+
| IRLMP HEADER | TTP Header |    Control    |      UserData      |
+--------------+------------+---------------+--------------------+
                           /                 \
                          /                   \
                         /                     \
                       +------+------------------+
                       | Clen |      CValue      |
                       +------+------------------+

                       |<--1->|<--- variable --->|


The IrLMP & TinyTP headers are left blank, to be filled in by Irlmp &
TinyTP.

Clen is the length of the control value and may be 0.  CValue is any
number of 3-tuples (Parameter ID, Parameter Length, and Parameter
Value) as defined in ircomm.def

The UserData makes up the rest of the packet and may also be 0 bytes.


	$Id: ircommMain.asm,v 1.1 97/04/18 11:46:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

connectionSem	Semaphore <0>		; place to block waiting for connect
statusSem	Semaphore <0>		; place to block waiting for status

connStatus	ConnectionStatus	; used for checking buffers when 
					; closing down

idata	ends



IrCommAPICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommConnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establishes a connection with the peer IrCOMM

CALLED BY:	EXTERNAL
PASS:		si	= IAS client to disconnect and unregister after 
			  connect
		di	= unit index
		cxdx	= IrlmpConnectArgs
RETURN:		carry clear if ok
			ax	= destroyed
		carry set on error
			ax	= STREAM_NO_DEVICE
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	This routine is being called as a result of the client wanting
	to open a stream.  A connection needs to be established before
	any data can be transferred.

	Call TTP_Connect.Request with the following parameters encoded:
		Service Type (if not "Default")
		Port Communication Settings
		Initial Line Settings (DTE or DCE)

	Change the state from IDLE to WAITI

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommConnectRequest	proc	far
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter

	push	si

	call	IrCommGetDGroupDS		; ds = dgroup
	mov	si, ds:[di].ISPD_client		; TinyTP client

if ERROR_CHECK
	;
	; We should be in the IDLE state
	;
	cmp	ds:[di].ISPD_state, ICFS_IDLE
	ERROR_NE	IRCOMM_ILLEGAL_STATE
endif
	;
	; Allocate a HugeLMem block and encode all of the correct
	; parameters.
	;
	push	cx, dx

	mov	ax, TTP_HEADER_SIZE + CONTROL_LENGTH_SIZE
	mov	es, cx
	mov	bx, dx				; es:bx = IrlmpConnectArgs
	mov	es:[bx].ICA_dataSize, 1		; just the control length
	mov	es:[bx].ICA_dataOffset, TTP_HEADER_SIZE	
	mov	cx, FOREVER_WAIT
	push	bx, di
	mov	bx, es:[bx].ICA_data.high	; bx = HugeLMem handle
	call	HugeLMemAllocLock		; ^lax:cx = block
						;  ds:di = buffer
	mov	{byte} ds:[di+TTP_HEADER_SIZE], 0 ; clen = 0

	mov	bx, ax				; ^hbx = HugeLMem block
	call	HugeLMemUnlock			; Irlmp will lock it...

	pop	bx, di				; di = unit number
	movdw	es:[bx].ICA_data, axcx

	pop	cx, dx				; cx:dx = IrlmpConnectArgs

;	jc	disconnectIAS			; not enough memory?

	call	IrCommGetDGroupDS		; ds = dgroup
EC <	push	bx							>
EC <	mov	bx, di							>
EC <	call	ECValidateUnitNumber					>
EC <	pop	bx							>
	mov	ds:[di].ISPD_state, ICFS_WAITI

	call	TTPConnectRequest		; request the connection
	jc	requestFailed

	PSem	ds, connectionSem, TRASH_BX	; wait til we get confirmation

	cmp	ds:[di].ISPD_state, ICFS_CONN
	clc
	je	disconnectIAS			; jump if connected

	;
	; This matches the call to TTPRegister in IrCommOpen->CheckConnection
	;
	clr	ds:[di].ISPD_client
	mov	ds:[di].ISPD_state, ICFS_IDLE
	call	TTPUnregister

	mov	ax, STREAM_NO_DEVICE
	stc

disconnectIAS:
	;
	; This matches the calls to IrlmpRegister and IrlmpGetValueByClass
	; in PortEmulatorGetLSAP
	;
	pop	si
	pushf
	call	IrlmpDisconnectIas
	call	IrlmpUnregister
	popf

	.leave
	ret
requestFailed:
	;
	; Someone has to free the HugeLMem block...
	;
	movdw	esdi, cxdx
	movdw	axcx, es:[di].ICA_data
	call	HugeLMemFree
	jmp	disconnectIAS
IrCommConnectRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommDataRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request by client to send data.  The data is already
		in a HugeLMem chunk.  Just set up the IrlmpDataArgs
		and call TinyTP_Data.Request.

CALLED BY:	EXTERNAL (PortEmulatorSend)
PASS:		di	= unit index
		^laxcx	= HugeLMem chunk
		dx	= size of userdata
RETURN:		carry clear if ok
			ax = destroyed
		carry set on error
			ax = STREAM_CLOSED
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommDataRequest	proc	far
	uses	cx,dx,si,bp,ds
	.enter

	call	IrCommGetDGroupDS		; ds = dgroup

	sub	sp, size IrlmpDataArgs
	mov	bp, sp

	mov	ss:[bp].IDA_dataSize, dx
	mov	ss:[bp].IDA_dataOffset, TTP_HEADER_SIZE
	movdw	ss:[bp].IDA_data, axcx

	mov	cx, ss
	mov	dx, bp				; cx:dx = IrlmpDataArgs
	mov	si, ds:[di].ISPD_client		; TinyTP client handle
	;
	; Loop until TinyTP can handle our request before sending the
	; data.
	;
	push	cx				; save data args segment
loopTop:
	call	TTPTxQueueGetFreeCount		; cx=buffers TTP will accept
	jcxz	loopTop				; loop if none free
	;
	; Send the data.  If the connection has been lost, discard the
	; data by freeing the block.
	;
	pop	cx				; cx:dx = IrlmpDataArgs
	call	TTPDataRequest			; send the data
EC <	WARNING_C	IRCOMM_DATA_LOST				>
	jc	discard
done:
	mov	cx, ax
	lahf
	add	sp, size IrlmpDataArgs
	sahf
	mov	ax, cx				; ax = return val if any

	.leave
	ret
discard:
	mov_tr	ds, cx
	mov_tr	si, dx
	tst	ds:[si].IDA_dataSize
	jz	error				; no data to discard
	movdw	axcx, ds:[si].IDA_data		; ^lax:cx = HugeLMem chunk
	call	HugeLMemFree
error:
	stc
	mov	ax, STREAM_CLOSED
	jmp	done
IrCommDataRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommControlRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a single setting through the control channel.

CALLED BY:	EXTERNAL
PASS:		di	= unit index
		ax	= virtual segment of movable stream data
		cxdx	= IrlmpDataArgs
		ss:bp	= Control length and list of Control 3-tuples
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Allocate a new HugeLMem block
	Write the correct headers and copy the control 3-tuple
	If there is a data block sitting around, move that data to new block
	Check TinyTP to see if we can send a block, sending if possible

NOTES:
	THIS ROUTINE WILL NOT BE USED SINCE AN ENCODED CONTROL
	PARAMETER WILL BE WRITTEN TO THE STREAM AND EVENTUALLY SENT BY
	A DATA REQUEST.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommControlRequest	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	.leave
	ret
IrCommControlRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommDisconnectRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Client wishes to disconnect.  Send a
		TinyTP_Disconnect.Request

CALLED BY:	EXTERNAL (PortEmulatorDisconnect)
PASS:		di	= unit index
		bl	= IrlmpDisconnectReason
		ds	= dgroup
RETURN:		carry set on error
			ax	= IrlmpError
		carry clear if ok
			ax	= IE_SUCCESS
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
	Userdata is any string up to 60 bytes and is optional

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommDisconnectRequest	proc	far
	uses	cx,dx,si,di,bp
	.enter

EC <	push	bx							>
EC <	mov	bx, di							>
EC <	call	ECValidateUnitNumber					>
EC <	pop	bx							>
	;
	; Simply send the request to TinyTP
	;
	mov	si, ds:[di].ISPD_client		; si = TinyTP client handle

	sub	sp, size IrlmpDataArgs
	mov	cx, ss
	mov	dx, sp				; cx:dx = IrlmpDataArgs
	mov	bp, sp

	mov	ss:[bp].IDA_dataSize, 0

	call	TTPDisconnectRequest
EC <	ERROR_C	-1							>

	mov	ds:[di].ISPD_state, ICFS_IDLE

	lahf
	add	sp, size IrlmpDataArgs
	sahf

	.leave
	ret
IrCommDisconnectRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommStatusRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call TinyTP for the current connection status

CALLED BY:	EXTERNAL (PortEmulatorDestroyStreams)
PASS:		si	= client handle
		ds	= dgroup
RETURN:		carry set if unacked data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	1/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommStatusRequest	proc	far
	.enter

	call	TTPStatusRequest
	cmc					; carry clear if no connection
	jnc	noData				; don't wait for status

	PSem	ds, statusSem

	test	ds:[connStatus], mask CS_UNACKED_DATA
	jz	noData				; carry clear if no data

	stc
noData:
	.leave
	ret
IrCommStatusRequest	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrCommAdvanceTTPCredit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance a TTP credit.  The credit may be sent right
		away in a dataless-PDU, or perhaps accumulated with
		other advanced credits and eventually packaged with
		Userdata, depending on the TinyTP implementation.

CALLED BY:	EXTERNAL
PASS:		bx	= unit number
		cx	= # of credits to advance
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	2/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrCommAdvanceTTPCredit	proc	far
	uses	si,ds
	.enter

EC <	call	ECValidateUnitNumber					>
	call	IrCommGetDGroupDS		; ds = dgroup

	mov	si, ds:[bx].ISPD_client
	call	TTPAdvanceCredit

	.leave
	ret
IrCommAdvanceTTPCredit	endp


IrCommAPICode	ends
