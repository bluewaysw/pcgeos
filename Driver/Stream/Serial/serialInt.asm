COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Serial Driver -- Interrupt handling
FILE:		serialInt.asm

AUTHOR:		Adam de Boor, Feb  6, 1990

ROUTINES:
	Name			Description
	----			-----------
	SerialNotify		Notification routine called by stream driver
	SerialPrimaryInt	Interrupt routine for primary serial vector
	SerialAlternateInt	Interrupt routine for alternate serial vector
	SerialWeird1Int		First interrupt routine for some vector other
				than the serial ones.
	SerialWeird2Int		Second interrupt routine for some vector other
				than the serial ones.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 6/90		Initial revision


DESCRIPTION:
	Functions to handle the read-side of a serial port's stream,
	fielding interrupts, handling flow-control, etc.
		
	This is the file in the driver that has free rein to play with the
	stream driver data (nobody else should).

	$Id: serialInt.asm,v 1.61 98/05/05 17:52:31 cthomas Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	serial.def

;NO_POWER		equ	TRUE

INTERRUPT_LOGGING	equ	FALSE

IntDesc	struct
    ID_notes	SerialNotificationsNeeded
    ID_iid	SerialIID
IntDesc	ends


if 	INTERRUPT_LOGGING
idata	segment

logPort	nptr.SerialPortData	com1
curLog	nptr.IntDesc	intLog

idata	ends
endif

udata	segment
if	INTERRUPT_LOGGING
NUM_LOGGED	equ	1024
intLog	IntDesc	NUM_LOGGED dup(<>)
endif

udata	ends

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialLogIID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the interrupt ID register in the log

CALLED BY:	(INTERNAL)
PASS:		ds:si	= SerialPortData
		al	= SerialIID
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	ID_iid of current log entry overwritten.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/12/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	INTERRUPT_LOGGING
SerialLogIID	proc	near
		uses	bx
		.enter
		cmp	si, ds:[logPort]
		jne	10$
		mov	bx, ds:[curLog]
		mov	ds:[bx].ID_iid, al
10$:
		.leave
		ret
SerialLogIID	endp
endif	; INTERRUPT_LOGGING

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialLogNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this is the port being tracked, record the notifications

CALLED BY:	(INTERNAL)
PASS:		ds:si	= SerialPortData
		bp	= SerialNotificationsNeeded
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	curLog is advanced

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/12/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	INTERRUPT_LOGGING
SerialLogNotes	proc	near
		uses	bx
		.enter
		cmp	si, ds:[logPort]
		jne	20$
		mov	bx, ds:[curLog]
		mov	ds:[bx].ID_notes, bp
		add	bx, size IntDesc
		cmp	bx, offset intLog + size intLog
		jb	15$
		mov	bx, offset intLog
15$:
		mov	ds:[curLog], bx
20$:
		.leave
		ret
SerialLogNotes	endp
endif	; INTERRUPT_LOGGING

if INTERRUPT_STAT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialIncIntStatCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment interrupt stat variable specified in the parameter

CALLED BY:	Various places within SerialInt
PASS:		ds:si	= current SerialPortData
		di	= offset ISS_interruptCount or
			  offset ISS_errorCount	or
			  offset ISS_xmitIntCount or
			  offset ISS_recvIntCount or
			  offset ISS_fifoTimeout or
			  offset ISS_overrunCount or
			  offset ISS_bufferFullCount
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialIncIntStatCount	proc	near
		push	di

		cmp	si, offset com1_passive
		je	e1
		cmp	si, offset com1
		jne	ne1
e1:
		add	di, offset com1Stat
		jmp	done
ne1:
		cmp	si, offset com2
		jne	ne2
		add	di, offset com2Stat
		jmp	done
ne2:
		cmp	si, offset com3
		jne	ne3
		add	di, offset com3Stat
		jmp	done
ne3:
		jmp	exit
done:
		inc	{word}ds:[di]
exit:
		pop	di
		ret
SerialIncIntStatCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordInterruptType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the type of interrupt in a stat variable

CALLED BY:	SerialInt
PASS:		ds:si	= SerialPortData
		al	= contents of interrupt ID register( SP_iid )
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/29/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordInterruptType	proc	near
		uses	bx
		.enter
	;
	; increment corresponding stat variable
	;
		mov	bl, al
		andnf	bl, SerialInterruptIdMask
		cmp	bl, II_DATA_READY		; most frequent
		jne	ne4
		IncIntStatCount	ISS_recvIntCount
		jmp	done
ne4:
		cmp	bl, II_XMIT_READY
		jne	ne2
		IncIntStatCount	ISS_xmitIntCount		
		jmp	done
ne2:
		cmp	bl, II_TRIG_LVL_CHANGE
		jne	ne1
		IncIntStatCount	ISS_fifoTimeout
		jmp	done
ne1:
		cmp	bl, II_ERROR_STATUS
		jne	ne3
		IncIntStatCount	ISS_errorCount
		jmp	done
ne3:
		cmp	bl, II_NO_ACTION
		jne	ne5
		IncIntStatCount	ISS_noActionCount
		jmp	done
ne5:
		cmp	bl, II_MODEM_STATUS
		jne	ne6
		IncIntStatCount	ISS_modemStatusCount
		jmp	done
ne6:
		IncIntStatCount ISS_bogusIntCount
done:
		.leave
		ret
RecordInterruptType	endp

endif	; INTERRUPT_STAT



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Data notification routine for stream driver to call when data
		first appear in the output stream.

CALLED BY:	Stream driver when data are present in the stream.
PASS:		dx	= stream token (ignored)
		bx	= stream segment
		ax	= SerialPortData
		cx	= # bytes available
		bp	= STREAM_READ (ignored)
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialNotify	proc	far	uses ds, es
if	INTERRUPT_LOGGING
		uses	bp
endif	; INTERRUPT_LOGGING
		.enter
		LoadVarSeg	ds

EC <		cmp	bx, dx						>
EC <		ERROR_NE	WHAT_THE_HELL?				>

		mov	es, bx		; es <- stream
		mov_tr	bx, ax		; ds:bx <- SPD

if	INTERRUPT_LOGGING
		mov	al, 1		; signal notify
		xchg	bx, si
		call	SerialLogIID
		xchg	bx, si
		mov	bp, mask SNN_EMPTY
endif	; INTERRUPT_LOGGING

		jcxz	doAck		; => no data available, so do nothing.
					; this will happen when a threshold of
					; 0 is set...

if 	INTERRUPT_LOGGING
		clr	bp
