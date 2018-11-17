COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		math.asm
AUTOR:		jimmy

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

DESCRIPTION:
	
	This file contains the c stubs for the internal calls generated
from c code that uses floating point math routines. It also contains
the stubs for math routines explicitly called and some conversion
routines that convert numbers between some of the different formats
used for floating point numbers

	Internal Rouintes:
		_mwfcomp	compares two floats and pops them off fp stack
		_mwtrunc	truncates a float
		_mwflload	loads double var from memory onto the fp stack
		_mwload		loads float var from stack onto the fp stack
		_mwtload	loads float var from memory onto fp stack
		_mwflret	pops a number off fp stack and stuffs it
				into a double variable
		_mwfret		pops a number off fp stack and returns a
				float value on ax:dx
		_mwfflt		does nothing now, WHAT SHOULD THIS DO??????
		_mwpush8ss	pushes a double variable onto the stack
		_mwpush8cs	pushes a double constant onto the stack



	Math Routines:
		_mwfmpy		muliplies two doubles
		_mwfadd		addes two doubles
		_mwfsubr	subtracts two doubles
		_mwfdivr	divides two doubles
		_mwfdiv		divides two floats
		_mwfabs		returns absolutes value of a double
		_mwfneg		returns negative value of a double
		_mwfdup		dupliactes what is on top of the fp stack

*****		_mwten_to_the_power
*****		_mwfcompare
*****		_mwfpop
*****		_mwutrunc
*****		_mwdutrunc
*****		_mwdsin,cos,tan,ln,sqrt
*****		_mwmodl
*****		_mwfxam
*****		_mwfbld
*****		_mwfbstp
		sin		sine of number
		cos		cosine of number
		tan		tangent of number
		fabs		absolute value of number


	Help Routines:			 # bits from -> # bits to
		FloatConvertFloat80ToFloat64 	80 -> 64
		FloatConvertFloat64ToFloat80	64 -> 80
		FloatConvertFloat32ToFloat80	32 -> 80
		FloatConvertFloat80ToFloat32	80 -> 32

		FloatPushBigNumber		push 80 bit float onto fp stack

	Float Library Stubs:
		FLOATFLOATTOASCII_STDFORMAT
		FLOATINIT		
		FLOATASCIITOFLOAT
RCS STAMP:
	$Id: math.asm,v 1.1 97/04/05 01:22:43 newdeal Exp $

------------------------------------------------------------------------------@


include geos.def
include ec.def
UseLib ui.def
UseLib math.def

RealNumStruc	struct
    RNS_word1	word
    RNS_word2	word
RealNumStruc	ends

SmallFloatStruc	struct
	SFS_word1	word
	SFS_word2	word
	SFS_word3	word
	SFS_word4	word
SmallFloatStruc	ends

;
; Define _mwstack_limit variable so Establish_dgroup toggle can be used
; without worry.
;
udata	segment public word 'BSS'
DGROUP	group	udata
_mwstack_limit	label	byte
	public	_mwstack_limit
udata	ends

Math     segment	resource

		SetGeosConvention


if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwmpyl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	multiplies two 32 bit integers and returns the low 32 bits

CALLED BY:	GLOBAL	

PASS:		pushed onto stack hw1,lw1,hw2,lw2 (hw = high word)

RETURN:		dx:ax = low 32 bits of the multiplication

DESTROYED:	bx, cx, si (the compiler must realize it gets biffed...)

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	got code from high C library

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/10/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwmpyl:far
_mwmpyl	proc	far	x1:dword, x2:dword
	.enter
	mov	bx, x1.low
	mov	ax, x2.high
	mul	bx
	xchg	ax, cx
	mov	ax, x2.low
	mov	si, ax
	mul	bx
	add	cx, dx
	xchg	ax, si
	mul	x1.high
	add	ax, cx
	mov	dx, si
	xchg	ax, dx	
	.leave
	ret
_mwmpyl	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwudivlCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code to do an unsigned divide of two 32 bit numbers

CALLED BY:	GLOBAL

PASS:		dx:cx = dividend	
		bx:ax = divisor

RETURN:		dx:ax = quotient
		si:bx = remainder

