
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		cursorPrLineFeedDumb6LPI.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/93		Initial revision


DESCRIPTION:

	$Id: cursorPrLineFeedDumb6LPI.asm,v 1.1 97/04/18 11:49:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrLineFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
        Executes a vertical line feed of dx 1/48", and updates
	the cursor position accordingly.

CALLED BY:
        Jump Table

PASS:
        es      =       segment of PState
        dx      =       length , in 1/48" to line feed.

	NOTE NOTE NOTE! This routine is NOT general purpose! it requires dx
			to be in 1/48" units.

RETURN:
        carry   - set if some transmission error

DESTROYED:
        nothing

PSEUDO CODE/STRATEGY:
	This routine is for only the stupidest printers where you cannot set
	the vertical line pitch. We have to live with a very coarse adjustment
	(Usually the ascii line spacing).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    02/93           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrLineFeed      proc    near
	uses    cx,dx
	.enter
		;first round the position to the nearest 1/6".
	test	dx,04h				;check most significant frac
	jz	andOff				;if to the low side just stuff
	add	dx,08h				;round up if here....
andOff:
	and	dx,0fff8h			;get rid of low 3 bits
	add     es:PS_cursorPos.P_y,dx

	shr	dx,1			;/8
	shr	dx,1			;to get 1/6" increments
	shr	dx,1

	mov     cx,dx
	jcxz    exit
lfLoop:
	mov     dx,cx			;save....
	mov	cl,C_LF			;reload the LF char.
	call    PrintStreamWriteByte    ;send 
	jc      exit
	mov     cx,dx                   ;recover the remaining line length.
	loop	lfLoop			;do for as many times as necessary.
	clc
exit:
	.leave
	ret
PrLineFeed      endp
