COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	SPOCK
MODULE:		high speed serial driver
FILE:		serialHighSpeed.asm

AUTHOR:		Steve Jang, Aug 12, 1997

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/12/97   	Initial revision

DESCRIPTION:
		
	High speed serial driver changes include:
	1. faster serial interrupt handlers
	2. DMA support for 1Mbps IrDA transfer

	Highlights of DMA support:
	1. replace stream driver with DMA stream driver

GENERAL NOTES:

	1. IRQ sharing is not supported any more
	2. SPF_PORT_GONE flag is not supported( no PCMCIA card support )


	$Id: serialHighSpeed.asm,v 1.9 98/06/20 15:03:37 kho Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include serial.def


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call interrupt handler

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/29/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEW_ISR
SerialInterrupt	macro	vector
		on_stack iret
		push	ds
 		push	si
		on_stack si, ds, iret
		LoadVarSeg ds
		cld			; we now use string instructions
		mov	si, offset vector
		jmp	MiniSerialInt	; ds, si destroyed
endm
endif


Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MiniSerialPrimaryInt
		MiniSerialAlternateInt
		MiniWeird1Int
		MiniWeird2Int
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt handlers for IRQ4, IRQ3 and non-standard IRQ

CALLED BY:	Hardware
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/14/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEW_ISR

MiniSerialPrimaryInt	proc	far		; IRQ4
		SerialInterrupt	primaryVec
MiniSerialPrimaryInt	endp

MiniSerialAlternateInt	proc	far		; IRQ3
		SerialInterrupt alternateVec
MiniSerialAlternateInt	endp

MiniWeird1Int	proc	far			; non-standard IRQ
		SerialInterrupt weird1Vec
MiniWeird1Int	endp

MiniWeird2Int	proc	far			; non-standard IRQ
		SerialInterrupt weird2Vec
MiniWeird2Int	endp

ForceRef	MiniWeird1Int
ForceRef	MiniWeird2Int

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndOfInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A macro to signal PIC that we are done handling an interrupt

PASS:		al = IRQ level

DESTROYS:	ax

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/26/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EndOfInterrupt	macro
		cmp	al, 8
		mov	al, IC_GENEOI
		jl	notSecond
		out	IC2_CMDPORT, al
notSecond:
		out	IC1_CMDPORT, al
endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JumpReturn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Jump back into MiniSerialInt routine
		All serial interrupt handlers are jumped-to from
		MiniSerialInt.  When they are done with their work,
		they have to jump back to place where we check for any other
		pending interrupts

PASS:		nothing for now		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	9/ 4/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JumpReturn	macro
		jmp	NextPendingInt
endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MiniSerialInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Serial interrupt handler

CALLED BY:	SerialPrimaryInt/SerialAlternateInt
PASS:		ds:si = SerialVectorData
RETURN:		nothing
DESTROYED:	ds, si, flags

BEFORE NOTES:	This interrupt handler is optimized to be used with FIFO
		enabled NS16550A UARTs.  If FIFO is not used, we should use
		old serial ISR.

NOTE 1:		These interrupt handlers don't allow IRQ sharing.  IRQ sharing
		is not done very often on GEOS devices and requires hardware to
		allow sharing( that they don't drive IRQ line high while
		requesting interrupt ).  If there is a need to do this, you'll
		have to add some code for that( IRQ sharing is done in old
		serial ISR )

NOTE 2:		This interrupt handler is used only with regular NS16550
		port operations.  For 1Mbps operation, there is an entirely
		different interrupt handler.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/12/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEW_ISR
CheckHack < SI_MODEM_STATUS eq 00b >
CheckHack < SI_TRANSMIT eq 01b >
CheckHack < SI_DATA_AVAIL eq 10b >
CheckHack < SI_LINE_ERR eq 11b >
CheckHack < offset SIID_TYPE eq 1 >
QuickHandlerTbl	label	nptr
		nptr	QuickModemStatus	; fourth priority
		nptr	QuickTransmit		; third priority
		nptr	QuickReceive		; second priority
		nptr	HandleLineError		; first priority interrupt
FcHandlerTbl	label	nptr			; NOTE: see SerialInts
		nptr	HandleModemStatus	; fourth priority
		nptr	HandleTransmit		; third priority
		nptr	HandleReceive		; second priority
		nptr	HandleLineError		; first priority interrupt
