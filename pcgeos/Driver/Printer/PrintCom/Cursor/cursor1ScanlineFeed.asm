
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		cursor1ScanlineFeed.asm

AUTHOR:		Dave Durran, 14 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	9/4/92		Initial revision


DESCRIPTION:

	$Id: cursor1ScanlineFeed.asm,v 1.1 97/04/18 11:49:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                Pr1ScanlineFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
        Executes a vertical line feed of 1/(vertical res.)", and updates the
	cursor position accordingly.

CALLED BY:
        Graphics routines.

PASS:
        es      =       segment of PState

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

Pr1ScanlineFeed      proc    near
	uses    si
	.enter
	inc     es:PS_cursorPos.P_y	;add one to the Y cursor pos.
	mov	si,offset pr_codes_Do1ScanlineFeed
	call	SendCodeOut
	.leave
	ret
Pr1ScanlineFeed      endp
