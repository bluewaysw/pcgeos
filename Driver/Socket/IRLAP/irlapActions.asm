COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		irlapActions.asm

AUTHOR:		Cody Kwok, May  6, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/ 6/94   	Initial revision


DESCRIPTION:
	Define most of the info xfer actions in primary and secondary state
	machines.
		
	$Id: irlapActions.asm,v 1.1 97/04/18 11:56:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;; all these routines can mess with ax, bx, es, di.  Don't touch cx
;; which should contain the header of the packet, nor ds, which is the
;; station.  Preferrable don't trash dx, bp which has the optr to packet

IrlapActionCode	segment	resource

; **************************************************************************
; **************************************************************************
; *******************    Connection-related Actions    *********************
; **************************************************************************
; **************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocQOSBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a hugelmem buffer for QOS

CALLED BY:	IrlapNativeConnectRequest
PASS:		ds:si	= QualityOfService structure
		es	= IrLAP station segment
RETURN:		carry clear if buffer allocated
			cxbp	= hugeLMem buffer that contains a copy of ds:si
		carry set if not
			cxbp 	= destroyed
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocQOSBuffer	proc	far
		uses	ax,bx,dx,si,di,es
		.enter
		push	ds
		mov	ax, size QualityOfService
		mov	bx, es:IS_hugeLMemHandle
		mov	cx, NO_WAIT
		call	HugeLMemAllocLock	; ds:di,^lax:cx = buffer
		segmov	es, ds, bx
		pop	ds
		jc	done
		mov	bx, cx
		mov	cx, size QualityOfService
		rep movsb
		movdw	cxbp, axbx
		mov	bx, ax
		call	HugeLMemUnlock
done:
		.leave
		ret
AllocQOSBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendSnrmPacket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sends a SNRM packet over the link
		( this frame is always a command frame )

CALLED BY:	When establishing and resetting connection
PASS:		ds    = station
		es    = dgroup
		ax    = IrlapConnectionFlags
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendSnrmPacket	proc	far
		uses	ax, bx, cx, ds, es, di, si
		.enter
EC <		IrlapCheckStation ds					>
	;
	; Send-u:snrm:cmd:P:ca:NA:da
	;
if _SOCKET_INTERFACE
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jnz	socketClient
endif ;_SOCKET_INTERFACE

		StackAllocPacket <size IrlapSnrmFrame>, es, di ; make buffer

if _SOCKET_INTERFACE
		jmp	continue
socketClient:
		StackAllocPacket <size IrlapSocketSnrmFrame>, es, di
		push	di
		add	di, offset ISSF_addr
		mov	si, IS_discoveryInfo
		mov	cx, 16/2
		rep	movsw			; copy address(socket lib only)
		pop	di
		mov	es:[di].ISSF_flags, ax
continue:
endif ;_SOCKET_INTERFACE

 		movdw	es:[di].ISF_srcDevAddr, ds:IS_devAddr, cx
 		movdw	es:[di].ISF_destDevAddr, ds:IS_destDevAddr, cx
		movm	es:[di].ISF_connAddr, ds:IS_connAddr, cl
	;
	; Fill in negotiation parameters
	; : es:di = Irlap Snrm frame
	;
		lea	si, es:[di].ISF_negotiationParams
		call	GetConnectionParamsInBuffer
	;
	; Send snrm:cmd packet
	;
		mov	cx, IRLAP_BROADCAST_CONNECTION_ADDR shl 8 or \
			    IUC_SNRM_CMD or mask IUCF_PFBIT
		BitSet	ch, IAF_CRBIT
	;
	; Send the packet
	;
if _SOCKET_INTERFACE
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jnz	socketClientSize
endif
		mov	bx, size IrlapSnrmFrame
		call	IrlapSendUFrame
		StackDeallocPacket	<size IrlapSnrmFrame>
done::
		.leave
		ret

if _SOCKET_INTERFACE
socketClientSize:
		mov	bx, size IrlapSocketSnrmFrame
		call	IrlapSendUFrame
		StackDeallocPacket	<size IrlapSocketSnrmFrame>
		jmp	done
endif ;_SOCKET_INTERFACE
		
SendSnrmPacket		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendUaRspFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a UA frame without negotiation field.

CALLED BY:	various
PASS:		ds	= station
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendUaRspFrame	proc	far
		uses	es, di, cx
		.enter
EC <		IrlapCheckStation ds					>
	;
	; Allocate a buffer for UA frame
	;
		StackAllocPacket <size IrlapUaFrame>, es, di
	;
	; Construct UA frame
	;
		mov	bx, size IrlapUaFrame
		mov	ch, ds:IS_connAddr	; already has CR bit off
		mov	cl, IUR_UA_RSP or mask IUCF_PFBIT
		movdw	es:[di].IUSF_srcDevAddr, ds:IS_devAddr, ax
		movdw	es:[di].IUSF_destDevAddr, ds:IS_destDevAddr, ax
	;
	; Send frame
	;
		call	IrlapSendUFrame
		StackDeallocPacket <size IrlapUaFrame>

		.leave
		ret
SendUaRspFrame		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendSnrmUaRspFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a UA frame in response to a SNRM, containing the
		negotiation parameters field.

CALLED BY:	ConnectResponseCONN
PASS:		ds	= station
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendSnrmUaRspFrame	proc	far
		uses	es, di, cx
		.enter
EC <		IrlapCheckStation ds					>
if	GENOA_TEST
	;
	; min turnaround time taken for Genoa Test Suite
	;
		push	ax
		mov	ax, 2
		call	TimerSleep
		pop	ax
endif
	;
	; Allocate a buffer for UA frame
	;
		StackAllocPacket <size IrlapUaSnrmFrame>, es, di
	;
	; Construct UA frame
	;
		mov	bx, size IrlapUaSnrmFrame
		mov	ch, ds:IS_connAddr	; already has CR bit off
		mov	cl, IUR_UA_RSP or mask IUCF_PFBIT
		movdw	es:[di].IUSF_srcDevAddr, ds:IS_devAddr, ax
		movdw	es:[di].IUSF_destDevAddr, ds:IS_destDevAddr, ax
	;
	; Add negotiation parameters
	;
		lea	si, es:[di].IUSF_negotiationParams
		call	GetConnectionParamsInBuffer
	;
	; Send frame
	;
		call	IrlapSendUFrame
		StackDeallocPacket <size IrlapUaSnrmFrame>
		.leave
		ret
SendSnrmUaRspFrame		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrepareFrmrFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare an frmr frame to send

CALLED BY:	RecvInvalidSeqRECV_S
PASS:		ds	= station
		es	= dgroup
		cx	= packet header received( rejected )
		al	= FrmrExplanation
			  one can simply pass 0 in here to unspecify the
			  reason.  We are doing that now.
RETURN:		ds:IS_frmrFrame = optr to FRMR frame to send
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrepareFrmrFrame	proc	far
		uses	ax, cx
		.enter
	;
	; fill in FRMR Frame in station segment
	;
EC <		IrlapCheckStation ds					>
		mov	ds:IS_frmrFrame.IFF_rejFrame, cl
		mov	ds:IS_frmrFrame.IFF_explanation, al
	;
	; construct IFF_counts
	;
		clr	al
		or	al, ds:IS_vs
		or	al, ds:IS_vr
		ror4	al		; swap Nr and Ns into correct position
		and	cl, mask FC_CR	; 1=command 0=response
		xor	cl, mask FC_CR	; 0=command 1=response ;invert CR only
		or	al, cl
		mov	ds:IS_frmrFrame.IFF_counts, al
		.leave
		ret
PrepareFrmrFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendFrmrFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an FRMR frame

CALLED BY:	RecvInvalidSeqRECV_S
PASS:		ds	= station
		ds:IS_frmrFrame contains FRMR frame prepared and ready to go
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendFrmrFrame	proc	far
		uses	ax,bx,cx,es,di
		.enter
EC <		IrlapCheckStation ds					>
	;
	; prepare header and dat to send
	;
		segmov	es, ds, bx
		mov	di, offset IS_frmrFrame
		mov	bx, size IrlapFrmrFrame
		mov	ch, ds:IS_connAddr
		mov	cl, IUR_FRMR_RSP or mask IUCF_PFBIT
	;
	; Send it
	;
		call	IrlapSendUFrame
		.leave
		ret
SendFrmrFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendRdRspFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send RD frame

CALLED BY:	DisconnectRequestRESET_CHECK_S
PASS:		ds = station
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendRdRspFrame	proc	far
		uses	bx,cx
		.enter
		mov	ch, ds:IS_connAddr
		mov	cl, IUR_RD_RSP or mask IUCF_PFBIT
		clr	bx
		call	IrlapSendUFrame
		.leave
		ret
SendRdRspFrame	endp



; **************************************************************************
; **************************************************************************
; ********************    Negotiation-Related Actions   ********************
; **************************************************************************
; **************************************************************************

;
; Negotiation tables
;

;
; ParamterIdTable maps a parameter ID to the corresponding index
; And the rest of the tables depend on this index.
; IRLAP_DATA_SIZE is negotiated as type 0, even though it is a type 1 param.
;
ParameterIdTable	byte\
 IRLAP_BAUD_RATE,
 IRLAP_MAX_TURN_AROUND,
 IRLAP_DATA_SIZE,
 IRLAP_WINDOW_SIZE,
 IRLAP_NUM_BOF,
 IRLAP_MIN_TURN_AROUND,
 IRLAP_LINK_DISCONNECT

;
; Minimum negotiation parameter
;   These are the least requirements for negotiation
;
MinParameterValues	byte\
  00000010b,		; min baudrate = 9600bps
  00000001b,		; least demanding max turnaround = 500ms
  00000001b,		; min data size = 64 bytes
  00000001b,		; min window size = 1 frame/window
  00000001b,		; least demanding # of BOFs = 48
  00000001b,		; least demanding min turnaround = 10ms
  00000001b		; min link disconnect time = 3 sec

;
; TableOfParamTables maps an index to a specific table that contains actual
; values to be used in the station.  All these tables are word-based table
; to make things simple.
;
TableOfParamTables	nptr\
	offset BaudRateTable,
	offset MaxTurnAroundTable,
	offset DataSizeTable,
	offset WindowSizeTable,
	offset NumBofTable,
	offset MinTurnAroundTable,
	offset LinkDisconnectTable

;
; BaudRateTable( index = 0 ): this affects IS_baudRate
; (*) SerialBaud is ASSUMED to be word size
;
BaudRateTable		SerialBaud\
	SB_2400,
	SB_9600,
	SB_19200,
	SB_38400,
	SB_57600,
	SB_115200,
	SB_115200,
	SB_115200

;
; MaxTurnAroundTable( index = 1): this affects IS_maxTurnAround in ticks
; Note: 1 tick = 16 ms.   Experimentally it was determined that minimum
; turnaround with no added delay is of about 6ms.  Thus, min turnarounds
; of 1ms and less are rounded to zero.
;
MaxTurnAroundTable	word\
	30,		; 500 * 60/1000,
	15,		; 250 * 60/1000,
	6,		; 100 * 60/1000,
	3,		; 50 * 60/1000,
	3,		; 25 * 60/1000,
	2,		; 10 * 60/1000,
	0,		; 5 * 60/1000,
	0		; reserved

