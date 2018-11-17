COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel System Functions -- Initialization
FILE:		sysInit.asm

AUTHOR:		Adam de Boor, Apr  6, 1989

ROUTINES:
	Name			Description
	----			-----------
	InitSys			Initialize random Sys module stuff

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/ 6/89		Initial revision


DESCRIPTION:
	Initialization code for the Sys module


	$Id: sysInit.asm,v 1.1 97/04/05 01:15:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitSys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure and record system configuration

CALLED BY:	InitGeos
PASS:		DS	= idata
RETURN:		Nothing
DESTROYED:

PSEUDO CODE/STRATEGY:
		Figure the type of processor by executing instructions from
		ever-rarefied regions of the 8086-family instruction space
		until one of them chokes.

		Try and figure the type of machine using BIOS, checking
		the model byte in ROM as a last resort (well, almost last :)

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/17/89		Initial version
	cheng	1/15/90		Extended recognition

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Mapping of model bytes to SysMachineType
ISM_MIN		= 0f8h

ifidn		HARDWARE_TYPE, <PC>

initSysModels	byte	SMT_PS2_80		;f8
		byte	SMT_PC_CONV		;f9 (PC convertible)
		byte	SMT_PS2_30		;fa (PS2 25, 30)
		byte	SMT_PC_XT		;fb (PC/XT)
		byte	SMT_PC_AT		;fc (PC/XT286, PC/AT, PS2 50,60,
						; PS1)
		byte	SMT_PC_JR		;fd
		byte	SMT_PC_XT		;fe
		byte	SMT_PC			;ff
endif

; ModRM byte for funky instructions. Refer to processor handbook for what
; the fields actually mean. For our purposes, MRMB_MOD == 3 => operand
; is a register, MRMB_RM == 2 => DX.
ModRMByte	record	MRMB_MOD:2, MRMB_REG:3, MRMB_RM:3

underSwatArg	char	's', 0
restartedArg	char	'r', 0
logFileArg	char	'log', 0

InitSys		proc	near 	uses cx, es, ax, di, bx, dx
		.enter

;;; We call into BIOS here, so turn off single-stepping and the like
SSP <	call	SaveAndDisableSingleStepping				>

ifidn	HARDWARE_TYPE, <PC>

	;
	; Figure out the processor type. This is done by diddling with the flags
	; register (eflags for 386 and 486) and seeing what flags we can
	; change. The code comes from the i486 programmer's reference, pages
	; 3-42 (for 486 vs. 386 decision), and 22-2 (8088/286/386). The
	; 80186 determination comes from the 186 reference.
	;
		pushf
		pop	bx
		andnf	bx, 0x0fff	; clear high nibble (undefined on
					; 8088, and always 1)
		push	bx
		popf
		pushf
		pop	ax

		
		andnf	ah, 0xf0	; See if they're all set
		cmp	ah, 0xf0
		jne	notLowEnd
		
	;
	; Either 808x or 8018x. We can distinguish between the two b/c the
	; 18x trims shift counts mod 32, while the 8x will just keep shifting.
	; Therefore, we take 1 and shift it left 32 times. If it's still 1, we
	; have a 18x.
	; 
		mov	ax, SPT_80186
		mov	cl, 32
		shl	ax, cl
			CheckHack <SPT_8088 eq 0>
		jmp	storePT

