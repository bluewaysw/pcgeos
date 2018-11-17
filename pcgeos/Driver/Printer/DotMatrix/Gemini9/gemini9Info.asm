
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Star Gemini 9-pin driver
FILE:		gemini9Info.asm

AUTHOR:		Dave Durran, 28 Mar 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/28/90		Initial revision
	Dave	5/92		Initial 2.0 revision

DESCRIPTION:
	This file contains the device information for the Star Gemini printer

	Other Printers Supported by this resource:

	$Id: gemini9Info.asm,v 1.1 97/04/18 11:54:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Star Gemini
;----------------------------------------------------------------------------

geminiInfo	segment	resource

	; info blocks

PrinterInfo		   <	< 0,	; ---- PrinterType -------------
				PT_RASTER,
				BMF_MONO >,
					; ---- PrinterConnections ------
				< 0,
				IC_NO_IEEE488,
				CC_NO_CUSTOM,
				SC_NO_SCSI,
				RC_RS232C,
				CC_CENTRONICS,
				FC_FILE,
				AC_NO_APPLETALK >,
					; ---- PrinterSmarts -----------
				PS_DUMB_RASTER,	
					; ---- Mode Info Offsets -------
				offset geminilowRes,
				NULL,
				offset geminihiRes,
                                offset printerFontInfo:mx80draft,
                                offset printerFontInfo:mx80nlq,
                                        ; ---- Font Geometry -----------
                                offset geminifontGeometries,
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
				< 0,
				MF_MANUAL1,
				TF_TRACTOR1,
				ASF_NO_TRAY >,
					; ---- PaperOutputOptions ------
				< OC_NO_COPIES,
				PS_REVERSE,
				OD_SIMPLEX,
				SO_NO_STAPLER,
				OS_NO_SORTER,
				OB_NO_OUTPUTBIN >,
					;
				612,			; paper width (points).
				NULL,			; Main UI
                                ASF0BinOptionsDialogBox, ; Options UI
                                PrintEvalASF0Bin        ; UI eval Routine
			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

geminilowRes	GraphicsProperties < LO_RES_X_RES,	; xres
				     LO_RES_Y_RES,	; yres
				     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

geminihiRes	GraphicsProperties < HI_RES_X_RES,	; xres
				     HI_RES_Y_RES,	; yres
				     HI_RES_BAND_HEIGHT,  ; band height
                                     HI_RES_BUFF_HEIGHT,  ; buffer height
                                     HI_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------


                ;need to add geometries in ascending pointsize, grouped by font
geminifontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset gemini_12ptpitchTab >
                word    FID_INVALID             ;table terminator


gemini_12ptpitchTab      label   byte
        byte    TP_17_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

geminiInfo	ends
