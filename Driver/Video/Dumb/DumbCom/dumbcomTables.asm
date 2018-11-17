
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Dumb Raster video drivers
FILE:		dumbcomTables.asm

AUTHOR:		Tony Requist

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Tony	10/88	initial version


DESCRIPTION:
	This file contains a few tables used by the bitmap screen driver.

	$Id: dumbcomTables.asm,v 1.1 97/04/18 11:42:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

;------------------------------------------------------------------------------
;		Mask tables
;------------------------------------------------------------------------------

ifndef	IS_CLR24
leftMaskTable	label	 word
	byte	11111111b,11111111b
	byte	01111111b,11111111b
	byte	00111111b,11111111b
	byte	00011111b,11111111b
	byte	00001111b,11111111b
	byte	00000111b,11111111b
	byte	00000011b,11111111b
	byte	00000001b,11111111b
	byte	00000000b,11111111b
	byte	00000000b,01111111b
	byte	00000000b,00111111b
	byte	00000000b,00011111b
	byte	00000000b,00001111b
	byte	00000000b,00000111b
	byte	00000000b,00000011b
	byte	00000000b,00000001b

rightMaskTable	label	 word
	byte	10000000b,00000000b
	byte	11000000b,00000000b
	byte	11100000b,00000000b
	byte	11110000b,00000000b
	byte	11111000b,00000000b
	byte	11111100b,00000000b
	byte	11111110b,00000000b
	byte	11111111b,00000000b
	byte	11111111b,10000000b
	byte	11111111b,11000000b
	byte	11111111b,11100000b
	byte	11111111b,11110000b
	byte	11111111b,11111000b
	byte	11111111b,11111100b
	byte	11111111b,11111110b
	byte	11111111b,11111111b
endif

;------------------------------------------------------------------------------
;		Table of draw mode routines
;------------------------------------------------------------------------------

drawModeTable	label	 word
	nptr	ModeCLEAR
	nptr	ModeCOPY
	nptr	ModeNOP
	nptr	ModeAND
	nptr	ModeINVERT
	nptr	ModeXOR
	nptr	ModeSET
	nptr	ModeOR


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

		; these are offsets to the byte mode routines in the 
		; bitmap module
PLByteModeRout	label	nptr
		nptr	ByteCLEAR
		nptr	ByteCOPY
		nptr	ByteNOP
		nptr	ByteAND
		nptr	ByteINV
		nptr	ByteINV		; map XOR to INV for bitmaps
		nptr	ByteSET
		nptr	ByteOR

PLByteMixRout	label	 word
		nptr	GetSetBitmapByte
		nptr	GetSetBitmapByte
		nptr	GetMixBitmapByte
		nptr	GetMixBitmapByte
		nptr	GetMixBitmapByte
		nptr	GetMixBitmapByte
		nptr	GetSetBitmapByte
		nptr	GetMixBitmapByte

VidEnds		PutLine

