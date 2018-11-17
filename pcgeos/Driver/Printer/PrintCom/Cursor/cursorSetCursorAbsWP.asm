
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dedicated WP print drivers
FILE:		cursorSetCursorAbsWP.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/94		Initial revision


DESCRIPTION:


	$Id: cursorSetCursorAbsWP.asm,v 1.1 97/04/18 11:49:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	sets the new cursor position in the PSTATE and moves the printhead
	to the new position.


CALLED BY:
	EXTERNAL

PASS:
	bp	- Segment of PSTATE
	cx.bx	- WWFixed new X position in points
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
	Dave	10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetCursor	proc	far
	uses	es
	.enter

	mov	es,bp			;get PSTATE segment.
	call	PrintMoveInYOnly
	call	PrintMoveInXOnly

	.leave
	ret
PrintSetCursor	endp
