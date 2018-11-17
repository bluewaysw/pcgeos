COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Parallel Driver -- Initialization/Exit
FILE:		parallelInit.asm

AUTHOR:		Adam de Boor, Feb  6, 1990

ROUTINES:
	Name			Description
	----			-----------
	ParallelRealInit	Movable routine called from ParallelInit
	ParallelRealExit	Movable routine called from ParallelExit
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/ 6/90		Initial revision


DESCRIPTION:
	Code for driver initialization/exit.
		

	$Id: parallelInit.asm,v 1.1 97/04/18 11:46:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	parallel.def

include timedate.def
include initfile.def

udata		segment
watchdog	hptr		; Timer handle for watchdog timer

delayFactor	word		; Index into jump table for strobe delay
udata		ends

Init		segment	resource

USER_IRQ	= 0x80		; Bit set to indicate interrupt level user-
				;  assigned. Allows explicit specification
				;  of thread-driven port.


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelCalcDelay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the delay factor the interrupt code should use,
		based on the calculated speed of the processor, as indicated
		by the number of idle ticks available in a second.

CALLED BY:	ParallelRealInit
PASS:		ds	= dgroup
RETURN:		carry set if processor too fast.
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		There is a notion in our system of the Tony Index of a machine,
		so-named because Tony was the one who added it into "perf" so
		we could transform performance measurements to what they'd be
		on a base PC w/o actually running on one.
		
		Briefly: The kernel supplies a measure of the CPU speed
		via the call SysgetCPUSpeed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelCalcDelay proc	near
		.enter
		mov	ax, SGIT_CPU_SPEED
		call	SysGetInfo
		clr	dx
		mov	bx, 10
		div	bx
		;
		; Just take the multiplier times 2 (preshifted to allow
		; quick indexing of the jump table.
		;
		cmp	ax, MAX_DELAY
		jbe	ok
		mov	ax, MAX_DELAY	; Just max the thing out. The
					;  machines that were having difficulty
					;  with this limit seem to operate
					;  just fine if we find the tony
					;  index unturboed, and then print
					;  after turboing the machine again.
ok:
		shl	ax
		mov	ds:delayFactor, ax
		clc

		.leave
		ret
ParallelCalcDelay endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelIRQTaken?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the indicated interrupt level has already been
		claimed by some other port.

CALLED BY:	ParallelRealInit
PASS:		ds:si	= ParallelPortData of port being initialized
		al	= potential interrupt level
RETURN:		carry set if already taken:
		di	= offset of ParallelPortData for port that claims it.
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelIRQTaken? proc	near
		uses	bx
		.enter
		mov	bx, ds:[si].PPD_base
		mov	di, offset lpt1 - size ParallelPortData
10$:
		add	di, size ParallelPortData
		cmp	di, si
		je	done			; Carry already clear
		cmp	bx, ds:[di].PPD_base
		je	yes			; if same base as other port,
						;  assume it's fake (created
						;  by some interceptor) and
						;  force BIOS/DOS only
		mov	ah, ds:[di].PPD_irq
		andnf	ah, not USER_IRQ
		cmp	ah, al
		jne	10$
yes:
		stc
done:
		.leave
		ret
ParallelIRQTaken? endp


parallelCategory	char	"parallel", 0
port1Str		char	"port1", 0
port2Str		char	"port2", 0
port3Str		char	"port3", 0
port4Str		char	"port4", 0
portStrs		nptr	port1Str, port2Str, port3Str, port4Str

ifdef ALLOW_PORT_OVERRIDE
parallelOverride	char	"override", 0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelFindPorts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate any existing parallel ports and determine their
		interrupt numbers.

CALLED BY:	ParallelRealInit
PASS:		es	= BIOS_DATA_SEG
		bx	= offset BIOS_PRINTER_PORTS
		ds	= dgroup 
RETURN:		nothing
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelFindPorts proc	near
		.enter
		mov	cx, 4		; four ports max in bios data area
userPortLoop:

ifdef ALLOW_PORT_OVERRIDE
		push	ds, si, cx
		segmov	ds, cs, cx

		mov	si, offset parallelCategory
		mov	dx, offset parallelOverride