notLowEnd:
	;
	; See if it's a 286 by trying to set bits 12-15 (non-settable and
	; always 0 in real mode on a 286, but alterable on a 386 even in
	; real mode).
	;
		ornf	bx, 0xf000
		push	bx
		popf
		pushf
		pop	ax
		test	ax, 0xf000	; still all zero?
		mov	al, SPT_80286	; assume so
		jz	storePT		; yup => 286

	;
	; Now for the fun part. It's at least a 386, but we'd like to determine
	; if it's a 486. The 486 has a bit that will cause a fault if an
	; unaligned memory reference happens.
	; 
		.386

	    ;
	    ; Make sure the stack is longword aligned so these pushes don't
	    ; cause traps when we set the AC flag.
	    ; 
		push	edx
		push	ecx
		mov	edx, esp
		andnf	sp, not 3
	    ;
	    ; Fetch the current EFLAGS register into EAX and ECX.
	    ; 
		pushfd
		pop	eax
		mov	ecx, eax
  	    ;
	    ; Set the AC flag (0x00040000) in the EFLAGS register.
	    ; 
		xor	eax, 0x00040000
		push	eax
		popfd
	    ;
	    ; See if the setting of AC took, XOR'ing the original flags
	    ; register (which doesn't have the bit set) with the possibly-
	    ; modified one.
	    ; 
		pushfd
		pop	eax
		xor	eax, ecx
	    ;
	    ; Shift the flag to the low bit of AX, not into the carry, as we
	    ; need to reset the EFLAGS register to its original value...
	    ; 
		shr	eax, 18
	    ;
	    ; Reset EFLAGS and ESP to their original values.
	    ; 
		push	ecx
		popfd
		mov	esp, edx
		pop	ecx
		pop	edx
		
	;
	; If AX<0> is 1, we're on a 486.
	; 
		test	ax, 1
		mov	al, SPT_80386
		jz	storePT
		
		mov	al, SPT_80486
storePT:
	;
	; AL is the processor type we've determined.
	; 
		mov	ds:[sysProcessorType], al

	;
	; Use the BIOS Get System Config call to figure out what sort of
	; machine we're on. The combinations of model bytes and submodel
	; bytes that determine the machine type are too complex to enter here.
	; They're in the "Personal System 2 and Personal Computer BIOS
	; Interface Technical Reference" on page 4-18, if you're interested.
	;

	; BIOS_GET_SYS_DESC disables the trap flag also, so save and restore
	; our trap status here.
		mov	ah, BIOS_GET_SYS_DESC
		int	15h
		INT_ON			; Some machines return interrupts off
					; here, the bastards
		jc	IS30		; Call unsupported
	;
	; ES:BX now point to the system descriptor table:
	;
	;
	; First take the two features bits in which we're interested and shove
	; them into the sysConfig byte.
	;
		mov	al, es:[bx].SDT_features
		and	al, (mask SDF_2ND_IC OR mask SDF_RTC_PRESENT or \
			     mask SDF_MCA)
		CheckHack <(offset SDF_2ND_IC eq offset SCF_2ND_IC) and \
			   (offset SDF_RTC_PRESENT eq offset SCF_RTC) and \
			   (offset SDF_MCA eq offset SCF_MCA)>

		or	ds:sysConfig, al
	;
	; Now the model byte...
	;
		mov	di, word ptr es:[bx].SDT_model
		and	di, 0ffh
		sub	di, ISM_MIN
		jl	IS20		; Below known values
		mov	al, cs:initSysModels[di]	; Fetch translation
		cmp	al, SMT_PC_AT
		jne	haveMT		; Everything else "correct"
	;
	; Model FC needs to be resolved by the submodel byte:
	;	02h	= PC/XT 286
	;	04h	= PS2_50
	;	05h	= PS2_60
	;	0bh	= PS1
	;	default	= PC_AT
	;
		mov	ah, es:[bx].SDT_subModel
		cmp	ah, 2
		jne	1$
		mov	al, SMT_PC_XT_286
		jmp	haveMT
1$:
		cmp	ah, 4
		jne	2$
		mov	al, SMT_PS2_50
		jmp	haveMT
2$:
		cmp	ah, 5
		jne	3$
		mov	al, SMT_PS2_60
		jmp	haveMT
3$:
		cmp	ah, 0bh
		jne	haveMT
		mov	al, SMT_PS1
		jmp	haveMT
IS20:
	;
	; Compare against return code (see below). If matches none of the known
	; values, we say the machine type is unknown.
	;
		mov	al, SMT_PC
		cmp	ah, 80h
		je	haveMT
		mov	al, SMT_PC_XT
		cmp	ah, 86h
		je	haveMT

		mov	al, SMT_UNKNOWN
		jmp	short haveMT
IS30:
	;
	; Call unrecognized. As a last resort, we use the error
	; code returned in AH:
	;	80h	=> PCjr and PC
	;	86h	=> PC/XT and early PC/AT
	; Try for the model byte at f000:fffe first, though
	;
		mov	bx, 0f000h
		mov	es, bx
		mov	bx, 0fffeh
		mov	di, es:[bx]
		and	di, 0ffh
		sub	di, ISM_MIN
		jl	IS20
		mov	al, cs:initSysModels[di]
haveMT:
		;
		; Store final machine type decision
		;
		mov	ds:sysMachineType, al
		;
		; If the thing's an AT, it's got a second 8259...this is done
		; to handle early AT's that don't support the 15h:c0h BIOS call
		; used above.
		;
		cmp	al, SMT_PC_AT
		jne	60$
		ornf	ds:[sysConfig], mask SCF_2ND_IC
60$:
	;
	; If BIOS thinks there's a coprocessor, we think there's a coprocessor.
	; 
		segmov	es, BIOS_DATA_SEG, ax
		test	es:[BIOS_EQUIPMENT], mask EC_MATH_COPROC
		jz	65$
		ornf	ds:[sysConfig], mask SCF_COPROC
65$:

else

	;------------------------------------------------------------------
	;		CUSTOM CPU/BIOS THINGS
	;

REDWOOD<	mov	ds:sysProcessorType, SPT_80286			>
REDWOOD<	mov	ds:sysMachineType, SMT_PC_AT			>
REDWOOD<	ornf	ds:sysConfig, mask SCF_2ND_IC			>

VG230<		mov	ds:[sysProcessorType], SPT_8086			>
VG230<		mov	ds:[sysMachineType], SMT_UNKNOWN		>

GULL<		mov	ds:[sysProcessorType], SPT_80386		>
GULL<		mov	ds:[sysMachineType], SMT_UNKNOWN		>
GULL<		ornf	ds:[sysConfig], mask SCF_2ND_IC or mask SCF_RTC	>



ifidn	HARDWARE_TYPE, <RESPG2>
		mov	ds:[sysProcessorType], SPT_80386
		mov	ds:[sysMachineType], SMT_UNKNOWN
		ornf	ds:[sysConfig], mask SCF_2ND_IC
endif



 ifdif HARDWARE_TYPE,<ZOOMER>
  ifdif HARDWARE_TYPE,<BULLET>
   ifdif HARDWARE_TYPE,<REDWOOD>
    ifdif HARDWARE_TYPE,<JEDI>
     ifdif HARDWARE_TYPE,<RESPONDER>
     ifdif HARDWARE_TYPE,<RESPG2>
      ifdif HARDWARE_TYPE,<GULLIVER>
       ifdif HARDWARE_TYPE,<PENELOPE>
	ifdif HARDWARE_TYPE,<DOVE>
	 .err	<you need to set up the processor and machine type for this architecture>
	endif ;DOVE
       endif ;PENELOPE
      endif ;GULLIVER
     endif ;RESPG2
     endif ;RESPONDER
    endif ;JEDI
   endif ;REDWOOD
  endif ;BULLET
 endif ;ZOOMER

endif
		;
		; Look for a /s flag, which declares we're under swat
		;
		mov	si, offset underSwatArg
		call	SysCheckArg
		jnc	70$
		;
		; Note that we're under swat
		;
		ornf	ds:sysConfig, mask SCF_UNDER_SWAT
70$:
		;
		; Look for a /log flag, which declares we're logging progress
		;
		mov	si, offset logFileArg
		call	SysCheckArg
		jnc	IS90
		;
		; Note that we're logging progress
		;
		ornf	ds:sysConfig, mask SCF_LOGGING
IS90:
	;
	; Look for our semaphore file that indicates if we crashed.
	;
		ornf	ds:[sysConfig], mask SCF_CRASHED	; assume yes
		mov	dx, offset sysSemaphoreFile
		mov	ax, (MSDOS_GET_SET_ATTRIBUTES shl 8) or 0
		int	21h
		jnc	interceptIRQs		; file exists => crashed before
	;
	; Semaphore file existeth not, so createth it please, m'lord.
	;
		andnf	ds:[sysConfig], not mask SCF_CRASHED
		
		mov	cx, FILE_ATTR_NORMAL
		mov	ah, MSDOS_CREATE_TRUNCATE
		int	21h
		jc	interceptIRQs		; DOS is weird, so no close
		
		; successfully created -- close down the file as we need it
		; no more.
		mov_trash	bx, ax
		mov	ah, MSDOS_CLOSE_FILE
		int	21h
interceptIRQs:
	;
	; Intercept all hardware interrupts so we can protect them from
	; context switching. The intercepts live in idata so we can store
	; the old vectors inside them, avoiding any segment juggling there.
	; They consist of a far call (5 bytes) a pushf (1 byte), a far call
	; to the old handler (5 bytes, giving an offset for the old vector
	; of the routine + 7), a far call (5 bytes) and an iret (1 byte), for
	; a total routine length of 17 bytes.
	; 
		mov	cx, offset FIRST_IRQ_INTERCEPT
		mov	ax, FIRST_IRQ_INTERCEPT_LEVEL
		mov	dx, LAST_IRQ_INTERCEPT_LEVEL

if HARDWARE_INT_CONTROL_8259
		test	ds:[sysConfig], mask SCF_2ND_IC
		jnz	interceptHardwareIRQs
		mov	dx, LAST_IRQ_INTERCEPT_LEVEL_ONE_IC
interceptHardwareIRQs:
endif

		mov	ds:[lastIntercept], dx
		mov	bx, ds
		mov	es, bx
interceptLoop:
		push	ax
		mov	di, cx
		add	di, IRQ_INTERCEPT_OLD_VECTOR_OFFSET
		call	SysCatchDeviceInterruptInternal	; nukes ax, di, bx
		mov	di, cx
		movdw	ds:[di+IRQ_INTERCEPT_DOS_VECTOR_OFFSET], \
			ds:[di+IRQ_INTERCEPT_OLD_VECTOR_OFFSET], \
			ax
		pop	ax
		mov	bx, ds
		inc	ax
		add	cx, IRQ_INTERCEPT_SIZE
		cmp	ax, dx
		jbe	interceptLoop

if not HARDWARE_INT_CONTROL_8259


endif

	;
	; Stop intercepting swat's interrupt, if we can find it and we're
	; running under the stub...The stub is running on either IRQ3 or IRQ4.
	; We determine which one by seeing which points to the space between
	; our PSP and kcode.
	; XXX: WON'T WORK IF STUB IS RELOCATED TO HIGHER MEMORY (e.g. in the
	; Dave board).
	;
		test	ds:[sysConfig], mask SCF_UNDER_SWAT
		jz	allocSysNotifyQueue
		
		

		mov	di, offset Irq3Intercept+IRQ_INTERCEPT_OLD_VECTOR_OFFSET
		mov	ax, 3
		mov	cx, ds:[di].segment
		cmp	cx, ds:[loaderVars].KLV_swatKcodePtr.segment
		je	replaceSwatIRQ

		mov	di, offset Irq4Intercept+IRQ_INTERCEPT_OLD_VECTOR_OFFSET
		mov	ax, 4
		mov	cx, ds:[di].segment
		cmp	cx, ds:[loaderVars].KLV_swatKcodePtr.segment
		jne	allocSysNotifyQueue
