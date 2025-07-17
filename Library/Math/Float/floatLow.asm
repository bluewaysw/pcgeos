
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name			Description
	----			-----------
	FloatNormalize
	FloatWordToFloat
	FloatDwordToFloat
	FloatFloatToDword
	FloatFloatToDwordNoPop
	FloatIEEE64ToGeos80
	FloatShlMantissaBytes
	FloatGeos80ToIEEE64
	FloatShrMantissaBytes
	Float2Scale
	FloatIntFrac
	FloatComp
	FloatSign
	FloatIsNoNAN2
	FloatDeFudge
	FloatExpFrac
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:
	Software Floating Point Primitives

	Internal stack representation is 10 bytes:
	0 - 7   normalized fraction (least significant byte first)
	8 - 9   low 15 bits contain base 2 exponent with bias of hex 3fffh
		high bit is sign (0 for positive, 1 for negative )

	------------------------------------------------------------------------

	notes:
	------

	{word}fp+8 = exponent
	exponent	= 7fffh => NAN
			= 43ffh => upper limit of dbl precision
			= 3c00h => lower limit of dbl precision
	
	+inf		= 7fffh exponent, 100... significand
	0		= 0 exponent, 0 significand
	-inf		= ffffh exponent, 100... significand

	------------------------------------------------------------------------

	register usage:
	---------------

	ds		usually fp stack seg
	si		usually top of fp stack
	es		occasionally fp stack seg
			occasionally destination segment
	di		occasionally top of fp stack
			occasionally destination offset

	ds is loaded with the fp stack segment when the stack is locked
	by FloatEnter.  It is assumed to be preserved throughout the
	library and only becomes useless when the stack is unlocked
	by FloatOpDone.

	All low level routines are free to destroy ax and dx.

	bx and cx are currently always preserved though this can
	be changed. There is code that depends on their preservation
	across calls though (eg. FloatStringToFloat & FloatFloatToString).

	bp, ds, es, di and si are always preserved.  This may be wasteful
	especially with si, since it frequently contains the top of
	the fp stack, but this will be left for optimization efforts.
	For now, loading si with the top of stack is not expensive.

	IMPORTANT!!!
	Routines that are not used are "if 0"ed out.  (These routines
	can be identified by locating a "???" in the "CALLED BY" section
	of the routine header).  Reincarnating them will require that you
	check to see that the register usage conventions are followed.

	$Id: floatLow.asm,v 1.1 97/04/05 01:23:10 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatNormalize (originally NORMALIZE)

DESCRIPTION:	Normalizes a floating point number.
		An fp number is normalized if the ms bit in its mantissa
		is one.

CALLED BY:	INTERNAL (FloatDwordToFloat, FloatAdd, FloatIntFrac)

PASS:		ds:si - number to normalize
		
RETURN:		ds:si is a normalize float

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	shift mantissa left till ms bit is 1,
	updating the exponent for all the shifts taking place
	store the number

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatNormalize	proc	near	uses	bx,cx,di
	.enter
	call	FloatIsNoNANCommon
	LONG jnc	done			; if a NAN then leave it alone

	mov	di, ds:[si].F_exponent
	mov	ax, ds:[si].F_mantissa_wd3
	mov	bx, ds:[si].F_mantissa_wd2
	mov	cx, ds:[si].F_mantissa_wd1
	mov	dx, ds:[si].F_mantissa_wd0

	;
	; di - exponent, ax:bx:cx:dx - mantissa
	;
	or	ax, ax
	jnz	4$

	or	bx, bx
	jnz	3$

	or	cx, cx
	jnz	2$

	or	dx, dx
	jnz	1$

	;
	; ax=bx=cx=dx=0
	;
	mov	ds:[si].F_exponent, ax	; zero out exponent
	jmp	short done

1$:
	;
	; word 0 (dx) non-zero
	;
	mov	ax, dx			; make ax non-zero
	clr	bx
	clr	cx
	clr	dx
	sub	di, 30h			; account for shift in exponent
	jmp	4$

2$:
	;
	; word 1 (cx) non-zero
	;
	mov	ax, cx			; make ax non-zero
	mov	bx, dx
	clr	cx
	clr	dx
	sub	di, 20h			; account for shift in exponent
	jmp	4$

3$:
	;
	; word 2 (bx) non-zero
	;
	mov	ax, bx			; make ax non-zero
	mov	bx, cx
	mov	cx, dx
	clr	dx
	sub	di, 10h			; account for shift in exponent

