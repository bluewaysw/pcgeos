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
                include gpmi.def

.386
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

					; inverse (for masking purposes)
PIC1_Mask	byte	0feh		; Mask for PIC1 (the master). Rpc_Init
					; masks in the com port's bit.
PIC2_Mask	byte	0ffh		; Mask for PIC2 (the slave)
COM_Mask1	byte			; Mask for the communications port,
COM_Mask2	byte			; which may never be turned off.
					; This is actually the com port mask's
					; inverse (for masking purposes)

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

STUB_USES_PM    = 64

stubType	byte	STUB_LOW or STUB_USES_PM or STUB_USES_REG32	
                                        ; Type of stub we are -- set to
					; other stub type if INIT_HARDWARE
					; goes well.

stubCounter	word	0

ifndef NETWARE
waitValue	dword
endif

    	    	assume	cs:scode,ds:nothing,es:nothing,ss:sstack


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Main
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry routine

CALLED BY:	MS-DOS
PASS:		es 	= PSP
RETURN:		Nothing
DESTROYED:	Everything

PSEUDO CODE/STRATEGY:
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
Main		proc	far


		mov	cs:PSP, es	; Preserve PSP segment
		mov	cs:swatPSP, es

		INIT_HARDWARE

if DEBUG and DEBUG_OUTPUT eq DOT_MONO_SCREEN
	; clear the screen and set the initial blinking cursor
   		les	di, cs:[curPos]
		mov	cx, SCREEN_SIZE/2
		mov	ax, (SCREEN_ATTR_NORMAL shl 8) or ' '
		rep	stosw
		mov	di, cs:[curPos].offset
		mov	ax, (SCREEN_ATTR_NORMAL or 0x80) or 0x7f
		stosw

endif

		;
		; Load es and ds properly
		; 
		mov	ax, cs
		mov	ds, ax
		mov	es, ax

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

		;
		; Look for /s -- don't let the kernel start running
		;
		push	es
                push    cs
                pop     es
		mov	di, offset noStart
		clr	bx			; no arg needed or desired
		call	FetchArg		;return bx = /s passed
		mov	ds:noStartee, bx	;Save /s flag
		pop	es

		assume	ds:cgroup, es:cgroup

    	    	;
		; Load in the kernel. This fills in the kernelHeader structure
		; stubInit is OVERWRITTEN by this call -- can no longer
		; call things there.
		;
		; Kernel_Load sets up exe_cs and exe_ss in kernelHeader for us.
		; 

    	    	call	Kernel_Load
		LONG jc	deathDeathDeath

	;
	; Change in plans. To deal with DosExec we now load the loader as a
	; separate entity with its own PSP and everything.
	; 
		call	MainFinishLoaderLoad
		LONG jc	deathDeathDeath


        ; Here is where we jump between the modes
; ---------------- ENTERING PROTECTED MODE ---------------------
;EnterPM:
                mov     es, ds:[kernelHeader].exe_cs
                mov     bx, es:[0]
                call    {fptr}es:[bx]
                LONG jc deathDeathDeath

