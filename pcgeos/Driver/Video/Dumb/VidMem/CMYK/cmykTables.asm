
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video driver
FILE:		cmykTables.asm

AUTHOR:		Jim DeFrisco

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	12/91	initial version


DESCRIPTION:
		
	$Id: cmykTables.asm,v 1.1 97/04/18 11:43:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;	left mask table

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
		nptr	offset PutBWScanCMYK 		; BMF_MONO   no    no
		nptr	offset PutCMYKColor4		; BMF_CLR4   no    no
		nptr	offset PutCMYKColor8		; BMF_CLR8   no    no
		nptr	offset PutCMYKColor24		; BMF_CLR24  no    no
		nptr	offset NullBMScan		; BMF_CMYK   no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScanCMYK 		; BMF_MONO   no    yes
		nptr	offset NullBMScan		; BMF_CLR4   no    yes
		nptr	offset NullBMScan		; BMF_CLR8   no    yes
		nptr	offset NullBMScan		; BMF_CLR24  no    yes
		nptr	offset NullBMScan		; BMF_CMYK   no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 

		nptr	offset PutBWScanMaskCMYK	; BMF_MONO   yes   no
		nptr	offset PutCMYKColor4Mask	; BMF_CLR4   yes   no
		nptr	offset PutCMYKColor8Mask	; BMF_CLR8   yes   no
		nptr	offset PutCMYKColor24Mask	; BMF_CLR24  yes   no
		nptr	offset NullBMScan		; BMF_CMYK   yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no

		nptr	offset FillBWScanCMYK 		; BMF_MONO   yes   yes
		nptr	offset FillBWScanCMYK		; BMF_CLR4   yes   yes
		nptr	offset FillBWScanCMYK		; BMF_CLR8   yes   yes
		nptr	offset FillBWScanCMYK		; BMF_CLR24  yes   yes
		nptr	offset FillBWScanCMYK		; BMF_CMYK   yes   yes

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
		nptr	offset PutBWScanCMYK 		; BMF_MONO   no    no
		nptr	offset PutCMYKColor4		; BMF_CLR4   no    no
		nptr	offset PutCMYKColor8		; BMF_CLR8   no    no
		nptr	offset PutCMYKColor24		; BMF_CLR24  no    no
		nptr	offset NullBMScan		; BMF_CMYK   no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no
		nptr	offset NullBMScan		; UNUSED     no    no

		nptr	offset FillBWScanCMYK 		; BMF_MONO   no    yes
		nptr	offset NullBMScan		; BMF_CLR4   no    yes
		nptr	offset NullBMScan		; BMF_CLR8   no    yes
		nptr	offset NullBMScan		; BMF_CLR24  no    yes
		nptr	offset NullBMScan		; BMF_CMYK   no    yes
		nptr	offset NullBMScan		; UNUSED     no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 
		nptr	offset NullBMScan		; UNUSED     no    yes 

		nptr	offset PutBWScanMaskCMYK	; BMF_MONO   yes   no
		nptr	offset PutCMYKColor4Mask	; BMF_CLR4   yes   no
		nptr	offset PutCMYKColor8Mask	; BMF_CLR8   yes   no
		nptr	offset PutCMYKColor24Mask	; BMF_CLR24  yes   no
		nptr	offset NullBMScan		; BMF_CMYK   yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no

		nptr	offset FillBWScanCMYK 		; BMF_MONO   yes   yes
		nptr	offset FillBWScanCMYK		; BMF_CLR4   yes   yes
		nptr	offset FillBWScanCMYK		; BMF_CLR8   yes   yes
		nptr	offset FillBWScanCMYK		; BMF_CLR24  yes   yes
		nptr	offset FillBWScanCMYK		; BMF_CMYK   yes   yes

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

	dw	offset cmykcode:VidGetPixel	; get a pixel color
	dw	offset cmykcode:CMYKCallMod	; GetBits in another module
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

	dw	offset cmykcode:VidDrawRect		; rectangle
	dw	offset cmykcode:VidPutString	; char string
	dw	offset cmykcode:CMYKCallMod	; BitBlt in another module
	dw	offset cmykcode:CMYKCallMod	; PutBits in another module
	dw	offset cmykcode:CMYKCallMod	; DrawLine in another module
	dw	offset cmykcode:VidDrawRegion	; draws a region
	dw	offset cmykcode:CMYKCallMod	; PutLine in another module
	dw	offset cmykcode:CMYKCallMod	; Polygon in another module
	dw	0				; ScreenOn in another module
	dw	0				; ScreenOff in another module
	dw	offset cmykcode:CMYKCallMod	; Polyline in another module
	dw	offset cmykcode:CMYKCallMod	; DashLine in another module
	dw	offset cmykcode:CMYKCallMod	; DashFill in another module
	dw	0				; SetPalette elsewhere
	dw	0				; GetPalette elsewhere
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
	fptr	CMYKMisc:VidGetBits	 	; GetBits in another module
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
	fptr	CMYKBlt:VidBitBlt		; BitBlt in another module
	fptr	CMYKBitmap:VidPutBits	  	; PutBits in another module
	fptr	CMYKLine:VidDrawLine		; DrawLine in another module
	fptr	0				; draws a region
	fptr	CMYKPutLine:VidPutLine		; PutLine in another module
	fptr	CMYKLine:VidPolygon		; Polygon in another module
	fptr	0				; ScreenOn in another module
	fptr	0				; ScreenOff in another module
	fptr	CMYKLine:VidPolyline		; Polyline in another module
	fptr	CMYKLine:VidDashLine		; DashLine in another module
	fptr	CMYKLine:VidDashFill		; DashFill in another module
	fptr	0				; SetPalette elsewhere
	fptr	0				; GetPalette elsewhere
.assert ($-moduleTable) eq (VidFunction*2)

;----------------------------------------------------------------------------
;		Video Semaphores
;----------------------------------------------------------------------------

videoSem	Semaphore	<1,0>

