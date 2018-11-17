
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Star 9-pin drivers
FILE:		fontStarInfo.asm

AUTHOR:		Dave Durran, 1 Aug 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/1/92		Initial revision

DESCRIPTION:
	This file contains the font information for the Star 9 pin printers

	Other Printers Supported by this resource:

	$Id: fontStarInfo.asm,v 1.1 97/04/18 11:49:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource


	word	0		;dummy word to give non-zero offsets.

	; mode info blocks

starnlq        label   word
                nptr    star_ROMAN12_10CPI
                word    0                       ; table terminator

stardraft      label   word
                nptr    star_ROMAN12_10CPI
                nptr    star_ROMAN12_5CPI
                nptr    star_ROMAN12_6CPI
                nptr    star_ROMAN12_12CPI
                nptr    star_ROMAN12_17CPI
                nptr    star_ROMAN12_PROP
                word    0                       ; table terminator

	; font info blocks

star_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set10Pitch,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

star_ROMAN12_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set12Pitch,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

star_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set10Pitch,	; control code
							; text style
							;  legal bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;Mandatory style bits
			  >

star_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set12Pitch,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;mandatory style bits 
			  >

star_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set17Pitch,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

star_ROMAN12_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_SetProportional, ; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;mandatory style bits 
			  >

printerFontInfo	ends
