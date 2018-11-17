
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		color Print Drivers
FILE:		colorGetFormat.asm

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
		
	$Id: colorGetFormat.asm,v 1.1 97/04/18 11:51:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGetColorFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Directly set the color for the CMYK ribbon

CALLED BY:	GLOBAL

PASS:		bp	- PState segment

RETURN:		al	= BMFormat enum representative of this printer's
				capabilities.
		carry	- cleared

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGetColorFormat	proc	near
	uses	bx, ds, es
	.enter
	mov	es,bp			;es --> PState
	mov	bx,es:[PS_deviceInfo]	;handle of device specific info.
	call	MemLock
	mov	ds,ax			;segment of device specific info.
	mov	al,ds:[PI_type]		;get the format for any color printing.
	and	al, mask PT_COLOR	;isolate the color format bits.
	call	MemUnlock
	clc
	.leave
	ret
PrintGetColorFormat	endp