; ---------------- ENTERED PROTECTED MODE ---------------------
;EnteredPM:
                ; Hold onto bx -- it's the kernel's code selector
                push    bx                      ; bx = kernel's cs

                ; We need an alias to cs or else we can't write to it
                ; (I have no idea what ds is pointing to at this point)
		mov	ax, bx
                mov     bx, cs                  ; bx = loader's cs
                call    GPMIAliasFirst		; bx = loader's ds version of cs
                mov     ds, bx                  ; ds = alias to cs
                mov     ds:stubDSSelector, bx      ; store ds
                mov     bx, cs
                mov     ds:stubCSSelector, bx   ; store cs

		; Now that we a place to store stuff, let's record the kernel's CS selector
                pop     bx
                mov     ds:kernelCSSelector, bx	; store cs

		; Get an alias to the Kernel's code so we can write to it
		call	GPMIAlias
		mov	ds:kernelDSSelector, bx
		mov	ds:[kdata], bx

                ; Setup the BIOS selector
                mov     bx, 0xF000
                mov     cx, 0xFFFF
                call    GPMIMapRealSegment
                mov     ds:kernelBIOSSelector, bx

    	    	;
		; Set up SS:SP for the kernel now.
		; 
		mov 	bx, ds:[kernelHeader].exe_ss
		mov	cx, ds:[kernelHeader].exe_sp
		; cx = stack limit: exe_sp may be the size, or it may be
		; size - 2.  Round up to the nearest paragraph to get size.
		add	cx, 15
		and	cx, not 15
                mov     ds:loaderStackSize, cx
		dec	cx				; cx = address mask
		call	GPMIMapRealSegment
		mov	ds:kernelSSSelector, bx

		; Let's go ahead and jump onto that stack
                mov     ds:[kernelHeader].exe_ss, bx
		mov	ss, bx
		mov 	sp, ds:[kernelHeader].exe_sp

	;
	; Stick in our hook at the base of the loader code segment
	;
		push	es
		mov	es, ds:kernelDSSelector
		mov	{word}es:[0+2], 0x9a9c	; PUSHF / CALL FAR PTR
		mov	{word}es:[2+2], offset KernelLoader
		mov	{word}es:[4+2], cs
		pop	es

		;
		; Set up interrupt frame for start of kernel in case we want
		; to keep the kernel stopped...
		;
		eni
		pushf
		push	ds:kernelCSSelector
		push	ds:[kernelHeader].exe_ip

	;
	; kdata now lives at the base of the kernel; kcodeSeg is adjusted
	; when we're told what resource kcode is  -- ardeb 1/22/91
	;
		mov	bx, ds:[kernelCSSelector]
		mov	ds:[loaderBase], bx	; also the initial base of
						;  the loader.
		mov	ds:[kcodeSeg], bx	; NOTE!  Are we ready for this?

	; Setup our little stack
		mov	bx, sstack
		mov	cx, offset StackBot
		call	GPMIMapRealSegment
		mov	ds:our_SS, bx

                ; Fixup the PSP for the swat stub.
    	    	mov 	bx, ds:[swatPSP]
		mov	cx, size ProgramSegmentPrefix-1
		call	GPMIMapRealSegment
		mov	ds:[swatPSP], bx

    	    	;
		; Set up es and ds as if the kernel had been invoked from the
		; shell.  This means setting up the PSP correctly.
		; 
    	    	mov 	bx, ds:[PSP]
		mov	cx, size ProgramSegmentPrefix-1
		call	GPMIMapRealSegment
		mov	ds:[PSP], bx
		mov	es, bx
		mov	ds, bx
	
	; Do the main initialization now that we have all the real most setup
		mov	ax, cs:[stubDSSelector]
		mov	ds, ax
		mov	es, ax
		call	MainHandleInit
	;
	; Flag initialization complete.
	; 
		ornf	ds:[sysFlags], mask initialized



		;
		; See if /s given
		;
		tst	cs:noStartee	; Were it there, mahn?
		jnz	MainDontStart	; yow. keep that puppy stopped

		;
		; No -- just do an iret to clear the stack and get going
		;
		RESTORE_STATE	; Deal with write-protect, etc...

		mov	ds, cs:[stubDSSelector]
		ornf	ds:[sysFlags], mask running
		mov	ds, cs:[PSP]
		mov	es, cs:[PSP]

		iret
MainDontStart:
		;
		; Just do a normal state save and go wait for something to do
		;
		mov	ds, cs:[PSP]
		mov	es, cs:[PSP]
		call	SaveState
		jmp	Rpc_Run

noLoadMahn	char	'Couldn''t load kernel: '
ecode		char	'00', '\r\n$'
swatRunError	char	'\r\n', "Couldn't run requested version of GEOS"
		char	 '\r\n', 'Please make sure you are in the '
		char	'correct EC or NC directory and try again','\r\n$'
deathDeathDeath:
		push	ax
		aam
		xchg	al, ah
		or	{word}ds:ecode, ax
                segmov  ds, cs
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
		segmov  ds, cs
		mov	ax, 1
		call	NetWare_Exit
endif
ifdef WINCOM
		segmov  ds, cs
		mov	ax, 1
		call	WinCom_Exit
endif
		EXIT_HARDWARE

		mov	ax, 4c01h
		int	21h
		.unreached
Main		endp

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
		dsi
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
		eni
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
		mov	bx, ds:[kcodeSeg]

		mov	ax, ds:[PSP]
		sub	bx, ax		; bx <- paragraphs needed

		mov	es, ax		; es <- block to resize
		mov	ah, MSDOS_RESIZE_MEM_BLK
		int	21h

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
		
	DPW DEBUG_INIT, bx

		mov	ds:[PSP], bx

	;
	; Set the termination address properly so it doesn't come back to just
	; after the int 21h, above
	; 

; NOTE!!!:  For PM, I don't think this will work.  
;           Exiting the DOS session will exit DPMI and not return here.
;               Lysle 8/10/2000

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
		jz	exitSaveState
		
		push	ds
		PointDSAtStub
		call	Kernel_ReleaseExceptions
		andnf	ds:[sysFlags], not mask attached
		pop	ds

