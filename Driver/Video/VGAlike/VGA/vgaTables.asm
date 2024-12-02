COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		vgaTables.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	4/88	initial version


DESCRIPTION:
	This file contains a few tables used by the EGA screen driver.  It
	is included in the file Kernel/Screen/ega.asm
		
	$Id: vgaTables.asm,v 1.2 98/03/04 04:36:16 joon Exp $

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
		nptr	offset VidTestVGA		; VD_VGA
		nptr	offset VidTestVGA		; VD_VGA_16_GRAY
		nptr	offset VidTestVGA		; VD_VGA_8_GRAY
		nptr	offset VidTestVGA		; VD_VGA_4_GRAY
		nptr	offset VidTestVGA		; VD_VGA_II

	; this table holds the offsets to the test routines for the devices
vidSetRoutines	label	nptr
		nptr	offset VidSetDefaultPalette	; VD_VGA
		nptr	offset VidSet16GrayScale	; VD_VGA_16_GRAY
		nptr	offset VidSet8GrayScale		; VD_VGA_8_GRAY
		nptr	offset VidSet4GrayScale		; VD_VGA_4_GRAY
		nptr	offset VidSetVGAII		; VD_VGA_II

VideoMisc	ends
