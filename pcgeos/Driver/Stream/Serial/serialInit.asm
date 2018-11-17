COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Serial Driver -- Initialization/Exit
FILE:		serialInit.asm

AUTHOR:		Adam de Boor, Feb  6, 1990

ROUTINES:
	Name			Description
	----			-----------
	SerialInit		Movable routine called from SerialInitStub
	SerialExit		Movable routine called from SerialExitStub
	SerialDefinePort	Movable routine called from SerialDefinePortStub
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 6/90		Initial revision based on previous incarnation


DESCRIPTION:
	Code for driver initialization/exit.
		

	$Id: serialInit.asm,v 1.50 97/09/22 19:23:38 jang Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	serial.def
include initfile.def


idata 		segment

irqMutex	Semaphore		; Semaphore that protects the variables
					;  used to determine the IRQ at which
					;  a port is operating.

initSem		Semaphore		; Semaphore on which we block while
					;  waiting for a forced interrupt. Must
					;  be semaphore so we can perform a
					;  timed block.
initPort	nptr.SerialPortData	; Port being examined by SerialCheckPort


if	STANDARD_PC_HARDWARE

primaryInitVec	SerialVectorData	<,,InitIrq4Interrupt,SDI_ASYNC>
alternateInitVec SerialVectorData	<,,InitIrq3Interrupt,SDI_ASYNC_ALT>
weirdInitVec	SerialVectorData	<,,InitWeirdInterrupt,>

endif	; STANDARD_PC_HARDWARE

definingPortSem	Semaphore
definingPort	SerialPortNum 	SERIAL_PORT_DOES_NOT_EXIST
					; port being defined by
					;  DR_SERIAL_DEFINE_PORT (set to -1
					;  so we don't use definingIRQ when
					;  initializing the driver)
idata		ends

udata		segment

if TRACK_INTERRUPT_DEPTH
maxIntDepth	word
curIntDepth	word
endif	

definingIRQ	byte			; interrupt level specified for the
					;  port.
udata		ends

OpenClose	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitWeirdInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a user-specified interrupt during initialization

CALLED BY:	Hardware level ?
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		pass si == weird1Vec to SerialIDPort

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	STANDARD_PC_HARDWARE
InitWeirdInterrupt proc	far
		ON_STACK	iret
		push	si
		ON_STACK	si iret
		mov	si, offset weirdInitVec
		jmp	SerialIDPort
InitWeirdInterrupt endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitIrq4Interrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a level 4 interrupt during initialization

CALLED BY:	Hardware level 4
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		pass si == primaryVec to SerialIDPort

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitIrq4Interrupt proc	far
		ON_STACK	iret
		push	si
		ON_STACK	si iret
		mov	si, offset primaryInitVec
		jmp	SerialIDPort
InitIrq4Interrupt endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitIrq3Interrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a level 3 interrupt during initialization

CALLED BY:	Hardware level 3
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		pass si == alternateVec to SerialIDPort

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	STANDARD_PC_HARDWARE
InitIrq3Interrupt proc	far
		ON_STACK	iret
		push	si
		ON_STACK	si iret
		mov	si, offset alternateInitVec
		jmp	SerialIDPort
InitIrq3Interrupt endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialIDPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if an interrupt we've fielded is from the port we're
		trying to locate.

CALLED BY:	InitIrq[34]Interrupt, InitWeirdInterrupt
PASS:		si	= offset of SerialVectorData in dgroup
RETURN:		nothing
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialIDPort	proc	far	uses ax, bx, dx, ds
		.enter

		mov	bx, handle dgroup
		call	MemDerefDS
