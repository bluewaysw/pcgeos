
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Mono module of vidmem video driver
FILE:		monoEscTab.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	1/90	initial version


DESCRIPTION:
	This file contains the table of escape functions provided by the driver
		
	$Id: monoEscTab.asm,v 1.1 97/04/18 11:42:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

DefEscapeTable	2

    DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC	; query esc capability
    DefEscape	VidSetColorTransfer, VID_ESC_SET_COLOR_TRANSFER
