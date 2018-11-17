
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Proprinter type 24-pin drivers
FILE:		fontIBM24Info.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/1/92		Initial revision

DESCRIPTION:
	This file contains the font information for the IBM Proprinter printers

	Other Printers Supported by this resource:

	$Id: fontIBM24Info.asm,v 1.1 97/04/18 11:49:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource


	word	0		;dummy word to give non-zero offsets.

	; mode info blocks

x24draft      label   word
                nptr    x24_ROMAN12_10CPI
                nptr    x24_ROMAN12_5CPI
                nptr    x24_ROMAN12_6CPI
                nptr    x24_ROMAN12_12CPI
                nptr    x24_ROMAN12_17CPI
                word    0                       ; table terminator

x24nlq        label   word
                nptr    x24_ROMAN12_10CPI_NLQ
                nptr    x24_ROMAN12_5CPI_NLQ
                nptr    x24_ROMAN12_6CPI_NLQ
                nptr    x24_ROMAN12_12CPI_NLQ
                nptr    x24_ROMAN12_17CPI_NLQ
                nptr    x24_ROMAN12_PROP_NLQ
                word    0                       ; table terminator

ps1draft      label   word
ps1nlq        label   word
                nptr    ps1_ROMAN12_10CPI
                nptr    ps1_ROMAN12_5CPI
                nptr    ps1_ROMAN12_6CPI
                nptr    ps1_ROMAN12_12CPI
                nptr    ps1_ROMAN12_15CPI
                nptr    ps1_ROMAN12_17CPI
                nptr    ps1_ROMAN12_20CPI
                nptr    ps1_ROMAN12_24CPI
                nptr    ps1_ROMAN12_PROP
                nptr    ps1_SANS12_5CPI
                nptr    ps1_SANS12_6CPI
                nptr    ps1_SANS12_10CPI
                nptr    ps1_SANS12_12CPI
                nptr    ps1_SANS12_15CPI
                nptr    ps1_SANS12_17CPI
                nptr    ps1_SANS12_20CPI
                nptr    ps1_SANS12_24CPI
                nptr    ps1_SANS12_PROP
                nptr    ps1_ROMAN24_5CPI
                nptr    ps1_ROMAN24_6CPI
                nptr    ps1_ROMAN24_10CPI
                nptr    ps1_ROMAN24_12CPI
                nptr    ps1_ROMAN24_PROP
                nptr    ps1_SANS24_5CPI
                nptr    ps1_SANS24_6CPI
                nptr    ps1_SANS24_10CPI
                nptr    ps1_SANS24_12CPI
                nptr    ps1_SANS24_PROP
                word    0                       ; table terminator

	; font info blocks

		;5 pitch couriers
x24_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchCourierDraft, ;control
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
x24_ROMAN12_5CPI_NLQ FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchCourierNLQ, ;control
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

		;6 pitch couriers.
x24_ROMAN12_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchCourierDraft, ;control
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
x24_ROMAN12_6CPI_NLQ FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchCourierNLQ, ;control
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

		;10-pitch couriers
x24_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchCourierDraft, ;control
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

x24_ROMAN12_10CPI_NLQ FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchCourierNLQ, ;control code
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

		;12 pitch couriers
x24_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchCourierDraft, ;control
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

x24_ROMAN12_12CPI_NLQ FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchCourierNLQ, ;control code
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

		;17 pitch couriers
x24_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set17PitchCourierDraft, ;control
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_OVERLINE,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

x24_ROMAN12_17CPI_NLQ FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set17PitchCourierNLQ, ;control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_UNDERLINE or \
				mask PTS_OVERLINE,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

		;proportional romans 
x24_ROMAN12_PROP_NLQ FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalRomanNLQ, ;control
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_UNDERLINE or \
				mask PTS_OVERLINE,
				mask PTS_CONDENSED	;mandatory style bits 
			  >



ps1_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >


ps1_ROMAN12_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

