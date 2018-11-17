
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson print drivers
FILE:		graphicsIBMX24Common.asm

AUTHOR:		Dave Durran 23 March 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/23/92		Initial revision


DESCRIPTION:
	This file consists of the common graphics routines for all the IBM X24
	type print drivers.

	$Id: graphicsIBMX24Common.asm,v 1.1 97/04/18 11:51:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendGraphicControlCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send the actiual graphics control code, and byte count.

CALLED BY:	INTERNAL

PASS:		si	- pointer to control code in Code Seg.
		cx	- column width to print.
		es	- segment of PSTATE

RETURN:		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrSendGraphicControlCode	proc	near
	uses	ax,cx
	.enter
	mov	al,cs:[si]		;get mode byte
					;test for a 24 pin mode.
	cmp	al,8			;see if 8 pin mode.
	jb	haveByteCount		;must be a mode less than 8 to jmp
	push	bx
	mov	bx,cx
	shl	cx,1			;need columns x3
	add	cx,bx
	pop	bx
	cmp	al,13			;see if 24 pin mode.
	jb	haveByteCount		;must be a mode less than 13 to jmp
	shl	cx,1			;must be a 48 pin mode (need col x 6).
haveByteCount:
	inc	cx			;need bytes+1
	mov	si,offset pr_codes_SetGraphics
	call	SendCodeOut		;send control code pointed at cs:si.
	jc	exit
	call	PrintStreamWriteByte	;send low byte.
	jc	exit
	mov	cl,ch			;send high byte
	call	PrintStreamWriteByte
	jc	exit
	mov	cl,al			;send mode byte
	call	PrintStreamWriteByte
exit:
	.leave
	ret
PrSendGraphicControlCode	endp
