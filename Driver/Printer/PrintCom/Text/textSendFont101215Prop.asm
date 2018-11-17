
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		textSendFont101215Prop.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/8/92		Initial revision from epson24Styles.asm
	Dave	8/92		Obsolesced by the print style run routines
				OBSOLETE: DO NOT USE!


DC_ESCRIPTION:
		
	$Id: textSendFont101215Prop.asm,v 1.1 97/04/18 11:49:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSendFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the right stuff to set the font in the printer

CALLED BY:	INTERNAL
		PrintSetFont

PASS:		es	- PState segment

RETURN:		carry	- set if some communications error

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
		uses	si
		.enter

		mov	si, offset cs:pr_codes_Set10Pitch ; assume it's 10CPI
		cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_10CPI ; chk ass
		je	sendTheFont
		mov	si, offset cs:pr_codes_SetProportional 
		cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_PROP_SERIF
		je	sendTheFont
		mov	si, offset cs:pr_codes_Set12Pitch ; check the next one
		cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_12CPI ; chk ass
		je	sendTheFont
		mov	si, offset cs:pr_codes_Set15Pitch ; check the next one

		;must be either 15 pitch or unsupported: set 15 pitch

sendTheFont:
		call	SendCodeOut			; set it at printer
exit:
		.leave
		ret
PrintSendFont	endp
