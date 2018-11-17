
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Diablo Daisy Wheel driver
FILE:		diablo630Info.asm

AUTHOR:		Dave Durran, 27 Mar 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	3/27/90		Initial revision
	Dave	5/92		Initial 2.0 version

DESCRIPTION:
	This file contains the device information for the toshiba P321 printer

	Other Printers Supported by this resource:

	$Id: diablo630Info.asm,v 1.1 97/04/18 11:56:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Diablo 630
;----------------------------------------------------------------------------

d630Info	segment	resource

	; info blocks

PrinterInfo		   <       ; ---- PrinterType -------------
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
                                NULL,
                                NULL,
                                NULL,
                                NULL,
                                offset printerFontInfo:d630nlq,
                                        ; ---- Font Geometry -----------
                                offset d630fontGeometries,
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
                                ASF0BinOptionsDialogBox,; Options UI
                                PrintEvalASF0Bin        ; UI eval Routine
                              >


;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

                ;need to add geometries in ascending pointsize, grouped by font
d630fontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset d630_12ptpitchTab >
                word    FID_INVALID             ;table terminator


d630_12ptpitchTab      label   byte
        byte    TP_17_PITCH
        byte    TP_15_PITCH
        byte    TP_12_PITCH
        byte    TP_10_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

d630Info	ends
