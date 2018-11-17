
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon BJ-130 48-jet driver
FILE:		canon48bj10eInfo.asm

AUTHOR:		Dave Durran, 27 Mar 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	This file contains the device information for the canon48pin bj10e
	narrow carriage printer

	Other Printers Supported by this resource:

	$Id: canon48bj10eInfo.asm,v 1.1 97/04/18 11:54:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Canon BJ-10e 48-jet 
;----------------------------------------------------------------------------

bj10eInfo	segment	resource

	; info blocks

PrinterInfo		   <      ; ---- PrinterType -------------
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
                                offset bj10elowRes,
                                offset bj10emedRes,
                                offset bj10ehiRes,
                                offset printerFontInfo:bj130edraft,
                                offset printerFontInfo:bj130enlq,
                                        ; ---- Font Geometry -----------
                                offset bj10efontGeometries,
                                        ; ---- Symbol Set list -----------
                                offset bj10eSymbolSets,
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
                                TF_NO_TRACTOR,
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
                                ASF1BinOptionsDialogBox, ; Options UI
				PrintEvalASF1Bin         ; eval routine address
                              >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

bj10elowRes	GraphicsProperties < LO_RES_X_RES,	; xres
				     LO_RES_Y_RES,	; yres
				     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

bj10emedRes	GraphicsProperties < MED_RES_X_RES,	; xres
				     MED_RES_Y_RES,	; yres
				     MED_RES_BAND_HEIGHT,  ; band height
                                     MED_RES_BUFF_HEIGHT,  ; buffer height
                                     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     handle gamma175 >		; color format

bj10ehiRes	GraphicsProperties < HI_RES_X_RES,	; xres
				     HI_RES_Y_RES,	; yres
				     HI_RES_BAND_HEIGHT,  ; band height
                                     HI_RES_BUFF_HEIGHT,  ; buffer height
                                     HI_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     handle gamma21 >		; color format

;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

                ;need to add geometries in ascending pointsize, grouped by font
bj10efontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset bj10e_12ptpitchTab >,
                <       FID_DTC_URW_ROMAN,
                        24,
                        offset bj10e_24ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        12,
                        offset bj10e_12ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        24,
                        offset bj10e_24ptpitchTab >
                word    FID_INVALID             ;table terminator


bj10e_12ptpitchTab      label   byte
        byte    TP_17_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

bj10e_24ptpitchTab      label   byte
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"


bj10eSymbolSets	label	word
	word	offset pr_codes_SetASCII7	;ASCII 7 bit
	word	offset pr_codes_SetIBM437	;IBM code page 437
	word	offset pr_codes_SetIBM850	;IBM code page 850

bj10eInfo	ends
