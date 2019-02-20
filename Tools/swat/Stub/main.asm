COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Swat -- Debugging Stub
FILE:		main.asm

AUTHOR:		Adam de Boor, Nov 15, 1988

ROUTINES:
	Name			Description
	----			-----------
	SetInterrupt		Set an interrupt vector to one of our own
				routines
	ResetInterrupt		Restore an interrupt vector to what it used
				to be.
	Main			Entry point
	FetchArg		Look up argument in command tail
	CatchInterrupt		Vector interrupt to special handler
	IgnoreInterrupt		Reset interrupt to previous handler
	SaveState		Switch to Stub-State
	RestoreState		Return to state prior to last SaveState
	FindSwatTSRStub		Look for a TSRed stub.
	TransferControlToTSR	Resume execution of the TSR.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/15/88	Initial revision


DESCRIPTION:
	This is the main file for the Swat debugging stub.
	
	It contains all the code for loading and relocating the kernel, as
	well as starting up and various utility functions.
		

	$Id: main.asm,v 2.50 97/05/23 08:16:15 weber Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_Main		= 1
KERNEL		= 1
		include	stub.def

		include geos.def		; for Semaphore
		include ec.def			; for FatalErrors
		include heap.def		; for HeapFlags
		include geode.def
		include thread.def		; for ThreadPriority
		include	Internal/heapInt.def	; ThreadPrivateData
		include	Internal/dos.def	; for BIOS_DATA_SEG

if _Regs_32
.386
endif

