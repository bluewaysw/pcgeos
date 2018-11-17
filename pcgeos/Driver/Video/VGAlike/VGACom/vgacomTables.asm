COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VGA video drivers	
FILE:		vgacomTables.asm

AUTHOR:		Jim DeFrisco, Feb 20, 1992

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/20/92		Initial revision


DESCRIPTION:
	various tables common to all VGAlike drivers	
		

	$Id: vgacomTables.asm,v 1.1 97/04/18 11:42:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

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

		nptr	offset PutBWScanMask		; BMF_MONO   yes   no
		nptr	offset PutColorScan		; BMF_CLR4   yes   no
		nptr	offset NullBMScan		; BMF_CLR8   yes   no
		nptr	offset NullBMScan		; BMF_CLR24  yes   no
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
		nptr	offset PutColorScan		; BMF_CLR4   yes   no
		nptr	offset NullBMScan		; BMF_CLR8   yes   no
		nptr	offset NullBMScan		; BMF_CLR24  yes   no
		nptr	offset NullBMScan		; BMF_CMYK   yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no
		nptr	offset NullBMScan		; UNUSED     yes   no

		nptr	offset FillBWScan 		; BMF_MONO   yes   yes
		nptr	offset FillBWScan		; BMF_CLR4   yes   yes
		nptr	offset FillBWScan		; BMF_CLR8   yes   yes
		nptr	offset FillBWScan		; BMF_CLR24  yes   yes
		nptr	offset FillBWScan		; BMF_CMYK   yes   yes

VidEnds		PutLine

