COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		math.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/26/92		Initial version.

DESCRIPTION:
	this file implements the interrupt handlers for the floating
	point interrupts for BorlandC and MicroSoftC

	the following interrupts are used:
	
			34h:	coprocessor instructions starting with d8h
			35h:	coprocessor instructions starting with d9h
			36h:	coprocessor instructions starting with dah
			37h:	coprocessor instructions starting with dbh
			38h:	coprocessor instructions starting with dch
			39h:	coprocessor instructions starting with ddh
			3ah:	coprocessor instructions starting with deh
			3bh:	coprocessor instructions starting with dfh
			3ch:	coporcessor instruction with segment override
			3dh:	standalong fwait instruction
			3eh:	BorlandC floating point shortcut routine

	the Math Library automatically sets up these interrupt handlers 
	with the assumption that any calls to these interruptss are indeed
	floating point operations (if not, we are hosed)


	THE FOLLOWING INSTRUCTIONS WILL NOT BE SUPPORTED BY THE
	BORLANDC/MICROSOFT FLOATING POINT INTERRUPT HANDLERS UNDER 
	PC/GEOS

	fincstp
	fdecstp
	fldenv
	fstenv
	fldcw
	fldsw
	fstsw
	fsave
	frstor
	fxam


	$Id: borlandc.asm,v 1.1 97/04/05 01:22:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include library.def

;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the borlandC lib is going to
;       be used in a system where all geodes (or most, at any rate)
;       are to be executed out of ROM.  
;------------------------------------------------------------------------------
ifndef FULL_EXECUTE_IN_PLACE
        FULL_EXECUTE_IN_PLACE           equ     FALSE
endif

;------------------------------------------------------------------------------
;  The .GP file only understands defined/not defined;
;  it can not deal with expression evaluation.
;  Thus, for the TRUE/FALSE conditionals, we define
;  GP symbols that _only_ get defined when the
;  condition is true.
;-----------------------------------------------------------------------------
if      FULL_EXECUTE_IN_PLACE
        GP_FULL_EXECUTE_IN_PLACE        equ     TRUE
endif

if FULL_EXECUTE_IN_PLACE
include Internal/xip.def
include ec.def
include assert.def
include	heap.def
endif

include resource.def
include Internal/interrup.def
UseLib	ui.def
UseLib	math.def



; this structure is for getting at register values passed in
; from there position on the stack where they are saved
InterruptRegistersOnStack	struct
	IROS_AX		word
	IROS_BX		word
	IROS_CX		word
	IROS_DX		word
	IROS_DI		word
	IROS_SI		word
	IROS_DS		word
	IROS_ES		word
	IROS_BP		word
	IROS_fret	fptr.far
	IROS_flags	CPUFlags
InterruptRegistersOnStack	end
	
; mod is either 0, 1, 2 or 3
;	0 = no displacment	; unless r/m == 6, 16 bits displacement
;	1 = 8 bits of displacement
;	2 = 16 bits of displacement
;	3 = register used rather than memory (no displacement)
GetMod	MACRO data, mod
	mov	mod, data
	mov	cl, 6
	shr	mod, cl
endm
		
	; dx = flag for segment override
	; ax = opcode info, cx = disp, we might need bp, bx, si or di
	; depending on the r/m info in ax so restore them from the stack
GET_EA	MACRO
	mov	ah, bl			; save mod info
	push	bp
	push	dx			; save flag for override on stack
	mov	bx, ss:[bp].IROS_BX
	mov	di, ss:[bp].IROS_DI
	mov	si, ss:[bp].IROS_SI
	mov	bp, ss:[bp].IROS_BP
	call	GetEA			; get the effective address in ds:dx
	pop	cx			; retrieve flags for override in cx
	pop	bp
	call	SetupDSForEA
endm

GetInstruction MACRO	reg
	and	reg, 00111000b
endm

GetRegister	MACRO	reg
	and	reg, 00000111b
endm

InterruptInitCode	segment resource

; place to save old interrupt handlers

if FULL_EXECUTE_IN_PLACE
udata	segment
endif
	OldHandlers	fptr 	11	dup(?)
if FULL_EXECUTE_IN_PLACE
udata	ends
endif

; a useful table for saving and restoring all the
; interrupt vetors at startup and shutdown respectively

	MyHandlers	fptr \
		Interrupt34Handler,
		Interrupt35Handler,
		Interrupt36Handler,
		Interrupt37Handler,
		Interrupt38Handler,
		Interrupt39Handler,
		Interrupt3aHandler,
		Interrupt3bHandler,
		Interrupt3cHandler,
		Interrupt3dHandler,
		Interrupt3eHandler

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BorlandcLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	installs and uninstalls software interrupts for handling the
		floating points interrupts

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
BorlandcLibraryEntry	proc	far
	uses	es, bx, cx, ax, si
	.enter

	mov	ax, 34h				; first interrupt
	mov	cx, 11				; # of consecutive interrupts
	cmp	di, LCT_ATTACH			;start up?
	je	installInt
	cmp	di, LCT_DETACH			;shut down?
	je	uninstallInt
done:
	clc
	.leave
	ret

	; Install out interrupt vectors
installInt:
	mov	si, offset MyHandlers
	mov	di, offset OldHandlers
