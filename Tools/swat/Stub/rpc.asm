COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Swat -- Stub Communications
FILE:		rpc.asm

AUTHOR:		Adam de Boor, Nov 17, 1988

ROUTINES:
	Name			Description
	----			-----------
	Rpc_Init		Initialize the system
	Rpc_Call		Place a call to the host. Doesn't return until
				reply received.
	Rpc_Serve		Register a server for a procedure
	Rpc_Wait		Wait for something to happen, then return
	Rpc_Run			Call Rpc_Wait indefinitely
	Rpc_Reply		Respond to rpc
	Rpc_Error		Send error response
	Rpc_LoadRegs		Load state block into an IbmRegs structure
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/17/88	Initial revision


DESCRIPTION:
	The functions in this file implement the Stub's communications
	mechanism via the Com module port (defaults to COM2)
		

	$Id: rpc.asm,v 2.37 97/05/23 08:21:19 weber Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Rpc		= 1
		include	stub.def

		include geos.def		;for Semaphore
		include ec.def			;for FatalErrors
		include	geode.def
		include Internal/geodeStr.def
		include Internal/debug.def
		include	thread.def		;for ThreadPriority
		include Internal/heapInt.def	; for HandleMem
		include	Internal/dos.def	;for PSP_userStack
		include system.def		;for things needed by kLoader
		include Internal/semInt.def

RpcCall		struct
    RC_next	nptr.RpcCall			; next call queued (all structs
						;  stored on our stack)
    RC_header	RpcHeader	<>		; header for the call
    RC_data	fptr.byte			; data to send with it (length
						;  is stored in RC_header)
    RC_replied	byte				; non-zero if reply received.
						;  no reply data accepted
						;  yet, as none of our calls
						;  requires it...
		even
    RC_resend	word				; counter at which to resend
RpcCall		ends


scode		segment

stepVector	fptr.far 0			; Initial STEP vector
stepping	word	0			; Non-zero if stepping...

; data for acting as a client
rpcCurCall	fptr.RpcCall			; offset in stack of first
						;  pending RpcCall structure
nextCallID	byte	0			; ID to use for next call

; data for acting as a server
servers		word	RPC_LAST+1 dup(?)	; ProcNum->server mapping

Serve		macro	num, rout
	org	servers+2*(num)
		word	rout
	org	servers+size servers
		endm

		Serve	RPC_MASK, RpcMask
		Serve	RPC_INTERRUPT, RpcInterrupt
		Serve	RPC_CBREAK, CBreak_Set
		Serve	RPC_NOCBREAK, CBreak_Clear
		Serve	RPC_CHGCBREAK, CBreak_Change
		Serve	RPC_SETTBREAK, TBreak_Set
		Serve	RPC_GETTBREAK, TBreak_GetCount
		Serve	RPC_ZEROTBREAK, TBreak_ZeroCount
		Serve	RPC_CLEARTBREAK, TBreak_Clear
		Serve	RPC_SETTIMEBRK, TB_Set
		Serve	RPC_CLEARTIMEBRK, TB_Clear
		Serve	RPC_GETTIMEBRK, TB_GetTime
		Serve	RPC_ZEROTIMEBRK, TB_ZeroTime
		Serve	RPC_SETBREAK, Break_Set
		Serve	RPC_CLEARBREAK, Break_Clear
		Serve	RPC_CONTINUE, RpcContinue
		Serve	RPC_STEP, RpcStep
		Serve	RPC_SKIPBPT, Bpt_RpcSkip
		Serve	RPC_READ_REGS, Kernel_ReadRegs
		Serve	RPC_WRITE_REGS, Kernel_WriteRegs
		Serve	RPC_READ_MEM, Kernel_ReadMem
		Serve	RPC_WRITE_MEM, Kernel_WriteMem,
		Serve	RPC_FILL_MEM8, Kernel_FillMem
		Serve	RPC_FILL_MEM16, Kernel_FillMem
		Serve	RPC_READ_IO8, RpcReadIO8
		Serve	RPC_READ_IO16, RpcReadIO16
		Serve	RPC_WRITE_IO8, RpcWriteIO8
		Serve	RPC_WRITE_IO16, RpcWriteIO16
		Serve	RPC_READ_ABS, Kernel_ReadAbs
		Serve	RPC_WRITE_ABS, Kernel_WriteAbs
		Serve	RPC_FILL_ABS8, Kernel_FillAbs
		Serve	RPC_FILL_ABS16, Kernel_FillAbs
		Serve	RPC_BLOCK_FIND, Kernel_BlockFind
		Serve	RPC_BLOCK_INFO, Kernel_BlockInfo
		Serve	RPC_BLOCK_ATTACH, Kernel_AttachMem
		Serve	RPC_BLOCK_DETACH, Kernel_DetachMem
		Serve	RPC_BEEP, RpcBeep
		Serve	RPC_HELLO, Kernel_Hello
		Serve	RPC_SETUP, Kernel_Setup
		Serve	RPC_GOODBYE, RpcGoodbye
		Serve	RPC_EXIT, RpcExit
		Serve	RPC_READ_FPU, RpcCoprocFetch
		Serve	RPC_WRITE_FPU, RpcCoprocStore
		Serve	RPC_SEND_FILE, RpcSendFile
		Serve	RPC_SEND_FILE_NEXT_BLOCK, RpcSendFileNextBlock
		Serve	RPC_READ_GEODE, Kernel_ReadGeode
		Serve	RPC_INDEX_TO_OFFSET, Kernel_IndexToOffset
		Serve	RPC_FIND_GEODE, RpcFindGeode
		Serve   RPC_GET_NEXT_DATA_BLOCK, Kernel_GetNextDataBlock
		Serve	RPC_READ_XMS_MEM, Kernel_ReadXmsMem
		Serve	RPC_READ_DEBUG_REGS, IBpt_ReadRegs
		Serve	RPC_WRITE_DEBUG_REGS, IBpt_WriteRegs

rpc_LastCall	RpcMessageBuf
lastReply	RpcMessageBuf

rpcInProgress	RpcHeader <RPC_ACK,0,0,-1> 	; call currently in-progress

rpc_ToHost	byte	RPC_MAX_DATA dup(?)

		assume	cs:scode,ds:cgroup,es:cgroup,ss:sstack

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rpc_Length
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the length of the current RPC call

CALLED BY:	Kernel_Write, Kernel_AbsWrite
PASS:		Nothing
RETURN:		CX	= length of current call, including the header
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Rpc_Length	proc	near
		clr	cx
		mov	cl, ds:[rpc_LastCall].RMB_header.rh_length
		ret
Rpc_Length	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rpc_LoadRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load an IbmRegs structure from the current state block

CALLED BY:	Kernel_ReadRegs, RpcStepReply, IRQCommon
PASS:		BP	= address of state block
		ES:DI	= address of IbmRegs structure
RETURN:		Nothing
DESTROYED:	AX, DI, DF, CX, SI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Rpc_LoadRegs	proc	near
	;
	; Copy in the general registers all at once
	; 
		cld
		push	ds
		push	ss
		pop	ds
if _Regs_32
		mov	cx, 8*2     ; 8 32-bit registers
else
		mov	cx, 8       ; 8 16-bit registers
endif
		lea	si, [bp].state_ax
		rep	movsw
		pop	ds

		;
		; Copy in the segment registers
		; 
		mov	ax, [bp].state_es
		stosw
		mov	ax, [bp].state_cs
		stosw
		mov	ax, [bp].state_ss
		stosw
		mov	ax, [bp].state_ds
		stosw
if _Regs_32
		mov	ax, [bp].state_fs
		stosw
		mov	ax, [bp].state_gs
		stosw
endif ; _Regs_32
		;
		; Finally, the saved IP and FLAGS registers
		;
		mov	ax, [bp].state_ip
		stosw
		mov	ax, [bp].state_flags
		stosw
		ret
Rpc_LoadRegs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an RPC_EXIT call. Also used for aborting during
		startup if bad info is given.

