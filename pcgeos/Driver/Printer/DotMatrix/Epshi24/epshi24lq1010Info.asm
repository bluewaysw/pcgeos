
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson late model 24-pin driver
FILE:		epshi24lq1010Info.asm

AUTHOR:		Dave Durran, 27 Mar 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision

DESCRIPTION:
	This file contains the device information for the Epson lq1010 printer

	Other Printers Supported by this resource:

	$Id: epshi24lq1010Info.asm,v 1.1 97/04/18 11:54:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Epson lq1010
;----------------------------------------------------------------------------

lq1010Info	segment	resource

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
				offset lq1010lowRes,
				offset lq1010medRes,
				offset lq1010hiRes,
				offset printerFontInfo:lq850draft,	
				offset printerFontInfo:lq850nlq,
					; ---- Font Geometry -----------
				offset lq1010fontGeometries,
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

lq1010lowRes	GraphicsProperties < LO_RES_X_RES,	; xres
				     LO_RES_Y_RES,	; yres
				     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

lq1010medRes	GraphicsProperties < MED_RES_X_RES,	; xres
				     MED_RES_Y_RES,	; yres
				     MED_RES_BAND_HEIGHT,  ; band height
                                     MED_RES_BUFF_HEIGHT,  ; buffer height
                                     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

lq1010hiRes	GraphicsProperties < HI_RES_X_RES,	; xres
				     HI_RES_Y_RES,	; yres
				     HI_RES_BAND_HEIGHT,  ; band height
                                     HI_RES_BUFF_HEIGHT,  ; buffer height
                                     HI_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     handle gamma30 >		; color format

;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

                ;need to add geometries in ascending pointsize, grouped by font
lq1010fontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        8,
                        offset lq1010_8ptpitchTab >,
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset lq1010_12ptpitchTab >,
                <       FID_DTC_URW_ROMAN,
                        24,
                        offset lq1010_24ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        8,
                        offset lq1010_8ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        12,
                        offset lq1010_12ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        24,
                        offset lq1010_24ptpitchTab >
                word    FID_INVALID             ;table terminator

lq1010_8ptpitchTab      label   byte
        byte    TP_15_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

lq1010_12ptpitchTab      label   byte
        byte    TP_20_PITCH
        byte    TP_17_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

lq1010_24ptpitchTab      label   byte
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"


lq1010Info	ends