MiniSerialInt	proc	near
		uses	ax, bx, cx, dx, di
		.enter
	;
	; prevent context switches
	;
		call	SysEnterInterrupt
	;
	; Count nested frames.
	;
		inc	ds:[si].SVD_active

		mov	si, ds:[si].SVD_port	; get port data
	;
	; record H/W interrupt count
	;
IS <		IncIntStatCount	ISS_interruptCount			>
		mov	di, ds:[si].SPD_handlers; di = handler table to use
NextPendingInt	label	near			; handlers return here
	;
	; identify pending interrupt type
	;
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_iid
		in	al, dx
		mov	ah, al			; ah = SerialIID for later use
IS <		call	RecordInterruptType				>
		test	al, mask SIID_IRQ
		jnz	nothingPending
		andnf	al, mask SIID_TYPE
		clr	bh
		mov	bl, al			; bx = offset into IIDTable
	;
	; read status register and call the right handler
	;
		add	dx, offset SP_status - offset SP_iid
		in	al, dx
		jmp	{nptr}cs:[di][bx]	; trashes ax,bx,cx,dx
nothingPending:
	;
	; SPD_ien to io port ( to enable/disable xmit interrupt appropriately )
	;
		mov	al, ds:[si].SPD_ien
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_ien
		out	dx, al			; xmit int may get cleared
		jmp	$+2			; because IIR is read, so we
		out	dx, al			; set it twice
	;
	; Ack interrupt controller
	;
		mov	al, ds:[si].SPD_irq
		EndOfInterrupt			; trashes ax
	;
	; Are we a nested interrupt handler?  If so, then we're done.
	;
		mov	di, ds:[si].SPD_vector
		cmp	ds:[di].SVD_active, 1
		jne	exit

doNotify::
	;
	; we are done handling HW request
	;
		INT_ON
	;
	; Now that we have interrupts back on, we handle non-critical things
	;
		call	NotifyClients		; trashes ax,bx,cx,dx

exit::	; interrupts off

		dec	ds:[di].SVD_active

		call	SysExitInterrupt

		.leave
	;
	; we jumped to MiniSerialInt from MiniSerialPrimaryInt, etc.
	;
		pop	si			; these were pushed in
		pop	ds			; SerialInterrupt macro


		iret				; return to regular program
MiniSerialInt	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickModemStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fastest modem status change handler
		( well, we should never get here )
CALLED BY:	MiniSerialInt
PASS:		ds:si	= SerialPortData
		al	= SerialStatus
		dx	= status register address
RETURN:		nothing
DESTROYED:	nothing		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	9/ 3/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if NEW_ISR
QuickModemStatus	proc	near
	;
	; record modem status and generate modem notification
	;
		add	dx, offset SP_modemStatus - offset SP_status
		in	al, dx
		test	al, MODEM_STATUS_CHANGE_MASK
		jz	done
		mov	ds:[si].SPD_modemStatus, al
		ornf	ds:[si].SPD_notifications, mask SNN_MODEM
done:
		JumpReturn
QuickModemStatus	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickTransmit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transmit buffer with no flow control
		Use REP OUTS

CALLED BY:	MiniSerialInt
PASS:		ds:si	= port data
		al	= SerialStatus
		dx	= status register address
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	9/ 3/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if NEW_ISR
QuickTransmit	proc	near
	;
	; chances are that we will send something here -- unless some horrible
	; thing happened that screwed up our interrupt code
	;
		BitSet	ds:[si].SPD_notifications, SNN_TRANSMIT
	;
	; prepare to xmit
	;
		push	ds, si
		mov	ds, ds:[si].SPD_outStream
		mov	si, ds:SD_reader.SSD_ptr	; ds:si = byte to xmit
		add	dx, offset SP_data - offset SP_status
		mov	cx, FIFO_SIZE
		sub	ds:SD_reader.SSD_sem.Sem_value, cx
		jb	case2
	;
	; case 1: cx = FIFO_SIZE, assume data doesn't wrap
	;
		lahf
		add	ds:[SD_unbalanced], cx
		add	cx, si
		cmp	cx, ds:SD_max
		jae	wrap				; infrequent case
		sub	cx, si
		rep outsb
		mov	ds:SD_reader.SSD_ptr, si
		sahf
		jz	empty
		pop	ds, si
		JumpReturn