CALLED BY:	Kernel_Load, Rpc_Wait
PASS:		attached= 1 if our hooks installed and EndGeosOff vector is
			  accurate.
RETURN:		No
DESTROYED:	Process

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcExit		proc	near

	DA	<DEBUG_TSR or DEBUG_EXIT>, 	<push ax>
	DPC	<DEBUG_TSR or DEBUG_EXIT>, 'E', inv
	DPW	<DEBUG_TSR or DEBUG_EXIT>, ds
	DPW	<DEBUG_TSR or DEBUG_EXIT>, ds:[sysFlags]
	DA	<DEBUG_TSR or DEBUG_EXIT>, 	<pop ax>

		;
		; Reset single-step vector
		; 
		mov	ax, RPC_HALT_STEP
		mov	bx, offset stepVector
		call	ResetInterrupt
		;
		; Ignore fatal errors during exit...
		;
		mov	ax, RPC_HALT_BPT
		call	IgnoreInterrupt

		;
		; Reset int 21h intercept.
		; 
		mov	ax, 21h
		mov	bx, offset dosAddr
		cmp	ds:[bx].segment, -1	; intercepted?
		je	dosReset		; nope.
		call	ResetInterrupt
dosReset:
		;
		; Reset serial line state
		;
if _NETWARE or _WINCOM
		clr	ax
endif
		call	Com_Exit

		test	ds:[sysFlags], MASK attached	; Were we attached?
		jnz	REExitGeos
RELaterDude:
		;
		; If we're not attached, we have no way to call the EndGeos
		; routine, so just exit to DOS ourselves
		; 
		EXIT_HARDWARE

		DPC	DEBUG_EXIT, 'E'
if DEBUG and DEBUG_EXIT
		push	ds, ax, si, cx, dx

		mov	ah, MSDOS_GET_PSP
		int	21h
		mov	ds, bx

		clr	si
		mov	cx, 80h
psploop:
	; print out the PSP
		lodsw
		DPW	DEBUG_EXIT, ax
		loop	psploop

		DPW	DEBUG_EXIT, ds
		pop	ds, ax, si, cx, dx
endif
		call	RestoreState	; Reset timer interrupt

		;
		; If Geos TSR'ed, then we must also TSR.
		;
	
		segmov	ds, cs

		test	ds:[sysFlags], mask geosTSR
		jz	normalExit

	DA	<DEBUG_TSR or DEBUG_EXIT>, 	<push ax>
	DPC	<DEBUG_TSR or DEBUG_EXIT>, 't'
	DA	<DEBUG_TSR or DEBUG_EXIT>, 	<pop ax>

		;
		; keep the same space we are occupying now when we TSR.
		; To find out how much space we use, we backstep to the
		; MCB preceding our PSP.
		;
	
		mov	dx, cs:[swatPSP]
		dec	dx
		mov	ds, dx			;ds:0 = MCB
		clr	si
		mov	dx, ds:[si].MCB_size

	DA	DEBUG_TSR, 	<push ax>
	DPW	DEBUG_TSR, cs:[PSP]
	DPW	DEBUG_TSR, cs:[swatPSP]
	DPW	DEBUG_TSR, dx
	DA	DEBUG_TSR, 	<pop ax>

		; return code 02h just for the heck of it...
		mov	ax, (MSDOS_TSR shl 8) or 02h
		int	21h

normalExit:
	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'n'
	DA	DEBUG_TSR, 	<pop ax>
		mov	ax, 4c01h
		int	21h
REExitGeos:
	DPC	DEBUG_EXIT, 'f'
	DPW	DEBUG_EXIT, ds:[sysFlags]

		call	Kernel_Detach	; Detach. 
		andnf	ds:[sysFlags], not mask connected
		;
		; Make sure GEOS hasn't called the DOS exit function. If it
		; has, we shouldn't go to EndGeos again...
		;
		test	ds:[sysFlags], MASK geosgone
		jnz	RELaterDude
	DPS	DEBUG_EXIT, <EG>
	;
	; Avoid ec-segment death by making sure ds and es point to kdata
	; when we continue at EndGeos
	; 
		mov	ax, ds:[kdata]
		mov	ss:[bp].state_ds, ax
		mov	ss:[bp].state_es, ax

		;
		; Pass control off to the EndGeos routine -- it will return
		; to DOS for us.
		; 
		mov	ax, ds:[kcodeSeg]
		mov	[bp].state_cs, ax
		mov	ax, ds:[EndGeosOff]
		mov	[bp].state_ip, ax
		;
		; Make sure trace bit is clear
		;
		and	[bp].state_flags, NOT TFlag
		andnf	ds:[sysFlags], NOT (MASK waiting OR MASK calling)
		call	RestoreState
		iret
RpcExit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcGoodbye
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach from remote host

CALLED BY:	Rpc_Wait
PASS:		Nothing
RETURN:		No
DESTROYED:	...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/13/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcGoodbye	proc	near
		test	ds:[sysFlags], MASK attached
		jz	RG2
		call	Kernel_Detach
RG2:
		andnf	ds:[sysFlags], not mask connected
		;
		; Continue la machine.
		; 
		jmp	RpcContinue
RpcGoodbye	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcContinue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue the machine

CALLED BY:	Rpc_Wait
PASS:		BP	= pointer to state block to be restored.
RETURN:		No
DESTROYED:	Everything

PSEUDO CODE/STRATEGY:
	We assume the stack is set up with a state block as described by
		the StateBlock structure and that this block is pointed
		to by BP.
	Call RestoreState to restore all the registers, etc.
	Perform an IRET to return to the place where we interrupted the
		machine.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcContinue	proc	near
		andnf	[bp].state_flags, NOT TFlag ; Clear TF
RpcContinueComm	label	near
		;
		; Common code for continuing the machine.
		; 
		clr	cx
		call	Rpc_Reply

		test	ds:[sysFlags], MASK calling
		jnz	RCC2
		andnf	ds:[sysFlags], NOT (MASK waiting OR MASK calling)
		jmp	ResumeFromInterrupt
RCC2:
		;
		; If we're in the middle of a call, we should be set to
		; continue the machine once a reply has been received.
		; The only one for which this isn't true is RPC_HALT,
		; and if we're continued before a reply is received,
		; something's wrong anyway, so...just set the replied flag
		; and return. This also gets around a problem in KernelLoadRes,
		; which see.
		; 
		push	ds, bx
		lds	bx, ds:[rpcCurCall]
callLoop:
		tst	bx
		jz	done
		mov	ds:[bx].RC_replied, RPC_REPLY
		mov	bx, ds:[bx].RC_next
		jmp	callLoop
done:
		pop	ds, bx
		ret
RpcContinue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcStep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the RPC_STEP call.

CALLED BY:	Rpc_Wait
PASS:		Nothing
RETURN:		No.
DESTROYED:	Everything

PSEUDO CODE/STRATEGY:
	Make sure the timer interrupt is masked when the machine continues (by
		setting b0 in state_PIC1)
	Set the TFlag bit in the flags word that will be restored.
	Go to the common continue code to reply to the rpc, restore state and
		continue the machine.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/27/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcStep		proc	near
		mov	ds:[stepping], 1
	;
	; Limit Heisenberg principle by emulating certain instructions:
	; 	- if instruction is about to read from port 21, load
	;	  al with the saved mask
	;	- if pushf, push already-saved flags word, which doesn't
	;	  have TF set
	;	- if software interrupt, emulate as TF won't take on > 8086
	;	  processors until after return
	;
			CheckHack <offset state_cs eq offset state_ip+2>
		les	di, {fptr}ss:[bp].state_ip

		mov	ax, es:[di]
		cmp	ax, 0x21e4	; byte IN from 21h?
		jne	checkPushf
		
		mov	al, ss:[bp].state_PIC1
		mov	ss:[bp].state_al, al
		add	ss:[bp].state_ip, 2	; two-byte instruction just
						;  emulated
		jmp	emulated
