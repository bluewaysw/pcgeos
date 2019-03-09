COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		intelbpt.asm

AUTHOR:		Eric Weber, May 19, 1997

ROUTINES:
	Name			Description
	----			-----------
    INT IBpt_ReadRegs		Read the Intel debug registers

    INT IBpt_WriteRegs		Write the Intel debug registers

    INT IBpt_Skip		Step over a hardware breakpoint

    INT IBptSkipRecover		Recover from a skipped hardware breakpoint

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	5/19/97   	Initial revision


DESCRIPTION:
		
	Code for handling x86 hardware breakpoints

	$Id: intelbpt.asm,v 1.1 97/05/23 07:55:10 weber Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		include	stub.def

scode	segment
		assume	ds:cgroup, es:cgroup, ss:sstack

if INTEL_BREAKPOINT_SUPPORT
ibptSkipDesc	nptr.BptDesc	; BptDesc being skipped, if known
ibptSkipMask1	byte		; Place to save interrupt controller mask 1
				; to be restored when the step is complete.
ibptSkipIF	byte		; Interrupt mask before skip
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IBpt_ReadRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the Intel debug registers

CALLED BY:	INTERNAL Rpc_Wait
PASS:		DebugRegsArgs in CALLDATA
		bp - state block
RETURN:		DebugRegsArgs filled in
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	DR6 and DR7 are part of the state block
	DR5 and DR4 are undefined
	DR3..DR0    can be read directly

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	5/19/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IBpt_ReadRegs	proc	near
if INTEL_BREAKPOINT_SUPPORT
		DPC	DEBUG_HWBRK, 'r'
		pushf
		dsi
		PointESAtStub
		mov	di, offset rpc_ToHost

		mov	eax, ss:[bp].state_dr7
		stosd
		mov	eax, ss:[bp].state_dr6
		stosd
		movsp	eax, dr3
		stosd
		movsp	eax, dr2
		stosd
		movsp	eax, dr1
		stosd
		movsp	eax, dr0
		stosd
		popf

		mov	si, offset rpc_ToHost

		mov	cx, size DebugRegsArgs
else ; not INTEL_BREAKPOINT_SUPPORT
		clr	cx
endif
		call	Rpc_Reply
		ret
		
IBpt_ReadRegs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IBpt_WriteRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the Intel debug registers

CALLED BY:	INTERNAL Rpc_Wait
PASS:		DebugRegsArgs in CALLDATA
		bp - state block
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	DR6 and DR7 are part of the state block
	DR5 and DR4 are undefined
	DR3..DR0    can be written directly
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	5/19/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IBpt_WriteRegs	proc	near
if INTEL_BREAKPOINT_SUPPORT
		mov	si, offset CALLDATA
		DPC	DEBUG_HWBRK, 'w'
if 0
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr7.high
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr7.low
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr6.high
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr6.low
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr3.high
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr3.low
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr2.high
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr2.low
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr1.high
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr1.low
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr0.high
		DPW	DEBUG_HWBRK, cs:[si].DRA_dr0.low
endif
		pushf
		dsi
		PointDSAtStub
		lodsd
		mov	ss:[bp].state_dr7, eax
		lodsd
		mov	ss:[bp].state_dr6, eax
		lodsd
		movsp	dr3, eax
		lodsd
		movsp	dr2, eax
		lodsd
		movsp	dr1, eax
		lodsd
		movsp	dr0, eax
		popf
endif
		clr	cx
		call	Rpc_Reply
		ret
IBpt_WriteRegs	endp

if INTEL_BREAKPOINT_SUPPORT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IBpt_CheckType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Are we at an instruction breakpoint?

