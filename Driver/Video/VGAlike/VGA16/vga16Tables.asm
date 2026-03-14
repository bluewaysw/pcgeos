COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved


PROJECT:	GEOS
MODULE:		VGA16 Video Driver
FILE:           vga16Tables.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	10/92	initial version


DESCRIPTION:
        Tables particular to 16 bit drivers
		
        $Id: vga16Tables.asm,v 1.2$

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
                nptr    offset PutColor24Scan           ; BMF_CLR24  no    no
		nptr	offset NullBMScan		; BMF_CMYK   no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScan 		; BMF_MONO   no    yes
		nptr	offset PutColorScan		; BMF_CLR4   no    yes
		nptr	offset PutColor8Scan		; BMF_CLR8   no    yes
                nptr    offset PutColor24Scan           ; BMF_CLR24  no    yes
		nptr	offset NullBMScan		; BMF_CMYK   no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes

		nptr	offset PutBWScanMask		; BMF_MONO   yes   no
		nptr	offset PutColorScanMask		; BMF_CLR4   yes   no
		nptr	offset PutColor8ScanMask	; BMF_CLR8   yes   no
                nptr    offset PutColor24ScanMask       ; BMF_CLR24  yes   no
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
                nptr    offset PutColor24Scan           ; BMF_CLR24  no    no
		nptr	offset NullBMScan		; BMF_CMYK   no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScan 		; BMF_MONO   no    yes
		nptr	offset PutColorScan		; BMF_CLR4   no    yes
		nptr	offset PutColor8Scan		; BMF_CLR8   no    yes
                nptr    offset PutColor24Scan           ; BMF_CLR24  no    yes
		nptr	offset NullBMScan		; BMF_CMYK   no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes

		nptr	offset PutBWScanMask 		; BMF_MONO   yes   no
		nptr	offset PutColorScanMask		; BMF_CLR4   yes   no
		nptr	offset PutColor8ScanMask	; BMF_CLR8   yes   no
                nptr    offset PutColor24ScanMask       ; BMF_CLR24  yes   no
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
		nptr    offset VidTestVGA16             ; VD_VESA_640x480_16
		nptr    offset VidTestSVGA16            ; VD_VESA_800x600_16
ifndef PRODUCT_WIN_DEMO
		nptr    offset VidTestVESA_640x350_16	; VD_VESA_640x350_16
		nptr    offset VidTestVESA_640x400_16	; VD_VESA_640x400_16
		nptr    offset VidTestVESA_720x400_16	; VD_VESA_720x400_16
		nptr    offset VidTestVESA_800x480_16	; VD_VESA_800x480_16
		nptr    offset VidTestVESA_832x624_16	; VD_VESA_832x624_16
		nptr    offset VidTestVESA_848x480_16	; VD_VESA_848x480_16
		nptr    offset VidTestVESA_960x540_16	; VD_VESA_960x540_16
		nptr    offset VidTestVESA_960x600_16	; VD_VESA_960x600_16
		nptr    offset VidTestVESA_1024_600_16	; VD_VESA_1024_600_16
		
		nptr    offset VidTestUVGA16            ; VD_VESA_1Kx768_16

		nptr    offset VidTestVESA_1152x864_16	; VD_VESA_1152x864_16
		nptr    offset VidTestVESA_1280x600_16	; VD_VESA_1280x600_16
		nptr    offset VidTestVESA_1280x720_16	; VD_VESA_1280x720_16
		nptr    offset VidTestVESA_1280x768_16	; VD_VESA_1280x768_16
		nptr    offset VidTestVESA_1280x800_16	; VD_VESA_1280x800_16
		nptr    offset VidTestVESA_1280x854_16	; VD_VESA_1280x854_16
		nptr    offset VidTestVESA_1280x960_16	; VD_VESA_1280x960_16

		nptr    offset VidTestHVGA16            ; VD_VESA_1280x1K_16

		nptr    offset VidTestVESA_1360_768_16	; VD_VESA_1360_768_16
		nptr    offset VidTestVESA_1366_768_16	; VD_VESA_1366_768_16
		nptr    offset VidTestVESA_1400_1050_16	; VD_VESA_1400_1050_16
		nptr    offset VidTestVESA_1440_900_16	; VD_VESA_1440_900_16
		nptr    offset VidTestVESA_1600_900_16	; VD_VESA_1600_900_16
		nptr    offset VidTestVESA_1600_1024_16	; VD_VESA_1600_1024_16
		nptr    offset VidTestVESA_1600_1200_16	; VD_VESA_1600_1200_16
		nptr    offset VidTestVESA_1680_1050_16	; VD_VESA_1680_1050_16
		nptr    offset VidTestVESA_1920_1024_16	; VD_VESA_1920_1024_16
		nptr    offset VidTestVESA_1920_1080_16	; VD_VESA_1920_1080_16
		nptr    offset VidTestVESA_1920_1200_16	; VD_VESA_1920_1200_16
		nptr    offset VidTestVESA_1920_1440_16	; VD_VESA_1920_1440_16
		nptr    offset VidTestVESA_2048_1536_16	; VD_VESA_2048_1536_16

		nptr    offset VidTestVESA_DPI72_16	; VD_VESA_DPI72_16
		nptr    offset VidTestVESA_DPI96_16	; VD_VESA_DPI96_16
		nptr    offset VidTestVESA_DPI120_16	; VD_VESA_DPI120_16
