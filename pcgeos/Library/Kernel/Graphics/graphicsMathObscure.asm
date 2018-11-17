COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Graphics
FILE:		Graphics/graphicsMathObscure.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
    GBL GrMulDWFixed
    GBL GrMulDWFixedPtr
    GBL GrPolarToCartesian
    GBL GrSDivDWFbyWWF

    INT MulWWFbyDWF
    INT MulDWFbyWWF

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	3/91	initial version


DESCRIPTION:
	This file contains routines to some fixed point math for DWFixed 
	format arguments.

	$Id: graphicsMathObscure.asm,v 1.1 97/04/05 01:13:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsSemiCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrMulDWFixed GrMulDWFixedPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply two 48-bit signed integers, where lower 16-bits of
		each is considered a fraction.

CALLED BY:	GLOBAL		(GrMulWWFixed, GrMulWWFixedPtr)

PASS:		ds:si - points to multiplicand, type DWFixed (GrMulDWFixedPtr)
		es:di - points to multiplier, type DWFixed   (GrMulDWFixedPtr)

		di.dx.cx - multiplier   (GrMulDWFixed)
		si.bx.ax - multiplicand (GrMulDWFixed)

RETURN:		carry	- set if there is overflow, otherwise
		dx.cx.bx - dx holds high part of int, bx holds fraction

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrMulDWFixed	proc	far
		uses	ds, es, si, di, ax
firstArg	local	DWFixed
secondArg	local	DWFixed
		.enter

		mov	firstArg.DWF_frac, cx
		mov	firstArg.DWF_int.low, dx
		mov	firstArg.DWF_int.high, di
		mov	secondArg.DWF_frac, ax
		mov	secondArg.DWF_int.low, bx
		mov	secondArg.DWF_int.high, si
		lea	si, firstArg
		lea	di, secondArg
		segmov	ds, ss, cx
		mov	es, cx		;base reg for offset di
		call	GrMulDWFixedPtr

		.leave
		ret
GrMulDWFixed	endp

		; special case: negate first argument
negateArg1	label	near
		mov	ax, ds:[si].DWF_frac	; get args into registers
		mov	dx, ds:[si].DWF_int.low
		mov	cx, ds:[si].DWF_int.high
		NegDWFixed  cx, dx, ax		; perform 48-bit 2's complement
		mov	ds:[si].DWF_frac, ax		; return args to memory
		mov	ds:[si].DWF_int.low, dx
		mov	ds:[si].DWF_int.high, cx
		jmp	testArg2

		; special case: negate second argument
negateArg2	label	near
		mov	ax, es:[di].DWF_frac	; get args into registers
		mov	dx, es:[di].DWF_int.low
		mov	cx, es:[di].DWF_int.high
		NegDWFixed  cx, dx, ax		; perform 48-bit 2's complement
		mov	es:[di].DWF_frac, ax		; return args to memory
		mov	es:[di].DWF_int.low, dx
		mov	es:[di].DWF_int.high, cx
		jmp	doMultiply

;------------------------------------

if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrMulDWFixedPtr	proc	far
		mov	ss:[TPD_callVector].segment, size DWFixed
		mov	ss:[TPD_dataBX], handle GrMulDWFixedPtrReal
		mov	ss:[TPD_dataAX], offset GrMulDWFixedPtrReal
		GOTO	SysCallMovableXIPWithDSSIAndESDIBlock
GrMulDWFixedPtr	endp
CopyStackCodeXIP	ends

else

GrMulDWFixedPtr	proc	far
		FALL_THRU	GrMulDWFixedPtrReal
GrMulDWFixedPtr	endp

endif

GrMulDWFixedPtrReal	proc	far
		uses	ax, si, di
saveSignBits	local	word
pp1Low		local	word			; all the partial products.
pp2		local	dword			; the first one's high word is
pp3		local	dword			; just kept in bx
pp4		local	dword
pp5		local	dword
pp6		local	dword
pp7		local	dword
pp8Low		local	word
		.enter

		; optimize for arguments less than 32-bit by initializing 
		; the partial products

		clr	ax
		mov	pp3.low, ax
		mov	pp3.high, ax
		mov	pp6.low, ax
		mov	pp6.high, ax
		mov	pp7.low, ax
		mov	pp7.high, ax
		mov	pp8Low, ax

		; test sign of both arguments, and determine if result is < 0

		mov	bh, ds:[si].DWF_int.high.high ; get hi byte of multiplicand
		mov	bl, es:[di].DWF_int.high.high ; get hi byte of multiplier
		tst	bh			; test multiplicand
		js	negateArg1		; negate first argument
