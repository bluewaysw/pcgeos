COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2021 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		TrueType Font Driver
FILE:		truetypeEscape.asm

AUTHOR:		Falk Rehwagen, Jan 24, 2021

ROUTINES:
	Name			Description
	----			-----------
	TrueTypeFontEscape	handle any escape functions

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	1/24/21		Initial revision

DESCRIPTION:
	Code for handling driver escape functions

	$Id: truetypeEscape.asm,v 1.1 21/01/24 11:45:26 bluewaysw Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueTypeFontEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hand
CALLED BY:	TrueTypeStrategy()

PASS:		di - escape function
RETURN:		di - 0 if escape function not supported
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	1/24/21		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TrueTypeFontEscape	proc	far
	call	FontCallEscape			;call general handling routine
	ret
TrueTypeFontEscape	endp

;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

DefEscapeTable	1

DefEscape	FontQueryEscape, 	DRV_ESC_QUERY_ESC
