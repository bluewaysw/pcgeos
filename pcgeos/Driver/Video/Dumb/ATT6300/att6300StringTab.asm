
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		att6300StringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision


DESCRIPTION:
	This file holds the device string tables
		

	$Id: att6300StringTab.asm,v 1.1 97/04/18 11:42:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
if NT_DRIVER
VD_NTVDD		enum	VideoDevice, 0
else
VD_ATT6300		enum	VideoDevice, 0
VD_GRIDPAD		enum	VideoDevice
VD_TOSHIBA_3100         enum    VideoDevice
endif

	; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		VideoDevice/2,			; DEIT_numDevices
		offset ATT6300StringTable,	; DEIT_nameTable
		0 				; DEIT_infoTable
		>


	; this is the table of near pointers to the device strings
ATT6300StringTable lptr.char \
			ATT6300String,			; VD_ATT6300
if not NT_DRIVER
			GridPadString,			; VD_GRIDPAD
		    	Tosh3100String,                 ; VD_TOSHIBA_3100
endif
			0				; table terminator

	; these are the strings describing the devices
if NT_DRIVER
ATT6300String	chunk.char "NT VDD 640x480 -color",0 	; VD_ATT6300
else
ATT6300String	chunk.char "AT&T 6300: 640x400 Mono",0 	; VD_ATT6300
GridPadString	chunk.char "GridPad: 640x400 Mono",0 	; VD_GRIDPAD
Tosh3100String  chunk.char "Toshiba 3100: 640x400 Mono",0  ; VD_TOSHIBA_3100
endif



