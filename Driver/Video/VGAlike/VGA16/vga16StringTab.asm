COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VGA16 Video Driver
FILE:		vga16StringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision


DESCRIPTION:
	This file holds the device string tables
		

	$Id: vga16StringTab.asm,v 1.3$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_VESA_640x480_16              enum    VideoDevice, 0
VD_VESA_800x600_16              enum    VideoDevice
ifndef PRODUCT_WIN_DEMO
VD_VESA_1Kx768_16               enum    VideoDevice
VD_VESA_1280x1K_16              enum    VideoDevice
endif

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
                        VGAString,                      ; VD_VESA_640x480_16
                        SVGAString,                     ; VD_VESA_800x600_16
ifndef PRODUCT_WIN_DEMO
								UVGAString,                     ; VD_VESA_1Kx768_16
                        HVGAString,                     ; VD_VESA_1280x1K_16
endif
			0				; table terminator


	; these are the strings describing the devices 	
LocalDefString VGAString <"VESA Compatible SuperVGA: 640x480 64K-color",0>
LocalDefString SVGAString <"VESA Compatible SuperVGA: 800x600 64K-color",0>
ifndef PRODUCT_WIN_DEMO
LocalDefString UVGAString <"VESA Compatible SuperVGA: 1024x768 64K-color",0>
LocalDefString HVGAString <"VESA Compatible SuperVGA: 1280x1024 64K-color",0>
endif

