
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon CaPSL drivers
FILE:		fontCapslInfo.asm

AUTHOR:		Dave Durran, 1 Aug 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/27/92		Initial revision

DESCRIPTION:
	This file contains the font information for the Canon CaPSL printers

	Other Printers Supported by this resource:

	$Id: fontCapslInfo.asm,v 1.1 97/04/18 11:49:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerFontInfo	segment	resource


	word	0		;dummy word to give non-zero offsets.

	; mode info blocks

capsl2nlq        label   word
                nptr    capsl2_ROMAN
                nptr    capsl2_MONO
                nptr    capsl2_SANS
                word    0                       ; table terminator

capsl3nlq        label   word
                nptr    capsl3_ROMAN
                nptr    capsl3_MONO
                nptr    capsl3_SANS
                word    0                       ; table terminator

	; font info blocks

capsl2_ROMAN	FontEntry < FID_DTC_URW_ROMAN,		; PC/GEOS FontID
			    NULL,			; PtSze place holder
			    NULL,			; Pitch place holder
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetDutch,	; control code
							; text style
							;  legal bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;Mandatory style bits
			  >

capsl3_ROMAN	FontEntry < FID_DTC_URW_ROMAN,		; PC/GEOS FontID
			    NULL,			; PtSze place holder
			    NULL,			; Pitch place holder
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetDutch,	; control code
							; text style
							;  legal bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_SHADOW or \
				mask PTS_OUTLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;Mandatory style bits
			  >

capsl2_MONO	FontEntry < FID_DTC_URW_MONO,		; PC/GEOS FontID
			    NULL,			; PtSze place holder
			    NULL,			; Pitch place holder
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetCourier,	; control code
							; text style
							;  legal bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;Mandatory style bits
			  >

capsl3_MONO	FontEntry < FID_DTC_URW_MONO,		; PC/GEOS FontID
			    NULL,			; PtSze place holder
			    NULL,			; Pitch place holder
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetCourier,	; control code
							; text style
							;  legal bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_SHADOW or \
				mask PTS_OUTLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;Mandatory style bits
			  >

capsl2_SANS	FontEntry < FID_DTC_URW_SANS,		; PC/GEOS FontID
			    NULL,			; PtSze place holder
			    NULL,			; Pitch place holder
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetSwiss,	; control code
							; text style
							;  legal bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;Mandatory style bits
			  >

capsl3_SANS	FontEntry < FID_DTC_URW_SANS,		; PC/GEOS FontID
			    NULL,			; PtSze place holder
			    NULL,			; Pitch place holder
			    PSS_IBM437,		; PrinterCharSet
			    offset pr_codes_SetSwiss,	; control code
							; text style
							;  legal bits
				mask PTS_NLQ or \
				mask PTS_BOLD or \
				mask PTS_ITALIC or \
				mask PTS_UNDERLINE or \
				mask PTS_SHADOW or \
				mask PTS_OUTLINE or \
				mask PTS_DBLWIDTH or \
				mask PTS_DBLHEIGHT,
				0			;Mandatory style bits
			  >

printerFontInfo	ends