case2:
	;
	; case 2: cx < FIFO_SIZE, assume data doesn't wrap
	;
		add	cx, ds:SD_reader.SSD_sem.Sem_value
		clr	ds:SD_reader.SSD_sem.Sem_value
		add	ds:[SD_unbalanced], cx
		add	cx, si
		cmp	cx, ds:SD_max
		jae	wrap				; infrequent case
		sub	cx, si
	 	rep outsb
		mov	ds:SD_reader.SSD_ptr, si
empty:
	;
	; turn off xmit interrupt
	;
		mov	ax, mask SNN_EMPTY
		mov	ds:SD_reader.SSD_data.SN_ack, 0
		test	ds:[SD_state], mask SS_LINGERING
		jz	emptyE
		BitSet	ds:[SD_state], SS_NUKING
		BitClr	ds:[SD_state], SS_LINGERING
		ornf	ax, mask SNN_DESTROY
emptyE:
		pop	ds, si
		ornf	ds:[si].SPD_notifications, ax
	;
	; if status register indicates that transmission was not completed
	; don't turn off the interrupt
	;
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_status
		in	al, dx
		test	al, mask SS_TSRE
		jnz	xmitIntOff
		JumpReturn
xmitIntOff:
	;
	; Turn off transmitter interrupt
	;
		BitClr	ds:[si].SPD_ien, SIEN_TRANSMIT
		JumpReturn
wrap:	;
	; wrap: data wraps, si = data ptr, cx = data size + si
	;
		mov	ax, cx
		sub	ax, ds:SD_max		; ax = # bytes that go over max
		sub	cx, si			; cx = orig. # bytes to send
		sub	cx, ax
		rep outsb
		mov	si, offset SD_data
		mov_tr	cx, ax			; note that if ax = 0, rep outs
		rep outsb			; writes no data -> no problem
		mov	ds:SD_reader.SSD_ptr, si
		tst	ds:SD_reader.SSD_sem.Sem_value
		jz	empty
		pop	ds, si
		JumpReturn
		
QuickTransmit	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickReceive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Receive data from serial port quickly
		Use REP INS where possible

CALLED BY:	MiniSerialInt
PASS:		ds:si	= port data
		ah	= SerialIID
		al	= SerialStatus
		dx	= status register address
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	9/ 3/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if NEW_ISR
; ---------------------------------------------------------------------------
; a macro to deal with NT demo not supporting FIFO mode
; pass:		no parameters to macro it self, but following register
;               setting is required:
;		ds:si = SerialPortData
;		dx    = data io address
;	        es:di = buffer to store bytes in
; return:	ax    = number of bytes read
; ---------------------------------------------------------------------------
FAKE_REP_IN	macro
		local	pex
		local	ex
		local	to
		push	ax
		push	bx
		mov	bx, ds:[si].SPD_base
		add	bx, offset SP_status
to:
		jcxz	pex
		in	al, dx
		stosb
		xchg	dx, bx
		in	al, dx
		xchg	dx, bx
		test	al, mask SS_DATA_AVAIL
		jz	ex
		loop	to
pex:
		inc	cx	; to counter dec instruction
ex:
		dec	cx	; if we jumped to ex, use 1 count
		pop	bx
		pop	ax
		sub	ax, cx	; 14 - whatever count left unused
		clr	cx
		endm

QuickReceive	proc	near
		push	bp
	;
	; if no data, exit
	;
		BitSet	ds:[si].SPD_notifications, SNN_RECEIVE
	;
	; prepare to receive data
	;
		mov	bp, dx
		add	dx, offset SP_data - offset SP_status
		tst	ds:[si].SPD_inStream
LONG		jz	clearOut				; rare case
	;
	; if there is input stream, put bytes there
	;
		push	es, di
		mov	es, ds:[si].SPD_inStream
		mov	di, es:SD_writer.SSD_ptr
		mov	bx, di
		mov	cx, es:SD_writer.SSD_sem.Sem_value
	;
	; If fifo timed out, we are not guaranteed to have 14 bytes at serial
	; port
	;
		test	ah, mask SIID_TCLIP
		jnz	leftover
	;	jz	leftover
	;
	; we only do rep insb if we have enough room in input stream, and
	; data doesn't have to wrap around( which is most of the time )
	;
		mov	ax, FIFO_RECV_THRESHOLD	; ax = frequently used constant
		cmp	cx, ax			; do we have enough room?
		jb	setup			; rare jump -- recover status
		add	di, ax			; di = ptr after reading data
		cmp	di, es:SD_max		; do we have to wrap?
		jae	setup			; rare jump -- recover status
		mov	cx, ax			; cx = # of bytes to read
		mov	di, bx			; es:di = input stream
	;
	; Put 14 bytes into stream.  Decrement room for writing in Stream.
	; Increment unbalanced count, which in this case, number of bytes
	; available for the reader( application ). This value will be added
	; to reader semaphore value later.
	;

