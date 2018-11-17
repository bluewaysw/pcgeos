COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Simp2Bit video driver
FILE:		simp2bitStringTab.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	10/7/96   	Initial revision


DESCRIPTION:
	This file holds the device string tables

	$Id: simp2bitStringTab.asm,v 1.1 97/04/18 11:43:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; these are the device enums
VD_SIMP2BIT		enum	VideoDevice, 0

	; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},				; lmem header added by Esp
		VideoDevice/2,			; DEIT_numDevices
		offset Simp2BitStringTable,	; DEIT_nameTable
		0 				; DEIT_infoTable
		>


	; this is the table of near pointers to the device strings
Simp2BitStringTable lptr.char \
		Simp2BitString,			; VD_SIMP2BIT
		0				; table terminator

	; these are the strings describing the devices
Simp2BitString	chunk.char "Simple 2-Bit Greyscale Driver",0 	; VD_SIMP2BIT