DESTROYED:	Nada.

		Since the 8088 div instruction divides a 32-bit number
		by a 16-bit divisor, we can't use it (we have a 32-bit
		divisor).  Therefore we go back to basics and write our
		own divide routine.  The basic algorithm is:

			partial_dividend = 0;
		        for (count=32; count>0; count--)
			   shift dividend left;
			   shift partial_dividend left;
			   if (divisor <= partial_dividend)
			      partial_dividend -= divisor;
			      dividend++;
			quotient = dividend;
			remainder=partial_dividend;

		register/stack usage:
			dx:cx - 48-bit divident/quotient
			bx:ax	 - 32-bit partial dividend/remainder
			si	 - count
			divisor	 - 32-bit divisor

		
		Believe it or not, this algorithm was adapted from one I found
		in "6502 Software Design", by Leo Scanlon.


KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/11/92		Initial version.
	ardeb	6/15/92		Changed to do everything in registers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_mwudivlCommon	proc	near
		uses	cx, di, bp
		.enter
		clrdw	dibp		; clear partial dividend
		mov	si, 32		; bit counter (loop count)

		; loop through all bits, doing that funky divide thing
GUD_loop:
	;	shift another bit from the dividend into the partial

		saldw	dxcx
		rcl	bp
		rcl	di
	;
	; if partial dividend is >= divisor, must do some work.
	; 
		cmp	di, bx		; pdiv.high > divisor.high
		ja	GUD_work	; yes
		jne	GUD_next	; no
		cmp	bp, ax		; is equal; pdiv.low >= divisor.high?
		jb	GUD_next	; no

		; divisor <= partial dividend, do some work
GUD_work:
		inc	cx			; can only be in there once,
						;  and b0 must be 0 (it was
						;  shifted into b0 by the
						;  SALDW up there...)

		subdw	dibp, bxax		; partial dividend -= divisor
GUD_next:
		dec	si
		jg	GUD_loop		; continue with next iteration

		; set up results

		xchg	ax, cx		; dx:ax = quotient
		movdw	sibx, dibp	; si:bx = remainder (partial dividend)

		.leave
		ret			; all done
_mwudivlCommon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwudivl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	divide two 32 bit integers and return the low 32 bits 
		for an answer

CALLED BY:	global

PASS:		push hw1, lw1, hw2, lw2 (hw = high word)

RETURN:		dxax = 32 bit quotient
		sibx = 32 bit remainder

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/10/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwudivl:far
_mwudivl	proc	far	divisor:dword, dividend:dword
		.enter
		movdw	dxcx, dividend
		movdw	bxax, divisor
		call	_mwudivlCommon
		.leave
		ret
_mwudivl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwdivlCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform signed divide of 32-bit numbers

CALLED BY:	(INTERNAL) _mwdivl, _mwmodl, _mwreml
PASS:		dxcx	= dividend
		bxax	= divisor
RETURN:		dxax	= quotient (negative if dividend & divisor opposite 
			  sign)
		sibx	= remainder (negative if dividend negative)
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
_mwdivlCommon	proc	near
signBit		local	byte
dividendSign	local	byte
		.enter
		
		clr	si			; scratch for negations
	;
	; Convert operands to unsigned
	; 
		mov	ss:[dividendSign], dh
		mov	ss:[signBit], dh
		tst	dx
		jge	haveDividend
		negdw	dxcx, si

haveDividend:
		xor	ss:[signBit], bh
		tst	bx 
		jge	haveDivisor

		negdw	bxax, si
haveDivisor:
	;
	; Do the right thing.
	; 
		call	_mwudivlCommon
	;
	; If operands of different sign, negate quotient
	; 
		clr	cx
		test	ss:[signBit], 0x80
		jz	fiddleWithRemainder
		negdw	dxax, cx

fiddleWithRemainder:
	;
	; If dividend negative, make remainder negative
	; 
		test	ss:[dividendSign], 0x80
		jz	done
		negdw	sibx, cx
done:
		.leave
		ret
_mwdivlCommon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwdivl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	divide two 32 bit integers and return the low 32 bits 
		for an answer

CALLED BY:	global

PASS:		push hw1, lw1, hw2, lw2 (hw = high word)

RETURN:		dxax = 32 bit quotient
		sibx = 32 bit remainder

