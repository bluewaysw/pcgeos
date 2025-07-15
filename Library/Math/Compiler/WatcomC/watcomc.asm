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

WatcomMath	ends