NOFXIP<	segmov	es, cs							>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefES			;es = dgroup		>

installLoop:
	push	ax, cx, di
	mov	bx, cs:[si].segment		
	mov	cx, cs:[si].offset		; bx:cx <- fptr of my handler
	call	SysCatchInterrupt		; install my handler
	pop	ax, cx, di
	add	si, size fptr			; cs:si <- next new handler
	add	di, size fptr			; es:di <- next place to store
	inc	ax
	loop	installLoop			; old interrupt handler
	jmp	done	

	; Re-install the old interrupt vectors
uninstallInt:
	mov	di, offset OldHandlers
NOFXIP<	segmov	es, cs							>
FXIP<	mov	bx, handle dgroup					>
FXIP<	call	MemDerefES			;es = dgroup		>

uninstallLoop:
	push	ax, cx	
	call	SysResetInterrupt		; restore old handler
	pop	ax, cx
	add	si, size fptr	
	inc	ax
	loop	uninstallLoop
	jmp	done
BorlandcLibraryEntry	endp

ForceRef BorlandcLibraryEntry

InterruptInitCode	ends

FloatMovableCode	segment resource


DfFunctionTable nptr \
	FILD_word,
	FloatNullFunctionNear,
	FIST_word,
	FISTP_word,
	FloatNullFunctionNear,	; don't support FBLD
	FILD_dword,		; this is realy for qwords, but gets really
				; only gets used for unsigned dwords in C
	FloatNullFunctionNear,	; FBSTP not supported
	FloatNullFunctionNear	; don't support 64 bit intergers

D8FunctionTable fptr \
	FloatAdd,
	FloatMultiply,
	FloatCompAndDropOne,
	FloatCompAndDrop,
	FloatSub,
	FloatSubR,
	FloatDivide,
	FloatDivideR

D9FunctionTable fptr \
	FloatNegate,
	FloatAbs,
	FloatNullFunction,	; reserved
	FloatNullFunction,	; reserved
	FloatEq0,	
	FloatNullFunction,	; fxam unsupported
	FloatNullFunction,	; reserved
	FloatNullFunction,	; reserved
	Float1,
	FloatLg10,
	FloatLgE,		; DOES NOT ACTUALLY EXIST in Math library
	FloatPi,
	FloatLog2,		; DOES NOT ACTUALLY EXIST in Math library
	FloatLn2,
	Float0,
	FloatNullFunction,	; reserved
	Float2XM1,		; DOES NOT ACTUALLY EXIST in Math library
	FloatYL2X,		; DOES NOT ACTUALLY EXIST in Math library
	FloatPTan,		; DOES NOT ACTUALLY EXIST in Math library
	FloatPArcTan,		; DOES NOT ACTUALLY EXIST in Math library
	FloatIntFrac,
	FloatNullFunction,	; reserved
	FloatNullFunction,	; fdecstp - not supported
	FloatNullFunction,	; fincstp - not supported
	FloatMod,	
	FloatYL2XP1,		; DOES NOT ACTUALLY EXIST in Math library
	FloatSqrt,
	FloatNullFunction,	; reserved
	FloatRound,		
	FloatScale,		; DOES NOT ACTUALLY EXIST in Math library
	FloatNullFunction	; reserved



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRoutineFromDfFunctionTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call a routine form the DfFunctionTable array of fptrs

CALLED BY:	GLOBAL

PASS:		al = opcode information on which routine to call

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/28/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallRoutineFromDfFunctionTable	proc	far
	uses	bx
	.enter
	GetInstruction al
					; we need al >> 3 then * 2 so
	shr	al			; just shift it right twice
	shr	al
	mov	bl, al
	clr	bh
	call	cs:[DfFunctionTable][bx]
	.leave
	ret
CallRoutineFromDfFunctionTable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRoutineFromD8FunctionTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call a routine form the D8FunctionTable array of fptrs

CALLED BY:	GLOBAL

PASS:		al = opcode information on which routine to call

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/28/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallRoutineFromD8FunctionTable	proc	far
	uses	bx, ax
	.enter
	; for some reason FloatSub/FloatSubR and FloatDiv/FloatDivR are
	; reversed in the table when using registers rather than memory
	; so we need to flip the low bit in the opcode for those four
	; values...sigh
	; if the upper two bigs are set then is a register instruction
	; and the third bit tells us whether its an SUB or DIV instruction
	; so we can just do this test to determine what to do
	cmp	al, 11100000b
	jb	gotOpcode
	xor	al, 00001000b	; flip low bit of opcode
gotOpcode:	

	GetInstruction al
	shr	al		; we really need (al >> 3) * size fptr
				; which happens to equal al >> 1
	mov	bl, al
	clr	bh
	mov	ax, cs:[D8FunctionTable][bx].offset
	mov	bx, cs:[D8FunctionTable][bx].handle
	call	ProcCallFixedOrMovable
	.leave
	ret
CallRoutineFromD8FunctionTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallRoutineFromD9FunctionTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call a routine from the D9 table of fptrs

CALLED BY:	Int 34h handler