testArg2	label	near
		tst	bl			; test multiplier
		js	negateArg2		; negate second argument

		; done fixing arguments, start multiply
doMultiply	label	near
		mov	saveSignBits, bx	; save sign bits
		xor	bh, bl			; calc sign of result
		pushf				; save sign bits
		clr	bx			; assume first is zero
		mov	ax, ds:[si].DWF_frac	; get low word of multiplicand
		mov	cx, es:[di].DWF_frac	; get low word of multiplier
		mul	cx			; form 1st partial product
		mov	pp1Low, ax		;  and save it
		mov	bx, dx			;  one free reg we can use
		mov	ax, ds:[si].DWF_int.low	; get middle word 
		mul	cx			; form 2nd partial product
		mov	pp2.low, ax		;  and save it
		mov	pp2.high, dx
		mov	ax, ds:[si].DWF_int.high	; get middle word 
		tst	ax			; check for zero
		jz	do_pp4			; we can skip a mul
		mul	cx
		mov	pp3.low, ax		;  and save it
		mov	pp3.high, dx
do_pp4:
		mov	ax, ds:[si].DWF_frac	; get low word of multiplicand
		mov	cx, es:[di].DWF_int.low	; get middle word of multiplier
		mul	cx			; form 3rd partial product
		mov	pp4.low, ax		;  and save it
		mov	pp4.high, dx
		mov	ax, ds:[si].DWF_int.low	; get middle word 
		mul	cx			; form final partial product
		mov	pp5.low, ax		;  and save it
		mov	pp5.high, dx
		mov	ax, ds:[si].DWF_int.high	; get middle word 
		tst	ax			; check for zero
		jz	do_pp7			; we can skip a mul
		mul	cx
		mov	pp6.low, ax		;  and save it
		tst	dx			; if dx <> 0, busted
		LONG jnz busted
		mov	pp6.high, dx
do_pp7:
		clr	ax			; assume it is zero
		clr	dx
		mov	cx, es:[di].DWF_int.high	; get middle word of multiplier
		jcxz	add_pps
		mov	ax, ds:[si].DWF_frac	; get low word of multiplicand
		mul	cx			; form 3rd partial product
		mov	pp7.low, ax		;  and save it
		mov	pp7.high, dx		
		mov	ax, ds:[si].DWF_int.low	; get low word of multiplicand
		mul	cx
		tst	dx			; see if busted
		jnz	busted
		mov	dx, ax			; save low word
		tst	ds:[si].DWF_int.high	; test high word 
		jnz	busted

		; add in all the partial products to form final result
		; the final result could be six words.  We overflow if we
		; end up with any more than 3 words, so let's keep four 
		; and bail if we detect a carry out of the highest word.
		; the four regs used (from most sig) are dx.cx.bx.ax
add_pps:
		mov	ax, pp1Low		; low word PP 1
		mov	cx, pp2.high		; init all of the places
		add	bx, pp2.low		; add in 2nd partial (low)
		adc	cx, pp3.low
		adc	dx, pp3.high
		jc	busted
		add	bx, pp4.low
		adc	cx, pp4.high
		adc	dx, pp5.high
		jc	busted
		add	cx, pp5.low
		adc	dx, pp6.low
		jc	busted
		add	cx, pp7.low
		adc	dx, pp7.high
		jc	busted

		; see if we need to negate result

		popf				; restore sign of result
		jns	alignGoodResult		; all ok, done
		not	ax			; neg result, do 2's complement
		not	bx			;  of 64-bit result with
		not	cx			;  brute force. (eat your
		not	dx			;  heart out Schwartzenegger)
		add	ax, 1
		adc	bx, 0
		adc	cx, 0
		adc	dx, 0

		; all done, see if args need negating, set up result,
		;  restore stack and leave
alignGoodResult:
		clc
alignResult:
		pushf				; save carry flag
		mov	ax, saveSignBits	; retrieve source sign bits
		tst	ah			; need to invert 1st one ?
		js	invertFirst		;  yes, go do it
