COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Graphics
FILE:		Graphics/graphicsMath.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
    GBL GrMulWWFixed		same as GrMul32, but global
    GBL GrSDivWWFixed		same as GrSDiv32, but global
    GBL GrUDivWWFixed		same as GrUDiv32, but global
    GBL GrSqrWWFixed		same as GrSqr32, but global
    GBL GrSqrRootWWFixed	same as GrSqrRoot32, but global
    GBL	GrQuickSine		same as GrFastSine, but global
    GBL	GrQuickCosine		same as GrFastCosine, but global
    GBL GrQuickTangent		divide the FastSine by the FastCosine
    GBL GrQuickArcSine		same as GrFastArcSine, but global

    INT	GrFastSine		Do table lookup for calculating sine
    INT	GrFastCosine		Do table lookup for calculating cosine
    INT	GrMul32			32-bit signed multiply, assuming 16 bits frac
    INT	GrRegMul32		same as GrMul32 but takes register args
    INT GrRegMul32ToDDF		same as GrRegMul32 but returns DDFixed number
    INT	GrReciprocal32		Take recprocal of signed 32-bit number/frac
    INT	GrSDiv32		32-bit signed divide, assuming 16 bits frac
    INT	GrUDiv32		32-bit unsigned divide, assuming 16 bits frac
    INT	GrMatrixMul		Full matrix multiply for transformation matrix
    INT GrSqrRoot32		32 bit square root, assuming 16 bits frac
    INT GrSqr32			Squares a 32 bit number
    INT GrFastArcSine		Do table search for calculating arcsine
    INT BinarySearch		Do a binary search on a table of words

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	3/89	initial version
	jim	8/89	added global versions to some routines for kernel lib


DESCRIPTION:
	This file contains routines to some fast pseudo-real math.

	$Id: graphicsMath.asm,v 1.1 97/04/05 01:12:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsObscure	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFastCosine GrQuickCosine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the cosine of an angle

CALLED BY:	INTERNAL	(GrFastCosine)
		GLOBAL		(GrQuickCosine)

PASS:		dx.ax	- 32-bit number representing angle * 65536
			  (dx holds high word, ax holds low word)

RETURN:		dx.ax	- 32-bit number representing cosine * 65536
			  (dx holds high word, ax holds low word)

DESTROYED:	bx, cx		(GrFastCosine)
		Nothing		(GrQuickCoSine)

PSEUDO CODE/STRATEGY:
		if (angle < 0)
		   negate angle;
		while (angle >= 360)
		   angle -= 360;
		if (angle > 270)
		   angle = 360 - angle;
		else if (angle > 180)
		   angle -= 180;
		   toggle negative flag;
		else if (angle > 90)
		   angle = 180-angle;
		   toggle negative flag;
		angle = 90 - angle;
		return(sine(angle));

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;	a few constants to represent bit positions if flag
GFC_NEG_RESULT	equ	80h			; mask for flag


GrQuickCosine	proc	far
		push	bx, cx
		call	GrFastCosine
		pop	bx, cx
		ret
GrQuickCosine	endp


GrFastCosine	proc	near

		; if angle < 0...

		clr	ch			; clear negate flags
		tst	dx			; see if negative	  ( 3)
		js	GFC_neg			;			(4/16)

		; normalize angle to 0 - 360
GFC_pos:
		cmp	dx, 360			; normalize to 0-360	  ( 4)
		jge	GFC_normalize		;			(4/16)

		; angle normalized, get 0 - 90
GFC_normal:
		cmp	dx, 90			; see if 0<=angle<90      ( 4)
		jge	GFC_quad		;  no, in another quad	(4/16)

		; in 0-90, so subtract from 90
GFC_0to90:
		Neg32	ax, dx			; negate angle
		add	dx, 90			; angle = 90 - angle

		; use sine function to calculate value

		push	cx			; save neg flag
		call	GrFastSine		; get sine of angle
		pop	cx			; restore flags

		; negate result if neccesary

		tst	ch			; test falgs
		jns	GFC_done
		Neg32	ax, dx			; negate result
GFC_done:
		ret

;-------------------------------------------------------


		; special case: negative angle
GFC_neg:
		Neg32	ax, dx			; negate 32-bit quantity
		jmp	short GFC_pos

		; special case: angle >= 360
