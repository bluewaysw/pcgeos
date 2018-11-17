
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson model 9-pin drivers
FILE:		fontEpsonMXInfo.asm

AUTHOR:		Dave Durran, 21 Aug 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/21/92		Initial revision

DESCRIPTION:
	This file contains the font information for the Epson mx printers

	Other Printers Supported by this resource:

	$Id: fontEpsonMXInfo.asm,v 1.1 97/04/18 11:49:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource


	word	0		;dummy word to give non-zero offsets.

	; mode info blocks

mx80draft      label   word
mx80nlq        label   word
                nptr    mx80_ROMAN12_10CPI
                nptr    mx80_ROMAN12_5CPI
                nptr    mx80_ROMAN12_12CPI
                nptr    mx80_ROMAN12_17CPI
                nptr    mx80_ROMAN12_PROP
                word    0                       ; table terminator

rx80draft      label   word
rx80nlq        label   word
                nptr    mx80_ROMAN12_10CPI
                nptr    mx80_ROMAN12_5CPI
                nptr    rx80_ROMAN12_6CPI
                nptr    mx80_ROMAN12_12CPI
                nptr    mx80_ROMAN12_17CPI
                nptr    mx80_ROMAN12_PROP
                word    0                       ; table terminator

	; font info blocks

mx80_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

rx80_ROMAN12_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 5 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

mx80_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;Mandatory style bits
			  >

mx80_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;mandatory style bits 
			  >

mx80_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

mx80_ROMAN12_PROP FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalRoman, ;control code
							; text style
							;  legal bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;Mandatory style bits
			  >

printerFontInfo	ends
