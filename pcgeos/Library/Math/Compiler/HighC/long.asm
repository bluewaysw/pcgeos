COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		math2.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/ 1/93		Initial version.

DESCRIPTION:
	highc math stuff, not dependant on math library

	$Id: long.asm,v 1.1 97/04/05 01:22:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


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


MathLong     segment	resource

		SetGeosConvention

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

MathLong ends

SetDefaultConvention
