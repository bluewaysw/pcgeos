
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Driver
FILE:		stylesSRNLQPitch.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/21/90		Initial revision


DESCRIPTION:
		
	$Id: stylesSRNLQPitch.asm,v 1.1 97/04/18 11:51:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetNLQ		proc	near
	mov	si,offset cs:pr_codes_SetNLQ
	jmp	SendCodeOut
SetNLQ		endp

ResetNLQ	proc	near
	mov	si,offset cs:pr_codes_ResetNLQ
	call	SendCodeOut
	jc	exit

	; the ResetNLQ code also set the font to 10CPI.  If the pstate 
	; has any other font in it, we should set it back to the font
	; we really want.

	cmp	ds:[PS_curFont].FE_fontID, FID_PRINTER_10CPI ; ok ?
	je	exitOK
	cmp	ds:[PS_curFont].FE_fontID, FID_PRINTER_17CPI ; this needs 10cpi
	je	exitOK

	; OK, we need to set the printer back to what it was.  It must be
	; either the serif font or the 12CPI font

	mov	si, offset cs:pr_codes_SetProportional 
	cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_PROP_SERIF
	je	sendTheFont
	mov	si, offset cs:pr_codes_Set12Pitch ; check the next one
	cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_12CPI ;chk ass
	je	sendTheFont
	cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_20CPI ;chk ass
	jne	exitOK				; if not, we don't know what..
						;   it is
sendTheFont:
	call	SendCodeOut
exit:
	ret

	; exit, but no error was found
exitOK:
	clc
	jmp	exit
ResetNLQ	endp
