COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Swat -- Kernel -> Swat communications
FILE:		kernel.asm

AUTHOR:		Adam de Boor, Nov 18, 1988

ROUTINES:
	Name			Description
	----			-----------
	KernelDOS		MS-DOS interceptor
	KernelMemory		DebugMemory interceptor
	KernelProcess		DebugProcess interceptor
	KernelLoadRes		DebugLoadResource interceptor
	Kernel_Hello		Rpc server for RPC_HELLO call
	Kernel_Goodbye		Detach from the kernel
	Kernel_ReadMem		Read from a handle
	Kernel_WriteMem		Write to a handle
	Kernel_FillMem		Fill in a handle
	Kernel_ReadAbs		Read from absolute memory
	Kernel_WriteAbs		Write to absolute memory
	Kernel_FillAbs		Fill in absolute memory
	Kernel_BlockInfo	Return info on a given handle
	Kernel_BlockFind	Locate a block covering an address
	Kernel_ReadRegs		Read registers for a thread
	Kernel_WriteRegs	Write registers for a thread
	Kernel_AttachMem	Attach to a block
	Kernel_DetachMem	Detach from a block
    scode: (was stubInit)
	Kernel_Load		Load the kernel in

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/18/88	Initial revision


DESCRIPTION:
	The functions in this file implement the interface between the GEOS
	kernel and Swat. They intercept the calls to the various Debug
	vectors, transforming the passed information into arguments for the
	proper RPC calls.
		

	$Id: kernel.asm,v 2.71 97/02/13 15:20:10 guggemos Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Kernel		= 1
KERNEL		= 1

		include stub.def

		include geos.def		;for Semaphore
		include ec.def			;for FatalErrors
		include	heap.def		;for HeapFlags
		include	geode.def
		include Internal/geodeStr.def
		include Internal/debug.def
		include	thread.def		;for ThreadPriority
		include Internal/heapInt.def	; HandleMem/ThreadBlockState
		include	Internal/dos.def	;for PSP_userStack
		include system.def		;for things needed by kLoader
		include Internal/kLoader.def
		include Internal/fileInt.def
		include	Internal/fileStr.def
		include	Internal/xip.def

.386
sstack		segment
		extrn	tpd:ThreadPrivateData
sstack		ends

scode		segment

		assume	cs:scode,ds:cgroup,es:cgroup,ss:sstack

kernelHeader	ExeHeader	<>
kernelSSSelector        word    0ffffh
kernelCSSelector        word    0ffffh
kernelDSSelector        word    0ffffh
kernelPSPSelector       word    0ffffh
kernelBIOSSelector      word    0ffffh
stubCSSelector        word      scode
stubDSSelector        word      scode
loaderStackSize         word    0

kernelVersion	byte	0

;
;	 these table are in place of the tables that did not get into
;	 early releases of the product.  They are tables of nptrs to
;	 internal routines and variables in the various kernels
;	
InternalVectorTable	struct
    IVT_checksum	word			; checksum of kcode that
						;  indicates the table should
						;  be used
    IVT_table		nptr.SwatVectorTable	; the table to use
InternalVectorTable	ends

internalTables	InternalVectorTable	\
		<923ch, upgradeTable>,
		<5b36h, wizardECTable>,
		<8451h, wizardTable>,
		<3067h, zoomerECTable>,
		<7830h, zoomerTable>

kernelVectors	label	SwatVectorTable	; overlay this static one with the
					;  real one
upgradeTable	SwatVectorTable \
<
	0d76h, 0f0eh, 0d7ch, 0d63h, 0a34h, 0000h, 0005h, 000ah, 6922h, 
	019bh, 0a410h, 09e3h, 0a16h, 0000h, 0000h, 0000h, 0dcah, 0041h, 
	01051h, 0000h, 0155h, 0198h, 850dh, 85beh, 8672h, 88ffh, 874ch, 
	8770h, 8618h, 862ch, 862dh, 8638h, 861ah, 862ch, 17b9h, 17beh, 
	169ah, 17b6h, 954ah, 9550h, 956ah, 956eh, 955bh, 9564h, 0a11fh, 
	0a158h
>

wizardTable	SwatVectorTable \
<
    0d76h, 0f0eh, 0d7ch, 0d63h, 0a34h, 0000h, 0005h, 000ah, 696fh,
    01fah, 0a496h, 0a43h, 0a76h, 0000h, 0000h, 0000h, 
    0dcah, 0041h, 10b1h, 1154h, 01b4h, 01f7h, 856bh, 861ch, 87aah, 87c2h,
    086d0h, 0895ch, 8676h, 868ah, 868bh, 8696h, 8678h, 868ah, 17f2h,
    17f4h, 16d3h, 17efh, 95aeh, 95b4h, 95cah, 95c9h, 95bfh, 95c9h, 
    0a1a5h, 0a1deh
>

wizardECTable	SwatVectorTable \
<
    0dc0h, 0f5ah, 0d6ch, 0dadh, 0a78h, 0000h, 0005h, 000ah, 7945h,
    0215h, 0c3e2h, 0bdch, 0c1dh, 0c91h, 0c93h, 0c8fh, 
    0e16h, 0041h, 14cah, 1589h, 1c2h, 0214h, 9dc0h, 9e95h, 0a11fh, 0a13fh,
    0a003h, 0a32fh, 09f81h, 09f86h, 9f98h, 9fa2h, 9f87h, 9f97h, 1ceah,
    1cf4h, 1bc4h, 1ce7h, 0b21eh, 0b224h, 0b23eh, 0b242h, 0b22fh, 0b239h,
    0c038h, 0c071h    
>

zoomerTable	SwatVectorTable \
<
    0d76h, 0f0eh, 0d7ch, 0d63h, 0a34h, 0000h, 0005h, 000ah, 06902h,
    019bh, 0a423h, 09d8h, 0a0bh, 0000h, 0000h, 0000h, 
    0dcah, 0041h, 1046h, 10dfh, 0155h, 019ah, 084feh, 085afh, 0873dh, 08755h,
    8663h, 88f9h, 8609h, 861dh, 861eh, 8629h, 860bh, 0861dh, 1785h,
    1787h, 1666h, 1782h, 9541h, 9547h, 9561h, 9565h, 9552h, 955ch,
    0a132h, 0a16bh
>
    
zoomerECTable	SwatVectorTable \
<
    0dc0h, 0f5ah, 0dc6h, 0dadh, 0a78h, 0000h, 0005h, 000ah, 78d8h,
    01b6h, 0c36fh, 0b71h, 0bb2h, 0c91h, 0c93h, 0c8fh, 
    0e16h, 0041h, 145fh, 151eh, 0163h, 01b5h, 9d53h, 9328h, 0a0b2h, 0a0d2h,
    9f96h, 0a2c1h, 9f14h, 9f19h, 9f2bh, 9f35h, 9f1ah, 9f2ah, 1c7dh,
    1c87h, 1b57h, 1c7ah, 0b1b1h, 0b1b7h, 0b1d1h, 0b1d5h, 0b1c2h, 0b1cch,
    0bfc5h, 0bffeh
>


previousReadOnlyES  word
kernelCore	hptr			; Handle of kernel's core block
loaderBase	sptr			; Current base of the loader
lastHandle	word			; End of handle table
HandleTable	word			; Start of handle table
resourceBeingLoaded	hptr		; Handle of resource currently being
					;  loaded so the Kernel_SegmentToHandle
					;  finds the resource, rather than
					;  the block to which the resource
					;  was loaded.

xipHeader	word	0		; segment value fo xipHeader
oldXIPPage	word	BPT_NOT_XIP	; save old page number for when
					; swat pages in a new page
xipPageSize	word	0
;xipPageAddr	equ	<kernelVectors.SVT_MAPPING_PAGE_ADDRESS>
xipPageAddr	word	0

;MAPPING_PAGE_SIZE = 4000h
;MAPPING_PAGE_ADDRESS = 0c800h

if TRACK_INT_21
int21Counts	word	256 dup(?)
bytesRead	dword	0
endif

;
; Macro to create an IRET frame on the stack w/o writing to memory. Needed
; since we might be running in write-protected RAM.
;
; DISABLES INTERRUPTS  
;

CreateNearFrame	macro
		push	cs:[kcodeSeg]	; PUSH CS
		pushf			; Save flags
		push	bp		; And BP
		mov	bp, sp		;  so we can play with the stack
		push	ax		; Save temp register
		mov	ax, 2[bp]	; Fetch flags word
		xchg	ax, 6[bp]	; Exchange with IP that was saved
					;  on near call to our far jump
		mov	2[bp], ax	; Store IP in proper place. Stack
					;  now holds FLAGS:CS:IP:BP:AX
		pop	ax		; Recover saved registers
		pop	bp
		dsi
		endm

CreateFarFrame	macro
		pushf			; save flags
		push	bp		; and BP
		mov	bp, sp		; so we can play with the stack
		push	ax		; save our temp reisger
		mov	ax, 2[bp]	; fetch the flags
		xchg	ax, 6[bp]	; ax = code seg, flags put on stack
		xchg	ax, 4[bp]	; ax = IP, code seg put on stack
		mov	2[bp], ax	; IP put on stack, stack now holds
					;  FLAGS:CS:IP:BP:AX
		pop	ax		; recover saved registers
		pop	bp
		dsi
		endm
;	
; Stuff for DOS interception
;
;dosAddr		fptr.far	-1	; INT 21h handler
;dosThread	word			; Thread in dos
;dosSP		word			; SP of thread in dos
;dosSS		word			; SS of thread in dos

;
; Kernel things -- from the HelloArgs packet
; 
kdata		word			; Segment address of kdata segment
        ;NOTE!!! Need to convert to selector at some point

heapSemOff	equ	<kernelVectors.SVT_heapSem>
sysECLevelOff	equ	<kernelVectors.SVT_sysECLevel>
DebugProcessOff	equ	<kernelVectors.SVT_DebugProcess>
BlockOnLongQueueOff equ	<kernelVectors.SVT_BlockOnLongQueue>
sysECBlockOff	equ	<kernelVectors.SVT_sysECBlock>
sysECChecksumOff equ	<kernelVectors.SVT_sysECCheckSum>

MemLockVec	fptr.far		; Vector to MemLock routine
FileReadVec	fptr.far		; Offset to FileRead routine
FilePosVec	fptr.far		; Offset to FilePos routine
MapXIPPageVec	fptr.far
SysCSVec	fptr.far

readGeodeSem	byte	0

topLevelPath	PathName	<"">	; save KLV_topLevelPath here to use in
					;  RPC_FIND_GEODE and RPC_SEND_FILE

ReloadStates	etype	byte
RS_IGNORE	enum	ReloadStates,0	; Kernel reload not pending
RS_WATCH_EXEC	enum	ReloadStates	; Look for load/exec as signal of
					;  kernel reload
RS_INTERCEPT	enum	ReloadStates	; load/exec seen; intercept when
					;  DOS returns

reloadState	ReloadStates RS_IGNORE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelFindMaxSP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the stack segment for a thread, locate its maximum
		SP.

CALLED BY:	KernelProcess, Kernel_Hello
PASS:		ES	= kdata
		DS	= scode
		AX	= stack segment
RETURN:		AX	= maximum SP
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelFindMaxSP	proc	near
		push	ds, bx, cx
		mov	ds, ax
		;
		; Assume the SS is correct and fetch the handle that should
		; be at TPD_blockHandle in the segment
		;
		mov	bx, ds:TPD_blockHandle
		test	bx, 0fh		; Valid handle?
		jnz	SomethingHuge	; No
		mov_tr	cx, ax		; save ax in cx
		call	Kernel_GetHandleAddress
		cmp	ax, cx
		jne	SomethingHuge	; No
		mov	ax, es:[bx].HM_size	; Convert size to bytes
		shl	ax, 1			;  from paragraphs
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1
KFMSPRet:
		pop	ds, bx, cx
		ret
SomethingHuge:
		;
		; On the theory that it is better to see some useful frames
		; and then spend a lot of time doing useless searches, as
		; opposed to getting an immediate "frame not valid" error,
		; we return -2 as the maximum SP for something whose block
		; we cannot find.
		;
		mov	ax, 0fffeh
		jmp	KFMSPRet
KernelFindMaxSP	endp

if INT21_INTERCEPT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelReloadSys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify Swat that the system is reloading

CALLED BY:	KernelDOS
PASS:		flags on stack
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelReloadSys	proc	far		; must be far to establish proper
					;  interrupt frame
		.enter
		call	SaveState
	;
	; Stick in our hook at the base of the loader code segment
	;
		push	es
		mov	es, ds:[kernelHeader].exe_cs
		call	Kernel_EnsureESWritable	; ax <- token
		mov	{word}es:[0], 0x9a9c	; PUSHF / CALL FAR PTR
		mov	{word}es:[2], offset KernelLoader
		mov	{word}es:[4], cs
		call	Kernel_RestoreWriteProtect
		mov	ds:[kernelCore], 0	; kernel core block
						;  unknown

		mov	ax, es
		pop	es
		mov	{word}ds:rpc_ToHost, ax
		mov	ax, RPC_RELOAD_SYS
		mov	bx, offset rpc_ToHost
		mov	cx, size word
		andnf	ds:sysFlags, not (mask dosexec or mask nomap)
		call	Rpc_Call
		call	RestoreState
		; NO WRITES UNTIL POP_PROTECT -- RestoreState write-protects
		.leave
		ret
KernelReloadSys	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelDOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept DOS calls to record the ID and SS:SP of the thread
		currently in DOS, as well as to catch the exit of PC GEOS.

CALLED BY:	INT 21h
PASS:		...
RETURN:		...
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelDOS	proc	far
		test	cs:[sysFlags], mask connected
		jz	checkExit

		;
		; Save registers we need
		;
		push	ds
		push	ax
		push	bx
		;
		; Turn off write-protect so we can play. We're careful to 
		; maintain the state of the write-protect bit because we
		; also intercept the function 52h call in Kernel_Hello (we
		; can't just avoid intercepting DOS until later b/c the user's
		; Swat may die and be restarted, causing us to attach w/o
		; having detached first).
		;
		PUSH_ENABLE
	DA DEBUG_DOS, <push ax>
	DPC DEBUG_DOS, 'd'
	DA DEBUG_DOS, <pop ax>
	DPW DEBUG_DOS, ax
		;
		; Fetch the current thread from the kernel and save it in
		; dosThread.
		;
		mov	ds, cs:kdata
		mov	bx, cs:currentThreadOff
		mov	ax, ds:[bx]
                push    ds
                PointDSAtStub
		mov	ds:dosThread, ax

		;
		; Save the SS:SP of the current thread
		;
		mov	ax, sp
		add	ax, 6		; Adjust for register still on stack
		mov	ds:dosSP, ax
		mov	ds:dosSS, ss

if TRACK_INT_21
                ; Make sure ds is point at scode
		mov	bx, sp
		mov	ax, ss:[bx+2]	; ah <- DOS call
		mov	bl, ah
		clr	bh
		shl	bx
		inc	ds:[int21Counts][bx]
		cmp	ah, MSDOS_READ_FILE
		jne	trackingDone
		add	ds:[bytesRead].low, cx
		adc	ds:[bytesRead].high, 0
trackingDone:
endif
                pop     ds
		;
		; Re-enable write-protect so DOS doesn't stomp us
		;
		POP_PROTECT
		;
		; Restore the registers we've abused
		;
		pop	bx
		pop	ax
		pop	ds

		;
		; Handle kernel reload
		;
		tst	cs:[reloadState]
		jz	checkExit
		cmp	ax, MSDOS_EXEC shl 8 or MSESF_LOAD_OVERLAY
		jne	checkExit
		push	ax		; Record loader's segment while we've
					;  got es:bx here
		PUSH_ENABLE
                push    ds
                PointDSAtStub
		mov	ds:reloadState, RS_INTERCEPT
		mov	ax, es:[bx]	; First word of argument block must be
					;  segment at which to load the thing
		mov	ds:[kernelHeader].exe_cs, ax
		mov	ds:[loaderBase], ax
		mov	ds:[kdata], ax
                pop     ds
		POP_PROTECT
		pop	ax
checkExit:
		;
		; See if it's an exit call...
		;
		cmp	ah, MSDOS_QUIT_APPL
		je	toIsExit
		cmp	ah, MSDOS_TSR
		jne	checkResize
toIsExit:
		jmp	isExit

checkResize:
	;
	; If resizing our child's PSP, we're about to run a DOS program and
	; Swat needs to know about it. We could also be enlarging the PSP,
	; though, to recover from the DOS exec, so check our dosexec flag
	; before issuing the call...
	; 
		cmp	ah, MSDOS_RESIZE_MEM_BLK
		jne	checkFree
		
		test	cs:[sysFlags], mask initialized
		jz	passItOn		; if not intialized, this is
						;  us shrinking ourselves down.

		push	ax
		mov	ax, es
		cmp	ax, cs:[PSP]
		pop	ax
		jne	passItOn

		test	cs:[sysFlags], mask dosexec
		jnz	passItOn

                push    ds
                PointDSAtStub
		mov	{word}ds:[rpc_ToHost], bx	; pass new size
							;  as word arg
                pop     ds
beginDosExec:
	;
	; Common code to signal to Swat that a DosExec is commencing.
	; 
		call	SaveState			; get into our context

		push	ax, si
		call	Bpt_Uninstall
		pop	ax, si
		ornf	ds:[sysFlags], mask dosexec	; flag dosexec so we
							;  know currentThread
							;  existeth not
		andnf	ds:[sysFlags], not mask attached; by definition, if it's
							;  running a DOS program
							;  the kernel ain't
							;  around
		mov	ds:[kernelCore], 0
		test	ds:[sysFlags], mask connected
		jz	execNotifyComplete
		mov	ax, RPC_DOS_RUN			; proc num
		mov	cx, size word			; arg size
		mov	bx, offset rpc_ToHost		; es:bx <- arg addr
		call	Rpc_Call
		test	ds:[sysFlags], mask dontresume	; wants to stop?
		jnz	stopBeforeDosExec		; yes -- do so
execNotifyComplete:
		call	RestoreState			; no -- continue with
		jmp	passItOn			;  our life

stopBeforeDosExec:
		jmp	Rpc_Run			; everything already set up...
checkFree:
	;
	; If freeing kdata, we're about to run a DOS program after having
	; reloaded following the launch of a TSR.
	; 
		cmp	ah, MSDOS_FREE_MEM_BLK
		jne	passItOn

                push    ds
                PointDSAtStub		
		mov	{word}ds:[rpc_ToHost], 0	;assume so
                pop     ds
		push	ax
		mov	ax, es
		cmp	ax, cs:[kdata]
		pop	ax
		je	beginDosExec

		;
		; Make like we called DOS with an interrupt.
		;
passItOn:
I21IFrame struct
    I21IF_bp	word
    I21IF_ax	word
    I21IF_retf	fptr.far
    I21IF_flags	word
