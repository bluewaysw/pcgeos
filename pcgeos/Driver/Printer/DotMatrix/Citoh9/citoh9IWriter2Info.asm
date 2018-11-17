
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		citoh 9-pin driver
FILE:		citoh9IWriter2Info.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	6/93		Initial 2.0 version

DESCRIPTION:
	This file contains the device information for the Epson generic printer

	Other Printers Supported by this resource:

	$Id: citoh9IWriter2Info.asm,v 1.1 97/04/18 11:53:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	C.Itoh iwriter2
;----------------------------------------------------------------------------

iwriter2Info	segment	resource

	; info blocks

PrinterInfo		   <      ; ---- PrinterType -------------
                                < PT_RASTER,
                                BMF_4CMYK >,
                                        ; ---- PrinterConnections ------
                                < IC_NO_IEEE488,
                                CC_NO_CUSTOM,
                                SC_NO_SCSI,
                                RC_RS232C,
                                CC_NO_CENTRONICS,
                                FC_FILE,
                                AC_NO_APPLETALK >,
                                        ; ---- PrinterSmarts -----------
                                PS_DUMB_RASTER,
					;-------Custom Entry Routine-------
				NULL,
					;-------Custom Exit Routine-------
				NULL,		
                                        ; ---- Mode Info Offsets -------
                                offset iwriter2lowRes,
                                0,
                                offset iwriter2hiRes,
                                offset printerFontInfo:dmpdraft,
                                offset printerFontInfo:dmpnlq,
                                        ; ---- Font Geometry -----------
                                offset iwriter2fontGeometries,
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
                                ASF_NO_TRAY >,
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
                                ASF0BinOptionsDialogBox,        ; Options UI
                                PrintEvalASF0Bin        ; UI eval Routine
                              >

;----------------------------------------------------------------------------
;       Graphics modes info
;----------------------------------------------------------------------------

iwriter2lowRes  GraphicsProperties < LO_RES_X_RES,      ; xres
                                     LO_RES_Y_RES,      ; yres
                                     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_4CMYK,
				     handle inkCorrection >  ; color format

iwriter2hiRes   GraphicsProperties < HI_RES_X_RES,      ; xres
                                     HI_RES_Y_RES,      ; yres
                                     HI_RES_BAND_HEIGHT,  ; band height
                                     HI_RES_BUFF_HEIGHT,  ; buffer height
                                     HI_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_4CMYK,
				     handle inkCorrection >  ; color format


;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

                ;need to add geometries in ascending pointsize, grouped by font
iwriter2fontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset iwriter2_12ptpitchTab >
                word    FID_INVALID             ;table terminator


iwriter2_12ptpitchTab      label   byte
        byte    TP_17_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

iwriter2Info	ends