checkArg2:
		tst	al			; need to invert 2nd one ?
		js	invertSecond		;  yes, go do it
reallyDone:
		popf
		.leave
		ret

		; overflow condition
busted:
		popf				; restore stack
		stc				; indicate overflow
		jmp	alignResult		; finish up

		; special case: negate first argument
invertFirst:
		push	dx, cx, bx
		mov	bx, ds:[si].DWF_frac	; get args into registers
		mov	cx, ds:[si].DWF_int.low
		mov	dx, ds:[si].DWF_int.high
		NegDWFixed  dx, cx, bx		; perform 48-bit 2's complement
		mov	ds:[si].DWF_frac, bx		; return args to memory
		mov	ds:[si].DWF_int.low, cx
		mov	ds:[si].DWF_int.high, dx
		pop	dx, cx, bx
		jmp	checkArg2

		; special case: negate second argument
invertSecond:
		push	dx, cx, bx
		mov	bx, es:[di].DWF_frac	; get args into registers
		mov	cx, es:[di].DWF_int.low
		mov	dx, es:[di].DWF_int.high
		NegDWFixed  dx, cx, bx		; perform 48-bit 2's complement
		mov	es:[di].DWF_frac, bx		; return args to memory
		mov	es:[di].DWF_int.low, cx
		mov	es:[di].DWF_int.high, dx
		pop	dx, cx, bx
		jmp	reallyDone


GrMulDWFixedPtrReal	endp

GraphicsSemiCommon ends

;------------------

kcode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulWWFbyDWF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply a WWFixed number by a DWFixed number

CALLED BY:	EXTERNAL	- used by other modules in the kernel

PASS:		ds:si	- far pointer to WWFixed number
		es:di	- far pointer to DWFixed number

RETURN:		dx.cx.bx - DWFixed result (dx = most sig word, bx = fraction)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for now, just convert the WWFixed number to a DWFixed and 
		call the DWFixed multiply routine.  Eventually this might
		be written separately for optimization...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version
		Joon	1/93		Do 32 bit multiply when possible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MulWWFbyDWF	proc	far

	; optimize for the usual case where doing a 32 bit multiply
	; would suffice.  We can do this whenever the DWFixed number
	; is small enough to fit in 32 bits (which is almost always
	; the case.)

		tst	es:[di].DWF_int.low	; positive number must fit in
		js	checkNeg		;  31 bits since the highest
		tst	es:[di].DWF_int.high	;  bit is the sign bit
		jnz	noOpt
optimize:
		push	ax		
		call	GrMul32ToDDF		; returns dxcx.bxax
		pop	ax			; ignore ax and we have answer
		ret				; <== EXIT HERE
checkNeg:
		cmp	es:[di].DWF_int.high, -1
		je	optimize		; optimize neg number if small
						;  enough to fit in 32 bits
noOpt:
		call	SlowMulDWFbyWWF
		ret
MulWWFbyDWF	endp

kcode ends

;---

GraphicsSemiCommon segment resource

SlowMulDWFbyWWF	proc	far
		uses	ds, si, ax
temp		local	DWFixed
		.enter

		mov	ax, ds:[si].WWF_int
		mov	temp.DWF_int.low, ax
		cwd
		mov	temp.DWF_int.high, dx
		mov	ax, ds:[si].WWF_frac	; load up temp
		mov	temp.DWF_frac, ax
		segmov	ds, ss, si
		lea	si, temp
		call	GrMulDWFixedPtr

		.leave
		ret
SlowMulDWFbyWWF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulDWFbyWWF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply a DWFixed number by a WWFixed number

CALLED BY:	EXTERNAL	- used by other modules in the kernel

PASS:		ds:si	- far pointer to DWFixed number
		es:di	- far pointer to WWFixed number

RETURN:		dx.cx.bx - DWFixed result (dx = most sig word, bx = fraction)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for now, just convert the WWFixed number to a DWFixed and 
		call the DWFixed multiply routine.  Eventually this might
		be written separately for optimization...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MulDWFbyWWF	proc	far
		uses	es, di, ax
temp		local	DWFixed
		.enter

		mov	ax, es:[di].WWF_int
		mov	temp.DWF_int.low, ax
		cwd
		mov	temp.DWF_int.high, dx
		mov	ax, es:[di].WWF_frac	; load up temp
		mov	temp.DWF_frac, ax
		segmov	es, ss, di
		lea	di, temp
		call	GrMulDWFixedPtr

		.leave
		ret