I21IFrame ends

	;
	; push the flags originally passed to us so interrupts are in the
	; right state when DOS returns to us.
	;
		push	ax
		push	bp
		mov	bp, sp
		mov	ax, ss:[bp].I21IF_flags
		xchg	ax, ss:[bp].I21IF_ax
		pop	bp

		dsi
		call	cs:dosAddr

		push	ax		; save ax from possible biffing
		PUSH_ENABLE

		;
		; Clear out dosThread so we don't get confused.
		;
                push    ds
                PointDSAtStub
		mov	ds:dosThread, 0
                pop     ds
		
		pushf
		cmp	cs:reloadState, RS_INTERCEPT
		jne	20$
		;
		; Re-intercept the various debug vectors, then give notice
		; to Swat that the kernel has been reloaded.
		;
                push    ds
                PointDSAtStub
		mov	ds:reloadState, RS_IGNORE
                pop     ds
		call	KernelReloadSys
		;
		; Test for interrupt request only now, not inside SaveState/
		; RestoreState, so we can give the user a reasonable context
		; if we do need to stop.
		;
		test	cs:sysFlags, mask dontresume
		jnz	stop
20$:
		popf

		POP_PROTECT
		pop	ax		; restore ax after possible biffing


		ret	2		; Nuke the flags, since DOS likes
					; to return things in CF...
isExit:
	;
	; A child process is exiting somehow. If the current process' parent
	; process is the kernel, set reloadState to watch for load-overlay
	; 
		PUSH_ENABLE
		push	ax, bx, es
		mov	ah, MSDOS_GET_PSP
		pushf
		dsi
		call	cs:[dosAddr]
		mov	es, bx
	DPW DEBUG_DOS, bx
	DA DEBUG_DOS, <mov ax, es:[PSP_parentId]>
	DPW DEBUG_DOS, ax
	DA DEBUG_DOS, <mov ax, cs:[PSP]>
	DPW DEBUG_DOS, ax
		mov	ax, cs:[PSP]
		cmp	es:[PSP_parentId], ax
		jne	exitHandlingComplete
                push    ds
                PointDSAtStub
		mov	ds:[reloadState], RS_WATCH_EXEC
                pop     ds
exitHandlingComplete:
		pop	ax, bx, es
		POP_PROTECT
		jmp	passItOn

stop:
		;
		; Stop requested by remote. Alter the flags of our return
		; address to match the flags returned by DOS so Rpc_Run can
		; just to a RestoreState and iret and not fuck anything up.
		; Note that we do all this weird stuff b/c we don't know
		; whether PUSH_ENABLE actually pushed anything, or how much,
		; if it did.
		;
		popf			; Fetch current flags.
		POP_PROTECT		; Recover protection state
		pop	ax		; Recover ax
		pushf			; Only way to get whole word...
		push	bp		; So we can address the stack
		mov	bp, sp
		push	ax		; Temporary register
		mov	ax, ss:[bp][2]	; Fetch flags
		mov	ss:[bp][8], ax	; Stuff in return. Stack is:
					;  	bp, flags, ip, cs, flags
		pop	ax
		pop	bp
		popf			; "discard"
		call	SaveState
		jmp	Rpc_Run

KernelDOS	endp
endif
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelMemoryBankPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deal with a new page being banked in

CALLED BY:	KernelMemory

PASS:		bx = page number

RETURN:		nothing

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	find all pending breakpoints and deal with them
			appropriately
KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/27/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KernelMemoryBankPage	proc	near
		uses	es, bx
		.enter
	; fetch the new current page and let the breakpoint module
	; do its thing

		DA	DEBUG_XIP, <push ax>
		DPS	DEBUG_XIP, BANK
		DPW	DEBUG_XIP, bx
		DPW	DEBUG_XIP, ds:[oldXIPPage]
		DA	DEBUG_XIP, <pop ax>
		mov	es, ds:[kdata]
		mov	bx, ds:[curXIPPageOff]
		mov	bx, es:[bx]
		call	Bpt_UpdatePending
		.leave
		ret
KernelMemoryBankPage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelMemory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HandleMem a change to the kernel's memory state

CALLED BY:	Kernel functions
PASS:		AL	= Function code:
			    DEBUG_REALLOC   - block reallocated
			    DEBUG_DISCARD   - block discarded
			    DEBUG_SWAPOUT   - block swapped out
			    DEBUG_SWAPIN    - block swapped in
			    DEBUG_MOVE	    - block moved
			    DEBUG_FREE	    - block freed
			    DEBUG_MODIFY    - block flags modified
			    DEBUG_BANK_PAGE - Bank in an XIP page
			
		BX	= affected handle (or page for DEBUG_SWAPPAGE)
		DX	= segment of affected block if address is needed
			  and [bx].HM_addr is 0
		DS	= kernel data segment
		ES	= destination segment for DEBUG_MOVE
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
       See if the block is being debugged. If not, return right away.
       
       Save current state.
       Put together proper rpc based on function code and send it
       Return.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KernelMemoryFar	proc	far
		CreateFarFrame		; INT_OFF
		jmp	KernelMemory
KernelMemoryFar	endp

KernelMemory	proc	near
		;
		; Form interrupt frame on stack in case we need to save state
		; 
	
	; if its an XIP page being banked in we can skip this stuff about
	; blocks changing as its not relavent for XIP pages
		cmp	al, DEBUG_BANK_PAGE
		je	KM1
	;
	; Deal with any breakpoints we've got set, regardless of whether the
	; host cares.
	; 
		call	Bpt_BlockChange
		cmp	bx, HID_KDATA	; Special case kernel
					; motion/resize/discard
		jbe	KM1
	;
	; If notification comes while we're on our own stack, it means
	; it happened because of us, and Swat has this handle in its
	; table, regardless of the HF_DEBUG bit, so we need to notify
	; it...
	;
		push	ax
		mov	ax, ss
		cmp	ax, sstack
		pop	ax
		je	KM1

		test	ds:[bx].HM_flags, MASK HF_DEBUG
		LONG jz	KMRet
KM1:
		;
		; Block is actually being debugged -- tell Swat what's up
		; 
		call	SaveState
		;
		; Load handle address into es:bx for access
		; 
		mov	bx, [bp].state_bx
		mov	es, ds:[kdata]
		mov	ax, [bp].state_ax
		
		cmp	al, DEBUG_BANK_PAGE
		jne	notBank
		
	; if a new page is banked in, we need to update the pending breakpoints
	; that fall in that page
		call	KernelMemoryBankPage
		jmp	KM6
notBank:
		;
		; All calls take handle as first arg.
		; 
		mov	{word}ds:[rpc_ToHost], bx

		cmp	al, DEBUG_REALLOC
		jne	KM2
;		mov	ax, es:[bx].HM_addr
		call	Kernel_GetHandleAddress
		tst	ax
		jnz	reallocHaveSegment
		mov	ax, ss:[bp].state_dx
reallocHaveSegment:
		mov	({ReallocArgs}ds:[rpc_ToHost]).rea_dataAddress, ax
		mov	ax, es:[bx].HM_size
		mov	({ReallocArgs}ds:[rpc_ToHost]).rea_paraSize, ax
		mov	cx, size ReallocArgs
		mov	ax, RPC_BLOCK_REALLOC
		jmp	short KMSend
KM2:
		cmp	al, DEBUG_SWAPOUT
		jg	KM3
		;
		; DISCARD or SWAPOUT -- load oa_discarded with ffff if discard
		; and 0 if swapped (DISCARD is 1, SWAPOUT is 2...)
		; 
		sub	al, DEBUG_SWAPOUT
		cbw
		mov	({OutArgs}ds:[rpc_ToHost]).oa_discarded, ax
		mov	cx, size OutArgs
		mov	ax, RPC_BLOCK_OUT
		jmp	short KMSend
KM3:
		cmp	al, DEBUG_SWAPIN
		jne	KM4
		;
		; Block swapped in -- Swat needs new data address in a LoadArgs
		; structure. The rpc is RPC_BLOCK_LOAD
		; 
;		mov	ax, es:[bx].HM_addr
		call	Kernel_GetHandleAddress
		mov	({LoadArgs}ds:[rpc_ToHost]).la_dataAddress, ax
		mov	cx, size LoadArgs
		mov	ax, RPC_BLOCK_LOAD
		jmp	short KMSend
KM4:
		cmp	al, DEBUG_MOVE
		jne	KM5
		;
		; Block moved -- Swat needs new data address in a MoveArgs
		; structure. The rpc is RPC_BLOCK_MOVE
		;
		mov	ax, [bp].state_es
		mov	cx, [bp].state_cx
		jcxz	justMove
		;
		; For a regular block, turn the call into a DEBUG_REALLOC
		; to deal with the contracting of LMem blocks by CompactHeap
		;
		mov	({ReallocArgs}ds:[rpc_ToHost]).rea_dataAddress, ax
		mov	({ReallocArgs}ds:[rpc_ToHost]).rea_paraSize, cx
		mov	ax, RPC_BLOCK_REALLOC
		mov	cx, size ReallocArgs
		jmp	KMSend
justMove:
		;
		; No resize involved, so use a regular BLOCK_MOVE call.
		;
		mov	({MoveArgs}ds:[rpc_ToHost]).ma_dataAddress, ax
		mov	cx, size MoveArgs
		mov	ax, RPC_BLOCK_MOVE
		jmp	KMSend
KM5:
		cmp	al, DEBUG_FREE
		jne	KM6
		;
		; Block freed -- already have the sole argument (the handle ID)
		; in the argument record. The rpc is RPC_BLOCK_FREE
		; 
		mov	cx, size hptr
		mov	ax, RPC_BLOCK_FREE
KMSend:
		;
		; Perform the actual RPC. When it returns, we're allowed to
		; continue.
		; 
		mov	bx, offset rpc_ToHost
		push	cs
		pop	es
		call	Rpc_Call

		test	ds:[sysFlags], mask dontresume	; if interrupt during
		jz	KM6				;  call, act on it now
		jmp	Rpc_Run
KM6:
		;
		; Fall-through point for any unknown (or unhandled) function
		; code. Restore state and return.
		; 
		call	RestoreState
KMRet:
		;
		; We created an interrupt frame up above, so use it now
		; 
		iret
KernelMemory	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HandleMem calls to the kernel's DebugProcess vector

CALLED BY:	Kernel for geode/thread state changes
PASS:		AL	= Function code:
			    DEBUG_EXIT_THREAD	- thread death
			    DEBUG_EXIT_GEODE	- geode death
			    DEBUG_CREATE_THREAD	- new thread created
			    DEBUG_LOAD_DRIVER	- new driver loaded
			    DEBUG_LOAD_LIBRARY	- new library loaded
			    DEBUG_RESTART_SYSTEM- note that system is about to
						  restart
			    DEBUG_SYSTEM_EXITING- note that the system is
						  exiting and banking things
						  in will soon not be possible
		BX	= Thread handle (dead one for DEBUG_EXIT_THREAD,
			    new one for DEBUG_CREATE_THREAD) or
			  Geode handle (for DEBUG_EXIT_GEODE) or
		DX	= Exit code (DEBUG_EXIT_THREAD only)
		DS	= kdata for DEBUG_CREATE_THREAD
			= segment of core block for DEBUG_LOAD_DRIVER,
			  DEBUG_LOAD_LIBRARY
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Save state
	Put together Rpc & deliver it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		;
		; Set up interrupt frame for SaveState
		; 
KernelProcessFar	proc	far
		CreateFarFrame
		jmp	KernelProcess
KernelProcessFar	endp

KernelProcess	proc	near

		call	SaveState
		mov	ax, [bp].state_bx	; Fetch passed handle
		mov	{word}ds:rpc_ToHost, ax	; Store handle right away

		mov	bx, [bp].state_ax
		clr	bh
		cmp	bl, DebugProcessFunction
		jae	badCode
		shl	bx
		jmp	cs:kpJumpTable[bx]
kpJumpTable	nptr.near	ExitThread,	; DEBUG_EXIT_THREAD
				ExitGeode,	; DEBUG_EXIT_GEODE
				CreateThread,	; DEBUG_CREATE_THREAD
				DLLoad,		; DEBUG_LOAD_DRIVER
				DLLoad,		; DEBUG_LOAD_LIBRARY
				RestartSys,	; DEBUG_RESTART_SYSTEM
				SysExiting	; DEBUG_SYSTEM_EXITING
CheckHack	<length kpJumpTable eq DebugProcessFunction>

badCode:	jmp	done
CreateThread:
		;
		; Need the thread's owner -- load ES:BX with the address of the
		; handle, fetch the owner (owner2) field of the handle and
		; stuff it, then fetch the saved SS:SP for it and stuff that.
		; The rpc is RPC_SPAWN.
		; 
		mov	es, ds:[kdata]
		mov	({SpawnArgs}ds:[rpc_ToHost]).sa_xipPage, BPT_NOT_XIP
		mov	bx, [bp].state_bx
		mov	ax, es:[bx].HT_owner
		mov	({SpawnArgs}ds:[rpc_ToHost]).sa_owner, ax
		mov	ax, es:[bx].HT_saveSS
		mov	({SpawnArgs}ds:[rpc_ToHost]).sa_ss, ax
		call	KernelFindMaxSP
		mov	({SpawnArgs}ds:[rpc_ToHost]).sa_sp, ax

		mov	ax, RPC_SPAWN
		mov	cx, size SpawnArgs
		jmp	send		; Sendez le.
ExitThread:
		;
		; Retrieve the status from dx and store it in the
		; ThreadExitArgs at rpc_ToHost. The rpc is RPC_THREAD_EXIT
		; 
		mov	ax, [bp].state_dx
		mov	({ThreadExitArgs}ds:[rpc_ToHost]).tea_status, ax
		mov	ax, RPC_THREAD_EXIT
		mov	cx, size ThreadExitArgs
		jmp	send
ExitGeode:
		;
		; A geode is history -- need to pass the geode handle
		; and the current thread (to give Swat some context).
		; The rpc is RPC_GEODE_EXIT.
		;
		mov	ax, [bp].state_bx
		mov	({GeodeExitArgs}ds:[rpc_ToHost]).gea_handle, ax
		mov	es, ds:[kdata]
		mov	bx, ds:[currentThreadOff]
		mov	ax, es:[bx]
		mov	({GeodeExitArgs}ds:[rpc_ToHost]).gea_curThread, ax
		mov	ax, RPC_GEODE_EXIT
		mov	cx, size GeodeExitArgs
		jmp	short send
DLLoad:
		;
		; Driver/Library load:
		; Clear out the two fields that aren't applicable for this
		; sort of object to signal that it's a library/driver
		; that's been loaded. The sa_thread field gets the
		; ID of the current thread in case the machine remains
		; stopped.
		;
		mov	ax, [bp].state_thread
		mov	({SpawnArgs}ds:[rpc_ToHost]).sa_thread, ax
		clr	ax
		mov	({SpawnArgs}ds:[rpc_ToHost]).sa_ss, ax
		mov	({SpawnArgs}ds:[rpc_ToHost]).sa_sp, ax

		push	ds
		mov	ds, [bp].state_ds
		mov	ax, ds:[GH_geodeAttr]
		or	ax, mask GA_KEEP_FILE_OPEN
		mov	ds:[GH_geodeAttr], ax
		mov	ax, ds:GH_geodeHandle	; Fetch handle of the block
		
		pop	ds
		mov	({SpawnArgs}ds:[rpc_ToHost]).sa_owner, ax

		mov	ax, BPT_NOT_XIP
		tst	ds:[xipHeader]
		jz	afterXIP
		mov	es, ds:[kdata]
		mov	bx, ds:[curXIPPageOff]
		mov	ax, es:[bx]
afterXIP:
		mov	({SpawnArgs}ds:[rpc_ToHost]).sa_xipPage, ax

		mov	ax, RPC_SPAWN
		mov	cx, size SpawnArgs
		jmp	short send
RestartSys:

	;
	; Note we should be looking for 4b03 and that we're no longer attached
	; to the kernel.
	; 

		mov	ds:[reloadState], RS_WATCH_EXEC
		andnf	ds:[sysFlags], not mask attached
		mov	ds:[kernelCore], 0
	;
	; And pass a really big size up to Swat so it knows what's going on.
	; 
		mov	{word}ds:[rpc_ToHost], -1
		mov	ax, RPC_DOS_RUN
		mov	cx, size word
		.assert	$ eq send
send:
		;
		; Load up BX for the call; make it; restore state; and return
		; through the jump vector
		; 
		push	cs			; load cgroup into ES
		pop	es
		mov	bx, offset rpc_ToHost
		call	Rpc_Call
		
		test	ds:[sysFlags], mask dontresume
		jz	done
		jmp	Rpc_Run

SysExiting:
		call	Bpt_SysExiting
done:
		call	RestoreState
		iret
KernelProcess	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelLoadRes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle DebugLoadResource calls

CALLED BY:	Kernel
PASS:		BX	= handle of loaded resource
		AX	= data address of resource
		ES	= kdata
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		;
		; Set up interrupt frame for SaveState
		; 
KernelLoadResFar	proc	far
		CreateFarFrame
		jmp	KernelLoadRes
KernelLoadResFar	endp

KernelLoadRes	proc	near
	;
	; Deal with breakpoints...
	; 
		call	Bpt_ResLoad
	
	;
	; If notification comes while we're on our own stack, it means
	; it happened because of us, and Swat has this handle in its
	; table, regardless of the HF_DEBUG bit, so we need to notify
	; it...
	;
		push	ax
		mov	ax, ss
		cmp	ax, sstack
		pop	ax
		je	notify
		;
		; Make sure we're actually interested in the block -- on the
		; initial load of a new process, we're not actually interested.
		; To avoid annoying errors each time, we do this check.
		; 
		test	es:[bx].HM_flags, MASK HF_DEBUG
		jz	KLRRet
notify:
		call	SaveState
		;
		; Store the handle and selector in the rpc packet while
		; we've got them handy...
		; 
		mov	es, ds:[kdata]
		mov	ax, [bp].state_ax
		mov	bx, [bp].state_bx

		mov	ds:[resourceBeingLoaded], bx

		mov	ds:({LoadArgs}rpc_ToHost).la_handle, bx
		mov	ds:({LoadArgs}rpc_ToHost).la_dataAddress, ax

		;
		; Prepare for rpc and send it
		; 
		push	cs
		pop	es
		mov	cx, size LoadArgs
		mov	bx, offset rpc_ToHost
		mov	ax, RPC_RES_LOAD
		call	Rpc_Call

		mov	ds:[resourceBeingLoaded], 0

		test	ds:[sysFlags], mask dontresume
		jnz	stop
		;
		; Restore previous state and return
		; 
		call	RestoreState
KLRRet:
		iret
stop:
		push	cs
		pop	es		; es = cgroup again
		jmp	Rpc_Run
KernelLoadRes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_CleanHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure no handle has its HF_DEBUG bit set

CALLED BY:	Kernel_Hello, Kernel_Detach
PASS:		DS	= cgroup
RETURN:		ES	= kdata
DESTROYED:	BX, DX, AX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_CleanHandles proc	near
		mov	es, ds:[kdata]
		mov	dx, ds:[lastHandle]	; Locate end of table
		tst	dx			; Handle table set up?
		jz	done			; No -- DON'T DO ANYTHING
		mov	bx, ds:[HandleTable]	; Start at beginning