4$:
	;
	; word 3 (ms word, ax) non-zero
	;
	or	ah, ah
	jnz	5$

	mov	ah, al			; make ms byte non-zero
	mov	al, bh
	mov	bh, bl
	mov	bl, ch
	mov	ch, cl
	mov	cl, dh
	mov	dh, dl
	xor	dl, dl
	sub	di, 8			; account for shift in exponent
	clc

5$:
	dec	di
	rcl	dx, 1
	rcl	cx, 1
	rcl	bx, 1
	rcl	ax, 1
	jnc	5$

	rcr	ax, 1			; shift 1 bit back
	rcr	bx, 1
	rcr	cx, 1
	rcr	dx, 1
	inc	di

	;
	; store normalized number
	;
	mov	ds:[si].F_mantissa_wd0, dx
	mov	ds:[si].F_mantissa_wd1, cx
	mov	ds:[si].F_mantissa_wd2, bx
	mov	ds:[si].F_mantissa_wd3, ax
	mov	ds:[si].F_exponent, di
done:
	.leave
	ret
FloatNormalize	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatWordToFloat (/S->F),
		FloatDwordToFloat (/D->F)

DESCRIPTION:	Converts signed integers in registers to floating point numbers
		on the fp stack.
		FloatWordToFloat falls through to FloatDwordToFloat

		FloatWordToFloat - ( N --- )( fp: --- N )
		FloatDwordToFloat - ( D --- )( fp: --- D )

CALLED BY:	FloatWordToFloat	- FloatLn1plusX, FloatDoLn
		FloatDwordToFloat	- FloatMinus16382, Float0, Float1,
					  Float2, Float10, Float16384

PASS:		FloatWordToFloat
			ax - signed integer
		FloatDwordToFloat
			dx:ax - signed double word

RETURN:		nothing

DESTROYED:	FloatWordToFloat
			ax,dx
		FloatDwordToFloat
			ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatWordToFloat	proc	near
	cwd				; dx <- sign extended ax
	clc
	GOTO		FloatDwordToFloatCommon
FloatWordToFloat	endp

FloatDwordToFloat	proc	near
	clc
	GOTO		FloatDwordToFloatCommon
FloatDwordToFloat	endp

FloatUnsignedToFloat	proc	near
	stc
	FALL_THRU	FloatDwordToFloatCommon
FloatUnsignedToFloat	endp

FloatDwordToFloatCommon	proc	near	uses	cx,di,si
	.enter

	mov	di, 0
	jnc	2$
	dec	di
2$:
	call	FloatDecSP_FPSIZE		; prepare to push
	FloatGetSP_DSSI

	mov	cx, 401eh		; bias - binary point has been shifted
					; right 31 bits (dx:ax)
	or	di, di
	js	1$			; carry  set if no signs

	or	dx, dx			; check sign
	jns	1$			; branch if positive

	;
	; negative number
	;

	neg	ax
	adc	dx, di				; incorporate carry
	neg	dx
	or	ch, 80h				; negate exponent

1$:
	clr	di
	mov	ds:[si].F_exponent, cx		; store exponent
	mov	ds:[si].F_mantissa_wd3, dx
	mov	ds:[si].F_mantissa_wd2, ax
	mov	ds:[si].F_mantissa_wd1, di	; no significant digits here
	mov	ds:[si].F_mantissa_wd0, di	; no significant digits here
	call	FloatNormalize			; destroys ax,dx
	.leave
	ret

FloatDwordToFloatCommon	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFloatToDword (originally F->D)

DESCRIPTION:	Pops the number from the top of the fp stack and
		converts it into a dword.
		( --- D ) ( fp: X --- )

CALLED BY:	INTERNAL (FloatComputeSin, FloatComputeTan, FloatDoExp,
			  FloatExponential)

PASS:		number on fp stack
		ds - fp stack seg

RETURN:		carry clear if successful
		    dx:ax - dbl
		carry set otherwise
		    dx:ax = -80000000 if X is out of range

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatFloatToDword	proc	near
	.enter
	clc
	call	FloatFloatToDwordNoPop

	pushf
	call	FloatIncSP_FPSIZE	; drop fp num
	popf
	.leave
	ret
FloatFloatToDword	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatFloatToUnsigned (originally F->D)

DESCRIPTION:	Pops the number from the top of the fp stack and
		converts it into a unsigned dword.
		( --- D ) ( fp: X --- )

CALLED BY:	Watcom Float Stub

PASS:		number on fp stack
		ds - fp stack seg

RETURN:		carry clear if successful
		    dx:ax - dbl
		carry set otherwise
		    dx:ax = -80000000 if X is out of range

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatFloatToUnsigned	proc	near
	.enter
	stc
	call	FloatFloatToDwordNoPop

	pushf
	call	FloatIncSP_FPSIZE	; drop fp num
	popf
	.leave
	ret
