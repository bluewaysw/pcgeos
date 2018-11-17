COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 48-jet printer driver
FILE:		epson48mj1000v2Info.asm

AUTHOR:		Tsutomu Owa

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Owa	1/94		Initial revision

DESCRIPTION:
	This file contains the device information for the Epson MachJet 1000v2 printer
	Other Printers Supported by this resource:
		Epson MachJet 1000v2

	$Id: epson48mj1000v2Info.asm,v 1.1 97/04/18 11:54:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Canon BJ-10v printer
;----------------------------------------------------------------------------

mj1000Info	segment	resource

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
				offset mj1000lowRes,
				offset mj1000medRes,
				offset mj1000hiRes,
				offset printerFontInfo:lq850draft,	
				offset printerFontInfo:lq850nlq,
					; ---- Font Geometry -----------
				offset mj1000fontGeometries,
                                        ; ---- Symbol Set list -----------
                                NULL,
					; ---- PaperMargins ------------
				< 10,	; Tractor Margins
				24,	;
				10,	;
				52>,	;
				< 10,	; ASF Margins, 3mm
				24,	; 8.5mm
				10,	; *
				52>,	; 13.5mm + 5mm
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
				1191,	; paper width (points). 420mm
				NULL,	; Main UI
				ASF1BinOptionsDialogBox, ; Options UI
				PrintEvalASF1Bin         ; eval routine address

			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

mj1000lowRes	GraphicsProperties < LO_RES_X_RES,	; xres
				     LO_RES_Y_RES,	; yres
				     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color format

mj1000medRes	GraphicsProperties < MED_RES_X_RES,	; xres
				     MED_RES_Y_RES,	; yres
				     MED_RES_BAND_HEIGHT,  ; band height
                                     MED_RES_BUFF_HEIGHT,  ; buffer height
                                     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     handle gamma175 >		; color format

mj1000hiRes	GraphicsProperties < HI_RES_X_RES,	; xres
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
mj1000fontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        8,
                        offset mj1000_8ptpitchTab >,
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset mj1000_12ptpitchTab >,
                <       FID_DTC_URW_ROMAN,
                        24,
                        offset mj1000_24ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        8,
                        offset mj1000_8ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        12,
                        offset mj1000_12ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        24,
                        offset mj1000_24ptpitchTab >
                word    FID_INVALID             ;table terminator

mj1000_8ptpitchTab      label   byte
        byte    TP_15_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

mj1000_12ptpitchTab      label   byte
        byte    TP_20_PITCH
        byte    TP_17_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

mj1000_24ptpitchTab      label   byte
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"


mj1000Info	ends