;
; DataSizeTable( index = 2 ): this affects IS_maxIFrameSize
;
DataSizeTable		word\
	64,
	128,				
	256,
	512,
	1024,
	2048,
	64,
	64		; illegal value, but assume the maximum in this case

;
; WindowSizeTable( index = 3 ): this affects IS_maxWindows
; the numbers in the table is row index to BaudRate_Bof_Table
;
WindowSizeTable		word\
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	7

;
; NumBofTable( index = 4 ): this affects IS_numBof
; The actual number of Bof's should be determined by looking up
; BaudRate_Bof_Table w/ the index provided by this table, since this depends
; on the baud rate
;
NumBofTable		word\
	0,
	1,
	2,
	3,
	4,
	5,
	6,
	7

;
; each row corresponds to number of Bof's at baud rate of 115200
; each column corresponds baud rates 2400, 9600, 19200, 38400, 57600, 115200
;
BaudRate_Bof_Table	byte\
	1,	4,	8,	16,	24,	48,	    0,0,
	0,	2,	4,	 8,	12,	24,	    0,0,
	0,	1,	2,	 4,	 6,	12,	    0,0,
	0,	0,	1,	 2,	 3,	 6,	    0,0,
	0,	0,	0,	 1,	 1,	 3,	    0,0,
	0,	0,	0,	 0,	 1,	 2,	    0,0,
	0,	0,	0,	 0, 	 0,	 1,	    0,0,
	0,	0,	0,	 0,	 0,	 0,	    0,0
;
;    2400bps 9600bps 19200bps 38400bps 57600bps 115200bps  reserved
;

;
; MinTurnAroundTable (index = 5): this affects IS_minTurnAround (in ticks.)
; Note: 1 tick = 16 ms.   Experimentally it was determined that minimum
; turnaround with no added delay is of about 6ms.  Thus, min turnarounds
; of 1ms and less are rounded to zero.
;
MinTurnAroundTable	word\
	2,
	1,
	0,
	0,
	0,
	0,
	0,
	0

;
; LinkDisconnectTable( index = 7 ): this affects IS_
; 1 sec = 60 ticks
;
LinkDisconnectTable	word\
	3 * 60,
	8 * 60,
	12 * 60,
	16 * 60,
	20 * 60,
	25 * 60,
	30 * 60,
	40 * 60


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapParamValueToMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a value to mask given a parameter table entry

CALLED BY:	Utility
PASS:		es:di	= table( of size 8 word ) to lookup to find value
		ax	= value
RETURN:		al	= IrlapNegotiationParameter style mask
		carry set if the value is not found in the
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapParamValueToMask	proc	near
		uses	bx,cx,di
		.enter
		mov_tr	bx, ax
		mov	al, 1
		mov	cx, 8		; connection parameter table is always
findLoop:				; size of 8 words
		cmp	bx, {word}es:[di]
		je	outOfLoop
		shl	al, 1
		or	al, 1
		add	di, size word
		loop	findLoop
		stc
		jmp	done
outOfLoop:
		clc
done:
		.leave
		ret
IrlapParamValueToMask	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NegotiateConnectionParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse remote QOS params from the incoming packet, 
		negotiate those parameters against IS_connectionParams.
		Store the negotiated parameters in the station segment.

CALLED BY:	ConnectResponseCONN
		RecvUaRspSETUP
		RecvSnrmCmdSNIFF
		RecvUaRspSSETUP

PASS:		ds    = station
		^ldx:bp = PacketHeader for remote UA/SNRM frame received 
			(HugeLMem)
		IS_connectionParams filled in with desired local params.

RETURN:		If valid connection parameters were negotiated:
			carry clear
			ds:IS_baudRate		; same for local and remote
			ds:IS_numBofComputed	; requested by remote
			ds:IS_maxTurnAround	; requested by remote
			ds:IS_maxIFrameSizeIn	; local param
			ds:IS_maxIFrameSize	; requested by remote(LCC)
			ds:IS_remoteMaxWindows	; requested by remote(LCC)
			ds:IS_maxWindows	; our limitation for winsize
			ds:IS_minTurnaround	; requested by remote
			ds:IS_linkDisconnect	; same for local and remote
			contain negotiated value
		else:
			carry set
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NegotiateConnectionParameters	proc	far
		uses	ax, bx, cx, di, si, es
		.enter
	;
	; Lockdown the buffer
	;
		IrlapLockPacket esdi, dxbp		;es:di = PacketHeader

	;
	; ds	= station segment
	; es:di	= SNRM/UA frame received from remote machine
	;
		
	;
	; negotiate baud rate
	;
		call	NegotiateBaudRate
		jc	exit
	;
	; negotiate link disc
	;
		call	NegotiateLinkDisconnectTime
		jc	exit
	;
	; negotiate max TAT
	;
		call	NegotiateMaxTurnaroundTime
		jc	exit
	;
	; negotiate min TAT
	;
		call	NegotiateMinTurnaroundTime
		jc	exit
	;
	; negotiate number of BOFs
	;
		call	NegotiateNumberOfBofs
		jc	exit
	;
	; negotiate data size
	;
		call	NegotiateDataSize
		jc	exit
	;
	; negotiate window size
	;
		call	NegotiateWindowSize
		jc	exit
	;
	; calculate line capacity
	;
		call	LineCapacityCalculation	; local parameters adjusted
	;
	; calculate line capacity for remote machine ONLY if we are secondary
	;
		test	ds:IS_connAddr, mask ICA_CR
		clc
		jnz	exit
		call	RemoteLineCapacityCalculation ; remote params adjusted
		clc
exit:
	;
	; Unlock and free the SNRM frame
	;
		mov	bx, dx
		call	HugeLMemUnlock			;flags preserved
		.leave
		ret
disconnect:
	;
	; make a disconnect request
	;
		mov	bx, ds:IS_clientHandle
		call	IrlapNativeDisconnectRequest
		stc
		jmp	exit
		
NegotiateConnectionParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NegotiateBaudRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Negotiate baud rate

CALLED BY:	NegotiateConnectionParameters
PASS:		ds	= station segment
		es:di	= SNRM frame received
RETURN:		nothing (IS_baudRate adjusted)
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NegotiateBaudRate	proc	near
		uses	ax, si
		.enter
	;
	; find parameter in SNRM frame
	;
		mov	al, IRLAP_BAUD_RATE
		call	FindParameterInSnrmFrame	; es:si = IrlapParam
		jc	exit
	;
	; take logical AND of remote parameter and local parameter
	;
		mov	ah, es:[si].IP_val
		mov	al, ds:[IS_connectionParams].[ICP_baudRate]
		and	al, ah
		or	al, 00000010b		; we always support 9600bps
		mov	ds:[IS_connectionParams].[ICP_baudRate], al
	;
	; convert the mask to index
	; al = negotiated value
	;
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
	;
	; get baud rate value with index in cx
	;
		mov	ax, {word}cs:[BaudRateTable][si]
		mov	ds:IS_baudRate, ax
exit:
		.leave
		ret
NegotiateBaudRate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NegotiateLinkDisconnectTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Negotiate link disconnect time

CALLED BY:	NegotiateConnectionParameters
PASS:				ds	= station segment
		es:di	= SNRM frame received
RETURN:		nothing (IS_minTurnAround adjusted)		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NegotiateLinkDisconnectTime	proc	near
		uses	ax,si
		.enter
	;
	; find parameter in SNRM frame
	;
		mov	al, IRLAP_LINK_DISCONNECT
		call	FindParameterInSnrmFrame	; es:si = IrlapParam
		jc	exit
	;
	; take logical AND of remote parameter and local parameter
	;
		mov	ah, es:[si].IP_val
		mov	al, ds:[IS_connectionParams].[ICP_linkDisconnect]
		and	al, ah
		or	al, 00000001b	; min link disconnect time = 3 sec
		mov	ds:[IS_connectionParams].[ICP_linkDisconnect], al
	;
	; convert the mask to index
	; al = negotiated value
	;
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
	;
	; get baud rate value with index in cx
	;
		mov	ax, {word}cs:[LinkDisconnectTable][si]
		mov	ds:IS_linkDisconnect, ax
exit:
		.leave
		ret
NegotiateLinkDisconnectTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NegotiateMaxTurnaroundTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Negotiate max turnaround time

CALLED BY:	NegotiateConnectionParameters
PASS:		ds	= station segment
		es:di	= SNRM frame received
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NegotiateMaxTurnaroundTime	proc	near
		uses	ax,si
		.enter
	;
	; find parameter in SNRM frame
	;
		mov	al, IRLAP_MAX_TURN_AROUND
		call	FindParameterInSnrmFrame
		jc	exit
	;
	; convert mask to index
	;
		mov	al, es:[si].IP_val
		or	al, 1 ; least demanding max turnaround time = 500ms
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
	;
	; move the correct value into IS_maxTurnAround
	;
		mov	ax, {word}cs:[MaxTurnAroundTable][si]
		mov	ds:IS_maxTurnAround, ax
	;
	; we also find out what remote max turnaround time is
	;
		mov	al, ds:[IS_connectionParams][ICP_maxTurnAround]
		or	al, 1		; or with min requirement
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
		mov	ax, {word}cs:[MaxTurnAroundTable][si]
		mov	ds:IS_remoteMaxTurnAround, ax
exit:
		.leave
		ret
NegotiateMaxTurnaroundTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NegotiateMinTurnaroundTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Negotiate minimum turn around time
CALLED BY:	NegotiateConnectionParameters
PASS:		ds	= station segment
		es:di	= SNRM frame
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NegotiateMinTurnaroundTime	proc	near
		uses	ax, si
		.enter
	;
	; find parameter in SNRM frame
	;
		mov	al, IRLAP_MIN_TURN_AROUND
		call	FindParameterInSnrmFrame
		jc	exit
	;
	; convert mask to index
	;
		mov	al, es:[si].IP_val
		or	al, 1 ; least demanding min turnaround time = 10ms
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
	;
	; move the correct value into IS_maxTurnAround
	;
		mov	ax, {word}cs:[MinTurnAroundTable][si]
		mov	ds:IS_minTurnAround, ax
	;
	; we also find out what remote max turnaround time is
	;
		mov	al, ds:[IS_connectionParams][ICP_minTurnAround]
		or	al, 1		; or with min requirement
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
		mov	ax, {word}cs:[MinTurnAroundTable][si]
		mov	ds:IS_remoteMinTurnAround, ax
exit:
		.leave
		ret
NegotiateMinTurnaroundTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NegotiateNumberOfBofs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Negotiate number of BOFs
CALLED BY:	NegotiateConnectionParameters
PASS:		ds	= station segment
		es:di	= SNRM frame
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NegotiateNumberOfBofs	proc	near
		uses	ax,bx,cx,si,di,es
		.enter
	;
	; find parameter in SNRM frame
	;
		mov	al, IRLAP_NUM_BOF
		call	FindParameterInSnrmFrame	; es:si = IrlapParam
		jc	exit
	;
	; convert mask to index
	;
		mov	al, es:[si].IP_val
		or	al, 1		; or with min requirement
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
	;
	; find the index value of baud rate and put it in bx
	;
		segmov	es, cs, ax
		mov	di, offset BaudRateTable
		mov	ax, ds:IS_baudRate
		mov	cx, 8
		repne	scasw
		jnz	noMatch
		dec	di				; move back one hop
		sub	di, offset BaudRateTable	; di = index x 2
		shr	di, 1				; di = index
		mov	bx, di
	;
	; move the correct value into IS_numBofComputed.
	;
		shl	si, 1
		shl	si, 1				; si = index x 8
		mov	al, cs:[BaudRate_Bof_Table][bx][si]
		mov	ds:IS_numBofComputed, al

	;
	; Find remote numOfBofs also
	;
		mov	al, ds:[IS_connectionParams][ICP_numBof]
		or	al, 1		; or with min requirement
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
	;
	; find the index value of baud rate and put it in bx
	;
		segmov	es, cs, ax
		mov	di, offset BaudRateTable
		mov	ax, ds:IS_baudRate
		mov	cx, 8
		repne	scasw
		jnz	noMatch
		dec	di				; move back one hop
		sub	di, offset BaudRateTable	; di = index x 2
		shr	di, 1				; di = index
		mov	bx, di
	;
	; move the correct value into IS_remoteNumBofComputed.
	;
		shl	si, 1
		shl	si, 1				; si = index x 8
		mov	al, cs:[BaudRate_Bof_Table][bx][si]
		mov	ds:IS_remoteNumBofComputed, al

		clc
exit:
		.leave
		ret

noMatch:
		stc
		jmp	exit
NegotiateNumberOfBofs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NegotiateDataSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Negotiate data size

CALLED BY:	NegotiateConnectionParameters
PASS:		ds	= station segment
		es:di	= SNRM frame
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NegotiateDataSize	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; [ Find out going data size ]
	;
		
	;
	; find parameter in SNRM frame
	;
		mov	al, IRLAP_DATA_SIZE
		call	FindParameterInSnrmFrame	; es:si.IP_val = mask
		jc	exit				; recvd from remote sd
		
		mov	al, es:[si].IP_val
		or	al, 1		; or with min requirement
	;
	; convert mask to index
	;
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
	;
	; move the correct value into IS_maxTurnAround
	;
		mov	ax, {word}cs:[DataSizeTable][si]
		mov	ds:IS_maxIFrameSize, ax
	;
	; we also need to fill in dataSize parameter part
	; ( this is incoming data size )
	;
		segmov	es, cs, di
		mov	di, offset DataSizeTable
		call	IrlapParamValueToMask
		mov	ds:IS_connectionParams.ICP_dataSize, al
	;
	; [ Find out incoming data size ]
	;

	;
	; get local data size parameter
	;
		mov	al, ds:[IS_connectionParams][ICP_dataSizeIn]
		or	al, 1		; or with min requirement
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
		mov	ax, {word}cs:[DataSizeTable][si]
		mov	ds:IS_maxIFrameSizeIn, ax
	;
	; dataSizeIn paramter will be filled in in LineCapacityCalculation
	; routine
	;
exit:	
		.leave
		ret
NegotiateDataSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NegotiateWindowSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Negotiate window size

CALLED BY:	NegotiateConnectionParameters
PASS:		ds	= station segment
		es:di	= SNRM frame
RETURN:		nothing
DESTROYED:	nothing		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NegotiateWindowSize	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Record remoteMaxWindow size in IS_remoteMaxWindows
	;
		mov	al, IRLAP_WINDOW_SIZE
		call	FindParameterInSnrmFrame
		jc	exit
		mov	al, es:[si].IP_val
		or	al, 1		; 1 is the min window size
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
		mov	ax, {word}cs:[WindowSizeTable][si]
		mov	ds:IS_remoteMaxWindows, al
	;
	; record our own window size
	;
		mov	al, ds:[IS_connectionParams][ICP_windowSizeIn]
		or	al, 1		; or with min requirement
		call	GetMostSignificantByteIndex	; si = index x 2
		jc	exit
		mov	ax, {word}cs:[WindowSizeTable][si]
		mov	ds:IS_maxWindows, al
exit:
		.leave
		ret
NegotiateWindowSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMostSignificantByteIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the most significant byte to an index
CALLED BY:	Utility
PASS:		al	= mask to convert into index
RETURN:		si	= index x (size word)
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMostSignificantByteIndex	proc	near
		uses	ax, cx
		.enter
	;
	; convert mask into an index: 0-7
	; al = mask
	;
		tst	al
		jz	error
		mov	ah, 10000000b
		mov	cx, 8
convLoop:
		test	al, ah
		jnz	found
		shr	ah, 1
		loop	convLoop
		jmp	error
found:
		dec	cx
		shl	cx, 1
		mov	si, cx
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
GetMostSignificantByteIndex	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RenegotiateConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Station received a renegotiation XID frame

CALLED BY:	RecvXidRspRECV_P
		RecvXidCmdRECV_S
PASS:		ds	= station
		dx:bp	= packet optr
RETURN:		nothing
DESTROYED:	nothing

NOTE:
	There is no way to initiate a renegotiation in the spec... So, we
	ignore this for the moment

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RenegotiateConnection	proc	far
		.enter
	;
	; not supported
	;
		.leave
		ret
RenegotiateConnection		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ApplyDefaultConnectionParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize connection parameters to their default values

CALLED BY:	event handlers
PASS:		ds = station
		es = dgroup
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ApplyDefaultConnectionParams	proc	far
		uses	ax, bx, cx, di, es
		.enter
EC <		WARNING	_APPLY_DEFAULT_CONNECTION_PARAMS		>
	;
	; Before changing important things like the baud rate, make sure
	; that all the data in the output stream is transmitted, because
	; we don't want to change paramters in the middle of a frame.
	;
		mov	bx, ds:[IS_serialPort]
		call	IrlapWaitForOutput
	;
	; Set correct serial baud
	;
		mov	ds:IS_baudRate, SB_9600
	;
	; Following is the default connection parameters in spec
	;
	;	lea	si, ds:[IS_connectionParams]
	;*	mov	ds:[si].ICP_baudRate, mask IPBR_9600bps or \
	;				      mask IPBR_2400bps
	;	mov	ds.[si].ICP_maxTurnAround, mask IPMTA_500ms
	;	mov	ds:[si].ICP_DataSize, mask IPDS_64bytes
	;	mov	ds:[si].ICP_windowSize, mask IPWS_1frame
	;*	mov	ds:[si].ICP_numBof, mask IPNB_3BOF
	;	mov	ds:[si].ICP_minTurnAround, mask IPMT_001ms
	;	mov	ds:[si].ICP_pTimer, mask IPT_normal
	;	mov	ds:[si].ICP_linkDisconnect, mask IPLTT_20sec or \
	;					    mask IPLTT_16sec or \
	;					    mask IPLTT_12sec or \
	;					    mask IPLTT_8sec or \
	;					    mask IPLTT_3sec
	;
	; '*' indicates the things that will actually have any significance
	;     in making initial connection to other machines
	;
		mov	ah, SM_RAW
		mov	al, SerialFormat<0,0,SP_NONE,0,SL_8BITS>
		mov	bx, ds:IS_serialPort
		mov	cx, SB_9600
		mov	di, DR_SERIAL_SET_FORMAT
		call	{fptr.far}es:serialStrategy
		
if _EXTENDED_SYSTEMS_9680
	;
	; If we are using 9610s from extended system, we need to set
	; DTR, and RTS to set correct baud rates.  We set the baudrate of
	; the dongle to be 9600.
	;
	; bx = unit number
	; al = modem control bits
	;
		mov	di, DR_SERIAL_GET_MODEM
		call	{fptr.far}es:serialStrategy	; al = modem ctrl bits
		and	al, not mask SMC_DTR		; DTR = low
		or	al, mask SMC_RTS		; RTS = high
		mov	di, DR_SERIAL_SET_MODEM		; this means 9600bps
		call	{fptr.far}es:serialStrategy
endif ;_EXTENDED_SYSTEMS_9680

	;
	; Recommend 11 additional BOFs on frames transmitted outside 
	; connection.  See IrLAP errata.
	;	mov	ds:IS_numBof, 3		; specified in spec
		mov	ds:IS_numBof, 10	; specified in spec
		mov	ds:IS_retryN1, 3
		mov	ds:IS_retryN2, 5
		mov	ds:IS_retryN3, 4
	;
	; Also, set correct frame size based on 9600bps rate
	; ( therefore, test frames are allowed to be 400 bytes long )
	;
		mov	ds:IS_maxIFrameSizeIn, IRLAP_NDM_TEST_FRAME_SIZE
	;
	; Clear ISS_REMOTE_BUSY since we are disconnected now and don't
	; care about the remote machine
	;
		BitClr	ds:IS_status, ISS_REMOTE_BUSY
		.leave
		ret
ApplyDefaultConnectionParams		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapWriteStatistics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out statistics to INI file

CALLED BY:	ApplyDefaultConnectionParams
PASS:		ds	= station segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	5/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	IRLAP_STAT
categoryIrlap	char	"irlap", 0
keyBadCrc	char	"badCrc", 0
IrlapWriteStatistics	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter
		mov	bp, ds:IS_badCrc
		segmov	ds, cs
		mov	si, offset categoryIrlap
		mov	cx, ds
		mov	dx, offset keyBadCrc
		call	InitFileWriteInteger
		.leave
		ret
IrlapWriteStatistics	endp
endif	; IRLAP_STAT



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ApplyConnectionParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ditto

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ApplyConnectionParameters	proc	far
		uses	ax,bx,cx,dx,di
		.enter
EC <		WARNING	_APPLY_CONNECTION_PARAMETERS			>
	;
	; Before changing important things like the baud rate, make sure
	; that all the data in the output stream is transmitted, because
	; we don't want to change paramters in the middle of a frame.
	;
		mov	bx, ds:[IS_serialPort]
		call	IrlapWaitForOutput
	;
	; Set serial format
	;
		mov	ah, SM_RAW
		mov	al, SerialFormat<0,0,SP_NONE,0,SL_8BITS>
		mov	bx, ds:IS_serialPort
		mov	cx, ds:IS_baudRate
		mov	di, DR_SERIAL_SET_FORMAT
		call	{fptr.far}es:serialStrategy
if _EXTENDED_SYSTEMS_9680
	;
	; If we are using 9610s from extended system, we need to adjust
	; DTR, and RTS to set correct baud rates.
	;
	; bx = unit number
	; al = modem control bits
	;
		mov	di, DR_SERIAL_GET_MODEM
		call	{fptr.far}es:serialStrategy	; al = modem ctrl bits

		cmp	ds:IS_baudRate, SB_19200
		jne	nextBaud
		or	al, mask SMC_DTR		; DTR = high
		and	al, not mask SMC_RTS		; RTS = low
		jmp	skipBaud
nextBaud:
		cmp	ds:IS_baudRate, SB_115200
		jne	skipBaud
		or	al, mask SMC_DTR or mask SMC_RTS; DTR,RTS = high
skipBaud:
		mov	di, DR_SERIAL_SET_MODEM		; this means 9600bps
		call	{fptr.far}es:serialStrategy
endif ;_EXTENDED_SYSTEMS_9680
	;
	; Calculate other connection variables
	; : move IS_numBofComputed to IS_numBof
	;
		movm	ds:IS_numBof, ds:IS_numBofComputed, al
	;
	; calculate IS_retryN1, N2, N3 based on IS_linkDisconnect
	;
		clr	dx
		mov	ax, ds:IS_linkDisconnect
		mov	cx, ds:IS_maxTurnAround
		div	cx				; ax = retry count
