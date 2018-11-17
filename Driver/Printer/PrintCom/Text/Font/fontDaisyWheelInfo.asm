
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		DaisyWheel drivers
FILE:		fontDaisyWheelInfo.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/28/92		Initial revision

DESCRIPTION:
	This file contains the font information for the DaisyWheel printers

	Other Printers Supported by this resource:

	$Id: fontDaisyWheelInfo.asm,v 1.1 97/04/18 11:49:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource


	word	0		;dummy word to give non-zero offsets.

	; mode info blocks


d630nlq        label   word
                nptr    d630_ROMAN12_10CPI
                nptr    d630_ROMAN12_12CPI
                nptr    d630_ROMAN12_15CPI
                nptr    d630_ROMAN12_17CPI
                nptr    d630_ROMAN12_PROP
                word    0                       ; table terminator

	; font info blocks

d630_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				0			;Mandatory style bits
			  >

d630_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE, 
				0			;mandatory style bits 
			  >

d630_ROMAN12_15CPI FontEntry < FID_DTC_URW_ROMAN,	; 15 pitch draft font
			    12,				; 12 point font
			    TP_15_PITCH,		; 15 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set15PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE, 
				0			;mandatory style bits 
			  >

d630_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 17 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 17 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set17PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE, 
				0			;mandatory style bits 
			  >

d630_ROMAN12_PROP FontEntry < FID_DTC_URW_ROMAN,	; proportional font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; proportional font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_SetProportionalRoman, ; control code
							; text style
							;  compatibility bits
			    	mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE, 
				0			;mandatory style bits 
			  >

printerFontInfo	ends
