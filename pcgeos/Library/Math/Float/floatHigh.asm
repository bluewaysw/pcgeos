
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name					Description
	----					-----------
	FloatAdd
	FloatDIV
	FloatDivide
	FloatZero				internal routine
	FloatZeroTail				internal routine
	FloatInfinity				internal routine
	FloatMultiply
	FloatMultiply2
	FloatMultiply10
	FloatDivide2
	FloatDivide10
	FloatFactorial
	FloatDoFactorial
	FloatFrac
	FloatInt
	FloatMod
	FloatNegate
	FloatOver
	FloatRandom
	FloatRandomize
	FloatRandomN
	FloatRoll
	FloatRot
	FloatRound
	FloatSub
	FloatSwap
	FloatInverse
	Float10ToTheX
	Float10ToTheX
	FloatIncorporatePwrOfTenMultiple	internal routine
	FloatTrunc
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:

	$Id: floatHigh.asm,v 1.1 97/04/05 01:23:02 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatAdd (originally /++)

DESCRIPTION:	Gives the sum of the top two numbers on the fp stack.
		( fp: X1 X2 --- X1+X2 )

CALLED BY:	INTERNAL (many)

PASS:		X1, X2 on fp stack (X2 = top)
		ds - fp stack seg

RETURN:		(X1+X2) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	align binary points
	add

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatAdd	proc	near	uses	bx,cx,bp,di,si
	.enter
EC<	call	FloatCheck2Args >

;	call	FloatGetSP_DSSI			; ds:si <- top of fp stack
	FloatGetSP_DSSI
	call	FloatIncSP_FPSIZE		; pop topmost fp num

	mov	bp, ds:[si].F_mantissa2_wd0
	mov	dx, ds:[si].F_mantissa2_wd1
	mov	di, ds:[si].F_mantissa2_wd2
	mov	bx, ds:[si].F_mantissa2_wd3
	mov	cx, ds:[si].F_exponent2

	; X2 in cx:bx:di:dx:bp

	and	ch, 7fh				; clear sign bit
	mov	ax, ds:[si].F_exponent1		; ax <- exp(X1)
	and	ah, 7fh				; clear sign bit
	cmp	cx, ax     			; exp(X2) - exp(X1)
	jl	regsSmaller
	jg	regsGreater

	cmp	bx, ds:[si].F_mantissa1_wd3
	jb	regsSmaller
	ja	regsGreater

	cmp	di,  ds:[si].F_mantissa1_wd2
	jb	regsSmaller
	ja	regsGreater

	cmp	dx,  ds:[si].F_mantissa1_wd1
	jb	regsSmaller
	ja	regsGreater

	cmp	bp,  ds:[si].F_mantissa1_wd0
	jbe	regsSmaller

regsGreater:
	;
	; registers contain larger value -- exchange
	;
	xchg	bp, ds:[si].F_mantissa1_wd0
	xchg	dx, ds:[si].F_mantissa1_wd1
	xchg	di, ds:[si].F_mantissa1_wd2
	xchg	bx, ds:[si].F_mantissa1_wd3
	mov	ax, ds:[si].F_exponent2
	xchg	ax, ds:[si].F_exponent1
	mov	ds:[si].F_exponent2, ax
	and	ah, 7fh
	xchg	ax, cx		;sign of result = sign of larger argument

regsSmaller:
	;
	; registers contain smaller value 
	; ax used for rounding:  highest bit is guard bit
	;                        second highest bit is round bit
	;                        logical OR of remaining bits for sticky bit
	sub	cx, ax
	neg	cx
	clr	ax
	cmp	cx, 10h
	jb	7$

	mov	ax, bp
	cmp	cx, 20h
	jae	3$

	mov	bp, dx
	mov	dx, di
	mov	di, bx
	clr	bx
	sub	cx, 10h
	jmp	short 7$

3$:
	or	al, ah
	xor	ah, ah
	or	ax, dx
	cmp	cx, 30h
	jae	4$

	mov	bp, di
	mov	dx, bx
	clr	di
	clr	bx
	sub	cx, 20h
	jmp	short 7$

4$:
	or	al, ah
	clr	ah
	or	ax, di
	cmp	cx, 40h
	jae	5$

	mov	bp, bx
	clr	dx
	clr	di
	clr	bx
	sub	cx, 30h
	jmp	short 7$

5$:
	or	al, ah
	clr	ah
	or	ax, bx
	clr	bp
	clr	dx
	clr	di
	clr	bx
	sub	cx, 40h
	jz	10$

	cmp	cx, 1
	je	8$

	or	al, ah
	clr	ah
	jmp	short 10$

7$:
	;
	; cx < 10
	;
	cmp	cx, 8
	jb	8$

	push	cx
	or	al, ah
	mov	cx, bp
	mov	ah, cl
	mov	cl, ch
	mov	ch, dl
	mov	bp, cx
	mov	dl, dh
	mov	cx, di
	mov	dh, cl
	mov	cl, ch
	mov	ch, bl
	mov	di, cx
	mov	bl, bh
	xor	bh, bh
	pop	cx
	sub	cx, 8
8$:
	;
	; cx < 8
	;
	jcxz	10$
	mov	ch, ah
	and	ah, 7fh
	or	al, ah
	mov	ah, ch
	and	ah, 80h
	xor	ch, ch

9$:
	shr	bx, 1
	rcr	di, 1
	rcr	dx, 1
	rcr	bp, 1
	rcr	ah, 1
	loop	9$


10$:
	;
	; binary points aligned
	;

	mov	cx, ds:[si].F_exponent2
	xor	cx, ds:[si].F_exponent1
	js	differentSigns

	;
	; arguments have same sign
	;
	add	bp, ds:[si].F_mantissa1_wd0
	adc	dx, ds:[si].F_mantissa1_wd1
	adc	di, ds:[si].F_mantissa1_wd2
	adc	bx, ds:[si].F_mantissa1_wd3
	jnc	11$

	or	al, ah
	clr	ah
	inc	ds:[si].F_exponent1
	stc
	rcr	bx, 1
	rcr	di, 1
	rcr	dx, 1
	rcr	bp, 1
	rcr	ah, 1

11$:
	test	ah, 80h
	jz	13$

	;
	; round smaller
	;
	test	ax, 7fffh
	jnz	12$

	;
	; round bigger
	;
	test	bp, 1
	jz	13$

	;
	; round even
	;
12$:
	add	bp, 1
	adc	dx, 0
	adc	di, 0
	adc	bx, 0
	jnc	13$

	;
	; carry set only if registers all 0
	;
	mov	bh, 80h
	inc	ds:[si].F_exponent1

13$:
	mov	ds:[si].F_mantissa1_wd0, bp
	mov	ds:[si].F_mantissa1_wd1, dx
	mov	ds:[si].F_mantissa1_wd2, di
	mov	ds:[si].F_mantissa1_wd3, bx
	jmp	done

differentSigns:
	;
	; arguments have different signs
	; bx:di:dx:bp
	;
	neg	ax
	sbb	ds:[si].F_mantissa1_wd0, bp
	sbb	ds:[si].F_mantissa1_wd1, dx
	sbb	ds:[si].F_mantissa1_wd2, di
	sbb	ds:[si].F_mantissa1_wd3, bx
	jns	16$

	test	ah, 80h		;no shift required
	jz	done

	;
	; round smaller
	;
	test	ax, 7fffh
	jnz	15$

	;
	; round bigger
	;
	test	ds:[si].F_mantissa1_wd0, 1
	jz	done

	;
	; round even
	;
15$:
	add	ds:[si].F_mantissa1_wd0, 1
	adc	ds:[si].F_mantissa1_wd1, 0
	adc	ds:[si].F_mantissa1_wd2, 0
	adc	ds:[si].F_mantissa1_wd3, 0
	;
	; cannot produce carry since rounding amount less than smaller argument
	;
	jmp	done

