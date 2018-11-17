
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		cursorSetCursorAbsRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/9/93		Initial revision


DESCRIPTION:

	The cursor position is kept in 2 words: integer 360ths in Y
	and integer 360ths in X

	$Id: cursorSetCursorAbsRedwood.asm,v 1.1 97/04/18 11:49:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	sets the new cursor position in the PSTATE and moves the printhead
	to the new position.

	The resolution for positioning the printhead is based on the current
	character pitch, as the routine uses tabs to position the printhead
	in the X direction.

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
	2 do X positioning

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetCursor	proc	far
	uses	si,es
	.enter
	mov	es,bp			;get PSTATE segment.

	call	PrintMoveInYOnly
	call	PrintMoveInXOnly

exit:
	.leave
	ret

PrintSetCursor	endp
