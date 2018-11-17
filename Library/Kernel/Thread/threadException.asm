COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Thread -- exception handling
FILE:		threadException.asm

AUTHOR:		Adam de Boor, Jun 30, 1990

ROUTINES:
	Name			Description
	----			-----------
    GLB	ThreadHandleException	System call to set exception handler for
    				a thread.
    EXT	ThreadFindStack		Return the stack segment for the given thread.
    EXT ThreadRestoreExceptions	Restore processor exception interrupt vectors
    				to their original state.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/30/90		Initial revision


DESCRIPTION:
	Functions to deal with processor exceptions.
		

	$Id: threadException.asm,v 1.1 97/04/05 01:15:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadFindStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the stack segment for the given thread.

CALLED BY:	EXTERNAL
PASS:		bx	= handle of thread whose stack segment is desired
		ds	= idata
RETURN:		ax	= stack segment for thread
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Must deal with threads context switching inside DOS. If this happens,
	HT_saveSS does *not* point to the thread's stack segment. Rather,
	it points into DOS itself, where there is no ThreadPrivateData.
	DOS saves the old SS:SP at PSP_userStack in the current process's
	(always geos itself) program segment prefix, from whence we may
	pluck it at need (this is true in DOS 2.X, 3.X and 4.X). We must,
	however, be careful the thread in question is not the current
	thread, as the HT_saveSS will remain the DOS stack until the
	thread context switches. If the thread being examined is the
	current one, we can (and do) just use SS itself...

	4/23/94: changed to use a linked list of stack blocks and just
	traverse that, to cope with stack-switching in the video driver.
	Stacks are fixed, so we just run through the list until we find a
	block whose TPD_threadHandle is the thread for which the stack is
	desired -- ardeb

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadFindStack	proc	far
		uses	si, es
		.enter
		mov	si, offset threadStackPtr - offset HM_usageValue
stackLoop:
		mov	si, ds:[si].HM_usageValue
EC <		tst	si						>
EC <		ERROR_Z	ILLEGAL_THREAD					>
		mov	es, ds:[si].HM_addr
		cmp	es:[TPD_threadHandle], bx
		jne	stackLoop

		mov	ax, es
		.leave
		ret
ThreadFindStack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadHandleException
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Define a handler function for a thread to field one of the
		defined processor exceptions.

CALLED BY:	GLOBAL
PASS:		ax	= ThreadException
		bx	= thread for which to define the handler, or 0 for
			  current thread.
		cx:dx	= segment:offset of fixed-memory handler routine
			= 0:0 to return to using system default handler
RETURN:		bx	= thread modified
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadHandleException	proc	far	uses ds, es, cx, dx
		.enter
EC <		cmp	ax, ThreadException				>
EC <		ERROR_AE	INVALID_THREAD_EXCEPTION		>
EC <		test	ax, 0x3						>
EC <		ERROR_NZ	INVALID_THREAD_EXCEPTION		>

	;
	; Figure the thread to modify
	;
		LoadVarSeg	ds
		tst	bx
		jnz	haveThread
		mov	bx, ds:[currentThread]
haveThread:
EC <		call	ECCheckThreadHandle				>
	;
	; Locate its stack segment so we can change the TPD
	;
		push	ax
		call	ThreadFindStack
		mov	es, ax
		pop	ax
		xchg	bx, ax

		jcxz	useDefault
storeHandler:
	;
	; Store the handler away in its slot.
	;
		mov	ds, es:[TPD_exceptionHandlers]
		cmp	ds:[TEH_referenceCount], 1
		ja	newBlock

		movdw	ds:[TEH_divideByZero+bx], cxdx
		xchg	ax, bx

		.leave
		ret
useDefault:
	;
	; Fetch the default handler from that for the kernel.
	;
		mov	ds, ds:[kTPD.TPD_exceptionHandlers]
		movdw	cxdx, ds:[TEH_divideByZero+bx]
		jmp	storeHandler

newBlock:
	;
	; The ThreadExceptionHandlers block is referenced by multiple threads.
	; Since we want to modify it for only one thread, we need to allocate
	; a new ThreadExceptionHandlers block and modify the new block.
	;
		push	ax, bx, cx, si, di, ds
		mov	bx, handle 0		; owned by kernel
		mov	ax, size ThreadExceptionHandlers
		mov	cx, mask HAF_NO_ERR shl 8 or \
				mask HF_FIXED or mask HF_SHARABLE
		call	MemAllocSetOwner

		; copy from old ThreadExceptionHandlers block

		push	es			; save thread stack segment
		mov	ds, es:[TPD_exceptionHandlers]
		mov	es, ax
		clr	si, di
		mov	cx, (size ThreadExceptionHandlers)/2
		rep	movsw
		mov	es:[TEH_handle], bx
		mov	es:[TEH_referenceCount], 1
		pop	es			; restore thread stack segment

		; now set this new block as our ThreadExceptionHandlers block

		mov	es:[TPD_exceptionHandlers], ax

		; decrement old block ref count since we no longer refer to it

		dec	ds:[TEH_referenceCount]
		jnz	notZero

		; the ref count on the old block went to 0, so it must be freed

		mov	bx, ds:[TEH_handle]	; bx = old TEH block handle
		call	MemFree			; free old TEH block