16$:
	test	{byte} ds:[si+11h], 0c0h
	jnz	17$

	dec	ds:[si].F_exponent1	;1 bit shift required -- exact result
	;
	; dec exponent
	;
	shl	ax, 1
	rcl	{word} ds:[si].F_mantissa1_wd0, 1
	rcl	{word} ds:[si].F_mantissa1_wd1, 1
	rcl	{word} ds:[si].F_mantissa1_wd2, 1
	rcl	{word} ds:[si].F_mantissa1_wd3, 1

	add	si, FPSIZE		; normalize X1
	call	FloatNormalize
	jmp	short done
17$:
	;
	; shift required after rounding
	;
	test	ah, 40h
	jz	19$

	;
	; round smaller
	;
	test	ax, 3fffh
	jnz	18$

	;
	; round bigger
	;
	test	ah, 80h
	jz	19$

18$:
	;
	; round even
	;
	add	ah, 80h
	adc	ds:[si].F_mantissa1_wd0, 0
	adc	ds:[si].F_mantissa1_wd1, 0
	adc	ds:[si].F_mantissa1_wd2, 0
	adc	ds:[si].F_mantissa1_wd3, 0
	test	ds:[si+11h], 80h
	jnz	done
19$:
	;
	; 1 bit shift required
	;
	dec	ds:[si].F_exponent1
	;
	; decrement exponent
	;
	shl	ax, 1
	rcl	ds:[si].F_mantissa1_wd0, 1
	rcl	ds:[si].F_mantissa1_wd1, 1
	rcl	ds:[si].F_mantissa1_wd2, 1
	rcl	ds:[si].F_mantissa1_wd3, 1
done:
	.leave
	ret
FloatAdd	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDIV

DESCRIPTION:	Performs the DIV operation.
		( fp: X1 X2 -- X3 )

CALLED BY:	INTERNAL ()

PASS:		X1, X2 on fp stack (X2 = top)
		ds - fp stack seg

RETURN:		X1 DIV X2 on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDIV	proc	near
EC<	call	FloatCheck2Args >

	call	FloatDivide
	GOTO	FloatTrunc
FloatDIV	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDivide

DESCRIPTION:	Performs floating point division.
		( fp: X1 X2 --- X1/X2 )

CALLED BY:	INTERNAL (many)

PASS:		X1, X2 on fp stack (X2 = top)
		ds - fp stack seg

RETURN:		(X1/X2) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDivide	proc	near	uses	bx,cx,di,si,bp
	.enter
EC<	call	FloatCheck2Args >

	call	FloatIsNoNAN2
	LONG jnc done

;	call	FloatGetSP_DSSI
	FloatGetSP_DSSI
	mov	cx, FPSIZE
	call	FloatIncSP
	sub	si, 8
	;
	; 1st argument will be at offsets  8,  A,  C,  E, and 10
	; 2nd argument will be at offsets 12, 14, 16, 18, and 1A
	;
	mov	ax, ds:[si+10h]
	or	ax, ax
	jnz	over

infinity:
	call	FloatInfinity
	jmp	done

over:
	mov	bx, ds:[si+1ah]
	or	bx, bx
	jnz	over2

zero:
	call	FloatZero
	jmp	done

over2:
	mov	ch, ah
	xor	ch, bh
	and	ch, 80h

	;
	; result sign
	;
	and	ah, 7fh
	and	bh, 7fh
	sub	bx, ax
	add	bx, 3fffh

	;
	; result exp + 1
	;
	jo	infinity

	dec	bx
	jle	zero

	and	bh, 7fh
	or	bh, ch
	mov	ds:[si+1ah], bx

	mov	bp, ds:[si+12h]
	mov	di, ds:[si+14h]
	mov	bx, ds:[si+16h]
	mov	dx, ds:[si+18h]
	xchg	bp,  ds:[si+8]
	xchg	di,  ds:[si+0ah]
	xchg	bx,  ds:[si+0ch]
	xchg	dx,  ds:[si+0eh]
	mov	ds:[si+12h], bp
	mov	ds:[si+14h], di
	mov	ds:[si+16h], bx
	mov	ds:[si+18h], dx
	clr	cx
	cmp	dx, ds:[si+0eh]
	jb	1$
	ja	2$

	cmp	bx, ds:[si+0ch]
	jb	1$
	ja	2$

	cmp	di, ds:[si+0ah]
	jb	1$
	ja	2$

	cmp	bp, ds:[si+8]
	ja	2$

1$:
	inc	cx
	sub	ds:[si+8], bp
	sbb	ds:[si+0ah], di
	sbb	ds:[si+0ch], bx
	sbb	ds:[si+0eh], dx

2$:
	push	cx

	;
	; highest bit of quotient
	;
	mov	cx, dx
	mov	dx, ds:[si+0ch]
	mov	ax, ds:[si+0eh]
	inc	cx
	jcxz	3$

	xchg	ax, dx
	div	cx
3$:
	clr	cx
	add	dx, ax
	rcl	cx, 1
	push	cx
	mov	ds:[si+0ch], dx
	mov	cx, ax

	;
	; quotient
	;
	mul	bp
	xchg	ax, di
	mov	bp, dx
	mul	cx
	add	bp, ax
	adc	dx, 0
	mov	ax, bx
	mov	bx, dx
	mul	cx
	add	ax, bx
	adc	dx, 0

	;
	; product of quotient and lower 3 words of 2nd arg in di, bp, ax, dx
	;
	neg	di
	mov	ds:[si+6], di
	sbb	ds:[si+8], bp
	sbb	ds:[si+0ah], ax
	sbb	ds:[si+0ch], dx
	pop	ax
	sbb	ax, 0

	;
	; ax contains highest word of remainder
	;
	mov	bp, ds:[si+12h]
	mov	di, ds:[si+14h]
	mov	bx, ds:[si+16h]
	mov	dx, ds:[si+18h]
	or	ax, ax
	jz	5$

4$:
	;
	; increment quotient
	;
	inc	cx
	sub	ds:[si+6], bp
	sbb	ds:[si+8], di
	sbb	ds:[si+0ah], bx
	sbb	ds:[si+0ch], dx
	sbb	ax, 0
	jnz	4$

5$:
	cmp	dx, ds:[si+0ch]
	jb	6$
	ja	7$

	cmp	bx, ds:[si+0ah]
	jb	6$
	ja	7$

	cmp	di, ds:[si+8]
	jb	6$
	ja	7$

	cmp	bp, ds:[si+6]
	ja	7$

6$:
	inc	cx
	sub	ds:[si+6], bp
	sbb	ds:[si+8], di
	sbb	ds:[si+0ah], bx
	sbb	ds:[si+0ch], dx
	jmp	5$

7$:
	mov	ds:[si+0eh], cx
	mov	cx, dx
	mov	dx, ds:[si+0ah]
	mov	ax, ds:[si+0ch]
	inc	cx
	jcxz	13$
	xchg	ax, dx
	div	cx

13$:
	clr	cx
	add	dx, ax
	rcl	cx, 1
	push	cx
	mov	ds:[si+0ah], dx
	mov	cx, ax
	;
	; quotient
	;
	mul	bp
	xchg	ax, di
	mov	bp, dx
	mul	cx
	add	bp, ax
	adc	dx, 0
	mov	ax, bx
	mov	bx, dx
	mul	cx
	add	ax, bx
	adc	dx, 0

	;
	; product of quotient and lower 3 words of 2nd arg in di, bp, ax, dx
	;
	neg	di
	mov	ds:[si+4], di
	sbb	ds:[si+6], bp
	sbb	ds:[si+8], ax
	sbb	ds:[si+0ah], dx
	pop	ax
	sbb	ax, 0

	;
	; ax contains highest word of remainder
	;
	mov	bp, ds:[si+12h]
	mov	di, ds:[si+14h]
	mov	bx, ds:[si+16h]
	mov	dx, ds:[si+18h]
	or	ax, ax
	jz	15$

14$:
	;
	;	 increment quotient
	;
	inc	cx
	sub	ds:[si+4], bp
	sbb	ds:[si+6], di
	sbb	ds:[si+8], bx
	sbb	ds:[si+0ah], dx
	sbb	ax, 0
	jnz	14$

