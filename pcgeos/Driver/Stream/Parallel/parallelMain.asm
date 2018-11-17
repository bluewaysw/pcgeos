COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Stream Drivers -- Output-only Parallel port
FILE:		parallelMain.asm

AUTHOR:		Adam de Boor, Jan 12, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/12/90		Initial revision


DESCRIPTION:
	Code to communicate with multiple parallel ports.
		
	Some notes of interest:

	There can be up to four parallel ports on some machines, but
	there are only two interrupt levels allocated to the things,
	so for some we have to set up a low-priority thread that just
	waits for the port to become ready and spews data at it. If no
	data are available, the thread just blocks on the stream's
	reader semaphore until data are there.

	Because parallel ports will only interrupt when the printer's ACK
	signal changes from active to inactive, and we've no control over
	what the printer will send us, we cannot determine at what interrupt
	level a port is operating. To get around this, we allow the user
	to specify the level in the .ini file in the [parallel] category:

		port1	= <num>	gives the interrupt level for LPT1
		port2	= <num>	gives the interrupt level for LPT2
		port3	= <num>	gives the interrupt level for LPT3
		port4	= <num>	gives the interrupt level for LPT4

	The ports are checked in order (their addresses and numbers are
	assigned by BIOS and we take our information from there). If no
	level is specified for a port, it is given level 7 (primary parallel
	interrupt) unless that level has already been assigned, in which case
	level 5 (alternate parallel interrupt) is assigned, unless that level
	has been assigned, in which case no interrupt is assumed (see above).

	When a port is opened, its interrupt vector will be snagged by the
	driver, and its SLCT IN line asserted (in case the printer wants it).

	$Id: parallelMain.asm,v 1.1 97/04/18 11:46:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	parallel.def
UseDriver Internal/powerDr.def

;------------------------------------------------------------------------------
;		       MISCELLANEOUS VARIABLES
;------------------------------------------------------------------------------
udata		segment
machine		SysMachineType		; Needed to determine if alternate
					;  interrupt available
udata		ends

idata		segment

; table of ports, indexed by ParallelPortNum (must come first to avoid giving
; offset 0 to lpt1)

printerPorts	nptr	lpt1, lpt2, lpt3, lpt4

lpt1		ParallelPortData
lpt2		ParallelPortData
lpt3		ParallelPortData
lpt4		ParallelPortData


primaryVec	ParallelVectorData<,,ParallelPrimaryInt>; Primary interrupt
alternateVec	ParallelVectorData<,,ParallelAlternateInt>; Alternate interrupt
weird1Vec	ParallelVectorData<,,ParallelWeird1Int>	; Data for first weird
							;  port interrupting at
							;  non-standard level
weird2Vec	ParallelVectorData<,,ParallelWeird2Int>	; Data for second weird
							;  port interrupting at
							;  non-standard level


;
; Vector through which interrupt handlers call, based on the way interrupts
; are triggered in this system -- edge or level.
; 
interruptCommon word	offset ParallelEdgeInt

idata		ends

udata		segment
;
; Map to return on call to DR_STREAM_GET_DEVICE_MAP
;
deviceMap	ParallelDeviceMap	<0,0,0,0>
udata		ends

;------------------------------------------------------------------------------
;	Driver info table
;------------------------------------------------------------------------------

idata		segment

DriverTable	DriverInfoStruct	<
	ParallelStrategy, mask DA_CHARACTER, DRIVER_TYPE_STREAM
>
	ForceRef	DriverTable

numPorts	word	0		; No known ports... will be changed by
					;  ParallelRealInit

idata		ends

Resident	segment	resource
DefFunction	macro	funcCode, routine
if ($-parallelFunctions) ne funcCode
	ErrMessage <routine not in proper slot for funcCode>
endif
		nptr	routine
		endm

parallelFunctions	label	nptr
DefFunction	DR_INIT,			ParallelInit
DefFunction	DR_EXIT,			ParallelExit
DefFunction	DR_SUSPEND,			ParallelSuspend
DefFunction	DR_UNSUSPEND,			ParallelUnsuspend
DefFunction	DR_STREAM_GET_DEVICE_MAP,	ParallelGetDeviceMap
DefFunction	DR_STREAM_OPEN,			ParallelOpen
DefFunction	DR_STREAM_CLOSE,		ParallelClose
DefFunction	DR_STREAM_SET_NOTIFY,		ParallelSetNotify
DefFunction	DR_STREAM_GET_ERROR,		ParallelHandOffAsWriter
DefFunction	DR_STREAM_SET_ERROR,		ParallelHandOffAsWriter
DefFunction	DR_STREAM_FLUSH,		ParallelHandOffAsWriter
DefFunction	DR_STREAM_SET_THRESHOLD,	ParallelHandOffAsWriter
DefFunction	DR_STREAM_READ,			ParallelRead
DefFunction	DR_STREAM_READ_BYTE,		ParallelReadByte
DefFunction	DR_STREAM_WRITE,		ParallelWrite
DefFunction	DR_STREAM_WRITE_BYTE,		ParallelWriteByte
DefFunction	DR_STREAM_QUERY,		ParallelHandOffAsWriter

