COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Sys -- Interrupt Manipulation
FILE:		sysInterrupt.asm

AUTHOR:		Adam de Boor, May 17, 1989

ROUTINES:
	Name			Description
	----			-----------
	SysEnterInterrupt	Prevent context switches
	SysExitInterrupt	Allow pending context switches

	SysCatchInterrupt	Catch an arbitrary interrupt vector
	SysResetInterrupt	Replace an arbitrary interrupt vector
	SysCatchDeviceInterrupt	Catch an interrupt from a hardware device
	SysResetDeviceInterrupt	Replace the previous vector for same



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/17/89		Initial revision


DESCRIPTION:
	Functions for manipulating interrupt vectors and dealing with
	interrupts in geodes in general


	$Id: sysInterrupt.asm,v 1.1 97/04/05 01:15:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef PROTECTED_MODE
include	gpmi.def

.386 
endif

;
; Not needed globally -- just declare them here
;
idata segment
global	interruptCount:byte
global	intWakeUpAborted:byte

idata ends

if TRACK_INTERRUPT_SOURCES
udata	segment
intLog	fptr	20 dup(?)
udata	ends
endif



COMMENT @----------------------------------------------------------------------

FUNCTION:	SysCountInterrupt

DESCRIPTION:	Increment the count of interrupts that have happened.  This
		should be called by interrupt handlers that do not call
		SysEnterInterrupt

CALLED BY:	GLOBAL

PASS:
	none

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
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

SysCountInterrupt	proc	far
	push	ds
	LoadVarSeg	ds
	jmp	IntCommon

SysCountInterrupt	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SysEnterCritical

DESCRIPTION:	Block context switches until SysExitInterrupt is called
		WITHOUT incrementing the interrupt count

CALLED BY:	GLOBAL

PASS:
	none

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
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

SysEnterCritical	proc	far
	push	ds
	LoadVarSeg	ds
	inc	ds:[interruptCount]
if TRACK_INTERRUPT_COUNT and ERROR_CHECK
	cmp	ds:[interruptCount], 1
	jnz	notZeroToOne
	movdw	ds:[intCountStack], sssp
	mov	ds:[intCountType], INT_COUNT_SYS_ENTER_CRITICAL
	mov	ds:[intCountData], 0
notZeroToOne:
endif
	pop	ds
	ret

SysEnterCritical	endp

if	VERIFY_INTERRUPT_REGS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysEnterInterruptSaveRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysEnterInterruptSaveRegs proc	far
	call	PushAll
	mov	bp, sp
	pushdw	ss:[bp].PAF_fret
	mov	bp, ss:[bp].PAF_bp
	call	SysEnterInterrupt
	ret
SysEnterInterruptSaveRegs endp
endif
	

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysEnterInterrupt

DESCRIPTION:	Block context switches until SysExitInterrupt is called

CALLED BY:	GLOBAL

PASS:
	none

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
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

SysEnterInterrupt	proc	far
	push	ds
	LoadVarSeg	ds

if TRACK_INTERRUPT_SOURCES
	push	ax, bx, bp

SEIStack struct
    SEIS_bp	word
    SEIS_bx	word
    SEIS_ax	word
    SEIS_ds	word
    SEIS_retf	fptr.far
SEIStack ends

	mov	bp, sp
	mov	bx, ds:[curStats].SS_interrupts
	cmp	bx, length intLog
	jae	ugh
	shl	bx, 1
	shl	bx, 1
	mov	ax, ss:[bp].SEIS_retf.offset
	mov	ds:intLog[bx].offset, ax
	mov	ax, ss:[bp].SEIS_retf.segment
	mov	ds:intLog[bx].segment, ax
ugh:
	pop	ax, bx, bp
endif

	inc	ds:[interruptCount]
if TRACK_INTERRUPT_COUNT and ERROR_CHECK
	cmp	ds:[interruptCount], 1
	jnz	notZeroToOne
	movdw	ds:[intCountStack], sssp
	mov	ds:[intCountType], INT_COUNT_SYS_ENTER_INTERRUPT
	mov	ds:[intCountData], 0
notZeroToOne:
endif

	; Notify the power management driver that we need to exit the
	; idle state

	tst	ds:defaultDrivers.DDT_power
	jz	noPowerDriver
	tst	ds:[idleCalled]
	jz	noPowerDriver
	push	di
	mov	di, DR_POWER_NOT_IDLE
	call	ds:powerStrategy
	pop	di
noPowerDriver:

IntCommon	label	near

	inc	ds:[curStats].SS_interrupts
	pop	ds
	ret

SysEnterInterrupt	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SysExitInterrupt

DESCRIPTION:	Allow any pending context switches that were prevented
		because of SysEnterInterrupt

CALLED BY:	GLOBAL

PASS:
	none

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
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

if	CATCH_MISSED_COM1_INTERRUPTS

INT_STACK_SAVE		equ	30

