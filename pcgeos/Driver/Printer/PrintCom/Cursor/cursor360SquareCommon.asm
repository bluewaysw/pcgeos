
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		cursor360SquareCommon.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/9/93		Initial revision


DESCRIPTION:

	$Id: cursor360SquareCommon.asm,v 1.1 97/04/18 11:49:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GetCursor loads processor registers with the cursor 
		location in points from the top left corner of the page.

CALLED BY: 	GLOBAL

PASS: 		bp	- Segment of PSTATE

RETURN: 	WWFixed:
		cx.bx	=	X position in 1/72" from the left edge of
				printable area.
		dx.ax	=	Y position in 1/72" from the top edge of
				printable area.

DESTROYED: 	es	- left pointing at pstate

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetCursor	proc	far
	mov	es, bp			; get PSTATE segment
	mov	dx, es:[PS_cursorPos].P_x
	call	PrConvertFromDriverCoordinates
	mov	cx,dx
	mov	bx,ax
	mov	dx, es:[PS_cursorPos].P_y
	call	PrConvertFromDriverCoordinates
	clc				; no errors
	ret
PrintGetCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendLineFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Executes a vertical line feed of the set line spacing , and updates
	the cursor position accordingly.

CALLED BY:
	Internal

PASS:
	es	- Segment of PSTATE

RETURN:
	carry	- set if some transmission error

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

SendLineFeed	proc	near
	uses	dx
	.enter
	mov	es,bp
	mov	dx,es:[PS_asciiSpacing]	;get the line spacing from PSTATE.
	clr	ax
        call    PrConvertToDriverCoordinates
	call	PrLineFeed		;send the LF.
	.leave
	ret
SendLineFeed	endp
