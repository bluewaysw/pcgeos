
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		cursorPrLineFeedRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/8/93		Initial revision


DESCRIPTION:

	$Id: cursorPrLineFeedRedwood.asm,v 1.1 97/04/18 11:49:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrLineFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
        Executes a vertical line feed of dx <printer units>, and updates
	the cursor position accordingly.

CALLED BY:
        Jump Table

PASS:
        es      =       segment of PState
        dx      =       length , in <printer units>" to line feed.

RETURN:
        carry   - set if some transmission error

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

PrLineFeed      proc    near
	uses    ax,dx,si
	.enter
	add     es:PS_cursorPos.P_y,dx	;update the new PState position.

	test	dh,80h			;see if neg movement....
	jz	doPositive		;if not, skip.

	neg	dx			;make positive.
	mov	si,offset pr_codes_DoReverseFeed
	jmp	feedCommon

doPositive:
	mov	si,offset pr_codes_DoLineFeed

feedCommon:
	call    SendCodeOut

	mov	al,dl
	call	ControlByteOut
        mov     al,dh
        call    ControlByteOut
	
	.leave
	ret
PrLineFeed      endp
