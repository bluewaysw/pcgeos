
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		MEGA video driver
FILE:		megaTables.asm

AUTHOR:		Jim DeFrisco, Jeremy Dashe

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	4/88	initial version
	jeremy	5/91	monochrome version


DESCRIPTION:
	This file contains a few tables used by the MEGA screen driver.  It
	is included in the file Kernel/Screen/mega.asm
		
	$Id: megaTables.asm,v 1.1 97/04/18 11:42:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;***************************************************************************
;	TABLES
;***************************************************************************

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
		nptr	offset VidTestMEGA		; VD_MEGA
		nptr	offset VidTestMEGA		;

	; this table holds the offsets to the test routines for the devices
vidSetRoutines	label	nptr
		nptr	offset VidSetMEGA		; VD_MEGA
		nptr	offset VidSetMEGAInverse	; VD_MEGA_INVERSE
VideoMisc	ends

VidSegment	Bitmap

		; this is a table of routines to put a single bitmap scan
		; line.  The B_type field passed in PutBitsArgs is used to
		; index into the table (the lower 5 bits).  The low three 
		; bits are the bitmap format, the next bit (BMT_COMPLEX) is
		; used by the kernel bitmap code to signal that it is a 
		; monochrome bitmap that should be filled with the current
		; area color.  The fifth bit is set if there is a mask storeed
		; with the bitmap.
putbitsTable	label	nptr				; FORMAT    mask? fill?
		nptr	offset PutBWScan 		; BMF_MONO   no    no
		nptr	offset NullBMScan		; BMF_CLR4   no    no
		nptr	offset NullBMScan		; BMF_CLR8   no    no
		nptr	offset NullBMScan		; BMF_CLR24  no    no
		nptr	offset NullBMScan		; BMF_CMYK   no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScan 		; BMF_MONO   no    yes
		nptr	offset NullBMScan		; BMF_CLR4   no    yes
		nptr	offset NullBMScan		; BMF_CLR8   no    yes
		nptr	offset NullBMScan		; BMF_CLR24  no    yes
		nptr	offset NullBMScan		; BMF_CMYK   no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 

		nptr	offset PutBWScanMask 		; BMF_MONO   yes   no
		nptr	offset NullBMScan		; BMF_CLR4   yes   no
		nptr	offset NullBMScan		; BMF_CLR8   yes   no
		nptr	offset NullBMScan		; BMF_CLR24  yes   no
		nptr	offset NullBMScan		; BMF_CMYK   yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no

		nptr	offset FillBWScan 		; BMF_MONO   yes   yes
		nptr	offset FillBWScan 		; BMF_CLR4   yes   yes
		nptr	offset FillBWScan 		; BMF_CLR8   yes   yes
		nptr	offset FillBWScan 		; BMF_CLR24  yes   yes
		nptr	offset FillBWScan 		; BMF_CMYK   yes   yes

VidEnds		Bitmap

VidSegment	PutLine

		; this is a table of routines to put a single bitmap scan
		; line.  The B_type field passed in PutBitsArgs is used to
		; index into the table (the lower 5 bits).  The low three 
		; bits are the bitmap format, the next bit (BMT_COMPLEX) is
		; used by the kernel bitmap code to signal that it is a 
		; monochrome bitmap that should be filled with the current
		; area color.  The fifth bit is set if there is a mask storeed
		; with the bitmap.
putlineTable	label	nptr				; FORMAT    mask? fill?
		nptr	offset PutBWScan 		; BMF_MONO   no    no
		nptr	offset NullBMScan		; BMF_CLR4   no    no
		nptr	offset NullBMScan		; BMF_CLR8   no    no
		nptr	offset NullBMScan		; BMF_CLR24  no    no
		nptr	offset NullBMScan		; BMF_CMYK   no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScan 		; BMF_MONO   no    yes
		nptr	offset NullBMScan		; BMF_CLR4   no    yes
		nptr	offset NullBMScan		; BMF_CLR8   no    yes
		nptr	offset NullBMScan		; BMF_CLR24  no    yes
		nptr	offset NullBMScan		; BMF_CMYK   no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 

		nptr	offset PutBWScanMask		; BMF_MONO   yes   no
		nptr	offset NullBMScan		; BMF_CLR4   yes   no
		nptr	offset NullBMScan		; BMF_CLR8   yes   no
		nptr	offset NullBMScan		; BMF_CLR24  yes   no
		nptr	offset NullBMScan		; BMF_CMYK   yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no

		nptr	offset FillBWScan 		; BMF_MONO   yes   yes
		nptr	offset FillBWScan 		; BMF_CLR4   yes   yes
		nptr	offset FillBWScan 		; BMF_CLR8   yes   yes
		nptr	offset FillBWScan 		; BMF_CLR24  yes   yes
		nptr	offset FillBWScan 		; BMF_CMYK   yes   yes

VidEnds		PutLine