EC <		cmp	ah, 0						>
EC <		WARNING_NE BAD_CONTENTION_TIMEOUT_VALUE			>
		mov	ds:IS_retryN1, al
		inc	ds:IS_retryN1
		mov	ds:IS_retryN2, al
		shr	al, 1
		mov	ds:IS_retryN3, al			; N3 = N2/2
	;
	; if disconnection time threshold is above 3sec we want to warn the
	; user after 3 seconds of link failure otherwise we don't generate
	; warning
	;
		cmp	ds:IS_linkDisconnect, 3*60
		jna	skipWarnThr
		clr	dx
		mov	ax, 3 * 60		; warning after 3 seconds
		mov	cx, ds:IS_maxTurnAround
		div	cx
		mov	ds:IS_retryN1, al
skipWarnThr:
	;	
	;	mov	ds:IS_retryN1, al
	;	cmp	ds:IS_linkDisconnect, (3*60)	; 3 seconds
	;	je	noDisconnectUserWarning
	;	mov	ds:IS_retryN1, ( 3*60 / IRLAP_CONTENTION_TIMEOUT_TICKS)
	;
	; noDisconnectUserWarning:
	;
		.leave
		ret
ApplyConnectionParameters	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitConnectionState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize state variables of the station on connection

CALLED BY:	State machine
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing
PSEUDO CODE/STRATEGY:
		Vs := Vr := 0		
		remoteBusy := false
		window := maxWindow
		retryCount := 0

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitConnectionState	proc	far
		uses	ax, bx, cx
		.enter
EC <		WARNING	_INIT_CONNECTION_STATE				>
	;
	; Initialize connection variables
	;
		clr	ax
if	IRLAP_STAT
		mov	ds:IS_badCrc, ax
endif
		mov	ds:IS_vs, al
		mov	ds:IS_vr, al
		mov	ds:IS_retryCount, al
		movm	{byte}ds:IS_window, {byte}ds:IS_remoteMaxWindows, al
		BitClr	ds:IS_status, ISS_REMOTE_BUSY
		BitClr	ds:IS_status, ISS_WARNED_USER
	;
	; Initialize Ns range flag:
	;   maxWindows number of frames are valid & the rest is invalid
	;
		mov	bx, offset IS_store
		mov	cx, IRLAP_MAX_WINDOWS		; cx = maxWindows size
		mov	ax, cx
		clr	ah
		sub	al, ds:IS_maxWindows	; al = max windows
nsLoop:
		cmp	cl, al
		jbe	invalidRange
		BitSet	ds:[bx].IW_flags, IWF_NS_RANGE
		jmp	cont
invalidRange:
		BitClr	ds:[bx].IW_flags, IWF_NS_RANGE
cont:
		add	bx, size IrlapWindow
		loop	nsLoop
		
		.leave
		ret
InitConnectionState	endp

;---------------------------------------------------------------------------
; 		LINE CAPACITY CALCULATION
;---------------------------------------------------------------------------

;
; baudrate table, if you cannot find your baudrate in here, you cannot
; continue with connection.  You must disconect.
; Note that there 5 baudrates are available currently including 115200bps
; which is handled differently
;
LineBaudrateTable	word\
	SB_9600,
	SB_19200,
	SB_38400,
	SB_57600

;
; These values are number of bytes that is equivalent to MinTurnaround of
; 2 ticks in GEOS system
;
MinTurnaroundInBytes	word\
	17,		; at 9600bps
	33,		; at 19200bps
	66,		; at 38400bps
	96		; at 57600bps

MIN_TAT_IN_BYTES_AT_115200 equ 192

;
; line capacity according to baudrate with 500ms max turnaround
;
MaxLineCapacityTable	word\
	(400*9/10),	; at 9600bps 
	(800*9/10),	; at 19200bps
	(1600*9/10),	; at 38400bps
	(2360*9/10)	; at 57600bps

;
; Reduce frame size according to this table using scasw
;
IRLAP_MIN_FRAME_SIZE	equ	64
ReduceFrameSizeTable	word\
	2048,
	1024,
	512,
	256,
	128,
	IRLAP_MIN_FRAME_SIZE,
	0				; this is error case

;
; These values are capacity for 115200bps at different max turnaround time
; anything outside of this is not supported
;
; WARNING!!!!
; all the values in this table MUST be unique as I will heedless use
; scasw on this.
;
BytesAt115K		word\
	30,(4800*9/10),	; at 500ms	we can send 4800 bytes in 30 ticks
	15,(2400*9/10),	; at 250ms	we can send 2400 bytes in 15 ticks
	6,(960*9/10), 	; at 100ms	we can send 960 bytes in 6 ticks
	3,(480*9/10)	; at 50ms	we can send 480 bytes in 3 ticks

ifidn HARDWARE_TYPE, <PC>
SYSTEM_OVERHEAD		equ	2 ; system operational overhead
				  ; this has to be experimentally determined
				  ; on prototypes for different products
else
   SYSTEM_OVERHEAD	equ	0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LineCapacityCalculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a line capacity calculation

CALLED BY:	NegotiateConnectioParameters
PASS:		ds	= station
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Before we exit we finally do line capacity calculation
	Algorithm:
	1. look up max line capacity at current baudrate
	2. compute requested line capacity at current settings
	3. if max capacity > requested capacity, we are done
	4. decrement data size or window size, and go to 2

	formular for requested line capacity:
	r_l_c = (windowSize * (dataSize + 6 + numBofs)) + min_turnaround_bytes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LineCapacityCalculation	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; look up maximum line capacity for a given baudrate
	;
		mov	ax, ds:IS_baudRate
		cmp	ax, SB_115200
		je	specialCase
	;
	; we have to make sure that the max turnaround we have now is 500ms
	; for baudrates that are slower than 11.5Kbps, anything less than
	; that is not acceptable
	;
		mov	dx, {word}cs:[MaxTurnAroundTable]
		mov	ds:IS_maxTurnAround, dx
	;
	; get baudrate index
	;
		segmov	es, cs, di
		mov	di, offset LineBaudrateTable
		mov	cx, size LineBaudrateTable
		repne scasw
		stc
		jne	done		; carry set
		sub	di, offset LineBaudrateTable + 2; di= offset into table
	;
	; get max line capacity
	;
		mov	cx, cs:[MaxLineCapacityTable][di]
		mov	si, cs:[MinTurnaroundInBytes][di]
common:
	;
	; al = windowSize
	; cx = max line capacity
	; si = min turnaround time in bytes
	;
		clr	ah			; just in case
		mov	al, ds:IS_remoteMaxWindows
		clr	dx
adjust:	
		call	ComputeRequestedLineCapacity
		jnc	doneClr
	;
	; reduce outgoing frame size unless the size is 64 already
	;
		call	ReduceFrameSize
		jnc	adjust
reduceWindowSize::
		cmp	al, 1
EC <		ERROR_BE IRLAP_STRANGE_ERROR				>
NEC <		jbe	done ; something is very wrong, but what can I do?>
		dec	al
		jmp	adjust
doneClr:
		mov	ds:IS_remoteMaxWindows, al
	;
	; reflect the change in IS_connectionParams so that an appropriate
	; QoS parameters are passed up the layer.
	;		
		clr	ah		; ax = remote window size
		mov	di, offset WindowSizeTable
		call	IrlapParamValueToMask	; al= IrlapParamWindowSize
		mov	ds:IS_connectionParams.ICP_windowSize, al

		mov	ax, ds:IS_maxIFrameSize
		mov	di, offset DataSizeTable
		call	IrlapParamValueToMask	; al= IrlapParamDataSize
		mov	ds:IS_connectionParams.ICP_dataSize, al
		clc
done:
		.leave
		ret
specialCase:
	;
	; things work differently at 115200bps, beware! hhhehhehhh
	;
getMaxCapacity115:
	;
	; lookup max line capacity
	;
		mov	ax, ds:IS_maxTurnAround
		segmov	es, cs, di
		mov	di, offset BytesAt115K
		mov	cx, size BytesAt115K
		repne scasw
		jne	notFoundMinTurnaround
		mov	cx, {word}es:[di]
	;
	; min turnaround time in bytes is always 192 bytes for 115200bps
	; if it is >1ms.
	;
		clr	si
		tst	ds:IS_minTurnAround
		jz	zeroMinTAT
		mov	si, MIN_TAT_IN_BYTES_AT_115200
zeroMinTAT:
		jmp	common
notFoundMinTurnaround:
	;
	; Min turnaround is shorter than acceptable
	; Make it 50ms min turnaround and see if that fits
	;
		mov	ds:IS_maxTurnAround, 3
		jmp	getMaxCapacity115
		
LineCapacityCalculation	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoteLineCapacityCalculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a line capacity calculation on parameters passed in by
		remote side

CALLED BY:	NegotiateConnectioParameters
PASS:		ds	= station
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Before we exit we finally do line capacity calculation on remote params
	Algorithm:
	1. look up max line capacity at current baudrate
	2. compute requested line capacity at current settings
	3. if max capacity > requested capacity, we are done
	4. decrement data size or window size, and go to 2

	formular for requested line capacity:
	r_l_c = (windowSize * (dataSize + 6 + numBofs)) + min_turnaround_bytes

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoteLineCapacityCalculation	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; look up maximum line capacity for a given baudrate
	;
		mov	ax, ds:IS_baudRate
		cmp	ax, SB_115200
		je	specialCase
	;
	; we have to make sure that the max turnaround we have now is 500ms
	; for baudrates that are slower than 11.5Kbps, anything less than
	; that is not acceptable
	;
		mov	dx, {word}cs:[MaxTurnAroundTable]
		mov	ds:IS_remoteMaxTurnAround, dx
	;
	; get baudrate index
	;
		segmov	es, cs, di
		mov	di, offset LineBaudrateTable
		mov	cx, size LineBaudrateTable
		repne scasw
		stc
		jne	done		; carry set
		sub	di, offset LineBaudrateTable + 2; di= offset into table
	;
	; get max line capacity
	;
		mov	cx, cs:[MaxLineCapacityTable][di]
		mov	si, cs:[MinTurnaroundInBytes][di]
common:
	;
	; al = windowSize
	; cx = max line capacity
	; si = min turnaround time in bytes
	;
		clr	ah			; just in case
		mov	al, ds:IS_maxWindows
		mov	dx, mask LF_REMOTE
adjust:
		call	ComputeRequestedLineCapacity
		jnc	doneClr
	;
	; reduce outgoing frame size unless the size is 64 already
	;
		call	ReduceFrameSize
		jnc	adjust
reduceWindowSize::
		cmp	al, 1
EC <		ERROR_BE IRLAP_STRANGE_ERROR				>
NEC <		jbe	done ; something is very wrong, but what can I do?>
		dec	al
		jmp	adjust
doneClr:
		mov	ds:IS_maxWindows, al
	;
	; reflect the change in IS_connectionParams so that an appropriate
	; SNRM/UA frame gets sent out in case of secondary
	;		
		clr	ah		; ax = remote window size
		mov	di, offset WindowSizeTable
		call	IrlapParamValueToMask	; al= IrlapParamWindowSize
		mov	ds:IS_connectionParams.ICP_windowSizeIn, al

		mov	ax, ds:IS_maxIFrameSizeIn
		mov	di, offset DataSizeTable
		call	IrlapParamValueToMask	; al= IrlapParamDataSize
		mov	ds:IS_connectionParams.ICP_dataSizeIn, al
		clc