GFC_normalize:
		sub	dx, 360
		jge	GFC_normalize
		add	dx, 360
		jmp	GFC_normal

		; special case: 90 <= angle < 360
GFC_quad:
		cmp	dx, 270			; see if in 4th quad
		jl	GFC_chk3		;  no, check for 3rd quad
		Neg32	ax, dx			;  yes, angle=-angle
		add	dx, 360			;       angle=360-angle
		jmp	short GFC_0to90
GFC_chk3:
		cmp	dx, 180			; check for 3rd quad
		jl	GFC_do2			;  no, must be 2nd
		sub	dx, 180			;  yes, angle-=180
		xor	ch, GFC_NEG_RESULT 	; toggle both flags
		jmp	short GFC_0to90
GFC_do2:
		Neg32	ax, dx			; 2nd quadrant
		add	dx, 180			;  angle=180-angle
		xor	ch, GFC_NEG_RESULT 	; toggle both flags
		jmp	short GFC_0to90
GrFastCosine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFastSine GrQuickSine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the sine of an angle

CALLED BY:	INTERNAL	(GrFastSine)
		GLOBAL		(GrQuickSine)

PASS:		dx.ax	- 32-bit number representing angle * 65536
			  (dx holds high word, ax holds low word)

RETURN:		dx.ax	- 32-bit number representing sine * 65536
			  (dx holds high word, ax holds low word)

DESTROYED:	bx, cx		(GrFastSine)
		Nothing		(GrQuickSine)

PSEUDO CODE/STRATEGY:
		if (angle < 0)
		   negate angle;
		   toggle negative flag;
		while (angle >= 360)
		   angle -= 360;
		if (angle > 270)
		   angle = 360 - angle;
		   toggle negative flag;
		else if (angle > 180)
		   angle -= 180;
		   toggle negative flag;
		else if (angle > 90)
		   angle = 180-angle;
		lookup sine in table;
		if (negative flag set)
		   value *= -1;

		There are two flags kept in ch, one to indicate if the result
		should be negated, the other to indicate how the fractional
		portion of the sin interpolation should be calculated.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		TIMINGS	(8088)
		--------------
		minimum	      67 cycles		(0<=angle< 90, frac= 0)
		typical	    ~175 cycles		(0<=angle<360, frac= 0, avg)
		fraction    ~425 cycles 	(0<=angle<360, frac!=0, avg)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;	a few constants to represent bit positions if flag
GFS_NEG_RESULT	equ	80h			; mask for flag

GrQuickSine	proc	far
		push	bx, cx
		call	GrFastSine
		pop	bx, cx
		ret
GrQuickSine	endp

		; special case: interpolate fractional angle. We'll use
		; the additional sinFracTable to help us calculate a
		; more accurate (but fast) result.
haveFraction:
		mov	dx, ds:[sinFracTable][bx]
		cmp	ax, 8000h
		je	doneFraction
		jb	lessThanHalf
		cmp	bx, 89 * 2		; if ceiling is 90 degress
		mov	bx, ds:[sinIntTable][bx+2]
		xchg	bx, dx			; bx = floor, dx = ceiling
		jne	doInterpolation		; ...not, so do nothing
		dec	bx			; ...account for sinIntTable[90]

		; dx = ceiling value
		; bx = floor value
		; ax = fraction
doInterpolation:
		sub	dx, bx			; start interpolation
		shl	ax, 1			; double the fraction, as the
						; difference is .5 degrees
		mul	dx			; dx:ax = diff * frac
		shl	ax, 1
		adc	dx, 0			; round result
		add	dx, bx			; dx = final result
		jmp	doneFraction

lessThanHalf:
		mov	bx, ds:[sinIntTable][bx]
		jmp	doInterpolation

;-------------------------------

GrFastSine	proc	near			;		        CYCLES
		uses	ds
		.enter

		segmov	ds, cs			; ds = segment for sine tables
		clr	ch			; use ch for toggle flag  ( 3)

		; if angle < 0...

		tst	dx			; see if negative	  ( 3)
		js	negativeAngle		;			(4/16)

		; determine which quadrant angle resides; fixup angle,flags
havePositiveAngle:
		cmp	dx, 360			; normalize to 0-360	  ( 4)
		jge	normalizeAngle		;			(4/16)
haveNormalAngle:
		cmp	dx, 90			; see if 0<=angle<90      ( 4)
		jge	checkQuadrant		;  no, in another quad	(4/16)

		; use table to lookup angle