FloatFloatToUnsigned	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatFloatToDwordNoPop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the number of the top of the fp-stack to a dword
		without actually removing the number.

CALLED BY:	FloatFloatToDword
PASS:		ds	- fp-stack
RETURN:		carry clear if successful
			dx.ax = dword
		carry set otherwise
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 9/ 7/91	Initial version
	mgroeb	20/05/00	Avoid returning error for (sdword)0x80000000

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatFloatToDwordNoPop	proc	far
	uses	bx,cx,si,di
	.enter
	mov	di, 0
	jnc	1$
	dec	di
1$:
EC<	call	FloatCheck1Arg >

	FloatGetSP_DSSI			; ds:si <- top of fp stack

	mov	cx, 401eh		; max exponent limit
	mov	dx, ds:[si].F_exponent	; dx <- exponent
	and	dx, 7fffh		; remove sign bit
	jnz	nonZero

	; else number is 0
	clr	ax
	clr	bx
	jmp	done

nonZero:
	sub	cx, dx			; check limit
	jl	outOfRange		; branch if num is larger than will fit

	mov	bx, ds:[si].F_mantissa_wd3
	mov	ax, ds:[si].F_mantissa_wd2
	mov	dx, ds:[si].F_mantissa_wd0

	;
	; bx:ax:??:dx - mantissa
	;
	or	dl, dh
	xor	dh, dh				; clear dh
	or	dx, ds:[si].F_mantissa_wd1	; used for rounding
	cmp	cx, 10h
	jl	2$

	or	dl, dh
	or	dl, al
	mov	dh, ah
	mov	ax, bx
	clr	bx
	sub	cx, 10h

2$:
	cmp	cx, 8
	jl	3$

	or	dl, dh
	mov	dh, al
	mov	al, ah
	mov	ah, bl
	mov	bl, bh
	xor	bh, bh
	sub	cx, 8

3$:
	jcxz	5$
	or	dl, dh
	xor	dh, dh

4$:
	clc
	rcr	bx, 1
	rcr	ax, 1
	rcr	dh, 1
	loop	4$

5$:

	test	dh, 80h			; round smaller
	jz	setSign			; branch if high bit = 0

	test	dx, 7fffh		; round bigger
	jnz	6$

	test	al, 01			; round even
	jz	setSign

6$:
	inc	ax
	adc	bx, 0

setSign:
	or	di, di
	js	done

	;
	; account for sign
	;
	mov	cx, ds:[si].F_exponent	; get exponent
	cmp	cx, 0c01eh
	je	testMinInt		; special case of MinLongInt
	cmp	cx, 0401eh
	je	outOfRange		; we have also let this pass before
	and	ch, 80h			; negative?
	jz	done			; done if not

	neg	ax
	adc	bx, 0
	neg	bx
	jmp	short done

	;
	; special test for (sdword)0x80000000 - this is the only number
	; with exponent c01eh that we can successfully convert.
	;
testMinInt:
	tst	ax
	jnz	outOfRange
	cmp	bx, 8000h
	je	done

outOfRange:
	;
	; out of range
	;
	clr	ax
	mov	bx, 8000h
	stc
	jmp	short exit

done:
	clc

exit:
	; bx:ax = dbl
	mov	dx, bx
	.leave
	ret
FloatFloatToDwordNoPop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      FloatGeos80ToFloat32

DESCRIPTION:   convert 80 bit number to 32 bit number


PASS:          number on fp stack

RETURN:        dx:ax = 32 bit number

DESTROYED:     nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy   2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	FloatGeos80ToIEEE32:far
FloatGeos80ToIEEE32	proc	far
bigfloat	local	FloatNum
	uses	es, di, cx, bx
	.enter
	segmov	es, ss, di
	lea	di, bigfloat
	call	FloatPopNumberFar

	mov	ax, ss:[bigfloat].F_exponent
	mov	dx, ax
	and	dx, 0x8000
	and	ax, 0x7fff
	tst	ax
	jz	doZero

	or	ax, dx
	sub	ax, 0x3fff
	add	ax, 0x7f
	and	ax, 0xff

	mov	cl, 7
	shl	ax, cl
	or	ax, dx
	push	ax		; save exponent
	mov	ax, ss:[bigfloat].F_mantissa_wd3
	mov	dx, ax			; save for later
	mov	cl, 8
	shr	ax, cl
	and	ax, 0xff7f		; turn off implicit one
	pop	bx
	or	ax, bx
	push	ax			; save high word
	and	dx, 0x00ff	
	shl	dx, cl
	mov	ax, ss:[bigfloat].F_mantissa_wd2

	and	ax, 0xff00
	shr	ax, cl
	or	ax, dx
	pop	dx			; dx:ax = real
	jmp	done