done:
		.leave
		ret
specialCase:
	;
	; things work differently at 115200bps, beware! hhhehhehhh
	;
getMaxCapacity115:
	;
	; lookup max line capacity
	;
		mov	ax, ds:IS_remoteMaxTurnAround
		segmov	es, cs, di
		mov	di, offset BytesAt115K
		mov	cx, size BytesAt115K
		repne scasw
		jne	notFoundMinTurnaround
		mov	cx, {word}es:[di]
	;
	; min turnaround time in bytes is always 192 bytes for 115200bps
	; if it is >1ms.
	;
		clr	si
		tst	ds:IS_remoteMinTurnAround
		jz	zeroMinTAT
		mov	si, MIN_TAT_IN_BYTES_AT_115200
zeroMinTAT:
		jmp	common
notFoundMinTurnaround:
	;
	; Min turnaround is shorter than acceptable
	; Make it 50ms min turnaround and see if that fits
	;
		mov	ds:IS_remoteMaxTurnAround, 3
		jmp	getMaxCapacity115
		
RemoteLineCapacityCalculation	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReduceFrameSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reduce current max frame size to next small one

CALLED BY:	LineCapacityCalculation
PASS:		es = code segment
		ds = station segment
		dx = LccFlag
RETURN:		ds:IS_remoteMaxIFrameSize adjusted to next small frame size
		carry set if frame size already minimum
DESTROYED:	nothing

NOTE:		we will not actually reduce ds:IS_maxIFrameSizeIn since it
		is very dangerous thing to do in case when we are primary.
		Since on primaries, Line capacity calculation happens after
		connection establishment, and we cannot dictate other values
		for data size and window size for secondary.

NOTE2:		Disregard NOTE, because I decided not to call
		RemoteLineCapacityCalculation if we are the primary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReduceFrameSize	proc	near
		uses	ax,cx,di
		.enter
	;
	; look up the next small frame size in the table
	;
		
		mov	ax, ds:IS_maxIFrameSize
		test	dx, mask LF_REMOTE
		jz	localMaxIFrame
		mov	ax, ds:IS_maxIFrameSizeIn
localMaxIFrame:
		cmp	ax, IRLAP_MIN_FRAME_SIZE
		je	error
		mov	di, offset ReduceFrameSizeTable
		mov	cx, size ReduceFrameSizeTable
		repne scasw
		mov	cx, {word}es:[di]
		jcxz	error
	;
	; reduce i frame size that remote side should use if we are
	; computing line capacity for remote side
	;
		test	dx, mask LF_REMOTE
		jz	updateLocalMaxIFrame
		mov	ds:IS_maxIFrameSizeIn, cx
doneClr:
		clc
done:
		.leave
		ret
updateLocalMaxIFrame:
		mov	ds:IS_maxIFrameSize, cx
		jmp	doneClr
error:
		stc
		jmp	done
ReduceFrameSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeRequestedLineCapacity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compute the capacity given arguments and compare that with
		max line capacity that was passed in

CALLED BY:	LineCapacityCalculation
PASS:		al = window size
		cx = max line capacity
		si = min turnaround time in bytes
		ds = station segment
		dx = LccFlag
RETURN:		carry set if requested line capacity exceeds max line capacity
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	formular for requested line capacity:
	r_l_c = (windowSize * (dataSize + 6 + numBofs)) + min_turnaround_bytes
		+ system load

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeRequestedLineCapacity	proc	near
		uses	ax,bx,cx,dx,si,bp
		.enter
	;
	; get paramters inside parenthesis
	;
		mov	bp, dx
		mov	bx, 6			; +6
	;
	; + num BOFs
	;
		clr	dh
		mov	dl, ds:IS_numBofComputed
		test	bp, mask LF_REMOTE
		jz	localNumBof
		mov	dl, ds:IS_remoteNumBofComputed
localNumBof:
		add	bx, dx
	;
	; + data Size
	;
		mov	dx, ds:IS_maxIFrameSize
		test	bp, mask LF_REMOTE
		jz	localFrameSize
		mov	dx, ds:IS_maxIFrameSizeIn
localFrameSize:
		add	bx, dx
	;
	; multiply
	;
		mul	bx			; dx should be 0 now
		add	ax, si
		add	ax, SYSTEM_OVERHEAD
	;
	; compare with maximum capacity
	;
		cmp	ax, cx
		jae	doneC
		clc
done:
		.leave
		ret
doneC:
		stc
		jmp	done
ComputeRequestedLineCapacity	endp


; ***************************************************************************
; ***************************************************************************
; **************************    Indications    ******************************
; ***************************************************************************
; ***************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pass data back to the user

CALLED BY:	Various routines in PXfer and SXfer
PASS:		dx:bp = data buffer with SequencedPacketHeader in front
		ds    = station
RETURN:		dx    = 0 always to indicate that the packet will be freed
			by the user.
DESTROYED:	nothing
SIDE EFFECTS:	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataIndication	proc	far
		uses	ax,bx,cx,di,si,es
		.enter
EC <		WARNING	_DATA_INDICATION				>
	;
	; Get dataSize, dataOffset, seqInfo by locking the buffer
	;
		tst	dx
		jz	done
		mov	bx, dx
		call	HugeLMemLock
		mov	es, ax
		mov	di, es:[bp]
		mov	cx, es:[di].PH_dataSize		; cx = dataSize
		mov	si, size SequencedPacketHeader	; si = dataOffset
		add	di, si				;
		mov	ax, {word}es:[di]		; ax = seqInfo	
		call	HugeLMemUnlock
	;
	; Clear IrlapDataRequestType flag only if we are native client
	;
if _SOCKET_INTERFACE
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jnz	cont
endif ;_SOCKET_INTERFACE
		clr	ax		; clear IrlapDataRequestType flags
cont::
	;
	; call the callback routine
	;
		mov	bx, ds:IS_clientHandle
		pushdw	ds:IS_clientCallback
		mov	di, NII_DATA_INDICATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		clr	dx			; indicate that the packet
						; has been sent to the user
done:
		.leave
		ret
DataIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnitdataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Indicate arrival of an unnumbered frame

CALLED BY:	Various PXfer and SXfer routines
PASS:		dx:bp = HugeLMem optr to PacketHeader of packet
		ds    = station
RETURN:		dx    = always 0 to indicate that the packet will be freed
		        by the service user
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnitdataIndication	proc	far
		uses	ax,bx,cx,di,si,es,ds
		.enter
EC <		WARNING	_UNIT_DATA_INDICATION				>
	;
	; Get dataSize, dataOffset, seqInfo by locking the buffer
	;
		tst	dx
		jz	done
		mov	bx, dx
		call	HugeLMemLock
		mov	es, ax
		mov	di, es:[bp]
		mov	cx, es:[di].PH_dataSize		; cx = dataSize
		mov	si, es:[di].PH_dataOffset	; si = dataOffset
	;
	; See if this packet is an expedited I frame
	;
if _SOCKET_INTERFACE
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jnz	socketClient
endif ;_SOCKET_INTERFACE
		
		clr	ah
		mov	al, es:[di].PH_reserved
		mov	di, NII_UNITDATA_INDICATION
		test	ax, mask IDRT_EXPEDITED
		jz	unlock				; normal UI frame
		mov	di, NII_DATA_INDICATION		; expedited I frame

if _SOCKET_INTERFACE
		jmp	unlock
socketClient:
		add	di, si
		mov	ax, {word}es:[di]		; ax = seqInfo
		mov	di, NII_UNITDATA_INDICATION
endif ;_SOCKET_INTERFACE

unlock:
		call	HugeLMemUnlock
	;
	; call the callback routine
	;
		mov	bx, ds:IS_clientHandle
		pushdw	ds:IS_clientCallback
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		clr	dx			; indicate that the packet
						; has been sent to the user
done:
		.leave
		ret
UnitdataIndication		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the client that the link needs to be reset

CALLED BY:	INTERNAL GLOBAL
PASS:		ds = station
		cx = IrlapResetIndicationType
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetIndication	proc	far
		uses	bx,di
		.enter
EC <		WARNING _RESET_INDICATION				>
	;
	; Notify the client
	;
		mov	bx, ds:IS_clientHandle
		pushdw	ds:IS_clientCallback
		mov	di, NII_RESET_INDICATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL
exit:
		.leave
		ret
ResetIndication		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StatusIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Indicate that the connection is in jeopardy

CALLED BY:	Various transfer even handlers
PASS:		ds = station segment
		cx = IrlapStatusIndicationType
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StatusIndication	proc	far
		uses	bx,di,si
		.enter
EC <		WARNING	_STATUS_INDICATION				>
	;
	; Send a notification
	;
		mov	si, SST_IRDA
		mov	di, NII_STATUS_INDICATION

		push	ax, bx, cx, dx		;destroyed by C notification
		call	SysSendNotification
		pop	ax, bx, cx, dx		
	;
	; Notify the client
	;
		mov	bx, ds:IS_clientHandle
		pushdw	ds:IS_clientCallback
		mov	di, NII_STATUS_INDICATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		.leave
		ret
StatusIndication		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StatusConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Confirm a status request

CALLED BY:	IrlapNativeStatusRequest
PASS:		ds	= station
		ax 	= ConnectionStatus
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	6/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StatusConfirm	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Notify the client
	;
		mov	bx, ds:IS_clientHandle
		pushdw	ds:IS_clientCallback
		mov	di, NII_STATUS_CONFIRMATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL		
		.leave
		ret
StatusConfirm	endp


	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Connection has been reset per request

CALLED BY:	Various transfer event handlers
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetConfirm	proc	far
		uses	bx, di
		.enter
EC <		WARNING	_RESET_CONFIRM					>
	;
	; Notify the client
	;
		mov	bx, ds:IS_clientHandle
		pushdw	ds:IS_clientCallback
		mov	di, NII_RESET_CONFIRMATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		.leave
		ret
ResetConfirm		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Indicate incoming connection

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = event code
		if (client = socket library)
			es:di  = IrlapSocketSnrmFrame

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectIndication	proc	far
		uses	ax,bx,cx,dx,di,ds,si,es,bp
		.enter
EC <		WARNING	_CONNECTION_INDICATION				>
	;
	; also do a status indication
	;
		mov	cx, ISIT_CONNECTED
		call	StatusIndication
	;
	; Common paramters
	;
		mov	bx, ds:IS_clientHandle
		movdw	cxdx, ds:IS_destDevAddr
		pushdw	ds:IS_clientCallback

if _SOCKET_INTERFACE		
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jz	nativeClient
	;
	; Socket client specific
	;
		mov	ax, es:[di].ISSF_flags
		mov	si, di
		add	si, offset ISSF_addr
		jmp	callClient
nativeClient:
endif ;_SOCKET_INTERFACE

	;
	; Native client specific
	; ds = station segment
	;
	;	mov	bp, offset IS_qos	; ds:bp = ds:IS_qos
	;	mov	di, si			; es:di = beginning of packet
	;	call	GetParamsInQOSBuffer	; ds:IS_qos filled in
	;	segmov	es, ds, si
	;	mov	si, offset IS_qos	; es:si = QOS
	;
	; we don't need to go through the complicated procedure above since
	; we are now doing negotiation before we send indication above
	;
		segmov	es, ds, si
		mov	si, offset IS_qos	; es:si = qos
