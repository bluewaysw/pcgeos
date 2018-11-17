
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson type late model 24-pin print drivers
FILE:		cursorConvert360.asm

AUTHOR:		Dave Durran, 14 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/14/90		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the Epson 24-pin
	print driver cursor movement support

	The cursor position is kept in 1/360" units.

	$Id: cursorConvert360.asm,v 1.1 97/04/18 11:49:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertToDriverCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	SendLineFeed

PASS:
	dx.ax	- number to convert WWFixed

RETURN:
	dx	- number in 1/360"

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrConvertToDriverCoordinates	proc	near
	uses	ax,cx
	.enter
	mov	cx,dx		;save the x1
	mov	bx,ax
	shl	ax,1
	rcl	dx,1		;x2
	shl	ax,1
	rcl	dx,1		;x4
	add	ax,bx		
	adc	dx,cx		;+1 for x5.
	clc
	.leave
	ret
PrConvertToDriverCoordinates	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertFromDriverCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	SendLineFeed

PASS:
	dx	- number in 1/360"

RETURN:
	dx.ax	- number in 1/72" WWFixed

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrConvertFromDriverCoordinates	proc	near
	uses	ax,cx
	.enter
	clr	ax		
	mov	cx,ax			
	mov	bx,5
	call	GrUDivWWFixed
	mov	ax,cx
	clc
	.leave
	ret
PrConvertFromDriverCoordinates	endp
