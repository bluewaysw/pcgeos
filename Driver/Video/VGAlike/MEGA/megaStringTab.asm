
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		MEGA Video Driver
FILE:		megaStringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90
		Jeremy Dashe, 4/20/91

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision
	Jeremy	4/91		monochrome version


DESCRIPTION:
	This file holds the device string tables
		

	$Id: megaStringTab.asm,v 1.1 97/04/18 11:42:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_MEGA		enum	VideoDevice, 0
VD_MEGA_INVERSE	enum	VideoDevice


	; the first thing in the segment is the DriverExtendedInfoTable
	; structure
megaDevTable DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		VideoDevice/2,			; DEIT_numDevices
		offset MEGAStringTable,		; DEIT_nameTable
		0 				; DEIT_infoTable
		>

	; this is the table of near pointers to the device strings
MEGAStringTable lptr.char \
			MEGAString,			; VD_MEGA
			MEGAInverseString,		; VD_MEGA_INVERSE
			0				; table terminator


	; these are the strings describing the devices
MEGAString	  chunk.char "EGA: 640x350 Mono",0 		;VD_MEGA
MEGAInverseString chunk.char "EGA: 640x350 Inverse Mono",0	;VD_MEGA_INVERSE