endif

	; this table holds the offsets to the test routines for the devices
vidSetRoutines	label	nptr
		nptr    offset VidSetVESA               ; VD_VESA_640x480_16
		nptr    offset VidSetVESA               ; VD_VESA_800x600_16
ifndef PRODUCT_WIN_DEMO
		nptr    offset VidSetVESA		; VD_VESA_640x350_16
		nptr    offset VidSetVESA		; VD_VESA_640x400_16
		nptr    offset VidSetVESA		; VD_VESA_720x400_16
		nptr    offset VidSetVESA		; VD_VESA_800x480_16
		nptr    offset VidSetVESA		; VD_VESA_832x624_16
		nptr    offset VidSetVESA		; VD_VESA_848x480_16
		nptr    offset VidSetVESA		; VD_VESA_960x540_16
		nptr    offset VidSetVESA		; VD_VESA_960x600_16
		nptr    offset VidSetVESA		; VD_VESA_1024_600_16
		
		nptr    offset VidSetVESA               ; VD_VESA_1Kx768_16
		
		nptr    offset VidSetVESA		; VD_VESA_1152x864_16
		nptr    offset VidSetVESA		; VD_VESA_1280x600_16
		nptr    offset VidSetVESA		; VD_VESA_1280x720_16
		nptr    offset VidSetVESA		; VD_VESA_1280x768_16
		nptr    offset VidSetVESA		; VD_VESA_1280x800_16
		nptr    offset VidSetVESA		; VD_VESA_1280x854_16
		nptr    offset VidSetVESA		; VD_VESA_1280x960_16
		
		nptr    offset VidSetVESA               ; VD_VESA_1280x1K_16

		nptr    offset VidSetVESA		; VD_VESA_1360_768_16
		nptr    offset VidSetVESA		; VD_VESA_1366_768_16
		nptr    offset VidSetVESA		; VD_VESA_1400_1050_16
		nptr    offset VidSetVESA		; VD_VESA_1440_900_16
		nptr    offset VidSetVESA		; VD_VESA_1600_900_16
		nptr    offset VidSetVESA		; VD_VESA_1600_1024_16
		nptr    offset VidSetVESA		; VD_VESA_1600_1200_16
		nptr    offset VidSetVESA		; VD_VESA_1680_1050_16
		nptr    offset VidSetVESA		; VD_VESA_1920_1024_16
		nptr    offset VidSetVESA		; VD_VESA_1920_1080_16
		nptr    offset VidSetVESA		; VD_VESA_1920_1200_16
		nptr    offset VidSetVESA		; VD_VESA_1920_1440_16
		nptr    offset VidSetVESA		; VD_VESA_2048_1536_16

		nptr    offset VidSetVESA		; VD_VESA_DPI72_16
		nptr    offset VidSetVESA		; VD_VESA_DPI96_16
		nptr    offset VidSetVESA		; VD_VESA_DPI120_16
endif

VidEnds		Misc

VidSegment      Blt

BltRouts        label   nptr
                nptr    offset Blt1Fast,
                        offset Blt1OverSrc,
                        offset Blt1OverDest,
                        offset Blt1OverBoth,

                        offset Blt1FastLeftSt,          ; same page
                        offset Blt1OverSrc,
                        offset Blt1OverDest,
                        offset Blt1OverBoth,

                        offset Blt1Fast,               ; from right to left
                        offset Blt1OverSrc,            ; different pages
                        offset Blt1OverDest,
                        offset Blt1OverBoth,

                        offset Blt1FastRightSt,        ; same page
                        offset Blt1OverSrc,
                        offset Blt1OverDest,
                        offset Blt1OverBoth,
                         
                        offset Blt1FastLeftSt,         ; 2 windows for r/w
                        offset Blt2OverSrc,            ; from left to right
                        offset Blt2OverDest,           ; different pages
                        offset Blt2OverBoth,

                        offset Blt1FastLeftSt,         ; same page
                        offset Blt2OverSrc,
                        offset Blt2OverDest,
                        offset Blt2OverBoth,

                        offset Blt1FastRightSt,        ; from right to left
                        offset Blt2OverSrcRS,          ; different pages
                        offset Blt2OverDestRS,
                        offset Blt2OverBothRS,

                        offset Blt1FastRightSt,        ; same page
                        offset Blt2OverSrcRS,
                        offset Blt2OverDestRS,
                        offset Blt2OverBothRS

VidEnds         Blt
