
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VGA8 Video Driver
FILE:		vga8StringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision


DESCRIPTION:
	This file holds the device string tables
		

	$Id: vga8StringTab.asm,v 1.3 97/05/01 15:29:29 lshields Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_VESA_640x480_15              enum    VideoDevice, 0
VD_VESA_800x600_15              enum    VideoDevice
VD_VESA_1Kx768_15               enum    VideoDevice
VD_VESA_1280x1K_15              enum    VideoDevice

        ; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
			VideoDevice/2,                  ; DEIT_numDevices
                        offset VGA16StringTable,        ; DEIT_nameTable
			0                               ; DEIT_infoTable
			>


	; this is the table of near pointers to the device strings
VGA16StringTable lptr.char \
                        VGAString,                      ; VD_VESA_640x480_15
                        SVGAString,                     ; VD_VESA_640x480_15
                        UVGAString,                     ; VD_VESA_640x480_15
                        HVGAString,                     ; VD_VESA_1280x1K_15
			0				; table terminator


	; these are the strings describing the devices 	
LocalDefString VGAString <"VESA Compatible SuperVGA: 640x480 32K-color",0>
LocalDefString SVGAString <"VESA Compatible SuperVGA: 800x600 32K-color",0>
LocalDefString UVGAString <"VESA Compatible SuperVGA: 1024x768 32K-color",0>
LocalDefString HVGAString <"VESA Compatible SuperVGA: 1280x1024 32K-color",0>
