
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		hgcStringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision
	jeremy	5/91		Added support for HGC compatible cards.


DESCRIPTION:
	This file holds the device string tables
		

	$Id: hgcStringTab.asm,v 1.1 97/04/18 11:42:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_HERCULES_HGC		enum	VideoDevice, 0
VD_HERCULES_HGC_COMPAT	enum	VideoDevice
VD_HERCULES_HGC_INVERSE	enum	VideoDevice

	; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		VideoDevice/2,			; DEIT_numDevices
		offset HGCStringTable,		; DEIT_nameTable
		0 				; DEIT_infoTable
		>


	; this is the table of near pointers to the device strings
HGCStringTable lptr.char \
			HGCString,		; VD_HERCULES_HGC
			HGCCompatString,	; VD_HERCULES_HGC_COMPAT
			HGCInverseString,	; VD_HERCULES_HGC_INVERSE
			0			; table terminator



	; these are the strings describing the devices
HGCString	chunk.char "Hercules HGC: 720x348 Mono",0 ; VD_HERCULES_HGC
HGCCompatString	chunk.char "Hercules HGC Compatible: 720x348 Mono",0 
						; VD_HERCULES_HGC_COMPAT
HGCInverseString chunk.char "Hercules HGC: 720x348 Inverse Mono",0 
						; VD_HERCULES_HGC_INVERSE
