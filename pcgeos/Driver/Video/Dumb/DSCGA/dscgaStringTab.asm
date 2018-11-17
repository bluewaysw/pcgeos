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
		
	$Id: dscgaStringTab.asm,v 1.1 97/04/18 11:43:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_DSCGA		enum	VideoDevice, 0


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
			DSCGAString,			; VD_DSCGA
			0				; table terminator

	; these are the strings describing the devices
DSCGAString	chunk.char "Double-Scan CGA: 640x400 Mono",0 	; VD_DSCGA



