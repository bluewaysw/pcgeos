
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		graphicsAdjustForResolution.asm

AUTHOR:		Dave Durran January 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/1/90		Initial laserjet revision
	Dave	1/21/92		2.0 PCL 4 driver revision


DESCRIPTION:

	$Id: graphicsAdjustForResolution.asm,v 1.1 97/04/18 11:51:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrAdjustForResolution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:
	Jump Table

PASS:
	ax	- 300dpi value to adjust for the resolution.
	es	- Segment of PSTATE

RETURN:
	nothing

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrAdjustForResolution	proc	near
EC<	cmp	es:[PS_mode],PM_FIRST_TEXT_MODE				>
EC<	ERROR_AE INVALID_MODE				>
	cmp	es:[PS_mode],PM_GRAPHICS_HI_RES
	je	doneshifting
	shl	ax,1 	;shift for the number of dots in one pixel at 150dpi
	
	cmp	es:[PS_mode],PM_GRAPHICS_MED_RES
	je	doneshifting
	shl	ax,1	;shift for  the number of dots in one pixel at 75dpi

doneshifting:
	clc		;get rid of potential carrys generating bogus errors.
	ret
PrAdjustForResolution	endp
