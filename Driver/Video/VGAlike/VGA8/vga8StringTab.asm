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
		

	$Id: vga8StringTab.asm,v 1.1 97/04/18 11:42:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_VESA_640x480_8		enum	VideoDevice, 0
VD_VESA_800x600_8		enum	VideoDevice
ifndef PRODUCT_WIN_DEMO
VD_VESA_1Kx768_8		enum	VideoDevice
VD_VESA_1280x1K_8		enum	VideoDevice
;VD_VESA_640x400_8_TV		enum	VideoDevice
endif


        ; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
			VideoDevice/2,                  ; DEIT_numDevices
			offset VGA8StringTable,         ; DEIT_nameTable
			0                               ; DEIT_infoTable
			>


	; this is the table of near pointers to the device strings
VGA8StringTable lptr.char \
			VGAString,			; VD_VESA_640x480_8
			SVGAString,			; VD_VESA_800x600_8
ifndef PRODUCT_WIN_DEMO
			UVGAString,			; VD_VESA_1Kx768_8
			HVGAString,			; VD_VESA_1280x1K_8
;			TVGAString,			; VD_VESA_640x400_8_TV
endif
			0				; table terminator


	; these are the strings describing the devices 	
LocalDefString VGAString <"VESA Compatible SuperVGA: 640x480 256-color",0>
LocalDefString SVGAString <"VESA Compatible SuperVGA: 800x600 256-color",0>
ifndef PRODUCT_WIN_DEMO
LocalDefString UVGAString <"VESA Compatible SuperVGA: 1024x768 256-color",0>
LocalDefString HVGAString <"VESA Compatible SuperVGA: 1280x1024 256-color",0>
;LocalDefString TVGAString <"VESA Compatible SuperVGA: 640x400 256-color (TV)",0>
endif

