COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parallelInt.asm

AUTHOR:		Adam de Boor, Feb  6, 1990

ROUTINES:
	Name			Description
	----			-----------
	ParallelNotify		Notification routine called by stream driver
	ParallelPrimaryInt	Interrupt routine for primary printer vector
	ParallelAlternateInt	Interrupt routine for alternate printer vector
	ParallelWeird1Int	First interrupt routine for some vector other
				than the printer ones.
	ParallelWeird2Int	Second interrupt routine for some vector other
				than the printer ones.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 6/90		Initial revision


DESCRIPTION:
	Functions to handle the read-side of a parallel port's stream,
	fielding interrupts, dealing with timers, etc.
		
	This is the file in the driver that has free rein to play with the
	stream driver data (nobody else should).

	$Id: parallelInt.asm,v 1.1 97/04/18 11:46:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	parallel.def

include thread.def

UseDriver Internal/fsDriver.def
UseDriver Internal/dosFSDr.def
include Internal/dos.def
include Internal/fsd.def

Resident	segment	resource

PBP	proc	near
	call	SysLockBIOS
	ret
PBP	endp

VBP	proc	near
	call	SysUnlockBIOS
	ret
VBP	endp

;------------------------------------------------------------------------------
;
;			    WATCHDOG TIMER
;
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelRestart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restart output on a port that shut up due to an error.

CALLED BY:	ParallelWatchdog
PASS:		ds:si	= ParallelPortData for the port
RETURN:		nothing
DESTROYED:	ax, dx (di, bx, es by ParallelSendAndNotify)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelRestart	proc	near
		.enter
		mov	al, ds:[si].PPD_lastSent
		call	ParallelSendAndNotify
		jc	done		; Error => nothing more to do

	;
	; If port has interrupts enabled, turn them back on again.
	;
		cmp	ds:[si].PPD_irq, 1
		jbe	done
		mov	dx, ds:[si].PPD_base
		add	dx, offset PP_ctrl
		mov	al, ds:[si].PPD_ctrl
		ornf	al, mask PC_IEN
		mov	ds:[si].PPD_ctrl, al
		out	dx, al
done:
		.leave
		ret
ParallelRestart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelCheckError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed port has an error pending

CALLED BY:	ParallelWatchdog, ParallelDebounce
PASS:		ds:si	= ParallelPortData
RETURN:		ax	= ParallelError record (some bits outside the domain
			  of the record may be set, but high byte always clear)
		ZF	= 0 (jnz) if error detected
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelCheckError	proc	near
		.enter
	;
	; If printing via DOS then return no error
	;
		mov	ax, mask PS_BUSY	; (clears AH)
		cmp	ds:[si].PPD_irq, 1
		je	done

		tst	ds:[si].PPD_thread
		jnz	useBios

		mov	dx, ds:[si].PPD_base
		inc	dx	| CheckHack <offset PP_status eq 1>
		in	al, dx
	;
	; Get the bits in the status register to be set if there's
	; an error. We need to invert PS_SELECT and PS_ERROR to achieve
	; this...
	;
		xornf	al, mask PS_SELECT or mask PS_ERROR
	;
	; Clear out any masked errors.
	;
figureErrors:
		andnf	ax, ds:[si].PPD_errMask
	;
	; Any errors left?
	;
done:
		test	ax, mask ParallelError
		.leave
		ret
useBios:
	;
	; Consult the BIOS to get the error code, rather than going to the
	; hardware directly.
	;
		mov	dx, ds:[si].PPD_biosNum
		call	PBP
		mov	ah, 2		; get port status
		int	17h
		call	VBP
		mov	al, ah
		xornf	al, mask PS_SELECT	; BIOS only inverts PS_ERROR
		clr	ah			; PE_TIMEOUT|PE_FATAL not
						;  set
		jmp	figureErrors
ParallelCheckError	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelWatchdog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	General maintenance timer to look for errors or their
		disappearance

CALLED BY:	TimerInterrupt
PASS:		ax	= dgroup
RETURN:		nothing
DESTROYED:	maybe ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:
	for each port:
		if port open:
			if expecting interrupt and counter expired:
				notify other side of any error, defaulting
				to timeout if none indicated by port
			else if waiting for error to clear
				check status
				if error now clear, restart the output
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelWatchdog proc	far
		.enter
		mov	ds, ax
		mov	si, offset lpt1
		mov	cx, ds:numPorts
portLoop:
		tst	ds:[si].PPD_openSem.Sem_value
		jg	nextPort
		INT_OFF
		dec	ds:[si].PPD_counter	; Another second gone
		jg	nextPort		; > 0, so still ok
		jz	timeout			; decremented to 0, so timeout
		inc	ds:[si].PPD_counter	; reset
		js	errorClear?		; still < 0 => encountered error
nextPort:
		INT_ON
		add	si, size ParallelPortData
		loop	portLoop
		.leave
		ret