scanLoop:
		tst	es:[bx].HM_owner	; See if it's free
		jz	next			; Yes -- do nothing

		cmp	es:[bx].HM_addr.high, SIG_NON_MEM
		jae	next			; Not a memory handle

		and	es:[bx].HM_flags, NOT MASK HF_DEBUG
next:
		add	bx, size HandleMem
		cmp	bx, dx
		jb	scanLoop
done:
		ret
Kernel_CleanHandles endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelIntercept
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept the kernel debug vectors

CALLED BY:	Kernel_Hello, KernelDos
PASS:		ds = cgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		; in going from version 0 to version 1 I moved the Debug
		; routines from kcode to kdata for XIP purposes

		; And I moved them back into kcode for PM purposes
		; -dhunter 11/21/00

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 2/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
interceptPoints	nptr.word	DebugLoadResOff, DebugMemoryOff, DebugProcessOff
postSDKRoutines	nptr.far	KernelLoadResFar, KernelMemoryFar, KernelProcessFar

KernelIntercept	proc	near	uses es, di, ax, si, cx
		.enter
		pushf
	DPC <DEBUG_DOS or DEBUG_FILE_XFER>, 'I', inverse

		;
		; Intercept the various debugging vectors in the kernel by
		; storing a direct FAR jump to our own routine.
		; 
		mov	es, ds:[kcodeSeg]	; Get kernel segment in es
		mov	bx, offset postSDKRoutines - offset interceptPoints

	DPW DEBUG_SETUP, es
		call	Kernel_EnsureESWritable
		push	ax

FJMP		= 0eah
		cld

		mov	si, offset interceptPoints
		mov	cx, length interceptPoints
interceptLoop:
		lodsw				; ax <- offset of variable
						;  holding routine offset
		mov_tr	di, ax
		mov	di, ds:[di]		; es:di <- intercept routine
		mov	al, FJMP
		stosb
		mov	ax, ds:[si+bx-2]	; ax <- routine in us to call
		stosw
		mov	es:[di], cs
		loop	interceptLoop
		
		pop	ax
		call	Kernel_RestoreWriteProtect

		popf
		.leave
		ret
KernelIntercept	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get internal swat addresses needed by the stub

CALLED BY:	Kernel_Setup
PASS:		ES, DS	= cgroup
RETURN:		carry set if kernel cannot be dealt with
		carry clear if we have a table:
			di = -1 if kernel contains table
			   = 0 if had to use an internal table
			table copied to "kernelVectors" variable
DESTROYED:	cx, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KernelSetup	proc	near
		uses	si, ax
		.enter

	;
	; Locate the kernel's library entry function. The vector table, if
	; any, is pointed to by a SwatVectorDesc structure that immediately
	; follows a short jump at the start of the library entry.
	; 
			DPC	DEBUG_SETUP, 'S'
			DPC	DEBUG_SETUP, 'S'
			DPW	DEBUG_SETUP, ds:[kdata]
			DPW	DEBUG_SETUP, ds:[kernelCore]
		clr	di
		mov	es, ds:[kdata]
		mov	bx, ds:[kernelCore]
		mov	es, es:[bx].HM_addr
		mov	ax, es:[GH_libEntrySegment]
			DPW	DEBUG_SETUP, ax
		mov	si, es:[GH_libEntryOff]
		mov	es, ax
	;
	; now look for the signature that says we have a swat table
	; 
		inc	si		; skip jmp instruction...
		inc	si		;  ...and displacement
		cmp	{word}es:[si].SVD_signature, SWAT_VECTOR_SIG
		jne	noTable
					DPC	DEBUG_SETUP, 'v'
		mov	al, es:[si].SVD_version
		mov	ds:[kernelVersion], al
					DPB	DEBUG_SETUP, al

					DPC	DEBUG_SETUP, 'T', inv
		segxchg	ds, es
		mov	si, ds:[si].SVD_table	; ds:si <- vector table
		mov	di, -1			; => table in kernel
		jmp	loadOffsets

noTable:
	;
	; Kernel is not equipped with a table for us to copy, so
	; lets do a checksum in kcode to find out which kernel we have
	; it better be either Zoomer, Wizard or upgrade!
	; ES = kcode (where the kernel library entry resides)
	; 
		push	ds
		segmov	ds, es
		mov	si, 1000h	; random place in kcode
		mov	cx, 10		; number of words to checksum with
		clr	di		; di = checksum
calcChecksum:
		lodsw		
		add	di, ax
		loop	calcChecksum
		pop	ds
					DPC	DEBUG_SETUP, 'C', inv
					DPW	DEBUG_SETUP, di
		segmov	es, ds		; es <- cgroup again
		mov_tr	ax, di		; ax <- checksum
		mov	cx, length internalTables
		mov	di, offset internalTables
findTableLoop:
		cmp	ds:[di].IVT_checksum, ax
		je	foundTable
		add	di, size InternalVectorTable
		loop	findTableLoop
		stc
		jmp	done

foundTable:
		mov	si, ds:[di].IVT_table
		clr	di
loadOffsets:
	;
	; Copy the table into our internal data area.
	; ds:si	= table to copy
	; es = cgroup
	; 
		push	di
		mov	di, offset kernelVectors
		mov	cx, size kernelVectors
		rep	movsb
		pop	di
		segmov	ds, es
					DPC	DEBUG_SETUP, 'x'
					DPW	DEBUG_SETUP, ds:[curXIPPageOff]
	;
	; Set up the offsets for the procedure vectors of the things we call
	; in the kernel.
	; 
		mov	ax, ds:[kernelVectors].SVT_MemLock
		mov	ds:[MemLockVec].offset, ax
		mov	ax, ds:[kernelVectors].SVT_FileReadFar
		mov	ds:[FileReadVec].offset, ax
		mov	ax, ds:[kernelVectors].SVT_FilePosFar
		mov	ds:[FilePosVec].offset, ax
		mov	ax, ds:[kernelVectors].SVT_MapXIPPageFar
		mov	ds:[MapXIPPageVec].offset, ax
		mov	ax, ds:[kernelVectors].SVT_SysContextSwitch
		mov	ds:[SysCSVec].offset, ax
		mov	ax, ds:[kcodeSeg]
		mov	ds:[SysCSVec].segment, ax
	;
	; Convert the XIP page size from bytes to paragraphs
	; 
		mov	cl, 4
		mov	ax, ds:[kernelVectors].SVT_MAPPING_PAGE_SIZE
		shr	ax, cl
		mov	ds:[xipPageSize], ax
		clc
done:
		.leave
		ret
KernelSetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_Setup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send swat a list of internal kernel symbols that it might
		find useful.

CALLED BY:	Rpc_Wait
PASS:		ES, DS	= cgroup
RETURN:		Nothing
DESTROYED:	Probably

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/26/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Kernel_Setup	proc	near
	.enter
				DPC	DEBUG_SETUP, 's'
	call	KernelSetup
	jc	error

	mov	({SetupReplyArgs}ds:[rpc_ToHost]).sa_kernelHasTable, di
	mov	cx, size SwatVectorTable/2
	mov	({SetupReplyArgs}ds:[rpc_ToHost]).sa_tableSize, cx
			
	lea	di, ({SetupReplyArgs}ds:[rpc_ToHost]).sa_currentThread
	mov	si, offset kernelVectors
		CheckHack <(size SwatVectorTable and 1) eq 0>
	rep	movsw

	mov	si, offset rpc_ToHost
	mov	cx, size SetupReplyArgs
			DPC	DEBUG_SETUP, 'y'
			DPW	DEBUG_SETUP, cx
	call	Rpc_Reply
done:
	.leave
	ret
error:
	mov	ax, RPC_INCOMPAT
	call	Rpc_Error
	jmp	done
Kernel_Setup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_Hello
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the receipt of an RPC_HELLO call

CALLED BY:	Rpc_Wait
PASS:		ES, DS	= cgroup
RETURN:		Nothing
DESTROYED:	Probably

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The various state variables in main.asm are set up using the
			offsets passed in the HelloArgs structure

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; List of interrupts/processor exceptions to catch for '286 or later processors
; single-step and breakpoint exceptions are fielded elsewhere.
; 
pcATIntercepts	byte	RPC_HALT_DIV0,
			RPC_HALT_NMI,
			RPC_HALT_INTO,
			RPC_HALT_BOUND,
			RPC_HALT_ILLINST,
			RPC_HALT_GP,
			RPC_HALT_SSOVER,
			RPC_HALT_NOSEG

;
; List of interrupts/processor exceptions to catch for 8088/8086 processors
; single-step and breakpoint exceptions are fielded elsewhere.
; 
pcXTIntercepts	byte	RPC_HALT_DIV0,
			RPC_HALT_NMI,
			RPC_HALT_INTO

