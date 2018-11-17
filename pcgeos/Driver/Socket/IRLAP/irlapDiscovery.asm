COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		irlapDiscovery.asm

AUTHOR:		Cody Kwok, Mar 17, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	3/17/94   	Initial revision
	SJ	9/14/94		Rewrote everything

DESCRIPTION:
	Defines IRLAP-SIR discovery events and procedures.
		

	$Id: irlapDiscovery.asm,v 1.1 97/04/18 11:56:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapConnectionCode		segment	resource

;------------------------------------------------------------------------------
;				    NDM
;------------------------------------------------------------------------------

slotLookupTable	byte \
		1,		; IUTS_1_SLOT  = 0 (00b)
		6,		; IUTS_6_SLOT  = 1 (01b)
		8,		; IUTS_8_SLOT  = 2 (10b)
		16		; IUTS_16_SLOT = 3 (11b)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscoveryRequestNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received discovery request

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds	= station
		es	= dgroup
		ch	= IrlapDiscoveryType
		cl	= IrlapUserTimeSlot ( 0 - 3 )
				IUTS_1_SLOT 
				IUTS_6_SLOT 
				IUTS_8_SLOT
				IUTS_16_SLOT
		if ch = IDT_ADDRESS_RESOLUTION
			dxbp	= target device address
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	maxSlot := (S-1)
	slotCount := 0
	send Discovery-XID-Cmd:maxSlot, slotCount
	start-slot-timer
	log := {0}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/14/94		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscoveryRequestNDM	proc	far
		.enter
	;
	; [Check media busy]
	;
		call	IrlapCheckMediaBusy
		jnc	mediaNotBusy
	; 
	; Discovery-Indication(media-busy)
	; 
		mov	ax, mask DLF_MEDIA_BUSY
		call	DiscoveryIndication
		jmp	done
mediaNotBusy:
	;
	; [Initialize discovery variables]
	;
		clr	bh
		mov	bl, cl			; bl = IrlapUserTimeSlot
		mov	di, bx
		add	di, offset slotLookupTable
		mov	cl, {byte}cs:[di]	; cl = integer corresponding to
	; 
	; maxSlot = (S-1)
	; 
		dec	cl			; S-1
		mov	ds:IS_maxSlot, cl	; maxSlot = S-1
	; 
	; slotCount = 0
	; 
		clr	{byte}ds:IS_slotCount
	;
	; [initialize IS_discoveryXIDFrame]
	;
		mov	di, offset IS_discoveryXIDFrame
		mov	ds:[di].IDXF_formatID, IXFI_DISCOVERY_XID
		movdw	ds:[di].IDXF_srcDevAddr, ds:IS_devAddr, ax
		mov	ds:[di].IDXF_destDevAddr.high, 0xffff
		mov	ds:[di].IDXF_destDevAddr.low, 0xffff
		mov	ds:[di].IDXF_xidFlags, bl		
		mov	ds:[di].IDXF_version, IDXF_VERSION_1_0
		BitClr	ds:[di].IDXF_xidFlags, IXDF_GEN_NEW_DEV_ADDR
	;
	; [Address resolution?]
	;
		cmp	ch, IDT_ADDRESS_RESOLUTION
		jne	continue
		movdw	ds:[di].IDXF_destDevAddr, dxbp		; target dev
		BitSet	ds:[di].IDXF_xidFlags, IXDF_GEN_NEW_DEV_ADDR
continue:
	; 
	; Send discovery-XID-Cmd:maxSlot, slot count
	; [ds = station]
	;
		call	SendDiscoveryXIDCmdFrame	; nothing destroyed
	;
	; Start-Slot-Timer
	;
		call	StartSlotTimer		; nothing destroyed
	;
	; log := {}
	; [ allocate a new block -- we want the discovery information to be
	;			    available for some time ]
	;
		tst	ds:IS_discoveryLogBlock
		jz	skipFree
		mov	bx, ds:IS_discoveryLogBlock
		call	MemFree
skipFree:
	;
	; [ Q:Should I just allocate one block and use it until we exit? ]
	;
		inc	cl			; cl = max. number of slots.
		mov	ax, size DiscoveryLog
		mul	cl			; ax= sz discoveryLog x maxSlot
		clr	dh
		mov_tr	dl, cl			; dx = maxSlots
		add	ax, size DiscoveryLogBlock
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or \
			    (mask HAF_ZERO_INIT shl 8) or \
			    mask HF_SHARABLE
		call	MemAlloc		; ax = segment, bx = handle
		mov	es, ax			;
		mov	es:DLB_blockHandle, bx	;
		mov	ds:IS_discoveryLogBlock, bx
		call	MemUnlock
	;
	; NEXT STATE = QUERY
	;
		ChangeState	QUERY, ds
