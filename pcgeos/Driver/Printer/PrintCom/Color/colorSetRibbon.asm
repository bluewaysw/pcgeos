
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		color Print Drivers
FILE:		colorSetRibbon.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Initial revision
	Dave	5/92		Parsed from printcomEpsonColor.asm


DESCRIPTION:
		
	$Id: colorSetRibbon.asm,v 1.1 97/04/18 11:51:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSetRibbonColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Directly set the color for the CMYK ribbon

CALLED BY:	PrintSetColor

PASS:		bp	- PState segment
		cl	- number of color to set

RETURN:		carry	- set if some communications error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrSetRibbonColor	proc	near
	uses	si, es
	.enter
	mov	es,bp			;es --> PState
	mov	si, offset pr_codes_SetColor
	call	SendCodeOut		;send the control code to set color.
	jc	exit
	call	PrintStreamWriteByte	;cl has color.
exit:
	.leave
	ret
PrSetRibbonColor	endp