doZero:
	mov	ax, 0
	mov	dx, 0
done:
	.leave
	ret
FloatGeos80ToIEEE32	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	Float32BitEpsilon
DESCRIPTION:	create a number that is of the same exponent but has the
		smallest possible non-zero mantissa, this number gets added to
		32 bit values that are being converted to 64 or 80 bit values 
		so that we don't have things like 2.8 turning into 2.799999...
		
		since many more things get floored rather than ceilinged 
		(especially in C) is is better to be a little to high
		rather than a little to low...

CALLED BY:	INTERNAL ()

PASS:		ds:si = 80 bit float
		
RETURN:		ds:si = epsilon value based on float passed in
	
DESTROYED:	ax, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	1/93		initial version

-------------------------------------------------------------------------------@
ifdef USE_EPSILON

Float32BitEpsilon	proc	near 
	.enter
	mov	ax, 0
	mov	ds:[si].F_mantissa_wd3, ax
	mov	ds:[si].F_mantissa_wd2, 0200h	; turn on 23 bit
	mov	ds:[si].F_mantissa_wd1, ax
	mov	ds:[si].F_mantissa_wd0, ax
	call	FloatNormalize
	.leave
	ret
Float32BitEpsilon	endp

endif

COMMENT @-----------------------------------------------------------------------

FUNCTION:	Float64BitEpsilon
DESCRIPTION:	create a number that is of the same exponent but has the
		smallest possible non-zero mantissa, this number gets added to
		32 bit values that are being converted to 64 or 80 bit values 
		so that we don't have things like 2.8 turning into 2.799999...
		
		since many more things get floored rather than ceilinged 
		(especially in C) is is better to be a little to high
		rather than a little to low...

CALLED BY:	INTERNAL ()

PASS:		ds:si = 80 bit float
		
RETURN:		ds:si = epsilon value based on float passed in
	
DESTROYED:	ax, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	1/93		initial version

-------------------------------------------------------------------------------@
ifdef USE_EPSILON

Float64BitEpsilon	proc	near 
	.enter
	mov	ax, 0
	mov	ds:[si].F_mantissa_wd3, ax
	mov	ds:[si].F_mantissa_wd2, ax
	mov	ds:[si].F_mantissa_wd1, ax
	mov	ds:[si].F_mantissa_wd0, 1000h	; turn on 52nd bit
	call	FloatNormalize
	.leave
	ret
Float64BitEpsilon	endp

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      FloatIEEE32ToGeos80

DESCRIPTION:   convert 32 bit number to 80 bit number


PASS:           dx:ax = 32 bit number
	
RETURN:		number on fp stack

DESTROYED:      ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	FloatIEEE32ToGeos80:far
FloatIEEE32ToGeos80	proc	far
	uses	si, ds, cx, bx
bigfloat	local	FloatNum
	.enter
	mov	bx, ax
	mov	ax, dx
	or	dx, bx
	jz	pushZero
	push	ax			; original dx (half with exponent)
	push	bx			; original ax 
	mov	cl, 8
	shl	ax, cl
	or	ax, 0x8000		; turn on implicit 1
	shr	bx, cl
	or	ax, bx
	mov	ss:[bigfloat].F_mantissa_wd3, ax
	pop	dx			; original ax
	shl	dx, cl
	mov	ss:[bigfloat].F_mantissa_wd2, dx
	mov	ss:[bigfloat].F_mantissa_wd1, 0
	mov	ss:[bigfloat].F_mantissa_wd0, 0
	
	pop	cx			; original dx
	mov	ax, cx
	mov	dx, cx
	and	dx, 0x8000			; get sign bit
	and	ax, 0x7f80
	mov	cl, 7
	shr	ax, cl
	tst	ax
	jz	doZero
	sub	ax, 0x7f
	add	ax, 0x3fff
	or	ax, dx
	jmp	cont
doZero:
	clr	ax
cont:
	mov	ss:[bigfloat].F_exponent, ax
	segmov	ds, ss, si
	lea	si, bigfloat
	push	es
	call	FloatEnter_ES
	call	FloatPushNumber
ifdef	USE_EPSILON
	call	Float32BitEpsilon
	call	FloatPushNumber
	segmov	ds, es
	call	FloatAdd
endif
	call	FloatOpDone_ES
	pop	es
done:
	.leave
	ret
pushZero:
	call	FLOAT0
	jmp	done
FloatIEEE32ToGeos80	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatIEEE64ToGeos80

