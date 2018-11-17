COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		vgaStringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision


DESCRIPTION:
	This file holds the device string tables
		
	$Id: vgaStringTab.asm,v 1.2 98/03/04 04:38:20 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_VGA		enum	VideoDevice, 0
VD_VGA_16_GRAY	enum	VideoDevice
VD_VGA_8_GRAY	enum	VideoDevice
VD_VGA_4_GRAY	enum	VideoDevice
VD_VGA_II	enum	VideoDevice

        ; the first thing in the segment is the DriverExtendedInfoTable
	; structure
;vgaDevTable 
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		VideoDevice/2,		; DEIT_numDevices
		offset VGAStringTable,	; DEIT_nameTable
		0			; DEIT_infoTable
		>


	; this is the table of near pointers to the device strings
VGAStringTable lptr.char \
		VGAString,		; VD_VGA
		Gray16,			; VD_VGA_16_GRAY
		Gray8,			; VD_VGA_8_GRAY
		Gray4,			; VD_VGA_4_GRAY
		VGAII,			; VD_VGA_II
		0			; table terminator


	; these are the strings describing the devices
LocalDefString VGAString <"VGA: 640x480 16-color",0>	      ; VD_VGA
LocalDefString Gray16 <"VGA: 640x480 16-level grayscale",0>   ; VD_VGA_16_GRAY
LocalDefString Gray8 <"VGA: 640x480 8-level grayscale",0>     ; VD_VGA_8_GRAY
LocalDefString Gray4 <"VGA: 640x480 4-level grayscale",0>     ; VD_VGA_4_GRAY
LocalDefString VGAII <"VGA: 640x480 16-color II",0>	      ; VD_VGA_II
