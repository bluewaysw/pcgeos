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
VD_VESA_640x350_16              enum    VideoDevice
VD_VESA_640x400_16              enum    VideoDevice
VD_VESA_720x400_16              enum    VideoDevice
VD_VESA_800x480_16              enum    VideoDevice
VD_VESA_832x624_16              enum    VideoDevice
VD_VESA_848x480_16              enum    VideoDevice
VD_VESA_960x540_16              enum    VideoDevice
VD_VESA_960x600_16              enum    VideoDevice
VD_VESA_1024_600_16             enum    VideoDevice

VD_VESA_1Kx768_16               enum    VideoDevice

VD_VESA_1152x864_16             enum    VideoDevice
VD_VESA_1280x600_16             enum    VideoDevice
VD_VESA_1280x720_16             enum    VideoDevice
VD_VESA_1280x768_16             enum    VideoDevice
VD_VESA_1280x800_16             enum    VideoDevice
VD_VESA_1280x854_16             enum    VideoDevice
VD_VESA_1280x960_16             enum    VideoDevice

VD_VESA_1280x1K_16              enum    VideoDevice

VD_VESA_1360_768_16              enum    VideoDevice
VD_VESA_1366_768_16              enum    VideoDevice
VD_VESA_1400_1050_16             enum    VideoDevice
VD_VESA_1440_900_16              enum    VideoDevice
VD_VESA_1600_900_16              enum    VideoDevice
VD_VESA_1600_1024_16             enum    VideoDevice
VD_VESA_1600_1200_16             enum    VideoDevice
VD_VESA_1680_1050_16             enum    VideoDevice
VD_VESA_1920_1024_16             enum    VideoDevice
VD_VESA_1920_1080_16             enum    VideoDevice
VD_VESA_1920_1200_16             enum    VideoDevice
VD_VESA_1920_1440_16             enum    VideoDevice
VD_VESA_2048_1536_16             enum    VideoDevice

; DPI based modes
VD_VESA_DPI72_16             	 enum    VideoDevice
VD_VESA_DPI96_16             	 enum    VideoDevice
VD_VESA_DPI120_16             	 enum    VideoDevice

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
			VGA640_350String,
			VGA640_400String,
			VGA720_400String,
			VGA800_480String,
			VGA832_624String,
			VGA848_480String,
			VGA960_540String,
			VGA960_600String,
			VGA1024_600String,
			UVGAString,                     ; VD_VESA_1Kx768_16
			VGA1152_864String,
			VGA1280_600String,
			VGA1280_720String,
			VGA1280_768String,
			VGA1280_800String,
			VGA1280_854String,
			VGA1280_960String,
			HVGAString,                     ; VD_VESA_1280x1K_16
			VGA1360_768String,
			VGA1366_768String,
			VGA1400_1050String,
			VGA1440_900String,
			VGA1600_900String,
			VGA1600_1024String,
			VGA1600_1200String,
			VGA1680_1050String,
			VGA1920_1024String,
			VGA1920_1080String,
			VGA1920_1200String,
			VGA1920_1440String,
			VGA2048_1536String,
			VGA72DPIString,
			VGA96DPIString,
			VGA120DPIString,
endif
			0				; table terminator


	; these are the strings describing the devices 	
LocalDefString VGAString <"VESA Compatible SuperVGA: 640x480 64K-color",0>
LocalDefString SVGAString <"VESA Compatible SuperVGA: 800x600 64K-color",0>

ifndef PRODUCT_WIN_DEMO
LocalDefString VGA640_350String <"VESA Compatible SuperVGA: 640x350 64K-color",0>
LocalDefString VGA640_400String <"VESA Compatible SuperVGA: 640x400 64K-color",0>
LocalDefString VGA720_400String <"VESA Compatible SuperVGA: 720x400 64K-color",0>
LocalDefString VGA800_480String <"VESA Compatible SuperVGA: 800x480 64K-color",0>
LocalDefString VGA832_624String <"VESA Compatible SuperVGA: 832x624 64K-color",0>
LocalDefString VGA848_480String <"VESA Compatible SuperVGA: 848x480 64K-color",0>
LocalDefString VGA960_540String <"VESA Compatible SuperVGA: 960x540 64K-color",0>
LocalDefString VGA960_600String <"VESA Compatible SuperVGA: 960x600 64K-color",0>
LocalDefString VGA1024_600String <"VESA Compatible SuperVGA: 1024x600 64K-color",0>

LocalDefString UVGAString <"VESA Compatible SuperVGA: 1024x768 64K-color",0>

LocalDefString VGA1152_864String <"VESA Compatible SuperVGA: 1152x864 64K-color",0>
LocalDefString VGA1280_600String <"VESA Compatible SuperVGA: 1280x600 64K-color",0>
LocalDefString VGA1280_720String <"VESA Compatible SuperVGA: 1280x720 64K-color",0>
LocalDefString VGA1280_768String <"VESA Compatible SuperVGA: 1280x768 64K-color",0>
LocalDefString VGA1280_800String <"VESA Compatible SuperVGA: 1280x800 64K-color",0>
LocalDefString VGA1280_854String <"VESA Compatible SuperVGA: 1280x854 64K-color",0>
LocalDefString VGA1280_960String <"VESA Compatible SuperVGA: 1280x960 64K-color",0>

LocalDefString HVGAString <"VESA Compatible SuperVGA: 1280x1024 64K-color",0>

LocalDefString VGA1360_768String <"VESA Compatible SuperVGA: 1360x768 64K-color",0>
LocalDefString VGA1366_768String <"VESA Compatible SuperVGA: 1366x768 64K-color",0>
LocalDefString VGA1400_1050String <"VESA Compatible SuperVGA: 1400x1050 64K-color",0>
LocalDefString VGA1440_900String <"VESA Compatible SuperVGA: 1440x900 64K-color",0>
LocalDefString VGA1600_900String <"VESA Compatible SuperVGA: 1600x900 64K-color",0>
LocalDefString VGA1600_1024String <"VESA Compatible SuperVGA: 1600x1024 64K-color",0>
LocalDefString VGA1600_1200String <"VESA Compatible SuperVGA: 1600x1200 64K-color",0>
LocalDefString VGA1680_1050String <"VESA Compatible SuperVGA: 1680x1050 64K-color",0>
LocalDefString VGA1920_1024String <"VESA Compatible SuperVGA: 1920x1024 64K-color",0>
LocalDefString VGA1920_1080String <"VESA Compatible SuperVGA: 1920x1080 64K-color",0>
LocalDefString VGA1920_1200String <"VESA Compatible SuperVGA: 1920x1200 64K-color",0>
LocalDefString VGA1920_1440String <"VESA Compatible SuperVGA: 1920x1440 64K-color",0>
LocalDefString VGA2048_1536String <"VESA Compatible SuperVGA: 2048x1536 64K-color",0>

LocalDefString VGA72DPIString <"Basebox: 72 DPI 64K-color",0>
LocalDefString VGA96DPIString <"Basebox: 96 DPI 64K-color",0>
LocalDefString VGA120DPIString <"Basebox: 120 DPI 64K-color",0>
endif
   
