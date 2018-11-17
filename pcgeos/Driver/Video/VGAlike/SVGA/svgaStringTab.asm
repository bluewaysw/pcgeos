
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		SVGA Video Driver
FILE:		svgaStringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision


DESCRIPTION:
	This file holds the device string tables
		

	$Id: svgaStringTab.asm,v 1.1 97/04/18 11:42:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_VESA_800		enum	VideoDevice, 0
VD_EVEREX_VP800		enum	VideoDevice
VD_HEADLAND_800         enum    VideoDevice
VD_OAK_800              enum    VideoDevice
VD_AHEAD_800            enum    VideoDevice
VD_ATI_800		enum    VideoDevice
VD_MAXLOGIC_800		enum    VideoDevice
VD_CHIPS_800		enum    VideoDevice
VD_GENOA_800		enum    VideoDevice
VD_TVGA_800		enum    VideoDevice
VD_TSENG_800		enum    VideoDevice
VD_PARADISE_800		enum    VideoDevice
VD_ZYMOS_POACH51	enum    VideoDevice
VD_ORCHID_PRO_800	enum    VideoDevice
VD_QUADRAM_SPECTRA	enum    VideoDevice
VD_SOTA			enum    VideoDevice
VD_STB			enum    VideoDevice
VD_CIRRUS_800		enum    VideoDevice
VD_LASER_800		enum    VideoDevice


        ; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
			VideoDevice/2,                  ; DEIT_numDevices
			offset SVGA800StringTable,      ; DEIT_nameTable
			0                               ; DEIT_infoTable
			>


	; this is the table of near pointers to the device strings
SVGA800StringTable lptr.char \
			VESA800String,			; VD_VESA_800
			View800String,			; VD_EVEREX_VP800
			Head800String,			; VD_HEADLAND_800
			Oak800String,			; VD_OAK_800
			Ahead800String,			; VD_AHEAD_800
			ATI800String,			; VD_ATI_800
			MaxLogic800String,		; VD_MAXLOGIC_800
			Boca800String,			; VD_CHIPS_800
			Genoa800String,			; VD_GENOA_800
			TVGA800String,			; VD_TVGA_800
			Tseng800String,			; VD_TSENG_800
			Paradise800String,		; VD_PARADISE_800
			ZymosString,			; VD_ZYMOS_POACH51
			OrchidString,			; VD_ORCHID_PRO_800
			QuadramString,			; VD_QUADRAM_SPECTRA
			SOTAString,			; VD_SOTA
			STBString,			; VD_STB
			Cirrus800String,		; VD_CIRRUS_800
			Laser800String,			; VD_LASER_800
			0				; table terminator


	; these are the strings describing the devices 	
LocalDefString VESA800String <"VESA Compatible Super VGA: 800x600 16-color",0>
LocalDefString View800String <"Everex Viewpoint VGA: 800x600 16-color",0>
LocalDefString Head800String <"Headland (Video 7) V7VGA: 800x600 16-color",0>
LocalDefString Oak800String <"Oak Technologies VGA: 800x600 16-color",0>
LocalDefString Ahead800String <"Ahead Wizard/Deluxe VGA: 800x600 16-color",0>
LocalDefString ATI800String <"ATI VGA Wonder: 800x600 16-color",0>
LocalDefString MaxLogic800String <"MaxLogic MaxVGA: 800x600 16-color",0>
LocalDefString Boca800String <"Boca Research 1024VGA: 800x600 16-color",0>
LocalDefString Genoa800String <"Genoa SuperVGA: 800x600 16-color",0>
LocalDefString TVGA800String <"Trident Compatible TVGA: 800x600 16-color",0>
LocalDefString Tseng800String <"Tseng Labs Compatible VGA: 800x600 16-color",0>
LocalDefString Paradise800String <"Paradise VGA: 800x600 16-color",0>
LocalDefString ZymosString <"Zymos POACH51 VGA: 800x600 16-color",0>
LocalDefString OrchidString <"Orchid ProDesigner VGA: 800x600 16-color",0>
LocalDefString QuadramString <"Quadram Spectra VGA: 800x600 16-color",0>
LocalDefString SOTAString <"SOTA VGA/16: 800x600 16-color",0>
LocalDefString STBString <"STB VGA Extra: 800x600 16-color",0>
LocalDefString Cirrus800String <"Cirrus Logic Compatible VGA: 800x600 16-color",0>
LocalDefString Laser800String <"Laser Enhanced Turbo VGA: 800x600 16-color",0>