exitSaveState:
		pushf				; create suitable frame
		push	cs			;  for SaveState
		push	cs:[uffDa]

		call	SaveState		; I think this should be
						;  ok, as we'll probably
						;  be on our own stack
						;  anyway...

		PointDSAtStub


		;
		; Get the return code from Geos to check if it TSRed.  If
		; Geos TSRed, then remember that fact because then the stub
		; must also TSR. 
		;
		mov	ah, 4dh
		int	21h

		;
		; Notify UNIX of exit. UNIX will in turn instruct us to
		; exit, so life will be groovy (but we'll be dead).
		; Note we need to record that GEOS is gone so RpcExit
		; doesn't go to EndGeos again.
		;
		or	ds:[sysFlags], MASK geosgone

		test	ds:[sysFlags], mask connected
		jz	handleUnattachedExit

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
		jmp	RpcExit
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
;;if 0
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
;;endif
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
;;if 0
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
;;endif
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
;;if 0
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
;;endif
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
DebugPrintChar	proc	near
;;if 0
		uses	ax
		.enter
		mov	ah, 0xe
		int	10h
		.leave
;;endif
		ret
DebugPrintChar	endp
elif DEBUG_OUTPUT eq DOT_BUFFER

debugPtr	nptr.char debugBuf		; current position in buffer
debugBufSize	word	DEBUG_RING_BUF_SIZE	; size of buffer, for ddebug
						;  to use
debugMagic	word	0xadeb			; my initials, again
debugBuf	char	DEBUG_RING_BUF_SIZE dup(0)


DebugPrintChar	proc	near
if 0
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
endif
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
if 0
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
endif
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
	According to DPMI 0.9, Exceptions 0-5 and 7 are reflected as interrupts,
	but 6 and 8-1Fh are not.  We must catch those via the get/set exception
	handler	vector calls.  To keep things uniform, all interrupts will
	be trapped and handled as exceptions.

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
		push	cx, edx

		; Get the old vector
		mov	bl, al
		clr	bh
		call	GPMIGetExceptionHandler

		; If we already have that exception caught, then don't grab it
		cmp	cx, cs:[stubCSSelector]
		je	CI2

		; Setup this exception for ourselves
		mov	si, bx
		shl	si, 1
		mov	ax, si		; ax = interrupt * 2
		shl	si, 1
		shl	si, 1		; si = interrupt * 8
		add	si, ax		; si = interrupt * 10
		add	si, bx		; si = interrupt * 11
		add	si, (offset ExceptionHandlers)+5

		; Record old vector
		mov	es, cs:[stubDSSelector]
		mov	es:[si], edx
		mov	es:4[si], cx

		; Set the new vector
		DPC	DEBUG_FALK3, 'C'
		xor	edx, edx
		sub	si, 5
		mov	dx, si
		mov	cx, cs
		call	GPMISetExceptionHandler
		jnc setOK
		DPC	DEBUG_FALK3, 'E'

setOK:
		DPB	DEBUG_FALK3, bl

		; Make sure the outside world knows the matching
		; InterruptHandler is also in use.
		mov	si, bx
		shl	si, 1
		mov	ax, si		; ax = interrupt * 2
		shl	si, 1
		shl	si, 1		; si = interrupt * 8
		add	si, ax		; si = interrupt * 10
		add	si, (offset InterruptHandlers)+4
		mov	es:[si], edx
		mov	es:4[si], cx

CI2:
		pop	cx, edx
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
	dhunter	11/14/00	GPMI version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IgnoreInterrupt	proc	near
		push	es		; Save needed registers
		push	bx
		push	si
		push	cx, edx

		; Get the old vector
		mov	bl, al
		clr	bh
		call	GPMIGetExceptionHandler

		; If we don't have that vector caught, then do nothing.
		cmp	cx, cs:[stubCSSelector]
		jne	II2

		; Locate the interrupt in our table
		mov	si, bx
		shl	si, 1
		mov	ax, si		; ax = interrupt * 2
		shl	si, 1
		shl	si, 1		; si = interrupt * 8
		add	si, ax		; si = interrupt * 10
		add	si, bx		; si = interrupt * 11
		add	si, (offset ExceptionHandlers)+5

		; Restore old vector
		mov	es, cs:[stubDSSelector]
		mov	edx, es:[si]
		mov	cx, es:4[si]
		call	GPMISetExceptionHandler

		; The matching InterruptHandler is now free.
		mov	si, bx
		shl	si, 1
		mov	ax, si		; ax = interrupt * 2
		shl	si, 1
		shl	si, 1		; si = interrupt * 8
		add	si, ax		; si = interrupt * 10
		add	si, (offset InterruptHandlers)+4
		clr	{dword}es:[si]
		clr	{word}es:4[si]

II2:
		pop	cx, edx
		pop	si		; Restore registers
		pop	bx
		pop	es
		ret
IgnoreInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetStepHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the interrupt handler for the step exception.  This
		modifies ExceptionReflector1.

CALLED BY:	Rpc_Init, Bpt_Skip, BptSkipRecover
PASS:		dx = offset of routine
RETURN:		nothing
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		Modify the call instruction in ExceptionReflector1.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	11/21/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetStepHandler	proc	near
		uses	ds
		.enter

		mov	ds, cs:[stubDSSelector]
	;
	; Thru the magic of observation, we know that the near call in an
	; ExceptionReflector is 15 bytes from the start of the routine.
	; We will replace that call with a near jmp (opcode E9).  Also,
	; don't forget that the jmp offset is PC-relative!
	;
		sub	dx, (offset ExceptionReflector1 + 18)
		mov	{byte}ds:[(offset ExceptionReflector1 + 15)], 0e9h
		mov	{word}ds:[(offset ExceptionReflector1 + 16)], dx
		
		.leave
		ret
SetStepHandler	endp


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
	dhunter	11/15/00	Handle exception stack frame

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
haltCodeAddr	word	    	    ; Address of interrupt code

		assume	ds:nothing,es:nothing,ss:nothing
IRQCommon	proc	near
		WRITE_ENABLE

                ; NOTE:  The following code is trickey because it is re-entrant.
                ; because of this, we have a hard time finding a place to store
                ; the old ds.  I was going to put it on the stack, roll back sp
                ; and then look at the ds at the end, but because it is reentrant,
                ; it has a chance of being overwritten by another interrupt.
                ; Instead, we stuff all our needed registers on the stack and then
                ; look back on the stack for the data we need.  We then recover
                ; the stack "popping" off the no longer needed near return to the
                ; IRQ stub.  The key is SaveState has to look like we are returning
                ; back via a iret.

                ; AFter the SaveState, well, we can play.
                ;  -- Lysle 08/14/2000

                push    ds
                push    ax
                push    bp
                mov     bp, sp
                
		mov     ds, cs:[stubDSSelector]
		mov	ax, ss:[bp+6]

        ; Return address goes in haltCodeAddr
	; so we can get the reason for the
	; stoppage
                mov     ds:haltCodeAddr, ax     

                pop     bp
                pop     ax
		pop     ds
		add	sp, 2
		call	SaveState
IRQCommon_SaveState	label near
		assume	ds:cgroup, es:cgroup, ss:sstack
;XXX put return address back on the new stack (WHY?)
		push	cs:[haltCodeAddr]

		mov     ds, cs:[stubDSSelector]
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

		DA	DEBUG_ENTER_EXIT, <push ax>
		DPC	DEBUG_ENTER_EXIT, 'Q'
		DA	DEBUG_ENTER_EXIT, <pop ax>
		DPB	DEBUG_ENTER_EXIT, al


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
;		eni			; Handle skipped call...
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
		word	0		; segment of previous vector too
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
		ExceptionCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to start reflecting an exception to an interrupt

CALLED BY:	ExceptionHandlers
PASS:		[SP] = ExceptionReflector#
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	When GPMI throws an exception our way, our call stack looks
	like this:

		SS		stack at time of exception
		SP
		Flags		flags at time of exception
		CS		execution point at time of exception
		IP
		Error code	exception error code
		Return CS	our caller (DPMI)
	TOS ->	Return IP

	An exception handler reflects the exception to an interrupt
	handler by saving the original CS:IP, then pointing it to an
	ExceptionReflector and returning.  GPMI will return control
	to the excepting process at the new location, where the
	reflector will defer to an interrupt handler.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 11/19/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
exceptedFlags	word			; flags of he who caused the exception
exceptedCS	word			; CS of he who caused the exception
exceptedIP	word			; IP of he who caused the exception
exceptedError	word			; exception error code

ExceptionCommon	proc	near
	;
	; Load DS with our dgroup.
	;
		push	ds, ax, bx, bp
		mov	ds, cs:[stubDSSelector]

	;
	; Save CS:IP and error code of excepting process.
	;
		mov	bp, sp			; ss:bp+10 = ExceptionFrame
		add	bp, 10			; ss:bp = ExceptionFrame
		mov	ax, ss:[bp].except_cs
		mov	ds:exceptedCS, ax
		mov	ax, ss:[bp].except_ip
		mov	ds:exceptedIP, ax
		mov	ax, ss:[bp].except_error
		mov	ds:exceptedError, ax
	;
	; Turn off the trap flag in the ExceptionFrame in case we're single
	; stepping.  Also disable interrupts, but store the original state
	; in exceptedFlags.
	;
		mov	ax, ss:[bp].except_flags
		andnf	ax, not TFlag
		mov	ds:exceptedFlags, ax
		andnf	ax, not IFlag
		mov	ss:[bp].except_flags, ax
	;
	; Change CS:IP to passed ExceptionReflector.
	;
		mov	ax, cs
		mov	ss:[bp].except_cs, ax
		mov	bx, ss:[bp-10+8]	; cs:bx = ExceptionReflector#
		mov	ax, cs:[bx]
		mov	ss:[bp].except_ip, ax
	;
	; If trapping a stack exception (12), change SS:SP to the stub
	; stack now, so our stack activities in the reflector and so on
	; don't potentially cause another exception.
	;
		cmp	ax, offset ExceptionReflector12
		jne	done
		mov	ax, ss:[bp].except_ss
		mov	ds:prev_SS, ax		; save old ss
		mov	ax, ss:[bp].except_sp
		mov	ds:prev_SP.low, ax	; save old sp
		mov	ax, ds:our_SS
		mov	ss:[bp].except_ss, ax	; set our ss
		mov	ax, ds:stateStackOffset
		sub	ds:stateStackOffset, 1024
		mov	ss:[bp].except_sp, ax	; set our sp
	;
	; Skip near return and do far return.
	;
done:
		pop	ds, ax, bx, bp
		add	sp, 2
		retf
		
ExceptionCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExceptionHandlers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	These are the handlers for all the various possible
		exceptions.

CALLED BY:	CPU via GPMI
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	See ExceptionCommon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	11/19/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
defineExceptionH	macro	num
Exception&num:
		call	ExceptionCommon	; Do the regular stuff
		.unreached
		nptr	ExceptionReflector&num	; where to redirect CS:IP
		dword	0		; Previous vector
		word	0		; segment of previous vector too
endm

ExceptionHandlers label near
EXCEPT_NUM	= 0

.warn	-unref		; these are referenced indirectly via
			;  ExceptionHandlers
		rept	16		; Exception 0 - 0F
		defineExceptionH	%EXCEPT_NUM
EXCEPT_NUM	= EXCEPT_NUM+1
		endm
.warn	@unref


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExceptionReflectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reflect an exception to an interrupt

CALLED BY:	ExceptionCommon via GPMI
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Pretend we're an InterruptHandler and were called by an interrupt
	by pushing the usual interrupt frame and calling IRQCommon.  CS:IP
	was saved by ExceptionCommon.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 11/19/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
defineExceptionR	macro	num
ExceptionReflector&num:
		push	cs:exceptedFlags; 5 bytes
		push	cs:exceptedCS	; 5
		push	cs:exceptedIP	; 5
		call	IRQCommon	; 3 - Do the regular thing
		.unreached
		byte	num		; Exception that caused the stop
endm

EXCEPT_NUM	= 0

		rept	16		; Exception 0 - 0F
		defineExceptionR	%EXCEPT_NUM
EXCEPT_NUM	= EXCEPT_NUM+1
		endm

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
		dsi
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
prev_DS		word	0		; DS when saving
our_SS		word	sstack		; Only way to load SS w/o using another
					; register (which we haven't got).
ssRetAddr	word	0		; Our return address.
ssTimerCount	word			; Count in timer 0 when state last
					;  saved
ssResumeTimerCountPtr nptr.word	0	; Place to store count that's in
					;  timer 0 when we restore state
					;  0 if not to store it.
stateStackOffset    word    offset StackBot
stackException	word	0		; non-zero if saving after stack exception

		assume 	ds:nothing, es:nothing, ss:nothing
SaveState	proc	near
	;
	; Deal with write-protection, etc.
	;
		SAVE_STATE

	DA	DEBUG_ENTER_EXIT, <push ax>
	DPC	DEBUG_ENTER_EXIT, 'e'
	DA	DEBUG_ENTER_EXIT, <pop ax>
	DA	DEBUG_FALK3, <push ax>
	DPC	DEBUG_FALK3, 'e'
	DA	DEBUG_FALK3, <pop ax>
	;
	; Remove our return address from the stack
	; 
		push	ds
		mov	ds, cs:stubDSSelector
				assume	ds:scode
		clr	ds:ssRetAddr

		push	ax
		push	bp
		mov	bp, sp
		mov	ax, ss:[bp+4]	; Get ds on stack
		mov	ds:prev_DS, ax
		mov	ax, ss:[bp+6]	; Get ip on stack
		mov	ds:ssRetAddr, ax
		pop	bp
		pop	ax
		add	sp, 4	; don't pop off ds and get rid of return address

		push	ax
		call	FetchTimer0
		mov	[ssTimerCount], ax
		DPC DEBUG_FALK2, 'T'
		pop	ax
	;
	; If we're here because of a stack exception, the stack has already been
	; switched and prev_SS:SP have been loaded.  Skip ahead.
	;
		clr	ds:stackException
		cmp	ds:ssRetAddr, offset IRQCommon_SaveState
		jne	switch
		push	bx
		mov	bx, ds:[haltCodeAddr]
		cmp	{byte}ds:[bx], 12	; stack exception?
		pop	bx
		jne	switch			; nope, switch
		inc	ds:stackException	; flag this condition
		jmp	SS1			;  and skip ahead
	;
	; Switch to our stack, saving the previous one in
	; prev_SS:prev_SP. If we were already on our stack, don't
	; change SS:SP at all.
	;
switch:
	DA	DEBUG_FALK2, <push ax>
	DPC	DEBUG_FALK2, 'K'
	DA	DEBUG_FALK2, <pop ax>
		mov	ds:prev_SS, ss		; Store SS
	        mov	ds:prev_SP, esp
                push    bx
                mov     bx, ss
                ;call    GPMIIsSelector16Bit
                ;jnz     is32BitStack
		clr     ds:prev_SP.high
is32BitStack:
	DA	DEBUG_FALK2, <push ax>
	DPC	DEBUG_FALK2, 'H'
	DA	DEBUG_FALK2, <pop ax>
		pop	bx
		
		; Ok, I know this looks weird, but we have a very serious problem.
		; In the old 16-bit setup, an interrupt would always occur on the
		; active stack.  When running under DPMI (and technically any possible
		; PM core), the calling stack does not always appear and instead
		; we break on a new separate stack.  This occurs when the interrupt
		; occurs while in protected mode 32-bit code segment instead of a 16-bt
		; code segment.  DPMI sets up another stack and processes the interrupt
		; from there -- even if you were originally waiting in a 16-bit segment.
		; So, when a ComInterrupt occurs, it is usually reflected through
		; WinNT's 32-bit code before coming here and given it's own special stack.  
		; We can't just compare SS with the Stub's normal SS, so we effectively have 
		; to create a stack per state.  We can do this by giving each state 1024 bytes
		; of the stack.  I've increased the size to 4096 (instead of its
		; original 1024) to ensure there is enough room.  I doubt we'll
		; ever have an interrupt four levels deep that we need to catch.  In
		; fact, we should only have two levels deep (ComInterrupt while in
		; a breakpoint).  -- lshields 08/29/2000
		;		push	ax
		;		mov	ax, cs:our_SS
		;		cmp	ds:prev_SS, ax
		;		pop	ax
		;		je	SS1
		mov	ss, ds:our_SS	; bp = state_PIC1
		mov	sp, ds:stateStackOffset
		sub	sp, 1024
		mov	ds:stateStackOffset, sp
		add	sp, 1024
SS1:
		DA	DEBUG_ENTER_EXIT, <push ax>
		DPW	DEBUG_ENTER_EXIT, ds:stateStackOffset
		DA	DEBUG_ENTER_EXIT, <pop ax>

		assume	ss:sstack

	;
	; Save all the registers mostly in the order dictated
	; by an IbmRegs structure so they can be copied in easily.
	; 

if _Regs_32
                push    edi
                push    esi
                push    ebp
                push    ds:prev_SP
                push    ebx
                push    edx
                push    ecx
                push    eax

		push	gs
		push	fs
else
                push    di
                push    si
                push    bp
                push    ds:prev_SP
                push    bx
                push    dx
                push    cx
                push    ax
endif
		push	es	; bp = state_PIC1
		push	ds:prev_SS
		push	ds:prev_DS

	;
	; Now the pertinent kernel variables:
	; 	currentThread
	; 
		mov	ax, HID_KTHREAD	; Assume we don't know and make it
					; the kernel...
		test	cs:sysFlags, MASK attached
		jz	SS2

; NOTE!!! This section of code til SS2 has not been tested (since I have not attached even once yet)
		
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
		and	al, 0feh	
					; Make sure timer interrupt is
					; enabled on return (might have been
					; disabled for single-stepping). If
					; function that continues wants it
					; disabled, it will have to set the
					; bit here itself.
		push	ax
		
	;
	; Fetch flags, cs and ip from the previous stack.  And in case we were
	; fired by an exception, fetch the error code too.
	; If fired by a stack exception, the iret frame is on our stack instead.
	;
		tst	cs:stackException		; stack exception?
		jnz	SS3				; yep, got iret frame
		.assert	(offset prev_SS) eq ((offset prev_SP) + 4)
		lds     ebx, dword ptr cs:prev_SP	; ds:ebx = interrupt frame
		jmp	foundIret
SS3:
		segmov	ds, ss, ax
		clr	ebx
		mov	bx, cs:stateStackOffset		; ebx = starting point - 1024
		add	bx, 1024-(size IRetFrame)	; ebx = IRetFrame
foundIret:
		push 	ds:[ebx].iret_flags		; state_flags
		DPW	DEBUG_ENTER_EXIT, ds:[ebx].iret_cs
		push 	ds:[ebx].iret_cs		; state_cs
		DPW	DEBUG_ENTER_EXIT, ds:[ebx].iret_ip
		push 	ds:[ebx].iret_ip		; state_ip
		push	cs:[exceptedError]		; state_error
		
	;
	; Save the timer interrupt vector and use our own
	;

		mov	bl, TIMER_INT
		call	GPMIGetInterruptHandler

                ; push this into the state_timerInt position
		push	cx
		push	edx

		xor	edx, edx
		mov	dx, offset StubTimerInt
		mov	cx, cs
		call	GPMISetInterruptHandler

if INTEL_BREAKPOINT_SUPPORT
	;
	; save the hardware breakpoint status, then clear it
	; so the next person to save state doesn't think they also are
	; handling a breakpoint
	;
		movsp	eax, dr6
                push    eax
		and	ax, not ( mask DR6L_B3 or mask DR6L_B2 \
			       or mask DR6L_B1 or mask DR6L_B0 )
		movsp	dr6, eax
	;
	; save the breakpoint state, then disable all breakpoints so
	; we don't trigger one from within the stub
	;
		movsp	eax, dr7
                push    eax
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
		tst	cs:stackException		; stack exception?
		jnz	SS4				; yep, no adjust
		add	([bp].state_esp), size IRetFrame
SS4:
	;
	; Want our data, thank you.
	; 
		mov	ax, cs:[stubDSSelector]
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
	
ifndef WINCOM
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
	DA	DEBUG_FALK2, <push ax>
	DPC	DEBUG_FALK2, 'S'
	DA	DEBUG_FALK2, <pop ax>
	DA	DEBUG_FALK3, <push ax>
	DPC	DEBUG_FALK3, 'E'
	DA	DEBUG_FALK3, <pop ax>
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
		mov	al, 0xfe
		mov	ah, ds:[COM_Mask1]
		not	ah
		and	al, ah
		out	PIC1_REG, al
	DA	DEBUG_FALK3, <push ax>
	DPC	DEBUG_FALK3, 'F'
	DA	DEBUG_FALK3, <pop ax>
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
                PointDSAtStub		; satisfy our assumption
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
                pop     eax
		movsp	dr7, eax
                pop     eax
		clr	eax
		movsp	dr6, eax
endif
		;
		; Restore the timer interrupt vector
		;
		pop     edx
		pop	cx
		mov	bl, TIMER_INT
		call	GPMISetInterruptHandler

    	    	;
		; Set up CS:IP and flags
		;
		add	sp, 2			; skip state_error

		mov 	es, [bp].state_ss
		assume	es:nothing
		mov 	edi, [bp].state_esp

		sub	edi, size IRetFrame		; Make room for iret frame
		cld
		mov	[bp].state_esp, edi
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
		push	ds
		mov	ds, ds:[kdata]
		mov	[bx], ax
		pop	ds
RS1:
		;
		; Registers
		; 
		pop	ds:prev_DS
		pop	ds:prev_SS
		pop	es
if _Regs_32
                pop	fs
                pop	gs
endif

                pop     eax
                pop     ecx
                pop     edx
                pop     ebx
		pop     ds:prev_SP
                pop     ebp
                pop     esi
                pop     edi

		mov	ss, cs:prev_SS
                mov     esp, cs:prev_SP
		assume	ss:nothing

		tst	cs:[ssResumeTimerCountPtr]
		jz	done

		push	ax, bx
		clr	bx
		xchg	bx, ds:[ssResumeTimerCountPtr]
		call	FetchTimer0
		mov	ds:[bx], ax
		pop	ax, bx
done:
		push ax
		mov ax, ds:stateStackOffset
		DPW	DEBUG_ENTER_EXIT, ax
		add ax, 1024
		mov ds:stateStackOffset, ax
		pop ax

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

                ; Recover the interrupt flag -- correctly for DPMI
		; We can't just pop the flag with iret and expect
		; the emulated interrupt to work correctly.  so, we
		; have to do a dsi/eni manually without messing up
		; any of the registers or other flags.
                dsi
                pushf
                push ax
                push bp
                mov bp, sp
                mov ax, ss:[bp+4]
                test ax, IFlag
                jnz enabled
disabled:              
                pop bp   
                pop ax
                popf
                jmp continueOn
enabled:
                pop bp   
                pop ax
                popf
                eni
continueOn:
		mov	ds, cs:prev_DS
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
                pushfd
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
                iretd
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

		DPC	DEBUG_TIMER_TICK, 'T'
	;
	; Deliver the specific EOI for this level (timer at level 0). The
	; EOI has to be specific since the controller will be in
	; special-mask mode when we're called (since we're only called in
	; the stub's context).
	;
	mov	al,I8259_SPEOI
	out	I8259_COMMAND,al

if 0	; Is this really necessary? And wouldn't this mess with 
	; the floppy drive ALL the time? -- lshields 09/08/2000

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
        mov     ds, cs:[stubDSSelector]
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
		uses	bx, cx, dx
		.enter
DA DEBUG_BPT,	<push ax>
DPC DEBUG_BPT, 'i'
DA DEBUG_BPT, 	<pop ax>

		push	di, es		; save patient's current cs:ip
	;
	; Set our saved cs:ip to the start of the interrupt handler so
	; when we continue, we continue there.
	; 
		mov	bl, ah		; bl <- interrupt #
                call    GPMIGetInterruptHandler
		mov	ss:[bp].state_ip, dx
		mov	ss:[bp].state_cs, cx
	;
	; Push the return address and flags onto the stack as if the interrupt
	; had been taken by the processor...
	; 
		mov	es, ss:[bp].state_ss
		mov	di, ss:[bp].state_sp
		sub	di, size IRetFrame
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
                push    edx

                push    bx
                mov     bl, al
                call    GPMIGetInterruptHandler
                pop     bx
                mov     ds:[bx], dx
                mov     ds:[bx+2], cx

                ; Get the original (e)dx again
                pop     edx

                ; All interrupts are in this same segment/selector
                mov     cx, cs
                push    bx
                mov     bl, al
                call    GPMISetInterruptHandler
                pop     bx

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


scode	segment
		assume	cs:scode, ds:cgroup, es:cgroup

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
FetchArg	proc	far
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
                cmp     cx, 0
                jle     FAFail          ; out of characters
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
                push    ds
                PointDSAtStub
		mov	ds:[loaderPos], di	; record for next time
                pop     ds
		mov	cx, di
		jmp	computeLength
FAGetTailLength	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainHandleInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with one-time initialization stuff for Main 
		
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
		PointESAtStub
		assume	es:scode
		call	FetchArg
		cmp	bx, offset hardwareBuf
		je	gotHardware	; use default
		; since we only have two types of hardware right now
		; just assume it's the PC
		mov	bl, es:[hardwareBuf]
		mov	ax, HT_PC
		cmp	bl, 'P'
		je	setHardwareType
		mov	ax, HT_PC
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
		PointESAtStub		; Point ES at segment for
						; strings.
		assume	es:scode
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
		;
		; Look for /t -- TSR mode, don't let stub overwrite itself.
		;
		mov	di, offset tsrFlag
		clr	bx
		call	FetchArg
		mov	cx, bx			;return cx = /t passed.
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
ifndef NETWARE
CalibrateWaitLoop	proc	near
		uses	cx, ds, bx, dx, ax
		.enter
		mov	bx, 40h
		mov	cx, 256-1
		call	GPMIAccessRealSegment
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
                mov     es, cs:[stubDSSelector]
		mov	di, offset ignoreInt
		mov	bx, offset ignoreBuf
		mov	dx, length ignoreBuf
		call	FetchArg
		mov	di, offset ignoreBuf
		cmp	bx, offset ignoreBuf 	;  if bx changed we got it
		jne	gotit
		push	ds
;		call	GetPSP		; ds <- gets the PSP segment
		mov	es, ds:[swatPSP]
                mov     bx, es:[2ch]    ; PSP_ENV_SEG
                mov     cx, -1
                call    GPMIAccessRealSegment
                mov     es, bx

                mov     ds, cs:[stubDSSelector]
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
;;		pop	ds
;;                mov     es, cs:[stubDSSelector]
;;		mov	di, offset ignoreBuf
;;		mov	ax, 'd'
;;		mov	es:[di], ax
;;		inc	bx
;;		jmp	gotit
noIntGiven:
		pop	ds
;;		dec	ds:[intsToIgnore][RPC_HALT_GP]

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

scode	ends

scode		segment
GPMIAliasFirst	proc    near
                push    es
		push	si
		mov	es, ax
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_ALIAS]
		pop	si
                pop     es
                ret
