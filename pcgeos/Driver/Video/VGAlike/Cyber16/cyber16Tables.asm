COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved


PROJECT:	GEOS
MODULE:		Cyber16 Video Driver
FILE:		cyber16Tables.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	10/92	initial version


DESCRIPTION:
	Tables particular to 16 bit drivers
		
	$Id: cyber16Tables.asm,v 1.2$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


		; jump table for different (small) char drawing
FCC_table	label	word
	dw	offset dgroup:Char1In1Out	;load 1 byte
	dw	offset dgroup:Char2In2Out	;load 2 bytes
	dw	offset dgroup:Char3In3Out	;load 3 bytes
	dw	offset dgroup:Char4In4Out	;load 4 bytes


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
		nptr	offset PutColor8Scan		; BMF_CLR8   no    no
		nptr	offset PutColor24Scan		; BMF_CLR24  no    no
		nptr	offset NullBMScan		; BMF_CMYK   no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScan 		; BMF_MONO   no    yes
		nptr	offset PutColorScan		; BMF_CLR4   no    yes
		nptr	offset PutColor8Scan		; BMF_CLR8   no    yes
		nptr	offset PutColor24Scan		; BMF_CLR24  no    yes
		nptr	offset NullBMScan		; BMF_CMYK   no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes

		nptr	offset PutBWScanMask		; BMF_MONO   yes   no
		nptr	offset PutColorScanMask		; BMF_CLR4   yes   no
		nptr	offset PutColor8ScanMask	; BMF_CLR8   yes   no
		nptr	offset PutColor24ScanMask	; BMF_CLR24  yes   no
		nptr	offset NullBMScan		; BMF_CMYK   yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no

		nptr	offset FillBWScan 		; BMF_MONO   yes   yes
		nptr	offset FillBWScan		; BMF_CLR4   yes   yes
		nptr	offset FillBWScan		; BMF_CLR8   yes   yes
		nptr	offset FillBWScan		; BMF_CLR24  yes   yes
		nptr	offset FillBWScan		; BMF_CMYK   yes   yes

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
		nptr	offset PutColor8Scan		; BMF_CLR8   no    no
		nptr	offset PutColor24Scan		; BMF_CLR24  no    no
		nptr	offset NullBMScan		; BMF_CMYK   no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScan 		; BMF_MONO   no    yes
		nptr	offset PutColorScan		; BMF_CLR4   no    yes
		nptr	offset PutColor8Scan		; BMF_CLR8   no    yes
		nptr	offset PutColor24Scan		; BMF_CLR24  no    yes
		nptr	offset NullBMScan		; BMF_CMYK   no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes

		nptr	offset PutBWScanMask 		; BMF_MONO   yes   no
		nptr	offset PutColorScanMask		; BMF_CLR4   yes   no
		nptr	offset PutColor8ScanMask	; BMF_CLR8   yes   no
		nptr	offset PutColor24ScanMask	; BMF_CLR24  yes   no
		nptr	offset NullBMScan		; BMF_CMYK   yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no

		nptr	offset FillBWScan 		; BMF_MONO   yes   yes
		nptr	offset FillBWScan		; BMF_CLR4   yes   yes
		nptr	offset FillBWScan		; BMF_CLR8   yes   yes
		nptr	offset FillBWScan		; BMF_CLR24  yes   yes
		nptr	offset FillBWScan		; BMF_CMYK   yes   yes

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

VidEnds		PutLine

VidSegment	Misc
	; this table holds the offsets to the test routines for the devices
vidTestRoutines	label	nptr
if	ALLOW_BIG_MOUSE_POINTER
	nptr	offset VidTestIGSCyberPro ; VD_IGS_CYBER_PRO_640x480_16_SP
	nptr	offset VidTestIGSCyberPro ; VD_IGS_CYBER_PRO_640x480_16_BP
	nptr	offset VidTestIGSCyberPro ; VD_IGS_CYBER_PRO_800x600_16_SP
	nptr	offset VidTestIGSCyberPro ; VD_IGS_CYBER_PRO_800x600_16_BP
if	ALLOW_1Kx768_16
	nptr	offset VidTestIGSCyberPro ; VD_IGS_CYBER_PRO_1Kx768_16_SP
	nptr	offset VidTestIGSCyberPro ; VD_IGS_CYBER_PRO_1Kx768_16_BP
endif	; ALLOW_1Kx768_16
else
	nptr	offset VidTestIGSCyberPro ; VD_IGS_CYBER_PRO_640x480_16
	nptr	offset VidTestIGSCyberPro ; VD_IGS_CYBER_PRO_800x600_16
if	ALLOW_1Kx768_16
	nptr	offset VidTestIGSCyberPro ; VD_IGS_CYBER_PRO_1Kx768_16
endif	; ALLOW_1Kx768_16
endif	; ALLOW_BIG_MOUSE_POINTER

	; this table holds the offsets to the test routines for the devices
vidSetRoutines	label	nptr
if	ALLOW_BIG_MOUSE_POINTER
	nptr	offset VidSetIGSCyberPro ; VD_IGS_CYBER_PRO_640x480_16_SP
	nptr	offset VidSetIGSCyberPro ; VD_IGS_CYBER_PRO_640x480_16_BP
	nptr	offset VidSetIGSCyberPro ; VD_IGS_CYBER_PRO_800x600_16_SP
	nptr	offset VidSetIGSCyberPro ; VD_IGS_CYBER_PRO_800x600_16_BP
if	ALLOW_1Kx768_16
	nptr	offset VidSetIGSCyberPro ; VD_IGS_CYBER_PRO_1Kx768_16_SP
	nptr	offset VidSetIGSCyberPro ; VD_IGS_CYBER_PRO_1Kx768_16_BP
endif	; ALLOW_1Kx768_16
else
	nptr	offset VidSetIGSCyberPro ; VD_IGS_CYBER_PRO_640x480_16
	nptr	offset VidSetIGSCyberPro ; VD_IGS_CYBER_PRO_800x600_16
if	ALLOW_1Kx768_16
	nptr	offset VidSetIGSCyberPro ; VD_IGS_CYBER_PRO_1Kx768_16
endif	; ALLOW_1Kx768_16
endif	; ALLOW_BIG_MOUSE_POINTER

VidEnds		Misc

VidSegment	Blt

BltRouts	label	nptr
		nptr	offset Blt1Fast,
			offset Blt1OverSrc,
			offset Blt1OverDest,
			offset Blt1OverBoth,

			offset Blt1FastLeftSt,		; same page
			offset Blt1OverSrc,
			offset Blt1OverDest,
			offset Blt1OverBoth,

			offset Blt1Fast,		; from right to left
			offset Blt1OverSrc,		; different pages
			offset Blt1OverDest,
			offset Blt1OverBoth,

			offset Blt1FastRightSt,		; same page
			offset Blt1OverSrc,
			offset Blt1OverDest,
			offset Blt1OverBoth,
			 
			offset Blt1FastLeftSt,		; 2 windows for r/w
			offset Blt2OverSrc,		; from left to right
			offset Blt2OverDest,		; different pages
			offset Blt2OverBoth,

			offset Blt1FastLeftSt,		; same page
			offset Blt2OverSrc,
			offset Blt2OverDest,
			offset Blt2OverBoth,

			offset Blt1FastRightSt,		; from right to left
			offset Blt2OverSrcRS,		; different pages
			offset Blt2OverDestRS,
			offset Blt2OverBothRS,

			offset Blt1FastRightSt,		; same page
			offset Blt2OverSrcRS,
			offset Blt2OverDestRS,
			offset Blt2OverBothRS

VidEnds	 Blt
