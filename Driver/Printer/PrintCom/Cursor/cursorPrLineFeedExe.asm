
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		cursorPrLineFeedExe.asm

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

	$Id: cursorPrLineFeedExe.asm,v 1.1 97/04/18 11:49:40 newdeal Exp $

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
	uses    ax,cx,si
	.enter
	add     es:PS_cursorPos.P_y,dx

hiloop:
	mov     cx,dx
	sub     cx,PR_MAX_LINE_FEED     ;see if there is room to do a max feed.
	jle     writeoutlowdigit        ;if not, send just the low digits.

	mov     dx,cx                   ;save new length after max feed.
	mov     si,offset pr_codes_DoMaxLineFeed
	call    SendCodeOut             ;send PR_MAX_FEED 1/216" feed
	jc      exit
	jmp     hiloop                  ;do [hi digit] times.

writeoutlowdigit:
	mov     si,offset pr_codes_DoLineFeed
	call    SendCodeOut             ;send following 1/216" feed
	jc      exit
	mov     cx,dx                   ;recover the remaining line length.
		;guaranteed less than 256.....
	jcxz    exit
	call    PrintStreamWriteByte
exit:
	.leave
	ret
PrLineFeed      endp