lookup:
		mov	bx, dx			; prepare to do lookup    ( 2)
		shl	bx, 1			; index into word table   ( 2)
		mov	dx, ds:sinIntTable[bx]	; lookup floor (angle)    (21)
		tst	ax			; see if non-zero fraction( 3)
		jnz	haveFraction		;  yes, do it		(4/16)
doneFraction	label	near
		mov	ax, dx			; copy fraction to result ( 2)
		clr	dx			; fraction, no int	  ( 3)

		; apply negation , if necc
negateMaybe:
		tst	ch			; see if we need to neg	  ( 3)
		js	negateResult		;  yes, do it		(4/16)
done:
		.leave
		ret

;-------------------------------------------------------

		; special case: negate result
negateResult:
		negwwf	dxax			; negate result
		jmp	done

		; special case: negative angle
negativeAngle:
		xor	ch, GFS_NEG_RESULT 	; toggle both flags
		negwwf	dxax			; negate 32-bit quantity
		jmp	havePositiveAngle

		; special case: angle >= 360
normalizeAngle:
		sub	dx, 360
		jge	normalizeAngle
		add	dx, 360
		jmp	haveNormalAngle

		; special case: 90 <= angle < 360
checkQuadrant:
		cmp	dx, 270			; see if in 4th quad
		jl	checkQuadrant3		;  no, check for 3rd quad
		negwwf	dxax			;  yes, angle=-angle
		add	dx, 360			;       angle=360-angle
		xor	ch, GFS_NEG_RESULT	;       toggle negate flag
		jmp	check90Degrees
checkQuadrant3:
		cmp	dx, 180			; check for 3rd quad
		jl	doQuadrant2		;  no, must be 2nd
		sub	dx, 180			;  yes, angle-=180
		xor	ch, GFS_NEG_RESULT 	; toggle both flags
		jmp	check90Degrees
doQuadrant2:
		negwwf	dxax			; 2nd quadrant
		add	dx, 180			;  angle=180-angle
check90Degrees:
		cmp	dx, 90
		jne	lookup
		mov	ax, 0			; just stuff value for 90 deg
		mov	dx, 1
		jmp	negateMaybe
GrFastSine	endp

GraphicsObscure	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrMulWWFixedPtr	GrMul32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply two 32-bit signed integers, where lower 16-bits of
		each is considered a fraction.

CALLED BY:	GLOBAL		(GrMulWWFixed, GrMulWWFixedPtr)
		INTERNAL	(GrRegMul32, GrMul32)

PASS:		ds:si	- points to multiplicand (GrMul32, GrMulWWFixedPtr)
		es:di	- points to multiplier 	 (GrMul32, GrMulWWFixedPtr)

		dx.cx	- multiplier   (GrRegMul32, GrMulWWFixed)
		bx.ax	- multiplicand (GrRegMul32, GrMulWWFixed)

RETURN:		dx.cx	- dx holds high word, cx holds low word

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		do the right thing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version
	Joon	12/92		Optimized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrMulWWFixedPtr	proc	far
	uses	ax,bx
	.enter
if	FULL_EXECUTE_IN_PLACE
EC <	push	ds, si							>
EC <	call	ECCheckBounds						>
EC <	segmov	ds, es, si						>
EC <	mov	si, di				; ds:si = multiplier	>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>
endif
	movdw	dxcx, ds:[si]
	movdw	bxax, es:[di]
	call	GrRegMul32ToDDF
	.leave
	ret
GrMulWWFixedPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrMulWWFixed	GrRegMul32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiplies two fixed point numbers
		dx.cx = dx.cx * bx.ax

CALLED BY:	GLOBAL

PASS:		dx.cx	multiplicand
		bx.ax	multiplier

RETURN:		dx.cx	result

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/20/89		Initial version
	JS	6/9/92		Optimized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrRegMul32	label	far
GrMulWWFixed	proc	far
	uses	ax, bx
	.enter
	call	GrRegMul32ToDDF
	.leave
	ret
GrMulWWFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRegMul32ToDDF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply 2 WWFixed numbers and return a DDFixed number

CALLED BY:	GLOBAL
PASS:		dx.cx		= multiplicand
		bx.ax		= multiplier