DESCRIPTION:	Convert a floating point number in IEEE 64 bit format into an
		fp number in Geos 80 bit format and push it onto the fp stack.
		Geos 80 bit format is almost the same as the IEEE 80 bit format
		except that we do not have an implied msb 1.

		A 64 bit number has a 52 bit mantissa and a 12 bit exponent.
		An 80 bit number has a 64 bit mantissa and a 16 bit exponent.

CALLED BY:	INTERNAL ()

PASS:		es - fp stack seg
		ds:si - IEEE 64 bit number

RETURN:		float number on the fp stack
		
DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	We convert by zero-padding the least-significant positions in
	12 positions of the mantissa and 4 positions of the exponent.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

MASK_MSB	= 0x8000
EXP_CONVERT	= 0x3c00		; = 3fffh - 3ffh
IEEE64_BIAS	= 0x3FF


FloatIEEE64ToGeos80	proc	near	uses	cx,dx,di,si
	.enter

	call	FloatDecSP_ES_FPSIZE	; make space
	mov	di, es:FSV_topPtr	; es:di <- top of fp stack
	
	;
	; deal with mantissa
	; shift mantissa bits left 11 bits and add a ms 1 bit
	;
	; We will stick a 0 as the ls byte.  This takes care of shifting 8 bits.
	; We have to manually shift the mantissa 3 bits and then "or" the
	; "1" bit in.
	;
	push	di
	clr	al
	stosb				; first 8 bits are 0
	mov	cx, 7			; copy 4 words
	rep	movsb			; si <- last byte of IEEE64 number
	mov	dx, ds:[si-1]		; dx <- 12 bits of the exponent
	pop	di

	call	FloatShlMantissaBytes
	call	FloatShlMantissaBytes
	call	FloatShlMantissaBytes
	tst	dx
	jnz	nonZeroExponent
	clr	ax
	jmp	gotExponent
nonZeroExponent:
	ornf	es:[di].F_mantissa_wd3, MASK_MSB

	;
	; deal with exponent
	;
	mov	ax, dx			; ax <- word containing exponent bits
	andnf	dx, MASK_MSB		; dx <- sign bit
	andnf	ax, not MASK_MSB	; clear sign bit
	mov	cl, 4
	shr	ax, cl			; ax <- 3ffh biased exponent
	add	ax, EXP_CONVERT		; make bias = 3fffh
	or	ax, dx			; mask in the sign bit
gotExponent:
	mov	es:[di].F_exponent, ax	; store the exponent
ifdef USE_EPSILON
	push	ds
	segmov	ds, es
	mov	si, di
	call	FloatPushNumber	; actually a FloatDup but faster in this case
	call	Float64BitEpsilon
	call	FloatAdd
	pop	ds
endif
	.leave
	ret
FloatIEEE64ToGeos80	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatShlMantissaBytes

DESCRIPTION:	Shift the bytes of the mantissa left by 1 bit.

CALLED BY:	INTERNAL (FloatIEEE64ToGeos80)

PASS:		es:di - location of fp number

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

FloatShlMantissaBytes	proc	near	uses	ax,cx,di
	.enter

	shl	{word} es:[di], 1		; carry <- ms bit
	inc	di				; doesn't nuke carry
	inc	di				; doesn't nuke carry
	mov	cx, 3				; doesn't nuke carry
shiftLoop:
	rcl	{word} es:[di], 1		; lsb <- carry, carry <- ms bit
	inc	di				; doesn't nuke carry
	inc	di				; doesn't nuke carry
	dec	cx				; doesn't nuke carry
	jnz	shiftLoop			; doesn't nuke carry
	
	.leave
	ret
FloatShlMantissaBytes	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGeos80ToIEEE64

DESCRIPTION:	Convert a floating point number in Geos 80 bit format into an
		fp number in IEEE 64 bit format and push it onto the fp stack.
		Geos 80 bit format is almost the same as the IEEE 80 bit format
		except that we do not have an implied msb 1.

		An 80 bit number has a 64 bit mantissa and a 16 bit exponent.
		A 64 bit number has a 52 bit mantissa and a 12 bit exponent.

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack seg
		es:di - location to store the IEEE 64 bit number

RETURN:		carry clear if successful
		carry set otherwise
		float number popped off stack in either case

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	We convert by checking that limits are not exceeded and then we
	lop off 12 bits from the mantissa and 4 bits from the exponent.

	get exponent, e
	e <- e - 3fffh + 3ffh
	if (e < 0) or (e > 3ffh) then
	    overflow, bail

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

