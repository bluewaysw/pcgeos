
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Driver
FILE:		stylesSRDblWidthPitch.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Parsed from oki9Styles.asm


DC_ESCRIPTION:
		
	$Id: stylesSRDblWidthPitch.asm,v 1.1 97/04/18 11:51:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetDblWidth	proc	near
	mov	si,offset cs:pr_codes_SetDblWidth
	jmp	SendCodeOut
SetDblWidth	endp

ResetDblWidth	proc	near

	; the set condensed printer code on the Oki9 is a pitch setting
	; code (ie, we switch fonts).  So we need to check the font in
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
	;cmp	ds:[PS_curFont].FE_fontID, FID_PRINTER_10CPI ; ok ?
	;je	sendTheFont
	;cmp	ds:[PS_curFont].FE_fontID, FID_PRINTER_17CPI ; this needs 10cpi
	;je	sendTheFont
	;cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_20CPI ;chk ass

sendTheFont:
	call	SendCodeOut
	ret
ResetDblWidth	endp
