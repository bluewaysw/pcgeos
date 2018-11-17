COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		textPrintRaw.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintRaw		Send raw bytes to the printer

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial revision
	Dave	3/92		Moved in a bunch of common test routines
	Dave	5/92		Parsed up printcomText.asm


DESCRIPTION:

	$Id: textPrintRaw.asm,v 1.1 97/04/18 11:50:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PrintRaw sends a buffer of bytes to the printer

CALLED BY: 	GLOBAL

PASS: 		bp	- Segment of PSTATE
		dx:si	- buffer to send
		cx	- byte count

RETURN: 	carry	- set if some error 

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintRaw	proc	far
	uses	es,ds
	.enter

		; just send the buffer on

	mov	es,bp			; get PSTATE seg.
	mov	ds, dx			; ds -> buffer
	call	PrintStreamWrite

	.leave
	ret
PrintRaw	endp