PASS:		al = index in table

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/26/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CallRoutineFromD9FunctionTable	proc	far
	uses	bx
	.enter
	shl	al
	shl	al
	clr	ah
	mov	bx, ax
	mov	ax, cs:[D9FunctionTable][bx].offset
	mov	bx, cs:[D9FunctionTable][bx].handle
	call	ProcCallFixedOrMovable
	.leave
	ret
CallRoutineFromD9FunctionTable	endp


FloatNullFunction	proc	far
	ret
FloatNullFunction	endp

FloatNullFunctionNear	proc	near
	ret
FloatNullFunctionNear	endp

FILD_word	proc	near
	mov	si, dx
	mov	ax, ds:[si]
	call	FloatWordToFloat
	ret
FILD_word	endp

FIST_word	proc 	near
	mov	si, dx
	call	FloatTrunc
	call	FloatFloatToDword
	mov	ds:[si], ax		; lose top 16 bits if > 2^16
	ret
FIST_word	endp

FISTP_word	proc	near
	mov	si, dx
	call	FloatTrunc
	call	FloatFloatToDword
	mov	ds:[si], ax		; lose top 16 bits if > 2^16
	call	FloatDrop
	ret
FISTP_word	endp

FILD_dword	proc	near
	mov	si, dx
	lodsw			; dx:ax = dword
	mov	dx, ds:[si]
	call	FloatDwordToFloat
	ret
FILD_dword	endp

FloatCompAndDropOne	proc	far
	call	FloatComp
	call	FloatDrop
	ret
FloatCompAndDropOne	endp


FloatDivideR	proc	far
	call	FloatSwap
	call	FloatDivide
	ret
FloatDivideR	endp

FloatSubR	proc	far
	call	FloatSwap
	call	FloatSub
	ret
FloatSubR	endp

FloatLgE	proc	far
	call	Float1
	call	FloatExp
	call	FloatLg
	ret
FloatLgE	endp

FloatLog2	proc	far
	call	Float2
	call	FloatLog
	ret
FloatLog2	endp

Float2XM1	proc	far
	call	FloatLn2
	call	FloatMultiply
	call	FloatExp
	call	Float1
	call	FloatSub
	ret
Float2XM1	endp

FloatYL2X	proc	far
	call	FloatLog
	call	FloatMultiply
	ret
FloatYL2X	endp

FloatYL2XP1	proc	far
	call	FloatLog
	call	FloatMultiply
	call	Float1
	call	FloatAdd
	ret
FloatYL2XP1	endp

FloatPTan	proc	far
	call	FloatTan
	call	Float1
	ret
FloatPTan	endp

FloatPArcTan	proc	far
	call	FloatArcTan
	call	Float1
	ret
FloatPArcTan	endp

FloatScale	proc	far
	call	FloatSwap
	call	FloatLn2
	call	FloatMultiply
	call	FloatExp
	call	FloatMultiply
	ret
FloatScale	endp


SetGeosConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		F_FTOL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert a float to a 32bit integer

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	ax, dx

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/18/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	public F_FTOL@
F_FTOL@	proc	far
	call	FloatTrunc
	call	FloatFloatToDword
	ret
F_FTOL@	endp

if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwflret
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	puts the top number on the FP stackinto a 64 bit
		location

CALLED BY:	INTERNAL

PASS:		number on top of FP stack

RETURN:		64 bit float in location passed in

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
		Pop of top of FP stack, convert from 80 bits to 64 bit float
		and put into passed in memory location

KNOWN BUGS/SIDEFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_mwflret	proc	near	answer:fptr
	uses	es, di
	.enter
	les	di, ss:[answer]
	call	FloatGeos80ToIEEE64
	.leave
	ret
_mwflret	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_trig_common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code to implement the various trigonometric functions
		in this file

CALLED BY:	sin, cos, sinh, cosh, tan, tanh, ...
PASS:		each of these routines receives on the stack:
			sp	-> retf
				   arg (double)
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		First set up the regular stack
		Push the operand
		Call our caller back to do what it needs to do
		the result is left on the top of the FPU stack
		return, clearing the stack

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetDefaultConvention

_trig_common	proc	near 	:fptr.far,	; caller's return address
				arg:IEEE64
		uses	ds, si
		.enter
	;
	; Push the passed 64-bit float onto the FPU stack
	; 
		segmov	ds, ss
		lea	si, ss:[arg]
		call	FloatIEEE64ToGeos80
	;
	; Call our caller back to have it do what it has to do.
	; 
		call	{nptr.far}ss:[bp+2]
		.leave
	;
	; Clear the return address to our caller
	; 
		inc	sp
		inc	sp
	;
	; And return to our caller's caller, clearing the stack of its args
	; 
		retf	@ArgSize-4
_trig_common	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_float_2_arg_common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code to implement the various trigonometric functions
		in this file
		
		Same as _trig_common, but with 2 arguments on the stack