idata	segment
exitIntCount	sword	-1
exitStack	word	INT_STACK_SAVE dup (0)
exitStatus	byte
exitCPUFlags	CPUFlags
idata	ends

LookForMissedCom1Interrupt	proc	far	uses ax, dx
	.enter
	mov	dx, 0x3fd
	in	al, dx
	test	al, 0x02
	jz	foo
	int	3
foo:
	.leave
	ret
LookForMissedCom1Interrupt	endp

endif

if	VERIFY_INTERRUPT_REGS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysExitInterruptVerifyRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
udata	segment
deathFrame	PushAllFrame	2 dup(<>)
deathCount	word	0
udata	ends
SysExitInterruptVerifyRegs proc	far
	; on stack	-> fret
	; 		   PushAllFrame w/ fret to caller of SysEnterInterrupt

	call	PushAll
	cld
	segmov	ds, ss, ax
	mov	es, ax
	mov	si, sp
	lea	di, ss:[si+size PushAllFrame]
	mov	cx, offset PAF_ret		; compare up to near ret
	repe	cmpsb
	jne	death

recover:
	call	PopAll

	; shift our return address up and arrange to clear the stack of the
	; previously-pushed registers, so we return the registers exactly
	; as we (not SysEnterInterrupt) got them (with the exception of flags)

	push	bp, ax
	mov	bp, sp
	movdw	(ss:[bp+8].PAF_fret), ({fptr.far}ss:[bp+4]), ax
	lea	ax, ss:[bp+8].PAF_fret	; ax <- sp we want
	mov	ss:[bp+4], ax	; store where we can pop it
	pop	sp, bp, ax

	call	SysExitInterrupt
	ret
death:
	; copy both frames in and up the number of trashed regs
	LoadVarSeg	es
	mov	si, sp
	mov	di, offset deathFrame
	mov	cx, size deathFrame
	rep	movsb
	inc	es:[deathCount]
	jmp	recover
SysExitInterruptVerifyRegs endp

endif

ifdef PROTECTED_MODE
;
; Esp refuses protected-mode instructions, so emit LSL AX, AX
; (0F 03 /r, modrm 11 000 000 = C0h) as raw bytes. ZF set if valid.
;
LSL_AX_AX	macro
	.inst	byte 0x0f
	.inst	byte 0x03
	.inst	byte 0xc0
endm

idata	segment
contextSwitching	byte	0
;
; Set when SysExitInterrupt had to drop a context switch because it
; cannot reach the interrupted frame on the DPMI host's interrupt stack
; (every host except NTVDM, e.g. HDPMI). The switch is then performed
; at the next safe point by SysPreemptIfPending.
;
preemptPending		byte	0
;
; HDPMI: selector of the host's ring-3 interrupt stub segment (its default
; PM interrupt vectors point there). Non-zero once HDPMI was detected; used
; by SysHDPMISetTrap to find the interrupted context on HDPMI's LPMS.
;
hdpmiIntSel		word	0
idata	ends
endif

SysExitInterrupt	proc	far
			
	push	ds
	pushf				; save interrupt state on entry
	LoadVarSeg	ds

if	CATCH_MISSED_COM1_INTERRUPTS
	cld
	push	cx, si, di, ds, es

	pushf
	pop	ds:[exitCPUFlags]

	push	ax, dx
	mov	dx, 0x3fd
	in	al, dx
	mov	ds:[exitStatus], al
	test	al, 0x02
	jz	foo
	int	3
foo:
	pop	ax, dx

	mov	cx, ds:[curStats].SS_interrupts
	mov	ds:[exitIntCount], cx
	segmov	es, ds
	mov	di, offset exitStack
	segmov	ds, ss
	mov	si, sp
	add	si, 10
	mov	cx, INT_STACK_SAVE
	rep	movsw
	pop	cx, si, di, ds, es
endif

	INT_OFF

	dec	ds:[interruptCount]
	jnz	SEI_done
	tst	ds:[intWakeUpAborted]
	jz	SEI_done
	mov	ds:[intWakeUpAborted], 0
ifndef PROTECTED_MODE
	; a potential wake-up was aborted because interrupt code was running
	; make sure that the highest priority thread is running

EC <	cmp	ds:[runQueue],0						>
EC <	ERROR_Z	SYS_EXIT_INTERRUPT_RUN_QUEUE_IS_ZERO			>

	; Notify the power management driver that a thread will be woken
	; up when we exit the interrupt

	push	ax
	tst	ds:defaultDrivers.DDT_power
	jz	noPowerDriver
	clr	ax
	xchg	al, ds:[idleCalled]
	tst	al
	jz	noPowerDriver
	push	di
	mov	di, DR_POWER_NOT_IDLE_ON_INTERRUPT_COMPLETION
	call	ds:powerStrategy
	pop	di
noPowerDriver:

	call	WakeUpRunQueue
	pop	ax