timeout:
	;
	; The timer for this port has expired without our having gotten an
	; acknowledgement back from the printer. If an obvious error, declare
	; that. Otherwise just declare a timeout error. Note that an interface
	; error means we need to watch for the error clearing to restart the
	; output, while a timeout error must be restarted by the opener of the
	; port.
	; 
		push	cx			; Save port counter
		cmp	ds:[si].PPD_irq, 1	; interrupt driven?
		jbe	errorNext		; no -- let ParallelThread
						;  deal with it. We've already
						;  flagged the timeout by
						;  setting PPD_counter to 0

		call	ParallelCheckError
		jnz	error
		;
		; Timeout. Set that error and leave the counter at 0 so we don't
		; look for a non-existent error's clearing.
		;
		mov	cx, mask PE_TIMEOUT
		jmp	setError
error:
		mov	ds:[si].PPD_counter, -1	; Flag restart needed
		mov	cx, mask ParallelError
		and	cx, ax
setError:
	;
	; Post the error passed in CX. PPD_counter for the stream is already
	; set to the proper value for this error code.
	; 
		mov	al, ds:[si].PPD_ctrl	; Shut off interrupts for the
		andnf	al, not mask PC_IEN	;  port
		mov	ds:[si].PPD_ctrl, al
		mov	dx, ds:[si].PPD_base
		add	dx, offset PP_ctrl
		out	dx, al

		mov	bx, ds:[si].PPD_stream
		mov	ax, STREAM_READ
		mov	di, DR_STREAM_SET_ERROR
		call	StreamStrategy
errorNext:
		pop	cx
		jmp	nextPort

errorClear?:
	;
	; See if a previously-posted error is now clear.
	;
		cmp	ds:[si].PPD_irq, 1	; BIOS or DOS?
		jbe	nextPort		; ja. don't mess wid it

		call	ParallelCheckError
		jnz	nextPort
		INT_ON
		call	ParallelRestart
		jmp	nextPort
ParallelWatchdog endp


;------------------------------------------------------------------------------
;
;		     HANDLING PORT VIA INTERRUPTS
;
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Data notification routine for stream driver to call.

CALLED BY:	Stream driver when data are present in the stream.
PASS:		al	= first byte in buffer
		dx	= stream token (ignored)
		cx	= ParallelPortData
		bp	= STREAM_READ (ignored)
RETURN:		carry set (byte consumed)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelNotify	proc	far	uses ds, es, si, di
		.enter
		LoadVarSeg	ds
		mov	si, cx
		mov	es, ds:[si].PPD_stream
	;
	; Fetch the byte so all counters etc. are properly decremented
	; in case notification or wakeup of the writer takes longer than
	; the acknowledging interrupt coming in. If we don't do this,
	; the interrupt handler will send the byte twice, which isn't
	; good.
	;
	; There appears to be some funky race condition that I can't
	; see going on here. Somehow, though the stream was emptied, so
	; no interrupt should be pending, and the spooler is single-
	; threaded (for a given printer), and the semaphore value
	; wasn't zero the last time this thing blocked when the
	; train left StreamWriteBulkCopy, nonetheless, the thing
	; was empty when it arrived here (perhaps the laserjet is
	; sending bogus ACKs down the line). To deal with this, and
	; avoid being stuck w/no notifier forever, make the get-byte
	; non-blocking and boogie if it says the stream is empty.
	; 
		StreamGetByteNB	es, al
		jc	done

		;
		; Shut off the data notifier for our side of the stream until
		; the stream has drained.
		;
		mov	es:SD_reader.SSD_data.SN_type, SNM_NONE
		
		;
		; Ship the byte out
		;
		call	SysEnterInterrupt
		call	ParallelSendAndNotify
		call	SysExitInterrupt
done:
		clc		; Tell caller not to worry
		.leave
		ret
ParallelNotify	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InterruptHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Macro containing the body of one of our interrupt handlers,
		minus the iret. Saves a couple registers, points another
		at the ParallelPortData for the port and calls the common
		handler.

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
		LoadVarSeg	ds
		call	ds:[interruptCommon]
		.inst word offset portData
		.unreached
		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelPrimaryInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an interrupt on the primary printer interrupt level

CALLED BY:	hardware interrupt 7
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
idata	segment
primaryIntSem	byte	1
idata	ends

ParallelPrimaryInt proc	far
        ;
        ; Check for spurious interrupts. Spurious interrupts can be generated if
        ; an interrupt is triggered on the leading edge of the waveform and the
	; level goes low before the CPU acks. If this is a spurious interrupt,
	; then simply ignore it. (the Intel book refers to these as "default"
	; interrupts, but they sound rather spurious to me...see page 7-132
        ; of the "Component Data Catalog", 1982).
	; 10/18/90: also have to check if we may be servicing a real primary
	; interrupt already. If so, this interrupt is spurious. primaryIntSem
	; is incremented again in ParallelEOI when it detects an EOI of level
	; 7 (SDI_PARALLEL).
        ;
                push    ax
                mov     al, IC_READ_ISR         ;al <- read in-service register
                out     IC1_CMDPORT, al
                jmp     $+2                     ;give time for 8259A to react
                in      al, IC1_CMDPORT         ;see if in service
                test    al, (1 shl 7)           ;hardware interrupt 7
                pop     ax
                jz      ignoreInt

		push	ds
		LoadVarSeg	ds
		dec	ds:[primaryIntSem]	;already servicing a primary?
		js	primaryActive		; yes -- don't service this
						; one. 
		call	ds:[interruptCommon]
		.inst word offset ds:[primaryVec].PVD_port
		.UNREACHED