checkPushf:
	;
	; Can't emulate either pushf or int if running on stub stack
	;
		cmp	ss:[bp].state_ss, sstack
		je	doStep

		cmp	al, 0x9c		; pushf?
		jne	checkInt
		mov	es, ss:[bp].state_ss
		mov	di, ss:[bp].state_sp
		dec	di
		dec	di
		mov	ax, ss:[bp].state_flags
		andnf	ax, NOT TFlag ; Clear TF
		mov	es:[di], ax
		mov	ss:[bp].state_sp, di
		add	ss:[bp].state_ip, 1	; single-byte instruction just
						;  emulated
		jmp	emulated

emulateInt:
		call	EmulateInterrupt
		jmp	emulated
checkInt:
		cmp	al, 0xcd		; two-byte int?
		je	emulateInt
		cmp	al, 0xcc
		je	emulated		; *DO NOTHING* if bpt -- just
						;  stick there

doStep:
		segmov	es, ds
		or	[bp].state_PIC1, TIMER_MASK; Keep timer interrupt OFF
						; so the thread won't c-switch
		or	[bp].state_flags, TFlag	; Set trace bit on return.
		andnf	ds:[sysFlags], NOT (MASK waiting OR MASK calling)
		call	RestoreState
		iret

emulated:
	;
	; Make life easier (and smaller without the risk of building gross
	; things up on the stack by jumping to Rpc_Run after RpcWait has
	; called us) by just restoring state and falling into RpcStepReply as
	; if the instruction were actually executed.
	; 
		segmov	es, ds
		andnf	ds:[sysFlags], NOT (MASK waiting OR MASK calling)
		call	RestoreState

		.fall_thru	RpcStepReply
RpcStep		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcStepReply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the reply to the just-handled RPC_STEP call
		based on the current state.

CALLED BY:	Single-step interrupt
PASS:		Interrupts off...
RETURN:		No
DESTROYED:	Everything

PSEUDO CODE/STRATEGY:
		Call SaveState to do that.
		Put together a StepReply in rpc_ToHost
		Call Rpc_Reply to do that.
		Jump to Rpc_Run to wait for further instructions.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcStepReply	proc	far

		cmp	cs:stepping, 1
		jne	RSRNotUs
		call	SaveState
		mov	ds:stepping, 0
		;
		; Fetch the active thread and store it
		; 
		mov	ax, BPT_NOT_XIP
		tst	ds:[xipHeader]
		jz	gotXIP
		push	es, di
		mov	es, ds:[kdata]
		mov	di, ds:[curXIPPageOff]
		mov	ax, es:[di]
		pop	es, di
gotXIP:
		mov	({StepReply}ds:[rpc_ToHost]).sr_curXIPPage, ax
		
		mov	ax, [bp].state_thread
		mov	({StepReply}ds:[rpc_ToHost]).sr_thread, ax

		mov	di, offset ({StepReply}rpc_ToHost).sr_regs
		call	Rpc_LoadRegs
		
		mov	cx, size StepReply
		mov	si, offset rpc_ToHost

		call	Rpc_Reply
		jmp	Rpc_Run
RSRNotUs:
if INTEL_BREAKPOINT_SUPPORT
		;
		; Perhaps it was an interrupt from the Intel debug registers
		;
		push	ax
		movsp	eax, dr6
		test	ax, mask DR6L_B3 or mask DR6L_B2 \
			 or mask DR6L_B1 or mask DR6L_B0
		pop	ax
		jnz	RSRHardwareBreak
endif
		;
		; See if we expect someone else to handle the thing. This
		; will only be true if running under the atron board (or
		; some better debugger)
		;
		tst	cs:[intsToIgnore][RPC_HALT_NMI]
		jnz	RSRPassTheBuck
		;
		; Nope -- unexpected single step, therefore. Make like
		; we're a vector in the InterruptHandlers table, performing
		; a near call to IRQCommon with the halt code immediately
		; following.
		;
;RSRCommon:
		call	IRQCommon
		.inst byte	RPC_HALT_STEP
RSRPassTheBuck:
		;
		; Let the dude what's debugging us have control
		;
		jmp	cs:stepVector

if INTEL_BREAKPOINT_SUPPORT
RSRHardwareBreak:
	;
	; Log the breakpoint
	;
		DA	DEBUG_HWBRK, <push ax>
		DPC	DEBUG_HWBRK, 'B'
		DA	DEBUG_HWBRK, <movsp eax, dr6>
		DPB	DEBUG_HWBRK, al
		DA	DEBUG_HWBRK, <pop ax>
		jmp	RSRCommon		
endif		
		
RpcStepReply	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the interrupt controller masks we use when waiting.

CALLED BY:	Rpc_Wait
PASS:		MaskArgs in rpc_FromHost
RETURN:		Nothing (maybe return actual masks?)
DESTROYED:	AX, CX, current i.c. masks

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 6/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcMask		proc	near
		;
		; Don't want any pending interrupts in until we've set up
		; both things....(user might be forced to interrupt, 
		; trashing the second mask, eg.)
		; 
		dsi
		mov	al, ({MaskArgs}CALLDATA).ma_PIC1
		mov	ah, ds:[COM_Mask1]
		not	ah
		and	al, ah			; Keep our com port from
						; being masked out.
		mov	ds:[PIC1_Mask], al
		out	PIC1_REG, al
		mov	al, ({MaskArgs}CALLDATA).ma_PIC2
		mov	ah, ds:[COM_Mask2]
		not	ah
		and	al, ah
		mov	ds:[PIC2_Mask], al
		out	PIC2_REG, al
		eni
		clr	cx		; Life's good
		jmp	Rpc_Reply
RpcMask		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an RPC_INTERRUPT call

CALLED BY:	Rpc_Wait
PASS:		waiting	= 1 if we're not interrupting anyone but ourselves
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Send null reply
	If waiting is set, return right away (already interrupted...)
	Else jump to Rpc_Run to wait for more commands.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcInterrupt	proc	near
		;
		; Reply with the current thread.
		; 
		mov	ax, [bp].state_thread
		mov	word ptr ds:[rpc_ToHost], ax
		mov	si, offset rpc_ToHost
		mov	cx, 2		
		call	Rpc_Reply

	;
	; If we're actively calling (XXX: check rpcCurCall.offset instead),
	; the caller may continue the machine, so set the dontresume
	; flag to stop that and return so the call can be completed
	; as dialed.
	; 
		test	ds:[sysFlags], MASK calling
		jz	checkWaiting
		ornf	ds:[sysFlags], MASK dontresume
done:
		ret

checkWaiting:		
	;
	; If neither waiting nor calling flag is set, it means we were called by
	; ComInterrupt and need to go to Rpc_Run to keep the machine stopped.
	; 
		test	ds:[sysFlags], MASK waiting
		jnz	done
		jmp	Rpc_Run

RpcInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcReadIO8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read an 8-bit I/O port and return its contents

CALLED BY:	Rpc_Wait
PASS:		CALLDATA	= port to read
RETURN:		zero-extended 8-bit value read, padded to a word.
DESTROYED:	AX, DX, SI, CX, ?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcReadIO8	proc	near
		mov	dx, word ptr CALLDATA	; Fetch port #
		;
		; Need to handle references to the PIC registers specially,
		; returning the stored values, rather than the current ones.
		;
		cmp	dx, PIC1_REG
		jne	RRIO8_1
		mov	al, [bp].state_PIC1
		jmp	short RRIO8_3
RRIO8_1:
		cmp	dx, PIC2_REG
		jne	RRIO8_2
		mov	al, [bp].state_PIC2
		jmp	short RRIO8_3
RRIO8_2:
		;
		; General port -- read it
		;
		in	al, dx
RRIO8_3:
		;
		; Stuff the byte and reply with it.
		;
		clr	ah
		mov	word ptr ds:[rpc_ToHost], ax
		mov	cx, 2
		mov	si, offset rpc_ToHost
		call	Rpc_Reply
		ret
