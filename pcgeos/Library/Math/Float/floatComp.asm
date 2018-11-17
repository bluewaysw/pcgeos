
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		floatComp.asm

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name			Description
	----			-----------
	FloatLt
	FloatMin
	FloatMax
	FloatLt0
	FloatEq0
	FloatGt0
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:
	Comparison routines for the floating point library.

	$Id: floatComp.asm,v 1.1 97/04/05 01:23:16 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatMin (originally FMIN)

DESCRIPTION:	( FP: X1 X2 --- X3 )

CALLED BY:	INTERNAL ()

PASS:		X1, X2 on the fp stack (X2 = top)

RETURN:		min(X1, X2) on the fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatMin	proc	near
	.enter
EC<	call	FloatCheck2Args >

	call	FloatComp
	jle	ok			; branch if X1 < X2

	call	FloatSwap		; destroys ax

ok:
	FloatDrop	trashFlags
	.leave
	ret
FloatMin	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatMax (originally FMAX)

DESCRIPTION:	( FP: X1 X2 --- X3 )

CALLED BY:	INTERNAL ()

PASS:		X1, X2 on the fp stack (X2 = top)

RETURN:		max(X1, X2) on the fp stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatMax	proc	near
	.enter
EC<	call	FloatCheck2Args >

	call	FloatComp
	jge	ok			; branch if X1 >= X2

	call	FloatSwap
ok:
	FloatDrop	trashFlags
	.leave
	ret
FloatMax	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatLt0, FloatEq0, FloatGt0 (originally F0<, F0=, F0>)

DESCRIPTION:	( --- F ) ( FP: X --- )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack

RETURN:		carry - set if TRUE
			clear otherwise
		X is popped off

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatLt0	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatSign		; bx <- {+,-}
	stc
	jl	done
	clc
done:
	FloatDrop
	.leave
	ret
FloatLt0	endp


FloatEq0	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatSign
	stc
	je	done
	clc
done:
	FloatDrop
	.leave
	ret
FloatEq0	endp


FloatGt0	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatSign
	stc
	jg	done
	clc
done:
	FloatDrop
	.leave
	ret
FloatGt0	endp