endif	; INTERRUPT_LOGGING
	;
	; Turn on transmitter interrupts for the port. SerialInt will
	; handle the rest of our job whenever the interrupt comes in.
	; Do not do this if output is stopped, however (interrupt will
	; be re-enabled when the appropriate signal arrives saying
	; output may recommence).
	;
		test	ds:[bx].SPD_mode, mask SF_SOFTSTOP or mask SF_HARDSTOP
		jnz	doAck				; (carry clear)
		
if 	INTERRUPT_LOGGING
		mov	bp, mask SNN_TRANSMIT
endif	; INTERRUPT_LOGGING

		call	SerialEnableTransmit
done:
if	INTERRUPT_LOGGING
		xchg	bx, si
		call	SerialLogNotes
		xchg	bx, si
endif	; INTERRUPT_LOGGING
		.leave
		ret
doAck:
		mov	es:[SD_reader.SSD_data].SN_ack, 0
		jmp	done
SerialNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialEnableTransmit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable transmitter interrupts for the port.

CALLED BY:	(INTERNAL) SerialRestart, SerialNotify
PASS:		ds:bx	= SerialPortData
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	power driver is called if port still exists.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialEnableTransmit proc	near
		.enter
		pushf
		INT_OFF		; interrupts off so SPD_ien doesn't change
				;  while we're playing with al...

		mov	al, ds:[bx].SPD_ien

		mov	dx, ds:[bx].SPD_base
		add	dx, offset SP_ien
if	STANDARD_PC_HARDWARE
		or	al, mask SIEN_TRANSMIT
endif	; STANDARD_PC_HARDWARE

	;
	; Ask power driver to turn on transmit buffers before we enable the
	; interrupt. Note we do this only for local serial ports, as the
	; PDT_PCMCIA_SOCKET has no facility to enable the buffers independently.
	;
		mov	ds:[bx].SPD_ien, al
		test	ds:[bx].SPD_flags, mask SPF_PORT_GONE
		jnz	done		; => don't mess with hardware, as it's
					;  not there.

ifndef	NO_POWER
		xchg	bx, si
		call	SerialBufferPowerChange
		xchg	bx, si
endif

		out	dx, al
		jmp	$+2
		out	dx, al		; second write to cope with extra reset
					;  from reading the IID register...
done:
	;
	; Restore IF safely please.
	;
		push	cs
		call	safePopf
		.leave
		ret
safePopf:
		iret
SerialEnableTransmit endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialPassiveNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal the owner of a passive port that one of the following
		has happened:

		* The port's input buffer has filled up, which means
		  all incoming data will be discarded.  This
		  notification happens once.

		* The port was preempted by an active allocation of
		  the port.  All data in the input buffer will be
		  cleared when control is returned to the passive
		  port.

		* Control of the port is returning after being
		  preempted by an active allocation.  The state of the
		  port will be the same as when the preemption
		  originally occurred, though the input buffer will be
		  cleared.

CALLED BY:	Internal

PASS:		ds:si	= SerialPortData of passive port from which this
			  notification is sent
		cx	= A SerialPassiveNotificationStatus record
			  that contains the current status of the
			  connection, with the "changed" fields set
			  accordingly.

RETURN:		nothing

DESTROYED:	cx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialPassiveNotify	proc	far
		uses	es, di, ax, bx, dx, bp
		.enter

EC <		call	ECSerialVerifyPassive				>

		mov	bp, ds:[si].SPD_portNum
		mov	es, ds:[si].SPD_inStream	; es <- stream to notify
		
		lea	di, ds:[si].SPD_passiveEvent
		mov	ah, STREAM_NOACK
		call	StreamNotify

		.leave
		ret
SerialPassiveNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialRestart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restart output to the port again (from the remote device),
		now that the input stream has drained to a reasonable level.

CALLED BY:	Stream driver
PASS:		cx	= number of bytes available in stream (ignored)
		dx	= stream token
		bp	= STREAM_WRITE (ignored)
		ax	= SerialPortData
RETURN:		nothing
DESTROYED:	ax, bx, dx, ds, es

PSEUDO CODE/STRATEGY:
		If SH_PORT_GONE is set, we just store stuff in the port
		state variables, from which they'll get put in the port
		when the card gets stuck back in again...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialRestart	proc	far	uses es, ds
		.enter
	;
	; Turn notifier back off again.
	;
		mov	es, dx
		mov	es:SD_writer.SSD_data.SN_type, SNM_NONE
		mov	es:SD_writer.SSD_data.SN_ack, 0

		LoadVarSeg	ds
		mov	bx, ax
		test	ds:[bx].SPD_mode, mask SF_HARDWARE
		jz	software
	;
	; Assert the signal(s) we dropped to make the other side shut up.
	;		
		mov	dx, ds:[bx].SPD_base
		add	dx, offset SP_modemCtrl
		in	al, dx
		or	al, ds:[bx].SPD_stopCtrl
		mov	ds:[bx].SPD_curState.SPS_modem, al
		test	ds:[bx].SPD_flags, mask SPF_PORT_GONE
		jnz	software
		out	dx, al

software:
		test	ds:[bx].SPD_mode, mask SF_SOFTWARE
		jz	done
	;
	; Set the XON pending flag for the port and enable transmit interrupts
	; for it. SerialInt will take care of the rest.
	;
		ornf	ds:[bx].SPD_mode, mask SF_XON

		call	SerialEnableTransmit
done:
		.leave
		ret
SerialRestart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InterruptHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Macro containing the body of one of our interrupt handlers,
		minus the iret. Saves a couple registers, points another
		at the SerialPortData for the port and calls the common handler.

PASS:		portData= where to find the data for the port. ds will be
			  pointing at dgroup, so it can be used...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InterruptHandler macro	portData
		on_stack	iret
		
		push	ds
		push	si
		on_stack	si ds iret
		cld			;Need this, in case a notify routine
					; calls a system function, like
					; MemDeref...
		LoadVarSeg	ds
		lea	si, portData
		call	SerialInt
		pop	si
		pop	ds
		on_stack	iret
		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialPrimaryInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an interrupt on the primary serial interrupt level

CALLED BY:	hardware interrupt 4
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NEW_ISR
SerialPrimaryInt proc	far
		.enter
		InterruptHandler	ds:primaryVec
		.leave
		iret
SerialPrimaryInt endp
endif	; not NEW_ISR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialAlternateInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an interrupt on the alternate serial interrupt level

CALLED BY:	hardware interrupt 3
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NEW_ISR
SerialAlternateInt proc	far
		.enter
		InterruptHandler	ds:alternateVec
		.leave
		iret
SerialAlternateInt endp
endif	; not NEW_ISR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialWeird1Int
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an interrupt on the first weird interrupt level

CALLED BY:	?
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NEW_ISR
if	STANDARD_PC_HARDWARE
SerialWeird1Int proc	far
		.enter
		InterruptHandler	ds:weird1Vec
		.leave
		iret
