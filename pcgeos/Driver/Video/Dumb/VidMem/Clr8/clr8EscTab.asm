
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		clr8EscTab.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	12/91	initial version


DESCRIPTION:
	This file contains the table of escape functions provided by the driver
		
	$Id: clr8EscTab.asm,v 1.1 97/04/18 11:42:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

DefEscapeTable	1

    DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC	; query esc capability