primaryActive:
if	TEST_PARALLEL
		inc	cs:[primaryActiveCount]
endif
		inc	ds:[primaryIntSem]
		pop	ds
		iret

ignoreInt:
if	TEST_PARALLEL
		inc	cs:[ignoreIntCount]
endif
		iret
ParallelPrimaryInt endp


if	TEST_PARALLEL
ignoreIntCount		sword	0
primaryActiveCount	sword	0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelAlternateInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an interrupt on the alternate printer interrupt level

CALLED BY:	hardware interrupt 5
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
ParallelAlternateInt proc	far
		InterruptHandler	ds:[alternateVec].PVD_port
ParallelAlternateInt endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelWeird1Int
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
ParallelWeird1Int proc	far
		InterruptHandler	ds:[weird1Vec].PVD_port
ParallelWeird1Int endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelWeird2Int
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
ParallelWeird2Int proc	far
		InterruptHandler	ds:[weird2Vec].PVD_port
ParallelWeird2Int endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelEdgeInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for edge-triggered interrupts

CALLED BY:	The above interrupt handlers, via [interruptCommon]
PASS:		ds	= dgroup
		on stack:
			sp ->	return address
				original ds
				iret-frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelEdgeInt	proc	near
		XchgTopStack	si
			on_stack	si ds iret
		mov	si, cs:[si]		; si <- offset in dgroup of
						;  offset to ParallelPortData
		mov	si, ds:[si]		; ds:si <- ParallelPortData
	;
	; There are some ports where shutting the interrupt off seems to
	; provoke an interrupt. God only knows why. Allowing this interrupt
	; through, however, will wreak havoc with our carefully laid plans
	; (mice not involved), so we bail (after acknowledging the interrupt)
	; if the PC_IEN bit isn't set in our copy of the control register.
	; 
		push	dx, ax
			on_stack	ax dx si ds iret
		test	ds:[si].PPD_ctrl, mask PC_IEN
		jz	bail
		call	ParallelInt
done:
		pop	ds, si, dx, ax
		iret

bail:
		call	ParallelEOI
		jmp	done
ParallelEdgeInt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelLevelInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common interrupt code for level-triggered interrupt

CALLED BY:	Above interrupt handlers via ds:[interruptCommon]
PASS:		ds	= dgroup
		on stack:
			sp ->	return address
				original ds
				iret-frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelLevelInt proc	near
		XchgTopStack	si
			on_stack	si ds iret
		mov	si, cs:[si]		; si <- offset in dgroup of
						;  offset to ParallelPortData
		mov	si, ds:[si]		; ds:si <- ParallelPortData
		push	dx, ax
			on_stack	ax dx si ds iret
	;
	; Make sure the interrupt is for this parallel port. This check
	; is only valid on MCA parallel ports, that's why we only check
	; it for level-sensitive systems...(PS_IRQ is undefined for ISA
	; parallel ports)
	; 
		mov	dx, ds:[si].PPD_base
		inc	dx		| CheckHack <offset PP_status eq 1>
		in	al, dx
		test	al, mask PS_IRQ
		jnz	passItOn
		call	ParallelInt
finish:
		pop	ds, si, dx, ax
				on_stack	iret
		iret
passItOn:
	;
	; Interrupt not for this port, so chain to the previous interrupt
	; handler.
	; 
			on_stack	ax dx si ds iret
		mov	si, ds:[si].PPD_vector
		pushf
		call	ds:[si].PVD_old
		jmp	finish
ParallelLevelInt endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelEOI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge an interrupt from a port by sending a
		level-specific end-of-interrupt command to the appropriate
		interrupt controller(s)

CALLED BY:	ParallelInt, ParallelErrorHandler
PASS:		ds:si	= ParallelPortData for the port
RETURN:		nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelEOI	proc	near
		.enter
		pushf
		mov	al, ds:[si].PPD_irq
		cmp	al, SDI_PARALLEL
		jne	doEOI
		INT_OFF				;protect against spurious
						; "default" interrupts.
		inc	ds:[primaryIntSem]
doEOI:
		cmp	al, 8
		mov	al, IC_GENEOI
		jl	notSecond
		;
		; Need to send an acknowledgement to the second controller.
		;
		out	IC2_CMDPORT, al
notSecond:
		out	IC1_CMDPORT, al
		push	cs
		call	safePopf
		.leave
		ret
safePopf:
		iret
ParallelEOI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelErrorHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A non-masked error was detected on the line. Deal with it
		properly.

CALLED BY:	ParallelInt
PASS:		es	= StreamData
		ds:si	= ParallelPortData
		al	= ParallelError (with perhaps a few extra bits set)
		dx	= status port
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
		put the byte back into the stream
		turn off any timer and clear irqPend
		record error flags being sent, then perform notification
		start timer to check for clearing of error

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelErrorHandler	proc	near	uses di
		.enter
		mov	ds:[si].PPD_errCount, ERROR_CONFIRM_COUNT
		xchg	ax, si		; ax <- PPD
		call	ParallelDebounce
	;
	; Acknowledge the interrupt, finally
	;
		call	ParallelEOI
		.leave
		ret
ParallelErrorHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelDebounce
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Timer routine to see if an error condition previously
		noticed has mysteriously vanished during our debounce
		interval.