SerialWeird1Int endp
endif
endif	; not NEW_ISR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialWeird2Int
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an interrupt on the second weird interrupt level

CALLED BY:	?
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NEW_ISR
if	STANDARD_PC_HARDWARE
SerialWeird2Int proc	far
		.enter
		InterruptHandler	ds:weird2Vec
		.leave
		iret
SerialWeird2Int endp
endif
endif	; NEW_ISR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialEOIFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	FAR version of SerialEOI for init code

CALLED BY:	SerialIDPort
PASS:		al	= interrupt level
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialEOIFar	proc	far
		.enter
		call	SerialEOI
		.leave
		ret
SerialEOIFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialEOI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge an interrupt from a port by sending a
		level-specific end-of-interrupt command to the appropriate
		interrupt controller(s)

CALLED BY:	SerialInt, SerialErrorHandler
PASS:		al	= interrupt level
RETURN:		nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialEOI	proc	near
		.enter
if	STANDARD_PC_HARDWARE
		cmp	al, 8
		mov	al, IC_GENEOI
		jl	notSecond
	;
	; Acknowledge with 2d controller too
	; 
		out	IC2_CMDPORT, al
notSecond:
		out	IC1_CMDPORT, al
endif	; STANDARD_PC_HARDWARE
		.leave
		ret
SerialEOI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialStopRemote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the remote side shut up using all methods of flow-
		control enabled for the port.

CALLED BY:	SerialInt
PASS:		ds:si	= SerialPortData
		es	= input stream
		ah	= mode byte for the port
RETURN:		ah	= new mode byte for the port
DESTROYED:	al

PSEUDO CODE/STRATEGY:
		If software flow-control is enabled, make sure the next byte
		that goes out is an XOFF by setting the SF_XOFF flag in
		the mode byte and by ensuring transmitter interrupts are
		enabled when we leave here.
		
		If hardware flow-control is enabled, clear the signal(s)
		the user of the port has designated as the one(s) that will
		make the other side shut up.
		
		Change the data notifier for the writing side of the input
		stream to actually be of type SNM_ROUTINE. The threshold and
		destination and data for the notifier were set up for us in
		SerialInitPort. This will cause SerialRestart to be called
		once the input stream has drained sufficiently.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NEW_ISR
SerialStopRemote proc	near	uses dx, cx
		.enter
		test	ah, mask SF_SOFTWARE or mask SF_HARDWARE
		jz	cantDoNuthin
		test	ah, mask SF_INPUT
		jz	cantDoNuthin	; => we're not allowed to control
					;  the remote
		test	ah, mask SF_SOFTWARE
		jz	hardware
	;
	; Set SF_XOFF and enable transmit interrupts to force XOFF to be the
	; next byte to be sent.
	; 
		ornf	ah, mask SF_XOFF
		ornf	ds:[si].SPD_ien, mask SIEN_TRANSMIT

ifndef	NO_POWER
		call	SerialBufferPowerChange
endif

hardware:
		test	ah, mask SF_HARDWARE
		jz	done
	;
	; De-assert whatever signals we were told to drop.
	;
		mov	cl, ds:[si].SPD_stopCtrl
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_modemCtrl
		; use SPS_modem, rather than reading the port, in case port
		; has gone missing -- want to keep a consistent view of what
		; that register should hold, not pollute it with an 0ffh
		mov	al, ds:[si].SPD_curState.SPS_modem
		not	cl
		and	al, cl
		out	dx, al
		mov	ds:[si].SPD_curState.SPS_modem, al
done:
	;
	; Enable routine notifier to call us when the other side has read
	; enough to bring the buffer below the low-water mark.
	; 
		mov	es:SD_writer.SSD_data.SN_type, SNM_ROUTINE
cantDoNuthin:
		.leave
		ret
SerialStopRemote endp
endif	; not NEW_ISR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialEnableTransOnlyIfXONorXOFFPending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stupid little routine to nuke out-of-range warnings,
		turning SIEN_TRANSMIT on or off in PD_ien based on whether
		we need to send an XON or XOFF

CALLED BY:	SerialInt
PASS:		ds:si	= SerialPortData
		ah	= SerialFlow for port
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NEW_ISR
SerialEnableTransOnlyIfXONorXOFFPending		proc	near
		.enter
		ornf	ds:[si].SPD_ien, mask SIEN_TRANSMIT

		test	ah, mask SF_XOFF or mask SF_XON
		jnz	done
		;
		; Shut off transmission interrupts if neither XON nor XOFF
		; pending.
		;
		andnf	ds:[si].SPD_ien, not mask SIEN_TRANSMIT
done:
ifndef	NO_POWER
		call	SerialBufferPowerChange
endif
		.leave
		ret
SerialEnableTransOnlyIfXONorXOFFPending		endp
endif	; not NEW_ISR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialProcessPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process an NS8250-compatible port

CALLED BY:	(INTERNAL) SerialInt
PASS:		ds:si	= SerialPortData
		INTERRUPTS OFF
RETURN:		cx	= SerialModemStatus
		bp	= notifications needed from this processing of the
			  port
		dx	= interrupt-enable port
DESTROYED:	ax, bx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NEW_ISR
SerialProcessPort proc	near
		.enter
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_iid

		clr	ah		; no notifications, yet

		in	al, dx

if INTERRUPT_STAT
	;
	; Serial Interrupt Statatistics
	;
		call	RecordInterruptType
endif

	;
	; Just exit if there is no pending interrupt to be handled
	;
		test	al, mask SIID_IRQ
		jnz	prepareExit
		
		test	al, not SerialIID
		jz	checkStatus
		
prepareExit::	
	;
	; Port is likely on PCMCIA card that has been removed -- stop servicing
	; it now.
	;
		clr	bp, cx		; bp <- no notifications, cx <- no
					;  modem status changes
		jmp	exit

checkStatus:

if	INTERRUPT_LOGGING
		call	SerialLogIID
endif	;INTERRUPT_LOGGING

		; 5/9/94: clearing of IEN removed b/c transition from
		; !TIEN to TIEN forces bogus transmitter interrupt, and
		; my earlier supposition of why I sometimes ended up with
		; the 8250 thinking it had a transmit interrupt pending
		; while the 8259 thought it didn't seems not to have ever
		; been seen by Ray Gwinn, who has been dealing with these
		; chips for years and years and years -- ardeb

;;		add	dx, offset SP_ien - offset SP_iid
;;		mov	al, ds:[si].SPD_ien
;;		andnf	al, mask SIEN_TRANSMIT
;;		out	dx, al
	;
	; Fetch the status of the port into al
	;