SEI_done:
	call	SafePopf	; restore initial interrupt state w/o
				;  tickling 286 bug
	pop	ds
	ret
SysExitInterrupt	endp

else ; PROTECTED_MODE

EC <	cmp	ds:[runQueue],0						>
EC <	ERROR_Z	SYS_EXIT_INTERRUPT_RUN_QUEUE_IS_ZERO			>

	;
	; HACK ALERT: DPMI requires interrupt handlers to return on the
	; same stack on which they are called.  However, we may need to
	; switch stack to that of the highest priority thread.  DPMI doesn't
	; describe the layout of the interrupt stack, leaving its layout up
	; to the implementor.  But by observation, we can figure out a few
	; useful tidbits:
	;
	; Note: These apply to the NTVDM DPMI (DOSX) only.
	;
	; If the interrupt occurred in protected mode, the stack will
	; look like this:
	;
	; SS:0ffeh	Flags (at point of interrupt)
	; SS:0ffch	CS (at point of interrupt)
	; SS:0ffah	IP (at point of interrupt)
	; SS:0ff8h	Flags     (normal interrupt frame)
	; SS:0ff6h	Return CS            "
	; SS:0ff4h TOS>	Return IP            "

	push	ax
	mov	ax, ss
	cmp	ax, 017fh
	pop	ax
	jne	SEI_tryHDPMI
	cmp	ss:[0ffch], 0c7h
	je	SEI_defer

SEI_switch	label near
	ForceRef SEI_switch
	ornf	ss:[0ffeh], mask CPU_TRAP
	inc	ds:[contextSwitching]
		
SEI_done:
	call	SafePopf	; restore initial interrupt state w/o
				;  tickling 286 bug
	pop	ds
	ret

SEI_tryHDPMI:
	call	SysHDPMISetTrap		; carry clear: switch scheduled
	jnc	SEI_done
SEI_defer:
	;
	; We can't redirect the interrupted context on this DPMI host.
	; Remember the switch so SysPreemptIfPending can do it as soon as
	; the interrupted thread reaches a safe point.
	;
	mov	ds:[preemptPending], TRUE
	jmp	SEI_done
SysExitInterrupt	endp

ExceptionFrame	STRUC
    except_retIP	word
    except_retCS	word
    except_error	word
    except_ip		word
    except_cs		word
    except_flags	word
    except_sp		word
    except_ss		word
ExceptionFrame	ENDS


SysContextSwitch	proc	far
	pushf
	push	ss:[TPD_SCSVector].segment
	push	ss:[TPD_SCSVector].offset

SCS_iretSetup	label	near
	INT_OFF
	push	ds, ax
ifdef PROTECTED_MODE
	;
	; Swat's stub jumps here for single steps that aren't its own,
	; with the trapped flags (TF still set) in the frame. Clear TF, or
	; the iret below keeps single stepping every instruction.
	; Stack: ax, ds, ip, cs, flags
	;
	push	bp
	mov	bp, sp
	andnf	{word}ss:[bp+10], not mask CPU_TRAP
	pop	bp
endif
	LoadVarSeg	ds
	tst	ds:[contextSwitching]
	jz	done
	dec	ds:[contextSwitching]
	call	SysCheckContextSwitch	; carry set: not here, deferred
	jc	done
	
	; a potential wake-up was aborted because interrupt code was running
	; make sure that the highest priority thread is running

	; Notify the power management driver that a thread will be woken
	; up when we exit the interrupt

	tst	ds:defaultDrivers.DDT_power
	jz	noPowerDriver
	clr	ax
	xchg	al, ds:[idleCalled]
	tst	al
	jz	noPowerDriver
	push	di
	mov	di, DR_POWER_NOT_IDLE_ON_INTERRUPT_COMPLETION
	call	ds:powerStrategy
	pop	di
noPowerDriver:

	call	SysWakeUpRunQueueSaveAll	; this preempts arbitrary code
done:
	pop	ds, ax
	iret
SysContextSwitch	endp

;
; WakeUpRunQueue is near; IRQCode needs a far way to it.
;
SysWakeUpRunQueueFar	proc	far
	call	WakeUpRunQueue
	ret
SysWakeUpRunQueueFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysPreemptIfPending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a context switch that SysExitInterrupt had to defer.

CALLED BY:	SysUnlockCommon, SysVSemCommon, MemUnlock
		(PROTECTED_MODE only)

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing, not even flags

PSEUDO CODE/STRATEGY:
	In real mode, SysExitInterrupt switches to a higher-priority thread
	that an interrupt made runnable (input manager, time slicing, ...).
	In protected mode that only works on NTVDM, whose interrupt stack
	layout is known. On other hosts the switch is deferred and done here.

	This is only safe where the real-mode kernel could have been
	preempted as well, so we require:
	    - interrupts enabled at the call (not in a critical section)
	    - not running interrupt code (interruptCount == 0)
	    - a real thread (not the kernel/idle context)
	    - running on that thread's own stack (not a DPMI host stack)
	Otherwise the flag stays set and a later safe point handles it.

	The fast path is a single byte test.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Esp refuses protected-mode instructions, so emit VERR AX