CALLED BY:	INTERNAL ResumeFromInterrupt
PASS:		ss:bp  - state block
RETURN:		zero flag set if not in an instruction breakpoint
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If, for any n in 0..3, Bn = 1 and RWn = 0, we are at an instruction
	breakpoint.

	By repetitive shift and logic operations, we compress the RWn fields
	into a 4-bit mask which aligns with the Bn fields.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	5/22/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IBpt_CheckType	proc	near
	;
	; load up the state register
	;
	; the high word of dr7 has 4 bits for each breakpoint, of which
	; the lower 2 bits are the RWn field
	;
	; see also declaration of DR7Low
	;
		mov	ax, ss:[bp].state_dr7.high
	;
	; combine the two bits of each RWn field, and clear out all
	; other bits
	;
	; in theory, we could skip the first three instructions of
	; this block since 10 is not a valid bit combination, but
	; we'll allow for that case just to be safe
	;
	;
		mov	bx, ax
		shr	bx
		or	ax, bx
		and	ax, 1111h
	;
	; concatenate RW3 with RW2 and RW1 with RW0
	;
		mov	bx, ax
		shr	bx, 3
		or	ax, bx
	;
	; concatenate RW3RW2 with RW1RW0
	;
		mov	bx, ax
		shr	bx, 6
		or	ax, bx
	;
	; invert the bits so 1=instruction and 0=data
	;
		xor	al, 0fh
	;
	; compare this to the mask of breakpoints taken, in the lower
	; 4 bits of DR6
	;
		mov	bx, ss:[bp].state_dr6.low
		and	al, bl
		test	al, 0fh
		ret
IBpt_CheckType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IBpt_Skip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Step over a hardware breakpoint

CALLED BY:	INTERNAL 
PASS:		ss:bp - state block
		ds = cs
RETURN:		carry set if instruction emulated
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	ardeb		11/18/91	Initial version
	weber   	5/19/97    	Hardware breakpoint version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IBpt_Skip	proc	near
	.enter
	DPC DEBUG_HWBRK, 'S', inv
	;
	; See if the thing is a software interrupt of some sort. If so, we
	; need to emulate it, as 286 and later processors turn off the TF
	; early in the handling of INT so the trap isn't actually taken
	; until the interrupt returns.
	;
	; We also take care of emulating PUSHF and IN AL, 21h instructions
	; to avoid having to clean up after having executed them.
	;
		CheckHack <offset state_cs eq offset state_ip+2>
		les	di, {fptr}ss:[bp].state_ip
	DPW DEBUG_HWBRK, es
	DPW DEBUG_HWBRK, di
		mov	ax, es:[di]
	DPW DEBUG_HWBRK, ax
		cmp	al, 0xcd	; two-byte software interrupt?
		je	emulateInterrupt
		cmp	al, 0xcc	; breakpoint?
		je	breakpoint

		cmp	ax, 0x21e4	; byte IN from 21h?
		je	emulatePIC1Read
		cmp	al, 0x9c	; pushf?
		je	emulatePushf
		
		cmp	al, 0xfa	; CLI?
		je	emulateIF
		cmp	al, 0xfb	; STI?
		je	emulateIF
		jmp	setupForSkip
	;--------------------
emulateIF:
		andnf	[bp].state_flags, not IFlag	; assume CLI
		test	al, 1			; CLI (0xfa vs. 0xfb for STI)?
		jz	emulatedIncIP		; yes -- done
		ornf	ss:[bp].state_flags, IFlag
		jmp	emulatedIncIP
	;--------------------
breakpoint:
		mov	al, RPC_HALT_BPT
		inc	ss:[bp].state_ip	; pretend bpt hit
		segmov	es, ds
		mov	ds:[ibptSkipDesc], 0	; act as if BptSkipRecover
						;  was hit... (never set
						;  bptSkipAddr, but caller
						;  might have set this beast)
		jmp	IRQCommon_StoreHaltCode
	;--------------------
emulatePushf:
		cmp	ss:[bp].state_ss, sstack
		je	setupForSkip		; can't do this on stub stack

	;call	BptStore		; restore breakpoint now
		mov	es, ss:[bp].state_ss
		mov	di, ss:[bp].state_sp	; es:di <- ss:sp
		dec	di
		dec	di			; room for push...
		mov	ax, ss:[bp].state_flags
		andnf	ax, NOT TFlag 		; Clear TF
		mov	es:[di], ax		; push flags
		mov	ss:[bp].state_sp, di	; store new sp
		jmp	emulatedIncIP
	;--------------------