CALLED BY:	sin, cos, sinh, cosh, tan, tanh, ...
PASS:		each of these routines receives on the stack:
			sp	-> retf
				   arg2 (double)
				   arg  (double)

		(Remember, PASCAL notation means args are pushed left to
		right, so the second arg will be nearest to top of stack.)
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		First set up the regular stack
		Push the operand
		Call our caller back to do what it needs to do
		the result is left on the top of the FPU stack
		return, clearing the stack

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	2000/4/19	Initial revision
    mgroeb	2000/5/12	Merged cruppel's changes
	dhunter	7/16/2000	Fixup arg order to make sense

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_float_2_arg_common proc	near 	:fptr.far, ; caller's return address
				arg2:IEEE64,
				arg:IEEE64
		uses	ds, si
		.enter
	;
	; Push the passed 64-bit float onto the FPU stack
	; 
		segmov	ds, ss
                lea     si, ss:[arg]
		call	FloatIEEE64ToGeos80
	;
	; Push the passed 64-bit float onto the FPU stack
	; 
		segmov	ds, ss
                lea     si, ss:[arg2]
		call	FloatIEEE64ToGeos80
	;
	; Call our caller back to have it do what it has to do.
	; 
		call	{nptr.far}ss:[bp+2]
		.leave
	;
	; Clear the return address to our caller
	; 
		inc	sp
		inc	sp
	;
	; And return to our caller's caller, clearing the stack of its args
	; 
		retf	@ArgSize-4
_float_2_arg_common	endp


; Same as _trig_common, but with 0 arguments on the stack

_trig_common0	proc	near 	return:fptr.far	; caller's return address
		uses	ds, si
		.enter

	;
	; Call our caller back to have it do what it has to do.
	; 
		call	{nptr.far}ss:[bp+2]
		.leave
	;
	; Clear the return address to our caller
	; 
		inc	sp
		inc	sp
	;
	; And return to our caller's caller, clearing the stack of its args
	; 
		retf	@ArgSize-4
_trig_common0	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		sin of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SIN	proc	far 
	call	_trig_common
	call	FloatSin
	retn
SIN	endp
	public	SIN

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		cos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		cos of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COS	proc	far
	call	_trig_common
	call	FloatCos
	retn
COS	endp
	public	COS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		tan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		tan of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TAN	proc	far
	call	_trig_common
	call	FloatTan
	retn
TAN	endp
	public	TAN

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		cosh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		cosh of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COSH	proc	far
	call	_trig_common
	call	FloatCosh
	retn
COSH	endp
	public	COSH

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sinh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		sinh of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SINH	proc	far
	call	_trig_common
	call	FloatSinh
	retn
SINH	endp
	public	SINH

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		tanh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		tanh of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TANH	proc	far
	call	_trig_common
	call	FloatTanh
	retn
TANH	endp
	public	TANH

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		atan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		atan of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ATAN	proc	far
	call	_trig_common
	call	FloatArcTan
	retn
ATAN	endp
	public	ATAN

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		asin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		asin of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ASIN	proc	far
	call	_trig_common
	call	FloatArcSin
	retn
ASIN	endp
	public	ASIN

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		acos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		acos of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ACOS	proc	far
	call	_trig_common
	call	FloatArcCos
	retn
ACOS	endp
	public	ACOS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		atanh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		atanh of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ATANH	proc	far
	call	_trig_common
	call	FloatArcTanh
	retn
ATANH	endp
	public	ATANH

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		asinh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		asinh of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ASINH	proc	far
	call	_trig_common
	call	FloatArcSinh
	retn
ASINH	endp
	public	ASINH

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		acosh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		asinh of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ACOSH	proc	far
	call	_trig_common
	call	FloatArcCosh
	retn
ACOSH	endp
	public	ACOSH

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		log
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		log of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LOG	proc	far
	call	_trig_common
	call	FloatLog
	retn
LOG	endp
	public	LOG

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ln
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		ln of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LN	proc	far
	call	_trig_common
	call	FloatLn
	retn
LN	endp
	public	LN

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		sqrt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		sqrt of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 9/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SQRT	proc	far
	call	_trig_common
	call	FloatSqrt
	retn
SQRT	endp
	public	SQRT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		atan2, floor, fabs, exp, frand, fmod, pow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Glue for various Ansi routines not supported before 3/99

CALLED BY:	GLOBAL

PASS:		routines with _trig_common are passed one float argument
			on the stack; with _trig_common2, two floats; with 
			_trig_common0, nothing.

RETURN:		float result

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/3/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FABS_C	proc	far
	call	_trig_common
	call	FloatAbs
	retn
FABS_C	endp
	public	FABS_C


FLOOR	proc	far
	call	_trig_common
	call	FloatInt
	retn
FLOOR	endp
	public	FLOOR

EXP	proc	far
	call	_trig_common
	call	FloatExp
	retn
EXP	endp
	public	EXP

FRAND	proc	far
	call	_trig_common0
	call	FloatRandom
	retn
FRAND	endp
	public	FRAND

FMOD	proc	far
	call	_float_2_arg_common
	call	FloatMod
	retn
FMOD	endp
	public	FMOD

ATAN2	proc	far
	call	_float_2_arg_common
	call	FloatArcTan2
	retn
ATAN2	endp
	public	ATAN2

LOG10	proc	far
	call	_trig_common
	call	FloatLog
	retn
LOG10	endp
	public	LOG10


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		POW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes an ieee64 number off the stack and returns the
		cos of it in the return adress passed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	2000/4/19	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
POW	proc	far
	call	_float_2_arg_common
	call	FloatExponential
	retn
