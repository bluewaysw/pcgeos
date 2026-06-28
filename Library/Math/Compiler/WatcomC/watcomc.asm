COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		math.asm

AUTHOR:		Falk Rehwagen

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	7/15/25		Initial version.

DESCRIPTION:
	this file implements the stubs for the floating
	point functions of WatcomC

	$Id: watcomc.asm,v 1.1 97/04/05 01:22:47 newdeal Exp $

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


;=========================================================================
;==     Name:           FDFS                                            ==
;==     Operation:      Float double to float single conversion         ==
;==     Inputs:         AX;BX;CX;DX     double precision float          ==
;==     Outputs:        DX;AX           single precision float          ==
;==     Volatile:       CX, DX destroyed                                ==
;=========================================================================

WatcomMath	segment resource

SetGeosConvention


pushIEEE64	proc	near
	uses	ds, si	
number	local	IEEE64
	.enter
	mov	number.IEEE64_wd0, dx
	mov	number.IEEE64_wd1, cx
	mov	number.IEEE64_wd2, bx
	mov	number.IEEE64_wd3, ax
	segmov	ds, ss, si
	lea	si, number
	call	FloatIEEE64ToGeos80
	.leave
	ret
pushIEEE64	endp

pushIEEE64essi	proc	near
	uses	ds, si, ax	
number	local	IEEE64
	.enter
        mov	ax, es:[si]
	mov	number.IEEE64_wd0, ax
        mov	ax, es:2[si]
	mov	number.IEEE64_wd1, ax
        mov	ax, es:4[si]
	mov	number.IEEE64_wd2, ax
        mov	ax, es:6[si]
	mov	number.IEEE64_wd3, ax
	lea	si, number
	segmov	ds, ss, ax
	call	FloatIEEE64ToGeos80
	.leave
	ret

pushIEEE64essi	endp

pushIEEE64sssi	proc	near
	uses	ds, si, ax	
number	local	IEEE64
	.enter
        mov	ax, ss:[si]
	mov	number.IEEE64_wd0, ax
        mov	ax, ss:2[si]
	mov	number.IEEE64_wd1, ax
        mov	ax, ss:4[si]
	mov	number.IEEE64_wd2, ax
        mov	ax, ss:6[si]
	mov	number.IEEE64_wd3, ax
	lea	si, number
	segmov	ds, ss, ax
	call	FloatIEEE64ToGeos80
	.leave
	ret

pushIEEE64sssi	endp

retIEEE64	proc	near
	uses	es, di
answer	local	IEEE64
	.enter
	lea	di, answer
	segmov	es, ss
	call	FloatGeos80ToIEEE64

	mov	dx, answer.IEEE64_wd0
	mov	cx, answer.IEEE64_wd1
	mov	bx, answer.IEEE64_wd2
	mov	ax, answer.IEEE64_wd3

	.leave
	ret
retIEEE64	endp

__FDFS	proc	far
	call	pushIEEE64
	call	FloatGeos80ToIEEE32
	ret
__FDFS	endp
	public	__FDFS