DESTROYED:	nothing

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/10/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwdivl:far
_mwdivl proc	far	divisor:dword, dividend:dword
		.enter
		movdw	dxcx, ss:[dividend]
		movdw	bxax, ss:[divisor]
		call	_mwdivlCommon
		.leave
		ret
_mwdivl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwumodl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	does an unsigned mod

CALLED BY:	GLOBAL

PASS:		divisor and dividend

RETURN:		dxax	= remainder
		sibx	= quotient

DESTROYED:	bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwumodl:far
_mwumodl	proc	far	divisor:dword, dividend:dword
		.enter
		movdw	dxcx, dividend
		movdw	bxax, divisor
		call	_mwudivlCommon
		xchg	ax, bx
		xchg	si, dx
		.leave
		ret
_mwumodl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwreml
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	does the remainder & quotient functions at the same time

CALLED BY:	GLOBAL

PASS:		divisor and dividend

RETURN:		dxax 	= remainder (proper sign)
		sibx	= quotient

DESTROYED:	bx, cx

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/12/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwreml:far
_mwreml	proc	far	divisor:dword, dividend:dword
		.enter
		movdw	dxcx, dividend
		movdw	bxax, divisor
		call	_mwdivlCommon
		xchg	si, dx
		xchg	ax, bx
		.leave
		ret
_mwreml		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwmodl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	does the remainder & quotient functions at the same time

CALLED BY:	GLOBAL

PASS:		divisor and dividend

RETURN:		dxax 	= remainder (positive)
		sibx	= quotient

DESTROYED:	bx, cx

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/12/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwmodl:far
_mwmodl	proc	far	divisor:dword, dividend:dword
		.enter
		movdw	dxcx, dividend
		movdw	bxax, divisor
		call	_mwdivlCommon
		tst	si
		jge	exchange
		adddw	sibx, ss:[divisor]
exchange:
		xchg	si, dx
		xchg	ax, bx
		.leave
		ret
_mwmodl		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwufflt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	converts a 32 bit integer to a 80 bit float and pushes 
		it on the FP stack	

CALLED BY:	INTERNAL
PASS:		32 bit integer on the stack

RETURN:		80 bit number on top of the FP stack	
DESTROYED:	ax,dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwufflt:far
_mwufflt	proc	far	real:dword

	.enter
	movdw	dxax,real
	call	FloatDwordToFloat
	.leave
	ret
_mwufflt	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfcmp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compares the two floating point numbers on the top
		of the FP stack 

CALLED BY:	INTERNAL

DESCRIPTION:    ( --- F ) ( FP: X1 X2 --- )


PASS:           X1, X2 on the fp stack (X2 = top)

RETURN:         flags set by what you may consider to be a cmp X1,X2
                both numbers are popped off

DESTROYED:      ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/11/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwfcmp:far
_mwfcmp	proc	far
	call	FloatCompAndDrop
	ret
_mwfcmp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwtrunc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	truncates an 80 bit floating point number to a 32 bit
		integer, it operates on the top of the FP stack
		and pops it off the FP stack

CALLED BY:	INTERNAL

PASS:		number on FP stack

RETURN:         carry clear if successful
                    dx:ax - 32 bit float
                carry set otherwise
                    dx:ax = -80000000 if X is out of range
DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	

; THIS ROUTINE NEEDS WORK, should check for overflow and all that jazz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/11/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwtrunc:far
_mwtrunc	proc	far
	call	FloatTrunc
	call	FloatFloatToDword	
	ret
_mwtrunc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwflload
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	takes a double (64 bit) float and converts it to an
		eighty bit float and pushes in onto the FP stack

CALLED BY:	INTERNAL

PASS:		a 64 bit float on the stack

RETURN:		800 bit float on FP stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
		we get passed an fptr to a 64 bit float, we convert it to
		an 80 bit float and then push it onto the FP stacl

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/11/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwflload:far
_mwflload	proc	far	smallfloat:fptr
	uses	ds, si
	.enter
	lds	si, ss:[smallfloat]
	call	FloatIEEE64ToGeos80
	.leave
	ret	
_mwflload	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfload
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert a 32 bit float to an eighty bit float and
		push it onto the FP stack

CALLED BY:	INTERNAL

PASS:		32 bit float on the stack