DefFunction	DR_PARALLEL_MASK_ERROR,		ParallelMaskError
DefFunction	DR_PARALLEL_QUERY,		ParallelPortQuery
DefFunction	DR_PARALLEL_TIMEOUT,		ParallelTimeout
DefFunction	DR_PARALLEL_RESTART,		ParallelPortRestart

DefFunction	DR_PARALLEL_VERIFY,		ParallelVerify
DefFunction	DR_PARALLEL_SET_INTERRUPT,	ParallelSetInterrupt

DefFunction	DR_PARALLEL_STAT_PORT,		ParallelStatPort

CheckHack <($-parallelFunctions) eq ParallelFunction>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all parallel-driver functions

CALLED BY:	GLOBAL
PASS:		di	= routine number
		bx	= open port number (usually)
RETURN:		depends on function, but an ever-present possibility is
		carry set with AX = STREAM_CLOSING or STREAM_CLOSED
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
parallelData	sptr	dgroup
ParallelStrategy proc	far	uses es, ds, bx
		.enter
EC <		cmp	di, ParallelFunction				>
EC <		ERROR_AE	INVALID_FUNCTION			>
EC <		cmp	di, first StreamFunction			>
EC <		jb	ecDone						>
EC <		cmp	di, DR_STREAM_GET_DEVICE_MAP			>
EC <		je	ecDone						>
EC <		test	bx, 1						>
EC <		ERROR_NZ	PORT_EXISTETH_NOT			>
EC <		cmp	bx, ParallelPortNum				>
EC <		ERROR_AE	PORT_EXISTETH_NOT			>
EC <ecDone:								>
		segmov	es, ds		; In case segment passed in DS
		mov	ds, cs:parallelData
	;
	; Handle functions that don't take an open stream as an arg.
	; 
   		cmp	di, DR_STREAM_OPEN
		jbe	callFunction
		cmp	di, DR_PARALLEL_SET_INTERRUPT
		je	callFunction
		cmp	di, DR_PARALLEL_STAT_PORT
		je	callFunction
	;
	; Point at port data if already open -- most things will need it.
	;
		mov	bx, ds:printerPorts[bx]
		test	ds:[bx].PPD_portStatus, mask PPS_OPEN
		jz	closed

		
callFunction:
		call	cs:parallelFunctions[di]

exit:
		.leave
		ret
		
closed:
	;
	; Port is closed.  return with carry set and an error enum
	;
		mov	ax, STREAM_CLOSED		; signal error type
		stc
		jmp	exit
		
ParallelStrategy endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front-end for DR_INIT function. Just calls to ParallelRealInit,
		which is movable.

CALLED BY:	DR_INIT (ParallelStrategy)
PASS:		ds	= dgroup
RETURN:		Carry clear if we're happy
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelInit	proc	near
		.enter
		CallMod	ParallelRealInit
		.leave
		ret
ParallelInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle driver exit.

CALLED BY:	DR_EXIT (ParallelStrategy)
PASS:		Nothing
RETURN:		Carry clear if we're happy, which we generally are...
DESTROYED:	

PSEUDO CODE/STRATEGY:
		Go to ParallelRealExit to do the real work

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelExit	proc	near
		.enter
		CallMod	ParallelRealExit
		clc
		.leave
		ret
ParallelExit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelFindVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the interrupt vector for a port.

CALLED BY:	ParallelInitPort, ParallelClose
PASS:		ds:si	= ParallelPortData for the port
RETURN:		cx	= device interrupt level
		ds:di	= ParallelVectorData to use
		carry set if no interrupt vector allocated to the port
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelFindVector proc	near
		.enter
		clr	cx
		mov	cl, ds:[si].PPD_irq	; cx <- interrupt level
		cmp	cl, 1
		jbe 	noInts			; 0/1 means can't interrupt
	;
	; Check known interrupt levels first
	;
		mov	di, offset primaryVec
		cmp	cl, SDI_PARALLEL	; Primary vector?
		je	haveVec
		mov	di, offset alternateVec
		cmp	cl, SDI_PARALLEL_ALT	; Alternate vector?
		je	haveVec
	;
	; Not a known level, so see if one of the weird interrupt
	; vector slots is available for use.
	;
		mov	di, offset weird1Vec
		tst	ds:[di].PVD_port		; Weird1 taken?
		je	haveVec
		mov	di, offset weird2Vec
		tst	ds:[di].PVD_port		; Weird2 taken?
		jz	haveVec			
noInts:
		stc				; Signal no vector available
haveVec:
		.leave
		ret
ParallelFindVector endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelInitPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize things for a newly opened port

