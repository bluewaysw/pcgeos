
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		CGA video driver
FILE:		cgaTables.asm

AUTHOR:		Tony Requist

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Tony	10/88	initial version
	jeremy	5/91	added CGA compatible card support


DESCRIPTION:
	This file contains a few tables used by the CGA screen driver.

	$Id: cgaTables.asm,v 1.1 97/04/18 11:42:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


VideoMisc	segment	resource

	; this table holds the offsets to the test routines for the devices
vidTestRoutines	label	nptr
		nptr	offset VidTestCGA		; VD_CGA
		nptr	offset VidTestCGACompat	; VD_CGA_BDB 
		nptr	offset VidTestCGACompat	; VD_CGA_BDG 
		nptr	offset VidTestCGACompat	; VD_CGA_BDC 
		nptr	offset VidTestCGACompat	; VD_CGA_BDR 
		nptr	offset VidTestCGACompat	; VD_CGA_BDV 
		nptr	offset VidTestCGACompat	; VD_CGA_BB  
		nptr	offset VidTestCGACompat	; VD_CGA_BLGy
		nptr	offset VidTestCGACompat	; VD_CGA_BDGy
		nptr	offset VidTestCGACompat	; VD_CGA_BLB 
		nptr	offset VidTestCGACompat	; VD_CGA_BLG 
		nptr	offset VidTestCGACompat	; VD_CGA_BLC 
		nptr	offset VidTestCGACompat	; VD_CGA_BLR 
		nptr	offset VidTestCGACompat	; VD_CGA_BLV 
		nptr	offset VidTestCGACompat	; VD_CGA_BY  
		nptr	offset VidTestCGACompat	; VD_CGA_BW  
		nptr	offset VidTestCGACompat	; VD_CGA_COMPAT
		nptr	offset VidTestCGACompat	; VD_CGA_INVERSE

	; this table holds the offsets to the set routines for the devices
vidSetRoutines	label	nptr
		nptr	offset VidSetCGA		; VD_CGA
		nptr	offset VidSetColorCGA	; VD_CGA_BDB 
		nptr	offset VidSetColorCGA	; VD_CGA_BDG 
		nptr	offset VidSetColorCGA	; VD_CGA_BDC 
		nptr	offset VidSetColorCGA	; VD_CGA_BDR 
		nptr	offset VidSetColorCGA	; VD_CGA_BDV 
		nptr	offset VidSetColorCGA	; VD_CGA_BB  
		nptr	offset VidSetColorCGA	; VD_CGA_BLGy
		nptr	offset VidSetColorCGA	; VD_CGA_BDGy
		nptr	offset VidSetColorCGA	; VD_CGA_BLB 
		nptr	offset VidSetColorCGA	; VD_CGA_BLG 
		nptr	offset VidSetColorCGA	; VD_CGA_BLC 
		nptr	offset VidSetColorCGA	; VD_CGA_BLR 
		nptr	offset VidSetColorCGA	; VD_CGA_BLV 
		nptr	offset VidSetColorCGA	; VD_CGA_BY  
		nptr	offset VidSetColorCGA	; VD_CGA_BW  
		nptr	offset VidSetCGA		; VD_CGA_COMPAT
		nptr	offset VidSetInverseCGA	; VD_CGA_INVERSE

VideoMisc	ends
