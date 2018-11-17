
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Graphics type 9-pin drivers
FILE:		fontIBMGrprInfo.asm

AUTHOR:		Dave Durran, 1 Aug 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/93		Initial revision

DESCRIPTION:
	This file contains the font information for the IBM Graphics printers

	Other Printers Supported by this resource:

	$Id: fontIBMGrprInfo.asm,v 1.1 97/04/18 11:49:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource


	word	0		;dummy word to give non-zero offsets.

	; mode info blocks

grprdraft      label   word
grprnlq        label   word
                nptr    grpr_ROMAN12_10CPI
                nptr    grpr_ROMAN12_5CPI
                nptr    grpr_ROMAN12_17CPI
                word    0                       ; table terminator

pp1draft      label   word
pp1nlq        label   word
                nptr    pp1_ROMAN12_10CPI
                nptr    pp1_ROMAN12_5CPI
                nptr    pp1_ROMAN12_12CPI
                nptr    pp1_ROMAN12_17CPI
                nptr    pp1_ROMAN12_PROP
                word    0                       ; table terminator


	; font info blocks

grpr_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10Pitch,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_DBLWIDTH or \
				mask PTS_OVERLINE,
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

pp1_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10Pitch,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_OVERLINE,
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

grpr_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10Pitch,	; control code
							; text style
							;  legal bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_DBLWIDTH or \
				mask PTS_OVERLINE, 
				0			;Mandatory style bits
			  >

pp1_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10Pitch,	; control code
							; text style
							;  legal bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_OVERLINE, 
				0			;Mandatory style bits
			  >

pp1_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12Pitch,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_OVERLINE,
				0			;mandatory style bits 
			  >

grpr_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10Pitch,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_OVERLINE,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

pp1_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10Pitch,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_UNDERLINE or \
				mask PTS_OVERLINE,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

pp1_ROMAN12_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportional, ; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_OVERLINE,
				0			;mandatory style bits 
			  >



printerFontInfo	ends