RETURN:		80 bit float on the FP stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
		we get passed a 32 bit float, the convert it to an
		80 bit float and push in on the FP stack

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/11/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwfload:far
_mwfload	proc	far	realfloat:dword
	.enter
	mov	dx, realfloat.high
	mov	ax, realfloat.low
	call	FloatIEEE32ToGeos80
	.leave
	ret	
_mwfload	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwftload
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	load an 80 bit float onto the FP stack

CALLED BY:	INTERNAL

PASS:		address of 80 bit float on stack

RETURN:		80 bit float on FP stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
		we get passed an fptr to an 80 bit float, so we just
		push it on to the FP stack

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/11/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwftload:far
_mwftload	proc	far	longfloat:fptr

	uses	si, ds

	.enter

	lds	si, longfloat
	call	FloatPushNumber	
	.leave
	ret	
_mwftload	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfdup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	_mwfdup duplicate the top of the FP stack

CALLED BY:	INTERNAL

PASS:		nummber X on top of stack

RETURN:		number X on top two positions of FP stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwfdup:far
_mwfdup	proc	far
	.enter
	call	FloatDup
	.leave
	ret
_mwfdup	endp
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwftret
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fills an 80 bit float from top of FP stack into a
		memory location, passed in as an fptr

CALLED BY:	INTERNAL

PASS:		fptr to location to puutt 80  bit float

RETURN:		80 bit float in passed in memory location

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwftret:far
_mwftret	proc	far	answer:fptr

	uses	di, es
	.enter
	
	les	di, answer
	call	FloatPopNumber
	jnc	done
	; don't know what should be done here
done:
	.leave

	ret
_mwftret	endp



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
global _mwflret:far
_mwflret	proc	far	answer:fptr
	uses	es, di
	.enter
	les	di, ss:[answer]
	call	FloatGeos80ToIEEE64
	.leave
	ret
_mwflret	endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfret
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pop number oof off  FP stack into 32 bit location

CALLED BY:	INTERNAL

PASS:		number on top of FP stack

RETURN:		dx:ax = 32 bit float

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
		pop number of off FP stack and convert to 32 bit float
		then put into dx:ax

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwfret:far
_mwfret		proc	far	
	.enter
	call	FloatGeos80ToIEEE32
	.leave
	ret
_mwfret	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfadd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	addes two numbers on top of FP stack

CALLED BY:	INTERNAL

PASS:		two numbers X1, X1 on top of FP stack

RETURN:		X1 + X2 on top of SP stack (X1 and X2 popped off FP stack)

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwfadd:far
_mwfadd	proc	far
	call	FloatAdd
	ret
_mwfadd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfsub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


FUNCTION:       FloatSub (originally /--)

DESCRIPTION:    Perform floating point subtraction.
                ( FP: X1 X2 --- X3 )

CALLED BY:      INTERNAL (many)

PASS:           X1, X2 on fp stack (X2 = top)
                ds - fp stack seg

RETURN:         X1-X2 on fp stack

DESTROYED:      ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
        X1 - X2  =  X1 + (-X2)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwfsub:far
_mwfsub	proc	far
	call	FloatSub
	ret
_mwfsub	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfsubr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


FUNCTION:       _mwfsubr

DESCRIPTION:    Perform floating point subtraction (in reverse order).
                ( FP: X1 X2 --- X3 )

CALLED BY:      INTERNAL (many)

PASS:           X1, X2 on fp stack (X2 = top)
                ds - fp stack seg

RETURN:         X2-X1 on fp stack

DESTROYED:      ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
        X2 - X1  =  X2 + (-X1)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwfsubr:far
_mwfsubr proc	far
	call	FloatSwap
	call	FloatSub
	ret
_mwfsubr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfmpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


FUNCTION:       _mwfmpy

DESCRIPTION:    Perform floating point multiplication
                ( FP: X1 X2 --- X3 )

CALLED BY:      INTERNAL (many)

PASS:           X1, X2 on fp stack (X2 = top)
                ds - fp stack seg

RETURN:         X1 * X2 on fp stack

DESTROYED:      ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwfmpy:far
_mwfmpy	proc	far
	call	FloatMultiply
	ret
_mwfmpy	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfdiv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:       _mwfdiv

DESCRIPTION:    Performs floating point division.
                ( fp: X1 X2 --- X1/X2 )