ifdef	WIN32
		FAKE_REP_IN			; ax = # of bytes read
else
		rep insb
endif
		sub	es:SD_writer.SSD_sem.Sem_value, ax
		add	es:[SD_unbalanced], ax
		mov	es:SD_writer.SSD_ptr, di
	;
	; set up for leftover loop:
	; we have just read 14 bytes off FIFO.  FIFO size is 16 though.  So
	; there may be couple more bytes in FIFO.  We need to read them, too.
	;
		mov	bx, di
		mov	cx, es:SD_writer.SSD_sem.Sem_value
setup:
		xchg	dx, bp			; dx = status io addr
		in	al, dx
		xchg	dx, bp			; dx = data io addr
leftover:
	;
	; read leftover bytes
	;
	; al    = SerialStatus
	; es:bx = next place to put incoming byte data
	; cx = how much room in input stream
	; dx = data io addr, bp = status io addr
	;
		jcxz	full
		test	al, mask SS_DATA_AVAIL
		jz	popDone
		push	si
		mov	di, bx
		clr	bx			; unbalanced count
		mov	si, es:SD_max		; si = bound of stream segment
readLoop:
		in	al, dx
		stosb
		inc	bx			; inc unbalance
		cmp	di, si
		je	wrap
cnt:
		xchg	dx, bp			; dx = status io addr
		in	al, dx
		xchg	dx, bp			; dx = data io addr
		test	al, mask SS_DATA_AVAIL
		loopnz	readLoop
	;
	; adjust stream data
	;
		mov	es:SD_writer.SSD_sem.Sem_value, cx
		mov	es:SD_writer.SSD_ptr, di
		add	es:SD_unbalanced, bx
		pop	si
		jcxz	full
popDone:
		pop	es, di
done:
		pop	bp
		JumpReturn
wrap:
		mov	di, offset SD_data
		jmp	cnt
full:
	;
	; al = SerialStatus
	;
		pop	es, di
		BitSet	ds:[si].SPD_notifications, SNN_INPUT_FULL
		test	al, mask SS_DATA_AVAIL
		jz	done
clearOut:
	;
	; there is no input stream, clear out port, anyways
	;
		in	al, dx
		xchg	dx, bp			; dx = status io addr
		in	al, dx
		xchg	dx, bp			; dx = data io addr
		test	al, mask SS_DATA_AVAIL
		jnz	clearOut
		pop	bp
		JumpReturn
		
QuickReceive	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleModemStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle modem status change and tramsmit flow control

CALLED BY:	MinimalSerialInt (ISR)
PASS:		al	= SerialStatus
		ds:si	= SerialPortData
		dx	= address of [base].SP_status
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

NOTE:		Hardware flow control actually turns off xmit interrupts
		where as software flow control only sets appropriate bit
		in SPD_mode.  HandleTransmit routine will deal with software
		flow control appropriately by checking SPD_mode.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/18/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEW_ISR
HandleModemStatus	proc	near
	;
	; read modem status, find the bit that has changed
	;
		add	dx, offset SP_modemStatus - offset SP_status
		in	al, dx
		test	al, MODEM_STATUS_CHANGE_MASK
		jz	done
		mov	ds:[si].SPD_modemStatus, al
	;
	; if no output flow control, we ignore signals from remote side
	;
		test	ds:[si].SPD_mode, mask SF_OUTPUT or mask SF_HARDWARE
		jz	notification
		jpo	notification	; one of them not set
	;
	; check if relevant bit was changed
	;
		mov	bl, ds:[si].SPD_stopSignal
		mov	bh, bl		; bl = bh = stop signal mask
		mov	cl, offset SMS_CTS
		shr	bl, cl		; convert from signal bit to
					; signal-changed bit ( see
					; SerialModemStatus definition )
		test	bl, al
		jz	notification	; no interesting bit changed
	;
	; stop signal bit changed, prepare to apply change
	;
		mov	bl, bh
		xor	bl, al		; bl = interesting bits that are
					;      clear in al
		and	bl, bh		; mask out bits other than stop signals
		jnz	stopXmit	; some stop signal bits are off
	;
	; if status indicates that all SPD_stopSignal bits are on in AL,
	; turn back on xmit interrupt, otherwise turn it off.  we don't worry
	; about SW flow ctrl here ( HandleTransmit takes care of that )
	;