notZero:
		pop	ax, bx, cx, si, di, ds
		jmp	storeHandler

ThreadHandleException	endp

;==============================================================================
;
;			  EXCEPTION HANDLERS
;
;==============================================================================

; LAST_IRQ_INTERCEPT_LEVEL_ONE_IC, from Library/Kernel/Sys/sysVariable.def
if	HARDWARE_INT_CONTROL_8259
LAST_IRQ_INTERCEPT_LEVEL_ONE_IC	equ	7
else
	;	CUSTOM INTERRUPT CONTROLLER CHIP
endif

TEHandler	macro	const

Thread&const&Handler	proc	far
	        call    ThreadJumpToExceptionHandler
	        .unreached
	        word    TEH_divideByZero + TE_&const
Thread&const&Handler	endp

TEDefault	TE_&const
		endm

TEDefault	macro	value
Thread&value&Default	proc	far
		on_stack	iret
		call	ThreadExceptionDefault
					.UNREACHED
		byte	value/4
Thread&value&Default	endp
		endm

TEPassOnIrqDefault	macro	value, irq, oldHandler
Thread&value&PassOnIrqDefault	proc	far
			on_stack	iret

	; See if we are invoked by an IRQ.
		push	ax
			on_stack	ax iret
if	irq le LAST_IRQ_INTERCEPT_LEVEL_ONE_IC
		mov	al, IC_READ_ISR
		out	IC1_CMDPORT, al
		jmp	$+2
		in	al, IC1_CMDPORT
		test	al, 1 shl (irq)
else
	; ddurran said we only need to check the slave controller but don't
	; need to check the master one.
		mov	al, IC_READ_ISR
		out	IC2_CMDPORT, al
		jmp	$+2
		in	al, IC2_CMDPORT
		test	al, 1 shl (irq-8)
endif
		pop	ax
			on_stack	iret
		jz	exception

	; IRQ.  Call old IRQ handler.
		push	ds
			on_stack	ds iret
		LoadVarSeg	ds
		pushf
			on_stack	cc ds iret
		call	ds:[oldHandler]
			on_stack	ds iret
		pop	ds
			on_stack	iret

		iret

exception:
			on_stack	iret
		call	ThreadExceptionDefault
		.unreached
		byte	value/4
Thread&value&PassOnIrqDefault	endp
		endm

TEHandler	DIVIDE_BY_ZERO
TEHandler	OVERFLOW
TEHandler	BOUND

NOSSP <TEHandler	SINGLE_STEP					>
TEHandler	BREAKPOINT

TEDefault	TE_FPU_EXCEPTION	; handled by NMIFrontEnd...
TEDefault	TIE_ILLEGAL_INST

ifdef CATCH_PROTECTION_FAULT
TEPassOnIrqDefault	TIE_PROTECTION_FAULT, (13-8), oldProtFlt
endif

ifdef CATCH_STACK_EXCEPTION
TEPassOnIrqDefault	TIE_STACK_EXCEPTION, (12-8), oldStackExpt
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadJumpToExceptionHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Jump to exception handler

CALLED BY:	TEHandler macro
PASS:		offset of jump vector must be at our return address
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/ 5/96    	Initial version from adam's email

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadJumpToExceptionHandler    proc near call
        push    ax, ds, bx      ; deliberately pushed in this order. saved bx
                                ;  will replace our return address to put
                                ;  regs in proper order for SysJmpVector
        LoadVarSeg ds, ax
        mov     bx, ds:[currentThread]
        call    ThreadFindStack ; ax <- thread's actual stack
        mov     ds, ax
        mov     ds, ds:[TPD_exceptionHandlers]
        mov     bx, sp
        mov     bx, ss:[bx+6]   ; bx <- our return address
        mov     ax, cs:[bx]     ; ax <- vector to jump through
        mov     bx, sp
        pop     ss:[bx+6]       ; put saved bx in the proper place
        mov_tr  bx, ax          ; bx <- vector to jump through
        jmp     SysJmpVector
