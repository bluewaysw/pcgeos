
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Epson 9-pin driver
FILE:		epson9dfx5000Info.asm

AUTHOR:		Dave Durran, 28 Mar 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Initial revision

DESCRIPTION:
	This file contains the device information for the Epson dfx5000 printer

	Other Printers Supported by this resource:

	$Id: epson9dfx5000Info.asm,v 1.1 97/04/18 11:53:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Epson dfx5000
;----------------------------------------------------------------------------

dfx5000Info	segment	resource

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
				offset dfx5000lowRes,
				offset dfx5000medRes,
				offset dfx5000hiRes,
				offset printerFontInfo:fx86edraft,	
				offset printerFontInfo:fx86enlq,
                                        ; ---- Font Geometry -----------
                                offset dfx5000fontGeometries,
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
				ASF_NO_TRAY >,
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
				ASF0BinOptionsDialogBox,	; Options UI
				PrintEvalASF0Bin		; UI eval Routine
			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

dfx5000lowRes	GraphicsProperties < LO_RES_X_RES,	; xres
				     LO_RES_Y_RES,	; yres
				     LO_RES_BAND_HEIGHT,  ; band height
				     LO_RES_BUFF_HEIGHT,  ; buffer height
				     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color correction

dfx5000medRes	GraphicsProperties < MED_RES_X_RES,	; xres
				     MED_RES_Y_RES,	; yres
				     MED_RES_BAND_HEIGHT,  ; band height
				     MED_RES_BUFF_HEIGHT,  ; buffer height
				     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     NULL >		; color correction

dfx5000hiRes	GraphicsProperties < HI_RES_X_RES,	; xres
				     HI_RES_Y_RES,	; yres
				     HI_RES_BAND_HEIGHT,  ; band height
				     HI_RES_BUFF_HEIGHT,  ; buffer height
				     HI_RES_INTERLEAVE_FACTOR, ;#interleaves
				     BMF_MONO,		;color format
				     handle gamma30 >	; color correction

;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

                ;need to add geometries in ascending pointsize, grouped by font
dfx5000fontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset dfx5000_12ptpitchTab >,
                <       FID_DTC_URW_ROMAN,
                        24,
                        offset dfx5000_24ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        12,
                        offset dfx5000_12ptpitchTab >,
                <       FID_DTC_URW_SANS,
                        24,
                        offset dfx5000_24ptpitchTab >
                word    FID_INVALID             ;table terminator


dfx5000_12ptpitchTab      label   byte
        byte    TP_20_PITCH
        byte    TP_17_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

dfx5000_24ptpitchTab      label   byte
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_6_PITCH
        byte    TP_5_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"



dfx5000Info	ends
