
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		SVGA screen driver
FILE:		svgaTables.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	9/90	initial version


DESCRIPTION:
	This file contains a few tables used by the EGA screen driver.  It
	is included in the file Kernel/Screen/ega.asm
		
	$Id: svgaTables.asm,v 1.1 97/04/18 11:42:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;	this table maps grDrawMode to the appropriate EGA function
;		EQUATE		OPERATION		SAME AS...
;		------		---------		----------
;		0 - CLEAR	dst <- 0		$00 COPY 
;		1 - COPY	dst <- src		src COPY 
;		2 - NOP		dst <- dst		$ff AND dst
;		3 - AND		dst <- (src) AND (dst)	src AND dst
;		4 - INVERT	dst <- NOT (dst)	$ff XOR dst
;		5 - XOR		dst <- (src) XOR (dst)  src XOR dst
;		6 - SET		dst <- 1		$ff COPY
;		7 - OR		dst <- (src) OR (dst)	src OR  dst

;	mapping drawMode to ega function number
egaFunc		db	DR_COPY			; drawing mode 0: COPY
		db	DR_COPY			; drawing mode 1: COPY
		db	DR_AND			; drawing mode 2: AND
		db	DR_AND			; drawing mode 3: AND
		db	DR_XOR			; drawing mode 4: XOR
		db	DR_XOR			; drawing mode 5: XOR
		db	DR_COPY			; drawing mode 6: COPY
		db	DR_OR			; drawing mode 7: OR

;	since some of the drawing modes don't require a source, but do
;	require some constant (see table above), we provide these constants
;	here.  The drawing mode equates are set up so that the odd numbered
;	modes require a constant source value.
constSrcTab	db	0, 0, 0ffh, 0, 0ffh, 0, 0ffh, 0
	

;	left mask table

leftMaskTable	label	byte
	db	11111111b
	db	01111111b
	db	00111111b
	db	00011111b
	db	00001111b
	db	00000111b
	db	00000011b
	db	00000001b

;	right mask table

rightMaskTable	label	byte
	db	10000000b
	db	11000000b
	db	11100000b
	db	11110000b
	db	11111000b
	db	11111100b
	db	11111110b
	db	11111111b



VideoMisc	segment	resource
	; this table holds the offsets to the test routines for the devices
vidTestRoutines	label	nptr
		nptr	offset VidTestVESA		; VD_VESA_800
		nptr	offset VidTestEverex		; VD_EVEREX_VP800
		nptr	offset VidTestHeadland		; VD_HEADLAND_800
		nptr	offset VidTestOak		; VD_OAK_800
		nptr	offset VidTestAhead		; VD_AHEAD_800
		nptr	offset VidTestATI		; VD_ATI_800
		nptr	offset VidTestCirrus		; VD_MAXLOGIC_800
		nptr	offset VidTestCHiPS		; VD_CHIPS_800
		nptr	offset VidTestGenoa		; VD_GENOA_800
		nptr	offset VidTestTrident		; VD_TVGA_800
		nptr	offset VidTestTseng		; VD_TSENG_800
		nptr	offset VidTestParadise		; VD_PARADISE_800
		nptr	offset VidTestTrident		; VD_ZYMOS_POACH51
		nptr	offset VidTestTseng		; VD_ORCHID_PRO_800
		nptr	offset VidTestTseng		; VD_QUADRAM_SPECTRA
		nptr	offset VidTestTseng		; VD_SOTA
		nptr	offset VidTestTseng		; VD_STB
		nptr	offset VidTestCirrus		; VD_CIRRUS_800
		nptr	offset VidTestLaser		; VD_LASER_800

	; this table holds the offsets to the test routines for the devices
vidSetRoutines	label	nptr
		nptr	offset VidSetWithOldBIOS	; VD_VESA_84
		nptr	offset VidSetEverex		; VD_EVEREX_VP800
		nptr	offset VidSetHeadland		; VD_HEADLAND_800
		nptr	offset VidSetWithOldBIOS	; VD_OAK_800
		nptr	offset VidSetWithOldBIOS	; VD_AHEAD_800
		nptr	offset VidSetWithOldBIOS	; VD_ATI_800
		nptr	offset VidSetWithOldBIOS	; VD_MAXLOGIC_800
		nptr	offset VidSetWithOldBIOS	; VD_CHIPS_800
		nptr	offset VidSetWithOldBIOS	; VD_GENOA_800
		nptr	offset VidSetWithOldBIOS	; VD_TVGA_800
		nptr	offset VidSetWithOldBIOS	; VD_TSENG_800
		nptr	offset VidSetWithOldBIOS	; VD_PARADISE_800
		nptr	offset VidSetWithOldBIOS	; VD_ZYMOS_POACH51
		nptr	offset VidSetWithOldBIOS	; VD_ORCHID_PRO_800
		nptr	offset VidSetWithOldBIOS	; VD_QUADRAM_SPECTRA
		nptr	offset VidSetWithOldBIOS	; VD_SOTA
		nptr	offset VidSetWithOldBIOS	; VD_STB
		nptr	offset VidSetWithOldBIOS	; VD_CIRRUS_800
		nptr	offset VidSetLaser		; VD_LASER_800

VideoMisc	ends