Kernel_Hello	proc	near
		DPC	DEBUG_FALK3, 'H'
	;
	; It seems we're getting interrupted in here, context
	; switching before we can set currentThread to HID_KTHREAD
	; and never making it back due to EC code in DispatchSI
	; that will decide the saveSS is bogus (it's not below PSP),
	; vault to FatalError and we'll never tell anyone because
	; we're not attached yet.
	;
	; I have some doubts about this theory. E.g. if so, we should
	; be able to attach again after the timeout. Also, it only
	; happens with a bus mouse, which runs off the timer interrupt,
	; which we intercept in SaveState, so the mouse shouldn't
	; be consulted...
	; 
		dsi
	;
	;
	; See if the kernel's been loaded. If not, we can't return anything
	; else...when the kernel loads, it'll take care of setting the
	; segment portion of MemLockVec 
	;

	; initialize value to -1, it will change when necessary
		mov	({HelloReply}ds:[rpc_ToHost]).hr_curXIPPage, 
				BPT_NOT_XIP

		tst	ds:[kernelCore]
		jnz	KH2		; can actually look things up
	;
	; Nothing running -- set hr_numGeodes, and hr_numThreads to 0.
	; Claim the current thread is the kernel.
	; 
KH1_7:
		clr	ax
		mov	({HelloReply}ds:[rpc_ToHost]).hr_numGeodes, ax
		mov	({HelloReply}ds:[rpc_ToHost]).hr_numThreads, ax
		mov	({HelloReply}ds:[rpc_ToHost]).hr_curThread, ax
		mov	({HelloReply}ds:[rpc_ToHost]).hr_kernelVersion, ax
	;
	; Just reply with the HelloReply structure. KH3 sends the
	; reply and goes into wait mode.
	; 
		mov	cx, size HelloReply
		eni
		jmp	sendReply

KH2:
	;
	; Update our TPD_blockHandle, and TPD_processHandle while we've got
	; kdata in es. This allows us to mimic the kernel thread.
	;
		mov	es, ds:[kdata]
		mov	ax, es:[TPD_blockHandle]
		mov	ss:[tpd].TPD_blockHandle, ax
		mov	ax, es:[TPD_processHandle]
		mov	ss:[tpd].TPD_processHandle, ax
		
	;
	; Stuff in the current thread.
	; 
		test	ds:[sysFlags], MASK attached
		jnz	fetchCurThread
	;
	; If weren't attached before, currentThread in the kernel
	; actually contains the ID of the thread at the time of the
	; interruption, so fetch it and store it in the state block
	; so when we continue, we don't switch to a garbage thread.
	;
	; Done here to handle the case where we intercepted a fatal
	; error without having been attached. The saveSS of the current
	; thread is unreliable in such a case, so we want to make sure
	; we get the value from our state block, not from the handle.
	; Also done here to make sure the thing gets transmitted to
	; Swat even if ha_bootstrap is true.
	; 
		mov	bx, ds:[currentThreadOff]
		mov	ax, HID_KTHREAD
		xchg	ax, es:[bx]
		mov	[bp].state_thread, ax
		; FALLTHRU
fetchCurThread:
	;
	; Fetch the current thread from the state block...
	; 
		mov	ax, [bp].state_thread
		mov	({HelloReply}ds:[rpc_ToHost]).hr_curThread, ax

	;
	; See if Swat is bootstrapping. This is here to allow one to
	; attach to a system that has too much running for an initial
	; setup reply to fit.
	;
	DPC	DEBUG_FALK3, 'h'
		tst	({HelloArgs}CALLDATA).ha_bootstrap
		jnz	KH1_7
		eni

		tst	ds:[xipHeader]
		jz	afterXIP
		
	; at this point es = kdata
		mov	di, ds:[curXIPPageOff]
		mov	ax, es:[di]
		mov	({HelloReply}ds:[rpc_ToHost]).hr_curXIPPage, ax
afterXIP:		
	;
	; First figure the number of geodes in the system
	; 
		mov	di, offset rpc_ToHost + size HelloReply
		segxchg	ds, es		;es <- cgroup, ds <- kdata
		assume	es:cgroup, ds:nothing
		clr	cx
		mov	dx, RPC_MAX_DATA - size HelloReply
		mov	si, es:[geodeListPtrOff]
		mov	bx, ds:[si]	; Load initial geode handle into BX

KHGetGeodes:
	;
	; Null segment => end of chain
	; 
		tst	bx
		jz	KHGGDone
	;
	; Store the geode handle in the RPC structure
	;
		mov	ax, bx
		stosw
	;
	; Lock the geode (if possible). You might think that the call to
	; KernelSafeLock could generate a call to the host, but it can't
	; as no HF_DEBUG bit can possibly be set at this point.
	;
		segmov	ds, es			;ds = cgroup
		call	KernelSafeLock
		segxchg	ds, es			;ds = geode, es = cgroup
		jc	KHGGDone
	;
	; Extract the handle of the next geode
	; 
		push	ds:[GH_nextGeode]
		call	KernelSafeUnlock
		pop	bx
	;
	; Advance the numGeodes counter and the pointer into the reply
	; 
		inc	cx
		dec	dx
		dec	dx
		jnz	KHGetGeodes
KHTooBig:
		mov	ax, RPC_TOOBIG
		call	Rpc_Error
		ret
KHGGDone:
		mov	ds, es:[kdata]		; Restore kdata
		mov	es:[{HelloReply}rpc_ToHost].hr_numGeodes, cx

	; put in the Kernel Version
		mov	al, es:[kernelVersion]
		clr	ah
		mov	({HelloReply}es:[rpc_ToHost]).hr_kernelVersion, ax

	;
	; DI now points to the place at which to start storing thread
	; information. We do a thing similar to that above to enumerate
	; all the threads in the system. 
	; 
		mov	si, es:[threadListPtrOff]
		clr	cx
		sub	si, offset HT_next
KHGetThreads:
		mov	ax, ds:[si].HT_next
		tst	ax		; no next thread?
		jz	KHGTDone	; correct -- all done here
		
		stosw			; Store the handle itself in the
					;  reply buffer
		xchg	si, ax		; si <- next thread
		inc	cx
		dec	dx
		dec	dx
		jnz	KHGetThreads
		tst	ds:[si].HT_next
		jnz	KHTooBig
KHGTDone:
		segxchg	ds, es
		assume	ds:cgroup, es:nothing

	;
	; Store # of threads in system
	; 
		mov	({HelloReply}ds:[rpc_ToHost]).hr_numThreads, cx
	;
	; Figure total size of reply and move it into CX
	; 
		sub	di, offset rpc_ToHost
		mov	cx, di
sendReply:
	;
	; Make sure ES contains cgroup, point SI at rpc_ToHost and
	; reply to the rpc that everything's groovy.
	; 
		push	cs
		pop	es
		mov	si, offset rpc_ToHost
		call	Rpc_Reply
	;
	; Now the reply has been shipped off, catch major errors, as determined
	; by the processor type.
	; 
		test	ds:[sysFlags], MASK attached
		jnz	KHRet			; => Already have our hooks in

	DPC	DEBUG_FALK3, 'p'
		dsi				; No ints while catching
		;
		; Always catch divide by 0
		;
		mov	bx, offset intsToIgnore

		mov	si, offset pcATIntercepts
		mov	cx, length pcATIntercepts
		;test	ds:[sysFlags], mask isPC
		;jz	catchEmAll
		;mov	si, offset pcXTIntercepts
		;mov	cx, length pcXTIntercepts
catchEmAll:
		lodsb	cs:		; al <- interrupt #

		mov	ah, al		; save it...
		xlatb			; al <- intsToIgnore[al]
		tst	al		; ignore it?
		jnz	nextInt		; yes..

		mov	al, ah		; al <- interrupt # again
		call	CatchInterrupt
nextInt:
		loop	catchEmAll
	;
	; Intercept kernel debug vectors
	;
		call	KernelIntercept
		
KHRet:
	;
	; Attach complete -- note this, please.
	;
		or	ds:[sysFlags], MASK attached
;exit:
		ret
Kernel_Hello	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_Detach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach from the kernel.

CALLED BY:	Rpc_Wait, RpcExit, RpcGoodbye
PASS:		Debug* vector offsets accurate
RETURN:		Nothing
DESTROYED:	...

PSEUDO CODE/STRATEGY:
		Re-install near returns (0c3h) at the start of the vectors
		we changed.
		Clear the attached bit in sysFlags
		Reply that everything's ok

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_Detach	proc	near
		test	ds:[sysFlags], MASK attached
		jz	done		; Not actually attached, so don't
					; detach from the kernel. We've
					; not gotten our hooks into the
					; interrupt vectors either...
	;
	; Figure where the intercept vectors lie and what their calling
	; distance is. For pre-SDK kernels (kernelVersion == 0), the vectors
	; lie as near routines in kcode. All other kernels have them as
	; far routines in kdata.
	;
		push	es
		mov	es, ds:[kcodeSeg]
		mov	bl, 0c3h	; retn opcode

		tst	ds:[kernelVersion]
		jz	gotSeg

		mov	es, ds:[kdata]
		mov	bl, 0cbh	; retf opcode
gotSeg:
		call	Kernel_EnsureESWritable
		push	ax
		mov_tr	ax, bx		; ax <- return opcode
		mov	bx, ds:[DebugLoadResOff]
		mov	byte ptr es:[bx], al
		mov	bx, ds:[DebugMemoryOff]
		mov	byte ptr es:[bx], al
		mov	bx, ds:[DebugProcessOff]
		mov	byte ptr es:[bx], al
		
		pop	ax
		call	Kernel_RestoreWriteProtect

		call	Kernel_CleanHandles
		pop	es
	;
	; Restore the various interrupt handlers to their previous
	; state. IgnoreInterrupt deals with our not having actually
	; hooked a vector...
	; 
		call	Kernel_ReleaseExceptions

		and	ds:[sysFlags], NOT MASK attached
done:
		DPC	DEBUG_EXIT, 'd'
		ret
Kernel_Detach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_ReleaseExceptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ignore the processor exceptions we caught when Swat attached

CALLED BY:	(EXTERNAL) Kernel_Detach, MainGeosExited
PASS:		ds	= cgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/19/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_ReleaseExceptions proc	near
		uses	ax, bx
		.enter
		dsi
		mov	al, RPC_HALT_DIV0
		call	IgnoreInterrupt
		mov	al, RPC_HALT_NMI
		call	IgnoreInterrupt
		;mov	al, RPC_HALT_BPT	Always caught
		;call	IgnoreInterrupt
		mov	al, RPC_HALT_INTO
		call	IgnoreInterrupt
		mov	al, RPC_HALT_BOUND
		call	IgnoreInterrupt
		mov	al, RPC_HALT_ILLINST
		call	IgnoreInterrupt
		;mov	al, RPC_HALT_PEXT	never caught
		;call	IgnoreInterrupt
		;mov	al, RPC_HALT_INVTSS	never caught
		;call	IgnoreInterrupt
		mov	al, RPC_HALT_GP
		call	IgnoreInterrupt
		eni
		.leave
		ret
Kernel_ReleaseExceptions endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_IndexToOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert an index into the export table into an offset

CALLED BY:	RPC_INDEX_TO_OFFSET

PASS:		handle of core block and index into export entry table

RETURN:		converted offset

DESTROYED:	ax, bx, cx, dx

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/13/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Kernel_IndexToOffset	proc	near
		uses	es, si
		.enter
		DPC	DEBUG_FILE_XFER, 'I'
		mov	bx, ({IndexToOffsetArgs}CALLDATA).ITOA_geodeHandle
		mov	cx, ({IndexToOffsetArgs}CALLDATA).ITOA_index

	; using 1000h for now, should really be the fist handle in the
	; handle table
		cmp	bx, 100h
		jg	geosHandle

	; here we have a DOS handle so we must read stuff in from the 
	; DOS file directly, eck
	;	bx = DOS file handle
	;	cxsi = offset to read from
	;	di = how much to read
	;	ds:dx = buffer to read into
		mov_tr	ax, cx			; save our index
		
		clr	cx
		mov	si, offset GH_exportLibTabOff
		mov	dx, offset rpc_ToHost
		mov	di, size GH_exportLibTabOff
		call	KernelDosFileRead
		LONG jc	done

		mov	si, {word}ds:rpc_ToHost
		add	si, size word			; get offset from fptr
		clr	cx
		mov	di, size word
		call	KernelDosFileRead

		mov	ax, {word}ds:rpc_ToHost
		jmp	gotOffset
geosHandle:
		call	KernelSafeLock		; es = core block address
		LONG jc	done
		DPC	DEBUG_FILE_XFER, 'L'
	
		mov	si, es:[GH_exportLibTabOff]
		shl	cx
		shl	cx		; index * 4 = position in fptr table
		add	si, cx
		mov	ax, es:[si]		
		DPW	DEBUG_FILE_XFER, ax
		call	KernelSafeUnlock
gotOffset:
		mov	cx, size IndexToOffsetReply
		mov	si, offset rpc_ToHost
		push	ds
		pop	es
		mov	({IndexToOffsetReply}ds:rpc_ToHost).ITOR_offset, ax
		DPW	DEBUG_FILE_XFER, ax		
		call	Rpc_Reply
		clc
done:
		.leave
		ret
Kernel_IndexToOffset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_GetNextDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the next block of data to the host

CALLED BY:	Rpc_Wait

PASS:		nothing

RETURN:		data

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/18/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_GetNextDataBlock	proc	near
		.enter
		DPC	DEBUG_XIP, 'n'

		push	ds, es
	; get the size to read and store it in saved ReadGeodeArgs
		mov	ax, ({GetNextDataBlock}CALLDATA).GNDB_size
		mov	ds:[savedReadGeodeArgs].RGA_size, ax
	; copy the savedReadGeodeArgs into CALLDATA so ReadGeode thinks its
	; being called with those args
		segmov	es, ds
		mov	di, offset CALLDATA
		PointDSAtStub
		mov	si, offset savedReadGeodeArgs
		mov	cx, size ReadGeodeArgs
		rep	movsb
		pop	ds, es
		call	Kernel_ReadGeode	; cx = size of data read
		segmov	es, ds
		mov	si, offset rpc_ToHost
		add	si, size ReadGeodeReply	; skip the reply info
		call	Rpc_Reply
		.leave
		ret
Kernel_GetNextDataBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelGetResourceFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the resource flags for a geode

CALLED BY:	GLOBAL

PASS:		bx = geode handle

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/19/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KernelGetResourceFlags	proc	near
		.enter
		DA	DEBUG_XIP, <push ax>
		DPC	DEBUG_XIP, 'F'
		DA	DEBUG_XIP, <pop ax>
		mov	cx, offset HM_flags
;		mov	di, offset dataBuf
		mov	di, offset rpc_ToHost + size ReadGeodeReply
		call	KernelGetGeodeResourcesInfo
		.leave
		ret
KernelGetResourceFlags	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelGetGeodeResourcesInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the info of the resources for a geode

CALLED BY:	GLOBAL

PASS:		bx = geode handle
		cx = offset of field to get (ie offset HM_addr or HM_flags)
		di = offset of buffer to store data in (ds = scode)

RETURN:		cx = size
		carry clear (if things go ok)

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/26/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KernelGetGeodeResourcesInfo	proc	near
		uses	ds, es, di, dx, bp, ax, si
		.enter
		DA	DEBUG_XIP, <push ax>
		DPS	DEBUG_XIP, <RI>
		DA	DEBUG_XIP, <pop ax>


		mov	bp, cx		; save away in extra register
		mov	dx, ds:[kdata]	; save away in dx for speed
		call	KernelSafeLock	; es = geode block
		jc	done
		push	bx		; save for unlock
		mov	si, es:[GH_resHandleOff] ; es:si <- geode handle table
		mov	cx, ({ReadGeodeArgs}CALLDATA).RGA_size
		shr	cx
		cmp	ds:[rpc_LastCall].RMB_header.rh_procNum, RPC_READ_GEODE
		je	resetState

	; if we came through GET_NEXT_DATA_BLOCK then we must strart from where
	; we left off
		DPW	DEBUG_XIP, cs:[savedReadGeodeArgs].RGA_dataValue1
		add	si, ds:[savedReadGeodeArgs].RGA_dataValue1
		add	ds:[savedReadGeodeArgs].RGA_dataValue1, \
				FILE_XFER_BLOCK_SIZE - size ReadGeodeReply
		jmp	getInfo
resetState:
	; use one of the generic values to remember where to pick from
		mov	ds:[savedReadGeodeArgs].RGA_dataValue1, \
				FILE_XFER_BLOCK_SIZE - size ReadGeodeReply
getInfo:	
		segxchg	ds, es	; ds:si = geode handle table, es:di = out buffer
		push	cx
handleloop:
		push	es
		mov	es, dx
		lodsw
		mov_tr	bx, ax		; bx = next handle
		add	bx, bp		; get proper field of handle
		mov	ax, es:[bx]	; get flags for that handle
		pop	es		; restore destination buffer segment
		stosw			; stuff the flags into the buffer
		loop	handleloop
		pop	cx
		shl	cx		; size = 2 * resCount
		pop	bx
		call	KernelSafeUnlock
		DPW	DEBUG_XIP, cx
		clc
done:
		.leave
		ret
KernelGetGeodeResourcesInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelGetHeaderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get all relavent header info for an XIPed geode

CALLED BY:	Kernel_ReadGeode

PASS:		bx = geode handle
		ds = scode

RETURN:		fill dataBuf with a GeodeHeader struct full of juicy details
		cx = size of data

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
	a geode really looks like this
		GeosFileHeader
		ExecutableFileHeader
		GeodeFileHeader
		data

	now swat wants
		ExecutableFileHeader
		GeodeFileHeader

	and for XIPed geodes we only have access to
		GeodeFileHeader

	so we will just send up what data we can, put into the right place	
KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/17/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KernelGetHeaderInfo	proc	near
		uses	ax, di, es, ds, si
		.enter
		DPS	DEBUG_XIP, <HI>
	; set up di to point to where GeodeHeader info should go
		mov	di, offset rpc_ToHost + size ExecutableFileHeader \
					      + size ReadGeodeReply
		call	KernelSafeLock		; es = GeodeHeader for geode
		jc	done
		segxchg es, ds			; es:di = place to send data
		clr	si			; ds:si = GeodeHeader info
		mov	cx, offset GH_endOfVariablesFromFile
		rep	movsb			; copy GeodeHeader
		mov	cx, size ExecutableFileHeader + \
					offset GH_endOfVariablesFromFile
		; note that the size we return is bigger than what we
		; actually get by size ExectuableFileHeader as that
		; extra data is not around in memory...
		DPC	DEBUG_XIP, 'h', inv
		call	KernelSafeUnlock
		clc
done:
		.leave
		ret
KernelGetHeaderInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelGetNormalData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get data from a resource

CALLED BY:	GLOBAL

PASS:		dx = handle of resource
		ax = offset
		cx = number of bytes to get

RETURN:		cx = size, save as cx passed in
		carry set on error

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/19/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KernelGetNormalData	proc	near
		uses	ds, es, si, di, ax, bx, cx
		push	ax
		DPC	DEBUG_FALK3, 'K'
		pop	ax
		.enter

		mov	bx, dx
		mov	si, ax
		call	KernelSafeLock
		jc	done
		segxchg	ds, es		; ds:si = data to get
		mov	di, offset rpc_ToHost + size ReadGeodeReply
		rep	movsb		; copy data
		call	KernelSafeUnlock
		clc
done:
		.leave
		push	ax
		DPC	DEBUG_FALK3, 'k'
		pop	ax
		ret
KernelGetNormalData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_ReadGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read in data from a geode

CALLED BY:	RPC_READ_GEODE

PASS:		size of data

RETURN:		cx = size of adata read if not called from RPC_READ_GEODE

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
		if we can, we will gather the data from memory otherwise
		call GEOS's FileRead on the geode (if geode not XIPed)

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/23/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

savedReadGeodeArgs	ReadGeodeArgs

DataTypeFunctions	nptr 	offset KernelGetResourceFlags,
				offset KernelGetHeaderInfo,
				offset KernelGetNormalData


Kernel_ReadGeode	proc	near
		.enter
;BRK
		DPC	DEBUG_FILE_XFER, 'R'
		tst	ds:[readGeodeSem]
		jz	readGeodePsem

		mov	({ReadGeodeReply}ds:rpc_ToHost).RGR_ok, FILE_XFER_QUIT
		mov	cx, ({ReadGeodeArgs}CALLDATA).RGA_size
		add	cx, size ReadGeodeReply
		call	Rpc_Reply
		DPC	DEBUG_FILE_XFER, 'E', inv
		stc
		jmp	doneNoV
readGeodePsem:
		mov	ds:[readGeodeSem], 1

	; lets copy over the arguments in case we need them for successive calls
	; to GET_NEXT_BLOCK
		PointESAtStub
		mov	di, offset savedReadGeodeArgs
		mov	si, offset CALLDATA
		mov	cx, size ReadGeodeArgs
		rep	movsb
	; see if the data type lends itself towards avoiding a call to fread
	; or not...if so try that first
		mov	bx, ({ReadGeodeArgs}CALLDATA).RGA_geodeHandle
		mov	cx, ({ReadGeodeArgs}CALLDATA).RGA_dataType
		DPC	DEBUG_XIP, 'D'
		DPW	DEBUG_XIP, cx

		sub	cx, GEODE_DATA_GEODE
		jb	useGeode		; => nothing special
	; first try to gather the data without having to read from the 
	; geo file...
	; these data values could be useful to the specific data type routine
		mov	dx, ({ReadGeodeArgs}CALLDATA).RGA_dataValue1
		mov	ax, ({ReadGeodeArgs}CALLDATA).RGA_dataValue2
		shl	cx
		mov	si, cx
		mov	cx, ({ReadGeodeArgs}CALLDATA).RGA_size
		call	cs:[DataTypeFunctions][si]
		jnc	afterFileRead	; if it failed try the geode
useGeode:
		call	KernelReadFromGeodeFile
afterFileRead:
		jc	error
	; send out the size of the stuff read

		DPC	DEBUG_FILE_XFER, 'S'
		DPW	DEBUG_FILE_XFER, cx

	; add in the amount sent to the offset so we know where to start from
	; next time
		clr	dx
		adddw	ds:[savedReadGeodeArgs].RGA_offset, dxcx

	; if we weren't called from READ_GEODE then just return
		cmp	ds:[rpc_LastCall].RMB_header.rh_procNum, RPC_READ_GEODE
		jne	done
		mov	({ReadGeodeReply}ds:[rpc_ToHost]).RGR_ok, FILE_XFER_SYNC
		mov	({ReadGeodeReply}ds:[rpc_ToHost]).RGR_size, cx
sendReply:
		add	cx, size ReadGeodeReply
		mov	si, offset rpc_ToHost
		segmov	es, ds
		DPW	DEBUG_XIP, cx
		call	Rpc_Reply
done:
		clr	ds:[readGeodeSem]
doneNoV:
		.leave
		ret
error:
		cmp	al, FILE_XFER_QUIT
		je	sendError
		mov	al, FILE_XFER_ERROR
sendError:
		mov	({ReadGeodeReply}ds:[rpc_ToHost]).RGR_ok, al
		mov	cx, ({ReadGeodeArgs}CALLDATA).RGA_size
		jmp	sendReply
Kernel_ReadGeode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelReadFromGeodeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read bytes out of the geode file, since other methods failed

CALLED BY:	(INTERNAL) Kernel_ReadGeode
PASS:		ds	= cgroup
		rpc_FromHost = ReadGeodeArgs
RETURN:		carry set on error:
			ax	= FileError or FILE_XFER_QUIT
		carry clear if ok:
			cx	= # bytes read
DESTROYED:	dx, si, di, es, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/94		Initial version (extracted from
				Kernel_ReadGeode)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelReadFromGeodeFile proc	near
		.enter
		DPC	DEBUG_XIP, 'u', inv
		DPW	DEBUG_FILE_XFER, ({ReadGeodeArgs}CALLDATA).RGA_offset.high
		DPW	DEBUG_FILE_XFER, ({ReadGeodeArgs}CALLDATA).RGA_offset.low
		DPW	DEBUG_FILE_XFER, ({ReadGeodeArgs}CALLDATA).RGA_size
		DPW	DEBUG_FILE_XFER, ({ReadGeodeArgs}CALLDATA).RGA_geodeHandle
	; if the handle is 1 then we are dealing with the loader so just
	; return the size of the header, which should be the only thing
	; that we get asked for...i hope so anyways.
		mov	bx, ({ReadGeodeArgs}CALLDATA).RGA_geodeHandle
		cmp	bx, 1
		jne	notLoader
		mov	ax, ds:[kernelHeader].exe_headerSize
		DPW	DEBUG_FILE_XFER, ax

		mov	{word}ds:[offset rpc_ToHost + size ReadGeodeReply], ax
		mov	cx, 2
		clc
		jmp	done
notLoader:
		call	KernelSafeLock		; es <- core block segment
		jc	error
		DPC	DEBUG_FILE_XFER, 'L'
		mov	ax, es:[GH_geoHandle]
		mov	dx, es:[GH_geodeAttr]
		DPW	DEBUG_FILE_XFER, ax
		call	KernelSafeUnlock

	; make sure there is a file handle and the GA_KEEP_FILE_OPEN bit
	; is set as otherwise the file may have been closed and the handle
	; invalid
		mov_tr	bx, ax			; bx <- file handle
		tst	bx			; make sure the file handle
		jz	error			; non-zero
		test	dx, mask GA_KEEP_FILE_OPEN
		jz	error

	;
	; Load up registers for read, regardless of type of handle:
	; 	cx <- # bytes to read
	;	sidi <- offset from which to read
	;	ds:dx <- buffer to which to read (rpc_ToHost, right after the
	;		 ReadGeodeReply header)
	;
		mov	cx, ({ReadGeodeArgs}CALLDATA).RGA_size
		movdw	sidi, ({ReadGeodeArgs}CALLDATA).RGA_offset
		mov	dx, offset rpc_ToHost + size ReadGeodeReply

	;
	; See if handle is GEOS or DOS (using 100h for now, should really be
	; the first handle in the handle table)
	; 
		cmp	bx, 100h
		jb	dosFileRead

		call	KernelSafeFileRead
		jmp	done
dosFileRead:
	; until the DOS file system driver is loaded,
	; we have a dos handle, not a GEOS handle, so just do a normal dos
	; file position and file read
		call	KernelDosFileRead
done:
		.leave
		ret
error:
		mov	al, FILE_XFER_QUIT
		stc
		jmp	done
KernelReadFromGeodeFile endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelDosFileRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read data from a dos file

CALLED BY:	KernelReadFromGeodeFile

PASS:		bx = DOS file handle
		sidi = offset to read from
		cx = how much to read
		ds:dx = buffer to read into

RETURN:		ds:dx =  buffer full of data read in
		cx = # of bytes read

DESTROYED:	ax, dx, si, di

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/ 7/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KernelDosFileRead	proc	near
		.enter
		DPC	DEBUG_FILE_XFER, 'D'
	; first save away current position
		push	cx, dx
		clr	cx, dx
		mov	ax, MSDOS_POS_FILE shl 8 or FILE_POS_RELATIVE
		int	21h
		xchg	di, dx
		mov	cx, si			; cxdx <- new position
		mov_tr	si, ax			; disi <- old position

	; add size GeosFileHeader to the offset since we are now starting
	; from the actual beginning of the file
		.assert	size GeosFileHeader eq 256
		adddw	cxdx, <size GeosFileHeader>
		DPW	DEBUG_FILE_XFER, dx
		mov	ax, MSDOS_POS_FILE shl 8 or FILE_POS_START
		int	21h
		pop	cx, dx			; ds:dx <- buffer to read into
						; cx <- # bytes
		jc	error

		DPW	DEBUG_FILE_XFER, cx
		DPW	DEBUG_FILE_XFER, bx
		mov	ah, MSDOS_READ_FILE
		int	21h
		jc	error

		DPW	DEBUG_FILE_XFER, ax
	; now restore old position
		push	ax
		movdw	cxdx, disi
		mov	ax, MSDOS_POS_FILE shl 8 or FILE_POS_START
		int	21h
		pop	cx		; return cx = # of bytes read
		DPC	DEBUG_FILE_XFER, 'd'
		clc
done:
		DA	DEBUG_FILE_XFER, <pushf>
		DA	DEBUG_FILE_XFER, <push ax>
		DPC	DEBUG_FILE_XFER, 'D', inv
		DA	DEBUG_FILE_XFER, <pop ax>
		DA	DEBUG_FILE_XFER, <popf>
		.leave
		ret
error:
		DPC	DEBUG_FILE_XFER, 'd', inv
		stc
		jmp	done
KernelDosFileRead	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelSafeFileRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read from a file using GEOS's FileRead

CALLED BY:	KernelReadFromGeodeFile
PASS:		BX	= GEOS File Handle
		DS:DX	= buffer to write to
		CX	= number of bytes to read
		SI:DI	= dword offset to start reading at

RETURN:		Carry set if couldn't read from the file
			ax	= FileError or FILE_XFER_QUIT
		carry clear if read:
			cx	= # bytes read

DESTROYED:	ax, es, dx, di

PSEUDO CODE/STRATEGY:
		If block resident, call MemLock on it and return carry clear
		Else, if block discarded, send error and return carry set
		Else if dosSem free, call MemLock anyway and let the kernel
			swap the block in (can only do this if the semaphore
			is free b/c if we try to context switch out of
			kernel mode [which is what we're in], the kernel
			will abort)
		Else send error and return carry set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

KernelSafeFileRead	proc	near
		uses	si, bp
		.enter
	;
	; If not attached, kernel not loaded, so can't do anything here.
	;
		mov	al, FILE_XFER_QUIT
		tst	ds:[kernelCore]
		stc
		LONG jz	exit

		mov	es, ds:[kdata]
		mov	bp, si		; bpdi <- read start offset
		
	; now lets turn off the EC flags
		mov	si, ds:[sysECLevelOff]
		tst	si
		jz	afterECset		; => we're attached to non-ec,
						;  so don't do this stuff
		push	es:[si]
		mov	{word}es:[si], 0		; clear out EC flags
afterECset:
	;
	; If something's in DOS, we can't possibly read, so check the DOS
	; semaphore first...
	; 
		mov	si, ds:[dosSemOff]
		cmp	es:[si].Sem_value, 0
		jle 	KSLError	; Semaphore taken -- honk

		DPW	DEBUG_FILE_XFER, es:[bx].HM_owner
if 0
		DA	DEBUG_FILE_XFER, <push ax>
		DPC	DEBUG_FILE_XFER, 't'
		DPB	DEBUG_FILE_XFER, es:[bx].HG_data1
		DPB	DEBUG_FILE_XFER, es:[bx].HG_type
		DPW	DEBUG_FILE_XFER, es:[bx].HG_owner
		DA	DEBUG_FILE_XFER, <pop ax>
endif
		cmp	es:[bx].HG_type, SIG_FILE
		jne	KSLError
	;
	; Set the segment portion of FileReadVec & FilePosVec to match kcode.
	; 
		mov	ax, ds:[kcodeSeg]
		mov	ds:[FileReadVec].segment, ax
		mov	ds:[FilePosVec].segment, ax

	;
	; now we have our file handle, first we position the file pointer
	; calling FilePos after saving the current position for later
	; restoration.
	; 
		push	cx, dx

		DPC	DEBUG_FILE_XFER, 'p'
if 0
		DPW	DEBUG_FILE_XFER, cx
		DPW	DEBUG_FILE_XFER, bx
endif
	; Put a signature in here so that some EC code in SysLockCommon
	; can tell that this is the swat stub and not really the kernel.

		call	KernelSetSwatStubFlag

		mov	al, FILE_POS_RELATIVE
		clr	cx
		mov	dx, cx
		call	cs:[FilePosVec]
		xchg	di, dx
		mov	cx, bp			; cxdx <- new position
		mov_tr	bp, ax			; dibp <- old position

		DPB	DEBUG_FILE_XFER, es:[bx].HF_accessFlags

		DPC	DEBUG_FILE_XFER, 'P'
		DPW	DEBUG_FILE_XFER, cx
		DPW	DEBUG_FILE_XFER, dx
		DPW	DEBUG_FILE_XFER, bx

		mov	al, FILE_POS_START
		call	cs:[FilePosVec]		; dx:ax = new position
		DPW	DEBUG_FILE_XFER, dx
		DPW	DEBUG_FILE_XFER, ax

		pop	cx, dx

		DPC	DEBUG_FILE_XFER, 'R'
		DPW	DEBUG_FILE_XFER, bx
		DPW	DEBUG_FILE_XFER, cx
if 0
		DPW	DEBUG_FILE_XFER, cs:[FileReadVec].segment
		DPW	DEBUG_FILE_XFER, cs:[FileReadVec].offset
endif
	; inform the kernel that this is really the swat stub
		clr	al
		call	cs:[FileReadVec]; Call through FileRead vector to 
					; read the data. Returns carry set/clear
					; and ax = FileError/cx = # bytes read
	;
	; Restore old position regardless of success or failure of read.
	; 
		pushf
		push	ax, cx
		mov	al, FILE_POS_START
		movdw	cxdx, dibp
		call	cs:[FilePosVec]
		pop	ax, cx
		popf

		DA	DEBUG_FILE_XFER, <jc KSLError>
		DPC	DEBUG_FILE_XFER, 'r'
		DPW	DEBUG_FILE_XFER, cx
done:
	;
	; Restore EC flags to their previous settings before returning.
	; 
		mov_tr	dx, ax
		lahf
		mov	si, ds:[sysECLevelOff]
		tst	si
		jz	afterECreset		; => non-ec, so didn't push
						;  anything
		pop	es:[si]			; restore old EC state
afterECreset:
		sahf
		mov_tr	ax, dx

exit:
		.leave
		ret

KSLError:
		mov	al, FILE_XFER_QUIT
		DA	DEBUG_FILE_XFER, <push ax>
		DPW	DEBUG_FILE_XFER, ax
		DPW	DEBUG_FILE_XFER, cx
		DPC	DEBUG_FILE_XFER, 'e', inv
		DA	DEBUG_FILE_XFER, <pop ax>
		stc
		jmp	done
KernelSafeFileRead	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelSafeLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a handle in the kernel without chance of being
		blown up.

CALLED BY:	Kernel_ReadMem, Kernel_WriteMem, Kernel_FillMem
PASS:		BX	= handle ID to lock
RETURN:		Carry set if couldn't lock the block. If so, an RPC_SWAPPED
			error has already been returned.
		ES	= segment address for block if locked.
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		If block resident, call MemLock on it and return carry clear
		Else, if block discarded, send error and return carry set
		Else if dosSem free, call MemLock anyway and let the kernel
			swap the block in (can only do this if the semaphore
			is free b/c if we try to context switch out of
			kernel mode [which is what we're in], the kernel
			will abort)
		Else send error and return carry set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelSafeLock	proc	near
		uses	si, cx, dx, bx
		.enter
	;
	; If not attached, kernel not loaded, so can't do anything here.
	;
		tst	ds:[kernelCore]
		jz	KSLError
		mov	es, ds:[kdata]
		mov	ax, es:[bx].HM_addr
                cmp     ax, 0xF000          ; Is this a handle to something special?
                jae     KSLError
		test	es:[bx].HM_flags, MASK HF_FIXED
		jz	KSL1
		;
		; Block is fixed, so just fetch its address into ES, clear
		; the carry and return.
		; 
KSLRetAX:
		mov	es, ax
		clc
done:
		.leave
		ret
KSL1:
		;
		; See if the block is resident...
		; 
		tst	ax
		jz	KSLNonResident

		cmp	es:[bx].HM_lockCount, 255	; pseudo-fixed?
		je	KSLRetAX
		inc	es:[bx].HM_lockCount	; Lock the block (for
						; consistency with swapped-in
						; blocks).
		jmp	KSLRetAX
KSLNonResident:
		DPC	DEBUG_XIP, 'l'
		test	es:[bx].HM_flags, MASK HF_SWAPPED
		jnz	notXIP		; swapped XIP handles should be treated
					; like non-XIP handles (atw - 4/96)
		; lets see if its an XIP handle, and if so, just bank it in
		; rather than calling ReadMem, we must be sure to save
		; away the currently banked in page number so we can 
		; restore in on the call to MemUnlock
		call	Kernel_TestForXIPHandle
		cmp	dx, BPT_NOT_XIP
		je	notXIP
		call	Kernel_SafeMapXIPPage	; dx is already page number
		mov	ax, cx
		shr	ax
		shr	ax
		shr	ax
		shr	ax
		add	ax, bx
		jmp	KSLRetAX
KSLError:
	;
	; Don't return an error here if the call being processed is the
	; HELLO call sent down to connect to the kernel...this allows the
	; user to attach even if a core block is swapped out and can't
	; be swapped back in again.
	; 
		cmp	ds:[rpc_LastCall].RMB_header.rh_procNum, RPC_HELLO
		je	errorDone

	; READ_GEODE wants to handle its own error conditions as well
		cmp	ds:[rpc_LastCall].RMB_header.rh_procNum, RPC_READ_GEODE
		je	errorDone

		mov	ax, RPC_SWAPPED	; Tell the host we can't access that
					; block.
		call	Rpc_Error
errorDone:
		stc
		jmp	done

notXIP:

		;
		; Non-resident. Was it discarded?
		; 
		test	es:[bx].HM_flags, MASK HF_DISCARDED
		jnz	KSLError	; Discarded -- honk
		;
		; Can we force it to be swapped in?
		; 

		mov	si, ds:[dosSemOff]
		cmp	es:[si].Sem_value, 0
		jle	KSLError	; Semaphore taken -- honk
		;
		; Heap semaphore already held? (i.e. will we c-switch if
		; we call MemLock?)
		;
		mov	si, ds:[heapSemOff]
		cmp	es:[si].Sem_value, 0
		jle	KSLError	; Choke -- MemLock will block.

		;
		; Masquerade as the block's owner so the kernel doesn't
		; abort, should the block not be shareable
		; 

	; Put a signature in here so that some EC code in SysLockCommon
	; can tell that this is the swat stub and not really the kernel.

		call	KernelSetSwatStubFlag

		push	ss:[TPD_processHandle]
		mov	ax, es:[bx].HM_owner
		mov	ss:[TPD_processHandle], ax

	;
	; Set the segment portion of MemLockVec to match kcode.
	; 
		mov	ax, ds:[kcodeSeg]
		mov	ds:[MemLockVec].segment, ax
		
	    ;
	    ; Save both words of the header (XXX) so any reply knows where to
	    ; go. We have to do this b/c the locking of a block with HF_DEBUG
	    ; set causes a message to be sent up and responded to, overwriting
	    ; the rpc_LastCall buffer. -- ardeb 4/20/92
	    ; 
		
		push	{word}ds:[rpc_LastCall].RMB_header,
			{word}ds:[rpc_LastCall].RMB_header+2
		push	ds
		mov	ax, 0
		mov	ds, ax		; defeat ec +segment by not passing
					;  DS as ourself. ES is kdata, so it's
					;  fine.
		call	cs:[MemLockVec]	; Call through MemLock vector to lock/
					; swap in the block. Returns
					; dataAddress in AX and carry clear.
		pop	ds
		pop	{word}ds:[rpc_LastCall].RMB_header,
			{word}ds:[rpc_LastCall].RMB_header+2
		pop	ss:[TPD_processHandle]
		jc	KSLError
		jmp	KSLRetAX
KernelSafeLock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_SafeMapXIPPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	map in an XIP page using the kernels routine to do so

CALLED BY:	Kernel_BlockInfo
PASS:		dx	= page number, or BPT_NOT_XIP if restoring previous
RETURN:		carry set if not attached
		bx	= segment of mapped page
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/94		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_SafeMapXIPPage	proc	near
		uses	di, es
		.enter
	;
	; If not attached, kernel not loaded, so can't do anything here.
	;
		DPC	DEBUG_XIP, 'M'
		DPW	DEBUG_XIP, dx
		DPW	DEBUG_XIP, ds

		tst	ds:[kernelCore]
		jz	error

		tst	ds:[xipHeader]
		jz	error			; => not XIP system
	;
	; Fetch the current page so we can save it or see if we need to do
	; any further work, once we've determined what page we're trying to map
	;
		mov	es, ds:[kdata]
		mov	di, ds:[curXIPPageOff]
		mov	di, es:[di]

		cmp	dx, BPT_NOT_XIP
		jne	saveCurPage
	;
	; Restoring the previous page, so fetch that out of oldXIPPage and set
	; DX to that former page.
	;
		xchg	ds:[oldXIPPage], dx
		jmp	havePage

saveCurPage:
	;
	; Record the current page for restoration.
	;
		mov	ds:[oldXIPPage], di

havePage:
	; if the new one is the same as the current one, do nothing else

		DPW	DEBUG_XIP, di

		mov	bx, ds:[xipPageAddr]	; assume same...
		cmp	di, dx
		je	done	; carry set to zero when equal

	;
	; Set the segment portion of MapXIPPageVec to match kcode.
	; 
		mov	ax, ds:[kcodeSeg]
		mov	ds:[MapXIPPageVec].segment, ax

	; Put a signature in here so that some EC code in SysLockCommon
	; can tell that this is the swat stub and not really the kernel.

		call	KernelSetSwatStubFlag

		push	ds
		segmov	ds, es		; ds is kdata for MapXIPPage

		DPC	DEBUG_XIP, 'p'
		DPW	DEBUG_XIP, cs:[MapXIPPageVec].segment
		DPW	DEBUG_XIP, cs:[MapXIPPageVec].offset
		call	cs:[MapXIPPageVec]	; bx <- map segment
		pop	ds
		DPW	DEBUG_XIP, bx
		clc
done:
		.leave
		ret
error:
		DPC	DEBUG_XIP, 'm'
		DPW	DEBUG_XIP, dx
		stc
		jmp	done
Kernel_SafeMapXIPPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelSafeUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a block safely (i.e. without making the kernel die)

CALLED BY:	Kernel_ReadMem, Kernel_WriteMem, Kernel_FillMem
PASS:		BX	= HandleMem to unlock
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelSafeUnlock proc	near
		uses	es, di, ax, dx, ds
		.enter
		DPC	DEBUG_XIP, 'U'
		DPW	DEBUG_XIP, bx
		DPW	DEBUG_XIP, ds
		;
		; S.O.R.
		; 
		;
		; If block is FIXED, no need to unlock it.
		; 

		PointDSAtStub 	; make sure ds = scode

		mov	es, cs:[kdata]
		test	es:[bx].HM_flags, MASK HF_FIXED
		jnz	KSURet
		cmp	es:[bx].HM_lockCount, 255	; pseudo-fixed?
		je	KSURet

	; if its already in memory, just decrement its lock count
		tst	es:[bx].HM_addr
		jnz	notXIP
	
	; if its an XIP handle, we should bank in whatever we unbanked
	; when we did the MemLock
		push	cx
		call	Kernel_TestForXIPHandle
		pop	cx
		cmp	dx, BPT_NOT_XIP
		je	notXIP
		DPC	DEBUG_XIP, 'X'
		push	bx
		mov	dx, BPT_NOT_XIP		; dx <- restore previous
		call	Kernel_SafeMapXIPPage
		pop	bx
		jmp	KSURet
notXIP:
		
	;
	; Decrement the lock count of the block. MemUnlock does
	; other things (like updating heapCounter and the block's
	; usageValue), but a) it's unnecessary and b) we (as the
	; debugger) want to disturb as little as possible.
	; 
		dec	es:[bx].HM_lockCount
KSURet:
		;
		; R.O.R.
		; 
		.leave
		ret
KernelSafeUnlock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_ReadMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read memory from a handle

CALLED BY:	Rpc_Wait
PASS:		ReadArgs structure in CALLDATA
RETURN:		Nothing
DESTROYED:	SI, DI, CX, AX, BX

PSEUDO CODE/STRATEGY:
	Load the handle ID into BX and lock it using KernelSafeLock
	If lock unsuccessful, return
	Else set up for a repeated MOVSB and do that into rpc_ToHost
	Unlock the handle
	Call Rpc_Reply to send the data back to the host.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_ReadMem	proc	near
		push	es
		DPC	DEBUG_FALK3, 'A'
	;
	; Load SI and CX with the offset and count for the transfer
	; of bytes from the block. ES contains the segment, so
	; all we need to do is call Rpc_Reply -- it will copy the
	; bytes into the output queue...
	; 
		clr	ecx
		mov	si, ({ReadArgs}CALLDATA).ra_offset
		mov	cx, ({ReadArgs}CALLDATA).ra_numBytes
                call    Rpc_ReplyCCOut
		mov	bx, ({ReadArgs}CALLDATA).ra_handle
		DPC	DEBUG_XIP, 'R'
		DPW	DEBUG_XIP, si
		DPW	DEBUG_XIP, cx
		DPW	DEBUG_XIP, bx
		call	KernelSafeLock
		jc	done 	; No access -- KernelSafeLock will have sent
				; the error message for us.
		push	bx
		mov	bx, es
		mov	dx, si
		call    GPMISelectorCheckLimits		; cx adjusted to bounds
		pop	bx
		jc	selectorBad
reply:
		DPC	DEBUG_FALK3, 'B'
		call	Rpc_Reply
		;
		; Unlock the block -- BX still contains the handle ID
		; 
		DPC	DEBUG_FALK, 'C'
		call	KernelSafeUnlock
done:
		DPC	DEBUG_FALK, 'D'
		pop	es
		ret
selectorBad:
                ; No selector?  Copy nothing in the reply then
                clr     ecx
                segmov  es, cs
                clr     si
                jmp     reply
Kernel_ReadMem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelCalculateBlockSum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the new/current checksum for the block.

CALLED BY:	KernelUndoChecksum, KernelRecalcChecksum
PASS:		es	= kdata
		bx	= block handle
		ds	= segment of locked block
RETURN:		ax	= checksum
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelCalculateBlockSum proc	near
		uses	cx, si, di
		.enter

		mov	cx, es:[bx].HM_size
DPW	DEBUG_MEM_WRITE, bx
DPW	DEBUG_MEM_WRITE, cx
	; generate the checksum -- cx = # paragraphs

		clr	si
		clr	di			;di = checksum
addLoop:
		lodsw				;1
		add	di, ax
		lodsw				;2
		add	di, ax
		lodsw				;3
		add	di, ax
		lodsw				;4
		add	di, ax
		lodsw				;5
		add	di, ax
		lodsw				;6
		add	di, ax
		lodsw				;7
		add	di, ax
		lodsw				;8
		add	di, ax
		loop	addLoop

	; di = checksum (if 0 then make 1)

		tst	di
		jnz	done
		inc	di
done:
		mov_tr	ax, di
		.leave
		ret
KernelCalculateBlockSum endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelUndoChecksum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the words we're about to overwrite from the EC block
		checksum, if they're there.

CALLED BY:	Kernel_WriteMem
PASS:		es:di	= start of affected range
		ds	= cgroup
		cx	= # bytes in affected range
		bx	= handle of block being written
RETURN:		ax	= checksum to pass to KernelRecalcChecksum
			= 0 if checksum shouldn't be generated after the
			  write (if kernel hasn't generated the sum yet,
			  or the checksum is invalid before the write)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelUndoChecksum proc	near
		uses	ds, es, si
		.enter

	DPC DEBUG_MEM_WRITE, 'w'
	DPW DEBUG_MEM_WRITE, cx

		clr	ax

		tst	ds:[sysECBlockOff]
		jz	done			; => non-ec
		
	;
	; See if the write falls within the current checksum block.
	; 
		push	es
		mov	si, ds:[sysECBlockOff]
		mov	es, ds:[kdata]		; es:si <- sysECBlock
		cmp	bx, es:[si]		; same block?
		pop	ds			; ds:di <- start of affected
						;  range
		jne	done			; not same block
		
		call	KernelCalculateBlockSum	; ax <- sum
		
	DPW DEBUG_MEM_WRITE, ax

		mov	si, cs:[sysECChecksumOff]

		cmp	ax, es:[si]
		je	done

	DA DEBUG_MEM_WRITE, <lodsw es:>
	DPW DEBUG_MEM_WRITE, ax

		clr	ax
done:
		.leave
		ret
KernelUndoChecksum endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelRecalcChecksum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the EC block checksum using the words we just 
		wrote

CALLED BY:	Kernel_WriteMem
PASS:		es	= segment of locked block
		ax	= checksum from which to start (0 if shouldn't
			  calculate a new sum)
		bx	= block being written to
		ds	= cgroup
RETURN:		nothing
DESTROYED:	ax, cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelRecalcChecksum proc near
		uses	bx, ds, es
		.enter

	DA DEBUG_MEM_WRITE, <push ax>
	DPC DEBUG_MEM_WRITE, 'r'
	DA DEBUG_MEM_WRITE, <pop ax>
	DPW DEBUG_MEM_WRITE, ax

		tst	ax			; are we to generate things?
		jz	done			; no

		mov	ax, ds:[kdata]
		mov	cx, es
		mov	ds, cx			; ds <- block
		mov	es, ax			; es <- kdata
		call	KernelCalculateBlockSum	; ax <- new sum
		
		mov	si, cs:[sysECChecksumOff]; es:si <- sysECChecksum
		mov	es:[si], ax

	DPW DEBUG_MEM_WRITE, ax

done:
		.leave
		ret
KernelRecalcChecksum endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_WriteMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write memory into a block via its handle

CALLED BY:	Rpc_Wait
PASS:		WriteArga and data in CALLDATA
		number of bytes in rpc_LastCall.RMB_header.rh_length
RETURN:		Nothing
DESTROYED:	SI, DI, CX, AX, BX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_WriteMem	proc	near
		uses	es, dx
		.enter
	;
	; Load DI and CX with the offset and count for the transfer
	; of bytes to the block. The number of bytes to write is
	; encoded in the header for the RPC as Rpc_Length() -
	; size WriteArgs. The data to be written are at size WriteArgs
	; bytes from the start of the argument buffer (CALLDATA)
	; 
		mov	di, ({WriteArgs}CALLDATA).wa_offset
		call	Rpc_Length
		sub	cx, size WriteArgs
		mov	bx, ({WriteArgs}CALLDATA).wa_handle
		call	KernelSafeLock
		jc	KWMRet			; No access -- KernelSafeLock
						; will have sent the error
						; message for us.
		mov	si, offset CALLDATA + size WriteArgs
	;
	; Make sure this write won't affect our state block.
	; 
		mov	ax, es
		mov	dx, bp
		cmp	ax, sstack
		je	checkState
		cmp	ax, cgroup
		jne	doWrite
	    ;
	    ; Normalize the current value of bp to be relative to cgroup,
	    ; not sstack, for valid comparison...
	    ; 
		mov	dx, sstack
		sub	dx, cgroup
		shl	dx
		shl	dx
		shl	dx
		shl	dx
		add	dx, bp
checkState:
		mov	ax, dx
		add	ax, size StateBlock
		cmp	di, ax
		jae	doWrite			; => starts after state, so ok

		mov	ax, cx
		add	ax, di
		cmp	ax, dx
		jbe	doWrite			; => ends before state, so ok

		mov	ax, dx
		sub	ax, di
		jb	moveStart		; => state is < di, so want to
						;  move di beyond the end of
						;  the state block
		mov_tr	cx, ax			; else di < state, so move in
						;  only enough bytes to get up
						;  to the state block, but no 
						;  farther
		jmp	doWrite

moveStart:
		mov	ax, dx
		add	ax, size StateBlock	; ax <- end of state block
		sub	ax, di			; ax <- # bytes to skip
		add	di, ax			; skip that many in dest
		add	si, ax			;  and source
		sub	cx, ax			; remove that many from length

doWrite:

	; XXX: In theory, the bytes following the WriteArgs structure could
	; have been biffed by a transaction during the call to KernelSafeLock.
	; In practice, the only thing coming down from the host will be
	; an RpcHeader that is a zero-length reply to whatever call we
	; sent up.

	;
	; Deal with the checksummed block.
	; 
		call	KernelUndoChecksum	; ax <- checksum w/o words
						;  about to be overwritten

		push	ax
		call	Kernel_EnsureESWritable
		push	ax

		dsi
		cld

if	 _WRITE_ONLY_WORDS
	; For these versions, we can only WRITE WORDS out to the memory.
	
		call	Kernel_CopyMemWordAligned

else	;_WRITE_ONLY_WORDS is FALSE
		test	cx, 1
		jz	KWM2
		movsb		; Move single byte
		dec	cx
		jcxz	KWM3
KWM2:
                ; Aha!  But in Protected Mode, we need to ensure we can't write past our limits
		push	bx, dx
		mov	bx, es
		mov	dx, di
		call    GPMISelectorCheckLimits		; cx adjusted to bounds
		pop	bx, dx

		shr	cx, 1	; Move words
		rep	movsw
KWM3:

endif	;_WRITE_ONLY_WORDS

		eni

		pop	ax
		call	Kernel_RestoreWriteProtect
		pop	ax
	;
	; Deal with the checksummed block.
	; 
		call	KernelRecalcChecksum
		;
		; Send null reply.
		; 
		clr	cx
		call	Rpc_Reply

		;
		; Unlock the block -- BX still contains the handle ID
		; 
		call	KernelSafeUnlock
KWMRet:
		.leave
		ret
Kernel_WriteMem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_FillMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill memory in a block with a byte

CALLED BY:	Rpc_Wait
PASS:		FillArgs structure in CALLDATA
RETURN:		Nothing
DESTROYED:	DI, CX, AX, BX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_FillMem	proc	near
		push	es
		;
		; Load DI and CX with the offset and count for the transfer
		; of bytes to the block.
		; 
		mov	di, ({FillArgs}CALLDATA).fa_offset
		mov	cx, ({FillArgs}CALLDATA).fa_length
		cld
		mov	bx, ({FillArgs}CALLDATA).fa_handle
		call	KernelSafeLock
		jc	KFMRet			; No access -- KernelSafeLock
						; will have sent the error
						; message for us.

		call	Kernel_EnsureESWritable
		mov_tr	dx, ax

		mov	ax, ({FillArgs}CALLDATA).fa_value

		cmp	ds:[rpc_LastCall].RMB_header.rh_procNum, RPC_FILL_MEM8
		jne	KFMWord

		rep	stosb
		jmp	short KFMDone
KFMWord:
		rep	stosw
KFMDone:
		mov_tr	ax, dx
		call	Kernel_RestoreWriteProtect
		;
		; Send null reply.
		; 
		clr	cx
		call	Rpc_Reply

		;
		; Unlock the block -- BX still contains the handle ID
		; 
		call	KernelSafeUnlock
KFMRet:
		pop	es
		ret
Kernel_FillMem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_ReadAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read from absolute memory (server for RPC_READ_ABS)

CALLED BY:	Rpc_Wait
PASS:		AbsReadArgs in CALLDATA
RETURN:		Nothing
DESTROYED:	EBX, ECX, DX, SI, DI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_ReadAbs	proc	near
		push	es
		;
		; Load the registers for the transfer. CX comes from the
		; ara_numBytes field of the request, while ES:SI is loaded from
		; the ara_offset and ara_segment fields.
		; 
                clr     ecx
		mov	cx, ({AbsReadArgs}CALLDATA).ara_numBytes
                call    Rpc_ReplyCCOut
                xor     edx, edx
                mov     bx, ({AbsReadArgs}CALLDATA).ara_segment
		mov     dx, ({AbsReadArgs}CALLDATA).ara_offset
		.inst db 00fh, 000h, 0e3h	; verr bx
		jnz	selectorBad		; branch if selector unreadable
                call    GPMISelectorCheckLimits
		jc	selectorBad		; branch if GPMI objects
		call	GPMITestPresent
		jc	selectorBad		; branch if not present
		les	si, dword ptr ({AbsReadArgs}CALLDATA).ara_offset
dontUseSelector:
		call	Rpc_Reply
		pop	es
		ret
selectorBad:	
                ; No selector?  Copy nothing in the reply then
                clr     ecx
                segmov  es, cs
                clr     si
                jmp     dontUseSelector
Kernel_ReadAbs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_WriteAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write data to an absolute location

CALLED BY:	Rpc_Wait
PASS:		CALLDATA contains an AbsWriteArgs structure
RETURN:		Null Reply
DESTROYED:	...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_WriteAbs	proc	near
		push	es
		;
		; Load the registers for the transfer. CX returned by
		; Rpc_Length function, while ES:DI is loaded from the awa_offset
		; and awa_segment fields.
		;
		; SI is just CALLDATA + size AbsWriteArgs since the data
		; follow the args immediately.
		; 
		call	Rpc_Length
		sub	cx, size AbsWriteArgs
		les	di, dword ptr ({AbsWriteArgs}CALLDATA).awa_offset
		mov	si, offset CALLDATA + size AbsWriteArgs

		call	Kernel_EnsureESWritable
		;
		; Move the requested data into memory.
		; 
		cld
		dsi

if	 _WRITE_ONLY_WORDS
	; For these versions, we can only WRITE WORDS out to the memory.
	
		push	ax
		call	Kernel_CopyMemWordAligned
		pop	ax
else	;_WRITE_ONLY_WORDS is FALSE
		rep	movsb
endif	;_WRITE_ONLY_WORDS

		eni
		
		call	Kernel_RestoreWriteProtect
		;
		; Restore ES to cgroup for the reply (which is NULL)
		; 
		pop	es
		clr	cx
		call	Rpc_Reply
		ret
Kernel_WriteAbs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_CopyMemWordAligned
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies a chunk of memory but does it so that only words
		are written out.  This is for the stub versions where
		_WRITE_ONLY_WORDS is TRUE.  Some devices are incapable of
		writing unaligned bytes to certain areas of memory.

CALLED BY:	Kernel_WriteAbs, Kernel_WriteMem (_WRITE_ONLY_WORDS only)

PASS:		ds:si	= source
		es:di	= dest
		cx	= count

RETURN:		nothing

DESTROYED:	di, si, cx, ax

SIDE EFFECTS:	
	NOTE: This does NOT disable interrupts, so if you want them
	disabled, do it before you call.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	3/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _WRITE_ONLY_WORDS

Kernel_CopyMemWordAligned	proc	near
		.enter
		test	di, 1
		jz	evenStart
		
	; Odd starting point.  Read back the word containing the odd byte from
	; SRAM.  Then read the byte from the buffer into the high byte and
	; write the word back out.
		
		dec	di				; back up to word bndry
		mov	ax, {word} es:[di]
		mov	ah, {byte} ds:[si]
		mov	{word} es:[di], ax

		inc	di				; move dest to next word
		inc	di
		inc	si				; move src to next byte

		dec	cx				; one less byte
	
evenStart:
		tst	cx
		jz	doneWithCopy
	
	; Do the bulk of the copy with repsw
		shr	cx, 1
		rep	movsw
		jnc	doneWithCopy			; even count - done
	
	; Odd count.. copy last byte, writing words.
		mov	ax, {word} es:[di]
		mov	al, {byte} ds:[si]
		mov	{word} es:[di], ax

doneWithCopy:
		.leave
		ret
Kernel_CopyMemWordAligned	endp

endif	;_WRITE_ONLY_WORDS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_FillAbs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a range of memory at an absolute address

CALLED BY:	Rpc_Wait
PASS:		AbsFillArgs structure in CALLDATA
RETURN:		Null reply
DESTROYED:	...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_FillAbs	proc	near
		push	es
		;
		; Load the registers for the fill. CX comes from the
		; afa_length field of the request, while ES:DI is
		; loaded from the afa_offset and afa_segment fields.
		; 
		mov	cx, ({AbsFillArgs}CALLDATA).afa_length
		les	di, dword ptr ({AbsFillArgs}CALLDATA).afa_offset
		cld
		
		call	Kernel_EnsureESWritable
		mov_tr	bx, ax

		mov	ax, ({AbsFillArgs}CALLDATA).afa_value


		cmp	ds:[rpc_LastCall].RMB_header.rh_procNum, RPC_FILL_ABS8
		jne	KFAWord
		;
		; Fill the requested area of memory.
		; 
		rep	stosb
		jmp	short KFADone
KFAWord:
		rep	stosw
KFADone:
		mov_tr	ax, bx
		call	Kernel_RestoreWriteProtect
		;
		; Restore ES to cgroup for the reply (which is NULL)
		; 
		pop	es
		clr	cx
		call	Rpc_Reply
		ret
Kernel_FillAbs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelMapOwner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with ownership by things other than Geodes

CALLED BY:	Kernel_BlockInfo, Kernel_BlockFind
PASS:		ES	= kdata
		AX	= owner ID
RETURN:		AX	= owner ID to return
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		There are things in this system (e.g. VM blocks) that are
		owned by a handle other than a Geode (a VM block is owned
		by its corresponding VMHandle). This is not something Swat
		can deal with. To get around this, we examine the owner's
		signature to make sure the thing is actually a memory handle.
		If it ain't, we return HID_KDATA so Swat thinks it's owned
		by the kernel.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/15/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelMapOwner	proc	near
		push	bx
		mov	bx, ax
		cmp	ax, ds:[HandleTable]	; Handle font blocks and
						;  things owned by the kernel
						;  w/o having to hope that
						;  kdata:11h or kdata:21h
						;  contains a value >= f8h
		jb	ownedByKernel
		cmp	es:[bx].HM_addr.high, SIG_NON_MEM
		jb	KMORet		; Is memory handle, is ok
ownedByKernel:
		mov	ax, ds:[kernelCore]; Ewwww. Map it to kernel ownership
KMORet:
		pop	bx
		ret
KernelMapOwner	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_XIPSegmentToHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	map a segment to a handle for an XIP handle

CALLED BY:	GLOBAL

PASS:		cx = segment address
		ds = scode
		ax = xipPage to use (BPT_NOT_XIP to use currentPage)
RETURN:		carry clear if XIP:
			cx = handle (may not be mapped, if ax was
			     BPT_NOT_XIP on entry)
			ax = address of handle
			dx = page number
		carry set if not:
			ax, cx, dx = unchanged if cx was outside the
				XIP map bank. destroyed if it was
				inside the map bank.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/26/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Kernel_XIPSegmentToHandle	proc	near
		uses	es, bp, bx, ds, di, si
		.enter
		DA	DEBUG_XIP, <push ax>
		DPC	DEBUG_XIP, 't'
		DPW	DEBUG_XIP, cx
		DA	DEBUG_XIP, <pop ax>

		call	Kernel_CheckXIPSegment	; ax <- page #
		jnc	notXIPHandle

	; loop through the XIP handle table to find the offset within the
	; page
		DPW	DEBUG_XIP, ax
		mov	es, ds:[xipHeader]
		mov	bp, ds:[HandleTable]
		mov	dx, ds:[xipPageAddr]	; (save for later)

		mov	ds, ds:[kdata]
		mov	bx, es:[FXIPH_handleAddresses]
				
	; first, compute the offset of the thing within the map page
		sub	cx, dx
		shl	cx
		shl	cx
		shl	cx
		shl	cx
searchLoop:
		cmp	ax, es:[bx].high	; same xip page?
		jne	doNext			; no
		mov	di, es:[bx].low
		cmp	cx, di			; same offset?
		jb	doNext			; no
		mov	si, ds:[bp].HM_size	; compute first byte
		shl	si			;  not in the resource
		shl	si
		shl	si
		shl	si
		add	si, di
		cmp	si, cx
		ja	foundXIP		; => is within resource
doNext:
		add	bx, size dword				
		add	bp, size HandleMem
		cmp	bp, es:[FXIPH_lastXIPResource]
		jbe	searchLoop
notXIPHandle:
		stc
		jmp	done

foundXIP:
		mov	cx, bp			; cx <- handle
		DA	DEBUG_XIP, <push ax>
		DPC	DEBUG_XIP, 'f'
		DPW	DEBUG_XIP, cx
		DA	DEBUG_XIP, <pop ax>
		xchg	ax, di			; ax <- actual page offset
						; di <- page number
		shr	ax
		shr	ax
		shr	ax
		shr	ax
		add	ax, dx	; dx = segment address of XIP page from above
		DPW	DEBUG_XIP, ax
		mov	dx, di			; dx <- page number
		clc
done:
		.leave
		ret
Kernel_XIPSegmentToHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_CheckXIPSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a segment to see if it falls within the XIP map bank
		and return its page number if so

CALLED BY:	(EXTERNAL)
PASS:		ds	= scode
		cx	= segment
		ax	= presumed page number if it's in the map bank
			= BPT_NOT_XIP if page should be gotten from the kernel
RETURN:		carry set if segment falls within map bank:
			ax	= page number
		carry clear if segment not within map bank:
			ax	= unchanged
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/21/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_CheckXIPSegment proc	near
		uses	es, dx, bx
		.enter
		tst	ds:[xipHeader]
		jz	notXIPHandle		; => not an XIP kernel

		mov	dx, ds:[xipPageAddr]
		cmp	cx, dx
		jb	notXIPHandle		; => below map bank
		add	dx, ds:[xipPageSize]
		cmp	cx, dx
		jae	notXIPHandle		; => above map bank

		cmp	ax, BPT_NOT_XIP
		jne	gotXIPPage
		mov	es, ds:[kdata]
		mov	bx, ds:[curXIPPageOff]
		mov	ax, es:[bx]
gotXIPPage:
		stc
done:
		.leave
		ret
notXIPHandle:
		clc
		jmp	done
Kernel_CheckXIPSegment endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_GetHandleAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get an address given a handle

CALLED BY:	GLOBAL

PASS:		es:bx = HandleMem

RETURN:		ax = segment address of handle

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	see if its an XIP handle, if so do the XIP thang
			else return es:[bx].HM_addr
	
KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/26/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Kernel_GetHandleAddress	proc	far
		uses	cx, dx
		.enter
		call	Kernel_TestForXIPHandle
		cmp	dx, BPT_NOT_XIP
		je	notXIP
done:
		.leave
		ret
notXIP:
		mov	ax, es:[bx].HM_addr
		call	GPMITestPresent
		jnc	done
		clr	ax		;selector isn't present
		jmp	done
Kernel_GetHandleAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_TestForXIPHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	see if we have an XIP handle, if so return its address

CALLED BY:	GLOBAL

PASS:		bx = handle
		ds = scode

RETURN:		ax = address of segment (or what it would be if mapped in)
		dx = page number, dx = BPT_NOT_XIP if not XIP handle
		cx = page offset
		carry set if not an XIP handle or not mapped in

DESTROYED:

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/26/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Kernel_TestForXIPHandle	proc	far
		uses	es, bx, bp, ds
		.enter
		DPC	DEBUG_XIP, 'T'
	; check to see if the handle is an XIP handle
		PointDSAtStub 
		tst	ds:[xipHeader]
		jz	notXIP

		DPC	DEBUG_XIP, 't'
		mov	es, ds:[xipHeader]

		mov	cx, es:[FXIPH_lastXIPResource]

	; if the handle is greater than the lastXIPResource handle then it's
	; not an XIP handle
		cmp	bx, cx
		ja	notXIP

	; first see if its a Fixed or psuedo fixed handle, if so it
	; just acts like a NON-XIP handle
		mov	es, ds:[kdata]
		mov	ax, es:[bx].HM_addr

		test	es:[bx].HM_flags, mask HF_FIXED
		jnz	notXIP

		cmp	es:[bx].HM_lockCount, 0ffh
		je	notXIP

		mov	es, ds:[xipHeader]
				
	; it IS an XIP handle so let's decode it. First fetch the page & offset
	; from the FXIPH_handleAddresses table
		DPC	DEBUG_XIP, 'm'
		push	bx
		sub	bx, ds:[HandleTable]
		shr	bx	; (bx - handleTable)/16 = handle index
		shr	bx	; index * 4 = offset into XIP map
				; so just get (bx-handleTable)/4
		add	bx, es:[FXIPH_handleAddresses]
		movdw	dxcx, es:[bx]	; dx <- page, cx <- offset w/in page
					;		    (for return)
		pop	bx

	; compute the segment within the bank page, for return
		mov	ax, cx
		shr	ax
		shr	ax
		shr	ax
		shr	ax
		add	ax, ds:[xipPageAddr]

	; see if the thing is currently mapped in
		mov	es, ds:[kdata]
		mov	bp, ds:[curXIPPageOff]
		cmp	es:[bp], dx
		jne	notMappedIn
doneOK::
		clc			; signal mapped
done:
		.leave
		ret
notXIP:
		mov	dx, BPT_NOT_XIP
notMappedIn:
		stc
		jmp	done
Kernel_TestForXIPHandle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_BlockInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the data for a handle.

CALLED BY:	Rpc_Wait
PASS:		Handle ID in CALLDATA
RETURN:		dataAddress, paraSize, handleFlags
DESTROYED:	rpc_ToHost

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_BlockInfo proc	near
		push	es
		tst	ds:[kernelCore]
		jz	KBIBad

	;
	; Load ES:BX to point to the handle record
	; 
		mov	es, ds:[kdata]
		mov	bx, {word}CALLDATA

		cmp	bx, ds:[HandleTable]
		jb	KBIBad
		cmp	bx, ds:[lastHandle]
		ja	KBIBad

	; assume non-xip handle
		mov	dx, BPT_NOT_XIP

		tst	ds:[xipHeader]
		jz	notXIP

		tst	es:[bx].HM_addr
		jnz	notXIP

		call	Kernel_TestForXIPHandle
		cmp	dx, BPT_NOT_XIP
		jne	gotAddr
notXIP:
	;
	; Transfer the desired fields into an InfoReply structure in
	; the standard reply area.
	; 
		mov	ax, es:[bx].HM_addr
		call	GPMITestPresent
		jnc	gotAddr
		clr	ax		;selector isn't present
gotAddr:
		mov	({InfoReply}ds:[rpc_ToHost]).ir_dataAddress, ax
		tst	ax
		jnz	KBI10
	;
	; No data associated with the handle. Make sure the handle
	; itself isn't free (free handles have an owner of 0)
	;
		tst	es:[bx].HM_owner
		jz	KBIBad		; choke
KBI10:
		cmp	ah, SIG_THREAD
		je	threadInfo

		mov	al, es:[bx].HM_flags
		mov	({InfoReply}ds:[rpc_ToHost]).ir_flags, al
		mov	ax, es:[bx].HM_size
		mov	({InfoReply}ds:[rpc_ToHost]).ir_paraSize, ax
		mov	ax, es:[bx].HM_otherInfo
		mov	({InfoReply}ds:[rpc_ToHost]).ir_otherInfo, ax
storeOwner:
		mov	({InfoReply}ds:[rpc_ToHost]).ir_xipPage, dx
		mov	ax, es:[bx].HM_owner
		call	KernelMapOwner
		mov	({InfoReply}ds:[rpc_ToHost]).ir_owner, ax
	;
	; Restore ES for the reply and load up CX and SI.
	; 
		pop	es
		mov	cx, size InfoReply
		mov	si, offset rpc_ToHost
		call	Rpc_Reply
		ret
KBIBad:
		pop	es
		mov	ax, RPC_BADARGS
		call	Rpc_Error
		ret

threadInfo:
	;
	; Return special stuff if the handle being returned is for
	; a thread:
	; 	- paraSize = max sp
	;	- otherInfo = ss
	;
		mov	ax, es:[bx].HT_saveSS
		cmp	bx, ss:[bp].state_thread
		jne	checkSSBounds
		; If it's the current thread, use the saved SS in our state
		; block, not that in the handle...much more reliable.
		mov	ax, ss:[bp].state_ss
checkSSBounds:
if 0
		push	ds, bx
		mov	ds, ax
		mov	si, ds:[TPD_blockHandle]
		mov	bx, si				; es:bx = HandleMem
		call	Kernel_GetHandleAddress		; ax = address 
		mov	bx, ds				
		cmp	ax, bx
		pop	ds, bx
endif
                push    ds
                mov     ds, ax
                mov     si, ds:[TPD_blockHandle]
                cmp     ax, es:[si].HM_addr
                pop     ds
 
		jne	maybeInDOS
storeSS_SP:
		mov	ds:[({InfoReply}rpc_ToHost)].ir_otherInfo, ax
		call	KernelFindMaxSP
		mov	ds:[({InfoReply}rpc_ToHost)].ir_paraSize, ax
		jmp	storeOwner

maybeInDOS:
	;
	; Assume the thing is in DOS and return the saved SS and SP from
	; our/the kernel's PSP
	; 
		push	es
		mov	es, ds:[PSP]
		mov	ax, es:[PSP_userStack].segment
		pop	es
		jmp	storeSS_SP
Kernel_BlockInfo endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_SegmentToHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a segment to its associated handle, if possible.

CALLED BY:	Kernel_BlockFind, Bpt_Set
PASS:		cx	= segment to map
		ax	= xip page (or BPT_NOT_XIP if xip page not known)
RETURN:		carry set if not found
		carry clear if handle found:
			es:bx	= HandleMem
		ax = address, can't use es:bx.HM_addr as it might be an XIP
			resource
		dx = Xip page number or BPT_NOT_XIP if none
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_SegmentToHandle proc	near
		uses	cx, si
		.enter
		tst	ds:[kernelCore]
		jz	done			; (carry is clear)

		mov	es, ds:[kdata]

	;
	; Deal with resource being loaded by checking the resourceBeingLoaded
	; handle first, since our hack in KernelLoadRes yields two handles
	; with the same segment...
	; 
		mov	bx, ds:[resourceBeingLoaded]
		tst	bx
		jz	checkXIPHandles

		cmp	cx, es:[bx].HM_addr
		clc
		je	isXip
checkXIPHandles:
		call	Kernel_XIPSegmentToHandle
		jc	scanTable
		mov	bx, cx
		jmp	isXip
scanTable:
    	    	mov 	dx, ds:[lastHandle]    	; Load last handle into DX
		mov	bx, ds:[HandleTable]	; Start at beginning of table
						; (This puppy's static...)
scanLoop:
	;
	; Make sure it's a memory handle.
	;
		mov	ax, es:[bx].HM_addr
		cmp	ah, SIG_NON_MEM		; non-memory handle?
		jae	nextBlock		; yes -- ignore it.
		test	es:[bx].HM_flags, mask HF_DISCARDED or mask HF_SWAPPED
		jnz	nextBlock		; ignore if discarded/swapped
	;
	; See if it matches
	;
		cmp	ax, cx
		jne	nextBlock		; Close, but no cigar
	;
	; It does match. make sure it's neither free nor fake.
	;
		mov	ax, es:[bx].HM_owner
		tst	ax			; See if it's free
		jz	nextBlock		; Free -- DON'T RETURN IT EVEN
						; IF IT MATCHES.
		cmp	ax, ds:[kernelCore]
		jne	found
		
		cmp	es:[bx].HM_otherInfo, FAKE_BLOCK_CODE
		jne	found
		cmp	es:[bx].HM_lockCount, 1
		jne	found
		cmp	es:[bx].HM_flags, 0
		je	nextBlock

found:
						; found the thing. (carry set)
		mov	cx, es:[bx].HM_addr
		stc
		jmp	done
nextBlock:
	;
	; Advance to next handle
	; 
		add	bx, size HandleMem
		cmp	bx, dx
		jb	scanLoop
		; (carry is clear after a failed jb)
done:
		mov	dx, BPT_NOT_XIP	; not XIP handle
		mov_tr	ax, cx	; get segment into ax
	;
	; Invert the carry, as when we get here it's clear on error and
	; set if found.
	; 
		cmc
isXip:
		.leave
		ret
Kernel_SegmentToHandle endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_BlockFind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the handle of a block given its dataAddress

CALLED BY:	Rpc_Wait
PASS:		Segment address in CALLDATA
RETURN:		FindReply in rpc_ToHost
DESTROYED:	Many things.

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_BlockFind proc	near
		push	es
		mov	cx, ({FindArgs}CALLDATA).fa_address; Load segment
							;  into CX
		mov	ax, ({FindArgs}CALLDATA).fa_xipPage
		call	Kernel_SegmentToHandle
		jc	KBFError

	; ax returned from Kernel_SegmentToHandle with address
		mov	({FindReply}ds:[rpc_ToHost]).fr_id, bx
		mov	({FindReply}ds:[rpc_ToHost]).fr_dataAddress, ax
		mov	ax, es:[bx].HM_size
		mov	({FindReply}ds:[rpc_ToHost]).fr_paraSize, ax
		mov	ax, es:[bx].HM_owner
		call	KernelMapOwner
		mov	({FindReply}ds:[rpc_ToHost]).fr_owner, ax
		mov	ax, es:[bx].HM_otherInfo
		mov	({FindReply}ds:[rpc_ToHost]).fr_otherInfo, ax
		mov	al, es:[bx].HM_flags
		mov	({FindReply}ds:[rpc_ToHost]).fr_flags, al
		mov	({FindReply}ds:[rpc_ToHost]).fr_xipPage, dx
		
		pop	es
		mov	cx, size FindReply
		mov	si, offset rpc_ToHost
		call	Rpc_Reply
		ret
KBFError:
		mov	ax, RPC_NOHANDLE
		pop	es
		jmp	Rpc_Error
Kernel_BlockFind endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_ReadRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a READ_REGS rpc call, returning the current
		registers for the given thread.

CALLED BY:	Rpc_Wait
PASS:		CALLDATA contains the HandleMem of the thread whose
		registers are sought.
RETURN:		Nothing
DESTROYED:	rpc_ToHost

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_ReadRegs	proc	near
		push	es			; Preserve ES...
DPC	DEBUG_XIP, 'R'

		test	ds:[sysFlags], mask dosexec
		jnz	useState
		tst	ds:[kernelCore]
		jz	useState

		mov	bx, {word}CALLDATA	; Load thread handle whose
						; registers are desired.
		cmp	bx, ds:[HandleTable]	; Loader thread?
		jae	checkStateThread
		clr	bx			; Yes -- map to kernel thread
						;  (they're effectively the
						;  same thing)
checkStateThread:
		cmp	bx, [bp].state_thread
		jne	KRR2

useState:

		;
		; Wants registers from current thread -- we've got it all in
		; the current state block. Copy the registers into an IbmRegs
		; structure at rpc_ToHost.
		; 
		mov	di, offset rpc_ToHost
		call	Rpc_LoadRegs
		mov	ax, BPT_NOT_XIP
		tst	ds:[xipHeader]
		jz	setXIP
		mov	es, ds:[kdata]
		mov	si, ds:[curXIPPageOff]
		mov	ax, es:[si]
setXIP:
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_xipPage, ax
		jmp	KRRSend
KRR2:
		;
		; Not the current thread. Copy in all registers but CS, IP,
		; AX and BX from the ts block found at the saved SS:SP.
		; 
		tst	bx
		LONG	jz	KRRKernelThread	; Kernel thread -- no registers

		mov	es, ds:[kdata]
		mov	ax, es:[bx].HT_saveSS
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_ss], ax
		mov	si, es:[bx].HT_saveSP
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_sp], si
		mov	es, ax

	; get xipPage from the ThreadBlockState
		mov	ax, BPT_NOT_XIP
		; if we are doing XIP stuff, the offsets of ThreadBlockState
		; are all off by two, of we need to account for that
		tst	ds:[xipHeader]
		jz	gotOffset
		mov	ax, es:[si]; TBS_xipPage
		add	si, 2 ; size TBS_xipPage