RpcReadIO8	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcReadIO16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a 16-bit I/O port (w/o special treatment of PIC regs)

CALLED BY:	Rpc_Wait
PASS:		CALLDATA	= port # to read
RETURN:		rpc_ToHost	= value read
DESTROYED:	...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcReadIO16	proc	near
		mov	dx, word ptr CALLDATA
		in	ax, dx
		mov	word ptr ds:[rpc_ToHost], ax
		mov	cx, 2
		mov	si, offset rpc_ToHost
		call	Rpc_Reply
		ret
RpcReadIO16	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcWriteIO8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write an 8-bit value to an I/O port

CALLED BY:	Rpc_Wait
PASS:		CALLDATA	= IoWriteArgs
RETURN:		Nothing
DESTROYED:	AX, DX, CX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcWriteIO8	proc	near
		mov	dx, ({IoWriteArgs}CALLDATA).iow_port
		mov	ax, ({IoWriteArgs}CALLDATA).iow_value
		cmp	dx, PIC1_REG
		jne	RWIO8_1
		mov	[bp].state_PIC1, al
		jmp	short RWIO8_3
RWIO8_1:
		cmp	dx, PIC2_REG
		jne	RWIO8_2
		mov	[bp].state_PIC2, al
		jmp	short RWIO8_3
RWIO8_2:
		out	dx, al
RWIO8_3:
		clr	cx
		call	Rpc_Reply
		ret
RpcWriteIO8	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcWriteIO16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a value to a 16-bit I/O port (w/o regard to PIC regs)

CALLED BY:	Rpc_Wait	
PASS:		CALLDATA	= IoWriteArgs structure
RETURN:		Nothing
DESTROYED:	DX, AX, CX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcWriteIO16	proc	near
		mov	dx, ({IoWriteArgs}CALLDATA).iow_port
		mov	ax, ({IoWriteArgs}CALLDATA).iow_value
		out	dx, ax
		clr	cx
		call	Rpc_Reply
		ret
RpcWriteIO16	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcBeep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an RPC_BEEP call

CALLED BY:	Rpc_Wait
PASS:		Nothing
RETURN:		the loader's checksum and our revision level and other things
DESTROYED:	...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
RpcBeep		proc	near
	;
	; Abort any in-progress calls immediately, to reduce the chance
	; of hosing Swat.
	; 
		call	RpcAbortCalls

		ornf	ds:[sysFlags], mask connected

		mov	ax, ds:[kernelHeader].exe_csum
		mov	({BeepReply}ds:[rpc_ToHost]).br_csum, ax

		mov	({BeepReply}ds:[rpc_ToHost]).br_rev, RPC_REVISION

		mov	ax, ds:[loaderBase]	; current loader base
		mov	({BeepReply}ds:[rpc_ToHost]).br_baseSeg, ax

		mov	({BeepReply}ds:[rpc_ToHost]).br_stubSeg, cs

	;
	; We may or may not be trashing stubInit...
	;
		mov	ax, stubInit	; figure how big we are
		sub	ax, cgroup
		shl	ax
		shl	ax
		shl	ax
		shl	ax

	; 
	; If stubInit is not deallocated, then we must include its size.
	;
		tst	ds:tsrMode
		jz	noTSR
		add	ax, offset endOfStubInit
		add	ax, 0x10
noTSR:

		mov	({BeepReply}ds:[rpc_ToHost]).br_stubSize, ax

		mov	al, ds:[stubType]
		mov	({BeepReply}ds:[rpc_ToHost]).br_stubType, al

		mov	ax, ds:[kernelCore]
		or	al, ah			; sets al non-zero if kernel
						;  loaded, b/c at least 1 bit
						;  of core block must be n/z
		mov	({BeepReply}ds:[rpc_ToHost]).br_kernelLoaded, al

		mov	({BeepReply}ds:[rpc_ToHost]).br_irqHandlers,
			offset InterruptHandlers
	;
	; Get the address of the various DOS system tables and store
	; it in the reply. This uses the undocumented DOS function
	; 52, which returns in ES:BX a pointer to a table of pointers
	; to various system data structures.
	; 
		push	es
		mov	ah, 52h	; Get DOS tables...
		int	21h
		mov	({BeepReply}ds:[rpc_ToHost]).br_sysTablesOff, bx
		mov	({BeepReply}ds:[rpc_ToHost]).br_sysTablesSeg, es
		pop	es

		mov	ax, ds:[PSP]
		mov	({BeepReply}ds:[rpc_ToHost]).br_psp, ax

	;
	; Tell Swat what we're masking at the moment.
	; 
		mov	al, ds:[PIC1_Mask]
		mov	({BeepReply}ds:[rpc_ToHost]).br_mask1, al
		mov	al, ds:[PIC2_Mask]
		mov	({BeepReply}ds:[rpc_ToHost]).br_mask2, al
		
		mov	cx, size BeepReply
		mov	si, offset rpc_ToHost
		call	Rpc_Reply
	;
	; (Re)initialize the sequence number for rpc calls so we're in
	; sync with the host.
	; 
		mov	ds:[nextCallID], 0
	;
	; If kernel's been loaded, ship off a call to Swat telling it so.
	;
		tst	({BeepReply}ds:[rpc_ToHost]).br_kernelLoaded
		jz	done
	;
	; Swat's not expecting to be attached to anything, so make
	; sure no handle has the DEBUG bit set.
	;
		push	es
		call	Kernel_CleanHandles
		pop	es
	;
	; Build up a SpawnArgs for transmission to the host.
	;
if 0
		cmp	ds:[loaderInitialized], 1
		je	tryAgain
		mov	ds:[loaderInitialized], 2
		jmp	done
endif
tryAgain:
		mov	ax, ds:[kernelCore]
		mov	ds:[{SpawnArgs}rpc_ToHost].sa_owner, ax
		clr	ax
		mov	ds:[{SpawnArgs}rpc_ToHost].sa_thread, ax; kernel thread,
								;  for now
		mov	ds:[{SpawnArgs}rpc_ToHost].sa_ss, ax	; loading
								;  library
		mov	ds:[{SpawnArgs}rpc_ToHost].sa_sp, ax	; ditto

	;
	; Tell host the kernel's been loaded.
	;
		mov	ax, RPC_KERNEL_LOAD
		mov	cx, size SpawnArgs
		mov	bx, offset rpc_ToHost
		call	Rpc_Call
		jc	tryAgain		; => procedure wasn't
						;  registered yet (most likely),
						;  so send again.
done:
	;
	; Wait to be continued.
	; 
		test	ds:[sysFlags], mask waiting or mask calling
		jnz	alreadyStopped
		jmp	Rpc_Run
alreadyStopped:
		test	ds:[sysFlags], mask calling
		jz	exit
		ornf	ds:[sysFlags], mask dontresume
exit:
		ret
RpcBeep		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcCoprocFetch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch all the registers for the coprocessor.

CALLED BY:	RPC_COPROC_FETCH
PASS:		nothing
RETURN:		CoprocRegs
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcCoprocFetch	proc	near
		.enter
		fsave	{word}ds:[rpc_ToHost]	; initializes the FPU, so...
		finit
		frstor	{word}ds:[rpc_ToHost]	;  restore things right away
		mov	cx, size CoprocRegs
		mov	si, offset rpc_ToHost
		call	Rpc_Reply
		.leave
		ret
RpcCoprocFetch	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcCoprocStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store all the registers for the coprocessor.

CALLED BY:	RPC_COPROC_STORE
PASS:		nothing
RETURN:		CoprocRegs
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcCoprocStore	proc	near
		.enter
		frstor	ds:[rpc_LastCall].RMB_data
		fwait
		clr	cx
		call	Rpc_Reply
		.leave
		ret
RpcCoprocStore	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcSendFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	recieve a file from the host