;;		add	dx, offset SP_status - offset SP_ien
		add	dx, offset SP_status - offset SP_iid
		mov	cx, SERIAL_ERROR	; cx <- bits we're interested in
	;
	; If an error has been detected by the port, record it.
	;
	; NOTE: MULTIPLE ERRORS ON NESTED INTERRUPTS ARE MERGED INTO ONE
	; ERROR NOTIFICATION HERE. IS THIS KOSHER?
	;
		in	al, dx
		and	cl, al
		jz	checkDataAvail		; None of the error bits
						;  is set.
		ornf	ax, mask SNN_ERROR
		or	ds:[si].SPD_error, cl
		
if	INTERRUPT_STAT
	;
	; Check for overrun error
	;
		test	cl, mask SS_OVERRUN
		jz	noOverrun
		IncIntStatCount	ISS_overrunCount
noOverrun:
endif

	;----------------------------------------------------------------------
	;		 HANDLE INCOMING DATA
checkDataAvail:		
	;
	; Save already-determined notification & status data, as we need to
	; munge ah here (al needs to continue to hold the SerialStatus record).
	; 
		mov	bp, ax
	;
	; The mode of the port goes in ah for the duration.
	;
		mov	ah, ds:[si].SPD_mode
	;
	; Handle data being available next, as we've no control over when more
	; data may come in.
	;
		add	dx, offset SP_data - offset SP_status
		test	al, mask SS_DATA_AVAIL
		jz	checkHWFC
		call	HandleInputByte

	;----------------------------------------------------------------------
	;	     HANDLE HARDWARE FLOW-CONTROL
checkHWFC:
	;
	; Fetch the modem status and check on hardware flow-control. DX
	; contains SP_status for the port. We have to fetch and save b/c the
	; fetch destroys the delta indicators used for the SNE_MODEM notifier.
	; 
		add	dx, offset SP_modemStatus - offset SP_data
		in	al, dx			; read the modem status port


		mov	bl, al			; save status
		push	ax

		test	ah, mask SF_HARDWARE
		jz	checkTrans		; if hwfc not enabled, then
						;  don't check for it

		andnf	ah, not mask SF_HARDSTOP; Assume no signal(s) down.
		test	al, ds:[si].SPD_stopSignal ; only look at certain bits
		mov	al, bl			; restore status
		jnz	checkOutputRestart	; We were right.
		ornf	ah, mask SF_HARDSTOP	; Fall through as we must still
						;  check for XOFF needing to be
						;  sent.
		call	SerialEnableTransOnlyIfXONorXOFFPending
storeModeCheckTrans:
		mov	ds:[si].SPD_mode, ah

	;----------------------------------------------------------------------
	;	       HANDLE DATA TRANSMISSION
checkTrans:
	;
	; See if we're allowed to send a byte.
	;
		test	bp, mask SS_THRE shl (offset SNN_STATUS)
		jz	done

		add	dx, offset SP_data - offset SP_modemStatus
		mov	cl, not mask SIEN_TRANSMIT
		call	HandleOutputByte
		jc	outputEmpty
done:
		pop	cx			; recover status fetched for
						;  checking hw flow-control
exit:
	;
	; Get the io address we use to (re-)enable the interrupts we need
	; enabled
	;
		mov	dx, ds:[si].SPD_base
		add	dx, offset SP_ien
		.leave
		ret

outputEmpty:
	;----------------------------------------------------------------------
	;	      HANDLE OUTPUT STREAM EMPTY
	;
	; Output stream was empty. Make sure transmit interrupts are off for
	; this port when we leave and that our data notifier is back on for the
	; output stream.
	;
		mov	dl, not mask SIEN_TRANSMIT
		call	HandleOutputEmpty
		jmp	done

checkOutputRestart:
	;
	; If output was stopped due to HWFC before, then re-enable it. If
	; there's nothing to output, or we're stopped by SWFC, this will
	; just generate an extra xmit interrupt, at which point we'll notice
	; we're stopped and disable the xmit interrupt again. No big wup.
	; 				-- ardeb 9/9/93
	; 
		test	ds:[si].SPD_mode, mask SF_HARDSTOP
		jz	storeModeCheckTrans
		ornf	ds:[si].SPD_ien, mask SIEN_TRANSMIT
ifndef	NO_POWER
		call	SerialBufferPowerChange
endif
		jmp	storeModeCheckTrans

SerialProcessPort endp
endif	; not NEW_ISR



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common interrupt handler code.

CALLED BY:	SerialWeird2Int, SerialWeird1Int,
       		SerialAlternateInt, SerialPrimaryInt
PASS:		ds:si	= SerialVectorData of interrupting vector
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	COUNT_INTERRUPTS_AND_INPUT
udata	segment
	numSerialInts	word	(?)
	numRead		word
udata	ends
endif
ife	NEW_ISR
SerialInt	proc	near	uses ax, bx, cx, dx, di, es, bp
		.enter

if	COUNT_INTERRUPTS_AND_INPUT
PrintMessage< Warning - interrupt counting turned on >

		inc	ds:[numSerialInts]
endif
IS <		push	si						>
IS <		mov	si, ds:[si].SVD_port				>
IS <		IncIntStatCount	ISS_interruptCount			>
IS <		pop	si						>

if 	TRACK_INTERRUPT_DEPTH
		mov	ax, ds:[curIntDepth]
		inc	ax
		mov	ds:[curIntDepth], ax
		cmp	ax, ds:[maxIntDepth]
		jbe	1$
		mov	ds:[maxIntDepth], ax
1$:
endif	; TRACK_INTERRUPT_DEPTH

	;
	; Disable context switches and save the interrupt level for sending
	; the end-of-interrupt command when we're done.
	;
		call	SysEnterInterrupt

		inc	ds:[si].SVD_active	; mark another active IRQ frame
		mov	ds:[si].SVD_interrupted, 1; so top-level frame knows
						;  another interrupt has
						;  happened
		mov	di, si			; ds:di <- vector
	;
	; We now loop through the ports at this level repeatedly until none of
	; the ports has anything to give or take from us, as indicated by
	; ds:di.SVD_useful ending up 0, in all the bits that indicate the
	; hardware was active, at the end of a loop through the ports.
	; 
startPortLoop:
		clr	ds:[di].SVD_useful
		mov	si, ds:[di].SVD_port	; ds:si <- first port
portLoop:
		test	ds:[si].SPD_flags, mask SPF_PORT_GONE
		jnz	nextPort

		call	SerialProcessPort

