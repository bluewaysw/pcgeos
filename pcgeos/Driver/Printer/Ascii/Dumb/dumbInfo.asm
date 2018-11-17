
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dumb ASCII (Unformatted) Print Driver
FILE:		dumbInfo.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        Dave    8/30/93         Initial Revision


DESCRIPTION:
	This file contains the device information for the dumb ASCII printer

	Other Printers Supported by this resource:

	$Id: dumbInfo.asm,v 1.1 97/04/18 11:56:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	Dumb ASCII
;----------------------------------------------------------------------------

dumbInfo	segment	resource

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
                                offset printerFontInfo:dumbnlq,
                                        ; ---- Font Geometry -----------
                                offset dumbfontGeometries,
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
                                NoSettingsDialogBox,; Options UI
                                PrintEvalDummyASF        ; UI eval Routine
                              >


;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------

                ;need to add geometries in ascending pointsize, grouped by font
dumbfontGeometries     FontGeometry \
                <       FID_DTC_URW_ROMAN,
                        12,
                        offset dumb_12ptpitchTab >
                word    FID_INVALID             ;table terminator


dumb_12ptpitchTab      label   byte
        byte    TP_10_PITCH
        byte    TP_PROPORTIONAL         ;"table Terminator"

dumbInfo	ends
