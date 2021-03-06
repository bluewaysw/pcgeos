
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson Escape P2 24-pin driver
FILE:		escp2generInfo.asm

AUTHOR:		Dave Durran, 27 Mar 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision

DESCRIPTION:
	This file contains the device information for the Epson gener printer

	Other Printers Supported by this resource:

	$Id: escp2generInfo.asm,v 1.1 97/04/18 11:54:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Epson gener
;----------------------------------------------------------------------------

generInfo	segment	resource

	; info blocks

generInfoStruc	PrinterInfo < < 0,PC_MONO,PT_RASTER>,; PrinterType 
			      < 0,0,1,1,0,0 >,	; PrinterConnection: 
			      PS_DUMB_RASTER, 	; PrinterSmarts
						; Mode Info Offsets
			      offset generlowRes, 	; PM_GRAPHICS_LOW_RES
			      offset generhiRes,	; PM_GRAPHICS_MED_RES
			      offset genershiRes,	; PM_GRAPHICS_HI_RES
			      offset generdraft,	; PM_TEXT_DRAFT
			      offset genernlq,		; PM_TEXT_NLQ
						; Paper Margins
			      PR_MARGIN_LEFT,	; left/top margin
			      PR_MARGIN_TOP,	
			      PR_MARGIN_RIGHT,	; right/bottom margin
			      PR_MARGIN_BOTTOM,	
			      < 0,PS_NORMAL,1,1,0 >, ; PrinterFeedOptions
			      PS_LEGAL,		; largest paper accepted.
			    >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

generlowRes	GraphicsProperties < LO_RES_X_RES,	; xres
				     LO_RES_Y_RES,	; yres
				     LO_RES_BAND_HEIGHT,  ; band height
				     LO_RES_BYTES_COLUMN, ; bytes/column.
				     BMF_MONO >		; color format

generhiRes	GraphicsProperties < HI_RES_X_RES,	; xres
				     HI_RES_Y_RES,	; yres
				     HI_RES_BAND_HEIGHT,  ; band height
				     HI_RES_BYTES_COLUMN, ; bytes/column.
				     BMF_MONO >		; color format

genershiRes	GraphicsProperties < SHI_RES_X_RES,	; xres
				     SHI_RES_Y_RES,	; yres
				     SHI_RES_BAND_HEIGHT,  ; band height
				     SHI_RES_BYTES_COLUMN, ; bytes/column.
				     BMF_MONO >		; color format

;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

generdraft	label	word
genernlq	label	word
		nptr	gener_10CPI
		nptr	gener_12CPI
		nptr	gener_15CPI
		nptr	gener_17CPI
		nptr	gener_PROP
		word	0			; table terminator


;----------------------------------------------------------------------------
;	Font Structures
;----------------------------------------------------------------------------

gener_10CPI	FontEntry < FONT_PRINTER_10CPI,		; 10 pitch draft font
			    12,				; 12 point font
			    < FU_NOT_USEFUL,		; "useful" bit, unused.
			      FP_FIXED,			; non-proportional.
			      FO_NORMAL,		; orientation
			      FS_BITMAP,		; bitmap font
			      FF_MONO >,		; font family
			    TP_10_PITCH,		; 10 pitch font
			    PCS_IBM8BIT,		; PrinterCharSet
							; text style
							;  compatibility bits
			    < 1111111000011000b,	; condensed
			      1111111000011000b,	; subscript
			      1111111000011000b,	; superscript
			      1111111000011000b,	; NLQ
			      1111111000011000b,	; bold
			      1111111000011000b,	; italic
			      1111111000011000b,	; underline
			      1111111000011000b,	; strikethru
			      1111111000011000b,	; shadow
			      1111111000011000b,	; outline
			      1111111000011000b,	; reverse
			      1111111000011000b,	; dblwidth
			      1111111000011000b,	; dblheight
			      1111111000011000b,	; quadheight
			      1111111000011000b,	; future 2
			      1111111000011000b >	; future 1


			;     CSSNBIUSSORDDQFF
			;     OUULOTNTHUEBBUUU
			;     NBPQLADRATVLLATT
			;     DSE DLEIDLEWHDUU
			;     ECR  IRKOIRIEHRR
			;     NRS  CLEWNSDIEEE
			;     SIC   IT EETGI  
			;     EPR   NH   HHG21
			;     DTI   ER    TH
			;       P    U     T
			;       T
			  >

gener_12CPI	FontEntry < FONT_PRINTER_12CPI,		; 12 pitch draft font
			    12,				; 12 point font
			    < FU_NOT_USEFUL,		; "useful" bit, unused.
			      FP_FIXED,			; non-proportional.
			      FO_NORMAL,		; orientation
			      FS_BITMAP,		; bitmap font
			      FF_MONO >,		; font family
			    TP_12_PITCH,		; 12 pitch font
			    PCS_IBM8BIT,		; PrinterCharSet
							; text style
							;  compatibility bits
			    < 1111111000011000b,	; condensed
			      1111111000011000b,	; subscript
			      1111111000011000b,	; superscript
			      1111111000011000b,	; NLQ
			      1111111000011000b,	; bold
			      1111111000011000b,	; italic
			      1111111000011000b,	; underline
			      1111111000011000b,	; strikethru
			      1111111000011000b,	; shadow
			      1111111000011000b,	; outline
			      1111111000011000b,	; reverse
			      1111111000011000b,	; dblwidth
			      1111111000011000b,	; dblheight
			      1111111000011000b,	; quadheight
			      1111111000011000b,	; future 2
			      1111111000011000b >	; future 1


			;     CSSNBIUSSORDDQFF
			;     OUULOTNTHUEBBUUU
			;     NBPQLADRATVLLATT
			;     DSE DLEIDLEWHDUU
			;     ECR  IRKOIRIEHRR
			;     NRS  CLEWNSDIEEE
			;     SIC   IT EETGI  
			;     EPR   NH   HHG21
			;     DTI   ER    TH
			;       P    U     T
			;       T
			  >

