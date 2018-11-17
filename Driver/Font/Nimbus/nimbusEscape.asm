COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		nimbusEscape.asm
FILE:		nimbusEscape.asm

AUTHOR:		Gene Anderson, Jan 21, 1992

ROUTINES:
	Name			Description
	----			-----------
	NimbusFontEscape	handle any escape functions

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/21/92		Initial revision

DESCRIPTION:
	Code for handling driver escape functions

	$Id: nimbusEscape.asm,v 1.1 97/04/18 11:45:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusFontEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hand
CALLED BY:	NimbusStrategy()

PASS:		di - escape function
RETURN:		di - 0 if escape function not supported
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusFontEscape	proc	far
	call	FontCallEscape			;call general handling routine
	ret
NimbusFontEscape	endp

;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

DefEscapeTable	1

DefEscape	FontQueryEscape, 	DRV_ESC_QUERY_ESC