CALLED BY:	ParallelOpen
PASS:		bx	= port number (ParallelPortNum)
		ds:si	= ParallelPortData for the port
		dx	= buffer size
RETURN:		carry set if port couldn't be initialized (ax = reason)
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
		Create a stream for the port
		Set up routine notifier for ourselves
		Set notification threshold to 1
		Grab interrupt vector and enable interrupts for port's
			interrupt level.
		Force the printer on-line and turn off auto-feed, since we
			do mostly graphics printing around here.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelInitPort proc	near	uses bx
		.enter
		call	GeodeGetProcessHandle	; Stream owned by opener
		mov	ax, dx			; ax <- buffer size
		mov	cx, mask HF_FIXED
		mov	di, DR_STREAM_CREATE
		call	StreamStrategy
		LONG jc	exit
		mov	ds:[si].PPD_stream, bx
		;
		; Notify the power management driver
		;
		push	cx
		mov	cx, 1			; indicate open
		call	NotifyPowerDriver
		pop	cx
		mov	ax, STREAM_POWER_ERROR
		LONG jc	openFailed
		;
		; Deal with port interrupts.
		;
		call	ParallelFindVector
		jc	noInts
		push	di, cx			; save vector, level
		;
		; Set up a routine notifier to call us when we stick data in
		; the stream. This may seem strange, after all we're the one who
		; caused the data to go there, but it seems somehow cleaner to
		; me to do it this way...
		;
		mov	ax, StreamNotifyType <1,SNE_DATA,SNM_ROUTINE>
		mov	bp, si			; Pass ParallelPortData offset to us
		mov	dx, offset ParallelNotify
		mov	cx, cs
		mov	di, DR_STREAM_SET_NOTIFY
		call	StreamStrategy
		;
		; We need to know if even one byte goes in...
		;
		mov	ax, STREAM_READ
		mov	cx, 1
		mov	di, DR_STREAM_SET_THRESHOLD
		call	StreamStrategy
		;
		; Intercept the device's interrupt vector. 
		;
		pop	di, cx
		segmov	es, ds, bx
		mov	ax, cx
		mov	bx, cs
		mov	cx, ds:[di].PVD_handler
		mov	ds:[di].PVD_port, si	; Record port using the vector
						;  before di biffed.
		mov	ds:[si].PPD_vector, di	; Similarly....
		call	SysCatchDeviceInterrupt
		
		mov	cl, ds:[si].PPD_irq
		mov	dx, IC1_MASKPORT	; Assume controller 1
		cmp	cl, 8			; Second controller?
		jb	controller1		; No
		sub	cl, 8			; Yes -- adjust to level for
		mov	dx, IC2_MASKPORT	;  second and set dx to second's
						;  mask register. XXX: Assumes
						;  second controller not masked
						;  out. Ok?
controller1:
		in	al, dx			; Fetch current mask
		mov	ah, not 1		; Form mask to clear
		rol	ah, cl			;  out bit based on level
		and 	al, ah			; Clear it
		out	dx, al			; Store new mask

	;
	; Now enable interrupts for the port
	;
		mov	dx, ds:[si].PPD_base
		add	dx, offset PP_ctrl
		in	al, dx
		ornf	al, mask PC_IEN
		jmp	10$
noInts:
	;
	; Code for non-interrupting port -- need to start a thread and
	; load in the control register for the port, but don't set PC_IEN.
	;
		call	ParallelStartThread
		jnc	threadOk

		mov	bx, ds:[si].PPD_stream	; Biff the stream, since we
		mov	ax, STREAM_DISCARD	;  we can't create the driver
		mov	di, DR_STREAM_DESTROY	;  thread
		call	StreamStrategy
		mov	ax, STREAM_CANNOT_ALLOC	; Return proper error
		stc				;  and carry set
		jmp	openFailed

threadOk:
		mov	dx, ds:[si].PPD_base
		add	dx, offset PP_ctrl
		in	al, dx
		andnf	al, not mask PC_IEN	; make sure it's off
		jmp	10$			; I/O delay
10$:
	;
	; Force the printer on-line, if it supports such things.
	;
		ornf	al, mask PC_SLCTIN or mask PC_INIT
		andnf	al, not (mask PC_AUTOFEED or mask PC_STROBE)
						; Turn off auto-newline and deal
						;  with weird ports where
						;  PC_STROBE is asserted when
						;  the printer is off.
		out	dx, al
		mov	ds:[si].PPD_ctrl, al	; Save as standard control
						;  value
		mov	ds:[si].PPD_counter, 0	; No interrupts pending
						;  from this port yet.
		clc				; We're happy
exit:
		.leave
		ret
openFailed:
		clr	cx			;Tell the power driver to
						; close the port
		call	NotifyPowerDriver
		stc
		jmp	exit
ParallelInitPort endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NotifyPowerDriver

DESCRIPTION:	Notify the power management driver that a serial port
		has opened or closed

