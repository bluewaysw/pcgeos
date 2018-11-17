
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Drivers
FILE:		textSendFont10121517Prop.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/21/92		Initial revision from epson24Styles.asm
	Dave	8/92		Obsolesced by the print style run routines
				OBSOLETE: DO NOT USE!


DC_ESCRIPTION:
		
	$Id: textSendFont10121517Prop.asm,v 1.1 97/04/18 11:49:58 newdeal Exp $

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

		mov	si, offset cs:pr_codes_SetProportional 
		cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_PROP_SERIF
		je	sendTheFont
		mov	si, offset cs:pr_codes_Set12Pitch ; check the next one
		cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_12CPI ; chk ass
		je	sendTheFont
		mov	si, offset cs:pr_codes_Set15Pitch ; check the next one
		cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_15CPI ; chk ass
		je	sendTheFont
		mov	si, offset cs:pr_codes_Set10Pitch ; assume it's 10CPI
		cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_10CPI ; chk ass
		je	sendTheFont

		; it must be one of the condensed ones, so set condensed mode
		; first set the appropriate font

		mov	si, offset cs:pr_codes_Set10Pitch ; assume it's 17CPI
		cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_17CPI ; chk ass
		je	setCondensedFont
		mov	si, offset cs:pr_codes_Set12Pitch ; assume it's 20CPI

setCondensedFont:
		call	SendCodeOut			; set it at printer
		jc	exit
		or	es:[PS_xtraStyleInfo], mask PMF_FORCE_CONDENSED
		or	es:[PS_asciiStyle], mask PTS_CONDENSED ; set condensed
		call	SetCondensed
		jmp	exit
sendTheFont:
		call	SendCodeOut			; set it at printer
exit:
		.leave
		ret
PrintSendFont	endp