MulDWFbyWWF	endp

GraphicsSemiCommon ends

;---

kcode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrMulWWFixedToDDF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply two WWFixed numbers, and return a DDFixed result

CALLED BY:	MulWWFbyDWF (most of the time)
		various routines that deal with inverse scale factors in the
		transformation matrices

PASS:		ds:si	-> WWFixed number
		es:di	-> another WWFixed number
RETURN:		dxcx.bxax	- 64-bit DDFixed result
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/15/92		Initial version
	Joon	12/92		Optimized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrMulWWFixedToDDF	proc	far
	call	GrMul32ToDDF
	ret
GrMulWWFixedToDDF	endp

GrMul32ToDDF	proc	near
	movdw	dxcx, ds:[si]		;dx.cx = multiplicand
	movdw	bxax, es:[di]		;bx.ax = multiplier
	call	GrRegMul32ToDDF		;returns bxdx.cxax
	xchg	bx, dx			; becomes dxbx.cxax
	xchg	bx, cx			; becomes dxcx.bxax
	ret
GrMul32ToDDF	endp

kcode ends

;---------------

GraphicsObscure segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrPolarToCartesian
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a polar coordinate to its corresponding
		cartesian coordinate

CALLED BY:	GLOBAL

PASS:		dx.cx - angle (theta)
		bx.ax - distance (r)

RETURN:		dx.cx - x coordinate
		bx.ax - y cordinate

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	X = R * cos(theta), Y=-R * sin(theta)


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The angle (theta) is assumed to be relative to the x-axis,
	with increasing values of theta going counterclockwise.

	The returned values are in standard document coordinates, 
	ie, increasing values of Y move DOWN.  This is why the
	negation of y at the end of this routine is necessary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 3/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrPolarToCartesian	proc far
	angle	 local WWFixed	push	dx, cx
	distance local WWFixed	push	bx, ax
	.enter

	; calc Y coordinate

	mov	ax, cx
	call	GrQuickSine
	mov	cx, ax
	movwwf	bxax, distance
	call	GrMulWWFixed		; dx y-coord
	push	dx, cx

	; calc X coordinate

	movwwf	dxax, angle
	call	GrQuickCosine		; cos(theta) in dx.ax
	mov	cx, ax			; dxcx <- cos(theta)
	movwwf	bxax, distance
	call	GrMulWWFixed		; dxcx <- x-coordinate
	pop	bx, ax			; bxax <- y-coord
	negwwf	bxax

	.leave
	ret
GrPolarToCartesian	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSDivDWFbyWWF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signed divide of 48 bit value (32 int, 16 frac) by
		32 bit value (16 int by 16 frac)

CALLED BY:	GLOBAL

PASS:		dx:cx.bp - Dividend (signed)
		bx.ax 	 - Divisor  (signed)

RETURN:		dx:cx.bp - Quotient (signed)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 7/92   	Initial version
	don	2/25/94		Made more accurate through use of DDF routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSDivDWFbyWWF		proc	far
		uses	ax, bx, di, si, ds
		.enter

		; Determine the sign of the result, and make both
		; operands positive

		mov	si, dx
		xor	si, bx
		pushf				; save sign result
		clr	si
		tst	dx
		jns	checkDivisor
		negdwf	dxcxbp, si
checkDivisor:
		tst	bx
		jns	doDivision
		negwwf	bxax, si

		; Calculate the unsigned result
doDivision:
		push	dx, cx			; push integer
		push	bp, si			; push fraction
		mov	di, sp			; ss:di -> dividend on stack
		push	si, bx			; push integer
		push	ax, si			; push fraction
		mov	bx, sp			; ss:bx -> divisor on stack
		segmov	ds, ss
		call	UDivideDDF
		add	sp, 8			; partially clear the stack
		pop	bp, ax			; bp:ax -> fractional result
		pop	dx, cx			; dx:cx -> integer result

		; Round the result to a DWFixed value (note: SI = 0, still)

		test	ax, 0x8000
		jz	calcSign
		add	bp, 1
		adc	cx, si
		adc	dx, si

		; Calculate the sign of the result
