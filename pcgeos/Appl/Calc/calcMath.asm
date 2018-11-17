COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calculator
FILE:		calcMath.asm

AUTHOR:		Adam de Boor, Mar 15, 1990

ROUTINES:
	Name			Description
	----			-----------
	CalcAdd			Add two DDFixed numbers
	CalcSubtract		Subtract two DDFixed numbers
	CalcMultiply		Multiply two DDFixed numbers
	CalcDivide		Divide two DDFixed numbers
	CalcAToF		Convert from a string to DDFixed
	CalcFToA		Convert a DDFixed to an ascii string

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/15/90		Initial revision


DESCRIPTION:
	The actual fixed-point math routines for the calculator
		

	$Id: calcMath.asm,v 1.1 97/04/04 14:47:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Main		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add two fixed point numbers, overwriting one of them

CALLED BY:	CalcEngineAdd
PASS:		ds:bx	= source
		ds:di	= destination (overwritten)
RETURN:		sum of the two numbers is placed in ds:di
		carry set on overflow
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcAdd		proc	near	uses ax
		.enter
		mov	ax, ds:[bx].DDF_frac.low
		add	ds:[di].DDF_frac.low, ax
		mov	ax, ds:[bx].DDF_frac.high
		adc	ds:[di].DDF_frac.high, ax
		mov	ax, ds:[bx].DDF_int.low
		adc	ds:[di].DDF_int.low, ax
		mov	ax, ds:[bx].DDF_int.high
		adc	ds:[di].DDF_int.high, ax
		clc		; Assume no overflow
		jno	ok
		stc		; signal overflow.
ok:
		.leave
		ret
CalcAdd		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcSubtract
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subtract two DDFixed numbers, overwriting the number
		subtracted from.

CALLED BY:	CalcEngineSubtract
PASS:		ds:bx	= value to subtract
		ds:di	= value from which to subtract
RETURN:		difference stored in ds:di
		carry set on overflow.
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcSubtract	proc	near	uses ax
		.enter
		mov	ax, ds:[bx].DDF_frac.low
		sub	ds:[di].DDF_frac.low, ax
		mov	ax, ds:[bx].DDF_frac.high
		sbb	ds:[di].DDF_frac.high, ax
		mov	ax, ds:[bx].DDF_int.low
		sbb	ds:[di].DDF_int.low, ax
		mov	ax, ds:[bx].DDF_int.high
		sbb	ds:[di].DDF_int.high, ax
		clc		; Assume no overflow
		jno	ok
		stc		; Signal overflow
ok:
		.leave
		ret
CalcSubtract	endp



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
		CalcDivide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signed division

CALLED BY:	EXTERNAL
PASS:		ds:bx	= source (divisor)
		ds:di	= destination (dividend)
RETURN:		ds:di	= quotient of ds:[di]/ds:[bx]
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDivide	proc	near
		.enter
		clr	ax
		tst	ds:[bx].DDF_int.high
		jns	checkDI
		xchg	bx, di
		call	CalcNegDSDI
		xchg	bx, di
		not	ax
checkDI:
		tst	ds:[di].DDF_int.high
		jns	setup
		call	CalcNegDSDI
		not	ax
setup:
		push	ax
		call	CalcUDivide
		pop	cx
		jc	error
		jcxz	noNegate
		neg	ds:[di].DDF_frac.low
		not	ds:[di].DDF_frac.high
		not	ds:[di].DDF_int.low
		not	ds:[di].DDF_int.high
		cmc
		jnc	noNegate
		adc	ds:[di].DDF_frac.high, 0
		adc	ds:[di].DDF_int.low, 0
		adc	ds:[di].DDF_int.high, 0
noNegate:
		clc		; Can be no overflow
error:
		.leave
		ret
CalcDivide	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcUDivide
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

CalcUDivide	proc	near	uses cx
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
CalcUDivide	endp

powersOfTen	dword	1,
			10,
			100,
			1000,
			10000,
			100000,
			1000000,
			10000000,
			100000000,
			1000000000,
			1000000000



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCvtFrac
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an ascii string to an unsigned 32-bit integer
		suitable for dividing by one of the powersOfTen to obtain
		a fraction