15$:
	cmp	dx, ds:[si+0ah]
	jb	16$
	ja	17$

	cmp	bx, ds:[si+8]
	jb	16$
	ja	17$

	cmp	di, ds:[si+6]
	jb	16$
	ja	17$

	cmp	bp, ds:[si+4]
	ja	17$

16$:
	inc	cx
	sub	ds:[si+4], bp
	sbb	ds:[si+6], di
	sbb	ds:[si+8], bx
	sbb	ds:[si+0ah], dx
	jmp	15$

17$:
	mov	ds:[si+0ch], cx
	mov	cx, dx
	mov	dx, ds:[si+8]
	mov	ax, ds:[si+0ah]
	inc	cx
	jcxz	23$

	xchg	ax, dx
	div	cx
23$:
	clr	cx
	add	dx, ax
	rcl	cx, 1
	push	cx
	mov	ds:[si+8], dx
	mov	cx, ax

	;
	; quotient
	;
	mul	bp
	xchg	ax, di
	mov	bp, dx
	mul	cx
	add	bp, ax
	adc	dx, 0
	mov	ax, bx
	mov	bx, dx
	mul	cx
	add	ax, bx
	adc	dx, 0

	;
	; product of quotient and lower 3 words of 2nd arg in di, bp, ax, dx
	;
	neg	di
	mov	ds:[si+2], di
	sbb	ds:[si+4], bp
	sbb	ds:[si+6], ax
	sbb	ds:[si+8], dx
	pop	ax
	sbb	ax, 0

	;
	; ax contains highest word of remainder
	;
	mov	bp, ds:[si+12h]
	mov	di, ds:[si+14h]
	mov	bx, ds:[si+16h]
	mov	dx, ds:[si+18h]
	or	ax, ax
	jz	25$

24$:
	inc	cx
	;
	; increment quotient
	;
	sub	ds:[si+2], bp
	sbb	ds:[si+4], di
	sbb	ds:[si+6], bx
	sbb	ds:[si+8], dx
	sbb	ax, 0
	jnz	24$

25$:
	cmp	dx, ds:[si+8]
	jb	26$
	ja	27$

	cmp	bx, ds:[si+6]
	jb	26$
	ja	27$

	cmp	di, ds:[si+4]
	jb	26$
	ja	27$

	cmp	bp, ds:[si+2]
	ja	27$

26$:
	inc	cx
	sub	ds:[si+2], bp
	sbb	ds:[si+4], di
	sbb	ds:[si+6], bx
	sbb	ds:[si+8], dx
	jmp	25$

27$:
	mov	ds:[si+0ah], cx
	mov	cx, dx
	mov	dx, ds:[si+6]
	mov	ax, ds:[si+8]
	inc	cx
	jcxz	33$
	xchg	ax, dx
	div	cx

33$:
	clr	cx
	add	dx, ax
	rcl	cx, 1
	push	cx
	mov	ds:[si+6], dx
	mov	cx, ax

	;
	; quotient
	;
	mul	bp
	xchg	ax, di
	mov	bp, dx
	mul	cx
	add	bp, ax
	adc	dx, 0
	mov	ax, bx
	mov	bx, dx
	mul	cx
	add	ax, bx
	adc	dx, 0

	;
	; product of quotient and lower 3 words of 2nd arg in di, bp, ax, dx
	;
	neg	di
	mov	ds:[si], di
	sbb	ds:[si+2], bp
	sbb	ds:[si+4], ax
	sbb	ds:[si+6], dx
	pop	ax
	sbb	ax, 0
	;
	; ax contains highest word of remainder
	;
	mov	bp, ds:[si+12h]
	mov	di, ds:[si+14h]
	mov	bx, ds:[si+16h]
	mov	dx, ds:[si+18h]
	or	ax, ax
	jz	35$

34$:
	;
	; increment quotient
	;
	inc	cx
	sub	ds:[si], bp
	sbb	ds:[si+2], di
	sbb	ds:[si+4], bx
	sbb	ds:[si+6], dx
	sbb	ax, 0
	jnz	34$

35$:
	cmp	dx, ds:[si+6]
	jb	36$
	ja	37$

	cmp	bx, ds:[si+4]
	jb	36$
	ja	37$

	cmp	di, ds:[si+2]
	jb	36$
	ja	37$

	cmp	bp, ds:[si]
	ja	37$

36$:
	inc	cx
	sub	ds:[si], bp
	sbb	ds:[si+2], di
	sbb	ds:[si+4], bx
	sbb	ds:[si+6], dx
	jmp	35$

37$:
	;
	; division complete -- now test for rounding
	;
	mov	ds:[si+8], cx
	xor	al, al
	;
	; al will contain rounding bits
	;
	shr	dx, 1
	rcr	bx, 1
	rcr	di, 1
	rcr	bp, 1
	;
	; 2nd argument / 2
	;
	lahf
	cmp	dx, ds:[si+6]
	jb	38$
	ja	39$

	cmp	bx, ds:[si+4]
	jb	38$
	ja	39$

	cmp	di, ds:[si+2]
	jb	38$
	ja	39$

	cmp	bp, ds:[si]
	ja	39$

38$:
	mov	al, 0c0h
	jb	39$

	;
	; first 64 bits equal
	;
	clr	al
	inc	ah
	rcr	ax, 1

39$:
	mov	bp, ds:[si+8]
	mov	di, ds:[si+0ah]
	mov	bx, ds:[si+0ch]
	mov	dx, ds:[si+0eh]
	pop	cx
	shr	cx, 1
	jnc	40$

	rcr	dx, 1
	rcr	bx, 1
	rcr	di, 1
	rcr	bp, 1
	rcr	al, 1
	inc	{word} ds:[si+1ah]

40$:
	test	al, 80h
	jz	42$

	;
	; round smaller
	;
	test	al, 7fh
	jnz	41$

	;
	; round bigger
	;
	test	bp, 1
	jz	42$

	;
	; round even
	;
41$:
	add	bp, 1
	adc	di, 0
	adc	bx, 0
	adc	dx, 0
	jnc	42$

	rcr	dx, 1
	rcr	bx, 1
	rcr	di, 1
	rcr	bp, 1
	inc	{word} ds:[si+1ah]

42$:
	mov	ds:[si+12h], bp
	mov	ds:[si+14h], di
	mov	ds:[si+16h], bx
	mov	ds:[si+18h], dx
	or	dx, bx
	or	dx, di
	or	dx, bp
	jnz	done

	;
	; zero result
	;
	and	{word} ds:[si+1ah], 8000h

done:
	.leave
	ret
FloatDivide	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatZero

DESCRIPTION:	Utility routine for FloatDivide and FloatMultiply.

CALLED BY:	FloatZero	- FloatMultiply, FloatDivide
		FloatZeroTail	- FloatInfinity, fall through from FloatZero

PASS:		ds:si+8 - X1 
		ds:si+12h - X2

RETURN:		

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatZero	proc	near
	;
	; zero out X2
	;
	clr	ax
	mov	ds:[si+1ah], ax
	mov	ds:[si+18h], ax
	FALL_THRU	FloatZeroTail
FloatZero	endp

FloatZeroTail	proc	near
	clr	ax
	mov	ds:[si+12h], ax
	mov	ds:[si+14h], ax
	mov	ds:[si+16h], ax
	ret
FloatZeroTail	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatInfinity

DESCRIPTION:	Utility routine for FloatDivide and FloatMultiply.

CALLED BY:	INTERNAL (FloatMultiply, FloatDivide)

PASS:		ds:si+12h - fp number to make infinity

RETURN:		

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatInfinity	proc	near
	mov	ax, ds:[si+10h]			; exp(X1)
	xor	ax, ds:[si+1ah]			; exp(X2), get sign of mult/div
	and	ax, 8000h			; isolate sign bit
	or	ax, 7fffh			; set all other bits to get NAN
	mov	ds:[si+1ah], ax			; store exp
	mov	{word} ds:[si+18h], 8000h	; indicate number is infinity
	GOTO	FloatZeroTail