calcSign:
		popf
		jns	done
		clr	ax
		negdwf	dxcxbp, ax
done:
		.leave
		ret
GrSDivDWFbyWWF		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrReciprocalDDF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reciprocal of a DDFixed number

CALLED BY:	EXTERNAL
PASS:		dxcxbxax	- DDFixed number
RETURN:		dxcxbxax	- DDFixed result
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		ds:bx	= source (divisor)
		ds:di	= destination (dividend)
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrReciprocalDDF	proc	far
		uses	ds, di
dividend	local	DDFixed
divisor		local	DDFixed
		.enter

		tst	dx			; see if need to negate
		pushf				; save flag
		jns	saveDividend
		neg	ax
		cmc
		not	bx
		adc	bx, 0
		not	cx
		adc	cx, 0
		not	dx
		adc	dx, 0
saveDividend:
		movdw	ss:[divisor].DDF_frac, bxax
		movdw	ss:[divisor].DDF_int, dxcx
		clr	ax
		clrdw	ss:[dividend].DDF_frac, ax
		mov	ss:[dividend].DDF_int.high, ax
		mov	ss:[dividend].DDF_int.low, 1

		segmov	ds, ss, ax
		lea	bx, ss:divisor
		lea	di, ss:dividend

		call	UDivideDDF

		movdw	bxax, ss:dividend.DDF_frac
		movdw	dxcx, ss:dividend.DDF_int
		
		popf				; restore negate flag
		jns	done
		neg	ax
		cmc
		not	bx
		adc	bx, 0
		not	cx
		adc	cx, 0
		not	dx
		adc	dx, 0
done:
		.leave
		ret
GrReciprocalDDF	endp

	; the following routines were torn from Calc (the orig calculator)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UDivideDDF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsigned divide

CALLED BY:	CalcDivide, CalcAToF
PASS:		ds:bx	= unsigned DDFixed divisor
		ds:di	= unsigned DDFixed dividend
RETURN:		ds:di	= unsigned DDFixed quotient of ds:[di]/ds:[bx]
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DDDividend	struc
    DDD_extra	dword
    DDD_real	DDFixed
DDDividend	ends

UDivideDDF	proc	near	uses cx
partial		local	DDFixed
dividend	local	DDDividend
		.enter
	;
	; Make sure divisor not zero
	;
		mov	ax, ds:[bx].DDF_frac.low
		or	ax, ds:[bx].DDF_frac.high
		or	ax, ds:[bx].DDF_int.low
		or	ax, ds:[bx].DDF_int.high
		stc				; assume zero
		LONG jz	done
		
	;
	; Copy the dividend into the expanded dividend required by the
	; algorithm, effectively multiplying the thing by 2**32
	;
		mov	ax, ds:[di].DDF_frac.low
		mov	dividend.DDD_real.DDF_frac.low, ax
		mov	ax, ds:[di].DDF_frac.high
		mov	dividend.DDD_real.DDF_frac.high, ax
		mov	ax, ds:[di].DDF_int.low
		mov	dividend.DDD_real.DDF_int.low, ax
		mov	ax, ds:[di].DDF_int.high
		mov	dividend.DDD_real.DDF_int.high, ax
		clr	ax
		mov	dividend.DDD_extra.low, ax
		mov	dividend.DDD_extra.high, ax
	;
	; Initialize the partial dividend to 0.
	;
		mov	partial.DDF_frac.low, ax
		mov	partial.DDF_frac.high, ax
		mov	partial.DDF_int.low, ax
		mov	partial.DDF_int.high, ax
		
		mov	cx, size DDDividend * 8
divLoop:
	;
	; Shift another bit into the partial dividend.
	;
		shl	dividend.DDD_extra.low
		rcl	dividend.DDD_extra.high
		rcl	dividend.DDD_real.DDF_frac.low
		rcl	dividend.DDD_real.DDF_frac.high
		rcl	dividend.DDD_real.DDF_int.low
		rcl	dividend.DDD_real.DDF_int.high
		rcl	partial.DDF_frac.low
		rcl	partial.DDF_frac.high
		rcl	partial.DDF_int.low
		rcl	partial.DDF_int.high
	;
	; See if the dividend now greater or equal to the divisor
	;
		mov	ax, partial.DDF_int.high
		cmp	ax, ds:[bx].DDF_int.high
		ja	doWork
		jb	endLoop
		mov	ax, partial.DDF_int.low
		cmp	ax, ds:[bx].DDF_int.low
		ja	doWork
		jb	endLoop
		mov	ax, partial.DDF_frac.high
		cmp	ax, ds:[bx].DDF_frac.high
		ja	doWork
		jb	endLoop
		mov	ax, partial.DDF_frac.low
		cmp	ax, ds:[bx].DDF_frac.low
		jb	endLoop