GPMIAliasFirst	endp

GPMIAlias       proc    near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_ALIAS]
		pop	si
                pop     es
                ret
GPMIAlias       endp

GPMIFreeAlias       proc    near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_FREE_ALIAS]
		pop	si
                pop     es
                ret
GPMIFreeAlias       endp

GPMIAccessRealSegment       proc    near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_ACCESS_REAL_SEGMENT]
		pop	si
                pop     es
                ret
GPMIAccessRealSegment       endp

GPMIMapRealSegment       proc    near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_MAP_REAL_SEGMENT]
		pop	si
                pop     es
                ret
GPMIMapRealSegment       endp

if 0
GPMIResizeBlock	proc near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_RESIZE_BLOCK]
		pop	si
                pop     es
                ret
GPMIResizeBlock	endp
endif

GPMIGetExceptionHandler proc near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_GET_EXCEPTION_HANDLER]
		pop	si
                pop     es
                ret
GPMIGetExceptionHandler endp

GPMISetExceptionHandler proc near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_SET_EXCEPTION_HANDLER]
		pop	si
                pop     es
                ret
GPMISetExceptionHandler endp

GPMIGetInterruptHandler	proc near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_GET_INTERRUPT_HANDLER]
		pop	si
                pop     es
                ret
GPMIGetInterruptHandler	endp

