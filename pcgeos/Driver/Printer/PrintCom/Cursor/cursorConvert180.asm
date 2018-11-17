
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson type 24-pin print drivers
FILE:		cursorConvert180.asm

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

	The cursor position is kept in 1/180" units.

	$Id: cursorConvert180.asm,v 1.1 97/04/18 11:49:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertToDriverCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	SendLineFeed

PASS:
	dx.ax	- WWFixed number to convert

RETURN:
	dx	- number in integer 1/180"

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version
	Dave	03/92		WWFixed update

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrConvertToDriverCoordinates	proc	near
	uses	bx,cx
	.enter
	mov	cx,dx		;save orig.
	mov	bx,ax
	sar	cx,1		;x .5
	rcr	bx,1
	shl	ax,1		;x 2
	rcl	dx,1
	add	ax,bx		;add for x 2.5
	adc	dx,cx		;dx is our coordinates in 1/180"
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
	dx	- number in integer 1/180" units

RETURN:
	dx.ax	- WWFixed number converted to 1/72nd" units

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version
	Dave	03/92		WWFixed update

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrConvertFromDriverCoordinates	proc	near
        uses    cx,bx
        .enter
        clr     cx              ;get the fractions to zero.
        mov     ax,08000h	
        mov     bx,2            ;we divide by 2.5
        call    GrUDivWWFixed   ;do the divide
        mov     ax,cx           ;move the fraction to our reg format
        .leave
        ret
PrConvertFromDriverCoordinates	endp