CALLED BY:	one-shot timer
PASS:		ax	= offset of ParallelPortData
RETURN:		si 	= offset of ParallelPortData
DESTROYED:	ax, bx, cx, dx, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelDebounce proc	far
		.enter
		xchg	si, ax		; si <- port data
		segmov	ds, dgroup, ax

	;
	; If timeout occurred (counter <= 0), error notification has been sent
	; and we should stop this nonsense.
	;
		tst	ds:[si].PPD_counter
		jle	done

	;
	; See if the error condition is still with us.
	;
		call	ParallelCheckError
		jnz	error
	;
	; No. Fetch the character we were working on and send the beast.
	;
		mov	al, ds:[si].PPD_lastSent
		call	ParallelSendByte		
done:
		.leave
		ret
error:
	;
	; Try again in another bit. We continue this until the timeout period
	; expires, b/c some printers are given really long timeouts during
	; which the user may fix the problem before we give notice.
	;
		mov	al, TIMER_ROUTINE_ONE_SHOT
		mov	bx, cs
		mov	dx, si		; pass port data back to us in AX
		mov	si, offset ParallelDebounce
		mov	cx, DEBOUNCE_INTERVAL
		call	TimerStart
		mov	si, dx		; restore port data offset in case
					;  we're called from
					;  ParallelErrorHandler, or...

		; just in case, make sure we own the timer...this would
		; be a helluva a bug to track down...

		mov	ax, handle 0
		call	HandleModifyOwner
		jmp	done

ParallelDebounce endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelSendByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a byte off to a parallel port.

CALLED BY:	ParallelInt, ParallelThread
PASS:		ds:si	= port data
		al	= character
RETURN:		carry set if port has an error (AX is ParallelError, with
		perhaps a few extra bits set)
		carry clear otherwise
		INTERRUPTS ON
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelSendByte proc	near
		.enter
EC <		cmp	ds:[si].PPD_irq, 1				>
EC <		ERROR_BE	PORT_NOT_INTERRUPT_DRIVEN		>
	;
	; Store the data in the latches to provide enough setup time
	;
		mov	dx, ds:[si].PPD_base
		out	dx, al
		
	;
	; Save the byte in the lastSent and reset the timeout counter for
	; the port.
	;
		mov	ds:[si].PPD_lastSent, al
		mov	al, ds:[si].PPD_timeout
		mov	ds:[si].PPD_counter, al
	;
	; Now wait for the printer to become un-busy so we can strobe
	; the byte into its little latches.
	;
CheckHack	<offset PP_status-offset PP_data eq 1>
		inc	dx
		clr	ah	; ensure high byte of ParallelError clear
busyLoop:
		in	al, dx
		;
		; Get the bits in the status register to be set if there's
		; an error. We need to invert PS_SELECT and PS_ERROR to achieve
		; this...
		;
		xornf	al, mask PS_SELECT or mask PS_ERROR
		;
		; Clear out any masked errors.
		;
		andnf	al, ds:[si].PPD_errMask.low
		;
		; Any errors left?
		;
		test	al, mask ParallelError and 0xff
		jnz	error
		;
		; Now see if the printer is still busy
		;
		test	al, mask PS_BUSY
		jnz	portReady		; active-low...
		;
		; came through this cycle w/o an error, so reset the
		; confirmation counter.
		;
		mov	ds:[si].PPD_errCount, ERROR_CONFIRM_COUNT
		;
		; If we've not timed out, keep looping.
		;
		tst	ds:[si].PPD_counter
		jg	busyLoop
error:
		;
		; Error was detected for the port. Abort service if
		; all confirmation passes have been used up, etc.
		;
		dec	ds:[si].PPD_errCount
		jnz	busyLoop
		stc
		jmp	done
portReady:
	;
	; We now need to assert the strobe line for a minimum of 1 microsecond
	; and, theoretically, for no more than 5 microseconds. Trick is, of
	; course, that different processors will execute the same instructions
	; at different speeds. For a base PC (4.77Mhz 8088), the single
	; indirect jump with the mov al, ah takes 11 cycles = 2.3 us. An 8Mhz
	; '286 comes in at 4.5, giving two jumps of 9 cycles each.
	; 18 cycles = 2.25 us.
	;
		inc	dx
		;
		; The Everex Hercules card, at least, has the nasty habit
		; of giving us a control register with IEN and INIT low
		; at random intervals. Rather than be screwed by this, we
		; just set up al to be the proper control register.
		; XXX: the Everex HGC card also has the high three bits set...
		;
		mov	al, ds:[si].PPD_ctrl
		mov	ah, al
		or	al, mask PC_STROBE
		mov	bx, ds:delayFactor
		mov	bx, cs:delayTable[bx]
		INT_OFF			; Avoid pulse-stretch by interrupt
		out	dx, al
		jmp	bx
delayTable	nptr	basePC, 	; PC or lower (?!)
			basePC, 	; PC or a bit faster
			twoJumps, 	; twice as fast
			twoJumps, 	; three times as fast
			twoJumps, 	; four times as fast
			threeJumps,	; five times as fast
			threeJumps,	; six times as fast
			fourJumps,	; seven times as fast
			fourJumps,	; eight times as fast
			fourJumps,	; nine times as fast
			fiveJumps,	; 10
			fiveJumps,	; 11
			fiveJumps,	; 12
			sixJumps,	; 13
			sixJumps,	; 14
			sixJumps	; 15