gotOffset:
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_xipPage, ax

		mov	ax, es:[si].TBS_bp
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_bp], ax
		mov	ax, es:[si].TBS_es
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_es], ax
		mov	ax, es:[si].TBS_dx
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_dx], ax
		mov	ax, es:[si].TBS_flags
                movToIbmRegFlags ds:[rpc_ToHost], ax
		mov	ax, es:[si].TBS_cx
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_cx], ax
		mov	ax, es:[si].TBS_di
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_di], ax
		mov	ax, es:[si].TBS_si
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_si], ax
		mov	ax, es:[si].TBS_ds
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_ds], ax
if _Regs_32
		mov	ax, es:[si].TBS_fs
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_fs], ax
		mov	ax, es:[si].TBS_gs
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_gs], ax
		mov	ax, es:[si].TBS_eaxHigh
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_ax+2], ax
		mov	ax, es:[si].TBS_ebxHigh
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_bx+2], ax
		mov	ax, es:[si].TBS_ecxHigh
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_cx+2], ax
		mov	ax, es:[si].TBS_edxHigh
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_dx+2], ax
		mov	ax, es:[si].TBS_ebpHigh
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_bp+2], ax
		mov	ax, es:[si].TBS_ediHigh
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_di+2], ax
		mov	ax, es:[si].TBS_esiHigh
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_si+2], ax
endif		
		
		;
		; AX and BX are not (reliably) saved on the stack when a
		; thread is blocked, so we always return BOGUS_REG for them
		; 
		mov	ax, BOGUS_REG
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_ax], ax
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_bx], ax
		
		;
		; No matter how it blocked, there's a near return address
		; above the saved registers and three bytes before that
		; address is a near call. To figure out in what function
		; it was operating, we must add the offset of that near
		; call (2 bytes before the return address) to the return
		; address.
		; 
		mov	bx, es:[si].TBS_ret	; Fetch return address
		mov	ax, ds:[kcodeSeg]	; get kcodeSeg in ax and es
		mov	es, ax
		cmp	{byte}es:[bx-3], 0xe8	; Near call?
		jne	10$			; Just give address to which
						;  Dispatch will return, since
						;  we can't figure out the
						;  blocking routine...
		add	bx, es:-2[bx]		; add offset to ret addr,
						; giving ip of routine
						; responsible for block.
