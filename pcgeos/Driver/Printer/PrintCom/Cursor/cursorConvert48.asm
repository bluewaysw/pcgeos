
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Toshiba print drivers
FILE:		cursorConvert48.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision from laserplsCursor.asm


DESCRIPTION:

	$Id: cursorConvert48.asm,v 1.1 97/04/18 11:49:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertToDriverCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	converts the value in 1/72s passed in ax to 1/48s

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

PrConvertToDriverCoordinates	proc	near
	uses	bx,cx
	.enter
	mov	cx,ax		;get in right reg for kernal.
	mov	bx,0		;x.66666666
	mov	ax,43690	;
	call	GrMulWWFixed
	.leave
	ret
PrConvertToDriverCoordinates	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertFromDriverCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	converts the value in 1/48s passed in ax to 1/72s

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

PrConvertFromDriverCoordinates	proc	near
	uses	bx,cx
	.enter
	clr	ax		;zero the fraction.
	mov	bx,dx		;get x1
	sar	bx,1		;x.5
	rcr	ax,1		;keep track of fraction.
	add	dx,bx		;x1.5 = 72" units.
	.leave
	ret
PrConvertFromDriverCoordinates	endp