RETURN:		bxdx.cxax	= result
		dx.cx		= same as result from old GrMul32
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:			D.C		dx.cx
					B.A		bx.ax
				-----------		-----
			  A*D + (A*C >> 16)	      bxdx.cxax
 	    (B*D << 16) + B*C
      -------------------------------------
      (B*D << 16) + A*D + B*C + (A*C >> 16)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/12/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrRegMul32ToDDF	proc	near
	uses	bp, si, di
	.enter

        mov	si, dx		;si.cx = multiplicand
	mov	di, ax		;bx.di = multiplier

	mov	ax, si
	xor	ax, bx		;if signs are different then SFlag will be set
	pushf			;save flags

	tst	si
	js	neg_sicx	;if signed, negate operand
after_sicx:

	tst	bx
	js	neg_bxdi	;if signed, negate operand
after_bxdi:

	mov	ax, cx
	mul	di		;0.dxax = C*A
	mov	bp, dx		;0.bp = C*A
	push	ax		;save lowest word

	mov	ax, si
	mul	bx		;dxax.0 = D*B
	push	dx		;save highest word

	xchg	ax, cx		;cx.0 = D*B, ax = C
	mul	bx		;dx.ax = C*B
	add	bp, ax
	adc	cx, dx		;cx.bp = D*B + C*B + C*A

	mov	ax, si
	mul	di		;dx.ax = D*A
	add	ax, bp
	adc	dx, cx		;dx.ax = middle two words of answer
	pop	bx		;bx <= highest word
	adc	bx, 0		;add carry to highest word
	pop	cx		;cx <= lowest word
	xchg	ax, cx		;answer = bxdx.cxax

	popf
	js	neg_bxdxcxax	;if signs of operands are different,
done:				; negate result
	.leave
	ret

neg_sicx:
	negdw	sicx		;make multiplicand
	jmp	short after_sicx

neg_bxdi:
	negdw	bxdi		;make multiplier positive
	jmp	short after_bxdi

neg_bxdxcxax:
	neg	ax
	cmc
	not	cx
	adc	cx, 0
	not	dx
	adc	dx, 0
	not	bx
	adc	bx, 0
	jmp	short done

GrRegMul32ToDDF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrReciprocal32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the reciprocal of a 32-bit integer, where 16-bits
		are considered the integer part, and 16-bits are fraction.

CALLED BY:	INTERNAL

PASS:		bx.ax	- number to take reciprocal

			This notation is meant to represent a 32-bit quantity
			as HighWord:LowWord -- not a far pointer.

RETURN:		bx.ax	- reciprocal

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		uses GrUDiv32, below

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrReciprocal32Far	proc	far
		call	GrReciprocal32	
		ret
GrReciprocal32Far	endp

GrReciprocal32	proc	near

		push	cx, dx 			; save regs

		; set up 1.0 as dividend

		clr	cx			; no fraction
		mov	dx, 1			; sets up 1.0
		call	GrSDiv32		; do 32-bit divide
		mov	bx, dx			; set up result
		mov	ax, cx

		pop	cx, dx			; restore regs
		ret
GrReciprocal32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSDiv32 GrSDivWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	signed divide, 32-bit dividend and divisor

CALLED BY:	INTERNAL	(GrSDiv32)
		GLOBAL		(GrSDivWWFixed)

PASS:		dx.cx	- 32-bit dividend
		bx.ax	- 32-bit divisor

		This notation is meant to describe dx:cx as a 32-bit quantity,

RETURN:		dx.cx	- 32-bit quotient (dx=integer part, cx=fractional part)
		bx.ax	- unchanged

		carry	- set if overflow occurred, else clear
			- quotient is undefined if overflow occurred.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This uses the unsigned divide routine, and fixes up the
		signs of result.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSDivWWFixed	proc	far
		push	ax, bx
		call	GrSDiv32
		pop	ax, bx
		ret
GrSDivWWFixed	endp

GrSDiv32	proc	near

		uses	si

		.enter
		mov	si, dx		; calc sign of result
		xor	si, bx		; positive if both same sign

		; change sign of operands, if necc

		tst	dx		; test dividend
		jns	GSD_numfixed	; negative ?
		negdw	dxcx		;  yes, negate dividend
GSD_numfixed:
		tst	bx		; test divisor
		jns	GSD_denfixed	; negative ?
		negdw	bxax		;  yes, negate divisor