CALLED BY:	CalcAToF
PASS:		ds:si	= string to convert
RETURN:		dx:bx	= integer
		al	= terminating character
		cx	= number of characters consumed
		ds:si	= character after terminating character
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcCvtFrac	proc	near	uses di, bp
		.enter
		clr	bx
		mov	dx, bx
		mov	ax, bx
		mov	cx, length powersOfTen-1
intLoop:
		lodsb
		cmp	al, '0'
		jb	doneFrac
		cmp	al, '9'
		ja	doneFrac
		sub	al, '0'
		DoPush	dx, bx		; save current in case of overflow

	;
	; Now multiply the previous result by 10.
	;
		shl	bx
		rcl	dx
		jc	overflow
		mov	bp, bx
		mov	di, dx
		shl	bx
		rcl	dx
		jc	overflow
		shl	bx
		rcl	dx
		jc	overflow
		add	bx, bp
		adc	dx, di
		jc	overflow
	;
	; Add in the new digit and loop if we've not overflowed.
	; 
		add	bx, ax
		adc	dx, 0
		jc	overflow
		add	sp, 4
		loop	intLoop
doneFrac:
		sub	cx, length powersOfTen-1
		neg	cx
		clc
		.leave
		ret
overflow:
	;
	; On overflow, just throw away the rest of the fraction, as it's
	; not significant to our calculations.
	; 
		DoPopRV	dx, bx
		jmp	doneFrac
CalcCvtFrac	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCvtInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an ascii string to a signed 32-bit integer

CALLED BY:	CalcAToF
PASS:		ds:si	= string to convert
RETURN:		dx:bx	= integer
		al	= terminating character
		cx	= number of characters consumed
		ds:si	= character after terminating character
		carry set on overflow
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcCvtInt	proc	near	uses di, bp
		.enter
		clr	bx
		mov	dx, bx
		mov	cx, bx
		mov	ax, bx
intLoop:
		lodsb
		cmp	al, '0'
		jb	doneInt
		cmp	al, '9'
		ja	doneInt
		inc	cx		; another digit converted
		sub	al, '0'

	;
	; Now multiply the previous result by 10.
	;
		shl	bx
		rcl	dx
		jc	done
		mov	bp, bx
		mov	di, dx
		shl	bx
		rcl	dx
		jc	done
		shl	bx
		rcl	dx
		jc	done
		add	bx, bp
		adc	dx, di
		jc	done
	;
	; Add in the new digit and loop if we've not overflowed.
	; 
		add	bx, ax
		adc	dx, 0
		jnc	intLoop
		jmp	done
doneInt:
		clc
done:
		.leave
		ret
CalcCvtInt	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcAToF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a real number in ascii (no exponent) to DDFixed

CALLED BY:	CalcEnter
PASS:		ds:si	= string to evaluate
		es:di	= place to store result
		al	= decimal point
RETURN:		carry set on overflow,
		else carry clear, and result in es:di
DESTROYED:	si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcAToF	proc	near	uses ax, bx, cx, dx, ds, si
temp		local	DDFixed		; Temp result for converting int to
					;  fraction
divisor		local	DDFixed		; Divisor to use for converting int to
					;  fraction.
decimal		local	char		; Decimal point
		.enter
		mov	ss:[decimal], al
		clr	ax
		mov	es:[di].DDF_frac.low,ax	; In case no fraction (integer
		mov	es:[di].DDF_frac.high,ax;  always loaded)
		mov	ss:[temp].DDF_frac.low, ax
		mov	ss:[temp].DDF_frac.high, ax

		cmp	{char}ds:[si], '-'
		jne	notNegative
		inc	si
		not	ax
notNegative:
		not	ax
		push	ax		; Save whether result should be positive
	;
	; Convert integer to 32-bit number and store it in the result
	;
		call	CalcCvtInt
		jc	overflow
		mov	es:[di].DDF_int.low, bx
		mov	es:[di].DDF_int.high, dx
		cmp	al, ss:[decimal]	; Ended on a decimal point?
		jne	final		; Nope => no fraction
	;
	; Convert fraction to 32-bit number
	;
		call	CalcCvtFrac
		mov	ss:[temp].DDF_int.low, bx
		mov	ss:[temp].DDF_int.high, dx
		push	di
		segmov	ds, ss, bx
		lea	di, ss:[temp]