callClient:
		mov	di, NII_CONNECT_INDICATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		.leave
		ret
ConnectIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the client of disconnection

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
		ax    = IrlapCondition
RETURN:		nothing
DESTROYED:	ax

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisconnectIndication	proc	far
		uses	cx, bx, dx, di, bp
		.enter
EC <		WARNING	_DISCONNECTION_INDICATION			>
	;
	; First of all, do a status indication for IrLMP
	;
		mov	cx, ISIT_DISCONNECTED
		call	StatusIndication
	;
	; stop timers( MODIFICATION-TO-ORIGINAL-SPEC )
	;
		mov_tr	bp, ax			; store IrlapCondition in bp
		push	ax, bx
		movdw	axbx, ds:IS_pTimer
		call	TimerStop
		movdw	axbx, ds:IS_fTimer
		call	TimerStop
		pop	ax, bx
	;
	; Determine whether we have unacked data
	;
		clr	cx
		cmp	ax, IC_CONNECTION_FAILURE
		je	noUnackedData
		cmp	ax, IC_MEDIA_BUSY
		je	noUnackedData
	;
	; Make a IrlapUnackedData info block
	
		mov	ax, size IrlapUnackedData
		mov	cl, mask HF_SWAPABLE
		mov	ch, mask HAF_ZERO_INIT or \
			    mask HAF_LOCK or \
			    mask HAF_NO_ERR
		call	MemAlloc		; bx = handle, ax = segment
		mov	cx, bx			; cx = handle
		mov	es, ax			; es = IrlapUnackedData
	;
	; Store all unacked data into IrlapUnackedData info Block
	;
		clr	ax			; unacked data counter
		mov	di, offset IUD_optrArray; unacked data optr array start
	;
	; Find the beginning of the unacked data sequence
	;
		call	FindFirstUnackedDataFrame	; bx = index to the
		jc	zeroUnackedData			;   first unacked data
unackedDataLoop:
	;
	; Found an unacked data
	;
		inc	ax

		movm	es:[di].UF_dataOffset,\
			ds:[IS_store][bx].IW_extended.EIW_dataOffset, dx
if _SOCKET_INTERFACE
		movm	es:[di].UF_seqInfo, \
			ds:[IS_store][bx].IW_extended.EIW_seqInfo, dx
endif ;_SOCKET_INTERFACE
		movm	es:[di].UF_size, ds:[IS_store][bx].IW_size, dx
		movdw	es:[di].UF_optr, ds:[IS_store][bx].IW_buffer, dx
		add	di, size UnackedFrame	
checkNext:
		add	bl, IrlapWindowIndexInc		; bx = next elt in 
		and	bl, IrlapWindowIndexRange	;      circular buff
		test	ds:[IS_store][bx].IW_flags, mask IWF_VALID
		jnz	unackedDataLoop
zeroUnackedData:
	;
	; Store the number of unacked data found
	;
		mov	es:IUD_numUnackedFrames, ax
		mov	bx, cx
		call	MemUnlock
noUnackedData:
		mov_tr	ax, bp
		mov	bx, ds:IS_clientHandle
		pushdw	ds:IS_clientCallback
		mov	di, NII_DISCONNECT_INDICATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		
if	IRLAP_STAT
	;
	; write out statistics data to INI file
	;
		call	IrlapWriteStatistics
endif
		.leave
		ret
DisconnectIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindFirstUnackedDataFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find first unacked data frame in IS_store field

CALLED BY:	DisconnectIndication
PASS:		ds	= station
RETURN:		bx	= offset to first unacked data frame in IS_store
		carry set if there is no unacked data
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindFirstUnackedDataFrame	proc	near
		uses	cx
		.enter
	;
	; Start from the window right before the current Vs window
	;
		clr	bh
		mov	bl, ds:IS_vs
		sub	bl, IrlapVsIncrement
		and	bl, mask IICF_NS	; frame right before current Vs
		shl3	bl			; convert Vs to window index
		test	ds:[IS_store][bx].IW_flags, mask IWF_VALID
		jz	noUnackedData
	;
	; Scan backward to find an invalid frame
	;
scanLoop:
		mov	cl, bl			; current window index in CL
		sub	bl, IrlapWindowIndexInc
		and	bl, IrlapWindowIndexRange
		test	ds:[IS_store][bx].IW_flags, mask IWF_VALID
		jz	done
		jmp	scanLoop
noUnackedData:
		stc
done:
	;
	; CL = first unacked data index
	;
		mov	bl, cl
		.leave
		ret
FindFirstUnackedDataFrame	endp

	
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The remote side agreed to connect to us

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		es    = dgroup
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConnectConfirm	proc	far
		uses	bx,cx,dx,di
		.enter
EC <		WARNING	_CONNECTION_CONFIRM				>
	;
	; also do a status indication
	;
		mov	cx, ISIT_CONNECTED
		call	StatusIndication
	;
	; Notify the client
	;
		movdw	cxdx, ds:IS_devAddr
		mov	bx, ds:IS_clientHandle
		pushdw	ds:IS_clientCallback
		mov	si, offset IS_connectionParams
	;
	; ds:si = IrlapConnectionParams( already negotiated )
	;
		mov	di, NII_CONNECT_CONFIRMATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		.leave
		ret
ConnectConfirm	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscoveryIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remote side requested discovery

CALLED BY:	Discovery routines
PASS:		ds	= station
		ax	= DiscoveryLogFlags to send
		es:di	= fptr to IrlapDiscoveryXidFrame received
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscoveryIndication	proc	far
		uses	ax,bx,di,si
		.enter
EC <		WARNING	_DISCOVERY_INDICATION				>
	;
	; if this is not an indication for remote services, just return
	; flags in ax
	;
		test	ax, mask DLF_REMOTE
		jz	abnormalTermination
	;
	; make es:di = start of DiscoveryLog buffer
	; modify the contents of DiscoveryLog buffer
	; notify the client
	;
		mov	si, di
		add	si, (size IrlapDiscoveryXidFrame - size DiscoveryLog)
		movdw	es:[si].DL_devAddr, es:[di].IDXF_srcDevAddr, bx
		mov	es:[si].DL_flags, ax
abnormalTermination:
		mov	bx, ds:IS_clientHandle
		pushdw	ds:IS_clientCallback
		mov	di, NII_DISCOVERY_INDICATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		
		.leave
		ret
DiscoveryIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscoveryConfirm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Discovery procedure has ended and we obtained discoveryLogs

CALLED BY:	Various discovery routines
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscoveryConfirm	proc	far
		uses	bx,dx,di
		.enter
EC <		WARNING	_DISCOVERY_CONFIRM				>
	;
	; Notify the client
	;
		mov	dx, ds:IS_discoveryLogBlock
		mov	bx, ds:IS_clientHandle
		pushdw	ds:IS_clientCallback
		mov	di, NII_DISCOVERY_CONFIRMATION
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	;
	; reset last receipt time
	;
		push	ax
		call	TimerGetCount		; bxax = sys counter
		subdw	bxax, IRLAP_CHECK_BUSY_TICKS
		movdw	ds:IS_lastReceiptTime, bxax
		pop	ax
		
		.leave
		ret
DiscoveryConfirm	endp


; ****************************************************************************
; ****************************************************************************
; **********************   Transfer-related Actions   ************************
; ****************************************************************************
; ****************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendUnitdata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends unitdata

CALLED BY:	UnitdataRequest routines
PASS:		ds	= station
		al	= IrLAP connection address
			  if client is native client
			  	Always IRLAP_BROADCAST_CONNECTION_ADDR
		cx	= UnitdataRequestParams
		dxbp	= data buffer
RETURN:		nothing
DESTROYED:	everything but es, ds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendUnitdata	proc	far
		uses	es
		.enter
	;
	; Lockdown the DataRequestParams buffer to get real packet buffer
	; and the rest of the parameters
	;
		call	IrlapUnwrapDataRequestParams
	;
	; -->
	; dxbp	= data packet
	; si	= data offset
	; di	= seqInfo
	;
		
	;
	; Adjust address according to IrlapDataRequestType
	;
if _SOCKET_INTERFACE
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jnz	cont1
endif ;_SOCKET_INTERFACE
		or	al, IRLAP_BROADCAST_CONNECTION_ADDR
		test	di, mask IDRT_EXPEDITED
		jz	cont1
		mov	al, ds:IS_connAddr
cont1:
		push	bp			; save data packet chunk handle
		push	di			; save seqInfo
	;
	; Lock down the buffer and get parameters for IrlapSendUFrame
	;
		IrlapLockPacket	esdi, dxbp
		add	di, si
		mov	bx, cx			; bx = size of data
		and	bx, mask URP_DATASIZE
		BitClr	cl, IUCF_PFBIT
		test	cx, mask URP_PFBIT
		jz	noPfBit
		mov	cl, mask IUCF_PFBIT
noPfBit:
		and	cl, mask IUCF_PFBIT
		or	cl, IUC_UI_CMD		; the same as IUR_UI_RSP
		mov	ch, al			; cr bit should've been set
		pop	bp			; bp = seqInfo
		call	IrlapSendUFrame
		cmp	bx, bp			; compare dataSize and seqInfo
		pop	cx			; cx = data packet chunk handle
		IrlapUnlockPacket dx, bx
		jne	done
	;
	; Last frame: free the data packet
	;
		mov_tr	ax, dx			; axcx = hugelmem chunk
		call	HugeLMemFree
done:
		.leave
		ret
SendUnitdata	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDataWithPFbitClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send an I packet with PFbit clear

CALLED BY:	Various Information sending routines
PASS:		ds	= station
		cx	= data size
		dx:bp	= RequestDataParams block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Store[Vs] := data
		Ack[Vs] := false
		Send i:Vr:Vs:~P:data
		Vs := Vs + 1 mod 8
		window := window - 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendDataWithPFbitClear	proc	far
		uses	ax, bx, cx, es, di, si
		.enter
	;
	; Get parameters from parameter block
	;
		call	IrlapUnwrapDataRequestParams	; dxbp = data buffer
							; si = data offset
							; di = seqInfo
	;
	; parameters:
	;	dxbp = data buffer
	;	di   = seqInfo
	;	si   = dataOffset
	;	cx   = dataSize
	;
		
	;
	; Store[Vs] := data
	;
		clr	bh
		mov	bl, ds:IS_vs		; Vs is stored in bits 1 - 3
		shl3	bl			; si = Vs * size IrlapWindow
		movdw	ds:[IS_store][bx].IW_buffer, dxbp
		mov	ds:[IS_store][bx].IW_size, cx	
		mov	ds:[IS_store][bx].IW_extended.EIW_dataOffset, si

if _SOCKET_INTERFACE
		mov	ds:[IS_store][bx].IW_extended.EIW_seqInfo, di

	;
	; Check for the last fragment of a packet
	;
		BitSet	ds:[IS_store][bx].IW_flags, IWF_LAST_FRAGMENT
		cmp	cx, di
		je	lastFragment
	;
	; there are more fragments to be sent in buffer, so do not deallocate
	; this buffer even if we are done with it.
	;
		BitClr	ds:[IS_store][bx].IW_flags, IWF_LAST_FRAGMENT
