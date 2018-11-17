COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Dumb frame buffer video drivers
FILE:		dumbcomColor.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
    GLB VidMapRGB		Map passed RGB value to closest available
    GLB VidGetPalette		Get the current palette
    GLB VidSetPalette		Set the current palette

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/89	initial version


DESCRIPTION:
	This is the source for the bitmap screen drivers color escape routines.
	They are dummy routines for the most part, and are here to make life
	easier for the kernel.
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/usr/pcgeos/Spec/video.doc).  
	The spec for the color stuff is in pcgeos/Spec/color.doc

	$Id: dumbcomColor.asm,v 1.1 97/04/18 11:42:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDevicePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the actual device palette

CALLED BY:	INTERNAL
		VidSetPalette
PASS:		palCurRGBValues buffer up to date
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDevicePalette	proc	near
		.enter
		.leave
		ret
SetDevicePalette	endp
