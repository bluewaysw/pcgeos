
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Driver
FILE:		textSendFont1012.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Parsed from oki9Styles.asm
	Dave	8/92		Obsolesced by the print style run routines
				OBSOLETE: DO NOT USE!


DC_ESCRIPTION:
		
	$Id: textSendFont1012.asm,v 1.1 97/04/18 11:50:02 newdeal Exp $

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
		uses	si
		.enter

		mov	si, offset cs:pr_codes_Set12Pitch ; check the next one
		cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_12CPI ;
		je	sendTheFont
		mov	si, offset cs:pr_codes_Set10Pitch ; assume it's 10CPI
		cmp	es:[PS_curFont].FE_fontID, FID_PRINTER_10CPI ;
		je	sendTheFont

		; must be one of the condensed fonts.  First set the font, then
		; the condensed bit

		or	es:[PS_xtraStyleInfo], mask PMF_FORCE_CONDENSED
		or	es:[PS_asciiStyle], mask PTS_CONDENSED ; set condensed
		call	SetCondensed
		jmp	exit				; exit if comm error
sendTheFont:
		call	SendCodeOut			; set it at printer
exit:
		.leave
		ret
PrintSendFont	endp