done:
		.leave
		ret
DiscoveryRequestNDM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscoveryXidCmdNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	(Secondary)
		Received a broadcast discovery frame from remote primary
		Consist of events:
		recv Discovery-XID-Cmd:s
		recv Discovery-Slot-XID-Cmd:s
		Recv End-Discovery-XID-Cmd

CALLED BY:	IrlapMessageProcessCallback
PASS:		ds	= Station getting this event
		es 	= dgroup
		dx:bp	= HugeLMem optr of PacketHeader for 
			  IrlapDiscoveryXidFrame
RETURN:		nothing
DESTROYED:	ax
PSEUDO CODE/STRATEGY:
	slot := random(S,s)
	if (slot = 0)
		Send-discovery-XID-Rsp:NA, discoveryInfo
		fragmentSent = true
	else
		fragmentSent = false
	Start-Query-Timer
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	4/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscoveryXidCmdNDM	proc	far
		uses	dx
		.enter
	;
	; [Copy remote XID frame information]
	;
		IrlapLockPacket	esdi, dxbp
		add	di, es:[di].PH_dataOffset
	;
	; check source device address
	;
		movdw	bxsi, es:[di].IDXF_srcDevAddr
		cmpdw	bxsi, IRLAP_NULL_DEV_ADDR
		je	wrongAddr
		cmpdw	bxsi, IRLAP_BROADCAST_DEV_ADDR
		je	wrongAddr
	;
	; check destination device address
	;
		movdw	bxsi, es:[di].IDXF_destDevAddr
		cmpdw	bxsi, ds:IS_devAddr
		je	skipBroadcastCheck	; this is addr resolution
		cmpdw	bxsi, IRLAP_BROADCAST_DEV_ADDR
		jne	wrongAddr
skipBroadcastCheck:
	;
	; check XID formatID
	;
		mov	bl, es:[di].IDXF_formatID
		cmp	bl, IXFI_DISCOVERY_XID
		jne	wrongFormat
		mov	ds:IS_discoveryXIDFrame.IDXF_formatID, bl
	;
	; fill in xid frame in our station structure
	;
		movm	ds:IS_discoveryXIDFrame.IDXF_xidFlags, \
			es:[di].IDXF_xidFlags, al
		movdw	ds:IS_discoveryXIDFrame.IDXF_destDevAddr, \
			es:[di].IDXF_srcDevAddr, ax
	;
	; we assume that even if version number is different,
	; implementation is backward compatible ( version number checking was
	; therefore removed from this section of the code )
	;

	;
	; [check "generate a new device address" bit]
	;
		clr	ah
		mov	al, es:[di].IDXF_xidFlags
		mov	cl, al
		andnf	al, mask IXDF_NUM_SLOTS
		test	cl, mask IXDF_GEN_NEW_DEV_ADDR	; cl= genNewAddr flag
		jz	normalDiscovery
	;
	; [Address resolution: generate new device address]
	;
		push	ax, dx				; ax = num slots index
		call	IrlapGenerateRandom32		; dxax = address
		movdw	ds:IS_devAddr, dxax
		pop	ax, dx				; dx = packet handle