restartXmit::
		BitClr	ds:[si].SPD_mode, SF_HARDSTOP
		BitSet	ds:[si].SPD_ien, SIEN_TRANSMIT
		jmp	notification
stopXmit:
		BitSet	ds:[si].SPD_mode, SF_HARDSTOP
		BitClr	ds:[si].SPD_ien, SIEN_TRANSMIT
notification:
	;
	; set up modem notification
	;
		ornf	ds:[si].SPD_notifications, mask SNN_MODEM
done:
		JumpReturn
HandleModemStatus	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleTransmit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle transmission of bytes to serial port

CALLED BY:	MinimalSerialInt (ISR)
PASS:		al	= SerialStatus
		ds:si	= SerialPortData
		dx	= address of [base].SP_status
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

NOTE:		HW flow control disables xmit interrupt when remote requests
		us to stop sending.  So, we will never hit this routine if
		xmit is disabled by modem control.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/18/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEW_ISR
HandleTransmit	proc	near
		uses	es
		.enter
	;
	; safety check( this seems unnecessary )
	;
		test	al, mask SS_THRE
		jz	done
	;
	; set up send loop
	;
		mov	es, ds:[si].SPD_outStream
		mov	cx, FIFO_SIZE
		add	dx, offset SP_data - offset SP_status
	;
	; check for pending XOFF/XON
	;
		test	ds:[si].SPD_mode, mask SF_XOFF or mask SF_XON
		jnz	sendXoff
	;
	; check flow control
	;
		test	ds:[si].SPD_mode, mask SF_SOFTSTOP or mask SF_HARDSTOP
		jnz	done
	;
	; get output stream, check if there is data to send
	;
		tst	ds:[si].SPD_outStream
		jz	done
		tst	es:SD_reader.SSD_sem.Sem_value
		jz	empty
		BitSet	ds:[si].SPD_notifications, SNN_TRANSMIT
sendL:
		StreamGetByteNB es, al, NO_VSEM
		jc	empty
send:
		out	dx, al
		loop	sendL
done:
		.leave
		JumpReturn
sendXoff:
		mov	al, XOFF_CHAR
		test	ds:[si].SPD_mode, mask SF_XOFF
		jnz	beforeSend
sendXon::
		mov	al, XON_CHAR
beforeSend:
	;
	; clear pending bits
	;
		andnf	ds:[si].SPD_mode, not mask SF_XOFF and \
					  not mask SF_XON
	;
	; if xmit is not allowed, we still send XON/XOFF character
	;
		test	ds:[si].SPD_mode, mask SF_SOFTSTOP or mask SF_HARDSTOP
		jz	send
		mov	cx, 1		; send only 1 character
		BitClr	ds:[si].SPD_ien, SIEN_TRANSMIT
		jmp	send
empty:
	;
	; stream is empty, shut off xmit interrupt, acknowledge notification
	; to turn on xmit interrupt, etc.
	;
		mov	es:[SD_reader.SSD_data.SN_ack], 0
		BitSet	ds:[si].SPD_notifications, SNN_EMPTY
	;
	; before turning off xmit interrupt, make sure all the bytes have been
	; shifted out from the port
	;
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_status
		in	al, dx
		test	al, mask SS_TSRE
		jz	done
		BitClr	ds:[si].SPD_ien, SIEN_TRANSMIT

	;
	; If the stream was being nuked and we were just waiting for
	; data to drain set SNN_DESTROY so we know to clear the
	; output stream, etc.
	;
		test	es:[SD_state], mask SS_LINGERING
		jz	done
		ornf	es:[SD_state], mask SS_NUKING
		andnf	es:[SD_state], not mask SS_LINGERING
		BitSet	ds:[si].SPD_notifications, SNN_DESTROY
		jmp	done

HandleTransmit	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleReceive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle receiving bytes from serial port

CALLED BY:	MinimalSerialInt (ISR)
PASS:		al	= SerialStatus
		ds:si	= SerialPortData
		dx	= address of [base].SP_status
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/18/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEW_ISR
HandleReceive	proc	near
		uses	es, bp
		.enter
	;
	; see if data is available
	;
		test	al, mask SS_DATA_AVAIL
		jz	done
	;
	; set up data read loop
	;
		mov	ah, ds:[si].SPD_mode
		mov	bp, dx
		add	bp, offset SP_data - offset SP_status
		mov	cx, ds:[si].SPD_inStream
		mov	es, cx