10$:
		;
		; now have cs in ax, and ip in bx. Stuff them
		; 
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_cs], ax
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_ip, bx
KRRSend:
		pop	es			;Restore ES for reply
		mov	cx, size IbmRegs
		mov	si, offset rpc_ToHost
DA	DEBUG_XIP, <push ax>
DPS	DEBUG_XIP, <regs>
DPW	DEBUG_XIP, ({IbmRegs}ds:[rpc_ToHost]).reg_xipPage
DA	DEBUG_XIP, <pop ax>
		call	Rpc_Reply
		ret

KRRKernelThread:
		;
		; Information requested about the kernel thread, which is
		; not running (and thus there are no good values to return).
		; Return random stuff
		;
		; Fill all the general registers with the BOGUS_REG value
		; using a repeated STOSW.
		; 
		push	ds		; Shift cgroup into ES for STOSW
		pop	es
		mov	di, offset rpc_ToHost
		mov	cx, (size IbmRegs.reg_regs) / 2
		mov	ax, BOGUS_REG
		rep stosw
		;
		; Now set up SS:SP to be the start of the handle table, which
		; is where SP will start when the scheduler thread actually
		; runs.
		; 
		mov	ax, ds:[kdata]
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_ss], ax
		mov	ax, ds:[HandleTable]
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_sp], ax
		;
		; CS:IP is taken to be BlockOnLongQueue for now. It makes no
		; difference, as there are no stack frames to decode anyway.
		; 
		mov	ax, ds:[kcodeSeg]
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_regs[reg_cs], ax
		mov	ax, ds:[BlockOnLongQueueOff]
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_ip, ax
		
		;
		; No current XIP page, thanks.
		;
		mov	({IbmRegs}ds:[rpc_ToHost]).reg_xipPage, BPT_NOT_XIP
		jmp	KRRSend