;		segmov	ds, dgroup, ax
		mov	bx, ds:initPort
	;
	; Make sure our port is performing the interrupt by checking
	;	(a) the SIID_IRQ bit is low in the interrupt ID register
	;	(b) the SS_THRE bit is set in the status register
	; we do two checks just to make sure.
	;
		mov	dx, ds:[bx].SPD_base
		add	dx, offset SP_iid
		in	al, dx

		test	al, mask SIID_IRQ
		jnz	passItOn		; => Our port didn't interrupt


	;
	; Turn off interrupts for the port
	;
		clr	al
		out	dx, al
	;
	; V the semaphore on which SerialCheckPort blocks so it
	; can get going again.
	;
		VSem	ds, initSem
	;
	; Record the interrupt level from the SerialVectorData
	;
		mov	al, ds:[si].SVD_irq
		mov	ds:[bx].SPD_irq, al
	;
	; Tell the interrupt controller we're done.
	;
ignoreInt:
		call	SerialEOIFar
	;
	; Recover registers we pushed and those pushed by routine that
	; jumped to us, then return.
	;
done:
		.leave
		pop	si
		iret
passItOn:
	;
	; Deal with spurious interrupts generated by degating the UART
	; from the interrupt bus. If the interrupt that got generated is
	; the same level as the level to which we've bound the port
	; being ID'ed, just issue an EOI and get the hell out.
	; 
		mov	al, ds:[si].SVD_irq
		cmp	ds:[bx].SPD_irq, al
		je	ignoreInt
	;
	; Interrupt not for us, call the old routine, then leave
	;
		pushf				; simulate interrupt
		call	ds:[si].SVD_old
		jmp	done
SerialIDPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialGetUserInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch any user-specified interrupt for the port

CALLED BY:	SerialCheckPort
PASS:		bx	= port number (SerialPortNum)
RETURN:		al	= irq
		ah	= interrupt mask
		carry set if user specified an interrupt level
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	STANDARD_PC_HARDWARE

serialCategory	char	"serial", 0
port1Str	char	"port1", 0
port2Str	char	"port2", 0
port3Str	char	"port3", 0
port4Str	char	"port4", 0
port5Str	char	"port5", 0
port6Str	char	"port6", 0
port7Str	char	"port7", 0
port8Str	char	"port8", 0
portStrs	nptr	port1Str, port2Str, port3Str, port4Str,
			port5Str, port6Str, port7Str, port8Str
SerialGetUserInterrupt proc near	uses ds, si, cx, dx, bx
		.enter
	;
	; See if we're being called b/c we're defining a port. If so,
	; use the IRQ that's stored in the variable for that purpose...
	; 
		mov	al, ds:[definingIRQ]
		cmp	bx, ds:[definingPort]
		je	haveIRQ
	;
	; Else consult the ini file to see if the user's defined anything
	; for this...
	; 
		segmov	ds, cs, cx
		assume ds:OpenClose
		and	bx, (not SERIAL_PASSIVE) ; strip passive bit
		mov	dx, ds:portStrs[bx]
		mov	si, offset serialCategory
		call	InitFileReadInteger
		cmc
		jnc	done
haveIRQ:
		mov	cl, al
		mov	ah, 1
		rol	ah, cl		; Use ROL in case level >= 8
		stc
done:
		.leave
		assume	ds:dgroup
		ret
SerialGetUserInterrupt endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCheckPortPC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check a PC-like serial port

CALLED BY:	SerialCheckPort

PASS:		ds:si = SerialPortData

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 3/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef GPC
NUM_DEFAULT_SERIAL_PORT_IRQ	equ	2

SerialPortIRQDefaults	label	byte
	byte	4
	byte	3
endif

SerialCheckPortPC	proc	near
		.enter
	
		mov	dx, ds:[si].SPD_base

	;
	; Enable only the transmitter interrupt for the port. This
	; should interrupt in a couple of ticks at most.
	;
		INT_OFF
		;
		; Enable OUT2 for the port, thereby gating the IRQ line onto
		; the bus. Preserve the original SP_modemCtrl contents for
		; restoring after we're done...
		;
		add	dx, offset SP_modemCtrl
		in	al, dx
		mov	ds:[si].SPD_initState.SPS_modem, al
		mov	al, mask SMC_OUT2