readByte:
	;
	; dx = data addr, bp = status addr, es,cx = stream, ah = SerialFlow
	;
		xchg	dx, bp			; dx = SP_data
		in	al, dx			; al = data byte
		test	ah, mask SF_SOFTWARE or mask SF_OUTPUT	; SF flow ctrl?
		jz	store			; neither set
		jpe	swFC			; Both set?
store:
	;
	; read byte if we have valid stream
	;
		jcxz	afterStore		; just clean out serial port
		StreamPutByteNB es, al, NO_VSEM	; trashes ax,bx
		jc	full
		mov	ah, ds:[si].SPD_mode
		test	ah, mask SF_INPUT	; input flow ctrl?
		jnz	inputFC
afterStore:
	;
	; now read line status register
	;
		xchg	dx, bp			; dx = SP_status
		in	al, dx
		test	al, mask SS_DATA_AVAIL
		jnz	readByte
		tst	es:[SD_unbalanced]	; have we put any bytes into
		jz	done			; input stream?
		ornf	ds:[si].SPD_notifications, mask SNN_RECEIVE
done:
		.leave
		JumpReturn
full:
		ornf	ds:[si].SPD_notifications, mask SNN_INPUT_FULL
		jmp	afterStore
swFC:
	;
	; check for XON/XOFF chars
	;
		cmp	al, XOFF_CHAR
		je	xoff
		cmp	al, XON_CHAR
		jne	store
xon::
		BitClr	ds:[si].SPD_mode, SF_SOFTSTOP
		BitSet	ds:[si].SPD_ien, SIEN_TRANSMIT
		jmp	afterStore
xoff:
		BitSet	ds:[si].SPD_mode, SF_SOFTSTOP
		BitClr	ds:[si].SPD_ien, SIEN_TRANSMIT
		jmp	afterStore
inputFC:
	;
	; check if we need to hold off incoming data from remote device
	;
		mov	bx, es:SD_reader.SSD_sem.Sem_value
		add	bx, es:[SD_unbalanced]	; bx = # of bytes in input buff
		cmp	bx, ds:[si].SPD_highWater
		jne	afterStore
	;
	; Stop incoming data
	;
		call	StopIncomingData	; trashes nothing
		jmp	afterStore
		
HandleReceive	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleLineError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle line error from serial port

CALLED BY:	MinimalSerialInt (ISR)
PASS:		al	= SerialStatus
		ds:si	= SerialPortData
		dx	= address of [base].SP_status
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/18/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEW_ISR
HandleLineError	proc	near
		mov	ah, al
if	INTERRUPT_STAT
		test	al, mask SS_OVERRUN
		jz	noOvrn
		IncIntStatCount ISS_overrunCount
noOvrn:
endif	; INTERRUPT_STAT
		andnf	ah, SERIAL_ERROR
		ornf	ds:[si].SPD_error, ah
		ornf	ds:[si].SPD_notifications, mask SNN_ERROR
		JumpReturn
HandleLineError	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopIncomingData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal remote device to stop sending data

CALLED BY:	HandleReceive( MiniSerialInt -- on HW interrupt )
PASS:		ah	= SPD_mode
		ds:si	= SerialPortData
		es	= in-buffer stream segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/19/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEW_ISR
StopIncomingData	proc	far
		uses	ax,dx
		.enter
	;
	; if software FC, set SF_XOFF so that xmit interrupt sends XOFF char
	; next time it happens.
	;
		test	ah, mask SF_SOFTWARE
		jz	hwFC
		BitSet	ds:[si].SPD_mode, SF_XOFF
		BitSet	ds:[si].SPD_ien, SIEN_TRANSMIT	; this will enable
hwFC:							; xmit interrupr
	;
	; if hardware FC, drive stop control lines low so that the other side
	; knows that they need to hold off their transmission.
	;
		test	ah, mask SF_HARDWARE
		jz	setupNotification
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_modemCtrl
		mov	al, ds:[si].SPD_stopCtrl
		not	al
		andnf	al, ds:[si].SPD_curState.SPS_modem ; turn off stop ctrl
		out	dx, al				   ; bits
		mov	ds:[si].SPD_curState.SPS_modem, al