;sevenJumps:	jmp	sixJumps
sixJumps:	jmp	fiveJumps
fiveJumps: 	jmp	fourJumps
fourJumps: 	jmp	threeJumps
threeJumps: 	jmp	twoJumps
twoJumps: 	jmp	basePC
basePC:
		mov	al, ah
		out	dx, al
		INT_ON
		clc
		mov	al, ds:[si].PPD_timeout	; Reset watchdog timer for port
		mov	ds:[si].PPD_counter, al
done:
		.leave
		ret
ParallelSendByte endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelSendAndNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a byte out a port and notify the writer of the space
		that is available. Deals with setting PPD_counter properly
		in the event of an error or timeout.

CALLED BY:	ParallelNotify, ParallelThread
PASS:		ds:si	= ParallelPortData
		al	= byte to send
RETURN:		carry set on error
DESTROYED:	ax, bx, dx, es, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelSendAndNotify	proc	near	uses cx
		.enter
		call	ParallelSendByte
		jc	error
		mov	es, ds:[si].PPD_stream
		tst	es:[SD_writer.SSD_data.SN_type]
		jz	done
		call	StreamWriteDataNotify
done:
		.leave
		ret
error:
		mov	ds:[si].PPD_errCount, ERROR_CONFIRM_COUNT
		xchg	ax, si		; ax <- PPD
		call	ParallelDebounce
		stc
		jmp	done
ParallelSendAndNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelGetByteNB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a byte from the stream in a non-blocking fashion

CALLED BY:	ParallelInt, ParallelThread
PASS:		es	= stream segment
RETURN:		if carry clear:
			al	= byte fetched
		else if carry set, no byte available
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelGetByteNB proc	near
		.enter
		StreamGetByteNB	es, al
		.leave
		ret
ParallelGetByteNB endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common interrupt handler code.

CALLED BY:	ParallelTimer, ParallelWeird2Int, ParallelWeird1Int,
       		ParallelAlternateInt, ParallelPrimaryInt
PASS:		ds:si	= ParallelPortData of port to service.
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelInt	proc	near	uses bx, cx, es, bp
		.enter
		call	SysEnterInterrupt	;must keep up those stats
		INT_ON
		stc
		mov	cx, ds:[si].PPD_stream
		jcxz	outputComplete
		mov	es, cx
		call	ParallelGetByteNB
		jc	outputComplete

		call	ParallelSendByte
		jc	error
	;
	; Data now in the printer. Send the interrupt acknowledgement for which
	; it yearns.
	;
	;	... but wait!  If we give it the EOI now, we can recurse
	;	infinitely if an interrupt is already pending.  Therefore,
	;	wait (in the no notify case) until just before SysExitInterrupt.
	;	SysExitInterrupt will be kind enough to not turn interrupts on
	;
		;
		; Wasn't empty -- see if writer is interested in notification.
		; Don't waste time doing a far call if not.
		;
		tst	es:[SD_writer.SSD_data.SN_type]
		jz	noNotifyDoEOI		; => SNM_NONE (carry clear)
		;
		; Goober. Preserve registers to be biffed and tell stream driver
		; to notify the other side.
		;
		call	ParallelEOI
		push	di
		call	StreamWriteDataNotify
		pop	di
		jmp	noNotify

noNotifyDoEOI:
		INT_OFF
		call	ParallelEOI
noNotify:
		call	SysExitInterrupt
		.leave
		ret
error:
		call	ParallelErrorHandler
		jmp	noNotify
outputComplete:
	;
	; The buffer is now empty. Want to restore our notifier so we get
	; called again should more data become available.
	;
		mov	es:[SD_reader.SSD_data.SN_type], SNM_ROUTINE
		mov	ds:[si].PPD_counter, 0
	;
	; Acknowledge the interrupt on MCA systems (they're the ones that
	; need an explicit acknowledgement...) by reading the parallel status
	; register.
	;
		mov	dx, ds:[si].PPD_base
		inc	dx	| CheckHack <offset PP_status eq 1>
		in	al, dx
	;
	; If destroyer is lingering waiting for data to be written, we
	; need to wake the thing up if the useCount is 0 (if not, whatever
	; is still in the stream will wake the destroyer up on its way
	; out).
	;
		test	es:[SD_state], mask SS_LINGERING
		jz	noNotifyDoEOI
		tst	es:[SD_useCount]
		jnz	noNotifyDoEOI
		mov	ax, es
		mov	bx, offset SD_closing
		call	ThreadWakeUpQueue
		jmp	noNotifyDoEOI
ParallelInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend output to all interrupt-driven ports.

CALLED BY:	DR_SUSPEND
PASS:		nothing
		ds	= dgroup (from ParallelStrategy)
RETURN:		carry set if refuse to suspend
DESTROYED:	nothing (interrupts on)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelSuspend	proc	near
		uses	ax, dx, bx, cx, si
		.enter
		mov	si, offset printerPorts
		mov	cx, ds:[numPorts]
		INT_OFF
