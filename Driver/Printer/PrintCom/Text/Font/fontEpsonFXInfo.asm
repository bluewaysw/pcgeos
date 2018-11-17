
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson model 9-pin drivers
FILE:		fontEpsonFXInfo.asm

AUTHOR:		Dave Durran, 1 Aug 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/1/92		Initial revision

DESCRIPTION:
	This file contains the font information for the Epson fx printers

	Other Printers Supported by this resource:

	$Id: fontEpsonFXInfo.asm,v 1.1 97/04/18 11:49:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource


	word	0		;dummy word to give non-zero offsets.

	; mode info blocks

fx80draft      label   word
fx80nlq        label   word
                nptr    fx80_ROMAN12_10CPI
                nptr    fx80_ROMAN12_5CPI
                nptr    fx80_ROMAN12_6CPI
                nptr    fx80_ROMAN12_12CPI
                nptr    fx80_ROMAN12_17CPI
                nptr    fx80_ROMAN12_20CPI
                nptr    fx80_ROMAN12_PROP
                nptr    fx80_ROMAN24_5CPI
                nptr    fx80_ROMAN24_6CPI
                nptr    fx80_ROMAN24_10CPI
                nptr    fx80_ROMAN24_12CPI
                nptr    fx80_ROMAN24_PROP
                word    0                       ; table terminator

fx85draft      label   word
fx85nlq        label   word
                nptr    fx85_ROMAN12_10CPI
                nptr    fx85_ROMAN12_5CPI
                nptr    fx85_ROMAN12_6CPI
                nptr    fx85_ROMAN12_12CPI
                nptr    fx85_ROMAN12_17CPI
                nptr    fx85_ROMAN12_20CPI
                nptr    fx85_ROMAN12_PROP
                nptr    fx85_ROMAN24_5CPI
                nptr    fx85_ROMAN24_6CPI
                nptr    fx85_ROMAN24_10CPI
                nptr    fx85_ROMAN24_12CPI
                nptr    fx85_ROMAN24_PROP
                word    0                       ; table terminator

fx86edraft      label   word
fx86enlq        label   word
                nptr    fx85_ROMAN12_10CPI
                nptr    fx85_ROMAN12_5CPI
                nptr    fx86e_ROMAN12_6CPI
                nptr    fx86e_ROMAN12_12CPI
                nptr    fx85_ROMAN12_17CPI
                nptr    fx86e_ROMAN12_20CPI
                nptr    fx85_ROMAN12_PROP
                nptr    fx86e_SANS12_5CPI
                nptr    fx86e_SANS12_6CPI
                nptr    fx86e_SANS12_10CPI
                nptr    fx86e_SANS12_12CPI
                nptr    fx86e_SANS12_17CPI
                nptr    fx86e_SANS12_20CPI
                nptr    fx86e_SANS12_PROP
                nptr    fx85_ROMAN24_5CPI
                nptr    fx86e_ROMAN24_6CPI
                nptr    fx85_ROMAN24_10CPI
                nptr    fx86e_ROMAN24_12CPI
                nptr    fx85_ROMAN24_PROP
                nptr    fx86e_SANS24_5CPI
                nptr    fx86e_SANS24_6CPI
                nptr    fx86e_SANS24_10CPI
                nptr    fx86e_SANS24_12CPI
                nptr    fx86e_SANS24_PROP
                word    0                       ; table terminator

	; font info blocks

fx80_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
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
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

fx85_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
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

fx80_ROMAN12_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

fx85_ROMAN12_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    12,				; 12 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH	;Mandatory style bits
			  >

fx86e_ROMAN12_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
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

fx80_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
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
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				0			;Mandatory style bits
			  >

fx85_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
			    	mask PTS_CONDENSED or \
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

fx80_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;mandatory style bits 
			  >

fx85_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;mandatory style bits 
			  >

fx86e_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
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

fx80_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
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
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

fx85_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

fx80_ROMAN12_20CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_20_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

fx85_ROMAN12_20CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_20_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

fx86e_ROMAN12_20CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_20_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

fx80_ROMAN12_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalRoman, ; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;mandatory style bits 
			  >

fx85_ROMAN12_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalRoman, ; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
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


fx86e_SANS12_5CPI FontEntry < FID_DTC_URW_SANS,	; 5 pitch draft font
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

fx86e_SANS12_6CPI FontEntry < FID_DTC_URW_SANS,	; 6 pitch draft font
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

fx86e_SANS12_10CPI FontEntry < FID_DTC_URW_SANS,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchSans,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
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

fx86e_SANS12_12CPI FontEntry < FID_DTC_URW_SANS,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchSans,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
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

fx86e_SANS12_17CPI FontEntry < FID_DTC_URW_SANS,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchSans,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

fx86e_SANS12_20CPI FontEntry < FID_DTC_URW_SANS,	; 12 pitch draft font
			    12,				; 12 point font
			    TP_20_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchSans,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				mask PTS_CONDENSED	;mandatory style bits 
			  >

fx86e_SANS12_PROP FontEntry < FID_DTC_URW_SANS,	; proport. draft font
			    12,				; 12 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalSans, ; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
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

fx80_ROMAN24_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
			    24,				; 24 point font
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
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT	;Mandatory style bits
			  >

fx85_ROMAN24_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
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

fx80_ROMAN24_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    24,				; 24 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT	;Mandatory style bits
			  >

fx85_ROMAN24_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
			    24,				; 24 point font
			    TP_6_PITCH,			; 6 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  legal bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT	;Mandatory style bits
			  >

fx86e_ROMAN24_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
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

fx80_ROMAN24_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    24,				; 24 point font
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
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT, 
				mask PTS_DBLHEIGHT	;Mandatory style bits
			  >

fx85_ROMAN24_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    24,				; 24 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchRoman,	; control code
							; text style
							;  legal bits
			    	mask PTS_CONDENSED or \
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

fx80_ROMAN24_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    24,				; 24 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				mask PTS_DBLHEIGHT	;mandatory style bits 
			  >

fx85_ROMAN24_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    24,				; 24 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				mask PTS_DBLHEIGHT	;mandatory style bits 
			  >

fx86e_ROMAN24_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
			    24,				; 24 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchRoman,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
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

fx80_ROMAN24_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
			    24,				; 24 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalRoman, ; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT	;mandatory style bits 
			  >

fx85_ROMAN24_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
			    24,				; 24 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalRoman, ; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
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

fx86e_SANS24_5CPI FontEntry < FID_DTC_URW_SANS,	; 5 pitch draft font
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

fx86e_SANS24_6CPI FontEntry < FID_DTC_URW_SANS,	; 6 pitch draft font
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

fx86e_SANS24_10CPI FontEntry < FID_DTC_URW_SANS,	; 10 pitch draft font
			    24,				; 24 point font
			    TP_10_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set10PitchSans,	; control code
							; text style
							;  legal bits
			    	mask PTS_CONDENSED or \
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

fx86e_SANS24_12CPI FontEntry < FID_DTC_URW_SANS,	; 12 pitch draft font
			    24,				; 24 point font
			    TP_12_PITCH,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set12PitchSans,	; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
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

fx86e_SANS24_PROP FontEntry < FID_DTC_URW_SANS,	; proport. draft font
			    24,				; 24 point font
			    TP_PROPORTIONAL,		; 12 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetProportionalSans, ; control code
							; text style
							;  compatibility bits
			    	mask PTS_CONDENSED or \
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