FloatGeos80ToIEEE64	proc	near	uses	cx,dx,di,si
	.enter

	FloatGetSP_DSSI				; ds:si <- top of fp stack

	call	FloatIncSP_FPSIZE		; pop topmost fp num

	mov	ax, ds:[si].F_exponent		; ax <- exponent
	tst	ax
	jz	doZero
	mov	dx, ax				; dx <- save exponent
	and	dx, 8000h
	;
	; check limits
	;
	and	ax, not MASK_MSB		; clear sign bit
	sub	ax, EXP_CONVERT			; ax <- 3ffh biased exponent
	cmp	ax, 0
	jl	err
;	cmp	ax, IEEE64_BIAS
;	jg	err

	;
	; round mantissa
	; lop off 11 ls bits and the msb 1 bit
	;
	push	ax,si
	inc	si				; lop off 8 bits
	mov	cx, 4
	rep	movsw
	pop	ax,si

	sub	di, 2				; es:di <- ms 8 bits of mantissa
EC<	push	ax >
EC<	mov	ax, es:[di] >			; ax <- ms mantissa bits
EC<	and	ax, 80h >			; see that ms bit is 1
EC<	ERROR_E	FLOAT_ASSERTION_FAILED >
EC<	pop	ax >
	andnf	{word} es:[di], 7fh		; nuke exponent bits & ms 1 bit

	call	FloatShrMantissaBytes
	call	FloatShrMantissaBytes
	call	FloatShrMantissaBytes

	;
	; deal with the exponent
	;
	mov	cl, 4
	shl	ax, cl				; shift exponent left 4 bits
	ornf	ax, dx				; mask in the sign bit
	ornf	{word} es:[di], ax		; mask in the exponent bits

	clc
	jmp	short done

err:
	stc

done:
	.leave
	ret
doZero:
	; the thing is a zero so just fill in zeros
	mov	cx, 4
	rep	stosw
	clc
	jmp	done
FloatGeos80ToIEEE64	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatShrMantissaBytes

DESCRIPTION:	

CALLED BY:	INTERNAL (FloatGeos80ToIEEE64)

PASS:		es:di - ms bits of the 4 word mantissa

RETURN:		4 word mantissa shifted right 1 bit

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	10/91		Initial version

-------------------------------------------------------------------------------@

FloatShrMantissaBytes	proc	near	uses	cx,di
	.enter

	shr	{word} es:[di], 1		; carry <- ms bit
	dec	di				; doesn't nuke carry
	dec	di				; doesn't nuke carry
	mov	cx, 3				; doesn't nuke carry
shiftLoop:
	rcr	{word} es:[di], 1		; msb <- carry, carry <- ls bit
	dec	di				; doesn't nuke carry
	dec	di				; doesn't nuke carry
	dec	cx				; doesn't nuke carry
	jnz	shiftLoop			; doesn't nuke carry

	.leave
	ret
FloatShrMantissaBytes	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	Float2Scale (originally /2SCALE)

DESCRIPTION:	Multiply the topmost fp num by the given factor of 2.
		( N --- )( fp: X --- X*2^N )

CALLED BY:	INTERNAL (FloatSqrt, FloatExpC, FloatExp)

PASS:		bx - factor of 2 to multiply number by
		X on fp stack

RETURN:		X*2^N on fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

Float2Scale	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	FloatGetSP_DSSI			; ds:si <- top of fp stack
	add	ds:[si].F_exponent, bx	; add to the exponent
	.leave
	ret
Float2Scale	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatIntFrac (originally /INTFRAC)

DESCRIPTION:	Splits a number into its integer and fractional components.
		( fp: X --- [X] X-[X] )

CALLED BY:	INTERNAL (FloatDoExp, FloatExponential, FloatSin, FloatTan)

PASS:		X on the fp stack
		ds - fp stack seg

RETURN:		[X], X-[X] on the fp stack (fraction on top)

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	push a number with a 0 mantissa onto the stack
	give this number the same exponent as the argument
	if the binary point lies to the right of the mantissa, it
	    means we're done because the number is an integer
	otherwise we need to mask out the integer and fractional portions

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

intmask   word	0, 8000h, 0c000h, 0e000h, 0f000h,
		0f800h, 0fc00h, 0fe00h, 0ff00h, 0ff80h,
		0ffc0h, 0ffe0h, 0fff0h, 0fff8h, 0fffch, 0fffeh

FloatIntFrac	proc	near	uses	bx,cx,es,di,si,bp
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatDecSP_FPSIZE	; prepare to push fraction
	FloatGetSP_ESDI			; es:di <- top of fp stack

	mov	si, di
	;
	; zero out mantissa of fraction portion
	;
	clr	ax
	mov	cx, 0004
	push	di
	rep	stosw
	pop	di

	mov	si, es:[di].F_exponent1		; get exponent of X
	mov	es:[di].F_exponent2, si	; give fraction portion same exponent
	and	si, 7fffh		; remove sign bit
	sub	si, 403eh		; bias+3fh, does binary pt sit in
					; mantissa?
	jb	2$			; branch if so