checkModemStatusCX::		; zoomer-specific label...
	;
	; If one of the modem bits changed and there's a modem notifier
	; registered, record the modem status for generating the notification.
	; 
		test	cl, mask SMS_DCD_CHANGED or mask SMS_RING_CHANGED or \
				mask SMS_DSR_CHANGED or \
				mask SMS_CTS_CHANGED
		jz	portDone

		tst	ds:[si].SPD_modemEvent.SN_type
		jz	portDone

	;
	; Record the most recent state of the modem bits, but OR in the
	; changed bits, creating a union of the things we've seen during
	; this loop and nested interrupts.
	;
		andnf	ds:[si].SPD_modemStatus,
			not (mask SMS_DCD or mask SMS_RING or mask SMS_DSR or \
			     mask SMS_CTS)
		or	ds:[si].SPD_modemStatus, cl

		ornf	bp, mask SNN_MODEM
portDone:
	;
	; Remember what was done for this port during this iteration so we
	; know whether the iteration produced anything interesting.
	; 
		ornf	ds:[di].SVD_useful, bp
	;
	; Merge the new notifications into those pending for the port.
	; This whomps on the SNN_STATUS field, but we don't need it anymore.
	; 
		ornf	ds:[si].SPD_notifications, bp

if	INTERRUPT_LOGGING
		call	SerialLogNotes
endif	;INTERRUPT_LOGGING
	;
	; Enable those interrupts that need enabling
	; 
		mov	al, ds:[si].SPD_ien
		out	dx, al
		jmp	$+2
		out	dx, al	; and again, to avoid losing transmitter
				;  interrupt from initial read of
				;  IID at start of the loop
	;
	; Advance to the next port for this interrupt level.
	;
nextPort:
		mov	si, ds:[si].SPD_next
		tst	si
		jnz	portLoop

	;
	; If we did anything this time through the port loop, then try again.
	; We keep doing this until no port is ready for us to do diddly with
	; it.
	; 
		test	ds:[di].SVD_useful, mask SNN_ERROR or \
				mask SNN_RECEIVE or \
				mask SNN_TRANSMIT or \
				mask SNN_MODEM or \
				mask SNN_INPUT_FULL
		jnz	startPortLoop

	;
	; We're done handling stuff, now turn on interrupts and send
	; appropriate notification
	;
		mov	al, ds:[di].SVD_irq
		call	SerialEOI
	;
	; If we're not the top-most interrupt frame, just bail -- the
	; topmost one will take care of any of the stuff we set up here.
	; 
		cmp	ds:[di].SVD_active, 1
		jne 	afterNotifications

startNotificationLoop:
	;
	; Loop through all the ports for the level (again) generating all
	; the appropriate notifications. Clear the SVD_interrupted flag so
	; we know if an interrupt occurred for the vector while we were in
	; the loop, meaning we have to loop back to find something else
	; that needs doing.
	; 
		mov	ds:[di].SVD_interrupted, 0
		INT_ON
		lea	si, ds:[di].SVD_port-offset SPD_next
		push	di

notificationLoop:
	;
	; Advance to the next port.
	; 
		mov	si, ds:[si].SPD_next
		tst	si
		jz	notificationsDone
	;
	; Fetch the notifications it has pending and clear them at the
	; same time...
	; 
		clr	ax
		xchg	ds:[si].SPD_notifications, ax
		call	SerialSendNotifications
		jmp	notificationLoop

notificationsDone:
	;
	; We've handled all the ports for this level. See if one of them
	; interrupted during all that.
	; 
		pop	di
		INT_OFF
		tst	ds:[di].SVD_interrupted
		jnz	startNotificationLoop

afterNotifications:
		dec	ds:[di].SVD_active
if	TRACK_INTERRUPT_DEPTH
		dec	ds:[curIntDepth]
endif	; TRACK_INTERRUPT_DEPTH
		call	SysExitInterrupt

		.leave
		ret
SerialInt	endp
endif	; not NEW_ISR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSendNotifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send all the pending notifications for a single port.

CALLED BY:	(INTERNAL) SerialInt
PASS:		ax	= SerialNotificationsNeeded
		ds:si	= SerialPortData wanting notification
RETURN:		nothing
DESTROYED:	ax, cx, dx, es, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife NEW_ISR
SerialSendNotifications proc	near
		.enter
	;
	; do receive VSem
	;
		test	ax, mask SNN_RECEIVE
		jz	checkTransmit
		mov	es, ds:[si].SPD_inStream
		mov	bx, offset SD_reader.SSD_sem
		call	SerialVStream

checkTransmit:
	;
	; do transmit VSem
	;
		test	ax, mask SNN_TRANSMIT
		jz	checkModem
		mov	es, ds:[si].SPD_outStream
		mov	bx, offset SD_writer.SSD_sem
		call	SerialVStream

checkModem:
	;
	; if modem notification needed then send it
	;
		test	ax, mask SNN_MODEM
		jz	checkError

		push	ax
	;
	; Try to pass along the inStream token, as Modem notification
	; is based upon input, but if that stream is no longer available,
	; pass along the outStream token.
	;
		mov	ax, ds:[si].SPD_inStream
		tst	ax
		jnz	modemNotificationHaveStream
		mov	ax, ds:[si].SPD_outStream

modemNotificationHaveStream:
		clr	cx		; need to reset the delta bits...
		xchg	cl, ds:[si].SPD_modemStatus
		jcxz	modemSent		; a second notification could
						;  have been asked for between
						;  when SPD_notifications was
						;  0'd and when we got here in
						;  the previous iteration. if
						;  so, the notification would
						;  already have been sent, so
						;  this SNN_MODEM is a false
						;  positive
		mov	es, ax
		lea	di, ds:[si].SPD_modemEvent
		mov	ah, STREAM_NOACK
		call	StreamNotify

modemSent:
		pop	ax

checkError:
	;
	; if error notification needed then send it
	; 
	; XXX: MULTIPLE ERRORS WILL BE CONDENSED INTO ONE HERE. IS THIS
	; GOOD?
	;
		test	ax, mask SNN_ERROR
		jz	checkReceiveNotify

		push	ax, di
		clr	cx
		xchg	ds:[si].SPD_error, cl
		jcxz	afterSetError		; same logic applies here as
						;  for SNN_MODEM case, above

		mov	ax, STREAM_WRITE	; Assume input stream exists
		mov	bx, ds:[si].SPD_inStream
		tst	bx
		jnz	setError
		mov	ax, STREAM_READ		; Output stream?
		or	bx, ds:[si].SPD_outStream; (bx must be zero...)
		jz	afterSetError		; No streams => no error, but
						;  still must read any waiting
						;  data to clear port's irq
setError:
		mov	di, DR_STREAM_SET_ERROR
		call	StreamStrategy
afterSetError:
		pop	ax, di

