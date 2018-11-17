
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Toshiba 24-pin drivers
FILE:		fontToshibaInfo.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/28/92		Initial revision

DESCRIPTION:
	This file contains the font information for the Toshiba 24-pin printers

	Other Printers Supported by this resource:

	$Id: fontToshibaInfo.asm,v 1.1 97/04/18 11:49:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource


	word	0		;dummy word to give non-zero offsets.

	; mode info blocks

p321draft      label   word
                nptr    p321_ROMAN12_10CPI_DRAFT
                nptr    p321_ROMAN12_5CPI_DRAFT
                nptr    p321_ROMAN12_6CPI_DRAFT
                nptr    p321_ROMAN12_12CPI_DRAFT
                nptr    p321_ROMAN12_15CPI_DRAFT
                nptr    p321_ROMAN12_17CPI_DRAFT
                nptr    p321_ROMAN12_PROP
                word    0                       ; table terminator

p321nlq        label   word
                nptr    p321_ROMAN12_10CPI
                nptr    p321_ROMAN12_5CPI
                nptr    p321_ROMAN12_6CPI
                nptr    p321_ROMAN12_12CPI
                nptr    p321_ROMAN12_15CPI
                nptr    p321_ROMAN12_17CPI
                nptr    p321_ROMAN12_PROP
                word    0                       ; table terminator

	; font info blocks

p321_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

p321_ROMAN12_5CPI_DRAFT FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set10PitchDraft,	; control code
							; text style
							;  legal bits
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

p321_ROMAN12_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

p321_ROMAN12_6CPI_DRAFT FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set12PitchDraft,	; control code
							; text style
							;  legal bits
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

p321_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
			    	mask PTS_CONDENSED or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;Mandatory style bits
			  >

p321_ROMAN12_10CPI_DRAFT FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set10PitchDraft,	; control code
							; text style
							;  legal bits
			    	mask PTS_CONDENSED or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;Mandatory style bits
			  >

p321_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;mandatory style bits 
			  >

p321_ROMAN12_12CPI_DRAFT FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set12PitchDraft,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;mandatory style bits 
			  >

p321_ROMAN12_15CPI FontEntry < FID_DTC_URW_ROMAN,	; 15 pitch draft font
			    12,				; 12 point font
			    TP_15_PITCH,		; 15 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set15PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;mandatory style bits 
			  >

p321_ROMAN12_15CPI_DRAFT FontEntry < FID_DTC_URW_ROMAN,	; 15 pitch draft font
			    12,				; 12 point font
			    TP_15_PITCH,		; 15 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set15PitchDraft,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;mandatory style bits 
			  >

p321_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set17PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				0			;mandatory style bits 
			  >

p321_ROMAN12_17CPI_DRAFT FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_Set10PitchDraft,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

p321_ROMAN12_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_ASCII7,		; PrinterCharSet
			    offset pr_codes_SetProportionalRoman, ; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH,
				0			;mandatory style bits 
			  >

printerFontInfo	ends
