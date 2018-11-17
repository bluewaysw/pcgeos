
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		nullStringTab.asm

AUTHOR:		Jim DeFrisco, 8/1/90

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/1/90		Initial revision
	jeremy	4/10/91		Added "mono VGA" string


DESCRIPTION:
	This file holds the device string tables
		

	$Id: nullStringTab.asm,v 1.1 97/04/18 11:43:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

        ; the first thing in the segment is the DriverExtendedInfoTable
	; structure
DriverExtendedInfoTable <
		{},			; lmem header added by Esp
		length NullStringTable,         ; DEIT_numDevices
		offset NullStringTable,         ; DEIT_nameTable
		0                               ; DEIT_infoTable
		>

	; this is the table of near pointers to the device strings
NullStringTable lptr.char \
			NullVideoString,
			0				; table terminator

LocalDefString NullVideoString <"Null Video",0>
