
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		egaStringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision
	jeremy	5/91		added support for EGA compatible, monochrome,
				and inverse mono EGA drivers


DESCRIPTION:
	This file holds the device string tables
		

	$Id: egaStringTab.asm,v 1.1 97/04/18 11:42:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_EGA		enum	VideoDevice, 0
VD_EGA_COMPAT	enum	VideoDevice


	; the first thing in the segment is the DriverExtendedInfoTable
	; structure
egaDevTable DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		VideoDevice/2,			; DEIT_numDevices
		offset EGAStringTable,		; DEIT_nameTable
		0 				; DEIT_infoTable
		>

	; this is the table of near pointers to the device strings
EGAStringTable lptr.char \
			EGAString,			; VD_EGA
			EGACompatString,		; VD_EGA_COMPAT
			0				; table terminator


	; these are the strings describing the devices
EGAString	chunk.char "EGA: 640x350 16-color",0 		; VD_EGA
EGACompatString	chunk.char "EGA Compatible: 640x350 16-color",0 ; VD_EGA_COMPAT
