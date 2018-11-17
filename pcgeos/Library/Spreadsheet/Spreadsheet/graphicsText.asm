COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		graphics.asm

AUTHOR:		Gene Anderson, May 27, 1991

ROUTINES:
	Name				Description
	----				-----------
	GrJustifyText			Draw text justified in space defined
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/27/91		Initial revision

DESCRIPTION:
	

	$Id: graphicsText.asm,v 1.1 97/04/07 11:13:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrJustifyText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw text justified in space defined.
CALLED BY:	GLOBAL

PASS:		ds:si - ptr to string
		cx - # of characters to draw (0 for NULL-terminated)
		dl - Justification
		di - handle of GState
		ss:bx - ptr to JustifyTextParams
			JTP_leftX
			JTP_rightX
			JTP_yPos
RETURN:		none
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: Doesn't work for full justification -- feel free to change it :-)
	NOTE: Normal text attributes affect the output (eg. track kerning,
	draw from position, font, pointsize, etc.) as expected.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrJustifyText	proc	far
	uses	ax, dx
	.enter

	push	cx				;save length of string
	cmp	dl, J_LEFT			;left justified?
	je	leftJustify			;branch if left justified

	mov	al, dl				;al <- Justification value
	mov	dx, ss:[bx].JTP_width		;dx <- width
	tst	dx				;width known?
	jnz	gotWidth			;branch if width known
	call	GrTextWidth			;dx <- width of text
gotWidth:
	cmp	al, J_CENTER			;centered?
	je	centerJustify			;branch if centered
EC <	cmp	al, J_FULL			;>
EC <	ERROR_E		GRAPHICS_ILLEGAL_JUSTIFICATION ;>
EC <	cmp	al, J_RIGHT			;>
EC <	ERROR_NE	GRAPHICS_ILLEGAL_JUSTIFICATION ;>

	;
	; The text is right justified.  Subtract the width of the string
	; from the right side to get the start position.
	;
	mov	ax, ss:[bx].JTP_rightX		;ax <- right of text
	sub	ax, dx				;ax <- right - width
	jmp	drawText

	;
	; The text is center justified.  Subtract the width of the string
	; from the available width, divide in half, and add to the left
	; side to get the start position.
	;
centerJustify:
	mov	ax, ss:[bx].JTP_rightX
	sub	ax, ss:[bx].JTP_leftX		;ax <- available width
	sub	ax, dx				;ax <- available - width
	sar	ax, 1				;ax <- space/2
	add	ax, ss:[bx].JTP_leftX
	jmp	drawText

	;
	; The text is left justified.  Just use the left side as the
	; start position.
	;
leftJustify:
	mov	ax, ss:[bx].JTP_leftX		;ax <- left edge
drawText:
	pop	cx				;cx <- length of string
	mov	bx, ss:[bx].JTP_yPos
	;
	; ax - x coordinate (WBFixed, document coords)
	; bx - y coordinate (WBFixed, document coords)
	; cx - # of chars to draw
	; ds:si - ptr to string to draw
	;
	call	GrDrawText			;draw me jesus

	.leave
	ret
GrJustifyText	endp

DrawCode	ends