checkReceiveNotify:
	;
	; if receive notification needed then send it (nested stuff, as per
	; SNN_MODEM & SNN_ERROR, is taken care of by ack mechanism for data
	; notifier)
	;
		test	ax, mask SNN_RECEIVE
		jz	checkTransmitNotify
		mov	es, ds:[si].SPD_inStream
		tst	es:SD_reader.SSD_data.SN_type
		jz	checkTransmitNotify
		push	ax
		call	StreamReadDataNotify
		pop	ax

checkTransmitNotify:
	;
	; if transmit notification needed then send it
	;
		test	ax, mask SNN_TRANSMIT
		jz	checkDestroyNotify
		mov	es, ds:[si].SPD_outStream
		tst	es:SD_writer.SSD_data.SN_type
		jz	checkDestroyNotify
		push	ax
		call 	StreamWriteDataNotify
		pop	ax

checkDestroyNotify:
	;
	; if destroy notification needed then send it. We have to be careful,
	; however, as another interrupt could have come in and that nested
	; interrupt handler would have sent the destroy notification so
	; the stream won't actually exist.
	;
	; 2/10/95: we may wakeup SD_closing more than once, since we don't
	; zero SPD_outStream until someone returns to SerialStrategy and
	; reduces the refCount to 0. Multiple wakeups on SD_closing should
	; be ok, however, unless there are more than 16 of them. -- ardeb
	;
		test	ax, mask SNN_DESTROY
		jz	done
		mov	cx, ds:[si].SPD_outStream
		jcxz	done
		mov	es, cx
		tst	es:SD_useCount
		jg	done
		mov	ax, es
		mov	bx, offset SD_closing
		call	ThreadWakeUpQueue

done:
		.leave
		ret
SerialSendNotifications endp
endif	; NEW_ISR



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialVStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the necessary V operations on the given stream,
		as indicated by the SD_unbalanced count for the stream.

CALLED BY:	(INTERNAL) SerialInt
PASS:		es	= stream segment
		bx	= offset of semaphore to V (within ES)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	es:SD_unbalanced is reduced to 0

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife NEW_ISR
SerialVStream	proc	near
		uses	ax
		.enter
		INT_OFF
		tst	es:[SD_unbalanced]
		jz	done		; => got handled on previous pass
vLoop:
		VSem	es, [bx], TRASH_AX, NO_EC
		dec	es:[SD_unbalanced]
		jnz	vLoop
done:
		INT_ON
		.leave
		ret
SerialVStream	endp
endif ; NEW_ISR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleOutputByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes a byte out to the port.

CALLED BY:	(INTERNAL) SerialProcessPort, SerialProcessPortZoomer
PASS:		dx - port to write out
		ah - SerialFlow
		cl - byte to use to mask out SPD_ien if we want to stop
		     the IO (flow control)
		ds:si - SerialPortData     
		bp - SerialNotificationsNeeded

RETURN:		carry set if stream was empty (no data to send)
		bp - adjusted SerialNotificationsNeeded
DESTROYED:	al, cx, es
 
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NEW_ISR
HandleOutputByte	proc	near
	.enter
	;
	; Transmitter is free. Do we have an XON or XOFF pending here?
	;
		mov	ch, 1			;Assume no FIFO (only one byte
						; can be written out)
		test	ds:[si].SPD_flags, mask SPF_FIFO
		jz	loopTop
		mov	ch, FIFO_SIZE
loopTop:
		test	ah, mask SF_XON or mask SF_XOFF
		jz	sendFromStream
		mov	al, 'S' AND 0x1f		; Assume XOFF
		test	ah, mask SF_XOFF
		jnz	sendSpecial			; Yup.
		mov	al, 'Q' AND 0x1f		; Nope. Send XON
sendSpecial:
		;
		; Can't both be on at once, so just clear them both...
		;
		andnf	ah, not (mask SF_XON or mask SF_XOFF)
		mov	ds:[si].SPD_mode, ah		; record new mode
		;
		; If output stopped, disable transmit interrupts after
		; this byte is sent.
		; 
		test	ah, mask SF_SOFTSTOP or mask SF_HARDSTOP
		jz	sendByte

		and	ds:[si].SPD_ien, cl
		jmp	sendByte

sendFromStream:
	;
	; Fetch a byte from the output stream, if one's available and output
	; isn't stopped. If output is stopped, then disable transmit
	; interrupts until SF_XON/SF_XOFF is set or until we're told it's ok
	; to continue.
	;
		test	ah, mask SF_SOFTSTOP or mask SF_HARDSTOP
		jnz	disableOutput
		

	;If the stream has been freed (port has closed), exit

		tst	ds:[si].SPD_outStream
		jz	returnNonEmpty
		mov	es, ds:[si].SPD_outStream
		StreamGetByteNB	es, al, NO_VSEM
		jc	exit
		or	bp, mask SNN_TRANSMIT
	;
	; Send byte from AL (dx contains port from checkHWFC).
	;
sendByte:

		out	dx, al
		dec	ch
		jnz	loopTop
returnNonEmpty:
		clc
exit:
		.leave
		ret
		
	;
	; checking for IRLAP EOF character is an overkill, so we decided to
	; remove it.
	;
		
disableOutput:
		and	ds:[si].SPD_ien, cl
		jmp	returnNonEmpty

HandleOutputByte	endp
endif	; not NEW_ISR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleOutputEmpty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cope with the output stream being empty, reestablishing the
		data notifier, shutting off interrupts, coping with lingering
		destroyers, etc.

CALLED BY:	(INTERNAL) SerialProcessPort, SerialProcessPortZoomer
PASS:		ds:si	= SerialPortData
		es	= output stream segment
		dl	= mask for clearing transmitter interrupt out of
			  SPD_ien
		bp	= current SerialNotificationsNeeded record
RETURN:		bp	= adjusted
		ds:si.SPD_ien possibly with transmit interrupt flag cleared
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/21/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	NEW_ISR
HandleOutputEmpty proc	near
		.enter

	;
	; if actually sent something, wait until we get the interrupt following
	; its transmission before doing this stuff. Allows the power to remain
	; on during the transmission, and permits the FIFO to be filled during
	; the initial write of data to the stream -- ardeb 8/21/95
	;
		test	bp, mask SNN_TRANSMIT
		jnz	done
		andnf	ds:[si].SPD_ien, dl
ifndef	NO_POWER
		call	SerialBufferPowerChange
endif
	;
	; Acknowledge the initial notification that got us to turn transmit
	; interrupts on, then note the thing was empty, so we know something
	; happened.
	;
		mov	es:[SD_reader.SSD_data.SN_ack], 0
		ornf	bp, mask SNN_EMPTY
	;
	; If the stream was being nuked and we were just waiting for
	; data to drain set SNN_DESTROY so we know to clear the
	; output stream, etc.
	;
		test	es:[SD_state], mask SS_LINGERING
		jz	done
		ornf	es:[SD_state], mask SS_NUKING
		andnf	es:[SD_state], not mask SS_LINGERING
		ornf	bp, mask SNN_DESTROY