divLoop:
	;
	; Figure the proper power of 10 from the number of digits in the
	; fraction, copying the power into divisor in our frame.
	;
		clr	ax
		mov	ss:[divisor].DDF_frac.low, ax
		mov	ss:[divisor].DDF_frac.high, ax
		mov	bx, cx
		shl	bx
		shl	bx
		mov	ax, cs:powersOfTen[bx].low
		mov	ss:[divisor].DDF_int.low, ax
		mov	ax, cs:powersOfTen[bx].high
		mov	ss:[divisor].DDF_int.high, ax
		
	;
	; Divide the integer we got (now in temp) by the power of 10 we need
	; (now in divisor).
	; 
		lea	bx, divisor
		call	CalcUDivide
		sub	cx, 9
		jg	divLoop
		pop	di
	;
	; Copy the fraction of the result from temp into our result.
	;
		mov	ax, ss:[temp].DDF_frac.low
		mov	es:[di].DDF_frac.low, ax
		mov	ax, ss:[temp].DDF_frac.high
		mov	es:[di].DDF_frac.high, ax
final:
	;
	; Negate the result if there was a leading '-' on the string.
	;
		pop	cx
		jcxz	negate
		tst	es:[di].DDF_int.high	; should be positive...
		js	overflowNoPop
noOverflow:
		clc	; Signal no overflow
done:
		.leave
		ret
overflow:
		pop	cx		; Discard negation-needed flag
overflowNoPop:
		stc			; Flag overflow
		jmp	done
negate:
		neg	es:[di].DDF_frac.low
		not	es:[di].DDF_frac.high
		not	es:[di].DDF_int.low
		not	es:[di].DDF_int.high
		cmc
		adc	es:[di].DDF_frac.high, 0
		adc	es:[di].DDF_int.low, 0
		adc	es:[di].DDF_int.high, 0
		jns	overflowNoPop	; Should be negative, since we negated
					;  it. If result not negative, it's too
					;  big.
		jmp	noOverflow
CalcAToF	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcIToA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a signed 32-bit integer to ascii

CALLED BY:	CalcFToA
PASS:		dx:ax	= 32-bit unsigned integer
		es:di	= buffer in which store the result
RETURN:		es:di	= null byte after converted number
		cx	= length of number, including null
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcIToA	proc	near
		.enter
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii
	;
	; Locate the end of the result (null terminated)
	;
		clr	al
		mov	cx, -1
		repne	scasb
		not	cx		;cx = length including null
		dec	di
		.leave
		ret
CalcIToA	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcFToA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a DDFixed number to its ascii equivalent

CALLED BY:	CalcDisplayDSBX
PASS:		es:di	= Place to store result
		ds:bx	= Number to convert
		cx	= Precision for converting fraction (number of
			  digits after the decimal point)
		al	= decimal point
RETURN:		Nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcFToA	proc	near	uses ax, bx, cx, dx, si, di
fracCount	local	byte	; Counter for fractional part. We've only got a
				;  certain amount of precision in this format,
				;  and there's no point in pretending we've got
				;  more. This counter limits the number of
				;  digits we produce for the fractional portion.
				;  Any trailing zeroes are trimmed off at the
				;  end.
buffer		local	word	; Storage for buffer start in case we have to
				;  round the integer part up...
temp		local	DDFixed
decimalAddr	local	word	; Offset of decimal separator in string.
		.enter
		push	ax
		mov	ss:[buffer], di
		mov	ss:[fracCount], cl	; Save precision
	;
	; If the number is negative, store a - at the front and negate the
	; number before we stick it in temp. This allows us to forget about the
	; sign for the rest of the time, unless we round the thing to 0, of
	; course, when we have to be careful not to say something stupid like
	; -0
	;
		mov	si, ds:[bx].DDF_frac.low
		mov	cx, ds:[bx].DDF_frac.high
		mov	ax, ds:[bx].DDF_int.low
		mov	dx, ds:[bx].DDF_int.high
		tst	dx
		jns	storeTemp
		mov	{char}es:[di], '-'
		inc	di

		neg	si
		not	cx
		not	ax
		not	dx
		cmc
		adc	cx, 0
		adc	ax, 0
		adc	dx, 0
