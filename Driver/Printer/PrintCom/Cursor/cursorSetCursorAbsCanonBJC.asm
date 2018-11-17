COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		cursorSetCursorAbsCanonBJ.asm

AUTHOR:		Joon Song, 10 Jan 1999

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/10/99		Initial revision from cursorSetCursorAbs72.asm


DESCRIPTION:

	The cursor position is kept in 2 words: integer <printer units> in Y
	and integer 72nds in X

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	sets the new cursor position in the PSTATE.

	The printhead can be moved in either direction in X, but only down the
	page (increasing Y).

CALLED BY:
	EXTERNAL

PASS:
	bp	- Segment of PSTATE
	cx.si	- WWFixed new X position in points
	dx.ax	- WWFixed new Y position in points

RETURN:
	carry	- set if some communications problem

DESTROYED:

PSEUDO CODE/STRATEGY:
	1 if desired position is below the current one, do y positioning
	2 ignore X positioning

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	01/99		Initial version from cursorSetCursorAbs72.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintSetCursor	proc	far
	uses	si,es
	.enter

	mov	es, bp				;get PSTATE segment.
	mov	es:[PS_cursorPos].P_x, cx	;save the new X Position.
	tst	cx
	jnz	serviceY		

	mov	cl, C_CR			;send a carriage return.
	call	PrintStreamWriteByte

serviceY:
		;Service the Y position.
	call	PrConvertToDriverCoordinates
	sub	dx,es:[PS_cursorPos].P_y ;see if the position desired is below
	clc				; make sure carry is clear for exiting
					; when there are no errors.  "jle" does
					; not look at the carry bit
	jle	exit			;dont update position if neg or zero.
	call	PrLineFeed		;adjust the position in PSTATE and
					;the printhead position.
exit:
	.leave
	ret
PrintSetCursor	endp