CALLED BY:	RPC_SEND_FILE

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/14/93		Initial version.
	Joon	10/21/93	Retransmit bad blocks

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
initialDrive	byte			; initial drive
initialPath	byte 65 dup (?)		; buffer for initial path
fileHandle	word

RpcSendFile	proc	near
		uses	ds, es
		.enter
		DPC	DEBUG_FILE_XFER, 's'
		segmov	ds, cs, ax
		mov	es, ax

	; check the DOS semaphore to see if its free
		tst	ds:[kernelCore]
		jz	semFree

		mov	es, ds:[kdata]
		mov	si, ds:[dosSemOff]
		cmp	es:[si].Sem_value, 0
		jg	semFree

		mov	al, FILE_XFER_ERROR_DOS_SEM_TAKEN
;		call	Com_Write
		mov	ds:[rpc_ToHost], al
		jmp	done
semFree:
	; save current path and switch to topLevelPath
		call	RpcSavePathAndSwitchToTopLevelPath

	; create the directory the file should be sent to
		call	RpcCreateDirectory

		segmov	ds, cs, ax
		mov	es, ax
		mov	dx, offset CALLDATA
		mov	ah, MSDOS_CREATE_TRUNCATE
		clr	cx			; normal file
		int	21h			; ax = file handle
		jnc	createOk

		mov	al, FILE_XFER_ERROR_FILE_CREATE_FAILED
;		call	Com_Write
		mov	ds:[rpc_ToHost], al
		DPC	DEBUG_FILE_XFER, 'e', inv
		jmp	restorePath
createOk:
		mov_tr	bx, ax	; bx = file handle
		DPW	DEBUG_FILE_XFER, bx
		mov	cs:[fileHandle], bx
		mov	al, FILE_XFER_SYNC
;		call	Com_Write
		mov	si, offset rpc_ToHost
		mov	ds:[si], al
		jmp	done
restorePath:
	; restore drive and path to what it was before we started the filexfer.
		call	RpcRestorePath
done:
		mov	cx, 1
		mov	si, offset rpc_ToHost
		segmov	es, ds
		call	Rpc_Reply
		.leave
		ret
RpcSendFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcSendFileNextBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the next block in a send file operation

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/30/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RpcSendFileNextBlock	proc	near
		.enter
		DPC	DEBUG_FILE_XFER, 'n'
		call	Rpc_Length	; cx = length of block
		DPW	DEBUG_FILE_XFER, cx
		push	cx
	; write out next block to file
		mov	dx, offset CALLDATA
		mov	bx, cs:[fileHandle]
		DPW	DEBUG_FILE_XFER, bx
		mov	ah, MSDOS_WRITE_FILE
		int	21h
		pop	dx
		jc	error
		mov	al, FILE_XFER_SYNC
		jmp	checkEnd
error:
		mov	al, FILE_XFER_ERROR
checkEnd:
		cmp	dx, FILE_XFER_BLOCK_SIZE
		je	done
		push	ax
		DPC	DEBUG_FILE_XFER, 'c'
		mov	ah, MSDOS_CLOSE_FILE
		int	21h
		pop	ax
		jnc	done
		mov	al, FILE_XFER_ERROR
done:
		mov	cx, 1
		segmov	es, ds
		mov	si, offset rpc_ToHost
		mov	es:[si], al
		call	Rpc_Reply
		.leave
		ret
RpcSendFileNextBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcFindGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find geode by doing a recursive search of .geo files
		starting from the WORLD directory.
CALLED BY:	RPC_FIND_GEODE
PASS:		geode_name
RETURN:		full path name of geode
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	7/31/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DosDataTransferArea	struct
    DDTA_reserved	byte 21 dup(?)	; reserved for DOS use on next matches
    DDTA_attributes	byte		; attributes of matched file
    DDTA_fileTime	word		; file time
    DDTA_fileDate	word		; file date
    DDTA_fileSize	dword		; file size
    DDTA_fileName	byte 13 dup(?)	; file name
DosDataTransferArea	ends

MSDOS_GET_DTA	equ	2fh

worldDir	char "WORLD",0
upDir		char "..",0
geosFileSpec	char "*.GEO",0
allFileSpec	char "*.*",0

RpcFindGeode	proc	near
		uses	ds, es
		.enter
	;
	; we will be doing DOS file stuff, so check whether we're in DOS
		segmov	ds, cs
		mov	{word} ds:[rpc_ToHost], 0

		tst	ds:[kernelCore]
		jz	savePath

		mov	es, ds:[kdata]
		mov	si, ds:[dosSemOff]
		cmp	es:[si].Sem_value, 0
		jle	reply			; Semaphore taken -- honk
savePath:
		call	RpcSavePathAndSwitchToTopLevelPath
cdWorld::
		mov	dx, offset worldDir
		mov	ah, MSDOS_SET_CURRENT_DIR
		int	21h
		jc	restorePath
	;
	; we will be changing the dos data transfer area.
		mov	ah, MSDOS_GET_DTA
		int	21h
	;
	; recursively search for geode.
		push	es, bx, bp
		call	RpcFindGeodeRecursively
		pop	ds, dx, bp
	;
	; reset dos data transfer area back to what it was before.
		mov	ah, MSDOS_SET_DTA
		int	21h
restorePath:
	;
	; restore drive and path to what it was before we started the search.
		call	RpcRestorePath
reply:
		segmov	ds, cs
		segmov	es, cs
		mov	si, offset rpc_ToHost
		mov	cx, RPC_FIND_GEODE_XFER_SIZE
		call	Rpc_Reply

		.leave
		ret
RpcFindGeode	endp

;
; Returns carry clear if geode was found.
;
RpcFindGeodeRecursively	proc	near
dosDTA		local	DosDataTransferArea
		.enter
	;
	; check current directory
		call	RpcFindGeodeCurrentDir
		jnc	done
	;
	; we will be using DOS data transfer area
		segmov	ds, ss
		lea	dx, ss:[dosDTA]
		mov	ah, MSDOS_SET_DTA
		int	21h
	;
	; geode was not found in current directory.  so check subdirectories.
		segmov	ds, cs
		mov	dx, offset allFileSpec
		mov	cx, 10h			; directories
		mov	ah, MSDOS_FIND_FIRST
		int	21h
		jc	done
checkDir:
		cmp	{byte} ss:[dosDTA].DDTA_fileName, '.'
		je	nextDir
	;
	; change into directory and do recursive search
		segmov	ds, ss
		lea	dx, ss:[dosDTA].DDTA_fileName
		mov	ah, MSDOS_SET_CURRENT_DIR
		int	21h
		jc	nextDir

		call	RpcFindGeodeRecursively
		jnc	done

		segmov	ds, cs
		mov	dx, offset upDir
		mov	ah, MSDOS_SET_CURRENT_DIR
		int	21h
		jc	done			; if this happens, we are
						;  really screwed!!!
nextDir:
	;
	; reset DOS data transfer area in case it's been changed
		segmov	ds, ss
		lea	dx, ss:[dosDTA]
		mov	ah, MSDOS_SET_DTA
		int	21h
	;
	; get next subdirectory
		mov	ah, MSDOS_FIND_NEXT
		int	21h
		jnc	checkDir
done:
		.leave
		ret
RpcFindGeodeRecursively	endp		

;
; Notifies host machine and returns carry clear if geode is found.
; Returns carry set if geode is not found.
;
RpcFindGeodeCurrentDir	proc	near
dosDTA		local	DosDataTransferArea
geodeName	local	(GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE+1) dup (byte)
		.enter
	;
	; we will be using DOS data transfer area
		segmov	ds, ss
		lea	dx, ss:[dosDTA]
		mov	ah, MSDOS_SET_DTA
		int	21h
	;
	; check geodes in current directory to see if any match
	; the geode we are looking for
		segmov	ds, cs
		mov	dx, offset geosFileSpec
		clr	cx			; normal files only
		mov	ah, MSDOS_FIND_FIRST
		int	21h
		LONG jc	done