EC <		push	es	; fucking error-checking code....	>
EC <		segmov	es, ds						>
		call	InitFileReadInteger
EC <		pop	es						>
		pop	ds, si, cx
		jc	noOverride

		; ax = number of ports to override, cx = number left

		mov	dx, 5
		sub	dx, cx		;dx = port # we're on (from 1)
		cmp	dx, ax
		jbe	portExists

noOverride:
endif

		mov	ax, es:[bx]
		tst	ax		; Port exists?
		jz	findNextPort	; 0 => no.
portExists:
	ForceRef portExists

	;
	; Set the proper bit in the ParallelDeviceMap
	;

                push    ax, cx
                mov     ax, 1 shl 6
		dec	cx
		shl	cx
		shr	ax, cl
                or      ds:[deviceMap], ax
                pop     ax, cx


	;
	; Record I/O base port and BIOS port number for the printer.
	;
		inc	ds:[numPorts]	; another port found...
		mov	ds:[si].PPD_base, ax
		mov	ax, bx
		sub	ax, offset BIOS_PRINTER_PORTS
		shr	ax
		mov	ds:[si].PPD_biosNum, ax
	;
	; See if the port<n> key is in the init file.
	;
		push	ds, si, cx
		segmov	ds, cs, cx
		shl	ax
		xchg	si, ax		; si <- offset into portStrs (1-b i)
		mov	dx, cs:portStrs[si]
		mov	si, offset parallelCategory
EC <		push	es	; fucking error-checking code....	>
EC <		segmov	es, ds						>
		call	InitFileReadInteger
EC <		pop	es						>
		pop	ds, si, cx
		jc	findNextPort
	;
	; Make sure the user hasn't screwed up and already specified
	; this one before.
	;
		cmp	ax, 1
		jbe	userIRQOk
		call	ParallelIRQTaken?
		jc	findNextPort	; If specified before, just
					;  hooey the user and ignore this one.
					;  Eventually we need to notify the
					;  user of the error of his/her ways...
userIRQOk:
		ornf	al, USER_IRQ
		mov	ds:[si].PPD_irq, al
findNextPort:
		add	si, size ParallelPortData
		inc	bx
		inc	bx
		loop	userPortLoop
		
	;
	; Now try and assume IRQ levels for any ports that remain
	; unspecified, assigning the two interrupt levels we have
	; in order of port number.
	;
		mov	cx, 4		; max # ports
		mov	si, offset lpt1
assumePortLoop:
		tst	ds:[si].PPD_base; Port exists?
		jz	hasIRQ		; No. Ignore it.

		mov	al, ds:[si].PPD_irq
		tst	al
		jnz	storeIRQ	; Already known -- go strip USER_IRQ
		
		mov	al, SDI_PARALLEL
		call	ParallelIRQTaken?
		jnc	storeIRQ	; Primary not taken -- give it to this
					;  one
		
		cmp	ds:machine, SMT_PC_XT
		jbe	clearRemaining	; Can't use alternate on PC or XT, so
					;  nothing more we can do.

		mov	al, SDI_PARALLEL_ALT
		call	ParallelIRQTaken?
		jc	clearRemaining	; Alternate taken -- we've nothing more
					;  to give, so break out of the loop
storeIRQ:
		andnf	al, not USER_IRQ
		mov	ds:[si].PPD_irq, al
hasIRQ:
		add	si, size ParallelPortData
		loop	assumePortLoop

clearRemaining:
	;
	; Clear the USER_IRQ bit from the remaining ports, if any
	;
		jcxz	portsInitialized
clearLoop:
		andnf	ds:[si].PPD_irq, not USER_IRQ
		add	si, size ParallelPortData
		loop	clearLoop

portsInitialized:
		.leave
		ret
ParallelFindPorts endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelRealInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Real initialization routine for the driver

