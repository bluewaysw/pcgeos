
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 48-jet driver
FILE:		epson48sq1170Info.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	9/22/92		Initial revision

DESCRIPTION:
	This file contains the device information for the Epson sq1170 printer

	Other Printers Supported by this resource:

	$Id: epson48sq1170Info.asm,v 1.1 97/04/18 11:54:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Epson sq1170
;----------------------------------------------------------------------------

sq1170Info	segment	resource

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
				offset sq1170lowRes,
				offset sq1170medRes,
				offset sq1170hiRes,
				offset printerFontInfo:lq850draft,	
				offset printerFontInfo:lq850nlq,
					; ---- Font Geometry -----------
				offset sq1170fontGeometries,
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
				ASF1BinOptionsDialogBox, ; Options UI
				PrintEvalASF1Bin         ; eval routine address
			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

sq1170lowRes	GraphicsProperties < LO_RES_X_RES,	; xres
				     LO_RES_Y_RES,	; yres
				     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

sq1170medRes	GraphicsProperties < MED_RES_X_RES,	; xres
				     MED_RES_Y_RES,	; yres
				     MED_RES_BAND_HEIGHT,  ; band height
                                     MED_RES_BUFF_HEIGHT,  ; buffer height
                                     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     handle gamma175 >		; color format

sq1170hiRes	GraphicsProperties < HI_RES_X_RES,	; xres
				     HI_RES_Y_RES,	; yres
				     HI_RES_BAND_HEIGHT,  ; band height
                                     HI_RES_BUFF_HEIGHT,  ; buffer height
                                     HI_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     handle gamma20 >		; color format

;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

                ;need to add geometries in ascending pointsize, grouped by font
sq1170fontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        8,
                        offset sq1170_8ptpitchTab >,
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset sq1170_12ptpitchTab >,
                <       FID_DTC_URW_ROMAN,
                        24,
                        offset sq1170_24ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        8,
                        offset sq1170_8ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        12,
                        offset sq1170_12ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        24,
                        offset sq1170_24ptpitchTab >
                word    FID_INVALID             ;table terminator

sq1170_8ptpitchTab      label   byte
        byte    TP_15_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

sq1170_12ptpitchTab      label   byte
        byte    TP_20_PITCH
        byte    TP_17_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

sq1170_24ptpitchTab      label   byte
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"


sq1170Info	ends