CALLED BY:	INTERNAL

PASS:
	cx	= non-zero for open, zero for close
	ds:si	= ParallelPortData for the port

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/16/92		Initial version

------------------------------------------------------------------------------@
NotifyPowerDriver	proc	near	uses ax, bx, si, di, ds
	.enter

	clr	bx
findLoop:
	cmp	si, ds:printerPorts[bx]
	jz	gotPort
	add	bx, 2
	jmp	findLoop

gotPort:
	shr	bx			; bx = number

	mov	ax, GDDT_POWER_MANAGEMENT
	call	GeodeGetDefaultDriver
	tst	ax
	jz	done
	xchg	ax, bx			; ax = port number, bx = driver
	call	GeodeInfoDriver
	mov_tr	bx, ax
	mov	ax, PDT_PARALLEL_PORT
	mov	di, DR_POWER_DEVICE_ON_OFF
	call	ds:[si].DIS_strategy

done:
	.leave
	ret

NotifyPowerDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open one of the parallel ports

CALLED BY:	DR_STREAM_OPEN (ParallelStrategy)
PASS:		ax	= StreamOpenFlags record. SOF_NOBLOCK and SOF_TIMEOUT
			  are exclusive.
		bx	= port number to open
		dx	= total size of output buffer
		bp	= timeout value if SOF_TIMEOUT given in ax
		ds	= dgroup
RETURN:		carry set if port couldn't be opened (port busy/timed
		out/doesn't exist)
			ax = STREAM_NO_DEVICE if requested port doesn't exist
			     STREAM_DEVICE_IN_USE if SOF_NOBLOCK or SOF_TIMEOUT
			         passed and device is in use/timeout period
				 expired.
		bx	= port number opened, if carry clear
DESTROYED:	ax, dx, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelOpen	proc	near	uses si, cx
		.enter
EC <		test	ax, not StreamOpenFlags				>
EC <		ERROR_NZ	OPEN_BAD_FLAGS				>
EC <		test	ax, mask SOF_NOBLOCK or mask SOF_TIMEOUT	>
EC <		jz	10$	; neither is ok				>
EC <		jpo	10$	; just one is fine			>
EC <		ERROR		OPEN_BAD_FLAGS				>
EC <10$:								>
		mov	si, ds:printerPorts[bx]	; Point to port data
		tst	ds:[si].PPD_base
		jz	portExistethNot

		test	ax, mask SOF_NOBLOCK or mask SOF_TIMEOUT
		jnz	noBlockOpenPort
		
		PSem	ds, [si].PPD_openSem	; Wait for port to be available
afterPortOpen:
		call	ParallelInitPort
		jc	initFailed

		ornf	ds:[si].PPD_portStatus, mask PPS_OPEN

done:
		.leave
		ret
portExistethNot:
		mov	ax, STREAM_NO_DEVICE
		stc
		jmp	done

noBlockOpenPort:
		;
		; Perform a non-blocking PSem on the openSem for a port. We
		; also come here if just have a timeout option -- in the case
		; of a non-blocking one, we just have a timeout value of 0...
		;
		test	ax, mask SOF_TIMEOUT
		jnz	20$
		clr	bp
20$:
		PTimedSem	ds, [si].PPD_openSem, bp
		jnc	afterPortOpen
		mov	ax, STREAM_DEVICE_IN_USE
		jmp	done

initFailed:
	;
	; Initialization of the port failed for some reason, but we don't
	; want to mark the thing as open when it isn't, so V the semaphore
	; before leaving.
	;
		VSem	ds, [si].PPD_openSem
		jmp	done
ParallelOpen	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close an open parallel port.

CALLED BY:	DR_STREAM_CLOSE (ParallelStrategy)
PASS:		ds:bx	= ParallelPortData for the port
		ax	= STREAM_LINGER if should wait for pending data
			  to be read before closing. STREAM_DISCARD if
			  can just throw it away.
RETURN:		
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelClose	proc	near	uses si, di, cx, dx

		.enter
		
		andnf	ds:[bx].PPD_portStatus, not mask PPS_OPEN
		
	;
	; If discarding, we have to turn off interrupts from the port
	; *before* calling the stream driver to biff the stream, else
	; an interrupt could come in and use a bogus segment...
	;
		INT_OFF
		cmp	ds:[bx].PPD_irq, 1
		jbe	lingering	; not using interrupts, bozo...

		tst	ax
		jnz	lingering
		mov	dx, ds:[bx].PPD_base
		add	dx, offset PP_ctrl
		in	al, dx
		jmp	$+2		; I/O delay
		andnf	al, not mask PC_IEN
		out	dx, al
		clr	al		; AX <- STREAM_DISCARD
lingering:
		INT_ON
		push	bx
		mov	bx, ds:[bx].PPD_stream
		mov	di, DR_STREAM_DESTROY
		call	StreamStrategy
		pop	si
		jc	done		; if port being closed by another
					;  party, let it handle the clean-up
