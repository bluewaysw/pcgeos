COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		deskjet CMY driver
FILE:		dj500cInfo.asm

AUTHOR:		Dave Durran

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	5/92		Initial revision from inter1Info.asm

DESCRIPTION:
	This file contains the device information for the HP deskjet 500C
	Other Printers Supported by this resource:

	$Id: dj500cInfo.asm,v 1.1 97/04/18 11:52:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	HP internal font set common to color deskjets.
;----------------------------------------------------------------------------

dj500cInfo	segment	resource

	; info blocks

PrinterInfo		 <		; ---- PrinterType -------------
				< PT_RASTER,
				BMF_3CMY >,
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
				offset dj500clowRes,
				offset dj500cmedRes,
				offset dj500chiRes,
				NULL,		;Graphics only driver.
				NULL,
                                        ; ---- Font Geometry -----------
                                NULL,
                                        ; ---- Symbol Set list -----------
                                NULL,
					; ---- PaperMargins ------------
				< PR_MARGIN_LEFT,	; Tractor Margins
				PR_MARGIN_TRACTOR, 
				PR_MARGIN_RIGHT,
				PR_MARGIN_TRACTOR >,
				< PR_MARGIN_LEFT,	; ASF Margins
				29,		; 6.5mm but... 10mm 	
				PR_MARGIN_RIGHT,
				61>,		; 16.5mm + 5mm
					; ---- PaperInputOptions -------
				< MF_MANUAL1,
				TF_NO_TRACTOR,
				ASF_TRAY1 >,
					; ---- PaperOutputOptions ------
				< OC_COPIES,
				PS_REVERSE,
				OD_SIMPLEX,
				SO_NO_STAPLER,
				OS_NO_SORTER,
				OB_NO_OUTPUTBIN >,
					;
				682,	; paper width (points).  241mm
				NULL,			; Main UI
				ASF1BinOptionsDialogBox, ; Options UI
				PrintEvalASF1Bin	; UI eval routines.
			      >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

dj500clowRes  GraphicsProperties < LO_RES_X_RES,      ; xres
                                     LO_RES_Y_RES,      ; yres
                                     LO_RES_BAND_HEIGHT,  ; band height
                                     LO_RES_BUFF_HEIGHT,  ; buffer height
                                     LO_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_3CMY,		;color format
                                     handle dj500cInkCorrection > ; color corr

dj500cmedRes  GraphicsProperties < MED_RES_X_RES,     ; xres
                                     MED_RES_Y_RES,     ; yres
                                     MED_RES_BAND_HEIGHT,  ; band height
                                     MED_RES_BUFF_HEIGHT,  ; buffer height
                                     MED_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_3CMY,		;color format
                                     handle dj500cInkCorrection > ; color corr

dj500chiRes   GraphicsProperties < HI_RES_X_RES,      ; xres
                                     HI_RES_Y_RES,      ; yres
                                     HI_RES_BAND_HEIGHT,  ; band height
                                     HI_RES_BUFF_HEIGHT,  ; buffer height
                                     HI_RES_INTERLEAVE_FACTOR, ;#interleaves
                                     BMF_3CMY,		;color format
                                     handle dj500cInkCorrection > ; color corr


;----------------------------------------------------------------------------
;	Text modes info
;----------------------------------------------------------------------------


dj500cnlq	label	word

dj500cInfo	ends