doWork:
		inc	dividend.DDD_extra.low	; Cannot carry
		
		mov	ax, ds:[bx].DDF_frac.low
		sub	partial.DDF_frac.low, ax
		mov	ax, ds:[bx].DDF_frac.high
		sbb	partial.DDF_frac.high, ax
		mov	ax, ds:[bx].DDF_int.low
		sbb	partial.DDF_int.low, ax
		mov	ax, ds:[bx].DDF_int.high
		sbb	partial.DDF_int.high, ax
		
endLoop:
		loop	divLoop
	;
	; Figure how to round by generating another bit.
	;
		shl	dividend.DDD_real.DDF_int.high
		rcl	partial.DDF_frac.low
		rcl	partial.DDF_frac.high
		rcl	partial.DDF_int.low
		rcl	partial.DDF_int.high
	;
	; See if the dividend now greater or equal to the divisor
	;
		mov	ax, partial.DDF_int.high
		cmp	ax, ds:[bx].DDF_int.high
		ja	roundUp
		jb	storeResult
		mov	ax, partial.DDF_int.low
		cmp	ax, ds:[bx].DDF_int.low
		ja	roundUp
		jb	storeResult
		mov	ax, partial.DDF_frac.high
		cmp	ax, ds:[bx].DDF_frac.high
		ja	roundUp
		jb	storeResult
		mov	ax, partial.DDF_frac.low
		cmp	ax, ds:[bx].DDF_frac.low
		jb	storeResult
roundUp:
		add	dividend.DDD_extra.low, 1
		adc	dividend.DDD_extra.high, 0
		adc	dividend.DDD_real.DDF_frac.low, 0
		adc	dividend.DDD_real.DDF_frac.high, 0
storeResult:
	;
	; Now copy the quotient from the dividend. The part we want ends up
	; split between DDD_extra and DDD_real.DDF_frac, for some reason.
	; 
		mov	ax, dividend.DDD_extra.low
		mov	ds:[di].DDF_frac.low, ax
		mov	ax, dividend.DDD_extra.high
		mov	ds:[di].DDF_frac.high, ax
		mov	ax, dividend.DDD_real.DDF_frac.low
		mov	ds:[di].DDF_int.low, ax
		mov	ax, dividend.DDD_real.DDF_frac.high
		mov	ds:[di].DDF_int.high, ax
		
		clc	; Can't overflow
done:
		.leave
		ret
UDivideDDF	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulDDF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mutliply two DDFixed numbers

CALLED BY:	EXTERNAL
		TMatrix code
PASS:		ds:si	-> source
		es:di	-> destination
RETURN:		dx:cx	-> integer result
		bx:ax	-> fractional result
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MulDDF		proc	far
		uses	di, ds
ddfSrc		local	DDFixed
ddfDest		local	DDFixed
		.enter

		; copy params to local stack

		movdw	bxax, ds:[si].DDF_frac
		movdw	ss:ddfSrc.DDF_frac, bxax
		movdw	bxax, ds:[si].DDF_int
		movdw	ss:ddfSrc.DDF_int, bxax
		movdw	bxax, es:[di].DDF_frac
		movdw	ss:ddfDest.DDF_frac, bxax
		movdw	bxax, es:[di].DDF_int
		movdw	ss:ddfDest.DDF_int, bxax

		segmov	ds, ss, ax
		lea	bx, ss:ddfSrc
		lea	di, ss:ddfDest

		call	CalcMultiply

		; place result in registers

		movdw	dxcx, ds:[ddfDest].DDF_int
		movdw	bxax, ds:[ddfDest].DDF_frac

		.leave
		ret
MulDDF		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcMultiply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply two DDFixed numbers together, overwriting one of
		them

CALLED BY:	CalcEngineMultiply
PASS:		ds:bx	= source
		ds:di	= destination
