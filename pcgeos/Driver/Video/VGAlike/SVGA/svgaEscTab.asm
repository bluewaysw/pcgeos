
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		SVGA Video Driver
FILE:		svgaEscTab.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	9/90	initial version


DESCRIPTION:
	This file contains the table of escape functions provided by the driver
		
	$Id: svgaEscTab.asm,v 1.1 97/04/18 11:42:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

DefEscapeTable	1

    DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC	; query esc capability
