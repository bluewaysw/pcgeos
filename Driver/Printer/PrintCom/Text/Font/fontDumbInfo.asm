
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dumb ASCII (Unformatted) Print Driver
FILE:		fontDumbInfo.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        Dave    8/30/93         Initial Revision

DESCRIPTION:
	This file contains the font information for the DaisyWheel printers

	Other Printers Supported by this resource:

	$Id: fontDumbInfo.asm,v 1.1 97/04/18 11:49:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource


	word	0		;dummy word to give non-zero offsets.

	; mode info blocks


dumbnlq        label   word
                nptr    dumb_ROMAN12_10CPI
                nptr    dumb_ROMAN12_PROP
                word    0                       ; table terminator

	; font info blocks

dumb_ROMAN12_PROP label	byte
dumb_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
				0,			;  legal bits
				0			;Mandatory style bits
			  >

printerFontInfo	ends