done:
		.leave
		ret
HandleOutputEmpty endp
endif	; not NEW_ISR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleInputByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reads a byte from the port, handles any XON/XOFF stuff, and
		writes the byte to the input stream if appropriate.
		

CALLED BY:	(INTERNAL) SerialProcessPort, SerialProcessPortZoomer
PASS:		ah - SerialFlow for the port
		dx - io port to read from 
		bp - SerialNotificationsNeeded
		ds:si - SerialPortData for the port
RETURN:		bp - modified SerialNotificationsNeeded
DESTROYED:	al, cx, es, bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;;udata	segment
;;inputFull	dword
;;udata	ends

ife	NEW_ISR
HandleInputByte	proc	near
		.enter
		in	al, dx
		and	al, ds:[si].SPD_byteMask	; If in COOKED mode,
							;  strip off the high
							;  bit of the byte to
							;  handle errant parity
							;  bits hiding in an
							;  8-bit data byte.

if	COUNT_INTERRUPTS_AND_INPUT
		inc	ds:[numRead]
endif
	;
	; If output flow control enabled, watch for XON/XOFF characters on
	; input.
	;
		test	ah, mask SF_SOFTWARE or mask SF_OUTPUT
		jz	noFlow
		jpo	noFlow			; => one not set
		cmp	al, 'S' AND 0x1f	; XOFF?
		je	handleXOFF
		cmp	al, 'Q' AND 0x1f	; XON?
		je	handleXON
noFlow:
		;
		; Now we know the byte isn't for flow-control, if we actually
		; have an input stream, store the byte in it.
		; 
		mov	cx, ds:[si].SPD_inStream
		jcxz	full		; No place to store char so just
					;  drop it.
		mov	es, cx		; es <- seg of buffer
	;
	; If this is a passive connection, make sure there is enough
	; room to fit another byte.
	;
		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		jnz	checkForRoom	; jump if passive
		