; (0F 00 /4, modrm 11 100 000 = E0h) as raw bytes.
; Sets ZF if the selector in AX is valid and readable.
;
VERR_AX	macro
	.inst	byte 0x0f
	.inst	byte 0x00
	.inst	byte 0xe0
endm

SysPreemptIfPending	proc	near
	pushf
	push	ds, ax
	LoadVarSeg	ds, ax
	tst	ds:[preemptPending]
	jz	done

	;
	; Interrupts must have been on at the call site.
	; Stack: ax, ds, flags
	;
	push	bp
	mov	bp, sp
	test	{word}ss:[bp+6], mask CPU_INTERRUPT
	pop	bp
	jz	done

	INT_OFF
	tst	ds:[interruptCount]
	jnz	done
	mov	ax, ds:[currentThread]
	tst	ax
	jz	done
	cmp	ax, ss:[TPD_threadHandle]
	jne	done

	mov	ds:[preemptPending], 0

	;
	; Same as SysContextSwitch: tell the power driver we're not idle.
	;
	tst	ds:defaultDrivers.DDT_power
	jz	noPowerDriver
	clr	ax
	xchg	al, ds:[idleCalled]
	tst	al
	jz	noPowerDriver
	push	di
	mov	di, DR_POWER_NOT_IDLE_ON_INTERRUPT_COMPLETION
	call	ds:powerStrategy
	pop	di
noPowerDriver:

	;
	; The thread switch only saves the 16-bit registers (plus ds/es)
	; unless SUPPORT_32BIT_DATA_REGS is set, which it isn't for every
	; product. Our callers (SysUnlockCommon, MemUnlock, ...) promise to
	; destroy nothing, and PM kernel code keeps 32-bit values and fs/gs
	; live across them, so save the full state ourselves.
	;
	pushad
	push	fs, gs

	call	WakeUpRunQueue		; may switch threads; we come back
					;  here when this thread runs again
	;
	; fs/gs may hold selectors of blocks another thread freed while we
	; were switched out; don't fault on reloading them.
	;
	pop	ax			; ax <- saved gs
	VERR_AX
	jz	gsOK
	clr	ax
gsOK:
	mov	gs, ax
	pop	ax			; ax <- saved fs
	VERR_AX
	jz	fsOK
	clr	ax
fsOK:
	mov	fs, ax
	popad
done:
	pop	ds, ax
	call	SafePopf		; restore caller's flags
	ret
SysPreemptIfPending	endp

;
; New code outside kcode (kcode is at its 64K limit).
;
kcode	ends
IRQCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysHDPMISetTrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Schedule a context switch for the interrupted code when
		running under HDPMI, like the NTVDM hack in SysExitInterrupt.

CALLED BY:	SysExitInterrupt (outermost interrupt, on its stack)
PASS:		ds	= kdata
		ss	= stack the interrupt handler runs on
RETURN:		carry clear if TF was set in the interrupted context
		carry set if the layout isn't HDPMI's (caller defers)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	HDPMI runs IRQ handlers for interrupted ring-3 protected mode code
	on its 4K locked PM stack (LPMS). The top of the LPMS then holds
	(see HDPMI.ASM, lpms_call_int and rpmstacki):

		SS:0ffch	CS of interrupted code (+ hiword EFL)
		SS:0ff8h	EIP of interrupted code
		SS:0ff6h	Flags	\
		SS:0ff4h	_INTSEL_ > outermost IRET frame, returns to
		SS:0ff2h	_RTINT_	/  the host's int 30h stub

	The flags the handler IRETs with become the flags of the
	interrupted code ("TF preserved"), so setting TF at 0ff6h gives
	the same single step trap as on NTVDM. If the IRQ came from real
	mode or host code, the CS at 0ffch is _INTSEL_ itself.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysHDPMISetTrap	proc	far
	tst	ds:[hdpmiIntSel]
	jz	notHDPMI
	push	ax
	mov	ax, ss
	LSL_AX_AX			; ax <- limit of SS, ZF if valid
	jnz	notHDPMIPop
	cmp	ax, 0fffh		; LPMS is 4K
	jne	notHDPMIPop
	mov	ax, ds:[hdpmiIntSel]
	cmp	ss:[0ff4h], ax		; outermost frame returns to host?
	jne	notHDPMIPop
	cmp	ss:[0ffch], ax		; interrupted code is host/real mode?
	je	notHDPMIPop
	;
	; Only preempt arbitrary code where it buys something: a waiting
	; thread with higher priority (lower value) than the current one
	; (input -> IM thread). Equal priorities rotate at safe points.
	;
	push	bx, si
	mov	bx, ds:[currentThread]
	tst	bx
	jz	noHigher
	mov	al, ds:[bx][HT_curPriority]
	mov	si, ds:[runQueue]