;		andnf	al, mask SerialModem	; clear out loopback bit...
;		ornf	al, mask SMC_OUT2
		out	dx, al
		add	dx, offset SP_ien - offset SP_modemCtrl
		in	al, dx	; Save currently-enabled interrupts
		push	ax
	;
	; Disable all interrupts from the chip so we can make sure
	; all bogus existing conditions (like pending DATA_AVAIL or
	; TRANSMIT interrupts) are gone.
	;
		clr	al
		out	dx, al
		add	dx, offset SP_status - offset SP_ien	; Clear pending
		in	al, dx					;  error irq
		jmp	$+2

		add	dx, offset SP_data-offset SP_status	; Clear pending
		in	al, dx					;  data avail
		jmp	$+2

		add	dx, offset SP_iid - offset SP_data	; Clear pending
		in	al, dx					;  transmit irq
		jmp	$+2

		add 	dx, offset SP_modemStatus-offset SP_iid	;Clear pending
		in	al, dx					;  modem status
		jmp	$+2					;  irq
	;
	; Now enable the transmitter interrupt
	;

		mov	cx, SERIAL_PROBE_RETRIES
	
		add	dx, offset SP_ien - offset SP_modemStatus; Back to ien
								 ;  port
retry:
		INT_OFF

		mov	al, mask SIEN_TRANSMIT
		out	dx, al
		jmp	$+2
		;
		; Second write of IEN added per AN-493, which states:
		; "The interrupt indication that would normally appear at this
		; time will be cleared by a previously stored reset, if the IIR
		; [iid register] has been read prior to this. Write to the
		; interrupt enable register, again. Since there is no read of
		; the IIR before this second write, there will be no stored
		; reset to clear the normal THRE interrupt."
		; 
		out	dx, al
		jmp	$+2

		INT_ON
		
		PTimedSem	ds, initSem, SERIAL_PROBE_WAIT
		jnc	portThere
		clr	ax
		out	dx, al
		loop	retry
		
ifdef GPC
	; For known hardware (such as for GlobalPC), if this test
	; fails, let us try to use the known IRQ value anyway.
	; This test is sometime known to not work for who-knows-what
	; reason.  But if we use default values, things seem to reset
	; themselves.
	;
		push	di
		mov	di, ds:[si].SPD_portNum
		shr	di
		cmp	di, NUM_DEFAULT_SERIAL_PORT_IRQ
		jae	noDefault
EC <		WARNING SERIAL_CHECK_PORT_FAILED__USING_DEFAULT_VALUE	>
		add	di, offset SerialPortIRQDefaults
		mov	al, cs:[di]
		mov	ds:[si].SPD_irq, al
		mov	ax, ds:[si].SPD_base
noDefault:
		pop	di
endif  ;GPC
			
		mov	ds:[si].SPD_base, ax	; Flag port as absent
portThere:

		pop	ax	; Recover enabled ints and user-interrupt
				;  flag, which we put back in CF eventually

		; adjust interrupt enable and modem status before loosing
		; the vectors so we can field any bogus interrupts generated
		; by degating the UART from the IRQ bus.
		out	dx, al	; Reset port's interrupt status
				; Reset modem control port now we've played
				;  with the port's interrupts.
		add	dx, offset SP_modemCtrl - offset SP_ien
		mov	al, ds:[si].SPD_initState.SPS_modem
		out	dx, al
		jmp	$+2		; I/O delay to make sure any bogus
		jmp	$+2		;  interrupts are taken before
		jmp	$+2		;  we loose the vectors we've got
		.leave
		ret
SerialCheckPortPC	endp

endif	; STANDARD_PC_HARDWARE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCheckPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of a serial port and determine at
		what interrupt it is running.

CALLED BY:	SerialInit
PASS:		ds:si	= SerialPortData for the port
		bx	= SerialPortNum for the port
