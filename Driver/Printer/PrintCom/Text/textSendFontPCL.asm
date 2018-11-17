
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Driver
FILE:		textSendFontPCL.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/22/92		Initial revision from laserjetStyles.asm
	Dave	9/2/92		OBSOLESCED by new ASCII style run printing
				DO NOT USE!


DC_ESCRIPTION:
		
	$Id: textSendFontPCL.asm,v 1.1 97/04/18 11:49:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSendFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the right stuff to set the font in the printer

CALLED BY:	INTERNAL
		PrintSetFont

PASS:		es	- PState segment

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSendFont	proc	near
	uses	ax,dx,si,di
	.enter

	mov	si, offset cs:pr_codes_SetProportional 
	cmp	es:[PS_curFont].FE_pitch, 0	;text for proportional.
	jne	sendFontPitch
	call	SendCodeOut		; set it at printer
	jmp	exit			;pass out.

sendFontPitch:
	clr	ah
	mov	al,es:[PS_curFont].FE_pitch	;pitch x 10
	clr	dx
	mov	si,10
	div	si
	mov	di, offset cs:pr_codes_SetPitch ; code to set the pitch value.
	call	WriteNumCommand
exit:
	.leave
	ret
PrintSendFont	endp