;==============================================================================
;
; Define the state block/stack segment contents
;
;==============================================================================
sstack		segment
;
; Pretend we're the kernel.
;
tpd		ThreadPrivateData <
	0,		; TPD_blockHandle (none)
	0,		; TPD_processHandle (?!)
	sstack,		; TPD_dgroup
	HID_KTHREAD,	; TPD_threadHandle
	0,		; TPD_classPointer (none)
	0,		; TPD_callVector
	0,		; TPD_callTemporary
	StackTop,	; TPD_stackBot
	0,		; TPD_dataAX (don't care; placeholder)
	0,		; TPD_dataBX (don't care; placeholder)
	0,		; TPD_curPath (don't care; placeholder)
	0		; TPD_exceptionHandlers -- This must be zero in the
			; stub in order for SysLockCommon to function
			; properly.  --JimG 5/15/96
>
		public	tpd	; for kernel.asm
;
; Our private stack.
;
StackTop	label	word
		db	STUB_STACK_SIZE dup (?)
StackBot	label	word
sstack		ends


;==============================================================================
;
; Data definitions. Variables are kept in the code segment b/c it allows
; us to use cs: in difficult places. Besides, we don't have to be in ROM.
; 
;==============================================================================
scode		segment

ifdef ZOOMER
PIC1_Mask	byte	0fdh		; Mask for PIC1 (the master). Rpc_Init
					; masks in the com port's bit.
PIC2_Mask	byte	0feh		; Mask for PIC2 (the slave)
COM_Mask1	byte			; Mask for the communications port,
COM_Mask2	byte	
else
					; inverse (for masking purposes)
PIC1_Mask	byte	0feh		; Mask for PIC1 (the master). Rpc_Init
					; masks in the com port's bit.
PIC2_Mask	byte	0ffh		; Mask for PIC2 (the slave)
COM_Mask1	byte			; Mask for the communications port,
COM_Mask2	byte			; which may never be turned off.
					; This is actually the com port mask's
					; inverse (for masking purposes)
endif

PSP		sptr			; Segment of current PSP
swatPSP		sptr			; Segment of swat stubs original PSP
swatDrive	byte			; original drive swat ran from
swatPath	byte	64 dup (0)	; original path swat ran from

intsToIgnore	byte	16 dup (0)	; byte set to ignore int

if USE_SPECIAL_MASK_MODE
noSpecialMaskMode word 0		; non-zero to biff special mask mode
endif

if ENABLE_CHANNEL_CHECK
noChannelCheck	word	0		; non-zero to not give special attention
					;  to I/O channel check
endif

sysFlags    	SysFlags    <>		; System status flags -- all 0 for init

stubCode	word	scode		; Segment in which we're running, since

					; we can't compare against CS
if _Regs_32
STUB_USES_REG32 = 128
else
STUB_USES_REG32 = 0
endif

ifndef ZOOMER
stubType	byte	STUB_LOW or STUB_USES_REG32	; Type of stub we are -- set to
					; other stub type if INIT_HARDWARE
					; goes well.
else
stubType	byte	STUB_ZOOMER or STUB_USES_REG32
endif

stubCounter	word	0
ifndef NETWARE
waitValue	dword
endif

doTSR		byte	0
tsrSize		word	0

    	    	assume	cs:scode,ds:nothing,es:nothing,ss:sstack

if 0		;; useful code should something trash memory before
		;;  Swat can even attach
bleah		proc	far
		push	ds
		push	bx
		push	bp
		pushf
		mov	bp, sp
		
		mov	bx, 653h
		mov	ds, bx
		cmp	{byte}ds:[111h], 0xe8
		lds	bx, ss:[bp+8]
		je	ok
		push	ax
		mov	al, ds:[bx]
		mov	ah, 0eh
		int	10h
		pop	ax
ok:
		inc	bx
		mov	ss:[bp+8], bx
		popf
		pop	bp
		pop	bx
		pop	ds
		ret
bleah		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry routine

CALLED BY:	MS-DOS
PASS:		es 	= PSP
RETURN:		Nothing
DESTROYED:	Everything

PSEUDO CODE/STRATEGY:
	First of all, check if there already is a swat stub TSRed. If so,
	transfer control to it.

	Initialize the RPC module
	Note /s switch.
	Find kernel file in command tail
	Copy kernel args down to the bottom of the tail and change the
		tail length appropriately
	Load kernel, performing relocation.
	If /s, enter special loop waiting for connection.
	Hand control over to the kernel.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/15/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
noStartee	word	0
tsrMode		word	0
Main		proc	far


if 0 	;; funky code for setting DR0 to trap a write to a byte that was
	;; getting trashed (for which "bleah" was checking)
		.inst	byte 66h
		mov	ax, 6641h | .inst word 0	; mov eax, 6641h
		.inst byte 0fh, 23h, 0xc0	; movs dr0, eax
		.inst	byte 66h
		mov	ax, 0x0303 | .inst word 0x0001
		.inst byte 0fh, 23h, 0xf8	; movs dr7, eax
endif
	;;	BLEAH	a

		mov	cs:PSP, es	; Preserve PSP segment
		mov	cs:swatPSP, es

		INIT_HARDWARE

if DEBUG and DEBUG_OUTPUT eq DOT_MONO_SCREEN

		test	ds:[sysFlags], mask stubTSR
		jnz	skipScreenReset

	; clear the screen and set the initial blinking cursor
   		les	di, cs:[curPos]
		mov	cx, SCREEN_SIZE/2
		mov	ax, (SCREEN_ATTR_NORMAL shl 8) or ' '
		rep	stosw
		mov	di, cs:[curPos].offset
		mov	ax, (SCREEN_ATTR_NORMAL or 0x80) or 0x7f
		stosw
skipScreenReset:

endif

		;
		; Load es and ds properly
		; 
		mov	ax, cs
		mov	ds, ax
		mov	es, ax

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'M'
	DA	DEBUG_TSR, 	<pop ax>

	;		
	; Look for a swat stub that TSRed.  If found,
	; transfer control to it.
	;

		call	FindSwatTSRStub
	;;	BLEAH	b
		jnc	noTSR
	
		jmp	TransferControlToTSR	;does not return.
		.unreached

noTSR:
		segmov	ds, cs

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'N'
	DA	DEBUG_TSR, 	<pop ax>

	; save away the current drive and path for downloading files
		mov	ah, MSDOS_GET_DEFAULT_DRIVE
		int	21h

		mov	cs:swatDrive, al
		mov	al, '\\'
		mov	cs:swatPath, al
		mov	ah, MSDOS_GET_CURRENT_DIR
		mov	si, (offset swatPath) + 1
		clr	dl	; default drive
		int	21h

	;;	BLEAH	c
		assume	ds:cgroup, es:cgroup

		call	far ptr MainHandleInit
	;;	BLEAH	d
		LONG jc	deathDeathDeath

		mov	ds:noStartee, bx	;Save /s flag
		mov	ds:tsrMode, cx		;Save /t flag

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 't'
	DPW	DEBUG_TSR, cx
	DPC	DEBUG_TSR, 's'
	DPW	DEBUG_TSR, bx
	DA	DEBUG_TSR, 	<pop ax>
    	    	;
		; Load in the kernel. This fills in the kernelHeader structure
		; stubInit is OVERWRITTEN by this call -- can no longer
		; call things there.
		;
		; Kernel_Load sets up exe_cs and exe_ss in kernelHeader for us.
		; 

    	    	call	Kernel_Load
	;;	BLEAH	e
		LONG jc	deathDeathDeath
	;
	; Change in plans. To deal with DosExec we now load the loader as a
	; separate entity with its own PSP and everything.
	; 
		call	MainFinishLoaderLoad
	;;	BLEAH	f
		LONG jc	deathDeathDeath

		;
		; Point DS back at cgroup (points at kernel when Kernel_Load
		; returns)
		;
		segmov	ds,cs,ax
    	    	;
		; Set up SS:SP for the kernel now.
		; 
		mov 	ss, ds:[kernelHeader].exe_ss
		mov 	sp, ds:[kernelHeader].exe_sp

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 's'
	DPW	DEBUG_TSR, ss
	DPW	DEBUG_TSR, sp
	DA	DEBUG_TSR, 	<pop ax>

	;
	; Stick in our hook at the base of the loader code segment
	;
		push	es
		mov	es, ds:[kernelHeader].exe_cs
		mov	{word}es:[0], 0x9a9c	; PUSHF / CALL FAR PTR
		mov	{word}es:[2], offset KernelLoader
		mov	{word}es:[4], cs
		pop	es
		;
		; Set up interrupt frame for start of kernel in case we want
		; to keep the kernel stopped...
		;
		sti
		pushf
		push	ds:[kernelHeader].exe_cs
		push	ds:[kernelHeader].exe_ip

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'c'
	DPW	DEBUG_TSR, ds:[kernelHeader].exe_cs
	DPW	DEBUG_TSR, ds:[kernelHeader].exe_ip
	DA	DEBUG_TSR, 	<pop ax>

	;
	; kdata now lives at the base of the kernel; kcodeSeg is adjusted
	; when we're told what resource kcode is  -- ardeb 1/22/91
	;
		mov	ax, ds:[kcodeSeg]

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'k'
	DPW	DEBUG_TSR, ax
	DA	DEBUG_TSR, 	<pop ax>

		mov	ds:[kdata], ax
		mov	ds:[loaderBase], ax	; also the initial base of
						;  the loader.
	;;	BLEAH	g
	;
	; Flag initialization complete.
	; 
		ornf	ds:[sysFlags], mask initialized
    	    	;
		; Set up es and ds as if the kernel had been invoked from the
		; shell.
		; 
    	    	mov 	es, ds:[PSP]
		mov 	ds, ds:[PSP]

		;
		; See if /s given
		;
		tst	cs:noStartee	; Were it there, mahn?
		jnz	MainDontStart	; yow. keep that puppy stopped

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'Y'
	DA	DEBUG_TSR, 	<pop ax>

		;
		; No -- just do an iret to clear the stack and get going
		;
		RESTORE_STATE	; Deal with write-protect, etc...

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'Z'
	DA	DEBUG_TSR, 	<pop ax>

		ornf	cs:[sysFlags], mask running

		iret
MainDontStart:
		;
		; Just do a normal state save and go wait for something to do
		;
	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'T'
	DA	DEBUG_TSR, 	<pop ax>
		call	SaveState
		jmp	Rpc_Run

noLoadMahn	char	'Couldn''t load kernel: '
ecode		char	'00', '\r\n$'
ifdef ZOOMER
swatRunError	char	'\r\n','The loader.exe file is missing.', '\r\n'
		char	'Please download this platform''s loader.exe'
		char	'file and try again.','\r\n$'
else
swatRunError	char	'\r\n', "Couldn't run requested version of GEOS"
		char	 '\r\n', 'Please make sure you are in the '
		char	'correct EC or NC directory and try again','\r\n$'
endif
deathDeathDeath:
		push	ax
		aam
		xchg	al, ah
		or	{word}ds:ecode, ax
		segmov	ds,cs
		pop	ax
		mov	dx, offset swatRunError
		cmp	ax, 2
		je	printError		
		mov	dx, offset noLoadMahn
printError:
		mov	ah, 9
		int	21h
		mov	ax, RPC_HALT_BPT
		call	IgnoreInterrupt

ifndef NETWARE
ifndef WINCOM
		push	cx
		mov	cx, 20
		call	Sleep
		pop	cx
endif
endif

ifdef NETWARE
		segmov	ds,cs
		mov	ax, 1
		call	NetWare_Exit
endif
ifdef WINCOM
		segmov	ds,cs
		mov	ax, 1
		call	WinCom_Exit
endif
		EXIT_HARDWARE

		mov	ax, 4c01h
		int	21h
		.unreached
;		mov	ds:noStartee, -1
;		jmp	foo
Main		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransferControlToTSR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer control to the swat stub that is TSRed.

CALLED BY:	Main
PASS:		ds 	= PSP of TSR
RETURN:		does not return
DESTROYED:
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/ 4/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransferControlToTSR	proc	near

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'T'
	DPC	DEBUG_TSR, 'S'
	DPC	DEBUG_TSR, 'R'
	DA	DEBUG_TSR, 	<pop ax>

	;	
	; transfer control to TSRed instance of stub. ds = PSP of TSR.
	; This is accomplished by setting our PSP_parentId to the PSP of
	; the stub TSR, and setting PSP_saveQuit to the address to resume
	; execution.  When we exit, DOS will think that the stub had 
	; originally Exec'ed us, and will return execution at the
	; PSP_saveQuit address.
	;
		mov	dx, ds				
		mov	cx, dx				;cx = PSP of TSR
		add	dx, 0x10			;dx = code seg. of TSR
		mov	ax, cs:[PSP]
		mov	ds, ax
		clr	si				;ds:si = my PSP.
		mov	ds:[si].PSP_parentId, cx
		mov	ds:[si].PSP_saveQuit.segment, dx
		mov	ds:[si].PSP_saveQuit.offset, offset StubResume
	
	;
	; In addition, copy PSP_cmdTail to the TSR PSP, since it may have
	; been destroyed (what really happens?)
	;
		mov	si, PSP_cmdTail		;ds:si = my PSP_cmdTail
		mov	es, cx
		mov	di, si			;es:di = PSP_cmdTail of TSR
		mov	cx, CMD_TAIL_SIZE
		rep	movsb

	;
	; perform a standard exit
	;
		mov	ax, MSDOS_QUIT_APPL shl 8
		int	21h
		.unreached
TransferControlToTSR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindSwatTSRStub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for the possible existence of a swat TSR stub.

CALLED BY:	Main
PASS:		nothing
RETURN:		if swat stub TSR stub is found:
			carry set
			ds = PSP of stub.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Walk the MCB chain, using undocumented DOS stuff.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindSwatTSRStub	proc	near
	uses	ax,bx,cx,dx,si,di,es
	.enter
	;
	; Get the first MCB in the chain by looking at offset -2 of the 
	; es:bx address returned by MSDOS_GET_DOS_TABLES.
	; 
		mov	ah, MSDOS_GET_DOS_TABLES
		int	21h
		mov	ax, es:[bx-2]
		mov	es, ax
		clr	di

	;
	; Follow the MCB chain starting with es:0, looking for the 
	; signature of the swat stub, except that we're not interested
	; in ourselves.
	;

findLoop:
		cmp	es:[di].MCB_endMarker, 'M'
		jne 	notFound		;end of MCB chain

		mov	ax, es:[di].MCB_PSP
		tst	ax				
		jz	findNext		;skip free blocks
	
		;
		; Make sure we skip our own MCB, because even though we
		; have the correct signature, we're only interested in 
		; the TSRed instance of the stub.  
		;

		cmp	ax, cs:[PSP]
		je	findNext

		;
		; Look for the right signature. 
		;

		push	es			;save MCB

		; 
		; account for the difference between the PSP and cs in 
		; an EXE program.  The PSP is 16 paragraphs below the
		; start of the load image of a .exe file.
		;
		mov	dx, ax			;save the PSP
		add	ax, 0x10		;skip the PSP
		mov	ds, ax			;ds = cs of TSR (?)
		mov	si, offset swatStubSignature
		
		segmov	es, cs
		mov	di, offset swatStubSignature
		mov	cx, length swatStubSignature

		repe	cmpsb
		pop	es			;restore MCB
		stc
		mov	ds, dx			;restore that PSP.
		jz	done

findNext:
		;
		; jump to the next MCB
		;
		clr	di
		mov	ax, es
		add	ax, es:[di].MCB_size
		inc	ax			;is this necessary?
		mov	es, ax
		jmp	findLoop
notFound:
		clc
done:	
	.leave
	ret
FindSwatTSRStub	endp

swatStubSignature	char	"GEOS Swat Stub", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StubResume
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called by DOS when a stub loaded as TSR should
		take over control.

CALLED BY:	DOS
PASS:		nothing -- all registers but cs:ip are suspect.
RETURN:		never.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StubResume	proc	near
		assume	ds:nothing

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'S'
	DPC	DEBUG_TSR, 't'
	DPC	DEBUG_TSR, 'u'
	DPC	DEBUG_TSR, 'b'
	DA	DEBUG_TSR, 	<pop ax>

	; Re-initialize stuff in dgroup.  Since we can be re-executing
	; after a TSR, we cannot count on idata and udata being 
	; automatically reinitialized.

	;not necessary
	DA	DEBUG_TSR, 	<push ax>
	DPW	DEBUG_TSR, cs:[kernelCore]
	DA	DEBUG_TSR, 	<pop ax>
		clr	cs:[kernelCore]
		mov	cs:[sysFlags], mask stubTSR

		mov	dx, segment stubInit
		mov	ds, dx
		clr	ds:[loaderPos]
	;
	; Main expects es = PSP.  We know that cs is the first segment,
	; so the PSP = cs - 10h
	;

		mov	ax, cs
		sub	ax, 10h
		mov	ds, ax
		mov	es, ax
		jmp	Main

		.unreached

StubResume	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Sleep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pause for a few moments to smell the roses

CALLED BY:	GLOBAL

PASS:		cx = number of seconds to smell

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; the BIOS location 40h:6ch contains a dword that gets incremented
	; 18.2 times per second, I will use this to tick of ten seconds
	; and if I have not yet got a sync I will timeout and abort
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	use the calibrated value we got at startup since we want
	interrupts off now (I am not sure why, but it goes off into
	space if interrupts are on)

KNOWN BUGS/SIDEFFECTS/IDEAS:
		use 16 instead of 18.2, close enough for me...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/18/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	; random code for taking up CPU cycles
WasteTime	macro
	; add code here if machines ever get too fast
endm

ifndef NETWARE
Sleep	proc	far
		uses	cx, bx, ds, ax, dx
		.enter
		cli
		shl	cx	; use 16 instead of 18.2
		shl	cx
		shl	cx
		shl	cx
outerLoop:
		push	cx
		mov	cx, cs:[waitValue].low
		mov	dx, cs:[waitValue].high
	; ok, lets deal with the low word...
waitLowLoop:
		WasteTime
		loop	waitLowLoop
	; now deal with the high loop
waitHighLoop:
		tst	dx
		jz	afterInnerLoop
		clr	cx
waitHighInnerLoop:
		WasteTime
		loop	waitHighInnerLoop
		dec	dx
		jmp	waitHighLoop
afterInnerLoop:
		pop	cx
		loop	outerLoop
		sti
		.leave
		ret
Sleep	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainFinishLoaderLoad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the actual loading of the loader, now that Kernel_Load
		has set everything up for us.

CALLED BY:	Main
PASS:		ds 	= cgroup
RETURN:		carry set if couldn't load:
			ax	= error code
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadProgramArgs	struct
    LPA_environment	sptr		; environment for program
    LPA_commandTail	fptr		; command tail to use
    LPA_fcb1		fptr		; FCB #1
    LPA_fcb2		fptr		; FCB #2
    LPA_ss_sp		fptr		; OUT: ss:sp for new process
    LPA_cs_ip		fptr		; OUT: cs:ip for new process
LoadProgramArgs	ends

MainFinishLoaderLoad proc	near
lpa		local	LoadProgramArgs
		.enter
	;
	; Shrink ourselves down appropriately.
	; 
		tst	ds:tsrMode
		jz	noTSR
		mov	bx, segment stubInit

		;
		; don't get rid of stubInit.  Keep it all instead...
		;
		mov	cx, offset endOfStubInit
		shr	cx
		shr	cx
		shr	cx
		shr	cx		; in paragraphs.
		inc	cx		;is anything getting chopped off?
		add	bx, cx
		;
		; place a new value in kcodeSeg, since we're not overwriting
		; ourselves now.
		;
		mov	ds:[kcodeSeg], bx
		jmp	resize
noTSR:
		mov	bx, ds:[kcodeSeg]

resize:
	;;	BLEAH	A

		mov	ax, ds:[PSP]
		sub	bx, ax		; bx <- paragraphs needed
		mov	ds:[tsrSize], bx

		mov	es, ax		; es <- block to resize
		mov	ah, MSDOS_RESIZE_MEM_BLK
	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'r'
	DPW	DEBUG_TSR, bx
	DA	DEBUG_TSR, 	<pop ax>
		int	21h
	;;	BLEAH	B

	;
	; Set up the parameter block and load the beast.
	; 
		mov	ss:[lpa].LPA_environment, 0
		mov	ax, ds:[PSP]
		mov	ss:[lpa].LPA_commandTail.segment, ax
		mov	ss:[lpa].LPA_commandTail.offset, PSP_cmdTail
		mov	ss:[lpa].LPA_fcb1.segment, ax
		mov	ss:[lpa].LPA_fcb1.offset, offset PSP_fcb1
		mov	ss:[lpa].LPA_fcb2.segment, ax
		mov	ss:[lpa].LPA_fcb2.offset, offset PSP_fcb2
if DEBUG and DEBUG_INIT
		mov	si, offset kernelName
		call	DebugPrintString
		push	ds
		lds	si, ss:[lpa].LPA_commandTail
		inc	si
		call	DebugPrintString
		pop	ds
endif
	;
	; XXX: Under MS-DOS 5 & 6, this call somehow mystically trashes
	; the low word of the video BIOS interrupt. I have no idea how it
	; manages this, and an extended trace with netswat revealed only that
	; the thing blows up when stepping through IPXODI (re-entrancy, you
	; know). Rather than figure out what the f*** microsoft is doing
	; wrong, I'm just going to preserve the offset across the call.
	; 			-- ardeb 3/23/94
	; 
		clr	ax
		mov	es, ax
		push	es:[10h*fptr].offset

		segmov	es, ss
		lea	bx, ss:[lpa]
		mov	dx, offset kernelName
		mov	ax, (MSDOS_EXEC shl 8) or MSESF_LOAD
		push	bp, ds
		int	21h		; XXX: on 2.X, this biffs everything
					;  but CS:IP
	;;	BLEAH	C
		pop	bp, ds

		mov	bx, 0		; don't mess with carry or error code
		mov	es, bx
		pop	es:[10h*fptr].offset

		jc	done
	;
	; Fetch the new process's PSP.
	; 
		mov	ah, MSDOS_GET_PSP
		int	21h
	;;	BLEAH	D
		
	DPW DEBUG_INIT, bx

		mov	ds:[PSP], bx

	;
	; Set the termination address properly so it doesn't come back to just
	; after the int 21h, above
	; 
		mov	es, bx
		mov	es:[PSP_saveQuit].segment, cs
		mov	es:[PSP_saveQuit].offset, offset MainGeosExited
	;
	; Record PSP+16 as the actual kcodeSeg etc.
	; 
		add	bx, size ProgramSegmentPrefix shr 4
		mov	ds:[kdata], bx
		mov	ds:[kcodeSeg], bx
	;
	; Fetch the cs:ip and ss:sp for the kernel and store them away in the
	; kernelHeader for our caller to use.
	; 
		mov	ax, ss:[lpa].LPA_cs_ip.segment
		mov	ds:[kernelHeader].exe_cs, ax
		mov	ax, ss:[lpa].LPA_cs_ip.offset
		mov	ds:[kernelHeader].exe_ip, ax
		mov	ax, ss:[lpa].LPA_ss_sp.segment
		mov	ds:[kernelHeader].exe_ss, ax
		mov	ax, ss:[lpa].LPA_ss_sp.offset
		mov	ds:[kernelHeader].exe_sp, ax

		clc
done:
	;;	BLEAH	E
		.leave
		ret
MainFinishLoaderLoad endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainGeosExited
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Place to which DOS returns when geos finally exits.

CALLED BY:	DOS
PASS:		nothing -- all registers but cs:ip are suspect
RETURN:		never
DESTROYED:	us

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DEBUG and DEBUG_OUTPUT eq DOT_BUFFER
debugPtrPtr	nptr	debugPtr		; so Swat can find the
						;  thing easily...
endif
uffDa		word	MainGeosExited
MainGeosExited	proc	far
	;
	; clear the attached flag *now* so SaveState doesn't try to dick
	; with non-existent currentThread variable.
	;
	; 10/19/95: release processor exceptions first, since once we clear
	; the attached flag, RpcExit won't -- ardeb
	; 
		mov	ss, cs:[our_SS]
		mov	sp, offset StackBot
		test	cs:[sysFlags], mask attached
		jz	save_State
		
		push	ds
		segmov	ds, cs
		call	Kernel_ReleaseExceptions
		andnf	ds:[sysFlags], not mask attached
		pop	ds

save_State:
		pushf				; create suitable frame
		push	cs			;  for SaveState
		push	cs:[uffDa]

		call	SaveState		; I think this should be
						;  ok, as we'll probably
						;  be on our own stack
						;  anyway...

		segmov	ds, cs

	DA	DEBUG_TSR, 	<push ax>
	DPS	DEBUG_TSR, <MGE>
	DA	DEBUG_TSR, 	<pop ax>

		;
		; Get the return code from Geos to check if it TSRed.  If
		; Geos TSRed, then remember that fact because then the stub
		; must also TSR. 
		;
		mov	ah, 4dh
		int	21h

	DA	DEBUG_TSR, 	<push ax>
	DPB	DEBUG_TSR, ah
	DPW	DEBUG_TSR, ds:[sysFlags]
	DA	DEBUG_TSR, 	<pop ax>

		cmp	ah, DSEC_TSR
		jne	notTSR

		or	ds:[sysFlags], mask geosTSR

	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 't'
	DPW	DEBUG_TSR, ds:[sysFlags]
	DA	DEBUG_TSR, 	<pop ax>
notTSR:
	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'n'
	DA	DEBUG_TSR, 	<pop ax>
		;
		; Notify UNIX of exit. UNIX will in turn instruct us to
		; exit, so life will be groovy (but we'll be dead).
		; Note we need to record that GEOS is gone so RpcExit
		; doesn't go to EndGeos again.
		;
		or	ds:[sysFlags], MASK geosgone

		test	ds:[sysFlags], mask connected
		jz	handleUnattachedExit

		tst	ds:[doTSR]
		jnz	dontReallyExit

		mov	ax, RPC_EXIT
		clr	cx
		call	Rpc_Call
		jmp	Rpc_Run
handleUnattachedExit:
	;
	; The kernel is exiting. Pretend we received an RPC_EXIT call.
	; It will reset the necessary vectors etc. and then call
	; DOS to exit.
	; 
	DA	DEBUG_TSR, 	<push ax>
	DPC	DEBUG_TSR, 'Z'
	DPW	DEBUG_TSR, ds
	DPW	DEBUG_TSR, ds:[sysFlags]
	DA	DEBUG_TSR, 	<pop ax>
		jmp	RpcExit

dontReallyExit:
		mov	ax, 3100h		; TSR
		mov	dx, ds:[tsrSize]
		int	21h
		.UNREACHED
MainGeosExited	endp

if	DEBUG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DebugPrintString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a null-terminated string

CALLED BY:	Debugging things
PASS:		ds:si	= null-terminated string to print
		ah	= attribute
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DebugPrintStringFar proc far
		call	DebugPrintString
		ret
DebugPrintStringFar endp

DebugPrintString proc	near
		uses	al, si
		.enter
printLoop:
		lodsb
		tst	al
		jz	done
		call	DebugPrintChar
		jmp	printLoop
done:
		.leave
		ret
DebugPrintString endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DebugPrintByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a byte in HEX on the screen

CALLED BY:	Debugging things

PASS:		AL	= byte to print

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/27/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
nibbles		db	"0123456789ABCDEF"
DebugPrintByteFar proc far
		call	DebugPrintByte
		ret
DebugPrintByteFar endp

DebugPrintByte	proc	near
		push	bx
		push	ax
		mov	bx, offset nibbles
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1
		and	al, 0fh
		xlatb	cs:
		mov	ah, SCREEN_ATTR_NORMAL
		call	DebugPrintChar
		pop	ax
		push	ax
		and	al, 0fh
		xlatb	cs:
		mov	ah, SCREEN_ATTR_NORMAL
		call	DebugPrintChar

		mov	ax, (SCREEN_ATTR_NORMAL shl 8) or ' '
		call	DebugPrintChar

		pop	ax
		pop	bx
		ret
DebugPrintByte	endp

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DebugPrintWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a word in HEX on the screen

CALLED BY:	Debugging things

PASS:		AX	= byte to print

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/27/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
DebugPrintWordFar proc far
		call	DebugPrintWord
		ret
DebugPrintWordFar endp

DebugPrintWord	proc	near
		uses	ax, bx, cx
		.enter
		mov	bx, offset nibbles
		mov	cl, 4
		xchg	al, ah
		ror	al, cl
		call	printNibble
		ror	al, cl
		call	printNibble
		xchg	al, ah
		ror	al, cl
		call	printNibble
		ror	al, cl
		call	printNibble

		mov	ax, (SCREEN_ATTR_NORMAL shl 8) or ' '
		call	DebugPrintChar

		.leave
		ret

printNibble:
		push	ax
		and	al, 0fh
		xlatb	cs:
		mov	ah, SCREEN_ATTR_NORMAL
		call	DebugPrintChar
		pop	ax
		retn
DebugPrintWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DebugPrintChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the passed character to the screen, obeying the
		attribute request, if possible.

CALLED BY:	Debugging things
PASS:		ah	= attribute
		al	= character
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DebugPrintCharFar proc far
		call	DebugPrintChar
		ret
DebugPrintCharFar endp

if DEBUG_OUTPUT eq DOT_BIOS
ifdef  ZOOMER
charNum	word 0
endif
DebugPrintChar	proc	near
		uses	ax
		.enter
ifdef ZOOMER
		cmp	charNum, 1300
		jl	printChar
		push	bx, dx, ax
		mov	ah, 2
		mov	bh, 0
		mov	dx, 0
		int	10h
		pop	bx, dx, ax
		mov	cs:[charNum], 0
printChar:
		inc	cs:[charNum]
endif
ifdef	RESPONDER
		;Fucking buggy bios...
		push	bx, dx, si, bp
		clr	bx
endif
PENE <		pushf							>
PENE <		push	bx						>
PENE <		clr	bx						>
		mov	ah, 0xe
		int	10h
PENE <		pop	bx						>
PENE <		popf							>
ifdef	RESPONDER
		pop	bx, dx, si, bp
endif
		.leave
		ret
DebugPrintChar	endp
elif DEBUG_OUTPUT eq DOT_BUFFER

debugPtr	nptr.char debugBuf		; current position in buffer
debugBufSize	word	DEBUG_RING_BUF_SIZE	; size of buffer, for ddebug
						;  to use
debugMagic	word	0xadeb			; my initials, again
debugBuf	char	DEBUG_RING_BUF_SIZE dup(0)


DebugPrintChar	proc	near
		uses	di
		.enter
ifdef WINCOM
		push	bx, dx
		mov	bx, VDD_FUNC_SHOW_OUTPUT_CHAR
		mov	dx, ax		; char and attribute
		call	CallVDD
		pop	bx, dx
endif ; WINCOM		
		mov	di, cs:[debugPtr]
		push	ax
		cmp	ah, SCREEN_ATTR_INV
		jne	storeChar
		or	al, 0x80
storeChar:
		mov	cs:[di], al
		pop	ax
		inc	di
		cmp	di, offset debugBuf + size debugBuf
		jb	done
		mov	di, offset debugBuf
done:
		mov	cs:[debugPtr], di
		.leave
		ret
DebugPrintChar	endp

else
	.assert DEBUG_OUTPUT eq DOT_MONO_SCREEN
SCREEN_SEG	equ	0xb000
SCREEN_SIZE	equ	(80*2)*25	; total # bytes in screen


MonoScreen segment at SCREEN_SEG
screenBase	label	word
MonoScreen ends

curPos		fptr.word	screenBase; current location in mono screen

DebugPrintChar	proc	near
		uses	es, di
		.enter
		les	di, cs:[curPos]
		stosw
		cmp	di, SCREEN_SIZE
		jb	setCursor
		clr	di
setCursor:
		mov	{word}es:[di], ((SCREEN_ATTR_NORMAL or 0x80) shl 8) or \
					0x7f
		mov	cs:[curPos].offset, di
		.leave
		ret
DebugPrintChar	endp
endif
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CatchInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revector the indicated interrupt to one of our IRQ routines.

CALLED BY:	main, RpcCatch
PASS:		AL	= interrupt # to be intercepted
		Interrupts OFF
RETURN:		Nothing
DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Doesn't use SetInterrupt because most of the work there would be
	duplicated here just to figure the correct element of InterruptHandlers
	to use.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CatchInterruptFar proc far
		call	CatchInterrupt
		ret
CatchInterruptFar endp

CatchInterrupt	proc	near
		push	es		; Save needed registers
		push	bx
		push	dx
		push	si

    	    	clr 	ah  	    	; Clear out high byte
		clr	bx		; Set ES to 0 for addressing vector
					; table
		mov	es, bx
		shl	ax, 1		; AX *= 4 to give vector address
		shl	ax, 1
		mov	bx, ax
		shl	ax, 1		; * 8 to give offset into
					; InterruptHandlers of interception
					; record.
		add	ax, offset InterruptHandlers
		mov	dx, ax		; DX gets offset of actual handler code
		add	ax, 4		; Offset to storage for old vector
		mov	si, ax		; That goes into SI
		mov	ax, es:2[bx]	; Fetch current CS
		cmp	ax, ds:stubCode	; Make sure it's not already caught
		je	CI2		; It is...
		mov	2[si], ax	; Not caught -- save it
		mov	es:2[bx], cs	; Store ours
		mov	ax, es:[bx]	; Fetch IP of vector
		mov	[si], ax	; Save it
		mov	es:[bx], dx	; Store ours

CI2:
		pop	si		; Restore registers
		pop	dx
		pop	bx
		pop	es
		ret
CatchInterrupt	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IgnoreInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the indicated interrupt to its previous value

CALLED BY:	RpcExit
PASS:		AL	= interrupt # to be intercepted
		Interrupts OFF
RETURN:		Nothing
DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IgnoreInterrupt	proc	near
		push	es		; Save needed registers
		push	bx
		push	si

    	    	clr 	ah  	    	; Clear out high byte
		clr	bx		; Set ES to 0 for addressing vector
					; table
		mov	es, bx
		shl	ax, 1		; AX *= 4 to give vector address
		shl	ax, 1
		mov	bx, ax
		shl	ax, 1		; * 8 to give offset into
					; InterruptHandlers of interception
					; record.
		add	ax, offset InterruptHandlers + 4
		mov	si, ax		; That goes into SI
		mov	ax, es:2[bx]	; Make sure it's actually caught
		cmp	ax, ds:stubCode
		jne	II2		; It's not -- do nothing
		mov	ax, 2[si]	; Fetch old CS
		mov	es:2[bx], ax	; Stuff it
		mov	ax, [si]	; Fetch old IP
		mov	es:[bx], ax	; Stuff that
		mov	word ptr [si+2],0; Indicate vector is free
II2:
		pop	si		; Restore registers
		pop	bx
		pop	es
		ret
IgnoreInterrupt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IRQCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to send off notification of a stop to UNIX

CALLED BY:	InterrupHandlers
PASS:		[SP]	= halt code
RETURN:		No
DESTROYED:	Everything saved

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
haltCodeAddr	word	    	    ; Address of interrupt code

		assume	ds:nothing,es:nothing,ss:nothing
IRQCommon	proc	near
		WRITE_ENABLE
		pop	cs:haltCodeAddr	; Return address goes in haltCodeAddr
					; so we can get the reason for the
					; stoppage
		call	SaveState
		assume	ds:cgroup, es:cgroup, ss:sstack
;XXX put return address back on the new stack (WHY?)
		push	cs:[haltCodeAddr]
	;
	; Deal with timing-breakpoint calibration....
	; 
		test	ds:[sysFlags], mask calibrating
		jz	fetchHaltCode
		jmp	TB_CalibrateLoop
fetchHaltCode:
		;
		; Since this thing isn't re-entrant and getting interrupted
		; in a REP with an override causes evil things to happen, we
		; keep interrupts off until the call is actually made.
		;
		; Fetch the fault code and store it in the args
		; 
		mov	bx, ds:[haltCodeAddr]
		mov	al, [bx]
IRQCommon_StoreHaltCode	label near
		clr	ah
		mov	({HaltArgs}ds:[rpc_ToHost]).ha_reason, ax

		;
		; If stopped on a breakpoint, back the IP up to the bpt's
		; address so we don't need to write the registers each time...
		; 
		cmp	al, RPC_HALT_BPT
		jne	IC1
		dec	[bp].state_ip
IC1:

	; get the curXIPage if any
		mov	ax, -1
		tst	ds:[xipHeader]
		jz	gotXIPPage
		push	es, di
		mov	es, ds:[kdata]
		mov	di, ds:[curXIPPageOff]
		mov	ax, es:[di]
		pop	es, di
gotXIPPage:
		mov	({HaltArgs}ds:[rpc_ToHost]).ha_curXIPPage, ax

		;
		; Fetch the active thread and store it. If execing a DOS
		; prog, pretend it's the kernel thread that's running.
		; 
		mov	ax, [bp].state_thread
		test	ds:[sysFlags], mask dosexec
		jz	IC1_5
		clr	ax
IC1_5:
		mov	({HaltArgs}ds:[rpc_ToHost]).ha_thread, ax

		mov	di, offset ({HaltArgs}rpc_ToHost).ha_regs
		call	Rpc_LoadRegs
		
		;
		; Handle breakpoints. Bpt_Check will only
		; return if the breakpoint is to be taken.
		;
		cmp	({HaltArgs}ds:[rpc_ToHost]).ha_reason, RPC_HALT_BPT
		jne	IC2

		call	Bpt_Check
IC2:
		mov	ax, RPC_HALT		; Load RPC parameters here so
    	    	mov 	cx, size HaltArgs	;  CHECK_NMI can change them if
		mov	bx, offset rpc_ToHost	;  it wants

		cmp	({HaltArgs}ds:[rpc_ToHost]).ha_reason, RPC_HALT_NMI
		jne	IC2_5
		CHECK_NMI
IC2_5:
		;
		; If not connected, don't send the call...duhhh
		;
		test	ds:[sysFlags], mask connected
		jz	IC3
		call	Rpc_Call	; This will turn on interrupts once
					; the message is copied into the output
					; queue.
IC3:
		eni			; Handle skipped call...
;XXX discard return address from stack, since we won't need it
		pop	ax
		jmp	Rpc_Run		; Wait for a continue message to come
					; in. Rpc_Run will take care of
					; returning to the proper context.
IRQCommon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InterruptHandlers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	These are the handlers for all the various possible
		interrupts.

CALLED BY:	CPU
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	Nothing


PSEUDO CODE/STRATEGY:
	A handler consists of a near call to the IRQCommon code, followed by
	the interrupt number invoked, followed by the former contents of the
	vector for that interrupt. The idea is for IRQCommon to pop the
	return address from the stack and have instant access to the
	interrupt number and where to jump to if the interrupt is to be
	continued.
	
	We only allocate 16 vectors for the low 16 interrupts that we've
	got to be able to catch, then another 16 for Swat to do with
	as it sees fit. A vector with a saved-vector segment of 0 is
	considered free and can be allocated by Swat at any time.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

defineIRQH	macro	num
;;		public	IRQ&num
IRQ&num:
		call	IRQCommon	; Do the regular things
		.unreached
		byte	num		; Interrupt that caused the stop
		dword	0		; Previous vector
		endm

		word	NUM_VECTORS	; So Swat knows how many there are.
InterruptHandlers label	near
IRQ_NUM		= 0

.warn	-unref		; these are referenced indirectly via
			;  InterruptHandlers
		rept	NUM_VECTORS
		defineIRQH	%IRQ_NUM
IRQ_NUM		= IRQ_NUM+1
		endm
.warn	@unref

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchTimer0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the current value of timer 0, for one reason or
		another

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		ax	= timer 0 counter
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FetchTimer0	proc	near
		.enter
		pushf
		cli
ifdef ZOOMER
	;
	; Read the word value from the timer. The cruft here is a near-
	; duplicate of the kernel's ReadTimer routine. We do not, as it does,
	; have access to the currentTimerCount variable, so we just assume the
	; maximum value. Note also that the Zoomer timer counts up, while
	; the PC timer counts down. All the code expects it to count down,
	; so...
	; 
		in	ax, TIMER_IO_1_GET_COUNT
		tst	ax
		jz	useTickCount
		neg	ax
		add	ax, GEOS_TIMER_VALUE
		jns	haveCount
useTickCount:
		mov	ax, GEOS_TIMER_VALUE-1
haveCount:
		inc	ax			; count from 1, not 0
else
	;
	; Latch timer 0's current counter value. We make sure interrupts are
	; off so no one comes along and gives the chip another command before
	; we can finish the read...
	; 
		mov	al, TIMER_COMMAND_0_READ_COUNTER
		out	TIMER_IO_COMMAND, al
		jmp	$+2			; I/O delay
	;
	; Now read the two bytes of the value from the timer.
	; 
		in	al, TIMER_IO_0_LATCH	; al <- low byte
		mov	ah, al
		jmp	$+2			; I/O delay
		in	al, TIMER_IO_0_LATCH

		xchg	al, ah			; return in proper order
endif
		push	cs
		call	safePopf
		.leave
		ret
safePopf:
		iret
FetchTimer0	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the current state and switch to our own context

CALLED BY:	Interrupt handlers (IRQCommon, etc.)
PASS:		Interrupts off.
RETURN:		Interrupts still off.
		ds, es, ss, sp set up
		prev_SS, prev_SP set to SS:SP on entry to this function
		currentThreadOff set for kernel thread.
		bp points to the start of the state block.
		
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		Carefully switch to our stack (wherever we left off),
			preserving SS:SP in prev_SS:prev_SP
		Push all registers
		Push the currentThreadOff and set it to the kernel thread
		Push the interrupt controller masks
		Set our interrupt masks
		Set ds, es to our segment (in cs)
		Copy return address from previous stack to ours

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _Regs_32
prev_SP		dword	0		; SP after save
else
prev_SP		word	0		; SP after save
endif

prev_SS		word	0		; SS before save
our_SS		word	sstack		; Only way to load SS w/o using another
					; register (which we haven't got).
ssRetAddr	word	?		; Our return address.
ssTimerCount	word			; Count in timer 0 when state last
					;  saved
ssResumeTimerCountPtr nptr.word	0	; Place to store count that's in
					;  timer 0 when we restore state
					;  0 if not to store it.
		assume 	ds:nothing, es:nothing, ss:nothing
SaveState	proc	near
	;
	; Deal with write-protection, etc.
	;
		SAVE_STATE

	DA	DEBUG_ENTER_EXIT, <push ax>
	DPC	DEBUG_ENTER_EXIT, 'e'
	DA	DEBUG_ENTER_EXIT, <pop ax>
	;
	; Remove our return address from the stack
	; 
		pop	cs:ssRetAddr

		push	ax
		call	FetchTimer0
		mov	cs:[ssTimerCount], ax
		pop	ax

	;
	; Switch to our stack, saving the previous one in
	; prev_SS:prev_SP. If we were already on our stack, don't
	; change SS:SP at all.
	; 
		mov	cs:prev_SS, ss
if _Regs_32
		mov	cs:prev_SP, esp
else
		mov	{word}cs:prev_SP, sp
endif
		push	ax
		mov	ax, cs:our_SS
		cmp	cs:prev_SS, ax
		pop	ax
		je	SS1
		mov	ss, cs:our_SS
		mov	sp, offset StackBot
SS1:
		assume	ss:sstack
	;
	; Save all the registers mostly in the order dictated
	; by an IbmRegs structure so they can be copied in easily.
	; 
if _Regs_32
		push	edi
                push    esi
                push    ebp
                push    cs:prev_SP
                push    ebx
                push    edx
                push    ecx
                push    eax
else
		push	di
		push	si
        	push	bp
                push	{word}cs:prev_SP
		push	bx
		push	dx
		push	cx
		push	ax
endif

if _Regs_32
                .inst db 0Fh, 0A8h ; push gs
                .inst db 0Fh, 0A0h ; push fs
endif
		push	es
		push	cs:prev_SS
		push	ds

	;
	; Now the pertinent kernel variables:
	; 	currentThread
	; 
		mov	ax, HID_KTHREAD	; Assume we don't know and make it
					; the kernel...
		test	cs:sysFlags, MASK attached
		jz	SS2
		
		mov	ds, cs:kdata
		mov	bx, cs:currentThreadOff
	    ; fetch current thread and switch to kernel context at the
	    ; same time (prevents context switches, in theory)
		xchg	ax, [bx]

	;
	; KLUDGE: Make sure the saveSS field of the handle for the
	; current thread contains the actual SS for the thread.
	; THIS BREAKS THE NON-INTERFERENCE DIRECTIVE. Unfortunately,
	; if one uses -b and encounters a thread that cswitched in
	; DOS and hasn't cswitched again now it's out, Swat will
	; choke b/c the saveSS for the thread will be wrong. Rather
	; than making the kernel do extra work all the time, we simply
	; make sure the saveSS for the current thread reflects its
	; actual value.
	; 
		cmp	ax, HID_KTHREAD
		je	SS2		; Kernel thread has no real handle, so
					;  don't try and write to it.
		mov	bx, ax
		mov	ax, cs:prev_SS
		cmp	ax, cs:kdata	; There's one point where we're in
					;  a thread but still running on the
					;  kernel stack. If we step through
					;  there, we don't want to biff things,
					;  so don't store ss if it's the
		je	SS1_9		;  kernel stack.
		mov	ds:[bx].HT_saveSS, ax
SS1_9:
		mov	ax, bx
SS2:
		push	ax

	;
	; Fetch the interrupt controller masks both into ax.
	; 
		in	al, PIC2_REG
		mov	ah, al
		in	al, PIC1_REG
ifdef ZOOMER
		and	al, 0fch
else
		and	al, 0feh	
endif
					; Make sure timer interrupt is
					; enabled on return (might have been
					; disabled for single-stepping). If
					; function that continues wants it
					; disabled, it will have to set the
					; bit here itself.
		push	ax
		
	;
	; Fetch flags, cs and ip from the previous stack.
	; 
if _Regs_32
                mov     bx, cs:prev_SS
                mov     ds, bx
                mov     ebx, cs:prev_SP
else
   	    	lds 	bx, dword ptr cs:prev_SP
endif
		push 	4[bx]		; Fetch flags
		push 	2[bx]		; Fetch cs
		push 	[bx] 		; Fetch ip
		
	;
	; Save the timer interrupt vector and use our own
	;
		clr	ax
		mov	ds,ax		;ds = interrupt block
		push	ds:[TIMER_INT_VECTOR].segment
		push	ds:[TIMER_INT_VECTOR].offset
		mov	ds:[TIMER_INT_VECTOR].segment,cs
		mov	ds:[TIMER_INT_VECTOR].offset,offset StubTimerInt
if INTEL_BREAKPOINT_SUPPORT
	;
	; save the hardware breakpoint status, then clear it
	; so the next person to save state doesn't think they also are
	; handling a breakpoint
	;
		movsp	eax, dr6
use32 <		push	ax						>
		and	ax, not ( mask DR6L_B3 or mask DR6L_B2 \
			       or mask DR6L_B1 or mask DR6L_B0 )
		movsp	dr6, eax
	;
	; save the breakpoint state, then disable all breakpoints so
	; we don't trigger one from within the stub
	;
		movsp	eax, dr7
use32 <		push	ax						>
		and	ax, not (  mask DR7L_L0 or mask DR7L_G0 \
				or mask DR7L_L1 or mask DR7L_G1 \
				or mask DR7L_L2 or mask DR7L_G2 \
				or mask DR7L_L3 or mask DR7L_G3 )
		movsp	dr7, eax
endif
	;   
	; Point bp at the state block just created.
	; 
		mov	bp, sp

	;
	; Adjust for iret frame on stack
	; 
		add	{word}([bp].state_sp), 6
		
	;
	; Want our data, thank you.
	; 
		mov	ax, cs
		mov	ds, ax
		mov	es, ax
		
		assume	ds:cgroup, es:cgroup

		call	Bpt_Uninstall

	;
	; Make sure DF is clear so we don't get nailed by anyone
	; but ourselves... (also provides kernel with what it
	; expects in case we're about to go to EndGeos...)
	;
		cld
		
if USE_SPECIAL_MASK_MODE
	;
	; Switch the first (maybe only) interrupt controller into
	; "special mask mode" whereby interrupts from non-masked
	; levels are enabled when the mask register is set. This
	; allows us to field breakpoints in service routines for and
	; intercept interrupts that are of a higher priority than
	; our own serial port.
	;
		tst	noSpecialMaskMode
		jnz	skipSMM
		mov	al, 01101000b	; This be enable special mask mode.
					; Refer to p. 7-129 of Intel
					; Component Data Catalog
		out	PIC1_REG-1, al	; Need to write to 20h, not 21h...
skipSMM:
		mov	al, 00001011b	; Fetch the in-service register
		out	PIC1_REG-1, al	;  when reading PIC1_REG-1
		out	PIC2_REG-1, al	;  or PIC2_REG-1
	;
	; Now install our state. First the interrupt controller masks.
	; We merge in the current state of the masks to avoid enabling
	; any interrupt we just intercepted.
	;
		cmp	sp, StackTop+SIZE StateBlock+STACK_SLOP
		jbe	SSMaskAll
		in	al, PIC1_REG-1	; Fetch in-service register
		or	al, PIC1_Mask	; Merge in bits we want masked
		and	al, COM_Mask1	; Make sure we're still on...
		out	PIC1_REG, al	; Set interrupt mask

	; XXX: this should kill a Tandy 1000TX

		in	al, PIC2_REG-1	; Fetch in-service register
		or	al, PIC2_Mask	; Merge in bits we want masked
		and	al, COM_Mask2
		out	PIC2_REG, al	; Set interrupt mask
		
else
	
	; EVENTUALLY THIS SHOULD BE DEALT WITH FOR THE ZOOMER!!
ifndef WINCOM
ifndef ZOOMER
	;
	; Switch the first interrupt controller into a mode where our
	; serial line is the highest-priority interrupt in the chip.
	;
		mov	al, ds:[com_IntLevel]
		cmp	al, 8
		jb	adjust1stController

		sub	al, 9		; make level just above comm IRQ be
					;  the lowest priority
		andnf	al, 7
		ornf	al, 11000000b	; OCW2 with R=1, SL=1, EOI=0
					; (q.v. p. 7-129 of Intel Component
					;  Data Catalog)
		out	PIC2_REG-1, al
		mov	al, 2		; pretend com_IntLevel is 2 -- the
					;  cascade IRQ level for the 2nd
					;  controller into the 1st

adjust1stController:
		dec	al		; make level just above our serial
					; port be the lowest priority
		or	al, 11000000b	; OCW2 with R=1, SL=1, EOI=0
					; (c.f. p. 7-129 of Intel
					; Component Data Catalog)
		out	PIC1_REG-1, al
else	
	; ramp the thing up.. XXX how do we restore it?
		mov	dx, ds:[comIrq]
		clr	al
		out	dx, al
setPrior:
endif	; not ZOOMER
endif   ; not WINCOM
	;
	; Now install our state, setting the interrupt masks to what they
	; should be.
	;
		cmp	sp, offset StackTop+SIZE StateBlock+STACK_SLOP
		jbe	SSMaskAll
		
		mov	al, ds:[PIC1_Mask]
		out	PIC1_REG, al
		
		mov	al, ds:[PIC2_Mask]
		out	PIC2_REG, al
endif	; not special mask mode
		;
		; Return via the saved return address
		; 
		jmp	ds:[ssRetAddr]
SSMaskAll:
		;
		; Can't take another interrupt (no room on stack) so disable
		; all interrupts but our own.
		;
		mov	al, 0ffh
		mov	ah, ds:[COM_Mask2]
		not	ah
		and	al, ah
		out	PIC2_REG, al
ifndef ZOOMER
		mov	al, 0xfe
else
		mov	al, 0xfd
endif
		mov	ah, ds:[COM_Mask1]
		not	ah
		and	al, ah
		out	PIC1_REG, al
		jmp	ds:[ssRetAddr]		
SaveState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the previous state pointed to by bp

CALLED BY:	?
PASS:		bp	= address of state block to restore
RETURN:		all registers, kernel variables restored
DESTROYED:	all registers

PSEUDO CODE/STRATEGY:
		Pop return address into a vector for jumping through
		Disable interrupts
		Pop rest of stack back to state block
		Pop the components
		Return through saved return address

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
rsRetAddr	word			; Our return address, since it'd be a
					; pain to place it on the old stack
					; (since we can't use sp for indexing)
					; when we can just as easily jump
					; through it.
		assume	ds:cgroup,es:cgroup,ss:sstack
RestoreState	proc	near
		dsi			; No interrupts here
		pop	ds:[rsRetAddr]	; Fetch our return address

		call	Bpt_Install
		mov	sp, bp		; Get back to state block

if DEBUG and DEBUG_INIT
	;
	; Set the running flag the first time we get off the stub stack, so we
	; know to no longer install bpts when on the stub stack in Bpt_Install,
	; as stub initialization is complete.
	;
		cmp	ss:[bp].state_ss, sstack
		je	doRestore
		mov	ax, ss:[bp].state_cs
		cmp	ax, scode
		jb	doRestore
		cmp	ax, 0xf000
		ja	doRestore
		ornf	ds:[sysFlags], mask running
doRestore:
endif

if INTEL_BREAKPOINT_SUPPORT
		;
		; restore hardware breakpoint state but clear the status
		; register so we will have a clean slate for the next stop
		;
use32 <		pop	ax						>
		movsp	dr7, eax
use32 <		pop	ax						>
		clr32	ax
		movsp	dr6, eax
endif
		;
		; Restore the timer interrupt vector
		;
		clr	ax
		mov	ds,ax		;ds = interrupt block
		pop	ds:[TIMER_INT_VECTOR].offset
		pop	ds:[TIMER_INT_VECTOR].segment
		segmov	ds,cs,ax		
    	    	;
		; Set up CS:IP and flags
		; 
    	    	mov 	es, [bp].state_ss
		assume	es:nothing
		mov 	di, [bp].state_sp
		sub	di, 6		; Make room for iret frame
		cld
		mov	[bp].state_sp, di
    	    	pop 	ax		; IP
		stosw
		pop	ax		; CS
		stosw
		pop	ax		; FLAGS
		stosw
		
		;
		; Disable special mask mode if going back to real operation
		; (sp is within the final state block on the stack).
		;
		cmp	sp, offset StackBot-size StateBlock
		jb	RS2
ifndef ZOOMER
 if USE_SPECIAL_MASK_MODE
		tst	noSpecialMaskMode
		jnz	RS2
		mov	al, 01001000b	; This be disable special mask mode.
					; Refer to p. 7-129 of Intel
					; Component Data Catalog
		out	PIC1_REG-1, al	; Need to write to 20h, not 21h...
 else
		mov	al, 11000111b	; Make level 7 be the lowest priority
		out	PIC1_REG-1, al
		out	PIC2_REG-1, al
 endif
else
	; reset to level 4...?
		mov	dx, ds:[comIrq]
		mov	al, 4
		out	dx, al
resetPrior:
endif
RS2:
		;
	    	; Now the interrupt controller masks
		; 
		pop	ax		
		out	PIC1_REG, al
		mov	al, ah
		out	PIC2_REG, al

		;
		; currentThread. SaveState will have stored HID_KTHREAD in
		; this slot if it didn't know where to find currentThread when
		; the state was saved. If we actually were attached and
		; currentThread was HID_KTHREAD when we came in, we don't
		; need to store the variable back anyway, as we set
		; currentThread to zero on entry...
		; 
		pop	ax
		cmp	ax, HID_KTHREAD
		je	RS1
		mov	bx, ds:[currentThreadOff]
		mov	ds, ds:[kdata]
		mov	[bx], ax
RS1:
		assume	ds:nothing
		;
		; Registers
		; 
		pop	ds
		pop	cs:prev_SS
		pop	es
if _Regs_32
                .inst db 0fh, 0a1h ;pop fs
                .inst db 0fh, 0a9h ;pop gs
endif

if _Regs_32
		pop	eax
		pop	ecx
		pop	edx
		pop	ebx
		pop	cs:prev_SP
		pop	ebp
		pop	esi
		pop	edi
		mov	esp, cs:prev_SP
else
		pop	ax
		pop	cx
		pop	dx
		pop	bx
		pop	cs:prev_SP
		pop	bp
		pop	si
		pop	di
		mov	sp, cs:prev_SP
endif
		mov	ss, cs:prev_SS

		assume	ss:nothing

		tst	cs:[ssResumeTimerCountPtr]
		jz	done

		push	ax, bx
		clr	bx
		xchg	bx, cs:[ssResumeTimerCountPtr]
		call	FetchTimer0
		mov	cs:[bx], ax
		pop	ax, bx
done:
	DA	DEBUG_ENTER_EXIT, <push ax>
	DPC	DEBUG_ENTER_EXIT, 'E'
	DA	DEBUG_ENTER_EXIT, <pop ax>
		;
		; Write-protect, enable breakpoints and trace-buffer, etc.
		;
		RESTORE_STATE
		;
		; Return
		; 
		jmp	cs:rsRetAddr
RestoreState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResumeFromInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resume after an interrupt

CALLED BY:	INTERNAL
PASS:		ss:bp - state block
RETURN:		does not return
DESTROYED:	n/a
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (not in hardware breakpoint)
	   restore state
	   16-bit iret
        else
           set up to step over next instruction
	   restore state
	   rewrite stack as 32-bit interrupt frame
	   set RF in saved flags
	   32-bit iret
        endif

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	weber   	5/14/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResumeFromInterrupt	proc	near
if INTEL_BREAKPOINT_SUPPORT
	;
	; read the breakpoint state
	;
		DPC	DEBUG_HWBRK, 'R'
		DA	DEBUG_HWBRK, <mov ax, ss:[bp].state_dr6.low>
		DPB	DEBUG_HWBRK, al
	;
	; are we in a breakpoint?
	;
		test	ss:[bp].state_dr6.low, \
			 mask DR6L_B3 or mask DR6L_B2 \
			 or mask DR6L_B1 or mask DR6L_B0
		jnz	inBreak
	;
	; not in a breakpoint - just do a normal iret
	;
normal:
		call	RestoreState
		iret
inBreak:
		DPC	DEBUG_HWBRK, 'b'
	;
	; if no instruction breakpoint was taken, we do not need
	; to do anything fancy
	;
		call	IBpt_CheckType
		jz	normal
	;
	; set up to skip the breakpoint
	; if we emulate the instruction, then we are no longer at the
	; breakpoint so we can continue normally
	;
		call	IBpt_Skip
		jc	normal
	;
	; unwind the stack and restore all the thread registers
	;
		call	RestoreState
	;
	; make room to expand 16-bit stack to a 32-bit stack
	;
		sub	sp, (size Interrupt32Stack - size Interrupt16Stack)
		push	bp
		mov	bp, sp
		add	bp, 2		; ignore saved BP
	;
	; shuffle the data
	;
		clr	ss:[bp].I32S_eip.high
		segmov	ss:[bp].I32S_eip.low,	 ss:[bp].TS_I16.I16S_ip
		segmov	ss:[bp].I32S_cs,	 ss:[bp].TS_I16.I16S_cs
		segmov	ss:[bp].I32S_eflags.low, ss:[bp].TS_I16.I16S_flags
	;
	; the caller will get our extended flags, but with RF set
	;
		push	ax
use32 <		pushf							>
		pop	ax				; eflags.low
		pop	ax				; eflags.high
		or	ax, mask ECPU_RF
		mov	ss:[bp].I32S_eflags.high, ax
		pop	ax
	;
	; make note of the current stack
	;
if 0
		DA	DEBUG_HWBRK, <push ax>
		DA	DEBUG_HWBRK, <mov  bp, sp>
		DPC	DEBUG_HWBRK, 'P'
		DPW	DEBUG_HWBRK, sp
		DPS	DEBUG_HWBRK, <S: >
		DPW	DEBUG_HWBRK, <ss:[bp]>		; should be ax
		DPW	DEBUG_HWBRK, <ss:[bp]+2>	; should be bp
		DPW	DEBUG_HWBRK, <ss:[bp]+4>	; should be ip
		DPW	DEBUG_HWBRK, <ss:[bp]+6>	; should be 0
		DPW	DEBUG_HWBRK, <ss:[bp]+8>	; should be cs
		DPW	DEBUG_HWBRK, <ss:[bp]+10>	; undefined
		DPW	DEBUG_HWBRK, <ss:[bp]+12>	; should be flags.low
		DPW	DEBUG_HWBRK, <ss:[bp]+14>	; should be flags.high
		DPW	DEBUG_HWBRK, <ss:[bp]+16>	; application data
		DA	DEBUG_HWBRK, <pop ax>
endif
	;
	; return to caller
	;
		pop	bp
use32 <		iret							>
else	; not INTEL_BREAKPOINT_SUPPORT
                call    RestoreState
		iret
endif
ResumeFromInterrupt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StubTimerInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle timer interrupts by turning off the floppy's drive
		motor, if need be, and upping our internal counter.

CALLED BY:	Hardware
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	8/31/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StubTimerInt	proc	far
	push	ax
	push	ds

	;
	; Deliver the specific EOI for this level (timer at level 0). The
	; EOI has to be specific since the controller will be in
	; special-mask mode when we're called (since we're only called in
	; the stub's context).
	;
ifdef ZOOMER
	mov	al, 2				; TIMER1 interrupt level is 2
	out	ICEOIPORT, al
else
	mov	al,I8259_SPEOI
	out	I8259_COMMAND,al
	; take care of floppy drive's motor
	mov	ax,BIOS_DATA_SEG		;address BIOS variables
	mov	ds,ax
	dec	byte ptr ds:[BIOSMotorCount]
	jnz	afterMotor

	push	dx
	and	byte ptr ds:[BIOSMotorStatus],not BIOS_MOTOR_BITS
	mov	al,BIOS_CMD_MOTOR_OFF
	mov	dx,BIOS_MOTOR_PORT
	out	dx,al
	pop	dx
afterMotor:
endif	
	segmov	ds, cgroup, ax
	inc	ds:[stubCounter]

	pop	ds
	pop	ax
	iret

StubTimerInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmulateInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pretend to have executed the two-byte software interrupt
		at es:di
		
		NOTE: THIS FUNCTION CANNOT WORK IF state_ss IS sstack

CALLED BY:	Bpt_Skip, Rpc_Step
PASS:		es:di	= cs:ip of patient
		ax	= interrupt instruction
		ss:bp	= StateBlock
RETURN:		nothing
DESTROYED:	ax, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/26/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EmulateInterrupt proc	near
		.enter
DA DEBUG_BPT,	<push ax>
DPC DEBUG_BPT, 'i'
DA DEBUG_BPT, 	<pop ax>

		push	di, es		; save patient's current cs:ip
	;
	; Set our saved cs:ip to the start of the interrupt handler so
	; when we continue, we continue there.
	; 
		clr	di
		mov	es, di
		mov	al, ah		; al <- interrupt #
		clr	ah
		shl	ax		; *4 to index the interrupt
		shl	ax		;  vector table
		mov_tr	di, ax
		mov	ax, es:[di].offset
		mov	ss:[bp].state_ip, ax
		mov	ax, es:[di].segment
		mov	ss:[bp].state_cs, ax
	;
	; Push the return address and flags onto the stack as if the interrupt
	; had been taken by the processor...
	; 
		mov	es, ss:[bp].state_ss
		mov	di, ss:[bp].state_sp
		sub	di, 6
		mov	ax, ss:[bp].state_flags
		andnf	ax, NOT TFlag 	; Clear TF so it doesn't single-step
					;  on return (unless we want it to)
		mov	es:[di][4], ax	; push flags
		pop	es:[di][2]	; push cs
		pop	ax
		inc	ax		; advance beyond software
		inc	ax		;  interrupt instruction
		mov	es:[di][0], ax	; push ip
		mov	ss:[bp].state_sp, di
		.leave
		ret
EmulateInterrupt endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set an interrupt w/o consulting MS-DOS, saving the old value

CALLED BY:	Com_Init

PASS:		ax = interrupt number to alter
		bx = place (4-byte) to store old value
		dx = new offset
		ds = cgroup (relocated, if stub not in original place)

RETURN:		Nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Sets es to segment 0, copies old value out, places new offset and cs
	in vector.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetInterrupt	proc	far
		push	es		; preserve registers we'll use
		push	cx
		push	bp

		clr	cx		; Place segment 0 in es.
		mov	es, cx

		shl	ax,1		; Multiply vector # by 4 to get vector
		shl	ax,1		; address and place that in bp so we've
		mov	bp, ax		; got a pointer register to it

		dsi			; no interrupts while we're adjusting
					; the vectors, thank you.

		mov	ax, es:[bp]	; First replace offset value
		mov	[bx], ax
		mov	es:[bp], dx

		mov	ax, es:2[bp]	; Then the segment value
		mov	2[bx], ax
		mov	ax, ds:stubCode
		mov	es:2[bp], ax

		eni			; Can now allow interrupts

		pop	bp		; Restore trashed registers
		pop	cx
		pop	es
		ret
SetInterrupt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset an interrupt vector we modified

CALLED BY:	Com_Exit

PASS:		ax = vector number to reset
		bx = area (4-byte) from which to restore it

RETURN:		Nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Make es point to segment 0 and copy the old vector in w/o regard for
	what's there.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	adam	6/7/88		Initial Revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetInterrupt	proc	far
		push	es		; Preserve registers we'll use
		push	di
		push	cx

		shl	ax,1		; Form address for vector and place in
		shl	ax,1		; bp so we can indirect
		mov	di, ax

		clr	cx		; Make es be zero
		mov	es, cx

		dsi			; No interrupts during modification
		mov	ax, [bx]	; Copy vector elements in
		stosw			; DF cleared by SaveState...
		mov	ax, 2[bx]
		stosw
		eni			; Interrupts now ok

		pop	cx		; Restore trashed registers
		pop	di
		pop	es

		ret
ResetInterrupt	endp


scode		ends


stubInit	segment
		assume	cs:stubInit, ds:cgroup, es:cgroup

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FetchArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch an arg from the command tail

CALLED BY:	Com_Init, Main, Kernel_Load
PASS:		ES:DI	= address of desired arg
		ES:BX	= place to store succeeding word -- 0 if no value
			  for arg.
		DX	= number of bytes in value space.
RETURN:		BX	= address after word (or 1 if arg takes no value)
DESTROYED:	SI, AX, DX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/29/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
loaderPos	word	0		; offset of "loader.exe" arg in our
					;  command tail. this is non-zero
					;  if we've found it already.
FetchArg	proc	near
		push	cx
		push	ds
    	    	push	es		; THESE THREE MUST BE IN ORDER
		push	di		;	...
		push	bp		;	...
		mov	bp, sp
		mov 	es, ds:[PSP]
		mov 	ds, ds:[PSP]
		
		cld			; just to be sure

		call	FAGetTailLength	; ds:si <- start of tail, cx <- # of
					;  chars to scan

		jcxz	FAFail
		mov	di, si		; SCAS uses di
FAFindSlash:
		mov	al, '/'	 	; look for /
		repne scasb		; do it, babe.
		jne	FAFail		; Didn't find /
		lds	si, 2[bp]	; Fetch arg name
FACmp:
		lodsb			; Load next arg char
		tst	al		; See if it's null
		jz	FAEqual		; Yes -- consider it a match
		scasb			; Compare it with the next tail char
		loope	FACmp		; Continue the scan unless we hit the
					; end of the tail or we mismatched.
		jne	FAFindSlash	; Nope -- look for next arg. Must
					; be done in this order to ensure
					; that CX keeps track of the tail
					; properly. Since REPNE checks CX
					; first, even if CX is zero at this
					; point, we'll get to FAFail from
					; the JNE up above (ZF will be
					; unchanged).
		lodsb			; Might have hit the end of the arg,
					; too. Check for final null
		tst	al
		jne	FAFail		; Nope -- no such arg
		;FALLTHRU
FAEqual:
		tst	bx		; See if arg takes a value
		jnz	FAEqual2	; yes
		inc	bx		; No -- set bx as a flag
		jmp	short FACopyDone2
FAEqual2:
		jcxz	FAFail		; require : but none here...

		mov	al, ':'		; Args are separated from their
					; values by a colon -- find it
		scasb
		jnz	FAFail		; If hit end of tail (even if last
					; char is :), arg invalid
;FACopy:
		mov	si, di		; Need tail pointer in si for lodsb
FACopy2:
		lods	byte ptr es:[si]; Copy bytes in until the end of
					; the tail or we hit a space or slash
		cmp	al, ' '
		je	FACopyDone
		cmp	al, '/'
		je	FACopyDone
		cmp	al, '\t'
		je	FACopyDone
		mov	[bx], al	; Store the value byte
		inc	bx		; Next place in value
		dec	dx		; See if out of room in value
		jz	FACopyDone2	; Yes.
		loop	short FACopy2	; Go back as long as there's stuff in
					; the tail.
FACopyDone:
		mov	byte ptr [bx], 0; Null-terminate the value, if there's
				        ; room.
FACopyDone2:
FAFail:
		pop	bp
		pop	di		; Remove di from stack
		pop 	es
    	    	pop 	ds
		pop	cx
		ret
FetchArg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FAGetTailLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the start and number of chars in the command tail

CALLED BY:	(INTERNAL) FetchArg
PASS:		ds, es	= PSP
RETURN:		cx	= # chars
		si	= first char of tail to scan
DESTROYED:	ax, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
FAGetTailLengthFar	proc	far
	call	FAGetTailLength
	ret
FAGetTailLengthFar	endp
endif

FAGetTailLength	proc	near
		.enter
		mov	cx, cs:[loaderPos]
		jcxz	locateLoader
computeLength:
		mov	si, 81h
		sub	cx, si
		DPC	DEBUG_INIT, 'L'
		DPW	DEBUG_INIT, cx
		.leave
		ret
locateLoader:
		mov	si, 80h 	; Start search from beginning
					; of tail. 
		cld			; Search forward.
		lodsb			; Fetch the tail length
		cbw			; Convert the length
		mov	cx, ax		; Store count in cx
		mov	di, si
findLoaderLoop:
		mov	al, ' '
		repe	scasb
		je	foundIt		; => went to end of string. di is
					;  exact offset of first char not
					;  included in arg searches
		mov	ah, es:[di-1]	; ah <- first non-space
		cmp	ah, '/'		; switch start?
		jne	foundItButWereOneTooFarIn	; no, but es:di points
							;  to 2d char of loader
							;  name, so must
							;  back it up
		repne	scasb		; is switch -- skip to first blank
		je	findLoaderLoop	; hit blank, so keep looking
		jmp	foundIt		; else hit end of tail
foundItButWereOneTooFarIn:
		dec	di
foundIt:
		mov	cs:[loaderPos], di	; record for next time
		mov	cx, di
		jmp	computeLength
FAGetTailLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainHandleInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with one-time initialization stuff for Main before
		stubInit is overwritten

CALLED BY:	Main
PASS:		DS=ES=cgroup
RETURN:		BX	= non-zero if /s given
		CX	= non-zero if /t given
		intsToIgnore set if /i given
		mask isPC in sysFlags set if running on PC
		PIC1_Mask & PIC2_Mask set to initial interrupt controller
			mask registers
DESTROYED:	AX, ...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

hardwareArg	byte	'H',0	; String for /h match
hardwareBuf	byte	0
ignoreInt	byte	'i',0	; String for /i match
ignoreBuf	byte	5 dup (0)
noStart		byte	's', 0	; String for /s match
tsrFlag		byte	't', 0	; String for /t match

if USE_SPECIAL_MASK_MODE
noSpecialMM	byte	'I', 0	; String for /I match
endif
if ENABLE_CHANNEL_CHECK
noChannelCheckStr	char	'C', 0	; String for /C match
endif

doTsrFlag	char	'T', 0	; string for /T match

MainHandleInit	proc	far
	; try to figure out how fast this PC is...
	; I want to put in a delay loop if we error when starting up, 
	; but for some reason if I loop with interrupts on it seems to
	; go off into space, so I will try it this way...sigh
ifndef NETWARE
		call	CalibrateWaitLoop
endif
	;
	; Always catch breakpoints so if the thing dies before swat
	; can attach, it can still be debugged.
	;
		mov	ax, RPC_HALT_BPT
		call	CatchInterruptFar
	;
	; Fetch initial interrupt controller registers. We don't
	; care about them except that the timer interrupt should be
	; off when we're inside here...
	;
		in	al, PIC2_REG
		mov	ah, al
		in	al, PIC1_REG
		;or	al, 1			;disables timer interrupts
						;while in the stub
		mov	word ptr ds:[PIC1_Mask], ax
		;
		; Determine whether we are on PC or AT to handle different
		; baud rates/interrupts/etc.
		; On the AT, the KBD_CONTROL location cannot have
		; its high bit changed. So we try and change it. If it
		; changes, voila, it's not an AT.
		;
KBD_CONTROL	= 61h
		in	al,KBD_CONTROL      	; get special info
		mov	ah,al			; save info it ah
		or	al,mask XP61_KBD_STROBE	; set high bit 
		out	KBD_CONTROL,al		; 
		in	al,KBD_CONTROL      	; read back new special info
		xchg	al,ah			; save our changed? results
		out	KBD_CONTROL,al		; and return kbd to orig state
		test	ah,mask XP61_KBD_STROBE	; check if high bit changed
		jz	isAT			; Nope.
		or	ds:[sysFlags], MASK isPC; Note we're on PC
isAT:
		mov	di, offset hardwareArg
		mov	bx, offset hardwareBuf
		mov	dx, size hardwareBuf
		push	es
		segmov	es, cs
		assume	es:stubInit
		call	FetchArg
		cmp	bx, offset hardwareBuf
		je	gotHardware	; use default
		; since we only have two types of hardware right now
		; just assume it's the ZOOMER
		mov	bl, es:[hardwareBuf]
		mov	ax, HT_PC
		cmp	bl, 'P'
		je	setHardwareType
		mov	ax, HT_ZOOMER
setHardwareType:		
		call	Com_SetHardwareType
gotHardware:
		pop	es
		assume	es:cgroup
		;
		; Initialize communication system
		; 
		call	Rpc_Init
		jc	done
		;
		; Look for interrupt ignore flag:
		;	/i:n	ignore level N interrupts
		;
		push	es
		segmov	es, cs, di		; Point ES at segment for
						; strings.
		assume	es:stubInit
		call	IgnoreInit
if USE_SPECIAL_MASK_MODE
		;
		; Look for /I -- don't use special mask mode
		;
		mov	di, offset noSpecialMM
		clr	bx		; no arg needed or desired
		call	FetchArg
		mov	noSpecialMaskMode, bx
endif
if ENABLE_CHANNEL_CHECK
		mov	di, offset noChannelCheckStr
		clr	bx		; no arg needed or desired
		call	FetchArg
		mov	ds:[noChannelCheck], bx
		tst	bx
		jnz	findSlashS
		
		test	ds:[sysFlags], mask isPC
		jnz	enableXTChannelCheck
		in	al, 61h
		andnf	al, not mask IPB_ENABLE_IOCHK
		jmp	$+2
		out	61h, al
		jmp	findSlashS
enableXTChannelCheck:
		in	al, 61h
		andnf	al, not mask XP61_ENABLE_IOCHK
		jmp	$+2
		out	61h, al

findSlashS:
endif
	;
	; Look for /T -- always TSR, don't exit.
	; 
		mov	di, offset doTsrFlag
		clr	bx		; no arg needed or desired
		call	FetchArg
		mov	ds:[doTSR], bl

		;
		;
		; Look for /t -- TSR mode, don't let stub overwrite itself.
		;
		mov	di, offset tsrFlag
		clr	bx
		call	FetchArg
		mov	cx, bx			;return cx = /t passed.
		;
		; Look for /s -- don't let the kernel start running
		;
		mov	di, offset noStart
		clr	bx			; no arg needed or desired
		call	FetchArg		;return bx = /s passed
		pop	es			; Point ES back at cgroup

		push	cx			;save cx return value.
		call	Bpt_Init
		pop	cx			
		clc
done:
		assume	es:cgroup
		ret
MainHandleInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalibrateWaitLoop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL

PASS:		es = scode

RETURN:		put the number of loops made for one clock tick

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/18/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef ZOOMER
CalibrateWaitLoop	proc	near
	; just put in some hardwired numbers for Zoomer
		mov	es:[waitValue].high, 0
		mov	es:[waitValue].low, 1000h
		ret
CalibrateWaitLoop	endp
else
ifndef NETWARE
CalibrateWaitLoop	proc	near
		uses	cx, ds, bx, dx, ax
		.enter
		mov	bx, 40h
		mov	ds, bx
		mov	bx, 6ch
		mov	ax, ds:[bx]
waitLoop1:
		cmp	ax, ds:[bx]
		je	waitLoop1

	; ok we got the first one, now wait for the second one
		clr	cx
		mov	dx, cx
		mov	ax, ds:[bx]
waitLoop2:
		cmp	ax, ds:[bx]
		jne	done
		add	cx, 1
		jcxz	overFlow
	; ok waste some clock cycles
		WasteTime
		jmp	waitLoop2
overFlow:
		inc	dx
		jmp	waitLoop2
done:
		mov	es:[waitValue].low, cx
		mov	es:[waitValue].high, dx
		DPW	DEBUG_EXIT, es:[waitValue].low
		DPW	DEBUG_EXIT, es:[waitValue].high
		.leave
		ret
CalibrateWaitLoop	endp
endif
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IgnoreInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	see if we should ignore any interrupts from the environment
		(ignoreed if passed a 'i' flag)
		if so, fill in addIgnore buffer

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/21/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ignoreVar	db	"SWATNOIGNORE="

IgnoreInit	proc	near
		uses	ds, ax, bx, cx, di, es
		.enter
ifdef ZOOMER
		jmp	done
endif
		mov	di, offset ignoreInt
		mov	bx, offset ignoreBuf
		mov	dx, length ignoreBuf
		call	FetchArg
		mov	di, offset ignoreBuf
		cmp	bx, offset ignoreBuf 	;  if bx changed we got it
		jne	gotit
		push	ds
;		call	GetPSP		; ds <- gets the PSP segment
		mov	ax, ds:[swatPSP]
		mov	es, ax
		mov	es, es:[2ch]	; PSP_ENV_SEG
		push	cs
		pop	ds
		clr	ax
		mov	di, ax
doString:
		;
		; See if the variable matches what we're looking for.
		; 
		mov	si, offset ignoreVar
		mov	cx, length ignoreVar
		repe	cmpsb
		je	noIntGiven	; => matches up to the =, so it's
					;  ours...
		dec	di		; deal with mismatch on null byte...
		mov	cx, -1
		repne	scasb
	
		cmp	es:[di], al	; double null (i.e. end of environment)
		jne	doString		; => no
		; ok, not there so default to ignoring int 13 = 0dh
		pop	ds
		push	cs
		pop	es
		mov	di, offset ignoreBuf
		mov	ax, 'd'
		mov	es:[di], ax
		inc	bx
		jmp	gotit
noIntGiven:
		pop	ds
		dec	ds:[intsToIgnore][RPC_HALT_GP]

done:
		.leave
		ret
gotit:
intLoop:
		mov	al, es:[di]		;get char
		cmp	al, 'A'			;check for 'A' to 'F'
		jb	noAF
		cmp	al, 'F'
		ja	noAF
		sub	al, 'A' - 10
		jmp	gotInt
noAF:
		cmp	al, 'a'			;check for 'a' to 'f'
		jb	noaf
		cmp	al, 'f'
		ja	noaf
		sub	al, 'a' - 10
		jmp	gotInt
noaf:
		cmp	al, '0'			;check for '0' to '9'
		jb	afterInts
		cmp	al, '9'
		ja	afterInts
		sub	al, '0'
gotInt:
		clr	ah
		mov	si, ax
		dec	ds:[intsToIgnore][si]
		inc	di
		cmp	di, bx
		jnz	intLoop
		jmp	afterInts

afterInts:
		jmp	done
IgnoreInit	endp

stubInit	ends
		end	Main

