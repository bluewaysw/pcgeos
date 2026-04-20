COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		int8087.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/ 2/92		Initial version.

DESCRIPTION:
	specifi code to the 8087 chip

	$Id: int8087.asm,v 1.1 97/04/04 17:48:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource

TRIG_SWAP_BIT		equ	8000h
TRIG_EXACT45_BIT	equ	4000h


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87PrepareSinCos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reduce the top-of-stack angle to the first octant.

CALLED BY:	INTERNAL

PASS:		st = angle in radians

RETURN:		carry clear:
			ax = original FTST status (sign bit preserved)
			bx = quadrant bits from FPREM, plus internal flags
			st = reduced angle in [0, pi/4]
		carry set:
			st = error value suitable for CheckNormalNumberAndLeave

DESTROYED:	ax, bx

PSEUDOCODE/STRATEGY:

		use fprem with a pi/2 modulus so the low quotient bits tell us
		which quadrant the original angle was in.  If the reduced angle
		is above pi/4, mirror it around pi/2 so fptan always sees a
		value in the 8087-safe range.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87PrepareSinCos	proc	near
signStatus	local	word
remainder	local	FloatNum
	uses	dx
	.enter

	ftst
	StatusToAX
	mov	signStatus, ax
	test	ax, mask SW_CONDITION_CODE_2
	jnz	error

	fabs

	; Reduce |x| modulo pi/2 and remember the quadrant in the quotient
	; bits returned by FPREM.
	fldpi
	fidiv	cs:[int87Two]
	fxch
reduceLoop:
	fprem
	StatusToAX
	test	ax, mask SW_CONDITION_CODE_2
	jnz	reduceLoop

	mov	bx, ax

	; Save the remainder, then drop the pi/2 divisor.
	fstp	remainder
	fstp	st

	; If the remainder is larger than pi/4, reflect it so the tangent
	; kernel only sees values in the first octant.
	fld	remainder
	fldpi
	fidiv	cs:[int87Two]
	fidiv	cs:[int87Two]
	fcom
	StatusToAX
	sahf
	fstp	st			; drop pi/4, keep remainder
	jp	error
	je	exact45
	ja	firstOctant		; pi/4 > remainder

	fldpi
	fidiv	cs:[int87Two]
	fsubrp				; st = pi/2 - remainder
	or	bx, TRIG_SWAP_BIT
	jmp	short done

exact45:
	or	bx, TRIG_EXACT45_BIT
	jmp	short done

firstOctant:
done:
	mov	ax, signStatus
	clc
	.leave
	ret

error:
	mov	ax, signStatus
	stc
	.leave
	ret
Intel80X87PrepareSinCos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87ComputeReducedSinCos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute sin/cos for an angle known to be in [0, pi/4].

CALLED BY:	INTERNAL

PASS:		st = reduced angle in [0, pi/4]

RETURN:		st = cosine(reduced angle)
		st(1) = sine(reduced angle)

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:

		fptan leaves 1 and tan(x) on the stack.  From tan(x), recover
		cos(x) = 1/sqrt(1 + tan^2(x)) and sine by multiplying by tan(x).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87ComputeReducedSinCos	proc	near
tanValue	local	FloatNum
cosValue	local	FloatNum
	.enter

	fptan				; ( 1 tan(x) )
	fxch				; ( tan(x) 1 )
	fstp	tanValue		; save tan(x), leave 1
	fld	tanValue		; ( tan(x) 1 )
	fld	st			; ( tan(x) tan(x) 1 )
	fmulp				; ( tan^2(x) 1 )
	faddp				; ( 1 + tan^2(x) )
	fsqrt
	fld1
	fdivrp				; ( cos(x) )
	fstp	cosValue
	fld	cosValue
	fld	tanValue		; ( tan(x) cos(x) )
	fmulp				; ( sin(x) )
	fld	cosValue		; ( cos(x) sin(x) )

	.leave
	ret