Kernel_ReadRegs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_WriteRegs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify the registers for a thread

CALLED BY:	Rpc_Wait
PASS:		WriteRegsArgs structure in CALLDATA
RETURN:		Nothing
DESTROYED:	Everything

PSEUDO CODE/STRATEGY:
		If setting for the current thread, modify our state block
		Else find the ss:sp for the thread and modify the kernel
			state block. If thread retreated into the kernel,
			return an error.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_WriteRegs proc	near
		push	es
		test	ds:[sysFlags], mask dosexec
		jnz	useState
		tst	ds:[kernelCore]
		jz	useState

		mov	bx, ({WriteRegsArgs}CALLDATA).wra_thread

		cmp	bx, ds:[HandleTable]	; Loader thread?
		jae	checkStateThread
		clr	bx			; Yes -- map to kernel thread
						;  (they're effectively the
						;  same thing)
checkStateThread:
		
		cmp	bx, [bp].state_thread
		jne	KWR2
useState:
		;
		; Modify registers for current thread -- we've got it all in
		; the current state block. Copy the registers into the state
		; block.
		; XXX: Do the 8 general regs with a MOVSW.
		; 
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_ds]
		mov	[bp].state_ds, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_ss]
		mov	[bp].state_ss, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_es]
		mov	[bp].state_es, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_cs]
		mov	[bp].state_cs, ax
if _Regs_32
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_ax]
		mov	[bp].state_ax, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_ax+2]
		mov	[bp].state_eax.high, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_cx]
		mov	[bp].state_cx, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_cx+2]
		mov	[bp].state_ecx.high, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_dx]
		mov	[bp].state_dx, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_dx+2]
		mov	[bp].state_edx.high, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_bx]
		mov	[bp].state_bx, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_bx+2]
		mov	[bp].state_ebx.high, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_si]
		mov	[bp].state_si, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_si+2]
		mov	[bp].state_esi.high, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_di]
		mov	[bp].state_di, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_di+2]
		mov	[bp].state_edi.high, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_bp]
		mov	[bp].state_bp, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_bp+2]
		mov	[bp].state_ebp.high, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_sp]
		mov	[bp].state_sp, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_sp+2]
		mov	[bp].state_esp.high, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_ip
		mov	[bp].state_ip, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_fs]
		mov	[bp].state_fs, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_gs]
		mov	[bp].state_gs, ax