scanRunQueue:
	tst	si
	jz	noHigher
	cmp	al, ds:[si][HT_curPriority]
	ja	higherWaiting		; waiting thread is more important
	mov	si, ds:[si][HT_nextQThread]
	jmp	scanRunQueue
noHigher:
	pop	bx, si
	jmp	notHDPMIPop
higherWaiting:
	pop	bx, si
	;
	; Don't arm the trap on a Swat breakpoint (int 3 = 0cch): Swat's
	; stub single-steps over that same instruction itself (bpt skip,
	; BptSkipRecover) and would take our trap for its own.
	;
	push	es, bx
	mov	ax, ss:[0ffch]		; CS of interrupted code
	VERR_AX
	jnz	trapOK			; not readable: can't be a breakpoint
	mov	es, ax
	mov	bx, ss:[0ff8h]		; IP of interrupted code
	cmp	{byte}es:[bx], 0cch
	jne	trapOK
	pop	es, bx
	jmp	notHDPMIPop
trapOK:
	pop	es, bx
	pop	ax
	ornf	{word}ss:[0ff6h], mask CPU_TRAP
	inc	ds:[contextSwitching]
	clc
	ret

notHDPMIPop:
	pop	ax
notHDPMI:
	stc
	ret
SysHDPMISetTrap	endp

SysContextSwitchReflector	proc	far
	;
	; Load DS with our dgroup.
	;
		push	ds, ax, bx, bp, si
	;
	; Save CS:IP and error code of excepting process.
	;
		mov	bp, sp			; ss:bp+10 = ExceptionFrame
		add	bp, 10			; ss:bp = ExceptionFrame
	;
	; Only redirect if this is our trap and the code runs on the
	; current thread's stack (TPD_SCSVector lives there). Otherwise
	; leave the switch to the next safe point.
	;
		LoadVarSeg	ds, ax
		tst	ds:[contextSwitching]
		jz	reflectNoSwitch
		mov	bx, ds:[currentThread]
		tst	bx
		jz	reflectDefer
		mov	ds, ss:[bp].except_ss
		cmp	bx, ds:[TPD_threadHandle]
		jne	reflectDefer
		mov	ax, ss:[bp].except_cs
		mov	ds:[TPD_SCSVector].segment, ax
		mov	ax, ss:[bp].except_ip
		mov	ds:[TPD_SCSVector].offset, ax
		and	ss:[bp].except_flags, not mask CPU_TRAP
	;
	; Change CS:IP to SysContextSwitch.
	;
		mov	ss:[bp].except_cs, segment SysContextSwitch
		mov	ss:[bp].except_ip, offset SysContextSwitch
		jmp	reflectDone

reflectDefer:
		LoadVarSeg	ds, ax
		dec	ds:[contextSwitching]
		mov	ds:[preemptPending], TRUE
reflectNoSwitch:
		and	ss:[bp].except_flags, not mask CPU_TRAP
reflectDone:
		pop	ds, ax, bx, bp, si
		retf
SysContextSwitchReflector	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCheckContextSwitch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide whether the single step trap may switch threads here.

CALLED BY:	SysContextSwitch (also reached from Swat's stub via
		SCS_iretSetup)
PASS:		ds	= kdata, interrupts off
		stack	= ax, ds, ip, cs, flags of the trapped code
RETURN:		carry clear if WakeUpRunQueue may be called
		carry set if not: preemptPending is set instead
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The trap fires one instruction after the interrupt returned, which
	may have been a CLI, an INT into interrupt code, or code running on
	a non-thread stack. Real mode couldn't have preempted there either.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCheckContextSwitch	proc	far
	push	bp
	mov	bp, sp
	;
	; bp+0 bp, +2/+4 return address, +6 ax, +8 ds, +10 ip, +12 cs,
	; +14 flags of the trapped code
	;
	test	{word}ss:[bp+14], mask CPU_INTERRUPT
	pop	bp
	jz	defer
	tst	ds:[interruptCount]
	jnz	defer
	push	ax
	mov	ax, ds:[currentThread]
	tst	ax
	jz	deferPop
	cmp	ax, ss:[TPD_threadHandle]
	pop	ax
	jne	defer
	clc
	ret

deferPop:
	pop	ax
defer:
	mov	ds:[preemptPending], TRUE
	stc
	ret
SysCheckContextSwitch	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysWakeUpRunQueueSaveAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	WakeUpRunQueue for a thread preempted at an arbitrary
		instruction (single step trap from SysExitInterrupt).

CALLED BY:	SysContextSwitch
PASS:		ds	= kdata, interrupts off
RETURN:		nothing
DESTROYED:	nothing (WakeUpRunQueue destroys ax)

