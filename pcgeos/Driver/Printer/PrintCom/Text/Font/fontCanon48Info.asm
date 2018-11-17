COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon 48-jet drivers
FILE:		fontCanon48Info.asm

AUTHOR:		Dave Durran, 21 Aug 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/21/92		Initial revision

DESCRIPTION:
	This file contains the font information for the Canon 48 printers

	Other Printers Supported by this resource:

	$Id: fontCanon48Info.asm,v 1.1 97/04/18 11:49:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource

	word	0		;dummy word to give non-zero offsets.

	; mode info blocks

bj130edraft	label	word
bj130enlq	label	word
                nptr    bj130e_ROMAN12_10CPI
                nptr    bj130e_ROMAN12_5CPI
                nptr    bj130e_ROMAN12_6CPI
                nptr    bj130e_ROMAN12_12CPI
                nptr    bj130e_ROMAN12_17CPI
                nptr    bj130e_ROMAN12_PROP
                nptr    bj130e_SANS12_5CPI
                nptr    bj130e_SANS12_6CPI
                nptr    bj130e_SANS12_10CPI
                nptr    bj130e_SANS12_12CPI
                nptr    bj130e_SANS12_17CPI
                nptr    bj130e_ROMAN12_PROP
                nptr    bj130e_ROMAN24_5CPI
                nptr    bj130e_ROMAN24_6CPI
                nptr    bj130e_ROMAN24_10CPI
                nptr    bj130e_ROMAN24_12CPI
                nptr    bj130e_ROMAN24_PROP
                nptr    bj130e_SANS24_5CPI
                nptr    bj130e_SANS24_6CPI
                nptr    bj130e_SANS24_10CPI
                nptr    bj130e_SANS24_12CPI
                nptr    bj130e_SANS24_PROP
                word    0                       ; table terminator

			;The following fonts are found in the file
			;"fontIBMPPDSInfo.asm" which is included after this
			;one.....
execjetdraft      label   word
execjetnlq        label   word
                nptr    pp239x_ROMAN12_10CPI
                nptr    pp239x_ROMAN12_5CPI
                nptr    pp239x_ROMAN12_6CPI
                nptr    pp239x_ROMAN12_12CPI
                nptr    pp239x_ROMAN12_15CPI
                nptr    pp239x_ROMAN12_17CPI
                nptr    pp239x_ROMAN12_20CPI
                nptr    pp239x_ROMAN12_PROP
                nptr    pp239x_SANS12_5CPI
                nptr    pp239x_SANS12_6CPI
                nptr    pp239x_SANS12_10CPI
                nptr    pp239x_SANS12_12CPI
                nptr    pp239x_SANS12_15CPI
                nptr    pp239x_SANS12_17CPI
                nptr    pp239x_SANS12_20CPI
                nptr    pp239x_SANS12_PROP
                nptr    pp239x_ROMAN24_5CPI
                nptr    pp239x_ROMAN24_6CPI
                nptr    pp239x_ROMAN24_10CPI
                nptr    pp239x_ROMAN24_12CPI
                nptr    pp239x_ROMAN24_PROP
                nptr    pp239x_SANS24_5CPI
                nptr    pp239x_SANS24_6CPI
                nptr    pp239x_SANS24_10CPI
                nptr    pp239x_SANS24_12CPI
                nptr    pp239x_SANS24_PROP
                word    0                       ; table terminator

	; font info blocks

bj130e_ROMAN12_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
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


bj130e_ROMAN12_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
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

bj130e_ROMAN12_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
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

bj130e_ROMAN12_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
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

bj130e_ROMAN12_17CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set17PitchRoman,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				0		;mandatory style bits 
			  >

bj130e_ROMAN12_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
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


bj130e_SANS12_5CPI FontEntry < FID_DTC_URW_SANS,	; 5 pitch draft font
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

bj130e_SANS12_6CPI FontEntry < FID_DTC_URW_SANS,	; 6 pitch draft font
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

bj130e_SANS12_10CPI FontEntry < FID_DTC_URW_SANS,	; 10 pitch draft font
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

bj130e_SANS12_12CPI FontEntry < FID_DTC_URW_SANS,	; 12 pitch draft font
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

bj130e_SANS12_17CPI FontEntry < FID_DTC_URW_SANS,	; 10 pitch draft font
			    12,				; 12 point font
			    TP_17_PITCH,		; 10 pitch font
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_Set17PitchSans,	; control code
							; text style
							;  compatibility bits
				mask PTS_SUBSCRIPT or \
				mask PTS_SUPERSCRIPT or \
				mask PTS_NLQ or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLHEIGHT,
				0		;mandatory style bits 
			  >

bj130e_SANS12_PROP FontEntry < FID_DTC_URW_SANS,	; proport. draft font
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

bj130e_ROMAN24_5CPI FontEntry < FID_DTC_URW_ROMAN,	; 5 pitch draft font
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

bj130e_ROMAN24_6CPI FontEntry < FID_DTC_URW_ROMAN,	; 6 pitch draft font
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

bj130e_ROMAN24_10CPI FontEntry < FID_DTC_URW_ROMAN,	; 10 pitch draft font
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

bj130e_ROMAN24_12CPI FontEntry < FID_DTC_URW_ROMAN,	; 12 pitch draft font
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

bj130e_ROMAN24_PROP FontEntry < FID_DTC_URW_ROMAN,	; proport. draft font
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

bj130e_SANS24_5CPI FontEntry < FID_DTC_URW_SANS,	; 5 pitch draft font
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

bj130e_SANS24_6CPI FontEntry < FID_DTC_URW_SANS,	; 6 pitch draft font
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

bj130e_SANS24_10CPI FontEntry < FID_DTC_URW_SANS,	; 10 pitch draft font
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

bj130e_SANS24_12CPI FontEntry < FID_DTC_URW_SANS,	; 12 pitch draft font
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

bj130e_SANS24_PROP FontEntry < FID_DTC_URW_SANS,	; proport. draft font
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
