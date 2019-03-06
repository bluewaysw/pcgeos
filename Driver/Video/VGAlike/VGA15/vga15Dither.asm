COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Driver
FILE:           vga16Dither.asm

AUTHOR:		Jim DeFrisco, Oct 19, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/19/92	Initial revision
        FR       9/ 5/97        Initial 16-bit version        


DESCRIPTION:
        Tables to generate dither matrices for 16-bit devices


        $Id: vga16Dither.asm,v 1.2 96/08/05 03:51:52 canavese Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		; We are implementing a 4x4 matrix for dithering purposes.  
		; The ditherCutoff table takes the output of the ditherMod 
		; table and the (x,y) position of the pixel to determine 
		; the 16 indices that inhabit the dither matrix.  So, instead
		; of a single equation for the index (as shown above), we
		; actually have 16 separate equations, one for each spot in
		; the ditherMatrix. 
ditherCutoff	label	byte
		byte	0x00, 0x1a, 0x06, 0x20
		byte	0x27, 0x0d, 0x2d, 0x13
		byte	0x09, 0x23, 0x03, 0x1d
		byte	0x30, 0x16, 0x2a, 0x10