PSEUDO CODE/STRATEGY:
	The thread switch only saves the 16-bit registers and ds/es unless
	SUPPORT_32BIT_DATA_REGS is set. In real mode that's enough, but
	in protected mode drivers (e.g. VGA16) keep FS and 32-bit values
	live, and the thread we switch to (the IM thread calling the video
	driver to move the pointer) changes them. Save everything here.

	fs/gs may hold selectors of blocks freed while we were switched
	out; don't fault on reloading them.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysWakeUpRunQueueSaveAll	proc	far
	pushad
	push	fs, gs
	call	SysWakeUpRunQueueFar
	pop	ax			; ax <- saved gs
	VERR_AX
	jz	gsOK
	clr	ax
gsOK:
	mov	gs, ax
	pop	ax			; ax <- saved fs
	VERR_AX
	jz	fsOK
	clr	ax
fsOK:
	mov	fs, ax
	popad
	ret
SysWakeUpRunQueueSaveAll	endp

IRQCode	ends
kcode	segment

endif ; PROTECTED_MODE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCatchInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept interrupts of the given type

CALLED BY:	GLOBAL
PASS:		AX	= interrupt number
		BX:CX	= routine for interrupt to invoke
		ES:DI	= place to store previous vector. The vector
			  is suitable for performing a FAR jump through
			  it (even in protected mode).
RETURN:		Nothing
DESTROYED:	AX, DI, BX

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/89		Initial version
	dhunter	11/19/00	GPMI version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCatchInterrupt proc	far
		pushf

if	0	;Can cause a deadlock if this is called at interrupt time
EC <		push	bx, si					>
EC <		mov	si, cx					>
EC <		call	ECAssertValidTrueFarPointerXIP		>
EC <		movdw	bxsi, esdi				>
EC <		call	ECAssertValidTrueFarPointerXIP		>
EC <		pop	bx, si					>
endif
		push	ds
ifdef PROTECTED_MODE
		push	cx, edx
		push	bx

		cld

		INT_OFF			; No interrupts while changing vector

		push	cx
		mov	bl, al
		call	GPMIGetInterruptHandlerFar	; cx:edx = old vector
		
		mov	es:[di], dx	; Store offset portion in passed
					;  buffer.
		mov	es:[di+2], cx	; Store segment portion
		pop	dx
		pop	cx		; cx:dx = new vector
		call	GPMISetInterruptHandlerFar

		pop	cx, edx
else ; PROTECTED_MODE
		push	bx
		clr	bx		; Interrupt table at segment 0
		mov	ds, bx

		shl	ax, 1		; Vectors are dwords
		shl	ax, 1
		mov	bx, ax

		cld

		INT_OFF			; No interrupts while changing vector

		mov	ax, ds:[bx]
		stosw			; Store offset portion in passed
					;  buffer.
		mov	ds:[bx], cx	; Store passed offset
		mov	ax, ds:2[bx]
		stosw			; Store segment portion
		pop	ds:2[bx]	; Store passed segment
endif ; PROTECTED_MODE
		jmp	popDS_popf_ret
SysCatchInterrupt endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysResetInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the previous value of an interrupt vector

CALLED BY:	GLOBAL
PASS:		AX	= interrupt number
		ES:DI	= dword where previous vector was stored
RETURN:		Nothing
DESTROYED:	AX

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/89		Initial version
	dhunter	11/19/00	GPMI version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysResetInterrupt proc	far
		pushf

if	0	;Can cause a deadlock if this is called at interrupt time
EC <		push	bx, si				>
EC <		movdw	bxsi, esdi			>
EC <		call	ECAssertValidTrueFarPointerXIP	>
EC <		pop	bx, si				>
endif

		push	ds
		push	bx
ifdef PROTECTED_MODE
		push	cx, edx

		INT_OFF
		mov	bl, al			; al = interrupt
		mov	dx, es:[di]
		mov	cx, es:[di+2]		; cx:dx = old vector
		call	GPMISetInterruptHandlerFar

		pop	cx, edx
else

		clr	bx		; Point DS at interrupt table
		mov	ds, bx

		shl	ax, 1		; Point BX at the interrupt vector
		shl	ax, 1
		mov	bx, ax

		INT_OFF
		mov	ax, es:[di]	; Fetch offset portion
		mov	ds:[bx], ax	; Store it back
		mov	ax, es:2[di]	; Fetch segment portion
		mov	ds:2[bx], ax	; Store it back
endif
		pop	bx

popDS_popf_ret	label	near
		pop	ds
		call	SafePopf	; Restore IF w/o possible interrupt
					;  from buggy '286
		ret
SysResetInterrupt endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCatchDeviceInterruptInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a hardware interrupt level, catch the vector that
		implies.

CALLED BY:	EXTERNAL
PASS:		AX	= interrupt level
		BX:CX	= routine to be invoked
		ES:DI	= place to store previous vector
RETURN:		Nothing
DESTROYED:	AX, DI, BX

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCatchDeviceInterruptInternal proc	far

if	0	;Can cause deadlock if this is called at interrupt level
EC <		push	bx, si					>
EC <		mov	si, cx					>
EC <		call	ECAssertValidTrueFarPointerXIP		>
EC <		movdw	bxsi, esdi				>
EC <		call	ECAssertValidTrueFarPointerXIP		>
EC <		pop	bx, si					>
endif
		
		push	dx
		mov	dx, offset SysCatchInterrupt
		GOTO	CatchResetCommon, dx
SysCatchDeviceInterruptInternal endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysResetDeviceInterruptInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a hardware interrupt level, reset the vector that
		implies.

CALLED BY:	EXTERNAL
PASS:		AX	= interrupt level
		ES:DI	= place where previous vector was stored
RETURN:		Nothing
DESTROYED:	AX

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysResetDeviceInterruptInternal proc	far

if	0	;Causes a deadlock, if this code is called at interrupt time
EC <		push	bx, si				>
EC <		movdw	bxsi, esdi			>
EC <		call	ECAssertValidTrueFarPointerXIP	>
EC <		pop	bx, si				>
endif
		
		push	dx
		mov	dx, offset SysResetInterrupt
		FALL_THRU	CatchResetCommon, dx
SysResetDeviceInterruptInternal endp

	; dx = offset of routine to call

CatchResetCommon	proc	far

if		HARDWARE_INT_CONTROL_8259
		cmp	ax, 8
		jge	SRDICheck2nd
		add	ax, 8	; Interrupt controller 1 starts with vector 8
				;  in real mode
		jmp	common
SRDICheck2nd:
		;
		; Make sure we're running on an AT, as that's the only thing
		; that's got two controllers.
		;
EC <		push	ds						>
EC <		LoadVarSeg ds						>
EC <		test	ds:sysConfig,mask SCF_2ND_IC			>
EC <		ERROR_Z NO_SUCH_INTERRUPT				>
EC <		pop	ds						>
		add	ax, 70h-8; Interrupt controller 2 starts with vector
				;  70h in real mode, but adjust for level
				;  starting at 8
common:
		push	cs
		call	dx
else
	;------------------------------------------------------------------
	;	CUSTOM INTERRUPT CONTROLLER CHIP
	;
	.err <setup interrupt vector for custom controller>

endif
		FALL_THRU_POP	dx
		ret
CatchResetCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCatchDeviceInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Catch a hardware interrupt with a handler defined in a geode
		other than the kernel.

CALLED BY:	GLOBAL
PASS:		ax	= interrupt level
		bx:cx	= routine to be invoked
		es:di	= place to store previous vector
RETURN:		nothing
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Put the passed routine at Irq?OldVector+1 rather than segment 0, such
	that when hardware interrupt happens the external vector is called
	by Irq?Intercept rather than invoked directly.  This prevents context
	switching to another thread that can possibly unload the geode
	containing the interrupt handler before the current thread returns
	from the handler.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCatchDeviceInterrupt	proc	far

	pushf
	push	ds

	push	bx
	call	CatchResetLocateVectorCommon
	mov	ax, cx
	xchg	ds:[bx].offset, ax	; Store passed offset
	stosw				; Store offset portion in passed buffer
	pop	ax
	xchg	ds:[bx].segment, ax	; Store passed segment
	stosw				; Store segment portion in passed
					;  buffer
ifdef PROTECTED_MODE
	mov	bx, ds
	pop	ds			; ds gets invalid here, so 
					; revert it first
	call	GPMIFreeAliasFar
	
	call	SafePopf	; Restore IF w/o possible interrupt
					;  from buggy '286
	ret
else
	jmp	popDS_popf_ret
endif
SysCatchDeviceInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysResetDeviceInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unhook a hardware interrupt handler that was hooked up with
		SysCatchDeviceInterrupt.

CALLED BY:	GLOBAL
PASS:		ax	= interrupt level
		es:di	= place where previous vector was stored
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysResetDeviceInterrupt	proc	far
ifdef PROTECTED_MODE
	pushf
	push	bx
	push	ds

	call	CatchResetLocateVectorCommon
	movdw	ds:[bx], es:[di], ax

	mov	bx, ds
	pop	ds			; ds gets invalid here, so 
					; revert it first
	call	GPMIFreeAliasFar
	pop	bx

	call	SafePopf	; Restore IF w/o possible interrupt
					;  from buggy '286
	ret
else
	pushf
	push	ds

	push	bx
	call	CatchResetLocateVectorCommon
	movdw	ds:[bx], es:[di], ax
	pop	bx

	jmp	popDS_popf_ret
endif
SysResetDeviceInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CatchResetLocateVectorCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the place where the hardware interrupt vector is stored.

