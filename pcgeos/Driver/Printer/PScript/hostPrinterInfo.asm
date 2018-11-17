
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript driver
FILE:		qmsColorScriptf35Info.asm

AUTHOR:		Jens-Michael Gross, 2 February 2001

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JMG		2/2/01		Initial revision parsed from other PS definitions
   Falk	2015		added to the PS 2 PDF package 

DESCRIPTION:
	This file contains the device information for the virtual PostScript printer:

	GhostScript Software RIP (color and B/W version)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

hostPrinterInfo	segment	resource

	; info blocks

			PrinterInfo <	; ---- PrinterType -------------
				< PT_RASTER, BMF_MONO>,
					; ---- PrinterConnections ------
				< IC_NO_IEEE488,
				CC_CUSTOM,
				SC_NO_SCSI,
				RC_NO_RS232C,
				CC_NO_CENTRONICS,
				FC_NO_FILE,
				AC_NO_APPLETALK >,
					; ---- PrinterSmarts -----------
				PS_PDL,	
					;-------Custom Entry Routine-------
				PrintEnterHostIntegration,
					;-------Custom Exit Routine-------
				PrintExitHostIntegration,		
					; ---- Mode Info Offsets -------
				NULL,
				NULL,
				offset hostPrinter300,
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
				< MF_NO_MANUAL,
				TF_NO_TRACTOR,
				ASF_NO_TRAY >,
					; ---- PaperOutputOptions ------
				< OC_COPIES,        ;?
				PS_REVERSE,         ;?
				OD_SIMPLEX,         ;?
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
                                   
hostPrinter300			GraphicsProperties < 300,		; xres
						300,		; yres
						1,  		; band height
						1,  		; buff height
						1, 		; interleaves
						BMF_MONO,	; color format
						NULL >		; color correct

;----------------------------------------------------------------------------
;	PostScript Info
;----------------------------------------------------------------------------

;	This structure holds PostScript-specific info about the printer.  It
;	*must* be placed directly after the hires GraphicProperties struct

		PSInfoStruct   <
			      PSFL_STANDARD_13, ; PSFontList
			      0x0001,		; PSLevel flags 
						;  9=PSL_CMYK or PSL_FILE
			      HOST_PRINTER_PROLOG_LEN,	; prolog length
			      offset hostPrinterProlog ; ptr to prolog
			      >			;   (see pscriptConstant.def)

;	this sets up a transfer function that is described in Computer
;	Graphics and Applications, May 1991 issue, Jim Blinn's column.
;	Basically, it corrects for the perceived darkening of greys when
;	printing.  The hardcoded values are empirical values arrived at
;	through experimentation (see the article for details).
;	also, the standard fonts are 'registered', so GhostScript will
;	find them.

hostPrinterProlog	label	byte
	char	"GWDict begin", NL
	char	"GWDict begin", NL
	char	"/SDC { 85 35 currentscreen 3 1 roll pop pop setscreen", NL
	char	"{dup dup 0.3681 mul -1.145 add mul 1.7769 add mul}", NL
	char	"currenttransfer CP settransfer} bdef", NL
	char	"end", NL
	char	"/Times-Roman findfont", NL
	char	"/Times-Bold  findfont", NL
	char	"/Times-Italic findfont", NL
	char	"/Times-BoldItalic findfont", NL
	char	"/Courier findfont", NL
	char	"/Courier-Bold findfont", NL
	char	"/Courier-Oblique findfont", NL
	char	"/Courier-BoldOblique findfont", NL
	char	"/Helvetica findfont", NL
	char	"/Helvetica-Bold findfont", NL
	char	"/Helvetica-Oblique findfont", NL
	char	"/Helvetica-BoldOblique findfont ", NL
	
hostPrinterEndProlog	label	byte

HOST_PRINTER_PROLOG_LEN equ	offset hostPrinterEndProlog - offset hostPrinterProlog

hostPrinterInfo	ends