storeTemp:
		mov	ss:[temp].DDF_frac.low, si
		mov	ss:[temp].DDF_frac.high, cx
		mov	ss:[temp].DDF_int.low, ax
		mov	ss:[temp].DDF_int.high, dx
	;
	; Convert the integer to ascii first (already in dx:ax).
	;
		call	CalcIToA
	;
	; Now multiply the fraction by 10 (with shifts) until the fraction is
	; 0.
	;
		mov	cx, ss:[temp].DDF_frac.high
		mov	dx, ss:[temp].DDF_frac.low

		pop	ax		; Recover decimal separator

		tst	dx
		jnz	startFrac
		jcxz	noTrim
startFrac:
		mov	ss:[decimalAddr], di	; Record separator addr for
						;  possible trimming.
		stosb
		tst	fracCount
		jz	round
fracLoop:
	;
	; Multiply the remaining fraction by 10 to get the next digit.
	;
		call	nextDigit
		stosb
		dec	fracCount	; Precision exhausted?
		jz	round		; yes
		tst	dx		; Anything in this fractional word?
		jnz	fracLoop	; yes -- keep going
		tst	cx		; How about this one?
		jnz	fracLoop
toAscii:
		push	di
		dec	di
		mov	si, di
		std
		lodsb	es:
toAsciiLoop:
		add	al, '0'
		stosb
		cmp	si, ss:[decimalAddr]
		lodsb	es:
		jne	toAsciiLoop
		pop	di
noTrim:
		cld
		clr	al
		stosb
		.leave
		ret
round:
	;
	; We ran out of precision. Figure another digit and use that to round
	; the rest of the digits.
	;
		call	nextDigit
		lea	si, [di-1] 	; es:si = last fractional digit
		std
		cmp	al, 5
		jl	trimZeroes
roundTrimLoop:				;First deal with trailing zeroes caused
					; by rippling in the rounding carry
		cmp	si, ss:[decimalAddr]
		lodsb	es:
		je	noFractionRoundUp
		inc	ax		;(1-byte inst)
		aaa			;sets carry if result > 9
		dec	di		;es:di = byte from which al came in case
					; we need to store it back
		jc	roundTrimLoop
		;
		; Have a fractional digit that doesn't need to ripple to
		; the next and, thus, is not 0. Store the adjusted digit back
		; in, setting DI to just after it as the location for the null
		; terminator, then go convert the fractional digits to ascii
		;
saveThisOne:
		cld
		stosb
		jmp	toAscii
noFractionRoundUp:
		mov	ax, 1
noFractionLeft:
	;
	; Need to round the integer up as well. Rather than trying to do it
	; with the already-converted ascii representation, it seems easier
	; to just reconvert an incremented version of the thing.
	;
		cld
		mov	di, ss:[buffer]
		add	ax, ss:[temp].DDF_int.low
		mov	dx, ss:[temp].DDF_int.high
		adc	dx, 0
		cmp	{char}es:[di], '-'	; Number started out negative?
		jne	reconvert	; No -- just convert
		inc	di		; Assume still negative
		tst	ax		; If number is 0, don't want to say
		jnz	reconvert	; '-0'
		tst	dx
		jnz	reconvert
		dec	di		; just zero, so trash '-'
reconvert:
		call	CalcIToA
		jmp	noTrim
trimZeroes:
	;
	; Trim any trailing zeroes.
	;
		cmp	si, ss:[decimalAddr]
		lodsb	es:
		je	noFractionThere
		dec	di		;es:di = source of al
		cmp	al, 0
		jne	saveThisOne
		jmp	trimZeroes

noFractionThere:
	;
	; Another special case. Don't want to have a decimal if no precision
	; allowed or fraction is actually non-existent. Also don't want
	; to show -0...
	;
		mov	ax, 0		; no increment required
		jmp	noFractionLeft
nextDigit:
	;
	; Multiply cx:dx by 10, leaving next fractional digit in al
	; ah, bx, si destroyed
	;
		clr	al	; Clear units byte
		shl	dx	; frac *= 2
		rcl	cx
		rcl	al
		mov	ah, al	; save that away for addition
		mov	bx, cx
		mov	si, dx
		shl	dx	; frac *= 4
		rcl	cx
		rcl	al
		shl	dx	; frac *= 8
		rcl	cx
		rcl	al
		add	dx, si	; frac *= 10
		adc	cx, bx
		adc	al, ah
		retn
CalcFToA	endp

Main		ends
