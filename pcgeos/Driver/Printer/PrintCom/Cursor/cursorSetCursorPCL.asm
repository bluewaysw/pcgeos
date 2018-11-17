
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet print driver
FILE:		cursorSetCursorPCL.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision from laserplsCursor.asm


DESCRIPTION:

	$Id: cursorSetCursorPCL.asm,v 1.1 97/04/18 11:49:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	sets the new cursor position in the PSTATE and moves the cursor
	to the new position.
	the cursor position is kept in 1/300" units.

CALLED BY:
	EXTERNAL

PASS:
	bp	- Segment of PSTATE
	WWFixed:
	cx.si	- new X position
	dx.ax	- new Y position

RETURN:
	nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version
	Dave	03/92		changed to work on 1/300" units.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetCursor	proc	far
	uses	ax,si,ds,es
	.enter
	mov	es,bp		;get PSTATE segment.

		;convert the WWFixed into 1/300 units.
	call	PrConvertToDriverCoordinates	;get into dot units.
	mov	es:[PS_cursorPos].P_y,dx ;save the new Y Position.
	mov	dx,cx		;now ge the x pos into 
	mov	ax,si
	call	PrConvertToDriverCoordinates	;dot units.
	mov	es:[PS_cursorPos].P_x,dx ;save the new X Position.
	call	PrMoveCursor

	.leave
	ret
PrintSetCursor	endp

		;common moving routine.
PrMoveCursor	proc	near
	;trashes ax,cx,si
	uses	dx
	.enter
		;reset the styles so that underlining does not cross tabs.
	mov	dx,es:PS_asciiStyle	;get current style word.
	call	PrintClearStyles
	jc	exit		;pass errors out

		;Service the X position.
	mov	si, offset pr_codes_CursorPosition
	call	SendCodeOut
	jc	exit
	mov	ax,es:[PS_cursorPos].P_x
	call	HexToAsciiStreamWrite
	jc	exit			;pass errors out.
	mov	cl,"x"			;send the horizintal position.
	call	PrintStreamWriteByte
	jc	exit			;pass errors out.

		;Service the Y position.
	mov	ax,es:[PS_cursorPos].P_y
	call	HexToAsciiStreamWrite
	jc	exit			;pass errors out.
	mov	cl,"Y"			;send the horizintal position.
	call	PrintStreamWriteByte
	jc	exit			;pass errors out.
	call	PrintSetStyles		;reset the style word in dx.

exit:
	.leave
	ret
PrMoveCursor	endp