CALLED BY:	(INTERNAL) SysCatchDeviceInterrupt, SysResetDeviceInterrupt
PASS:		ax	= interrupt level
RETURN:		ds:bx	= place where vector is stored
		direction flag clear
		interrupt off
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/28/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CatchResetLocateVectorCommon	proc	near
ifdef PROTECTED_MODE
	mov	bx, segment IRQCode
	call	GPMIAliasFar		;bx = writable alias
	mov	ds, bx
else
	LoadVarSeg	ds
endif
	; Do not use "Assert" here, since it uses "popf" which is unsafe.
EC <	cmp	ax, FIRST_IRQ_INTERCEPT_LEVEL				>
EC <	ERROR_B	NO_SUCH_INTERRUPT					>
EC <	cmp	ax, LAST_IRQ_INTERCEPT_LEVEL				>
EC <	ERROR_A	NO_SUCH_INTERRUPT					>

		CheckHack <LAST_IRQ_INTERCEPT_LEVEL le 255>
		CheckHack <IRQ_INTERCEPT_SIZE le 255>
	mov	ah, IRQ_INTERCEPT_SIZE
	mul	ah
	add	ax, (- FIRST_IRQ_INTERCEPT_LEVEL * IRQ_INTERCEPT_SIZE) \
			+ offset FIRST_IRQ_INTERCEPT \
			+ IRQ_INTERCEPT_OLD_VECTOR_OFFSET
	mov_tr	bx, ax			; ds:bx = vector

	cld
	INT_OFF				; No interrupts while changing vector

	ret
CatchResetLocateVectorCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysResetIntercepts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the hardware intercepts just before exiting

CALLED BY:	EndGeos
PASS:		ds	= idata
RETURN:		nothing
DESTROYED:	ax, bx, cx, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysResetIntercepts proc	near
		.enter
	;
	; Use lastIntercept to see if InitSys has been called...
	;
		mov	cx, ds:[lastIntercept]
		jcxz	done

		segmov	es, ds
		mov	ax, FIRST_IRQ_INTERCEPT_LEVEL
		mov	di, offset FIRST_IRQ_INTERCEPT + IRQ_INTERCEPT_DOS_VECTOR_OFFSET
interceptLoop:
		push	ax
		call	SysResetDeviceInterruptInternal
		pop	ax
		add	di, IRQ_INTERCEPT_SIZE
		inc	ax
		cmp	ax, ds:[lastIntercept]
		jbe	interceptLoop


if	not HARDWARE_INT_CONTROL_8259

	;--------------------------------------------------------------------
	;	CUSTOM INTERRUPT CONTROLLER CODE
	;

endif

done:
		.leave
		ret
SysResetIntercepts endp

DosapplCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysSwapIntercepts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap the existing hardware interrupt vectors with those
		stored in the various little hardware-intercept routines.
CALLED BY:	DosExecSuspend, DosExecUnsuspend
PASS:		ds 	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, es, di

PSEUDO CODE/STRATEGY:
		You wouldn't think this would be necessary, but TaskMAX has
		a really bad interaction between our having intercepted the
		interrupt for a network card and its trying to figure out
		what the working directories are for the network drives. I
		thought this was fixed before TaskMAX shipped, but it seems
		to have re-appeared.
		
		In any case, we simply swap all the hardware interrupt
		vectors with the saved values in the intercept routines.
		When called from spend, this restores the vectors
		to where they were when PC/GEOS started up. When called
		from DosExecUnsuspend, it restores them to what they were
		when the system was suspended.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysSwapIntercepts proc near
ifndef PROTECTED_MODE  ; Is this still necessary? -dhunter 11/16/00
		.enter
		clr	ax
		mov	es, ax
		mov	si, offset FIRST_IRQ_INTERCEPT + \
				IRQ_INTERCEPT_DOS_VECTOR_OFFSET
		mov	cx, ds:[lastIntercept]
		sub	cx, FIRST_IRQ_INTERCEPT_LEVEL
		inc	cx	; lastIntercept is inclusive, so we need to
				;  up the loop count by 1 to get the right
				;  number of vectors to mangle -- ardeb 2/23/94
		mov	di, (FIRST_IRQ_INTERCEPT_LEVEL+8)*dword
suspendLoop:
	;
	; Fetch the current value and exchange it with the value stored in
	; our little intercept hook, thereby restoring all hardware interrupts
	; to where they were on start-up.
	; 
		INT_OFF
		lodsw
		xchg	es:[di].offset, ax
		mov	ds:[si-2], ax
		lodsw
		xchg	es:[di].segment, ax
		mov	ds:[si-2], ax
		INT_ON

		add	di, 4
		cmp	di, (8+8)*dword
		jne	nextIntercept
		mov	di, 70h*dword
nextIntercept:
		add	si, IRQ_INTERCEPT_SIZE-4
		loop	suspendLoop

if	not HARDWARE_INT_CONTROL_8259


endif
		.leave
endif
		ret
SysSwapIntercepts endp

DosapplCode	ends