lastFragment:

endif ;_SOCKET_INTERFACE

	;
	; Ack[Vs] := false
	;
		BitClr	ds:[IS_store][bx].IW_flags, IWF_ACK
		BitSet	ds:[IS_store][bx].IW_flags, IWF_VALID
	;
	; Send i:Vr:Vs:~P:data
	;
		clr	ax
		xchg	bx, ax			; ax = Vs * size IrlapWindow
		xchg	bx, cx			; cl = 0; bx = data size
		push	di
		IrlapLockPacket	esdi, dxbp
		pop	bp			; bp = seq info
		add	di, si			; add dataOffset
		call	IrlapSendIFrame
		IrlapUnlockPacket dx, bx
		mov_tr	bx, ax
	;
	; Vs := Vs + 1 mod 8
	;
		IncVs	ds
	;
	; window := window - 1
	;
		dec	ds:IS_window
		
		.leave
		ret
SendDataWithPFbitClear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDataWithPFbitSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends an I frame with P/F bit set

CALLED BY:	Various routines that sends data
PASS:		ds	= station
		al	= IrlapStationType
		cx	= data size
		dx:bp	= optr to DataRequestParam (hugelmem chunk)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if al = IST_PRIMARY
		Stop-P-Timer
	Store[Vs] := data
	Ack[Vs] := false
	Send i:Vr:Vs:P:data
	Vs := Vs + 1 mod 8
	window := windowSize
	if al = IST_PRIMARY
		Start-F-Timer
	else
		Start-WD-Timer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendDataWithPFbitSet	proc	far
		uses	ax, bx, cx, si, es, di, si, bp
		.enter
	;
	; Get parameters from parameter block
	;
		call	IrlapUnwrapDataRequestParams	; dxbp = data buffer
							; si = data offset
							; di = seqInfo
	;
	; parameters:
	;	dxbp = data buffer
	;	di   = seqInfo
	;	si   = dataOffset
	;	cx   = dataSize
	;
		
	;
	; Stop-P-Timer if primary
	;
		cmp	ds:IS_state, IMS_XMIT_P
		jne	notPrimary
		movdw	axbx, ds:IS_pTimer
		call	TimerStop
notPrimary:
	;
	; Store[Vs] := data
	;
		clr	bh
		mov	bl, ds:IS_vs		; Vs is stored in bits 1 - 3
		shl3	bl			; si = Vs * size IrlapWindow
		movdw	ds:[IS_store][bx].IW_buffer, dxbp
		mov	ds:[IS_store][bx].IW_size, cx
		mov	ds:[IS_store][bx].IW_extended.EIW_dataOffset, si

if _SOCKET_INTERFACE
		mov	ds:[IS_store][bx].IW_extended.EIW_seqInfo, di
	;
	; Check for the last fragment of a packet.  We don't know 
	; the current status of the flags so assume it's the last 
	; packet and set the bit.  
	;
		BitSet	ds:[IS_store][bx].IW_flags, IWF_LAST_FRAGMENT
		cmp	cx, di
		je	lastFragment
		BitClr	ds:[IS_store][bx].IW_flags, IWF_LAST_FRAGMENT
lastFragment:

endif ;_SOCKET_INTERFACE
	;
	; Ack[Vs] := false
	;
		BitClr	ds:[IS_store][bx].IW_flags, IWF_ACK
		BitSet	ds:[IS_store][bx].IW_flags, IWF_VALID
	;
	; Send i:Vr:Vs:P:data
	;
		mov	ax, mask IICF_PFBIT
		xchg	bx, ax			; ax = Vs * size IrlapWindow
		xchg	bx, cx			; cl = Pbit set; bx = data size
		push	di
		IrlapLockPacket	esdi, dxbp
		pop	bp			; bp = seqInfo
		add	di, si			; add dataOffset
		call	IrlapSendIFrame
		IrlapUnlockPacket dx, bx
		mov_tr	bx, ax			; restore Vs
	;
	; Vs := Vs + 1 mod 8
	;
		IncVs	ds
	;
	; window := windowSize
	;
		movm	{byte}ds:IS_window, {byte}ds:IS_remoteMaxWindows, al
	;
	; Start appropriate timer
	;
		cmp	ds:IS_state, IMS_XMIT_P
		jne	secondary
	;
	; Start-F-Timer
	;
		call	StartFTimer
		jmp	done
secondary:
		call	StartWDTimer
done:
		.leave
		ret
SendDataWithPFbitSet	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateNrReceived
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge and free packets through Nr received

