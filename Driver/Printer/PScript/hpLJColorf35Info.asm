
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript driver
FILE:		hpLJColorf35Info.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	12/15/94	Initial revision parsed from ibm4079f35Info.asm

DESCRIPTION:
	This file contains the device information for the PostScript printer:

	HP Color LaserJet


	Other Printers Supported by this resource:

	$Id: hpLJColorf35Info.asm,v 1.1 97/04/18 11:56:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;		IBM Color JetPrinter PS 4079
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hpLJColorf35Info	segment	resource

	; info blocks

			PrinterInfo <	; ---- PrinterType -------------
				< PT_RASTER, BMF_4CMYK>,
					; ---- PrinterConnections ------
				< IC_NO_IEEE488,
				CC_NO_CUSTOM,
				SC_SCSI,
				RC_RS232C,
				CC_CENTRONICS,
				FC_FILE,
				AC_APPLETALK >,
					; ---- PrinterSmarts -----------
				PS_PDL,	
					;-------Custom Entry Routine-------
				NULL,
					;-------Custom Exit Routine-------
				NULL,		
					; ---- Mode Info Offsets -------
				NULL,
				NULL,
				offset hpLJColorf35hires,
				NULL,	
				NULL,
                                        ; ---- Font Geometry -----------
                                NULL,
                                        ; ---- Symbol Set list -----------
                                NULL,
					; ---- PaperMargins ------------
				< PR_MARGIN_LEFT,	; Tractor Margins
				PR_MARGIN_TRACTOR, 
				PR_MARGIN_RIGHT,
				PR_MARGIN_TRACTOR >,
				< PR_MARGIN_LEFT,	; ASF Margins
				18, 	
				PR_MARGIN_RIGHT,
				18 >,
					; ---- PaperInputOptions -------
				< MF_MANUAL1,
				TF_NO_TRACTOR,
				ASF_TRAY1 >,
					; ---- PaperOutputOptions ------
				< OC_COPIES,
				PS_REVERSE,
				OD_SIMPLEX,
				SO_NO_STAPLER,
				OS_NO_SORTER,
				OB_NO_OUTPUTBIN >,
					;
				792,			; paper width (points).
				NULL,			; Main UI
				NoSettingsDialogBox,	; Options UI
				offset PrintEvalDummyASF ; UI eval Routine
			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

hpLJColorf35hires    GraphicsProperties < 300,		; xres
					300,		; yres
					1,  		; band height
					1,  		; buff height
					1, 		; interleaves
					BMF_24BIT,	; color format
					NULL >		; color correction


;----------------------------------------------------------------------------
;	PostScript Info
;----------------------------------------------------------------------------

;	This structure holds PostScript-specific info about the printer.  It
;	*must* be placed directly after the hires GraphicProperties struct

		PSInfoStruct   <
			      PSFL_STANDARD_35N, ; PSFontList
			      0x9001,		; PSLevel flags 
						;  9=PSL_CMYK or PSL_FILE
			      HPLJCOLORF35_PROLOG_LEN,	; prolog length
			      offset hpLJColorf35Prolog ; ptr to prolog
			      >			;   (see pscriptConstant.def)

hpLJColorf35Prolog	label	byte
	char	"GWDict begin", NL
	char	"/SDC { 85 35 currentscreen 3 1 roll pop pop setscreen", NL
	char	"{} setblackgeneration {} setundercolorremoval }bdef", NL
	char	"end", NL
hpLJColorf35EndProlog	label	byte

HPLJCOLORF35_PROLOG_LEN equ	offset hpLJColorf35EndProlog - offset hpLJColorf35Prolog

hpLJColorf35Info	ends