POW	endp
	public	POW


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupDSForEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ds = effective address segment

CALLED BY:	GLOBAL

PASS:		al = mod r/m byte
		cl = data for segment override
		ch = 1 for segment override, 0 for normal
RETURN:		ds = correct segment

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/11/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupDSForEA	proc	far
	.enter
	tst	ch	
	jz	doNormal
	; override/escape byte looks like such (cl)
	; ss011xxx where ss = 
	;			00 -> DS
	; 			01 -> SS
	;			10 -> CS
	; 			11 -> ES
	test	cl, 10000000b	
	jz	doDSorSS
	test	cl, 01000000b
	jz	doCS
	; ok, its ES
	segmov	ds, es, cx
	jmp	done
doCS:
	segmov	ds, cs, cx
	jmp	done
doDSorSS:
	test	cl, 01000000b
	jz	done
	segmov	ds, ss
	jmp	done
doNormal:
	push	ax		; save value on stack
	and	ax, 11000111b	; turn of reg bits, leaving mod and r/m bits
				; to test for special case of ds:[disp]
	cmp	al, 6		; direct addressing?
	pop	ax		; restore ax
	je	done		; yes -- uses DS
	test	al, 2		; only 2, 3 and 6 use SS; all have b1 set
	jz	done
	test	al, 101b
	jz	useSS		; => is 2 (must check as 0 has even parity)
	jpe	done		; => is 7, so no go, else must be 3 or 6
useSS:
	segmov	ds, ss
done:
	.leave
	ret
SetupDSForEA	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the effective address

CALLED BY:	GLOBAL

PASS:		bp, bx, si, di  all same as they were when the interrupt
				was called
		cx = displacement
		al = r/m info (low 3 bits)

RETURN:		dx = effective address

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/26/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetEA	proc	far
	uses	ax
	.enter
	mov	dx, cx		; dx will be final displacement
	mov	cx, bx		; save bx value so we can use
				; bx for indirection
	GetRegister	al
	mov	bl, al
	clr	bh
	shl	bx
	jmp	cs:[fpRegisters][bx]
reg0:
	add	dx, cx		; r/m == 1, EA = ds:[bx][si][disp]
	add	dx, si
	jmp	done
reg1:
	add	dx, cx		; r/m == 2, EA = ds:[bx][di][disp]
	add	dx, di
	jmp	done
reg2:
	add	dx, bp		; r/m == 3, EA = ds:[bp][di][disp]
	add	dx, si
	jmp	done
reg3:
	add	dx, bp		; r/m == 4, EA = ds:[bp][di][disp]
	add	dx, di
	jmp	done
reg4:
	add	dx, si		; r/m == 4, EA = ds:[si][disp]
	jmp	done
reg5:
	add	dx, di		; r/m == 5, EA = ds:[di][disp]
	jmp	done
reg6:
	tst	ah
	jz	done		; r/m == 6 AND mod == 0, EA = ds:[disp]
	add	dx, bp		; r/m == 6, mod != 0, EA = ds:[bp][disp]
	jmp	done
reg7:
	add	dx, cx		; r/m == 7, EA = ds:[bx][disp]
done:
	.leave
	ret
fpRegisters	nptr	 reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7
GetEA	endp



FloatMovableCode	ends


FloatInterruptCode segment resource 


; MACRO to start up an interrupt handler (same for all of them)
InterruptStart	MACRO
	INT_ON			; let higher proiority interrupts through

	; push the registers in the order dictated by our structure.
	
	push	bp, es, ds, si, di, dx, cx, bx, ax

	CheckHack <IROS_AX eq 0 and IROS_BX eq 2 and IROS_CX eq 4 and \
		   IROS_DX eq 6 and IROS_DI eq 8 and IROS_SI eq 10 and \
		   IROS_DS eq 12 and IROS_ES eq 14 and IROS_BP eq 16>

	mov	bp, sp		; ss:bp <- InterruptRegistersOnStack
	
	lds	si, ss:[bp].IROS_fret	; ds:si <- stuff after interrupt

endm

InterruptEnd	MACRO
	mov	sp, bp		; make sure we're back at the
				;  InterruptRegistersOnStack

	CheckHack <IROS_AX eq 0 and IROS_BX eq 2 and IROS_CX eq 4 and \
		   IROS_DX eq 6 and IROS_DI eq 8 and IROS_SI eq 10 and \
		   IROS_DS eq 12 and IROS_ES eq 14 and IROS_BP eq 16>

	pop	bp, es, ds, si, di, dx, cx, bx, ax

	iret
endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InterruptCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code for the interrupt handlers

CALLED BY:	GLOBAL

PASS:		ss:bp = InterruptRegistersOnStack
		ds:si = byte past interrupt (the ModRM byte)

RETURN:		bl = mod value (0, 1, 2 or 3)
		cx = displacement

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InterruptCommon	proc	far
	.enter
	lodsb	; al = ds:[si]

	; from the mod info in the last byte, we can figure out how many
	; more bytes are in the opcode
	GetMod	al, bl		; bl = mod info from al	(destroys cl)
	mov	cx, ax		; save unmodified modrm byte in cx
	cmp	bl, 3
	je	adjustRet

	tst	bl
	jnz	fetchDisp	; go fetch byte or word displacement

	; if the mod == 0, and r/m == 6 we have a special case

	and	al, 00000111b		
	cmp	al, 00000110b
	je	getWordDisp	; => is direct, so need word displacement
	clr	ax		; else has 0 displacement, and we're set
	jmp	parseOpCode	

