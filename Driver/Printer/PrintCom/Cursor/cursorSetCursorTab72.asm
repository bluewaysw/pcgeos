
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		print drivers
FILE:		cursorSetCursorTab72.asm

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

	$Id: cursorSetCursorTab72.asm,v 1.1 97/04/18 11:49:46 newdeal Exp $

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
	Dave	03/92		changed to do Y first, and generalize pitch
				support.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SET_CURSOR_MODIFIES_FONT	=	1

PrintSetCursor	proc	far
	uses	si,es
	.enter
	mov	es,bp			;get PSTATE segment.

	call	PrintClearStyles
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
	mov	es:[PS_cursorPos].P_x,0ffffh ;cram a large value....
	call	PrLineFeed		;adjust the position in PSTATE and
					;the printhead position.

		;Service the X position.
serviceXPosition:
		;recover the X position words.
	pop	cx			;pop fraction into cx
	pop	dx			;and integer into dx
					;now in the correct reg for WWFixed.
	jc	exit			;pass errors from PrLineFeed out.

		;before doing any X movement, make sure the position is to the
		;right of the last set cursor position.
	cmp	es:[PS_cursorPos].P_x,dx ;save the new X Position.
	je	exit			;do nothing before exiting.
	jb	storeNewXPosition
	push	cx
	mov	cl,C_CR			;send a carriage return.
	call	PrintStreamWriteByte
	pop	cx
	jc	exit

storeNewXPosition:	
	mov	es:[PS_cursorPos].P_x,dx ;save the new X Position.

		;we'll use 10pitch to get as much standardization
		;as possible from most printers.
		;dx.cx must be the new X position.

	mov	ax,9102			;x .1388888 for 10 pitch.
	clr	bx
	call	GrMulWWFixed		;dx.cx = # of chars to tab.
	shl	cx,1			;do any necessary rounding.
	adc	dx,0			;dl is assumed to have the correct
					;tab character position at this point.
	push	dx			;get the character position.
	mov	bl,TP_10_PITCH
	mov	cx,FID_DTC_URW_ROMAN
	mov	dx,12
	call	PrintSetFont
	pop	cx			;get the character position.
	jc	exit
	jcxz	exit			;if no cursor movement from left, dont.
	mov	si, offset pr_codes_SetTab
	call	SendCodeOut
	jc	exit
	call	PrintStreamWriteByte
	jc	exit
	mov	si, offset pr_codes_DoTab	;finish tab table, and execute
	call	SendCodeOut			;the tab.
exit:
	.leave
	ret
PrintSetCursor	endp