RETURN:		ds:[si].SPD_base set to 0 if port doesn't exist.
		ds:[si].SPD_irq set to hardware interrupt level if it does.
		carry set if port doesn't exist
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		XIP - locked code resource on heap when setting up
			init vectors per Todd's suggestion

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/12/90		Initial version
	jwu	5/5/94		XIP-enabled

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	STANDARD_PC_HARDWARE

SerialCheckPort	proc	near	uses bx
		.enter
	;
	; Gain exclusive access to global variables.
	; 
		PSem	ds, irqMutex
	;
	; Record the port we're checking for SerialIDPort to use
	;
		mov	ds:initPort, si
		mov	ds:[initSem].Sem_value, 0	; ensure block when
							;  we P the thing
	;
	; Initialize interrupt vectors we always need
	;
		push	bx


FXIP <		push	ax						>
FXIP <		mov	bx, handle OpenClose				>
FXIP <		call	MemLock						>
FXIP <		mov	bx, ax		; bx = locked code segment	>
FXIP <		pop	ax						>

NOFXIP<		mov	bx, cs		; bx = segment of handlers for	>
					;  SerialInitVector calls
		mov	di, offset primaryInitVec
		call	SerialInitVector

		mov	di, offset alternateInitVec
		call	SerialInitVector

	;
	; See if the user has specified a special interrupt level
	; for this port. Trap it to InitWeirdInterrupt if so.
	;
		mov	di, bx			; di <- saved handler segment
		pop	bx
		call	SerialGetUserInterrupt
		jnc	forceInt
		push	bx
		mov	ds:weirdInitVec.SVD_irq, al

		mov	bx, di			; bx <- handler segment
		mov	di, offset weirdInitVec
		call	SerialInitVector
		stc
		pop	bx
forceInt:
		lahf 		; Save whether user-specified interrupt
				;  trapped

		call	SerialCheckPortPC
		sahf
		jnc	noResetUserInterrupt

		mov	di, offset weirdInitVec
		call	SerialResetVector
noResetUserInterrupt:
	;
	; Reset the vectors we always snag.
	;
		mov	di, offset alternateInitVec
		call	SerialResetVector

		mov	di, offset primaryInitVec
		call	SerialResetVector

FXIP <		push	bx						>
FXIP <		mov	bx, handle OpenClose				>
FXIP <		call	MemUnlock					>
FXIP <		pop	bx						>
		tst	ds:[si].SPD_base
		jnz	exists
		stc
done:
		VSem	ds, irqMutex
		.leave
		ret

exists:
	;
	; Set the proper bit in the device map to be returned to interested
	; parties...
	;
		xchg	cx, bx
		mov	bx, 1
		shl	bx, cl
		ornf	ds:[deviceMap], bx
		mov	bx, cx
		jmp	done
SerialCheckPort	endp

endif	; STANDARD_PC_HARDWARE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialLookForMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the .ini file contains an indication of the media
		attached to this port

CALLED BY:	(INTERNAL) SerialCheckPort
PASS:		bx	= SerialPortNum
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/22/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if STANDARD_PC_HARDWARE
mediaCatStr	char	'media', 0
portMediaStrs	nptr.char	port1Media, port2Media, port3Media, port4Media,
				port5Media, port6Media, port7Media, port8Media
port1Media	char	'com1', 0
port2Media	char	'com2', 0
port3Media	char	'com3', 0
port4Media	char	'com4', 0
port5Media	char	'com5', 0
port6Media	char	'com6', 0
port7Media	char	'com7', 0
port8Media	char	'com8', 0

SerialLookForMedium proc	near
medium		local	SERIAL_MAX_MEDIA dup (MediumType)
		uses	ax, bx, cx, dx, si, di, bp, es
		.enter
		push	ds, bp
		segmov	ds, cs, cx	; ds, cx <- cs
		assume	ds:@CurSeg
		mov	dx, ds:[portMediaStrs][bx]	; cx:dx <- key
		mov	si, offset mediaCatStr		; ds:si <- category
		segmov	es, ss
		lea	di, ss:[medium]			; es:di <- buffer
		mov	bp, size medium			; bp <- buffer size
		push	bx
		call	InitFileReadData
		pop	bx
		pop	ds, bp
		assume	ds:dgroup
		jc	checkDefault			; => no key

			CheckHack <size MediumType eq 4>
		shr	cx