GSD_denfixed:
		call	GrUDiv32	; do unsigned divide
		pushf			;save overflow status
		; restore sign of result, do the right thing

		tst	si		; test sign of result
		js	changeSign	; negative, so change sign

popfDone:
		popf
		.leave
		ret
changeSign:
		negdw	dxcx		; negate result
		jmp	popfDone
GrSDiv32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrUDiv32 GrUDivWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unsigned divide, 32-bit dividend and divisor

CALLED BY:	INTERNAL (GrUDiv32)
		GLOBAL	 (GrUDivWWFixed)

PASS:		dx.cx	- 32-bit dividend
		bx.ax	- 32-bit divisor

		This notation is meant to describe dx:cx as a 32-bit quantity,

RETURN:		dx.cx	- 32-bit quotient (WWFixed format)
		bx.ax	- unchanged

		carry	- set if overflow occurred, else clear
			- quotient is undefined if overflow occurred.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		All integer divide algorithms (that I could find) produce a
		quotient and a remainder.  Unfortunately, we want a quotient
		that is part integer and part fraction.  To get around this
		problem, we shift the dividend left 16-bits which will produce
		a 48-bit quotient that is also multiplied by 2^16.  This makes
		the low 16-bits of the result a fraction, just what we want.

		Since the 8088 div instruction divides a 32-bit number
		by a 16-bit divisor, we can't use it (we have a 32-bit
		divisor).  Therefore we go back to basics and write our
		own divide routine.  The basic algorithm is:

			partial_dividend = 0;
		        for (count=48; count>0; count--)
			   shift dividend left;
			   shift partial_dividend left;
			   if (divisor <= partial_dividend)
			      partial_dividend -= divisor;
			      dividend++;
			quotient = dividend;
			remainder=partial_dividend;

		register/stack usage:
			dx:cx:di - 48-bit divident/quotient
			bx:ax	 - 32-bit partial dividend/remainder
			si	 - count
			[bp-4]	 - 32-bit divisor

		
		Believe it or not, this algorithm was adapted from one I found
		in "6502 Software Design", by Leo Scanlon.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrUDivWWFixed	proc	far
		call	GrUDiv32
		ret
GrUDivWWFixed	endp

GrUDiv32	proc	near

;
; This "if" contains the trivial reject and simple-case analysis code
;
if 1
		;
		;	Check for dividend == 0 (dx = cx = 0)
		;
		tst_clc	dx
		jnz	nonZeroDividend
		jcxz	exit

		;
		;	Check for division by 1:0 (bx = 1, ax = 0)
		;
nonZeroDividend:
		tst	ax
		jnz	axNonZero
		cmp	bx, 1
		je	exit		;carry clear from = comparison
		jcxz	bothInts
axNonZero:
		tst	bx
		jnz	divisorBig
		cmp	ax, dx		;if dividend is too big, error
		ja	divisorSmall
error:
		stc
		ret

		;
		;	A quick divide for the case where
		;	divisor is 16 bits (bx = 0)
		;
divisorSmall:

		xchg	ax, cx		; dx:ax = dividend,
					; cx = divisor
		jcxz	error		; error on divide by zero
		div	cx		; ax <- quotient
					; dx <- remainder
		xchg	bx, ax		; ax <- 0
					; bx <- quotient
		div	cx		; ax <- frac quotient
					; dx <- frac remainder (we toss this)
		mov	dx, bx		;dx <- quotient
		xchg	cx, ax		;cx <- fraction,
					;ax <- divisor
		xor	bx, bx		;return bx to its original state (= 0),
					;and clear the carry
exit:
		ret			; all done

bothInts:
		;
		;	Both passed #'s are integers (ax = cx = 0)
		;
		xchg	ax, dx		;dx <- 0, ax <- int
		tst	bx
		jz	error		;error on divide by zero
		div	bx		;ax <- quotient int, dx <- remainder
		tst_clc	dx
		jz	intIntInt
		xchg	ax, cx		;ax <- 0, cx <- quotient int
		div	bx		;ax <- quotient frac, dx <- toss
		mov	dx, cx		;dx <- quotient int
		mov_tr	cx, ax		;cx <- quotient frac
		xor	ax, ax		;return ax to its original state (= 0),
					;and clear the carry
		ret

		;
		;	Both args ints, result int
		;