portLoop:
		lodsw
		xchg	bx, ax		; ds:bx <- ParallelPortData
		cmp	ds:[bx].PPD_irq, 1	; interrupt-driven?
		jbe	nextPort
	;
	; Turn off the interrupt-enable bit for the port (XXX: disable interrupt
	; in the mask register?)
	; 
		mov	dx, ds:[bx].PPD_base
				CheckHack <offset PP_ctrl eq 2>
		inc	dx
		inc	dx
		mov	al, ds:[bx].PPD_ctrl
		andnf	al, not mask PC_IEN
		mov	ds:[bx].PPD_ctrl, al
		out	dx, al
	;
	; Make the port appear to have timed out. If the thing had an error
	; before, someone will tell us to restart and will re-recognize the
	; error then...
	; 
		clr	al
		mov	ds:[bx].PPD_counter, al

nextPort:
		loop	portLoop	; If more to go, handle them.

		INT_ON
		clc
		.leave
		ret
ParallelSuspend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resume output to all open ports.

CALLED BY:	DR_UNSUSPEND
PASS:		ds	= dgroup (from ParallelStrategy)
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelUnsuspend proc	near
		uses	bx, cx, si
		.enter
		mov	si, offset printerPorts
		mov	cx, ds:[numPorts]
portLoop:
		lodsw
		xchg	bx, ax		; ds:bx <- ParallelPortData
		cmp	ds:[bx].PPD_irq, 1	; interrupt-driven?
		jbe	nextPort		; no
		tst	ds:[bx].PPD_openSem.Sem_value	; port open?
		jg	nextPort		; no
	;
	; Call our DR_PARALLEL_RESTART function for the thing, telling it
	; to send the next byte in the stream, not to resend the previous one.
	; 
		clr	ax		; no resend of last byte
		call	ParallelPortRestart
nextPort:
		loop	portLoop
		.leave
		ret
ParallelUnsuspend endp



;------------------------------------------------------------------------------
;
;		HANDLING PORT VIA LOW-PRIORITY THREAD
;
;------------------------------------------------------------------------------

PARALLEL_STACK_SIZE	equ	800	; This is even more excessive than
					;  it used to be. This was 128, but
					;  there are times when a port thread
					;  is the last reference to the driver
					;  and the kernel must load in
					;  the Init resource on our stack,
					;  which requires > 256 bytes of
					;  stack space.




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelStartThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start up a thread to handle a port

CALLED BY:	ParallelInitPort
PASS:		ds:si	= ParallelPortData for the port
RETURN:		carry set if thread couldn't be created.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Creates a really low priority thread that loops infinitely
		reading a byte and sending it to the port.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelStartThread proc near	uses ax, bx, cx, dx, di, bp
		.enter
	;
	; Initialize open semaphore for blocking...
	;
		mov	ds:[si].PPD_sem.Sem_value, 0
	;
	; Now create the new thread.
	;
		push	si
		mov	al, PRIORITY_LOW
		mov	bx, si		; Pass port data in cx
		mov	cx, cs		; cx:dx = routine addr for start
		mov	dx, offset ParallelThread
		mov	di, PARALLEL_STACK_SIZE	; di = stack size
		mov	bp, handle 0	; We want to own it
		call	ThreadCreate
		pop	si
	;
	; Wait for the sucker to get started.
	;
		PSem	ds, [si].PPD_sem
		mov	ds:[si].PPD_sem.Sem_value, 1
	;
	; Store away the thread's handle.
	;
		mov	ds:[si].PPD_thread, bx
		.leave
		ret
ParallelStartThread endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Function to manage a port on a separate, low-priority,
		background thread.

CALLED BY:	ThreadCreate
PASS:		cx	= offset of ParallelPortData for the port
		ds,es	= dgroup
RETURN:		Never
DESTROYED:	Everything

PSEUDO CODE/STRATEGY:
		Loop infinitely doing a StreamGetByte and calling
			ParallelSendByte to deliver the byte to the printer.
		When StreamGetByte returns carry set, it means the port is
			being closed so we should go away.
		
		Since we're a low-priority thread, we can busy-wait to our
			heart's content, as we'll only run if nothing else
			of interest is ready, so the CPU is all ours...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PRINT_BUF_SIZE	=	128

idata	segment
lptName		char	"LPT"
lptStuff	char	"0", 0
idata	ends

ParallelThread	proc	far
		mov	si, cx			; ds:si = port
	;
	; Lock down the stream so it won't go away without our knowing...
	;
		mov	es, ds:[si].PPD_stream	; es = stream data
		inc	es:SD_useCount		; So stream driver knows we're
	;
	; Are we using DOS or BIOS ???
	;
		tst	ds:[si].PPD_irq
		jz	useBIOS

		call	ParallelThreadDOS
		jmp	common

useBIOS:
		call	ParallelThreadBIOS

common:

	;
	; Signal thread no longer driving the port.
	;
		clr	ds:[si].PPD_thread
	;
	; The stream wants to close, which means we have no further
	; purpose in life. Wake up the thread that's waiting for our
	; death, then call ThreadDestroy with code 0, telling it
	; not to send the acknowledgement anywhere, as no-one's
	; interested.
	;

		dec	es:SD_useCount
		jnz	noWakeup		; Not only one here -- let Them
						;  handle the wakeup

		mov	bx, offset SD_closing
		mov	ax, es
		call	ThreadWakeUpQueue

