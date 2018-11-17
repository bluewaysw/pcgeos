
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson type 9-pin print drivers
FILE:		cursorConvert216.asm

AUTHOR:		Dave Durran, 14 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/14/90		Initial revision
	Dave	3/92		moved from epson9 to printcom


DESCRIPTION:
	This file contains most of the code to implement the epson FX type
	print driver cursor movement support

	The cursor position is kept in 2 words: integer 216ths in Y and
	integer 72nds in X

	$Id: cursorConvert216.asm,v 1.1 97/04/18 11:49:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertToDriverCoordinates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	convert a value passed in 1/72" units in dx.ax to 1/216" units in dx

CALLED BY:

PASS:
        dx.ax   =       WWFixed value to convert.

RETURN:
	dx	=	value in 1/216" units

DESTROYED:
        nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    02/90           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrConvertToDriverCoordinates	proc    near
	uses	cx
	.enter
	mov	cx,dx		;save x1
	shl	ax,1		;x2
	rcl	dx,1
	add	dx,cx		;add together for x3: integer done....
	.leave
	ret
PrConvertToDriverCoordinates	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrConvertFromDriverCoordinates	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
	convert a value passed in 1/216" units in dx to 1/72" units in dx.ax

CALLED BY:

PASS:
	dx	=	value in 1/216" units

RETURN:
        dx.ax   =       WWFixed value in 1/72nd " units

DESTROYED:
        nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    02/90           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrConvertFromDriverCoordinates	proc    near
	uses	cx,bx
	.enter
	clr	ax		;get the fractions to zero.
	mov	cx,ax
	mov	bx,3		;we divide by 3
	call	GrUDivWWFixed	;do the divide
	mov	ax,cx		;move the fraction to our reg format
	.leave
	ret
PrConvertFromDriverCoordinates	endp
