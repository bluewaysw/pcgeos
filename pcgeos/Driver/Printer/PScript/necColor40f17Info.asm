
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript driver
FILE:		necColor40f17Info.asm

AUTHOR:		Dave Durran, 13 April 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/13/93		Initial revision parsed from pscriptNecColor.asm

DESCRIPTION:
	This file contains the device information for the PostScript printer:

	NEC Colormate PS/40


	Other Printers Supported by this resource:

	$Id: necColor40f17Info.asm,v 1.1 97/04/18 11:56:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;	NEC Colormate PS/40
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

necColor40f17Info	segment	resource

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
				offset necColor40f17hires,
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
				72, 	
				PR_MARGIN_RIGHT,
				72 >,
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
				612,			; paper width (points).
				NULL,			; Main UI
				NoSettingsDialogBox,    ; Options UI
				offset PrintEvalDummyASF ; UI eval Routine
			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

necColor40f17hires GraphicsProperties < 300,		; xres
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
			      PSFL_IBM_17,	; PSFontList
			      0x9001,		; PSLevel flags 
						;  9=PSL_CMYK or PSL_FILE
			      NEC40_PROLOG_LEN,	; prolog length
			      offset necColor40f17Prolog ; ptr to prolog
			      >			;   (see pscriptConstant.def)

necColor40f17Prolog	label	byte
	char	"GWDict begin", NL
	char	"/SDC { 85 35 currentscreen 3 1 roll pop pop setscreen", NL
	char	"{} setblackgeneration {} setundercolorremoval }bdef", NL
	char	"end", NL
necColor40f17EndProlog	label	byte

NEC40_PROLOG_LEN equ	offset necColor40f17EndProlog - offset necColor40f17Prolog

necColor40f17Info	ends