fetchDisp:
	cmp	bl, 1		; 1-byte displacement?
	jne	getWordDisp	; no

	lodsb	 			; al = byte disp
	cbw				; sign extend to a word disp
	jmp	parseOpCode		

getWordDisp:
	lodsw				; get word disp. i hope this is
					; the right byte order
parseOpCode:
	xchg	ax, cx			; cx = disp, ax = opcode info

adjustRet:
	mov	ss:[bp].IROS_fret.offset, si
	mov	ds, ss:[bp].IROS_DS	; restore ds to what it was before
					;  the interrupt

	.leave
	ret
InterruptCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt34Common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	guts of int34 handler

CALLED BY:	GLOBAL

PASS:		ds:si = rest of the opcode

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/25/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt34Common	proc	near
	call	InterruptCommon		; bl = mod, cx = displacement
	cmp	bl, 3
	je	doReg

	; ok, we have and instruction of the form:
	;	d8 MODXXXR/M
	GET_EA			; ds:dx <- effective address

	mov	si, dx
	push	ax
	mov	dx, ds:[si].high
	mov	ax, ds:[si].low
	call	FloatIEEE32ToGeos80
	pop	ax
	call	CallRoutineFromD8FunctionTable
	jmp	done	
doReg:
	push	ax
	mov	bl, al
	GetRegister	bl
	call	FloatPick
	pop	ax
	call	CallRoutineFromD8FunctionTable		
done:		
	ret
Interrupt34Common	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt34Handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handles floating point opcodes starting with d8h

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt34Handler	proc	far
	InterruptStart	
	mov	dx, 0		; no segment override
	call	Interrupt34Common
	InterruptEnd
Interrupt34Handler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt35Common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	guts of interrupt 35 handler

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/25/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt35Common	proc	near
	call	InterruptCommon
	cmp	bl, 3
	je	doMod3

	GET_EA			; ds:dx <- effective address
	GetInstruction	al	
	jnz	tryFST
	; if zero, the we have a FLD {dword}ds:[dx]
	mov	si, dx
	mov	dx, ds:[si].high
	mov	ax, ds:[si].low		; dx:ax = 32 bit float
	call	FloatIEEE32ToGeos80	; push 32bit float onto fp stack
	jmp	done
tryFST:
	cmp	al, 00010000b		; if equal we have a FST
	jne	tryFSTP
	mov	di, dx
	call	FloatGeos80ToIEEE32	;  dx:ax = ST
	mov	ds:[di].high, dx
	mov	ds:[di].low, ax
	call	FloatIEEE32ToGeos80

	jmp	done
tryFSTP:
	cmp	al, 00011000b		; if equal, we have FSTP
	jne	done			; everything else unsupported
	mov	di, dx
	call	FloatGeos80ToIEEE32	;  dx:ax = ST
	mov	ds:[di].high, dx
	mov	ds:[di].low, ax
	jmp	done
doMod3:
	test	al, 00100000b	; check the third bit
	jz	doRegOperation
	; the third bit was 1, so just look up the instruction in a table
	; based on the last 5 bits
	and	al, 00011111b	; get the last 5 bits
	call	CallRoutineFromD9FunctionTable
	jmp	done 
doRegOperation:
	clr	bx
	mov	bl, al
	GetRegister bl
	and	al, 00011111b		; get last 5 bits for instruction
	cmp	al, 00011000b		; FLD ST(i)
	jne	tryFXCH
	; ok, do a FLD ST(i)
	call	FloatPick
	jmp	done
tryFXCH:
	; special case FXCH st(1) which is the most useful, that just swaps
	; the top two elements
	cmp	al, 00011001b		; FXCH ST(i)
	jne	done
	cmp	bl, 1
	je	doEasySwap

	; if its not the easy case, we must Roll up the next element to the
	; the top, swap it with the old top and roll the old top back down
	clr	bh
	call	FloatRoll
	call	FloatSwap
	call	FloatRollDown
	jmp	done
doEasySwap:
	call	FloatSwap
done:
	ret
Interrupt35Common	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt35Handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handles coprocessor opcodes starting with d8h

CALLED BY:	int 35h (BorlandC and MicroSoftC programs)

PASS:		SS:SP points to data on the stack

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:
		we must figure out how long the op code really is from context
		and add the correct value to the return address on the stack
		so we return to the next instruction

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/26/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt35Handler	proc	far
	InterruptStart
	mov	dx, 0		; no segment override
	call	Interrupt35Common
	InterruptEnd
Interrupt35Handler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt36Common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	guts of interrupt 36 handler

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/25/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt36Common	proc	near
	call	InterruptCommon
	cmp	bl, 3		; mod == 3 are all reserved instructions
	je	done		

	; ok, we have and instruction of the form:
	;	da MODXXXR/M
	GET_EA			; ds:dx <- effective address
	push	ax
	mov	di, dx
	mov	ax, ds:[di].low
	mov	dx, ds:[di].high
	call	FloatDwordToFloat
	pop	ax
	call	CallRoutineFromD8FunctionTable
