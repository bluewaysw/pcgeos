
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		IBM Graphics Printer 9-pin driver
FILE:		grpr9pp1Info.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/93		Initial 2.0 revision

DESCRIPTION:
	This file contains the device information for the IBM Graphics Printer 
	9-pin printer

	Other Printers Supported by this resource:

	$Id: grpr9pp1Info.asm,v 1.1 97/04/18 11:55:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	IBM Proprinter 
;----------------------------------------------------------------------------

pp1Info	segment	resource

	; info blocks

PrinterInfo		    <       ; ---- PrinterType -------------
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
                                offset pp1lowRes,
                                offset pp1medRes,
                                offset pp1hiRes,
                                offset printerFontInfo:pp1draft,
                                offset printerFontInfo:pp1nlq,
                                        ; ---- Font Geometry -----------
                                offset pp1fontGeometries,
                                        ; ---- Symbol Set list -----------
                                NULL,
                                        ; ---- PaperMargins ------------
                                < PR_MARGIN_LEFT,       ; Tractor Margins
                                PR_MARGIN_TRACTOR,
                                PR_MARGIN_RIGHT,
                                PR_MARGIN_TRACTOR >,
                                < PR_MARGIN_LEFT,       ; ASF Margins
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
                                612,                    ; paper width (points).
				NULL,                   ; Main UI
                                ASF1BinOptionsDialogBox,; Options UI
                                PrintEvalASF1Bin        ; UI eval Routine
                              >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

pp1lowRes	GraphicsProperties < LO_RES_X_RES,	; xres
				     LO_RES_Y_RES,	; yres
				     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

pp1medRes	GraphicsProperties < MED_RES_X_RES,	; xres
				     MED_RES_Y_RES,	; yres
				     MED_RES_BAND_HEIGHT,  ; band height
                                     MED_RES_BUFF_HEIGHT,  ; buffer height
                                     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

pp1hiRes	GraphicsProperties < HI_RES_X_RES,	; xres
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
pp1fontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset pp1_12ptpitchTab >
                word    FID_INVALID             ;table terminator


pp1_12ptpitchTab      label   byte
        byte    TP_17_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"



pp1Info	ends