intIntInt:
		xchg	dx, ax		;dx <- quotient int
		ret			;carry clear from tst_clc
divisorBig:
endif

		push	si, di, bp	; save registers trashed


		; set up regs as we like

		mov	bp, sp		; allocate some scratch space
		push	bx		;ss:[bp-2] <- divisor int
		push	ax		;ss:[bp-4] <- divisor frac


	;		sub	sp, 4		; need space for divisor
	;		mov	[bp-2], bx	; move divisor to stack
	;		mov	[bp-4], ax

		clr	ax, bx, di	; clear partial dividend, low word
		mov	si, cx
		mov	cx, 49		; bit counter (loop count)

		; loop through all bits, doing that funky divide thing
GUD_topNext:
		dec	cx
		jz	GUD_afterLoop
GUD_loop:
		sal	di, 1		; shift partial dividend/dividend
		rcl	si, 1
		rcl	dx, 1
		rcl	ax, 1
		rcl	bx, 1
		cmp	[bp-2], bx		; divisor > partial dividend ?
		ja	GUD_topNext	;  no, continue with next loop
		jne	GUD_work	;  yes, need to do some more work
		cmp	[bp-4], ax	;  can't tell yet, check low word
		ja	GUD_topNext	;  no, continue next loop

		; divisor <= partial dividend, do some work
GUD_work:
	;	this code has been replaced
	;		add	di, 1		; increment quotient
	;		adc	si, 0
	;		adc	dx, 0

		inc	di
		jz	GUD_rippleCarry
GUD_afterRipple:
		sub	ax, [bp-4]	; partial divident -= divisor
		sbb	bx, [bp-2]
;GUD_next:
		loop	GUD_loop	; continue with next iteration
GUD_afterLoop:
		; test for overflow, set up results

		pop	ax		; restore divisor frac
		pop	bx		; restore divisor int
		tst_clc	dx		; should be zero if no overflow
		jnz	GUD_overflow	;  error, signal and quit
		mov	dx, si		; move integer over
		mov	cx, di		; move fraction over
GUD_done:
		pop	si, di, bp	; restore trashed regs
		ret			; all done

GUD_overflow:
		stc			; set carry flag to indicate overflow
		jmp short GUD_done	; all done

GUD_rippleCarry:
		inc	si
		jnz	GUD_afterRipple
		inc	dx
		jmp	GUD_afterRipple

GrUDiv32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSqr32 GrSqrWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the square of a 32 bit number.

CALLED BY:	GLOBAL		(GrSqrWWFixed)
		INTERNAL	(GrSqr32)
PASS:		dx.cx	- dx = hi, cx = lo
RETURN:		dx.cx
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Sets up parameters for GrRegMul32 and calls it

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/20/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSqrWWFixed	proc	far
		call	GrSqr32
		ret
GrSqrWWFixed	endp

GrSqr32		proc	near
	push	ax,bx
	mov	ax,cx
	mov	bx,dx
	call	GrRegMul32ToDDF
	pop	ax,bx
	ret
GrSqr32		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSqrRoot32 GrSqrRootWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the square root of a 32 bit number. The first
		16 bits are integer and the second 16 bits are fractional.
		Numbers less than 1 return with the value 1. So Sorry.

CALLED BY:
		CalcButtCap
PASS:
		dx.cx 	- WWFixed number to take square root of
RETURN:
		dx.cx	- WWFixed square root
DESTROYED:
		nothing