setupNotification:
	;
	; Enable routine notifier to call us when our application has
	; read enough to bring the buffer below the low-water mark.
	;
		test	ah, mask SF_SOFTWARE or mask SF_HARDWARE
		jz	done
		mov	es:SD_writer.SSD_data.SN_type, SNM_ROUTINE
done:
		.leave
		ret
StopIncomingData	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResumeIncomingData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal remote device to resume sending data
		This callback routine is set up by StopIncomingData and
		SerialInitInput

CALLED BY:	Stream driver ( when input buffer is available )
PASS:		cx	= number of bytes available in stream
		dx	= stream token
		bp	= STREAM_WRITE (ignored)
		ax	= SerialPortData
RETURN:		nothing
DESTROYED:	nothing

NOTE:		We wouldn't be here unless somebody stopped the remote side
		using software or hardware flow control.  So, assume that
		somebody did.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/19/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEW_ISR
ResumeIncomingData	proc	far
		uses	ax, bx, dx, ds, es
		.enter
	;
	; turn off notification
	;
		mov	es, dx
		mov	es:SD_writer.SSD_data.SN_type, SNM_NONE
		mov	es:SD_writer.SSD_data.SN_ack, 0
		LoadVarSeg ds
		mov	bx, ax
	;
	; if hardware FC is set, clear it and signal remote side
	; to resume sending data
	;
		test	ds:[bx].SPD_mode, mask SF_HARDWARE
		jz	swFC
		mov	dx, ds:[bx].SPD_base
		add	dx, offset SP_modemCtrl
		mov	al, ds:[bx].SPD_stopCtrl
		ornf	al, ds:[bx].SPD_curState.SPS_modem
		out	dx, al
		mov	ds:[bx].SPD_curState.SPS_modem, al
swFC:
	;
	; if software FC, set XON pending bit and enable transmit interrupt
	;
		test	ds:[bx].SPD_mode, mask SF_SOFTWARE
		jz	done
		BitSet	ds:[bx].SPD_mode, SF_XON
		mov	dx, ds:[bx].SPD_base
		add	dx, offset SP_ien
		INT_OFF				; to protect SPD_ien
		mov	al, ds:[bx].SPD_ien
		ornf	al, mask SIEN_TRANSMIT
		out	dx, al
		jmp	$+2
		out	dx, al
		mov	ds:[bx].SPD_ien, al
		INT_ON
done:		
		.leave
		ret
ResumeIncomingData	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyClients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify clients of changes in serial port

CALLED BY:	MiniSerialInt
PASS:		ds:si	= SerialPortData
RETURN:		nothing
		interrupts off
DESTROYED:	ax, bx, cx, dx, flags

NOTE:		other interrupts may happen while this routine is running

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	8/19/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	NEW_ISR
NotifyClients	proc	near
		uses	es, di, si, ds
		.enter
notificationLoop:
	;
	; handle each SNN_ condition if any
	;
		INT_OFF
		clr	ax
		xchg	ax, ds:[si].SPD_notifications
		test	ax, mask SNN_INPUT_FULL or\
			    mask SNN_EMPTY or\
			    mask SNN_ERROR or\
			    mask SNN_RECEIVE or\
			    mask SNN_TRANSMIT or\
			    mask SNN_MODEM or\
			    mask SNN_DESTROY
		jz	exit			; keep int off until we iret,
						;  so that nothing else
						; can happen before we exit
		INT_ON
		call	HandleNotifications
		jmp	notificationLoop
exit:
		.leave
		ret
NotifyClients	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNotifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle notifications needed

CALLED BY:	NotifyClients
PASS:		ds:si	= port data
		ax	= SerialNotificationsNeeded record
RETURN:		nothing
DESTROYED:	es, di

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	9/ 4/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if NEW_ISR
HandleNotifications	proc	near
		uses	bx,cx,dx
		.enter
		lea	di, cs:[notificationTable]
repeat:
		test	ax, cs:[di].MJE_mask
		jz	next
		push	ax, di
		jmp	{nptr}cs:[di].MJE_func	; trashes ax,bx,cx,es,di
return:
		pop	ax, di
next:
		add	di, size MaskJumpEntry
		jmp	repeat			; not an infinite loop
exitLoop:					; (see notificationTable)
		pop	ax, di
		.leave
		ret
		
