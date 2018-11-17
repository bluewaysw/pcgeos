
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript driver
FILE:		ibm4216f43Info.asm

AUTHOR:		Dave Durran 13 April 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dave	4/13/93		Initial revision parsed from pscriptIBMInfo.asm

DESCRIPTION:
	This file contains the device information for the IBM PostScript 
	printers


	$Id: ibm4216f43Info.asm,v 1.1 97/04/18 11:56:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	4216 (43 fonts)
;----------------------------------------------------------------------------

ibm4216f43Info	segment	resource

	; info blocks

		PrinterInfo <		; ---- PrinterType -------------
				< PT_RASTER, BMF_MONO>,
					; ---- PrinterConnections ------
				< IC_NO_IEEE488,
				CC_NO_CUSTOM,
				SC_NO_SCSI,
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
				offset ibm4216f43hiRes,
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
				PR_MARGIN_TOP, 	
				PR_MARGIN_RIGHT,
				PR_MARGIN_BOTTOM >,
					; ---- PaperInputOptions -------
				< MF_MANUAL1,
				TF_NO_TRACTOR,
				ASF_TRAY1 >,
					; ---- PaperOutputOptions ------
				< OC_COPIES,
				PS_NORMAL,
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

ibm4216f43hiRes    GraphicsProperties < 300,		; xres
					300,		; yres
					1,  		; band height
					1,  		; buff height
					1, 		; interleaves
					BMF_MONO,	; color format
					NULL >		; color correction


;----------------------------------------------------------------------------
;	PostScript Info
;----------------------------------------------------------------------------

;	This structure holds PostScript-specific info about the printer.  It
;	*must* be placed directly after the hires GraphicProperties struct

		PSInfoStruct   <
			      PSFL_IBM_43,	; PSFontList
			      0x0001,		; PSLevel flags 
			      IBM43_PROLOG_LEN,	; prolog length
			      offset ibm4216f43Prolog ; ptr to prolog
			      >			;   (see pscriptConstant.def)

;	this sets up a transfer function that is described in Computer
;	Graphics and Applications, May 1991 issue, Jim Blinn's column.
;	Basically, it corrects for the perceived darkening of greys when
;	printing.  The hardcoded values are empirical values arrived at
;	through experimentation (see the article for details).

ibm4216f43Prolog	label	byte
	char	"GWDict begin", NL
	char	"/SDC { 85 35 currentscreen 3 1 roll pop pop setscreen", NL
	char	"{dup dup 0.3681 mul -1.145 add mul 1.7769 add mul}", NL
	char	"currenttransfer CP settransfer} bdef", NL
	char	"end", NL
ibm4216f43EndProlog	label	byte

IBM43_PROLOG_LEN equ	offset ibm4216f43EndProlog - offset ibm4216f43Prolog

ibm4216f43Info	ends
