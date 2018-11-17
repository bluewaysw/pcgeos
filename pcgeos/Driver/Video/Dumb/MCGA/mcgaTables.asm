
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		MCGA screen driver
FILE:		mcgaTables.asm

AUTHOR:		Tony Requist

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Tony	10/88	initial version
	jeremy	4/91	Added "mono VGA" string to driver list


DESCRIPTION:
	This file contains a few tables used by the MCGA screen driver.

	$Id: mcgaTables.asm,v 1.1 97/04/18 11:42:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

VideoMisc	segment	resource

	; this table holds the offsets to the test routines for the devices
vidTestRoutines	label	nptr
if not PZ_PCGEOS
		nptr	offset VidTestMCGA		; VD_IBM_MCGA
endif
		nptr	offset VidTestMCGA		; VD_IBM_MVGA
		nptr	offset VidTestMCGA		; VD_IBM_MVGA_INVERSE
CheckHack <($-vidTestRoutines) eq VideoDevice>

	; this table holds the offsets to the test routines for the devices
vidSetRoutines	label	nptr
if not PZ_PCGEOS
		nptr	offset VidSetMCGA		; VD_IBM_MCGA
endif
		nptr	offset VidSetMCGA		; VD_IBM_MVGA
		nptr	offset VidSetInverseMCGA	; VD_IBM_MVGA_INVERSE
CheckHack <($-vidSetRoutines) eq VideoDevice>

VideoMisc	ends