CALLED BY:      INTERNAL (many)

PASS:           X1, X2 on fp stack (X2 = top)
                ds - fp stack seg

RETURN:         (X1/X2) on fp stack

DESTROYED:      ax,dx

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/15/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwfdiv:far
_mwfdiv	proc	far
	call	FloatDivide
	ret
_mwfdiv	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfdivr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:       _mwfdivr

DESCRIPTION:    Performs floating point division in REVERSE ORDER as _mwfdiv
                ( fp: X1 X2 --- X1/X2 )

CALLED BY:      INTERNAL (many)

PASS:           X1, X2 on fp stack (X2 = top)
                ds - fp stack seg

RETURN:         (X2/X1) on fp stack

DESTROYED:      ax,dx

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/15/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwfdivr:far
_mwfdivr proc	far
	call	FloatSwap
	call	FloatDivide
	ret
_mwfdivr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfneg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	negates number on top of FP stack

CALLED BY:	INTERNAL

PASS:		number on top of FP stack

RETURN:		number on top of FP stack (negative of value passed in)

DESTROYED:	ax, dx

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/15/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwfneg:far
_mwfneg	proc	far
	call	FloatNegate
	ret
_mwfneg	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfabs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets absoulte value of number on FP stack

CALLED BY:	INTERNAL

PASS:		number on FP	 stack

RETURN:		absolute value of number passed in on top of FP stack

DESTROYED:	ax, dx

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/15/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global _mwfabs:far
_mwfabs	proc	far
	call	FloatAbs
	ret
_mwfabs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwfflt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	converts a 32 bit interger to an 80 bit float and pushes
		it onto FP stack

CALLED BY:	INTERNAL

PASS:		32 bit integer on stack

RETURN:		80 bit number of top of FP stack

DESTROYED:	ax, dx

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/15/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwfflt:far
_mwfflt	proc	far	myreal:dword

	.enter
	movdw	dxax, myreal
	call	FloatDwordToFloat
	.leave
	ret
_mwfflt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwpush8es
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	push a 64 bit float from the code segment onto the stack

CALLED BY:	INTERNAL

PASS:		es:cx = 64 bit number to push