normalDiscovery:
	;
	; ax = num slots index into slotLookupTable
	; cl = current slot number
	; unlock packet
	;
		mov	cl, es:[di].IDXF_slotNumber
		IrlapUnlockPacket dx, bx
	;
	; slot := Generate-Random-Time-Slot(S,s)
	;
		mov	di, ax
		mov	dl, {byte}cs:[slotLookupTable][di]
		mov	al, dl				; al = number of slots
		dec	dl				; range( 0 - #. slots )
		sub	dl, cl				; decrement by cur slot
		jc	exit				; invalid slot value
		call	IrlapGenerateRandom8		; dl = slot
		add	dl, cl				; range( s - S )
		mov	ds:IS_selectedSlot, dl
	;
	; [put source address in XID frame]
	;
		movdw	ds:IS_discoveryXIDFrame.IDXF_srcDevAddr, \
			ds:IS_devAddr, cx
	;
	; frameSent := false
	;
		BitClr	ds:IS_status, ISS_FRAME_SENT	; frameSent = false
		tst	dl
		jnz	startTimer
	;
	; if slot = 0, send Discovery-XID-Rsp:NA, discoveryInfo
	;
		call	SendDiscoveryXIDRspFrame
		BitSet	ds:IS_status, ISS_FRAME_SENT	; frameSent = true
startTimer:
	;
	; Start-Query-Timer
	;
NEC <		mov	cx, IRLAP_DISCOVERY_SLOT_TIMEOUT * 3		>
EC <		mov	cx, IRLAP_DISCOVERY_SLOT_TIMEOUT_EC * 6		>
		mul	cx				; dxax = timeout value
		mov	cx, ax				; cx = query timeout
		call	StartQueryTimer			; = slots * SlotTimeout
	;
	; NEXT STATE = REPLY
	;
		ChangeState	REPLY, ds
exit:
		.leave
		ret
		
wrongFormat:
wrongAddr:
EC <		WARNING IRLAP_RECEIVED_UNSUPPORTED_DISCOVERY_FRAME	>
		IrlapUnlockPacket dx, bx
		jmp	exit
		
RecvDiscoveryXidCmdNDM		endp


;------------------------------------------------------------------------------
;				   QUERY
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlotTimerExpiredQUERY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The slot timer expired (one shot).
		Send another slot.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds:si = station
		es    = dgroup
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	if (slotCount < maxSlot)
		slotCount := slotCount + 1
		send Discovery-XID-Cmd:maxSlot, slotCount
		start-slot-timer
	else
		send End-Discovery-XID-Cmd
		Discovery-Confirm(log)
		change to NDM
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlotTimerExpiredQUERY	proc	far
		.enter
	;
	; [check slot number]
	;
		mov	al, {byte}ds:IS_slotCount
		cmp	al, {byte}ds:IS_maxSlot
		jae	lastXidFrame
	;
	; slotCount := slotCount + 1
	;
		inc	{byte}ds:IS_slotCount
	;
	; send Discovery-XID-Cmd:maxSlot, slotCount
	;
		call	SendDiscoveryXIDCmdFrame
	;
	; Start-Slot-Timer
	;
		call	StartSlotTimer
		jmp	done
lastXidFrame:
	;
	; send End-Discovery-XID-Cmd
	;
		mov	{byte}ds:IS_slotCount, IRLAP_LAST_DISCOVERY_XID_SLOT
		call	SendDiscoveryXIDCmdFrame
	;
	; Discovery-Confirm
	;
		call	DiscoveryConfirm
	;
	; Next State = NDM
	;
		ChangeState	NDM, ds
done:		
		.leave
		ret
SlotTimerExpiredQUERY	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiscoveryAbortConditionQUERY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	(Primary)
		For some reasons I got an abort from somewhere,  so I stop
		discovery and finish up.

CALLED BY:	IrlapMessageProcessCallback
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	stop-slot-timer
	send End-Discovery-XID-Cmd
	Discovery-Indication(aborted)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DiscoveryAbortConditionQUERY		proc	far
		.enter
	;
	; Stop-Slot-Timer
	;
		call	StopSlotTimer
	;
	; Send End-Discovery-XID-Frame
	;
		mov	{byte}ds:IS_slotCount, 0xff
		call	SendDiscoveryXIDCmdFrame
	;
	; Discovery-Indication ( aborted )
	;
		mov	ax, mask DLF_ABORTED
		call	DiscoveryIndication
		
		.leave
		ret
DiscoveryAbortConditionQUERY	endp
ForceRef DiscoveryAbortConditionQUERY ; this never happens
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscoveryXidRspQUERY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	(Primary)
		Got a reply from remote; log it.

CALLED BY:	IrlapEventFromPacket
PASS:		ds	= station
		dx:bp	= HugeLMem optr to PacketHeader of block
RETURN:		nothing
DESTROYED:	ax, bx, cx, di, si, es (ds, dx, bp preserved)

PSEUDO CODE/STRATEGY:
	log := log U {<sa, info>}
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CK	4/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscoveryXidRspQUERY		proc	far
		uses	ds

		.enter
	;
	; [Get sa in dxbp, discoveryInfo in dssi, and slot number in cl]
	;
		segmov	es, ds, si
		IrlapLockPacket	dssi, dxbp
		push	dx, bp
		mov	ax, ds:[si].PH_dataSize
		add	si, ds:[si].PH_dataOffset	; dssi = I field
	;
	; check source device address
	;
		movdw	dxbp, ds:[si].IDXF_srcDevAddr	; dxbp = srcDevAddr
		cmpdw	dxbp, IRLAP_NULL_DEV_ADDR, ax
		je	wrongAddr
		cmpdw	dxbp, IRLAP_BROADCAST_DEV_ADDR, ax
		je	wrongAddr
	;
	; check XID formatID
	;
		cmp	ds:[si].IDXF_formatID, IXFI_DISCOVERY_XID
		jne	wrongFormat
	;
	; get other paramters
	;
		mov	cl, ds:[si].IDXF_slotNumber	; cl = slotNumber
		add	si, offset IDXF_discoveryInfo	; dssi = discoveryInfo
	; 
	; log := log U {<sa, info>}
	; 
		push	ax
		mov	bx, es:IS_discoveryLogBlock
		call	MemLock
		mov	es, ax
		clr	ah
		mov	al, es:DLB_lastIndex
		mov	cl, size DiscoveryLog
		mul	cl				; ax = next entry pos
		mov	di, ax				; di = next entry pos
		add	di, size DiscoveryLogBlock	; esdi= DiscoveryLog[s]
	;
	; [Fill in devAddr and info field]
	;
		pop	ax				; ax <- packet size
		sub	ax, offset IDXF_discoveryInfo
		mov	cl, offset DLF_INFO_SIZE
		shl	ax, cl
		ornf	ax, mask DLF_VALID or \
					  mask DLF_SOLICITED or \
					  mask DLF_REMOTE
		movdw	es:[di].DL_devAddr, dxbp
		mov	es:[di].DL_flags, ax
		add	di, offset DL_info		; esdi = infoField in
		mov	cx, size DiscoveryInfo		;        discoveryLog
		rep	movsb
		inc	es:DLB_lastIndex
		BitSet	es:DLB_flags, DBF_LOG_RCVD
		call	MemUnlock			;unlock discoveryLogBlk
wrongFormat:
wrongAddr:
	;
	; [Unlock the packet]
	;
		pop	dx, bp
		IrlapUnlockPacket dx, bx
		.leave
		ret
RecvDiscoveryXidRspQUERY		endp

;------------------------------------------------------------------------------
;				   REPLY
;------------------------------------------------------------------------------

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvDiscoveryXidCmdREPLY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	recv a "slot packet", respond.

IMPL NOTES:	if we get an XID frame which is not discovery, REPLY
		state's x:x:x:x said Empty,  so we just exit.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
		cx    = IrlapCommonHeader
		dx:bp = HugeLMem optr to PacketHeader of data

RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

PSEUDO CODE/STRATEGY:
	if (not end-discovery-xid-cmd)
		Send Discovery-XID-Rsp: NA, discovery-info
		frameSent := true
	else
		stop-query-timer
		Discovery-Indication(remote)
		change to NDM
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvDiscoveryXidCmdREPLY	proc	far
		.enter
	;
	;  [Is this End-Discovery-XID-Cmd?]
	;
		IrlapLockPacket esdi, dxbp
		add	di, es:[di].PH_dataOffset	; esdi = xid I field
	;
	; check source device address
	;
		cmpdw	es:[di].IDXF_destDevAddr, IRLAP_NULL_DEV_ADDR, ax
		je	wrongAddr
		cmpdw	es:[di].IDXF_srcDevAddr, IRLAP_BROADCAST_DEV_ADDR, ax
		je	wrongAddr
	;
	; check XID formatID
	;
		cmp	es:[di].IDXF_formatID, IXFI_DISCOVERY_XID
		jne	wrongFormat
	;
	; check if this is end discovery frame
	;
		mov	al, {byte}es:[di].IDXF_slotNumber
		cmp	al, IRLAP_LAST_DISCOVERY_XID_SLOT
		je	endDiscovery
	;
	; [if ( frameSent or slotNumber > selectedSlot ), don't do anything]
	;
		test	ds:IS_status, mask ISS_FRAME_SENT
		jnz	done
		cmp	al, ds:IS_selectedSlot
		jb	done
	;
	; [Set src/dest device address (es:di = xid frame received)]
	;
		mov	si, offset IS_discoveryXIDFrame
		mov	ds:[si].IDXF_formatID, 1
		mov	ds:[si].IDXF_version, 0
		movdw	ds:[si].IDXF_srcDevAddr, ds:IS_devAddr, ax
		movdw	ds:[si].IDXF_destDevAddr, es:[di].IDXF_srcDevAddr, ax
		movm	ds:[si].IDXF_xidFlags, es:[di].IDXF_xidFlags, al
	;
	; Send Discovery-XID-Rsp:NA, discoveryInfo
	;
		call	SendDiscoveryXIDRspFrame
	;
	; frameSent = true
	;
		BitSet	ds:IS_status, ISS_FRAME_SENT
		jmp	done
endDiscovery:
	;
	; [es:di = XID frame received]
	;
	; Stop-Query-Timer
	;
		call	StopQueryTimer
	;
	; Discovery-Indication(remote)
	;
		mov	ax, mask DLF_VALID or mask DLF_REMOTE
		call	DiscoveryIndication
	;
	; NEXT STATE = NDM
	;
		ChangeState	NDM, ds
wrongFormat:
wrongAddr:
done:
		IrlapUnlockPacket dx, bx
		.leave
		ret
RecvDiscoveryXidCmdREPLY	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecvTestCmdNDM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Received test frame with broadcasting address
		We swap the source address and destination address
		and echo it back

CALLED BY:	IrlapMessageProcessCallback
PASS:		ds	= station
		ch	= address field 
		cl	= control field
		dx:bp	= data frame
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecvTestCmdNDM	proc	far
		uses	dx, bp, si
		.enter
	;
	; Lock the packet
	;
		IrlapLockPacket esdi, dxbp
		mov	bx, es:[di].PH_dataSize
		add	di, es:[di].PH_dataOffset
	;
	; see if this test frame is for us
	;
		cmpdw	es:[di].ITF_destAddr, IRLAP_BROADCAST_DEV_ADDR, ax
		je	skipAddrCheck
		cmpdw	es:[di].ITF_destAddr, ds:IS_devAddr, ax
		jne	unlock		; this is not for us
skipAddrCheck:
	;
	; This test frame is for us, respond to it
	;
		movdw	es:[di].ITF_destAddr, es:[di].ITF_sourceAddr, ax
		movdw	es:[di].ITF_sourceAddr, ds:IS_devAddr, ax
	;
	; Genoa test suite expects us to wait 10 msec before transmitting
	; anything.  So, we sleep for 16.6+ msec here.  This should not
	; have been here and it's all Genoa's fault.  They should NOT be
	; expecting 10 msec minimum turnaround delay in NDM mode.  But, there
	; you have it.  This is a test frame anyways.
	;
		mov	ax, 2
		call	TimerSleep
	;
	; send back the same information back to the sender
	;
		mov	cx, IRLAP_BROADCAST_CONNECTION_ADDR shl 8 or \
			    IUR_TEST_RSP or mask IUCF_PFBIT
		call	IrlapSendUFrame
unlock:	;
	; Unlock the block
	;
		IrlapUnlockPacket dx, bx
	;
	; dx:bp will be freed by MessageProcessCallback
	;
		.leave
		ret
RecvTestCmdNDM	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueryTimerExpiredREPLY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	station thinks that discovery is over.

CALLED BY:	IrlapMessageProcessCallback (event dispatcher)
PASS:		ds    = station
RETURN:		nothing
DESTROYED:	everything (handled by the calling function, just like msg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cody K.	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueryTimerExpiredREPLY	proc	far
		.enter
	;
	; NEXT STATE = NDM
	;
		ChangeState	NDM, ds
		.leave
		ret
QueryTimerExpiredREPLY	endp

	
;------------------------------------------------------------------------------
;			     Service functions
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartSlotTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start slot timer

CALLED BY:	DiscoveryRequestNDM, SlotTimerExpiredQUERY
PASS:		ds	= station
		es	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartSlotTimer	proc	near
		uses	cx,dx
		.enter	
	; 
	; Only start the slot timer after all the data has been sent out.
	;
		mov	bx, ds:[IS_serialPort]		;bx = SerialPortNum
		call	IrlapWaitForOutput

		call	StartSlotTimerNoWait
		.leave
		ret
StartSlotTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartSlotTimerNoWait
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start slot timer, without waiting for all data to be 
		transmitted.

CALLED BY:	IrlapRecv, StartSlotTimer
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartSlotTimerNoWait	proc	far
		uses	ax,bx,cx,dx
		.enter
		clr	ax, bx
		xchgdw	axbx, ds:IS_slotTimer
		tst	bx
		jz	noTimer

		call	TimerStop
noTimer:
		mov	bx, ds:IS_eventThreadHandle	; start-slot-timer
EC <		mov	cx, IRLAP_DISCOVERY_SLOT_TIMEOUT_EC		>
NEC <		mov	cx, IRLAP_DISCOVERY_SLOT_TIMEOUT		>
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	dx, ILE_TIME_EXPIRE shl 8 or mask ITEV_SLOT
if	SLOW_TIMEOUT
		shl	cx, 1
		shl	cx, 1
endif
		call	TimerStart
		movdw	ds:IS_slotTimer, axbx
		.leave
		ret
StartSlotTimerNoWait	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopSlotTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop slot timer

CALLED BY:	discovery procedures
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	ax, bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopSlotTimer	proc	far
		uses	ax,bx,cx,dx
		.enter
		clr	ax, bx
		xchgdw	axbx, ds:IS_slotTimer
		tst	bx
		jz	noTimer

		call	TimerStop

noTimer:
		.leave
		ret
StopSlotTimer	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartQueryTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start query timer

CALLED BY:	discovery procedures
PASS:		ds	= station
		cx	= timeout value in ticks
RETURN:		nothing
DESTROYED:	ax, bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartQueryTimer	proc	near
		uses	dx
		.enter
		movdw	axbx, ds:IS_queryTimer
		call	TimerStop
		mov	bx, ds:IS_eventThreadHandle	; start-query-timer
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	dx, ILE_TIME_EXPIRE shl 8 or mask ITEV_QUERY
if	SLOW_TIMEOUT
		shl	cx, 1
		shl	cx, 1
endif
		call	TimerStart
		movdw	ds:IS_queryTimer, axbx
		.leave
		ret
StartQueryTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopQueryTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop Query Timer

CALLED BY:	RecvDiscoveryXidCmdREPLY
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	ax, bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopQueryTimer	proc	near
		uses	cx, dx
		.enter
		movdw	axbx, ds:IS_queryTimer
		call	TimerStop
		.leave
		ret
StopQueryTimer	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDiscoveryXIDCmdFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send discovery XID command frame
		Send discovery info part only when XID frame is the last
		frame to be sent.
CALLED BY:	discovery routines
PASS:		ds	= station
		ds:IS_discoveryXIDFrame = discovery XID frame to send
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendDiscoveryXIDCmdFrame	proc	near
		uses	ax,bx,cx,es,di
		.enter
	;
	; Send XID frame
	;
		segmov	es, ds, ax
		mov	di, offset IS_discoveryXIDFrame
		mov	bx, size IrlapDiscoveryXidFrame
	;
	; Send discovery info only if this frame is the last frame
	;
		cmp	es:[di].IDXF_slotNumber, IRLAP_LAST_DISCOVERY_XID_SLOT
		je	lastXidFrame
		sub	bx, size DiscoveryInfo
lastXidFrame:
	;
	; We don't need min turnaround in this case
	;
		BitSet	ds:IS_extStatus, IES_MIN_TURNAROUND
	;
	; send last xid frame
	;
		mov	cx,(IRLAP_BROADCAST_CONNECTION_ADDR or mask IAF_CRBIT)\
			    shl 8 or IUC_XID_CMD or mask IUCF_PFBIT
		call	IrlapSendUFrame
		.leave
		ret
SendDiscoveryXIDCmdFrame	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDiscoveryXIDRspFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send discovery response frame

CALLED BY:	discovery routines
PASS:		ds	= station
		ds:IS_discoveryXIDFrame = XID frame to send
NOTE:
		IDXF_discoveryInfo = must be filled in with Discovery.response
				     in advance( on startup maybe )
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendDiscoveryXIDRspFrame	proc	near
		uses	ax,bx,cx,es,di
		.enter
	;
	; We don't need min turnaround in this case
	;
		BitSet	ds:IS_extStatus, IES_MIN_TURNAROUND
	;
	; Send XID frame
	;
		segmov	es, ds, ax
		mov	di, offset IS_discoveryXIDFrame
		mov	bx, size IrlapDiscoveryXidFrame
		mov	cx, IRLAP_BROADCAST_CONNECTION_ADDR shl 8 or \
			    IUR_XID_RSP or mask IUCF_PFBIT
		call	IrlapSendUFrame
		.leave
		ret
SendDiscoveryXIDRspFrame	endp


IrlapConnectionCode		ends

