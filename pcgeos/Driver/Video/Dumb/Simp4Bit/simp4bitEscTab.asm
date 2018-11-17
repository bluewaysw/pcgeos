
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		simp4bitEscTab.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	1/90	initial version


DESCRIPTION:
	This file contains the table of escape functions provided by the driver
		
	$Id: simp4bitEscTab.asm,v 1.1 97/04/18 11:43:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

DefEscapeTable	2

    DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC	; query esc capability
    DefEscape	VidUnsetDevice, VID_ESC_UNSET_DEVICE	; uninitialize driver