Intel80X87ComputeReducedSinCos	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Cos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = cos(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

		reduce the argument modulo pi/2, mirror anything above pi/4
		back into the first octant, recover sine/cosine from tangent,
		then reapply the correct quadrant sign.
 
KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Cos	proc	far
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>

	call	Intel80X87PrepareSinCos
	jc	finish

	test	bx, TRIG_EXACT45_BIT
	jnz	loadDiagonal

	call	Intel80X87ComputeReducedSinCos	; ( cos(first) sin(first) )
	test	bx, TRIG_SWAP_BIT
	jnz	haveFirstQuadrant
	fxch					; ( sin(first) cos(first) )
	jmp	short haveFirstQuadrant

loadDiagonal:
	fstp	st				; drop pi/4
	fld	cs:[int87Sqrt2]
	fld1
	fdivrp					; st = 1/sqrt(2)
	fld	st				; ( sin(first) cos(first) )

haveFirstQuadrant:
	; Stack is now ( sin(first quadrant) cos(first quadrant) ).
	test	bx, mask SW_CONDITION_CODE_3
	jnz	quadrants23
	test	bx, mask SW_CONDITION_CODE_1
	jz	quadrant0			; quadrant 0: cos = +cos(first)
	fchs					; quadrant 1: cos = -sin(first)
	jmp	short popOther

quadrant0:
	fxch
	jmp	short popOther

quadrants23:
	test	bx, mask SW_CONDITION_CODE_1
	jnz	popOther			; quadrant 3: cos = +sin(first)
	fxch					; quadrant 2: cos = -cos(first)
	fchs

popOther:
	fxch
	fstp	st				; discard the non-result
finish:
	mov	ax, -2	
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Cos	endp
	public	Intel80X87Cos


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Intel80X87Sin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	st = sin(st)

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry set on NAN or infinity
		ax = error information if carry set

DESTROYED:	ax.

PSEUDOCODE/STRATEGY:	

		reduce the argument modulo pi/2, mirror anything above pi/4
		back into the first octant, recover sine/cosine from tangent,
		then reapply the correct quadrant and original sign.
 
KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/20/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Intel80X87Sin	proc	far
	.enter
	mov	ax, 2
	call	FloatHardwareEnter
	jc	done
EC <	call	Intel80X87Check1Arg				>

	call	Intel80X87PrepareSinCos
	jc	finish

	test	bx, TRIG_EXACT45_BIT
	jnz	loadDiagonal

	call	Intel80X87ComputeReducedSinCos	; ( cos(first) sin(first) )
	test	bx, TRIG_SWAP_BIT
	jnz	haveFirstQuadrant
	fxch					; ( sin(first) cos(first) )
	jmp	short haveFirstQuadrant

loadDiagonal:
	fstp	st				; drop pi/4
	fld	cs:[int87Sqrt2]
	fld1
	fdivrp					; st = 1/sqrt(2)
	fld	st				; ( sin(first) cos(first) )

haveFirstQuadrant:
	; Stack is now ( sin(first quadrant) cos(first quadrant) ).
	test	bx, mask SW_CONDITION_CODE_3
	jnz	quadrants23
	test	bx, mask SW_CONDITION_CODE_1
	jz	applySign			; quadrant 0: sin = +sin(first)
	fxch					; quadrant 1: sin = +cos(first)
	jmp	short applySign

quadrants23:
	test	bx, mask SW_CONDITION_CODE_1
	jnz	quadrant3
	fchs					; quadrant 2: sin = -sin(first)
	jmp	short applySign

quadrant3:
	fxch					; quadrant 3: sin = -cos(first)
	fchs

applySign:
	test	ax, mask SW_CONDITION_CODE_0
	jz	popOther
	fchs

popOther:
	fxch
	fstp	st				; discard the non-result
finish:
	mov	ax, -2	
	call	Intel80X87CheckNormalNumberAndLeave
done:
	.leave
	ret
Intel80X87Sin	endp
	public	Intel80X87Sin

CommonCode	ends	