FloatInfinity	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatMultiply (originally /**)

DESCRIPTION:	Performs floating point multiplication.
		( fp: X1 X2 --- X1*X2 )

CALLED BY:	INTERNAL (many)

PASS:		X1, X2 on fp stack (X2 = top)
		ds - fp stack seg

RETURN:		(X1*X2) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatMultiply	proc	near	uses	bx,cx,di,si,bp
	.enter
EC<	call	FloatCheck2Args >

	call	FloatIsNoNAN2		; if either number is NAN, result
	LONG jnc done			; ...is also NAN

;	call	FloatGetSP_DSSI		; ds:si <- top of fp stack
	FloatGetSP_DSSI
	call	FloatIncSP_FPSIZE	; drop top number

	sub	si, 8
	;
	; 1st argument will be at offsets  8,  A,  C,  E, and 10
	; 2nd argument will be at offsets 12, 14, 16, 18, and 1A
	;

	;
	; if either number is 0, result is 0
	;
	mov	ax, ds:[si+10h]		; ax <- exp(X1)
	or	ax, ax
	LONG jz	zero

	mov	bx, ds:[si+1ah]		; bx <- exp(X2)
	or	bx, bx
	LONG jz	zero

	;
	; result sign
	;
	mov	ch, ah
	xor	ch, bh
	and	ch, 80h			; isolate sign bit

	and	ah, 7fh			; remove sign bit
	and	bh, 7fh			; remove sign bit
	add	ax, bx
	sub	ax, 3ffeh
	;
	; result exponent
	;
	LONG jbe	zero

	cmp	ax, 7ffeh		; overflow ?
	LONG jae	infinity	; infinity if so

	and	ah, 7fh
	or	ah, ch
	mov	ds:[si+1ah], ax		; store exponent of result

	clr	bp
	clr	di
	clr	bx
	mov	ds:[si], bx
	mov	ds:[si+2], bx
	;
	; VP code did not clear words 6 and 8
	; led to multiplies like PI^2 being off
	; if these locations were non-zero
	;
	mov	ds:[si+4], bx
	mov	ds:[si+6], bx

	mov	cx, ds:[si+8]
	jcxz	4$

	mov	ax, ds:[si+12h]
	or	ax, ax
	jz	1$

	mul	cx
	mov	ds:[si], ax
	mov	ds:[si+2], dx

1$:
	mov	ax, ds:[si+14h]
	or	ax, ax
	jz	2$

	mul	cx
	add	ds:[si+2], ax
	adc	bp, dx

2$:
	mov	ax, ds:[si+16h]
	or	ax, ax
	jz	3$

	mul	cx
	add	bp, ax
	adc	di, dx

3$:
	mov	ax, ds:[si+18h]
	or	ax, ax
	jz	4$

	mul	cx
	add	di, ax
	adc	bx, dx

4$:
	mov	ds:[si+4], bp
	clr	bp
	mov	cx, ds:[si+0ah]
	jcxz	14$

	mov	ax, ds:[si+12h]
	or	ax, ax
	jz	11$

	mul	cx
	add	ds:[si+2], ax
	adc	ds:[si+4], dx
	adc	di, 0
	adc	bx, 0
	adc	bp, 0

11$:
	mov	ax, ds:[si+14h]
	or	ax, ax
	jz	12$

	mul	cx
	add	ds:[si+4], ax
	adc	di, dx
	adc	bx, 0
	adc	bp, 0

12$:
	mov	ax, ds:[si+16h]
	or	ax, ax
	jz	13$

	mul	cx
	add	di, ax
	adc	bx, dx
	adc	bp, 0

13$:
	mov	ax, ds:[si+18h]
	or	ax, ax
	jz	14$

	mul	cx
	add	bx, ax
	adc	bp, dx

14$:
	mov	ds:[si+6], di
	clr	di
	mov	cx, ds:[si+0ch]
	jcxz	24$

	mov	ax, ds:[si+12h]
	or	ax, ax
	jz	21$

	mul	cx
	add	ds:[si+4], ax
	adc	ds:[si+6], dx
	adc	bx, 0
	adc	bp, 0
	adc	di, 0

21$:
	mov	ax, ds:[si+14h]
	or	ax, ax
	jz	22$

	mul	cx
	add	ds:[si+6], ax
	adc	bx, dx
	adc	bp, 0
	adc	di, 0

22$:
	mov	ax, ds:[si+16h]
	or	ax, ax
	jz	23$

	mul	cx
	add	bx, ax
	adc	bp, dx
	adc	di, 0

23$:
	mov	ax, ds:[si+18h]
	or	ax, ax
	jz	24$

	mul	cx
	add	bp, ax
	adc	di, dx

24$:
	mov	ds:[si+8], bx
	clr	bx
	mov	cx, ds:[si+0eh]
	jcxz	34$

	mov	ax, ds:[si+12h]
	or	ax, ax
	jz	31$

	mul	cx
	add	ds:[si+6], ax
	adc	ds:[si+8], dx
	adc	bp, 0
	adc	di, 0
	adc	bx, 0

31$:
	mov	ax, ds:[si+14h]
	or	ax, ax
	jz	32$

	mul	cx
	add	ds:[si+8], ax
	adc	bp, dx
	adc	di, 0
	adc	bx, 0

32$:
	mov	ax, ds:[si+16h]
	or	ax, ax
	jz	33$

	mul	cx
	add	bp, ax
	adc	di, dx
	adc	bx, 0

33$:
	mov	ax, ds:[si+18h]
	or	ax, ax
	jz	34$

	mul	cx
	add	di, ax
	adc	bx, dx

34$:
	;
	; multiplication of fractions complete
	;
	mov	dx, ds:[si+8]
	mov	ax, ds:[si]
	or	ax, ds:[si+2]
	or	ax, ds:[si+4]
	or	al, ah
	xor	ah, ah
	or	ax, ds:[si+6]

	;
	; ax contains rounding bits
	;
	or	bx, bx
	js	35$

	dec	{word} ds:[si+1ah]
	shl	ax, 1
	rcl	dx, 1
	rcl	bp, 1
	rcl	di, 1
	rcl	bx, 1

35$:
	test	ah, 80h
	jz	37$

	;
	; round smaller
	;
	test	ax, 7fffh
	jnz	36$

	;
	; round bigger
	;
	test	dx, 1
	jz	37$

	;
	; round even
	;
36$:
	add	dx, 1
	adc	bp, 0
	adc	di, 0
	adc	bx, 0
	jnc	37$

	;
	; registers contain all zeroes
	;
	mov	bh, 80h
	inc	{word} ds:[si+1ah]

37$:
	mov	ds:[si+12h], dx
	mov	ds:[si+14h], bp
	mov	ds:[si+16h], di
	mov	ds:[si+18h], bx
	or	bx, di
	or	bx, bp
	or	bx, dx
	jnz	done

	;
	; zero product
	;
	and	{word} ds:[si+1ah], 8000h

done:
	.leave
	ret

zero:
	call	FloatZero
	jmp	short done

infinity:
	call	FloatInfinity
	jmp	short done

FloatMultiply	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatMultiply2 (originally /2.*)

DESCRIPTION:	Multiplies the floating point number on the top of the stack
		by 2. ( FP: X --- 2X )

CALLED BY:	INTERNAL (FloatExpBC, FloatSin, FloatASin)

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		2X on fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatMultiply2	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatSign		; destroys bx
	je	done			; done if 0

	mov	bx, 1			; else multiply by 2^1
	call	Float2Scale		; destroys nothing
done:
	.leave
	ret
FloatMultiply2	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatMultiply10 (originally /10.*)

DESCRIPTION:	Multiplies the number on the top of the fp stack by 10.
		( fp: X --- 10X )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		10X on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Let m*2^e be the number, where m is the mantissa and e the exponent

	then 10 * m*2b^e is = (1.25*2^3) * m*2^e
			    = 1.25*m * 2^(e+3)

	1.25*m can be gotten by shifting the mantissa right twice
	e+3 can be gotten by adding 3 to the exponent

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatMultiply10	proc	near	uses	bx,cx,bp,es,di,si
	.enter
EC<	call	FloatCheck1Arg >

;	call	FloatGetSP_ESDI		; es:di <- top of fp stack
	FloatGetSP_ESDI

	mov	ax, es:[di].F_exponent	; ax <- exponent
	test	ax, 7fffh		; 0?
	jz	done			; done if so

	clr	bx
	mov	bp, es:[di].F_mantissa_wd0
	mov	si, es:[di].F_mantissa_wd1
	mov	dx, es:[di].F_mantissa_wd2
	mov	cx, es:[di].F_mantissa_wd3

	; cx:dx:si:bp - mantissa, ax - exponent

	shr	cx, 1			; get m/2
	rcr	dx, 1
	rcr	si, 1
	rcr	bp, 1
	rcr	bx, 1

	shr	cx, 1			; get m/4
	rcr	dx, 1
	rcr	si, 1
	rcr	bp, 1
	rcr	bx, 1

	add	bp, es:[di].F_mantissa_wd0	; add m to get 1.25*m
	adc	si, es:[di].F_mantissa_wd1
	adc	dx, es:[di].F_mantissa_wd2
	adc	cx, es:[di].F_mantissa_wd3
	jnc	1$

	rcr	cx, 1
	rcr	dx, 1
	rcr	si, 1
	rcr	bp, 1
	rcr	bx, 1
	inc	ax
1$:
	test	bh, 80h
	jz	3$

	; round smaller
	test	bh, 7fh
	jnz	2$

	; round bigger
	test	bp, 1
	jz	3$

2$:
	; round even
	add	bp, 1
	adc	si, 0
	adc	dx, 0
	adc	cx, 0
	jnc	3$

	mov	ch, 80h
	inc	ax
3$:
	add	ax, 3
	mov	es:[di].F_exponent, ax
	mov	es:[di].F_mantissa_wd0, bp
	mov	es:[di].F_mantissa_wd1, si
	mov	es:[di].F_mantissa_wd2, dx
	mov	es:[di].F_mantissa_wd3, cx
done:
	.leave
	ret
FloatMultiply10	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDivide2 (originally /2./)

DESCRIPTION:	Divides the number on the top of the fp stack by 2.
		( FP: X --- X/2 )

CALLED BY:	INTERNAL (FloatSqrt, FloatLn1plusX, FloatDoLn, FloatASin)

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X/2 on fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Let m*2^e be the number, where m is the mantissa and e the exponent

	dividing X by 2 is then just m*2^(e-1)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDivide2	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatSign		; destroys bx
	je	done

	mov	bx, -1
	call	Float2Scale		; destroys nothing
done:
	.leave
	ret
FloatDivide2	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDivide10

DESCRIPTION:	Divides the number on the top of the fp stack by 10.
		( fp: X -- X/10 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X/10 on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDivide10	proc	near
EC<	call	FloatCheck1Arg >

	call	Float10
	call	FloatDivide
	ret
FloatDivide10	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFactorial

DESCRIPTION:	Returns the factorial of the given number.

CALLED BY:	INTERNAL (FloatDispatch, not used internally)

PASS:		X on fp stack

RETURN:		X! on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	probably easiest implemented by using recursion but large Xs (~1000)
	will probably test stack limits

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFactorial	proc	near	uses	cx
	.enter
	call	FloatInt		; round down (floor)
	call	FloatFloatToDword	; dx:ax <- integer
	mov	cx, ax

	;
	; error check argument
	;
	tst	dx
	jne	err

	cmp	ax, FACTORIAL_LIMIT
	jg	err

	call	FloatDoFactorial
done:
	.leave
	ret

err:
	call	FloatErr
	jmp	short done
FloatFactorial	endp


FloatDoFactorial	proc	near
	call	Float1

doFact:
	cmp	cx, 1
	jle	done

	mov	ax, cx
	call	FloatWordToFloat
	call	FloatMultiply
	dec	cx
	jmp	short doFact

done:
	ret
FloatDoFactorial	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFrac

DESCRIPTION:	Returns the fractional portion of the number.
		See also FloatTrunc.

CALLED BY:	INTERNAL (FloatDispatch, not used internally)

PASS:		X on fp stack

RETURN:		frac(X) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatFrac	proc	near
EC<	call	FloatCheck1Arg >

	call	FloatIntFrac
	call	FloatSwap
	FloatDrop trashFlags
	ret
FloatFrac	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatInt

DESCRIPTION:	Implements the INT() function.

		Rounds a number down to the nearest integer.
		INT(7.8) equals 7
		INT(-7.8) equals -8

		Related:
		* TRUNC truncates a number to an integer by removing the
		fractional part.
		* ROUND rounds a number to a specified number of digits.
		* MOD returns the remainder from division.

CALLED BY:	INTERNAL (FloatDispatch, not used internally)

PASS:		ds - fp stack seg
		X on fp stack

RETURN:		int(X) on fp stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatInt	proc	near	uses	bx
	.enter

	call	FloatSign
	pushf
	call	FloatIntFrac		; ( fp: i f )
	popf
	jge	done			; done if number was positive

	call	FloatEq0		; fractional portion = 0?
	je	exit			; done if so

	call	Float1			; else dec number, ( fp: i 1 )
	call	FloatSub		; ( fp: i-1)
	jmp	short exit

done:
	FloatDrop trashFlags		; lose fraction, ( fp: i )
	
exit:
	.leave
	ret
FloatInt	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatMod

DESCRIPTION:	Implements the MOD() function.
		MOD returns the remainder from division.
		( fp: X1 X2 -- X3 )

		Related:
		* TRUNC truncates a number to an integer by removing the
		fractional part.
		* INT rounds a number down to the nearest integer.
		* ROUND rounds a number to a specified number of digits.

CALLED BY:	INTERNAL (FloatDispatch, not used internally)

PASS:		X1, X2 on fp stack (X2 = top)
		ds - fp stack seg

RETURN:		X1 MOD X2 on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
for stack info, first part is operand stack, / is base of return stack, and
    | is base of FP stack

: FMOD   ( FP: X1 X2 --- X3 ) ( KMB 851030 )
  ?NONAN2
  IF FABS FSIGN ?DUP
    IF ( sign-of-|X2| )
      FSWAP FSIGN ( sign-of-|X2| sign-of-X1 )
      >R ( sign-of-|X2| )
      FABS FSIGN   2DUP <=   ( FS2' FS1' F / FS1 | |X2| |X1| )
      IF - NEGATE 0 SWAP   ( 0 N / FS1 | |X2| |X1| )
        DO FOVER I 2SCALE ( / FS1 I | |X2| |X1| |X2|*2^I )
	  FCOMP 0< ( F / FS1 I | |X2| |X1| |X2|*2^I )
          IF FDROP ( drop scaled modulus )  ELSE --
          THEN   ( / FS1 | |X2| |X3'| )
        -1 +LOOP
      ELSE ( drop exponents, as already have remainder ) 2DROP
      THEN
      R> ( FS1 / | |X2| rem ) 
      0< IF FNEGATE   THEN FSWAP FDROP
    ELSE ( X2 is 0, so drop both and err ) FDROP FDROP FERR
    THEN
  THEN ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatMod	proc	near	uses	bx,cx,di
	.enter
EC<	call	FloatCheck2Args >

	call	FloatIsNoNAN2
	jnc	done

	call	FloatAbs
	call	FloatSign
	tst	bx			; MOD 0 ?
	je	cleanStack		; error if so

	; since MOD is only defined for integers, round the numbers
	clr	al
	call	FloatRound
	; bx is non-zero

	mov	cx, bx			; cx <- exp(abs(X2))
	call	FloatSwap
	call	FloatSign
	mov	di, bx			; di <- exp(X1)

	clr	al
	call	FloatAbs
	call	FloatRound		; round the other number
	call	FloatSign		; bx <- exp(abs(X1))

	;
	; bx = exp(abs(X1)), di = exp(X1), cx = exp(abs(X2))
	;

	cmp	cx, bx			; X2 > X1 ?
	jg	modGotten		; branch if so

	;
	; cx <= bx, exp(abs(X2)) <= exp(abs(X1))
	;

	sub	cx, bx
	neg	cx

modLoop:
	call	FloatOver
	mov	bx, cx
	call	Float2Scale	; FP: |MOD| |DIV| |MOD|*2^I
	call	FloatComp
	jge	doSub

	FloatDrop trashFlags	; drop too-large |MOD|*2^I
	jmp	short over

doSub:
	call	FloatSub

over:
	dec	cx
	cmp	cx, 0
	jge	modLoop

modGotten:
	cmp	di, 0			; exp X1 < 0 ?
	jge	signOK

	call	FloatNegate

signOK:
	call	FloatSwap
	FloatDrop trashFlags
	jmp	short done

cleanStack:
	FloatDrop trashFlags
	FloatDrop trashFlags
	call	FloatErr
done:
	.leave
	ret
FloatMod	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatNegate (originally /FNEGATE)

DESCRIPTION:	Negates the number on the top of the fp stack.
		( fp: X --- -X )

CALLED BY:	INTERNAL (many)

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		-X on fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	toggle the sign bit

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatNegate	proc	near	uses	bx,si
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatSign
	je	done

;	call	FloatGetSP_DSSI		; ds:si <- top of fp stack
	FloatGetSP_DSSI
	xor	{byte} ds:[si+9], 80h	; toggle sign bit

done:
	.leave
	ret
FloatNegate	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatOver (originally /FOVER)

DESCRIPTION:	Copies the second number on the fp stack to the top
		of the stack.
		( fp: X1 X2 --- X1 X2 X1 )

CALLED BY:	INTERNAL (many)

PASS:		X1, X2 on fp stack (X2 = top)
		ds - fp stack seg

RETURN:		X1 copied to the top of the fp stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatOver	proc	near	uses	bx
	.enter
EC<	call	FloatCheck2Args >

	mov	bx, 2
	call	FloatPick		; destroys ax
	.leave
	ret
FloatOver	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatRandom

DESCRIPTION:	FloatRandom returns a number between 0 (inclusive) and 1
		(exclusive).  See also FloatRandomN.

CALLED BY:	INTERNAL (FloatDispatch, FloatRandomN)

PASS:		ds - fp stack seg
		seed on the fp stack

RETURN:		random number on the fp stack,
		0 <= X < 1

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	We want to generate a number such that a list of such generated numbers
	will satisfy all of the statistical tests that a random sequence
	would satisfy.

	Algorithm taken from Knuth Vol 2 Chapter 3 - Random Numbers
	-----------------------------------------------------------

	The linear congruential method:

	The detailed investigations suggest that the following procedure
	will generate "nice" and "simple" random numbers.  At the beginning
	of the program, set an integer variable X to some value Xo.  This
	variable X is to be used only for the purpose of random number
	generation. Whenever a new random number is required by the program,
	set
		X <- (aX + c) mod m
	
	and use the new value of X as the random value.  It is necessary to
	choose Xo, a, c, and m properly, according to the following principles:

	1)  The "seed" number Xo may be chosen arbitrarily.  We use the
	    current date and time since that is convenient.
	
	2)  The number m should be large, say at least 2^30.  The computation
	    of (aX + c)mod m must be done exactly, with no roundoff error.
	
	3)  If m is a power of 2, pick a so that a mod 8 = 5.
	    If m is a power of 10, choose a so that a mod 200 = 21.

	    The choice of a together with the choice of c given below
	    ensures that the random number generator will produce all
	    m different possible values of X before it starts to repeat
	    and ensures high "potency".

	4)  The multiplier a should preferably be chosen between 0.01m
	    0.99m, and its binary or decimal digits should not have a simple
	    regular pattern.  By choosing a = 314159261 (which satisfies
	    both of the conditions in 3), one almost always obtains a
	    reasonably good multiplier.  There are several tests that can
	    be performed before it is considered to have a truly clean
	    bill of health.
	
	5)  The value of c is immaterial when a is a good multiplier,
	    except that c must have no factor in common with m.
	    Thus we may choose c=1 or c=a.
	
	6)  The least significant digits of X are not very random, so
	    decisions based on the number X should always be influenced
	    primarily by the most significant digits.

	    It is generally best to think of X as a random fraction
	    between 0 and 1.  To compute a random integer between 0
	    and k-1, one should multiply by k and truncate the result.
	
	Implementation notes:
	---------------------

	Desirable properties:

	* the same seed generates the same sequence of random numbers

	* 2 different threads accessing the routine will not lose
	  their "place" in the random number sequence.  This is important
	  because the property of Uniform Distribution will be adversely
	  affected if one thread's behaviour can alter the next number
	  seen by another thread.

	  This "state" is wholly represented by X since the other
	  parameters a, c, and m are hardwired in the code.  The
	  question then is where to save X.  We can force the user
	  to preserve X on the floating point stack but that may
	  be inconvenient because the caller will then have to
	  place calls to FloatDup to duplicate the number and pop
	  it off when done.

	  We instead save X in the floating point stack header.
	  This costs 5 words and it seems affordable.
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatRandomInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	internal call to FloatRandom
CALLED BY:	INTERNAL

	see upbove header for FloatRandom
	exported for coprocessor libriaries		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatRandomInternal	proc	far
	call	FloatRandom
	ret
FloatRandomInternal	endp
	public	FloatRandomInternal

RANDOM_A	=	3141592621
RANDOM_M_EXP	=	32

FloatRandom	proc	near	uses	bx,dx,ds,es,di,si
	.enter
	segmov	es,ds,di		; es <- fp stack seg

	;
	; retrieve X from stack
	;
	mov	si, offset FSV_randomX
	call	FloatPushNumber

	mov	dx, high RANDOM_A
	mov	ax, low RANDOM_A
	call	FloatDwordToFloat	; ( fp: X a )
	call	FloatMultiply		; ( fp: aX )

	call	Float1
	call	FloatAdd		; ( fp: aX+c )

	;
	; perform mod m
	;
	mov	bx, -RANDOM_M_EXP
	call	Float2Scale

	call	FloatIntFrac		; ( fp: int frac )
	call	FloatSwap		; ( fp: frac int )
	FloatDrop trashFlags		; lose integer portion

	;
	; ( fp: X/2^32 ) = number that satisfies [0,1)
	; we will return this to the caller
	; after we save X in the fp stack header
	;

	call	FloatDup
	neg	bx
	call	Float2Scale		; ( fp: X )

	;
	; error check X
	; X must satisfy:
	;	0 <= X < 2^32
	;	X must be an integer
	;
;EC<	call	FloatDup >
EC<	call	FloatDup >
EC<	push	bx >
EC<	call	FloatExpFrac		; bx - unbiased exp >
EC<	FloatDrop	 		; lose frac >
EC<	cmp	bx, RANDOM_M_EXP >
EC<	ERROR_GE FLOAT_ASSERTION_FAILED >
EC<	pop	bx >
if 0
;EC<	call	FloatIntFrac >
;EC<	call	FloatEq0 >
;EC<	ERROR_NC FLOAT_ASSERTION_FAILED >
;EC<	FloatDrop			; lose integer >
endif
	mov	di, si			; es:di <- stkRandomX
	call	FloatPopNumber
	.leave
	ret
FloatRandom	endp
	public	FloatRandom

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatRandomize

DESCRIPTION:	Prime the random number generator. The caller may choose to
		pass a seed or have the routine generate one. 

		If the seed is small ( << 2^32 ), the random number
		generator needs to be primed before use by calling
		FloatRandom and discarding the results.

CALLED BY:	INTERNAL (FloatRandomFar, FloatInit)

PASS:		al - RandomGenInitFlags
		     RGIF_USE_SEED
		     RGIF_GENERATE_SEED
		cx:dx - seed if RGIF_USE_SEED
		ds - fp stack seg

RETURN:		nothing

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatRandomizeInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	internal call to FloatRandomize
CALLED BY:	INTERNAL

	see upbove header for FloatRandomize
	exported for coprocessor libriaries		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatRandomizeInternal	proc	far
	call	FloatRandomize
	ret
FloatRandomizeInternal	endp
	public	FloatRandomizeInternal

FloatRandomize	proc	near	uses	bx,cx,es,di
	.enter

EC<	push	ax >
EC<	test	al, not (mask RGIF_USE_SEED or mask RGIF_GENERATE_SEED) >
EC<	ERROR_NZ FLOAT_BAD_FLAGS >
EC<	test	al, mask RGIF_USE_SEED >
EC<	je	ok >
EC<	test	al, mask RGIF_GENERATE_SEED >
EC<	ERROR_NZ FLOAT_BAD_FLAGS >
EC< ok: >
EC<	pop	ax >

	;-----------------------------------------------------------------------
	; get the seed Xo

	test	al, mask RGIF_USE_SEED
	jne	seedGotten

	;
	; user wants us to generate seed
	;
	call	TimerGetDateAndTime	; use cx:dx - day, hour, min, sec
					; ax, bx destroyed

seedGotten:
	; cx:dx = seed

	mov	ax, dx			; dx:ax <- seed
	mov	dx, cx
	call	FloatDwordToFloat

	segmov	es,ds,di
	mov	di, offset FSV_randomX
	call	FloatPopNumber

	;-----------------------------------------------------------------------
	; prime the random number generator
	; necessary to get the numbers large enough when a small seed is used
	; more calls may be needed if a smaller RANDOM_A is used,
	; less if a larger RANDOM_A is used

	call	FloatRandom
	call	FloatRandom
	call	FloatRandom

	mov	cx, FPSIZE*3
	call	FloatIncSP		; drop the numbers
	.leave
	ret
FloatRandomize	endp
	public	FloatRandomize

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatRandomN

DESCRIPTION:	Returns a random integer between 0 and N-1.

CALLED BY:	INTERNAL (FloatDispatch)

PASS:		N on fp stack, 0 <= N < 2^31
		ds - fp stack seg

RETURN:		int between 0 and N-1 on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatRandomNInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	internal call to FloatRandomN
CALLED BY:	INTERNAL

	see upbove header for FloatRandomN
	exported for coprocessor libriaries		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatRandomNInternal	proc	far
	call	FloatRandomN
	ret
FloatRandomNInternal	endp
	public	FloatRandomNInternal

FloatRandomN	proc	near
EC<	call	FloatCheck1Arg >

	call	FloatDup
	call	Float0
	call	FloatCompAndDrop
	jg	proceed

	FloatDrop trashFlags
	call	FloatErr
	jmp	short done

proceed:
	;
	; the real work...
	;
	call	FloatRandom		; ( fp: X' r )
	call	FloatMultiply		; ( fp: r*X' )
	call	FloatTrunc		; ( fp: R )
done:
	ret
FloatRandomN	endp
	public	FloatRandomN

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatRoll (originally /FROLL)

DESCRIPTION:	Moves the specified fp number to the top of the fp stack
		( N --- ) ( fp: X1 X2 ... XN --- XN X1 X2 ... XN-1 )

CALLED BY:	INTERNAL (FloatSwap, FloatRot)

PASS:		bx = N
		ds - fp stack seg

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	achieved via block moves

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatRollInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	internal call to FloatRoll
CALLED BY:	INTERNAL

	see upbove header for FloatRoll
	exported for coprocessor libriaries		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatRollInternal	proc	far
	call	FloatRoll
	ret
FloatRollInternal	endp
	public	FloatRollInternal

FloatRoll	proc	near	uses	cx,es,di,si
	.enter
EC<	call	FloatCheckNArgs >

	mov	al, FPSIZE
	mul	bl			; ax <- offset to fp num

;	call	FloatGetSP_ESDI		; es:di <- top of fp stack
	FloatGetSP_ESDI

	sub	di, FPSIZE
	mov	si, di
	add	si, ax

	mov	cx, FPSIZE/2
	rep	movsw

	mov	cx, si
	sub	cx, di
	dec	si
	dec	si
	mov	di, si
	sub	si, FPSIZE
	shr	cx, 1
	std
	rep	movsw
	cld
	.leave
	ret
FloatRoll	endp
	public FloatRoll

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatRollDown (originally /FROLL)

DESCRIPTION:	Moves the top of the fp stack to the Nth spot in the stack
		( N --- ) ( fp: X1 X2 ... XN --- X2 ... XN X1 )

CALLED BY:	INTERNAL (FloatSwap, FloatRot)

PASS:		bx = N
		ds - fp stack seg

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	achieved via block moves

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatRollDownInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	internal call to FloatRollDown
CALLED BY:	INTERNAL

	see upbove header for FloatRollDown
	exported for coprocessor libriaries		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/29/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatRollDownInternal	proc	far
	call	FloatRollDown
	ret
FloatRollDownInternal	endp
	public	FloatRollDownInternal

FloatRollDown	proc	near	uses	cx,es,di,si
	.enter
EC<	call	FloatCheckNArgs >

	;
	; shift bl elements down
	;
;	call	FloatGetSP_ESDI		; es:di <- top of fp stack
	FloatGetSP_ESDI

	mov	si, di
	mov	ax, FPSIZE
	sub	di, ax
	push	di

	mul	bl			; ax <- num bytes to Roll
	mov	cx, ax			; cx <- num bytes
	shr	cx, 1			; cx <- num words
	rep	movsw

	pop	si
	mov	cx, FPSIZE/2
	rep	movsw

	.leave
	ret
FloatRollDown	endp
	public FloatRollDown

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatRot (originally /FROT)

DESCRIPTION:	Performs a rotation of the top 3 numbers on the fp stack.
		( fp: X1 X2 X3 --- X2 X3 X1 )

CALLED BY:	INTERNAL (many)

PASS:		X1, X2, X3 on fp stack (X3 = top)
		ds - fp stack seg

RETURN:		X2, X3, X1 on fp stack (X1 = top)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatRot	proc	near	uses	bx
	.enter
	mov	bx, 3
EC<	call	FloatCheckNArgs >

	call	FloatRoll		; destroys ax
	.leave
	ret
FloatRot	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatRound

DESCRIPTION:	Rounds a number to the given number of decimal places.
		See also RoundNumber which is an internal routine that
		is also capable of rouding normalized floating point numbers.

		Related:
		* TRUNC truncates a number to an integer by removing the
		fractional part.
		* INT rounds a number down to the nearest integer.
		* MOD returns the remainder from division.

CALLED BY:	INTERNAL (FloatDispatch, not used internally)

PASS:		al - number of decimal places to round to
		X on fp stack
		ds - fp stack seg

RETURN:		X rounded to al decimal places

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatRound	proc	near	uses	bx
	.enter
	call	FloatSign
	pushf
	jge	10$
	call	FloatAbs
10$:
	clr	ah
	push	ax
	call	Float10ToTheX
	call	FloatMultiply

	call	FloatPoint5
	call	FloatAdd
	call	FloatTrunc

	pop	ax
	neg	ax
	call	Float10ToTheX
	call	FloatMultiply

	popf
	jge	done
	call	FloatNegate
done:
	.leave
	ret
FloatRound	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatSub (originally /--)

DESCRIPTION:	Perform floating point subtraction.
		( FP: X1 X2 --- X3 )

CALLED BY:	INTERNAL (many)

PASS:		X1, X2 on fp stack (X2 = top)
		ds - fp stack seg

RETURN:		X1-X2 on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	X1 - X2  =  X1 + (-X2)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatSub	proc	near
	call	FloatNegate		; destroys nothing
	call	FloatAdd		; destroys ax,dx
	ret
FloatSub	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatSwap (originally /FSWAP)

DESCRIPTION:	Swaps the top two numbers on the floating point stack.
		( fp: X1 X2 --- X2 X1 )

CALLED BY:	INTERNAL (many)

PASS:		X1, X2 on fp stack (X2 = top)
		ds - fp stack seg

RETURN:		X2, X1 on fp stack (X1 = top)

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatSwap	proc	near	uses	bx
	.enter
	mov	bx, 2
	call	FloatRoll		; destroys ax
	.leave
	ret
FloatSwap	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatInverse (originally 1/X)

DESCRIPTION:	Performs the inverse operation.
		( FP: X --- 1/X )

CALLED BY:	INTERNAL (FloatArcTan, FloatComputeTan)

PASS:		fp number X on the fp stack
		ds - fp stack seg

RETURN:		1/X on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
    1/X   1. FSWAP // ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatInverse	proc	near
EC<	call	FloatCheck1Arg >
	call	Float1			; destroys ax,dx
	call	FloatSwap		; destroys ax
	call	FloatDivide		; destroys ax,dx
	ret
FloatInverse	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	Float10ToTheX

DESCRIPTION:	Given an integer exponent x, returns a fp number that is 10^x.

CALLED BY:	INTERNAL (FloatFloatToAscii, FloatRound)

PASS:		ax - exponent, 
		DECIMAL_EXPONENT_LOWER_LIMIT<=ax<=DECIMAL_EXPONENT_UPPER_LIMIT

RETURN:		10^ax on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:
	bx - boolean - negative exponent
	cx - 10 (decimal divisor and also size of fp nums)

PSEUDO CODE/STRATEGY:
	assertion - looping to generate 10^x is undesirable for large x

	employ these facts:
		10^(a+b) = 10^a * 10^b
		(10^a)^b = 10^(a * b)
	
	Table lookup is used for speed and accuracy.  This routine was
	written for the FloatFloatToAscii routine.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

Float10ToTheX	proc	near	uses	bx,cx,si
	.enter

	cmp	ax, DECIMAL_EXPONENT_LOWER_LIMIT
	jge	10$

	call	Float0
	jmp	exit

10$:
EC<	call	FloatCheckLegalDecimalExponent >

	mov	cx, 10		; decimal divisor and also size of fp nums 
	clr	bx
	or	ax, ax
	jns	signOK

	dec	bx		; indicate negative number
	neg	ax		; make ax positive

signOK:
	;
	; for speed, we read 10^x, where x < 10 off a table
	;
	clr	dx
	div	cx		; ax <- quotient, dx <- remainder
	push	ax
	mov	al, dl
	mul	cl		; ax <- offset into table (remainder * 10)
	mov	si, ax
	add	si, offset tenToTheOnesTable
	call	PushFPNum
	pop	ax

	;
	; any exponent left?
	;
	tst	ax
	je	done

	clr	dx
	div	cx		; ax <- quotient, dx <- remainder
	mov	si, offset tenToTheTen
	call	FloatIncorporatePwrOfTenMultiple

	;
	; any exponent left?
	;
	tst	ax
	je	done

	clr	dx
	div	cx		; ax <- quotient, dx <- remainder
	mov	si, offset tenToTheHundred
	call	FloatIncorporatePwrOfTenMultiple

	;
	; any exponent left?
	;
	tst	ax
	je	done

	clr	dx
	div	cx		; ax <- quotient, dx <- remainder
	mov	si, offset tenToTheThousand
	call	FloatIncorporatePwrOfTenMultiple

done:
	tst	bx
	je	exit

	call	FloatInverse

exit:
	.leave
	ret
Float10ToTheX	endp

tenToTheOnesTable	label	word
	word	0000, 0000, 0000, 08000h, 3fffh		; 10^0 1
	word	0000, 0000, 0000, 0a000h, 4002h		; 10^1 10
	word	0000, 0000, 0000, 0c800h, 4005h		; 10^2 100
	word	0000, 0000, 0000, 0fa00h, 4008h		; 10^3 1000
	word	0000, 0000, 0000, 09c40h, 400ch		; 10^4 10000
	word	0000, 0000, 0000, 0c350h, 400fh		; 10^5 100000
	word	0000, 0000, 0000, 0f424h, 4012h		; 10^6 1000000
	word	0000, 0000, 8000h, 09896h, 4016h	; 10^7 10000000
	word	0000, 0000, 2000h, 0bebch, 4019h	; 10^8 100000000
	word	0000, 0000, 2800h, 0ee6bh, 401ch	; 10^9 1000000000

tenToTheTen		label	word
	word	0000, 0000, 0f900h, 09502h, 4020h	; 10^10

tenToTheHundred		label	word
	word	0e759h, 0a61bh, 0692ch, 0924dh, 414bh	; 10^100

tenToTheThousand	label	word
	word	0ac01h, 0dd3dh, 0b1f9h, 0f38dh, 4cf8h	; 10^1000

if 0
;
; the iterative 10^x, not very useful for 10^4000
;
Float10ToTheX	proc	near	uses	cx
	.enter
	mov	cx, ax				; cx <- exponent
	call	Float1				; initialize exponent
	jcxz	done

expLoop:
	call	FloatMultiply10
	loop	expLoop

done:
	.leave
	ret
Float10ToTheX	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatIncorporatePwrOfTenMultiple

DESCRIPTION:	

CALLED BY:	INTERNAL (Float10ToTheX)

PASS:		X on fp stack
		si - offset from cs to 10^(x, a power of ten)
		dx - multiple of that power of ten desired

		eg. pass si = 10^100 and dx = 4 if 10^400 desired

RETURN:		X * 10^(dx*x)

DESTROYED:	dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	employ fact that 10^a * 10^b = 10^(a+b)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatIncorporatePwrOfTenMultiple	proc	near	uses	ax,cx
	.enter
	tst	dx
	je	return1

	call	PushFPNum		; ( fp: num 10^x )
	mov	cx, dx
	dec	cx			; cx <- multiple-1
	jz	done			; done if no more multiples to add

	call	FloatDup		; ( fp: num 10^x 10^x )

getMultipleLoop:
	call	FloatOver		; ( fp: num 10^x multiplicand 10^x )
	call	FloatMultiply		; ( fp: num 10^x newMultiplicand )
	loop	getMultipleLoop

	;
	; done, clean up
	;
	call	FloatSwap		; ( fp: num newMult 10^x )
	FloatDrop trashFlags		; ( fp: num newMult )
	jmp	short done

return1:
	call	Float1			; 10^0
done:
	call	FloatMultiply		; ( fp: num*newMult )
	.leave
	ret
FloatIncorporatePwrOfTenMultiple	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatTrunc

DESCRIPTION:	Truncates the floating point number. ie. lose the fractional
		portion.  See also FloatFrac.

		Related:
		* INT rounds a number down to the nearest integer.
		* ROUND rounds a number to a specified number of digits.
		* MOD returns the remainder from division.

CALLED BY:	INTERNAL (FloatDispatch, FloatDIV, FloatRound)

PASS:		X on fp stack

RETURN:		X truncated

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatTrunc	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	;
	; HACK - to guard against numbers that are 1 bit less than desired
	;
	call	FloatSign
	je	done

	pushf
	call	FloatAbs
	call	FloatEpsilon
	call	FloatAdd
	popf
	jg	done

	call	FloatNegate

done:
	call	FloatIntFrac
	FloatDrop trashFlags

	.leave
	ret
FloatTrunc	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatEpsilon
DESCRIPTION:	Create a small number related to the number that is on top of
		the fp stack.  This may be useful for routines whose
		implementation returns a number that is consistently less than
		OR greater than what is desired.

CALLED BY:	INTERNAL ()

PASS:		X on fp stack

RETURN:		X, e on fp stack (e = top)

DESTROYED:	ax, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/92		Initial version

-------------------------------------------------------------------------------@

FloatEpsilon	proc	near 	uses si
	.enter	
	call	FloatDup
;	call	FloatGetSP_DSSI		; ds:si <- top of stack
	FloatGetSP_DSSI
	clr	ax
	mov	ds:[si].F_mantissa_wd0, 1	; store lsb
	mov	ds:[si].F_mantissa_wd1, ax
	mov	ds:[si].F_mantissa_wd2, ax
	mov	ds:[si].F_mantissa_wd3, ax
	call	FloatNormalize
	.leave
	ret
FloatEpsilon	endp
