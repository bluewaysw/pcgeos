COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3EndPage.asm

AUTHOR:		Jacob Gabrielson, Apr 16, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/16/93   	Initial revision
	AC	9/ 8/93		Changed for Group3


DESCRIPTION:
	
		

	$Id: group3EndPage.asm,v 1.1 97/04/18 11:52:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does end-page routine for the printer driver.

CALLED BY:	
PASS:           bp      - PSTATE segment address.
                cl      - Suppress form feed flag, C_FF is FF non-suppressed

RETURN:         carry   -set if some communications error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintEndPage	proc	far

	;
	; Exit cleanly
	;
		clc				; "signify happiness"
		ret
PrintEndPage	endp










