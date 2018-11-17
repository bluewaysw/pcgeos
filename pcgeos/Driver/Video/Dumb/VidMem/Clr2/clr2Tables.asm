COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		VidMem/Clr2
FILE:		clr2Tables.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:
	

	$Id: clr2Tables.asm,v 1.1 97/04/18 11:43:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;	left mask table

leftMaskTable	label	 word
	byte	11111111b,11111111b
	byte	00111111b,11111111b
	byte	00001111b,11111111b
	byte	00000011b,11111111b
	byte	00000000b,11111111b
	byte	00000000b,00111111b
	byte	00000000b,00001111b
	byte	00000000b,00000011b

rightMaskTable	label	 word
	byte	11000000b,00000000b
	byte	11110000b,00000000b
	byte	11111100b,00000000b
	byte	11111111b,00000000b
	byte	11111111b,11000000b
	byte	11111111b,11110000b
	byte	11111111b,11111100b
	byte	11111111b,11111111b

;----------------------------------------------------------------------------
;		Driver jump table (used by DriverStrategy)
;----------------------------------------------------------------------------

driverJumpTable	label	word
	dw	0				; intiialization
	dw	0				; last gasp
	dw	0				; suspend
	dw	0				; unsuspend
	dw	0				; test for device existance
	dw	0				; set device type
	dw	0				; get ptr to info block
	dw	0				; get exclusive
	dw	0				; start exclusive
	dw	0				; end exclusive

	dw	offset Clr2:VidGetPixel		; get a pixel color
	dw	offset Clr2:Clr2CallMod		; GetBits in another module
	dw	0				; set the ptr pic
	dw	0				; hide the cursor
	dw	0				; show the cursor
	dw	0				; move the cursor
	dw	0				; set save under area
	dw	0				; restore save under area
	dw	0				; nuke save under area
	dw	0				; request save under
	dw	0				; check save under
	dw	0				; get save under info
	dw	0		 		; check s.u. collision
	dw	0				; set xor region
	dw	0				; clear xor region

	dw	offset Clr2:VidDrawRect		; rectangle
	dw	offset Clr2:VidPutString	; char string
	dw	offset Clr2:Clr2CallMod		; BitBlt in another module
	dw	offset Clr2:Clr2CallMod		; PutBits in another module
	dw	offset Clr2:Clr2CallMod		; DrawLine in another module
	dw	offset Clr2:VidDrawRegion	; draws a region
	dw	offset Clr2:Clr2CallMod		; PutLine in another module
	dw	offset Clr2:Clr2CallMod		; Polygon in another module
	dw	0				; ScreenOn in another module
	dw	0				; ScreenOff in another module
	dw	offset Clr2:Clr2CallMod		; Polyline in another module
	dw	offset Clr2:Clr2CallMod		; Polyline in another module
	dw	offset Clr2:Clr2CallMod		; Polyline in another module
	dw	0				; SetPalette
	dw	0				; GetPalette
.assert ($-driverJumpTable) eq VidFunction


	; this table holds offsets to the routines in different modules
moduleTable	label	fptr
	fptr	0 				; intiialization
	fptr	0				; last gasp
	fptr	0				; suspend
	fptr	0				; unsuspend
	fptr	0				; test for device existance
	fptr	0				; set device type
	fptr	0				; get ptr to info block
	fptr	0				; get exclusive
	fptr	0				; start exclusive
	fptr	0				; end exclusive

	fptr	0				; get a pixel color
	fptr	Clr2Misc:VidGetBits	 	; GetBits in another module
	fptr	0				; set the ptr pic
	fptr	0				; hide the cursor
	fptr	0				; show the cursor
	fptr	0				; move the cursor
	fptr	0				; set save under area
	fptr	0				; restore save under area
	fptr	0				; nuke save under area
	fptr	0				; request save under
	fptr	0				; check save under
	fptr	0				; get save under info
	fptr	0		 		; check s.u. collision
	fptr	0				; set xor region
	fptr	0				; clear xor region

	fptr	0				; rectangle
	fptr	0				; char string
	fptr	Clr2Blt:VidBitBlt		; BitBlt in another module
	fptr	Clr2Bitmap:VidPutBits	  	; PutBits in another module
	fptr	Clr2Line:VidDrawLine		; DrawLine in another module
	fptr	0				; draws a region
	fptr	Clr2PutLine:VidPutLine		; PutLine in another module
	fptr	Clr2Line:VidPolygon		; Polygon in another module
	fptr	0				; ScreenOn in another module
	fptr	0				; ScreenOff in another module
	fptr	Clr2Line:VidPolyline		; Polyline in another module
	fptr	Clr2Line:VidDashLine		; DashLine in another module
	fptr	Clr2Line:VidDashFill		; DashFill in another module
	fptr	0				; SetPalette in another module
	fptr	0				; SetPalette in another module