ThreadJumpToExceptionHandler    endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadExceptionDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler for an exception in a thread

CALLED BY:	Individual default exception handlers
PASS:		following return address: byte that is the interrupt
			number
RETURN:		doesn't
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadExceptionDefault	proc	near
				on_stack	retn
		LoadVarSeg	ds, ax

		mov	al, KS_TE_SYSTEM_ERROR
		call	AddStringAtMessageBuffer
	;
	; Fetch the exception string based on byte stored after the call to us.
	;
		pop	si
				on_stack	iret
		lodsb	cs:
		add	al, KS_TE_DIVIDE_BY_ZERO
		call	AddStringAtESDI
		
	;
	; Record a single fault.  This way, the GEOS_CRASHED file will not
	; be removed, which is a good thing, since by default we have crashed
	; if an exception is taken
	;
		inc	ds:[errorFlag]		
	;
	; Call SysNotify to tell the user what's happened.
	;
ifdef	GPC
		mov	ax, mask SNF_REBOOT	; unrecoverable - reboot
else
		mov	ax, mask SNF_EXIT or mask SNF_REBOOT or mask SNF_BIZARRE
endif
		call	SysNotifyWithMessageBuffer
	;
	; If we return, we're trying to exit cleanly, so go handle the thread's
	; event queue.
	;
		clr	bx
		call	ThreadAttachToQueue
		.UNREACHED
ThreadExceptionDefault	endp

ifdif HARDWARE_TYPE,<ZOOMER>
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NMIFrontEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front-end function for handling an NMI. Anything
		we don't recognize, we pass on. In 2.0, this'll
		want to check the coprocessor, too...

CALLED BY:	NMI
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NMIFrontEnd	proc	far
	;
	; The NMI source is recorded in the high two bits of port 61h (AT)
	; or 62h (XT).  The following values have the following meaning:
	;	00	= source unknown -- pass it on
	;	01	= mother-board parity error
	;	10	= I/O channel error (usually a parity error on
	;		  a memory expansion board)
	;	11	= power failure imminent (e.g. for laptops shutting
	;		  down to low-power mode) -- pass it on
	;
		push	ax, ds
		mov	ax, dgroup
		mov	ds, ax
		clr	ax

		cmp	ds:[sysMachineType], SMT_PC_XT_286
		jb	xt
		in	al, 61h
		jmp	gotFlags
xt:
		in	al, 62h
gotFlags:

		; get the carry flag to hold the XOR of b7 and b6. if the
		; result is 0 (00 and 11 cases above), we want to pass it
		; on.

		shl	ax
		rol	al
		xor	al, ah
		shr	al
		pop	ax, ds
		jnc	passOn
	;
	; Trap the thing. Allow interception in case some app is doing
	; something that can legally generate an IOCHK...
	;
	        call    ThreadJumpToExceptionHandler
	        .unreached
	        word    TEH_fpuException
passOn:
	;
	; Here's where we'd look for a coprocessor error...
	;
		sub	sp, 4
		push	ds
		push	bp
		push	ax
		mov	ax, dgroup
		mov	ds, ax
		mov	bp, sp
		movdw	ss:[bp+6], ds:[oldFPU], ax
		pop	ax
		pop	bp
		pop	ds
		retf

NMIFrontEnd	endp
endif	; !ZOOMER

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadRestoreExceptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore exception interrupt vectors on exit

CALLED BY:	EndGeos
PASS:		ds	= idata
RETURN:		nothing
DESTROYED:	ax, cx, di, es, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadRestoreExceptions	proc	near
		test	ds:[sysConfig], mask SCF_UNDER_SWAT
		jnz	done

		tst	ds:[oldDBZ].segment	; Have we caught anything?
		jz	done			; no => nothing to reset

		segmov	es, ds
		mov	si, offset exceptions
		mov	cx, ds:[numExceptionsCaught]
restoreLoop:
		inc	si		; skip handler offset
		inc	si
		lodsw
		xchg	di, ax		; di <- offset of save vector
		lodsw			; ax <- interrupt #
		call	SysResetInterrupt
		loop	restoreLoop

done:
		ret
ThreadRestoreExceptions	endp


GLoad	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ThreadInitProcessExceptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the exception vectors in the ThreadPrivateData
		of a new process thread.

CALLED BY:	ProcCreate
PASS:		es	= idata
		ds	= process's dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreadInitProcessExceptions proc near
		uses	es
		.enter
		mov	es, es:[kTPD.TPD_exceptionHandlers]
		inc	es:[TEH_referenceCount]
		mov	ds:[TPD_exceptionHandlers], es
		.leave
		ret
ThreadInitProcessExceptions endp

GLoad	ends
