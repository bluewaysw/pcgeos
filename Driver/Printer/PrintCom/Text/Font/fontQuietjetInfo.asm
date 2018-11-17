
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		HP Quietjet drivers
FILE:		fontQuietjetInfo.asm

AUTHOR:		Dave Durran, 1 Aug 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	9/1/92		Initial revision

DESCRIPTION:
	This file contains the font information for the HP Quietjet printers

	Other Printers Supported by this resource:

	$Id: fontQuietjetInfo.asm,v 1.1 97/04/18 11:49:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource


	word	0		;dummy word to give non-zero offsets.

	; mode info blocks

qjetdraft      label   word
qjetnlq        label   word
                nptr    qjet_ROMAN12_10CPI
                nptr    qjet_ROMAN12_5CPI
                nptr    qjet_ROMAN12_6CPI
                nptr    qjet_ROMAN12_106CPI
                nptr    qjet_ROMAN12_12CPI
                nptr    qjet_ROMAN12_213CPI
                nptr    qjet_ROMAN12_PROP
                word    0                       ; table terminator

	; font info blocks

qjet_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_ROMAN8,		; PrinterCharSet
			    offset pr_codes_Set5PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				0			;Mandatory style bits
			  >

qjet_ROMAN12_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_ROMAN8,		; PrinterCharSet
			    offset pr_codes_Set6PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				0			;Mandatory style bits
			  >

qjet_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_ROMAN8,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				0			;Mandatory style bits
			  >

qjet_ROMAN12_106CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_6_PITCH,		; 10.6 pitch font
			    PSS_ROMAN8,		; PrinterCharSet
			    offset pr_codes_Set106PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				0			;Mandatory style bits
			  >

qjet_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_ROMAN8,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				0			;Mandatory style bits
			  >

qjet_ROMAN12_213CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_21_3_PITCH,		; 10 pitch font
			    PSS_ROMAN8,		; PrinterCharSet
			    offset pr_codes_Set213PitchRoman,	; control code
							; text style
							;  compatibility bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				0			;Mandatory style bits
			  >

qjet_ROMAN12_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_ROMAN8,		; PrinterCharSet
			    offset pr_codes_SetProportionalRoman, ; control code
							; text style
							;  compatibility bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE,
				0			;Mandatory style bits
			  >


printerFontInfo	ends
