COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		cmykColor.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
    GBL	VidSetPalEntry	Set a new palette entry
	
REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/91	initial version


DESCRIPTION:

	$Id: cmykColor.asm,v 1.1 97/04/18 11:43:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetColorTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color transfer function

CALLED BY:	GLOBAL
PASS:		ax	- handle of block containing transfer table
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidSetColorTransfer	proc	near
		uses	ds
		.enter
		
		mov	ds, ss:[bm_segment]	; get EditableBitmap segment
		mov	ds:[EB_color], ax

		.leave
		ret
VidSetColorTransfer	endp