ps1_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				0			;Mandatory style bits
			  >

ps1_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;mandatory style bits 
			  >

ps1_ROMAN12_15CPI FontEntry < FID_DTC_URW_ROMAN,	; 15 pitch draft font
			    12,				; 12 point font
			    TP_15_PITCH,		; 15 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set15PitchRoman,	; control code
							; text style
							;  compatibility bits
			      	mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;mandatory style bits 
			  >

ps1_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set17PitchRoman,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				0		;mandatory style bits 
			  >

ps1_ROMAN12_20CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_20_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set20PitchRoman,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				0		;mandatory style bits 
			  >

ps1_ROMAN12_24CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_24_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set24PitchRoman,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				0		;mandatory style bits 
			  >

ps1_ROMAN12_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalRoman, ; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;mandatory style bits 
			  >


ps1_SANS12_5CPI FontEntry < FID_DTC_URW_SANS,	; 5 pitch draft font
			    12,				; 12 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchSans,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

ps1_SANS12_6CPI FontEntry < FID_DTC_URW_SANS,	; 6 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchSans,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

ps1_SANS12_10CPI FontEntry < FID_DTC_URW_SANS,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchSans,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;mandatory style bits 
			  >

ps1_SANS12_12CPI FontEntry < FID_DTC_URW_SANS,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchSans,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;mandatory style bits 
			  >

ps1_SANS12_15CPI FontEntry < FID_DTC_URW_SANS,	; 15 pitch draft font
			    12,				; 12 point font
			    TP_15_PITCH,		; 15 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set15PitchSans,	; control code
							; text style
							;  compatibility bits
			      	mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;mandatory style bits 
			  >

ps1_SANS12_17CPI FontEntry < FID_DTC_URW_SANS,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set17PitchSans,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				0		;mandatory style bits 
			  >

ps1_SANS12_20CPI FontEntry < FID_DTC_URW_SANS,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_20_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set20PitchSans,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				0		;mandatory style bits 
			  >

ps1_SANS12_24CPI FontEntry < FID_DTC_URW_SANS,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_24_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set24PitchSans,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				0		;mandatory style bits 
			  >

ps1_SANS12_PROP FontEntry < FID_DTC_URW_SANS,	; proport. draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalSans, ; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;mandatory style bits 
			  >

ps1_ROMAN24_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    24,				; 24 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT	;Mandatory style bits
			  >

ps1_ROMAN24_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    24,				; 24 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT	;Mandatory style bits
			  >

ps1_ROMAN24_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    24,				; 24 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLHEIGHT	;Mandatory style bits
			  >

ps1_ROMAN24_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    24,				; 24 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				mask PTS_DBLHEIGHT	;mandatory style bits 
			  >

ps1_ROMAN24_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
			    24,				; 24 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalRoman, ; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT	;mandatory style bits 
			  >

ps1_SANS24_5CPI FontEntry < FID_DTC_URW_SANS,	; 5 pitch draft font
			    24,				; 24 point font
			    TP_5_PITCH,			; 5 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchSans,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT	;Mandatory style bits
			  >

ps1_SANS24_6CPI FontEntry < FID_DTC_URW_SANS,	; 6 pitch draft font
			    24,				; 24 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchSans,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT	;Mandatory style bits
			  >

ps1_SANS24_10CPI FontEntry < FID_DTC_URW_SANS,	; 10 pitch draft font
			    24,				; 24 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchSans,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLHEIGHT	;Mandatory style bits
			  >

ps1_SANS24_12CPI FontEntry < FID_DTC_URW_SANS,	; 12 pitch draft font
			    24,				; 24 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchSans,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				mask PTS_DBLHEIGHT	;mandatory style bits 
			  >

ps1_SANS24_PROP FontEntry < FID_DTC_URW_SANS,	; proport. draft font
			    24,				; 24 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalSans, ; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT	;mandatory style bits 
			  >

printerFontInfo	ends