replaceSwatIRQ:
		call	SysResetDeviceInterruptInternal

allocSysNotifyQueue:
		call	GeodeAllocQueue
if	USE_MOUSE_TO_REPLY_TO_SYS_ERROR_BOX
		mov	ds:[errorMouseQueue], bx
else
		mov	ds:[errorKbdQueue], bx
endif
		
		mov	si, offset restartedArg
		call	SysCheckArg
		jnc	done
		ornf	ds:[sysConfig], mask SCF_RESTARTED
done:

if UTILITY_MAPPING_WINDOW
		call	InitUtilWindow
endif

SSP <	call	RestoreSingleStepping					>
		.leave
		ret
InitSys		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SysCheckArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the given argument is present on our command line

CALLED BY:	InitSys, LoadMemoryDriver
PASS:		cs:si	= null-terminated string for which to search.
			  must be matched exactly and preceded by a /
		ds	= idata
RETURN:		carry set if argument present
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SysCheckArg	proc	near	uses si, cx, di, es, ax
		.enter
		mov	es, ds:[loaderVars].KLV_pspSegment
		mov	di, offset PSP_cmdTail+1 ; Point ES:DI at command tail
		clr	cx
		mov	cl, es:[PSP_cmdTail]	; Fetch tail length
		jcxz	absent		; Handle empty tail
		cld			; Search forward