checkFile:
	;
	; check file in dosDTA
		segmov	ds, ss
		lea	dx, ss:[dosDTA].DDTA_fileName
		clr	al			; read access
		mov	ah, MSDOS_OPEN_FILE
		int	21h
		jc	nextFile

		mov_tr	bx, ax			; bx <= file handle

		clr	al			; offset from beginning of file
		clr	cx
		mov	dx, offset GFH_coreBlock.GH_geodeName + 256
		mov	ah, MSDOS_POS_FILE
		int	21h
		jc	closeFile

		segmov	ds, ss
		lea	dx, ss:[geodeName]
		mov	cx, GEODE_NAME_SIZE+GEODE_NAME_EXT_SIZE
		mov	ah, MSDOS_READ_FILE
		int	21h
closeFile:
		pushf
		mov	ah, MSDOS_CLOSE_FILE
		int	21h
		popf
		jc	nextFile
	;
	; Compare current file with file we are looking for.
		segmov	ds, cs
		lea	si, CALLDATA
		segmov	es, ss
		lea	di, ss:[geodeName]
		mov	cx, GEODE_NAME_SIZE
		repe	cmpsb			; Z=1 if names match
		jne	nextFile

		lodsb
		cmp	al, es:[di]		; if first byte of ext are same
		je	found			;  then we have found the file

		cmp	al, 'E'			; else first byte of ext must
		je	nextFile		;  not be 'E'.
		cmp	{byte} es:[di], 'E'
		je	nextFile
found:
	;
	; Found geode - notify host machine and return carry clear.
		segmov	ds, cs
		mov	si, offset rpc_ToHost
		clr	dl			; default drive
		mov	ah, MSDOS_GET_CURRENT_DIR
		int	21h

		segmov	es, ds
		mov	di, si
		clr	al
		mov	cx, RPC_FIND_GEODE_XFER_SIZE
		repne	scasb
		dec	di

		mov	al, '\\'
		stosb

		segmov	ds, ss
		lea	si, ss:[dosDTA].DDTA_fileName
		mov	cx, size DDTA_fileName
		rep	movsb
		clr	al
		stosb

		clc
		jmp	done
nextFile:
		mov	ah, MSDOS_FIND_NEXT
		int	21h
		jnc	checkFile
done:
		.leave
		ret
RpcFindGeodeCurrentDir	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcSavePathAndSwitchToTopLevelPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save current drive and directory

CALLED BY:	RpcSendFile, RpcFindGeode
PASS:		stack frame
RETURN:		nothing
DESTROYED:	ax, dx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/21/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcSavePathAndSwitchToTopLevelPath	proc	near
		uses	ds, es
		.enter
	;
	; Save current drive and path.
	;
		mov	ah, MSDOS_GET_DEFAULT_DRIVE
		int	21h
		mov	cs:[initialDrive], al	; save default drive

		segmov	ds, cs
		lea	si, cs:[initialPath]	; ds:si = path buffer
		mov	{byte} ds:[si], '\\'	; store path relative to root
		inc	si			; store path after '\'
		clr	dl			; default drive (current)
		mov	ah, MSDOS_GET_CURRENT_DIR
		int	21h

if DEBUG and DEBUG_FILE_XFER
		mov	ah, SCREEN_ATTR_NORMAL
		mov	al, ' '
		call	DebugPrintChar
		mov	al, cs:[initialDrive]
		add	al, 'A'
		call	DebugPrintChar
		mov	al, ':'
		call	DebugPrintChar
		lea	si, cs:[initialPath]
		call	DebugPrintString
		mov	al, ' '
		call	DebugPrintChar

		mov	al, '"'
		call	DebugPrintChar
		segmov	ds, cs
		mov	si, offset topLevelPath
		call	DebugPrintString
		mov	al, '"'
		call	DebugPrintChar
		mov	al, ' '
		call	DebugPrintChar
endif
	;
	; Now switch to topLevelPath.
	;
		segmov	ds, cs
		mov	dl, {char}ds:[topLevelPath]	; get drive letter
		tst	dl
		jz	done			; if no topLevelPath, we'll
						; just assume that we're
						; already in SP_TOP.  This
						; should be a reasonable
						; assumption if we're using the
						; PC-SDK.

		sub	dl, 'A'			; (A: = 0, Z: = 25)
		mov	ah, MSDOS_SET_DEFAULT_DRIVE
		int	21h

		mov	dx, offset topLevelPath
		mov	ah, MSDOS_SET_CURRENT_DIR
		int	21h
done:
		.leave
		ret
RpcSavePathAndSwitchToTopLevelPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcRestorePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save current drive and directory

CALLED BY:	RpcSendFile, RpcFindGeode
PASS:		stack frame
RETURN:		nothing
DESTROYED:	ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/21/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcRestorePath	proc	near
		uses	ds, es
		.enter

		mov	dl, cs:[initialDrive]
		mov	ah, MSDOS_SET_DEFAULT_DRIVE
		int	21h

		segmov	ds, cs
		lea	dx, cs:[initialPath]		
		mov	ah, MSDOS_SET_CURRENT_DIR
		int	21h

if DEBUG and DEBUG_FILE_XFER
		mov	ah, SCREEN_ATTR_NORMAL
		mov	al, cs:[initialDrive]
		add	al, 'A'
		call	DebugPrintChar		
		mov	al, ':'
		call	DebugPrintChar
		lea	si, cs:[initialPath]
		call	DebugPrintString
		mov	al, ' '
		call	DebugPrintChar
endif
		.leave
		ret
RpcRestorePath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcCreateDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create directory in current directory

CALLED BY:	RpcSendFile
PASS:		cs:CALLDATA = file path
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Given a file path like 'world\c\helloec.geo',
		create directory 'world' and then 'world\c'.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	7/31/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcCreateDirectory	proc	near
		uses	ax,cx,dx,si,ds
		.enter

		segmov	ds, cs, ax
		mov	dx, offset CALLDATA
		mov	si, dx

		; find end of directory name by searching for backslash
pathLoop:
		lodsb
		tst	al
		jz	done
		cmp	al, '\\'
		jne	pathLoop

		; temporarily null terminate the string at the backslash

		clr	cx
		xchg	cl, ds:[si-1]	; cl = backslash, ds:[si-1] = null

		; now create the directory

		mov	ah, MSDOS_CREATE_DIR
		int	21h

		; restore the backslash character and continue on

		xchg	cl, ds:[si-1]
		jmp	pathLoop
done:
		.leave
		ret
RpcCreateDirectory	endp

scode		ends

;==============================================================================
;
;		RPC MECHANISM (NO MORE SERVERS AFTER THIS POINT)
;
;==============================================================================
stubInit	segment
		assume	cs:stubInit

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rpc_Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the RPC system

CALLED BY:	MainHandleInit
PASS:		ES, DS pointing to cgroup, SS to sstack		
RETURN:		Nothing
DESTROYED:	Many things

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
Rpc_Init	proc	near

		call	Com_Init

		mov	ax, RPC_HALT_STEP
		mov	bx, offset stepVector
		mov	dx, offset RpcStepReply
		call	SetInterrupt			; Uses old copy
							; if stub is relocated

		andnf	ds:[sysFlags], NOT MASK waiting
		ret
Rpc_Init	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rpc_Serve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter an extra server into the table beyond those entered
		by default.

CALLED BY:	EXTERNAL
PASS:		bx	= rpc number
		ax	= handler procedure
		ds	= cgroup
RETURN:		carry clear if couldn't register the server
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Rpc_Serve	proc	near
		.enter
		cmp	bx, length servers
		jae	cantRegister
		shl	bx
		mov	ds:servers[bx], ax
		stc
cantRegister:
		.leave
		ret
Rpc_Serve	endp

endOfStubInit:
		.unreached
stubInit	ends

scode		segment
		assume	cs:scode

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rpc_Exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the Rpc system

CALLED BY:	RpcExit
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	Maybe

