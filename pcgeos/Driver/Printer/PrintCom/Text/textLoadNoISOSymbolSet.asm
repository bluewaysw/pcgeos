COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		textLoadNoISOSymbolSet.asm

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

	$Id: textLoadNoISOSymbolSet.asm,v 1.1 97/04/18 11:50:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintLoadSymbolSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dummy routine for no ISO subs, just load code page.
		(that is, no software control for ISO subs. ISO subs
		may still be set through UI and DIP switches as in
		the C.Itoh 9-pin driver, and the SpoolUpdateTranslationTable
		routine will still use them)

CALLED BY: 	INTERNAL SetFont, StartJob

PASS: 		es	- Segment of PSTATE
		al	- Country Code enum

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
	push	dx
        mov     dx, handle DriverInfo
        call    SpoolUpdateTranslationTable     ;fix up PState table
	clc
	pop	dx
	ret
PrintLoadSymbolSet	endp