done:
	ret
Interrupt36Common	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt36Handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle opcodes starting with dah

CALLED BY:	GLOBAL

CALLED BY:	int 36h (BorlandC and MicroSoftC programs)

PASS:		SS:SP points to data on the stack

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt36Handler	proc	far
	InterruptStart		
	mov	dx, 0		; no segment override
	call	Interrupt36Common
	InterruptEnd
Interrupt36Handler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt37Common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	guts of interrupt 37 handler

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/25/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt37Common	proc	near
	call	InterruptCommon
	cmp	bl, 3	
	je	done			; unsupport stuff

	; ok, we have and instruction of the form:
	;	db MODXXXR/M
	GET_EA			; ds:dx <- effective address

	GetInstruction al
	jne	tryFIST			; if zero, we have a FILD int32
	mov	si, dx
	mov	ax, ds:[si].low
	mov	dx, ds:[si].high
	call	FloatDwordToFloat
	jmp	done
tryFIST:
	cmp	al, 00010000b		; test for FIST
	je	doFIST
	cmp	al, 00011000b		; test for FISTP
	jne	tryFLD
doFIST:
	push	ax	
	mov	di, dx
	segmov	es, ds			; es:di = destination
	call	FloatTrunc
	call	FloatFloatToDword	; dx:ax = int32
	mov	es:[di].high, dx
	mov	es:[di].low, ax
	pop	ax
	cmp	al, 00011000b
	jne	done
	call	FloatDrop
	jmp	done
tryFLD:
	cmp	al, 00101000b
	jne	tryFSTP
	mov	si, dx
	call	FloatPushNumber
	jmp	done
tryFSTP:
	cmp	al, 00111000b
	jne	done			; must be a reserved instruction
	mov	di, dx
	push	es
	segmov	es, ds
	call	FloatPopNumber
	pop	es
done:
	ret
Interrupt37Common	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt37Handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handles opcodes starting with dbh

CALLED BY:	GLOBAL

CALLED BY:	int 37h (BorlandC and MicroSoftC programs)

PASS:		SS:SP points to data on the stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt37Handler	proc	far
	InterruptStart
	mov	dx, 0		; no segment override
	call	Interrupt37Common
	InterruptEnd
Interrupt37Handler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatOpNotST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do an operation to a stack element that's not neccessarily
		the top element		

CALLED BY:	GLOBAL

PASS:		al = register info

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/28/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatOpNotST	proc	far
	.enter
	mov	bl, al
	GetRegister bl
	clr	bh
	push	bx
	push	ax
	cmp	bl, 1
	; since our stuff always works off the top of the stack, its tricky
	; to do a FADD st(i), st, since we want to save the value in st(i)
	; and not lose the original st value, so we must do some convalutions
	; to get it to work
	je	doEasySwap	
	call	FloatRoll
	call	FloatSwap
	call	FloatRollDown
	call	doneSwap
doEasySwap:
	call	FloatSwap
doneSwap:
	; the hardware stack starts from 0, our stack starts from 1 so	
	; increment bx for our stuff
	inc	bx		
	call	FloatPick
	pop	ax
	call	CallRoutineFromD8FunctionTable		
	; now swap answer into correct place in the stack
	pop	bx
	cmp	bl, 1
	je	doEasySwapAgain
	call	FloatRoll
	call	FloatSwap
	call	FloatRollDown
	jmp	done
doEasySwapAgain:
	call	FloatSwap
done:
	.leave
	ret
FloatOpNotST	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt38Common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	guts of Interrupt 38 handler

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/25/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt38Common	proc	near
	call	InterruptCommon
	cmp	bl, 3		; mod == 3 are all reserved instructions
	je	doRegOp		; from a reg, not memory

	; ok, we have and instruction of the form:
	;	dc MODXXXR/M
	push	ax
	GET_EA			; ds:dx <- effective address
	mov	si, dx
	call	FloatIEEE64ToGeos80
	pop	ax
	call	CallRoutineFromD8FunctionTable
	jmp	done
doRegOp:
	call	FloatOpNotST
done:
	ret
Interrupt38Common	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt38Handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handles opcode starting with dch

CALLED BY:	GLOBAL

CALLED BY:	int 38h (BorlandC and MicroSoftC programs)

PASS:		SS:SP points to data on the stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt38Handler	proc	far
	InterruptStart		
	mov	dx, 0		; no segment override
	call	Interrupt38Common
	InterruptEnd
Interrupt38Handler	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt39Common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	guts of interrupt 39 Handler

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/25/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt39Common	proc	near
	.enter

	call	InterruptCommon
	cmp	bl, 3
	je	doRegOp

	; ok, we have and instruction of the form:
	;	dd MODXXXR/M
	GET_EA			; ds:dx <- effective address
	mov	si, dx			; ds:si = effective address

	GetInstruction al		; if zero, its an FLD
	jnz	tryFST
	call	FloatIEEE64ToGeos80
	jmp	done
