COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		stylesGet.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	PrintGetStyles		Get currently set style bits

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/1/90		Initial revision
	Dave	3/92		Moved in a bunch of common test routines
	Dave	5/92		Parsed from printcomText.asm


DESCRIPTION:

	$Id: stylesGet.asm,v 1.1 97/04/18 11:51:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		bp	- segment of PState

RETURN:		cx	- current style bits

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetStyles	proc far
	uses	es
	.enter

		; set up PState and get the thing

	mov	es, bp			; es -> PState
	mov	cx, es:[PS_asciiStyle]	; return styles
	clc				; no errors
		
	.leave
	ret
PrintGetStyles	endp