;[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
;[]
;[] __FDU4      convert double float AX;BX;CX;DX into 32-bit integer DX:AX
;[]     Input:  AX BX CX DX - double precision floating point number
;[]     Output: DX:AX       - 32-bit integer
;[]
;[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
;       convert floating double to 4-byte integer with rounding

__FDU4	proc	far
	call	pushIEEE64
	call	FloatTrunc
	call	FloatFloatToUnsigned
	ret
__FDU4	endp
	public	__FDU4

__FDI4	proc	far
	call	pushIEEE64
	call	FloatTrunc
	call	FloatFloatToDword
	ret
__FDI4	endp
	public	__FDI4

;========================================================================
; Name:         I4FS, U4FS
; Operation:    Convert Integer types to single precision
; Inputs:       DX;AX, unsigned or signed integer
; Outputs:      DX;AX single precision floating point (DX exp)
; Volatile:     none
;========================================================================

__FSU4	proc	far
	call	FloatIEEE32ToGeos80
	call	FloatTrunc
	call	FloatFloatToUnsigned
	ret
__FSU4	endp
	public	__FSU4

__FSI4	proc	far
	call	FloatIEEE32ToGeos80
	call	FloatTrunc
	call	FloatFloatToDword
	ret
__FSI4	endp
	public	__FSI4

;
;   real*8 math library
;
;   __FDM,__FDD
;                   floating point routines
;                   13 June, 1984 @Watcom
;
;   All routines have the same calling conventions.
;   Op_1 and Op_2 are double prec reals, pointed to by DI and SI resp.
;   The binary operations are perfomed as Op_1 (*) Op_2.
;
;   In all cases, BP and DI are returned unaltered.
;
;
;                               have to always point at DGROUP.
;                               **** This routine does CODE modification ****
;                               is a power of 2.
;                               aligning fractions before the add
;                               No need to push second operand in f8split
;                               since ss:[si] can already be used to access it
;                               Moved f8split into each subroutine.
;                               to get rid of code modification
;                               we might be running with SS != DGROUP
;

__EDM	proc	far
        call	pushIEEE64
	call	pushIEEE64essi
	call	FloatMultiply
	call	retIEEE64
	ret
__EDM	endp
	public	__EDM

__EDA	proc	far
        call	pushIEEE64
	call	pushIEEE64essi
	call	FloatAdd
	call	retIEEE64
	ret
__EDA	endp
	public	__EDA

__EDS	proc	far
        call	pushIEEE64
	call	pushIEEE64essi
	call	FloatSub
	call	retIEEE64
	ret
__EDS	endp
	public	__EDS

__EDD	proc	far
        call	pushIEEE64
	call	pushIEEE64essi
	call	FloatDivide
	call	retIEEE64
	ret
__EDD	endp
	public	__EDD

__FDM	proc	far
	call	pushIEEE64
        call	pushIEEE64sssi
	call	FloatMultiply
	call	retIEEE64
	ret
__FDM	endp
	public	__FDM

__FDA	proc	far
	call	pushIEEE64
        call	pushIEEE64sssi
	call	FloatAdd
	call	retIEEE64
	ret
__FDA	endp
	public	__FDA

__FDS	proc	far
	call	pushIEEE64
        call	pushIEEE64sssi
	call	FloatSub
	call	retIEEE64
	ret
__FDS	endp
	public	__FDS

__FDD	proc	far
	call	pushIEEE64
        call	pushIEEE64sssi
	call	FloatDivide
	call	retIEEE64
	ret
__FDD	endp
	public	__FDD

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;<>
;<> __FDC - floating double comparison
;<>     input:  AX:BX:CX:DX - operand 1
;<>             DS:SI - address of operand 2
;<>       if op1 > op2,  1 is returned in AX
;<>       if op1 < op2, -1 is returned in AX
;<>       if op1 = op2,  0 is returned in AX
;<>
;<>
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

__EDC	proc	far
	call	pushIEEE64
        call	pushIEEE64essi
	call	FloatCompAndDrop
	mov	ax, 0		; assume equal
	jz	done
	mov	ax, -1		; X1 < X2
	jc	done		
	mov	ax, 1		; X1 > X2
done:
	ret
__EDC	endp
	public	__EDC

__FDC	proc	far
	call	pushIEEE64
        call	pushIEEE64sssi
	call	FloatCompAndDrop
	mov	ax, 0		; assume equal
	jz	done
	mov	ax, -1		; X1 < X2
	jc	done		
	mov	ax, 1		; X1 > X2
done:
	ret
__FDC	endp
	public	__FDC

;========================================================================
;==     Name:           FDN                                            ==
;==     Operation:      Floating double negate                         ==
;==     Inputs:         AX      high word of float                     ==
;==     Outputs:        AX      new high word of float                 ==
;==     Volatile:       none                                           ==
;========================================================================

__FDN	proc	far
	call	pushIEEE64
	call	FloatNegate
	call	retIEEE64
	ret
__FDN	endp
	public	__FDN

; Name:         __I4FD, __U4FD
; Operation:    __I4FD convert signed 32-bit integer in DX:AX into double float
;               __U4FD convert unsigned 32-bit integer in DX:AX into double float
; Inputs:       DX:AX       - 32-bit integer
; Outputs:      AX BX CX DX - double precision representation of integer
; Volatile:     none
;
;

__I4FD	proc	far
	call	FloatDwordToFloat
	call	retIEEE64
	ret
__I4FD	endp
	public	__I4FD

__U4FD	proc	far
	call	FloatUnsignedToFloat
	call	retIEEE64
	ret
__U4FD	endp
	public	__U4FD

;
;     real*4 math library
;
;  04-apr-86    G. Coschi       special over/underflow check in mul,div
;                               have to always point at DGROUP.
;                               we might be running with SS != DGROUP
;
;     inputs: DX,AX - operand 1 (high word, low word resp. ) (op1)
;             CX,BX - operand 2                              (op2)
;
;     operations are performed as op1 (*) op2 where (*) is the selected
;     operation
;
;     output: DX,AX - result    (high word, low word resp. )
;
;     __FSA, __FSS - written  28-apr-84
;                  - modified by A.Kasapi 15-may-84
;                  - to:      Calculate sign of result
;                  -          Guard bit in addition for extra accuracy
;                             Add documentation
;     __FSM        - written  16-may-84
;                  - by       Athos Kasapi
;     __FSD        - written  may-84 by "
;
;
;

__FSM	proc	far
	call	FloatIEEE32ToGeos80
	mov	dx, cx
	mov	ax, bx
        call	FloatIEEE32ToGeos80
	call	FloatMultiply
	call	FloatGeos80ToIEEE32
	ret
__FSM	endp
	public	__FSM

__FSA	proc	far
	call	FloatIEEE32ToGeos80
	mov	dx, cx
	mov	ax, bx
        call	FloatIEEE32ToGeos80
	call	FloatAdd
	call	FloatGeos80ToIEEE32
	ret
__FSA	endp
	public	__FSA

__FSS	proc	far
	call	FloatIEEE32ToGeos80
	mov	dx, cx
	mov	ax, bx
        call	FloatIEEE32ToGeos80
	call	FloatSub
	call	FloatGeos80ToIEEE32
	ret
__FSS	endp
	public	__FSS

__FSD	proc	far
	call	FloatIEEE32ToGeos80
	mov	dx, cx
	mov	ax, bx
        call	FloatIEEE32ToGeos80
	call	FloatDivide
	call	FloatGeos80ToIEEE32
	ret
__FSD	endp
	public	__FSD

; Name:         I4FS, U4FS
; Operation:    Convert Integer types to single precision
; Inputs:       DX;AX, unsigned or signed integer
; Outputs:      DX;AX single precision floating point (DX exp)
; Volatile:     none
;

__I4FS	proc	far
	call	FloatDwordToFloat
	call	FloatGeos80ToIEEE32
	ret
__I4FS	endp
	public	__I4FS

__U4FS	proc	far
	call	FloatUnsignedToFloat
	call	FloatGeos80ToIEEE32
	ret
__U4FS	endp
	public	__U4FS

;========================================================================
;==     Name:           FSN                                            ==
;==     Operation:      Floating single negate                         ==
;==     Inputs:         DX      high word of float                     ==
;==     Outputs:        DX      new high word of float                 ==
;==     Volatile:       none                                           ==
;========================================================================

__FSN	proc	far
	call	FloatIEEE32ToGeos80
	call	FloatNegate
	call	FloatGeos80ToIEEE32
	ret
__FSN	endp
	public	__FSN

;=========================================================================
;==     Name:           FDFS                                            ==
;==     Operation:      Float double to float single conversion         ==
;==     Inputs:         AX;BX;CX;DX     double precision float          ==
;==     Outputs:        DX;AX           single precision float          ==
;==     Volatile:       CX, DX destroyed                                ==
;=========================================================================

__FSFD	proc	far
	call	FloatIEEE32ToGeos80
	call	retIEEE64
	ret
__FSFD	endp
	public	__FSFD

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;<>
;<> __FSC compares DX:AX with CX:BX
;<>       if DX:AX > CX:BX,  1 is returned in AX
;<>       if DX:AX = CX:BX,  0 is returned in AX
;<>       if DX:AX < CX:BX, -1 is returned in AX
;<>
;<>  =========    ===           =======
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

__FSC	proc	far
	call	FloatIEEE32ToGeos80
	mov	dx, cx
	mov	ax, bx
        call	FloatIEEE32ToGeos80
	call	FloatCompAndDrop
	mov	ax, 0		; assume equal
	jz	done
	mov	ax, -1		; X1 < X2
	jc	done		
	mov	ax, 1		; X1 > X2
done:
	ret
__FSC	endp
	public	__FSC


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_trig_common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code to implement the various trigonometric functions
		in this file

CALLED BY:	sin, cos, sinh, cosh, tan, tanh, ...
PASS:		each of these routines receives on the stack:
			sp	-> retf
				   offset (to store result in ss)
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
				off:word,
				arg:IEEE64
		uses	ds, es, si, di
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

	;
	; Fetch result from FPU stack
	;
		segmov	es, ss
		mov	di, off
		call	FloatGeos80ToIEEE64
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
				off:word,
				arg2:IEEE64,
				arg:IEEE64
		uses	ds, es, si, di
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
	;
	; Fetch result from FPU stack
	;
		segmov	es, ss
		mov	di, off
		call	FloatGeos80ToIEEE64
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

_trig_common0	proc	near 	return:fptr.far,; caller's return address
				off:word
		uses	ds, si
		.enter

	;
	; Call our caller back to have it do what it has to do.
	; 
		call	{nptr.far}ss:[bp+2]
	;
	; Fetch result from FPU stack
	;
		segmov	es, ss
		mov	di, off
		call	FloatGeos80ToIEEE64
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


WatcomMath	ends