RETURN:		ss:sp = 64 bit number on the  stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????
; gotta love this code (i got it from the hcme.lib, it's not mine, honest!!)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/16/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwpush8es:far
_mwpush8es	proc	far
	sub	sp, 4
	push	ds
	segmov	es, cs
	jmp	_mwpush8_common
_mwpush8es	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwpush8cs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	push a 64 bit float from the code segment onto the stack

CALLED BY:	INTERNAL

PASS:		cs:cx = 64 bit number to push

RETURN:		ss:sp = 64 bit number on the  stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????
; gotta love this code (i got it from the hcme.lib, it's not mine, honest!!)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/16/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwpush8cs:far
_mwpush8cs	proc	far
	sub	sp, 4
	push	ds
	segmov	ds, cs
	jmp	_mwpush8_common
_mwpush8cs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwpush8ds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	push a 64 bit float from the code segment onto the stack

CALLED BY:	INTERNAL

PASS:		ds:cx = 64 bit number to push

RETURN:		ss:sp = 64 bit number on the  stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????
; gotta love this code (i got it from the hcme.lib, it's not mine, honest!!)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/16/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwpush8ds:far
_mwpush8ds	proc	far
	sub	sp, 4
	push	ds
	jmp	_mwpush8_common
_mwpush8ds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_mwpush8ss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	push a  64 bit number from the stack segment 
		(i.e. a local variable) onto the stack

CALLED BY:	INTERNAL

PASS:		ss:cx = 64 bit number

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/16/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	_mwpush8ss:far
_mwpush8ss	proc	far

;	CX <- addr of float #

	; this code writes directly onto the stack
	; so it leaves a 64 bit float on the stack

	; now we allocate 4 bytes on the stack, the other four bytes
	; come from the four bytes taken by the return address
	sub	sp, 4	
	push	ds
	segmov	ds, ss
_mwpush8_common	label	far
	; ds:cx = addr of 8-byte thing
	; on_stack: 	saved DS
	;		4 bytes of space
	;		far return addr
	push	es
	push	si		; save di and si 
	push	di

	; es contains destination segment of the movsw
	; so es <- stack segment
	mov	si, cx		; ds:si = 64 bit number
	mov	di, sp
	add	di, 8		; es:di = destination for 64 bit number
				;  (skip over saved di, si, es, ds)
	
	; so now we fill up the first four bytes with data, since they
	; contain nothing interesting.
	segmov	es, ss
	movsw
	movsw

	; now we save away the return address sitting on the stack
	; and then write over the return address the remaining four bytes
	; of the 64 bit word (2 bytes at a time)

	mov	dx, es:[di]	;Load return addr
	movsw
	mov	cx, es:[di]
	movsw
	pop	di		;Restore old vals of si, di
	pop	si	
	pop	es
	pop	ds
	pushdw	cxdx		;Push return addr
	ret
_mwpush8ss	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatPushBigFloat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	push an 80 bit float onto FP stack

CALLED BY:	INTERNAL

PASS:		80 bit float in local variable bigFloat

RETURN:		80 bit number on top of FP stack

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/16/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatPushBigFloat	proc	near

	bigfloat	local	FloatNum

	uses	ds, si
	.enter	inherit near

	segmov	ds, ss, si
	lea	si, bigfloat
	call	FloatPushNumber	
	.leave
	ret
FloatPushBigFloat	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      FloatConvertFloat64ToFloat80

DESCRIPTION:   convert 64 bit format to 80 format


PASS:         es:bx = 64 bit number 

RETURN:       bigfloat = 80 bit format number

DESTROYED:      ???

PSEUDO CODE/STRATEGY:
		convert the exponent by subtracting out 64 bit bias (0x3ff) 
		and adding 80 bit bias (0x3fff)

		convert mantissa by copying over entire mantissa and filling
		remaining bits with zeros

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        JDM     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatConvertFloat64ToFloat80	proc	near

	bigfloat	local FloatNum
	.enter	inherit near

	; start with the most significant part of the mantissa
	; since the mantissa does no lie on byte or word boundaries
	; we must extract the first 16 bits and stuff them into a
	; word and then move them into the 80 bit numbers' mantissa

	add	bx, 3 *  (size word)
	call	FloatConvertFloat64ToFloat80Help

	; for the 64 bit format, there is an implied 1 as the first
	; bit of the mantissa, but the 80 bit format does not, so
	; we must turn it on explicitly

	or	ax, 0x8000		; MSB must be one
	mov	ss:[bigfloat].F_mantissa_wd3, ax

	; now do next most significant word of the mantissa
	call	FloatConvertFloat64ToFloat80Help
	mov	ss:[bigfloat].F_mantissa_wd2, ax

	; now do next most significant word of the mantissa
	call	FloatConvertFloat64ToFloat80Help
	mov	ss:[bigfloat].F_mantissa_wd1, ax

	; now do next most significant word of the mantissa
	; since this is the last one, we call the common routine
	; rather that the help routine to just get first half
	; last word of the mantissa

	call	FloatConvertFloat64ToFloat80Common
	mov	ss:[bigfloat].F_mantissa_wd0, ax


	; now for the exponent
	add	bx, 3 * (size word)	; es:bx = exponent
	mov	ax, es:[bx]		; ax = exponent
	mov	dx, ax			
	and	dx, 0x8000		; dx = sign bit of exponent

	; now shift over exponent to line up with the edge of the word
	mov	cl, 4			
	shr	ax, cl			

	; zero out all non-relavent bits
	and	ax, 0x7ff		; turn off sign bit

	; zero is a special case, if the exponent is zero we have the
	; number zero, so just zero out exponent
	tst	ax	
	jz	cont
	; if its not zero, subtract 64 bit bias and add 80 bit bias
	; and restore sing bit the corrent position
	sub	ax, 0x3ff		; subtract off old bias
	add	ax, 0x3fff		; add on new one
	or	ax, dx			; put in sign bit in correct place
	jmp	cont
cont:
	mov	ss:[bigfloat].F_exponent, ax
	.leave
	ret
FloatConvertFloat64ToFloat80	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatConvertFloat64ToFloat80Help
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	shoves the next sixteen bits of the mantissa into ax

CALLED BY:	FloatConvertFloat64ToFloat80

PASS:		es:bx = pointer to next most significant 16 bits of mantissa

RETURN:		ax = next 16 bits of mantissa

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
		
KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/16/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatConvertFloat64ToFloat80Help	proc	near
	bigfloat	local	FloatNum

	.enter inherit near
	call	FloatConvertFloat64ToFloat80Common
	sub	bx, size word
	mov	dx, es:[bx]
	mov	cl, 5
	shr	dx, cl
	or	ax, dx
	.leave
	ret
FloatConvertFloat64ToFloat80Help	endp

FloatConvertFloat64ToFloat80Common	proc	near
	mov	ax, es:[bx]
	and	ax, 0x1f
	mov	cl, 11
	shl	ax, cl
	ret
FloatConvertFloat64ToFloat80Common	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      floatConvertFloat80ToFloat64

DESCRIPTION:   convert 80 bit format to 64 format


PASS:         bigfloat = 80 bit format number

RETURN:       es:(bx-6) = 64 bit number 

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        JDM     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatConvertFloat80ToFloat64	proc	far
	bigfloat	local	FloatNum

	.enter	inherit far

	mov	{word}es:[bx], 0
	add	bx, size word
	mov	{word}es:[bx], 0
	add	bx, size word
	mov	{word}es:[bx], 0
	add	bx, size word
	mov	{word}es:[bx], 0

	stc
	mov	ax, ss:[bigfloat].F_mantissa_wd3
	call	FloatConvertFloat80ToFloat64Help

	clc
	mov	ax, ss:[bigfloat].F_mantissa_wd2
	call	FloatConvertFloat80ToFloat64Help

	clc					
	mov	ax, ss:[bigfloat].F_mantissa_wd1
	call	FloatConvertFloat80ToFloat64Help

	clc
	mov	ax, ss:[bigfloat].F_mantissa_wd0
	call	FloatConvertFloat80ToFloat64Common

	add	bx, 3 * (size word)

	mov	ax, ss:[bigfloat].F_exponent
	mov	dx, ax			; save sign bit
	and	dx, 0x8000		; get sign bit

	and	ax, 0x7fff		; truncate exponent
	jz	doZero
	sub	ax, 0x3fff
	add	ax, 0x3ff

	mov	cl, 4
	shl	ax, cl
	or	ax, dx
	mov	dx, es:[bx]
	and	dx, 0xf				; get bottom nibble
	or	ax, dx
	jmp	cont
doZero:
	clr	ax
cont:
	mov	es:[bx], ax	
	.leave
	ret
FloatConvertFloat80ToFloat64	endp



FloatConvertFloat80ToFloat64Help	proc	far
	bigfloat	local	FloatNum

	.enter inherit far
	mov	dx, es:[bx]
	jc	doMSB
	and	dx, 0xffe0		; clear out bottom 5 bits
	call	FloatConvertFloat80ToFloat64Common
	jmp	cont
doMSB:
	and	dx, 0xfff0		; clear out bottom 4 bits
	and	ax, 0x7fff		; turn off MSB (always 1)
	call	FloatConvertFloat80ToFloat64Common
cont:
	mov	cl, 5
	shl	ax, cl
	sub	bx, size word
	mov	es:[bx], ax

	.leave
	ret
FloatConvertFloat80ToFloat64Help	endp


FloatConvertFloat80ToFloat64Common	proc	near
	uses	ax
	.enter
	mov	cl, 11
	shr	ax, cl
	or	ax, dx
	mov	es:[bx], ax
	.leave
	ret
FloatConvertFloat80ToFloat64Common	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      FloatConvertFloat80ToFloat32

DESCRIPTION:   convert 32 bit number to 80 bit number


PASS:          cx:dx = 32 bit number

RETURN:        

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        JDM     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatConvertFloat80ToFloat32	proc	near

	bigfloat	local	FloatNum

	.enter	inherit near

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
FloatConvertFloat80ToFloat32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      FloatConvertFloat32ToFloat80

DESCRIPTION:   convert 32 bit number to 80 bit number


PASS:          cx:dx = 32 bit number

RETURN:        

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        JDM     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatConvertFloat32ToFloat80	proc	near

	bigfloat	local	FloatNum

	.enter	inherit near

	mov	ax, cx
	mov	bx, dx
	push	cx
	push	dx
	mov	cl, 8
	shl	ax, cl
	or	ax, 0x8000		; turn on implicit 1
	shr	bx, cl
	or	ax, bx
	mov	ss:[bigfloat].F_mantissa_wd3, ax
	pop	dx
	shl	dx, cl
	mov	ss:[bigfloat].F_mantissa_wd2, dx
	mov	ss:[bigfloat].F_mantissa_wd1, 0
	mov	ss:[bigfloat].F_mantissa_wd0, 0
	
	pop	cx
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
	.leave
	ret
FloatConvertFloat32ToFloat80	endp


FLOATFLOATTOASCII_STDFORMAT	proc	far 	mystring:fptr,
						mynumber:SmallFloatStruc,
						format:word,
						digits:word,
						fraction:word

	bigfloat	local	FloatNum
	uses	ds, si, di
	.enter	

	lea	bx, mynumber
	call	FloatConvertFloat64ToFloat80

	segmov	ds, ss
	lea	si, bigfloat
	
	mov	ax, ss:[mystring].segment
	mov	es, ax
	mov	ax, ss:[mystring].offset
	mov	di, ax
	mov	ax, ss:[digits]
	mov	bx, ss:[fraction]
	mov	bh, al
	mov	ax, ss:[format]

	call	FloatFloatToAscii_StdFormat
	.leave
	ret
FLOATFLOATTOASCII_STDFORMAT	endp

FLOATASCIITOFLOAT	proc	far	flags:word,
					mylength:word,
					mystring:fptr,
					destAddr:fptr		
	uses	ds, di, si
	.enter
	mov	ax, flags
	mov	cx, mylength
	lds	si, mystring
	les	di, destAddr
	call	FloatAsciiToFloat
	.leave
	ret
FLOATASCIITOFLOAT	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_trig_common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code to implement the various trigonometric functions
		in this file

CALLED BY:	sin, cos, sinh, cosh, tan, tanh, ...
PASS:		each of these routines receives on the stack:
			sp	-> retf
				   destAddr (fptr.dword)
				   arg (double)
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		First set up the regular stack
		Push the operand
		Call our caller back to do what it needs to do
		Store the top of the FPU stack in the passed buffer
		return, clearing the stack

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.model	medium, C

_trig_common	proc	near 	:fptr.far,	; caller's return address
				destAddr:fptr.dword,
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
	;
	; Return the result in the passed buffer.
	; 
		pushdw	ss:[destAddr]
		call	_mwflret

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

sin	proc	far 
	call	_trig_common
	call	FloatSin
	retn
sin	endp
	public	sin

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

cos	proc	far
	call	_trig_common
	call	FloatCos
	retn
cos	endp
	public	cos

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

tan	proc	far
	call	_trig_common
	call	FloatTan
	retn
tan	endp
	public	tan

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

cosh	proc	far
	call	_trig_common
	call	FloatCosh
	retn
cosh	endp
	public	cosh

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

sinh	proc	far
	call	_trig_common
	call	FloatSinh
	retn
sinh	endp
	public	sinh

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

tanh	proc	far
	call	_trig_common
	call	FloatTanh
	retn
tanh	endp
	public	tanh

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

atan	proc	far
	call	_trig_common
	call	FloatArcTan
	retn
atan	endp
	public	atan

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

asin	proc	far
	call	_trig_common
	call	FloatArcSin
	retn
asin	endp
	public	asin

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

acos	proc	far
	call	_trig_common
	call	FloatArcCos
	retn
acos	endp
	public	acos

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

atanh	proc	far
	call	_trig_common
	call	FloatArcTanh
	retn
atanh	endp
	public	atanh

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

asinh	proc	far
	call	_trig_common
	call	FloatArcSinh
	retn
asinh	endp
	public	asinh

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

acosh	proc	far
	call	_trig_common
	call	FloatArcCosh
	retn
acosh	endp
	public	acosh

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

log	proc	far
	call	_trig_common
	call	FloatLog
	retn
log	endp
	public	log

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

ln	proc	far
	call	_trig_common
	call	FloatLn
	retn
ln	endp
	public	ln

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


sqrt	proc	far
	call	_trig_common
	call	FloatSqrt
	retn
sqrt	endp
	public	sqrt

Math	ends

SetDefaultConvention
