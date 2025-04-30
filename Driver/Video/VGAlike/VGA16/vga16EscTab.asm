COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		VGA16 Video Driver
FILE:		vga8EscTab.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	9/90	initial version


DESCRIPTION:
	This file contains the table of escape functions provided by the driver
		
	$Id: vga16EscTab.asm,v 1.2$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;----------------------------------------------------------------------------
;		Escape Function Table
;----------------------------------------------------------------------------

DefEscapeTable	2

    DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC
    				; query esc capability
    DefEscape	VidEscSetDeviceAgain,	VID_ESC_UPDATE_DEVICE
				; update device for changed display sizee