EC <		mov	ds:[si].PPD_stream, -1				>

	;
	; Unhook ourselves from the interrupt vector
	;
		mov	di, ds:[si].PPD_vector
		tst	di
		jz	noInts
	;
	; Disable the interrupt in the interrupt controller
	;
		clr	cx
		mov	cl, ds:[si].PPD_irq
		mov	dx, IC1_MASKPORT
		mov	ax, cx
		cmp	cx, 8
		jb	10$
		mov	dx, IC2_MASKPORT
		sub	cx, 8
10$:
		mov	ch, 1		; Create bit mask for the level
		rol 	ch, cl
		mov	cl, al		; Preserve al
		in	al, dx		; Fetch current mask
		ornf	al, ch		; Mask out interrupt
		jmp	$+2		; I/O delay
		out	dx, al		; Write new mask
		mov	al, cl		; Recover al (low byte of interrupt #)
	;
	; Put back the old vector contents.
	;
		segmov	es, ds, cx
		call	SysResetDeviceInterrupt
		mov	ds:[di].PVD_port, 0	; Signal vector free
		mov	ds:[si].PPD_vector, 0
noInts:
	;
	; Turn off interrupts and switch printer off-line.
	;
		mov	dx, ds:[si].PPD_base
		add	dx, offset PP_ctrl
		in	al, dx
		andnf	al, not (mask PC_IEN or mask PC_SLCTIN)
		jmp	$+2
		out	dx, al
		
		mov	ds:[si].PPD_timeout, DEFAULT_TIMEOUT
		mov	ds:[si].PPD_errMask, -1
		mov	ds:[si].PPD_counter, 0
	;
	; Tell the power management driver that we are done with
	; the port
	;
		push	cx
		clr	cx
		call	NotifyPowerDriver
		pop	cx
	;
	; Wake up anyone waiting to open this port.
	;
		VSem	ds, [si].PPD_openSem

done:
		.leave
		ret
ParallelClose	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelSetNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a notifier for the caller. Caller may only set the
		notifier for the writing side of the stream.

CALLED BY:	DR_STREAM_SET_NOTIFY
PASS:		ax	= StreamNotifyType
		bx	= unit number (transformed to ParallelPortData offset by
			  ParallelStrategy).
		cx:dx	= address of handling routine, if SNM_ROUTINE;
			  destination of output if SNM_MESSAGE
		bp	= AX to pass if SNM_ROUTINE (except for SNE_DATA with
			  threshold of 1, in which case value is passed in CX);
			  method to send if SNM_MESSAGE.
RETURN:		nothing
DESTROYED:	bx (saved by ParallelStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelSetNotify proc	near
		.enter
		;
		; Make sure notifier set for the writing side...that's the
		; caller's domain.
		;
		andnf	ax, not mask SNT_READER
		mov	bx, ds:[bx].PPD_stream
		call	StreamStrategy
		.leave
		ret
ParallelSetNotify endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelHandOffAsWriter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass a call on to the stream driver as the writer of the
		stream.

CALLED BY:	DR_STREAM_GET_ERROR, DR_STREAM_SET_ERROR, DR_STREAM_FLUSH,
       		DR_STREAM_SET_THRESHOLD, DR_STREAM_QUERY
PASS:		bx	= unit number (transformed to ParallelPortData by 
			  ParallelStrategy)
		di	= function code
RETURN:		?
DESTROYED:	bx (saved by ParallelStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelHandOffAsWriter proc	near
		.enter
		mov	ax, STREAM_WRITE
		mov	bx, ds:[bx].PPD_stream
		call	StreamStrategy
		.leave
		ret
ParallelHandOffAsWriter endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read data from a port (ILLEGAL)

CALLED BY:	DR_STREAM_READ
PASS:		bx	= unit number (transformed to ParallelPortData by 
			  ParallelStrategy)
		ax	= STREAM_BLOCK/STREAM_NO_BLOCK
		cx	= number of bytes to read
		ds:si	= buffer to which to read
RETURN:		cx	= number of bytes read
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelRead	proc	near
EC <		ERROR	CANNOT_READ_FROM_PARALLEL_PORT			>
NEC <		stc							>
NEC <		clr	cx						>
NEC <		ret							>
ParallelRead	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelReadByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a single byte from a port (ILLEGAL)

CALLED BY:	DR_STREAM_READ_BYTE
PASS:		ax	= STREAM_BLOCK/STREAM_NO_BLOCK
		bx	= unit number (transformed to ParallelPortData by 
			  ParallelStrategy)
RETURN:		al	= byte read
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelReadByte proc	near
EC <		ERROR	CANNOT_READ_FROM_PARALLEL_PORT			>
NEC <		stc							>
NEC <		ret							>
ParallelReadByte endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelWriteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to prevent closing during writes.
		Increment the in-use count of the stream so that it
		doesn't go away in the middle of things.

CALLED BY:	ParallelWrite, ParallelWriteByte

PASS:		ds:bx - ParallelPortData

RETURN:		if carry set
			write will be aborted
		else
			bx - segment of StreamData 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelWriteCommon	proc near
		uses	ds
		.enter

	;
	; Turn off interrupts, as we don't want to context switch
	; after checking the PPS_OPEN flag, as the stream might go away,
	; and we'd be left with a bad DS
	;
		INT_OFF

		test	ds:[bx].PPD_portStatus, mask PPS_OPEN
		jz	error
		
		mov	ds, ds:[bx].PPD_stream
		inc	ds:[SD_useCount]	; clears the carry
done:
		INT_ON

	;
	; Return stream segment in BX for caller (returns garbage if
	; carry set)
	;
		
		mov	bx, ds	

		.leave
		ret

error:
		stc
		jmp	done

ParallelWriteCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelEndWriteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal that we're done with the stream, and wake up a
		blocking closer, if necessary.

CALLED BY:	ParallelWrite, ParallelWriteByte

PASS:		CARRY FLAG:  If set:
			write should be aborted
		else
			bx - stream segment

RETURN:		nothing 

DESTROYED:	es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelEndWriteCommon	proc near

		jc	exit

		push	bx
		call	StreamStrategy
		pop	es

	;
	; Turn off interrupts.  It's possible that if we context-switch
	; after the decrement, another thread might come in and
	; destroy the stream, leaving a bad ES
	;
		
		INT_OFF

		dec	es:[SD_useCount]
		jz	wakeUp

done:
		INT_ON
exit:
		ret

wakeUp:
		test	es:[SD_state], mask SS_NUKING
		jz	done
		
		mov	bx, offset SD_closing
		mov	ax, es
		call	ThreadWakeUpQueue
		jmp	done
ParallelEndWriteCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a buffer to the parallel port.

CALLED BY:	DR_STREAM_WRITE
PASS:		ax	= STREAM_BLOCK/STREAM_NO_BLOCK
		bx	= unit number (transformed to ParallelPortData by 
			  ParallelStrategy)
		cx	= number of bytes to write
		ds:si	= buffer from which to write (ds moved to es by
			  ParallelStrategy)
		di	= DR_STREAM_WRITE
RETURN:		cx	= number of bytes written
DESTROYED:	bx (preserved by ParallelStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelWrite	proc	near
		.enter

		call	ParallelWriteCommon

		segmov	ds, es		; ds <- buffer segment for
					;  stream driver

		call	ParallelEndWriteCommon
		
		.leave
		ret
ParallelWrite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelWriteByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a byte to the parallel port.

CALLED BY:	DR_STREAM_WRITE_BYTE
PASS:		ax	= STREAM_BLOCK/STREAM_NO_BLOCK
		bx	= unit number (transformed to ParallelPortData by 
			  ParallelStrategy)
		cl	= byte to write
		di	= DR_STREAM_WRITE_BYTE
RETURN:		carry set if byte could not be written and STREAM_NO_BLOCK
		was specified
DESTROYED:	bx (preserved by ParallelStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelWriteByte proc	near
		.enter

		call	ParallelWriteCommon
		call	ParallelEndWriteCommon
		.leave
		ret
ParallelWriteByte endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelMaskError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the error mask for an open port

CALLED BY:	DR_PARALLEL_MASK_ERROR
PASS:		ax	= ParallelError record indicating errors that should be
			  be ignored by the driver.
		bx	= unit number (transformed to ParallelPortData by 
			  ParallelStrategy)
RETURN:		Nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelMaskError proc	near
		.enter
EC <		test	ax, not mask ParallelError or mask PE_TIMEOUT or \
			    mask PE_FATAL				>
EC <		ERROR_NZ	INVALID_ERROR_MASK			>
		not	ax			; Need it as a mask...
		mov	ds:[bx].PPD_errMask, ax
		.leave
		ret
ParallelMaskError endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelPortQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a port is ready to go.

CALLED BY:	DR_PARALLEL_QUERY
PASS:		bx	= unit number (transformed to ParallelPortData by 
			  ParallelStrategy)
RETURN:		ax 	= non-zero if printer off-line or busy.
		(for internal use only: caller can perform a jnz after
		calling this to handle receiving an error)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelPortQuery proc	near	uses dx, si
		.enter

		mov	si, bx
		call	ParallelCheckError

		xornf	al, mask PS_BUSY	; also want to return this
						;  with the right polarity
		;
		; Clear all but those bits of interest to the caller.
		; This leaves ZF nicely positioned for ParallelVerify to use...
		;
		and	ax, mask PS_SELECT or mask PS_ERROR or \
			    mask PS_BUSY or mask PS_NOPAPER
		.leave
		ret
ParallelPortQuery endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the timeout value for a port.

CALLED BY:	DR_PARALLEL_TIMEOUT
PASS:		ax	= timeout value (seconds)
		bx	= unit number (transformed to ParallelPortData by 
			  ParallelStrategy)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelTimeout	proc	near
		.enter
		mov	ds:[bx].PPD_timeout, al
		.leave
		ret
ParallelTimeout	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelPortRestart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restart output to a port after a timeout error

CALLED BY:	DR_PARALLEL_RESTART
PASS:		ax	= non-zero to cause the byte on which the timeout
			  occurred to be re-sent
		bx	= unit number (transformed to ParallelPortData by 
			  ParallelStrategy)
RETURN:		carry set if the byte couldn't be re-sent
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelPortRestart proc near	uses dx, si
		.enter
		mov	si, bx
		cmp	ds:[si].PPD_irq, 1
		jbe	restartThread

		tst	ax
		jz	noResend
doRestart:
		call	ParallelRestart
done:
		.leave
		ret
noResend:
	;
	; Fetch the next byte from the stream, if there's anything there.
	;
		mov	bx, ds:[si].PPD_stream
		push	di
		mov	di, DR_STREAM_READ_BYTE
		mov	ax, STREAM_NOBLOCK
		call	StreamStrategy
		pop	di
		jc	setIEN		; Nothing to send if returned
					;  would-block, but still need to
					;  re-enable interrupts for the port
					;  next time.
		mov	ds:[si].PPD_lastSent, al ; Pretend byte we just got was
		jmp	doRestart	; last sent and call normal restart
					; routine
setIEN:
		ornf	ds:[si].PPD_ctrl, mask PC_IEN
		stc			; flag nothing sent
		jmp	done

restartThread:
	;
	; To restart a thread-driven port with no resend, we just need to
	; set the PPD_counter field greater than 0 and it will start back up
	; again automagically.
	; XXX: fix to return carry set, etc.
	; 
		tst	ax
		jz	setCounter
		ornf	ds:[si].PPD_ctrl, mask PC_IEN	; tell thread to
							;  resend the byte
setCounter:
		mov	al, ds:[si].PPD_timeout
		mov	ds:[si].PPD_counter, al
		jmp	done
ParallelPortRestart endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelGetDeviceMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the map of existing stream devices for this driver

CALLED BY:	DR_STREAM_GET_DEVICE_MAP
PASS:		ds	= dgroup (from ParallelStrategy)
RETURN:		ax	= ParallelDeviceMap
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelGetDeviceMap proc	near
		.enter
		mov	ax, ds:[deviceMap]
		.leave
		ret
ParallelGetDeviceMap endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelSetInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the interrupt vector used by a parallel port.

CALLED BY:	DR_PARALLEL_SET_INTERRUPT
PASS:		al	= SysDevInterrupt, or 0 to disable interrupts
		bx	= unit number of closed port
RETURN:		carry set if interrupt level couldn't be changed.
			ax	= StreamError giving reason for failure
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelSetInterrupt	proc	near	uses si, cx, dx
		.enter
	;
	; See if the port actually exists. Error code is loaded into DI for
	; later transfer to AX as we can't biff AX here...
	;
		mov	si, ds:printerPorts[bx]	; Point to port data
		mov	di, STREAM_NO_DEVICE
		tst	ds:[si].PPD_base
		jz	error
	;
	; See if the device is already open. If so, we can't update.
	; 
		PTimedSem	ds, [si].PPD_openSem, 0
		mov	di, STREAM_DEVICE_IN_USE
		jc	error
	;
	; See if the interrupt level is already given to some other port.
	; Of course, we always allow level 0 or 1..
	; 
		cmp	al, 1
		jbe	irqOk
		mov	dx, ds:[si].PPD_base
		mov	di, offset lpt1
		mov	cx, ds:[numPorts]
checkLoop:
		cmp	di, si			;on port being adjusted?
		je	nextPort		;yes -- skip it
		ja	checkIRQ
		cmp	ds:[di].PPD_base, dx	; same base as previous port?
		je	taken			; yes -- disallow hw access
checkIRQ:
		cmp	ds:[di].PPD_irq, al	;IRQ taken?
		je	taken
nextPort:
		add	di, size ParallelPortData
		loop	checkLoop

irqOk:
		mov	ds:[si].PPD_irq, al
		clc		; carry may be set by comparison to 1...
		VSem	ds, [si].PPD_openSem
done:
		.leave
		ret
taken:
		mov	di, STREAM_INTERRUPT_TAKEN
		VSem	ds, [si].PPD_openSem
error:
		mov_tr	ax, di			;ax <- error code
		stc
		jmp	done
ParallelSetInterrupt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelVerifyError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an error report from the port.

CALLED BY:	StreamSetError
PASS:		ax	= ParallelPortData offset of port being verified
		cx	= ParallelError record
		dx	= stream segment (ignored)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Store the error record in the ParallelPortData and wakeup the
		waiting thread.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelVerifyError proc far	uses ds, bx
		.enter
		segmov	ds, dgroup, bx
		mov	bx, ax		; bx <- ParallelPortData
		
		mov	ds:[bx].PPD_verRes, cx
		VSem	ds, [bx].PPD_sem
		.leave
		ret
ParallelVerifyError endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelVerifyData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of another byte making it out the port.

CALLED BY:	StreamWriteDataNotify
PASS:		cx	= ParallelPortData
		dx	= stream token (ignored)
		bp	= STREAM_READ (ignored)
RETURN:		carry clear (not returning anything more to write)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelVerifyData proc	far	uses ds, bx
		.enter
		segmov	ds, dgroup, bx
		mov	bx, cx
		
		dec	ds:[bx].PPD_verCount
		jnz	done
	;
	; Both bytes sent, so wake up the waiting thread.
	;
		VSem	ds, [bx].PPD_sem
done:
		clc		; nothing being returned for writing
		.leave
		ret
ParallelVerifyData endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelVerify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a printer is actually out there.

CALLED BY:	DR_PARALLEL_VERIFY
PASS:		bx	= unit number  (transformed to ParallelPortData by 
			  ParallelStrategy)
		(ds	= dgroup as loaded by ParallelStrategy)
RETURN:		ax	= ParallelError if printer not around (0 if happy)
DESTROYED:	di, SNE_DATA and SNE_ERROR notifiers for the port are
		reset to SNM_NONE.

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelVerify	proc	near	uses cx, dx, bp
		.enter
		call	ParallelPortQuery
		tst	ax				; see if any errors
		jnz	done
		
	;
	; Set up ParallelPortData for verification.
	;
		mov	ds:[bx].PPD_verCount, 2		; we write two nulls...
		mov	ds:[bx].PPD_sem.Sem_value, 0	; ensure initial block
		mov	ds:[bx].PPD_verRes, 0		; assume happy
	;
	; Initialize notifiers properly
	;
		mov	di, DR_STREAM_SET_NOTIFY	
		mov	ax, StreamNotifyType <0,SNE_ERROR,SNM_ROUTINE>
		mov	cx, cs
		mov	dx, offset ParallelVerifyError
		mov	bp, bx
		call	ParallelSetNotify

		mov	bx, bp		; restore ParallelPortData offset
		mov	ax, StreamNotifyType <0,SNE_DATA,SNM_ROUTINE>
		mov	dx, offset ParallelVerifyData
		call	ParallelSetNotify

	;
	; Write the two carriage return bytes to the port.
	;
		mov	di, DR_STREAM_WRITE_BYTE	
		mov	bx, bp		; restore ParallelPortData offset
		clr	cx
		mov	ax, STREAM_BLOCK
		call	ParallelWriteByte
		
		mov	bx, bp		; restore ParallelPortData offset
		clr	cx
		mov	ax, STREAM_BLOCK
		call	ParallelWriteByte
		
	;
	; Wait for something to happen...
	;
		mov	bx, bp		; restore ParallelPortData offset
		PSem	ds, [bx].PPD_sem

	;
	; Reset data and error notifiers.
	;
		mov	di, DR_STREAM_SET_NOTIFY	
		mov	ax, StreamNotifyType <0,SNE_DATA,SNM_NONE>
		call	ParallelSetNotify
		mov	bx, bp

		mov	ax, StreamNotifyType <0,SNE_ERROR,SNM_NONE>
		call	ParallelSetNotify
		
	;
	; Load result into AX and split
	;
		mov	bx, bp
		mov	ax, ds:[bx].PPD_verRes
done:
		.leave
		ret
ParallelVerify	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelStatPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check on the status of a parallel port.

CALLED BY:	DR_PARALLEL_STAT_PORT
PASS:		bx	= unit number
RETURN:		carry set if port doesn't exist
		carry clear if port is known:
			al	= interrupt level (0 => BIOS, 1 => DOS)
			ah	= BB_TRUE if port is currently open
DESTROYED:	nothing (interrupts turned on)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelStatPort proc	near
		.enter
		mov	bx, ds:printerPorts[bx]
		INT_OFF
		tst	ds:[bx].PPD_base
		jz	nonExistent
		mov	al, ds:[bx].PPD_irq
		cbw			; clear AH (not open; IRQ <= 127...)
		tst	ds:[bx].PPD_openSem.Sem_value	; (clears carry)
		jg	done
		dec	ah
done:
		INT_ON
		.leave
		ret
nonExistent:
		stc
		jmp	done
ParallelStatPort endp


if 	0	; will need something like this for DR_DISCONNECT...

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend output to all interrupt-driven ports.

CALLED BY:	DR_PARALLEL_SUSPEND
PASS:		nothing
		ds	= dgroup (from ParallelStrategy)
RETURN:		nothing
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
		mov	cx, length printerPorts
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
		.leave
		ret
ParallelSuspend	endp
endif
Resident	ends
