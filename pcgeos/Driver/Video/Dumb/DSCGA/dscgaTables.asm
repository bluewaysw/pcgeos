COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Double-Scan CGA Video driver
FILE:		dscgaTables.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	7/90	initial version, mostly copied from HGC driver


DESCRIPTION:
	This file contains a few tables used by the Double-Scan CGA driver

	$Id: dscgaTables.asm,v 1.1 97/04/18 11:43:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VideoMisc	segment	resource

	; this table holds the offsets to the test routines for the devices
vidTestRoutines	label	nptr
		nptr	offset VidTestDSCGA		; VD_DSCGA

	; this table holds the offsets to the set routines for the devices
vidSetRoutines	label	nptr
		nptr	offset VidSetDSCGA		; VD_DSCGA

VideoMisc	ends


