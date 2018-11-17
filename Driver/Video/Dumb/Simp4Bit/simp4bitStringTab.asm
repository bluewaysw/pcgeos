
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		simp4bitStringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision


DESCRIPTION:
	This file holds the device string tables
		

	$Id: simp4bitStringTab.asm,v 1.1 97/04/18 11:43:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_SIMP4BIT		enum	VideoDevice, 0

	; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		VideoDevice/2,			; DEIT_numDevices
		offset Simp4BitStringTable,	; DEIT_nameTable
		0 				; DEIT_infoTable
		>


	; this is the table of near pointers to the device strings
Simp4BitStringTable lptr.char \
			Simp4BitString,			; VD_SIMP4BIT
			0				; table terminator

	; these are the strings describing the devices
ifidn	PRODUCT, <BOR1>
Simp4BitString	chunk.char "BOR1 4-Bit Video Driver",0 		; VD_SIMP4BIT
else
Simp4BitString	chunk.char "Simple 4-Bit Greyscale Driver",0 	; VD_SIMP4BIT
endif