PSEUDO CODE/STRATEGY:
		Just need to call Com_Exit to reset the serial line.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
Rpc_Exit	proc	near
if _NETWARE or _WINCOM
		clr	ax
endif
		call	Com_Exit
		mov	ax, 1
		mov	bx, offset stepVector
		call	ResetInterrupt
		ret
Rpc_Exit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcResend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ship off the passed call and reset its resend counter.

CALLED BY:	Rpc_Call, Rpc_Wait
PASS:		es:bx	= RpcCall to resend (located on stack)
		ss:bp	= StateBlock
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcResend	proc	near
		uses	ds, si, di, dx
		.enter

	DPC	<DEBUG_RPC_WAIT or DEBUG_RPC_CALL>, 's', inverse
	DPB	<DEBUG_RPC_WAIT or DEBUG_RPC_CALL>, es:[bx].RC_header.rh_id
	DPB	<DEBUG_RPC_WAIT or DEBUG_RPC_CALL>, es:[bx].RC_header.rh_procNum
		tst	ds:[readGeodeSem]
		jnz	done

	;
	; Save initial SP for clearing the stack later
	; 
		mov	dx, sp
	;
	; Make room for the call data first and copy it onto the stack.
	; 
		clr	cx
		mov	cl, es:[bx].RC_header.rh_length
		sub	sp, cx
		mov	di, sp
		lds	si, es:[bx].RC_data
		rep	movsb
	;
	; Make room for the call header and copy it onto the stack.
	; 
		sub	sp, size RpcHeader
		segmov	ds, es
		lea	si, [bx].RC_header
		mov	di, sp
		mov	cx, size RpcHeader
		rep	movsb
	;
	; Figure the total length of the message and ship it off.
	; 
		mov	cl, es:[bx].RC_header.rh_length
		add	cx, size RpcHeader
		mov	si, sp
		call	Com_WriteMsg

	;
	; Clear the stack and figure the new resend counter to be one
	; second later than now. If the timer interrupt we superseded lay
	; in kcode, we assume the system clock is going at 60 Hz, rather
	; than the 18 Hz used by DOS. 
	; 
		mov	sp, dx

		segmov	ds, cgroup, ax
		mov	ax, ds:[kcodeSeg]
		cmp	ss:[bp].state_timerInt.segment, ax
		mov	ax, 60			; assume pc/geos clock rate
		je	addInterval
		mov	ax, 18			; nope. must be DOS's
addInterval:
		add	ax, ds:[stubCounter]	; ignore wrap...
		mov	es:[bx].RC_resend, ax
done:
		.leave
		ret
RpcResend	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rpc_Call
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a procedure on the host

CALLED BY:	GLOBAL
PASS:		AX	= Rpc number
		ES:BX	= Arguments
		CX	= Number of bytes of arguments
		ss:bp	= StateBlock
RETURN:		carry set if other side returned an error
DESTROYED:	SI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

Rpc_Call	proc	near
		.enter
	;
	; Note that we're calling so RpcInterrupt won't dick with us
	; 
		ornf	ds:[sysFlags], MASK calling
	;
	; First set up and send the header for the call
	; 
		sub	sp, size RpcCall
		mov	di, bx		; save data base
		mov	bx, sp
		mov	ss:[bx].RC_header.rh_procNum, al
		mov	ss:[bx].RC_header.rh_length, cl
		mov	ss:[bx].RC_header.rh_flags, RPC_CALL
		mov	al, ds:[nextCallID]
		inc	al
		mov	ds:[nextCallID], al
		mov	ss:[bx].RC_header.rh_id, al
		mov	ss:[bx].RC_data.offset, di
		mov	ss:[bx].RC_data.segment, es
		mov	ss:[bx].RC_replied, 0
		mov	ax, ds:[rpcCurCall].offset
		mov	ss:[bx].RC_next, ax
		dsi
		mov	ds:[rpcCurCall].offset, bx
		mov	ds:[rpcCurCall].segment, ss
		eni
		segmov	es, ss
		call	RpcResend
waitForIt:		
	;
	; Wait until we get a reply to our RPC
	; 
		push	bx
		call	Rpc_Wait
		pop	bx
		mov	al, ss:[bx].RC_replied
		tst	al
		jz	waitForIt
	;
	; Unlink this call from the chain.
	;
		dsi
		mov	bx, ss:[bx].RC_next
		mov	ds:[rpcCurCall].offset, bx
		tst	bx
		jnz	done
		;
		; Clear out the calling flag so we can continue...
		;
		andnf	ds:[sysFlags], NOT MASK calling
done:
		add	sp, size RpcCall
		eni
		test	al, RPC_ERROR
		jz	exit
		stc
exit:
		.leave
		ret
Rpc_Call	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rpc_Reply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reply to most recent request

CALLED BY:	Rpc servers
PASS:		CX	= number of bytes of data
		ES:SI	= Address of reply data
RETURN:		Nothing
DESTROYED:	AX, SI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
Rpc_Reply	proc	near
		uses	es, cx
		.enter
DPW	DEBUG_MEM_WRITE, cx
	;
	; Set up reply header. The id and procNum are just those
	; contained in lastCall.
	; 
		mov	ds:[lastReply].RMB_header.rh_length, cl
		mov	al, ds:[rpc_LastCall].RMB_header.rh_id
		mov	ds:[lastReply].RMB_header.rh_id, al
		mov	al, ds:[rpc_LastCall].RMB_header.rh_procNum
		mov	ds:[lastReply].RMB_header.rh_procNum, al
		mov	ds:[lastReply].RMB_header.rh_flags, RPC_REPLY
	;
	; Copy the data into the reply buffer in case we need to resend it.
	; 
		segxchg	ds, es
		mov	di, offset lastReply.RMB_data
		rep	movsb

	;
	; Write the message out the port.
	; 
		mov	si, offset lastReply
		segmov	ds, es
		mov	cl, ds:[lastReply].RMB_header.rh_length
		add	cx, size RpcHeader
		call	Com_WriteMsg
		.leave		
		ret
Rpc_Reply	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rpc_Error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an error for the most-recently received call

CALLED BY:	Rpc servers
PASS:		AL	= Error code (byte)
RETURN:		Nothing
DESTROYED:	CX, SI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
Rpc_Error	proc	near
		mov	ds:[lastReply].RMB_data, al
		mov	al, ds:[rpc_LastCall].RMB_header.rh_id
		mov	ds:[lastReply].RMB_header.rh_id, al
		mov	al, ds:[rpc_LastCall].RMB_header.rh_procNum
		mov	ds:[lastReply].RMB_header.rh_procNum, al
		mov	ds:[lastReply].RMB_header.rh_flags, RPC_ERROR
		mov	ds:[lastReply].RMB_header.rh_length, 1
		
		mov	cx, size RpcHeader + 1
		mov	si, offset lastReply
		call	Com_WriteMsg
		ret
Rpc_Error	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcHandleCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field an RPC_CALL packet.

CALLED BY:	Rpc_Wait
PASS:		rpc_LastCall holding call packet
RETURN:		nothing
DESTROYED:	ax, bx, cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcHandleCall	proc	near
		.enter
	;
	; Make sure we haven't replied to this already.
	; 

	DPC	<DEBUG_RPC_WAIT or DEBUG_TSR>, 'i'
		mov	al, ds:[rpc_LastCall].RMB_header.rh_id

	DPB	DEBUG_RPC_WAIT, al
	DPB	DEBUG_TSR, al

		cmp	ds:[lastReply].RMB_header.rh_id, al
		jne	notRepliedTo
	;
	; The last reply is for this ID, so resend our previous reply.
	; 
	DPC	DEBUG_RPC_WAIT, 'r'

		mov	si, offset lastReply
		clr	cx
		mov	cl, ds:[lastReply].RMB_header.rh_length
		add	cx, size RpcHeader
		call	Com_WriteMsg
		jmp	done

