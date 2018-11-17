
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
	jfh	10/7/07	JMG's version doesn't do Sans bold - it does do italic
						so let's mess with the font table

DESCRIPTION:
	This file contains the device information for the virtual PostScript printer:

	GhostScript Software RIP (color and B/W version)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

softRIPInfo	segment	resource

	; info blocks

			PrinterInfo <	; ---- PrinterType -------------
				< PT_RASTER, BMF_MONO>,
					; ---- PrinterConnections ------
				< IC_NO_IEEE488,
				CC_NO_CUSTOM,
				SC_NO_SCSI,
				RC_NO_RS232C,
				CC_NO_CENTRONICS,
				FC_FILE,
				AC_NO_APPLETALK >,
					; ---- PrinterSmarts -----------
				PS_PDL,	
					;-------Custom Entry Routine-------
				NULL,
					;-------Custom Exit Routine-------
				NULL,		
					; ---- Mode Info Offsets -------
				NULL,
				NULL,
				offset softRIP300,
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
                                   
softRIP300			GraphicsProperties < 300,		; xres
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
			      SOFTRIP_PROLOG_LEN,	; prolog length
			      offset softRIPProlog ; ptr to prolog
			      >			;   (see pscriptConstant.def)

;	this sets up a transfer function that is described in Computer
;	Graphics and Applications, May 1991 issue, Jim Blinn's column.
;	Basically, it corrects for the perceived darkening of greys when
;	printing.  The hardcoded values are empirical values arrived at
;	through experimentation (see the article for details).
;	also, the standard fonts are 'registered', so GhostScript will
;	find them.

softRIPProlog	label	byte
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
; jfh - start messing
	char	"/Sans findfont", NL
	char	"/Sans-Bold findfont", NL
	char	"/Sans-Oblique findfont", NL
	char	"/Sans-BoldOblique findfont ", NL

softRIPEndProlog	label	byte

SOFTRIP_PROLOG_LEN equ	offset softRIPEndProlog - offset softRIPProlog

softRIPInfo	ends

softRIPCInfo	segment	resource

	; info blocks

			PrinterInfo <	; ---- PrinterType -------------
				< PT_RASTER, BMF_4CMYK>,
					; ---- PrinterConnections ------
				< IC_NO_IEEE488,
				CC_NO_CUSTOM,
				SC_NO_SCSI,
				RC_NO_RS232C,
				CC_NO_CENTRONICS,
				FC_FILE,
				AC_NO_APPLETALK >,
					; ---- PrinterSmarts -----------
				PS_PDL,	
					;-------Custom Entry Routine-------
				NULL,
					;-------Custom Exit Routine-------
				NULL,		
					; ---- Mode Info Offsets -------
				NULL,
				NULL,
				offset softRIPcol300,
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
                                   
softRIPcol300			GraphicsProperties < 300,		; xres
						300,		; yres
						1,  		; band height
						1,  		; buff height
						1, 		; interleaves
						BMF_24BIT,	; color format
						NULL >		; color correct

;----------------------------------------------------------------------------
;	PostScript Info
;----------------------------------------------------------------------------

;	This structure holds PostScript-specific info about the printer.  It
;	*must* be placed directly after the hires GraphicProperties struct

		PSInfoStruct   <
			      PSFL_STANDARD_13, ; PSFontList
			      0x8001,		; PSLevel flags 
						;  9=PSL_CMYK or PSL_FILE
			      SOFTRIPC_PROLOG_LEN,	; prolog length
			      offset softRIPCProlog ; ptr to prolog
			      >			;   (see pscriptConstant.def)

softRIPCProlog	label	byte
	char	"GWDict begin", NL
	char	"/SDC { 85 35 currentscreen 3 1 roll pop pop setscreen", NL
	char	"{} setblackgeneration {} setundercolorremoval }bdef", NL
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
; jfh - start messing
	char	"/Sans findfont", NL
	char	"/Sans-Bold findfont", NL
	char	"/Sans-Oblique findfont", NL
	char	"/Sans-BoldOblique findfont ", NL
	
softRIPCEndProlog	label	byte

SOFTRIPC_PROLOG_LEN equ	offset softRIPCEndProlog - offset softRIPCProlog

softRIPCInfo	ends
