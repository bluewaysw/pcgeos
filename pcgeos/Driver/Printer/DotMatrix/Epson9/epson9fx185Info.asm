
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 9-pin driver
FILE:		epson9fx185Info.asm

AUTHOR:		Dave Durran, 28 Mar 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/28/90		Initial revision
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	This file contains the device information for the Epson fx185 printer

	Other Printers Supported by this resource:

	$Id: epson9fx185Info.asm,v 1.1 97/04/18 11:53:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Epson fx185
;----------------------------------------------------------------------------

fx185Info	segment	resource

	; info blocks

PrinterInfo		   <		; ---- PrinterType -------------
				< PT_RASTER,
				BMF_MONO >,
					; ---- PrinterConnections ------
				< IC_NO_IEEE488,
				CC_NO_CUSTOM,
				SC_NO_SCSI,
				RC_RS232C,
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
				offset fx185lowRes,
				offset fx185medRes,
				offset fx185hiRes,
				offset printerFontInfo:fx85draft,	
				offset printerFontInfo:fx85nlq,
                                        ; ---- Font Geometry -----------
                                offset fx185fontGeometries,
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
				TF_TRACTOR1,
				ASF_TRAY1 >,
					; ---- PaperOutputOptions ------
				< OC_NO_COPIES,
				PS_REVERSE,
				OD_SIMPLEX,
				SO_NO_STAPLER,
				OS_NO_SORTER,
				OB_NO_OUTPUTBIN >,
					;
				1008,			; paper width (points).
				NULL,			; Main UI
				ASF1BinOptionsDialogBox,	; Options UI
				PrintEvalASF1Bin	; UI eval Routine
			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

fx185lowRes     GraphicsProperties < LO_RES_X_RES,      ; xres
                                     LO_RES_Y_RES,      ; yres
                                     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_MONO,		;color format
				     NULL >         ; color correction

fx185medRes     GraphicsProperties < MED_RES_X_RES,     ; xres
                                     MED_RES_Y_RES,     ; yres
                                     MED_RES_BAND_HEIGHT,  ; band height
                                     MED_RES_BUFF_HEIGHT,  ; buffer height
                                     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_MONO,		;color format
				     NULL >         ; color correction

fx185hiRes      GraphicsProperties < HI_RES_X_RES,      ; xres
                                     HI_RES_Y_RES,      ; yres
                                     HI_RES_BAND_HEIGHT,  ; band height
                                     HI_RES_BUFF_HEIGHT,  ; buffer height
                                     HI_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_MONO,		;color format
				     handle gamma30 >   ; color correction

;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

                ;need to add geometries in ascending pointsize, grouped by font
fx185fontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset fx185_12ptpitchTab >,
                <       FID_DTC_URW_ROMAN,
                        24,
                        offset fx185_24ptpitchTab >
                word    FID_INVALID             ;table terminator


fx185_12ptpitchTab      label   byte
        byte    TP_20_PITCH
        byte    TP_17_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

fx185_24ptpitchTab      label   byte
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"



fx185Info	ends
