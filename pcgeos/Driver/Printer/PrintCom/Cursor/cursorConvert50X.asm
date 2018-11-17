
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		NIKE print drivers
FILE:		cursorConvert50X.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/94		Initial revision 


DESCRIPTION:

	$Id: cursorConvert50X.asm,v 1.1 97/04/18 11:49:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertToDriverXCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	converts the value in 1/72s passed in ax to 1/50s

CALLED BY:
	PrintSwath

PASS:
	dx.ax	=	value to convert.

RETURN:
	dx	=	value converted.

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrConvertToDriverXCoordinates	proc	near
	uses	bx,cx
	.enter
	mov	cx,ax		;get in right reg for kernal.
	mov	bx,0		;x0.69444444....
	mov	ax,45511	;
	call	GrMulWWFixed
	.leave
	ret
PrConvertToDriverXCoordinates	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertFromDriverXCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	converts the value in 1/50s passed in ax to 1/72s

CALLED BY:
	PrintSwath

PASS:
	dx	=	value to convert.

RETURN:
	dx.ax	=	value converted.

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrConvertFromDriverXCoordinates	proc	near
	uses	bx,cx
	.enter
	clr	cx		;zero the fraction.
	mov	bx,0		;/0.69444444....
	mov	ax,45511
	call	GrUDivWWFixed
	mov	ax,cx		;dx.ax now is the result.
	.leave
	ret
PrConvertFromDriverXCoordinates	endp

