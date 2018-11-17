COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		cursorPrLineFeedCanonBJ.asm

AUTHOR:		Joon Song, 10 Jan 1999

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/10/99		Initial revision from cursorPrLineFeed.asm


DESCRIPTION:

	$Id$

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
        dx      =       length, in <printer units>" to line feed.

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
	Joon	01/99           Initial version from cursorPrLineFeed.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrLineFeed      proc    near
	uses    ax,cx,si
	.enter

	add     es:[PS_cursorPos].P_y,dx

	mov     si,offset pr_codes_DoLineFeed
	call    SendCodeOut             ;send following 1/360" feed
	jc      exit

	mov	cl, dh			;write high byte of count
	call	PrintStreamWriteByte
	jc	exit	
	mov	cl, dl			;write low byte of count
	call	PrintStreamWriteByte
exit:
	.leave
	ret
PrLineFeed      endp
