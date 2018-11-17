COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisFloat.asm

AUTHOR:		John Wedgwood, Nov 11, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	11/11/91	Initial revision

DESCRIPTION:
	Misc routines which may get moved into the float library.

	$Id: axisFloat.asm,v 1.1 97/04/04 17:45:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatCeiling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the ceiling of the number on the fp stack.

CALLED BY:	Global
PASS:		fp stack with a number on it

RETURN:		number replated on stack with ceiling of that number

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatCeiling	proc	near
	.enter
	;
	; Check for fraction.
	;
	call	FloatDup		; fp: n n
	call	FloatDup		; fp: n n n
	call	FloatTrunc		; fp: n n t
	call	FloatSub		; fp: n (n-t)
	call	FloatEq0		; fp: n
	jc	quit			; Branch if no fraction

	;
	; Number has a fractional part, remove it...
	;
	call	Float1			; fp: n 1
	call	FloatAdd		; fp: (n+1)
	call	FloatTrunc		; fp: t

quit:
	.leave
	ret
FloatCeiling	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatFloor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the floor of the number on the fp stack.

CALLED BY:	Global
PASS:		fp stack with a number on it
RETURN:		number replated on stack with floor of that number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatFloor	proc	near
	call	FloatDup		; fp: n n
	call	FloatLt0		; fp: n
	jc	negativeNumber		; Branch if <0

	;
	; Number is positive, truncate it
	;
	call	FloatTrunc		; fp: t
	jmp	quit

negativeNumber:
	;
	; Number is negative
	;
	call	FloatAbs		; fp: -c
	call	FloatCeiling		; fp: -C
	call	FloatNegate		; fp: C

quit:
	ret
FloatFloor	endp



AxisCode	ends