slashLoop:
		mov	al, '/'
		repne	scasb		; Search for next /
		jne	absent		; Found nothing

		push	si
compareLoop:
		lodsb	cs:		; fetch next source byte
		tst	al		; end of string?
		jz	checkEnd	; yes -- make sure at end of arg
		scasb
		loope	compareLoop
		jne	checkNext	; if mismatch, re-check current
					;  character
		tst	{char}cs:[si]	; ran out of tail, run out of arg too?
		pop	si
		jz	present		; yup -- arg is there.
absent:
		clc
done:
		.leave
		ret
checkNext:
	;
	; Got out of the loop w/o having reached the end of the arg. Recover
	; the address of the start of the arg and backpedal to check the
	; character that didn't match.
	; 
		pop	si
		dec	di
		inc	cx
		jmp	slashLoop
checkEnd:
	;
	; Reached the end of the match string, so make sure we reached the
	; end of the arg in the tail (i.e. the thing was an exact match).
	; It was an exact match if the next character after the arg in the
	; tail is whitespace, a slash (start of another argument), or a null.
	; 
		pop	si
		mov	al, es:[di]
		cmp	al, ' '
		je	present
		cmp	al, '\t'
		je	present
		cmp	al, '\r'
		je	present
		cmp	al, '/'
		je	present
		tst	al
		jnz	slashLoop
present:
		stc
		jmp	done
SysCheckArg	endp