tryFST:
	test	al, 00100000b		; these are unsupported
	jnz	doSpecial		; chip status stuff
	; now we have wither an FST, or and FSTP with the 64 bit operand
	; if its not FSTP, then Dup it before popping it off
	test	al, 00001000b	
	jnz	doFST
	call	FloatDup
doFST:
	push	es
	segmov	es, ds
	mov	di, dx
	call	FloatGeos80ToIEEE64
	pop	es
	jmp	done
doSpecial:
	; handle FSTSW at least
	cmp	al, 00111000b			; FSTSW opcode
	jne	done
	call	FloatFSTSW		; ax = status word
	mov	ds:[si], ax		; store status word in EA
	jmp	done
doRegOp:
	mov	bl, al
	GetInstruction	al
	cmp	al, 00010000b	
	je	doRegFST
	cmp	al, 00011000b
	jne	done			; the rest are reserved
doRegFST:
	clr	bh
	GetRegister	bl
	tst	bl	; if its zero then we just pop the thing
	jnz	doRoll
	call	FloatDrop
	jmp	done
doRoll:
	call	FloatRoll	; first get the number to be overwritten
				; out of there
	call	FloatDrop
	test	al, 00001000b		
	jnz	afterDup
	call	FloatDup
	inc	bl
afterDup:
	call	FloatRollDown				
done:

	.leave
	ret
Interrupt39Common	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt39Handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handles opcodes atarting with ddh

CALLED BY:	int 39h (BorlandC and MicroSoftC programs)

PASS:		SS:SP points to data on the stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt39Handler	proc	far
	InterruptStart
	mov	dx, 0		; no segment override
	call	Interrupt39Common
	InterruptEnd
Interrupt39Handler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt3aCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	guts of 3a handler

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/25/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt3aCommon	proc	near

	call	InterruptCommon
	cmp	bl, 3
	je	doRegOp
	; ok, we have and instruction of the form:
	;	de MODXXXR/M
	GET_EA			; ds:dx <- effective address
	push	ax
	mov	si, dx
	mov	ax, ds:[si]
	call	FloatWordToFloat
	pop	ax
	call	CallRoutineFromD8FunctionTable
	jmp	done	
doRegOp:
	cmp	al, 0d9h		; FCOMPP special case
	jne	doNormalOP
	call	FloatSwap
	call	FloatCompAndDrop
	jmp	done
doNormalOP:
	call	FloatOpNotST
	call	FloatDrop
done:
	ret
Interrupt3aCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt3aHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handles opcodes starting with deh

CALLED BY:	GLOBAL

CALLED BY:	int 3ah (BorlandC and MicroSoftC programs)

PASS:		SS:SP points to data on the stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt3aHandler	proc	far
	InterruptStart
	mov	dx, 0		; no segment override
	call	Interrupt3aCommon
	InterruptEnd
Interrupt3aHandler	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt3bCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	guts of interrupt 3b handler

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/25/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt3bCommon	proc	near

	call	InterruptCommon
	cmp	bl, 3
	je	done			; reserved or unsupported

	; ok, we have and instruction of the form:
	;	df MODXXXR/M
	GET_EA			; ds:dx <- effective address
	
	GetInstruction	al
	call	CallRoutineFromDfFunctionTable		
done:
	ret
Interrupt3bCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt3bHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handles opcodes starting with dfh

CALLED BY:	GLOBAL


CALLED BY:	int 3bh (BorlandC and MicroSoftC programs)

PASS:		SS:SP points to data on the stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt3bHandler	proc	far
	InterruptStart
	mov	dx, 0		; no segment override
	call	Interrupt3bCommon
	InterruptEnd
Interrupt3bHandler	endp


InterruptCommonRoutines	nptr \
	Interrupt34Common,
	Interrupt35Common,
	Interrupt36Common,
	Interrupt37Common,
	Interrupt38Common,
	Interrupt39Common,
	Interrupt3aCommon,
	Interrupt3bCommon
	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt3cHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deal with segment overrides - joy - rapture

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt3cHandler	proc	far
	InterruptStart
	lodsb			; get override code
	
	; override/escape bytes looks like such
	; ss011xxx where ss = 
	;			00 -> DS
	; 			01 -> SS
	;			10 -> CS
	; 			11 -> ES
	; and xxx tells us which interrupt handler to call
;	test	al, 10000000b	
;	jz	doDSorSS
;	test	al, 01000000b
;	jz	doCS
;	; ok, its ES
;	segmov	ds, es, dx
;	jmp	callCommon
;doCS:
;	segmov	ds, cs, dx
;	jmp	callCommon
;doDSorSS:
;	test	al, 01000000b
;	jz	callCommon
;	segmov	ds, ss
;callCommon:
	mov	dl, al			; pass al on to common routines in dl
	mov	dh, 1			; flag for segment override
	and	al, 00000111b		; get xxx bits
	mov	bl, al
	clr	bh
	shl	bx
	mov	bx, cs:[InterruptCommonRoutines][bx]
	call	bx
	InterruptEnd
Interrupt3cHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt3dHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt3dHandler	proc	far
	INT_ON
	iret
Interrupt3dHandler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Interrupt3eHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/27/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Interrupt3eHandler	proc	far
	.enter

	.leave
	iret
Interrupt3eHandler	endp


FloatInterruptCode ends