emulatePIC1Read:
	;call	BptStore		; restore breakpoint now
		mov	al, ss:[bp].state_PIC1
		mov	ss:[bp].state_ax.low.low, al
		inc	ss:[bp].state_ip	; two-byte instruction just
						;  emulated
		.assert	$ eq emulatedIncIP
emulatedIncIP:
		inc	ss:[bp].state_ip
	;
	; Restore ES to scode and continue the machine normally, without
	; messing with single-stepping or the step vector.
	; 
emulated:
		segmov	es, ds
		mov	ds:[ibptSkipDesc], 0	; act as if BptSkipRecover
						;  was hit... (never set
						;  bptSkipAddr, but caller
						;  might have set this beast)
		DPC DEBUG_HWBRK, 'e'
		stc
done:
		.leave
		ret
	;--------------------
emulateInterrupt:
		cmp	ss:[bp].state_ss, sstack
		je	setupForSkip		; can't do this on stub stack

	;
	; Stuff the breakpoint back at the instruction start.
	; 
	;		push	ax
	;		call	BptStore
	;		pop	ax
		call	EmulateInterrupt
		jmp	emulated
	;--------------------
setupForSkip:
	;
	; Re-vector the single-step trap to our own routine.
	; 
                push    dx
                mov     dx, offset BptSkipRecover
                call    SetStepHandler
                pop     dx
	;
	; Go do the other stuff associated with continuing
	; 
		mov	al, [bp].state_PIC1
		mov	ds:[ibptSkipMask1], al
		or	[bp].state_PIC1, TIMER_MASK; Keep timer interrupt OFF
						   ; so the thread won't c-switch
		or	[bp].state_flags, TFlag	; Set trace bit on return.
	;
	; Save the interrupt flag and clear it out of the saved flags.
	; This is to prevent the processor from taking an interrupt
	; upon return, executing the interrupt routine, and returning
	; with RF clear (16-bit interrupts won't save the RF flag).
	;
		mov	al, [bp].state_flags.high
		and	al, IFlag SHR 8
		mov	ds:[ibptSkipIF], al
		and	[bp].state_flags, NOT IFlag

		DPC DEBUG_HWBRK, 's'
		clc
		jmp	done
	
IBpt_Skip	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IBptSkipRecover
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recover from a skipped hardware breakpoint

CALLED BY:	INTERNAL Single step trap, set by IBpt_Skip
PASS:		bptSkipAddr	= Address of skipped instruction
		bptSkipMask1	= Mask to store in interrupt controller 1
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Save registers we use
	Restore the single-step vector to RpcStepReply
	Clear TFlag in the saved flags (CPU saves flags w/TFlag still on)
	Restore registers and return control.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/89		Initial version
	weber   5/19/97    	Hardware breakpoint version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IBptSkipRecover	proc	far
	;
	; Save the three registers with which we dick. We use
	; BP so we can reference into the stack later, though it
	; costs us a byte in the es:[bp], below.
	; 
		push	es
		push	bp
		push	ax
	;
	; Restore the vector for single-stepping. SingleStep is
	; interrupt 1, so the vector address is 1*4 and our regular
	; handler is RpcStepReply
	; 
		push	dx
		mov     dx, offset RpcStepReply
		call	SetStepHandler
		pop     dx
	;
	; All done. Go back to doing our thing. Note we must
	; clear out the T bit from the flags word we're restoring,
	; as well as resetting the interrupt bit to what it was before
	; the step.
	; 
		mov	bp, sp
		add	bp, 3 * size word + size fptr
		mov	ax, ss:[bp]
		and	ax, NOT (TFlag or IFlag)
		or	ah, cs:[ibptSkipIF]
		mov	ss:[bp], ax
	;
	; Restore the interrupt mask w/timer interrupts enabled...
	; 
		mov	al, cs:[ibptSkipMask1]
		out	PIC1_REG, al
		pop	ax
		pop	bp
		pop	es
		iret
IBptSkipRecover	endp

endif	; INTEL_BREAKPOINT_SUPPORT
scode	ends
