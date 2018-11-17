
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		floatEC.asm

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name			Description
	----			-----------
	FloatCheckStack
	FloatCheckStack_ES
	FloatCheckDSStack
	FloatCheckDSSI_StkTop
	FloatCheckValidDSSI
	FloatCheckLegalDecimalExponent
	FloatCheck1Arg
	FloatCheck2Args
	FloatCheckNArgs
	FloatCheckStackCount
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:
	Entire file contains error-checking code.
	Error-checking code that sits in the non-EC code as well is placed
	at the end of the file.
		
	$Id: floatEC.asm,v 1.1 97/04/05 01:22:58 newdeal Exp $

-------------------------------------------------------------------------------@

if ERROR_CHECK

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCheckStack

DESCRIPTION:	Performs integrity checks on the fp stack.

CALLED BY:	INTERNAL ()

PASS:		ds - seg addr of fp stack

RETURN:		nothing, dies if assertions fail

DESTROYED:	nothing, including flags

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	stkTop <= stkBot
	stkBot = size of the block
	size of block > size available for the fp stack (by virtue of the vars)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatCheckDSStack	proc	near
	call	FloatCheckStack
	ret
FloatCheckDSStack	endp

FloatCheckStack_ES	proc	far
	uses	ds
	.enter

	segmov	ds, es				;ds <- seg addr of stack
	call	FloatCheckStack

	.leave
	ret
FloatCheckStack_ES	endp

FloatCheckStack	proc	far	uses	ax,bx,cx,dx,di,si
	.enter
	pushf

	mov	bx, ds:FSV_handle		;bx <- mem handle of stack
	mov	ax, MGIT_ADDRESS		;ax <- MemGetInfoType
	call	MemGetInfo			;ax <- address

	mov	dx, ds
	cmp	dx, ax
	ERROR_NE	FLOAT_BAD_STACK_SEGMENT

	mov	ax, MGIT_SIZE			;ax <- MemGetInfoType
	call	MemGetInfo
	cmp	ax, ds:FSV_bottomPtr
	ERROR_L		FLOAT_BAD_STACK_BOTTOM
	cmp	ax, ds:FSV_topPtr
	ERROR_L		FLOAT_BAD_STACK_TOP

	popf
	.leave
	ret
FloatCheckStack	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCheckLegalDecimalExponent

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ax - decimal exponent

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatCheckLegalDecimalExponent	proc	far
	pushf
	cmp	ax, DECIMAL_EXPONENT_UPPER_LIMIT
	ERROR_G		FLOAT_BAD_DECIMAL_EXPONENT
	cmp	ax, DECIMAL_EXPONENT_LOWER_LIMIT
	ERROR_L		FLOAT_BAD_DECIMAL_EXPONENT
	popf
	ret
FloatCheckLegalDecimalExponent	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCheck1Arg

DESCRIPTION:	Checks to see that there are at least 1 number on the
		fp stack.

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack seg

RETURN:		nothing. Dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatCheck1Arg	proc	far	uses	ax,dx
	.enter
	pushf
	call	FloatCheckDSStack
	call	FLOATDEPTH	; ax <- depth
	cmp	ax, 1
	ERROR_L	FLOAT_INSUFFICIENT_ARGUMENTS_ON_STACK
	popf
	.leave
	ret
FloatCheck1Arg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCheck2Args

DESCRIPTION:	Checks to see that there are at least 2 numbers on the
		fp stack.

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack seg

RETURN:		nothing. Dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatCheck2Args	proc	far	uses	ax,dx
	.enter
	pushf
	call	FloatCheckDSStack
	call	FLOATDEPTH	; ax <- depth
	cmp	ax, 2
	ERROR_L	FLOAT_INSUFFICIENT_ARGUMENTS_ON_STACK
	popf
	.leave
	ret
FloatCheck2Args	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCheckNArgs

DESCRIPTION:	Checks to see that there are at least N numbers on the
		fp stack.

CALLED BY:	INTERNAL ()

PASS:		bx - N
		ds - fp stack seg

RETURN:		nothing. Dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatCheckNArgs	proc	far	uses	ax,dx
	.enter
	pushf
	call	FloatCheckDSStack
	call	FLOATDEPTH	; ax <- depth
	cmp	ax, bx
	ERROR_L	FLOAT_INSUFFICIENT_ARGUMENTS_ON_STACK
	popf
	.leave
	ret
FloatCheckNArgs	endp
endif
