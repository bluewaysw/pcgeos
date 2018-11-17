
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		stylesSRCondensedPitch.asm

AUTHOR:		Dave Durran, 1 March 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial revision


DC_ESCRIPTION:
		
	$Id: stylesSRCondensedPitch.asm,v 1.1 97/04/18 11:51:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetCondensed	proc	near
	mov	si,offset cs:pr_codes_SetCondensed
	call	SendCodeOut
	ret
SetCondensed	endp

ResetCondensed	proc	near
	mov	si,offset cs:pr_codes_ResetCondensed
	call	SendCodeOut
	jc	exit		;pass any error out.

	; the set condensed printer code on the Epson 9 pin printers
	; is not a pitch setting code, but some IBM Proprinter clones
	; seem to want to exit condensed into 10-pitch, and ignore the
	; current font pitch setting.  So we need to check the font in
	; the pstate and set the font back to what it was before we set
	; condensed mode.

	; OK, we need to set the printer back to what it was.  We will test
	; either the serif font or the 12CPI font

	mov	si, offset cs:pr_codes_SetProportional 
	cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_PROP_SERIF
	je	sendTheFont
	mov	si, offset cs:pr_codes_Set12Pitch ; check the next one
	cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_12CPI ;chk ass
	je	sendTheFont

	; If here, then it must be either 10pitch, 17pitch, or some unsupported
	; pitch which we will set to 10-pitch anyway.

	mov	si, offset cs:pr_codes_Set10Pitch ; check the next one

sendTheFont:
	call	SendCodeOut
exit:
	ret

ResetCondensed	endp