.assert ($-moduleTable) eq (VidFunction*2)

;----------------------------------------------------------------------------
;		Video Semaphores
;----------------------------------------------------------------------------

videoSem	Semaphore	<1,0>

;------------------------------------------------------------------------------
;		Table of character drawing routines
;------------------------------------------------------------------------------

FCC_table	label	word
	dw	offset Clr2:Char1In	;load 1
	dw	offset Clr2:Char2In	;load 2
	dw	offset Clr2:Char3In	;load 3
	dw	offset Clr2:Char4In	;load 4



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
		nptr	offset NullBMScan		; BMF_4BIT   no    no
		nptr	offset NullBMScan		; BMF_8BIT   no    no
		nptr	offset NullBMScan		; BMF_24BIT  no    no
		nptr	offset NullBMScan		; BMF_4CMYK  no    no
		nptr	offset NullBMScan		; BMF_3CMY   no    no
		nptr	offset PutColorScan		; BMF_2BIT   no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScan 		; BMF_MONO   no    yes
		nptr	offset NullBMScan		; BMF_4BIT   no    yes
		nptr	offset NullBMScan		; BMF_8BIT   no    yes
		nptr	offset NullBMScan		; BMF_24BIT  no    yes
		nptr	offset NullBMScan		; BMF_4CMKY  no    yes
		nptr	offset NullBMScan		; BMF_3CMY   no    yes 
		nptr	offset NullBMScan		; BMF_2BIT   no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 

		nptr	offset PutBWScanMask 		; BMF_MONO   yes   no
		nptr	offset NullBMScan		; BMF_4BIT   yes   no
		nptr	offset NullBMScan		; BMF_8BIT   yes   no
		nptr	offset NullBMScan		; BMF_CLR24  yes   no
		nptr	offset NullBMScan		; BMF_4CMKY  yes   no
		nptr	offset NullBMScan		; BMF_3CMY   yes   no
		nptr	offset PutColorScanMask		; BMF_2BIT   yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no

		nptr	offset FillBWScan 		; BMF_MONO   yes   yes
		nptr	offset FillBWScan 		; BMF_4BIT   yes   yes
		nptr	offset FillBWScan 		; BMF_8BIT   yes   yes
		nptr	offset FillBWScan 		; BMF_24BIT  yes   yes
		nptr	offset FillBWScan 		; BMF_4CMKY  yes   yes
		nptr	offset FillBWScan		; BMF_3CMY   yes   yes
		nptr	offset FillBWScan		; BMF_2BIT   yes   yes

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
		nptr	offset NullBMScan		; BMF_4BIT   no    no
		nptr	offset NullBMScan		; BMF_8BIT   no    no
		nptr	offset NullBMScan		; BMF_24BIT  no    no
		nptr	offset NullBMScan		; BMF_4CMKY  no    no
		nptr	offset NullBMScan		; BMF_3CMY   no    no
		nptr	offset PutColorScan		; BMF_2BIT   no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScan 		; BMF_MONO   no    yes
		nptr	offset NullBMScan		; BMF_4BIT   no    yes
		nptr	offset NullBMScan		; BMF_8BIT   no    yes
		nptr	offset NullBMScan		; BMF_24BIT  no    yes
		nptr	offset NullBMScan		; BMF_4CMKY  no    yes
		nptr	offset NullBMScan		; BMF_3CMY   no    yes 
		nptr	offset NullBMScan		; BMF_2BIT   no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 

		nptr	offset PutBWScanMask		; BMF_MONO   yes   no
		nptr	offset NullBMScan		; BMF_4BIT   yes   no
		nptr	offset NullBMScan		; BMF_8BIT   yes   no
		nptr	offset NullBMScan		; BMF_24BIT  yes   no
		nptr	offset NullBMScan		; BMF_4CMKY  yes   no
		nptr	offset NullBMScan		; BMF_3CMY   yes   no
		nptr	offset PutColorScanMask		; BMF_2BIT   yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no

		nptr	offset FillBWScan 		; BMF_MONO   yes   yes
		nptr	offset FillBWScan 		; BMF_4BIT   yes   yes
		nptr	offset FillBWScan 		; BMF_8BIT   yes   yes
		nptr	offset FillBWScan 		; BMF_24BIT  yes   yes
		nptr	offset FillBWScan 		; BMF_4CMKY  yes   yes
		nptr	offset FillBWScan		; BMF_3CMY   yes   yes
		nptr	offset FillBWScan		; BMF_2BIT   yes   yes

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