inputfull:;-------------------------------------------------------------------
	;
	; input stream is full - we only care about this if we are passive
	; port
	;
		test	ds:[si].SPD_passive, mask SPS_PASSIVE or \
					     mask SPS_BUFFER_FULL
		jz	return
		jnp	return	; they are both on
		BitSet	ds:[si].SPD_passive, SPS_BUFFER_FULL
		mov	cx, mask SPNS_BUFFER_FULL or \
			    mask SPNS_BUFFER_FULL_CHANGED
		call	SerialPassiveNotify
		jmp	return
		
error:	;---------------------------------------------------------------------
	;
	; all error pertains to receiving side
	;
		clr	cx
		xchg	ds:[si].SPD_error, cl	; cx = error code
		mov	ax, STREAM_WRITE
		mov	bx, ds:[si].SPD_inStream
		tst	bx
		jz	return			; if no instream, no error
		mov	di, DR_STREAM_SET_ERROR
		call	StreamStrategy		; nothing
		jmp	return
		
modem:	;---------------------------------------------------------------------
	;
	; send modem line change notifications
	;
		tst	ds:[si].SPD_inStream
		jz	return			; no input stream, no service
		clr	cx
		xchg	cl, ds:[si].SPD_modemStatus
		jcxz	return			; no status change, no notice
		mov	es, ds:[si].SPD_inStream
		lea	di, ds:[si].SPD_modemEvent	; ds:di = notifier
		mov	ah, STREAM_NOACK
		call	StreamNotify
		jmp	short return

destroy:;---------------------------------------------------------------------
	;
	; send destroy notification
	;
		mov	cx, ds:[si].SPD_outStream
		jcxz	return
		mov	es, cx
		tst	es:SD_useCount
		jg	return
		mov	ax, es
		mov	bx, offset SD_closing
		call	ThreadWakeUpQueue
		jmp	return
		
receive:;---------------------------------------------------------------------
	;
	; adjust unbalanced stream
	;
		INT_OFF
		mov	es, ds:[si].SPD_inStream
		mov	cx, es:SD_reader.SSD_sem.Sem_value
		cmp	cx, 0
		jl	_vReader		; wow, someone's waiting
_adjReader:
		clr	ax
		xchg	ax, es:SD_unbalanced
		add	es:SD_reader.SSD_sem.Sem_value, ax
		INT_ON
	;
	; check receive notify
	;
		tst	es:SD_reader.SSD_data.SN_type
		jz	_exitR
		call	StreamReadDataNotify	; trash: ax, di
_exitR:
		jmp	return
_vReader:
	;
	; semaphore value is negative, meaning someone's in wait queue
	;
		neg	cx
		sub	es:SD_unbalanced, cx
_vL1:
		VSem	es, [SD_reader.SSD_sem], TRASH_AX, NO_EC
		loop	_vL1			; we'll probably never loop
		jmp	_adjReader
		
transmit:;--------------------------------------------------------------------
	;
	; adjust unbalanced stream
	;
		INT_OFF
		mov	es, ds:[si].SPD_outStream
		mov	cx, es:SD_writer.SSD_sem.Sem_value
		cmp	cx, 0
		jl	_vWriter		; wow, someone's waiting
_adjWrite:
		clr	ax
		xchg	ax, es:SD_unbalanced
		add	es:SD_writer.SSD_sem.Sem_value, ax
		INT_ON
	;
	; check receive notify
	;
		tst	es:SD_writer.SSD_data.SN_type
		jz	_exitW
		call	StreamWriteDataNotify	; trash: ax, di
_exitW:
		jmp	return
_vWriter:
	;
	; semaphore value is negative, meaning someone's in wait queue
	;
		neg	cx
		sub	es:SD_unbalanced, cx
_vL2:
		VSem	es, [SD_writer.SSD_sem], TRASH_AX, NO_EC
		loop	_vL2			; we'll probably never loop
		jmp	_adjWrite
		
notificationTable	label MaskJumpEntry
		MaskJumpEntry	<mask SNN_INPUT_FULL, inputfull>
		MaskJumpEntry	<mask SNN_ERROR,    error>
		MaskJumpEntry	<mask SNN_RECEIVE,  receive>
		MaskJumpEntry	<mask SNN_TRANSMIT, transmit>
		MaskJumpEntry	<mask SNN_MODEM,    modem>
		MaskJumpEntry	<mask SNN_DESTROY,  destroy>
		MaskJumpEntry	<-1, exitLoop>			; exit the loop

HandleNotifications	endp
endif ; NEW_ISR

Resident	ends