EC <		ERROR_C	INVALID_MEDIA_KEY_VALUE				>
		shr	cx				; cx <- # media
EC <		ERROR_C	INVALID_MEDIA_KEY_VALUE				>

		mov	dx, ss
		lea	ax, ss:[medium]			;dx:ax <- medium array
haveMedium:
		call	SerialSetMediumFAR
done:
		.leave
		ret

checkDefault:
	;
	; If this port is being defined via DR_SERIAL_DEFINE_PORT, leave the
	; medium alone, on the assumption that the caller will shortly set it.
	; If we found it just during initialization, however, we want to give
	; it some generic medium, and that medium is SERIAL_CABLE.
	; 
		cmp	ds:[definingPort], bx
		je	done
		mov	cx, 1
		mov	dx, cs
		mov	ax, offset serialCableMedium
		jmp	haveMedium

SerialLookForMedium endp

serialCableMedium MediumType	<GMID_SERIAL_CABLE, MANUFACTURER_ID_GEOWORKS>

endif ; STANDARD_PC_HARDWARE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Real initialization routine for the driver

CALLED BY:	SerialInit
PASS:		ds	= dgroup
RETURN:		carry clear if we're happy
DESTROYED:	?

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
portBases	word	COM1_BASE, COM2_BASE, COM3_BASE, COM4_BASE
if	STANDARD_PC_HARDWARE

SerialInit proc	far
		uses	ax, es, si
		.enter
	;
	; First consult BIOS to see what it has to say about existing ports.
	; The number of ports that BIOS knows is stored in the BIOS_EQUIPMENT
	; record (like everything else). Extract that number into CX for our
	; loop, and point SI at the base of the table of port bases.
	;
	; 4/14/91: changed to not count on equipment configuration word,
	; since it gets tromped by video boards and other nasties. We know
	; there can be at most 4 ports in the thing, and BIOS is "guaranteed"
	; to not place a real port after a 0 entry in the array, so we
	; can just loop 4 times and bail if we find a 0 entry. -- ardeb
	; 
		mov	ax, BIOS_DATA_SEG
		mov	es, ax
		mov	cx, 4		; BIOS holds 4 ports, max
		mov	si, offset BIOS_SERIAL_PORTS
biosLoop:
	;
	; Fetch the base of the next port.
	; 
		lodsw	es:
		tst	ax		; any port?
		jz	nextBiosPort	; no -- advance to next
		
	;
	; Figure out which "com" structure to use for it, based on industry
	; standard names for the things. BX tracks the SerialPortNum for the
	; thing...
	; 
		push	si, cx
		mov	bx, -2
		mov	cx, length portBases
baseLoop:
		inc	bx
		inc	bx
		cmp	ax,  cs:portBases[bx]
		loopne	baseLoop

	;
	; At this point:
	;	ax	= serial port base address( 03f8h, 02f8h, etc )
	; 	bx	= com port number that corresponds to base addr
	;	cx	= trashed
	;	ZF is set
	;

	;
	; Point SI to the right SerialPortData structure, if we've found it.
	; 
		pushf
		mov	si, bx			; si <- port number
		call	SerialGetPortDataFAR	; ds:bx <- SerialPortData
		xchg	si, bx			; bx <- port number
		popf
		je	havePortData
	;
	; Must be a PS/2 port (IBM just *had* to be different...). Look for a
	; free slot starting at com3, as "Serial_1" and "Serial_2" are the
	; standard addresses, with the non-standard ones starting at
	; "Serial_3". Presumably, IBM BIOS won't look for the standardly
	; non-standard ports at COM3_BASE and COM4_BASE...Once again, BX
	; tracks the SerialPortNum for the thing.
	; 
		mov	si, offset com3
		mov	bx, SERIAL_COM3