storeByte:
		StreamPutByteNB	es, al, NO_VSEM		;(doesn't trash ah if
							;can't write)
		jc	full		; => not stored, so no change of which
					;  to notify and no checking for
					;  high-water mark.
		ornf	bp, mask SNN_RECEIVE
	;
	; See if input stream is in danger of o'erflowing and force an XOFF
	; the next time we can send a byte if so. Of course, if no flow-control
	; is enabled, there's nothing we can do...Note that (for now) we only
	; stop the remote when the input stream *reaches* the high-water mark.
	; Perhaps we should send it again if we get to a second high-water mark?
	; 
		mov	ah, ds:[si].SPD_mode	;...was trashed by PutByte
		test	ah, mask SF_SOFTWARE or mask SF_HARDWARE
		jz	doNotStoreMode

		mov	bx, es:SD_reader.SSD_sem.Sem_value
		add	bx, es:[SD_unbalanced]	; bx <- actual # bytes in
						;  there, including those
						;  gotten during this int.
		cmp	bx, ds:[si].SPD_highWater
		jne	doNotStoreMode		;(don't bother to store
						; unchanged mode)
		call	SerialStopRemote
storeModeAndExit:
		mov	ds:[si].SPD_mode, ah
doNotStoreMode::
	;
	; We could just exit here, but if we are running in FIFO mode, we
	; may have a whole bunch of data sitting in the FIFO, so we might
	; as well quickly branch up to grab some more bytes, if there are
	; any.
	;
		add	dx, offset SP_status - offset SP_data
		in	al, dx
		add	dx, offset SP_data - offset SP_status
		test	al, mask SS_DATA_AVAIL
		jnz	HandleInputByte
exit:
		.leave
		ret

full:
	;
	; Flag that the input was full, so the caller knows we *did* something,
	; but couldn't actually *do* anything, if you see what I mean. This
	; prevents multiple interrupts from happening to empty a FIFO when
	; the input stream overflows...
	; 
		ornf	bp, mask SNN_INPUT_FULL
;;	inc	ds:[inputFull].low
;;	jnz	exit
;;	inc	ds:[inputFull].high
		jmp	exit

handleXON:
		;
		; Clear STOP and send stuff as soon as possible
		;
		andnf	ah, not mask SF_SOFTSTOP
		ornf	ds:[si].SPD_ien, mask SIEN_TRANSMIT
ifndef	NO_POWER
		call	SerialBufferPowerChange
endif
		jmp	storeModeAndExit

handleXOFF:
		;
		; Set stop bit, but still check for transmission (and turn
		; transmit interrupts on, just in case) possible if an
		; XON or an XOFF is pending to the other side.
		;
		ornf	ah, mask SF_SOFTSTOP
		call	SerialEnableTransOnlyIfXONorXOFFPending
		jmp	storeModeAndExit

checkForRoom:
EC <		call	ECSerialVerifyPassive				>
		;
		; Is there enough room for another byte in the passive buffer?
		; Must compare against SD_max-1 b/c pointer will never reach
		; SD_max (if it does, it wraps to &SD_data)
		;
		mov	cx, es:SD_max
		dec	cx
		cmp	es:SD_writer.SSD_ptr, cx
LONG		jb	storeByte		; jump if enough room
		
		ornf	bp, mask SNN_INPUT_FULL	; so we know something happened
						;  to the port...

		;
		; The stream is full.  Send a notification (once) to
		; the owner of this passive port.
		;
		; 2/22/95: in theory this really ought to be in SerialSendNotif-
		; ications, but if we put it there, other weird cases having to
		; do with the port being pre-empted and restored before we can
		; actually perform the notification come into play, and I don't
		; want to mess with it -- ardeb
		;
		test	ds:[si].SPD_passive, mask SPS_BUFFER_FULL
		jnz	exit			; jump if a notification has
						; already been sent.
		;
		; Send off a notification to the owner of the passive port
		; that the buffer is full.
		;
		ornf	ds:[si].SPD_passive, mask SPS_BUFFER_FULL

		mov	cx, mask SPNS_BUFFER_FULL or \
				mask SPNS_BUFFER_FULL_CHANGED
		call	SerialPassiveNotify
		jmp	exit
		
HandleInputByte	endp
endif	; not NEW_ISR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shut off all open serial ports while we task-switch out.

CALLED BY:	DR_SUSPEND
PASS:		cx:dx	= buffer for reason for failure
		ds	= dgroup (from SerialStrategy)
RETURN:		carry set if refuse to suspend
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialSuspend	proc	near
		uses	si, cx, dx, bx
		.enter

		mov	si, offset comPorts
		mov	cx, ds:[numPorts]
		call	SerialSuspendLoop
		jc	done

		mov	si, offset comPortsPassive
		mov	cx, ds:[numPorts]
		call	SerialSuspendLoop
done:
		.leave
		ret
SerialSuspend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSuspendLoop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loop through a set of SerialPortData structures to
		shut off their ports.

CALLED BY:	SerialSuspend

PASS:		ds:si - points to a table of offsets to SerialPortData
			structures
		cx - number of SerialPortData structures

RETURN:		carry set if refuse to suspend

DESTROYED:	ax, di

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialSuspendLoop	proc	near
	.enter

portLoop:
		lodsw
		push	si
	;
	; See if the port exists. If SPD_base is 0, it don't exist
	; 
		mov_tr	si, ax
		mov	dx, ds:[si].SPD_base
		tst	dx
		jz	nextPort
	;
	; If the port is not open, ignore it.
	; 
		IsPortOpen si
		jg	nextPort
	;
	; It's open.  If the port is active, shut it down.
	;
		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		jz	shutItDown
	;
	; It's a passive port.  If it's been preempted, then the active version
	; of this port has already been shut down.
	;
		test	ds:[si].SPD_passive, mask SPS_PREEMPTED
		jnz	nextPort		; jump if preempted
		
shutItDown:
	;
	; Shut off input from the other side using whatever means are at our
	; disposal.
	; 
		mov	es, ds:[si].SPD_inStream
		mov	ah, ds:[si].SPD_mode
if	NEW_ISR
		call	StopIncomingData	; SPD_mode adjusted
		mov	ah, ds:[si].SPD_mode
else
		call	SerialStopRemote
		mov	ds:[si].SPD_mode, ah
endif
	;
	; If software flow-control is enabled, set the interrupt-enable registr
	; to match what SerialStopRemote set it to and wait for the SF_XOFF
	; flag to clear from SPD_mode, indicating the XOFF character needed to
	; stop the other side has been sent.
	; 
if	STANDARD_PC_HARDWARE
		add	dx, offset SP_ien
endif	; STANDARD_PC_HARDWARE
		test	ah, mask SF_SOFTWARE
		jz	shutOffPortInterrupts
		mov	al, ds:[si].SPD_ien
		out	dx, al
waitForXoffToBeSentLoop:
		test	ds:[si].SPD_mode, mask SF_XOFF
		jnz	waitForXoffToBeSentLoop

shutOffPortInterrupts:
	;
	; Now the remote side has been notified, shut off all interrupts from
	; the port.
	; XXX: turn off OUT2 to tri-state the thing off the bus, too?
	; 
		clr	al
		out	dx, al
nextPort:
		pop	si
		loop	portLoop
		clc
		.leave
		ret
SerialSuspendLoop	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-enable both the active and the passive serial ports that
		were open before we went into stasis

CALLED BY:	DR_UNSUSPEND
PASS:		ds	= dgroup (from SerialStrategy)
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/20/92		Initial version
	jdashe	5/6/94		Added passive support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialUnsuspend	proc	near
		uses	cx, dx, si, bx, es
		.enter
		mov	si, offset comPorts
		mov	cx, ds:[numPorts]
		call	SerialUnsuspendLoop

		mov	si, offset comPortsPassive
		mov	cx, ds:[numPorts]
		call	SerialUnsuspendLoop

		.leave
		ret
SerialUnsuspend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialUnsuspendLoop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-enable the serial ports listed in a table.

CALLED BY:	SerialUnsuspend

PASS:		ds:si	- table of pointers to SerialPortData structures
		cx	- number of pointers in the table

RETURN:		nothing

DESTROYED:	ax, di, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialUnsuspendLoop	proc	near
		.enter

portLoop:
		lodsw
		push	si
		mov_tr	si, ax
	;
	; If the port doesn't exist (SPD_base is 0), go to the next one.
	; 
		tst	ds:[si].SPD_base
		jz	nextPort
	;
	; If the port's not open, ignore it.
	; 
		IsPortOpen	si
		jg	nextPort

		test	ds:[si].SPD_passive, mask SPS_PASSIVE
		jz	reestablishState	; jump if active.
	;
	; The port's passive.  If it's been preempted, then go to the
	; next one.
	;
		test	ds:[si].SPD_passive, mask SPS_PREEMPTED
		jnz	nextPort		; jump if preempted.

reestablishState:
	;
	; Since we might have task switched, the port may be in an odd state
	; Put it back to where it was.
	;
		push	di
		mov	bx, si			; ds:bx is now SerialPortData
		call	SerialReestablishState
		pop	di

	;
	; If the input stream isn't overflowing, restart the remote in whatever
	; way is possible with this port.
	; 
		mov	es, ds:[si].SPD_inStream
		mov	ax, es:[SD_reader].SSD_sem.Sem_value
		cmp	ax, ds:[si].SPD_highWater
		ja	remoteNotified
		
		mov	dx, es
		mov	ax, si
		call	SerialRestart
remoteNotified:
	;
	; Re-enable all interrupts that are supposed to be enabled, in case
	; we didn't actually call SerialRestart.
	; 
if	STANDARD_PC_HARDWARE
		mov	dx, ds:[si].SPD_base		
		add	dx, offset SP_ien
endif	; STANDARD_PC_HARDWARE
		mov	al, ds:[si].SPD_ien
		out	dx, al
nextPort:
		pop	si
		loop	portLoop

		.leave
		ret
SerialUnsuspendLoop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialNotifyModemNotifierChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The SNE_MODEM notifier has been changed.  Call it
		right away so that it can receive the initial settings.

CALLED BY:	(INTERNAL) SerialSetNotify
PASS:		ds:bx	= SerialPortData
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if NOTIFY_WHEN_SNE_MODEM_CHANGED

SerialNotifyModemNotifierChanged	proc	near
		uses	ax,cx,di,es
		.enter
	;
	; The client might want to know the initial settings of DTR &
	; RTS.  Lets send those right away.
	;
		mov	ax, ds:[bx].SPD_inStream
		tst	ax
		jnz	haveStream
		mov	ax, ds:[bx].SPD_outStream
haveStream:
		mov	cl, ds:[bx].SPD_modemStatus
	;
	; Mark the status bits as having changed so that the client
	; will pay attention to them.
	;
		or	cl, mask SMS_DTR_CHANGED or mask SMS_RTS_CHANGED or mask SMS_DSR_CHANGED or mask SMS_CTS_CHANGED

		mov	es, ax				; es = stream
		lea	di, ds:[bx].SPD_modemEvent	; ds:di=streamNotifier
		mov	ah, STREAM_NOACK
		call	StreamNotify			; send notification

		.leave
		ret
SerialNotifyModemNotifierChanged	endp

endif


Resident	ends

