
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		color Print Drivers
FILE:		colorSet.asm

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
		
	$Id: colorSet.asm,v 1.1 97/04/18 11:51:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Directly set the color for the CMYK ribbon

CALLED BY:	GLOBAL

PASS:		bp	- PState segment
		al	- R component to match
		dl	- G component to match
		dh	- B component to match

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

PrintSetColor	proc	near
	uses	bx,cx,es
	.enter
	mov	es,bp			;es --> PState
	mov	bl,es:PS_printerType	;see if we can do color.
	and	bl,mask PT_COLOR	;isolate the color bits.
	cmp	bl,BMF_MONO		;see if monochrome...
	clc
	je	exit			;if so, no color change....
	mov	bx,dx			;get stuff in the right regs.
	call	PrMapRGBtoCMYKIndex	;get the index for the color.
	call	PrSetRibbonColor	;set the ribbon color for this string.
exit:
	.leave
	ret
PrintSetColor	endp
