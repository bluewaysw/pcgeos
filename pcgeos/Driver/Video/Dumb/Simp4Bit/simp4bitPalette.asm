COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Simp4Bit video driver
FILE:		simp4bitPalette.asm

AUTHOR:		Andrew Wilson, Mar 23, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/23/95		Initial revision

DESCRIPTION:
	Palette stuff

	$Id: simp4bitPalette.asm,v 1.1 97/04/18 11:43:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDevicePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the hardware palette

CALLED BY:	VidSetPalette
PASS:		currentPalette setup
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/23/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDevicePalette	proc	far
	.enter
	.leave
	ret
SetDevicePalette	endp