else
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_ax]
		mov	[bp].state_ax, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_cx]
		mov	[bp].state_cx, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_dx]
		mov	[bp].state_dx, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_bx]
		mov	[bp].state_bx, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_si]
		mov	[bp].state_si, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_di]
		mov	[bp].state_di, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_bp]
		mov	[bp].state_bp, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_sp]
		mov	[bp].state_sp, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_ip
		mov	[bp].state_ip, ax
endif
                movFromIbmRegFlags ax, ({WriteRegsArgs}CALLDATA).wra_regs
		mov	[bp].state_flags, ax
		jmp	short KWRRet
KWR2:
		;
		; Not the current thread. Copy in all registers but CS, IP,
		; AX and BX to the ts block found at the saved SS:SP
		; AX and BX are not (reliably) saved on the stack when a
		; thread is blocked, so we can't change them.
		; 
		tst	bx
		jz	KWRNoRegs	; Kernel thread has no regs
		mov	es, ds:[kdata]
		mov	si, es:[bx].HT_saveSP
		mov	ax, es:[bx].HT_saveSS
		tst	ax
		jz	KWRNoRegs
		mov	es, ax

		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_bp]
		mov	es:[si].TBS_bp, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_es]
		mov	es:[si].TBS_es, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_dx]
		mov	es:[si].TBS_dx, ax
                movFromIbmRegFlags ax, ({WriteRegsArgs}CALLDATA).wra_regs
		mov	es:[si].TBS_flags, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_cx]
		mov	es:[si].TBS_cx, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_di]
		mov	es:[si].TBS_di, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_si]
		mov	es:[si].TBS_si, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_ds]
		mov	es:[si].TBS_ds, ax
if _Regs_32
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_fs]
		mov	es:[si].TBS_fs, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_gs]
		mov	es:[si].TBS_gs, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_ax+2]
		mov	es:[si].TBS_eaxHigh, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_bx+2]
		mov	es:[si].TBS_ebxHigh, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_cx+2]
		mov	es:[si].TBS_ecxHigh, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_dx+2]
		mov	es:[si].TBS_edxHigh, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_bp+2]
		mov	es:[si].TBS_ebpHigh, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_di+2]
		mov	es:[si].TBS_ediHigh, ax
		mov	ax, ({WriteRegsArgs}CALLDATA).wra_regs.reg_regs[reg_si+2]
		mov	es:[si].TBS_esiHigh, ax
endif
		
KWRRet:
		pop	es			;Restore ES for reply
		clr	cx
		call	Rpc_Reply
		ret
KWRNoRegs:
		;
		; Restore ES and return a BADARGS error.
		; 
		pop	es
		mov	ax, RPC_BADARGS
		call	Rpc_Error
		ret
Kernel_WriteRegs endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_AttachMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach to a memory block

CALLED BY:	RPC_BLOCK_ATTACH
PASS:		CALLDATA 	= handle ID
RETURN:		Nothing
DESTROYED:	AX, BX, CX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_AttachMem proc	near
		push	es
		mov	es, ds:[kdata]
		mov	bx, word ptr CALLDATA

		mov	al, es:[bx].HM_flags
		or	al, MASK HF_DEBUG
		mov	es:[bx].HM_flags, al
		;
		; Send null reply
		;
		clr	cx
		call	Rpc_Reply
		pop	es
		ret
Kernel_AttachMem endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_DetachMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach from a memory block

CALLED BY:	RPC_BLOCK_DETACH
PASS:		CALLDATA 	= handle ID
RETURN:		Nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_DetachMem proc	near
		push	es
		mov	es, ds:[kdata]
		mov	bx, word ptr CALLDATA

		mov	al, es:[bx].HM_flags
		and	al, NOT MASK HF_DEBUG
		mov	es:[bx].HM_flags, al
		;
		; Send null reply
		;
		clr	cx
		call	Rpc_Reply
		pop	es
		ret
Kernel_DetachMem endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelLoader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for calls from the loader

CALLED BY:	loader
PASS:		al	= DebugLoaderFunction
			  DEBUG_LOADER_MOVED:
			  	es	= new base segment of loader
			  DEBUG_KERNEL_LOADED
			  	cx:dx	= fptr.KernelLoaderVars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelLoader	proc	far

		push	ax
		DPC	DEBUG_FALK3, 'Y'
		pop	ax

		call	SaveState

		DPC	DEBUG_FALK3, 'X'

		mov	ax, ss:[bp].state_ax
		cmp	al, DEBUG_LOADER_MOVED
		jne	checkKernelLoaded

		mov	ax, DEBUG_MEM_LOADER_MOVED
		call	Bpt_BlockChange

		mov	ds:[{MoveArgs}rpc_ToHost].ma_handle, 0
						; special signal to
						;  say loader moved
		mov	ax, ss:[bp].state_es
		mov	ds:[{MoveArgs}rpc_ToHost].ma_dataAddress, ax
		mov	ds:[loaderBase], ax	; record for possible later
						;  return
		mov	ax, RPC_BLOCK_MOVE
		mov	cx, size MoveArgs
		jmp	transmit

checkKernelLoaded:
		cmp	al, DEBUG_KERNEL_LOADED
		LONG jne done			; que?

		push	es
		mov	es, ss:[bp].state_cx	; es:bx <- KernelLoaderVars
		mov	bx, ss:[bp].state_dx

		DPC	DEBUG_XIP, 'l'
		DPW	DEBUG_XIP, es
		DPW	DEBUG_XIP, bx
	;
	; Fetch the pertinent variables from the KernelLoaderVars now so we
	; (a) have them, and (b) don't have to be told where the kernel's
	; version of them lie...
	;
		mov	ax, es:[bx].KLV_handleTableStart
		mov	ds:[HandleTable], ax
		
		mov	ax, es:[bx].KLV_lastHandle
		mov	ds:[lastHandle], ax
		
		mov	ax, es:[bx].KLV_dgroupSegment
		mov	ds:[kdata], ax		

		mov	ax, es:[bx].KLV_kernelHandle
		DPW DEBUG_XIP, ax
		mov	ds:[kernelCore], ax	; record for possible later

	; AX must be preserved as the kernelCore as its used down below

	;
	; Save KLV_topLevelPath so we can use it later when we want to do
	; a RPC_FIND_GEODE or RPC_SEND_FILE.
	;
		push	si, di, cx
		push	ds, es
		pop	es, ds			; exchange segment registers
		lea	si, ds:[bx].KLV_topLevelPath
		mov	di, offset topLevelPath
		mov	cx, size topLevelPath
		rep	movsb			; copy path name
		push	ds, es
		pop	es, ds			; restore segment registers
		pop	si, di, cx
	;
	; Tell the kernel our code selector, so it can identify our comm.
	; IRQ handlers when trying to un-intercept them.
	;
		mov	es:[bx].KLV_swatKcode, cs
	;
	; Ask the kernel to tell us just where the f*** kcode ended up.
	; 
		mov	es:[bx].KLV_swatKcodePtr.segment, ds
		mov	es:[bx].KLV_swatKcodePtr.offset, offset kcodeSeg

	;
	; Build up a SpawnArgs for transmission to the host.
	;
		mov	ds:[{SpawnArgs}rpc_ToHost].sa_owner, ax
		clr	ax
		mov	ds:[{SpawnArgs}rpc_ToHost].sa_thread, ax	; kernel thread
	mov	ds:[{SpawnArgs}rpc_ToHost].sa_ss, ax	; loading library
		mov	ds:[{SpawnArgs}rpc_ToHost].sa_sp, ax	; ditto

		mov	ax, es:[bx].KLV_mapPageAddr
		mov	ds:[xipPageAddr], ax

	; snag this value now that es:bx are poiting to KLV in case we
	; need it, we don't want to assign this unless kernelVersion is
	; KV_FULL_XIP, but we won't know that until we call KernelSetup
		DPC	DEBUG_FALK3, 'A'
		mov	ax, es:[bx].KLV_xipHeader
		pop	es			; es <- cgroup
		call	KernelSetup

		DA	DEBUG_FALK3, <push ax>
		DPC	DEBUG_FALK3, 'B'
		DA	DEBUG_FALK3, <pop ax>

		cmp	ds:[kernelVersion], KV_FULL_XIP
		jb	findKcode
		DA	DEBUG_XIP, <push ax>
		DPC	DEBUG_XIP, 'H'
		DA	DEBUG_XIP, <pop ax>
		DPW	DEBUG_XIP, ax
		mov	ds:[xipHeader], ax
findKcode:
	;
	; now setup kcodeSeg, which we can get from the core block of
	; the kernel since the KernelLibraryEntry is in kcode
	;
		push	es
		mov	es, ds:[kdata]
		mov	bx, ds:[kernelCore]
				DPW DEBUG_SETUP, bx
		mov	es, es:[bx].HM_addr	; es = kernel core block
		mov	ax, es:[GH_libEntrySegment]
		pop	es
		mov	ds:[kcodeSeg], ax
				DPW DEBUG_FALK3, ax


		mov	cx, size SpawnArgs
		mov	ax, RPC_KERNEL_LOAD
transmit:
	;
	; Transmit the call to the host if it's connected (*not* attached)
	;
		test	ds:[sysFlags], mask connected
		jz	done
		mov	bx, offset rpc_ToHost
		call	Rpc_Call
		
		test	ds:[sysFlags], mask dontresume
		jz	done
		jmp	Rpc_Run
done:
	;
	; Return to our caller with its original state.
	;
		call	RestoreState
		iret
KernelLoader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_EnsureESWritable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For those machines where things are write-protected,
		sometimes, unprotect the memory pointed to by ES.

CALLED BY:	(EXTERNAL)
PASS:		es	= segment about to be written
RETURN:		ax	= original state, to pass to Kernel_RestoreWriteProtect
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_EnsureESWritable	proc	near
                uses bx, ds
		.enter
		PointDSAtStub
		mov     bx, es
                mov     ds:previousReadOnlyES, bx
                call    GPMIAlias
                mov     es, bx
                mov     ax, bx
		.leave
		ret
Kernel_EnsureESWritable endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_RestoreWriteProtect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the write-protect state as it was before a call
		to Kernel_EnsureESWritable

CALLED BY:	(EXTERNAL)
PASS:		ax	= as returned from Kernel_EnsureESWritable
RETURN:		nothing
DESTROYED:	ax, es = NULL
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		al	= port number
		ah	= previous value

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Kernel_RestoreWriteProtect proc	near
                uses ax, bx, ds
		.enter
                mov     bx, ax
		clr	ax
		mov	es, ax			; es = NULL
                call    GPMIFreeAlias
                PointDSAtStub
                mov     bx, ds:previousReadOnlyES
                mov     es, bx
		.leave
		ret
Kernel_RestoreWriteProtect endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_ReadXmsMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read xms memory given the handle of the XMS block, the
		the address of XMSReadBlockLow, and the number of
		bytes to read.

CALLED BY:	Rpc_ReadXmsMem
PASS:		ReadXmsMemArgs
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	10/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XMSMoveParams	struct
	XMSMP_size		dword	; number of bytes to move
	XMSMP_sourceHandle	word	;
	XMSMP_sourceOffset	dword	;
	XMSMP_destHandle	word	;
	XMSMP_destOffset	fptr	;
XMSMoveParams	ends
	
Kernel_ReadXmsMem	proc	near
xmsMoveParams	local	XMSMoveParams
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	;
	; transfer args from swat
	;
	movdw	xmsMoveParams.XMSMP_size, ({ReadXmsMemArgs}CALLDATA).RXMA_size, ax
	mov	ax, ({ReadXmsMemArgs}CALLDATA).RXMA_sourceHandle
	mov	xmsMoveParams.XMSMP_sourceHandle, ax
	movdw	xmsMoveParams.XMSMP_sourceOffset, ({ReadXmsMemArgs}CALLDATA).RXMA_sourceOffset, ax

	;
	; set the destination args so that the data is written to
	; REPLYDATA
	;
	mov	ax, ds
	mov	xmsMoveParams.XMSMP_destOffset.segment, ax
	lea	ax, REPLYDATA
	mov	xmsMoveParams.XMSMP_destOffset.offset, ax
	clr	xmsMoveParams.XMSMP_destHandle

	;
	; address of routine to call
	;
	mov	bx, ({ReadXmsMemArgs}CALLDATA).RXMA_procOffset
	DPW	DEBUG_PROFILE, bx
	mov	es, ds:[kdata]
	DPW	DEBUG_PROFILE, es
	
	mov	ax, es:[bx]
	DPW	DEBUG_PROFILE, ax
	mov	ax, es:[bx+2]
	DPW	DEBUG_PROFILE, ax

	push	ds
	segmov	ds, ss
	lea	si, ss:[xmsMoveParams]
	mov	ah, 0x0b
	DPW	DEBUG_PROFILE, ax
	call	{fptr}(es:[bx])
	pop	ds
	DPW	DEBUG_PROFILE, ax

	lea	si, REPLYDATA
	mov	ax, ds:[si]
	DPW	DEBUG_PROFILE, ax

	segmov	es, ds
	lea	si, REPLYDATA
	mov	cx, ss:[xmsMoveParams].XMSMP_size.low
	call	Rpc_Reply

	.leave
	ret
Kernel_ReadXmsMem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KernelSetSwatStubFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a word into ThreadPrivateData so that some EC code
		in SysLockCommon call tell that this is the swat stub and
		not really the kernel.

CALLED BY:	KernelSafeFileRead, KernelSafeLock, Kernel_SafeMapXIPPage
PASS:		ds = cgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	5/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KernelSetSwatStubFlag	proc	near
	.enter

	; In kernels before KV_AFTER_EXCEPTION_CHANGE, the kernel expects a
	; signature (0xadeb) to be in TPD_breakPoint.  This is used by EC
	; code in SysLockCommon so that the system can tell that the swat
	; stub and not the kernel is calling.
	
	; In kernels after KV_AFTER_EXCEPTION_CHANGE, the EC code in
	; SysLockCommon simply checks TPD_exceptionHandlers to see if it is
	; NULL.  Thus, the stub, in this case, does not have to do anything.
	

	cmp	ds:[kernelVersion], KV_AFTER_EXCEPTION_CHANGE
	jae	done
	
	; Old version: put signature in TPD_breakPoint
	
	mov	ss:[OTPD_breakPoint].segment, 0xadeb
done:
	.leave
	ret
KernelSetSwatStubFlag	endp

scode		ends

scode	segment

		assume	cs:scode, ds:cgroup, es:cgroup

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Kernel_Load
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the desired kernel at its proper place

CALLED BY:	Main, after performing a PUSHF
PASS:		DS=ES=cgroup
RETURN:		kernelHeader filled in.
DESTROYED:	Lots of things

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
scode		segment
;
; These things needs to stay around...
;
kcodeSeg	word	stubInit	; Where to load it  ; NOTE!!!:  Need to convert to selector at some point
kernelName	char	"loaderec.exe",0	; Storage for loader's name
		char	(64 - length kernelName) dup (?)

scode		ends

defArgs		byte	length defArgs-1, "/s"	; Default command tail if none
						;  given

Kernel_Load	proc	far
		;
		; Intercept int 21h right away.
		;
if INT21_INTERCEPT
; Protected mode doesn't need this watching capability
		mov	ax, 21h
		mov	bx, offset dosAddr
		mov	dx, offset KernelDOS
		call	SetInterrupt
endif

		;
		; Find the first blank-separated word that doesn't begin with a
		; slash -- this is the kernel to use
		; 
		mov	es, es:PSP	; PSP segment into ES for SCAS
		mov	di, 80h		; Fetch tail length into CX
		mov	cl, es:[di]
		inc	di		; Advance to tail start
		clr	ch
		cld			; Go forward
findLoaderLoop:
		mov	al, ' '
		repe	scasb		; Skip blanks
		je	useDefault	; All blanks -- no kernel. Ick.
		mov	ah, es:-1[di]	; Fetch first non-blank
		cmp	ah, '/'
		jne	foundLoader	; => found loader
		repne	scasb		; skip to next blank
		je	findLoaderLoop	; found a blank -- continue
useDefault:
		;
		; Use default kernel (already in kernelName).
		; Need to load in default arguments, though.
		;
		mov	di, 80h		; Need to store length, too
		mov	si, offset defArgs
		push	ds
		PointDSAtStub		; Point DS at init variables
		lodsb			; Fetch length
		stosb			; Store in tail as well
		mov	cl, al		; Shift to CX for rep movsb
		clr	ch
		rep movsb		; Copy rest of args
		pop	ds
		jmp	loadLoader	; Go load the kernel.
KLAbort:
if INT21_INTERCEPT
		push	ax
		mov	ax, 21h
		mov	bx, offset dosAddr
		call	ResetInterrupt
		pop	ax
endif
		stc
		ret			; return with carry set to our
					;  caller. ax = error code
foundLoader:
		;
		; Move index of kernel's name to BX (decrement required b/c
		; DI points one beyond its start)
		; 
		lea	bx, [di-1]
		;
		; Get to end of kernel's name (AL still contains ' ')
		; 
		repne	scasb
		je	figureNameLength
		inc	di	; Stopped on last char of kernel's name --
				; Point DI beyond it so copy/arithmetic
				; below works out correctly. CX will still
				; contain the correct number of bytes left (0)
figureNameLength:
		;
		; Calculate length of name in AX. Must decrement after
		; subtracting BX b/c DI once again points one beyond the first
		; blank.
		; 
		mov	ax, di
		sub	ax, bx
		dec	ax 
		;
		; Store count of remaining bytes of command tail in command
		; tail's length byte -- we'll make the remaining bytes into the
		; entire command tail later.
		; 
		push	cx		; Save for later tail shift
		
		;
		; Copy kernel's name into kernelName for opening/loading
		; 
		mov	si, bx		; Set SI to start of kernel name
					; for copy to kernelName
		mov	di, offset cgroup:kernelName
		mov	cx, ax
		push	ds		; Swap es and ds (storing in cgroup and
		push	es		; fetching from PSP...)
		pop	ds
		pop	es
		rep	movsb
		clr	al
		stosb			; String must be null-terminated
		;
		; Copy rest of tail down to its start.
		; 
		segmov	es, ds		; PSP -> ES too.
		pop	cx		; Restore count
		inc	cx		; off-by-one...
		mov	byte ptr es:[80h], cl
		mov	di, 81h		; Start of tail
		add	byte ptr es:[80h], 2	; another 2 chars in the tail
		mov	ax, '/' OR ('s' SHL 8)	; tell geos it's running
						;  under swat before copying
						;  down remaining tail, as
						;  that might contain a
						;  geode to load...
		stosw
		rep movsb		; Copy
		
loadLoader:
		PointDSAtStub
		;
		; Read the exe file header into kernelHeader.
		; 

		mov	dx, offset kernelName
		mov	ax, (MSDOS_OPEN_FILE shl 8) or 00h ; Open read-only
		int	21h
		jc	KLAbort		; Abort if couldn't open
		mov	bx, ax		; Need handle in BX

		mov	dx, offset kernelHeader
		mov	cx, size ExeHeader
		mov	ah, MSDOS_READ_FILE
		int	21h

		mov	ah, MSDOS_CLOSE_FILE
		int	21h
		
		ret
Kernel_Load	endp

scode	ends

		end
