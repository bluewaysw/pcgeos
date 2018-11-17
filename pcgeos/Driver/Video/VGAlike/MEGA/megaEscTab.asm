
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		MEGA screen driver
FILE:		megaEscTab.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	4/88	initial version


DESCRIPTION:
	This file contains a table of escape routines provided by the driver.
		
	$Id: megaEscTab.asm,v 1.1 97/04/18 11:42:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

DefEscapeTable	1

    DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC	; query esc capability
