COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		textLoadEpsonSymbolSet.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintLoadSymbolSet	Load up the symbol set to use in the printer

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/92		Initial Version


DESCRIPTION:

	$Id: textLoadEpsonSymbolSet.asm,v 1.1 97/04/18 11:50:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintLoadSymbolSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the printers Symbol set up and match it with the 
		PState ASCII Translation Table.

CALLED BY: 	INTERNAL SetFont, StartJob

PASS: 		es	- Segment of PSTATE

RETURN: 	carry	- set if some error sending string to printer

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintLoadSymbolSet	proc	near
	uses	ax,cx,dx,si
	.enter
	mov	dx, handle DriverInfo
	call	SpoolUpdateTranslationTable	;fix up PState table
	mov	si,offset pr_codes_SetCountry
	call	SendCodeOut
	jc	exit			;pass errors out....
        mov     cl,es:[PS_jobParams].[JP_printerData].[PUID_countryCode]
	inc	cl		;make it the argument for the control code.
	cmp	cl,(PCC_LEGAL + 1)
	jne	sendIt
	mov	cl,64		;special case legal.
sendIt:
	call	PrintStreamWriteByte

exit:
	.leave
	ret
PrintLoadSymbolSet	endp