GPMISetInterruptHandler	proc near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_SET_INTERRUPT_HANDLER]
		pop	si
                pop     es
                ret
GPMISetInterruptHandler	endp

GPMIIsSelector16Bit     proc near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_IS_SELECTOR_16_BIT]
		pop	si
                pop     es
                ret
GPMIIsSelector16Bit     endp

GPMISelectorCheckLimits proc near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_SELECTOR_CHECK_LIMITS]
		pop	si
                pop     es
                ret
GPMISelectorCheckLimits endp

GPMITestPresent	proc near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_TEST_PRESENT]
		pop	si
                pop     es
                ret
GPMITestPresent	endp

GPMIGetInfo	proc near
                push    es
		push	si
                mov     es, cs:[kernelCSSelector]
                mov     si, es:[0]
                call    {fptr}es:[si+GPMI_CALL_GET_INFO]
		pop	si
                pop     es
                ret
GPMIGetInfo	endp

GPMIGetDescriptor	proc near
DA DEBUG_FALK2,	<push ax>
DPC DEBUG_FALK2, '1'
DA DEBUG_FALK2, 	<pop ax>
                push    ds
		push	si
                mov     ds, cs:[kernelCSSelector]
                mov     si, ds:[0]
                call    {fptr}ds:[si+GPMI_CALL_GET_DESCRIPTOR]
		pop	si
                pop     ds
DA DEBUG_FALK2,	<push ax>
DPC DEBUG_FALK2, '2'
DA DEBUG_FALK2, 	<pop ax>
                ret
GPMIGetDescriptor	endp

scode		ends

		end	Main

