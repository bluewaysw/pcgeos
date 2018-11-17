
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet print driver
FILE:		cursorPCLCommon.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintGetCursor
	SendLineFeed

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision from laserplsCursor.asm


DESCRIPTION:
	This file contains most of the code to implement the Common PCL 
	print driver cursor movement support

	$Id: cursorPCLCommon.asm,v 1.1 97/04/18 11:49:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GetCursor loads processor registers with the cursor 
		location in points from the top left corner of the page.

CALLED BY: 	GLOBAL

PASS: 		bp	- Segment of PSTATE

RETURN: 	WWFixed:
		cx.bx	=	X position in 1/72" from the left edge of page.
		dx.ax	=	Y position in 1/72" from the top edge of page.

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
	mov	es,bp			; get PSTATE segment
	mov	dx,es:[PS_cursorPos].P_x
	call	PrConvertFromDriverCoordinates
	mov	cx,dx
	mov	bx,ax
	mov	dx,es:[PS_cursorPos].P_y
	call	PrConvertFromDriverCoordinates
	ret
PrintGetCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendLineFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
SendLineFeed sends a linefeed of to the printer based on the currently set
line spacing in PSTATE.

CALLED BY:
	PrPrintASCII

PASS:
	es	- Segment of PSTATE

RETURN:
	nothing

DESTROYED:
	ax,cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendLineFeed	proc	near
	push	dx,cx,ax
	mov	cx,es:PS_asciiSpacing	;get current line spacing from PSTATE.
	add	cx,es:PS_cursorPos.P_y	;add to the cursor position.
	mov	dx,es:[PS_cursorPos].P_x ;get current x position, unchanged.
	call	PrMoveCursor		;move the cursor down.
	pop	dx,cx,ax
	ret
SendLineFeed	endp