RETURN:		ds:di	= product
		ds:bx	= abs(ds:bx)
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
	The multiplication is straight-forward -- we multiply each word in
	the source by each word in the destination -- but the combination of
	the partial products produced by the individual multiplications gets
	rather hairy. Basically, we've got an array of 16 partial products
	laid out as follows:

	Index		    SI    DX    CX    BX
	-----------------------------------------------------
	    0 |     |     |     |     |     |     | 11H | 11L
	    1 |     |     |     |     |     | 12H | 12L	|
	    2 |     |     |     |     | 13H | 13L |     |
	    3 |     |     |     | 14H | 14L |     |     |
	    4 |     |     |     |     |     | 21H | 21L |
	    5 |     |     |     |     | 22H | 22L |     |
	    6 |     |     |     | 23H | 23L |     |     |
	    7 |     |     | 24H | 24L |     |     |     |
	    8 |     |     |     |     | 31H | 31L |     |
	    9 |     |     |     | 32H | 32L |     |     |
	   10 |     |     | 33H | 33L |     |     |     |
	   11 |     | 34H | 34L |     |     |     |     |
	   12 |     |     |     | 41H | 41L |     |     |
	   13 |     |     | 42H | 42L |     |     |     |
	   14 |     | 43H | 43L |     |     |     |     |
	   15 | 44H | 44L |     |     |     |     |     |

	The first digit is the word in ds:[bx], the second is the word in
	ds:[di]. The strategy followed in combining the partial products is
	to add things so the carry can be rippled up through the successive
	pieces of the result, with any final carry during any of the additions
	being saved in the low bit of al (if it ever carries out of SI, the
	result is inaccurate and overflow is declared). Eventually, we run
	out of things to add into the high words, so we have to adc 0 to
	ripple any carry through.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcMultiply	proc	near	uses ax, bx, dx, si
pprods		local	16 dup(dword)		; 4 * 4 partial products
		.enter
	;
	; If either operand is negative, negate it and record that the result
	; should be negative, since we're using an unsigned multiply instruction
	; (as we must to deal with the multi-partite nature of the universe).
	;
		clr	ax
		tst	ds:[bx].DDF_int.high
		jns	checkDI
		xchg	di, bx
		call	CalcNegDSDI
		xchg	di, bx
		not	ax		; Signal negation needed
checkDI:
		tst	ds:[di].DDF_int.high
		jns	doMult
		call	CalcNegDSDI
		not	ax
doMult:
		push	ax		; Save the product-should-be-negative
					;  flag.

	;
	; Multiply all the words together.
	; 
		mov	ax, ds:[bx].DDF_frac.low
		clr	si
		call	multPart

		mov	ax, ds:[bx].DDF_frac.high
		call	multPart

		mov	ax, ds:[bx].DDF_int.low
		call	multPart

		mov	ax, ds:[bx].DDF_int.high
		call	multPart

	;
	; Initialize the result to 0.
	;
		clr	ax
		mov	bx, ax
		mov	cx, ax
		mov	dx, ax
		mov	si, ax

	;
	; Now combine things as detailed in the PSEUDO CODE/STRATEGY section.
	; The ordering of the products is somewhat arbitrary, chosen only to
	; avoid as many "adc 0"s as possible.
	;
		mov	ax, pprods[0].high
		add	pprods[1*dword].low, ax
		mov	ax, 0		; init overflow record
		adc	bx, pprods[1*dword].high
		adc	cx, pprods[2*dword].high
		adc	dx, pprods[3*dword].high
		adc	si, pprods[7*dword].high
		lahf
		mov	al, ah

		push	ax
		mov	ax, pprods[4*dword].low
		add	pprods[1*dword].low, ax
		pop	ax
		adc	bx, pprods[2*dword].low
		adc	cx, pprods[3*dword].low
		adc	dx, pprods[6*dword].high
		adc	si, pprods[10*dword].high
		lahf
		or	al, ah

		add	bx, pprods[4*dword].high
		adc	cx, pprods[5*dword].high
		adc	dx, pprods[9*dword].high
		adc	si, pprods[11*dword].low
		lahf
		or	al, ah

		add	bx, pprods[5*dword].low
		adc	cx, pprods[6*dword].low
		adc	dx, pprods[7*dword].low
		adc	si, pprods[13*dword].high
		lahf
		or	al, ah

		add	bx, pprods[8*dword].low
		adc	cx, pprods[8*dword].high
		adc	dx, pprods[10*dword].low
		adc	si, pprods[14*dword].low
		lahf
		or	al, ah

		add	cx, pprods[9*dword].low
		adc	dx, pprods[12*dword].high
		adc	si, 0
		lahf
		or	al, ah

		add	cx, pprods[12*dword].low
		adc	dx, pprods[13*dword].low
		adc	si, 0
		lahf
		or	al, ah

	;
	; Round the result according to the highest bit of the word into
	; which the products below bx have been accumulated (the low word of
	; product 1).
	;
		shl	pprods[1*dword].low
		adc	bx, 0
		adc	cx, 0
		adc	dx, 0
		adc	si, 0
		lahf
		or	al, ah

	;
	; Store the resulting four words in the destination, regardless of
	; overflow.
	;
		mov	ds:[di].DDF_frac.low, bx
		mov	ds:[di].DDF_frac.high, cx
		mov	ds:[di].DDF_int.low, dx
		mov	ds:[di].DDF_int.high, si

	;
	; Negate the result if we're supposed to. Note that negating the result
	; means we expect the result to be negative. If, once the result is
	; negated, the number isn't negative, the computation has overflowed
	;
		pop	cx
		jcxz	noNegate
		call	CalcNegDSDI
		jns	overflow