ps2Loop:
		tst	ds:[si].SPD_base	; taken?
		jz	havePortData		; no -- it's ours
		add	si, size SerialPortData
		inc	bx
		inc	bx
		cmp	bx, LAST_ACTIVE_SERIAL_PORT
		jb	ps2Loop
		jmp	endBiosLoop	; ignore it if can't find an open
					;  structure to describe it...
havePortData:
	;
	; ax	= serial port base address( 03f8h, 02f8h, etc )
	; bx	= logical port number( SERIAL_COM1, SERIAL_COM2, etc )
	; ds:si	= SerialPortData structure
	;
	; See if there's an interrupt level defined for the port in the .ini
	; file and, if so, whether it's -1, which indicates the port has
	; been shut off by the user.
	; 
		push	ax
		call	SerialGetUserInterrupt	; al = irq ; ah = 1 (rol) irq
		jnc	setBase			; CF if user specified
		cmp	al, -1
		jne	setBase
		pop	ax
		jmp	endBiosLoop
setBase:
		pop	ds:[si].SPD_base

		call	SerialLookForMedium

		mov	ax, 1		; port exists, so figure the bit for
		mov	cx, bx		;  it in the device map
		shl	ax, cl
		ornf	ds:[deviceMap], ax
		inc	ds:[numPorts]	; and up the number of known ports
					;  we support.
endBiosLoop:
		pop	si, cx
nextBiosPort::
		loop	biosLoop

	;
	; Now look for user-specified ports 3 and 4. We do *not* probe for them.
	; We simply see if an interrupt level is specified for them in the
	; .ini file and leave it at that. There appear to be devices that
	; make use of these I/O addresses and that confuse things if we
	; do probe, so we don't do it...
	;
		mov	si, offset com3
		mov	bx, SERIAL_COM3
		tst	ds:[si].SPD_base	; already known?
		jnz	com4Check		; yes -- skip this old-fashioned
						;  check

		call	SerialGetUserInterrupt
		jnc	com4Check
		cmp	al, -1
		je	com4Check
		mov	ax, COM3_BASE
		call	SerialCheckExists
		jc	com4Check
		mov	ds:[si].SPD_base, ax
		call	SerialLookForMedium
		ornf	ds:[deviceMap], mask SDM_COM3
		inc	ds:[numPorts]
com4Check:
		add	si, size SerialPortData
		tst	ds:[si].SPD_base	; already known?
		jnz	copyPorts		; yes -- skip this old-fashioned
						;  check
		inc	bx
		inc	bx
		call	SerialGetUserInterrupt
		jnc	copyPorts
		cmp	al, -1
		je	copyPorts
		mov	ax, COM4_BASE
		call	SerialCheckExists
		jc	copyPorts
		mov	ds:[si].SPD_base, ax
		call	SerialLookForMedium
		ornf	ds:[deviceMap], mask SDM_COM4
		inc	ds:[numPorts]
copyPorts:
	;
	; Copy the just-initialized active port data to the passive
	; port structures.
	;
		mov	bx, -2
copyPortLoop:
		inc	bx
		inc	bx
		mov	si, ds:comPorts[bx]	; ds:si <- active struct

		mov	ax, ds:[si].SPD_base
		mov	si, ds:[si].SPD_otherPortData
		mov	ds:[si].SPD_base, ax

		cmp	bx, LAST_ACTIVE_SERIAL_PORT
		jne	copyPortLoop

		clc				;always happy
		.leave
		ret
SerialInit 	endp
endif	; STANDARD_PC_HARDWARE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialEnsureClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we're unhooked from the indicated interrupt vector

CALLED BY:	SerialExit
PASS:		ds:di	= SerialVectorData to reset, if necessary
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialEnsureClosed proc	near	uses	si, dx, ax
		.enter
		clr	al