CALLED BY:	ParallelInit
PASS:		ds	= dgroup
RETURN:		carry clear if we're happy
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		We obtain the addresses and number of ports from the BIOS
		data area, as this should correspond to the port numbering
		to which the user is accustomed.
		
		For each existing port, we determine its interrupt level in
		one of two ways:
			- consult the .ini file in the [parallel] category,
			  looking for port<n>. If it exists, the number is
			  taken as the interrupt level (0 means not to use
			  interrupts).
			- if no level specified, the port is assigned the
			  next available printer level: 7 if that's not
			  already assigned, or 5 (or 0 if both printer
			  interrupts are already assigned).

		Any port that does not exist has its ParallelPortData.PPD_base field
		left at 0.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelRealInit proc	far	uses bx, dx, es, ds, si
		.enter
		mov	si, offset lpt1
		
	;
	; Find out the machine type so we can decide if the alternate
	; printer interrupt is available. On a PC and PC/XT, interrupt
	; 5 is given to the fixed disk, so it can't be used for a
	; printer.
	;
		call	SysGetConfig
		mov	ds:machine, dh
	;
	; If we're on an MCA machine, we have to use a different common
	; interrupt routine to deal with interrupt chaining, which is available
	; on the MCA bus.
	; 
		test	al, mask SCF_MCA
		jz	figureDelay
		mov	ds:[interruptCommon], offset ParallelLevelInt

figureDelay:
		call	ParallelCalcDelay
		jc	done

		segmov	es, BIOS_DATA_SEG, bx
		mov	bx, offset BIOS_PRINTER_PORTS
		mov	ds:[numPorts], 0

		call	ParallelFindPorts

	;
	; If no ports around, no need for a watchdog (in fact, having one
	; causes random death...)
	;

		tst	ds:[deviceMap]
		jz	done			; carry clear

	;
	; Start up the watchdog timer to check our ports for errors
	;
EC <		segmov	es, ds		;Don't point at BIOS		>
		mov	ax, TIMER_ROUTINE_CONTINUAL
		mov	bx, segment ParallelWatchdog
		mov	si, offset ParallelWatchdog
		mov	cx, WATCHDOG_INTERVAL
		mov	di, cx
		mov	dx, ds		; Pass dgroup in ax when called
		call	TimerStart
		mov	ax, handle 0
		call	HandleModifyOwner			;Change owner of timer
		mov	ds:[watchdog], bx
		clc					;Signify no error
done:
		.leave
		assume	es:dgroup
		ret
ParallelRealInit endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                ParallelEnsureClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Make sure we're unhooked from the indicated interrupt vector

CALLED BY:      ParallelRealExit
PASS:           ds:di   = ParallelVectorData to reset, if necessary
RETURN:         es	= dgroup
DESTROYED:      Nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        ardeb   2/23/90         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelEnsureClosed proc near    uses    si, dx, ax
                .enter
                mov     si, ds:[di].PVD_port
                tst     si
                jz      done
        ;
        ; Shut off all interrupts for the port.
        ;
                mov     dx, ds:[si].PPD_base
                add     dx, offset PP_ctrl
		in	al, dx
		jmp	$+2		; I/O delay
		andnf	al, not mask PC_IEN
		out	dx, al
        ;
        ; Reset the vector.
        ;
		mov	al, ds:[si].PPD_irq
		segmov	es, ds
                call    SysResetDeviceInterrupt
		mov	ds:[si].PPD_vector, 0
		mov	ds:[di].PVD_port, 0
done:
                .leave
                ret
ParallelEnsureClosed endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelRealExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up driver state before exiting

CALLED BY:	ParallelExit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
       shut off the watchdog timer
       disable interrupts for any ports that have them enabled

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParallelRealExit proc	far
		.enter
		mov	bx, ds:[watchdog]
		tst	bx		; if no watchdog started, no port
					;  can be open.
		jz	done

		clr	ax		; 0 => continual
		call	TimerStop
		
		mov	di, offset primaryVec
		call	ParallelEnsureClosed
		mov	di, offset alternateVec
		call	ParallelEnsureClosed
		mov	di, offset weird1Vec
		call	ParallelEnsureClosed
		mov	di, offset weird2Vec
		call	ParallelEnsureClosed
done:
		.leave
		ret
ParallelRealExit endp

Init		ends
