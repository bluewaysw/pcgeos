COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Simp4Bit video driver
FILE:		simp4bitTables.asm

AUTHOR:		Andrew Wilson, Mar 23, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/23/95		Initial revision

DESCRIPTION:
	Contains tables for the simp4bit driver	

	$Id: simp4bitTables.asm,v 1.1 97/04/18 11:43:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

leftMaskTable	label	 word
	byte	11111111b,11111111b
	byte	MASK_FOR_RIGHTMOST_PIXEL_IN_BYTE, 11111111b
	byte	00000000b,11111111b
	byte	00000000b,MASK_FOR_RIGHTMOST_PIXEL_IN_BYTE

rightMaskTable	label	 word
	byte	MASK_FOR_LEFTMOST_PIXEL_IN_BYTE,00000000b
	byte	11111111b,00000000b
	byte	11111111b,MASK_FOR_LEFTMOST_PIXEL_IN_BYTE
	byte	11111111b,11111111b

;------------------------------------------------------------------------------
;		Table of character drawing routines
;------------------------------------------------------------------------------

FCC_table	label	word
	dw	offset dgroup:Char1In	;load 1
	dw	offset dgroup:Char2In	;load 2
	dw	offset dgroup:Char3In	;load 3
	dw	offset dgroup:Char4In	;load 4


VideoMisc	segment	resource
vidTestRoutines	label	nptr
	nptr	offset VidTestSimp4Bit	;VD_SIMP4BIT

vidSetRoutines	label	nptr
	nptr	offset VidSetSimp4Bit
VideoMisc	ends


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
		nptr	offset PutColorScan		; BMF_CLR4   no    no
		nptr	offset NullBMScan		; BMF_CLR8   no    no
		nptr	offset NullBMScan		; BMF_CLR24  no    no
		nptr	offset NullBMScan		; BMF_CMYK   no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScan 		; BMF_MONO   no    yes
		nptr	offset PutColorScan		; BMF_CLR4   no    yes
		nptr	offset NullBMScan		; BMF_CLR8   no    yes
		nptr	offset NullBMScan		; BMF_CLR24  no    yes
		nptr	offset NullBMScan		; BMF_CMYK   no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 

		nptr	offset PutBWScanMask 		; BMF_MONO   yes   no
		nptr	offset PutColorScanMask		; BMF_CLR4   yes   no
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
		nptr	offset PutColorScan		; BMF_CLR4   no    no
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
		nptr	offset PutColorScanMask		; BMF_CLR4   yes   no
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
		nptr	ByteXOR
		nptr	ByteSET
		nptr	ByteOR
VidEnds		PutLine