checkExtraWords:
	;
	; The sign appears ok, but make sure nothing carried out of all those
	; additions (low bit of ax is set if so) and none of the partial
	; products whose pieces didn't make it into the result is non-zero.
	; If these conditions don't hold, the result is inaccurate and overflow
	; has occurred. (note that "or" clears the carry.)
	;
		and	ax, 1		; Isolate carry-out flag
		or	ax, pprods[11*dword].high
		or	ax, pprods[14*dword].high
		or	ax, pprods[15*dword].low
		or	ax, pprods[15*dword].high
		jz	noOverflow
overflow:
		stc
noOverflow:
		.leave
		ret
noNegate:
	;
	; Result shouldn't be negative. Make sure of this.
	;
		tst	si
		js	overflow
		jmp	checkExtraWords

multPart:
	;
	; Subroutine to multiply a single word in the source by each word in the
	; destination, storing the resulting products in successive entries of
	; the pprods array.
	;	PASS:		ax = word by which to multiply all the pieces of
	;			     ds:[di]
	;			si = offset into pprods at which to store first
	;			     product
	;	RETURN:		si = offset into pprods at which to store next
	;			     product
	;	DESTROYED:	ax, cx, dx
	;
		mov	cx, ax		; save in cx for other multiplies
		mul	ds:[di].DDF_frac.low
		mov	pprods[si].low, ax
		mov	pprods[si].high, dx
		add	si, size dword

		mov	ax, cx
		mul	ds:[di].DDF_frac.high
		mov	pprods[si].low, ax
		mov	pprods[si].high, dx
		add	si, size dword

		mov	ax, cx
		mul	ds:[di].DDF_int.low
		mov	pprods[si].low, ax
		mov	pprods[si].high, dx
		add	si, size dword

		mov	ax, cx
		mul	ds:[di].DDF_int.high
		mov	pprods[si].low, ax
		mov	pprods[si].high, dx
		add	si, size dword
		retn
CalcMultiply	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcNegDSDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Negate the DDFixed pointed to by ds:di

CALLED BY:	CalcMultiply, CalcDivide
PASS:		ds:[di]	= number to negate
RETURN:		ds:[di] negated, of course. What else?
		js/jns will branch according as the result is
		negative/non-negative
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcNegDSDI	proc	near	uses ax
		.enter
		neg	ds:[di].DDF_frac.low
		cmc

		mov	ax, ds:[di].DDF_frac.high
		not	ax
		adc	ax, 0
		mov	ds:[di].DDF_frac.high, ax

		mov	ax, ds:[di].DDF_int.low
		not	ax
		adc	ax, 0
		mov	ds:[di].DDF_int.low, ax

		mov	ax, ds:[di].DDF_int.high
		not	ax
		adc	ax, 0
		mov	ds:[di].DDF_int.high, ax

		.leave
		ret
CalcNegDSDI	endp

GraphicsObscure	ends