noWakeup:
		clr	dx
		mov	bp, dx
		mov	cx, dx
	; avoid ec +segment death in ThreadDestroy when stream is biffed.
EC <		segmov	es, dgroup, ax					>
EC <		mov	ds, ax						>
		jmp	ThreadDestroy
ParallelThread	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelDecInUseCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the in-use count on the stream, and wake up
		a closer, if one is blocked

CALLED BY:	ParallelThread

PASS:		

RETURN:		nothing 

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelDecInUseCount	proc near

		.enter
	;
	; Turn off interrupts so we don't context-switch between
	; decrementing the use count and waking up the closing thread.
	;
		INT_OFF
		dec	es:SD_useCount
		jnz	noWakeup		; Not only one here -- let Them
						;  handle the wakeup
		mov	bx, offset SD_closing
		mov	ax, es
		call	ThreadWakeUpQueue
noWakeup:
		INT_ON

		.leave
		ret
ParallelDecInUseCount	endp

		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelThreadDOSSetRawMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the device into raw mode to avoid translations and
		bogus EOF interpretation.

CALLED BY:	(INTERNAL) ParallelThreadDOS
PASS:		dx	= file handle
RETURN:		carry set on error
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	XXX: This is a gross hack to set the device into raw mode, so it
	won't try to translate returns or do any of the other nonsense the
	DOS driver so likes to do.
	
	We have no generic IOCTL mechanism in the kernel, unfortunately, as
	we have no time to design a good one. So we're going to call the
	primary IFS driver directly for this one, gaining us a DOS file
	handle we can then use to make the call to DOS.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelThreadDOSSetRawMode proc	near
		uses	dx, si, ds, es
		.enter
	;
	; Fetch the geode handle of the primary IFS driver.
	; 
		call	FSDLockInfoShared
		mov	es, ax
		mov	si, es:[FIH_primaryFSD]
		mov	bx, es:[si].FSD_handle
	;
	; Get to its FSDriverInfoStruct and make sure its alternate
	; strategy is something we can talk to.
	; 
		call	GeodeInfoDriver		; ds:si <- FSDriverInfoStruct
		cmp	ds:[si].FSDIS_altProto.PN_major,
			DOS_PRIMARY_FS_PROTO_MAJOR
		jne	badProto
		cmp	ds:[si].FSDIS_altProto.PN_minor,
			DOS_PRIMARY_FS_PROTO_MINOR
		jb	badProto
	;
	; Fetch the SFN for the file handle and ask the driver to allocate
	; us a DOS file handle.
	; 
		mov	es, es:[FIH_dgroup]
		mov	bx, dx
		mov	bl, es:[bx].HF_sfn
		mov	di, DR_DPFS_ALLOC_DOS_HANDLE
		call	ds:[si].FSDIS_altStrat
	;
	; Now tell DOS to put the device into raw mode.
	; 
		mov	ax, MSDOS_IOCTL_SET_DEV_INFO
		mov	dx, mask DOS_IOCTL_RAW_MODE
		call	FileInt21
EC <		ERROR_C	DOS_WRITE_RETURNED_ERROR			>
	;
	; Release the DOS handle again.
	; 
   		mov	di, DR_DPFS_FREE_DOS_HANDLE
		call	ds:[si].FSDIS_altStrat
		clc
done:
		call	FSDUnlockInfoShared
		.leave
		ret
badProto:
	;
	; Couldn't set the device into raw mode, so we can't support the thing.
	; 
		stc
		jmp	done
ParallelThreadDOSSetRawMode endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelThreadDOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print to a port through DOS, using FileOpen/Write/Close

CALLED BY:	(INTERNAL) ParallelThread
PASS:		ds:si	= ParallelPortData
		es	= StreamData
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelThreadDOS proc	near
		.enter
	;
	;	=== PRINTING VIA DOS ===
	; Now let the driver continue its work since we're properly
	; established.
	;
		VSem	ds, [si].PPD_sem
	;
	; Open the file LPTn.
	;
		mov	ax, ds:[si].PPD_biosNum	; ax <- port number
		add	al, '1'
		mov	ds:[lptStuff], al
		mov	dx, offset lptName
		mov	al, FileAccessFlags <FE_EXCLUSIVE, FA_READ_WRITE>
		call	FileOpen
		jc	postError
	;
	; Set the file into raw mode.
	; 
		mov_tr	dx, ax		; dx <- file handle
		call	ParallelThreadDOSSetRawMode
		jc	closeAndPostError
	;
	; Allocate room on the stack for a buffer for transfer from the stream
	; to the device.
	; 
		push	ds, si
		mov	bx, es			;bx = stream
		sub	sp, PRINT_BUF_SIZE
		mov	si, sp
		segmov	ds, ss			;ds:si = buffer

EC <		call	ECCheckStack		>

loopUntilEternity:

		mov	ax, STREAM_BLOCK
		mov	cx, PRINT_BUF_SIZE
		mov	di, DR_STREAM_READ
		call	StreamStrategy
		jc	streamError		; => either closing or
						;  short read
processWhatWeGot:
		jcxz	done

		push	bx, dx			;save stream and file handle
		mov	bx, dx			;bx = file handle
		mov	dx, si			;ds:dx = buffer
		clr	ax			;allow errors
		call	FileWrite

		pop	bx, dx
		jnc	loopUntilEternity

		; error writing stuff. assume aborted critical error.
		; generate error and bail (errors here are not restartable)

		add	sp, PRINT_BUF_SIZE
		pop	ds, si			; ds:si <- ParallelPortData
		jmp	closeAndPostError

