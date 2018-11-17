COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Sim2Bit Video Driver
FILE:		simp2bitEscape.asm

AUTHOR:		Jim Guggemos, Mar 10, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	3/10/97   	Initial revision


DESCRIPTION:
	Escape functions specifically for simp2bit

	$Id: simp2bitEscape.asm,v 1.1 97/04/18 11:43:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Simp2BitSetContrast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the contrast.  Currently only supported for Penelope.

CALLED BY:	GLOBAL

PASS:		ah	= ContrastChangeType
		al	= change level

RETURN:		if carry clear:
		    al	= actual contrast set
		
		if carry set:
		    not supported

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	3/10/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Simp2BitSetContrast	proc	near

	stc					; NOT SUPPORTED
	ret

Simp2BitSetContrast	endp