done:
	FloatGetSP_DSSI
	call	FloatNormalize		; destroys ax,dx
	.leave
	ret

2$:
	;
	; binary point is in mantissa
	;
	mov	ax, es:[di].F_mantissa1_wd0
	mov	bx, es:[di].F_mantissa1_wd1
	mov	cx, es:[di].F_mantissa1_wd2
	mov	dx, es:[di].F_mantissa1_wd3
	;
	; dx:cx:bx:ax - mantissa X
	;
	add	si, 10h
	jnc	3$

	shl	si, 1
	mov	bp, cs:[si+intmask]
	and	es:[di].F_mantissa1_wd0, bp
	xor	bp, 0ffffh
	and	ax, bp
	mov	es:[di].F_mantissa2_wd0, ax
	jmp	short done

3$:
	mov	es:[di].F_mantissa2_wd0, ax
	clr	ax
	mov	es:[di].F_mantissa1_wd0, ax
	add	si, 10h
	jnc	4$

	shl	si, 1
	mov	bp, cs:[si+intmask]
	and	es:[di].F_mantissa1_wd1, bp
	xor	bp, 0ffffh
	and	bx, bp
	mov	es:[di].F_mantissa2_wd1, bx
	jmp	short done

4$:
	mov	es:[di].F_mantissa2_wd1, bx
	mov	es:[di].F_mantissa1_wd1, ax
	add	si, 10h
	jnc	5$

	shl	si, 1
	mov	bp, cs:[si+intmask]
	and	es:[di].F_mantissa1_wd2, bp
	xor	bp, 0ffffh
	and	cx, bp
	mov	es:[di].F_mantissa2_wd2, cx
	jmp	done

5$:
	mov	es:[di].F_mantissa2_wd2, cx
	mov	es:[di].F_mantissa1_wd2, ax
	add	si, 10h
	jnc	7$

	shl	si, 1
	mov	bp, cs:[si+intmask]
	and	es:[di].F_mantissa1_wd3, bp
	jnz	6$

	and	{word} es:[di].F_exponent1, 8000h ; zero exp but preserve sign
6$:
	xor	bp, 0ffffh
	and	dx, bp
	mov	es:[di].F_mantissa2_wd3, dx
	jmp	done

7$:
	mov	es:[di].F_mantissa2_wd3, dx
	mov	es:[di].F_mantissa1_wd3, ax
	mov	es:[di].F_exponent1, ax
	jmp	done
FloatIntFrac	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatSign (originally /FSIGN)

DESCRIPTION:	Returns the exponent of the topmost fp number.
		This exponent has these convenient properties:
		    * positive if the number is positive
		    * 0 if the number is positive
		    * negative  if the number is negative
		( fp: X --- X )

CALLED BY:	INTERNAL (many)

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X unchanged on fp stack
		bx - negative if fp number is negative
		     non-negative otherwise
		flags set by a "cmp bx, 0"

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatSign	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	FloatGetSP_DSSI			; ds:si <- top of fp stack
	mov	bx, ds:[si].F_exponent	; get exponent
	cmp	bx, 8000h		; negative 0?
	jne	done

	clr	bx			; change -0 to 0

done:
	cmp	bx, 0
	.leave
	ret
FloatSign	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatIsNoNAN2 (originally /?NONAN2)

DESCRIPTION:	Tells if the top 2 numbers on the fp stack are non-errors.
		( X1 X2 --- X1 X2 -1  or  X3 0 )

CALLED BY:	INTERNAL (many)

PASS:		X1, X2 on fp stack (X2 = top)