notRepliedTo:
	;
	; See if the call is currently in-progress.
	; 
		cmp	al, ds:[rpcInProgress].rh_id
		je	sendAck
	;
	; Find the address of the routine serving this procedure
	; number (load it into bx), recording it as the call currently
	; in-progress.
	; 
		mov	bl, ds:[rpc_LastCall].RMB_header.rh_procNum
		mov	ds:[rpcInProgress].rh_procNum, bl
		mov	ds:[rpcInProgress].rh_id, al

	DPC	DEBUG_RPC_WAIT, 'c'
	DPB	DEBUG_RPC_WAIT, bl

		clr	bh
		shl	bx, 1
		mov	bx, ds:[servers][bx]
	;
	; Make sure there's a server defined
	; 
		tst	bx
		jz	noProc		; Ick #2
	;
	; Call the service procedure. It will get its arguments from
	; CALLDATA...
	; 
		jmp	bx
done:
		.leave
		ret
sendAck:
	;
	; Received a retransmission for a call that's already in progress, so
	; just send an explicit ACK back to the host so it doesn't time out.
	; 
	DPC	DEBUG_RPC_WAIT, 'a'

		mov	si, offset rpcInProgress
		mov	cx, size rpcInProgress
		call	Com_WriteMsg
		jmp	done
		

noProc:
	DPC	DEBUG_RPC_WAIT, 'N'
	;
	; Undefined procedure -- report that error back to the host.
	; Rpc_Error will return to Rpc_Wait for us...
	; 
		mov	ax, RPC_NOPROC
		jmp	Rpc_Error
RpcHandleCall	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rpc_Wait
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait for an RPC packet to come in and dispatch it.

CALLED BY:	Rpc_Run, ComInterrupt
PASS:		SaveState should have been called before us. This means:
			ES, DS, SS set up for our segments
RETURN:		Nothing
DESTROYED:	AX, BX, CX, SI plus anything nuked by the servers. Basically
		everything but the segment registers and BP and SP.

PSEUDO CODE/STRATEGY:
	Read the header as a block via Com_ReadBlock (which won't return
		until the block is complete) into lastCall
	Figure how many bytes of data follow and read them into CALLDATA
	If packet is a call, find its server in the servers array.
		If the server is non-zero, jump to it.
		Else, return an RPC_NOPROC error.
	If packet is a reply or error, set the replied system flag true and
		return
	If it's anything else, drop it on the floor.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
Rpc_Wait	proc	near
		DPC	DEBUG_RPC_WAIT, 'W', inv
		DPC	DEBUG_TSR, 'W', inv
	;
	; Make sure interrupts are on so we can receive data.
	; NOTE: we do *not* set the waiting flag in here as RpcInterrupt
	; needs to know whether Rpc_Wait was called from ComInterrupt or
	; from Rpc_Run.
	; 
		eni
waitLoop:
	;
	; Fetch the next message from the serial line.
	;
		segmov	ds, cs, ax
		mov	es, ax
		
		mov	di, offset rpc_LastCall
		mov	cx, size rpc_LastCall
		call	Com_ReadMsg
		jc	RWRet		; error => bail (might have been
					;  called from ComInterrupt and
					;  must needs return if received
					;  message is hosed)

		jcxz	checkResends

	DPC	DEBUG_RPC_WAIT, 'p'
	DPW	DEBUG_RPC_WAIT, cx
		
		sub	cx, size RpcHeader
		cmp	cl, ds:[rpc_LastCall].RMB_header.rh_length
if DEBUG AND DEBUG_RPC_WAIT
		je	packetOK
	DPC	DEBUG_RPC_WAIT, 'l', inverse
		jmp	RWRet
packetOK:
else
		jne	RWRet		; should have been complete!
endif
	;
	; What sort of packet is it?
	; 
		mov	al, ds:[rpc_LastCall].RMB_header.rh_flags
		test	al, RPC_REPLY OR RPC_ERROR
		jnz	replyOrError		; Reply or error
		test	al, RPC_CALL
		jz	RWRet		; Ick

		call	RpcHandleCall
		jmp	RWRet

checkResends:
	;
	; See if any pending calls need to be resent.
	; 
		les	bx, ds:[rpcCurCall]
resendLoop:
		tst	bx
		jnz	doResend

	; don't allow control-Cingout of the swat stub if we are attached
		test	cs:sysFlags, MASK connected
		jnz	waitLoop
	; see if an exit key was pressed, if so we are out of here
	; control C exits unless GEOS has taken over the keyboard...
	; in which case nothing happens, but at that point you can just
	; exit geos...
		mov	ah, 11h
		int	16h
		jz	waitLoop
		mov	ah, 10h
		int	16h
		cmp	al, 3		; control c gives a 3
		jne	waitLoop

		call	RpcExit
		.unreached

doResend:		
		mov	ax, es:[bx].RC_resend
		sub	ax, ds:[stubCounter]
		jg	nextCall
		tst	es:[bx].RC_replied
		jnz	nextCall
		call	RpcResend
nextCall:
		mov	bx, es:[bx].RC_next
		jmp	resendLoop

replyOrError:
	;
	; Find the call to which the reply or error pertains and
	; store the appropriate value in its RC_replied field.
	; 
	DA	DEBUG_RPC_WAIT, <push ax>
	DPC	DEBUG_RPC_WAIT, 'y'
	DA	DEBUG_RPC_WAIT, <pop ax>

		mov	ah, ds:[rpc_LastCall].RMB_header.rh_id
		
		les	bx, ds:[rpcCurCall]
findCallLoop:
	DA	DEBUG_RPC_CALL_VERBOSE, <push ax>
	DPC	DEBUG_RPC_CALL_VERBOSE, 't'
	DPW	DEBUG_RPC_CALL_VERBOSE, bx
	DA	DEBUG_RPC_CALL_VERBOSE, <pop ax>

		tst	bx
		jz	dropReply	; just drop it...
		
		cmp	es:[bx].RC_header.rh_id, ah
		je	foundCall
		mov	bx, es:[bx].RC_next
		jmp	findCallLoop
foundCall:
		mov	es:[bx].RC_replied, al
	DPC	<DEBUG_RPC_CALL_VERBOSE or DEBUG_RPC_WAIT>, 'f'
	DPB	DEBUG_RPC_WAIT, ds:[rpc_LastCall].RMB_header.rh_id
	DPW	DEBUG_RPC_CALL_VERBOSE, es:[bx].RC_resend
	DPW	DEBUG_RPC_CALL_VERBOSE, ds:[stubCounter]

dropReply:
		segmov	es, ds		; es <- cgroup again
RWRet:
		ret
Rpc_Wait	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Rpc_Run
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run the RPC system indefinitely.

CALLED BY:	GLOBAL
PASS:		Nothing
RETURN:		Never
DESTROYED:	What do you care?

PSEUDO CODE/STRATEGY:
		This simply loops infinitely, calling Rpc_Wait each time
		through. When the machine is continued, we will effectively
		do a longjmp right through this beast.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
Rpc_Run		proc	near
		;
		; Tell ComInterrupt we're waiting for it.
		; 
		segmov	ds, cs, ax
		mov	es, ax

		DPC	DEBUG_RPC_WAIT, 'N', inv
		ornf	ds:[sysFlags], MASK waiting
		andnf	ds:[sysFlags], not mask dontresume
RRun1:
		call	Rpc_Wait
		jmp	RRun1
Rpc_Run		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RpcAbortCalls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Abort all the calls currently in-progress, as Swat has
		restarted on the host machine and sending such a call could
		really screw it up.

CALLED BY:	RpcBeep
PASS:		ds = es = cgroup
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RpcAbortCalls	proc	near
		uses	es
		.enter
		les	bx, ds:[rpcCurCall]
abortLoop:
		tst	bx
		jz	done
		ornf	es:[bx].RC_replied, RPC_ERROR
		mov	bx, es:[bx].RC_next
		jmp	abortLoop
done:
		.leave
		ret
RpcAbortCalls	endp

scode		ends
		end
