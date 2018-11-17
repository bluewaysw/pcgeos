COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Brother Nike 56-jet driver
FILE:		nike56ColorInfo.asm

AUTHOR:		Joon Song, Mar  8, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	3/ 8/95   	Initial revision


DESCRIPTION:
	This file contains the device information for the
	narrow carriage printer

	$Id: nike56ColorInfo.asm,v 1.1 97/04/18 11:55:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------------
;	
;----------------------------------------------------------------------------

colorInfo	segment	resource

	; info blocks

PrinterInfo		<	< PT_RASTER,	; ---- PrinterType ------------
				  BMF_3CMY >,
						; ---- PrinterConnections -----
				< IC_NO_IEEE488,
				  CC_NO_CUSTOM,
				  SC_NO_SCSI,
				  RC_NO_RS232C,
				  CC_NO_CENTRONICS,
				  FC_NO_FILE,
				  AC_NO_APPLETALK >,
						; ---- PrinterSmart -----------
				PS_DUMB_RASTER,
						; ---- Custom Entry Routine ---
				NULL,
						; ---- Custom Exit Routine ----
				NULL,
						; ---- Mode Info Offsets ------
				offset colorLoRes,
				offset colorMedRes,
				offset colorHiRes,
				NULL,
				NULL,
						; ---- Font Geometry ----------
				NULL,
						; ---- Symbol Set list --------
				NULL,
						; ---- PaperMargins -----------
				< PR_MARGIN_LEFT,	; Tractor Margins
				  PR_MARGIN_TOP,	; in reality there are
				  PR_MARGIN_RIGHT,	; no tractor margins
				  PR_MARGIN_BOTTOM >,
				< PR_MARGIN_LEFT,	; ASF Margins
				  PR_MARGIN_TOP,
				  PR_MARGIN_RIGHT,
				  PR_MARGIN_BOTTOM >,
						; ---- PaperInputOptions ------
				< MF_MANUAL1,
				  ASF_TRAY1,
				  TF_NO_TRACTOR >,
						; ---- PaperOutputOptions -----
				< OC_NO_COPIES,
				  PS_REVERSE,
				  OD_SIMPLEX,
				  SO_NO_STAPLER,
				  OS_NO_SORTER,
				  OB_NO_OUTPUTBIN >,

				PR_MAX_PAPER_WIDTH,     ; paper width (points).
				NULL,                   ; Main UI
				NikeOptionsDialogBox,	; Options UI
				PrintEvalNikeOptionsUI	; eval routine
                        >

;----------------------------------------------------------------------------
;	Graphics modes info
;----------------------------------------------------------------------------

colorHiRes	GraphicsProperties < HI_RES_COLOR_X_RES,	; xres
				     HI_RES_COLOR_Y_RES,	; yres
				     HI_RES_COLOR_BAND_HEIGHT,	; band height
                                     HI_RES_COLOR_BUFF_HEIGHT,	; buffer height
                                     NIKE_INTERLEAVE_FACTOR,	; #interleaves
				     BMF_3CMY,			; color format
				     handle nikeInkCorrection > ; color corr

colorMedRes	GraphicsProperties < MED_RES_COLOR_X_RES,	; xres
				     MED_RES_COLOR_Y_RES,	; yres
				     MED_RES_COLOR_BAND_HEIGHT,	; band height
                                     MED_RES_COLOR_BUFF_HEIGHT,	; buffer height
                                     NIKE_INTERLEAVE_FACTOR,	; #interleaves
				     BMF_3CMY,			; color format
				     handle nikeInkCorrection > ; color corr

colorLoRes	GraphicsProperties < LO_RES_COLOR_X_RES,	; xres
				     LO_RES_COLOR_Y_RES,	; yres
				     LO_RES_COLOR_BAND_HEIGHT,	; band height
                                     LO_RES_COLOR_BUFF_HEIGHT,	; buffer height
                                     NIKE_INTERLEAVE_FACTOR,	; #interleaves
				     BMF_3CMY,			; color format
				     handle nikeInkCorrection > ; color corr

colorInfo	ends