PSEUDO CODE/STRATEGY:
	MaNewton Bols formula says if you have an approximation A then
	(N/A +A) /2 is a better approximation ( N is the number whose square
	root we wish to know)
	For speed sake I choose an initial approx that is a
	power of two. I choose the power of two by determining the highest
	bit set in the integer portion of the number.
	highest bit set		init approx
		15		256
		14		128
		13		128
		12		64
		11		64
		10		32	and so on
	To determine the highest bit I basically shift the integer portion
	to the left until the carry is set. I then use this formula
	x=(17-#ofShifts)/2. x is the postion of the bit to set to create my
	approx and it is also the number of times to shift the original
	number to the right for the divide in Newtons formula.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/28/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSqrRootWWFixed proc	far
		call	GrSqrRoot32
		ret
GrSqrRootWWFixed endp

GSR32__10:			;number is less than or equal to 1 so return 1
	mov	dx,1
	clr	cx
	jmp	short	GSR32_99

GrSqrRoot32		proc	near
	push	ax,bx,si,di	;don't destroy
	cmp	dx,1
	jna	GSR32__10		;bra if number less than or equal 1
	mov	si,cx		;save fractional
	mov	cx,17
	mov	al,dh
	cmp	dh,0
	ja	GSR32_20	;bra if something in high byte of integer

	sub	cl,8		;pretend we have already done 8 shifts
	mov	al,dl		;search for highest set bit in low byte
GSR32_20:
	shl	al,1		;find highest bit
	dec	cl
	jnc	GSR32_20
	shr	cl,1		; now cl = magic number for right shift approx

	mov	bx,dx		;get original number in bx:ax
	mov	ax,si
	mov	di,1		;di will equal approx so it can be subtracted
GSR32_30:			;calculate second approximation
	shr	bx,1		;this gives number/approx in bx:ax
	rcr	ax,1
	shl	di,1		;and approx in di
	loopnz	GSR32_30
	add	bx,di		;add approx from num/approx
	shr	bx,1		;divide result by 2
	rcr	ax,1		;to get next approx in bx:ax

	push	dx		;save original number
	push	cx
	call	GrUDiv32	;divide number/approx
	add	ax,cx		;add fractional of quotient to approx
	adc	bx,dx		;add integer of quotient to approx
	shr	bx,1		;divide result of addition by 2
	rcr	ax,1		;to get next approx in bx:ax
	pop	cx		;retrieve original number
	pop	dx
				;calc final approx
	call	GrUDiv32	;divide number/approx
	add	cx,ax		;add fractional of quotient to approx
	adc	dx,bx		;add integer of quotient to approx
	shr	dx,1		;divide result of addition by 2
	rcr	cx,1		;to get final approx in dx:cx
GSR32_99 label near
	pop	ax,bx,si,di
	ret
GrSqrRoot32		endp



GraphicsObscure	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFastArcSine GrQuickArcSine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the inverse sign. In general you would pass
		-(delta y / radius) in dx and delta x in cx and the routine
		will return the correct angle for that quadrant. The minus
		on the (delta y / radius) is because the graphics coordinate
		system's origin is in the upper left, when usually it
		should be in the lower left.

CALLED BY:
PASS:
		bx - orig delta x value (only sign matters)
		dx.cx - value to get inverse sign for (delta y/ distance )
			(WWFixed format)
			-1 <= dx.cx <= 1
RETURN:
		dx.cx - angle
DESTROYED:
		ax,bx

PSEUDO CODE/STRATEGY:

	Do a binary search on the sine table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine currently routines largest integer angle with a sine
	less than the passed value. Linear Interpolation could be done
	but it wasn't necessary for my purposes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/89		Initial version
	jim	1/19/93		added interpolation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrQuickArcSine	proc	far
		call	GrFastArcSine
		ret
GrQuickArcSine	endp

GrFastArcSine	proc	near
		uses	di, bp, ds
		.enter

		push	bx, dx		; save passed int
		tst	dx		; force dx:cx to be positive
		jns	haveAbs
		negwwf	dxcx

		; have absolute value of sine.  Limit search to first quadrant.
haveAbs:
		cmp	dx, 1		; check for 90 degrees
		je	angleIs90	; binary search won't handle 1

		; OK, so it isn't the trivial case.  Do a binary search on
		; the sine table to find the angle.

		clr	bx		; lower search position
		mov	dx, 90		; upper table search position
		segmov	ds, cs		; sineIntTable is in our code segment
		mov	di, offset GraphicsObscure:sinIntTable
		call	BinarySearch	; ax = value, bp = table offset
		jnc	interpolate	; not exact, need to interpolate result
		mov	cx, 0		; don't use CLR, (assuming exact)
calcInteger:
		mov	dx, bp		; if exact, use table index for angle
		shr	dx, 1

		; We have an angle value between 0 and 90.  Adjust for the
		; right quadrant, based on the passed deltaX value and the
		; sine value.  The breakdown is as follows:
		;  	deltaX	sine	quadrant	action
		;	------	----	--------	------
		;	+	+	0-90		angle' = angle
		;	-	+	90-180		angle' = 180-angle
		;	-	-	180-270		angle' = 180+angle
		;	+	-	270-360		angle' = 360-angle
adjustForQuad:
		pop	bx, ax		; ax = sine, bx = deltaX

		tst	ax		; check sine first
		js	sineNegative	; jmp if in quadrants 3 or 4

		tst	bx		; check deltaX
		js	quadrant2	;  if positive, in quadrant 1
done:
		.leave
		ret

		; angle is 90 degrees.  No need for a search.
angleIs90:
		mov	dx, 90		; dx = +-1 so angle = 90 before
		clr	cx		;  adjust for quadrant
		jmp	adjustForQuad

		; we're in quadrant 2.  angle = 180-result
quadrant2:
		sub	dx, 180		; calc 180-angle for quad 2
		neg	dx		; dxcx = new 
		jmp	done

		; the original sine value was negative, so we're in quad 3 or 4
sineNegative:
		tst	bx		; check deltaX
		jns	quadrant4	; in last quadrant

		; we're in quadrant three, angle is 180+result

		add	dx,180		;otherwise must be in quad 3,so add 180
		jmp	done

		; quadrant 4.  angle is 360-result
quadrant4:
		sub	dx, 360
		neg	dx
		jmp	done

		; the search yielded that we're not on an integer angle.  
		; Interpolate between the two values in the table.  Result
		; should be:  angleInt =bp>>1
		;	      angleFrac=(origAng-tab[bp])/(tab[bp+2]-tab[bp])
interpolate:
		mov	dx, cx
		sub	dx, ax			; subtract tab[bp] from origAng
		clr	cx			; dxcx = numerator
		mov	bx, ds:[di][bp+2]	; bx = tab[bp+2]
		sub	bx, ax
		clr	ax
		call	GrUDivWWFixed
		jmp	calcInteger		; integer calculation same
GrFastArcSine		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BinarySearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a binary search on a table of words

CALLED BY:
PASS:		ds:di	- segment and offset to table
		bx	- lowest table position to search
		dx	- highest table position to search
		cx	- value to find
RETURN:
		ax <= cx
		bp - offset into table to value in ax
		stc - ax = cx
		clc - ax < cx
DESTROYED:
	dx,bx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BinarySearch		proc	near
	mov	bp, bx		;bp <- lower to avoid segment override on
				; table fetch and to shrink size of AND
				; instruction (need only mask BL, not all of
				; BP)
BS_0:
	add	bx, dx		;bx = table offset = (lower+upper/2)*2
BS_1:
	andnf	bx,not 1	; just need to clear low bit

	mov	ax,ds:[di][bx]	;get value now so we have it if we stop

	cmp	dx,bp
	jb	done		;stop, upper < lower

	shr	bx,1		;make bx into table position again

	cmp	ax,cx		;compare table to desired
	jb	truncateLowEnd	;jmp if table < hunted
	je	match		;BINGO

				;table > hunted
	dec	bx		;truncate high end
	mov	dx, bx
	add	bx, bp
	jmp	short	BS_1

truncateLowEnd:				;table < hunted
	inc	bx
	mov	bp,bx
	jmp	short 	BS_0

match:
	shl	bx,1		;make bx offset into table to exact answer
				; (must clear carry b/c bp was shifted right
				; above, clearing the high bit. A clear carry
				; is what we want so we can return carry set
				; to indicate the value was actually found)
done:
	cmc			;set carry properly. If we ran out of table,
				; carry is set (upper is below lower) but
				; we want it clear. If we found the thing, the
				; carry is clear (see above) but we want it set.

	mov	bp, bx		; return table offset in bp
	ret
BinarySearch		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrQuickTangent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates a tangent of the passed angle (uses table lookup)

CALLED BY:	GLOBAL

PASS:		DX.AX	= Angle (WWFixed)

RETURN:		DX.AX	= Tangent

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrQuickTangent	proc	far
		uses	bx, cx
		.enter
	
		; Tangent = Sine / Cosine
		;
		movwwf	bxcx, dxax		; angle to => BX.CX
		call	GrQuickCosine		; cosine => DX.AX
		xchgwwf	bxcx, dxax
		call	GrQuickSine		; sine => DX.AX
		xchg	ax, cx			; sine => DX.CX, cosine => BX.AX
		call	GrSDivWWFixed		; tangent => DX.CX
		mov_tr	ax, cx			; tangent => DX.AX

		.leave
		ret
GrQuickTangent	endp

GraphicsObscure	ends
