COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 24-pin driver
FILE:		epshi24dual34MInfo.asm

AUTHOR:		Tsutomu Owa

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Owa	1/94		Initial revision

DESCRIPTION:
	This file contains the device information for the Toshiba dual34M printer

	Other Printers Supported by this resource:
		Toshiba	DualMode Printer 3V
		Toshiba	DualMode Printer 3VE
		Toshiba	DualMode Printer 4V (B/W)
		Toshiba	DualMode Printer 4VE (B/W)
	$Id: epshi24dual34MInfo.asm,v 1.1 97/04/18 11:54:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Toshiba Dual Mode Printer	
;----------------------------------------------------------------------------

dual34MInfo	segment	resource

	; info blocks

PrinterInfo		   <		; ---- PrinterType -------------
				< PT_RASTER,
				BMF_MONO >,
					; ---- PrinterConnections ------
				< IC_NO_IEEE488,
				CC_NO_CUSTOM,
				SC_NO_SCSI,
				RC_NO_RS232C,
				CC_CENTRONICS,
				FC_FILE,
				AC_NO_APPLETALK >,
					; ---- PrinterSmarts -----------
				PS_DUMB_RASTER,	
					;-------Custom Entry Routine-------
				NULL,
					;-------Custom Exit Routine-------
				NULL,		
					; ---- Mode Info Offsets -------
				offset dual34MlowRes,
				offset dual34MmedRes,
				offset dual34MhiRes,
                                offset printerFontInfo:lq800draft,
                                offset printerFontInfo:lq800nlq,
                                        ; ---- Font Geometry -----------
                                offset dual34MfontGeometries,
                                        ; ---- Symbol Set list -----------
                                NULL,
					; ---- PaperMargins ------------
				< 39,	; Tractor Margins, 13mm
				29, 	; 10.2mm
				39,	; 13mm
				66>,	; 15mm
				< 15,	; ASF Margins, 5.08mm
				29, 	; 10mm
				15,	; 5.08mm
				57>,	; 15mm + 5mm
					; ---- PaperInputOptions -------
				< MF_MANUAL1,
				TF_NO_TRACTOR,
				ASF_TRAY1 >,
					; ---- PaperOutputOptions ------
				< OC_NO_COPIES,
				PS_NORMAL,
				OD_SIMPLEX,
				SO_NO_STAPLER,
				OS_NO_SORTER,
				OB_NO_OUTPUTBIN >,
				1080,	; paper width (points).	381mm
                                NULL,   ; Main UI
				ASF1BinOnlyOptionsDialogBox, ; Options UI
				PrintEvalASF1BinOnly    ; eval routine address
			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

dual34MlowRes	GraphicsProperties < LO_RES_X_RES,	; xres
				     LO_RES_Y_RES,	; yres
				     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

dual34MmedRes	GraphicsProperties < MED_RES_X_RES,	; xres
				     MED_RES_Y_RES,	; yres
				     MED_RES_BAND_HEIGHT,  ; band height
                                     MED_RES_BUFF_HEIGHT,  ; buffer height
                                     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

dual34MhiRes	GraphicsProperties < HI_RES_X_RES,	; xres
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
dual34MfontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        8,
                        offset dual34M_8ptpitchTab >,
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset dual34M_12ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        8,
                        offset dual34M_8ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        12,
                        offset dual34M_12ptpitchTab >
                word    FID_INVALID             ;table terminator

dual34M_8ptpitchTab      label   byte
        byte    TP_15_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

dual34M_12ptpitchTab      label   byte
        byte    TP_20_PITCH
        byte    TP_17_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"


dual34MInfo	ends