RETURN:		bx - -1 if neither X1 nor X2 are error codes.
		Otherwise, returns a 0 flag and either X1 or X2, whichever
		has a higher error code (higher mantissa, or the positive
		value if the mantissa's are equal.

		carry set if both 

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatIsNoNAN2	proc	near	uses	cx,si
	.enter
EC<	call	FloatCheck2Args >

	FloatGetSP_DSSI			; ds:si <- top of fp stack

	mov	ax, ds:[si].F_exponent2	; ax <- exponent of top num
	mov	dx, ds:[si].F_exponent1	; dx <- exponent of 2nd num

	mov	cx, ax			; check top num
	and	ch, 7fh
	inc	cx
	jo	NANpresent

	mov	cx, dx			; check 2nd num
	and	ch, 7fh
	inc	cx
	jo	doneNAN

	mov	bx, 0ffffh		; both nums are non NANs
	stc
	jmp	short exit

NANpresent:
	mov	cx, dx			; is top num the NAN?
	and	ch, 7fh
	inc	cx
	jno	x2NAN			; branch if X1 is a non NAN

	or	dx, dx
	jns	doneNAN

	or	ax, ax
	jns	x2NAN

x2NAN:
	;
	; X2's the NAN, lose it
	;
	call	FloatSwap

doneNAN:
	FloatDrop trashFlags		; lose top number, leave NAN
	clr	bx			; indicate NAN present, clear carry
exit:
	.leave
	ret
FloatIsNoNAN2	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDeFudge (originally /DFUDGE)

DESCRIPTION:	Increases the absolute value of X1, if non-zero, by 1
		double-precision least-significant bit.  This may be used to
		adjust for rounding error from a double-precision argument
		before formatting or rounding in order to avoid "unexpected"
		results (e.g. INT(X*100+.5) producing 14 when X=.145 double
		precision).  If X1 is 0 or NAN it is not altered.

CALLED BY:	INTERNAL (???)
		Not in use currently

PASS:		( FP: X1 --- X2 )

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

if 0
FloatDeFudge	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	FloatGetSP_DSSI			; ds:si <- top of fp stack

	mov	ax, ds:[si].F_exponent	; get exponent
	and	ax, 7fffh		; ignore sign
	jz	done			; exit if 0 exponent

	cmp	ax, 7fffh		; NAN ?
	jz	done			; exit if so

	add	ds:[si].F_mantissa_wd0, 0800h
	jnc	done

	inc	ds:[si].F_mantissa_wd1
	jnz	done

	inc	ds:[si].F_mantissa_wd2
	jnz	done

	inc	ds:[si].F_mantissa_wd3
	jnz	done

	mov	ds:[si].F_mantissa_wd3, 8000h
	inc	ds:[si].F_exponent	; up exponent
done:
	.leave
	ret
FloatDeFudge	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatExpFrac (originally EXP/FRAC)

DESCRIPTION:	Clears the exponent of the number on the fp stack.
		ie. forces it to lie between 1 & 2
		The original exponent is also returned.
		( --- N ) ( FP: X1 --- X2 )

CALLED BY:	INTERNAL (FloatSqrt, FloatLn1plusX, FloatDoLn)

PASS:		X on fp stack

RETURN:		bx - unbiased exponent
		X with a 0 exponent, ie. 1 <= X <= 2

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatExpFrac	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	FloatGetSP_DSSI			; ds:si <- top of fp stack

	mov	bx, ds:[si].F_exponent	; bx <- exponent
	and	bx, 7fffh		; remove sign bit
	sub	bx, BIAS		; remove bias

	push	bx
	neg	bx			; negate to remove exponent
	call	Float2Scale
	pop	bx
	.leave
	ret
FloatExpFrac	endp


FloatGetDecimalSeperator	proc	near
	uses	bx, cx, dx
	.enter

	call	LocalGetNumericFormat
	mov	ax, cx

	.leave
	ret
FloatGetDecimalSeperator	endp

FloatGetThousandsSeperator	proc	near
	uses	bx, cx, dx
	.enter

	call	LocalGetNumericFormat
	mov	ax, bx

	.leave
	ret
FloatGetThousandsSeperator	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	PushFPNum

DESCRIPTION:	Pushes 5 words onto the fp stack.  Used to push constants
		stored in the code segment.

CALLED BY:	INTERNAL (many)

PASS:		ds - fp stack seg
		si - offset from cs to 5 word lookup table entry to push

RETURN:		si  - updated to point past the 5 words

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

PushFPNum	proc	near	uses	cx,es,di
	.enter
	call	FloatDecSP_FPSIZE	; prepare to push to fp stack
	FloatGetSP_ESDI			; es:di <- top of fp stack

	; ds may have changed, as the fp stack might have be Realloced,
	; but ds will be pointing to the right thing
	push	ds
	segmov	ds, cs, cx

	mov	cx, FPSIZE/2
	rep	movsw
	pop	ds
	.leave
	ret
PushFPNum	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatFSTSW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store the status word of the co-processor

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ax = status word

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

	basically this routine is not meant for general consumption and 
	should probably not be documented.  It must however be exported 
	by the library so the coprocessor libraries can overwrite its
	place in the relocation table with there own routine.  It must
	simulate the actions of a coprocessor's FTSTW command

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/24/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatFSTSW	proc	far
	uses	ds
	.enter
	call	FloatEnter	; ds <- fp stack seg
	mov	ax, ds:[FSV_status]
	call	FloatOpDone
	.leave
	ret
FloatFSTSW	endp
	