CALLED BY:	Xfer routines
PASS:		ds	= station
		cl	= C field of incoming data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	i := Nr - 1
	While (Window[i] is valid) {
		Ack[i] := true
		Valid[i] := false
		Free Window[i].packet
		i := i - 1 mod 8
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateNrReceived	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; i := Nr - 1
	;
		clr	bh
		mov	bl, cl
		and 	bl, mask IICF_NR
		sub	bl, IrlapNrIncrement	; bl = Nr - 1
		and 	bl, mask IICF_NR
		shr	bl, 1			; bl = (Nr-1) * sz IrlapWindow
ackLoop:
		test	ds:[IS_store][bx].IW_flags, mask IWF_VALID
		jz	done
	;
	; Mark acked, and free the buffer
	;
		BitSet	ds:[IS_store][bx].IW_flags, IWF_ACK
		BitClr	ds:[IS_store][bx].IW_flags, IWF_VALID

if _SOCKET_INTERFACE
	;
	; If this is the last fragment of a packet, deallocate the buffer;
	; otherwise keep the buffer since there are still other unacked
	; fragments in this buffer.
	;
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jz	nativeClient
		test	ds:[IS_store][bx].IW_flags, mask IWF_LAST_FRAGMENT
		jz	skipFree
nativeClient:

endif ;_SOCKET_INTERFACE
		clr	ax, cx
		xchgdw	axcx, ds:[IS_store][bx].IW_buffer
		call	HugeLMemFree
skipFree::
	;
	; bx = bx - size IrlapWindow ( wrapping around )
	;
		sub	bl, IrlapWindowIndexInc
		and	bl, IrlapWindowIndexRange
		jmp	ackLoop
done:
		.leave
		ret
UpdateNrReceived	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResendRejFrames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resend rejected frames from Nr up to Vs
		Note: Nr is guarenteed to be neq to Vs

CALLED BY:	Xfer routines
PASS:		ds 	= station
		cl	= C field of the received packet
RETURN:		nothing
DESTROYED:	nothing
PSEUDO CODE:
	i := Nr
	while ( i != Vs ) {
		if (i+1 = Vs)
			resend Window[i] with P bit on
		else
			resend Window[i] with P bit off
		i := i + 1 mod 8
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResendRejFrames	proc	far
		uses	ax,bx,cx,dx,bp,es
		.enter
	;
	; Get Vs ( when we hit this value, we stop resending )
	;
		mov	ch, ds:IS_vs
		and	cx, mask IICF_NS shl 8 or mask IICF_NR
	;
	; Assign new Vs ( This is Nr received )
	;
		mov	bl, cl
		ror4	bl			; bl = new Ns
		mov	ds:IS_vs, bl		;
		shr	cl, 1			; cl = Nr * size IrlapWindow
		shl3	ch			; ch = Vs * size IrlapWindow
EC <		cmp	ch, cl						>
EC <		ERROR_E	-1						>
	;
	; bx = index into window array
	;
		mov	bl, cl
sendLoop:
		clr	bh			
		cmp	bl, ch			; check if we reached a window
		je	done			; that has never been sent out
	;
	; If this is the last packet, set F bit on
	;
		mov	cl, bl
		add	cl, IrlapWindowIndexInc
		and	cl, IrlapWindowIndexRange
		mov	ah, cl			; save next window
		cmp	cl, ch
		je	lastPacket
		clr	cl
		jmp	resendBuffer
lastPacket:
		mov	cl, mask IICF_PFBIT
resendBuffer:
	; XXX: If Nr received from remote is invalid?
	; 
		movdw	dxbp, ds:[IS_store][bx].IW_buffer ; cl = PFbit
		tst	dx
		jz	done
		IrlapLockPacket	esdi, dxbp		 ; esdi = buffer
	;
	; If we are in socketLib client mode, we also need to worry about
	; segmentation of packets
	;
if _SOCKET_INTERFACE
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jz	nativeClient
		mov	bp, ds:[IS_store][bx].IW_extended.EIW_seqInfo
endif ;_SOCKET_INTERFACE

nativeClient:
		add	di, ds:[IS_store][bx].IW_extended.EIW_dataOffset
		mov	bx, ds:[IS_store][bx].IW_size	 ; bx = size
		call	IrlapSendIFrame
		IncVs	ds
		IrlapUnlockPacket dx, bx
		mov_tr	bl, ah			; bl = ah = next window
		jmp	sendLoop
done:
		.leave
		ret
ResendRejFrames	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResendSrejFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resend one rejected frame.  Implements selective-repeat.

CALLED BY:	RecvSrejRspRECV_P
PASS:		cl = control field/Nr of the packet recv indicating rej.
		ds:si = station
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResendSrejFrame	proc	far
		uses	bx,cx,dx,bp,es,di
		.enter
	;
	; Get Nr
	;
		mov	bl, cl
		and	bx, 0 shl 8 or mask IICF_NR
		shr	bl, 1			; bx = Nr * size IrlapWindow
	;
	; Send I packet with P bit on
	;
		movdw	dxbp, ds:[IS_store][bx].IW_buffer
		IrlapLockPacket	esdi, dxbp
	;
	; If we are in socketLib client mode, we also need to worry about
	; segmentation of packets
	;
if _SOCKET_INTERFACE
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jz	nativeClient
		mov	bp, ds:[IS_store][bx].IW_extended.EIW_seqInfo
endif ;_SOCKET_INTERFACE

nativeClient:
	;
	; Do not use IrlapSendIFrame since that routine uses current Vr/Vs
	; value.  Resend rejected frame with our current Nr value
	;
		add	di, ds:[IS_store][bx].IW_extended.EIW_dataOffset
		mov	cx, ds:[IS_store][bx].IW_size
		mov	ah, ds:IS_connAddr
		mov	al, bl			; al = rejected Nr shr 1
		shr	al, 1
		shr	al, 1			; all other fields are 0
		shr	al, 1			; al = adjusted into Ns pos
		or	al, ds:IS_vr
		or	al, mask IICF_PFBIT
		mov	bx, ds:IS_serialPort
		call	IrlapSendPacket
		IrlapUnlockPacket dx, bx
		
		.leave
		ret
ResendSrejFrame	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReleaseBufferedData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release data frames that are stored in IS_store.
		These frames have not yet been acknowledged.

CALLED BY:	various Xfer routines
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for i := 0 to 7	( maxWindows ) {
			Release Window[i]
			BitSet Ack[i]
			BitClr Valid[i]
		}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReleaseBufferedData	proc	far
		uses	ax,bx,cx,dx
		.enter
EC <		WARNING	_RELEASE_BUFFERED_DATA				>
	;
	; Release Loop
	;
		mov	bx, offset IS_store
		mov	dx, IRLAP_MAX_WINDOWS
		ror4	dl			; dx = last window
		add	dx, bx
		sub	bx, size IrlapWindow
releaseLoop:
		add	bx, size IrlapWindow
		cmp	bx, dx
		jae	done
		test	ds:[bx].IW_flags, mask IWF_VALID
		jz	releaseLoop
		BitClr	ds:[bx].IW_flags, IWF_VALID
		BitSet	ds:[bx].IW_flags, IWF_ACK

if _SOCKET_INTERFACE
	;
	; Release buffer only if it is the last fragment of a packet
	;
		test	ds:IS_status, mask ISS_SOCKET_CLIENT
		jz	nativeClient

		test	ds:[bx].IW_flags, mask IWF_LAST_FRAGMENT
		jz	skipFree
nativeClient:

endif ;_SOCKET_INTERFACE

		clr	ax, cx
		xchgdw	axcx, ds:[bx].IW_buffer
		call	HugeLMemFree
skipFree::
		jmp	releaseLoop
done:
		.leave
		ret
ReleaseBufferedData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopAllTimers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops P and F timer on primary, WD timer on secondary
		(notice that WD = P timer on secondary,  but it doesn't
		hurt to stop F timer which has no meaning on secondary)

CALLED BY:	
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopAllTimers	proc	far
		uses	ax, bx
		.enter
EC <		WARNING _STOP_ALL_TIMERS				>
		clr	ds:IS_retryCount
		movdw	axbx, ds:IS_pTimer
		call	TimerStop
		movdw	axbx, ds:IS_fTimer
		call	TimerStop
		.leave
		ret
StopAllTimers		endp

; ****************************************************************************
; ****************************************************************************
; ************    Connection parameters and negotiation Utility    ***********
; ****************************************************************************
; ****************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrepareNegotiationParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare negotiation parameters and fill in 
		IS_connectionParams of station with local connection 
		params.

CALLED BY:	ConnectRequestNDM, ConnectResponseCONN
PASS:		ds 	= station
		^lcx:bp	= QualityOfService struct (HugeLMem buffer)
			  with local connection parameters.
RETURN:		cxbp 	= dev address that was in QOS struct
		ds:IS_connectionParams filled in

DESTROYED:	nothing
SIDE EFFECT:
		hugeLMem buffer in cxbp was freed

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrepareNegotiationParams	proc	far
		uses	ax,bx,dx,si,di,es,ds
		.enter
		
		segmov	es, ds, ax			;es = station
		mov	di, offset IS_connectionParams	;es:di = 
							;  IS_connectionParams

		IrlapLockPacket dssi, cxbp
		pushdw	ds:[si].QOS_devAddr		; save devAddr to return
		test	ds:[si].QOS_flags, mask QOSF_DEFAULT_PARAMS
		jnz	defaultParams

		push	cx
		mov	cx, size IrlapConnectionParams
		rep movsb	; copy conn params into IS_connctionParams
		pop	cx		

unlockDone:
		IrlapUnlockPacket cx, bx
		mov	ax, cx
		mov	cx, bp
		call	HugeLMemFree
		popdw	cxbp				;return cxbp = devAddr
		.leave
		ret

defaultParams:
		mov	bx, handle IrlapStrings
		call	MemLock
		mov	ds, ax
		call	InitializeNegotiationParams	; read from .ini file
		call	MemUnlock
		jmp	unlockDone
		
PrepareNegotiationParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetConnectionParamsInBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies current connection parameters in the buffer passed in

CALLED BY:	IrlapSendSnrmFrame, IrlapSendUAFrame
PASS:		ds	= station
		es:si	= fixed buffer for 7 connection parameters
RETURN:		nothing ( buffer filled in with the current connection
			  parameters )
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetConnectionParamsInBuffer	proc	near
		uses	si
		.enter
		
		mov	es:[si].IP_id, IRLAP_BAUD_RATE
		mov	es:[si].IP_len, 1
		movm	es:[si].IP_val, ds:IS_connectionParams.ICP_baudRate, al

		add	si, size IrlapParam
		mov	es:[si].IP_id, IRLAP_MAX_TURN_AROUND
		mov	es:[si].IP_len, 1
		movm	es:[si].IP_val, \
			ds:IS_connectionParams.ICP_maxTurnAround, al

		add	si, size IrlapParam
		mov	es:[si].IP_id, IRLAP_DATA_SIZE
		mov	es:[si].IP_len, 1
		movm	es:[si].IP_val, \
			ds:IS_connectionParams.ICP_dataSizeIn, al

		add	si, size IrlapParam
		mov	es:[si].IP_id, IRLAP_WINDOW_SIZE
		mov	es:[si].IP_len, 1
		movm	es:[si].IP_val, \
			ds:IS_connectionParams.ICP_windowSizeIn, al

		add	si, size IrlapParam
		mov	es:[si].IP_id, IRLAP_NUM_BOF
		mov	es:[si].IP_len, 1
		movm	es:[si].IP_val, ds:IS_connectionParams.ICP_numBof, al

		add	si, size IrlapParam
		mov	es:[si].IP_id, IRLAP_MIN_TURN_AROUND
		mov	es:[si].IP_len, 1
		movm	es:[si].IP_val, \
			ds:IS_connectionParams.ICP_minTurnAround, al

		add	si, size IrlapParam
		mov	es:[si].IP_id, IRLAP_LINK_DISCONNECT
		mov	es:[si].IP_len, 1
		movm	es:[si].IP_val, \
			ds:IS_connectionParams.ICP_linkDisconnect, al
		.leave
		ret
GetConnectionParamsInBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindParameterInSnrmFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds the location of a parameter in an SNRM frame

CALLED BY:	NegotiateConnectionParameters

PASS:		ds	= station segment
		es:di	= PacketHeader for SNRM frame buffer
		al	= IrlapParamIdVal to find
RETURN:		carry set if not found
		es:si	= frame found
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindParameterInSnrmFrame	proc	near
		uses	ax,bx,cx,dx
		.enter
		mov	dx, di
		add	dx, es:[di].PH_dataOffset	;es:dx = start of I 
							;  field.
		mov	si, dx				;es:si = start of I
							;  field
		add	dx, es:[di].PH_dataSize		;dx = one byte beyond
							;  last byte of the
							;  I field.
	;
	; Determine whether we looking at SNRM frame or UI frame
	; and go to the proper beginning of negotiation parameters
	;
		mov	bx, ds:IS_state
		cmp	bx, IMS_CONN
		je	snrmFrame
		cmp	bx, IMS_SNIFF
		je	snrmFrame
		cmp	bx, IMS_NDM
		je	snrmFrame
		cmp	bx, IMS_SETUP
		je	uiFrame
		cmp	bx, IMS_SSETUP
		je	uiFrame
EC <		WARNING IRLAP_HACK_FAILED				>
snrmFrame:
	;
	; We are looking at SNRM frame in connection procedure.  
	; Skip to negotiation parameters.
	;
		add	si, offset ISF_negotiationParams
							;es:si = params
		jmp	findLoop
uiFrame:
	;
	; we are looking at UI frame in connection procedure
	;
		add	si, offset IUSF_negotiationParams
							;es:si = params 
findLoop:
		cmp	si, dx			;check if we've past the end
		jae	notFound		;CF clear if greater or equal
		cmp	al, es:[si].IP_id	;CF clear if greater or equal
		je	found
		clr	bh
		mov	bl, es:[si].IP_len	; index+= length of value
		add	si, bx
		add	si, size IrlapParam - 1	; -1 accounts for IP_val
						; which was actually
						; defined as 1 byte
		jmp	findLoop
notFound:
		stc
found:
		.leave
		ret
FindParameterInSnrmFrame	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetParamsInQOSBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get parameters out of a SNRM frame and put in a
		IrlapConnectionParams structure

CALLED BY:	ConnectIndication
PASS:		ds	= station segment
		ds:bp	= IrlapConnectionParams buffer
		es:di	= entire snrm packet( including PacketHeader etc )
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetParamsInQOSBuffer	proc	far
		uses	ax,si
		.enter
		mov	al, IRLAP_BAUD_RATE
		call	FindParameterInSnrmFrame
		mov	al, es:[si].IP_val
		mov	{byte}ds:[bp].ICP_baudRate, al
		
		mov	al, IRLAP_MAX_TURN_AROUND
		call	FindParameterInSnrmFrame
		mov	al, es:[si].IP_val
		mov	{byte}ds:[bp].ICP_maxTurnAround, al
		
		mov	al, IRLAP_DATA_SIZE
		call	FindParameterInSnrmFrame
		mov	al, es:[si].IP_val
		mov	{byte}ds:[bp].ICP_dataSize, al
		
		mov	al, IRLAP_WINDOW_SIZE
		call	FindParameterInSnrmFrame
		mov	al, es:[si].IP_val
		mov	{byte}ds:[bp].ICP_windowSize, al
		
		mov	al, IRLAP_NUM_BOF
		call	FindParameterInSnrmFrame
		mov	al, es:[si].IP_val
		mov	{byte}ds:[bp].ICP_numBof, al
		
		mov	al, IRLAP_MIN_TURN_AROUND
		call	FindParameterInSnrmFrame
		mov	al, es:[si].IP_val
		mov	{byte}ds:[bp].ICP_minTurnAround, al
		
		mov	al, IRLAP_LINK_DISCONNECT
		call	FindParameterInSnrmFrame
		mov	al, es:[si].IP_val
		mov	{byte}ds:[bp].ICP_linkDisconnect, al
		.leave
		ret
GetParamsInQOSBuffer	endp

endif ; 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapBusyDetected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Busy condition was detected on IrLAP

CALLED BY:	IrlapRecv/IrlapSendPacket
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapBusyDetected	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		pushf
EC <		IrlapCheckStation	ds				>
	;
	; If MEMORY_SHORT was detected and was never cleared, we don't want
	; to post busy event again.
	;
		test	ds:IS_extStatus, mask IES_MEMORY_SHORT
		jnz	skip
detected::
	;
	; Send busy-deteceted event
	;
		mov	bx, ds:IS_eventThreadHandle
		mov	di, mask MF_FORCE_QUEUE
		clr	dx, bp
		mov	ax, (ILE_LOCAL_BUSY shl 8) or mask ILBV_DETECTED
		call	ObjMessage
	;
	; register with hugelmem
	;
		mov	ax, segment IrlapBusyClearCallback
		mov	cx, offset IrlapBusyClearCallback
		mov	bx, ds:IS_hugeLMemHandle
		mov	dx, ds
		call	HugeLMemWaitFreeSpace
	;
	; Set the flag that records memory short
	;
		BitSet	ds:IS_extStatus, IES_MEMORY_SHORT
skip:
EC <		inc	ds:IS_ranOutOfMemory				>
		popf
		.leave
		ret
IrlapBusyDetected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapBusyCleared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Busy condition was cleared in Irlap

CALLED BY:	IrlapBusyClearCallback
PASS:		ds 	= station segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapBusyCleared	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
EC <		IrlapCheckStation	ds				>
		mov	bx, ds:IS_eventThreadHandle
		mov	di, mask MF_FORCE_QUEUE
		clr	dx, bp
		mov	ax, (ILE_LOCAL_BUSY shl 8) or mask ILBV_CLEARED
		call	ObjMessage		
		BitClr	ds:IS_extStatus, IES_MEMORY_SHORT
		.leave
		ret
IrlapBusyCleared	endp

IrlapActionCode	ends

