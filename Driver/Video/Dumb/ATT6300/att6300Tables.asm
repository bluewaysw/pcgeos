
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		att6300Tables.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	7/90	initial version, mostly copied from HGC driver


DESCRIPTION:
	This file contains a few tables used by the ATT6300 screen driver.

	$Id: att6300Tables.asm,v 1.1 97/04/18 11:42:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


VideoMisc	segment	resource

	; this table holds the offsets to the test routines for the devices
vidTestRoutines	label	nptr
		nptr	offset VidTestATT6300	; VD_ATT6300
if not NT_DRIVER
		nptr	offset VidTestGridPad	; VD_GRIDPAD
		nptr    offset VidTestTosh3100          ; VD_TOSHIBA_3100
endif

	; this table holds the offsets to the set routines for the devices
vidSetRoutines	label	nptr
		nptr	offset VidSetATT6300		; VD_ATT6300
if not NT_DRIVER
		nptr	offset VidSetGridPad		; VD_GRIDPAD
		nptr    offset VidSetTosh3100        ; VD_TOSHIBA_3100
endif

VideoMisc	ends