done:
		add	sp, PRINT_BUF_SIZE
		pop	ds, si
		mov	bx, dx
		clr	ax			;ignore errors
		call	FileClose
exit:
		.leave
		ret

streamError:
		cmp	ax, STREAM_SHORT_READ_WRITE
		je	processWhatWeGot
		jmp	done

closeAndPostError:
		mov	bx, dx
		clr	al
		call	FileClose
postError:
	;
	; Post an error to the other side. XXX: MAKE IT MORE SPECIFIC SO
	; SPOOLER KNOWS NOT TO RETRY. Actually, this would be taken care of
	; by new stream close mechanism, as spooler would know there's no one
	; listening.
	; 
		mov	cx, mask PE_TIMEOUT or mask PE_FATAL
		mov	ds:[si].PPD_counter, 0
		mov	bx, es
		mov	ax, STREAM_READ
		mov	di, DR_STREAM_SET_ERROR
		call	StreamStrategy
		jmp	exit
ParallelThreadDOS endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelThreadBIOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print to a port through BIOS, using int 17h

CALLED BY:	(INTERNAL) ParallelThread
PASS:		ds:si	= ParallelPortData
		es	= StreamData
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelThreadBIOS proc	near
		.enter
	;
	;	=== PRINTING VIA BIOS ===
	;
		PSem	es, SD_reader.SSD_lock	;  here and may be blocked.
	;
	; Now let the driver continue its work since we're properly
	; established.
	;
		VSem	ds, [si].PPD_sem

		clr	cx			; init ch to 0
loopUntilEternity:
		push	bx
		call	ParallelGetByteNB	; Fetch next data byte
		pop	bx
		jnc	sendByte
	;
	; If someone's waiting for output to drain, leave now, as the
	; output be all gone.
	;
		test 	es:[SD_state], mask SS_LINGERING or mask SS_NUKING
		jnz	done
		mov	ds:[si].PPD_counter, 0	; Don't timeout please
		push	bx
		StreamGetByte	es, al
		pop	bx
		jc	done
sendByte:
		mov	ds:[si].PPD_lastSent, al	; save for restart
		mov	ah, ds:[si].PPD_timeout
		mov	ds:[si].PPD_counter, ah
		mov	dx, ds:[si].PPD_biosNum	; dx <- port number
sendByteLoop:
		call	PBP
		clr	ah	; ah=0 => print character
		int	17h
		call	VBP
		
		test	ah, 1		; not printed?
		jnz	error		; correct -- go deal with it
		; deal with notification of the other side.
		call	StreamWriteDataNotify
toLoopUntilEternity:
		jmp	loopUntilEternity

done:
		.leave
		ret
error:
		tst	ds:[si].PPD_counter	; our own timeout happened?
		jg	sendByteLoop		; nope. try again.
	;
	; In an ideal world, ParallelWatchdog would have handled the reporting
	; of the error. Semaphores being non-reentrant, however (and a good
	; thing, too), we have to send the error out ourselves.
	; 
		mov	cx, mask PE_TIMEOUT	; assume just time-out

		xornf	ah, mask PS_SELECT	; invert so set if off-line
		andnf	ah, ParallelError and 0xff
		jz	shipIt
		mov	cl, ah			; cx <- ParallelError record
						;  (all other bits [magically]
						;  correspond to the I/O port
						;  bits that make up the PE
						;  record...)
		clr	ch			; not timeout or fatal
shipIt:
	;
	; CX is now the proper ParallelError record; ES is the output stream.
	; Post the error to the writing side of the stream (as the reader).
	; 
		mov	bx, es
		mov	ax, STREAM_READ
		mov	di, DR_STREAM_SET_ERROR
		push	cx			; preserve this thing so
						;  we know whether to check
						;  the counter or not.
		call	StreamStrategy
		pop	cx
	;
	; Wait for the error to clear. When the output restarts, the
	; counter will be set to the timeout value and thus be > 0. Note
	; that we have to check for the stream being nuked as well as
	; for the error to clear as we're registered as using the
	; stream.
	;
waitForErrorToClear:
		test	es:[SD_state], mask SS_NUKING
		jnz	done
		call	ParallelCheckError
		jnz	waitForErrorToClear
	;
	; If the original error was a timeout error, we need to wait for
	; someone to restart the port (at which point PPD_counter will be
	; non-zero). In the event of some other sort of error, we're supposed
	; to restart once the error condition has cleared.
	; 
		test	cx, mask PE_TIMEOUT
		jz	errorAllGone

		tst	ds:[si].PPD_counter	; port restarted?
		jz	waitForErrorToClear
errorAllGone:
	;
	; Error/timeout cleared. See if we should resend the byte.
	; 
		mov	al, ds:[si].PPD_ctrl
		andnf	ds:[si].PPD_ctrl, not mask PC_IEN
		test	al, mask PC_IEN		; resend byte?
		jz	toLoopUntilEternity	; no
		mov	al, ds:[si].PPD_lastSent
		jmp	sendByte
ParallelThreadBIOS endp
Resident	ends