gener_15CPI	FontEntry < FONT_PRINTER_15CPI,		; 15 pitch draft font
			    12,				; 12 point font
			    < FU_NOT_USEFUL,		; "useful" bit, unused.
			      FP_FIXED,			; non-proportional.
			      FO_NORMAL,		; orientation
			      FS_BITMAP,		; bitmap font
			      FF_MONO >,		; font family
			    TP_15_PITCH,		; 15 pitch font
			    PCS_IBM8BIT,		; PrinterCharSet
							; text style
							;  compatibility bits
			    < 0111111000011000b,	; condensed
			      0111111000011000b,	; subscript
			      0111111000011000b,	; superscript
			      0111111000011000b,	; NLQ
			      0111111000011000b,	; bold
			      0111111000011000b,	; italic
			      0111111000011000b,	; underline
			      0111111000011000b,	; strikethru
			      0111111000011000b,	; shadow
			      0111111000011000b,	; outline
			      0111111000011000b,	; reverse
			      0111111000011000b,	; dblwidth
			      0111111000011000b,	; dblheight
			      0111111000011000b,	; quadheight
			      0111111000011000b,	; future 2
			      0111111000011000b >	; future 1


			;     CSSNBIUSSORDDQFF
			;     OUULOTNTHUEBBUUU
			;     NBPQLADRATVLLATT
			;     DSE DLEIDLEWHDUU
			;     ECR  IRKOIRIEHRR
			;     NRS  CLEWNSDIEEE
			;     SIC   IT EETGI  
			;     EPR   NH   HHG21
			;     DTI   ER    TH
			;       P    U     T
			;       T
			  >

gener_17CPI	FontEntry < FONT_PRINTER_17CPI,		; 10 pitch draft font
			    12,				; 12 point font
			    < FU_NOT_USEFUL,		; "useful" bit, unused.
			      FP_FIXED,			; non-proportional.
			      FO_NORMAL,		; orientation
			      FS_BITMAP,		; bitmap font
			      FF_MONO >,		; font family
			    TP_17_PITCH,		; 10 pitch font
			    PCS_IBM8BIT,		; PrinterCharSet
							; text style
							;  compatibility bits
			    < 1111111000011000b,	; condensed
			      1111111000011000b,	; subscript
			      1111111000011000b,	; superscript
			      1111111000011000b,	; NLQ
			      1111111000011000b,	; bold
			      1111111000011000b,	; italic
			      1111111000011000b,	; underline
			      1111111000011000b,	; strikethru
			      1111111000011000b,	; shadow
			      1111111000011000b,	; outline
			      1111111000011000b,	; reverse
			      1111111000011000b,	; dblwidth
			      1111111000011000b,	; dblheight
			      1111111000011000b,	; quadheight
			      1111111000011000b,	; future 2
			      1111111000011000b >	; future 1


			;     CSSNBIUSSORDDQFF
			;     OUULOTNTHUEBBUUU
			;     NBPQLADRATVLLATT
			;     DSE DLEIDLEWHDUU
			;     ECR  IRKOIRIEHRR
			;     NRS  CLEWNSDIEEE
			;     SIC   IT EETGI  
			;     EPR   NH   HHG21
			;     DTI   ER    TH
			;       P    U     T
			;       T
			  >

gener_PROP	FontEntry < FONT_PRINTER_PROP_SERIF,	; proport. draft font
			    12,				; 12 point font
			    < FU_NOT_USEFUL,		; "useful" bit, unused.
			      FP_PROPORTIONAL,			; proportional.
			      FO_NORMAL,		; orientation
			      FS_BITMAP,		; bitmap font
			      FF_SERIF >,		; font family
			    TP_PROPORTIONAL,		; 12 pitch font
			    PCS_IBM8BIT,		; PrinterCharSet
							; text style
							;  compatibility bits
			    < 1111111000011000b,	; condensed
			      1111111000011000b,	; subscript
			      1111111000011000b,	; superscript
			      1111111000011000b,	; NLQ
			      1111111000011000b,	; bold
			      1111111000011000b,	; italic
			      1111111000011000b,	; underline
			      1111111000011000b,	; strikethru
			      1111111000011000b,	; shadow
			      1111111000011000b,	; outline
			      1111111000011000b,	; reverse
			      1111111000011000b,	; dblwidth
			      1111111000011000b,	; dblheight
			      1111111000011000b,	; quadheight
			      1111111000011000b,	; future 2
			      1111111000011000b >	; future 1


			;     CSSNBIUSSORDDQFF
			;     OUULOTNTHUEBBUUU
			;     NBPQLADRATVLLATT
			;     DSE DLEIDLEWHDUU
			;     ECR  IRKOIRIEHRR
			;     NRS  CLEWNSDIEEE
			;     SIC   IT EETGI  
			;     EPR   NH   HHG21
			;     DTI   ER    TH
			;       P    U     T
			;       T
			  >


generInfo	ends