portLoop:
		mov	si, ds:[di].SVD_port
		tst	si
		jz	done
	;
	; Reset the vector.
	;
		call	SerialResetVector
	;
	; Reset the port to its initial state and loop to make sure we've
	; gotten all ports at this level.
	;
		call	SerialResetPort
		jmp	portLoop
done:
		.leave
		ret
SerialEnsureClosed endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that all ports are closed down properly.

CALLED BY:	SerialExit
PASS:		ds	= dgroup
RETURN:		carry clear if we're happy
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialExit	proc	far
		.enter
		mov	di, offset primaryVec
		call	SerialEnsureClosed
		mov	di, offset alternateVec
		call	SerialEnsureClosed
if	STANDARD_PC_HARDWARE
		mov	di, offset weird1Vec
		call	SerialEnsureClosed
		mov	di, offset weird2Vec
		call	SerialEnsureClosed
endif
		.leave
		ret
SerialExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCheckExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if a serial device exists given its base port.

CALLED BY:	SerialDefinePort, SerialInit
PASS:		ax	= base port for the device
RETURN:		carry set if port doesn't exist
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SerialCheckExists proc	near	uses ax, dx
		.enter
if	STANDARD_PC_HARDWARE
		push	cx
		mov	cx, SERIAL_EXISTENCE_CHECK_TRIES
	;
	; This test is taken from the AT BIOS listing and makes sense to me.
	; If there's no device there, a read from one of the I/O ports is
	; likely to return FF, so if we read the interrupt ID register and see
	; that any of the bits that must be zero (those not included in the
	; SerialIID record) are not, we assume the port doesn't actually exist,
	; or isn't one we can deal with.
	;
	; 11/11/93: this looping is a hack added to cope with Megahertz PCMCIA
	; modem cards that seem to take a while to settle down and return
	; something other than the status register when reading the IID reg.
	; 					-- ardeb
	; 
		xchg	ax, dx
		add	dx, offset SP_iid
checkLoop:
		in	al, dx
		test	al, not SerialIID	; (clears carry)
		jz	checkLoopDone
		mov	ax, SERIAL_EXISTENCE_CHECK_WAIT
		call	TimerSleep
		loop	checkLoop
		ornf	ax, 1			; force non-z
checkLoopDone:
		pop	cx
		jnz	bad
endif	; STANDARD_PC_HARDWARE
done:
		.leave
		ret
bad:
		stc
		jmp	done
SerialCheckExists endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialDefinePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Real implementation of DR_SERIAL_DEFINE_PORT

CALLED BY:	SerialDefinePort
PASS:		ax	= base of port being defined
		bx	= PCMCIA socket number (-1 if not PCMCIA)
		cl	= interrupt level for the thing
		ds	= dgroup (from SerialStrategy)
RETURN:		carry set if couldn't define the port, for some reason
			ax	= STREAM_NO_DEVICE if the device doesn't
				  exist at that address.
				= STREAM_DEVICE_IN_USE if the device is
				  currently open.
				= STREAM_NO_FREE_PORTS if no available
				  SerialPortData structure to track it.

		carry clear if port defined:
			bx	= SerialPortNum to use in future calls
			ax	= destroyed
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	STANDARD_PC_HARDWARE

SerialDefinePort proc	far	uses si, dx
		.enter
		mov	dx, bx		; dx <- socket #
	;
	; See if it's a standard port being defined after initialization time,
	; e.g. by graphical setup.
	; 
		push	cx
		mov	bx, -2
		mov	cx, length portBases
baseLoop:
		inc	bx
		inc	bx
		cmp	ax, cs:portBases[bx]
		loopne	baseLoop
	;
	; Point SI to the right SerialPortData structure, if we've found it.
	; 
		mov	si, ds:comPorts[bx]
		je	havePortData
	;
	; Unlike SerialInit, we start searching for an open port at
	; com5, not com3, so as not to conflict with later definitions of
	; COM3 and COM4, if such there are...
	; 
	; 1/19/93: to deal with intermediate ports having been shut off while
	; this port is being modified, we loop through all the things from
	; COM5 up, remembering the first free slot, but looking for one already
	; in-use with the given base. -- ardeb
	; 
		push	dx
		mov	si, offset com5
		mov	bx, SERIAL_COM5
		mov	dx, -1			; nothing seen yet
