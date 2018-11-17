
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		cmykEscTab.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	12/91	initial version


DESCRIPTION:
	This file contains the table of escape functions provided by the driver
		
	$Id: cmykEscTab.asm,v 1.1 97/04/18 11:43:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

DefEscapeTable	2

    DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC	; query esc capability
    DefEscape	VidSetColorTransfer, VID_ESC_SET_COLOR_TRANSFER
