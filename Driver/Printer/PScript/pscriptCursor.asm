
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript print driver
FILE:		pscriptCursor.asm

AUTHOR:		Jim DeFrisco, 15 May 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/14/90		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the PostScript
	print driver cursor movement support

	$Id: pscriptCursor.asm,v 1.1 97/04/18 11:56:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	sets the new cursor position in the PSTATE 

CALLED BY:
	EXTERNAL

PASS:
	bp	- Segment of PSTATE
	cx	- new X position
	dx	- new Y position

RETURN:
	nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetCursor	proc	far
	uses	ds
	.enter
	mov	ds,bp		;get PSTATE segment.
	mov	ds:[PS_cursorPos].P_x, cx 	; save the new X Position.
	mov	ds:[PS_cursorPos].P_y, dx 	; save the new Y Position.
	.leave
	ret
PrintSetCursor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GetCursor loads processor registers with the cursor 
		location in points from the top left corner of the page.

CALLED BY: 	GLOBAL

PASS: 		bp	- Segment of PSTATE

RETURN: 	cx	=	X position in 1/72" from the left edge of page.
		dx	=	Y position in 1/72" from the top edge of page.

DESTROYED: 	ds	- left pointing at pstate

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetCursor	proc	near
		mov	ds, bp			; get PSTATE segment
		mov	cx, ds:[PS_cursorPos].P_x
		mov	dx, ds:[PS_cursorPos].P_y
		clc				; no errors
		ret
PrintGetCursor	endp