weirdLoop:
		tst	ds:[si].SPD_base	; taken?
		jz	rememberFree		; no -- it's ours
		cmp	ax, ds:[si].SPD_base	; same one?
		je	popSocketHavePortData	; yup -- must be redefining
						;  it (maybe different IRQ,
						;  probably just driver being
						;  reloaded).
nextWeird:
		add	si, size SerialPortData
		inc	bx
		inc	bx
		cmp	bx, SerialPortNum
		jb	weirdLoop

		cmp	dx, -1			; seen any free one?
		jne	fetchFreeWeirdData	; yes -- use it
		pop	dx			; clear socket #
		mov	ax, STREAM_NO_FREE_PORTS
		jmp	bad		; ignore it if can't find an open
					;  structure to describe it...
rememberFree:
		cmp	dx, -1			; already seen a free one?
		jne	nextWeird		; yes
		mov	dx, bx			; no -- remember it
		jmp	nextWeird

busy:
		mov	ax, STREAM_DEVICE_IN_USE
		jmp	done

fetchFreeWeirdData:
		mov	bx, dx
		mov	si, ds:comPorts[bx]

popSocketHavePortData:
		pop	dx
havePortData:
		push	bx
		mov	bx, ds:[si].SPD_openSem
		PTimedSem	ds, [bx], 0
		pop	bx
		pop	cx
		jc	busy

		cmp	cl, -1
		LONG je	turnOffPort

		call	SerialCheckExists
		LONG jc	noExist

		xchg	ds:[si].SPD_base, ax
		mov	ds:[si].SPD_socket, dx

	;
	; Verify the interrupt (we take the fact that user wants to define
	; the port as indication that it's fair game).
	; 
		PSem	ds, definingPortSem
		mov	ds:[definingPort], bx
		mov	ds:[definingIRQ], cl
		push	ax
		call	SerialCheckPort
		pop	ax
		mov	ds:[definingPort], SERIAL_PORT_DOES_NOT_EXIST
		VSem	ds, definingPortSem
		jc	noExistReleasePort

		tst_clc	ax		; was slot free?
		jnz	doneReleasePort	; just specifying IRQ for an existing
					;  port, so don't mess with global
					;  vars

		mov	ax, 1		; port exists, so figure the bit for
		mov	cx, bx		;  it in the device map
		shl	ax, cl
		ornf	ds:[deviceMap], ax
		inc	ds:[numPorts]	; and up the number of known ports
					;  we support.
doneReleasePort:
		push	si
		mov	si, ds:[si].SPD_openSem		
		VSem	ds, [si]
		pop	si
done:		
		.leave
		ret
noExistReleasePort:
		push	si
		mov	si, ds:[si].SPD_openSem
		VSem	ds, [si]
		pop	si
noExist:
		mov	ax, STREAM_NO_DEVICE
bad:
		stc
		jmp	done

turnOffPort:
	;
	; Set the base to 0 to indicate the absence of the port, and clear
	; out the bit from the device map.
	; 
		mov	ds:[si].SPD_base, 0
EC <		push	dx						>
		clr	cx			; cx <- no medium bound
EC <		segmov	dx, cs			; dx:ax <- valid ptr	>
EC <		mov	ax, offset turnOffPort	;  to avoid death	>
		call	SerialSetMediumFAR
EC <		pop	dx						>

		mov	ax, not 1
		mov	cx, bx
		rol	ax, cl
		andnf	ds:[deviceMap], ax
		dec	ds:[numPorts]
	;
	; Signal success and release the port so it can be redefined
	; 
		clc
		jmp	doneReleasePort

SerialDefinePort endp

endif	; STANDARD_PC_HARDWARE

OpenClose	ends



