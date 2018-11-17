
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		hgcTables.asm

AUTHOR:		Tony Requist

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Tony	10/88	initial version
	jeremy	5/91	Added support for HGC compatible cards.


DESCRIPTION:
	This file contains a few tables used by the HGC screen driver.

	$Id: hgcTables.asm,v 1.1 97/04/18 11:42:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;-----------------------------------------------------------------------------
;		Tables for HGC Initialization
;-----------------------------------------------------------------------------

BIOSData	label	byte
	db	7		; CRT Mode
	dw	80		; CRT Columns
	dw	8000h		; CRT Length
	dw	0		; CRT Start
	dw	8 dup (0)	; Cursor position
	dw	0		; Cursor mode
	db	0		; Active Page
	dw	CRTC_ADDRESS	; CRT Controller Address
	db	0ah		; CRT Mode Set
	db	0		; CRT Palette (unused)
EndBIOSData	label	byte

BIOS_DATA_LENGTH	=	EndBIOSData - BIOSData

CRTCParams	label	word
	db	35h		; CRTC_REG_HORIZ_TOTAL
	db	2dh		; CRTC_REG_HORIZ_DISPLAYED
	db	2eh		; CRTC_REG_HORIZ_SYNC_POS
	db	07h		; CRTC_REG_HORIZ_SYNC_WIDTH
	db	5bh		; CRTC_REG_VERT_TOTAL
	db	02h		; CRTC_REG_VERT_ADJUST
	db	57h		; CRTC_REG_VERT_DISPLAYED
	db	57h		; CRTC_REG_VERT_SYNC_POS
	db	02h		; CRTC_REG_INTERLACE_MODE
	db	03h		; CRTC_REG_MAX_SCAN_LINE
;	db	00h		; CRTC_REG_CURSOR_START
;	db	00h		; CRTC_REG_CURSOR_END
EndCRTCParams	label	word

CRTC_PARAMS_LENGTH	=	EndCRTCParams - CRTCParams



VideoMisc	segment	resource

	; this table holds the offsets to the test routines for the devices
vidTestRoutines	label	nptr
		nptr	offset VidTestHGC	; VD_HERCULES_HGC
		nptr	offset VidTestHGCCompat	; VD_HERCULES_HGC_COMPAT
		nptr	offset VidTestHGC	; VD_HERCULES_HGC_INVERSE

	; this table holds the offsets to the test routines for the devices
vidSetRoutines	label	nptr
		nptr	offset VidSetHGC	; VD_HERCULES_HGC
		nptr	offset VidSetHGC	; VD_HERCULES_HGC_COMPAT
		nptr	offset VidSetInverseHGC	; VD_HERCULES_HGC_INVERSE
VideoMisc	ends
