
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		cursorSetCursorAbs72.asm

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

	The cursor position is kept in 2 words: integer <printer units> in Y
	and integer 72nds in X

	$Id: cursorSetCursorAbs72.asm,v 1.1 97/04/18 11:49:42 newdeal Exp $

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
	Dave	03/90		Initial version
	Dave	03/92		changed to do Y first, and generalize X
				position multiplier.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetCursor	proc	far
	uses	si,es
	.enter
	mov	es,bp			;get PSTATE segment.
	call	PrintClearStyles	;nuke any nasty styles hanging around.
	jc	exit

		;save the X position words.
	push	cx			;integer
	push	si			;fraction

		;Service the Y position.
	call	PrConvertToDriverCoordinates
	sub	dx,es:[PS_cursorPos].P_y ;see if the position desired is below
	clc				; make sure carry is clear for exiting
					; when there are no errors.  "jle" does
					; not look at the carry bit
	jle	serviceXPosition	;dont update position if neg or zero.
	call	PrLineFeed		;adjust the position in PSTATE and
					;the printhead position.

serviceXPosition:
		;recover the X position words.
	pop	cx			;pop fraction into cx
	pop	dx			;and integer into dx
					;now in the correct reg for WWFixed.
	jc	exit			;pass errors from PrLineFeed out.

		;Service the X position.
		;Use the font pitch to calculate the position  to tab to.
		;(treat proportional like 12-pitch)
	mov	es:[PS_cursorPos].P_x,dx ;save the new X Position.
	mov	ax,PR_X_CURSOR_FRAC	;get the multiple to convert units
	mov	bx,PR_X_CURSOR_INT
	call	GrMulWWFixed		;get #  of units to go right.
	shl	cx,1			;do any necessary rounding.
	adc	dx,0
					;dx is assumed to have the correct
					;absolute position at this point.
	mov	si, offset pr_codes_AbsPos
	call	SendCodeOut
	mov	cx,dx			;get the absolute position.
	jc	exit
	call	PrintStreamWriteByte
	jc	exit
	mov	cl,ch			;send hi byte.
	call	PrintStreamWriteByte
exit:
	.leave
	ret

PrintSetCursor	endp
